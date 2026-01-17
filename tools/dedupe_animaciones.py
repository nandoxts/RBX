import re
from pathlib import Path

src = Path(r"c:\Users\Admin\SX\ReplicatedStorage\Panda ReplicatedStorage\Emotes_Sync\Emotes_Modules\Animaciones.lua")
out = src.with_name("Animaciones.deduped.lua")
pat = re.compile(r"\{\s*ID\s*=\s*(\d+)\s*,\s*Nombre\s*=\s*(['\"]).*?\2\s*\},?\s*$")

seen = set()
removed = []
with src.open('r', encoding='utf-8') as f, out.open('w', encoding='utf-8') as w:
    for line in f:
        m = pat.search(line)
        if m:
            idv = m.group(1)
            if idv in seen:
                removed.append((idv, line.strip()))
                continue
            seen.add(idv)
        w.write(line)

print(f"Wrote deduped file: {out}")
print(f"Removed {len(removed)} duplicate entries")
for idv, txt in removed:
    print(idv, "->", txt)
