import assert from "node:assert/strict";
import { test } from "node:test";
import { readFile } from "node:fs/promises";
import { verifySavefObject } from "./savef-object.mjs";

const schemaUrl=new URL("../savef/schemas/KNOWLEDGE_OBJECT_V1.json",import.meta.url);
const objectUrl=new URL("../savef/objects/psc-specialization-pass.json",import.meta.url);

test("committed SAVEF specialization object verifies offline", async()=>{
  const schema=JSON.parse(await readFile(schemaUrl,"utf8"));
  const object=JSON.parse(await readFile(objectUrl,"utf8"));
  const result=verifySavefObject(object,schema);
  assert.equal(result.accepted,true);
});

test("tampered SAVEF object fails closed", async()=>{
  const schema=JSON.parse(await readFile(schemaUrl,"utf8"));
  const object=JSON.parse(await readFile(objectUrl,"utf8"));
  object.payload.currentAssurance="proved";
  assert.throws(()=>verifySavefObject(object,schema),/SAVEF_OBJECT_ID/);
});
