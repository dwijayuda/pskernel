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

const newTail = `def check (ctx : CheckerContext) (e : Expr) : Except String Expr :=\n  inferCore ctx e false\n\n/--\nStateful public WHNF boundary. Lean 4.34 has a distinct public-WHNF memo table\nfrom WHNF-core. This transitional implementation delegates the computation to\nthe proven pure checker while making the declaration-scoped cache explicit.\n-/\ndef whnfStateful\n    (ctx : CheckerContext)\n    (state : CheckerState)\n    (e : Expr) : Except String (Expr × CheckerState) :=\n  match CheckerExprMap.get? state.whnf e with\n  | some cached => .ok (cached, state)\n  | none =>\n      match whnf ctx e with\n      | .error err => .error err\n      | .ok result =>\n          let next := { state with\n            whnf := CheckerExprMap.insert state.whnf e result }\n          .ok (result, next)\n\nprivate def cacheInferStatefulResult\n    (state : CheckerState)\n    (inferOnly : Bool)\n    (e result : Expr) : CheckerState :=\n  if inferOnly then\n    { state with inferOnly := CheckerExprMap.insert state.inferOnly e result }\n  else\n    { state with checkedInfer := CheckerExprMap.insert state.checkedInfer e result }\n\n/--\nIncremental stateful counterpart of Lean 4.34 infer_type_core. Cache lookup is\nmode-specific. Checked application inference is already recursive and threads\nWHNF state; remaining forms deliberately delegate to the proven pure checker\nuntil their own RED tests migrate them.\n-/\npartial def inferCoreStateful\n    (ctx : CheckerContext)\n    (state : CheckerState)\n    (e : Expr)\n    (inferOnly : Bool) : Except String (Expr × CheckerState) :=\n  let cache := if inferOnly then state.inferOnly else state.checkedInfer\n  match CheckerExprMap.get? cache e with\n  | some cached => .ok (cached, state)\n  | none =>\n      match e with\n      | .app fn arg =>\n          if inferOnly then\n            match inferCore ctx e true with\n            | .error err => .error err\n            | .ok result => .ok (result, cacheInferStatefulResult state true e result)\n          else do\n            let (fnType, state1) ← inferCoreStateful ctx state fn false\n            let (fnTypeWhnf, state2) ← whnfStateful ctx state1 fnType\n            let .forallE _ domain body _ := fnTypeWhnf\n              | throw \"expected function type\"\n            let (argType, state3) ← inferCoreStateful ctx state2 arg false\n            let eqCtx :=\n              if isEagerReduceExpr arg then { ctx with eagerReduce := true } else ctx\n            let ok ← isDefEq eqCtx argType domain\n            if !ok then\n              throw \"application type mismatch\"\n            let result := body.instantiate1 arg\n            return (result, cacheInferStatefulResult state3 false e result)\n      | _ =>\n          match inferCore ctx e inferOnly with\n          | .error err => .error err\n          | .ok result => .ok (result, cacheInferStatefulResult state inferOnly e result)\n\n/-- Stateful checked-inference entry point. -/\ndef checkStateful\n    (ctx : CheckerContext)\n    (state : CheckerState)\n    (e : Expr) : Except String (Expr × CheckerState) :=\n  inferCoreStateful ctx state e false\n\n/-- Stateful infer-only entry point with a cache separate from checked inference. -/\ndef inferStateful\n    (ctx : CheckerContext)\n    (state : CheckerState)\n    (e : Expr) : Except String (Expr × CheckerState) :=\n  inferCoreStateful ctx state e true\n\nend PSC1Kernel\n`;

if (!text.includes('def checkStateful')) {
  if (!text.includes(oldTail)) throw new Error('TypeChecker tail anchor missing');
  text = text.replace(oldTail, newTail);
}

fs.writeFileSync(path, text);

const sessionPath = 'psc1-kernel/PSC1Kernel/CheckerSession.lean';
let sessionText = fs.readFileSync(sessionPath, 'utf8');

const oldSessionStruct = `structure CheckerSession where\n  context : CheckerContext\n`;
const newSessionStruct = `structure CheckerSession where\n  context : CheckerContext\n  /-- Pure declaration-scoped memo state; callers thread the returned session. -/\n  state : CheckerState := .empty\n`;
if (!sessionText.includes('state : CheckerState')) {
  if (!sessionText.includes(oldSessionStruct)) throw new Error('CheckerSession structure anchor missing');
  sessionText = sessionText.replace(oldSessionStruct, newSessionStruct);
}

const oldSessionTail = `def isDefEq (session : CheckerSession) (a b : Expr) : Except String Bool :=\n  PSC1Kernel.isDefEq session.context a b\n\nend CheckerSession\n`;
const newSessionTail = `def isDefEq (session : CheckerSession) (a b : Expr) : Except String Bool :=\n  PSC1Kernel.isDefEq session.context a b\n\n/--\nPure stateful checked inference. The updated session carries exactly the memo\nstate produced while checking this expression.\n-/\ndef checkStateful\n    (session : CheckerSession)\n    (e : Expr) : Except String (Expr × CheckerSession) := do\n  let (result, state) ← PSC1Kernel.checkStateful session.context session.state e\n  pure (result, { session with state := state })\n\n/-- Pure stateful infer-only entry point. -/\ndef inferStateful\n    (session : CheckerSession)\n    (e : Expr) : Except String (Expr × CheckerSession) := do\n  let (result, state) ← PSC1Kernel.inferStateful session.context session.state e\n  pure (result, { session with state := state })\n\n/-- Pure stateful public-WHNF entry point. -/\ndef whnfStateful\n    (session : CheckerSession)\n    (e : Expr) : Except String (Expr × CheckerSession) := do\n  let (result, state) ← PSC1Kernel.whnfStateful session.context session.state e\n  pure (result, { session with state := state })\n\nend CheckerSession\n`;
if (!sessionText.includes('def checkStateful')) {
  if (!sessionText.includes(oldSessionTail)) throw new Error('CheckerSession method anchor missing');
  sessionText = sessionText.replace(oldSessionTail, newSessionTail);
}

fs.writeFileSync(sessionPath, sessionText);
console.log('PSC1_STATEFUL_CHECKER_PATCH: recursive checker and pure session state flow applied');
