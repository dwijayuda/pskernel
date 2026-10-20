# PHP runtime ownership

The authoritative helper catalogue is `../src/Ps/BackendPhp/Runtime.lean`.
The native compiler embeds its readable snippets and emits the selected transitive
helper closure. Generated PHP declares ext-gmp only when needed; no separate
ProofScript PHP runtime package is required.
