import { createHash } from "node:crypto";
import { buildChecked } from "./checked-build.mjs";
export { createComparatorSession } from './comparator-session.mjs';

export const comparatorV1 = Object.freeze({
  id: "psc-comparator/1",
  status: "process-isolated-prototype",
  sandbox: "required-for-paranoid-production",
});

export function comparatorChallenge({
  sourceClosureSha256,
  primary = "lean434-wasm",
  secondary = "pskernel-core",
  securityProfile = "compatibility-v1",
}) {
  if (!/^[0-9a-f]{64}$/u.test(sourceClosureSha256 ?? "")) {
    throw new Error("PSC_COMPARATOR_CHALLENGE_SOURCE_HASH");
  }
  if (primary === secondary) throw new Error("PSC_COMPARATOR_CHALLENGE_DIVERSITY");
  return Object.freeze({
    contract: comparatorV1.id,
    sourceClosureSha256,
    primary,
    secondary,
    securityProfile,
  });
}

export async function runComparatorChallenge(
  challenge,
  buildOptions,
  runChecked = buildChecked,
) {
  if (challenge?.contract !== comparatorV1.id) {
    throw new Error("PSC_COMPARATOR_CHALLENGE_CONTRACT");
  }
  const receipt = await runChecked({
    ...buildOptions,
    checkOnly: true,
    kernel: challenge.primary,
    dualCheck: challenge.secondary,
    securityProfile: challenge.securityProfile,
  });
  if (receipt.sourceClosureSha256 !== challenge.sourceClosureSha256) {
    throw new Error("PSC_COMPARATOR_SOURCE_MISMATCH");
  }
  if (receipt.dualCheck?.decision !== "accepted") {
    throw new Error("PSC_COMPARATOR_NOT_ACCEPTED");
  }
  const evidence = JSON.stringify({
    contract: comparatorV1.id,
    sourceClosureSha256: receipt.sourceClosureSha256,
    primary: receipt.provider,
    dualCheck: receipt.dualCheck,
    providerSecurity: receipt.providerSecurity,
  });
  return Object.freeze({
    contract: comparatorV1.id,
    accepted: true,
    evidenceSha256: createHash("sha256").update(evidence).digest("hex"),
    receipt,
  });
}
