#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const repoRoot = process.cwd();
const kernelDir = path.join(repoRoot, 'psc1-kernel', 'PSC1Kernel');

// Explicit host/replay adapters are outside the portable semantic kernel.
const hostBoundaryFiles = new Set([
  'NativeMap.lean',
  'Replay.lean',
  'ReplayJson.lean',
]);

const portableFiles = fs.readdirSync(kernelDir)
  .filter((name) => name.endsWith('.lean'))
  .filter((name) => !hostBoundaryFiles.has(name))
  .sort();

const hardRules = [
  ['unsafe declaration', /\bunsafe\s+(?:partial\s+)?(?:def|abbrev|theorem|opaque|structure|inductive)\b/g],
  ['implemented_by', /@\[\s*implemented_by\b/g],
  ['extern', /\bextern\s+/g],
  ['run_tac', /\brun_tac\b/g],
  ['IO.Ref', /\bIO\.Ref\b/g],
  ['direct IO API', /\bIO\.(?!userError\b)[A-Za-z_][A-Za-z0-9_']*/g],
  ['IO result type', /:\s*IO(?:\s|\()/g],
  ['Lean implementation API', /\bLean\.(?:Meta|Elab|Parser|Compiler|Environment|Syntax|Macro)\b/g],
  ['syntax declaration', /^\s*syntax\b/gm],
  ['macro declaration', /^\s*macro\b/gm],
  ['elab declaration', /^\s*elab\b/gm],
];

const warnRules = [
  ['abbrev convenience', /\babbrev\s+/g],
  ['mutable local convenience', /\blet\s+mut\s+/g],
  ['structure update sugar', /\{\s*[A-Za-z_][A-Za-z0-9_']*\s+with\b/g],
  ['private visibility convenience', /\bprivate\s+(?:partial\s+)?(?:def|abbrev|structure|inductive)\b/g],
];

function stripComments(text) {
  let out = '';
  let i = 0;
  let blockDepth = 0;
  let inString = false;
  let escaped = false;

  while (i < text.length) {
    const a = text[i];
    const b = text[i + 1];

    if (blockDepth > 0) {
      if (a === '/' && b === '-') {
        blockDepth += 1;
        i += 2;
      } else if (a === '-' && b === '/') {
        blockDepth -= 1;
        i += 2;
      } else {
        if (a === '\n') out += '\n';
        i += 1;
      }
      continue;
    }

    if (inString) {
      // Preserve line structure but hide string contents from source-profile rules.
      if (a === '\n') out += '\n';
      if (escaped) {
        escaped = false;
      } else if (a === '\\') {
        escaped = true;
      } else if (a === '"') {
        inString = false;
        out += '"';
      }
      i += 1;
      continue;
    }

    if (a === '-' && b === '-') {
      while (i < text.length && text[i] !== '\n') i += 1;
      continue;
    }
    if (a === '/' && b === '-') {
      blockDepth = 1;
      i += 2;
      continue;
    }
    if (a === '"') {
      inString = true;
      out += '"';
      i += 1;
      continue;
    }

    out += a;
    i += 1;
  }

  return out;
}

function lineNumber(text, index) {
  let line = 1;
  for (let i = 0; i < index; i += 1) {
    if (text.charCodeAt(i) === 10) line += 1;
  }
  return line;
}

function collectMatches(source, rules, file) {
  const findings = [];
  for (const [label, regex] of rules) {
    regex.lastIndex = 0;
    for (const match of source.matchAll(regex)) {
      findings.push({
        file,
        line: lineNumber(source, match.index ?? 0),
        label,
        sample: match[0].replace(/\s+/g, ' ').trim(),
      });
    }
  }
  return findings;
}

const hard = [];
const warnings = [];

for (const file of portableFiles) {
  const fullPath = path.join(kernelDir, file);
  const source = stripComments(fs.readFileSync(fullPath, 'utf8'));
  hard.push(...collectMatches(source, hardRules, file));
  warnings.push(...collectMatches(source, warnRules, file));
}

console.log(`PSC1 portability audit: ${portableFiles.length} portable kernel modules`);
console.log(`Host-boundary exclusions: ${[...hostBoundaryFiles].sort().join(', ')}`);

if (warnings.length > 0) {
  console.log(`\nWARN (${warnings.length}) — currently desugarable Lean conveniences:`);
  for (const finding of warnings) {
    console.log(`  ${finding.file}:${finding.line}: ${finding.label}: ${finding.sample}`);
  }
} else {
  console.log('\nWARN: none');
}

if (hard.length > 0) {
  console.error(`\nFAIL (${hard.length}) — non-portable architectural dependencies:`);
  for (const finding of hard) {
    console.error(`  ${finding.file}:${finding.line}: ${finding.label}: ${finding.sample}`);
  }
  process.exit(1);
}

console.log('\nPSC1 portability hard gate: PASS');
