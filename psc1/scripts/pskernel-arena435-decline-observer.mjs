// Diagnostic-only support embedded into a separately hashed generated module.
// It observes returns; it never substitutes an argument, callback or result.
const __ps$declineOperations = new Set([
  "psKernelDagAdmitDeclaration", "psKernelDagTryAdmitSimpleWithFuel",
  "psKernelV1AdmitDeclaration",
  "psKernelExprV2AdmissionEnsureSortWithFuel",
  "psKernelExprV2AdmissionIsPropWithFuel",
  "psKernelExprV2AdmissionCheckHeaderWithFuel",
  "psKernelExprV2AdmissionPrepareBodyWithFuel",
  "psKernelExprV2AdmissionCheckBodyWithFuel",
  "psKernelExprV2TryCheckStateWithFuel", "psKernelExprV2TryInferStateWithFuel",
  "psKernelExprV2TryInferenceStateWithFuel", "psKernelExprV2TryInferCoreWithFuel",
  "psKernelExprV2CheckWhnfWithFuel", "psKernelExprV2CheckWhnfCoreWithFuel",
  "psKernelExprV2TryDefEqStateWithFuel",
  "psKernelExprV2TryWhnfCoreModeWithLocalValuesFuel",
  "psKernelExprV2TryWhnfCoreWithLocalValuesFuel",
  "psKernelExprV2TryWhnfCoreWithPublicFuel",
  "psKernelExprV2TryWhnfStateWithLocalValuesFuel",
  "psKernelExprV2TryWhnfProjectionWith", "psKernelExprV2TryWhnfAppWith",
  "psKernelExprV2TryWhnfCompositeWith", "psKernelExprV2TryWhnfAfterCoreWith",
  "psKernelExprV2TryWhnfPublicNonterminalWith",
  "psKernelExprV2DefEqPrefixContinueWith",
  "psKernelExprV2DefEqProofIrrelevanceContinueWith",
  "psKernelExprV2DefEqLazyDeltaWithFuel",
  "psKernelExprV2DefEqLazyDeltaContinueWithFuel",
  "psKernelExprV2DefEqLazyDeltaAfterStepWith",
  "psKernelExprV2DefEqFullShapePositive",
  "psKernelExprV2DefEqFullShapeListsWithFuel",
  "psKernelExprV2DefEqFullShapeAppWith",
  "psKernelExprV2DefEqFullShapeEtaWith",
  "psKernelExprV2DefEqFullShapeWith",
  "psKernelExprV2DefEqResidualProjectionShortcut",
  "psKernelExprV2DefEqResidualAfterFullWhnfWith",
  "psKernelExprV2DefEqResidualWith"
]);
const __ps$declineActive = [];
const __ps$declineContinuations = new WeakMap();
let __ps$declineRequests = new WeakMap();
let __ps$declineTags = null, __ps$declineCalls = 0, __ps$declineEvents = 0;
let __ps$declineLimited = false, __ps$declineBatch = 0;
const __ps$declineSeen = new Set();
function __ps$declineLimit(reason) {
  if (__ps$declineLimited) return;
  __ps$declineLimited = true;
  __ps$traceWrite({format: "psc1-v2-decline-v1", kind: "observation_limit",
    reason, tracked_calls: __ps$declineCalls, emitted_events: __ps$declineEvents,
    steps: __ps$traceSteps, kernel_qualified: false});
}
function __ps$declineWrite(kind, fields) {
  if (__ps$declineEvents >= 512) { __ps$declineLimit("event bound"); return; }
  __ps$traceWrite({format: "psc1-v2-decline-v1", kind,
    event: ++__ps$declineEvents, steps: __ps$traceSteps,
    elapsed_ms_since_import: performance.now() - __ps$traceStarted,
    ...fields, kernel_qualified: false});
}
function __ps$declineTag(left, right) {
  const candidates = Object.getOwnPropertySymbols(left).filter(symbol =>
    Object.prototype.hasOwnProperty.call(right, symbol) && left[symbol] !== right[symbol]);
  if (candidates.length !== 1) throw Error("diagnostic constructor tag is ambiguous");
  const symbol = candidates[0];
  if (typeof left[symbol] !== "string" || typeof right[symbol] !== "string")
    throw Error("diagnostic constructor tag is not the generated string ABI");
  return {symbol, left: left[symbol], right: right[symbol]};
}
export function __psc1ConfigureDecline(entries, summary, none, some, ok, error) {
  if (!Array.isArray(entries) || entries.length > 256)
    throw Error("decline diagnostic command bound exceeded");
  if (__ps$declineActive.length !== 0)
    throw Error("decline diagnostic configuration inside active operation");
  const option = __ps$declineTag(none, some), except = __ps$declineTag(ok, error);
  __ps$declineTags = {option, except};
  __ps$declineRequests = new WeakMap();
  const batch = ++__ps$declineBatch;
  for (const entry of entries) {
    if (!entry.request || typeof entry.request !== "object")
      throw Error("decline diagnostic request identity is not an object");
    __ps$declineRequests.set(entry.request, {...entry.identity, batch});
  }
  __ps$declineWrite("declaration_table", {batch, summary});
}
function __ps$declineArgument(value) {
  if (typeof value === "bigint")
    return {kind: "nat", value: value >= 0n && value <= 0xffffffffffffffffffffffffffffffffn
      ? value.toString() : "<outside diagnostic scalar bound>"};
  if (typeof value === "boolean") return {kind: "bool", value};
  if (typeof value === "function") return {kind: "callback"};
  if (typeof value === "string") return {kind: "string", value: value.slice(0, 160)};
  if (!value || typeof value !== "object") return {kind: typeof value};
  const arena = value.whnf?.arena || value.arena;
  return {kind: "object", keys: Object.keys(value).slice(0, 8),
    ...(typeof arena?.size === "bigint" ? {arena_size: arena.size.toString()} : {})};
}
function __ps$declineCall(fn, args, implementation) {
  if (!__ps$declineTags) return null;
  const carried = __ps$declineContinuations.get(fn);
  const named = (implementation?.name || fn.name || "").replace(/^__ps\$impl\$/, "");
  const operation = carried?.operation || named;
  if (!__ps$declineOperations.has(operation)) return null;
  if (__ps$declineCalls >= 32768) { __ps$declineLimit("tracked-call bound"); return null; }
  let declaration = __ps$declineActive.length
    ? __ps$declineActive[__ps$declineActive.length - 1].declaration : null;
  if (operation === "psKernelDagAdmitDeclaration")
    declaration = __ps$declineRequests.get(args[3]) || {batch: __ps$declineBatch, unmapped: true};
  const info = {call: ++__ps$declineCalls, operation, declaration,
    arguments: [...(carried?.arguments || []), ...args.map(__ps$declineArgument)].slice(0, 16),
    stage: (carried?.stage || 0) + 1};
  __ps$declineActive.push(info);
  if (operation === "psKernelDagAdmitDeclaration")
    __ps$declineWrite("admission_enter", {call: info.call, declaration});
  if (operation === "psKernelV1AdmitDeclaration")
    __ps$declineWrite(declaration ? "whole_v1_fallback_enter" : "direct_v1_admission_enter",
      {call: info.call, declaration});
  return info;
}
function __ps$declineResult(value) {
  if (typeof value === "function") return {kind: "continuation"};
  if (!value || typeof value !== "object") return {kind: "not-an-observed-result"};
  const {option, except} = __ps$declineTags;
  if (value[option.symbol] === option.left) return {kind: "none"};
  if (value[option.symbol] === option.right) {
    const inner = value.value;
    if (inner && typeof inner === "object" && inner[except.symbol] === except.right)
      return {kind: "some-error", error: String(inner.error).slice(0, 256)};
    if (inner && typeof inner === "object" && inner[except.symbol] === except.left)
      return {kind: "some-ok"};
    return {kind: "some-non-except"};
  }
  if (value[except.symbol] === except.left) return {kind: "ok"};
  if (value[except.symbol] === except.right)
    return {kind: "error", error: String(value.error).slice(0, 256)};
  return {kind: "not-an-observed-result"};
}
function __ps$declineReturn(info, value) {
  if (!info) return;
  if (__ps$declineActive[__ps$declineActive.length - 1] !== info)
    throw Error("decline diagnostic frame ownership mismatch");
  const result = __ps$declineResult(value);
  if (result.kind === "continuation" && !__ps$declineContinuations.has(value))
    __ps$declineContinuations.set(value, {
      operation: info.operation, arguments: info.arguments, stage: info.stage});
  const boundary = info.operation === "psKernelDagTryAdmitSimpleWithFuel"
    || info.operation === "psKernelDagAdmitDeclaration"
    || info.operation === "psKernelV1AdmitDeclaration";
  const firstKey = JSON.stringify([info.declaration?.batch,
    info.declaration?.command_index, info.operation, result.kind]);
  const firstNone = result.kind === "none" && !__ps$declineSeen.has(firstKey);
  if (firstNone) __ps$declineSeen.add(firstKey);
  if (firstNone || (boundary && result.kind !== "continuation"))
    __ps$declineWrite(firstNone ? "first_none_return" : "admission_result", {
      ...info, result,
      active_operations: __ps$declineActive.slice(-16).map(frame =>
        ({call: frame.call, operation: frame.operation, stage: frame.stage}))});
  __ps$declineActive.pop();
}
function __ps$declineExit() {
  __ps$declineWrite("observation_exit", {tracked_calls: __ps$declineCalls,
    emitted_events: __ps$declineEvents, observation_limited: __ps$declineLimited,
    unfinished_observed_frames: __ps$declineActive.length});
}
