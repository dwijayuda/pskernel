# M3+B exact-run evidence reconciliation

The e937461d work state excludes misattributed decoded logs. Before changing
recursor correspondence or reporting runtime qualification, the read-only
`psc0-m3-evidence-inspection.yml` checks source run39121411720, compiler/test
SHA d0146eaf1758b27cd7c8c29a75524f5021f8145d, artifact12134487916,
metadata size2756338 and independently pinned archive SHA256
6e6613f98717963782b73883b5e1f9a5be792c7af26405395fab38fb7e4985ff.
It rehashes downloaded bytes and checks internal source-sha files in GitHub
Linux CI. No local checkout/build is used and no archived program is executed.

The inspector reads only inert archive contents, bounds archive size, rejects
duplicate/noncanonical paths, does not extract files, and removes authorization
on cross-host redirects. Output contains run and inspection identities plus
per-file digests and explicitly labelled excerpts. Required evidence includes
recursor diagnostics, selected source checks and all twelve focused backend
logs. Missing evidence is an error, not an inferred pass. Archive authentication
alone does not establish semantic correctness; the excerpts must match the
committed observer and source fixtures before qualification claims.

This audit adds no compiler feature, selected asset, acceptance bypass or main
promotion. Its push trigger is limited to its own workflow file. The existing
M3 foundation preparation and all five integration gates are unchanged.
