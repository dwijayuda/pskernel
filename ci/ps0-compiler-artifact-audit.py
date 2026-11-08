#!/usr/bin/env python3
"""Audit retained compiler link provenance with explicit evidence boundaries."""
from pathlib import Path
import hashlib
import json
import os
import re
import subprocess

root = Path('compiler-evidence')
source = os.environ['PS0_SOURCE_SHA']
run = int(os.environ['PS0_BUILD_RUN'])
artifact = int(os.environ['PS0_BUILD_ARTIFACT'])
migration_path = root / 'migration.json'
full = migration_path.is_file()
data_path = migration_path if full else root / 'input-inventory.json'
data = json.loads(data_path.read_text())
assert data['source_commit'] == source
assert data['lean_commit'] == 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc'
assert data['module_count'] == len(data['inputs']) == 2564
digest = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
link_map = root / 'compiler-link.map'
text = link_map.read_text()
critical = ['Lean/Elab/Frontend', 'Lean/Compiler/LCNF/EmitC', 'PS0/LakeFrontend', 'PS0Main']
for module in critical:
    assert '/artifacts/ir/' + module + '.c.o' in text, ('missing rebuilt compiler object', module)
fallback = sorted(set(line.strip() for line in text.splitlines()
                      if re.search(r'/(?:libLean|libStd|libInit)\.a\(', line)))
needed = []
sdk_source_shared = []
if full:
    assert data['bootstrap_package_identity'] is None
    assert len(data['outputs']) == 2564 and data['verified_execution'] is False
    assert digest(root / 'migrated-ps0') == data['driver_sha256']
    dynamic = subprocess.check_output(['readelf', '-d', str(root / 'migrated-ps0')], text=True)
    needed = re.findall(r'Shared library: \[([^\]]+)\]', dynamic)
    sdk_source_shared = [name for name in needed if
                         name.startswith(('libleanshared', 'libInit_shared', 'libLake_shared'))]
print('PS0_LINK_CRITICAL_REBUILT_OBJECTS: ' + ', '.join(critical), flush=True)
print('PS0_LINK_SDK_SOURCE_ARCHIVE_LINES: ' + str(len(fallback)), flush=True)
for line in fallback[:100]:
    print(line, flush=True)
result = {
    'schema': 'ps0-compiler-link-audit/1',
    'source_commit': source, 'build_run': run, 'artifact_id': artifact,
    'module_count': data['module_count'],
    'metadata_sha256': digest(data_path), 'link_map_sha256': digest(link_map),
    'critical_rebuilt_objects': critical, 'sdk_source_archive_lines': fallback,
    'needed_libraries': needed, 'sdk_source_shared_libraries': sdk_source_shared,
    'elf_audit': 'EXECUTED' if full else 'NOT_AVAILABLE_BINARY_NOT_RETAINED',
    'compiler_runtime_smoke': data.get('runtime_smoke', 'FAILED_NOT_QUALIFIED'),
    'scope': 'Linux C backend; SDK C++ runtime remains the pinned infrastructure',
    'verified_execution': False,
}
Path('compiler-artifact-audit.json').write_text(json.dumps(result, indent=2) + '\n')
assert not fallback, 'SDK Lean/Init/Std source objects were linked; inspect the retained link map'
assert not sdk_source_shared, 'SDK Lean/Init/Lake shared source library was linked'
print('PS0_COMPILER_LINK_MAP_PROVENANCE: PASS', flush=True)
if full:
    print('PS0_COMPILER_ELF_PROVENANCE: PASS', flush=True)
else:
    print('PS0_COMPILER_ELF_PROVENANCE: NOT_AVAILABLE; runtime smoke failed in the build run', flush=True)
