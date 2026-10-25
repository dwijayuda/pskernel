# WebMerek — Biar kualitasnya terlihat.

An independently branded Indonesian business concept, research pack, and working static website. Built in isolation from the ProofScript/compiler/kernel projects in this repository.

**Status: prelaunch, not accepting orders.** The business identity, contact details, prices, capacity, trademark clearance, and production hosting still need owner validation. No real clients, testimonials, awards, or business outcomes are claimed. Research accessed **25 October 2026**.

## What is here

- Fifteen complete Bahasa Indonesia pages: home, services, packages, concept work, about, process, insight index, three articles, brief/contact, brand self-check, FAQ, privacy, and terms.
- Original editorial visual identity, CSS-built concept artwork, responsive navigation, accessible native disclosure controls, reduced-motion styling, and print styles.
- Local-only brief builder with text download and clipboard fallback; local-only five-question self-check. No analytics, cookies, embedded third-party resources, backend, or automatic form transmission.
- Research on Flourish Online, ten Indonesian competitors, a proposed business model, explicit unit economics, operating documents, and launch experiments.
- Independently scoped Linux GitHub Actions verification. No compiler packages, root package manifests, or existing workflows are changed.

## View the website

After the materialization workflow has committed its generated outputs, open `webmerek/index.html`, or serve the folder with a static server:

```sh
python3 -m http.server 8080 --directory webmerek
```

Then open `http://localhost:8080/`. This is an optional instruction for the owner, not a claim that local builds were run during development. The delivered website ZIP has `index.html` at its root and requires no package installation or build to view. HTTP preview is preferable for consistent clipboard/download behavior.

The full project ZIP includes sources and documents. Do not upload that full ZIP to a public web host: use the website-only ZIP. The source repository is already public; never add client information, credentials, or secrets.

## Repository isolation

Development branch: `webmerek/indonesia-launch-20261025`.
Base: `7d3e220e495f5d82178a3e66f191255045862bd5`.
Only `webmerek/**` and `.github/workflows/webmerek-quality.yml` belong to this assignment. No main merge, force push, package publication, or live deployment is authorized by this implementation.

## Edit and generate

```text
site.json                     Central prices, contact configuration and launch flags
content/pages.py              Original page copy and shared FAQ content
assets/site.css               Responsive design system
assets/site.js                Progressive enhancement; no runtime dependencies
assets/mark.svg / og.svg       Original brand assets
scripts/render.py             Deterministic HTML/config/robots/sitemap generation
scripts/check.py              Strict HTML, links, metadata, budgets and scope checks
scripts/finance.py            Reproducible scenario arithmetic
scripts/package.py            Website/project ZIPs and revision hashes
qa/                           Pinned browser and accessibility test tooling
.gitignore                    Excludes installed dependencies and QA artifacts
```

Generated HTML is committed so the folder is a real static site, not merely a generator. Edit sources rather than generated pages. GitHub Actions renders and commits the generated output with a non-force branch-head check, then tests that **actual generated commit**. The run-trigger SHA may therefore differ from the tested source SHA. The run summary and packaged `SOURCE_REVISION.txt` identify the tested commit. A dependency lockfile is created on the first run and retained; subsequent runs use `npm ci`.

## Verification and evidence

The `WebMerek quality` workflow runs only on `webmerek/**` branches for this project's paths. It checks HTML parsing, links and fragments, JavaScript syntax, deterministic output, financial arithmetic, scope isolation, browser interactions, no-JavaScript behavior, and automated accessibility in Chromium, Firefox and WebKit configurations. It captures desktop/mobile screenshots and exports evidence, report and ZIP artifacts. Automated checks do **not** establish full WCAG compliance, real-device coverage, business viability, or legal compliance.

Before treating any revision as qualified, inspect the matching run's conclusion and exact tested SHA. A workflow file existing in the repository is not itself evidence of a pass. See [QA and launch checklist](docs/QA_AND_LAUNCH_CHECKLIST.md).

## Contacts and launch protection

`site.json` intentionally has empty `whatsapp`, `email`, `operatorName` and `publicBaseUrl`. Do not insert example phone numbers or invented addresses. In preview mode the brief stays in the browser; download and copy work, but sending is unavailable. No order or payment is created.

A technical live-mode guard requires verified identity/contact and owner/legal/offer approvals. **Changing flags alone is not a launch procedure.** Privacy, terms, FAQ, price status, contact copy, search indexing, social artwork, QA expectations and hosting policies must be reviewed together. The present QA lane intentionally asserts preview mode and blank contacts. Establish a separately reviewed production qualification before accepting inquiries.

Use the actual HTTPS origin plus any deployment subpath for `publicBaseUrl`; there is no assumed `webmerek.com` or other registered domain. Canonical URLs, an absolute Open Graph PNG URL and a sitemap are emitted only when configured appropriately. `noindex` is an indexing instruction, not access control.

## Hosting and publication

No public website has been deployed by this project. GitHub Pages is **not selected as the commercial production host**: its published limits exclude using it as free hosting for an online business or a site primarily facilitating commercial transactions [T1]. A noncommercial educational preview would need separate policy review and authorization; this repository does not automatically publish even that.

After launch approval, select a static hosting provider whose current terms permit the intended commercial use, assess processor/logging arrangements, configure HTTPS and the verified domain, and deploy **only** the website artifact. Domain/hosting accounts should belong to the operator, not be inferred from the GitHub account. No hosting purchase or third-party account was created.

## Research map

Start with [Business strategy](docs/BUSINESS_STRATEGY.md), [Flourish analysis](docs/FLOURISH_DEEP_RESEARCH.md), [Competitor comparison](docs/COMPETITOR_ANALYSIS.md), [Pricing](docs/BUSINESS_MODEL_AND_PRICING.md), and [90-day plan](docs/90_DAY_LAUNCH_PLAN.md). Evidence IDs such as [F1], [M2] and [T1] resolve in [Sources](docs/SOURCES.md). Proposed prices and projections are assumptions, not market facts.
