# WebMerek work state

Date: 25 October 2026. Business adaptation and static website only; no ProofScript/kernel changes.

## Scope and branch

Branch `webmerek/indonesia-launch-20261025`, base main `7d3e220e495f5d82178a3e66f191255045862bd5`. Writes limited to `webmerek/**` and `.github/workflows/webmerek-quality.yml`. No main merge, force push, commercial launch, outreach or spending.

## Implemented

Fifteen complete Bahasa Indonesia pages, original identity and fictional concept artwork, local-only brief builder and self-check, deterministic committed HTML, research on Flourish and ten Indonesian competitors, pricing and financial hypotheses, strategy/operations/launch documents, proposal/contract draft, and isolated Linux browser/accessibility qualification. The project archive includes the standalone workflow; the website archive includes public runtime files only.

## Qualification record correction

Run https://github.com/dwijayuda/pskernel/actions/runs/40173190119 tested generated commit `f34b3ae1d6f7d344020b450bca2909eb70714e4f` (trigger `e547a371e7610b536fe62598e24db2453c6c52dd`). Strict HTML/link/scope, deterministic rendering, JavaScript syntax and financial arithmetic passed.

**The downloaded machine-readable qa/results.json is authoritative: 82 passed, 6 failed, not the previously recorded 84/4.** Two desktop homepage contrast failures involved the decorative caption obscured by the overlapping identity card. Four no-JavaScript failures were an unsuitable disabled assertion on the fieldset wrapper, while the disabled attribute itself was present. No ARIA-label failure was reported in that artifact; the earlier description was incorrect.

Corrections: remove the obscured decorative caption; give the composite artwork a single image role; restrict the compact menu button to mobile widths; clear stale brief output on edits; assert the no-JS fieldset attribute plus all seven actual disabled controls. No accessibility rule is suppressed and no failing test is removed. The next run must qualify the changed source; success is not assumed.

## Evidence rule

Read the matching run conclusion, actual tested SHA, browser results and artifact SOURCE_REVISION.txt. Trigger SHA can differ from the generated/tested commit. Packaging runs only after all required checks pass. Screenshots require actual visual review; automated capture alone is not review. Live configuration/contact behavior needs separate production qualification.

## Business and launch status

Branding-first productized service hypothesis for established consultants/training providers. Tagline: “Biar kualitasnya terlihat.” Prices, economics and capacity remain proposals. No fake clients, outcomes, contacts, addresses or credentials.

Before commercial use: verify operator/contact, trademark/domain, capacity, pricing, legal/tax/privacy details, suitable commercial hosting and explicit owner publication approval. Preview does not send inquiries or accept payment. See docs/QA_AND_LAUNCH_CHECKLIST.md and docs/AI_CONTINUATION_PROMPT.md.
