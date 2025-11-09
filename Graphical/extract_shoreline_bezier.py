import argparse
import json
from pathlib import Path
from typing import List, Tuple

import cv2
import numpy as np


def _build_mask(hsv: np.ndarray, low: Tuple[int, int, int], high: Tuple[int, int, int]) -> np.ndarray:
    mask = cv2.inRange(hsv, np.array(low, dtype=np.uint8), np.array(high, dtype=np.uint8))
    kernel = np.ones((5, 5), np.uint8)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel, iterations=2)
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel, iterations=1)
    return mask


def _extract_shoreline_contour(image: np.ndarray) -> np.ndarray:
    blurred = cv2.GaussianBlur(image, (7, 7), 0)
    hsv = cv2.cvtColor(blurred, cv2.COLOR_BGR2HSV)

    water_mask = _build_mask(hsv, (80, 40, 30), (140, 255, 255))
    sand_mask = _build_mask(hsv, (5, 20, 120), (30, 200, 255))

    boundary = cv2.Canny(water_mask, 30, 120)
    boundary = cv2.dilate(boundary, np.ones((5, 5), np.uint8), iterations=1)
    boundary = cv2.bitwise_and(boundary, cv2.Canny(sand_mask, 30, 120))

    contours, _ = cv2.findContours(boundary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    if not contours:
        raise RuntimeError("No shoreline contour detected; adjust color thresholds or preprocess image.")

    h, w = image.shape[:2]
    best = None
    best_score = -np.inf
    for contour in contours:
        if contour.shape[0] < 200:
            continue
        pts = contour[:, 0, :]
        xs = pts[:, 0]
        ys = pts[:, 1]
        width_span = xs.max() - xs.min()
        y_mean = ys.mean()
        score = (width_span / w) + ((h - y_mean) / h) + (np.std(ys) / h)
        if score > best_score:
            best_score = score
            best = contour

    if best is None:
        raise RuntimeError("Failed to identify shoreline contour; try adjusting thresholds.")

    return best[:, 0, :]


def _sample_contour_points(contour: np.ndarray, samples: int = 200) -> np.ndarray:
    diffs = np.diff(contour, axis=0)
    seg_lengths = np.hypot(diffs[:, 0], diffs[:, 1])
    cumulative = np.concatenate(([0.0], np.cumsum(seg_lengths)))
    total = cumulative[-1]
    if total == 0:
        raise RuntimeError("Degenerate contour with zero length.")

    targets = np.linspace(0.0, total, samples)
    sampled = []
    idx = 0
    for t in targets:
        while idx < len(cumulative) - 1 and cumulative[idx + 1] < t:
            idx += 1
        if idx == len(cumulative) - 1:
            sampled.append(contour[-1])
            continue
        segment_start = contour[idx]
        segment_end = contour[idx + 1]
        local = (t - cumulative[idx]) / (cumulative[idx + 1] - cumulative[idx] + 1e-6)
        point = (1 - local) * segment_start + local * segment_end
        sampled.append(point)
    return np.array(sampled)


def _fit_cubic_bezier(points: np.ndarray) -> np.ndarray:
    if points.shape[0] < 4:
        raise ValueError("Need at least four points to fit a cubic Bezier curve.")

    p0 = points[0]
    p3 = points[-1]

    diffs = np.diff(points, axis=0)
    lengths = np.hypot(diffs[:, 0], diffs[:, 1])
    cumulative = np.concatenate(([0.0], np.cumsum(lengths)))
    total = cumulative[-1]
    if total == 0:
        raise RuntimeError("Cannot fit Bezier: identical sample points.")
    ts = cumulative / total

    b1 = 3 * (1 - ts) ** 2 * ts
    b2 = 3 * (1 - ts) * ts ** 2
    rhs = points - np.outer((1 - ts) ** 3, p0) - np.outer(ts ** 3, p3)
    A = np.vstack([b1, b2]).T

    # Solve for x and y control points separately
    ctrl_x, _, _, _ = np.linalg.lstsq(A, rhs[:, 0], rcond=None)
    ctrl_y, _, _, _ = np.linalg.lstsq(A, rhs[:, 1], rcond=None)

    p1 = np.array([ctrl_x[0], ctrl_y[0]])
    p2 = np.array([ctrl_x[1], ctrl_y[1]])

    return np.vstack([p0, p1, p2, p3])


def extract_bezier_from_image(image_path: Path, samples: int = 200) -> Tuple[np.ndarray, np.ndarray]:
    image = cv2.imread(str(image_path))
    if image is None:
        raise FileNotFoundError(f"Could not read image at {image_path}")

    contour = _extract_shoreline_contour(image)
    sampled = _sample_contour_points(contour, samples=samples)
    bezier = _fit_cubic_bezier(sampled)
    return bezier, sampled


def _save_results(bezier: np.ndarray, sampled: np.ndarray, output: Path) -> None:
    payload = {
        "bezier_control_points": bezier.tolist(),
        "sampled_points": sampled.tolist(),
    }
    output.write_text(json.dumps(payload, indent=2))


def _visualize(image_path: Path, bezier: np.ndarray, sampled: np.ndarray) -> None:
    image = cv2.imread(str(image_path))
    if image is None:
        return

    for pt in sampled.astype(int):
        cv2.circle(image, tuple(pt), 2, (0, 0, 255), -1)

    ts = np.linspace(0.0, 1.0, 200)
    curve = []
    for t in ts:
        b0 = (1 - t) ** 3
        b1 = 3 * (1 - t) ** 2 * t
        b2 = 3 * (1 - t) * t ** 2
        b3 = t ** 3
        point = b0 * bezier[0] + b1 * bezier[1] + b2 * bezier[2] + b3 * bezier[3]
        curve.append(point)
    curve = np.array(curve).astype(int)

    for i in range(len(curve) - 1):
        cv2.line(image, tuple(curve[i]), tuple(curve[i + 1]), (0, 255, 0), 2)

    cv2.imshow("Shoreline Fit", image)
    cv2.waitKey(0)
    cv2.destroyAllWindows()


def main() -> None:
    parser = argparse.ArgumentParser(description="Extract a cubic Bezier approximation of a shoreline from an image.")
    parser.add_argument("image", type=Path, help="Path to the source image")
    parser.add_argument("--samples", type=int, default=200, help="Number of contour samples for fitting")
    parser.add_argument("--output", type=Path, help="Optional path to write control points as JSON")
    parser.add_argument("--show", action="store_true", help="Display overlay of fitted curve")
    args = parser.parse_args()

    bezier, sampled = extract_bezier_from_image(args.image, samples=args.samples)

    print("Cubic Bezier control points (x, y):")
    for idx, point in enumerate(bezier):
        print(f"P{idx}: {point[0]:.2f}, {point[1]:.2f}")

    if args.output:
        _save_results(bezier, sampled, args.output)
        print(f"Saved control points and samples to {args.output}")

    if args.show:
        _visualize(args.image, bezier, sampled)


if __name__ == "__main__":
    main()
