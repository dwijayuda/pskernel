#!/usr/bin/env python3
"""Strict HTML parsing, local link/fragment checks, scope and delivery budgets."""
from __future__ import annotations
import json
import re
import subprocess
from pathlib import Path
from urllib.parse import unquote, urlsplit
import html5lib

ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT / 'generated-manifest.json').read_text())
assert len(manifest['pages']) >= 10
parsed = {}
ids = {}
for name in manifest['pages']:
    text = (ROOT / name).read_text()
    assert len(text.encode()) < 65000, f'HTML budget exceeded: {name}'
    parser = html5lib.HTMLParser(strict=True, namespaceHTMLElements=False)
    tree = parser.parse(text)
    parsed[name] = tree
    identifiers = [node.attrib['id'] for node in tree.iter() if 'id' in node.attrib]
    assert len(identifiers) == len(set(identifiers)), f'Duplicate ID: {name}'
    ids[name] = set(identifiers)
    assert tree.attrib.get('lang') == 'id'
    assert len(list(tree.iter('h1'))) == 1, name
    assert len(list(tree.iter('main'))) == 1, name
    assert any(node.attrib.get('name') == 'description' and len(node.attrib.get('content', '')) >= 50 for node in tree.iter('meta')), name
    assert any(node.attrib.get('property') == 'og:title' for node in tree.iter('meta')), name
    assert 'lorem ipsum' not in text.lower()
    assert not re.search(r'(?:src|href)=[\"\'](?:https?:)?//', text), f'Unexpected remote resource: {name}'
    for image in tree.iter('img'):
        assert 'alt' in image.attrib and 'width' in image.attrib and 'height' in image.attrib, name
    for form in tree.iter('form'):
        assert form.attrib.get('method') == 'post'
        assert any('disabled' in field.attrib for field in form.iter('fieldset')), name
for name, tree in parsed.items():
    for node in tree.iter():
        for attr in ('href', 'src', 'action'):
            raw = node.attrib.get(attr)
            if not raw:
                continue
            url = urlsplit(raw)
            if url.scheme or url.netloc:
                continue
            target = unquote(url.path) or name
            path = (ROOT / target).resolve()
            assert path.is_relative_to(ROOT), f'Path escapes site: {raw}'
            assert path.is_file(), f'Broken link in {name}: {raw}'
            if url.fragment and target in ids:
                assert unquote(url.fragment) in ids[target], f'Broken fragment in {name}: {raw}'
for asset, limit in [('assets/site.css', 40000), ('assets/site.js', 15000), ('assets/og.png', 250000)]:
    assert (ROOT / asset).stat().st_size < limit, f'Asset budget exceeded: {asset}'
config = json.loads((ROOT / 'site.json').read_text())
assert config['mode'] == 'preview', 'This qualification lane is a preview-only lane'
assert not config['whatsapp'] and not config['email'], 'Real contact changes require separate launch review'
for name in manifest['pages']:
    assert 'noindex, nofollow' in (ROOT / name).read_text()
changed = subprocess.check_output(['git', 'diff', '--name-only', '7d3e220e495f5d82178a3e66f191255045862bd5', 'HEAD'], text=True).splitlines()
assert changed and all(name.startswith('webmerek/') or name == '.github/workflows/webmerek-quality.yml' for name in changed), 'Out-of-scope repository change'
assert not subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=no'], text=True).strip(), 'Tracked tree must be clean before QA'
print(f'PASS: {len(parsed)} HTML pages parsed; all local assets/links/fragments, metadata, preview guards and repository scope checked.')
