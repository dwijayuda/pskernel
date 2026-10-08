import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { fileURLToPath, pathToFileURL } from 'node:url';
export const root = fileURLToPath(new URL('../', import.meta.url));
export const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
export const json = file => JSON.parse(fs.readFileSync(file, 'utf8'));

// A source-profile guard, not a replacement for PSC parsing or kernel admission.
export function maskNonCode(source) {
  let out = '', i = 0, depth = 0, string = false;
  while (i < source.length) {
    const c = source[i], pair = source.slice(i, i + 2);
    if (depth) {
      if (pair === '/-') { depth++; out += '  '; i += 2; }
      else if (pair === '-/') { depth--; out += '  '; i += 2; }
      else { out += c === '\n' ? '\n' : ' '; i++; }
    } else if (string) {
      if (c === '\\') {
        if (i + 1 >= source.length) throw Error('UNTERMINATED_STRING');
        out += ' ' + (source[i+1] === '\n' ? '\n' : ' '); i += 2;
      } else { if (c === '"') string = false; out += c === '\n' ? '\n' : ' '; i++; }
    } else if (pair === '--') {
      while (i < source.length && source[i] !== '\n') { out += ' '; i++; }
    } else if (pair === '/-') { depth = 1; out += '  '; i += 2; }
    else if (c === '"') { string = true; out += ' '; i++; }
    else { out += c; i++; }
  }
  if (depth || string) throw Error('UNTERMINATED_NON_CODE');
  return out;
}
export function validateCode(source, allowedImports) {
  const masked = maskNonCode(source);
  if (/\b(?:unsafe|axiom|sorry|admit|extern|implemented_by|macro|macro_rules|elab|elab_rules|syntax|namespace|section|mutual|partial|IO)\b|\b(?:Lean|Std)\.|#/u.test(masked)) {
    throw Error('FORBIDDEN_SOURCE_FEATURE');
  }
  for (const line of masked.split(/\r?\n/u)) {
    if (!/\bimport\b/u.test(line)) continue;
    const match = line.match(/^\s*import\s+([A-Za-z0-9_.]+)\s*$/u);
    if (!match || !allowedImports.has(match[1])) throw Error('EXTERNAL_OR_OUT_OF_ORDER_IMPORT');
  }
  return source.split(/\r?\n/u).filter((_, i) =>
    !/^\s*import\s/u.test(masked.split(/\r?\n/u)[i])).join('\n');
}
export function readSources(base = root) {
  const manifest = json(path.join(base, 'manifests/SOURCE.json'));
  const expected = ["src/Ps/Kernel/Data.lean","src/Ps/Kernel/Structural.lean","src/Ps/Kernel/Natural.lean","src/Ps/Kernel/Expr.lean","src/Ps/Kernel/Binding.lean","src/Ps/Kernel/Order.lean","src/Ps/Kernel/Universe.lean","src/Ps/Kernel/LevelCheck.lean","src/Ps/Kernel/LevelInstantiate.lean","src/Ps/Kernel/ExprInstantiate.lean","src/Ps/Kernel/AlgebraicData.lean","src/Ps/Kernel/Environment.lean","src/Ps/Kernel/BuiltinNat.lean","src/Ps/Kernel/BuiltinText.lean","src/Ps/Kernel/AlgebraicReduction.lean","src/Ps/Kernel/Reduction.lean","src/Ps/Kernel/Conversion.lean","src/Ps/Kernel/TypeCheck.lean","src/Ps/Kernel/Admission.lean","src/Ps/Kernel/UnitInductive.lean","src/Ps/Kernel/NatInductive.lean","src/Ps/Kernel/RecordInductive.lean","src/Ps/Kernel/EnumInductive.lean","src/Ps/Kernel/SumInductive.lean","src/Ps/Kernel/AlgebraicHeader.lean","src/Ps/Kernel/Closing.lean","src/Ps/Kernel/Occurrence.lean","src/Ps/Kernel/ExpressionEquality.lean","src/Ps/Kernel/Positivity.lean","src/Ps/Kernel/AlgebraicConstructor.lean","src/Ps/Kernel/Parameters.lean","src/Ps/Kernel/AlgebraicMinor.lean","src/Ps/Kernel/AlgebraicRecursor.lean","src/Ps/Kernel/AlgebraicAdmission.lean","src/Ps/Kernel/JointAdmission.lean","src/Ps/Kernel/Bootstrap.lean"];
  if (manifest.schemaVersion !== 1 || JSON.stringify(manifest.files.map(x => x.path)) !== JSON.stringify(expected)) throw Error('SOURCE_CLOSURE_CHANGED');
  const allowed = new Set(), chunks = [];
  for (const entry of manifest.files) {
    let current = base;
    for (const segment of entry.path.split('/')) {
      current = path.join(current, segment);
      if (fs.lstatSync(current).isSymbolicLink()) throw Error('SYMLINK_SOURCE');
    }
    const bytes = fs.readFileSync(current);
    if (sha256(bytes) !== entry.sha256) throw Error(`SOURCE_HASH_MISMATCH: ${entry.path}`);
    chunks.push(validateCode(bytes.toString('utf8'), allowed));
    allowed.add(entry.path.slice(4, -5).replaceAll('/', '.'));
  }
  // Reject added, unmanifested semantic files rather than silently ignoring them.
  const found = [];
  function walk(dir) {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const file = path.join(dir, e.name);
      if (e.isSymbolicLink()) throw Error('SYMLINK_SOURCE');
      if (e.isDirectory()) walk(file);
      else if (e.name.endsWith('.lean')) found.push(path.relative(base, file).split(path.sep).join('/'));
    }
  }
  walk(path.join(base, 'src'));
  if (JSON.stringify(found.sort()) !== JSON.stringify([...expected].sort())) throw Error('UNMANIFESTED_SOURCE');
  return { manifest, flat: chunks.join('\n\n') + '\n' };
}
if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  const { manifest } = readSources();
  console.log(`PSKERNEL_CORE_SOURCE: PASS (${manifest.files.length} pinned owned modules)`);
}

// Shared explicit seed/oracle identity validation; never download or fall back.
export function checkedTool(candidate, expectedDigest, label) {
  if (typeof candidate !== 'string' || !candidate || typeof expectedDigest !== 'string' || !/^[a-f0-9]{64}$/.test(expectedDigest)) throw Error(`${label}_PIN_REQUIRED`);
  const resolved = fs.realpathSync(candidate);
  if (!fs.statSync(resolved).isFile() || sha256(fs.readFileSync(resolved)) !== expectedDigest) throw Error(`${label}_DIGEST_MISMATCH`);
  fs.accessSync(resolved, fs.constants.X_OK);
  return resolved;
}
export const verifySource = (base = root) => readSources(base).manifest;
export const sourceClosure = (base = root) => readSources(base).flat;
