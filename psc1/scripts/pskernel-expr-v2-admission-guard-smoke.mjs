import { pathToFileURL } from "node:url";
import path from "node:path";

const filename = process.argv[2];
if (!filename) throw Error("PSC1_ADMISSION_GUARD_REQUIRES_GENERATED_KERNEL");
const k = await import(pathToFileURL(path.resolve(filename)).href);
const get = name => {
  if (!(name in k)) throw Error("PSC1_ADMISSION_GUARD_MISSING_EXPORT " + name);
  return k[name];
};
let assertions = 0;
const must = (ok, label) => {
  if (ok !== true) throw Error("PSC1_ADMISSION_GUARD_FAILED " + label);
  assertions++;
};
const same = (left, right) => {
  if (Object.is(left, right)) return true;
  if (!left || !right || typeof left !== "object" || typeof right !== "object") return false;
  const a = Reflect.ownKeys(left), b = Reflect.ownKeys(right);
  return a.length === b.length && a.every(key => b.includes(key) && same(left[key], right[key]));
};
const atom = value => typeof value === "function" ? value() : value;
const Ex = get("Except"), Option = get("Option"), List = get("List");
const nil = atom(List.nil), none = atom(Option.none);
const list = values => values.reduceRight((tail, head) => List.cons(head, tail), nil);
const array = values => {
  const result = [];
  while (!same(values, nil)) {
    must(values && "head" in values && "tail" in values, "well-formed-list");
    result.push(values.head);
    values = values.tail;
  }
  return result;
};
const rejected = result => result && typeof result === "object" && "error" in result &&
  same(result, Ex.error(result.error));
const accepted = (result, label) => {
  if (result && typeof result === "object" && "value" in result && same(result, Ex.ok(result.value)))
    return result.value;
  throw Error("PSC1_ADMISSION_GUARD_REJECTED " + label);
};
const exactError = (result, message, label) => must(same(result, Ex.error(message)), label);
const N = get("PsKernelName"), L = get("PsKernelLevel"), E = get("PsKernelExpr");
const B = get("PsKernelBinderInfo"), S = get("PsKernelDefinitionSafety");
const D = get("PsKernelDagDeclarationRequest"), C = get("PsKernelDagCommand");
const Reply = get("PsKernelDagReply"), H = get("PsKernelReducibilityHints");
const Seen = get("PsKernelExprV2AdmissionSeen"), Node = get("PsKernelExprV2Node");
const name = text => N.str(atom(N.anonymous), text);
const u = name("guard-u"), v = name("guard-v"), x = name("guard-x");
const zero = atom(L.zero), defaultBinder = atom(B.default), safe = atom(S.safe);
const spec = (tag, ...args) => ({ tag, args });
const s0 = spec("sort", zero), s1 = spec("sort", L.succ(zero));
const su = spec("sort", L.param(u)), sv = spec("sort", L.param(v));
const sm = spec("sort", L.mvar(u)), fv = spec("fvar", x), mv = spec("mvar", x);
const Lit = get("PsKernelLiteral");
const fixtures = [
  ["bvar", spec("bvar", 0n)], ["fvar", fv], ["mvar", mv], ["sort-zero", s0],
  ["sort-u", su], ["sort-v", sv], ["sort-universe-mvar", sm],
  ["sort-nested", spec("sort", L.imax(L.max(zero, L.param(u)), L.succ(L.param(v))))],
  ["constant-empty", spec("const", name("C"), nil)],
  ["constant-uv", spec("const", name("C"), list([L.param(u), L.param(v)]))],
  ["constant-vu", spec("const", name("C"), list([L.param(v), L.param(u)]))],
  ["constant-universe-mvar", spec("const", name("C"), list([L.param(u), L.mvar(v)]))],
  ["nat-literal", spec("lit", Lit.nat(42n))], ["string-literal", spec("lit", Lit.str("λ雪😀"))],
  ["app-closed", spec("app", s0, s1)], ["app-uv", spec("app", su, sv)],
  ["app-vu", spec("app", sv, su)], ["fvar-before-universe-mvar", spec("app", fv, sm)],
  ["undefined-before-expression-mvar", spec("app", su, mv)],
  ["lambda-uv", spec("lam", x, su, sv, atom(B.implicit))],
  ["forall-vu", spec("forallE", x, sv, su, atom(B.strictImplicit))],
  ["let-uv-universe-mvar", spec("letE", x, su, sv, sm, false)],
  ["let-expression-mvar-fvar-u", spec("letE", x, mv, fv, su, true)],
  ["let-uv-closed", spec("letE", x, su, sv, s0, false)],
  ["metadata-u", spec("mdata", 73n, su)], ["projection-v", spec("proj", name("S"), 0n, sv)],
  ["fvar-before-undefined", spec("app", fv, su)],
  ["repeated-subterm", spec("app", spec("app", su, sv), spec("app", su, sv))]
];
const builderNames = {
  bvar: "BVar", fvar: "FVar", mvar: "MVar", sort: "Sort", const: "Const", lit: "Lit",
  app: "App", lam: "Lam", forallE: "Forall", letE: "Let", mdata: "MData", proj: "Proj"
};
const childSlots = { app: [0,1], lam: [1,2], forallE: [1,2], letE: [1,2,3], mdata: [1], proj: [2] };
function build(value, arena) {
  const terms = [...value.args], ids = [...value.args];
  for (const slot of childSlots[value.tag] ?? []) {
    const next = build(value.args[slot], arena);
    arena = next.arena; terms[slot] = next.term; ids[slot] = next.root;
  }
  const result = accepted(get("psKernelExprV2PagedMk" + builderNames[value.tag])(arena, ...ids), "builder");
  return { arena: result.fst, root: result.snd, term: E[value.tag](...terms) };
}
const empty = limit => get("psKernelExprV2PagedEmptyWithLimit")(limit);
const reference = (expr, allowed) => {
  const first = get("psKernelCheckNoMVarNoFVar")(expr);
  return rejected(first) ? first : get("psKernelCheckLevelParams")(expr, allowed);
};
const canonical = (arena, root, allowed) => get("psKernelExprV2AdmissionStaticOnCanonical")(arena, root, allowed);
const checked = (arena, root, allowed) => get("psKernelExprV2AdmissionStaticChecked")(arena, root, allowed);
const scan = (fuel, arena, allowed, seen, root, first) =>
  get("psKernelExprV2AdmissionScanWithFuel")(fuel)(arena)(allowed)(seen)(root)(first);
