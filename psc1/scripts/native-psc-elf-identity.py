#!/usr/bin/env python3
"""Compare Linux ELF64 execution sections before/after symbol stripping.

This is packaging identity evidence, not a proof of compiler preservation.
No binary is executed here. Reject unsupported ELF layouts instead of guessing.
"""
import hashlib
import json
import pathlib
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
    before, after = (inspect(name) for name in sys.argv[1:])
    assert before == after, 'stripping changed loadable ELF execution data'
    print(json.dumps({'schema': 'psc1-native-elf-strip-identity/1', 'passed': True,
                      'allocatedSections': len(before['allocatedSections']),
                      'identitySha256': hashlib.sha256(json.dumps(before, sort_keys=True).encode()).hexdigest(),
                      'scope': 'same program headers, entry and allocated sections; not semantic preservation theorem'}))
