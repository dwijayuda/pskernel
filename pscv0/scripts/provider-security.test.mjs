import assert from "node:assert/strict";
import { test } from "node:test";
import {
  assertProviderSecurity,
  assertProviderSecurityRegistry,
  defaultProviderSecurityProfile,
} from "./provider-security.mjs";

test("provider security registry is internally consistent", () => {
  assert.equal(assertProviderSecurityRegistry(), true);
  assert.equal(defaultProviderSecurityProfile, "development-v1");
});

test("current default provider records its exact security revision", () => {
  const security = assertProviderSecurity("lean434-wasm");
  assert.equal(security.contract, "psc-provider-security/1");
  assert.equal(security.profile, "development-v1");
  assert.match(security.securityRevision, /4\.34\.0/u);
});

test("paranoid policy fails closed until an explicitly hardened provider is registered", () => {
  assert.throws(
    () => assertProviderSecurity("lean434-wasm", "paranoid-v1"),
    /PROVIDER_SECURITY_REJECTED/,
  );
});
