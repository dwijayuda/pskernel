import { readFileSync } from "node:fs";

const data = JSON.parse(readFileSync(new URL("../profiles/provider-security/PROVIDER_SECURITY_PROFILES.json", import.meta.url), "utf8"));
export const providerSecurityContract = Object.freeze({
  id: data.contract,
  semanticProfile: data.semanticProfile,
});
export const defaultProviderSecurityProfile = "development-v1";

function profileById(id) {
  const profile = data.profiles.find(item => item.id === id);
  if (!profile) throw new Error("PSC2_PROVIDER_SECURITY_PROFILE_UNKNOWN: " + id);
  return profile;
}

export function providerSecurityDescriptor(selector) {
  const provider = data.providers[selector];
  if (!provider) throw new Error("PSC2_PROVIDER_SECURITY_SELECTOR_UNKNOWN: " + selector);
  return Object.freeze({ selector, ...provider });
}

export function assertProviderSecurity(selector, profileId = defaultProviderSecurityProfile) {
  const profile = profileById(profileId);
  const provider = providerSecurityDescriptor(selector);
  if (!profile.allowedSelectors.includes(selector)) {
    throw new Error("PSC2_PROVIDER_SECURITY_REJECTED: " + profileId + ":" + selector);
  }
  return Object.freeze({
    contract: data.contract,
    profile: profile.id,
    assurance: profile.assurance,
    selector,
    securityRevision: provider.securityRevision,
    runtimeFamily: provider.runtimeFamily,
    knownLimitations: Object.freeze([...(provider.knownLimitations ?? [])]),
  });
}

export function assertProviderSecurityRegistry() {
  if (data.schemaVersion !== 1 || data.contract !== "psc-provider-security/1") {
    throw new Error("PSC2_PROVIDER_SECURITY_SCHEMA");
  }
  const ids = new Set();
  for (const profile of data.profiles) {
    if (!profile.id || ids.has(profile.id)) throw new Error("PSC2_PROVIDER_SECURITY_PROFILE_ID");
    ids.add(profile.id);
    for (const selector of profile.allowedSelectors) providerSecurityDescriptor(selector);
  }
  if (!ids.has(defaultProviderSecurityProfile) || !ids.has("paranoid-v1")) {
    throw new Error("PSC2_PROVIDER_SECURITY_REQUIRED_PROFILE");
  }
  return true;
}
