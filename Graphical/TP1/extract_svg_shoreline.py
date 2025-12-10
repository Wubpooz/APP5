#!/usr/bin/env python3
"""
Extract multi-segment Bézier curves from SVG path data for GLSL shoreline rendering.

Usage:
    1. Open your image in Inkscape
    2. Use the Pen tool (B) to trace the shoreline with Bézier curves
    3. Save as SVG
    4. Run: python extract_svg_shoreline.py your_file.svg --output shoreline_segments.json
"""

import argparse
import json
import re
from pathlib import Path
from typing import List, Tuple, Dict
from xml.etree import ElementTree as ET


def parse_svg_path_data(path_d: str) -> List[Tuple[str, List[float]]]:
    """
    Parse SVG path d attribute into command sequences.
    Returns list of (command, [params]) tuples.
    """
    # SVG path commands: M/m, L/l, H/h, V/v, C/c, S/s, Q/q, T/t, A/a, Z/z
    commands = []
    
    # Split by command letters while preserving them
    tokens = re.findall(r'[MmLlHhVvCcSsQqTtAaZz]|[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?', path_d)
    
    current_command = None
    current_params = []
    
    for token in tokens:
        if token.upper() in 'MLHVCSQTAZ':
            if current_command is not None:
                commands.append((current_command, current_params))
            current_command = token
            current_params = []
        else:
            current_params.append(float(token))
    
    if current_command is not None:
        commands.append((current_command, current_params))
    
    return commands


def extract_bezier_segments(commands: List[Tuple[str, List[float]]]) -> List[List[Tuple[float, float]]]:
    """
    Extract cubic Bézier curve segments from parsed path commands.
    Returns list of segments, each with 4 control points: [P0, P1, P2, P3]
    """
    segments = []
    current_pos = (0.0, 0.0)
    path_start = (0.0, 0.0)
    last_control = None
    
    for cmd, params in commands:
        if cmd == 'M':  # Absolute moveto
            current_pos = (params[0], params[1])
            path_start = current_pos
            last_control = None
            
        elif cmd == 'm':  # Relative moveto
            current_pos = (current_pos[0] + params[0], current_pos[1] + params[1])
            path_start = current_pos
            last_control = None
            
        elif cmd == 'C':  # Absolute cubic Bézier
            # C x1 y1, x2 y2, x y
            for i in range(0, len(params), 6):
                p0 = current_pos
                p1 = (params[i], params[i+1])
                p2 = (params[i+2], params[i+3])
                p3 = (params[i+4], params[i+5])
                segments.append([p0, p1, p2, p3])
                current_pos = p3
                last_control = p2
                
        elif cmd == 'c':  # Relative cubic Bézier
            for i in range(0, len(params), 6):
                p0 = current_pos
                p1 = (current_pos[0] + params[i], current_pos[1] + params[i+1])
                p2 = (current_pos[0] + params[i+2], current_pos[1] + params[i+3])
                p3 = (current_pos[0] + params[i+4], current_pos[1] + params[i+5])
                segments.append([p0, p1, p2, p3])
                current_pos = p3
                last_control = p2
                
        elif cmd == 'S':  # Absolute smooth cubic Bézier
            for i in range(0, len(params), 4):
                p0 = current_pos
                # First control point is reflection of last control point
                if last_control:
                    p1 = (2*current_pos[0] - last_control[0], 2*current_pos[1] - last_control[1])
                else:
                    p1 = current_pos
                p2 = (params[i], params[i+1])
                p3 = (params[i+2], params[i+3])
                segments.append([p0, p1, p2, p3])
                current_pos = p3
                last_control = p2
                
        elif cmd == 's':  # Relative smooth cubic Bézier
            for i in range(0, len(params), 4):
                p0 = current_pos
                if last_control:
                    p1 = (2*current_pos[0] - last_control[0], 2*current_pos[1] - last_control[1])
                else:
                    p1 = current_pos
                p2 = (current_pos[0] + params[i], current_pos[1] + params[i+1])
                p3 = (current_pos[0] + params[i+2], current_pos[1] + params[i+3])
                segments.append([p0, p1, p2, p3])
                current_pos = p3
                last_control = p2
                
        elif cmd == 'Q':  # Absolute quadratic Bézier
            # Convert quadratic to cubic
            for i in range(0, len(params), 4):
                p0 = current_pos
                q1 = (params[i], params[i+1])
                p3 = (params[i+2], params[i+3])
                # Cubic control points from quadratic
                p1 = (p0[0] + 2/3*(q1[0]-p0[0]), p0[1] + 2/3*(q1[1]-p0[1]))
                p2 = (p3[0] + 2/3*(q1[0]-p3[0]), p3[1] + 2/3*(q1[1]-p3[1]))
                segments.append([p0, p1, p2, p3])
                current_pos = p3
                last_control = q1
                
        elif cmd == 'q':  # Relative quadratic Bézier
            for i in range(0, len(params), 4):
                p0 = current_pos
                q1 = (current_pos[0] + params[i], current_pos[1] + params[i+1])
                p3 = (current_pos[0] + params[i+2], current_pos[1] + params[i+3])
                p1 = (p0[0] + 2/3*(q1[0]-p0[0]), p0[1] + 2/3*(q1[1]-p0[1]))
                p2 = (p3[0] + 2/3*(q1[0]-p3[0]), p3[1] + 2/3*(q1[1]-p3[1]))
                segments.append([p0, p1, p2, p3])
                current_pos = p3
                last_control = q1
                
        elif cmd == 'L':  # Absolute lineto (convert to degenerate Bézier)
            for i in range(0, len(params), 2):
                p0 = current_pos
                p3 = (params[i], params[i+1])
                # Linear interpolation as Bézier
                p1 = (p0[0] + (p3[0]-p0[0])/3, p0[1] + (p3[1]-p0[1])/3)
                p2 = (p0[0] + 2*(p3[0]-p0[0])/3, p0[1] + 2*(p3[1]-p0[1])/3)
                segments.append([p0, p1, p2, p3])
                current_pos = p3
                last_control = None
                
        elif cmd == 'l':  # Relative lineto
            for i in range(0, len(params), 2):
                p0 = current_pos
                p3 = (current_pos[0] + params[i], current_pos[1] + params[i+1])
                p1 = (p0[0] + (p3[0]-p0[0])/3, p0[1] + (p3[1]-p0[1])/3)
                p2 = (p0[0] + 2*(p3[0]-p0[0])/3, p0[1] + 2*(p3[1]-p0[1])/3)
                segments.append([p0, p1, p2, p3])
                current_pos = p3
                last_control = None
    
    return segments


