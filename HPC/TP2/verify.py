import urllib.request

url = "https://oeis.org/A045917/b045917.txt"
lines = urllib.request.urlopen(url).read().decode('ascii').splitlines()

oeis = {}
for line in lines:
  line = line.strip()
  if not line or line.startswith("#"):
    continue
  parts = line.split()
  if len(parts) >= 2:
    n = int(parts[0])
    a_n = int(parts[1])
    oeis[n] = a_n

your_output = {}

with open("output.txt", "r") as f:
  for line in f:
    parts = line.strip().split()
    if len(parts) != 2:
      continue  # skip header or malformed lines

    n, val = parts
    if n.lower() == "n":
      continue

    your_output[int(n)] = int(val)

print("Loaded entries:", len(your_output))


max_common_n = min(max(your_output.keys()), max(oeis.keys()))
print("Comparing up to n =", max_common_n)

for n in range(1, max_common_n + 1):
  your_val = your_output.get(n)
  expected = oeis.get(n)
  if your_val != expected:
    print(f"Mismatch at n={n}: your {your_val}, expected {expected}")

print("Verification complete.")