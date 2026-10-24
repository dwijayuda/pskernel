import ScriptRuntimeReference

-- Exact allowed cache block and substitutions; all other retained bytes stay guarded.
def psPythonUtf8ReferenceCacheBlock : String := "# Immutable snapshots keep identity hits independent of String equality.\n_psc_utf8_cache = ((), 0)\n_psc_utf8_cache_limit = 33554432\n\ndef _psc_utf8(text):\n    global _psc_utf8_cache\n    entries, retained = _psc_utf8_cache\n    for index, entry in _psc_b.enumerate(entries):\n        if entry[0] is text:\n            if index:\n                _psc_utf8_cache = ((entry,) + entries[:index] + entries[index + 1:], retained)\n            return entry[1]\n    data = text.encode(\"utf-8\")\n    size = _psc_b.len(data)\n    if size <= _psc_utf8_cache_limit:\n        entries = ((text, data),) + entries\n        retained += size\n        while _psc_b.len(entries) > 8 or retained > _psc_utf8_cache_limit:\n            retained -= _psc_b.len(entries[-1][1])\n            entries = entries[:-1]\n        _psc_utf8_cache = (entries, retained)\n    return data\n\n"

def psPythonUtf8ReferenceNeutral (source : String) : String :=
  (source.replace psPythonUtf8ReferenceCacheBlock "").replace
    "data = _psc_utf8(text)" "data = text.encode(\"utf-8\")"
