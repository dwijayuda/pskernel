import { maskLeanSource } from './lean-source-mask.mjs';
import { existsSync, readdirSync } from 'node:fs';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { packageBySection, parseImports } from './workspace-layout.mjs';
import {
  allowedBootstrapPackageNames,
  assertBootstrapPackageAllowed,
} from './bootstrap-closure-contract.mjs';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
export const selfhostRoot = path.resolve(scriptDir, '..');
export const selfhostProfilePath = path.join(selfhostRoot, 'selfhost-profile.json');

export async function readSelfhostProfile() {
  return JSON.parse(await readFile(selfhostProfilePath, 'utf8'));
}

function moduleSource(moduleName) {
  const parts = moduleName.split('.');
  if (parts[0] === 'ProofScript') {
    return { packageName: 'stdlib', sourcePath: path.join(selfhostRoot, 'stdlib', ...parts) + '.lean' };
  }
  if (parts[0] === 'Ps' && parts.length >= 2) {
    const packageName = packageBySection.get(parts[1]);
    if (!packageName) throw new Error(`PSC2_SELFHOST_PROFILE_UNKNOWN_PACKAGE: ${moduleName}`);
    return {
      packageName,
      sourcePath: path.join(selfhostRoot, 'packages', packageName, 'src', ...parts) + '.lean',
    };
  }
  throw new Error(`PSC2_SELFHOST_PROFILE_UNKNOWN_IMPORT: ${moduleName}`);
}

export async function collectSelfhostClosure(profile) {
  profile ??= await readSelfhostProfile();
  const entry = path.resolve(selfhostRoot, profile.entry);
  const visited = new Set();
  const ordered = [];
  const packages = new Set(['bootstrap']);

  async function visit(sourcePath) {
    const absolute = path.resolve(sourcePath);
    if (visited.has(absolute)) return;
    visited.add(absolute);
    if (!existsSync(absolute)) {
      throw new Error(`PSC2_SELFHOST_PROFILE_SOURCE_MISSING: ${path.relative(selfhostRoot, absolute)}`);
    }
    const source = await readFile(absolute, 'utf8');
    for (const moduleName of parseImports(source)) {
      const resolved = moduleSource(moduleName);
      packages.add(resolved.packageName);
      await visit(resolved.sourcePath);
    }
    ordered.push({ path: absolute, source });
  }

  await visit(entry);
  return { entry, ordered, packages };
}

// Mask comments and string literals while preserving newlines and offsets.
// Lean block comments are nested, so a depth counter is required.
export const maskLeanNonCode = maskLeanSource;

export function findForbiddenForms(source, profile) {
  const code = maskLeanNonCode(source);
  const hits = [];
  for (const rule of profile.forbiddenLeanForms ?? []) {
    const regex = new RegExp(rule.pattern, 'gu');
    for (const match of code.matchAll(regex)) {
      const prefix = code.slice(0, match.index);
      const line = 1 + (prefix.match(/\n/gu)?.length ?? 0);
      hits.push({ id: rule.id, line, text: match[0] });
    }
  }
  return hits;
}

function assertProfileShape(profile) {
  if (profile.schemaVersion !== 1) throw new Error('PSC2_SELFHOST_PROFILE_SCHEMA');
  if (profile.profile !== 'PSC1-selfhost-stable/1') throw new Error('PSC2_SELFHOST_PROFILE_ID');
  if (profile.proofScriptLanguageEdition !== 'ps-0.9-r3') {
    throw new Error('PSC2_SELFHOST_PROFILE_LANGUAGE_EDITION');
  }
  if (profile.proofScriptSourceProfile !== 'ps-standard-0.9-r3') {
    throw new Error('PSC2_SELFHOST_PROFILE_SOURCE_EDITION');
  }
  if (profile.requiredLanguageProfile !== 'psc2-language-v1') {
    throw new Error('PSC2_SELFHOST_PROFILE_REQUIRED_LANGUAGE');
  }
  if (profile.standardLanguageProfile !== 'psc2-standard-language-v1') {
    throw new Error('PSC2_SELFHOST_PROFILE_STANDARD_LANGUAGE');
  }
  if (profile.entry !== 'packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean') {
    throw new Error('PSC2_SELFHOST_PROFILE_ENTRY');
  }
  const allowed = [...(profile.allowedPackages ?? [])].sort();
  const canonical = [...allowedBootstrapPackageNames].sort();
  if (JSON.stringify(allowed) !== JSON.stringify(canonical)) {
    throw new Error('PSC2_SELFHOST_PROFILE_PACKAGE_POLICY_DRIFT');
  }
  if (!Array.isArray(profile.legacyRepairGuards)) {
    throw new Error('PSC2_SELFHOST_PROFILE_LEGACY_GUARD_BASELINE');
  }
  const legacy = [...profile.legacyRepairGuards];
  const canonicalLegacy = [...new Set(legacy)].sort();
  if (JSON.stringify(legacy) !== JSON.stringify(canonicalLegacy)) {
    throw new Error('PSC2_SELFHOST_PROFILE_LEGACY_GUARD_ORDER');
  }
  if (profile.legacyRepairGuardMaxCount !== legacy.length) {
    throw new Error('PSC2_SELFHOST_PROFILE_LEGACY_GUARD_COUNT');
  }
}

