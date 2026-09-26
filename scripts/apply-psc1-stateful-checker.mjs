#!/usr/bin/env node

import fs from 'node:fs';

const path = 'psc1-kernel/PSC1Kernel/TypeChecker.lean';
let text = fs.readFileSync(path, 'utf8');

const importNeedle = 'import PSC1Kernel.Instantiate\n';
if (!text.includes('import PSC1Kernel.CheckerState\n')) {
  if (!text.includes(importNeedle)) throw new Error('TypeChecker import anchor missing');
  text = text.replace(importNeedle, importNeedle + 'import PSC1Kernel.CheckerState\n');
}

const oldTail = `def check (ctx : CheckerContext) (e : Expr) : Except String Expr :=\n  inferCore ctx e false\n\nend PSC1Kernel\n`;

const newTail = `def check (ctx : CheckerContext) (e : Expr) : Except String Expr :=\n  inferCore ctx e false\n\n/--\nState-threading entry point for declaration-scoped checked inference. This first\nstep deliberately reuses the existing pure checker body and makes the cache\nlifetime explicit; recursive operations will migrate behind this boundary one\nlayer at a time. Only successful results are memoized.\n-/\ndef checkStateful\n    (ctx : CheckerContext)\n    (state : CheckerState)\n    (e : Expr) : Except String (Expr × CheckerState) :=\n  match CheckerExprMap.get? state.checkedInfer e with\n  | some cached => .ok (cached, state)\n  | none =>\n      match check ctx e with\n      | .error err => .error err\n      | .ok result =>\n          let next := { state with\n            checkedInfer := CheckerExprMap.insert state.checkedInfer e result }\n          .ok (result, next)\n\n/-- Stateful infer-only entry point with a cache separate from checked inference. -/\ndef inferStateful\n    (ctx : CheckerContext)\n    (state : CheckerState)\n    (e : Expr) : Except String (Expr × CheckerState) :=\n  match CheckerExprMap.get? state.inferOnly e with\n  | some cached => .ok (cached, state)\n  | none =>\n      match infer ctx e with\n      | .error err => .error err\n      | .ok result =>\n          let next := { state with\n            inferOnly := CheckerExprMap.insert state.inferOnly e result }\n          .ok (result, next)\n\nend PSC1Kernel\n`;

if (!text.includes('def checkStateful')) {
  if (!text.includes(oldTail)) throw new Error('TypeChecker tail anchor missing');
  text = text.replace(oldTail, newTail);
}

fs.writeFileSync(path, text);
console.log('PSC1_STATEFUL_CHECKER_PATCH: boundary cache applied');
