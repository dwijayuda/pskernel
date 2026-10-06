import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));

const EXPECTED_ROOT =
  "spkf-poc-v0:sha256:fb24f3a56242051134f95ef4036d5c985f3c7d085602e738f825c96764c6afe6";
const EXPECTED_PROOF_BLOB =
  "spkf-poc-blob-v0:sha256:f4f6c65555c95780b0b236bb1ac1f8826503465a58e6f2079b68f1f04ba1c02a";

function fail(message) {
  throw new Error("SPKF_POC_FAILED: " + message);
}

function assert(condition, message) {
  if (!condition) fail(message);
}

// This is intentionally a SMALL PoC canonicalizer, not an RFC 8785 implementation.
// It is sufficient for these fixtures because they use:
// - UTF-8 strings,
// - booleans/null,
// - arrays/objects,
// - no floating-point or arbitrary JSON numeric values.
function canonicalize(value) {
  if (value === null) return "null";

  if (Array.isArray(value)) {
    return "[" + value.map(canonicalize).join(",") + "]";
  }

  switch (typeof value) {
    case "string":
      return JSON.stringify(value);

    case "boolean":
      return value ? "true" : "false";

    case "number":
      if (!Number.isSafeInteger(value)) {
        fail("only safe integers are accepted by the PoC canonicalizer");
      }
      return String(value);

    case "object": {
      const keys = Object.keys(value).sort();
      const fields = keys.map(
        (key) => JSON.stringify(key) + ":" + canonicalize(value[key]),
      );
      return "{" + fields.join(",") + "}";
    }

    default:
      fail("unsupported JSON value type: " + typeof value);
  }
}

function sha256(parts) {
  const hash = createHash("sha256");
  for (const part of parts) hash.update(part);
  return hash.digest("hex");
}

function objectId(value) {
  const canonical = Buffer.from(canonicalize(value), "utf8");
  return "spkf-poc-v0:sha256:" +
    sha256([Buffer.from("SPKF-POC/0\0", "utf8"), canonical]);
}

function blobId(bytes) {
  return "spkf-poc-blob-v0:sha256:" +
    sha256([Buffer.from("SPKF-POC-BLOB/0\0", "utf8"), bytes]);
}

async function loadJson(relativePath) {
  const bytes = await readFile(path.join(here, relativePath));
  return JSON.parse(bytes.toString("utf8"));
}

function reverseObjectInsertionOrder(value) {
  if (Array.isArray(value)) {
    return value.map(reverseObjectInsertionOrder);
  }
  if (value && typeof value === "object") {
    const result = {};
    for (const key of Object.keys(value).reverse()) {
      result[key] = reverseObjectInsertionOrder(value[key]);
    }
    return result;
  }
  return value;
}

const theory = await loadJson("theory.json");
const extension = await loadJson("extension.json");
const npmBinding = await loadJson("bindings/npm.json");
const cargoBinding = await loadJson("bindings/cargo.json");
const proofBytes = await readFile(path.join(here, "proof", "Identity.lean"));

const rootId = objectId(theory);
assert(rootId === EXPECTED_ROOT, "unexpected KnowledgeRoot ID");

const reorderedRootId = objectId(reverseObjectInsertionOrder(theory));
assert(
  reorderedRootId === rootId,
  "object-key insertion order changed semantic identity",
);

const proofBlob = blobId(proofBytes);
assert(proofBlob === EXPECTED_PROOF_BLOB, "unexpected proof-source blob ID");

assert(
  extension.subject?.spkf === rootId,
  "TheoryExtension does not target the KnowledgeRoot",
);
assert(
  extension.adds?.theorems?.[0]?.proofSource?.blob === proofBlob,
  "TheoryExtension proof-source blob does not match Identity.lean",
);
assert(
  extension.adds?.theorems?.[0]?.statement ===
    theory.specifications?.[0]?.statement,
  "TheoryExtension theorem statement differs from the root specification",
);

assert(
  npmBinding.subject?.spkf === rootId,
  "npm DistributionBinding does not target the KnowledgeRoot",
);
assert(
  cargoBinding.subject?.spkf === rootId,
  "Cargo DistributionBinding does not target the KnowledgeRoot",
);
assert(
  npmBinding.package?.purl !== cargoBinding.package?.purl,
  "PoC expects two different distribution coordinates",
);

// Negative test: semantic mutation MUST change the semantic root.
const mutatedTheory = structuredClone(theory);
mutatedTheory.capabilities = ["identity.nat.changed"];
const mutatedRootId = objectId(mutatedTheory);
assert(
  mutatedRootId !== rootId,
  "semantic mutation did not change KnowledgeRoot ID",
);

// Distribution coordinates are outside the KnowledgeRoot, therefore changing
// a registry/package coordinate cannot alter the theory identity.
const changedNpmBinding = structuredClone(npmBinding);
changedNpmBinding.package.purl =
  "pkg:npm/%40someone-else/another-carrier@9.9.9";
assert(
  changedNpmBinding.subject.spkf === rootId,
  "distribution-coordinate change altered semantic subject",
);

const extensionId = objectId(extension);

process.stdout.write(
  [
    "SPKF_POC: PASS",
    "knowledgeRoot=" + rootId,
    "proofSourceBlob=" + proofBlob,
    "theoryExtension=" + extensionId,
    "npm=" + npmBinding.package.purl,
    "cargo=" + cargoBinding.package.purl,
    "registryIndependentSubject=PASS",
    "keyOrderIndependence=PASS",
    "semanticMutationChangesId=PASS",
    "proofSourceIntegrity=PASS",
    "kernelReplay=NOT_RUN_BY_THIS_FORMAT_POC"
  ].join("\n") + "\n",
);