def normalize_to_uv(segments: List[List[Tuple[float, float]]], 
                    viewbox: Tuple[float, float, float, float],
                    uv_bounds: Dict[str, Tuple[float, float]]) -> List[List[Tuple[float, float]]]:
    """
    Normalize SVG coordinates to UV space matching shader expectations.
    
    viewbox: (min_x, min_y, width, height) from SVG
    uv_bounds: {'x': (min_uv_x, max_uv_x), 'y': (min_uv_y, max_uv_y)}
    """
    vb_x, vb_y, vb_w, vb_h = viewbox
    (uv_x_min, uv_x_max) = uv_bounds['x']
    (uv_y_min, uv_y_max) = uv_bounds['y']
    
    normalized = []
    for segment in segments:
        norm_seg = []
        for x, y in segment:
            # Normalize from viewbox to 0-1
            nx = (x - vb_x) / vb_w
            ny = (y - vb_y) / vb_h
            # Map to UV bounds
            uv_x = uv_x_min + nx * (uv_x_max - uv_x_min)
            uv_y = uv_y_min + ny * (uv_y_max - uv_y_min)
            norm_seg.append((uv_x, uv_y))
        normalized.append(norm_seg)
    
    return normalized


def extract_shoreline_from_svg(svg_path: Path, 
                               path_id: str = None,
                               uv_bounds: Dict[str, Tuple[float, float]] = None) -> List[List[Tuple[float, float]]]:
    """
    Extract Bézier curve segments from SVG file.
    
    Args:
        svg_path: Path to SVG file
        path_id: Optional specific path ID to extract (default: use first path found)
        uv_bounds: Optional UV bounds for normalization
    
    Returns:
        List of Bézier segments, each with 4 control points
    """
    tree = ET.parse(svg_path)
    root = tree.getroot()
    
    # Get viewBox
    viewbox_attr = root.get('viewBox')
    if viewbox_attr:
        viewbox = tuple(map(float, viewbox_attr.split()))
    else:
        # Fallback to width/height
        width = float(root.get('width', '1248'))
        height = float(root.get('height', '832'))
        viewbox = (0, 0, width, height)
    
    # Find path elements (handle namespace)
    ns = {'svg': 'http://www.w3.org/2000/svg'}
    paths = root.findall('.//svg:path', ns) or root.findall('.//path')
    
    if not paths:
        raise ValueError("No path elements found in SVG")
    
    # Select path
    if path_id:
        target_path = next((p for p in paths if p.get('id') == path_id), None)
        if not target_path:
            raise ValueError(f"Path with id='{path_id}' not found")
    else:
        # Use first path with actual data
        target_path = None
        for p in paths:
            d_attr = p.get('d', '')
            if d_attr and len(d_attr.strip()) > 10:
                target_path = p
                break
        if not target_path:
            raise ValueError("No valid path data found")
    
    path_data = target_path.get('d', '')
    print(f"Extracting path: id='{target_path.get('id')}', length={len(path_data)} chars")
    
    # Parse path
    commands = parse_svg_path_data(path_data)
    segments = extract_bezier_segments(commands)
    
    print(f"Found {len(segments)} Bézier segments")
    
    # Normalize if bounds provided
    if uv_bounds:
        segments = normalize_to_uv(segments, viewbox, uv_bounds)
    
    return segments


