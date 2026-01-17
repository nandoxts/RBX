import re
import os
from collections import defaultdict

root = r"c:\Users\Admin\SX"
patterns = [re.compile(r"rbxassetid://(\d+)") , re.compile(r"\bID\b\s*=\s*(\d+)") , re.compile(r"\bid\b\s*=\s*(\d+)")]

occ = defaultdict(list)

for dirpath, dirnames, filenames in os.walk(root):
    for fn in filenames:
        path = os.path.join(dirpath, fn)
        try:
            with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                for i, line in enumerate(f, start=1):
                    for pat in patterns:
                        for m in pat.finditer(line):
                            idv = m.group(1)
                            occ[idv].append((path.replace('\\\\','\\'), i, line.strip()))
        except Exception:
            pass

# Print duplicates
for idv, lst in sorted(occ.items(), key=lambda x: (-len(x[1]), x[0])):
    if len(lst) > 1:
        print(f"ID {idv} -> {len(lst)} occurrences")
        for p, ln, txt in lst:
            print(f"  {p}:{ln}: {txt}")
        print()

# If no duplicates
if not any(len(v)>1 for v in occ.values()):
    print("No duplicated IDs found.")
