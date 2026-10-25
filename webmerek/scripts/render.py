#!/usr/bin/env python3
"""Render committed static HTML from content/pages.py and site.json; standard library only."""
from __future__ import annotations
import argparse
import html
import json
import sys
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'content'))
from pages import PAGES, FAQS  # noqa: E402


def esc(value: object) -> str:
    return html.escape(str(value), quote=True)


def rupiah(value: int) -> str:
    return 'Rp' + f'{value:,}'.replace(',', '.')


def validate_config(config: dict) -> None:
    if config['mode'] not in ('preview', 'live'):
        raise ValueError('mode must be preview or live')
    base = config['publicBaseUrl']
    if base and (urlparse(base).scheme != 'https' or not urlparse(base).netloc or urlparse(base).query or urlparse(base).fragment):
        raise ValueError('publicBaseUrl must be a real HTTPS base URL without a query or fragment')
    if config['mode'] == 'live':
        required = ('contactVerified', 'legalReviewed', 'offersApproved', 'launchApproved')
        if not base or not config['operatorName'].strip() or not all(config[k] for k in required):
            raise ValueError('Live mode blocked: verify identity, contacts, legal text, offers and explicit launch approval first')
        phone = config['whatsapp']
        if not phone.isdigit() or not 8 <= len(phone) <= 15 or phone.startswith('0'):
            raise ValueError('Live mode requires a verified international WhatsApp number, digits only')
        if '@' not in config['email'] or any(c in config['email'] for c in '\r\n<>'):
            raise ValueError('Live mode requires a verified public email')
    elif config['allowIndexing']:
        raise ValueError('Preview mode must remain noindex')


def package_cards(config: dict) -> str:
    cards = []
    for i, package in enumerate(config['packages']):
        featured = ' featured' if i == 2 else ''
        cards.append(f'''<article class="package{featured}">
<p class="eyebrow">0{i + 1} / {esc(package['duration'])}</p>
<h3>{esc(package['name'])}</h3><p>{esc(package['fit'])}</p>
<p class="price"><span>Mulai dari</span>{rupiah(package['price'])}</p>
<ul class="checklist">{''.join('<li>' + esc(f) + '</li>' for f in package['features'])}</ul>
<p class="fine">{esc(package['exclusions'])}</p>
<a class="button {'button-light' if i == 2 else 'button-outline'}" href="kontak.html?paket={esc(package['id'])}">Susun brief paket ini <span aria-hidden="true">↗</span></a>
</article>''')
    return '<div class="packages">' + '\n'.join(cards) + '</div>'


def faq_block(limit: int | None = None) -> str:
    return '<div class="faqs">' + ''.join(f'<details><summary>{esc(q)}</summary><div><p>{a}</p></div></details>' for q, a in FAQS[:limit]) + '</div>'