def main():
    parser = argparse.ArgumentParser(
        description="Extract multi-segment Bézier curves from SVG for GLSL shoreline rendering"
    )
    parser.add_argument('svg', type=Path, help='Path to SVG file')
    parser.add_argument('--path-id', help='Specific path ID to extract (default: first valid path)')
    parser.add_argument('--output', type=Path, help='Output JSON file')
    parser.add_argument('--uv-x-min', type=float, default=0.0115, help='Minimum UV x coordinate')
    parser.add_argument('--uv-x-max', type=float, default=0.95, help='Maximum UV x coordinate')
    parser.add_argument('--uv-y-min', type=float, default=0.25, help='Minimum UV y coordinate')
    parser.add_argument('--uv-y-max', type=float, default=0.4794, help='Maximum UV y coordinate')
    parser.add_argument('--list-paths', action='store_true', help='List all path IDs and exit')
    
    args = parser.parse_args()
    
    if args.list_paths:
        tree = ET.parse(args.svg)
        root = tree.getroot()
        ns = {'svg': 'http://www.w3.org/2000/svg'}
        paths = root.findall('.//svg:path', ns) or root.findall('.//path')
        print(f"Found {len(paths)} path elements:")
        for i, path in enumerate(paths):
            path_id = path.get('id', f'<unnamed-{i}>')
            path_d = path.get('d', '')
            print(f"  [{i}] id='{path_id}' ({len(path_d)} chars)")
        return
    
    uv_bounds = {
        'x': (args.uv_x_min, args.uv_x_max),
        'y': (args.uv_y_min, args.uv_y_max)
    }
    
    segments = extract_shoreline_from_svg(args.svg, args.path_id, uv_bounds)
    
    # Format output
    print("\nBézier Segments (UV coordinates):")
    for i, seg in enumerate(segments):
        print(f"\n  Segment {i}:")
        for j, (x, y) in enumerate(seg):
            print(f"    P{j}: ({x:.4f}, {y:.4f})")
    
    if args.output:
        output_data = {
            'segment_count': len(segments),
            'segments': [[list(pt) for pt in seg] for seg in segments],
            'uv_bounds': {
                'x': [args.uv_x_min, args.uv_x_max],
                'y': [args.uv_y_min, args.uv_y_max]
            }
        }
        args.output.write_text(json.dumps(output_data, indent=2))
        print(f"\nSaved to {args.output}")
    
    # Generate GLSL array declaration
    print("\n// GLSL code snippet:")
    print(f"const int SEGMENT_COUNT = {len(segments)};")
    print("vec2 shorelineSegments[SEGMENT_COUNT * 4] = vec2[](")
    for i, seg in enumerate(segments):
        for j, (x, y) in enumerate(seg):
            comma = ',' if (i < len(segments)-1 or j < 3) else ''
            print(f"  vec2({x:.4f}, {y:.4f}){comma}")
    print(");")


if __name__ == '__main__':
    main()
