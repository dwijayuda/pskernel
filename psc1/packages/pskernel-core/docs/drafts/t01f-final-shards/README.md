# Saved T01F final qualification drafts

These files were preserved when the user requested a GPT-6.1 Sol / High
continuation prompt. They are **unexecuted drafts**, not active workflows or
qualification evidence. The handoff commit uses `[skip ci]`. Production Lean
remains19fb; the last tested native singleton harness is a368. Read
[the continuation](../../AI_CONTINUATION_PROMPT.md) and
[checkpoint receipt](../../../evidence/2026-10-22-t01f-handoff-checkpoint.json).

## Intended destinations

| Saved file | Intended repository destination |
| --- | --- |
| psc1-pskernel-expr-v2-integration.yml | .github/workflows/psc1-pskernel-expr-v2-integration.yml |
| psc1-pskernel-core-correctness.yml | .github/workflows/psc1-pskernel-core-correctness.yml |
| pskernel-t01f-shards.mjs | psc1/scripts/pskernel-t01f-shards.mjs |
| paired-owner-job.fragment.yml | Review reference; already included in the integration draft |

Do not install blindly. Fetch live branches and reconcile concurrent edits.
These full workflow drafts are the newest sharded versions; do not overwrite
them with older monolithic preparations. The drafts retain the previous
source/native/generated/provider/proof/performance structure by intent, but
static review is not execution evidence. Finish helper copy/spawn/log and
source/run/attempt/provider provenance review before activation.

The strict sample selector is already installed in the existing generated
String runner, and the focused artifact-reuse workflow is already installed
at `.github/workflows/psc1-pskernel-t01f-focus.yml`. Both are unexecuted at this
handoff. First run its authenticated19fb mixed-index5 and retained-controls
preflight. Then activate a reconciled helper/final workflows at one exact
coherent source and execute both complete six-case aggregates plus all old
gates, research, full performance and unchanged193-case Arena. Disable the
focused push trigger for that full-suite push to avoid duplicate work.

Three other existing research/Arena/profile workflows still need live review
and only the necessary work-branch trigger addition; their prepared edits
were not preserved before a tool-session reset. Do not alter their job bodies,
Arena limits or body-hash policy. Their exact paths are in the continuation.

## Static file digests

- psc1-pskernel-expr-v2-integration.yml: 91967 bytes; SHA256 74b974f6f3b0ad398a97ba3e72a935cc37c3e5616b33b94745f727ee988daea5
- psc1-pskernel-core-correctness.yml: 43193 bytes; SHA256 b9c124bc49625d675a2a8f3a385577b633cd63181c54af4fd4af2d1f27767114
- pskernel-t01f-shards.mjs: 15142 bytes; SHA256 1b8a302fcf22a573ee3b005578dd4930e6e773a9b803ec19c32f7f45bd3161d8
- paired-owner-job.fragment.yml: 16984 bytes; SHA256 34cacbc1b11b907b94771460086b004a9cdee60231fdfb436b9107129c2f0fb8

See [INTEGRATION_NOTES.md](INTEGRATION_NOTES.md) for the intended shard contract.
Its original preparation note refers to scratch-only work at drafting time;
this handoff now persists those same bytes in the repository. Neither that
persistence nor prior static syntax review is a CI PASS.
