// generated from pskernel-admitted ProofScript checked core
const __ps$brand$0 = Symbol("ProofScript.Prod");
const __ps$tag$0 = Symbol("ProofScript.List.tag");
export const List = {
    "nil": () => ({ [__ps$tag$0]: "nil" }),
    "cons": (__field0, __field1) => ({ [__ps$tag$0]: "cons", head: __field0, tail: __field1 }),
};
const __ps$tag$1 = Symbol("ProofScript.Option.tag");
export const Option = {
    "none": () => ({ [__ps$tag$1]: "none" }),
    "some": (__field0) => ({ [__ps$tag$1]: "some", value: __field0 }),
};
const __ps$tag$2 = Symbol("ProofScript.Except.tag");
export const Except = {
    "error": (__field0) => ({ [__ps$tag$2]: "error", error: __field0 }),
    "ok": (__field0) => ({ [__ps$tag$2]: "ok", value: __field0 }),
};
const __ps$tag$3 = Symbol("ProofScript.PsKernelPositive.tag");
export const PsKernelPositive = {
    "one": { [__ps$tag$3]: "one" },
    "bit0": (__field0) => ({ [__ps$tag$3]: "bit0", high: __field0 }),
    "bit1": (__field0) => ({ [__ps$tag$3]: "bit1", high: __field0 }),
};
const __ps$tag$4 = Symbol("ProofScript.PsKernelNatural.tag");
export const PsKernelNatural = {
    "zero": { [__ps$tag$4]: "zero" },
    "positive": (__field0) => ({ [__ps$tag$4]: "positive", value: __field0 }),
};
const __ps$tag$5 = Symbol("ProofScript.PsKernelText.tag");
export const PsKernelText = {
    "empty": { [__ps$tag$5]: "empty" },
    "byte": (__field0, __field1) => ({ [__ps$tag$5]: "byte", value: __field0, rest: __field1 }),
};
const __ps$tag$6 = Symbol("ProofScript.PsKernelName.tag");
export const PsKernelName = {
    "anonymous": { [__ps$tag$6]: "anonymous" },
    "str": (__field0, __field1) => ({ [__ps$tag$6]: "str", parent: __field0, value: __field1 }),
    "num": (__field0, __field1) => ({ [__ps$tag$6]: "num", parent: __field0, value: __field1 }),
};
const __ps$tag$7 = Symbol("ProofScript.PsKernelLevel.tag");
export const PsKernelLevel = {
    "zero": { [__ps$tag$7]: "zero" },
    "succ": (__field0) => ({ [__ps$tag$7]: "succ", value: __field0 }),
    "max": (__field0, __field1) => ({ [__ps$tag$7]: "max", left: __field0, right: __field1 }),
    "imax": (__field0, __field1) => ({ [__ps$tag$7]: "imax", left: __field0, right: __field1 }),
    "param": (__field0) => ({ [__ps$tag$7]: "param", name: __field0 }),
};
const __ps$tag$8 = Symbol("ProofScript.PsKernelList.tag");
export const PsKernelList = {
    "nil": () => ({ [__ps$tag$8]: "nil" }),
    "cons": (__field0, __field1) => ({ [__ps$tag$8]: "cons", head: __field0, tail: __field1 }),
};
const __ps$tag$9 = Symbol("ProofScript.PsKernelCompareResult.tag");
export const PsKernelCompareResult = {
    "outOfFuel": { [__ps$tag$9]: "outOfFuel" },
    "equal": { [__ps$tag$9]: "equal" },
    "different": { [__ps$tag$9]: "different" },
};
const __ps$tag$10 = Symbol("ProofScript.PsKernelCompareTask.tag");
export const PsKernelCompareTask = {
    "positive": (__field0, __field1) => ({ [__ps$tag$10]: "positive", left: __field0, right: __field1 }),
    "natural": (__field0, __field1) => ({ [__ps$tag$10]: "natural", left: __field0, right: __field1 }),
    "name": (__field0, __field1) => ({ [__ps$tag$10]: "name", left: __field0, right: __field1 }),
    "text": (__field0, __field1) => ({ [__ps$tag$10]: "text", left: __field0, right: __field1 }),
    "level": (__field0, __field1) => ({ [__ps$tag$10]: "level", left: __field0, right: __field1 }),
};
const __ps$tag$11 = Symbol("ProofScript.PsKernelFuel.tag");
export const PsKernelFuel = {
    "stop": { [__ps$tag$11]: "stop" },
    "more": (__field0) => ({ [__ps$tag$11]: "more", remaining: __field0 }),
};
const __ps$tag$12 = Symbol("ProofScript.PsKernelFlag.tag");
export const PsKernelFlag = {
    "no": { [__ps$tag$12]: "no" },
    "yes": { [__ps$tag$12]: "yes" },
};
const __ps$tag$13 = Symbol("ProofScript.PsKernelOrder.tag");
export const PsKernelOrder = {
    "less": { [__ps$tag$13]: "less" },
    "same": { [__ps$tag$13]: "same" },
    "greater": { [__ps$tag$13]: "greater" },
};
const __ps$tag$14 = Symbol("ProofScript.PsKernelBit.tag");
export const PsKernelBit = {
    "zero": { [__ps$tag$14]: "zero" },
    "one": { [__ps$tag$14]: "one" },
};
const __ps$tag$15 = Symbol("ProofScript.PsKernelDigit.tag");
export const PsKernelDigit = {
    "digit": (__field0, __field1) => ({ [__ps$tag$15]: "digit", low: __field0, high: __field1 }),
};
const __ps$tag$16 = Symbol("ProofScript.PsKernelNumericState.tag");
export const PsKernelNumericState = {
    "order": (__field0, __field1, __field2) => ({ [__ps$tag$16]: "order", left: __field0, right: __field1, lower: __field2 }),
    "add": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$16]: "add", left: __field0, right: __field1, carry: __field2, bits: __field3 }),
    "rebuild": (__field0, __field1) => ({ [__ps$tag$16]: "rebuild", bits: __field0, value: __field1 }),
};
const __ps$tag$17 = Symbol("ProofScript.PsKernelNumericStep.tag");
export const PsKernelNumericStep = {
    "next": (__field0) => ({ [__ps$tag$17]: "next", state: __field0 }),
    "ordered": (__field0) => ({ [__ps$tag$17]: "ordered", order: __field0 }),
    "sum": (__field0) => ({ [__ps$tag$17]: "sum", value: __field0 }),
};
const __ps$tag$18 = Symbol("ProofScript.PsKernelNumericResult.tag");
export const PsKernelNumericResult = {
    "outOfFuel": { [__ps$tag$18]: "outOfFuel" },
    "ordered": (__field0) => ({ [__ps$tag$18]: "ordered", order: __field0 }),
    "sum": (__field0) => ({ [__ps$tag$18]: "sum", value: __field0 }),
};
const __ps$tag$19 = Symbol("ProofScript.PsKernelBinder.tag");
export const PsKernelBinder = {
    "explicit": { [__ps$tag$19]: "explicit" },
    "implicit": { [__ps$tag$19]: "implicit" },
    "strictImplicit": { [__ps$tag$19]: "strictImplicit" },
    "instanceImplicit": { [__ps$tag$19]: "instanceImplicit" },
};
const __ps$tag$20 = Symbol("ProofScript.PsKernelLiteral.tag");
export const PsKernelLiteral = {
    "natural": (__field0) => ({ [__ps$tag$20]: "natural", value: __field0 }),
    "text": (__field0) => ({ [__ps$tag$20]: "text", value: __field0 }),
};
const __ps$tag$21 = Symbol("ProofScript.PsKernelExpr.tag");
export const PsKernelExpr = {
    "bvar": (__field0) => ({ [__ps$tag$21]: "bvar", index: __field0 }),
    "fvar": (__field0) => ({ [__ps$tag$21]: "fvar", id: __field0 }),
    "sortE": (__field0) => ({ [__ps$tag$21]: "sortE", level: __field0 }),
    "constE": (__field0, __field1) => ({ [__ps$tag$21]: "constE", name: __field0, levels: __field1 }),
    "app": (__field0, __field1) => ({ [__ps$tag$21]: "app", fn: __field0, arg: __field1 }),
    "lam": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$21]: "lam", name: __field0, type: __field1, body: __field2, binder: __field3 }),
    "forallE": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$21]: "forallE", name: __field0, type: __field1, body: __field2, binder: __field3 }),
    "letE": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$21]: "letE", name: __field0, type: __field1, value: __field2, body: __field3 }),
    "lit": (__field0) => ({ [__ps$tag$21]: "lit", value: __field0 }),
    "proj": (__field0, __field1, __field2) => ({ [__ps$tag$21]: "proj", family: __field0, index: __field1, value: __field2 }),
};
const __ps$tag$22 = Symbol("ProofScript.PsKernelBindingMode.tag");
export const PsKernelBindingMode = {
    "lift": (__field0) => ({ [__ps$tag$22]: "lift", amount: __field0 }),
    "instantiate": (__field0) => ({ [__ps$tag$22]: "instantiate", replacement: __field0 }),
    "abstract": (__field0) => ({ [__ps$tag$22]: "abstract", id: __field0 }),
    "closed": { [__ps$tag$22]: "closed" },
};
const __ps$tag$23 = Symbol("ProofScript.PsKernelBindingTask.tag");
export const PsKernelBindingTask = {
    "visit": (__field0, __field1, __field2) => ({ [__ps$tag$23]: "visit", mode: __field0, depth: __field1, value: __field2 }),
    "orderIndex": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$23]: "orderIndex", mode: __field0, depth: __field1, index: __field2, state: __field3 }),
    "orderFree": (__field0, __field1, __field2) => ({ [__ps$tag$23]: "orderFree", depth: __field0, id: __field1, state: __field2 }),
    "sumIndex": (__field0) => ({ [__ps$tag$23]: "sumIndex", state: __field0 }),
    "app": { [__ps$tag$23]: "app" },
    "lam": (__field0, __field1) => ({ [__ps$tag$23]: "lam", name: __field0, binder: __field1 }),
    "forallE": (__field0, __field1) => ({ [__ps$tag$23]: "forallE", name: __field0, binder: __field1 }),
    "letE": (__field0) => ({ [__ps$tag$23]: "letE", name: __field0 }),
    "proj": (__field0, __field1) => ({ [__ps$tag$23]: "proj", family: __field0, index: __field1 }),
};
const __ps$tag$24 = Symbol("ProofScript.PsKernelBindingState.tag");
export const PsKernelBindingState = {
    "state": (__field0, __field1) => ({ [__ps$tag$24]: "state", tasks: __field0, values: __field1 }),
};
const __ps$tag$25 = Symbol("ProofScript.PsKernelBindingResult.tag");
export const PsKernelBindingResult = {
    "outOfFuel": { [__ps$tag$25]: "outOfFuel" },
    "invalidState": { [__ps$tag$25]: "invalidState" },
    "invalidScope": { [__ps$tag$25]: "invalidScope" },
    "done": (__field0) => ({ [__ps$tag$25]: "done", value: __field0 }),
};
const __ps$tag$26 = Symbol("ProofScript.PsKernelBindingStep.tag");
export const PsKernelBindingStep = {
    "next": (__field0) => ({ [__ps$tag$26]: "next", state: __field0 }),
    "final": (__field0) => ({ [__ps$tag$26]: "final", result: __field0 }),
};
const __ps$tag$27 = Symbol("ProofScript.PsKernelOrderTask.tag");
export const PsKernelOrderTask = {
    "name": (__field0, __field1) => ({ [__ps$tag$27]: "name", left: __field0, right: __field1 }),
    "text": (__field0, __field1) => ({ [__ps$tag$27]: "text", left: __field0, right: __field1 }),
    "level": (__field0, __field1) => ({ [__ps$tag$27]: "level", left: __field0, right: __field1 }),
    "number": (__field0) => ({ [__ps$tag$27]: "number", state: __field0 }),
};
const __ps$tag$28 = Symbol("ProofScript.PsKernelOrderStep.tag");
export const PsKernelOrderStep = {
    "next": (__field0) => ({ [__ps$tag$28]: "next", tasks: __field0 }),
    "done": (__field0) => ({ [__ps$tag$28]: "done", order: __field0 }),
    "invalidState": { [__ps$tag$28]: "invalidState" },
};
const __ps$tag$29 = Symbol("ProofScript.PsKernelLevelOffset.tag");
export const PsKernelLevelOffset = {
    "parts": (__field0, __field1) => ({ [__ps$tag$29]: "parts", base: __field0, count: __field1 }),
};
const __ps$tag$30 = Symbol("ProofScript.PsKernelMaxProbe.tag");
export const PsKernelMaxProbe = {
    "probe": (__field0, __field1, __field2) => ({ [__ps$tag$30]: "probe", left: __field0, right: __field1, result: __field2 }),
};
const __ps$tag$31 = Symbol("ProofScript.PsKernelUniverseTask.tag");
export const PsKernelUniverseTask = {
    "normalize": (__field0, __field1) => ({ [__ps$tag$31]: "normalize", value: __field0, offset: __field1 }),
    "joinMax": (__field0) => ({ [__ps$tag$31]: "joinMax", offset: __field0 }),
    "joinIMax": (__field0) => ({ [__ps$tag$31]: "joinIMax", offset: __field0 }),
    "wrap": (__field0, __field1) => ({ [__ps$tag$31]: "wrap", value: __field0, offset: __field1 }),
    "imaxCompare": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$31]: "imaxCompare", left: __field0, right: __field1, offset: __field2, work: __field3 }),
    "maxBases": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$31]: "maxBases", left: __field0, right: __field1, offset: __field2, work: __field3 }),
    "maxOffsets": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$31]: "maxOffsets", left: __field0, right: __field1, offset: __field2, numeric: __field3 }),
    "probeMax": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$31]: "probeMax", left: __field0, right: __field1, offset: __field2, probes: __field3 }),
    "probeCompare": (__field0, __field1, __field2, __field3, __field4, __field5) => ({ [__ps$tag$31]: "probeCompare", left: __field0, right: __field1, offset: __field2, result: __field3, probes: __field4, work: __field5 }),
    "collect": (__field0, __field1, __field2) => ({ [__ps$tag$31]: "collect", offset: __field0, todo: __field1, leaves: __field2 }),
    "sort": (__field0, __field1, __field2) => ({ [__ps$tag$31]: "sort", offset: __field0, todo: __field1, sorted: __field2 }),
    "insert": (__field0, __field1, __field2, __field3, __field4) => ({ [__ps$tag$31]: "insert", offset: __field0, todo: __field1, candidate: __field2, scan: __field3, prefix: __field4 }),
    "insertCompare": (__field0, __field1, __field2, __field3, __field4, __field5, __field6) => ({ [__ps$tag$31]: "insertCompare", offset: __field0, todo: __field1, candidate: __field2, current: __field3, tail: __field4, prefix: __field5, work: __field6 }),
    "insertOffset": (__field0, __field1, __field2, __field3, __field4, __field5, __field6) => ({ [__ps$tag$31]: "insertOffset", offset: __field0, todo: __field1, candidate: __field2, current: __field3, tail: __field4, prefix: __field5, numeric: __field6 }),
    "restore": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$31]: "restore", offset: __field0, todo: __field1, prefix: __field2, suffix: __field3 }),
    "prune": (__field0, __field1) => ({ [__ps$tag$31]: "prune", offset: __field0, sorted: __field1 }),
    "constantScan": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$31]: "constantScan", offset: __field0, constant: __field1, others: __field2, scan: __field3 }),
    "constantCompare": (__field0, __field1, __field2, __field3, __field4) => ({ [__ps$tag$31]: "constantCompare", offset: __field0, constant: __field1, others: __field2, scan: __field3, numeric: __field4 }),
    "wrapList": (__field0, __field1, __field2) => ({ [__ps$tag$31]: "wrapList", offset: __field0, todo: __field1, doneRev: __field2 }),
    "wrapped": (__field0, __field1, __field2) => ({ [__ps$tag$31]: "wrapped", offset: __field0, todo: __field1, doneRev: __field2 }),
    "assemble": (__field0, __field1) => ({ [__ps$tag$31]: "assemble", todo: __field0, value: __field1 }),
};
const __ps$tag$32 = Symbol("ProofScript.PsKernelUniverseState.tag");
export const PsKernelUniverseState = {
    "state": (__field0, __field1) => ({ [__ps$tag$32]: "state", tasks: __field0, values: __field1 }),
};
const __ps$tag$33 = Symbol("ProofScript.PsKernelUniverseResult.tag");
export const PsKernelUniverseResult = {
    "outOfFuel": { [__ps$tag$33]: "outOfFuel" },
    "invalidState": { [__ps$tag$33]: "invalidState" },
    "done": (__field0) => ({ [__ps$tag$33]: "done", value: __field0 }),
};
const __ps$tag$34 = Symbol("ProofScript.PsKernelUniverseStep.tag");
export const PsKernelUniverseStep = {
    "next": (__field0) => ({ [__ps$tag$34]: "next", state: __field0 }),
    "final": (__field0) => ({ [__ps$tag$34]: "final", result: __field0 }),
};
const __ps$tag$35 = Symbol("ProofScript.PsKernelLevelCheckState.tag");
export const PsKernelLevelCheckState = {
    "left": (__field0, __field1) => ({ [__ps$tag$35]: "left", right: __field0, state: __field1 }),
    "right": (__field0, __field1) => ({ [__ps$tag$35]: "right", left: __field0, state: __field1 }),
    "order": (__field0) => ({ [__ps$tag$35]: "order", tasks: __field0 }),
};
const __ps$tag$36 = Symbol("ProofScript.PsKernelLevelCheckResult.tag");
export const PsKernelLevelCheckResult = {
    "outOfFuel": { [__ps$tag$36]: "outOfFuel" },
    "invalidState": { [__ps$tag$36]: "invalidState" },
    "equal": { [__ps$tag$36]: "equal" },
    "different": { [__ps$tag$36]: "different" },
};
const __ps$tag$37 = Symbol("ProofScript.PsKernelLevelCheckStep.tag");
export const PsKernelLevelCheckStep = {
    "next": (__field0) => ({ [__ps$tag$37]: "next", state: __field0 }),
    "final": (__field0) => ({ [__ps$tag$37]: "final", result: __field0 }),
};
const __ps$tag$38 = Symbol("ProofScript.PsKernelDefinition.tag");
export const PsKernelDefinition = {
    "definition": (__field0, __field1, __field2) => ({ [__ps$tag$38]: "definition", name: __field0, type: __field1, value: __field2 }),
};
const __ps$tag$39 = Symbol("ProofScript.PsKernelCheckError.tag");
export const PsKernelCheckError = {
    "invalidState": { [__ps$tag$39]: "invalidState" },
    "invalidScope": { [__ps$tag$39]: "invalidScope" },
    "unknownConstant": { [__ps$tag$39]: "unknownConstant" },
    "unsupported": { [__ps$tag$39]: "unsupported" },
    "typeExpected": { [__ps$tag$39]: "typeExpected" },
    "functionExpected": { [__ps$tag$39]: "functionExpected" },
    "typeMismatch": { [__ps$tag$39]: "typeMismatch" },
    "duplicateName": { [__ps$tag$39]: "duplicateName" },
    "invalidName": { [__ps$tag$39]: "invalidName" },
};
const __ps$tag$40 = Symbol("ProofScript.PsKernelLookupState.tag");
export const PsKernelLookupState = {
    "search": (__field0, __field1) => ({ [__ps$tag$40]: "search", name: __field0, entries: __field1 }),
    "compare": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$40]: "compare", name: __field0, entry: __field1, rest: __field2, tasks: __field3 }),
};
const __ps$tag$41 = Symbol("ProofScript.PsKernelLookupStep.tag");
export const PsKernelLookupStep = {
    "next": (__field0) => ({ [__ps$tag$41]: "next", state: __field0 }),
    "found": (__field0) => ({ [__ps$tag$41]: "found", entry: __field0 }),
    "missing": { [__ps$tag$41]: "missing" },
    "invalidState": { [__ps$tag$41]: "invalidState" },
};
const __ps$tag$42 = Symbol("ProofScript.PsKernelReduceTask.tag");
export const PsKernelReduceTask = {
    "whnf": (__field0) => ({ [__ps$tag$42]: "whnf", value: __field0 }),
    "apply": (__field0) => ({ [__ps$tag$42]: "apply", arg: __field0 }),
    "lookup": (__field0) => ({ [__ps$tag$42]: "lookup", state: __field0 }),
    "binding": (__field0) => ({ [__ps$tag$42]: "binding", state: __field0 }),
    "resumeWhnf": { [__ps$tag$42]: "resumeWhnf" },
    "normal": (__field0) => ({ [__ps$tag$42]: "normal", value: __field0 }),
    "expand": { [__ps$tag$42]: "expand" },
    "app": { [__ps$tag$42]: "app" },
    "lam": (__field0, __field1) => ({ [__ps$tag$42]: "lam", name: __field0, binder: __field1 }),
    "forallE": (__field0, __field1) => ({ [__ps$tag$42]: "forallE", name: __field0, binder: __field1 }),
};
const __ps$tag$43 = Symbol("ProofScript.PsKernelReduceState.tag");
export const PsKernelReduceState = {
    "state": (__field0, __field1, __field2) => ({ [__ps$tag$43]: "state", environment: __field0, tasks: __field1, values: __field2 }),
};
const __ps$tag$44 = Symbol("ProofScript.PsKernelReduceResult.tag");
export const PsKernelReduceResult = {
    "outOfFuel": { [__ps$tag$44]: "outOfFuel" },
    "rejected": (__field0) => ({ [__ps$tag$44]: "rejected", error: __field0 }),
    "done": (__field0) => ({ [__ps$tag$44]: "done", value: __field0 }),
};
const __ps$tag$45 = Symbol("ProofScript.PsKernelReduceStep.tag");
export const PsKernelReduceStep = {
    "next": (__field0) => ({ [__ps$tag$45]: "next", state: __field0 }),
    "final": (__field0) => ({ [__ps$tag$45]: "final", result: __field0 }),
};
const __ps$tag$46 = Symbol("ProofScript.PsKernelConversionTask.tag");
export const PsKernelConversionTask = {
    "expr": (__field0, __field1) => ({ [__ps$tag$46]: "expr", left: __field0, right: __field1 }),
    "natural": (__field0) => ({ [__ps$tag$46]: "natural", state: __field0 }),
    "level": (__field0) => ({ [__ps$tag$46]: "level", state: __field0 }),
};
const __ps$tag$47 = Symbol("ProofScript.PsKernelConversionState.tag");
export const PsKernelConversionState = {
    "left": (__field0, __field1, __field2) => ({ [__ps$tag$47]: "left", environment: __field0, right: __field1, state: __field2 }),
    "right": (__field0, __field1) => ({ [__ps$tag$47]: "right", left: __field0, state: __field1 }),
    "compare": (__field0) => ({ [__ps$tag$47]: "compare", tasks: __field0 }),
};
const __ps$tag$48 = Symbol("ProofScript.PsKernelConversionResult.tag");
export const PsKernelConversionResult = {
    "outOfFuel": { [__ps$tag$48]: "outOfFuel" },
    "rejected": (__field0) => ({ [__ps$tag$48]: "rejected", error: __field0 }),
    "equal": { [__ps$tag$48]: "equal" },
    "different": { [__ps$tag$48]: "different" },
};
const __ps$tag$49 = Symbol("ProofScript.PsKernelConversionStep.tag");
export const PsKernelConversionStep = {
    "next": (__field0) => ({ [__ps$tag$49]: "next", state: __field0 }),
    "final": (__field0) => ({ [__ps$tag$49]: "final", result: __field0 }),
};
const __ps$tag$50 = Symbol("ProofScript.PsKernelTypeTask.tag");
export const PsKernelTypeTask = {
    "infer": (__field0, __field1) => ({ [__ps$tag$50]: "infer", context: __field0, value: __field1 }),
    "levels": (__field0, __field1) => ({ [__ps$tag$50]: "levels", pending: __field0, result: __field1 }),
    "bound": (__field0, __field1, __field2) => ({ [__ps$tag$50]: "bound", context: __field0, index: __field1, shift: __field2 }),
    "lookup": (__field0) => ({ [__ps$tag$50]: "lookup", state: __field0 }),
    "binding": (__field0) => ({ [__ps$tag$50]: "binding", state: __field0 }),
    "reduce": (__field0) => ({ [__ps$tag$50]: "reduce", state: __field0 }),
    "reduceTop": { [__ps$tag$50]: "reduceTop" },
    "conversion": (__field0) => ({ [__ps$tag$50]: "conversion", state: __field0 }),
    "returnE": (__field0) => ({ [__ps$tag$50]: "returnE", value: __field0 }),
    "lamSort": (__field0, __field1, __field2, __field3, __field4) => ({ [__ps$tag$50]: "lamSort", context: __field0, name: __field1, type: __field2, body: __field3, binder: __field4 }),
    "lamFinish": (__field0, __field1, __field2) => ({ [__ps$tag$50]: "lamFinish", name: __field0, type: __field1, binder: __field2 }),
    "piDomain": (__field0, __field1, __field2) => ({ [__ps$tag$50]: "piDomain", context: __field0, type: __field1, body: __field2 }),
    "piFinish": (__field0) => ({ [__ps$tag$50]: "piFinish", domainLevel: __field0 }),
    "appPi": (__field0, __field1) => ({ [__ps$tag$50]: "appPi", context: __field0, arg: __field1 }),
    "appArgument": (__field0, __field1, __field2) => ({ [__ps$tag$50]: "appArgument", domain: __field0, body: __field1, arg: __field2 }),
    "letSort": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$50]: "letSort", context: __field0, type: __field1, value: __field2, body: __field3 }),
    "letValue": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$50]: "letValue", context: __field0, type: __field1, value: __field2, body: __field3 }),
    "letBody": (__field0) => ({ [__ps$tag$50]: "letBody", context: __field0 }),
    "checkSort": (__field0, __field1) => ({ [__ps$tag$50]: "checkSort", value: __field0, type: __field1 }),
    "checkValue": (__field0) => ({ [__ps$tag$50]: "checkValue", type: __field0 }),
};
const __ps$tag$51 = Symbol("ProofScript.PsKernelTypeState.tag");
export const PsKernelTypeState = {
    "state": (__field0, __field1, __field2) => ({ [__ps$tag$51]: "state", environment: __field0, tasks: __field1, values: __field2 }),
};
const __ps$tag$52 = Symbol("ProofScript.PsKernelTypeResult.tag");
export const PsKernelTypeResult = {
    "outOfFuel": { [__ps$tag$52]: "outOfFuel" },
    "rejected": (__field0) => ({ [__ps$tag$52]: "rejected", error: __field0 }),
    "done": (__field0) => ({ [__ps$tag$52]: "done", type: __field0 }),
};
const __ps$tag$53 = Symbol("ProofScript.PsKernelTypeStep.tag");
export const PsKernelTypeStep = {
    "next": (__field0) => ({ [__ps$tag$53]: "next", state: __field0 }),
    "final": (__field0) => ({ [__ps$tag$53]: "final", result: __field0 }),
};
const __ps$tag$54 = Symbol("ProofScript.PsKernelAdmissionState.tag");
export const PsKernelAdmissionState = {
    "pending": (__field0, __field1) => ({ [__ps$tag$54]: "pending", environment: __field0, entries: __field1 }),
    "duplicate": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$54]: "duplicate", environment: __field0, entry: __field1, rest: __field2, state: __field3 }),
    "checking": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$54]: "checking", environment: __field0, entry: __field1, rest: __field2, state: __field3 }),
};
const __ps$tag$55 = Symbol("ProofScript.PsKernelAdmissionResult.tag");
export const PsKernelAdmissionResult = {
    "outOfFuel": { [__ps$tag$55]: "outOfFuel" },
    "rejected": (__field0) => ({ [__ps$tag$55]: "rejected", error: __field0 }),
    "admitted": (__field0) => ({ [__ps$tag$55]: "admitted", environment: __field0 }),
};
const __ps$tag$56 = Symbol("ProofScript.PsKernelAdmissionStep.tag");
export const PsKernelAdmissionStep = {
    "next": (__field0) => ({ [__ps$tag$56]: "next", state: __field0 }),
    "final": (__field0) => ({ [__ps$tag$56]: "final", result: __field0 }),
};
export function psKernelCompareTasks(fuel) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$11]) {
    case "stop": return (tasks) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
        case "nil": return PsKernelCompareResult["equal"];
        case "cons": return ((unusedHead, unusedTail) => PsKernelCompareResult["outOfFuel"])(__ps$match$0.head, __ps$match$0.tail);
    } throw new Error("invalid ProofScript constructor tag"); })(tasks);
    case "more": return ((remaining) => (() => { const smaller = psKernelCompareTasks(remaining); return (tasks) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
        case "nil": return PsKernelCompareResult["equal"];
        case "cons": return ((task, rest) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$10]) {
            case "positive": return ((left, right) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$3]) {
                case "one": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$3]) {
                    case "one": return smaller(rest);
                    case "bit0": return ((_wild0) => PsKernelCompareResult["different"])(__ps$match$0.high);
                    case "bit1": return ((_wild0) => PsKernelCompareResult["different"])(__ps$match$0.high);
                } throw new Error("invalid ProofScript constructor tag"); })(right);
                case "bit0": return ((leftHigh) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$3]) {
                    case "one": return PsKernelCompareResult["different"];
                    case "bit0": return ((rightHigh) => smaller(PsKernelList["cons"](PsKernelCompareTask["positive"](leftHigh, rightHigh), rest)))(__ps$match$0.high);
                    case "bit1": return ((_wild0) => PsKernelCompareResult["different"])(__ps$match$0.high);
                } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.high);
                case "bit1": return ((leftHigh) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$3]) {
                    case "one": return PsKernelCompareResult["different"];
                    case "bit0": return ((_wild0) => PsKernelCompareResult["different"])(__ps$match$0.high);
                    case "bit1": return ((rightHigh) => smaller(PsKernelList["cons"](PsKernelCompareTask["positive"](leftHigh, rightHigh), rest)))(__ps$match$0.high);
                } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.high);
            } throw new Error("invalid ProofScript constructor tag"); })(left))(__ps$match$0.left, __ps$match$0.right);
            case "natural": return ((left, right) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$4]) {
                case "zero": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$4]) {
                    case "zero": return smaller(rest);
                    case "positive": return ((_wild0) => PsKernelCompareResult["different"])(__ps$match$0.value);
                } throw new Error("invalid ProofScript constructor tag"); })(right);
                case "positive": return ((leftValue) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$4]) {
                    case "zero": return PsKernelCompareResult["different"];
                    case "positive": return ((rightValue) => smaller(PsKernelList["cons"](PsKernelCompareTask["positive"](leftValue, rightValue), rest)))(__ps$match$0.value);
                } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.value);
            } throw new Error("invalid ProofScript constructor tag"); })(left))(__ps$match$0.left, __ps$match$0.right);
            case "name": return ((left, right) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$6]) {
                case "anonymous": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$6]) {
                    case "anonymous": return smaller(rest);
                    case "str": return ((_wild0, _wild1) => PsKernelCompareResult["different"])(__ps$match$0.parent, __ps$match$0.value);
                    case "num": return ((_wild0, _wild1) => PsKernelCompareResult["different"])(__ps$match$0.parent, __ps$match$0.value);
                } throw new Error("invalid ProofScript constructor tag"); })(right);
                case "str": return ((leftParent, leftValue) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$6]) {
                    case "anonymous": return PsKernelCompareResult["different"];
                    case "str": return ((rightParent, rightValue) => smaller(PsKernelList["cons"](PsKernelCompareTask["name"](leftParent, rightParent), PsKernelList["cons"](PsKernelCompareTask["text"](leftValue, rightValue), rest))))(__ps$match$0.parent, __ps$match$0.value);
                    case "num": return ((_wild0, _wild1) => PsKernelCompareResult["different"])(__ps$match$0.parent, __ps$match$0.value);
                } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.parent, __ps$match$0.value);
                case "num": return ((leftParent, leftValue) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$6]) {
                    case "anonymous": return PsKernelCompareResult["different"];
                    case "str": return ((_wild0, _wild1) => PsKernelCompareResult["different"])(__ps$match$0.parent, __ps$match$0.value);
                    case "num": return ((rightParent, rightValue) => smaller(PsKernelList["cons"](PsKernelCompareTask["name"](leftParent, rightParent), PsKernelList["cons"](PsKernelCompareTask["natural"](leftValue, rightValue), rest))))(__ps$match$0.parent, __ps$match$0.value);
                } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.parent, __ps$match$0.value);
            } throw new Error("invalid ProofScript constructor tag"); })(left))(__ps$match$0.left, __ps$match$0.right);
            case "text": return ((left, right) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$5]) {
                case "empty": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$5]) {
                    case "empty": return smaller(rest);
                    case "byte": return ((_wild0, _wild1) => PsKernelCompareResult["different"])(__ps$match$0.value, __ps$match$0.rest);
                } throw new Error("invalid ProofScript constructor tag"); })(right);
                case "byte": return ((leftByte, leftRest) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$5]) {
                    case "empty": return PsKernelCompareResult["different"];
                    case "byte": return ((rightByte, rightRest) => smaller(PsKernelList["cons"](PsKernelCompareTask["natural"](leftByte, rightByte), PsKernelList["cons"](PsKernelCompareTask["text"](leftRest, rightRest), rest))))(__ps$match$0.value, __ps$match$0.rest);
                } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.value, __ps$match$0.rest);
            } throw new Error("invalid ProofScript constructor tag"); })(left))(__ps$match$0.left, __ps$match$0.right);
            case "level": return ((left, right) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
                case "zero": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
                    case "zero": return smaller(rest);
                    case "succ": return ((_wild0) => PsKernelCompareResult["different"])(__ps$match$0.value);
                    case "max": return ((_wild0, _wild1) => PsKernelCompareResult["different"])(__ps$match$0.left, __ps$match$0.right);
                    case "imax": return ((_wild0, _wild1) => PsKernelCompareResult["different"])(__ps$match$0.left, __ps$match$0.right);
                    case "param": return ((_wild0) => PsKernelCompareResult["different"])(__ps$match$0.name);
                } throw new Error("invalid ProofScript constructor tag"); })(right);
                case "succ": return ((leftValue) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
                    case "zero": return PsKernelCompareResult["different"];
                    case "succ": return ((rightValue) => smaller(PsKernelList["cons"](PsKernelCompareTask["level"](leftValue, rightValue), rest)))(__ps$match$0.value);
                    case "max": return ((_wild0, _wild1) => PsKernelCompareResult["different"])(__ps$match$0.left, __ps$match$0.right);
                    case "imax": return ((_wild0, _wild1) => PsKernelCompareResult["different"])(__ps$match$0.left, __ps$match$0.right);
                    case "param": return ((_wild0) => PsKernelCompareResult["different"])(__ps$match$0.name);
                } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.value);
                case "max": return ((leftA, leftB) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
                    case "zero": return PsKernelCompareResult["different"];
                    case "succ": return ((_wild0) => PsKernelCompareResult["different"])(__ps$match$0.value);
                    case "max": return ((rightA, rightB) => smaller(PsKernelList["cons"](PsKernelCompareTask["level"](leftA, rightA), PsKernelList["cons"](PsKernelCompareTask["level"](leftB, rightB), rest))))(__ps$match$0.left, __ps$match$0.right);
                    case "imax": return ((_wild0, _wild1) => PsKernelCompareResult["different"])(__ps$match$0.left, __ps$match$0.right);
                    case "param": return ((_wild0) => PsKernelCompareResult["different"])(__ps$match$0.name);
                } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.left, __ps$match$0.right);
                case "imax": return ((leftA, leftB) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
                    case "zero": return PsKernelCompareResult["different"];
                    case "succ": return ((_wild0) => PsKernelCompareResult["different"])(__ps$match$0.value);
                    case "max": return ((_wild0, _wild1) => PsKernelCompareResult["different"])(__ps$match$0.left, __ps$match$0.right);
                    case "imax": return ((rightA, rightB) => smaller(PsKernelList["cons"](PsKernelCompareTask["level"](leftA, rightA), PsKernelList["cons"](PsKernelCompareTask["level"](leftB, rightB), rest))))(__ps$match$0.left, __ps$match$0.right);
                    case "param": return ((_wild0) => PsKernelCompareResult["different"])(__ps$match$0.name);
                } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.left, __ps$match$0.right);
                case "param": return ((leftName) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
                    case "zero": return PsKernelCompareResult["different"];
                    case "succ": return ((_wild0) => PsKernelCompareResult["different"])(__ps$match$0.value);
                    case "max": return ((_wild0, _wild1) => PsKernelCompareResult["different"])(__ps$match$0.left, __ps$match$0.right);
                    case "imax": return ((_wild0, _wild1) => PsKernelCompareResult["different"])(__ps$match$0.left, __ps$match$0.right);
                    case "param": return ((rightName) => smaller(PsKernelList["cons"](PsKernelCompareTask["name"](leftName, rightName), rest)))(__ps$match$0.name);
                } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.name);
            } throw new Error("invalid ProofScript constructor tag"); })(left))(__ps$match$0.left, __ps$match$0.right);
        } throw new Error("invalid ProofScript constructor tag"); })(task))(__ps$match$0.head, __ps$match$0.tail);
    } throw new Error("invalid ProofScript constructor tag"); })(tasks); })())(__ps$match$0.remaining);
} throw new Error("invalid ProofScript constructor tag"); })(fuel); }
export function psKernelPositiveSucc(value) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$3]) {
    case "one": return PsKernelPositive["bit0"](PsKernelPositive["one"]);
    case "bit0": return ((high) => PsKernelPositive["bit1"](high))(__ps$match$0.high);
    case "bit1": return ((high) => PsKernelPositive["bit0"](psKernelPositiveSucc(high)))(__ps$match$0.high);
} throw new Error("invalid ProofScript constructor tag"); })(value); }
export function psKernelNaturalSucc(value) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$4]) {
    case "zero": return PsKernelNatural["positive"](PsKernelPositive["one"]);
    case "positive": return ((high) => PsKernelNatural["positive"](psKernelPositiveSucc(high)))(__ps$match$0.value);
} throw new Error("invalid ProofScript constructor tag"); })(value); }
export function psKernelPositivePred(value) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$3]) {
    case "one": return PsKernelNatural["zero"];
    case "bit0": return ((high) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$4]) {
        case "zero": return PsKernelNatural["positive"](PsKernelPositive["one"]);
        case "positive": return ((rest) => PsKernelNatural["positive"](PsKernelPositive["bit1"](rest)))(__ps$match$0.value);
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelPositivePred(high)))(__ps$match$0.high);
    case "bit1": return ((high) => PsKernelNatural["positive"](PsKernelPositive["bit0"](high)))(__ps$match$0.high);
} throw new Error("invalid ProofScript constructor tag"); })(value); }
export function psKernelNaturalPred(value) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$4]) {
    case "zero": return PsKernelNatural["zero"];
    case "positive": return ((high) => psKernelPositivePred(high))(__ps$match$0.value);
} throw new Error("invalid ProofScript constructor tag"); })(value); }
export function psKernelNaturalDigit(value) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$4]) {
    case "zero": return PsKernelDigit["digit"](PsKernelBit["zero"], PsKernelNatural["zero"]);
    case "positive": return ((positive) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$3]) {
        case "one": return PsKernelDigit["digit"](PsKernelBit["one"], PsKernelNatural["zero"]);
        case "bit0": return ((high) => PsKernelDigit["digit"](PsKernelBit["zero"], PsKernelNatural["positive"](high)))(__ps$match$0.high);
        case "bit1": return ((high) => PsKernelDigit["digit"](PsKernelBit["one"], PsKernelNatural["positive"](high)))(__ps$match$0.high);
    } throw new Error("invalid ProofScript constructor tag"); })(positive))(__ps$match$0.value);
} throw new Error("invalid ProofScript constructor tag"); })(value); }
export function psKernelNaturalDoubleBit(value, bit) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$4]) {
    case "zero": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$14]) {
        case "zero": return PsKernelNatural["zero"];
        case "one": return PsKernelNatural["positive"](PsKernelPositive["one"]);
    } throw new Error("invalid ProofScript constructor tag"); })(bit);
    case "positive": return ((high) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$14]) {
        case "zero": return PsKernelNatural["positive"](PsKernelPositive["bit0"](high));
        case "one": return PsKernelNatural["positive"](PsKernelPositive["bit1"](high));
    } throw new Error("invalid ProofScript constructor tag"); })(bit))(__ps$match$0.value);
} throw new Error("invalid ProofScript constructor tag"); })(value); }
export function psKernelNumericAddContinue(left, right, carry, bit, bits) { return PsKernelNumericStep["next"](PsKernelNumericState["add"](left, right, carry, PsKernelList["cons"](bit, bits))); }
export function psKernelNumericAddDigits(left, right, a, b, carry, bits) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$14]) {
    case "zero": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$14]) {
        case "zero": return psKernelNumericAddContinue(left, right, PsKernelBit["zero"], carry, bits);
        case "one": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$14]) {
            case "zero": return psKernelNumericAddContinue(left, right, PsKernelBit["zero"], PsKernelBit["one"], bits);
            case "one": return psKernelNumericAddContinue(left, right, PsKernelBit["one"], PsKernelBit["zero"], bits);
        } throw new Error("invalid ProofScript constructor tag"); })(carry);
    } throw new Error("invalid ProofScript constructor tag"); })(b);
    case "one": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$14]) {
        case "zero": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$14]) {
            case "zero": return psKernelNumericAddContinue(left, right, PsKernelBit["zero"], PsKernelBit["one"], bits);
            case "one": return psKernelNumericAddContinue(left, right, PsKernelBit["one"], PsKernelBit["zero"], bits);
        } throw new Error("invalid ProofScript constructor tag"); })(carry);
        case "one": return psKernelNumericAddContinue(left, right, PsKernelBit["one"], carry, bits);
    } throw new Error("invalid ProofScript constructor tag"); })(b);
} throw new Error("invalid ProofScript constructor tag"); })(a); }
export function psKernelNumericStep(state) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$16]) {
    case "order": return ((left, right, lower) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$4]) {
        case "zero": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$4]) {
            case "zero": return PsKernelNumericStep["ordered"](lower);
            case "positive": return ((_wild0) => PsKernelNumericStep["ordered"](PsKernelOrder["less"]))(__ps$match$0.value);
        } throw new Error("invalid ProofScript constructor tag"); })(right);
        case "positive": return ((unusedLeft) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$4]) {
            case "zero": return PsKernelNumericStep["ordered"](PsKernelOrder["greater"]);
            case "positive": return ((unusedRight) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$15]) {
                case "digit": return ((a, leftHigh) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$15]) {
                    case "digit": return ((b, rightHigh) => (() => { const nextOrder = ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$14]) {
                        case "zero": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$14]) {
                            case "zero": return lower;
                            case "one": return PsKernelOrder["less"];
                        } throw new Error("invalid ProofScript constructor tag"); })(b);
                        case "one": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$14]) {
                            case "zero": return PsKernelOrder["greater"];
                            case "one": return lower;
                        } throw new Error("invalid ProofScript constructor tag"); })(b);
                    } throw new Error("invalid ProofScript constructor tag"); })(a); return PsKernelNumericStep["next"](PsKernelNumericState["order"](leftHigh, rightHigh, nextOrder)); })())(__ps$match$0.low, __ps$match$0.high);
                } throw new Error("invalid ProofScript constructor tag"); })(psKernelNaturalDigit(right)))(__ps$match$0.low, __ps$match$0.high);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelNaturalDigit(left)))(__ps$match$0.value);
        } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.value);
    } throw new Error("invalid ProofScript constructor tag"); })(left))(__ps$match$0.left, __ps$match$0.right, __ps$match$0.lower);
    case "add": return ((left, right, carry, bits) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$15]) {
        case "digit": return ((a, leftHigh) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$15]) {
            case "digit": return ((b, rightHigh) => (() => { const allZero = ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$4]) {
                case "zero": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$4]) {
                    case "zero": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$14]) {
                        case "zero": return PsKernelFlag["yes"];
                        case "one": return PsKernelFlag["no"];
                    } throw new Error("invalid ProofScript constructor tag"); })(carry);
                    case "positive": return ((_wild0) => PsKernelFlag["no"])(__ps$match$0.value);
                } throw new Error("invalid ProofScript constructor tag"); })(right);
                case "positive": return ((_wild0) => PsKernelFlag["no"])(__ps$match$0.value);
            } throw new Error("invalid ProofScript constructor tag"); })(left); return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$12]) {
                case "no": return psKernelNumericAddDigits(leftHigh, rightHigh, a, b, carry, bits);
                case "yes": return PsKernelNumericStep["next"](PsKernelNumericState["rebuild"](bits, PsKernelNatural["zero"]));
            } throw new Error("invalid ProofScript constructor tag"); })(allZero); })())(__ps$match$0.low, __ps$match$0.high);
        } throw new Error("invalid ProofScript constructor tag"); })(psKernelNaturalDigit(right)))(__ps$match$0.low, __ps$match$0.high);
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelNaturalDigit(left)))(__ps$match$0.left, __ps$match$0.right, __ps$match$0.carry, __ps$match$0.bits);
    case "rebuild": return ((bits, value) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
        case "nil": return PsKernelNumericStep["sum"](value);
        case "cons": return ((bit, rest) => PsKernelNumericStep["next"](PsKernelNumericState["rebuild"](rest, psKernelNaturalDoubleBit(value, bit))))(__ps$match$0.head, __ps$match$0.tail);
    } throw new Error("invalid ProofScript constructor tag"); })(bits))(__ps$match$0.bits, __ps$match$0.value);
} throw new Error("invalid ProofScript constructor tag"); })(state); }
export function psKernelNumericRun(fuel) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$11]) {
    case "stop": return (state) => PsKernelNumericResult["outOfFuel"];
    case "more": return ((remaining) => (state) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$17]) {
        case "next": return ((next) => (() => { const smaller = psKernelNumericRun(remaining); return smaller(next); })())(__ps$match$0.state);
        case "ordered": return ((order) => PsKernelNumericResult["ordered"](order))(__ps$match$0.order);
        case "sum": return ((value) => PsKernelNumericResult["sum"](value))(__ps$match$0.value);
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelNumericStep(state)))(__ps$match$0.remaining);
} throw new Error("invalid ProofScript constructor tag"); })(fuel); }
export function psKernelBindingPush(tasks, values, value) { return PsKernelBindingStep["next"](PsKernelBindingState["state"](tasks, PsKernelList["cons"](value, values))); }
export function psKernelBindingAfterOrder(mode, depth, index, order, tasks, values) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$22]) {
    case "lift": return ((amount) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$13]) {
        case "less": return psKernelBindingPush(tasks, values, PsKernelExpr["bvar"](index));
        case "same": return PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["sumIndex"](PsKernelNumericState["add"](index, amount, PsKernelBit["zero"], PsKernelList["nil"]())), tasks), values));
        case "greater": return PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["sumIndex"](PsKernelNumericState["add"](index, amount, PsKernelBit["zero"], PsKernelList["nil"]())), tasks), values));
    } throw new Error("invalid ProofScript constructor tag"); })(order))(__ps$match$0.amount);
    case "instantiate": return ((replacement) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$13]) {
        case "less": return psKernelBindingPush(tasks, values, PsKernelExpr["bvar"](index));
        case "same": return PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["visit"](PsKernelBindingMode["lift"](depth), PsKernelNatural["zero"], replacement), tasks), values));
        case "greater": return psKernelBindingPush(tasks, values, PsKernelExpr["bvar"](psKernelNaturalPred(index)));
    } throw new Error("invalid ProofScript constructor tag"); })(order))(__ps$match$0.replacement);
    case "abstract": return ((unusedId) => psKernelBindingPush(tasks, values, PsKernelExpr["bvar"](index)))(__ps$match$0.id);
    case "closed": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$13]) {
        case "less": return psKernelBindingPush(tasks, values, PsKernelExpr["bvar"](index));
        case "same": return PsKernelBindingStep["final"](PsKernelBindingResult["invalidScope"]);
        case "greater": return PsKernelBindingStep["final"](PsKernelBindingResult["invalidScope"]);
    } throw new Error("invalid ProofScript constructor tag"); })(order);
} throw new Error("invalid ProofScript constructor tag"); })(mode); }
export function psKernelBindingVisit(mode, depth, value, tasks, values) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$21]) {
    case "bvar": return ((index) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$22]) {
        case "lift": return ((_wild0) => PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["orderIndex"](mode, depth, index, PsKernelNumericState["order"](index, depth, PsKernelOrder["same"])), tasks), values)))(__ps$match$0.amount);
        case "instantiate": return ((_wild0) => PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["orderIndex"](mode, depth, index, PsKernelNumericState["order"](index, depth, PsKernelOrder["same"])), tasks), values)))(__ps$match$0.replacement);
        case "abstract": return ((unusedId) => psKernelBindingPush(tasks, values, value))(__ps$match$0.id);
        case "closed": return PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["orderIndex"](mode, depth, index, PsKernelNumericState["order"](index, depth, PsKernelOrder["same"])), tasks), values));
    } throw new Error("invalid ProofScript constructor tag"); })(mode))(__ps$match$0.index);
    case "fvar": return ((id) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$22]) {
        case "lift": return ((_wild0) => psKernelBindingPush(tasks, values, value))(__ps$match$0.amount);
        case "instantiate": return ((_wild0) => psKernelBindingPush(tasks, values, value))(__ps$match$0.replacement);
        case "abstract": return ((target) => PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["orderFree"](depth, id, PsKernelNumericState["order"](id, target, PsKernelOrder["same"])), tasks), values)))(__ps$match$0.id);
        case "closed": return PsKernelBindingStep["final"](PsKernelBindingResult["invalidScope"]);
    } throw new Error("invalid ProofScript constructor tag"); })(mode))(__ps$match$0.id);
    case "sortE": return ((unused) => psKernelBindingPush(tasks, values, value))(__ps$match$0.level);
    case "constE": return ((unusedName, unusedLevels) => psKernelBindingPush(tasks, values, value))(__ps$match$0.name, __ps$match$0.levels);
    case "app": return ((fn, arg) => PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["visit"](mode, depth, fn), PsKernelList["cons"](PsKernelBindingTask["visit"](mode, depth, arg), PsKernelList["cons"](PsKernelBindingTask["app"], tasks))), values)))(__ps$match$0.fn, __ps$match$0.arg);
    case "lam": return ((name, type, body, binder) => PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["visit"](mode, depth, type), PsKernelList["cons"](PsKernelBindingTask["visit"](mode, psKernelNaturalSucc(depth), body), PsKernelList["cons"](PsKernelBindingTask["lam"](name, binder), tasks))), values)))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
    case "forallE": return ((name, type, body, binder) => PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["visit"](mode, depth, type), PsKernelList["cons"](PsKernelBindingTask["visit"](mode, psKernelNaturalSucc(depth), body), PsKernelList["cons"](PsKernelBindingTask["forallE"](name, binder), tasks))), values)))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
    case "letE": return ((name, type, val, body) => PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["visit"](mode, depth, type), PsKernelList["cons"](PsKernelBindingTask["visit"](mode, depth, val), PsKernelList["cons"](PsKernelBindingTask["visit"](mode, psKernelNaturalSucc(depth), body), PsKernelList["cons"](PsKernelBindingTask["letE"](name), tasks)))), values)))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
    case "lit": return ((unused) => psKernelBindingPush(tasks, values, value))(__ps$match$0.value);
    case "proj": return ((family, index, target) => PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["visit"](mode, depth, target), PsKernelList["cons"](PsKernelBindingTask["proj"](family, index), tasks)), values)))(__ps$match$0.family, __ps$match$0.index, __ps$match$0.value);
} throw new Error("invalid ProofScript constructor tag"); })(value); }
export function psKernelBindingRebuild(task, tasks, values) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
    case "nil": return PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]);
    case "cons": return ((top, rest) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$23]) {
        case "visit": return ((_wild0, _wild1, _wild2) => PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]))(__ps$match$0.mode, __ps$match$0.depth, __ps$match$0.value);
        case "orderIndex": return ((_wild0, _wild1, _wild2, _wild3) => PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]))(__ps$match$0.mode, __ps$match$0.depth, __ps$match$0.index, __ps$match$0.state);
        case "orderFree": return ((_wild0, _wild1, _wild2) => PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]))(__ps$match$0.depth, __ps$match$0.id, __ps$match$0.state);
        case "sumIndex": return ((_wild0) => PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]))(__ps$match$0.state);
        case "app": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]);
            case "cons": return ((fn, tail) => psKernelBindingPush(tasks, tail, PsKernelExpr["app"](fn, top)))(__ps$match$0.head, __ps$match$0.tail);
        } throw new Error("invalid ProofScript constructor tag"); })(rest);
        case "lam": return ((name, binder) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]);
            case "cons": return ((type, tail) => psKernelBindingPush(tasks, tail, PsKernelExpr["lam"](name, type, top, binder)))(__ps$match$0.head, __ps$match$0.tail);
        } throw new Error("invalid ProofScript constructor tag"); })(rest))(__ps$match$0.name, __ps$match$0.binder);
        case "forallE": return ((name, binder) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]);
            case "cons": return ((type, tail) => psKernelBindingPush(tasks, tail, PsKernelExpr["forallE"](name, type, top, binder)))(__ps$match$0.head, __ps$match$0.tail);
        } throw new Error("invalid ProofScript constructor tag"); })(rest))(__ps$match$0.name, __ps$match$0.binder);
        case "letE": return ((name) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]);
            case "cons": return ((val, tail) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]);
                case "cons": return ((type, remaining) => psKernelBindingPush(tasks, remaining, PsKernelExpr["letE"](name, type, val, top)))(__ps$match$0.head, __ps$match$0.tail);
            } throw new Error("invalid ProofScript constructor tag"); })(tail))(__ps$match$0.head, __ps$match$0.tail);
        } throw new Error("invalid ProofScript constructor tag"); })(rest))(__ps$match$0.name);
        case "proj": return ((family, index) => psKernelBindingPush(tasks, rest, PsKernelExpr["proj"](family, index, top)))(__ps$match$0.family, __ps$match$0.index);
    } throw new Error("invalid ProofScript constructor tag"); })(task))(__ps$match$0.head, __ps$match$0.tail);
} throw new Error("invalid ProofScript constructor tag"); })(values); }
export function psKernelBindingFinish(values) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
    case "nil": return PsKernelBindingResult["invalidState"];
    case "cons": return ((value, rest) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
        case "nil": return PsKernelBindingResult["done"](value);
        case "cons": return ((_wild0, _wild1) => PsKernelBindingResult["invalidState"])(__ps$match$0.head, __ps$match$0.tail);
    } throw new Error("invalid ProofScript constructor tag"); })(rest))(__ps$match$0.head, __ps$match$0.tail);
} throw new Error("invalid ProofScript constructor tag"); })(values); }
export function psKernelBindingStep(state) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$24]) {
    case "state": return ((tasks, values) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
        case "nil": return PsKernelBindingStep["final"](psKernelBindingFinish(values));
        case "cons": return ((task, rest) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$23]) {
            case "visit": return ((mode, depth, value) => psKernelBindingVisit(mode, depth, value, rest, values))(__ps$match$0.mode, __ps$match$0.depth, __ps$match$0.value);
            case "orderIndex": return ((mode, depth, index, numeric) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$17]) {
                case "next": return ((next) => PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["orderIndex"](mode, depth, index, next), rest), values)))(__ps$match$0.state);
                case "ordered": return ((order) => psKernelBindingAfterOrder(mode, depth, index, order, rest, values))(__ps$match$0.order);
                case "sum": return ((_wild0) => PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]))(__ps$match$0.value);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelNumericStep(numeric)))(__ps$match$0.mode, __ps$match$0.depth, __ps$match$0.index, __ps$match$0.state);
            case "orderFree": return ((depth, id, numeric) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$17]) {
                case "next": return ((next) => PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["orderFree"](depth, id, next), rest), values)))(__ps$match$0.state);
                case "ordered": return ((order) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$13]) {
                    case "less": return psKernelBindingPush(rest, values, PsKernelExpr["fvar"](id));
                    case "same": return psKernelBindingPush(rest, values, PsKernelExpr["bvar"](depth));
                    case "greater": return psKernelBindingPush(rest, values, PsKernelExpr["fvar"](id));
                } throw new Error("invalid ProofScript constructor tag"); })(order))(__ps$match$0.order);
                case "sum": return ((_wild0) => PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]))(__ps$match$0.value);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelNumericStep(numeric)))(__ps$match$0.depth, __ps$match$0.id, __ps$match$0.state);
            case "sumIndex": return ((numeric) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$17]) {
                case "next": return ((next) => PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["sumIndex"](next), rest), values)))(__ps$match$0.state);
                case "ordered": return ((_wild0) => PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]))(__ps$match$0.order);
                case "sum": return ((index) => psKernelBindingPush(rest, values, PsKernelExpr["bvar"](index)))(__ps$match$0.value);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelNumericStep(numeric)))(__ps$match$0.state);
            case "app": return psKernelBindingRebuild(task, rest, values);
            case "lam": return ((_wild0, _wild1) => psKernelBindingRebuild(task, rest, values))(__ps$match$0.name, __ps$match$0.binder);
            case "forallE": return ((_wild0, _wild1) => psKernelBindingRebuild(task, rest, values))(__ps$match$0.name, __ps$match$0.binder);
            case "letE": return ((_wild0) => psKernelBindingRebuild(task, rest, values))(__ps$match$0.name);
            case "proj": return ((_wild0, _wild1) => psKernelBindingRebuild(task, rest, values))(__ps$match$0.family, __ps$match$0.index);
        } throw new Error("invalid ProofScript constructor tag"); })(task))(__ps$match$0.head, __ps$match$0.tail);
    } throw new Error("invalid ProofScript constructor tag"); })(tasks))(__ps$match$0.tasks, __ps$match$0.values);
} throw new Error("invalid ProofScript constructor tag"); })(state); }
export function psKernelBindingStart(mode, depth, value) { return PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["visit"](mode, depth, value), PsKernelList["nil"]()), PsKernelList["nil"]()); }
export function psKernelBindingRun(fuel) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$11]) {
    case "stop": return (state) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$24]) {
        case "state": return ((tasks, values) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return psKernelBindingFinish(values);
            case "cons": return ((_wild0, _wild1) => PsKernelBindingResult["outOfFuel"])(__ps$match$0.head, __ps$match$0.tail);
        } throw new Error("invalid ProofScript constructor tag"); })(tasks))(__ps$match$0.tasks, __ps$match$0.values);
    } throw new Error("invalid ProofScript constructor tag"); })(state);
    case "more": return ((remaining) => (state) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$26]) {
        case "next": return ((next) => (() => { const smaller = psKernelBindingRun(remaining); return smaller(next); })())(__ps$match$0.state);
        case "final": return ((result) => result)(__ps$match$0.result);
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelBindingStep(state)))(__ps$match$0.remaining);
} throw new Error("invalid ProofScript constructor tag"); })(fuel); }
export function psKernelOrderStep(tasks) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
    case "nil": return PsKernelOrderStep["done"](PsKernelOrder["same"]);
    case "cons": return ((task, rest) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$27]) {
        case "name": return ((left, right) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$6]) {
            case "anonymous": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$6]) {
                case "anonymous": return PsKernelOrderStep["next"](rest);
                case "str": return ((rParent, rValue) => PsKernelOrderStep["done"](PsKernelOrder["less"]))(__ps$match$0.parent, __ps$match$0.value);
                case "num": return ((rParent, rValue) => PsKernelOrderStep["done"](PsKernelOrder["less"]))(__ps$match$0.parent, __ps$match$0.value);
            } throw new Error("invalid ProofScript constructor tag"); })(right);
            case "str": return ((lParent, lValue) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$6]) {
                case "anonymous": return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                case "str": return ((rParent, rValue) => PsKernelOrderStep["next"](PsKernelList["cons"](PsKernelOrderTask["name"](lParent, rParent), PsKernelList["cons"](PsKernelOrderTask["text"](lValue, rValue), rest))))(__ps$match$0.parent, __ps$match$0.value);
                case "num": return ((rParent, rValue) => PsKernelOrderStep["done"](PsKernelOrder["less"]))(__ps$match$0.parent, __ps$match$0.value);
            } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.parent, __ps$match$0.value);
            case "num": return ((lParent, lValue) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$6]) {
                case "anonymous": return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                case "str": return ((rParent, rValue) => PsKernelOrderStep["done"](PsKernelOrder["greater"]))(__ps$match$0.parent, __ps$match$0.value);
                case "num": return ((rParent, rValue) => PsKernelOrderStep["next"](PsKernelList["cons"](PsKernelOrderTask["name"](lParent, rParent), PsKernelList["cons"](PsKernelOrderTask["number"](PsKernelNumericState["order"](lValue, rValue, PsKernelOrder["same"])), rest))))(__ps$match$0.parent, __ps$match$0.value);
            } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.parent, __ps$match$0.value);
        } throw new Error("invalid ProofScript constructor tag"); })(left))(__ps$match$0.left, __ps$match$0.right);
        case "text": return ((left, right) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$5]) {
            case "empty": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$5]) {
                case "empty": return PsKernelOrderStep["next"](rest);
                case "byte": return ((rValue, rRest) => PsKernelOrderStep["done"](PsKernelOrder["less"]))(__ps$match$0.value, __ps$match$0.rest);
            } throw new Error("invalid ProofScript constructor tag"); })(right);
            case "byte": return ((lValue, lRest) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$5]) {
                case "empty": return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                case "byte": return ((rValue, rRest) => PsKernelOrderStep["next"](PsKernelList["cons"](PsKernelOrderTask["number"](PsKernelNumericState["order"](lValue, rValue, PsKernelOrder["same"])), PsKernelList["cons"](PsKernelOrderTask["text"](lRest, rRest), rest))))(__ps$match$0.value, __ps$match$0.rest);
            } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.value, __ps$match$0.rest);
        } throw new Error("invalid ProofScript constructor tag"); })(left))(__ps$match$0.left, __ps$match$0.right);
        case "level": return ((left, right) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
            case "zero": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
                case "zero": return PsKernelOrderStep["next"](rest);
                case "succ": return ((rValue) => PsKernelOrderStep["done"](PsKernelOrder["less"]))(__ps$match$0.value);
                case "max": return ((rLeft, rRight) => PsKernelOrderStep["done"](PsKernelOrder["less"]))(__ps$match$0.left, __ps$match$0.right);
                case "imax": return ((rLeft, rRight) => PsKernelOrderStep["done"](PsKernelOrder["less"]))(__ps$match$0.left, __ps$match$0.right);
                case "param": return ((rName) => PsKernelOrderStep["done"](PsKernelOrder["less"]))(__ps$match$0.name);
            } throw new Error("invalid ProofScript constructor tag"); })(right);
            case "succ": return ((lValue) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
                case "zero": return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                case "succ": return ((rValue) => PsKernelOrderStep["next"](PsKernelList["cons"](PsKernelOrderTask["level"](lValue, rValue), rest)))(__ps$match$0.value);
                case "max": return ((rLeft, rRight) => PsKernelOrderStep["done"](PsKernelOrder["less"]))(__ps$match$0.left, __ps$match$0.right);
                case "imax": return ((rLeft, rRight) => PsKernelOrderStep["done"](PsKernelOrder["less"]))(__ps$match$0.left, __ps$match$0.right);
                case "param": return ((rName) => PsKernelOrderStep["done"](PsKernelOrder["less"]))(__ps$match$0.name);
            } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.value);
            case "max": return ((lLeft, lRight) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
                case "zero": return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                case "succ": return ((rValue) => PsKernelOrderStep["done"](PsKernelOrder["greater"]))(__ps$match$0.value);
                case "max": return ((rLeft, rRight) => PsKernelOrderStep["next"](PsKernelList["cons"](PsKernelOrderTask["level"](lLeft, rLeft), PsKernelList["cons"](PsKernelOrderTask["level"](lRight, rRight), rest))))(__ps$match$0.left, __ps$match$0.right);
                case "imax": return ((rLeft, rRight) => PsKernelOrderStep["done"](PsKernelOrder["less"]))(__ps$match$0.left, __ps$match$0.right);
                case "param": return ((rName) => PsKernelOrderStep["done"](PsKernelOrder["less"]))(__ps$match$0.name);
            } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.left, __ps$match$0.right);
            case "imax": return ((lLeft, lRight) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
                case "zero": return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                case "succ": return ((rValue) => PsKernelOrderStep["done"](PsKernelOrder["greater"]))(__ps$match$0.value);
                case "max": return ((rLeft, rRight) => PsKernelOrderStep["done"](PsKernelOrder["greater"]))(__ps$match$0.left, __ps$match$0.right);
                case "imax": return ((rLeft, rRight) => PsKernelOrderStep["next"](PsKernelList["cons"](PsKernelOrderTask["level"](lLeft, rLeft), PsKernelList["cons"](PsKernelOrderTask["level"](lRight, rRight), rest))))(__ps$match$0.left, __ps$match$0.right);
                case "param": return ((rName) => PsKernelOrderStep["done"](PsKernelOrder["less"]))(__ps$match$0.name);
            } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.left, __ps$match$0.right);
            case "param": return ((lName) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
                case "zero": return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                case "succ": return ((rValue) => PsKernelOrderStep["done"](PsKernelOrder["greater"]))(__ps$match$0.value);
                case "max": return ((rLeft, rRight) => PsKernelOrderStep["done"](PsKernelOrder["greater"]))(__ps$match$0.left, __ps$match$0.right);
                case "imax": return ((rLeft, rRight) => PsKernelOrderStep["done"](PsKernelOrder["greater"]))(__ps$match$0.left, __ps$match$0.right);
                case "param": return ((rName) => PsKernelOrderStep["next"](PsKernelList["cons"](PsKernelOrderTask["name"](lName, rName), rest)))(__ps$match$0.name);
            } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.name);
        } throw new Error("invalid ProofScript constructor tag"); })(left))(__ps$match$0.left, __ps$match$0.right);
        case "number": return ((state) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$17]) {
            case "next": return ((next) => PsKernelOrderStep["next"](PsKernelList["cons"](PsKernelOrderTask["number"](next), rest)))(__ps$match$0.state);
            case "ordered": return ((order) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$13]) {
                case "less": return PsKernelOrderStep["done"](PsKernelOrder["less"]);
                case "same": return PsKernelOrderStep["next"](rest);
                case "greater": return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
            } throw new Error("invalid ProofScript constructor tag"); })(order))(__ps$match$0.order);
            case "sum": return ((_wild0) => PsKernelOrderStep["invalidState"])(__ps$match$0.value);
        } throw new Error("invalid ProofScript constructor tag"); })(psKernelNumericStep(state)))(__ps$match$0.state);
    } throw new Error("invalid ProofScript constructor tag"); })(task))(__ps$match$0.head, __ps$match$0.tail);
} throw new Error("invalid ProofScript constructor tag"); })(tasks); }
export function psKernelLevelOffset(value) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
    case "zero": return PsKernelLevelOffset["parts"](PsKernelLevel["zero"], PsKernelNatural["zero"]);
    case "succ": return ((child) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
        case "parts": return ((base, count) => PsKernelLevelOffset["parts"](base, psKernelNaturalSucc(count)))(__ps$match$0.base, __ps$match$0.count);
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(child)))(__ps$match$0.value);
    case "max": return ((left, right) => PsKernelLevelOffset["parts"](PsKernelLevel["max"](left, right), PsKernelNatural["zero"]))(__ps$match$0.left, __ps$match$0.right);
    case "imax": return ((left, right) => PsKernelLevelOffset["parts"](PsKernelLevel["imax"](left, right), PsKernelNatural["zero"]))(__ps$match$0.left, __ps$match$0.right);
    case "param": return ((name) => PsKernelLevelOffset["parts"](PsKernelLevel["param"](name), PsKernelNatural["zero"]))(__ps$match$0.name);
} throw new Error("invalid ProofScript constructor tag"); })(value); }
export function psKernelLevelNeverZero(value) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
    case "zero": return PsKernelFlag["no"];
    case "succ": return ((child) => PsKernelFlag["yes"])(__ps$match$0.value);
    case "max": return ((left, right) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$12]) {
        case "no": return psKernelLevelNeverZero(right);
        case "yes": return PsKernelFlag["yes"];
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelNeverZero(left)))(__ps$match$0.left, __ps$match$0.right);
    case "imax": return ((left, right) => psKernelLevelNeverZero(right))(__ps$match$0.left, __ps$match$0.right);
    case "param": return ((name) => PsKernelFlag["no"])(__ps$match$0.name);
} throw new Error("invalid ProofScript constructor tag"); })(value); }
export function psKernelLevelAlwaysZero(value) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
    case "zero": return PsKernelFlag["yes"];
    case "succ": return ((child) => PsKernelFlag["no"])(__ps$match$0.value);
    case "max": return ((left, right) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$12]) {
        case "no": return PsKernelFlag["no"];
        case "yes": return psKernelLevelAlwaysZero(right);
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelAlwaysZero(left)))(__ps$match$0.left, __ps$match$0.right);
    case "imax": return ((left, right) => psKernelLevelAlwaysZero(right))(__ps$match$0.left, __ps$match$0.right);
    case "param": return ((name) => PsKernelFlag["no"])(__ps$match$0.name);
} throw new Error("invalid ProofScript constructor tag"); })(value); }
export function psKernelUniverseSchedule(task, tasks, values) { return PsKernelUniverseStep["next"](PsKernelUniverseState["state"](PsKernelList["cons"](task, tasks), values)); }
export function psKernelUniversePush(value, tasks, values) { return PsKernelUniverseStep["next"](PsKernelUniverseState["state"](tasks, PsKernelList["cons"](value, values))); }
export function psKernelUniverseSmartMax(left, right, offset, tasks, values) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
    case "zero": return psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](right, offset), tasks, values);
    case "succ": return ((_wild0) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
        case "zero": return psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](left, offset), tasks, values);
        case "succ": return ((_wild0) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
            case "parts": return ((leftBase, leftCount) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                case "parts": return ((rightBase, rightCount) => psKernelUniverseSchedule(PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values))(__ps$match$0.base, __ps$match$0.count);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(right)))(__ps$match$0.base, __ps$match$0.count);
        } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(left)))(__ps$match$0.value);
        case "max": return ((_wild0, _wild1) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
            case "parts": return ((leftBase, leftCount) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                case "parts": return ((rightBase, rightCount) => psKernelUniverseSchedule(PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values))(__ps$match$0.base, __ps$match$0.count);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(right)))(__ps$match$0.base, __ps$match$0.count);
        } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(left)))(__ps$match$0.left, __ps$match$0.right);
        case "imax": return ((_wild0, _wild1) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
            case "parts": return ((leftBase, leftCount) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                case "parts": return ((rightBase, rightCount) => psKernelUniverseSchedule(PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values))(__ps$match$0.base, __ps$match$0.count);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(right)))(__ps$match$0.base, __ps$match$0.count);
        } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(left)))(__ps$match$0.left, __ps$match$0.right);
        case "param": return ((_wild0) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
            case "parts": return ((leftBase, leftCount) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                case "parts": return ((rightBase, rightCount) => psKernelUniverseSchedule(PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values))(__ps$match$0.base, __ps$match$0.count);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(right)))(__ps$match$0.base, __ps$match$0.count);
        } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(left)))(__ps$match$0.name);
    } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.value);
    case "max": return ((_wild0, _wild1) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
        case "zero": return psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](left, offset), tasks, values);
        case "succ": return ((_wild0) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
            case "parts": return ((leftBase, leftCount) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                case "parts": return ((rightBase, rightCount) => psKernelUniverseSchedule(PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values))(__ps$match$0.base, __ps$match$0.count);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(right)))(__ps$match$0.base, __ps$match$0.count);
        } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(left)))(__ps$match$0.value);
        case "max": return ((_wild0, _wild1) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
            case "parts": return ((leftBase, leftCount) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                case "parts": return ((rightBase, rightCount) => psKernelUniverseSchedule(PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values))(__ps$match$0.base, __ps$match$0.count);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(right)))(__ps$match$0.base, __ps$match$0.count);
        } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(left)))(__ps$match$0.left, __ps$match$0.right);
        case "imax": return ((_wild0, _wild1) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
            case "parts": return ((leftBase, leftCount) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                case "parts": return ((rightBase, rightCount) => psKernelUniverseSchedule(PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values))(__ps$match$0.base, __ps$match$0.count);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(right)))(__ps$match$0.base, __ps$match$0.count);
        } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(left)))(__ps$match$0.left, __ps$match$0.right);
        case "param": return ((_wild0) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
            case "parts": return ((leftBase, leftCount) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                case "parts": return ((rightBase, rightCount) => psKernelUniverseSchedule(PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values))(__ps$match$0.base, __ps$match$0.count);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(right)))(__ps$match$0.base, __ps$match$0.count);
        } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(left)))(__ps$match$0.name);
    } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.left, __ps$match$0.right);
    case "imax": return ((_wild0, _wild1) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
        case "zero": return psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](left, offset), tasks, values);
        case "succ": return ((_wild0) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
            case "parts": return ((leftBase, leftCount) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                case "parts": return ((rightBase, rightCount) => psKernelUniverseSchedule(PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values))(__ps$match$0.base, __ps$match$0.count);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(right)))(__ps$match$0.base, __ps$match$0.count);
        } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(left)))(__ps$match$0.value);
        case "max": return ((_wild0, _wild1) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
            case "parts": return ((leftBase, leftCount) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                case "parts": return ((rightBase, rightCount) => psKernelUniverseSchedule(PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values))(__ps$match$0.base, __ps$match$0.count);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(right)))(__ps$match$0.base, __ps$match$0.count);
        } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(left)))(__ps$match$0.left, __ps$match$0.right);
        case "imax": return ((_wild0, _wild1) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
            case "parts": return ((leftBase, leftCount) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                case "parts": return ((rightBase, rightCount) => psKernelUniverseSchedule(PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values))(__ps$match$0.base, __ps$match$0.count);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(right)))(__ps$match$0.base, __ps$match$0.count);
        } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(left)))(__ps$match$0.left, __ps$match$0.right);
        case "param": return ((_wild0) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
            case "parts": return ((leftBase, leftCount) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                case "parts": return ((rightBase, rightCount) => psKernelUniverseSchedule(PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values))(__ps$match$0.base, __ps$match$0.count);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(right)))(__ps$match$0.base, __ps$match$0.count);
        } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(left)))(__ps$match$0.name);
    } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.left, __ps$match$0.right);
    case "param": return ((_wild0) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
        case "zero": return psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](left, offset), tasks, values);
        case "succ": return ((_wild0) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
            case "parts": return ((leftBase, leftCount) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                case "parts": return ((rightBase, rightCount) => psKernelUniverseSchedule(PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values))(__ps$match$0.base, __ps$match$0.count);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(right)))(__ps$match$0.base, __ps$match$0.count);
        } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(left)))(__ps$match$0.value);
        case "max": return ((_wild0, _wild1) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
            case "parts": return ((leftBase, leftCount) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                case "parts": return ((rightBase, rightCount) => psKernelUniverseSchedule(PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values))(__ps$match$0.base, __ps$match$0.count);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(right)))(__ps$match$0.base, __ps$match$0.count);
        } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(left)))(__ps$match$0.left, __ps$match$0.right);
        case "imax": return ((_wild0, _wild1) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
            case "parts": return ((leftBase, leftCount) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                case "parts": return ((rightBase, rightCount) => psKernelUniverseSchedule(PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values))(__ps$match$0.base, __ps$match$0.count);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(right)))(__ps$match$0.base, __ps$match$0.count);
        } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(left)))(__ps$match$0.left, __ps$match$0.right);
        case "param": return ((_wild0) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
            case "parts": return ((leftBase, leftCount) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                case "parts": return ((rightBase, rightCount) => psKernelUniverseSchedule(PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values))(__ps$match$0.base, __ps$match$0.count);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(right)))(__ps$match$0.base, __ps$match$0.count);
        } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(left)))(__ps$match$0.name);
    } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.name);
} throw new Error("invalid ProofScript constructor tag"); })(left); }
export function psKernelUniverseIMax(left, right, offset, tasks, values) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$12]) {
    case "no": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
        case "zero": return psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](right, offset), tasks, values);
        case "succ": return ((_wild0) => (() => { const smallLeft = ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
            case "zero": return PsKernelFlag["yes"];
            case "succ": return ((child) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
                case "zero": return PsKernelFlag["yes"];
                case "succ": return ((_wild0) => PsKernelFlag["no"])(__ps$match$0.value);
                case "max": return ((_wild0, _wild1) => PsKernelFlag["no"])(__ps$match$0.left, __ps$match$0.right);
                case "imax": return ((_wild0, _wild1) => PsKernelFlag["no"])(__ps$match$0.left, __ps$match$0.right);
                case "param": return ((_wild0) => PsKernelFlag["no"])(__ps$match$0.name);
            } throw new Error("invalid ProofScript constructor tag"); })(child))(__ps$match$0.value);
            case "max": return ((_wild0, _wild1) => PsKernelFlag["no"])(__ps$match$0.left, __ps$match$0.right);
            case "imax": return ((_wild0, _wild1) => PsKernelFlag["no"])(__ps$match$0.left, __ps$match$0.right);
            case "param": return ((_wild0) => PsKernelFlag["no"])(__ps$match$0.name);
        } throw new Error("invalid ProofScript constructor tag"); })(left); return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$12]) {
            case "no": return psKernelUniverseSchedule(PsKernelUniverseTask["imaxCompare"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](left, right), PsKernelList["nil"]())), tasks, values);
            case "yes": return psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](right, offset), tasks, values);
        } throw new Error("invalid ProofScript constructor tag"); })(smallLeft); })())(__ps$match$0.value);
        case "max": return ((_wild0, _wild1) => (() => { const smallLeft = ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
            case "zero": return PsKernelFlag["yes"];
            case "succ": return ((child) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
                case "zero": return PsKernelFlag["yes"];
                case "succ": return ((_wild0) => PsKernelFlag["no"])(__ps$match$0.value);
                case "max": return ((_wild0, _wild1) => PsKernelFlag["no"])(__ps$match$0.left, __ps$match$0.right);
                case "imax": return ((_wild0, _wild1) => PsKernelFlag["no"])(__ps$match$0.left, __ps$match$0.right);
                case "param": return ((_wild0) => PsKernelFlag["no"])(__ps$match$0.name);
            } throw new Error("invalid ProofScript constructor tag"); })(child))(__ps$match$0.value);
            case "max": return ((_wild0, _wild1) => PsKernelFlag["no"])(__ps$match$0.left, __ps$match$0.right);
            case "imax": return ((_wild0, _wild1) => PsKernelFlag["no"])(__ps$match$0.left, __ps$match$0.right);
            case "param": return ((_wild0) => PsKernelFlag["no"])(__ps$match$0.name);
        } throw new Error("invalid ProofScript constructor tag"); })(left); return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$12]) {
            case "no": return psKernelUniverseSchedule(PsKernelUniverseTask["imaxCompare"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](left, right), PsKernelList["nil"]())), tasks, values);
            case "yes": return psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](right, offset), tasks, values);
        } throw new Error("invalid ProofScript constructor tag"); })(smallLeft); })())(__ps$match$0.left, __ps$match$0.right);
        case "imax": return ((_wild0, _wild1) => (() => { const smallLeft = ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
            case "zero": return PsKernelFlag["yes"];
            case "succ": return ((child) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
                case "zero": return PsKernelFlag["yes"];
                case "succ": return ((_wild0) => PsKernelFlag["no"])(__ps$match$0.value);
                case "max": return ((_wild0, _wild1) => PsKernelFlag["no"])(__ps$match$0.left, __ps$match$0.right);
                case "imax": return ((_wild0, _wild1) => PsKernelFlag["no"])(__ps$match$0.left, __ps$match$0.right);
                case "param": return ((_wild0) => PsKernelFlag["no"])(__ps$match$0.name);
            } throw new Error("invalid ProofScript constructor tag"); })(child))(__ps$match$0.value);
            case "max": return ((_wild0, _wild1) => PsKernelFlag["no"])(__ps$match$0.left, __ps$match$0.right);
            case "imax": return ((_wild0, _wild1) => PsKernelFlag["no"])(__ps$match$0.left, __ps$match$0.right);
            case "param": return ((_wild0) => PsKernelFlag["no"])(__ps$match$0.name);
        } throw new Error("invalid ProofScript constructor tag"); })(left); return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$12]) {
            case "no": return psKernelUniverseSchedule(PsKernelUniverseTask["imaxCompare"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](left, right), PsKernelList["nil"]())), tasks, values);
            case "yes": return psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](right, offset), tasks, values);
        } throw new Error("invalid ProofScript constructor tag"); })(smallLeft); })())(__ps$match$0.left, __ps$match$0.right);
        case "param": return ((_wild0) => (() => { const smallLeft = ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
            case "zero": return PsKernelFlag["yes"];
            case "succ": return ((child) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
                case "zero": return PsKernelFlag["yes"];
                case "succ": return ((_wild0) => PsKernelFlag["no"])(__ps$match$0.value);
                case "max": return ((_wild0, _wild1) => PsKernelFlag["no"])(__ps$match$0.left, __ps$match$0.right);
                case "imax": return ((_wild0, _wild1) => PsKernelFlag["no"])(__ps$match$0.left, __ps$match$0.right);
                case "param": return ((_wild0) => PsKernelFlag["no"])(__ps$match$0.name);
            } throw new Error("invalid ProofScript constructor tag"); })(child))(__ps$match$0.value);
            case "max": return ((_wild0, _wild1) => PsKernelFlag["no"])(__ps$match$0.left, __ps$match$0.right);
            case "imax": return ((_wild0, _wild1) => PsKernelFlag["no"])(__ps$match$0.left, __ps$match$0.right);
            case "param": return ((_wild0) => PsKernelFlag["no"])(__ps$match$0.name);
        } throw new Error("invalid ProofScript constructor tag"); })(left); return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$12]) {
            case "no": return psKernelUniverseSchedule(PsKernelUniverseTask["imaxCompare"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](left, right), PsKernelList["nil"]())), tasks, values);
            case "yes": return psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](right, offset), tasks, values);
        } throw new Error("invalid ProofScript constructor tag"); })(smallLeft); })())(__ps$match$0.name);
    } throw new Error("invalid ProofScript constructor tag"); })(right);
    case "yes": return psKernelUniverseSmartMax(left, right, offset, tasks, values);
} throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelNeverZero(right)); }
export function psKernelUniverseProbes(left, right) { return (() => { const fromLeft = ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
    case "zero": return PsKernelList["nil"]();
    case "succ": return ((_wild0) => PsKernelList["nil"]())(__ps$match$0.value);
    case "max": return ((a, b) => PsKernelList["cons"](PsKernelMaxProbe["probe"](right, a, left), PsKernelList["cons"](PsKernelMaxProbe["probe"](right, b, left), PsKernelList["nil"]())))(__ps$match$0.left, __ps$match$0.right);
    case "imax": return ((_wild0, _wild1) => PsKernelList["nil"]())(__ps$match$0.left, __ps$match$0.right);
    case "param": return ((_wild0) => PsKernelList["nil"]())(__ps$match$0.name);
} throw new Error("invalid ProofScript constructor tag"); })(left); return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
    case "zero": return fromLeft;
    case "succ": return ((_wild0) => fromLeft)(__ps$match$0.value);
    case "max": return ((a, b) => PsKernelList["cons"](PsKernelMaxProbe["probe"](left, a, right), PsKernelList["cons"](PsKernelMaxProbe["probe"](left, b, right), fromLeft)))(__ps$match$0.left, __ps$match$0.right);
    case "imax": return ((_wild0, _wild1) => fromLeft)(__ps$match$0.left, __ps$match$0.right);
    case "param": return ((_wild0) => fromLeft)(__ps$match$0.name);
} throw new Error("invalid ProofScript constructor tag"); })(right); })(); }
export function psKernelUniverseFinish(values) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
    case "nil": return PsKernelUniverseResult["invalidState"];
    case "cons": return ((value, tail) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
        case "nil": return PsKernelUniverseResult["done"](value);
        case "cons": return ((_wild0, _wild1) => PsKernelUniverseResult["invalidState"])(__ps$match$0.head, __ps$match$0.tail);
    } throw new Error("invalid ProofScript constructor tag"); })(tail))(__ps$match$0.head, __ps$match$0.tail);
} throw new Error("invalid ProofScript constructor tag"); })(values); }
export function psKernelUniverseStep(state) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$32]) {
    case "state": return ((tasks, values) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
        case "nil": return PsKernelUniverseStep["final"](psKernelUniverseFinish(values));
        case "cons": return ((task, rest) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$31]) {
            case "normalize": return ((value, offset) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
                case "zero": return psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](value, offset), rest, values);
                case "succ": return ((child) => psKernelUniverseSchedule(PsKernelUniverseTask["normalize"](child, psKernelNaturalSucc(offset)), rest, values))(__ps$match$0.value);
                case "max": return ((left, right) => psKernelUniverseSchedule(PsKernelUniverseTask["normalize"](left, PsKernelNatural["zero"]), PsKernelList["cons"](PsKernelUniverseTask["normalize"](right, PsKernelNatural["zero"]), PsKernelList["cons"](PsKernelUniverseTask["joinMax"](offset), rest)), values))(__ps$match$0.left, __ps$match$0.right);
                case "imax": return ((left, right) => psKernelUniverseSchedule(PsKernelUniverseTask["normalize"](left, PsKernelNatural["zero"]), PsKernelList["cons"](PsKernelUniverseTask["normalize"](right, PsKernelNatural["zero"]), PsKernelList["cons"](PsKernelUniverseTask["joinIMax"](offset), rest)), values))(__ps$match$0.left, __ps$match$0.right);
                case "param": return ((_wild0) => psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](value, offset), rest, values))(__ps$match$0.name);
            } throw new Error("invalid ProofScript constructor tag"); })(value))(__ps$match$0.value, __ps$match$0.offset);
            case "joinMax": return ((offset) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                case "cons": return ((right, tail) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
                    case "nil": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                    case "cons": return ((left, remaining) => psKernelUniverseSchedule(PsKernelUniverseTask["collect"](offset, PsKernelList["cons"](left, PsKernelList["cons"](right, PsKernelList["nil"]())), PsKernelList["nil"]()), rest, remaining))(__ps$match$0.head, __ps$match$0.tail);
                } throw new Error("invalid ProofScript constructor tag"); })(tail))(__ps$match$0.head, __ps$match$0.tail);
            } throw new Error("invalid ProofScript constructor tag"); })(values))(__ps$match$0.offset);
            case "joinIMax": return ((offset) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                case "cons": return ((right, tail) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
                    case "nil": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                    case "cons": return ((left, remaining) => psKernelUniverseIMax(left, right, offset, rest, remaining))(__ps$match$0.head, __ps$match$0.tail);
                } throw new Error("invalid ProofScript constructor tag"); })(tail))(__ps$match$0.head, __ps$match$0.tail);
            } throw new Error("invalid ProofScript constructor tag"); })(values))(__ps$match$0.offset);
            case "wrap": return ((value, offset) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$4]) {
                case "zero": return psKernelUniversePush(value, rest, values);
                case "positive": return ((_wild0) => psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](PsKernelLevel["succ"](value), psKernelNaturalPred(offset)), rest, values))(__ps$match$0.value);
            } throw new Error("invalid ProofScript constructor tag"); })(offset))(__ps$match$0.value, __ps$match$0.offset);
            case "imaxCompare": return ((left, right, offset, work) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$28]) {
                case "next": return ((next) => psKernelUniverseSchedule(PsKernelUniverseTask["imaxCompare"](left, right, offset, next), rest, values))(__ps$match$0.tasks);
                case "done": return ((order) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$13]) {
                    case "less": return psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](PsKernelLevel["imax"](left, right), offset), rest, values);
                    case "same": return psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](left, offset), rest, values);
                    case "greater": return psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](PsKernelLevel["imax"](left, right), offset), rest, values);
                } throw new Error("invalid ProofScript constructor tag"); })(order))(__ps$match$0.order);
                case "invalidState": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelOrderStep(work)))(__ps$match$0.left, __ps$match$0.right, __ps$match$0.offset, __ps$match$0.work);
            case "maxBases": return ((left, right, offset, work) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$28]) {
                case "next": return ((next) => psKernelUniverseSchedule(PsKernelUniverseTask["maxBases"](left, right, offset, next), rest, values))(__ps$match$0.tasks);
                case "done": return ((order) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$13]) {
                    case "less": return psKernelUniverseSchedule(PsKernelUniverseTask["probeMax"](left, right, offset, psKernelUniverseProbes(left, right)), rest, values);
                    case "same": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                        case "parts": return ((unusedLeft, leftCount) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                            case "parts": return ((unusedRight, rightCount) => psKernelUniverseSchedule(PsKernelUniverseTask["maxOffsets"](left, right, offset, PsKernelNumericState["order"](leftCount, rightCount, PsKernelOrder["same"])), rest, values))(__ps$match$0.base, __ps$match$0.count);
                        } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(right)))(__ps$match$0.base, __ps$match$0.count);
                    } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(left));
                    case "greater": return psKernelUniverseSchedule(PsKernelUniverseTask["probeMax"](left, right, offset, psKernelUniverseProbes(left, right)), rest, values);
                } throw new Error("invalid ProofScript constructor tag"); })(order))(__ps$match$0.order);
                case "invalidState": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelOrderStep(work)))(__ps$match$0.left, __ps$match$0.right, __ps$match$0.offset, __ps$match$0.work);
            case "maxOffsets": return ((left, right, offset, numeric) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$17]) {
                case "next": return ((next) => psKernelUniverseSchedule(PsKernelUniverseTask["maxOffsets"](left, right, offset, next), rest, values))(__ps$match$0.state);
                case "ordered": return ((order) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$13]) {
                    case "less": return psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](right, offset), rest, values);
                    case "same": return psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](left, offset), rest, values);
                    case "greater": return psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](left, offset), rest, values);
                } throw new Error("invalid ProofScript constructor tag"); })(order))(__ps$match$0.order);
                case "sum": return ((_wild0) => PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]))(__ps$match$0.value);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelNumericStep(numeric)))(__ps$match$0.left, __ps$match$0.right, __ps$match$0.offset, __ps$match$0.numeric);
            case "probeMax": return ((left, right, offset, probes) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](PsKernelLevel["max"](left, right), offset), rest, values);
                case "cons": return ((probe, tail) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$30]) {
                    case "probe": return ((a, b, result) => psKernelUniverseSchedule(PsKernelUniverseTask["probeCompare"](left, right, offset, result, tail, PsKernelList["cons"](PsKernelOrderTask["level"](a, b), PsKernelList["nil"]())), rest, values))(__ps$match$0.left, __ps$match$0.right, __ps$match$0.result);
                } throw new Error("invalid ProofScript constructor tag"); })(probe))(__ps$match$0.head, __ps$match$0.tail);
            } throw new Error("invalid ProofScript constructor tag"); })(probes))(__ps$match$0.left, __ps$match$0.right, __ps$match$0.offset, __ps$match$0.probes);
            case "probeCompare": return ((left, right, offset, result, probes, work) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$28]) {
                case "next": return ((next) => psKernelUniverseSchedule(PsKernelUniverseTask["probeCompare"](left, right, offset, result, probes, next), rest, values))(__ps$match$0.tasks);
                case "done": return ((order) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$13]) {
                    case "less": return psKernelUniverseSchedule(PsKernelUniverseTask["probeMax"](left, right, offset, probes), rest, values);
                    case "same": return psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](result, offset), rest, values);
                    case "greater": return psKernelUniverseSchedule(PsKernelUniverseTask["probeMax"](left, right, offset, probes), rest, values);
                } throw new Error("invalid ProofScript constructor tag"); })(order))(__ps$match$0.order);
                case "invalidState": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelOrderStep(work)))(__ps$match$0.left, __ps$match$0.right, __ps$match$0.offset, __ps$match$0.result, __ps$match$0.probes, __ps$match$0.work);
            case "collect": return ((offset, todo, leaves) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return psKernelUniverseSchedule(PsKernelUniverseTask["sort"](offset, leaves, PsKernelList["nil"]()), rest, values);
                case "cons": return ((value, tail) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
                    case "zero": return psKernelUniverseSchedule(PsKernelUniverseTask["collect"](offset, tail, PsKernelList["cons"](value, leaves)), rest, values);
                    case "succ": return ((_wild0) => psKernelUniverseSchedule(PsKernelUniverseTask["collect"](offset, tail, PsKernelList["cons"](value, leaves)), rest, values))(__ps$match$0.value);
                    case "max": return ((a, b) => psKernelUniverseSchedule(PsKernelUniverseTask["collect"](offset, PsKernelList["cons"](a, PsKernelList["cons"](b, tail)), leaves), rest, values))(__ps$match$0.left, __ps$match$0.right);
                    case "imax": return ((_wild0, _wild1) => psKernelUniverseSchedule(PsKernelUniverseTask["collect"](offset, tail, PsKernelList["cons"](value, leaves)), rest, values))(__ps$match$0.left, __ps$match$0.right);
                    case "param": return ((_wild0) => psKernelUniverseSchedule(PsKernelUniverseTask["collect"](offset, tail, PsKernelList["cons"](value, leaves)), rest, values))(__ps$match$0.name);
                } throw new Error("invalid ProofScript constructor tag"); })(value))(__ps$match$0.head, __ps$match$0.tail);
            } throw new Error("invalid ProofScript constructor tag"); })(todo))(__ps$match$0.offset, __ps$match$0.todo, __ps$match$0.leaves);
            case "sort": return ((offset, todo, sorted) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return psKernelUniverseSchedule(PsKernelUniverseTask["prune"](offset, sorted), rest, values);
                case "cons": return ((candidate, tail) => psKernelUniverseSchedule(PsKernelUniverseTask["insert"](offset, tail, candidate, sorted, PsKernelList["nil"]()), rest, values))(__ps$match$0.head, __ps$match$0.tail);
            } throw new Error("invalid ProofScript constructor tag"); })(todo))(__ps$match$0.offset, __ps$match$0.todo, __ps$match$0.sorted);
            case "insert": return ((offset, todo, candidate, scan, prefix) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return psKernelUniverseSchedule(PsKernelUniverseTask["restore"](offset, todo, prefix, PsKernelList["cons"](candidate, PsKernelList["nil"]())), rest, values);
                case "cons": return ((current, tail) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                    case "parts": return ((a, unusedCountA) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                        case "parts": return ((b, unusedCountB) => psKernelUniverseSchedule(PsKernelUniverseTask["insertCompare"](offset, todo, candidate, current, tail, prefix, PsKernelList["cons"](PsKernelOrderTask["level"](a, b), PsKernelList["nil"]())), rest, values))(__ps$match$0.base, __ps$match$0.count);
                    } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(current)))(__ps$match$0.base, __ps$match$0.count);
                } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(candidate)))(__ps$match$0.head, __ps$match$0.tail);
            } throw new Error("invalid ProofScript constructor tag"); })(scan))(__ps$match$0.offset, __ps$match$0.todo, __ps$match$0.candidate, __ps$match$0.scan, __ps$match$0.prefix);
            case "insertCompare": return ((offset, todo, candidate, current, tail, prefix, work) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$28]) {
                case "next": return ((next) => psKernelUniverseSchedule(PsKernelUniverseTask["insertCompare"](offset, todo, candidate, current, tail, prefix, next), rest, values))(__ps$match$0.tasks);
                case "done": return ((order) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$13]) {
                    case "less": return psKernelUniverseSchedule(PsKernelUniverseTask["restore"](offset, todo, prefix, PsKernelList["cons"](candidate, PsKernelList["cons"](current, tail))), rest, values);
                    case "same": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                        case "parts": return ((unusedA, a) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                            case "parts": return ((unusedB, b) => psKernelUniverseSchedule(PsKernelUniverseTask["insertOffset"](offset, todo, candidate, current, tail, prefix, PsKernelNumericState["order"](a, b, PsKernelOrder["same"])), rest, values))(__ps$match$0.base, __ps$match$0.count);
                        } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(current)))(__ps$match$0.base, __ps$match$0.count);
                    } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(candidate));
                    case "greater": return psKernelUniverseSchedule(PsKernelUniverseTask["insert"](offset, todo, candidate, tail, PsKernelList["cons"](current, prefix)), rest, values);
                } throw new Error("invalid ProofScript constructor tag"); })(order))(__ps$match$0.order);
                case "invalidState": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelOrderStep(work)))(__ps$match$0.offset, __ps$match$0.todo, __ps$match$0.candidate, __ps$match$0.current, __ps$match$0.tail, __ps$match$0.prefix, __ps$match$0.work);
            case "insertOffset": return ((offset, todo, candidate, current, tail, prefix, numeric) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$17]) {
                case "next": return ((next) => psKernelUniverseSchedule(PsKernelUniverseTask["insertOffset"](offset, todo, candidate, current, tail, prefix, next), rest, values))(__ps$match$0.state);
                case "ordered": return ((order) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$13]) {
                    case "less": return psKernelUniverseSchedule(PsKernelUniverseTask["restore"](offset, todo, prefix, PsKernelList["cons"](current, tail)), rest, values);
                    case "same": return psKernelUniverseSchedule(PsKernelUniverseTask["restore"](offset, todo, prefix, PsKernelList["cons"](current, tail)), rest, values);
                    case "greater": return psKernelUniverseSchedule(PsKernelUniverseTask["restore"](offset, todo, prefix, PsKernelList["cons"](candidate, tail)), rest, values);
                } throw new Error("invalid ProofScript constructor tag"); })(order))(__ps$match$0.order);
                case "sum": return ((_wild0) => PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]))(__ps$match$0.value);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelNumericStep(numeric)))(__ps$match$0.offset, __ps$match$0.todo, __ps$match$0.candidate, __ps$match$0.current, __ps$match$0.tail, __ps$match$0.prefix, __ps$match$0.numeric);
            case "restore": return ((offset, todo, prefix, suffix) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return psKernelUniverseSchedule(PsKernelUniverseTask["sort"](offset, todo, suffix), rest, values);
                case "cons": return ((head, tail) => psKernelUniverseSchedule(PsKernelUniverseTask["restore"](offset, todo, tail, PsKernelList["cons"](head, suffix)), rest, values))(__ps$match$0.head, __ps$match$0.tail);
            } throw new Error("invalid ProofScript constructor tag"); })(prefix))(__ps$match$0.offset, __ps$match$0.todo, __ps$match$0.prefix, __ps$match$0.suffix);
            case "prune": return ((offset, sorted) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                case "cons": return ((first, tail) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                    case "parts": return ((base, count) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
                        case "zero": return psKernelUniverseSchedule(PsKernelUniverseTask["constantScan"](offset, first, tail, tail), rest, values);
                        case "succ": return ((_wild0) => psKernelUniverseSchedule(PsKernelUniverseTask["wrapList"](offset, sorted, PsKernelList["nil"]()), rest, values))(__ps$match$0.value);
                        case "max": return ((_wild0, _wild1) => psKernelUniverseSchedule(PsKernelUniverseTask["wrapList"](offset, sorted, PsKernelList["nil"]()), rest, values))(__ps$match$0.left, __ps$match$0.right);
                        case "imax": return ((_wild0, _wild1) => psKernelUniverseSchedule(PsKernelUniverseTask["wrapList"](offset, sorted, PsKernelList["nil"]()), rest, values))(__ps$match$0.left, __ps$match$0.right);
                        case "param": return ((_wild0) => psKernelUniverseSchedule(PsKernelUniverseTask["wrapList"](offset, sorted, PsKernelList["nil"]()), rest, values))(__ps$match$0.name);
                    } throw new Error("invalid ProofScript constructor tag"); })(base))(__ps$match$0.base, __ps$match$0.count);
                } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(first)))(__ps$match$0.head, __ps$match$0.tail);
            } throw new Error("invalid ProofScript constructor tag"); })(sorted))(__ps$match$0.offset, __ps$match$0.sorted);
            case "constantScan": return ((offset, constant, others, scan) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return psKernelUniverseSchedule(PsKernelUniverseTask["wrapList"](offset, PsKernelList["cons"](constant, others), PsKernelList["nil"]()), rest, values);
                case "cons": return ((head, tail) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                    case "parts": return ((unusedA, a) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$29]) {
                        case "parts": return ((unusedB, b) => psKernelUniverseSchedule(PsKernelUniverseTask["constantCompare"](offset, constant, others, tail, PsKernelNumericState["order"](b, a, PsKernelOrder["same"])), rest, values))(__ps$match$0.base, __ps$match$0.count);
                    } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(head)))(__ps$match$0.base, __ps$match$0.count);
                } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelOffset(constant)))(__ps$match$0.head, __ps$match$0.tail);
            } throw new Error("invalid ProofScript constructor tag"); })(scan))(__ps$match$0.offset, __ps$match$0.constant, __ps$match$0.others, __ps$match$0.scan);
            case "constantCompare": return ((offset, constant, others, scan, numeric) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$17]) {
                case "next": return ((next) => psKernelUniverseSchedule(PsKernelUniverseTask["constantCompare"](offset, constant, others, scan, next), rest, values))(__ps$match$0.state);
                case "ordered": return ((order) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$13]) {
                    case "less": return psKernelUniverseSchedule(PsKernelUniverseTask["constantScan"](offset, constant, others, scan), rest, values);
                    case "same": return psKernelUniverseSchedule(PsKernelUniverseTask["wrapList"](offset, others, PsKernelList["nil"]()), rest, values);
                    case "greater": return psKernelUniverseSchedule(PsKernelUniverseTask["wrapList"](offset, others, PsKernelList["nil"]()), rest, values);
                } throw new Error("invalid ProofScript constructor tag"); })(order))(__ps$match$0.order);
                case "sum": return ((_wild0) => PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]))(__ps$match$0.value);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelNumericStep(numeric)))(__ps$match$0.offset, __ps$match$0.constant, __ps$match$0.others, __ps$match$0.scan, __ps$match$0.numeric);
            case "wrapList": return ((offset, todo, doneRev) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
                    case "nil": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                    case "cons": return ((last, tail) => psKernelUniverseSchedule(PsKernelUniverseTask["assemble"](tail, last), rest, values))(__ps$match$0.head, __ps$match$0.tail);
                } throw new Error("invalid ProofScript constructor tag"); })(doneRev);
                case "cons": return ((head, tail) => psKernelUniverseSchedule(PsKernelUniverseTask["wrap"](head, offset), PsKernelList["cons"](PsKernelUniverseTask["wrapped"](offset, tail, doneRev), rest), values))(__ps$match$0.head, __ps$match$0.tail);
            } throw new Error("invalid ProofScript constructor tag"); })(todo))(__ps$match$0.offset, __ps$match$0.todo, __ps$match$0.doneRev);
            case "wrapped": return ((offset, todo, doneRev) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                case "cons": return ((wrapped, tail) => psKernelUniverseSchedule(PsKernelUniverseTask["wrapList"](offset, todo, PsKernelList["cons"](wrapped, doneRev)), rest, tail))(__ps$match$0.head, __ps$match$0.tail);
            } throw new Error("invalid ProofScript constructor tag"); })(values))(__ps$match$0.offset, __ps$match$0.todo, __ps$match$0.doneRev);
            case "assemble": return ((todo, value) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return psKernelUniversePush(value, rest, values);
                case "cons": return ((head, tail) => psKernelUniverseSchedule(PsKernelUniverseTask["assemble"](tail, PsKernelLevel["max"](head, value)), rest, values))(__ps$match$0.head, __ps$match$0.tail);
            } throw new Error("invalid ProofScript constructor tag"); })(todo))(__ps$match$0.todo, __ps$match$0.value);
        } throw new Error("invalid ProofScript constructor tag"); })(task))(__ps$match$0.head, __ps$match$0.tail);
    } throw new Error("invalid ProofScript constructor tag"); })(tasks))(__ps$match$0.tasks, __ps$match$0.values);
} throw new Error("invalid ProofScript constructor tag"); })(state); }
export function psKernelUniverseStart(value) { return PsKernelUniverseState["state"](PsKernelList["cons"](PsKernelUniverseTask["normalize"](value, PsKernelNatural["zero"]), PsKernelList["nil"]()), PsKernelList["nil"]()); }
export function psKernelUniverseRun(fuel) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$11]) {
    case "stop": return (state) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$32]) {
        case "state": return ((tasks, values) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return psKernelUniverseFinish(values);
            case "cons": return ((_wild0, _wild1) => PsKernelUniverseResult["outOfFuel"])(__ps$match$0.head, __ps$match$0.tail);
        } throw new Error("invalid ProofScript constructor tag"); })(tasks))(__ps$match$0.tasks, __ps$match$0.values);
    } throw new Error("invalid ProofScript constructor tag"); })(state);
    case "more": return ((remaining) => (state) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$34]) {
        case "next": return ((next) => (() => { const smaller = psKernelUniverseRun(remaining); return smaller(next); })())(__ps$match$0.state);
        case "final": return ((result) => result)(__ps$match$0.result);
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelUniverseStep(state)))(__ps$match$0.remaining);
} throw new Error("invalid ProofScript constructor tag"); })(fuel); }
export function psKernelLevelCheckStart(left, right) { return PsKernelLevelCheckState["left"](right, psKernelUniverseStart(left)); }
export function psKernelLevelCheckStep(state) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$35]) {
    case "left": return ((right, current) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$34]) {
        case "next": return ((next) => PsKernelLevelCheckStep["next"](PsKernelLevelCheckState["left"](right, next)))(__ps$match$0.state);
        case "final": return ((result) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$33]) {
            case "outOfFuel": return PsKernelLevelCheckStep["final"](PsKernelLevelCheckResult["invalidState"]);
            case "invalidState": return PsKernelLevelCheckStep["final"](PsKernelLevelCheckResult["invalidState"]);
            case "done": return ((left) => PsKernelLevelCheckStep["next"](PsKernelLevelCheckState["right"](left, psKernelUniverseStart(right))))(__ps$match$0.value);
        } throw new Error("invalid ProofScript constructor tag"); })(result))(__ps$match$0.result);
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelUniverseStep(current)))(__ps$match$0.right, __ps$match$0.state);
    case "right": return ((left, current) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$34]) {
        case "next": return ((next) => PsKernelLevelCheckStep["next"](PsKernelLevelCheckState["right"](left, next)))(__ps$match$0.state);
        case "final": return ((result) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$33]) {
            case "outOfFuel": return PsKernelLevelCheckStep["final"](PsKernelLevelCheckResult["invalidState"]);
            case "invalidState": return PsKernelLevelCheckStep["final"](PsKernelLevelCheckResult["invalidState"]);
            case "done": return ((right) => PsKernelLevelCheckStep["next"](PsKernelLevelCheckState["order"](PsKernelList["cons"](PsKernelOrderTask["level"](left, right), PsKernelList["nil"]()))))(__ps$match$0.value);
        } throw new Error("invalid ProofScript constructor tag"); })(result))(__ps$match$0.result);
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelUniverseStep(current)))(__ps$match$0.left, __ps$match$0.state);
    case "order": return ((tasks) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$28]) {
        case "next": return ((next) => PsKernelLevelCheckStep["next"](PsKernelLevelCheckState["order"](next)))(__ps$match$0.tasks);
        case "done": return ((order) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$13]) {
            case "less": return PsKernelLevelCheckStep["final"](PsKernelLevelCheckResult["different"]);
            case "same": return PsKernelLevelCheckStep["final"](PsKernelLevelCheckResult["equal"]);
            case "greater": return PsKernelLevelCheckStep["final"](PsKernelLevelCheckResult["different"]);
        } throw new Error("invalid ProofScript constructor tag"); })(order))(__ps$match$0.order);
        case "invalidState": return PsKernelLevelCheckStep["final"](PsKernelLevelCheckResult["invalidState"]);
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelOrderStep(tasks)))(__ps$match$0.tasks);
} throw new Error("invalid ProofScript constructor tag"); })(state); }
export function psKernelLevelCheckRun(fuel) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$11]) {
    case "stop": return (state) => PsKernelLevelCheckResult["outOfFuel"];
    case "more": return ((remaining) => (state) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$37]) {
        case "next": return ((next) => (() => { const smaller = psKernelLevelCheckRun(remaining); return smaller(next); })())(__ps$match$0.state);
        case "final": return ((result) => result)(__ps$match$0.result);
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelCheckStep(state)))(__ps$match$0.remaining);
} throw new Error("invalid ProofScript constructor tag"); })(fuel); }
export function psKernelLookupStep(state) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$40]) {
    case "search": return ((name, entries) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
        case "nil": return PsKernelLookupStep["missing"];
        case "cons": return ((entry, rest) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$38]) {
            case "definition": return ((candidate, unusedType, unusedValue) => PsKernelLookupStep["next"](PsKernelLookupState["compare"](name, entry, rest, PsKernelList["cons"](PsKernelOrderTask["name"](name, candidate), PsKernelList["nil"]()))))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value);
        } throw new Error("invalid ProofScript constructor tag"); })(entry))(__ps$match$0.head, __ps$match$0.tail);
    } throw new Error("invalid ProofScript constructor tag"); })(entries))(__ps$match$0.name, __ps$match$0.entries);
    case "compare": return ((name, entry, rest, tasks) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$28]) {
        case "next": return ((next) => PsKernelLookupStep["next"](PsKernelLookupState["compare"](name, entry, rest, next)))(__ps$match$0.tasks);
        case "done": return ((order) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$13]) {
            case "less": return PsKernelLookupStep["next"](PsKernelLookupState["search"](name, rest));
            case "same": return PsKernelLookupStep["found"](entry);
            case "greater": return PsKernelLookupStep["next"](PsKernelLookupState["search"](name, rest));
        } throw new Error("invalid ProofScript constructor tag"); })(order))(__ps$match$0.order);
        case "invalidState": return PsKernelLookupStep["invalidState"];
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelOrderStep(tasks)))(__ps$match$0.name, __ps$match$0.entry, __ps$match$0.rest, __ps$match$0.tasks);
} throw new Error("invalid ProofScript constructor tag"); })(state); }
export function psKernelReduceReject(error) { return PsKernelReduceStep["final"](PsKernelReduceResult["rejected"](error)); }
export function psKernelReduceNext(env, tasks, values) { return PsKernelReduceStep["next"](PsKernelReduceState["state"](env, tasks, values)); }
export function psKernelReducePush(env, tasks, values, value) { return psKernelReduceNext(env, tasks, PsKernelList["cons"](value, values)); }
export function psKernelReduceWhnf(env, tasks, values, value) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$21]) {
    case "bvar": return ((_wild0) => psKernelReducePush(env, tasks, values, value))(__ps$match$0.index);
    case "fvar": return ((unused) => psKernelReduceReject(PsKernelCheckError["invalidScope"]))(__ps$match$0.id);
    case "sortE": return ((_wild0) => psKernelReducePush(env, tasks, values, value))(__ps$match$0.level);
    case "constE": return ((name, levels) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
        case "nil": return psKernelReduceNext(env, PsKernelList["cons"](PsKernelReduceTask["lookup"](PsKernelLookupState["search"](name, env)), tasks), values);
        case "cons": return ((_wild0, _wild1) => psKernelReduceReject(PsKernelCheckError["unsupported"]))(__ps$match$0.head, __ps$match$0.tail);
    } throw new Error("invalid ProofScript constructor tag"); })(levels))(__ps$match$0.name, __ps$match$0.levels);
    case "app": return ((fn, arg) => psKernelReduceNext(env, PsKernelList["cons"](PsKernelReduceTask["whnf"](fn), PsKernelList["cons"](PsKernelReduceTask["apply"](arg), tasks)), values))(__ps$match$0.fn, __ps$match$0.arg);
    case "lam": return ((_wild0, _wild1, _wild2, _wild3) => psKernelReducePush(env, tasks, values, value))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
    case "forallE": return ((_wild0, _wild1, _wild2, _wild3) => psKernelReducePush(env, tasks, values, value))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
    case "letE": return ((unusedName, unusedType, val, body) => psKernelReduceNext(env, PsKernelList["cons"](PsKernelReduceTask["binding"](psKernelBindingStart(PsKernelBindingMode["instantiate"](val), PsKernelNatural["zero"], body)), PsKernelList["cons"](PsKernelReduceTask["resumeWhnf"], tasks)), values))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
    case "lit": return ((unused) => psKernelReduceReject(PsKernelCheckError["unsupported"]))(__ps$match$0.value);
    case "proj": return ((unusedName, unusedIndex, unusedValue) => psKernelReduceReject(PsKernelCheckError["unsupported"]))(__ps$match$0.family, __ps$match$0.index, __ps$match$0.value);
} throw new Error("invalid ProofScript constructor tag"); })(value); }
export function psKernelReduceValueTask(env, task, tasks, values) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
    case "nil": return psKernelReduceReject(PsKernelCheckError["invalidState"]);
    case "cons": return ((top, rest) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$42]) {
        case "whnf": return ((_wild0) => psKernelReduceReject(PsKernelCheckError["invalidState"]))(__ps$match$0.value);
        case "apply": return ((arg) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$21]) {
            case "bvar": return ((_wild0) => psKernelReducePush(env, tasks, rest, PsKernelExpr["app"](top, arg)))(__ps$match$0.index);
            case "fvar": return ((_wild0) => psKernelReducePush(env, tasks, rest, PsKernelExpr["app"](top, arg)))(__ps$match$0.id);
            case "sortE": return ((_wild0) => psKernelReducePush(env, tasks, rest, PsKernelExpr["app"](top, arg)))(__ps$match$0.level);
            case "constE": return ((_wild0, _wild1) => psKernelReducePush(env, tasks, rest, PsKernelExpr["app"](top, arg)))(__ps$match$0.name, __ps$match$0.levels);
            case "app": return ((_wild0, _wild1) => psKernelReducePush(env, tasks, rest, PsKernelExpr["app"](top, arg)))(__ps$match$0.fn, __ps$match$0.arg);
            case "lam": return ((unusedName, unusedType, body, unusedBinder) => psKernelReduceNext(env, PsKernelList["cons"](PsKernelReduceTask["binding"](psKernelBindingStart(PsKernelBindingMode["instantiate"](arg), PsKernelNatural["zero"], body)), PsKernelList["cons"](PsKernelReduceTask["resumeWhnf"], tasks)), rest))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
            case "forallE": return ((_wild0, _wild1, _wild2, _wild3) => psKernelReducePush(env, tasks, rest, PsKernelExpr["app"](top, arg)))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
            case "letE": return ((_wild0, _wild1, _wild2, _wild3) => psKernelReducePush(env, tasks, rest, PsKernelExpr["app"](top, arg)))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
            case "lit": return ((_wild0) => psKernelReducePush(env, tasks, rest, PsKernelExpr["app"](top, arg)))(__ps$match$0.value);
            case "proj": return ((_wild0, _wild1, _wild2) => psKernelReducePush(env, tasks, rest, PsKernelExpr["app"](top, arg)))(__ps$match$0.family, __ps$match$0.index, __ps$match$0.value);
        } throw new Error("invalid ProofScript constructor tag"); })(top))(__ps$match$0.arg);
        case "lookup": return ((_wild0) => psKernelReduceReject(PsKernelCheckError["invalidState"]))(__ps$match$0.state);
        case "binding": return ((_wild0) => psKernelReduceReject(PsKernelCheckError["invalidState"]))(__ps$match$0.state);
        case "resumeWhnf": return psKernelReduceNext(env, PsKernelList["cons"](PsKernelReduceTask["whnf"](top), tasks), rest);
        case "normal": return ((_wild0) => psKernelReduceReject(PsKernelCheckError["invalidState"]))(__ps$match$0.value);
        case "expand": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$21]) {
            case "bvar": return ((_wild0) => psKernelReducePush(env, tasks, rest, top))(__ps$match$0.index);
            case "fvar": return ((_wild0) => psKernelReducePush(env, tasks, rest, top))(__ps$match$0.id);
            case "sortE": return ((_wild0) => psKernelReducePush(env, tasks, rest, top))(__ps$match$0.level);
            case "constE": return ((_wild0, _wild1) => psKernelReducePush(env, tasks, rest, top))(__ps$match$0.name, __ps$match$0.levels);
            case "app": return ((fn, arg) => psKernelReduceNext(env, PsKernelList["cons"](PsKernelReduceTask["normal"](fn), PsKernelList["cons"](PsKernelReduceTask["normal"](arg), PsKernelList["cons"](PsKernelReduceTask["app"], tasks))), rest))(__ps$match$0.fn, __ps$match$0.arg);
            case "lam": return ((name, type, body, binder) => psKernelReduceNext(env, PsKernelList["cons"](PsKernelReduceTask["normal"](type), PsKernelList["cons"](PsKernelReduceTask["normal"](body), PsKernelList["cons"](PsKernelReduceTask["lam"](name, binder), tasks))), rest))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
            case "forallE": return ((name, type, body, binder) => psKernelReduceNext(env, PsKernelList["cons"](PsKernelReduceTask["normal"](type), PsKernelList["cons"](PsKernelReduceTask["normal"](body), PsKernelList["cons"](PsKernelReduceTask["forallE"](name, binder), tasks))), rest))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
            case "letE": return ((_wild0, _wild1, _wild2, _wild3) => psKernelReducePush(env, tasks, rest, top))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
            case "lit": return ((_wild0) => psKernelReducePush(env, tasks, rest, top))(__ps$match$0.value);
            case "proj": return ((_wild0, _wild1, _wild2) => psKernelReducePush(env, tasks, rest, top))(__ps$match$0.family, __ps$match$0.index, __ps$match$0.value);
        } throw new Error("invalid ProofScript constructor tag"); })(top);
        case "app": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return psKernelReduceReject(PsKernelCheckError["invalidState"]);
            case "cons": return ((fn, tail) => psKernelReducePush(env, tasks, tail, PsKernelExpr["app"](fn, top)))(__ps$match$0.head, __ps$match$0.tail);
        } throw new Error("invalid ProofScript constructor tag"); })(rest);
        case "lam": return ((name, binder) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return psKernelReduceReject(PsKernelCheckError["invalidState"]);
            case "cons": return ((type, tail) => psKernelReducePush(env, tasks, tail, PsKernelExpr["lam"](name, type, top, binder)))(__ps$match$0.head, __ps$match$0.tail);
        } throw new Error("invalid ProofScript constructor tag"); })(rest))(__ps$match$0.name, __ps$match$0.binder);
        case "forallE": return ((name, binder) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return psKernelReduceReject(PsKernelCheckError["invalidState"]);
            case "cons": return ((type, tail) => psKernelReducePush(env, tasks, tail, PsKernelExpr["forallE"](name, type, top, binder)))(__ps$match$0.head, __ps$match$0.tail);
        } throw new Error("invalid ProofScript constructor tag"); })(rest))(__ps$match$0.name, __ps$match$0.binder);
    } throw new Error("invalid ProofScript constructor tag"); })(task))(__ps$match$0.head, __ps$match$0.tail);
} throw new Error("invalid ProofScript constructor tag"); })(values); }
export function psKernelReduceStep(state) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$43]) {
    case "state": return ((env, tasks, values) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
        case "nil": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return psKernelReduceReject(PsKernelCheckError["invalidState"]);
            case "cons": return ((value, rest) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return PsKernelReduceStep["final"](PsKernelReduceResult["done"](value));
                case "cons": return ((_wild0, _wild1) => psKernelReduceReject(PsKernelCheckError["invalidState"]))(__ps$match$0.head, __ps$match$0.tail);
            } throw new Error("invalid ProofScript constructor tag"); })(rest))(__ps$match$0.head, __ps$match$0.tail);
        } throw new Error("invalid ProofScript constructor tag"); })(values);
        case "cons": return ((task, rest) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$42]) {
            case "whnf": return ((value) => psKernelReduceWhnf(env, rest, values, value))(__ps$match$0.value);
            case "apply": return ((_wild0) => psKernelReduceValueTask(env, task, rest, values))(__ps$match$0.arg);
            case "lookup": return ((current) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$41]) {
                case "next": return ((next) => psKernelReduceNext(env, PsKernelList["cons"](PsKernelReduceTask["lookup"](next), rest), values))(__ps$match$0.state);
                case "found": return ((entry) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$38]) {
                    case "definition": return ((unusedName, unusedType, value) => psKernelReduceNext(env, PsKernelList["cons"](PsKernelReduceTask["whnf"](value), rest), values))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value);
                } throw new Error("invalid ProofScript constructor tag"); })(entry))(__ps$match$0.entry);
                case "missing": return psKernelReduceReject(PsKernelCheckError["unknownConstant"]);
                case "invalidState": return psKernelReduceReject(PsKernelCheckError["invalidState"]);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelLookupStep(current)))(__ps$match$0.state);
            case "binding": return ((current) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$26]) {
                case "next": return ((next) => psKernelReduceNext(env, PsKernelList["cons"](PsKernelReduceTask["binding"](next), rest), values))(__ps$match$0.state);
                case "final": return ((result) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$25]) {
                    case "outOfFuel": return psKernelReduceReject(PsKernelCheckError["invalidState"]);
                    case "invalidState": return psKernelReduceReject(PsKernelCheckError["invalidState"]);
                    case "invalidScope": return psKernelReduceReject(PsKernelCheckError["invalidScope"]);
                    case "done": return ((value) => psKernelReducePush(env, rest, values, value))(__ps$match$0.value);
                } throw new Error("invalid ProofScript constructor tag"); })(result))(__ps$match$0.result);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelBindingStep(current)))(__ps$match$0.state);
            case "resumeWhnf": return psKernelReduceValueTask(env, task, rest, values);
            case "normal": return ((value) => psKernelReduceNext(env, PsKernelList["cons"](PsKernelReduceTask["whnf"](value), PsKernelList["cons"](PsKernelReduceTask["expand"], rest)), values))(__ps$match$0.value);
            case "expand": return psKernelReduceValueTask(env, task, rest, values);
            case "app": return psKernelReduceValueTask(env, task, rest, values);
            case "lam": return ((_wild0, _wild1) => psKernelReduceValueTask(env, task, rest, values))(__ps$match$0.name, __ps$match$0.binder);
            case "forallE": return ((_wild0, _wild1) => psKernelReduceValueTask(env, task, rest, values))(__ps$match$0.name, __ps$match$0.binder);
        } throw new Error("invalid ProofScript constructor tag"); })(task))(__ps$match$0.head, __ps$match$0.tail);
    } throw new Error("invalid ProofScript constructor tag"); })(tasks))(__ps$match$0.environment, __ps$match$0.tasks, __ps$match$0.values);
} throw new Error("invalid ProofScript constructor tag"); })(state); }
export function psKernelWhnfStart(env, value) { return PsKernelReduceState["state"](env, PsKernelList["cons"](PsKernelReduceTask["whnf"](value), PsKernelList["nil"]()), PsKernelList["nil"]()); }
export function psKernelNormalStart(env, value) { return PsKernelReduceState["state"](env, PsKernelList["cons"](PsKernelReduceTask["normal"](value), PsKernelList["nil"]()), PsKernelList["nil"]()); }
export function psKernelReduceRun(fuel) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$11]) {
    case "stop": return (state) => PsKernelReduceResult["outOfFuel"];
    case "more": return ((remaining) => (state) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$45]) {
        case "next": return ((next) => (() => { const smaller = psKernelReduceRun(remaining); return smaller(next); })())(__ps$match$0.state);
        case "final": return ((result) => result)(__ps$match$0.result);
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelReduceStep(state)))(__ps$match$0.remaining);
} throw new Error("invalid ProofScript constructor tag"); })(fuel); }
export function psKernelConversionReject(error) { return PsKernelConversionStep["final"](PsKernelConversionResult["rejected"](error)); }
export function psKernelConversionTasks(tasks) { return PsKernelConversionStep["next"](PsKernelConversionState["compare"](tasks)); }
export function psKernelConversionExpr(left, right, tasks) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$21]) {
    case "bvar": return ((index) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$21]) {
        case "bvar": return ((other) => psKernelConversionTasks(PsKernelList["cons"](PsKernelConversionTask["natural"](PsKernelNumericState["order"](index, other, PsKernelOrder["same"])), tasks)))(__ps$match$0.index);
        case "fvar": return ((_wild0) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.id);
        case "sortE": return ((_wild0) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.level);
        case "constE": return ((_wild0, _wild1) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.name, __ps$match$0.levels);
        case "app": return ((_wild0, _wild1) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.fn, __ps$match$0.arg);
        case "lam": return ((_wild0, _wild1, _wild2, _wild3) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
        case "forallE": return ((_wild0, _wild1, _wild2, _wild3) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
        case "letE": return ((_wild0, _wild1, _wild2, _wild3) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
        case "lit": return ((_wild0) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.value);
        case "proj": return ((_wild0, _wild1, _wild2) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.family, __ps$match$0.index, __ps$match$0.value);
    } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.index);
    case "fvar": return ((_wild0) => psKernelConversionReject(PsKernelCheckError["unsupported"]))(__ps$match$0.id);
    case "sortE": return ((level) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$21]) {
        case "bvar": return ((_wild0) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.index);
        case "fvar": return ((_wild0) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.id);
        case "sortE": return ((other) => psKernelConversionTasks(PsKernelList["cons"](PsKernelConversionTask["level"](psKernelLevelCheckStart(level, other)), tasks)))(__ps$match$0.level);
        case "constE": return ((_wild0, _wild1) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.name, __ps$match$0.levels);
        case "app": return ((_wild0, _wild1) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.fn, __ps$match$0.arg);
        case "lam": return ((_wild0, _wild1, _wild2, _wild3) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
        case "forallE": return ((_wild0, _wild1, _wild2, _wild3) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
        case "letE": return ((_wild0, _wild1, _wild2, _wild3) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
        case "lit": return ((_wild0) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.value);
        case "proj": return ((_wild0, _wild1, _wild2) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.family, __ps$match$0.index, __ps$match$0.value);
    } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.level);
    case "constE": return ((_wild0, _wild1) => psKernelConversionReject(PsKernelCheckError["unsupported"]))(__ps$match$0.name, __ps$match$0.levels);
    case "app": return ((fn, arg) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$21]) {
        case "bvar": return ((_wild0) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.index);
        case "fvar": return ((_wild0) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.id);
        case "sortE": return ((_wild0) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.level);
        case "constE": return ((_wild0, _wild1) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.name, __ps$match$0.levels);
        case "app": return ((otherFn, otherArg) => psKernelConversionTasks(PsKernelList["cons"](PsKernelConversionTask["expr"](fn, otherFn), PsKernelList["cons"](PsKernelConversionTask["expr"](arg, otherArg), tasks))))(__ps$match$0.fn, __ps$match$0.arg);
        case "lam": return ((_wild0, _wild1, _wild2, _wild3) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
        case "forallE": return ((_wild0, _wild1, _wild2, _wild3) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
        case "letE": return ((_wild0, _wild1, _wild2, _wild3) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
        case "lit": return ((_wild0) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.value);
        case "proj": return ((_wild0, _wild1, _wild2) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.family, __ps$match$0.index, __ps$match$0.value);
    } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.fn, __ps$match$0.arg);
    case "lam": return ((unusedName, type, body, unusedBinder) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$21]) {
        case "bvar": return ((_wild0) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.index);
        case "fvar": return ((_wild0) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.id);
        case "sortE": return ((_wild0) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.level);
        case "constE": return ((_wild0, _wild1) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.name, __ps$match$0.levels);
        case "app": return ((_wild0, _wild1) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.fn, __ps$match$0.arg);
        case "lam": return ((unusedOtherName, otherType, otherBody, unusedOtherBinder) => psKernelConversionTasks(PsKernelList["cons"](PsKernelConversionTask["expr"](type, otherType), PsKernelList["cons"](PsKernelConversionTask["expr"](body, otherBody), tasks))))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
        case "forallE": return ((_wild0, _wild1, _wild2, _wild3) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
        case "letE": return ((_wild0, _wild1, _wild2, _wild3) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
        case "lit": return ((_wild0) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.value);
        case "proj": return ((_wild0, _wild1, _wild2) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.family, __ps$match$0.index, __ps$match$0.value);
    } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
    case "forallE": return ((unusedName, type, body, unusedBinder) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$21]) {
        case "bvar": return ((_wild0) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.index);
        case "fvar": return ((_wild0) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.id);
        case "sortE": return ((_wild0) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.level);
        case "constE": return ((_wild0, _wild1) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.name, __ps$match$0.levels);
        case "app": return ((_wild0, _wild1) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.fn, __ps$match$0.arg);
        case "lam": return ((_wild0, _wild1, _wild2, _wild3) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
        case "forallE": return ((unusedOtherName, otherType, otherBody, unusedOtherBinder) => psKernelConversionTasks(PsKernelList["cons"](PsKernelConversionTask["expr"](type, otherType), PsKernelList["cons"](PsKernelConversionTask["expr"](body, otherBody), tasks))))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
        case "letE": return ((_wild0, _wild1, _wild2, _wild3) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
        case "lit": return ((_wild0) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.value);
        case "proj": return ((_wild0, _wild1, _wild2) => PsKernelConversionStep["final"](PsKernelConversionResult["different"]))(__ps$match$0.family, __ps$match$0.index, __ps$match$0.value);
    } throw new Error("invalid ProofScript constructor tag"); })(right))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
    case "letE": return ((_wild0, _wild1, _wild2, _wild3) => psKernelConversionReject(PsKernelCheckError["unsupported"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
    case "lit": return ((_wild0) => psKernelConversionReject(PsKernelCheckError["unsupported"]))(__ps$match$0.value);
    case "proj": return ((_wild0, _wild1, _wild2) => psKernelConversionReject(PsKernelCheckError["unsupported"]))(__ps$match$0.family, __ps$match$0.index, __ps$match$0.value);
} throw new Error("invalid ProofScript constructor tag"); })(left); }
export function psKernelConversionStep(state) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$47]) {
    case "left": return ((env, right, current) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$45]) {
        case "next": return ((next) => PsKernelConversionStep["next"](PsKernelConversionState["left"](env, right, next)))(__ps$match$0.state);
        case "final": return ((result) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$44]) {
            case "outOfFuel": return psKernelConversionReject(PsKernelCheckError["invalidState"]);
            case "rejected": return ((error) => psKernelConversionReject(error))(__ps$match$0.error);
            case "done": return ((left) => PsKernelConversionStep["next"](PsKernelConversionState["right"](left, psKernelNormalStart(env, right))))(__ps$match$0.value);
        } throw new Error("invalid ProofScript constructor tag"); })(result))(__ps$match$0.result);
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelReduceStep(current)))(__ps$match$0.environment, __ps$match$0.right, __ps$match$0.state);
    case "right": return ((left, current) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$45]) {
        case "next": return ((next) => PsKernelConversionStep["next"](PsKernelConversionState["right"](left, next)))(__ps$match$0.state);
        case "final": return ((result) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$44]) {
            case "outOfFuel": return psKernelConversionReject(PsKernelCheckError["invalidState"]);
            case "rejected": return ((error) => psKernelConversionReject(error))(__ps$match$0.error);
            case "done": return ((right) => psKernelConversionTasks(PsKernelList["cons"](PsKernelConversionTask["expr"](left, right), PsKernelList["nil"]())))(__ps$match$0.value);
        } throw new Error("invalid ProofScript constructor tag"); })(result))(__ps$match$0.result);
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelReduceStep(current)))(__ps$match$0.left, __ps$match$0.state);
    case "compare": return ((tasks) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
        case "nil": return PsKernelConversionStep["final"](PsKernelConversionResult["equal"]);
        case "cons": return ((task, rest) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$46]) {
            case "expr": return ((left, right) => psKernelConversionExpr(left, right, rest))(__ps$match$0.left, __ps$match$0.right);
            case "natural": return ((current) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$17]) {
                case "next": return ((next) => psKernelConversionTasks(PsKernelList["cons"](PsKernelConversionTask["natural"](next), rest)))(__ps$match$0.state);
                case "ordered": return ((order) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$13]) {
                    case "less": return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
                    case "same": return psKernelConversionTasks(rest);
                    case "greater": return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
                } throw new Error("invalid ProofScript constructor tag"); })(order))(__ps$match$0.order);
                case "sum": return ((_wild0) => psKernelConversionReject(PsKernelCheckError["invalidState"]))(__ps$match$0.value);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelNumericStep(current)))(__ps$match$0.state);
            case "level": return ((current) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$37]) {
                case "next": return ((next) => psKernelConversionTasks(PsKernelList["cons"](PsKernelConversionTask["level"](next), rest)))(__ps$match$0.state);
                case "final": return ((result) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$36]) {
                    case "outOfFuel": return psKernelConversionReject(PsKernelCheckError["invalidState"]);
                    case "invalidState": return psKernelConversionReject(PsKernelCheckError["invalidState"]);
                    case "equal": return psKernelConversionTasks(rest);
                    case "different": return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
                } throw new Error("invalid ProofScript constructor tag"); })(result))(__ps$match$0.result);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelLevelCheckStep(current)))(__ps$match$0.state);
        } throw new Error("invalid ProofScript constructor tag"); })(task))(__ps$match$0.head, __ps$match$0.tail);
    } throw new Error("invalid ProofScript constructor tag"); })(tasks))(__ps$match$0.tasks);
} throw new Error("invalid ProofScript constructor tag"); })(state); }
export function psKernelConversionStart(env, left, right) { return PsKernelConversionState["left"](env, right, psKernelNormalStart(env, left)); }
export function psKernelConversionRun(fuel) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$11]) {
    case "stop": return (state) => PsKernelConversionResult["outOfFuel"];
    case "more": return ((remaining) => (state) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$49]) {
        case "next": return ((next) => (() => { const smaller = psKernelConversionRun(remaining); return smaller(next); })())(__ps$match$0.state);
        case "final": return ((result) => result)(__ps$match$0.result);
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelConversionStep(state)))(__ps$match$0.remaining);
} throw new Error("invalid ProofScript constructor tag"); })(fuel); }
export function psKernelTypeReject(error) { return PsKernelTypeStep["final"](PsKernelTypeResult["rejected"](error)); }
export function psKernelTypeNext(env, tasks, values) { return PsKernelTypeStep["next"](PsKernelTypeState["state"](env, tasks, values)); }
export function psKernelTypePush(env, tasks, values, value) { return psKernelTypeNext(env, tasks, PsKernelList["cons"](value, values)); }
export function psKernelTypeInfer(env, context, value, tasks, values) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$21]) {
    case "bvar": return ((index) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["bound"](context, index, psKernelNaturalSucc(index)), tasks), values))(__ps$match$0.index);
    case "fvar": return ((unused) => psKernelTypeReject(PsKernelCheckError["invalidScope"]))(__ps$match$0.id);
    case "sortE": return ((level) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["levels"](PsKernelList["cons"](level, PsKernelList["nil"]()), PsKernelExpr["sortE"](PsKernelLevel["succ"](level))), tasks), values))(__ps$match$0.level);
    case "constE": return ((name, levels) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
        case "nil": return psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["lookup"](PsKernelLookupState["search"](name, env)), tasks), values);
        case "cons": return ((_wild0, _wild1) => psKernelTypeReject(PsKernelCheckError["unsupported"]))(__ps$match$0.head, __ps$match$0.tail);
    } throw new Error("invalid ProofScript constructor tag"); })(levels))(__ps$match$0.name, __ps$match$0.levels);
    case "app": return ((fn, arg) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["infer"](context, fn), PsKernelList["cons"](PsKernelTypeTask["reduceTop"], PsKernelList["cons"](PsKernelTypeTask["appPi"](context, arg), tasks))), values))(__ps$match$0.fn, __ps$match$0.arg);
    case "lam": return ((name, type, body, binder) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["infer"](context, type), PsKernelList["cons"](PsKernelTypeTask["reduceTop"], PsKernelList["cons"](PsKernelTypeTask["lamSort"](context, name, type, body, binder), tasks))), values))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
    case "forallE": return ((unusedName, type, body, unusedBinder) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["infer"](context, type), PsKernelList["cons"](PsKernelTypeTask["reduceTop"], PsKernelList["cons"](PsKernelTypeTask["piDomain"](context, type, body), tasks))), values))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
    case "letE": return ((unusedName, type, val, body) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["infer"](context, type), PsKernelList["cons"](PsKernelTypeTask["reduceTop"], PsKernelList["cons"](PsKernelTypeTask["letSort"](context, type, val, body), tasks))), values))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
    case "lit": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["unsupported"]))(__ps$match$0.value);
    case "proj": return ((_wild0, _wild1, _wild2) => psKernelTypeReject(PsKernelCheckError["unsupported"]))(__ps$match$0.family, __ps$match$0.index, __ps$match$0.value);
} throw new Error("invalid ProofScript constructor tag"); })(value); }
export function psKernelTypeValueTask(env, task, tasks, values) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
    case "nil": return psKernelTypeReject(PsKernelCheckError["invalidState"]);
    case "cons": return ((top, rest) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$50]) {
        case "infer": return ((_wild0, _wild1) => psKernelTypeReject(PsKernelCheckError["invalidState"]))(__ps$match$0.context, __ps$match$0.value);
        case "levels": return ((_wild0, _wild1) => psKernelTypeReject(PsKernelCheckError["invalidState"]))(__ps$match$0.pending, __ps$match$0.result);
        case "bound": return ((_wild0, _wild1, _wild2) => psKernelTypeReject(PsKernelCheckError["invalidState"]))(__ps$match$0.context, __ps$match$0.index, __ps$match$0.shift);
        case "lookup": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["invalidState"]))(__ps$match$0.state);
        case "binding": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["invalidState"]))(__ps$match$0.state);
        case "reduce": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["invalidState"]))(__ps$match$0.state);
        case "reduceTop": return psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["reduce"](psKernelWhnfStart(env, top)), tasks), rest);
        case "conversion": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["invalidState"]))(__ps$match$0.state);
        case "returnE": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["invalidState"]))(__ps$match$0.value);
        case "lamSort": return ((context, name, type, body, binder) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$21]) {
            case "bvar": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.index);
            case "fvar": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.id);
            case "sortE": return ((unusedLevel) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["infer"](PsKernelList["cons"](type, context), body), PsKernelList["cons"](PsKernelTypeTask["lamFinish"](name, type, binder), tasks)), rest))(__ps$match$0.level);
            case "constE": return ((_wild0, _wild1) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.name, __ps$match$0.levels);
            case "app": return ((_wild0, _wild1) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.fn, __ps$match$0.arg);
            case "lam": return ((_wild0, _wild1, _wild2, _wild3) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
            case "forallE": return ((_wild0, _wild1, _wild2, _wild3) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
            case "letE": return ((_wild0, _wild1, _wild2, _wild3) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
            case "lit": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.value);
            case "proj": return ((_wild0, _wild1, _wild2) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.family, __ps$match$0.index, __ps$match$0.value);
        } throw new Error("invalid ProofScript constructor tag"); })(top))(__ps$match$0.context, __ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
        case "lamFinish": return ((name, type, binder) => psKernelTypePush(env, tasks, rest, PsKernelExpr["forallE"](name, type, top, binder)))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.binder);
        case "piDomain": return ((context, type, body) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$21]) {
            case "bvar": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.index);
            case "fvar": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.id);
            case "sortE": return ((level) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["infer"](PsKernelList["cons"](type, context), body), PsKernelList["cons"](PsKernelTypeTask["reduceTop"], PsKernelList["cons"](PsKernelTypeTask["piFinish"](level), tasks))), rest))(__ps$match$0.level);
            case "constE": return ((_wild0, _wild1) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.name, __ps$match$0.levels);
            case "app": return ((_wild0, _wild1) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.fn, __ps$match$0.arg);
            case "lam": return ((_wild0, _wild1, _wild2, _wild3) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
            case "forallE": return ((_wild0, _wild1, _wild2, _wild3) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
            case "letE": return ((_wild0, _wild1, _wild2, _wild3) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
            case "lit": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.value);
            case "proj": return ((_wild0, _wild1, _wild2) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.family, __ps$match$0.index, __ps$match$0.value);
        } throw new Error("invalid ProofScript constructor tag"); })(top))(__ps$match$0.context, __ps$match$0.type, __ps$match$0.body);
        case "piFinish": return ((domainLevel) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$21]) {
            case "bvar": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.index);
            case "fvar": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.id);
            case "sortE": return ((bodyLevel) => psKernelTypePush(env, tasks, rest, PsKernelExpr["sortE"](PsKernelLevel["imax"](domainLevel, bodyLevel))))(__ps$match$0.level);
            case "constE": return ((_wild0, _wild1) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.name, __ps$match$0.levels);
            case "app": return ((_wild0, _wild1) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.fn, __ps$match$0.arg);
            case "lam": return ((_wild0, _wild1, _wild2, _wild3) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
            case "forallE": return ((_wild0, _wild1, _wild2, _wild3) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
            case "letE": return ((_wild0, _wild1, _wild2, _wild3) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
            case "lit": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.value);
            case "proj": return ((_wild0, _wild1, _wild2) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.family, __ps$match$0.index, __ps$match$0.value);
        } throw new Error("invalid ProofScript constructor tag"); })(top))(__ps$match$0.domainLevel);
        case "appPi": return ((context, arg) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$21]) {
            case "bvar": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["functionExpected"]))(__ps$match$0.index);
            case "fvar": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["functionExpected"]))(__ps$match$0.id);
            case "sortE": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["functionExpected"]))(__ps$match$0.level);
            case "constE": return ((_wild0, _wild1) => psKernelTypeReject(PsKernelCheckError["functionExpected"]))(__ps$match$0.name, __ps$match$0.levels);
            case "app": return ((_wild0, _wild1) => psKernelTypeReject(PsKernelCheckError["functionExpected"]))(__ps$match$0.fn, __ps$match$0.arg);
            case "lam": return ((_wild0, _wild1, _wild2, _wild3) => psKernelTypeReject(PsKernelCheckError["functionExpected"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
            case "forallE": return ((unusedName, domain, body, unusedBinder) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["infer"](context, arg), PsKernelList["cons"](PsKernelTypeTask["appArgument"](domain, body, arg), tasks)), rest))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
            case "letE": return ((_wild0, _wild1, _wild2, _wild3) => psKernelTypeReject(PsKernelCheckError["functionExpected"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
            case "lit": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["functionExpected"]))(__ps$match$0.value);
            case "proj": return ((_wild0, _wild1, _wild2) => psKernelTypeReject(PsKernelCheckError["functionExpected"]))(__ps$match$0.family, __ps$match$0.index, __ps$match$0.value);
        } throw new Error("invalid ProofScript constructor tag"); })(top))(__ps$match$0.context, __ps$match$0.arg);
        case "appArgument": return ((domain, body, arg) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["conversion"](psKernelConversionStart(env, top, domain)), PsKernelList["cons"](PsKernelTypeTask["binding"](psKernelBindingStart(PsKernelBindingMode["instantiate"](arg), PsKernelNatural["zero"], body)), tasks)), rest))(__ps$match$0.domain, __ps$match$0.body, __ps$match$0.arg);
        case "letSort": return ((context, type, value, body) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$21]) {
            case "bvar": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.index);
            case "fvar": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.id);
            case "sortE": return ((unusedLevel) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["infer"](context, value), PsKernelList["cons"](PsKernelTypeTask["letValue"](context, type, value, body), tasks)), rest))(__ps$match$0.level);
            case "constE": return ((_wild0, _wild1) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.name, __ps$match$0.levels);
            case "app": return ((_wild0, _wild1) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.fn, __ps$match$0.arg);
            case "lam": return ((_wild0, _wild1, _wild2, _wild3) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
            case "forallE": return ((_wild0, _wild1, _wild2, _wild3) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
            case "letE": return ((_wild0, _wild1, _wild2, _wild3) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
            case "lit": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.value);
            case "proj": return ((_wild0, _wild1, _wild2) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.family, __ps$match$0.index, __ps$match$0.value);
        } throw new Error("invalid ProofScript constructor tag"); })(top))(__ps$match$0.context, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
        case "letValue": return ((context, type, value, body) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["conversion"](psKernelConversionStart(env, top, type)), PsKernelList["cons"](PsKernelTypeTask["binding"](psKernelBindingStart(PsKernelBindingMode["instantiate"](value), PsKernelNatural["zero"], body)), PsKernelList["cons"](PsKernelTypeTask["letBody"](context), tasks))), rest))(__ps$match$0.context, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
        case "letBody": return ((context) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["infer"](context, top), tasks), rest))(__ps$match$0.context);
        case "checkSort": return ((value, type) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$21]) {
            case "bvar": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.index);
            case "fvar": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.id);
            case "sortE": return ((unusedLevel) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["infer"](PsKernelList["nil"](), value), PsKernelList["cons"](PsKernelTypeTask["checkValue"](type), tasks)), rest))(__ps$match$0.level);
            case "constE": return ((_wild0, _wild1) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.name, __ps$match$0.levels);
            case "app": return ((_wild0, _wild1) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.fn, __ps$match$0.arg);
            case "lam": return ((_wild0, _wild1, _wild2, _wild3) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
            case "forallE": return ((_wild0, _wild1, _wild2, _wild3) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
            case "letE": return ((_wild0, _wild1, _wild2, _wild3) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
            case "lit": return ((_wild0) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.value);
            case "proj": return ((_wild0, _wild1, _wild2) => psKernelTypeReject(PsKernelCheckError["typeExpected"]))(__ps$match$0.family, __ps$match$0.index, __ps$match$0.value);
        } throw new Error("invalid ProofScript constructor tag"); })(top))(__ps$match$0.value, __ps$match$0.type);
        case "checkValue": return ((type) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["conversion"](psKernelConversionStart(env, top, type)), PsKernelList["cons"](PsKernelTypeTask["returnE"](type), tasks)), rest))(__ps$match$0.type);
    } throw new Error("invalid ProofScript constructor tag"); })(task))(__ps$match$0.head, __ps$match$0.tail);
} throw new Error("invalid ProofScript constructor tag"); })(values); }
export function psKernelTypeLevels(env, pending, result, tasks, values) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
    case "nil": return psKernelTypePush(env, tasks, values, result);
    case "cons": return ((level, rest) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$7]) {
        case "zero": return psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["levels"](rest, result), tasks), values);
        case "succ": return ((next) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["levels"](PsKernelList["cons"](next, rest), result), tasks), values))(__ps$match$0.value);
        case "max": return ((left, right) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["levels"](PsKernelList["cons"](left, PsKernelList["cons"](right, rest)), result), tasks), values))(__ps$match$0.left, __ps$match$0.right);
        case "imax": return ((left, right) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["levels"](PsKernelList["cons"](left, PsKernelList["cons"](right, rest)), result), tasks), values))(__ps$match$0.left, __ps$match$0.right);
        case "param": return ((unusedName) => psKernelTypeReject(PsKernelCheckError["unsupported"]))(__ps$match$0.name);
    } throw new Error("invalid ProofScript constructor tag"); })(level))(__ps$match$0.head, __ps$match$0.tail);
} throw new Error("invalid ProofScript constructor tag"); })(pending); }
export function psKernelTypeStep(state) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$51]) {
    case "state": return ((env, tasks, values) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
        case "nil": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return psKernelTypeReject(PsKernelCheckError["invalidState"]);
            case "cons": return ((type, rest) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return PsKernelTypeStep["final"](PsKernelTypeResult["done"](type));
                case "cons": return ((_wild0, _wild1) => psKernelTypeReject(PsKernelCheckError["invalidState"]))(__ps$match$0.head, __ps$match$0.tail);
            } throw new Error("invalid ProofScript constructor tag"); })(rest))(__ps$match$0.head, __ps$match$0.tail);
        } throw new Error("invalid ProofScript constructor tag"); })(values);
        case "cons": return ((task, rest) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$50]) {
            case "infer": return ((context, value) => psKernelTypeInfer(env, context, value, rest, values))(__ps$match$0.context, __ps$match$0.value);
            case "levels": return ((pending, result) => psKernelTypeLevels(env, pending, result, rest, values))(__ps$match$0.pending, __ps$match$0.result);
            case "bound": return ((context, index, shift) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return psKernelTypeReject(PsKernelCheckError["invalidScope"]);
                case "cons": return ((type, tail) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$4]) {
                    case "zero": return psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["binding"](psKernelBindingStart(PsKernelBindingMode["lift"](shift), PsKernelNatural["zero"], type)), rest), values);
                    case "positive": return ((_wild0) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["bound"](tail, psKernelNaturalPred(index), shift), rest), values))(__ps$match$0.value);
                } throw new Error("invalid ProofScript constructor tag"); })(index))(__ps$match$0.head, __ps$match$0.tail);
            } throw new Error("invalid ProofScript constructor tag"); })(context))(__ps$match$0.context, __ps$match$0.index, __ps$match$0.shift);
            case "lookup": return ((current) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$41]) {
                case "next": return ((next) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["lookup"](next), rest), values))(__ps$match$0.state);
                case "found": return ((entry) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$38]) {
                    case "definition": return ((unusedName, type, unusedValue) => psKernelTypePush(env, rest, values, type))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value);
                } throw new Error("invalid ProofScript constructor tag"); })(entry))(__ps$match$0.entry);
                case "missing": return psKernelTypeReject(PsKernelCheckError["unknownConstant"]);
                case "invalidState": return psKernelTypeReject(PsKernelCheckError["invalidState"]);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelLookupStep(current)))(__ps$match$0.state);
            case "binding": return ((current) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$26]) {
                case "next": return ((next) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["binding"](next), rest), values))(__ps$match$0.state);
                case "final": return ((result) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$25]) {
                    case "outOfFuel": return psKernelTypeReject(PsKernelCheckError["invalidState"]);
                    case "invalidState": return psKernelTypeReject(PsKernelCheckError["invalidState"]);
                    case "invalidScope": return psKernelTypeReject(PsKernelCheckError["invalidScope"]);
                    case "done": return ((value) => psKernelTypePush(env, rest, values, value))(__ps$match$0.value);
                } throw new Error("invalid ProofScript constructor tag"); })(result))(__ps$match$0.result);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelBindingStep(current)))(__ps$match$0.state);
            case "reduce": return ((current) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$45]) {
                case "next": return ((next) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["reduce"](next), rest), values))(__ps$match$0.state);
                case "final": return ((result) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$44]) {
                    case "outOfFuel": return psKernelTypeReject(PsKernelCheckError["invalidState"]);
                    case "rejected": return ((error) => psKernelTypeReject(error))(__ps$match$0.error);
                    case "done": return ((value) => psKernelTypePush(env, rest, values, value))(__ps$match$0.value);
                } throw new Error("invalid ProofScript constructor tag"); })(result))(__ps$match$0.result);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelReduceStep(current)))(__ps$match$0.state);
            case "reduceTop": return psKernelTypeValueTask(env, task, rest, values);
            case "conversion": return ((current) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$49]) {
                case "next": return ((next) => psKernelTypeNext(env, PsKernelList["cons"](PsKernelTypeTask["conversion"](next), rest), values))(__ps$match$0.state);
                case "final": return ((result) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$48]) {
                    case "outOfFuel": return psKernelTypeReject(PsKernelCheckError["invalidState"]);
                    case "rejected": return ((error) => psKernelTypeReject(error))(__ps$match$0.error);
                    case "equal": return psKernelTypeNext(env, rest, values);
                    case "different": return psKernelTypeReject(PsKernelCheckError["typeMismatch"]);
                } throw new Error("invalid ProofScript constructor tag"); })(result))(__ps$match$0.result);
            } throw new Error("invalid ProofScript constructor tag"); })(psKernelConversionStep(current)))(__ps$match$0.state);
            case "returnE": return ((value) => psKernelTypePush(env, rest, values, value))(__ps$match$0.value);
            case "lamSort": return ((_wild0, _wild1, _wild2, _wild3, _wild4) => psKernelTypeValueTask(env, task, rest, values))(__ps$match$0.context, __ps$match$0.name, __ps$match$0.type, __ps$match$0.body, __ps$match$0.binder);
            case "lamFinish": return ((_wild0, _wild1, _wild2) => psKernelTypeValueTask(env, task, rest, values))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.binder);
            case "piDomain": return ((_wild0, _wild1, _wild2) => psKernelTypeValueTask(env, task, rest, values))(__ps$match$0.context, __ps$match$0.type, __ps$match$0.body);
            case "piFinish": return ((_wild0) => psKernelTypeValueTask(env, task, rest, values))(__ps$match$0.domainLevel);
            case "appPi": return ((_wild0, _wild1) => psKernelTypeValueTask(env, task, rest, values))(__ps$match$0.context, __ps$match$0.arg);
            case "appArgument": return ((_wild0, _wild1, _wild2) => psKernelTypeValueTask(env, task, rest, values))(__ps$match$0.domain, __ps$match$0.body, __ps$match$0.arg);
            case "letSort": return ((_wild0, _wild1, _wild2, _wild3) => psKernelTypeValueTask(env, task, rest, values))(__ps$match$0.context, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
            case "letValue": return ((_wild0, _wild1, _wild2, _wild3) => psKernelTypeValueTask(env, task, rest, values))(__ps$match$0.context, __ps$match$0.type, __ps$match$0.value, __ps$match$0.body);
            case "letBody": return ((_wild0) => psKernelTypeValueTask(env, task, rest, values))(__ps$match$0.context);
            case "checkSort": return ((_wild0, _wild1) => psKernelTypeValueTask(env, task, rest, values))(__ps$match$0.value, __ps$match$0.type);
            case "checkValue": return ((_wild0) => psKernelTypeValueTask(env, task, rest, values))(__ps$match$0.type);
        } throw new Error("invalid ProofScript constructor tag"); })(task))(__ps$match$0.head, __ps$match$0.tail);
    } throw new Error("invalid ProofScript constructor tag"); })(tasks))(__ps$match$0.environment, __ps$match$0.tasks, __ps$match$0.values);
} throw new Error("invalid ProofScript constructor tag"); })(state); }
export function psKernelInferStart(env, value) { return PsKernelTypeState["state"](env, PsKernelList["cons"](PsKernelTypeTask["infer"](PsKernelList["nil"](), value), PsKernelList["nil"]()), PsKernelList["nil"]()); }
export function psKernelCheckStart(env, value, type) { return PsKernelTypeState["state"](env, PsKernelList["cons"](PsKernelTypeTask["infer"](PsKernelList["nil"](), type), PsKernelList["cons"](PsKernelTypeTask["reduceTop"], PsKernelList["cons"](PsKernelTypeTask["checkSort"](value, type), PsKernelList["nil"]()))), PsKernelList["nil"]()); }
export function psKernelTypeRun(fuel) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$11]) {
    case "stop": return (state) => PsKernelTypeResult["outOfFuel"];
    case "more": return ((remaining) => (state) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$53]) {
        case "next": return ((next) => (() => { const smaller = psKernelTypeRun(remaining); return smaller(next); })())(__ps$match$0.state);
        case "final": return ((result) => result)(__ps$match$0.result);
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelTypeStep(state)))(__ps$match$0.remaining);
} throw new Error("invalid ProofScript constructor tag"); })(fuel); }
export function psKernelAdmissionReject(error) { return PsKernelAdmissionStep["final"](PsKernelAdmissionResult["rejected"](error)); }
export function psKernelAdmissionStep(state) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$54]) {
    case "pending": return ((env, entries) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$8]) {
        case "nil": return PsKernelAdmissionStep["final"](PsKernelAdmissionResult["admitted"](env));
        case "cons": return ((entry, rest) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$38]) {
            case "definition": return ((name, unusedType, unusedValue) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$6]) {
                case "anonymous": return psKernelAdmissionReject(PsKernelCheckError["invalidName"]);
                case "str": return ((_wild0, _wild1) => PsKernelAdmissionStep["next"](PsKernelAdmissionState["duplicate"](env, entry, rest, PsKernelLookupState["search"](name, env))))(__ps$match$0.parent, __ps$match$0.value);
                case "num": return ((_wild0, _wild1) => PsKernelAdmissionStep["next"](PsKernelAdmissionState["duplicate"](env, entry, rest, PsKernelLookupState["search"](name, env))))(__ps$match$0.parent, __ps$match$0.value);
            } throw new Error("invalid ProofScript constructor tag"); })(name))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value);
        } throw new Error("invalid ProofScript constructor tag"); })(entry))(__ps$match$0.head, __ps$match$0.tail);
    } throw new Error("invalid ProofScript constructor tag"); })(entries))(__ps$match$0.environment, __ps$match$0.entries);
    case "duplicate": return ((env, entry, rest, current) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$41]) {
        case "next": return ((next) => PsKernelAdmissionStep["next"](PsKernelAdmissionState["duplicate"](env, entry, rest, next)))(__ps$match$0.state);
        case "found": return ((unusedEntry) => psKernelAdmissionReject(PsKernelCheckError["duplicateName"]))(__ps$match$0.entry);
        case "missing": return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$38]) {
            case "definition": return ((unusedName, type, value) => PsKernelAdmissionStep["next"](PsKernelAdmissionState["checking"](env, entry, rest, psKernelCheckStart(env, value, type))))(__ps$match$0.name, __ps$match$0.type, __ps$match$0.value);
        } throw new Error("invalid ProofScript constructor tag"); })(entry);
        case "invalidState": return psKernelAdmissionReject(PsKernelCheckError["invalidState"]);
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelLookupStep(current)))(__ps$match$0.environment, __ps$match$0.entry, __ps$match$0.rest, __ps$match$0.state);
    case "checking": return ((env, entry, rest, current) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$53]) {
        case "next": return ((next) => PsKernelAdmissionStep["next"](PsKernelAdmissionState["checking"](env, entry, rest, next)))(__ps$match$0.state);
        case "final": return ((result) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$52]) {
            case "outOfFuel": return psKernelAdmissionReject(PsKernelCheckError["invalidState"]);
            case "rejected": return ((error) => psKernelAdmissionReject(error))(__ps$match$0.error);
            case "done": return ((unusedType) => PsKernelAdmissionStep["next"](PsKernelAdmissionState["pending"](PsKernelList["cons"](entry, env), rest)))(__ps$match$0.type);
        } throw new Error("invalid ProofScript constructor tag"); })(result))(__ps$match$0.result);
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelTypeStep(current)))(__ps$match$0.environment, __ps$match$0.entry, __ps$match$0.rest, __ps$match$0.state);
} throw new Error("invalid ProofScript constructor tag"); })(state); }
export function psKernelAdmissionStart(entries) { return PsKernelAdmissionState["pending"](PsKernelList["nil"](), entries); }
export function psKernelAdmissionRun(fuel) { return ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$11]) {
    case "stop": return (state) => PsKernelAdmissionResult["outOfFuel"];
    case "more": return ((remaining) => (state) => ((__ps$match$0) => { switch (__ps$match$0[__ps$tag$56]) {
        case "next": return ((next) => (() => { const smaller = psKernelAdmissionRun(remaining); return smaller(next); })())(__ps$match$0.state);
        case "final": return ((result) => result)(__ps$match$0.result);
    } throw new Error("invalid ProofScript constructor tag"); })(psKernelAdmissionStep(state)))(__ps$match$0.remaining);
} throw new Error("invalid ProofScript constructor tag"); })(fuel); }
