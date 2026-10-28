"""Usage: python3 -I gpl_scan.py <sources.txt> <build-root>; lists files from `dwarfdump --show-sources` whose header names the GPL without the Lesser/Library variant."""
import re, sys, os
src_list, root = sys.argv[1], os.path.realpath(sys.argv[2])
gpl = re.compile(r'GNU General Public License|GPL-[23]|GPLv[23]|General Public License', re.I)
lgpl = re.compile(r'Lesser General|Library General|LGPL', re.I)
hits, scanned, missing = [], 0, 0
for line in open(src_list):
    p = line.strip()
    if not p.startswith(root):
        continue
    if not os.path.isfile(p):
        missing += 1
        continue
    scanned += 1
    with open(p, errors='replace') as f:
        head = f.read(6000)
    if gpl.search(head) and not lgpl.search(head):
        hits.append(p[len(root) + 1:])
print(f"scanned={scanned} missing={missing} candidates={len(hits)}")
for h in hits:
    print(h)