export function legacyRepairGuardNames() {
  return readdirSync(scriptDir)
    .filter(name => /^check-.*-selfhost-source-syntax\.mjs$/u.test(name))
    .sort();
}

export function assertLegacyRepairGuards(currentNames, profile) {
  const baseline = new Set(profile.legacyRepairGuards ?? []);
  const additions = currentNames.filter(name => !baseline.has(name));
  if (additions.length > 0) {
    throw new Error(
      `PSC2_SELFHOST_PROFILE_ADHOC_GUARD_FORBIDDEN: new one-off repair guards: ${additions.join(', ')}`,
    );
  }
  if (currentNames.length > profile.legacyRepairGuardMaxCount) {
    throw new Error(
      `PSC2_SELFHOST_PROFILE_ADHOC_GUARD_COUNT: ${currentNames.length} > ${profile.legacyRepairGuardMaxCount}`,
    );
  }
}

export async function checkSelfhostProfile() {
  const profile = await readSelfhostProfile();
  assertProfileShape(profile);
  const psconfig = JSON.parse(await readFile(path.join(selfhostRoot, 'psconfig.json'), 'utf8'));
  if (psconfig.entry !== profile.entry) throw new Error('PSC2_SELFHOST_PROFILE_PSCONFIG_ENTRY_DRIFT');
  if (psconfig.languageVersion !== '0.9-r3' ||
      psconfig.languageEdition !== profile.proofScriptLanguageEdition ||
      psconfig.sourceProfile !== profile.proofScriptSourceProfile ||
      psconfig.requiredLanguageProfile !== profile.requiredLanguageProfile ||
      psconfig.standardLanguageProfile !== profile.standardLanguageProfile) {
    throw new Error('PSC2_SELFHOST_PROFILE_PSCONFIG_LANGUAGE_DRIFT');
  }
  if (psconfig.implementationProfile !== profile.implementationProfile) {
    throw new Error('PSC2_SELFHOST_PROFILE_IMPLEMENTATION_DRIFT');
  }

  const closure = await collectSelfhostClosure(profile);
  for (const packageName of closure.packages) assertBootstrapPackageAllowed(packageName);

  const violations = [];
  for (const item of closure.ordered) {
    for (const hit of findForbiddenForms(item.source, profile)) {
      violations.push(
        `${path.relative(selfhostRoot, item.path)}:${hit.line}: ${hit.id}: ${hit.text}`,
      );
    }
  }
  if (violations.length > 0) {
    throw new Error('PSC2_SELFHOST_PROFILE_FORBIDDEN_SOURCE\n' + violations.join('\n'));
  }

  const legacyNames = legacyRepairGuardNames();
  assertLegacyRepairGuards(legacyNames, profile);
  const legacyCount = legacyNames.length;

  return { profile, closure, legacyCount };
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const result = await checkSelfhostProfile();
  process.stdout.write(
    `PSC2_SELFHOST_PROFILE: PASS (${result.profile.profile}; ${result.closure.ordered.length} modules; ${result.legacyCount}/${result.profile.legacyRepairGuardMaxCount} legacy repair guards frozen)\n`,
  );
}
