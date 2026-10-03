<a id="release-notes"></a>

# ProofScript — Release Notes

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

These articles are the mirrored Lean release notes, not ProofScript releases. They document historical syntax, APIs, implementations and changes. The page named v4.34.0 in this mirror still identifies itself as rc2. Native source at the selected stable commit overrides stale details for a current ProofScript conformance claim. Historical examples remain native and are not silently modernized.

**Compiler and coverage boundary.** The stable delta note explicitly excludes the old native-reduction kernel hooks. Upgrading the pin requires a new reference/profile review and regenerated evidence.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [releases/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/releases/index.html). Source Git blob: `bb29136f78e7455bee8b800a42c0a58022b8af56`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## Release Notes

This section provides release notes about recent versions of Lean. When updating to a new version, please read the corresponding release notes. They may contain advice that will help you understand the differences with the previous version and upgrade your projects.

1. [Lean 4.34.0-rc2 (2026-08-21)](v4.34.0/index.md#release-v4___34___0)
2. [Lean 4.33.1 (2026-08-21)](v4.33.1/index.md#release-v4___33___1)
3. [Lean 4.33.0 (2026-08-10)](v4.33.0/index.md#release-v4___33___0)
4. [Lean 4.32.2 (2026-07-28)](v4.32.2/index.md#release-v4___32___2)
5. [Lean 4.32.1 (2026-07-22)](v4.32.1/index.md#release-v4___32___1)
6. [Lean 4.32.0 (2026-07-13)](v4.32.0/index.md#release-v4___32___0)
7. [Lean 4.31.0 (2026-06-13)](v4.31.0/index.md#release-v4___31___0)
8. [Lean 4.30.0 (2026-05-26)](v4.30.0/index.md#release-v4___30___0)
9. [Lean 4.29.1 (2026-04-14)](v4.29.1/index.md#release-v4___29___1)
10. [Lean 4.29.0 (2026-03-27)](v4.29.0/index.md#release-v4___29___0)
11. [Lean 4.28.1 (2026-04-14)](v4.28.1/index.md#release-v4___28___1)
12. [Lean 4.28.0 (2026-02-17)](v4.28.0/index.md#release-v4___28___0)
13. [Lean 4.27.0 (2026-01-24)](v4.27.0/index.md#release-v4___27___0)
14. [Lean 4.26.0 (2025-12-13)](v4.26.0/index.md#release-v4___26___0)
15. [Lean 4.25.1 (2025-11-18)](v4.25.1/index.md#release-v4___25___1)
16. [Lean 4.25.0 (2025-11-14)](v4.25.0/index.md#release-v4___25___0)
17. [Lean 4.24.0 (2025-10-14)](v4.24.0/index.md#release-v4___24___0)
18. [Lean 4.23.0 (2025-09-15)](v4.23.0/index.md#release-v4___23___0)
19. [Lean 4.22.0 (2025-08-14)](v4.22.0/index.md#release-v4___22___0)
20. [Lean 4.21.0 (2025-06-30)](v4.21.0/index.md#release-v4___21___0)
21. [Lean 4.20.0 (2025-06-02)](v4.20.0/index.md#release-v4___20___0)
22. [Lean 4.19.0 (2025-05-01)](v4.19.0/index.md#release-v4___19___0)
23. [Lean 4.18.0 (2025-04-02)](v4.18.0/index.md#release-v4___18___0)
24. [Lean 4.17.0 (2025-03-03)](v4.17.0/index.md#release-v4___17___0)
25. [Lean 4.16.0 (2025-02-03)](v4.16.0/index.md#release-v4___16___0)
26. [Lean 4.15.0 (2025-01-04)](v4.15.0/index.md#release-v4___15___0)
27. [Lean 4.14.0 (2024-12-02)](v4.14.0/index.md#release-v4___14___0)
28. [Lean 4.13.0 (2024-11-01)](v4.13.0/index.md#release-v4___13___0)
29. [Lean 4.12.0 (2024-10-01)](v4.12.0/index.md#release-v4___12___0)
30. [Lean 4.11.0 (2024-09-02)](v4.11.0/index.md#release-v4___11___0)
31. [Lean 4.10.0 (2024-07-31)](v4.10.0/index.md#release-v4___10___0)
32. [Lean 4.9.0 (2024-07-01)](v4.9.0/index.md#release-v4___9___0)
33. [Lean 4.8.0 (2024-06-05)](v4.8.0/index.md#release-v4___8___0)
34. [Lean 4.7.0 (2024-04-03)](v4.7.0/index.md#release-v4___7___0)
35. [Lean 4.6.0 (2024-02-29)](v4.6.0/index.md#release-v4___6___0)
36. [Lean 4.5.0 (2024-02-01)](v4.5.0/index.md#release-v4___5___0)
37. [Lean 4.4.0 (2023-12-31)](v4.4.0/index.md#release-v4___4___0)
38. [Lean 4.3.0 (2023-11-30)](v4.3.0/index.md#release-v4___3___0)
39. [Lean 4.2.0 (2023-10-31)](v4.2.0/index.md#release-v4___2___0)
40. [Lean 4.1.0 (2023-09-26)](v4.1.0/index.md#release-v4___1___0)
41. [Lean 4.0.0 (2023-09-08)](v4.0.0/index.md#release-v4___0___0)
42. [Lean 4.0.0-m5 (2022-08-22)](v4.0.0-m5/index.md#release-v4___0___0-m5)
43. [Lean 4.0.0-m4 (2022-03-27)](v4.0.0-m4/index.md#release-v4___0___0-m4)
44. [Lean 4.0.0-m3 (2022-01-31)](v4.0.0-m3/index.md#release-v4___0___0-m3)
45. [Lean 4.0.0-m2 (2021-03-02)](v4.0.0-m2/index.md#release-v4___0___0-m2)
46. [Lean 4.0.0-m1 (2021-01-04)](v4.0.0-m1/index.md#release-v4___0___0-m1)
