import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";

export const savefPrototypeContract = "spkf-local-prototype/1";
const domain = savefPrototypeContract + "\0";

export function savefCanonical(value) {
  if (Array.isArray(value)) return "[" + value.map(savefCanonical).join(",") + "]";
  if (value !== null && typeof value === "object") {
    return "{" + Object.keys(value).sort().map(key =>
      JSON.stringify(key) + ":" + savefCanonical(value[key])
    ).join(",") + "}";
  }
  return JSON.stringify(value);
}

export function savefObjectId(object) {
  const { objectId: _ignored, ...payload } = object;
  const bytes = domain + savefCanonical(payload);
  return "sha256:" + createHash("sha256").update(bytes, "utf8").digest("hex");
}

export function verifySavefObject(object, schema) {
  if (schema?.contract !== savefPrototypeContract) throw new Error("SAVEF_SCHEMA_CONTRACT");
  for (const field of schema.requiredFields ?? []) {
    if (!Object.hasOwn(object, field)) throw new Error("SAVEF_REQUIRED_FIELD: " + field);
  }
  if (!schema.authorityClasses.includes(object.authorityClass)) throw new Error("SAVEF_AUTHORITY_CLASS");
  for (const claim of object.claims ?? []) {
    if (!schema.claimStatuses.includes(claim.status)) throw new Error("SAVEF_CLAIM_STATUS: " + claim.status);
  }
  const expected = savefObjectId(object);
  if (object.objectId !== expected) throw new Error("SAVEF_OBJECT_ID");
  return Object.freeze({ accepted: true, objectId: expected });
}

export async function verifySavefFile(objectUrl, schemaUrl) {
  const [object, schema] = await Promise.all([
    readFile(objectUrl, "utf8").then(JSON.parse),
    readFile(schemaUrl, "utf8").then(JSON.parse),
  ]);
  return verifySavefObject(object, schema);
}
