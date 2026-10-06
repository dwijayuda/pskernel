import { existsSync, readdirSync } from 'node:fs';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { findForbiddenForms, readSelfhostProfile } from './selfhost-profile.mjs';
import {
  findSelfhostStructuralViolations,
  portableSelfhostStructuralRuleIds,
} from './selfhost-source-rules.mjs';
import { packageBySection, parseImports } from './workspace-layout.mjs';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const workspaceRoot = path.resolve(scriptDir, '..');
const profilePath = path.join(workspaceRoot, 'portable-selfhost-profile.json');

export async function readPortableSelfhostProfile() {
  return JSON.parse(await readFile(profilePath, 'utf8'));
}

function moduleSource(moduleName) {
  const parts = moduleName.split('.');
  if (parts[0] === 'ProofScript') {
    return path.join(workspaceRoot, 'stdlib', ...parts) + '.lean';
  }
  if (parts[0] === 'Ps' && parts.length >= 2) {
    const packageName = packageBySection.get(parts[1]);
    if (!packageName) return undefined;
    return path.join(workspaceRoot, 'packages', packageName, 'src', ...parts) + '.lean';
  }
  return undefined;
}

function walkLeanFiles(directory, files) {
  if (!existsSync(directory)) return;
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const full = path.join(directory, entry.name);
    if (entry.isDirectory()) walkLeanFiles(full, files);
    else if (entry.isFile() && entry.name.endsWith('.lean')) files.push(full);
  }
}

