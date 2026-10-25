#!/usr/bin/env python3
"""Create website-only and full project ZIPs. Do not include other repository work."""
from pathlib import Path
import hashlib
import json
import subprocess
import zipfile
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / '.artifacts'
OUT.mkdir(exist_ok=True)
sha = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
manifest = json.loads((ROOT / 'generated-manifest.json').read_text())
public = [ROOT / name for name in manifest['pages']] + [ROOT / 'robots.txt', ROOT / 'sitemap.xml']
public += sorted((ROOT / 'assets').glob('*')) + sorted((ROOT / 'downloads').glob('*'))
for name, paths in [('webmerek-website.zip', public), ('webmerek-project.zip', [ROOT / p for p in subprocess.check_output(['git', 'ls-files', 'webmerek'], text=True, cwd=ROOT.parent).splitlines() for p in [str(Path(p).relative_to('webmerek'))]])]:
    with zipfile.ZipFile(OUT / name, 'w', zipfile.ZIP_DEFLATED) as archive:
        for path in paths:
            if path.is_file(): archive.write(path, path.relative_to(ROOT))
        archive.writestr('SOURCE_REVISION.txt', sha + '\nVerified source is recorded by the matching GitHub Actions run.\n')
(OUT / 'source-revision.txt').write_text(sha + '\n')
(OUT / 'checksums.sha256').write_text(''.join(hashlib.sha256((OUT / name).read_bytes()).hexdigest() + '  ' + name + '\n' for name in ['webmerek-website.zip', 'webmerek-project.zip']))
print('Packaged source ' + sha)