const seenEmpty = atom(Seen.empty);
const seenInsert = (seen, id) => get("psKernelExprV2AdmissionSeenInsert")(seen, id);
const seenContains = (seen, id) => get("psKernelExprV2AdmissionSeenContains")(seen, id);
const requireEntry = (arena, root) => accepted(get("psKernelExprV2PagedRequire")(arena, root), "entry");
const session = (fuel, depth) => accepted(get("psKernelKernelSessionEmpty")(
  { ...get("psKernelResourcePolicyDefault"), fuel, maxRecDepth: depth },
  get("psKernelProviderDefault")), "session");

must(fixtures.length === 28, "fixture-count");
let staticComparisons = 0;
for (const capacity of [1n,3n,64n]) {
  for (const [label, expression] of fixtures) {
    const input = build(expression, empty(capacity));
    for (const params of [[],[u],[v],[u,v],[u,u]]) {
      const allowed = list(params), expected = reference(input.term, allowed);
      must(same(expected, canonical(input.arena, input.root, allowed)), "canonical-" + label);
      must(same(expected, checked(input.arena, input.root, allowed)), "checked-" + label);
      if (get("psKernelExprHasMVar")(input.term) === false) {
        const entry = requireEntry(input.arena, input.root);
        const scanned = accepted(scan(entry.depth + 1n, input.arena, allowed, seenEmpty, input.root, none), label);
        must(same(scanned.snd, get("psKernelFindUndefExprLevelParam")(input.term, allowed)), "first-undefined-" + label);
        must(seenContains(scanned.fst, input.root) === true, "root-memoized-" + label);
      }
      staticComparisons++;
    }
  }
}
must(staticComparisons === 420, "static-count");

let seen = seenEmpty;
const collisionIds = [0n,65536n,131072n,1n,65537n,18446744073709551616n];
for (const id of collisionIds) {
  must(seenContains(seen, id) === false, "collision-miss-before-insert");
  seen = seenInsert(seen, id);
  must(seenContains(seen, id) === true, "exact-id-after-insert");
}
for (const id of collisionIds) must(seenContains(seen, id) === true, "earlier-collision-retained");
must(seenContains(seen, 196608n) === false, "uninserted-id-not-hash-hit");
exactError(scan(0n, empty(64n), nil, seen, 0n, none), "PSKERNEL_V2_ADMISSION_GUARD_FUEL", "zero-before-memo");
let hostile = 0;
for (const capacity of [1n,3n,64n]) {
  for (const [label, leaf, params, message] of [
    ["allowed", su, [u], null],
    ["undefined", su, [], "invalid reference to undefined universe level parameter"],
    ["level-mvar", sm, [], "declaration has metavariables"],
    ["fvar", fv, [], "declaration has free variables"]
  ]) {
    let { arena, root } = build(leaf, empty(capacity));
    for (let depth = 0; depth < 128; depth++) {
      const next = accepted(get("psKernelExprV2PagedMkApp")(arena, root, root), "shared-build");
      arena = next.fst; root = next.snd;
    }
    must(arena.size === 129n, "linear-shared-arena-" + label);
    const result = checked(arena, root, list(params));
    if (message === null) accepted(result, "shared-allowed");
    else exactError(result, message, "shared-" + label);
    hostile++;
  }
}
must(hostile === 12, "hostile-count");
const scoped = build(su, empty(64n));
for (const params of [[u],[],[u],[],[u]]) {
  const allowed = list(params);
  must(same(reference(scoped.term, allowed), canonical(scoped.arena, scoped.root, allowed)), "fresh-allowed-scope");
}
const firstKept = accepted(scan(2n, scoped.arena, nil, seenEmpty, scoped.root, Option.some(v)), "earlier-name");
must(same(firstKept.snd, Option.some(v)), "earlier-undefined-kept");
exactError(checked(empty(64n), 0n, nil), "PSKERNEL_V2_PAGED_INVALID_CHILD", "empty-root");
exactError(checked(scoped.arena, scoped.arena.size, nil), "PSKERNEL_V2_PAGED_INVALID_CHILD", "dangling-root");
const entry = requireEntry(scoped.arena, scoped.root);
const fvarInput = build(fv, empty(64n)), mvarInput = build(mv, empty(64n));
const fvarEntry = requireEntry(fvarInput.arena, fvarInput.root);
const mvarEntry = requireEntry(mvarInput.arena, mvarInput.root);
const raw = item => get("psKernelExprV2PagedPush")(empty(64n), item).fst;
const forged = [
  { ...scoped.arena, pageLimit: 0n }, raw({ ...fvarEntry, hasFVar: false }),
  raw({ ...mvarEntry, hasExprMVar: false }), raw({ ...entry, depth: 0n }),
  raw({ ...entry, node: Node.app(0n,0n) }), raw({ ...entry, node: Node.app(999n,0n) })
];
for (const arena of forged) {
  const validation = get("psKernelExprV2PagedValidate")(arena);
  must(rejected(validation), "forged-source-refused");
  must(same(validation, checked(arena, 0n, nil)), "validation-before-static-flags");
}

