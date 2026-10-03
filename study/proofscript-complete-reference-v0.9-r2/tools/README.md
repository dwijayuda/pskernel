# Collection verification

Run `node tools/verify_collection.mjs` from a Node environment. It uses only built-in Node modules. The script checks exact artifact identities, the source-coverage map, retained example edits and their inverse, and recorded native-fixture hashes/outcomes. It does not prove syntax/semantic equivalence or execute all examples.

The HTML link audit was performed separately over generated local hrefs and anchors. Its recorded result is bound by the file manifest. Article-entry navigation aliases are documented in `research/NAVIGATION_ALIASES.json`; they are not precise source-token mappings.

Native fixtures can be rerun explicitly with the pinned installed toolchain: `lean +leanprover/lean4:v4.34.0 examples/CanonicalWritingExamples.lean`. Six `Reject*.lean` files intentionally fail. Check the toolchain commit and capture results; an unqualified `lean` may select a different version. The fixtures are hand-authored canonical counterparts, not emitted PSC output.

The source adaptation procedure was: verify cached HTML Git blobs; extract article DOMs; preserve content while separating tooltip annotations, diagnostics and proof states; apply only reversible definition-keyword presentation edits in recognized simple examples; add authored ProofScript guidance; write linked Markdown/HTML; preserve diagrams/screenshots and Apache attribution; verify hashes and navigation. The document-generation helpers are not a production ProofScript parser or a general Lean-to-PSC translator.
