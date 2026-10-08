import { validateCompilerExecutionPolicy } from './compiler-execution-policy.mjs';
import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const authority = JSON.parse(
  await readFile(path.join(root, "language-authority.json"), "utf8"),
);

if (authority.schemaVersion !== 2) {
  throw new Error(
    `PSCV_LANGUAGE_AUTHORITY_SCHEMA: expected 2, got ${authority.schemaVersion}`,
  );
}

const bootstrapToolchain = (await readFile(path.join(root, "lean-toolchain"), "utf8")).trim();
if (!authority.bootstrapLean ||
    bootstrapToolchain !== "leanprover/lean4:v" + authority.bootstrapLean.version ||
    !/^[a-f0-9]{40}$/.test(authority.bootstrapLean.commit)) {
  throw new Error("PSCV_LANGUAGE_AUTHORITY_BOOTSTRAP_PIN");
}

const document = await readFile(path.join(root, authority.document));
const actualSha = createHash("sha256").update(document).digest("hex");
if (actualSha !== authority.sha256) {
  throw new Error(
    `PSCV_LANGUAGE_AUTHORITY_HASH: expected ${authority.sha256}, got ${actualSha}`,
  );
}

const text = document.toString("utf8");
for (const value of [
  authority.languageEdition,
  authority.sourceProfile,
  authority.requiredLanguageProfile,
  authority.standardLanguageProfile,
  authority.leanCompatibilityProfile,
  authority.verificationProfile,
  authority.closedAssurancePolicy,
  authority.boundaryAssurancePolicy,
  authority.verificationSemantics,
  authority.certificatePolicy,
  authority.currentCompilerMilestone,
  authority.targetCompilerConformance,
  authority.normativeLeanVersion,
  authority.normativeLeanCommit,
]) {
  if (!text.includes(value)) {
    throw new Error(`PSCV_LANGUAGE_AUTHORITY_IDENTITY_MISSING: ${value}`);
  }
}

const psconfig = JSON.parse(
  await readFile(path.join(root, "psconfig.json"), "utf8"),
);

const executionPolicy = JSON.parse(await readFile(path.join(root, 'contracts/compiler/COMPILER_EXECUTION_POLICY_V1.json'), 'utf8'));
validateCompilerExecutionPolicy(executionPolicy, { languageAuthority: authority, config: psconfig, toolchain: bootstrapToolchain });

// Host implementation syntax is independent of accepted program semantics.
// Keep the inherited compiler capability milestone until PSCV conformance is
// implemented; choosing a hosted compiler is not a profile promotion.
for (const [key, expected] of [
  ["languageEdition", authority.languageEdition],
  ["sourceProfile", authority.sourceProfile],
  ["requiredLanguageProfile", authority.requiredLanguageProfile],
  ["standardLanguageProfile", authority.standardLanguageProfile],
  ["implementationProfile", authority.implementationProfile],
]) {
  if (psconfig[key] !== expected) {
    throw new Error(
      `PSCV_LANGUAGE_AUTHORITY_CONFIG_DRIFT: ${key} expected ${expected}, got ${psconfig[key]}`,
    );
  }
}

if ("acceptedLanguageProfile" in psconfig) {
  throw new Error(
    "PSCV_LANGUAGE_AUTHORITY_LEGACY_PROFILE: acceptedLanguageProfile is retired",
  );
}
if (JSON.stringify(psconfig).includes("PSC2-bootstrap")) {
  throw new Error(
    "PSCV_LANGUAGE_AUTHORITY_LEGACY_PROFILE: PSC2-bootstrap is retired",
  );
}

process.stdout.write(
  [
    "PSCV_LANGUAGE_AUTHORITY: PASS",
    `document=${authority.document}`,
    `implementationProfile=${authority.implementationProfile}`,
    "selfHostingRequired=false",
    `sha256=${actualSha}`,
    `edition=${authority.languageEdition}`,
    `baseProfile=${authority.requiredLanguageProfile}`,
    `verificationProfile=${authority.verificationProfile}`,
    `currentCompiler=${authority.currentCompilerMilestone}`,
    `targetCompiler=${authority.targetCompilerConformance}`,
    `normativeLean=${authority.normativeLeanVersion}@${authority.normativeLeanCommit}`,
  ].join("\n") + "\n",
);
