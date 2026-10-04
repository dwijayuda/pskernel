import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const authority = JSON.parse(
  await readFile(path.join(root, "language-authority.json"), "utf8"),
);
const document = await readFile(path.join(root, authority.document));
const actualSha = createHash("sha256").update(document).digest("hex");
if (actualSha !== authority.sha256) {
  throw new Error(
    `PSC2_LANGUAGE_AUTHORITY_HASH: expected ${authority.sha256}, got ${actualSha}`,
  );
}

const text = document.toString("utf8");
for (const value of [
  authority.languageEdition,
  authority.sourceProfile,
  authority.requiredLanguageProfile,
  authority.standardLanguageProfile,
  authority.javaScriptPlatformProfile,
  authority.leanCommit,
]) {
  if (!text.includes(value)) {
    throw new Error(`PSC2_LANGUAGE_AUTHORITY_IDENTITY_MISSING: ${value}`);
  }
}

const psconfig = JSON.parse(
  await readFile(path.join(root, "psconfig.json"), "utf8"),
);
for (const [key, expected] of [
  ["languageEdition", authority.languageEdition],
  ["sourceProfile", authority.sourceProfile],
  ["requiredLanguageProfile", authority.requiredLanguageProfile],
  ["standardLanguageProfile", authority.standardLanguageProfile],
]) {
  if (psconfig[key] !== expected) {
    throw new Error(
      `PSC2_LANGUAGE_AUTHORITY_CONFIG_DRIFT: ${key} expected ${expected}, got ${psconfig[key]}`,
    );
  }
}
if ("acceptedLanguageProfile" in psconfig) {
  throw new Error(
    "PSC2_LANGUAGE_AUTHORITY_LEGACY_PROFILE: acceptedLanguageProfile is retired",
  );
}
if (JSON.stringify(psconfig).includes("PSC2-bootstrap")) {
  throw new Error("PSC2_LANGUAGE_AUTHORITY_LEGACY_PROFILE: PSC2-bootstrap is retired");
}

process.stdout.write(
  [
    "PSC2_LANGUAGE_AUTHORITY: PASS",
    `document=${authority.document}`,
    `sha256=${actualSha}`,
    `edition=${authority.languageEdition}`,
    `standard=${authority.standardLanguageProfile}`,
    `compilerConformance=${authority.compilerConformance}`,
  ].join("\n") + "\n",
);
