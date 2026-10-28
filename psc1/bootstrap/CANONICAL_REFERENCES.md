# Canonical ProofScript and bootstrap references

The authored portable compiler and ordinary standard-library modules are the `.ps` owners listed in [`CANONICAL_SOURCES.json`](../CANONICAL_SOURCES.json). The unified compiler project is [`compiler.project.json`](../compiler.project.json).

Paired `.lean` files remain at their existing module paths as immutable checked bootstrap references. Edit the ProofScript owner and use the checked reference-refresh workflow; do not edit a reference independently. Untouched reference bytes remain unchanged.

The [ownership and maintenance guide](../docs/CANONICAL_SOURCE_OWNERSHIP.md) explains the 164 portable owners, explicit native exceptions, package source views, fresh correspondence checks and CI-only reference refresh. [`CANONICAL_BASELINE.json`](CANONICAL_BASELINE.json) pins the exact initial promotion manifest for transition checks.

Every new build still requires fresh independent admission and strict IR checks. Ownership manifests and correspondence receipts grant no admission authority.
