import re

for fname in ['lib/l10n/app_si.arb', 'lib/l10n/app_ta.arb']:
    with open(fname, encoding='utf-8') as f:
        content = f.read()
    seen = set()
    out_lines = []
    removed = []
    for line in content.splitlines(keepends=True):
        m = re.match(r'\s*"([^"]+)":', line)
        if m:
            key = m.group(1)
            if key in seen:
                removed.append(key)
                continue
            seen.add(key)
        out_lines.append(line)
    with open(fname, 'w', encoding='utf-8') as f:
        f.writelines(out_lines)
    print(fname + ' removed duplicates: ' + str(removed))

print('All done')
