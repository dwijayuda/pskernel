#!/usr/bin/env python3
"""Keep stripping only with identical ELF execution sections and metadata.

GNU strip may normalize zero sh_entsize on ELF constructor arrays to eight.
Restore that exact original section-header field outside all loadable segments,
then run the unchanged full identity comparison. Any other difference retains
an exact copy of the original binary. No code or allocated bytes are patched.
"""
import hashlib
import json
import pathlib
import shutil
import struct
import sys


def layout(filename):
    data = pathlib.Path(filename).read_bytes()
    assert 64 <= len(data) <= 256 * 1024 * 1024
    header = struct.unpack_from('<16sHHIQQQIHHHHHH', data)
    assert header[0][:6] == b'\x7fELF\x02\x01'
    assert header[1] in (2, 3) and header[2] == 62
    phoff, shoff = header[5:7]
    phsize, phcount, shsize, shcount, namesindex = header[9:14]
    assert phsize == 56 and shsize == 64 and 0 < namesindex < shcount < 65535
    assert phoff + phsize * phcount <= len(data)
    assert shoff + shsize * shcount <= len(data)
    sections = [struct.unpack_from('<IIQQQQIIQQ', data, shoff + i * shsize)
                for i in range(shcount)]
    namessection = sections[namesindex]
    assert namessection[4] + namessection[5] <= len(data)
    names = data[namessection[4]:namessection[4] + namessection[5]]
    allocated, locations = [], {}
    for index, section in enumerate(sections):
        offset, size = section[4:6]
        if not section[2] & 2:
            continue
        assert section[0] < len(names)
        end = names.index(b'\0', section[0])
        name = names[section[0]:end].decode('ascii')
        assert name not in locations
        assert section[1] == 8 or offset + size <= len(data)
        payload = b'' if section[1] == 8 else data[offset:offset + size]
        locations[name] = shoff + index * shsize + 56
        allocated.append({'name': name, 'type': section[1], 'flags': section[2],
                          'address': section[3], 'bytes': size, 'alignment': section[8],
                          'entrySize': section[9], 'sha256': hashlib.sha256(payload).hexdigest()})
    headers = [struct.unpack_from('<IIQQQQQQ', data, phoff + i * phsize)
               for i in range(phcount)]
    load_ranges = [(h[2], h[2] + h[5]) for h in headers if h[0] == 1]
    identity = {'type': header[1], 'machine': header[2], 'entry': header[4],
                'programHeadersSha256': hashlib.sha256(data[phoff:phoff + phsize * phcount]).hexdigest(),
                'allocatedSections': allocated}
    return data, identity, locations, load_ranges


def restore_nonloaded_array_metadata(source_identity, candidate):
    data, proposed, locations, loads = layout(candidate)
    if any(source_identity[k] != proposed[k] for k in source_identity if k != 'allocatedSections'):
        return []
    before, after = source_identity['allocatedSections'], proposed['allocatedSections']
    if len(before) != len(after):
        return []
    patches = []
    for old, new in zip(before, after):
        if old == new:
            continue
        old_fields = {k: v for k, v in old.items() if k != 'entrySize'}
        new_fields = {k: v for k, v in new.items() if k != 'entrySize'}
        if old_fields != new_fields or old['type'] not in (14, 15, 16):
            return []
        if old['entrySize'] != 0 or new['entrySize'] != 8 or old['bytes'] % 8:
            return []
        offset = locations[new['name']]
        assert all(offset + 8 <= lo or offset >= hi for lo, hi in loads), 'header field is loadable'
        patches.append({'section': old['name'], 'field': 'sh_entsize',
                        'original': 0, 'stripped': 8, 'offset': offset,
                        'outsideAllLoadableSegments': True})
    if patches:
        changed = bytearray(data)
        for patch in patches:
            struct.pack_into('<Q', changed, patch['offset'], patch['original'])
        pathlib.Path(candidate).write_bytes(changed)
        assert layout(candidate)[1] == source_identity, 'metadata restoration did not preserve identity'
    return patches


if __name__ == '__main__':
    assert len(sys.argv) == 3
    source, candidate = map(pathlib.Path, sys.argv[1:])
    before = layout(source)[1]
    patches = restore_nonloaded_array_metadata(before, candidate)
    proposed = layout(candidate)[1]
    differences = [key for key in before if before[key] != proposed[key]]
    applied = not differences
    if not applied:
        print('PSC1_NATIVE_STRIP_REJECTED: ' + json.dumps(differences), file=sys.stderr)
        shutil.copyfile(source, candidate)
        assert source.read_bytes() == candidate.read_bytes(), 'original restoration failed'
    assert layout(candidate)[1] == before, 'final binary changed ELF execution identity'
    print(json.dumps({'schema': 'psc1-native-elf-strip-identity/1', 'passed': True,
                      'stripApplied': applied,
                      'selection': 'stripped-execution-identical' if applied else 'exact-original-binary',
                      'restoredNonloadedMetadata': patches,
                      'rejectedCandidateDifferences': differences,
                      'allocatedSections': len(before['allocatedSections']),
                      'identitySha256': hashlib.sha256(json.dumps(before, sort_keys=True).encode()).hexdigest(),
                      'scope': 'identical program headers, entry, allocated bytes and section identity; only nonloaded array header metadata restored'}))
