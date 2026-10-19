// Stable grammar identity shared by current tooling and selected-seed recovery.
// Keep this data module independent of evolving conformance fixtures.
export const sh1GrammarProfile = Object.freeze({
  edition: 'ps-0.9-r3',
  mode: 'new-only',
  support: 'bounded-selfhost-subset',
  referenceSha256: '4c02626fd0b991e8526c64b65f4ffb66b9ce7b688298e82fb0309802a263db71',
  fullStandardConformance: false,
  fullPscvConformance: false,
});
