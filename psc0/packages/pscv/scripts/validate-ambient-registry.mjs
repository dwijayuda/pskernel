#!/usr/bin/env node
/** CI-only canonicalization of observed Lean extension state. No certification. */
import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { validateAmbientRegistryInventory } from '../src/ambient-registry-inventory.mjs';

const [input, output] = process.argv.slice(2);
if (!input || !output || process.argv.length !== 4) {
  throw new Error('PSC_PSCV_AMBIENT_INVENTORY_USAGE');
}
const filename = path.resolve(input);
const data = await readFile(filename);
if (data.length > 64 * 1024 * 1024) throw new Error('PSC_PSCV_AMBIENT_INVENTORY_LIMIT');
const original = JSON.parse(data.toString('utf8'));
const audit = validateAmbientRegistryInventory(original);
const { canonicalObserved, ...report } = audit;
const machine = {
  ...report, observed: canonicalObserved,
  // Host-approved normal forms and registry order require a separate
  // normative conformance study; this content is never the Standard manifest.
  standardManifestDigest: null,
  approvalStatus: 'not-approved',
};
await writeFile(path.resolve(output), JSON.stringify(machine) + '\n');
process.stdout.write(JSON.stringify({
  kind:machine.kind, state:machine.state,
  identitySha256:machine.identitySha256,
  counts:machine.counts,
  standardEnvironmentFrozen:false,
  pscvVerified:false,
}) + '\n');
