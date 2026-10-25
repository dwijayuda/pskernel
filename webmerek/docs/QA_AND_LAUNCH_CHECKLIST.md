# Qualification and launch checklist

This file defines gates, not a declaration that all gates have passed. Read the matching GitHub Actions run for actual execution evidence and source revision. Browser emulation and automated accessibility checks do not establish full WCAG conformance or real-device behavior [T2, T3].

## Technical qualification

- All generated HTML is committed and deterministic against `content/pages.py` and `site.json`.
- Strict HTML parsing, unique IDs, valid local links/fragments/assets, language/title/description/viewport and one main heading per page.
- JavaScript syntax and package/math integrity.
- No unintended external requests, console errors, failed assets or horizontal overflow in tested configurations.
- Keyboard navigation, FAQ disclosure, mobile menu/Escape, required-field validation and no-JavaScript fallbacks.
- Brief generation displays input literally, downloads correct text, never claims transmission, and invalidates stale output.
- Preview has no contacts, no data submission, no browser storage and no accidental indexing.
- Assessment scores and priorities are deterministic and explicitly non-scientific.
- Browser/axe results and screenshots retained as evidence. Human visual review must be separately recorded.
- Final source diff touches only `webmerek/**` and the independently scoped workflow.
- Packaged website/project hashes and `SOURCE_REVISION.txt` match the tested committed source.

## Browser matrix and limitations

Chromium desktop, Chromium Pixel 7 emulation, Firefox desktop and WebKit iPhone 13 emulation. Also a 320px layout check and reduced-motion check. No physical device lab, screen-reader user study, production hosting check or live WhatsApp round trip is implied. Performance file budgets are checked; Lighthouse/Core Web Vitals scores are not claimed.

## Launch blockers requiring explicit owner decisions

1. Legal operator and actual working contacts verified; no invented details.
2. WebMerek trademark/domain checks and asset licenses completed [L2].
3. Actual staffing, delivery capacity, pricing and available start dates approved.
4. Contract, invoicing/tax, privacy roles, retention, rights contact and processors reviewed [L1, L3].
5. Commercial hosting terms, security/HTTPS, logging and backup ownership reviewed; no automatic commercial GitHub Pages use [T1].
6. All hard-coded prelaunch labels, FAQs, legal text and social artwork reviewed together with `site.json`.
7. Production-specific tests added for canonical URLs, indexing, genuine contact links and explicit sharing consent. Existing preview-only assertions must not simply be deleted without replacements.
8. Owner explicitly authorizes public deployment and inquiry acceptance. No payment processor is part of this site.

## Honest release vocabulary

“Implemented” means code/content exists. “Tested” names actual checks and revision. “Visually reviewed” names screenshots actually inspected. “Published” requires an actual deployment. “Commercially validated” requires evidence from real buyers and delivery. None of these statuses is inferred from another.
