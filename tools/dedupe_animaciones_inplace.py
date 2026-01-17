import re
import shutil
from pathlib import Path
from datetime import datetime

src = Path(r"c:\Users\Admin\SX\ReplicatedStorage\Panda ReplicatedStorage\Emotes_Sync\Emotes_Modules\Animaciones.lua")
if not src.exists():
    print("Source file not found:", src)
    raise SystemExit(1)

bak = src.with_suffix('.lua.bak')
# include timestamp if bak exists
if bak.exists():
    bak = src.with_suffix('.lua.bak.' + datetime.now().strftime('%Y%m%d%H%M%S'))
shutil.copy2(src, bak)

lines = src.read_text(encoding='utf-8').splitlines()
entry_pat = re.compile(r"\{[^}]*\bID\s*=\s*(\d+)[^}]*\}", re.IGNORECASE)
seen = set()
new_lines = []
removed = []

for line in lines:
    m = entry_pat.search(line)
    if m:
        idv = m.group(1)
        if idv in seen:
            removed.append((idv, line.strip()))
            continue
        seen.add(idv)
    new_lines.append(line)

src.write_text('\n'.join(new_lines)+"\n", encoding='utf-8')

print(f"Backup created: {bak}")
print(f"Removed {len(removed)} duplicate entries")
for idv, txt in removed:
    print(idv, '->', txt)
