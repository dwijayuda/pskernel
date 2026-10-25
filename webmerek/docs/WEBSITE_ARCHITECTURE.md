# Website architecture and implementation decisions

## Runtime

Fifteen static HTML pages, local CSS, small vanilla JavaScript and original SVG/PNG assets. No framework, database, hosted form provider, analytics, external font or runtime package dependency. Python is used only to generate checked-in HTML in GitHub Actions; the delivered website needs no Python or Node server.

`site.json` owns package data and contact/launch configuration. `content/pages.py` owns page copy. `scripts/render.py` provides a common shell, packages, FAQ, metadata and manifest; `--check` detects stale committed HTML. Assets remain editable plain files. This keeps business content, presentation and interaction understandable without adding an application framework to the compiler repository.

## Information architecture

Home establishes the problem and routes to services/packages. Services explain scope and exclusions. Packages clarify proposed investment. Concept work demonstrates design thinking without fake client proof. About describes the independent prelaunch status. Process explains readiness and handover. Three insight articles support informed decisions. FAQ answers objections. Contact builds a brief. The self-check provides local feedback. Privacy/terms describe actual current behavior and limits.

## Progressive enhancement

Navigation and content work without JavaScript. The mobile menu uses `aria-expanded`, Escape handling and visible focus. FAQs use native `details/summary`. Forms begin disabled and are enabled only after their JavaScript listeners exist, preventing accidental submission when scripts fail. A downloadable blank brief remains available without JavaScript.

The brief builder uses `textContent`, local memory and Blob downloads. It does not transmit data, append personal details to URLs, set cookies or write browser storage. Clipboard denial has a manual-selection/download fallback. Editing inputs invalidates the prior generated brief. The self-check is explicitly a simple equal-weight reflection aid, not a scientific score.

## Contact boundary

Empty verified contacts are intentional. Preview mode never presents a fake phone number, “sent” message or functioning-looking dead mail link. In a separately reviewed live mode, an explicit consent control can open a prefilled WhatsApp message after review; opening WhatsApp is not proof the user sent it. The third-party destination and user action are disclosed. The current qualification does not constitute a live-contact integration test.

## Search and social

Each page has a unique title/description, viewport, language and Open Graph text metadata. Preview pages are `noindex, nofollow` and the robots file disallows crawling. Canonical URLs, absolute social-image URLs, WebSite structured data and a populated sitemap require a verified real deployment base. No invented domain, address, LocalBusiness location or review rating is emitted.

The original social SVG is rasterized in GitHub Actions to a 1200×630 PNG. Public deployment needs a fresh review of its prelaunch wording. Noindex is not access control; the repository is public.

## Design/performance

System sans/serif typography, semantic structure, purposeful contrast, responsive grids and a mobile-first reading order. Decorative browser/brand mockups are original CSS illustrations rather than third-party media downloads. Reduced-motion and print styles are included.

Static budgets are checked for individual HTML, CSS, JavaScript and social artwork. These budgets are not Lighthouse or real-user performance scores. No Lighthouse score is claimed unless an actual measurement is added and recorded.

## Verification model

Linux Actions installs isolated pinned QA tooling, renders outputs, commits generated files after a remote-head check, then tests that committed source. Checks cover strict HTML parsing, asset/link/fragment integrity, unique IDs, metadata, script syntax, source scope, deterministic rendering, arithmetic, four browser/device configurations, no-JavaScript behavior, form safety, keyboard actions, 320px overflow and reduced motion. Axe checks provide automated accessibility findings only [T2–T5].

Run-trigger and tested-source SHA can differ because generated output is committed inside the run. The summary and archive revision file record the actual tested commit. Browser reports and screenshots are exported. Human screenshot inspection must be reported separately from screenshot generation.

## Hosting decision

No deployment workflow or account is activated. GitHub Pages is not chosen for a commercial agency site because its published usage rules restrict such hosting [T1]. A commercial-compatible static host can serve the website artifact after separate approval and policy/privacy review. Relative internal links support a subpath without rebuilding the site around a specific provider.

## Known production gaps

Operator/contact verification, trademark/domain review, legal/tax review, real client proof, validated prices/capacity, hosting/log disclosures, production indexing and live-contact tests. Hard-coded prelaunch wording must be reviewed page by page; flipping configuration flags alone is insufficient. No CMS, payments, scheduling service, customer database or business email inbox has been created.