export async function collectPortableSelfhostPackages(profile, packageFilter) {
  const packagesRoot = path.join(workspaceRoot, 'packages');
  const selected = [];
  for (const entry of readdirSync(packagesRoot, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    if (packageFilter && entry.name !== packageFilter) continue;
    const packageRoot = path.join(packagesRoot, entry.name);
    const manifestPath = path.join(packageRoot, 'package.json');
    if (!existsSync(manifestPath)) continue;
    const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
    if (manifest.proofscript?.implementationProfile !== profile.profile) continue;
    if (manifest.proofscript?.portable !== true) {
      throw new Error('PSC1_PORTABLE_SELFHOST_PACKAGE_NOT_PORTABLE: ' + entry.name);
    }
    if (manifest.proofscript?.bootstrap === true) {
      throw new Error('PSC1_PORTABLE_SELFHOST_BOOTSTRAP_PROFILE_MISMATCH: ' + entry.name);
    }
    const roots = [];
    for (const sourceRoot of manifest.proofscript?.sourceRoots ?? []) {
      walkLeanFiles(path.resolve(packageRoot, sourceRoot), roots);
    }
    selected.push({ name: entry.name, roots });
  }
  return selected;
}

export async function collectImportClosure(rootFiles, includeImportClosure) {
  const visited = new Map();
  const queue = [...rootFiles];

  while (queue.length > 0) {
    const current = path.resolve(queue.shift());
    if (visited.has(current)) continue;
    if (!existsSync(current)) {
      throw new Error(
        'PSC1_PORTABLE_SELFHOST_SOURCE_MISSING: ' +
          path.relative(workspaceRoot, current),
      );
    }

    const source = await readFile(current, 'utf8');
    visited.set(current, source);
    if (!includeImportClosure) continue;

    for (const moduleName of parseImports(source)) {
      const imported = moduleSource(moduleName);
      if (!imported || !existsSync(imported)) {
        throw new Error('PSC1_PORTABLE_SELFHOST_IMPORT_UNRESOLVED: ' + moduleName + ' from ' + path.relative(workspaceRoot, current));
      }
      if (!visited.has(path.resolve(imported))) {
        queue.push(imported);
      }
    }
  }

  return visited;
}

export async function collectPortableSelfhostEntryRoots(
  pkg,
  includeImportClosure,
) {
  const packageRoots = new Set(pkg.roots.map(sourcePath => path.resolve(sourcePath)));
  const importedPackageRoots = new Set();

  for (const sourcePath of pkg.roots) {
    const source = await readFile(sourcePath, 'utf8');
    for (const moduleName of parseImports(source)) {
      const imported = moduleSource(moduleName);
      if (!imported) continue;
      const resolved = path.resolve(imported);
      if (packageRoots.has(resolved)) importedPackageRoots.add(resolved);
    }
  }

  const entries = pkg.roots
    .map(sourcePath => path.resolve(sourcePath))
    .filter(sourcePath => !importedPackageRoots.has(sourcePath))
    .sort();

  if (entries.length === 0) {
    throw new Error('PSC1_PORTABLE_SELFHOST_NO_ENTRY_ROOTS: ' + pkg.name);
  }

  const covered = new Set();
  for (const entry of entries) {
    const closure = await collectImportClosure(
      [entry],
      includeImportClosure === true,
    );
    for (const sourcePath of closure.keys()) {
      const resolved = path.resolve(sourcePath);
      if (packageRoots.has(resolved)) covered.add(resolved);
    }
  }

  const missing = [...packageRoots]
    .filter(sourcePath => !covered.has(sourcePath))
    .sort();

  if (missing.length > 0) {
    throw new Error(
      'PSC1_PORTABLE_SELFHOST_ENTRY_COVERAGE: ' +
        pkg.name +
        ': ' +
        missing.map(sourcePath => path.relative(workspaceRoot, sourcePath)).join(','),
    );
  }

  return entries;
}

function assertProfile(profile) {
  if (profile.schemaVersion !== 1) throw new Error('PSC1_PORTABLE_SELFHOST_PROFILE_SCHEMA');
  if (profile.profile !== 'PSC1-portable-selfhost/1') {
    throw new Error('PSC1_PORTABLE_SELFHOST_PROFILE_ID');
  }
  if (profile.proofScriptLanguageEdition !== 'ps-0.9-r3') {
    throw new Error('PSC1_PORTABLE_SELFHOST_LANGUAGE_EDITION');
  }
  if (profile.proofScriptSourceProfile !== 'ps-standard-0.9-r3') {
    throw new Error('PSC1_PORTABLE_SELFHOST_SOURCE_PROFILE');
  }
  if (profile.inheritsForbiddenLeanFormsFrom !== 'PSC1-selfhost-stable/1') {
    throw new Error('PSC1_PORTABLE_SELFHOST_INHERITANCE');
  }
  if (!Array.isArray(profile.structuralRules) || profile.structuralRules.length === 0) {
    throw new Error('PSC1_PORTABLE_SELFHOST_STRUCTURAL_RULES');
  }
  const implemented = new Set(portableSelfhostStructuralRuleIds);
  const unknown = profile.structuralRules.filter(rule => !implemented.has(rule));
  if (unknown.length > 0) {
    throw new Error(
      'PSC1_PORTABLE_SELFHOST_UNKNOWN_STRUCTURAL_RULES: ' + unknown.join(','),
    );
  }
  if (new Set(profile.structuralRules).size !== profile.structuralRules.length) {
    throw new Error('PSC1_PORTABLE_SELFHOST_DUPLICATE_STRUCTURAL_RULES');
  }
  if (profile.executableContract?.pscCheckSourceRoots !== true) {
    throw new Error('PSC1_PORTABLE_SELFHOST_EXECUTABLE_CONTRACT');
  }
  if (profile.executableContract?.pscTypeScriptEntryRoots !== true) {
    throw new Error('PSC1_PORTABLE_SELFHOST_EMISSION_CONTRACT');
  }
  if (profile.executableContract?.pscProofScriptEntryRoots !== true) {
    throw new Error('PSC1_PORTABLE_SELFHOST_PS_EMISSION_CONTRACT');
  }
}

export async function checkPortableSelfhostProfile(packageFilter) {
  const profile = await readPortableSelfhostProfile();
  const stableProfile = await readSelfhostProfile();
  assertProfile(profile);

  const packages = await collectPortableSelfhostPackages(profile, packageFilter);
  if (packages.length === 0) {
    throw new Error(
      'PSC1_PORTABLE_SELFHOST_NO_PACKAGES' +
        (packageFilter ? ': ' + packageFilter : ''),
    );
  }

  const violations = [];
  const closurePaths = new Set();

  for (const pkg of packages) {
    if (pkg.roots.length === 0) {
      throw new Error('PSC1_PORTABLE_SELFHOST_NO_SOURCE: ' + pkg.name);
    }

    const closure = await collectImportClosure(
      pkg.roots,
      profile.includeImportClosure === true,
    );

    for (const [sourcePath, source] of closure) {
      closurePaths.add(sourcePath);

      for (const hit of findForbiddenForms(source, stableProfile)) {
        violations.push({
          path: path.relative(workspaceRoot, sourcePath),
          line: hit.line,
          id: hit.id,
          text: hit.text,
        });
      }

      for (const hit of findSelfhostStructuralViolations(
        source,
        profile.structuralRules,
      )) {
        violations.push({
          path: path.relative(workspaceRoot, sourcePath),
          line: hit.line,
          id: hit.id,
          text: hit.text,
        });
      }
    }
  }

  violations.sort(
    (left, right) =>
      left.path.localeCompare(right.path) ||
      left.line - right.line ||
      left.id.localeCompare(right.id),
  );

  if (violations.length > 0) {
    const rendered = violations
      .map(hit => hit.path + ':' + hit.line + ': ' + hit.id + ': ' + hit.text)
      .join('\n');
    throw new Error('PSC1_PORTABLE_SELFHOST_PROFILE_VIOLATIONS\n' + rendered);
  }

  return {
    profile,
    packages: packages.map(pkg => pkg.name).sort(),
    moduleCount: closurePaths.size,
  };
}

if (
  process.argv[1] &&
  path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)
) {
  const packageIndex = process.argv.indexOf('--package');
  const packageFilter =
    packageIndex >= 0 ? process.argv[packageIndex + 1] : undefined;
  const result = await checkPortableSelfhostProfile(packageFilter);
  process.stdout.write(
    'PSC1_PORTABLE_SELFHOST_PROFILE: PASS (' +
      result.profile.profile +
      '; packages=' +
      result.packages.join(',') +
      '; modules=' +
      result.moduleCount +
      ')\n',
  );
}
