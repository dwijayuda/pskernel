import assert from "node:assert/strict";
import { test } from "node:test";
import { verifyOfflinePrototype } from "./pscv-verify.mjs";

test("offline verifier prototype checks local architecture/trust/SAVEF closure",async()=>{
  const result=await verifyOfflinePrototype();
  assert.equal(result.verifier,"pscv-verify/0-prototype");
  assert.equal(result.architecture,"pscv-architecture/v3");
  assert.match(result.savefObject,/^sha256:[0-9a-f]{64}$/u);
});
