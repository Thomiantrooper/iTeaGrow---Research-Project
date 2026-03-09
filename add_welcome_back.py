from pathlib import Path
BASE = Path(r'C:\Users\HP\Desktop\Tea\iTeaGrow-Prod\frontend\iTeaGrow---Research-Project\lib\l10n')
additions = [
    ('app_en.arb', 'login_welcome_back_heading', 'Welcome Back'),
    ('app_si.arb', 'login_welcome_back_heading', u'\u0db1\u0dd0\u0dc3\u0dd9\u0dad \u0dc3\u0dcf\u0daf\u0dbb\u0dba\u0dd9\u0db1 \u0db4\u0dd2\u0dbd\u0dd2\u0d9c\u0db1\u0dd2\u0db8\u0dd4'),
    ('app_ta.arb', 'login_welcome_back_heading', u'\u0bae\u0bc0\u0ba3\u0bcd\u0b9f\u0bc1\u0bae\u0bcd \u0bb5\u0bb0\u0bb5\u0bc7\u0bb1\u0bcd\u0b95\u0bbf\u0bb1\u0bcb\u0bae\u0bcd'),
]
for fname, key, val in additions:
    path = BASE / fname
    content = path.read_text(encoding='utf-8')
    if key in content:
        print(f'{fname}: already present')
        continue
    closing = content.rfind('\n}')
    new_content = content[:closing] + ',\n  "' + key + '": "' + val + '"' + content[closing:]
    path.write_text(new_content, encoding='utf-8')
    print(f'{fname}: added {key}')
print("Done.")