const infoEqual = (left, right) => {
  const a = get("psKernelConstantInfoBase")(left), b = get("psKernelConstantInfoBase")(right);
  return same(a.name,b.name) && same(a.levelParams,b.levelParams) &&
    get("psKernelExprEqual")(a.type)(b.type) === true && same(left,right);
};
const sameEnvironment = (left, right) => {
  const a = array(left.constants), b = array(right.constants);
  return left.quotInitialized === right.quotInitialized && a.length === b.length &&
    a.every((value,index) => infoEqual(value,b[index]));
};
const sameAdmission = (old, actual) => {
  if (rejected(old)) return rejected(actual) && same(old,actual);
  if (rejected(actual)) return false;
  const a = accepted(old, "old-admission"), b = accepted(actual, "dag-admission");
  const replies = array(b.replies);
  return sameEnvironment(a.session.environment,b.session.environment) && replies.length === 1 &&
    same(replies[0], Reply.admitted(a.declaration.receipt));
};
const target = name("GuardAdmissionCase");
let publicComparisons = 0;
for (const [label, expression] of fixtures) {
  const input = build(expression, empty(64n)), typeInput = build(s1, input.arena);
  const arena = typeInput.arena;
  const base = { name: target, levelParams: list([u]), type: input.root };
  const bodyBase = { ...base, type: typeInput.root };
  const decoded = accepted(get("psKernelExprV2DecodeChecked")(arena), "public-decode");
  const requests = [
    D.axiomDecl(base,false),
    D.definitionDecl({ base: bodyBase, value: input.root, hints: atom(H.abbrevHint), safety: safe })
  ];
  for (const request of requests) {
    const declaration = accepted(get("psKernelDagDecodeDeclaration")(decoded,request), "declaration");
    for (const fuel of [0n,1n,2n,8n,64n,4096n]) {
      for (const depth of [0n,1n]) {
        const seed = session(fuel,depth);
        const old = get("psKernelV1AdmitDeclaration")(seed,declaration);
        const actual = get("psKernelV1RunDag")(seed,nil,safe,arena,list([C.admit(request)]));
        must(sameAdmission(old,actual), "public-" + label + "/" + fuel);
        publicComparisons++;
      }
    }
  }
  const seed = session(64n,0n);
  const checker = get("psKernelKernelSessionChecker")(seed,list([u]),safe);
  const context = get("psKernelExprV2CheckContextEmpty")(checker.context);
  const state = get("psKernelExprV2CheckStateEmpty")(arena);
  const scalarBase = { name: target, levelParams: list([u]), type: typeInput.term };
  const expected = reference(input.term,list([u]));
  if (rejected(expected)) {
    const actual = get("psKernelExprV2AdmissionCheckBodyWithFuel")(
      0n,context,state,scalarBase,typeInput.root,input.term,input.root,"mismatch");
    must(same(actual,Option.some(expected)), "static-before-zero-checker-fuel-" + label);
  }
}
must(publicComparisons === 672, "public-count");
{
  const input = build(mv,empty(64n)), seed = session(64n,0n);
  const checker = get("psKernelKernelSessionChecker")(seed,nil,safe);
  const context = get("psKernelExprV2CheckContextEmpty")(checker.context);
  const state = get("psKernelExprV2CheckStateEmpty")(input.arena);
  const base = { name: target, levelParams: list([u,u]), type: input.term };
  const actual = get("psKernelExprV2AdmissionCheckHeaderWithFuel")(0n,context,state,base,input.root);
  must(same(actual,Option.some(Ex.error("duplicate universe parameter"))), "duplicate-before-mvar-and-zero");
}
console.log("PSC1_V2_ADMISSION_GUARD_JS: PASS staticComparisons=420 publicComparisons=672 sharedDepth=128 hostile=12 assertions=" + assertions);
