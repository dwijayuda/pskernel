import assert from "node:assert/strict";
import { test } from "node:test";
import { comparatorChallenge, runComparatorChallenge } from "./comparator-v1.mjs";

const sourceHash = "a".repeat(64);

test("comparator challenge binds source and checker policy", () => {
  const challenge = comparatorChallenge({ sourceClosureSha256: sourceHash });
  assert.equal(challenge.contract, "psc-comparator/1");
  assert.equal(challenge.primary, "lean434-wasm");
  assert.equal(challenge.secondary, "pskernel-core");
});

test("comparator accepts only matching dual-accepted receipt", async () => {
  const challenge = comparatorChallenge({ sourceClosureSha256: sourceHash });
  const result = await runComparatorChallenge(challenge, { entryPath: "fixture.ps" }, async options => ({
    sourceClosureSha256: sourceHash,
    provider: { provider: "lean4-cpp" },
    providerSecurity: { profile: options.securityProfile },
    dualCheck: { decision: "accepted" },
  }));
  assert.equal(result.accepted, true);
  assert.match(result.evidenceSha256, /^[0-9a-f]{64}$/u);
});

test("comparator fails closed on source or checker disagreement", async () => {
  const challenge = comparatorChallenge({ sourceClosureSha256: sourceHash });
  await assert.rejects(
    runComparatorChallenge(challenge, {}, async () => ({
      sourceClosureSha256: "b".repeat(64),
      dualCheck: { decision: "accepted" },
    })),
    /SOURCE_MISMATCH/,
  );
  await assert.rejects(
    runComparatorChallenge(challenge, {}, async () => ({
      sourceClosureSha256: sourceHash,
      dualCheck: { decision: "rejected:0" },
    })),
    /NOT_ACCEPTED/,
  );
});
