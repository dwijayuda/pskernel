#!/usr/bin/env python3
"""Keep symbol stripping only when the ELF execution identity is unchanged.

Unsupported layouts fail. A rejected strip candidate is replaced by the exact
original compiler bytes and explicitly reported, never silently qualified.
This is packaging identity evidence, not compiler semantic preservation.
"""
import hashlib
import json
import pathlib
import shutil
import struct
import sys


def inspect(filename):
    data = pathlib.Path(filename).read_bytes()
    assert 64 <= len(data) <= 256 * 1024 * 1024
    header = struct.unpack_from('<16sHHIQQQIHHHHHH', data)
    assert header[0][:6] == b'\x7fELF\x02\x01', 'expected little-endian ELF64'
    assert header[1] in (2, 3) and header[2] == 62, 'expected x86-64 executable'
    phoff, shoff = header[5:7]
    phsize, phcount, shsize, shcount, namesindex = header[9:14]
    assert phsize == 56 and shsize == 64 and 0 < namesindex < shcount < 65535
    assert phoff + phsize * phcount <= len(data)
    assert shoff + shsize * shcount <= len(data)
    sections = [struct.unpack_from('<IIQQQQIIQQ', data, shoff + i * shsize)
                for i in range(shcount)]
    namessection = sections[namesindex]
    names = data[namessection[4]:namessection[4] + namessection[5]]
    allocated = []
    for section in sections:
        offset, size = section[4:6]
        if not section[2] & 2:
            continue
        assert section[0] < len(names)
        end = names.index(b'\0', section[0])
        name = names[section[0]:end].decode('ascii')
        assert section[1] == 8 or offset + size <= len(data)
        payload = b'' if section[1] == 8 else data[offset:offset + size]
        allocated.append({'name': name, 'type': section[1], 'flags': section[2],
                          'address': section[3], 'bytes': size, 'alignment': section[8],
                          'entrySize': section[9], 'sha256': hashlib.sha256(payload).hexdigest()})
    return {'type': header[1], 'machine': header[2], 'entry': header[4],
            'programHeadersSha256': hashlib.sha256(data[phoff:phoff + phsize * phcount]).hexdigest(),
            'allocatedSections': allocated}


if __name__ == '__main__':
    assert len(sys.argv) == 3
    source, candidate = map(pathlib.Path, sys.argv[1:])
    before, proposed = inspect(source), inspect(candidate)
    changes = {key: {'original': before[key], 'proposed': proposed[key]}
               for key in before if before[key] != proposed[key]}
    applied = not changes
    if not applied:
        print('PSC1_NATIVE_STRIP_REJECTED: ' + json.dumps(changes), file=sys.stderr)
        shutil.copyfile(source, candidate)
        assert source.read_bytes() == candidate.read_bytes(), 'original binary restoration failed'
    after = inspect(candidate)
    assert before == after, 'final binary changed ELF execution identity'
    print(json.dumps({'schema': 'psc1-native-elf-strip-identity/1', 'passed': True,
                      'stripApplied': applied,
                      'selection': 'stripped-execution-identical' if applied else 'exact-original-binary',
                      'rejectedCandidateDifferences': changes,
                      'allocatedSections': len(before['allocatedSections']),
                      'identitySha256': hashlib.sha256(json.dumps(before, sort_keys=True).encode()).hexdigest(),
                      'scope': 'same program headers, entry and allocated sections; original bytes retained on strip mismatch'}))