def shell(page: dict, config: dict) -> str:
    slug, title, description = page['slug'], page['title'], page['description']
    preview = config['mode'] == 'preview'
    base = config['publicBaseUrl'].rstrip('/')
    nav_items = [('layanan.html', 'Layanan'), ('paket.html', 'Paket & harga'), ('karya.html', 'Karya konsep'), ('insight.html', 'Insight')]
    nav = ''.join(f'<a href="{url}"' + (' aria-current="page"' if slug == url else '') + f'>{label}</a>' for url, label in nav_items)
    extra = ''
    if base:
        extra += f'<link rel="canonical" href="{esc(base)}/{esc(slug)}">\n<meta property="og:url" content="{esc(base)}/{esc(slug)}">\n<meta property="og:image" content="{esc(base)}/assets/og.png">\n'
        if not preview:
            data = {'@context': 'https://schema.org', '@type': 'WebSite', 'name': config['name'], 'url': base + '/', 'inLanguage': 'id-ID'}
            extra += '<script type="application/ld+json">' + json.dumps(data, ensure_ascii=False).replace('<', '\\u003c') + '</script>\n'
    status = 'Prapeluncuran · harga usulan, belum menerima pemesanan' if preview else 'Studio branding & website untuk bisnis jasa'
    body = page['body'].replace('{{PACKAGES}}', package_cards(config)).replace('{{FAQ}}', faq_block()).replace('{{FAQ_SHORT}}', faq_block(3))
    # Composite artwork has a single accessible description. Remove the decorative
    # tagline obscured by the overlapping identity card; do not leave clipped text.
    body = body.replace('<div class="hero-art" aria-label=', '<div class="hero-art" role="img" aria-label=')
    body = body.replace('<p class="mock-caption">Ruang yang baik<br>dimulai dari cerita.</p>', '')
    return f'''<!doctype html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{esc(title)} | WebMerek</title>
<meta name="description" content="{esc(description)}">
<meta name="robots" content="{'index, follow' if not preview and config['allowIndexing'] else 'noindex, nofollow'}">
<meta name="theme-color" content="#f5f2eb">
<meta name="referrer" content="strict-origin-when-cross-origin">
<meta property="og:type" content="website">
<meta property="og:locale" content="id_ID">
<meta property="og:site_name" content="WebMerek">
<meta property="og:title" content="{esc(title)} | WebMerek">
<meta property="og:description" content="{esc(description)}">
<meta name="twitter:card" content="summary_large_image">
{extra}<link rel="icon" href="assets/mark.svg" type="image/svg+xml">
<link rel="stylesheet" href="assets/site.css">
<script src="assets/config.js" defer></script>
<script src="assets/site.js" defer></script>
</head>
<body>
<a class="skip" href="#main">Lewati ke konten</a>
<div class="notice"><div class="wrap notice-inner"><span>{status}</span><a href="{'tentang.html' if preview else 'kontak.html'}">{'Tentang proyek ini' if preview else 'Mulai percakapan'} <span aria-hidden="true">↗</span></a></div></div>
<header class="header"><div class="wrap nav-shell">
<a class="brand" href="index.html" aria-label="WebMerek, beranda"><img src="assets/mark.svg" width="34" height="34" alt=""><span>webmerek<span class="brand-dot">.</span></span></a>
<button class="menu-toggle" type="button" aria-expanded="false" aria-controls="main-nav" hidden>Menu <span aria-hidden="true">☰</span></button>
<nav id="main-nav" class="main-nav" aria-label="Navigasi utama">{nav}<a class="button button-small" href="kontak.html">Mulai dengan brief <span aria-hidden="true">↗</span></a></nav>
</div></header>
<main id="main" tabindex="-1">{body}</main>
<footer class="footer"><div class="wrap"><div class="footer-top"><div><p class="eyebrow">WEBMEREK / STUDIO INDEPENDEN</p><p class="footer-statement">Biar kualitasnya<br><em>terlihat.</em></p><p>Strategi, identitas, dan website.<br>Jelas dari awal. Milik Anda di akhir.</p></div><div class="footer-links"><div><h2>Jelajahi</h2><a href="layanan.html">Layanan</a><a href="paket.html">Paket & harga</a><a href="karya.html">Karya konsep</a><a href="proses.html">Proses kerja</a></div><div><h2>Kenali kami</h2><a href="tentang.html">Tentang WebMerek</a><a href="insight.html">Insight</a><a href="cek-merek.html">Cek mandiri merek</a><a href="faq.html">Pertanyaan umum</a><a href="kontak.html">Brief & kontak</a></div></div></div><div class="footer-bottom"><p>© 2026 WebMerek. {'Konsep bisnis independen dalam tahap prapeluncuran.' if preview else esc(config['operatorName']) + '.'}</p><a href="privasi.html">Privasi</a><a href="ketentuan.html">Ketentuan</a></div></div></footer>
</body>
</html>
'''


def outputs(config: dict) -> dict[str, str]:
    result = {p['slug']: shell(p, config) for p in PAGES}
    client = {k: config[k] for k in ('name', 'mode', 'whatsapp', 'email', 'contactVerified')}
    result['assets/config.js'] = '// Generated from site.json. Never put secrets in this public file.\nwindow.WEBMEREK = Object.freeze(' + json.dumps(client, ensure_ascii=False, indent=2) + ');\n'
    live = config['mode'] == 'live' and config['allowIndexing']
    base = config['publicBaseUrl'].rstrip('/')
    result['robots.txt'] = 'User-agent: *\n' + ('Allow: /\nSitemap: ' + base + '/sitemap.xml\n' if live else 'Disallow: /\n')
    urls = ''.join(f'<url><loc>{esc(base)}/{esc(p["slug"])}</loc></url>\n' for p in PAGES) if live else ''
    result['sitemap.xml'] = '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' + urls + '</urlset>\n'
    result['generated-manifest.json'] = json.dumps({'pages': [p['slug'] for p in PAGES], 'files': sorted(result)}, indent=2) + '\n'
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    config = json.loads((ROOT / 'site.json').read_text())
    validate_config(config)
    changed = []
    for name, content in outputs(config).items():
        destination = ROOT / name
        if not destination.exists() or destination.read_text() != content:
            changed.append(name)
            if not args.check:
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_text(content)
    if args.check and changed:
        print('Stale generated files: ' + ', '.join(changed), file=sys.stderr)
        return 1
    print(f'{len(PAGES)} pages; ' + ('deterministic output verified' if args.check else f'{len(changed)} generated files updated'))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
