from pathlib import Path
import hashlib
import json
import zipfile

root = Path(__file__).resolve().parent.parent
report = json.loads((root / 'validation-results.json').read_text())
assert report['status'] == 'passed' and report['failures'] == 0
assert report['projects'] == 65 and report['sourceFiles'] == 90
guide = f'''# Validation receipt

All {report['projects']} projects matched their documented outcomes in [GitHub Actions run {report['runId']}]({report['runUrl']}).

- {report['positiveProjects']} positive projects compiled through the existing checked pipeline and passed genuine independent Lean Wasm kernel checking.
- {report['intentionalDiagnosticProjects']} intentional diagnostic projects were refused in their expected compiler phases.
- {report['runtimeAssertions']} exported scalar values were checked by executing the emitted JavaScript.
- {report['sourceFiles']} `.ps` source files are covered by the recorded project snapshots.

Compiler: `{report['compiler']}`. Runtime: `{report['node']}` on `{report['platform']}`. Compiler tarball SHA-256: `{report['compilerTarballSha256']}`.

Exact source commit: `{report['commit']}`. Recorded at `{report['createdAt']}`.

These are real compiler, kernel, and runtime results. No compiler mocks were used, and the compiler/kernel implementations were not rebuilt or modified. Runtime values in the proof examples are separate smoke observations; they do not substitute for independent theorem checking.

See `validation-results.json` for every source hash, admitted-graph identity, observed value, diagnostic phase, and duration. Full target compilation and runtime observation were qualified on Linux; the previously qualified editor 0.1.1 checks source projects on Linux, Windows, and macOS.
'''
(root / 'VALIDATION.md').write_text(guide)
files = sorted(p for p in root.rglob('*') if p.is_file() and not any(x in p.relative_to(root).parts for x in ('_ci', '_dist')) and p.name != 'CHECKSUMS.sha256')
checksums = '\n'.join(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.relative_to(root).as_posix()}' for p in files) + '\n'
(root / 'CHECKSUMS.sha256').write_text(checksums)
files.append(root / 'CHECKSUMS.sha256')
out = root / '_dist'
out.mkdir(exist_ok=True)
archive = out / 'psc1-ps-examples-2026-10-28.zip'
with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for p in sorted(files):
        name = 'psc1-ps-examples/' + p.relative_to(root).as_posix()
        info = zipfile.ZipInfo(name, (2026, 10, 28, 0, 0, 0))
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = 0o100644 << 16
        z.writestr(info, p.read_bytes())
data = archive.read_bytes()
receipt = {'schema': 'psc1-example-archive/1', 'file': archive.name, 'bytes': len(data),
    'sha256': hashlib.sha256(data).hexdigest(), 'files': len(files), 'projects': report['projects'],
    'sourceFiles': report['sourceFiles'], 'qualifiedCommit': report['commit'], 'runId': report['runId']}
(out / 'bundle-build.json').write_text(json.dumps(receipt, indent=2) + '\n')
print('PSC1_EXAMPLE_ARCHIVE ' + json.dumps(receipt))
