#!/usr/bin/env python3
"""Package the tested static site and full WebMerek project, not unrelated repository work."""
from pathlib import Path
import hashlib
import json
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parent
OUT = ROOT / '.artifacts'
OUT.mkdir(exist_ok=True)
sha = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True, cwd=REPO).strip()
manifest = json.loads((ROOT / 'generated-manifest.json').read_text())
public = [ROOT / name for name in manifest['pages']] + [ROOT / 'robots.txt', ROOT / 'sitemap.xml']
public += sorted((ROOT / 'assets').glob('*')) + sorted((ROOT / 'downloads').glob('*'))
tracked = subprocess.check_output(['git', 'ls-files', 'webmerek'], text=True, cwd=REPO).splitlines()
project = [(REPO / name, str(Path(name).relative_to('webmerek'))) for name in tracked]
workflow = '.github/workflows/webmerek-quality.yml'
project.append((REPO / workflow, workflow))
archives = {
    'webmerek-website.zip': [(path, str(path.relative_to(ROOT))) for path in public],
    'webmerek-project.zip': project,
}
for name, entries in archives.items():
    with zipfile.ZipFile(OUT / name, 'w', zipfile.ZIP_DEFLATED) as archive:
        for path, arcname in entries:
            if not path.is_file():
                raise FileNotFoundError(path)
            archive.write(path, arcname)
        archive.writestr('SOURCE_REVISION.txt', sha + '\nVerified source is recorded by the matching GitHub Actions run.\n')
(OUT / 'source-revision.txt').write_text(sha + '\n')
(OUT / 'checksums.sha256').write_text(''.join(hashlib.sha256((OUT / name).read_bytes()).hexdigest() + '  ' + name + '\n' for name in archives))
print('Packaged source ' + sha)
