const __ps$implementations = new WeakMap();
function __ps$run(root) {
    const pending = [root];
    let value = undefined;
    while (pending.length !== 0) {
        const next = pending[pending.length - 1].next(value);
        if (next.done) {
            pending.pop();
            value = next.value;
        }
        else {
            const { fn, args } = next.value;
            const implementation = __ps$implementations.get(fn);
            if (implementation) {
                pending.push(Reflect.apply(implementation, undefined, args));
                value = undefined;
            }
            else
                value = Reflect.apply(fn, undefined, args);
        }
    }
    return value;
}
function __ps$wrap(implementation) {
    const fn = (...args) => __ps$run(implementation(...args));
    __ps$implementations.set(fn, implementation);
    return fn;
}
function* __ps$invoke(fn, ...args) {
    return (yield { fn, args });
}
let __ps$lastUtf8;
let __ps$previousUtf8;
function __ps$utf8Width(code) { return code <= 0x7f ? 1 : code <= 0x7ff ? 2 : code <= 0xffff ? 3 : 4; }
function __ps$utf8(text) {
    if (__ps$lastUtf8?.text === text)
        return __ps$lastUtf8;
    if (__ps$previousUtf8?.text === text)
        return __ps$previousUtf8;
    let size = 0;
    for (const char of text)
        size += __ps$utf8Width(char.codePointAt(0) ?? 0);
    const positions = new Uint32Array(size + 1);
    let byte = 0, index = 0;
    for (const char of text) {
        positions[byte] = index + 1;
        const __ps_w = __ps$utf8Width(char.codePointAt(0) ?? 0);
        byte += __ps_w;
        index += char.length;
    }
    positions[size] = text.length + 1;
    __ps$previousUtf8 = __ps$lastUtf8;
    return __ps$lastUtf8 = { text, size: BigInt(size), positions };
}
function __ps$stringGet(text, position) {
    const view = __ps$utf8(text);
    if (position < 0n || position >= view.size)
        return "A";
    const index = view.positions[Number(position)];
    return index === 0 ? "A" : String.fromCodePoint(text.codePointAt(index - 1) ?? 65);
}
function __ps$stringNext(text, position) {
    const view = __ps$utf8(text);
    if (position < 0n || position >= view.size)
        return position + 1n;
    const index = view.positions[Number(position)];
    return index === 0 ? position + 1n : position + BigInt(__ps$utf8Width(text.codePointAt(index - 1) ?? 0));
}
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
    "insert": (__field0, __field1, __field2, __field3, __field4) => ({ [__ps$tag$31]: "insert", offset: __field0, todo: __field1, candidate: __field2, scan: __field3, prefixRev: __field4 }),
    "insertCompare": (__field0, __field1, __field2, __field3, __field4, __field5, __field6) => ({ [__ps$tag$31]: "insertCompare", offset: __field0, todo: __field1, candidate: __field2, current: __field3, tail: __field4, prefixRev: __field5, work: __field6 }),
    "insertOffset": (__field0, __field1, __field2, __field3, __field4, __field5, __field6) => ({ [__ps$tag$31]: "insertOffset", offset: __field0, todo: __field1, candidate: __field2, current: __field3, tail: __field4, prefixRev: __field5, numeric: __field6 }),
    "restore": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$31]: "restore", offset: __field0, todo: __field1, prefixRev: __field2, suffix: __field3 }),
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
const __ps$tag$38 = Symbol("ProofScript.PsKernelLevelAssignment.tag");
export const PsKernelLevelAssignment = {
    "assignment": (__field0, __field1) => ({ [__ps$tag$38]: "assignment", name: __field0, value: __field1 }),
};
const __ps$tag$39 = Symbol("ProofScript.PsKernelLevelInstantiateTask.tag");
export const PsKernelLevelInstantiateTask = {
    "visit": (__field0) => ({ [__ps$tag$39]: "visit", value: __field0 }),
    "succ": { [__ps$tag$39]: "succ" },
    "max": { [__ps$tag$39]: "max" },
    "imax": { [__ps$tag$39]: "imax" },
    "lookup": (__field0, __field1) => ({ [__ps$tag$39]: "lookup", name: __field0, remaining: __field1 }),
    "compare": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$39]: "compare", name: __field0, replacement: __field1, remaining: __field2, work: __field3 }),
};
const __ps$tag$40 = Symbol("ProofScript.PsKernelLevelInstantiateState.tag");
export const PsKernelLevelInstantiateState = {
    "parameters": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$40]: "parameters", names: __field0, levels: __field1, assignments: __field2, target: __field3 }),
    "unique": (__field0, __field1, __field2, __field3, __field4, __field5, __field6) => ({ [__ps$tag$40]: "unique", name: __field0, value: __field1, names: __field2, levels: __field3, assignments: __field4, remaining: __field5, target: __field6 }),
    "compare": (__field0, __field1, __field2, __field3, __field4, __field5, __field6, __field7) => ({ [__ps$tag$40]: "compare", name: __field0, value: __field1, names: __field2, levels: __field3, assignments: __field4, remaining: __field5, target: __field6, work: __field7 }),
    "running": (__field0, __field1, __field2) => ({ [__ps$tag$40]: "running", assignments: __field0, tasks: __field1, values: __field2 }),
};
const __ps$tag$41 = Symbol("ProofScript.PsKernelLevelInstantiateResult.tag");
export const PsKernelLevelInstantiateResult = {
    "outOfFuel": { [__ps$tag$41]: "outOfFuel" },
    "invalidState": { [__ps$tag$41]: "invalidState" },
    "invalidParameters": { [__ps$tag$41]: "invalidParameters" },
    "undeclaredParameter": { [__ps$tag$41]: "undeclaredParameter" },
    "done": (__field0) => ({ [__ps$tag$41]: "done", value: __field0 }),
};
const __ps$tag$42 = Symbol("ProofScript.PsKernelLevelInstantiateStep.tag");
export const PsKernelLevelInstantiateStep = {
    "next": (__field0) => ({ [__ps$tag$42]: "next", state: __field0 }),
    "final": (__field0) => ({ [__ps$tag$42]: "final", result: __field0 }),
};
const __ps$tag$43 = Symbol("ProofScript.PsKernelExprInstantiateTask.tag");
export const PsKernelExprInstantiateTask = {
    "validate": (__field0, __field1) => ({ [__ps$tag$43]: "validate", target: __field0, state: __field1 }),
    "visit": (__field0) => ({ [__ps$tag$43]: "visit", value: __field0 }),
    "sort": (__field0) => ({ [__ps$tag$43]: "sort", state: __field0 }),
    "constant": (__field0, __field1, __field2) => ({ [__ps$tag$43]: "constant", name: __field0, remaining: __field1, reversed: __field2 }),
    "constantLevel": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$43]: "constantLevel", name: __field0, remaining: __field1, reversed: __field2, state: __field3 }),
    "constantReverse": (__field0, __field1, __field2) => ({ [__ps$tag$43]: "constantReverse", name: __field0, remaining: __field1, levels: __field2 }),
    "rebuild": (__field0) => ({ [__ps$tag$43]: "rebuild", task: __field0 }),
};
const __ps$tag$44 = Symbol("ProofScript.PsKernelExprInstantiateState.tag");
export const PsKernelExprInstantiateState = {
    "state": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$44]: "state", names: __field0, levels: __field1, tasks: __field2, values: __field3 }),
};
const __ps$tag$45 = Symbol("ProofScript.PsKernelExprInstantiateResult.tag");
export const PsKernelExprInstantiateResult = {
    "outOfFuel": { [__ps$tag$45]: "outOfFuel" },
    "invalidState": { [__ps$tag$45]: "invalidState" },
    "invalidParameters": { [__ps$tag$45]: "invalidParameters" },
    "undeclaredParameter": { [__ps$tag$45]: "undeclaredParameter" },
    "done": (__field0) => ({ [__ps$tag$45]: "done", value: __field0 }),
};
const __ps$tag$46 = Symbol("ProofScript.PsKernelExprInstantiateStep.tag");
export const PsKernelExprInstantiateStep = {
    "next": (__field0) => ({ [__ps$tag$46]: "next", state: __field0 }),
    "final": (__field0) => ({ [__ps$tag$46]: "final", result: __field0 }),
};
const __ps$tag$47 = Symbol("ProofScript.PsKernelDefinition.tag");
export const PsKernelDefinition = {
    "definition": (__field0, __field1, __field2) => ({ [__ps$tag$47]: "definition", name: __field0, type: __field1, value: __field2 }),
    "polymorphic": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$47]: "polymorphic", name: __field0, parameters: __field1, type: __field2, value: __field3 }),
};
const __ps$tag$48 = Symbol("ProofScript.PsKernelTypingContext.tag");
export const PsKernelTypingContext = {
    "context": (__field0, __field1) => ({ [__ps$tag$48]: "context", declarations: __field0, parameters: __field1 }),
};
const __ps$tag$49 = Symbol("ProofScript.PsKernelCheckError.tag");
export const PsKernelCheckError = {
    "invalidState": { [__ps$tag$49]: "invalidState" },
    "invalidScope": { [__ps$tag$49]: "invalidScope" },
    "unknownConstant": { [__ps$tag$49]: "unknownConstant" },
    "unsupported": { [__ps$tag$49]: "unsupported" },
    "typeExpected": { [__ps$tag$49]: "typeExpected" },
    "functionExpected": { [__ps$tag$49]: "functionExpected" },
    "typeMismatch": { [__ps$tag$49]: "typeMismatch" },
    "duplicateName": { [__ps$tag$49]: "duplicateName" },
    "invalidName": { [__ps$tag$49]: "invalidName" },
    "invalidUniverse": { [__ps$tag$49]: "invalidUniverse" },
};
const __ps$tag$50 = Symbol("ProofScript.PsKernelLookupState.tag");
export const PsKernelLookupState = {
    "search": (__field0, __field1) => ({ [__ps$tag$50]: "search", name: __field0, entries: __field1 }),
    "compare": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$50]: "compare", name: __field0, entry: __field1, rest: __field2, tasks: __field3 }),
};
const __ps$tag$51 = Symbol("ProofScript.PsKernelLookupStep.tag");
export const PsKernelLookupStep = {
    "next": (__field0) => ({ [__ps$tag$51]: "next", state: __field0 }),
    "found": (__field0) => ({ [__ps$tag$51]: "found", entry: __field0 }),
    "missing": { [__ps$tag$51]: "missing" },
    "invalidState": { [__ps$tag$51]: "invalidState" },
};
const __ps$tag$52 = Symbol("ProofScript.PsKernelReduceTask.tag");
export const PsKernelReduceTask = {
    "whnf": (__field0) => ({ [__ps$tag$52]: "whnf", value: __field0 }),
    "apply": (__field0) => ({ [__ps$tag$52]: "apply", arg: __field0 }),
    "lookup": (__field0, __field1) => ({ [__ps$tag$52]: "lookup", levels: __field0, state: __field1 }),
    "instantiate": (__field0) => ({ [__ps$tag$52]: "instantiate", state: __field0 }),
    "binding": (__field0) => ({ [__ps$tag$52]: "binding", state: __field0 }),
    "resumeWhnf": { [__ps$tag$52]: "resumeWhnf" },
    "normal": (__field0) => ({ [__ps$tag$52]: "normal", value: __field0 }),
    "expand": { [__ps$tag$52]: "expand" },
    "app": { [__ps$tag$52]: "app" },
    "lam": (__field0, __field1) => ({ [__ps$tag$52]: "lam", name: __field0, binder: __field1 }),
    "forallE": (__field0, __field1) => ({ [__ps$tag$52]: "forallE", name: __field0, binder: __field1 }),
};
const __ps$tag$53 = Symbol("ProofScript.PsKernelReduceState.tag");
export const PsKernelReduceState = {
    "state": (__field0, __field1, __field2) => ({ [__ps$tag$53]: "state", environment: __field0, tasks: __field1, values: __field2 }),
};
const __ps$tag$54 = Symbol("ProofScript.PsKernelReduceResult.tag");
export const PsKernelReduceResult = {
    "outOfFuel": { [__ps$tag$54]: "outOfFuel" },
    "rejected": (__field0) => ({ [__ps$tag$54]: "rejected", error: __field0 }),
    "done": (__field0) => ({ [__ps$tag$54]: "done", value: __field0 }),
};
const __ps$tag$55 = Symbol("ProofScript.PsKernelReduceStep.tag");
export const PsKernelReduceStep = {
    "next": (__field0) => ({ [__ps$tag$55]: "next", state: __field0 }),
    "final": (__field0) => ({ [__ps$tag$55]: "final", result: __field0 }),
};
const __ps$tag$56 = Symbol("ProofScript.PsKernelConversionTask.tag");
export const PsKernelConversionTask = {
    "expr": (__field0, __field1) => ({ [__ps$tag$56]: "expr", left: __field0, right: __field1 }),
    "natural": (__field0) => ({ [__ps$tag$56]: "natural", state: __field0 }),
    "level": (__field0) => ({ [__ps$tag$56]: "level", state: __field0 }),
};
const __ps$tag$57 = Symbol("ProofScript.PsKernelConversionState.tag");
export const PsKernelConversionState = {
    "left": (__field0, __field1, __field2) => ({ [__ps$tag$57]: "left", environment: __field0, right: __field1, state: __field2 }),
    "right": (__field0, __field1) => ({ [__ps$tag$57]: "right", left: __field0, state: __field1 }),
    "compare": (__field0) => ({ [__ps$tag$57]: "compare", tasks: __field0 }),
};
const __ps$tag$58 = Symbol("ProofScript.PsKernelConversionResult.tag");
export const PsKernelConversionResult = {
    "outOfFuel": { [__ps$tag$58]: "outOfFuel" },
    "rejected": (__field0) => ({ [__ps$tag$58]: "rejected", error: __field0 }),
    "equal": { [__ps$tag$58]: "equal" },
    "different": { [__ps$tag$58]: "different" },
};
const __ps$tag$59 = Symbol("ProofScript.PsKernelConversionStep.tag");
export const PsKernelConversionStep = {
    "next": (__field0) => ({ [__ps$tag$59]: "next", state: __field0 }),
    "final": (__field0) => ({ [__ps$tag$59]: "final", result: __field0 }),
};
const __ps$tag$60 = Symbol("ProofScript.PsKernelTypeTask.tag");
export const PsKernelTypeTask = {
    "infer": (__field0, __field1) => ({ [__ps$tag$60]: "infer", context: __field0, value: __field1 }),
    "levels": (__field0) => ({ [__ps$tag$60]: "levels", pending: __field0 }),
    "levelName": (__field0, __field1, __field2) => ({ [__ps$tag$60]: "levelName", name: __field0, remaining: __field1, pending: __field2 }),
    "levelNameCompare": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$60]: "levelNameCompare", name: __field0, remaining: __field1, pending: __field2, work: __field3 }),
    "parameterArguments": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$60]: "parameterArguments", remaining: __field0, reversed: __field1, value: __field2, type: __field3 }),
    "parameters": (__field0, __field1, __field2) => ({ [__ps$tag$60]: "parameters", state: __field0, value: __field1, type: __field2 }),
    "instantiate": (__field0) => ({ [__ps$tag$60]: "instantiate", state: __field0 }),
    "bound": (__field0, __field1, __field2) => ({ [__ps$tag$60]: "bound", context: __field0, index: __field1, shift: __field2 }),
    "lookup": (__field0, __field1) => ({ [__ps$tag$60]: "lookup", levels: __field0, state: __field1 }),
    "binding": (__field0) => ({ [__ps$tag$60]: "binding", state: __field0 }),
    "reduce": (__field0) => ({ [__ps$tag$60]: "reduce", state: __field0 }),
    "reduceTop": { [__ps$tag$60]: "reduceTop" },
    "conversion": (__field0) => ({ [__ps$tag$60]: "conversion", state: __field0 }),
    "returnE": (__field0) => ({ [__ps$tag$60]: "returnE", value: __field0 }),
    "lamSort": (__field0, __field1, __field2, __field3, __field4) => ({ [__ps$tag$60]: "lamSort", context: __field0, name: __field1, type: __field2, body: __field3, binder: __field4 }),
    "lamFinish": (__field0, __field1, __field2) => ({ [__ps$tag$60]: "lamFinish", name: __field0, type: __field1, binder: __field2 }),
    "piDomain": (__field0, __field1, __field2) => ({ [__ps$tag$60]: "piDomain", context: __field0, type: __field1, body: __field2 }),
    "piFinish": (__field0) => ({ [__ps$tag$60]: "piFinish", domainLevel: __field0 }),
    "appPi": (__field0, __field1) => ({ [__ps$tag$60]: "appPi", context: __field0, arg: __field1 }),
    "appArgument": (__field0, __field1, __field2) => ({ [__ps$tag$60]: "appArgument", domain: __field0, body: __field1, arg: __field2 }),
    "letSort": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$60]: "letSort", context: __field0, type: __field1, value: __field2, body: __field3 }),
    "letValue": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$60]: "letValue", context: __field0, type: __field1, value: __field2, body: __field3 }),
    "letBody": (__field0) => ({ [__ps$tag$60]: "letBody", context: __field0 }),
    "checkSort": (__field0, __field1) => ({ [__ps$tag$60]: "checkSort", value: __field0, type: __field1 }),
    "checkValue": (__field0) => ({ [__ps$tag$60]: "checkValue", type: __field0 }),
};
const __ps$tag$61 = Symbol("ProofScript.PsKernelTypeState.tag");
export const PsKernelTypeState = {
    "state": (__field0, __field1, __field2) => ({ [__ps$tag$61]: "state", environment: __field0, tasks: __field1, values: __field2 }),
};
const __ps$tag$62 = Symbol("ProofScript.PsKernelTypeResult.tag");
export const PsKernelTypeResult = {
    "outOfFuel": { [__ps$tag$62]: "outOfFuel" },
    "rejected": (__field0) => ({ [__ps$tag$62]: "rejected", error: __field0 }),
    "done": (__field0) => ({ [__ps$tag$62]: "done", type: __field0 }),
};
const __ps$tag$63 = Symbol("ProofScript.PsKernelTypeStep.tag");
export const PsKernelTypeStep = {
    "next": (__field0) => ({ [__ps$tag$63]: "next", state: __field0 }),
    "final": (__field0) => ({ [__ps$tag$63]: "final", result: __field0 }),
};
const __ps$tag$64 = Symbol("ProofScript.PsKernelAdmissionState.tag");
export const PsKernelAdmissionState = {
    "pending": (__field0, __field1) => ({ [__ps$tag$64]: "pending", environment: __field0, entries: __field1 }),
    "duplicate": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$64]: "duplicate", environment: __field0, entry: __field1, rest: __field2, state: __field3 }),
    "checking": (__field0, __field1, __field2, __field3) => ({ [__ps$tag$64]: "checking", environment: __field0, entry: __field1, rest: __field2, state: __field3 }),
};
const __ps$tag$65 = Symbol("ProofScript.PsKernelAdmissionResult.tag");
export const PsKernelAdmissionResult = {
    "outOfFuel": { [__ps$tag$65]: "outOfFuel" },
    "rejected": (__field0) => ({ [__ps$tag$65]: "rejected", error: __field0 }),
    "admitted": (__field0) => ({ [__ps$tag$65]: "admitted", environment: __field0 }),
};
const __ps$tag$66 = Symbol("ProofScript.PsKernelAdmissionStep.tag");
export const PsKernelAdmissionStep = {
    "next": (__field0) => ({ [__ps$tag$66]: "next", state: __field0 }),
    "final": (__field0) => ({ [__ps$tag$66]: "final", result: __field0 }),
};
export function psKernelCompareTasks(fuel, __ps_eta_0) { while (true) {
    {
        const __ps$match$0 = fuel;
        switch (__ps$match$0[__ps$tag$11]) {
            case "stop": {
                {
                    const tasks = __ps_eta_0;
                    {
                        const __ps$match$0 = tasks;
                        switch (__ps$match$0[__ps$tag$8]) {
                            case "nil": {
                                return PsKernelCompareResult["equal"];
                            }
                            case "cons": {
                                const unusedHead = __ps$match$0.head;
                                const unusedTail = __ps$match$0.tail;
                                return PsKernelCompareResult["outOfFuel"];
                            }
                        }
                        throw new Error("invalid ProofScript constructor tag");
                    }
                }
            }
            case "more": {
                const remaining = __ps$match$0.remaining;
                {
                    const tasks = __ps_eta_0;
                    {
                        const __ps$match$0 = tasks;
                        switch (__ps$match$0[__ps$tag$8]) {
                            case "nil": {
                                return PsKernelCompareResult["equal"];
                            }
                            case "cons": {
                                const task = __ps$match$0.head;
                                const rest = __ps$match$0.tail;
                                {
                                    const __ps$match$0 = task;
                                    switch (__ps$match$0[__ps$tag$10]) {
                                        case "positive": {
                                            const left = __ps$match$0.left;
                                            const right = __ps$match$0.right;
                                            {
                                                const __ps$match$0 = left;
                                                switch (__ps$match$0[__ps$tag$3]) {
                                                    case "one": {
                                                        {
                                                            const __ps$match$0 = right;
                                                            switch (__ps$match$0[__ps$tag$3]) {
                                                                case "one": {
                                                                    [fuel, __ps_eta_0] = [remaining, rest];
                                                                    continue;
                                                                }
                                                                case "bit0": {
                                                                    const _wild0 = __ps$match$0.high;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "bit1": {
                                                                    const _wild0 = __ps$match$0.high;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                            }
                                                            throw new Error("invalid ProofScript constructor tag");
                                                        }
                                                    }
                                                    case "bit0": {
                                                        const leftHigh = __ps$match$0.high;
                                                        {
                                                            const __ps$match$0 = right;
                                                            switch (__ps$match$0[__ps$tag$3]) {
                                                                case "one": {
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "bit0": {
                                                                    const rightHigh = __ps$match$0.high;
                                                                    [fuel, __ps_eta_0] = [remaining, PsKernelList["cons"](PsKernelCompareTask["positive"](leftHigh, rightHigh), rest)];
                                                                    continue;
                                                                }
                                                                case "bit1": {
                                                                    const _wild0 = __ps$match$0.high;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                            }
                                                            throw new Error("invalid ProofScript constructor tag");
                                                        }
                                                    }
                                                    case "bit1": {
                                                        const leftHigh = __ps$match$0.high;
                                                        {
                                                            const __ps$match$0 = right;
                                                            switch (__ps$match$0[__ps$tag$3]) {
                                                                case "one": {
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "bit0": {
                                                                    const _wild0 = __ps$match$0.high;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "bit1": {
                                                                    const rightHigh = __ps$match$0.high;
                                                                    [fuel, __ps_eta_0] = [remaining, PsKernelList["cons"](PsKernelCompareTask["positive"](leftHigh, rightHigh), rest)];
                                                                    continue;
                                                                }
                                                            }
                                                            throw new Error("invalid ProofScript constructor tag");
                                                        }
                                                    }
                                                }
                                                throw new Error("invalid ProofScript constructor tag");
                                            }
                                        }
                                        case "natural": {
                                            const left = __ps$match$0.left;
                                            const right = __ps$match$0.right;
                                            {
                                                const __ps$match$0 = left;
                                                switch (__ps$match$0[__ps$tag$4]) {
                                                    case "zero": {
                                                        {
                                                            const __ps$match$0 = right;
                                                            switch (__ps$match$0[__ps$tag$4]) {
                                                                case "zero": {
                                                                    [fuel, __ps_eta_0] = [remaining, rest];
                                                                    continue;
                                                                }
                                                                case "positive": {
                                                                    const _wild0 = __ps$match$0.value;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                            }
                                                            throw new Error("invalid ProofScript constructor tag");
                                                        }
                                                    }
                                                    case "positive": {
                                                        const leftValue = __ps$match$0.value;
                                                        {
                                                            const __ps$match$0 = right;
                                                            switch (__ps$match$0[__ps$tag$4]) {
                                                                case "zero": {
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "positive": {
                                                                    const rightValue = __ps$match$0.value;
                                                                    [fuel, __ps_eta_0] = [remaining, PsKernelList["cons"](PsKernelCompareTask["positive"](leftValue, rightValue), rest)];
                                                                    continue;
                                                                }
                                                            }
                                                            throw new Error("invalid ProofScript constructor tag");
                                                        }
                                                    }
                                                }
                                                throw new Error("invalid ProofScript constructor tag");
                                            }
                                        }
                                        case "name": {
                                            const left = __ps$match$0.left;
                                            const right = __ps$match$0.right;
                                            {
                                                const __ps$match$0 = left;
                                                switch (__ps$match$0[__ps$tag$6]) {
                                                    case "anonymous": {
                                                        {
                                                            const __ps$match$0 = right;
                                                            switch (__ps$match$0[__ps$tag$6]) {
                                                                case "anonymous": {
                                                                    [fuel, __ps_eta_0] = [remaining, rest];
                                                                    continue;
                                                                }
                                                                case "str": {
                                                                    const _wild0 = __ps$match$0.parent;
                                                                    const _wild1 = __ps$match$0.value;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "num": {
                                                                    const _wild0 = __ps$match$0.parent;
                                                                    const _wild1 = __ps$match$0.value;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                            }
                                                            throw new Error("invalid ProofScript constructor tag");
                                                        }
                                                    }
                                                    case "str": {
                                                        const leftParent = __ps$match$0.parent;
                                                        const leftValue = __ps$match$0.value;
                                                        {
                                                            const __ps$match$0 = right;
                                                            switch (__ps$match$0[__ps$tag$6]) {
                                                                case "anonymous": {
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "str": {
                                                                    const rightParent = __ps$match$0.parent;
                                                                    const rightValue = __ps$match$0.value;
                                                                    [fuel, __ps_eta_0] = [remaining, PsKernelList["cons"](PsKernelCompareTask["name"](leftParent, rightParent), PsKernelList["cons"](PsKernelCompareTask["text"](leftValue, rightValue), rest))];
                                                                    continue;
                                                                }
                                                                case "num": {
                                                                    const _wild0 = __ps$match$0.parent;
                                                                    const _wild1 = __ps$match$0.value;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                            }
                                                            throw new Error("invalid ProofScript constructor tag");
                                                        }
                                                    }
                                                    case "num": {
                                                        const leftParent = __ps$match$0.parent;
                                                        const leftValue = __ps$match$0.value;
                                                        {
                                                            const __ps$match$0 = right;
                                                            switch (__ps$match$0[__ps$tag$6]) {
                                                                case "anonymous": {
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "str": {
                                                                    const _wild0 = __ps$match$0.parent;
                                                                    const _wild1 = __ps$match$0.value;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "num": {
                                                                    const rightParent = __ps$match$0.parent;
                                                                    const rightValue = __ps$match$0.value;
                                                                    [fuel, __ps_eta_0] = [remaining, PsKernelList["cons"](PsKernelCompareTask["name"](leftParent, rightParent), PsKernelList["cons"](PsKernelCompareTask["natural"](leftValue, rightValue), rest))];
                                                                    continue;
                                                                }
                                                            }
                                                            throw new Error("invalid ProofScript constructor tag");
                                                        }
                                                    }
                                                }
                                                throw new Error("invalid ProofScript constructor tag");
                                            }
                                        }
                                        case "text": {
                                            const left = __ps$match$0.left;
                                            const right = __ps$match$0.right;
                                            {
                                                const __ps$match$0 = left;
                                                switch (__ps$match$0[__ps$tag$5]) {
                                                    case "empty": {
                                                        {
                                                            const __ps$match$0 = right;
                                                            switch (__ps$match$0[__ps$tag$5]) {
                                                                case "empty": {
                                                                    [fuel, __ps_eta_0] = [remaining, rest];
                                                                    continue;
                                                                }
                                                                case "byte": {
                                                                    const _wild0 = __ps$match$0.value;
                                                                    const _wild1 = __ps$match$0.rest;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                            }
                                                            throw new Error("invalid ProofScript constructor tag");
                                                        }
                                                    }
                                                    case "byte": {
                                                        const leftByte = __ps$match$0.value;
                                                        const leftRest = __ps$match$0.rest;
                                                        {
                                                            const __ps$match$0 = right;
                                                            switch (__ps$match$0[__ps$tag$5]) {
                                                                case "empty": {
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "byte": {
                                                                    const rightByte = __ps$match$0.value;
                                                                    const rightRest = __ps$match$0.rest;
                                                                    [fuel, __ps_eta_0] = [remaining, PsKernelList["cons"](PsKernelCompareTask["natural"](leftByte, rightByte), PsKernelList["cons"](PsKernelCompareTask["text"](leftRest, rightRest), rest))];
                                                                    continue;
                                                                }
                                                            }
                                                            throw new Error("invalid ProofScript constructor tag");
                                                        }
                                                    }
                                                }
                                                throw new Error("invalid ProofScript constructor tag");
                                            }
                                        }
                                        case "level": {
                                            const left = __ps$match$0.left;
                                            const right = __ps$match$0.right;
                                            {
                                                const __ps$match$0 = left;
                                                switch (__ps$match$0[__ps$tag$7]) {
                                                    case "zero": {
                                                        {
                                                            const __ps$match$0 = right;
                                                            switch (__ps$match$0[__ps$tag$7]) {
                                                                case "zero": {
                                                                    [fuel, __ps_eta_0] = [remaining, rest];
                                                                    continue;
                                                                }
                                                                case "succ": {
                                                                    const _wild0 = __ps$match$0.value;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "max": {
                                                                    const _wild0 = __ps$match$0.left;
                                                                    const _wild1 = __ps$match$0.right;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "imax": {
                                                                    const _wild0 = __ps$match$0.left;
                                                                    const _wild1 = __ps$match$0.right;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "param": {
                                                                    const _wild0 = __ps$match$0.name;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                            }
                                                            throw new Error("invalid ProofScript constructor tag");
                                                        }
                                                    }
                                                    case "succ": {
                                                        const leftValue = __ps$match$0.value;
                                                        {
                                                            const __ps$match$0 = right;
                                                            switch (__ps$match$0[__ps$tag$7]) {
                                                                case "zero": {
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "succ": {
                                                                    const rightValue = __ps$match$0.value;
                                                                    [fuel, __ps_eta_0] = [remaining, PsKernelList["cons"](PsKernelCompareTask["level"](leftValue, rightValue), rest)];
                                                                    continue;
                                                                }
                                                                case "max": {
                                                                    const _wild0 = __ps$match$0.left;
                                                                    const _wild1 = __ps$match$0.right;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "imax": {
                                                                    const _wild0 = __ps$match$0.left;
                                                                    const _wild1 = __ps$match$0.right;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "param": {
                                                                    const _wild0 = __ps$match$0.name;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                            }
                                                            throw new Error("invalid ProofScript constructor tag");
                                                        }
                                                    }
                                                    case "max": {
                                                        const leftA = __ps$match$0.left;
                                                        const leftB = __ps$match$0.right;
                                                        {
                                                            const __ps$match$0 = right;
                                                            switch (__ps$match$0[__ps$tag$7]) {
                                                                case "zero": {
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "succ": {
                                                                    const _wild0 = __ps$match$0.value;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "max": {
                                                                    const rightA = __ps$match$0.left;
                                                                    const rightB = __ps$match$0.right;
                                                                    [fuel, __ps_eta_0] = [remaining, PsKernelList["cons"](PsKernelCompareTask["level"](leftA, rightA), PsKernelList["cons"](PsKernelCompareTask["level"](leftB, rightB), rest))];
                                                                    continue;
                                                                }
                                                                case "imax": {
                                                                    const _wild0 = __ps$match$0.left;
                                                                    const _wild1 = __ps$match$0.right;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "param": {
                                                                    const _wild0 = __ps$match$0.name;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                            }
                                                            throw new Error("invalid ProofScript constructor tag");
                                                        }
                                                    }
                                                    case "imax": {
                                                        const leftA = __ps$match$0.left;
                                                        const leftB = __ps$match$0.right;
                                                        {
                                                            const __ps$match$0 = right;
                                                            switch (__ps$match$0[__ps$tag$7]) {
                                                                case "zero": {
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "succ": {
                                                                    const _wild0 = __ps$match$0.value;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "max": {
                                                                    const _wild0 = __ps$match$0.left;
                                                                    const _wild1 = __ps$match$0.right;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "imax": {
                                                                    const rightA = __ps$match$0.left;
                                                                    const rightB = __ps$match$0.right;
                                                                    [fuel, __ps_eta_0] = [remaining, PsKernelList["cons"](PsKernelCompareTask["level"](leftA, rightA), PsKernelList["cons"](PsKernelCompareTask["level"](leftB, rightB), rest))];
                                                                    continue;
                                                                }
                                                                case "param": {
                                                                    const _wild0 = __ps$match$0.name;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                            }
                                                            throw new Error("invalid ProofScript constructor tag");
                                                        }
                                                    }
                                                    case "param": {
                                                        const leftName = __ps$match$0.name;
                                                        {
                                                            const __ps$match$0 = right;
                                                            switch (__ps$match$0[__ps$tag$7]) {
                                                                case "zero": {
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "succ": {
                                                                    const _wild0 = __ps$match$0.value;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "max": {
                                                                    const _wild0 = __ps$match$0.left;
                                                                    const _wild1 = __ps$match$0.right;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "imax": {
                                                                    const _wild0 = __ps$match$0.left;
                                                                    const _wild1 = __ps$match$0.right;
                                                                    return PsKernelCompareResult["different"];
                                                                }
                                                                case "param": {
                                                                    const rightName = __ps$match$0.name;
                                                                    [fuel, __ps_eta_0] = [remaining, PsKernelList["cons"](PsKernelCompareTask["name"](leftName, rightName), rest)];
                                                                    continue;
                                                                }
                                                            }
                                                            throw new Error("invalid ProofScript constructor tag");
                                                        }
                                                    }
                                                }
                                                throw new Error("invalid ProofScript constructor tag");
                                            }
                                        }
                                    }
                                    throw new Error("invalid ProofScript constructor tag");
                                }
                            }
                        }
                        throw new Error("invalid ProofScript constructor tag");
                    }
                }
            }
        }
        throw new Error("invalid ProofScript constructor tag");
    }
} }
export function psKernelPositiveSucc(value) { return __ps$run(__ps$impl$psKernelPositiveSucc(value)); }
function* __ps$impl$psKernelPositiveSucc(value) { return (yield* (function* () { const __ps$match$0 = value; switch (__ps$match$0[__ps$tag$3]) {
    case "one": return PsKernelPositive["bit0"](PsKernelPositive["one"]);
    case "bit0": {
        const high = __ps$match$0.high;
        return PsKernelPositive["bit1"](high);
    }
    case "bit1": {
        const high = __ps$match$0.high;
        return PsKernelPositive["bit0"]((yield* __ps$invoke(psKernelPositiveSucc, high)));
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelPositiveSucc, __ps$impl$psKernelPositiveSucc);
export function psKernelNaturalSucc(value) { return __ps$run(__ps$impl$psKernelNaturalSucc(value)); }
function* __ps$impl$psKernelNaturalSucc(value) { return (yield* (function* () { const __ps$match$0 = value; switch (__ps$match$0[__ps$tag$4]) {
    case "zero": return PsKernelNatural["positive"](PsKernelPositive["one"]);
    case "positive": {
        const high = __ps$match$0.value;
        return PsKernelNatural["positive"]((yield* __ps$invoke(psKernelPositiveSucc, high)));
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelNaturalSucc, __ps$impl$psKernelNaturalSucc);
export function psKernelPositivePred(value) { return __ps$run(__ps$impl$psKernelPositivePred(value)); }
function* __ps$impl$psKernelPositivePred(value) { return (yield* (function* () { const __ps$match$0 = value; switch (__ps$match$0[__ps$tag$3]) {
    case "one": return PsKernelNatural["zero"];
    case "bit0": {
        const high = __ps$match$0.high;
        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelPositivePred, high)); switch (__ps$match$0[__ps$tag$4]) {
            case "zero": return PsKernelNatural["positive"](PsKernelPositive["one"]);
            case "positive": {
                const rest = __ps$match$0.value;
                return PsKernelNatural["positive"](PsKernelPositive["bit1"](rest));
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "bit1": {
        const high = __ps$match$0.high;
        return PsKernelNatural["positive"](PsKernelPositive["bit0"](high));
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelPositivePred, __ps$impl$psKernelPositivePred);
export function psKernelNaturalPred(value) { return __ps$run(__ps$impl$psKernelNaturalPred(value)); }
function* __ps$impl$psKernelNaturalPred(value) { return (yield* (function* () { const __ps$match$0 = value; switch (__ps$match$0[__ps$tag$4]) {
    case "zero": return PsKernelNatural["zero"];
    case "positive": {
        const high = __ps$match$0.value;
        return (yield* __ps$invoke(psKernelPositivePred, high));
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelNaturalPred, __ps$impl$psKernelNaturalPred);
export function psKernelNaturalDigit(value) { while (true) {
    {
        const __ps$match$0 = value;
        switch (__ps$match$0[__ps$tag$4]) {
            case "zero": {
                return PsKernelDigit["digit"](PsKernelBit["zero"], PsKernelNatural["zero"]);
            }
            case "positive": {
                const positive = __ps$match$0.value;
                {
                    const __ps$match$0 = positive;
                    switch (__ps$match$0[__ps$tag$3]) {
                        case "one": {
                            return PsKernelDigit["digit"](PsKernelBit["one"], PsKernelNatural["zero"]);
                        }
                        case "bit0": {
                            const high = __ps$match$0.high;
                            return PsKernelDigit["digit"](PsKernelBit["zero"], PsKernelNatural["positive"](high));
                        }
                        case "bit1": {
                            const high = __ps$match$0.high;
                            return PsKernelDigit["digit"](PsKernelBit["one"], PsKernelNatural["positive"](high));
                        }
                    }
                    throw new Error("invalid ProofScript constructor tag");
                }
            }
        }
        throw new Error("invalid ProofScript constructor tag");
    }
} }
export function psKernelNaturalDoubleBit(value, bit) { while (true) {
    {
        const __ps$match$0 = value;
        switch (__ps$match$0[__ps$tag$4]) {
            case "zero": {
                {
                    const __ps$match$0 = bit;
                    switch (__ps$match$0[__ps$tag$14]) {
                        case "zero": {
                            return PsKernelNatural["zero"];
                        }
                        case "one": {
                            return PsKernelNatural["positive"](PsKernelPositive["one"]);
                        }
                    }
                    throw new Error("invalid ProofScript constructor tag");
                }
            }
            case "positive": {
                const high = __ps$match$0.value;
                {
                    const __ps$match$0 = bit;
                    switch (__ps$match$0[__ps$tag$14]) {
                        case "zero": {
                            return PsKernelNatural["positive"](PsKernelPositive["bit0"](high));
                        }
                        case "one": {
                            return PsKernelNatural["positive"](PsKernelPositive["bit1"](high));
                        }
                    }
                    throw new Error("invalid ProofScript constructor tag");
                }
            }
        }
        throw new Error("invalid ProofScript constructor tag");
    }
} }
export function psKernelNumericAddContinue(left, right, carry, bit, bits) { while (true) {
    return PsKernelNumericStep["next"](PsKernelNumericState["add"](left, right, carry, PsKernelList["cons"](bit, bits)));
} }
export function psKernelNumericAddDigits(left, right, a, b, carry, bits) { return __ps$run(__ps$impl$psKernelNumericAddDigits(left, right, a, b, carry, bits)); }
function* __ps$impl$psKernelNumericAddDigits(left, right, a, b, carry, bits) { return (yield* (function* () { const __ps$match$0 = a; switch (__ps$match$0[__ps$tag$14]) {
    case "zero": return (yield* (function* () { const __ps$match$0 = b; switch (__ps$match$0[__ps$tag$14]) {
        case "zero": return (yield* __ps$invoke(psKernelNumericAddContinue, left, right, PsKernelBit["zero"], carry, bits));
        case "one": return (yield* (function* () { const __ps$match$0 = carry; switch (__ps$match$0[__ps$tag$14]) {
            case "zero": return (yield* __ps$invoke(psKernelNumericAddContinue, left, right, PsKernelBit["zero"], PsKernelBit["one"], bits));
            case "one": return (yield* __ps$invoke(psKernelNumericAddContinue, left, right, PsKernelBit["one"], PsKernelBit["zero"], bits));
        } throw new Error("invalid ProofScript constructor tag"); })());
    } throw new Error("invalid ProofScript constructor tag"); })());
    case "one": return (yield* (function* () { const __ps$match$0 = b; switch (__ps$match$0[__ps$tag$14]) {
        case "zero": return (yield* (function* () { const __ps$match$0 = carry; switch (__ps$match$0[__ps$tag$14]) {
            case "zero": return (yield* __ps$invoke(psKernelNumericAddContinue, left, right, PsKernelBit["zero"], PsKernelBit["one"], bits));
            case "one": return (yield* __ps$invoke(psKernelNumericAddContinue, left, right, PsKernelBit["one"], PsKernelBit["zero"], bits));
        } throw new Error("invalid ProofScript constructor tag"); })());
        case "one": return (yield* __ps$invoke(psKernelNumericAddContinue, left, right, PsKernelBit["one"], carry, bits));
    } throw new Error("invalid ProofScript constructor tag"); })());
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelNumericAddDigits, __ps$impl$psKernelNumericAddDigits);
export function psKernelNumericStep(state) { return __ps$run(__ps$impl$psKernelNumericStep(state)); }
function* __ps$impl$psKernelNumericStep(state) { return (yield* (function* () { const __ps$match$0 = state; switch (__ps$match$0[__ps$tag$16]) {
    case "order": {
        const left = __ps$match$0.left;
        const right = __ps$match$0.right;
        const lower = __ps$match$0.lower;
        return (yield* (function* () { const __ps$match$0 = left; switch (__ps$match$0[__ps$tag$4]) {
            case "zero": return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$4]) {
                case "zero": return PsKernelNumericStep["ordered"](lower);
                case "positive": {
                    const _wild0 = __ps$match$0.value;
                    return PsKernelNumericStep["ordered"](PsKernelOrder["less"]);
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
            case "positive": {
                const unusedLeft = __ps$match$0.value;
                return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$4]) {
                    case "zero": return PsKernelNumericStep["ordered"](PsKernelOrder["greater"]);
                    case "positive": {
                        const unusedRight = __ps$match$0.value;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelNaturalDigit, left)); switch (__ps$match$0[__ps$tag$15]) {
                            case "digit": {
                                const a = __ps$match$0.low;
                                const leftHigh = __ps$match$0.high;
                                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelNaturalDigit, right)); switch (__ps$match$0[__ps$tag$15]) {
                                    case "digit": {
                                        const b = __ps$match$0.low;
                                        const rightHigh = __ps$match$0.high;
                                        return (yield* (function* () { {
                                            const nextOrder = (yield* (function* () { const __ps$match$0 = a; switch (__ps$match$0[__ps$tag$14]) {
                                                case "zero": return (yield* (function* () { const __ps$match$0 = b; switch (__ps$match$0[__ps$tag$14]) {
                                                    case "zero": return lower;
                                                    case "one": return PsKernelOrder["less"];
                                                } throw new Error("invalid ProofScript constructor tag"); })());
                                                case "one": return (yield* (function* () { const __ps$match$0 = b; switch (__ps$match$0[__ps$tag$14]) {
                                                    case "zero": return PsKernelOrder["greater"];
                                                    case "one": return lower;
                                                } throw new Error("invalid ProofScript constructor tag"); })());
                                            } throw new Error("invalid ProofScript constructor tag"); })());
                                            return PsKernelNumericStep["next"](PsKernelNumericState["order"](leftHigh, rightHigh, nextOrder));
                                        } })());
                                    }
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "add": {
        const left = __ps$match$0.left;
        const right = __ps$match$0.right;
        const carry = __ps$match$0.carry;
        const bits = __ps$match$0.bits;
        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelNaturalDigit, left)); switch (__ps$match$0[__ps$tag$15]) {
            case "digit": {
                const a = __ps$match$0.low;
                const leftHigh = __ps$match$0.high;
                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelNaturalDigit, right)); switch (__ps$match$0[__ps$tag$15]) {
                    case "digit": {
                        const b = __ps$match$0.low;
                        const rightHigh = __ps$match$0.high;
                        return (yield* (function* () { {
                            const allZero = (yield* (function* () { const __ps$match$0 = left; switch (__ps$match$0[__ps$tag$4]) {
                                case "zero": return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$4]) {
                                    case "zero": return (yield* (function* () { const __ps$match$0 = carry; switch (__ps$match$0[__ps$tag$14]) {
                                        case "zero": return PsKernelFlag["yes"];
                                        case "one": return PsKernelFlag["no"];
                                    } throw new Error("invalid ProofScript constructor tag"); })());
                                    case "positive": {
                                        const _wild0 = __ps$match$0.value;
                                        return PsKernelFlag["no"];
                                    }
                                } throw new Error("invalid ProofScript constructor tag"); })());
                                case "positive": {
                                    const _wild0 = __ps$match$0.value;
                                    return PsKernelFlag["no"];
                                }
                            } throw new Error("invalid ProofScript constructor tag"); })());
                            return (yield* (function* () { const __ps$match$0 = allZero; switch (__ps$match$0[__ps$tag$12]) {
                                case "no": return (yield* __ps$invoke(psKernelNumericAddDigits, leftHigh, rightHigh, a, b, carry, bits));
                                case "yes": return PsKernelNumericStep["next"](PsKernelNumericState["rebuild"](bits, PsKernelNatural["zero"]));
                            } throw new Error("invalid ProofScript constructor tag"); })());
                        } })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "rebuild": {
        const bits = __ps$match$0.bits;
        const value = __ps$match$0.value;
        return (yield* (function* () { const __ps$match$0 = bits; switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return PsKernelNumericStep["sum"](value);
            case "cons": {
                const bit = __ps$match$0.head;
                const rest = __ps$match$0.tail;
                return PsKernelNumericStep["next"](PsKernelNumericState["rebuild"](rest, (yield* __ps$invoke(psKernelNaturalDoubleBit, value, bit))));
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelNumericStep, __ps$impl$psKernelNumericStep);
export function psKernelNumericRun(fuel, __ps_eta_0) { return __ps$run(__ps$impl$psKernelNumericRun(fuel, __ps_eta_0)); }
function* __ps$impl$psKernelNumericRun(fuel, __ps_eta_0) { return (yield* (function* () { const __ps$match$0 = fuel; switch (__ps$match$0[__ps$tag$11]) {
    case "stop": return (yield* (function* () { {
        const state = __ps_eta_0;
        return PsKernelNumericResult["outOfFuel"];
    } })());
    case "more": {
        const remaining = __ps$match$0.remaining;
        return (yield* (function* () { {
            const state = __ps_eta_0;
            return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelNumericStep, state)); switch (__ps$match$0[__ps$tag$17]) {
                case "next": {
                    const next = __ps$match$0.state;
                    return (yield* (function* () { {
                        const smaller = __ps$wrap(function* (_$3) { return (yield* __ps$invoke(psKernelNumericRun, remaining, _$3)); });
                        return (yield* __ps$invoke(smaller, next));
                    } })());
                }
                case "ordered": {
                    const order = __ps$match$0.order;
                    return PsKernelNumericResult["ordered"](order);
                }
                case "sum": {
                    const value = __ps$match$0.value;
                    return PsKernelNumericResult["sum"](value);
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
        } })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelNumericRun, __ps$impl$psKernelNumericRun);
export function psKernelBindingPush(tasks, values, value) { while (true) {
    return PsKernelBindingStep["next"](PsKernelBindingState["state"](tasks, PsKernelList["cons"](value, values)));
} }
export function psKernelBindingAfterOrder(mode, depth, index, order, tasks, values) { return __ps$run(__ps$impl$psKernelBindingAfterOrder(mode, depth, index, order, tasks, values)); }
function* __ps$impl$psKernelBindingAfterOrder(mode, depth, index, order, tasks, values) { return (yield* (function* () { const __ps$match$0 = mode; switch (__ps$match$0[__ps$tag$22]) {
    case "lift": {
        const amount = __ps$match$0.amount;
        return (yield* (function* () { const __ps$match$0 = order; switch (__ps$match$0[__ps$tag$13]) {
            case "less": return (yield* __ps$invoke(psKernelBindingPush, tasks, values, PsKernelExpr["bvar"](index)));
            case "same": return PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["sumIndex"](PsKernelNumericState["add"](index, amount, PsKernelBit["zero"], PsKernelList["nil"]())), tasks), values));
            case "greater": return PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["sumIndex"](PsKernelNumericState["add"](index, amount, PsKernelBit["zero"], PsKernelList["nil"]())), tasks), values));
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "instantiate": {
        const replacement = __ps$match$0.replacement;
        return (yield* (function* () { const __ps$match$0 = order; switch (__ps$match$0[__ps$tag$13]) {
            case "less": return (yield* __ps$invoke(psKernelBindingPush, tasks, values, PsKernelExpr["bvar"](index)));
            case "same": return PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["visit"](PsKernelBindingMode["lift"](depth), PsKernelNatural["zero"], replacement), tasks), values));
            case "greater": return (yield* __ps$invoke(psKernelBindingPush, tasks, values, PsKernelExpr["bvar"]((yield* __ps$invoke(psKernelNaturalPred, index)))));
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "abstract": {
        const unusedId = __ps$match$0.id;
        return (yield* __ps$invoke(psKernelBindingPush, tasks, values, PsKernelExpr["bvar"](index)));
    }
    case "closed": return (yield* (function* () { const __ps$match$0 = order; switch (__ps$match$0[__ps$tag$13]) {
        case "less": return (yield* __ps$invoke(psKernelBindingPush, tasks, values, PsKernelExpr["bvar"](index)));
        case "same": return PsKernelBindingStep["final"](PsKernelBindingResult["invalidScope"]);
        case "greater": return PsKernelBindingStep["final"](PsKernelBindingResult["invalidScope"]);
    } throw new Error("invalid ProofScript constructor tag"); })());
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelBindingAfterOrder, __ps$impl$psKernelBindingAfterOrder);
export function psKernelBindingVisit(mode, depth, value, tasks, values) { return __ps$run(__ps$impl$psKernelBindingVisit(mode, depth, value, tasks, values)); }
function* __ps$impl$psKernelBindingVisit(mode, depth, value, tasks, values) { return (yield* (function* () { const __ps$match$0 = value; switch (__ps$match$0[__ps$tag$21]) {
    case "bvar": {
        const index = __ps$match$0.index;
        return (yield* (function* () { const __ps$match$0 = mode; switch (__ps$match$0[__ps$tag$22]) {
            case "lift": {
                const _wild0 = __ps$match$0.amount;
                return PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["orderIndex"](mode, depth, index, PsKernelNumericState["order"](index, depth, PsKernelOrder["same"])), tasks), values));
            }
            case "instantiate": {
                const _wild0 = __ps$match$0.replacement;
                return PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["orderIndex"](mode, depth, index, PsKernelNumericState["order"](index, depth, PsKernelOrder["same"])), tasks), values));
            }
            case "abstract": {
                const unusedId = __ps$match$0.id;
                return (yield* __ps$invoke(psKernelBindingPush, tasks, values, value));
            }
            case "closed": return PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["orderIndex"](mode, depth, index, PsKernelNumericState["order"](index, depth, PsKernelOrder["same"])), tasks), values));
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "fvar": {
        const id = __ps$match$0.id;
        return (yield* (function* () { const __ps$match$0 = mode; switch (__ps$match$0[__ps$tag$22]) {
            case "lift": {
                const _wild0 = __ps$match$0.amount;
                return (yield* __ps$invoke(psKernelBindingPush, tasks, values, value));
            }
            case "instantiate": {
                const _wild0 = __ps$match$0.replacement;
                return (yield* __ps$invoke(psKernelBindingPush, tasks, values, value));
            }
            case "abstract": {
                const target = __ps$match$0.id;
                return PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["orderFree"](depth, id, PsKernelNumericState["order"](id, target, PsKernelOrder["same"])), tasks), values));
            }
            case "closed": return PsKernelBindingStep["final"](PsKernelBindingResult["invalidScope"]);
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "sortE": {
        const unused = __ps$match$0.level;
        return (yield* __ps$invoke(psKernelBindingPush, tasks, values, value));
    }
    case "constE": {
        const unusedName = __ps$match$0.name;
        const unusedLevels = __ps$match$0.levels;
        return (yield* __ps$invoke(psKernelBindingPush, tasks, values, value));
    }
    case "app": {
        const fn = __ps$match$0.fn;
        const arg = __ps$match$0.arg;
        return PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["visit"](mode, depth, fn), PsKernelList["cons"](PsKernelBindingTask["visit"](mode, depth, arg), PsKernelList["cons"](PsKernelBindingTask["app"], tasks))), values));
    }
    case "lam": {
        const name = __ps$match$0.name;
        const type = __ps$match$0.type;
        const body = __ps$match$0.body;
        const binder = __ps$match$0.binder;
        return PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["visit"](mode, depth, type), PsKernelList["cons"](PsKernelBindingTask["visit"](mode, (yield* __ps$invoke(psKernelNaturalSucc, depth)), body), PsKernelList["cons"](PsKernelBindingTask["lam"](name, binder), tasks))), values));
    }
    case "forallE": {
        const name = __ps$match$0.name;
        const type = __ps$match$0.type;
        const body = __ps$match$0.body;
        const binder = __ps$match$0.binder;
        return PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["visit"](mode, depth, type), PsKernelList["cons"](PsKernelBindingTask["visit"](mode, (yield* __ps$invoke(psKernelNaturalSucc, depth)), body), PsKernelList["cons"](PsKernelBindingTask["forallE"](name, binder), tasks))), values));
    }
    case "letE": {
        const name = __ps$match$0.name;
        const type = __ps$match$0.type;
        const val = __ps$match$0.value;
        const body = __ps$match$0.body;
        return PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["visit"](mode, depth, type), PsKernelList["cons"](PsKernelBindingTask["visit"](mode, depth, val), PsKernelList["cons"](PsKernelBindingTask["visit"](mode, (yield* __ps$invoke(psKernelNaturalSucc, depth)), body), PsKernelList["cons"](PsKernelBindingTask["letE"](name), tasks)))), values));
    }
    case "lit": {
        const unused = __ps$match$0.value;
        return (yield* __ps$invoke(psKernelBindingPush, tasks, values, value));
    }
    case "proj": {
        const family = __ps$match$0.family;
        const index = __ps$match$0.index;
        const target = __ps$match$0.value;
        return PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["visit"](mode, depth, target), PsKernelList["cons"](PsKernelBindingTask["proj"](family, index), tasks)), values));
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelBindingVisit, __ps$impl$psKernelBindingVisit);
export function psKernelBindingRebuild(task, tasks, values) { return __ps$run(__ps$impl$psKernelBindingRebuild(task, tasks, values)); }
function* __ps$impl$psKernelBindingRebuild(task, tasks, values) { return (yield* (function* () { const __ps$match$0 = values; switch (__ps$match$0[__ps$tag$8]) {
    case "nil": return PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]);
    case "cons": {
        const top = __ps$match$0.head;
        const rest = __ps$match$0.tail;
        return (yield* (function* () { const __ps$match$0 = task; switch (__ps$match$0[__ps$tag$23]) {
            case "visit": {
                const _wild0 = __ps$match$0.mode;
                const _wild1 = __ps$match$0.depth;
                const _wild2 = __ps$match$0.value;
                return PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]);
            }
            case "orderIndex": {
                const _wild0 = __ps$match$0.mode;
                const _wild1 = __ps$match$0.depth;
                const _wild2 = __ps$match$0.index;
                const _wild3 = __ps$match$0.state;
                return PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]);
            }
            case "orderFree": {
                const _wild0 = __ps$match$0.depth;
                const _wild1 = __ps$match$0.id;
                const _wild2 = __ps$match$0.state;
                return PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]);
            }
            case "sumIndex": {
                const _wild0 = __ps$match$0.state;
                return PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]);
            }
            case "app": return (yield* (function* () { const __ps$match$0 = rest; switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]);
                case "cons": {
                    const fn = __ps$match$0.head;
                    const tail = __ps$match$0.tail;
                    return (yield* __ps$invoke(psKernelBindingPush, tasks, tail, PsKernelExpr["app"](fn, top)));
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
            case "lam": {
                const name = __ps$match$0.name;
                const binder = __ps$match$0.binder;
                return (yield* (function* () { const __ps$match$0 = rest; switch (__ps$match$0[__ps$tag$8]) {
                    case "nil": return PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]);
                    case "cons": {
                        const type = __ps$match$0.head;
                        const tail = __ps$match$0.tail;
                        return (yield* __ps$invoke(psKernelBindingPush, tasks, tail, PsKernelExpr["lam"](name, type, top, binder)));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "forallE": {
                const name = __ps$match$0.name;
                const binder = __ps$match$0.binder;
                return (yield* (function* () { const __ps$match$0 = rest; switch (__ps$match$0[__ps$tag$8]) {
                    case "nil": return PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]);
                    case "cons": {
                        const type = __ps$match$0.head;
                        const tail = __ps$match$0.tail;
                        return (yield* __ps$invoke(psKernelBindingPush, tasks, tail, PsKernelExpr["forallE"](name, type, top, binder)));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "letE": {
                const name = __ps$match$0.name;
                return (yield* (function* () { const __ps$match$0 = rest; switch (__ps$match$0[__ps$tag$8]) {
                    case "nil": return PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]);
                    case "cons": {
                        const val = __ps$match$0.head;
                        const tail = __ps$match$0.tail;
                        return (yield* (function* () { const __ps$match$0 = tail; switch (__ps$match$0[__ps$tag$8]) {
                            case "nil": return PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]);
                            case "cons": {
                                const type = __ps$match$0.head;
                                const remaining = __ps$match$0.tail;
                                return (yield* __ps$invoke(psKernelBindingPush, tasks, remaining, PsKernelExpr["letE"](name, type, val, top)));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "proj": {
                const family = __ps$match$0.family;
                const index = __ps$match$0.index;
                return (yield* __ps$invoke(psKernelBindingPush, tasks, rest, PsKernelExpr["proj"](family, index, top)));
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelBindingRebuild, __ps$impl$psKernelBindingRebuild);
export function psKernelBindingFinish(values) { while (true) {
    {
        const __ps$match$0 = values;
        switch (__ps$match$0[__ps$tag$8]) {
            case "nil": {
                return PsKernelBindingResult["invalidState"];
            }
            case "cons": {
                const value = __ps$match$0.head;
                const rest = __ps$match$0.tail;
                {
                    const __ps$match$0 = rest;
                    switch (__ps$match$0[__ps$tag$8]) {
                        case "nil": {
                            return PsKernelBindingResult["done"](value);
                        }
                        case "cons": {
                            const _wild0 = __ps$match$0.head;
                            const _wild1 = __ps$match$0.tail;
                            return PsKernelBindingResult["invalidState"];
                        }
                    }
                    throw new Error("invalid ProofScript constructor tag");
                }
            }
        }
        throw new Error("invalid ProofScript constructor tag");
    }
} }
export function psKernelBindingStep(state) { return __ps$run(__ps$impl$psKernelBindingStep(state)); }
function* __ps$impl$psKernelBindingStep(state) { return (yield* (function* () { const __ps$match$0 = state; switch (__ps$match$0[__ps$tag$24]) {
    case "state": {
        const tasks = __ps$match$0.tasks;
        const values = __ps$match$0.values;
        return (yield* (function* () { const __ps$match$0 = tasks; switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return PsKernelBindingStep["final"]((yield* __ps$invoke(psKernelBindingFinish, values)));
            case "cons": {
                const task = __ps$match$0.head;
                const rest = __ps$match$0.tail;
                return (yield* (function* () { const __ps$match$0 = task; switch (__ps$match$0[__ps$tag$23]) {
                    case "visit": {
                        const mode = __ps$match$0.mode;
                        const depth = __ps$match$0.depth;
                        const value = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelBindingVisit, mode, depth, value, rest, values));
                    }
                    case "orderIndex": {
                        const mode = __ps$match$0.mode;
                        const depth = __ps$match$0.depth;
                        const index = __ps$match$0.index;
                        const numeric = __ps$match$0.state;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelNumericStep, numeric)); switch (__ps$match$0[__ps$tag$17]) {
                            case "next": {
                                const next = __ps$match$0.state;
                                return PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["orderIndex"](mode, depth, index, next), rest), values));
                            }
                            case "ordered": {
                                const order = __ps$match$0.order;
                                return (yield* __ps$invoke(psKernelBindingAfterOrder, mode, depth, index, order, rest, values));
                            }
                            case "sum": {
                                const _wild0 = __ps$match$0.value;
                                return PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]);
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "orderFree": {
                        const depth = __ps$match$0.depth;
                        const id = __ps$match$0.id;
                        const numeric = __ps$match$0.state;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelNumericStep, numeric)); switch (__ps$match$0[__ps$tag$17]) {
                            case "next": {
                                const next = __ps$match$0.state;
                                return PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["orderFree"](depth, id, next), rest), values));
                            }
                            case "ordered": {
                                const order = __ps$match$0.order;
                                return (yield* (function* () { const __ps$match$0 = order; switch (__ps$match$0[__ps$tag$13]) {
                                    case "less": return (yield* __ps$invoke(psKernelBindingPush, rest, values, PsKernelExpr["fvar"](id)));
                                    case "same": return (yield* __ps$invoke(psKernelBindingPush, rest, values, PsKernelExpr["bvar"](depth)));
                                    case "greater": return (yield* __ps$invoke(psKernelBindingPush, rest, values, PsKernelExpr["fvar"](id)));
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                            case "sum": {
                                const _wild0 = __ps$match$0.value;
                                return PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]);
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "sumIndex": {
                        const numeric = __ps$match$0.state;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelNumericStep, numeric)); switch (__ps$match$0[__ps$tag$17]) {
                            case "next": {
                                const next = __ps$match$0.state;
                                return PsKernelBindingStep["next"](PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["sumIndex"](next), rest), values));
                            }
                            case "ordered": {
                                const _wild0 = __ps$match$0.order;
                                return PsKernelBindingStep["final"](PsKernelBindingResult["invalidState"]);
                            }
                            case "sum": {
                                const index = __ps$match$0.value;
                                return (yield* __ps$invoke(psKernelBindingPush, rest, values, PsKernelExpr["bvar"](index)));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "app": return (yield* __ps$invoke(psKernelBindingRebuild, task, rest, values));
                    case "lam": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.binder;
                        return (yield* __ps$invoke(psKernelBindingRebuild, task, rest, values));
                    }
                    case "forallE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.binder;
                        return (yield* __ps$invoke(psKernelBindingRebuild, task, rest, values));
                    }
                    case "letE": {
                        const _wild0 = __ps$match$0.name;
                        return (yield* __ps$invoke(psKernelBindingRebuild, task, rest, values));
                    }
                    case "proj": {
                        const _wild0 = __ps$match$0.family;
                        const _wild1 = __ps$match$0.index;
                        return (yield* __ps$invoke(psKernelBindingRebuild, task, rest, values));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelBindingStep, __ps$impl$psKernelBindingStep);
export function psKernelBindingStart(mode, depth, value) { while (true) {
    return PsKernelBindingState["state"](PsKernelList["cons"](PsKernelBindingTask["visit"](mode, depth, value), PsKernelList["nil"]()), PsKernelList["nil"]());
} }
export function psKernelBindingRun(fuel, __ps_eta_0) { return __ps$run(__ps$impl$psKernelBindingRun(fuel, __ps_eta_0)); }
function* __ps$impl$psKernelBindingRun(fuel, __ps_eta_0) { return (yield* (function* () { const __ps$match$0 = fuel; switch (__ps$match$0[__ps$tag$11]) {
    case "stop": return (yield* (function* () { {
        const state = __ps_eta_0;
        return (yield* (function* () { const __ps$match$0 = state; switch (__ps$match$0[__ps$tag$24]) {
            case "state": {
                const tasks = __ps$match$0.tasks;
                const values = __ps$match$0.values;
                return (yield* (function* () { const __ps$match$0 = tasks; switch (__ps$match$0[__ps$tag$8]) {
                    case "nil": return (yield* __ps$invoke(psKernelBindingFinish, values));
                    case "cons": {
                        const _wild0 = __ps$match$0.head;
                        const _wild1 = __ps$match$0.tail;
                        return PsKernelBindingResult["outOfFuel"];
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    } })());
    case "more": {
        const remaining = __ps$match$0.remaining;
        return (yield* (function* () { {
            const state = __ps_eta_0;
            return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelBindingStep, state)); switch (__ps$match$0[__ps$tag$26]) {
                case "next": {
                    const next = __ps$match$0.state;
                    return (yield* (function* () { {
                        const smaller = __ps$wrap(function* (_$3) { return (yield* __ps$invoke(psKernelBindingRun, remaining, _$3)); });
                        return (yield* __ps$invoke(smaller, next));
                    } })());
                }
                case "final": {
                    const result = __ps$match$0.result;
                    return result;
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
        } })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelBindingRun, __ps$impl$psKernelBindingRun);
export function psKernelOrderStep(tasks) { return __ps$run(__ps$impl$psKernelOrderStep(tasks)); }
function* __ps$impl$psKernelOrderStep(tasks) { return (yield* (function* () { const __ps$match$0 = tasks; switch (__ps$match$0[__ps$tag$8]) {
    case "nil": return PsKernelOrderStep["done"](PsKernelOrder["same"]);
    case "cons": {
        const task = __ps$match$0.head;
        const rest = __ps$match$0.tail;
        return (yield* (function* () { const __ps$match$0 = task; switch (__ps$match$0[__ps$tag$27]) {
            case "name": {
                const left = __ps$match$0.left;
                const right = __ps$match$0.right;
                return (yield* (function* () { const __ps$match$0 = left; switch (__ps$match$0[__ps$tag$6]) {
                    case "anonymous": return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$6]) {
                        case "anonymous": return PsKernelOrderStep["next"](rest);
                        case "str": {
                            const rParent = __ps$match$0.parent;
                            const rValue = __ps$match$0.value;
                            return PsKernelOrderStep["done"](PsKernelOrder["less"]);
                        }
                        case "num": {
                            const rParent = __ps$match$0.parent;
                            const rValue = __ps$match$0.value;
                            return PsKernelOrderStep["done"](PsKernelOrder["less"]);
                        }
                    } throw new Error("invalid ProofScript constructor tag"); })());
                    case "str": {
                        const lParent = __ps$match$0.parent;
                        const lValue = __ps$match$0.value;
                        return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$6]) {
                            case "anonymous": return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                            case "str": {
                                const rParent = __ps$match$0.parent;
                                const rValue = __ps$match$0.value;
                                return PsKernelOrderStep["next"](PsKernelList["cons"](PsKernelOrderTask["name"](lParent, rParent), PsKernelList["cons"](PsKernelOrderTask["text"](lValue, rValue), rest)));
                            }
                            case "num": {
                                const rParent = __ps$match$0.parent;
                                const rValue = __ps$match$0.value;
                                return PsKernelOrderStep["done"](PsKernelOrder["less"]);
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "num": {
                        const lParent = __ps$match$0.parent;
                        const lValue = __ps$match$0.value;
                        return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$6]) {
                            case "anonymous": return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                            case "str": {
                                const rParent = __ps$match$0.parent;
                                const rValue = __ps$match$0.value;
                                return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                            }
                            case "num": {
                                const rParent = __ps$match$0.parent;
                                const rValue = __ps$match$0.value;
                                return PsKernelOrderStep["next"](PsKernelList["cons"](PsKernelOrderTask["name"](lParent, rParent), PsKernelList["cons"](PsKernelOrderTask["number"](PsKernelNumericState["order"](lValue, rValue, PsKernelOrder["same"])), rest)));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "text": {
                const left = __ps$match$0.left;
                const right = __ps$match$0.right;
                return (yield* (function* () { const __ps$match$0 = left; switch (__ps$match$0[__ps$tag$5]) {
                    case "empty": return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$5]) {
                        case "empty": return PsKernelOrderStep["next"](rest);
                        case "byte": {
                            const rValue = __ps$match$0.value;
                            const rRest = __ps$match$0.rest;
                            return PsKernelOrderStep["done"](PsKernelOrder["less"]);
                        }
                    } throw new Error("invalid ProofScript constructor tag"); })());
                    case "byte": {
                        const lValue = __ps$match$0.value;
                        const lRest = __ps$match$0.rest;
                        return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$5]) {
                            case "empty": return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                            case "byte": {
                                const rValue = __ps$match$0.value;
                                const rRest = __ps$match$0.rest;
                                return PsKernelOrderStep["next"](PsKernelList["cons"](PsKernelOrderTask["number"](PsKernelNumericState["order"](lValue, rValue, PsKernelOrder["same"])), PsKernelList["cons"](PsKernelOrderTask["text"](lRest, rRest), rest)));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "level": {
                const left = __ps$match$0.left;
                const right = __ps$match$0.right;
                return (yield* (function* () { const __ps$match$0 = left; switch (__ps$match$0[__ps$tag$7]) {
                    case "zero": return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$7]) {
                        case "zero": return PsKernelOrderStep["next"](rest);
                        case "succ": {
                            const rValue = __ps$match$0.value;
                            return PsKernelOrderStep["done"](PsKernelOrder["less"]);
                        }
                        case "max": {
                            const rLeft = __ps$match$0.left;
                            const rRight = __ps$match$0.right;
                            return PsKernelOrderStep["done"](PsKernelOrder["less"]);
                        }
                        case "imax": {
                            const rLeft = __ps$match$0.left;
                            const rRight = __ps$match$0.right;
                            return PsKernelOrderStep["done"](PsKernelOrder["less"]);
                        }
                        case "param": {
                            const rName = __ps$match$0.name;
                            return PsKernelOrderStep["done"](PsKernelOrder["less"]);
                        }
                    } throw new Error("invalid ProofScript constructor tag"); })());
                    case "succ": {
                        const lValue = __ps$match$0.value;
                        return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$7]) {
                            case "zero": return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                            case "succ": {
                                const rValue = __ps$match$0.value;
                                return PsKernelOrderStep["next"](PsKernelList["cons"](PsKernelOrderTask["level"](lValue, rValue), rest));
                            }
                            case "max": {
                                const rLeft = __ps$match$0.left;
                                const rRight = __ps$match$0.right;
                                return PsKernelOrderStep["done"](PsKernelOrder["less"]);
                            }
                            case "imax": {
                                const rLeft = __ps$match$0.left;
                                const rRight = __ps$match$0.right;
                                return PsKernelOrderStep["done"](PsKernelOrder["less"]);
                            }
                            case "param": {
                                const rName = __ps$match$0.name;
                                return PsKernelOrderStep["done"](PsKernelOrder["less"]);
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "max": {
                        const lLeft = __ps$match$0.left;
                        const lRight = __ps$match$0.right;
                        return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$7]) {
                            case "zero": return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                            case "succ": {
                                const rValue = __ps$match$0.value;
                                return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                            }
                            case "max": {
                                const rLeft = __ps$match$0.left;
                                const rRight = __ps$match$0.right;
                                return PsKernelOrderStep["next"](PsKernelList["cons"](PsKernelOrderTask["level"](lLeft, rLeft), PsKernelList["cons"](PsKernelOrderTask["level"](lRight, rRight), rest)));
                            }
                            case "imax": {
                                const rLeft = __ps$match$0.left;
                                const rRight = __ps$match$0.right;
                                return PsKernelOrderStep["done"](PsKernelOrder["less"]);
                            }
                            case "param": {
                                const rName = __ps$match$0.name;
                                return PsKernelOrderStep["done"](PsKernelOrder["less"]);
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "imax": {
                        const lLeft = __ps$match$0.left;
                        const lRight = __ps$match$0.right;
                        return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$7]) {
                            case "zero": return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                            case "succ": {
                                const rValue = __ps$match$0.value;
                                return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                            }
                            case "max": {
                                const rLeft = __ps$match$0.left;
                                const rRight = __ps$match$0.right;
                                return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                            }
                            case "imax": {
                                const rLeft = __ps$match$0.left;
                                const rRight = __ps$match$0.right;
                                return PsKernelOrderStep["next"](PsKernelList["cons"](PsKernelOrderTask["level"](lLeft, rLeft), PsKernelList["cons"](PsKernelOrderTask["level"](lRight, rRight), rest)));
                            }
                            case "param": {
                                const rName = __ps$match$0.name;
                                return PsKernelOrderStep["done"](PsKernelOrder["less"]);
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "param": {
                        const lName = __ps$match$0.name;
                        return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$7]) {
                            case "zero": return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                            case "succ": {
                                const rValue = __ps$match$0.value;
                                return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                            }
                            case "max": {
                                const rLeft = __ps$match$0.left;
                                const rRight = __ps$match$0.right;
                                return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                            }
                            case "imax": {
                                const rLeft = __ps$match$0.left;
                                const rRight = __ps$match$0.right;
                                return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                            }
                            case "param": {
                                const rName = __ps$match$0.name;
                                return PsKernelOrderStep["next"](PsKernelList["cons"](PsKernelOrderTask["name"](lName, rName), rest));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "number": {
                const state = __ps$match$0.state;
                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelNumericStep, state)); switch (__ps$match$0[__ps$tag$17]) {
                    case "next": {
                        const next = __ps$match$0.state;
                        return PsKernelOrderStep["next"](PsKernelList["cons"](PsKernelOrderTask["number"](next), rest));
                    }
                    case "ordered": {
                        const order = __ps$match$0.order;
                        return (yield* (function* () { const __ps$match$0 = order; switch (__ps$match$0[__ps$tag$13]) {
                            case "less": return PsKernelOrderStep["done"](PsKernelOrder["less"]);
                            case "same": return PsKernelOrderStep["next"](rest);
                            case "greater": return PsKernelOrderStep["done"](PsKernelOrder["greater"]);
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "sum": {
                        const _wild0 = __ps$match$0.value;
                        return PsKernelOrderStep["invalidState"];
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelOrderStep, __ps$impl$psKernelOrderStep);
export function psKernelLevelOffset(value) { return __ps$run(__ps$impl$psKernelLevelOffset(value)); }
function* __ps$impl$psKernelLevelOffset(value) { return (yield* (function* () { const __ps$match$0 = value; switch (__ps$match$0[__ps$tag$7]) {
    case "zero": return PsKernelLevelOffset["parts"](PsKernelLevel["zero"], PsKernelNatural["zero"]);
    case "succ": {
        const child = __ps$match$0.value;
        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, child)); switch (__ps$match$0[__ps$tag$29]) {
            case "parts": {
                const base = __ps$match$0.base;
                const count = __ps$match$0.count;
                return PsKernelLevelOffset["parts"](base, (yield* __ps$invoke(psKernelNaturalSucc, count)));
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "max": {
        const left = __ps$match$0.left;
        const right = __ps$match$0.right;
        return PsKernelLevelOffset["parts"](PsKernelLevel["max"](left, right), PsKernelNatural["zero"]);
    }
    case "imax": {
        const left = __ps$match$0.left;
        const right = __ps$match$0.right;
        return PsKernelLevelOffset["parts"](PsKernelLevel["imax"](left, right), PsKernelNatural["zero"]);
    }
    case "param": {
        const name = __ps$match$0.name;
        return PsKernelLevelOffset["parts"](PsKernelLevel["param"](name), PsKernelNatural["zero"]);
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelLevelOffset, __ps$impl$psKernelLevelOffset);
export function psKernelLevelNeverZero(value) { return __ps$run(__ps$impl$psKernelLevelNeverZero(value)); }
function* __ps$impl$psKernelLevelNeverZero(value) { return (yield* (function* () { const __ps$match$0 = value; switch (__ps$match$0[__ps$tag$7]) {
    case "zero": return PsKernelFlag["no"];
    case "succ": {
        const child = __ps$match$0.value;
        return PsKernelFlag["yes"];
    }
    case "max": {
        const left = __ps$match$0.left;
        const right = __ps$match$0.right;
        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelNeverZero, left)); switch (__ps$match$0[__ps$tag$12]) {
            case "no": return (yield* __ps$invoke(psKernelLevelNeverZero, right));
            case "yes": return PsKernelFlag["yes"];
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "imax": {
        const left = __ps$match$0.left;
        const right = __ps$match$0.right;
        return (yield* __ps$invoke(psKernelLevelNeverZero, right));
    }
    case "param": {
        const name = __ps$match$0.name;
        return PsKernelFlag["no"];
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelLevelNeverZero, __ps$impl$psKernelLevelNeverZero);
export function psKernelLevelAlwaysZero(value) { return __ps$run(__ps$impl$psKernelLevelAlwaysZero(value)); }
function* __ps$impl$psKernelLevelAlwaysZero(value) { return (yield* (function* () { const __ps$match$0 = value; switch (__ps$match$0[__ps$tag$7]) {
    case "zero": return PsKernelFlag["yes"];
    case "succ": {
        const child = __ps$match$0.value;
        return PsKernelFlag["no"];
    }
    case "max": {
        const left = __ps$match$0.left;
        const right = __ps$match$0.right;
        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelAlwaysZero, left)); switch (__ps$match$0[__ps$tag$12]) {
            case "no": return PsKernelFlag["no"];
            case "yes": return (yield* __ps$invoke(psKernelLevelAlwaysZero, right));
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "imax": {
        const left = __ps$match$0.left;
        const right = __ps$match$0.right;
        return (yield* __ps$invoke(psKernelLevelAlwaysZero, right));
    }
    case "param": {
        const name = __ps$match$0.name;
        return PsKernelFlag["no"];
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelLevelAlwaysZero, __ps$impl$psKernelLevelAlwaysZero);
export function psKernelUniverseSchedule(task, tasks, values) { while (true) {
    return PsKernelUniverseStep["next"](PsKernelUniverseState["state"](PsKernelList["cons"](task, tasks), values));
} }
export function psKernelUniversePush(value, tasks, values) { while (true) {
    return PsKernelUniverseStep["next"](PsKernelUniverseState["state"](tasks, PsKernelList["cons"](value, values)));
} }
export function psKernelUniverseSmartMax(left, right, offset, tasks, values) { return __ps$run(__ps$impl$psKernelUniverseSmartMax(left, right, offset, tasks, values)); }
function* __ps$impl$psKernelUniverseSmartMax(left, right, offset, tasks, values) { return (yield* (function* () { const __ps$match$0 = left; switch (__ps$match$0[__ps$tag$7]) {
    case "zero": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](right, offset), tasks, values));
    case "succ": {
        const _wild0 = __ps$match$0.value;
        return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$7]) {
            case "zero": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](left, offset), tasks, values));
            case "succ": {
                const _wild0$7 = __ps$match$0.value;
                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, left)); switch (__ps$match$0[__ps$tag$29]) {
                    case "parts": {
                        const leftBase = __ps$match$0.base;
                        const leftCount = __ps$match$0.count;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, right)); switch (__ps$match$0[__ps$tag$29]) {
                            case "parts": {
                                const rightBase = __ps$match$0.base;
                                const rightCount = __ps$match$0.count;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "max": {
                const _wild0$7 = __ps$match$0.left;
                const _wild1 = __ps$match$0.right;
                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, left)); switch (__ps$match$0[__ps$tag$29]) {
                    case "parts": {
                        const leftBase = __ps$match$0.base;
                        const leftCount = __ps$match$0.count;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, right)); switch (__ps$match$0[__ps$tag$29]) {
                            case "parts": {
                                const rightBase = __ps$match$0.base;
                                const rightCount = __ps$match$0.count;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "imax": {
                const _wild0$7 = __ps$match$0.left;
                const _wild1 = __ps$match$0.right;
                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, left)); switch (__ps$match$0[__ps$tag$29]) {
                    case "parts": {
                        const leftBase = __ps$match$0.base;
                        const leftCount = __ps$match$0.count;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, right)); switch (__ps$match$0[__ps$tag$29]) {
                            case "parts": {
                                const rightBase = __ps$match$0.base;
                                const rightCount = __ps$match$0.count;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "param": {
                const _wild0$7 = __ps$match$0.name;
                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, left)); switch (__ps$match$0[__ps$tag$29]) {
                    case "parts": {
                        const leftBase = __ps$match$0.base;
                        const leftCount = __ps$match$0.count;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, right)); switch (__ps$match$0[__ps$tag$29]) {
                            case "parts": {
                                const rightBase = __ps$match$0.base;
                                const rightCount = __ps$match$0.count;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "max": {
        const _wild0 = __ps$match$0.left;
        const _wild1 = __ps$match$0.right;
        return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$7]) {
            case "zero": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](left, offset), tasks, values));
            case "succ": {
                const _wild0$9 = __ps$match$0.value;
                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, left)); switch (__ps$match$0[__ps$tag$29]) {
                    case "parts": {
                        const leftBase = __ps$match$0.base;
                        const leftCount = __ps$match$0.count;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, right)); switch (__ps$match$0[__ps$tag$29]) {
                            case "parts": {
                                const rightBase = __ps$match$0.base;
                                const rightCount = __ps$match$0.count;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "max": {
                const _wild0$9 = __ps$match$0.left;
                const _wild1$10 = __ps$match$0.right;
                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, left)); switch (__ps$match$0[__ps$tag$29]) {
                    case "parts": {
                        const leftBase = __ps$match$0.base;
                        const leftCount = __ps$match$0.count;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, right)); switch (__ps$match$0[__ps$tag$29]) {
                            case "parts": {
                                const rightBase = __ps$match$0.base;
                                const rightCount = __ps$match$0.count;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "imax": {
                const _wild0$9 = __ps$match$0.left;
                const _wild1$10 = __ps$match$0.right;
                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, left)); switch (__ps$match$0[__ps$tag$29]) {
                    case "parts": {
                        const leftBase = __ps$match$0.base;
                        const leftCount = __ps$match$0.count;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, right)); switch (__ps$match$0[__ps$tag$29]) {
                            case "parts": {
                                const rightBase = __ps$match$0.base;
                                const rightCount = __ps$match$0.count;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "param": {
                const _wild0$9 = __ps$match$0.name;
                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, left)); switch (__ps$match$0[__ps$tag$29]) {
                    case "parts": {
                        const leftBase = __ps$match$0.base;
                        const leftCount = __ps$match$0.count;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, right)); switch (__ps$match$0[__ps$tag$29]) {
                            case "parts": {
                                const rightBase = __ps$match$0.base;
                                const rightCount = __ps$match$0.count;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "imax": {
        const _wild0 = __ps$match$0.left;
        const _wild1 = __ps$match$0.right;
        return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$7]) {
            case "zero": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](left, offset), tasks, values));
            case "succ": {
                const _wild0$9 = __ps$match$0.value;
                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, left)); switch (__ps$match$0[__ps$tag$29]) {
                    case "parts": {
                        const leftBase = __ps$match$0.base;
                        const leftCount = __ps$match$0.count;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, right)); switch (__ps$match$0[__ps$tag$29]) {
                            case "parts": {
                                const rightBase = __ps$match$0.base;
                                const rightCount = __ps$match$0.count;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "max": {
                const _wild0$9 = __ps$match$0.left;
                const _wild1$10 = __ps$match$0.right;
                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, left)); switch (__ps$match$0[__ps$tag$29]) {
                    case "parts": {
                        const leftBase = __ps$match$0.base;
                        const leftCount = __ps$match$0.count;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, right)); switch (__ps$match$0[__ps$tag$29]) {
                            case "parts": {
                                const rightBase = __ps$match$0.base;
                                const rightCount = __ps$match$0.count;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "imax": {
                const _wild0$9 = __ps$match$0.left;
                const _wild1$10 = __ps$match$0.right;
                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, left)); switch (__ps$match$0[__ps$tag$29]) {
                    case "parts": {
                        const leftBase = __ps$match$0.base;
                        const leftCount = __ps$match$0.count;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, right)); switch (__ps$match$0[__ps$tag$29]) {
                            case "parts": {
                                const rightBase = __ps$match$0.base;
                                const rightCount = __ps$match$0.count;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "param": {
                const _wild0$9 = __ps$match$0.name;
                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, left)); switch (__ps$match$0[__ps$tag$29]) {
                    case "parts": {
                        const leftBase = __ps$match$0.base;
                        const leftCount = __ps$match$0.count;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, right)); switch (__ps$match$0[__ps$tag$29]) {
                            case "parts": {
                                const rightBase = __ps$match$0.base;
                                const rightCount = __ps$match$0.count;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "param": {
        const _wild0 = __ps$match$0.name;
        return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$7]) {
            case "zero": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](left, offset), tasks, values));
            case "succ": {
                const _wild0$6 = __ps$match$0.value;
                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, left)); switch (__ps$match$0[__ps$tag$29]) {
                    case "parts": {
                        const leftBase = __ps$match$0.base;
                        const leftCount = __ps$match$0.count;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, right)); switch (__ps$match$0[__ps$tag$29]) {
                            case "parts": {
                                const rightBase = __ps$match$0.base;
                                const rightCount = __ps$match$0.count;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "max": {
                const _wild0$6 = __ps$match$0.left;
                const _wild1 = __ps$match$0.right;
                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, left)); switch (__ps$match$0[__ps$tag$29]) {
                    case "parts": {
                        const leftBase = __ps$match$0.base;
                        const leftCount = __ps$match$0.count;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, right)); switch (__ps$match$0[__ps$tag$29]) {
                            case "parts": {
                                const rightBase = __ps$match$0.base;
                                const rightCount = __ps$match$0.count;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "imax": {
                const _wild0$6 = __ps$match$0.left;
                const _wild1 = __ps$match$0.right;
                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, left)); switch (__ps$match$0[__ps$tag$29]) {
                    case "parts": {
                        const leftBase = __ps$match$0.base;
                        const leftCount = __ps$match$0.count;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, right)); switch (__ps$match$0[__ps$tag$29]) {
                            case "parts": {
                                const rightBase = __ps$match$0.base;
                                const rightCount = __ps$match$0.count;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "param": {
                const _wild0$6 = __ps$match$0.name;
                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, left)); switch (__ps$match$0[__ps$tag$29]) {
                    case "parts": {
                        const leftBase = __ps$match$0.base;
                        const leftCount = __ps$match$0.count;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, right)); switch (__ps$match$0[__ps$tag$29]) {
                            case "parts": {
                                const rightBase = __ps$match$0.base;
                                const rightCount = __ps$match$0.count;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["maxBases"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](leftBase, rightBase), PsKernelList["nil"]())), tasks, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelUniverseSmartMax, __ps$impl$psKernelUniverseSmartMax);
export function psKernelUniverseIMax(left, right, offset, tasks, values) { return __ps$run(__ps$impl$psKernelUniverseIMax(left, right, offset, tasks, values)); }
function* __ps$impl$psKernelUniverseIMax(left, right, offset, tasks, values) { return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelNeverZero, right)); switch (__ps$match$0[__ps$tag$12]) {
    case "no": return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$7]) {
        case "zero": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](right, offset), tasks, values));
        case "succ": {
            const _wild0 = __ps$match$0.value;
            return (yield* (function* () { {
                const smallLeft = (yield* (function* () { const __ps$match$0 = left; switch (__ps$match$0[__ps$tag$7]) {
                    case "zero": return PsKernelFlag["yes"];
                    case "succ": {
                        const child = __ps$match$0.value;
                        return (yield* (function* () { const __ps$match$0 = child; switch (__ps$match$0[__ps$tag$7]) {
                            case "zero": return PsKernelFlag["yes"];
                            case "succ": {
                                const _wild0$9 = __ps$match$0.value;
                                return PsKernelFlag["no"];
                            }
                            case "max": {
                                const _wild0$9 = __ps$match$0.left;
                                const _wild1 = __ps$match$0.right;
                                return PsKernelFlag["no"];
                            }
                            case "imax": {
                                const _wild0$9 = __ps$match$0.left;
                                const _wild1 = __ps$match$0.right;
                                return PsKernelFlag["no"];
                            }
                            case "param": {
                                const _wild0$9 = __ps$match$0.name;
                                return PsKernelFlag["no"];
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "max": {
                        const _wild0$7 = __ps$match$0.left;
                        const _wild1 = __ps$match$0.right;
                        return PsKernelFlag["no"];
                    }
                    case "imax": {
                        const _wild0$7 = __ps$match$0.left;
                        const _wild1 = __ps$match$0.right;
                        return PsKernelFlag["no"];
                    }
                    case "param": {
                        const _wild0$7 = __ps$match$0.name;
                        return PsKernelFlag["no"];
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
                return (yield* (function* () { const __ps$match$0 = smallLeft; switch (__ps$match$0[__ps$tag$12]) {
                    case "no": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["imaxCompare"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](left, right), PsKernelList["nil"]())), tasks, values));
                    case "yes": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](right, offset), tasks, values));
                } throw new Error("invalid ProofScript constructor tag"); })());
            } })());
        }
        case "max": {
            const _wild0 = __ps$match$0.left;
            const _wild1 = __ps$match$0.right;
            return (yield* (function* () { {
                const smallLeft = (yield* (function* () { const __ps$match$0 = left; switch (__ps$match$0[__ps$tag$7]) {
                    case "zero": return PsKernelFlag["yes"];
                    case "succ": {
                        const child = __ps$match$0.value;
                        return (yield* (function* () { const __ps$match$0 = child; switch (__ps$match$0[__ps$tag$7]) {
                            case "zero": return PsKernelFlag["yes"];
                            case "succ": {
                                const _wild0$11 = __ps$match$0.value;
                                return PsKernelFlag["no"];
                            }
                            case "max": {
                                const _wild0$11 = __ps$match$0.left;
                                const _wild1$12 = __ps$match$0.right;
                                return PsKernelFlag["no"];
                            }
                            case "imax": {
                                const _wild0$11 = __ps$match$0.left;
                                const _wild1$12 = __ps$match$0.right;
                                return PsKernelFlag["no"];
                            }
                            case "param": {
                                const _wild0$11 = __ps$match$0.name;
                                return PsKernelFlag["no"];
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "max": {
                        const _wild0$9 = __ps$match$0.left;
                        const _wild1$10 = __ps$match$0.right;
                        return PsKernelFlag["no"];
                    }
                    case "imax": {
                        const _wild0$9 = __ps$match$0.left;
                        const _wild1$10 = __ps$match$0.right;
                        return PsKernelFlag["no"];
                    }
                    case "param": {
                        const _wild0$9 = __ps$match$0.name;
                        return PsKernelFlag["no"];
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
                return (yield* (function* () { const __ps$match$0 = smallLeft; switch (__ps$match$0[__ps$tag$12]) {
                    case "no": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["imaxCompare"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](left, right), PsKernelList["nil"]())), tasks, values));
                    case "yes": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](right, offset), tasks, values));
                } throw new Error("invalid ProofScript constructor tag"); })());
            } })());
        }
        case "imax": {
            const _wild0 = __ps$match$0.left;
            const _wild1 = __ps$match$0.right;
            return (yield* (function* () { {
                const smallLeft = (yield* (function* () { const __ps$match$0 = left; switch (__ps$match$0[__ps$tag$7]) {
                    case "zero": return PsKernelFlag["yes"];
                    case "succ": {
                        const child = __ps$match$0.value;
                        return (yield* (function* () { const __ps$match$0 = child; switch (__ps$match$0[__ps$tag$7]) {
                            case "zero": return PsKernelFlag["yes"];
                            case "succ": {
                                const _wild0$11 = __ps$match$0.value;
                                return PsKernelFlag["no"];
                            }
                            case "max": {
                                const _wild0$11 = __ps$match$0.left;
                                const _wild1$12 = __ps$match$0.right;
                                return PsKernelFlag["no"];
                            }
                            case "imax": {
                                const _wild0$11 = __ps$match$0.left;
                                const _wild1$12 = __ps$match$0.right;
                                return PsKernelFlag["no"];
                            }
                            case "param": {
                                const _wild0$11 = __ps$match$0.name;
                                return PsKernelFlag["no"];
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "max": {
                        const _wild0$9 = __ps$match$0.left;
                        const _wild1$10 = __ps$match$0.right;
                        return PsKernelFlag["no"];
                    }
                    case "imax": {
                        const _wild0$9 = __ps$match$0.left;
                        const _wild1$10 = __ps$match$0.right;
                        return PsKernelFlag["no"];
                    }
                    case "param": {
                        const _wild0$9 = __ps$match$0.name;
                        return PsKernelFlag["no"];
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
                return (yield* (function* () { const __ps$match$0 = smallLeft; switch (__ps$match$0[__ps$tag$12]) {
                    case "no": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["imaxCompare"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](left, right), PsKernelList["nil"]())), tasks, values));
                    case "yes": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](right, offset), tasks, values));
                } throw new Error("invalid ProofScript constructor tag"); })());
            } })());
        }
        case "param": {
            const _wild0 = __ps$match$0.name;
            return (yield* (function* () { {
                const smallLeft = (yield* (function* () { const __ps$match$0 = left; switch (__ps$match$0[__ps$tag$7]) {
                    case "zero": return PsKernelFlag["yes"];
                    case "succ": {
                        const child = __ps$match$0.value;
                        return (yield* (function* () { const __ps$match$0 = child; switch (__ps$match$0[__ps$tag$7]) {
                            case "zero": return PsKernelFlag["yes"];
                            case "succ": {
                                const _wild0$8 = __ps$match$0.value;
                                return PsKernelFlag["no"];
                            }
                            case "max": {
                                const _wild0$8 = __ps$match$0.left;
                                const _wild1 = __ps$match$0.right;
                                return PsKernelFlag["no"];
                            }
                            case "imax": {
                                const _wild0$8 = __ps$match$0.left;
                                const _wild1 = __ps$match$0.right;
                                return PsKernelFlag["no"];
                            }
                            case "param": {
                                const _wild0$8 = __ps$match$0.name;
                                return PsKernelFlag["no"];
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "max": {
                        const _wild0$6 = __ps$match$0.left;
                        const _wild1 = __ps$match$0.right;
                        return PsKernelFlag["no"];
                    }
                    case "imax": {
                        const _wild0$6 = __ps$match$0.left;
                        const _wild1 = __ps$match$0.right;
                        return PsKernelFlag["no"];
                    }
                    case "param": {
                        const _wild0$6 = __ps$match$0.name;
                        return PsKernelFlag["no"];
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
                return (yield* (function* () { const __ps$match$0 = smallLeft; switch (__ps$match$0[__ps$tag$12]) {
                    case "no": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["imaxCompare"](left, right, offset, PsKernelList["cons"](PsKernelOrderTask["level"](left, right), PsKernelList["nil"]())), tasks, values));
                    case "yes": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](right, offset), tasks, values));
                } throw new Error("invalid ProofScript constructor tag"); })());
            } })());
        }
    } throw new Error("invalid ProofScript constructor tag"); })());
    case "yes": return (yield* __ps$invoke(psKernelUniverseSmartMax, left, right, offset, tasks, values));
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelUniverseIMax, __ps$impl$psKernelUniverseIMax);
export function psKernelUniverseProbes(left, right) { return __ps$run(__ps$impl$psKernelUniverseProbes(left, right)); }
function* __ps$impl$psKernelUniverseProbes(left, right) { return (yield* (function* () { {
    const fromLeft = (yield* (function* () { const __ps$match$0 = left; switch (__ps$match$0[__ps$tag$7]) {
        case "zero": return PsKernelList["nil"]();
        case "succ": {
            const _wild0 = __ps$match$0.value;
            return PsKernelList["nil"]();
        }
        case "max": {
            const a = __ps$match$0.left;
            const b = __ps$match$0.right;
            return PsKernelList["cons"](PsKernelMaxProbe["probe"](right, a, left), PsKernelList["cons"](PsKernelMaxProbe["probe"](right, b, left), PsKernelList["nil"]()));
        }
        case "imax": {
            const _wild0 = __ps$match$0.left;
            const _wild1 = __ps$match$0.right;
            return PsKernelList["nil"]();
        }
        case "param": {
            const _wild0 = __ps$match$0.name;
            return PsKernelList["nil"]();
        }
    } throw new Error("invalid ProofScript constructor tag"); })());
    return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$7]) {
        case "zero": return fromLeft;
        case "succ": {
            const _wild0 = __ps$match$0.value;
            return fromLeft;
        }
        case "max": {
            const a = __ps$match$0.left;
            const b = __ps$match$0.right;
            return PsKernelList["cons"](PsKernelMaxProbe["probe"](left, a, right), PsKernelList["cons"](PsKernelMaxProbe["probe"](left, b, right), fromLeft));
        }
        case "imax": {
            const _wild0 = __ps$match$0.left;
            const _wild1 = __ps$match$0.right;
            return fromLeft;
        }
        case "param": {
            const _wild0 = __ps$match$0.name;
            return fromLeft;
        }
    } throw new Error("invalid ProofScript constructor tag"); })());
} })()); }
__ps$implementations.set(psKernelUniverseProbes, __ps$impl$psKernelUniverseProbes);
export function psKernelUniverseFinish(values) { while (true) {
    {
        const __ps$match$0 = values;
        switch (__ps$match$0[__ps$tag$8]) {
            case "nil": {
                return PsKernelUniverseResult["invalidState"];
            }
            case "cons": {
                const value = __ps$match$0.head;
                const tail = __ps$match$0.tail;
                {
                    const __ps$match$0 = tail;
                    switch (__ps$match$0[__ps$tag$8]) {
                        case "nil": {
                            return PsKernelUniverseResult["done"](value);
                        }
                        case "cons": {
                            const _wild0 = __ps$match$0.head;
                            const _wild1 = __ps$match$0.tail;
                            return PsKernelUniverseResult["invalidState"];
                        }
                    }
                    throw new Error("invalid ProofScript constructor tag");
                }
            }
        }
        throw new Error("invalid ProofScript constructor tag");
    }
} }
export function psKernelUniverseStep(state) { return __ps$run(__ps$impl$psKernelUniverseStep(state)); }
function* __ps$impl$psKernelUniverseStep(state) { return (yield* (function* () { const __ps$match$0 = state; switch (__ps$match$0[__ps$tag$32]) {
    case "state": {
        const tasks = __ps$match$0.tasks;
        const values = __ps$match$0.values;
        return (yield* (function* () { const __ps$match$0 = tasks; switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return PsKernelUniverseStep["final"]((yield* __ps$invoke(psKernelUniverseFinish, values)));
            case "cons": {
                const task = __ps$match$0.head;
                const rest = __ps$match$0.tail;
                return (yield* (function* () { const __ps$match$0 = task; switch (__ps$match$0[__ps$tag$31]) {
                    case "normalize": {
                        const value = __ps$match$0.value;
                        const offset = __ps$match$0.offset;
                        return (yield* (function* () { const __ps$match$0 = value; switch (__ps$match$0[__ps$tag$7]) {
                            case "zero": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](value, offset), rest, values));
                            case "succ": {
                                const child = __ps$match$0.value;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["normalize"](child, (yield* __ps$invoke(psKernelNaturalSucc, offset))), rest, values));
                            }
                            case "max": {
                                const left = __ps$match$0.left;
                                const right = __ps$match$0.right;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["normalize"](left, PsKernelNatural["zero"]), PsKernelList["cons"](PsKernelUniverseTask["normalize"](right, PsKernelNatural["zero"]), PsKernelList["cons"](PsKernelUniverseTask["joinMax"](offset), rest)), values));
                            }
                            case "imax": {
                                const left = __ps$match$0.left;
                                const right = __ps$match$0.right;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["normalize"](left, PsKernelNatural["zero"]), PsKernelList["cons"](PsKernelUniverseTask["normalize"](right, PsKernelNatural["zero"]), PsKernelList["cons"](PsKernelUniverseTask["joinIMax"](offset), rest)), values));
                            }
                            case "param": {
                                const _wild0 = __ps$match$0.name;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](value, offset), rest, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "joinMax": {
                        const offset = __ps$match$0.offset;
                        return (yield* (function* () { const __ps$match$0 = values; switch (__ps$match$0[__ps$tag$8]) {
                            case "nil": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                            case "cons": {
                                const right = __ps$match$0.head;
                                const tail = __ps$match$0.tail;
                                return (yield* (function* () { const __ps$match$0 = tail; switch (__ps$match$0[__ps$tag$8]) {
                                    case "nil": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                                    case "cons": {
                                        const left = __ps$match$0.head;
                                        const remaining = __ps$match$0.tail;
                                        return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["collect"](offset, PsKernelList["cons"](left, PsKernelList["cons"](right, PsKernelList["nil"]())), PsKernelList["nil"]()), rest, remaining));
                                    }
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "joinIMax": {
                        const offset = __ps$match$0.offset;
                        return (yield* (function* () { const __ps$match$0 = values; switch (__ps$match$0[__ps$tag$8]) {
                            case "nil": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                            case "cons": {
                                const right = __ps$match$0.head;
                                const tail = __ps$match$0.tail;
                                return (yield* (function* () { const __ps$match$0 = tail; switch (__ps$match$0[__ps$tag$8]) {
                                    case "nil": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                                    case "cons": {
                                        const left = __ps$match$0.head;
                                        const remaining = __ps$match$0.tail;
                                        return (yield* __ps$invoke(psKernelUniverseIMax, left, right, offset, rest, remaining));
                                    }
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "wrap": {
                        const value = __ps$match$0.value;
                        const offset = __ps$match$0.offset;
                        return (yield* (function* () { const __ps$match$0 = offset; switch (__ps$match$0[__ps$tag$4]) {
                            case "zero": return (yield* __ps$invoke(psKernelUniversePush, value, rest, values));
                            case "positive": {
                                const _wild0 = __ps$match$0.value;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](PsKernelLevel["succ"](value), (yield* __ps$invoke(psKernelNaturalPred, offset))), rest, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "imaxCompare": {
                        const left = __ps$match$0.left;
                        const right = __ps$match$0.right;
                        const offset = __ps$match$0.offset;
                        const work = __ps$match$0.work;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelOrderStep, work)); switch (__ps$match$0[__ps$tag$28]) {
                            case "next": {
                                const next = __ps$match$0.tasks;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["imaxCompare"](left, right, offset, next), rest, values));
                            }
                            case "done": {
                                const order = __ps$match$0.order;
                                return (yield* (function* () { const __ps$match$0 = order; switch (__ps$match$0[__ps$tag$13]) {
                                    case "less": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](PsKernelLevel["imax"](left, right), offset), rest, values));
                                    case "same": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](left, offset), rest, values));
                                    case "greater": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](PsKernelLevel["imax"](left, right), offset), rest, values));
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                            case "invalidState": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "maxBases": {
                        const left = __ps$match$0.left;
                        const right = __ps$match$0.right;
                        const offset = __ps$match$0.offset;
                        const work = __ps$match$0.work;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelOrderStep, work)); switch (__ps$match$0[__ps$tag$28]) {
                            case "next": {
                                const next = __ps$match$0.tasks;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["maxBases"](left, right, offset, next), rest, values));
                            }
                            case "done": {
                                const order = __ps$match$0.order;
                                return (yield* (function* () { const __ps$match$0 = order; switch (__ps$match$0[__ps$tag$13]) {
                                    case "less": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["probeMax"](left, right, offset, (yield* __ps$invoke(psKernelUniverseProbes, left, right))), rest, values));
                                    case "same": return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, left)); switch (__ps$match$0[__ps$tag$29]) {
                                        case "parts": {
                                            const unusedLeft = __ps$match$0.base;
                                            const leftCount = __ps$match$0.count;
                                            return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, right)); switch (__ps$match$0[__ps$tag$29]) {
                                                case "parts": {
                                                    const unusedRight = __ps$match$0.base;
                                                    const rightCount = __ps$match$0.count;
                                                    return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["maxOffsets"](left, right, offset, PsKernelNumericState["order"](leftCount, rightCount, PsKernelOrder["same"])), rest, values));
                                                }
                                            } throw new Error("invalid ProofScript constructor tag"); })());
                                        }
                                    } throw new Error("invalid ProofScript constructor tag"); })());
                                    case "greater": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["probeMax"](left, right, offset, (yield* __ps$invoke(psKernelUniverseProbes, left, right))), rest, values));
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                            case "invalidState": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "maxOffsets": {
                        const left = __ps$match$0.left;
                        const right = __ps$match$0.right;
                        const offset = __ps$match$0.offset;
                        const numeric = __ps$match$0.numeric;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelNumericStep, numeric)); switch (__ps$match$0[__ps$tag$17]) {
                            case "next": {
                                const next = __ps$match$0.state;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["maxOffsets"](left, right, offset, next), rest, values));
                            }
                            case "ordered": {
                                const order = __ps$match$0.order;
                                return (yield* (function* () { const __ps$match$0 = order; switch (__ps$match$0[__ps$tag$13]) {
                                    case "less": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](right, offset), rest, values));
                                    case "same": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](left, offset), rest, values));
                                    case "greater": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](left, offset), rest, values));
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                            case "sum": {
                                const _wild0 = __ps$match$0.value;
                                return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "probeMax": {
                        const left = __ps$match$0.left;
                        const right = __ps$match$0.right;
                        const offset = __ps$match$0.offset;
                        const probes = __ps$match$0.probes;
                        return (yield* (function* () { const __ps$match$0 = probes; switch (__ps$match$0[__ps$tag$8]) {
                            case "nil": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](PsKernelLevel["max"](left, right), offset), rest, values));
                            case "cons": {
                                const probe = __ps$match$0.head;
                                const tail = __ps$match$0.tail;
                                return (yield* (function* () { const __ps$match$0 = probe; switch (__ps$match$0[__ps$tag$30]) {
                                    case "probe": {
                                        const a = __ps$match$0.left;
                                        const b = __ps$match$0.right;
                                        const result = __ps$match$0.result;
                                        return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["probeCompare"](left, right, offset, result, tail, PsKernelList["cons"](PsKernelOrderTask["level"](a, b), PsKernelList["nil"]())), rest, values));
                                    }
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "probeCompare": {
                        const left = __ps$match$0.left;
                        const right = __ps$match$0.right;
                        const offset = __ps$match$0.offset;
                        const result = __ps$match$0.result;
                        const probes = __ps$match$0.probes;
                        const work = __ps$match$0.work;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelOrderStep, work)); switch (__ps$match$0[__ps$tag$28]) {
                            case "next": {
                                const next = __ps$match$0.tasks;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["probeCompare"](left, right, offset, result, probes, next), rest, values));
                            }
                            case "done": {
                                const order = __ps$match$0.order;
                                return (yield* (function* () { const __ps$match$0 = order; switch (__ps$match$0[__ps$tag$13]) {
                                    case "less": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["probeMax"](left, right, offset, probes), rest, values));
                                    case "same": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](result, offset), rest, values));
                                    case "greater": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["probeMax"](left, right, offset, probes), rest, values));
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                            case "invalidState": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "collect": {
                        const offset = __ps$match$0.offset;
                        const todo = __ps$match$0.todo;
                        const leaves = __ps$match$0.leaves;
                        return (yield* (function* () { const __ps$match$0 = todo; switch (__ps$match$0[__ps$tag$8]) {
                            case "nil": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["sort"](offset, leaves, PsKernelList["nil"]()), rest, values));
                            case "cons": {
                                const value = __ps$match$0.head;
                                const tail = __ps$match$0.tail;
                                return (yield* (function* () { const __ps$match$0 = value; switch (__ps$match$0[__ps$tag$7]) {
                                    case "zero": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["collect"](offset, tail, PsKernelList["cons"](value, leaves)), rest, values));
                                    case "succ": {
                                        const _wild0 = __ps$match$0.value;
                                        return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["collect"](offset, tail, PsKernelList["cons"](value, leaves)), rest, values));
                                    }
                                    case "max": {
                                        const a = __ps$match$0.left;
                                        const b = __ps$match$0.right;
                                        return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["collect"](offset, PsKernelList["cons"](a, PsKernelList["cons"](b, tail)), leaves), rest, values));
                                    }
                                    case "imax": {
                                        const _wild0 = __ps$match$0.left;
                                        const _wild1 = __ps$match$0.right;
                                        return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["collect"](offset, tail, PsKernelList["cons"](value, leaves)), rest, values));
                                    }
                                    case "param": {
                                        const _wild0 = __ps$match$0.name;
                                        return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["collect"](offset, tail, PsKernelList["cons"](value, leaves)), rest, values));
                                    }
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "sort": {
                        const offset = __ps$match$0.offset;
                        const todo = __ps$match$0.todo;
                        const sorted = __ps$match$0.sorted;
                        return (yield* (function* () { const __ps$match$0 = todo; switch (__ps$match$0[__ps$tag$8]) {
                            case "nil": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["prune"](offset, sorted), rest, values));
                            case "cons": {
                                const candidate = __ps$match$0.head;
                                const tail = __ps$match$0.tail;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["insert"](offset, tail, candidate, sorted, PsKernelList["nil"]()), rest, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "insert": {
                        const offset = __ps$match$0.offset;
                        const todo = __ps$match$0.todo;
                        const candidate = __ps$match$0.candidate;
                        const scan = __ps$match$0.scan;
                        const prefixRev = __ps$match$0.prefixRev;
                        return (yield* (function* () { const __ps$match$0 = scan; switch (__ps$match$0[__ps$tag$8]) {
                            case "nil": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["restore"](offset, todo, prefixRev, PsKernelList["cons"](candidate, PsKernelList["nil"]())), rest, values));
                            case "cons": {
                                const current = __ps$match$0.head;
                                const tail = __ps$match$0.tail;
                                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, candidate)); switch (__ps$match$0[__ps$tag$29]) {
                                    case "parts": {
                                        const a = __ps$match$0.base;
                                        const unusedCountA = __ps$match$0.count;
                                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, current)); switch (__ps$match$0[__ps$tag$29]) {
                                            case "parts": {
                                                const b = __ps$match$0.base;
                                                const unusedCountB = __ps$match$0.count;
                                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["insertCompare"](offset, todo, candidate, current, tail, prefixRev, PsKernelList["cons"](PsKernelOrderTask["level"](a, b), PsKernelList["nil"]())), rest, values));
                                            }
                                        } throw new Error("invalid ProofScript constructor tag"); })());
                                    }
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "insertCompare": {
                        const offset = __ps$match$0.offset;
                        const todo = __ps$match$0.todo;
                        const candidate = __ps$match$0.candidate;
                        const current = __ps$match$0.current;
                        const tail = __ps$match$0.tail;
                        const prefixRev = __ps$match$0.prefixRev;
                        const work = __ps$match$0.work;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelOrderStep, work)); switch (__ps$match$0[__ps$tag$28]) {
                            case "next": {
                                const next = __ps$match$0.tasks;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["insertCompare"](offset, todo, candidate, current, tail, prefixRev, next), rest, values));
                            }
                            case "done": {
                                const order = __ps$match$0.order;
                                return (yield* (function* () { const __ps$match$0 = order; switch (__ps$match$0[__ps$tag$13]) {
                                    case "less": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["restore"](offset, todo, prefixRev, PsKernelList["cons"](candidate, PsKernelList["cons"](current, tail))), rest, values));
                                    case "same": return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, candidate)); switch (__ps$match$0[__ps$tag$29]) {
                                        case "parts": {
                                            const unusedA = __ps$match$0.base;
                                            const a = __ps$match$0.count;
                                            return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, current)); switch (__ps$match$0[__ps$tag$29]) {
                                                case "parts": {
                                                    const unusedB = __ps$match$0.base;
                                                    const b = __ps$match$0.count;
                                                    return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["insertOffset"](offset, todo, candidate, current, tail, prefixRev, PsKernelNumericState["order"](a, b, PsKernelOrder["same"])), rest, values));
                                                }
                                            } throw new Error("invalid ProofScript constructor tag"); })());
                                        }
                                    } throw new Error("invalid ProofScript constructor tag"); })());
                                    case "greater": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["insert"](offset, todo, candidate, tail, PsKernelList["cons"](current, prefixRev)), rest, values));
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                            case "invalidState": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "insertOffset": {
                        const offset = __ps$match$0.offset;
                        const todo = __ps$match$0.todo;
                        const candidate = __ps$match$0.candidate;
                        const current = __ps$match$0.current;
                        const tail = __ps$match$0.tail;
                        const prefixRev = __ps$match$0.prefixRev;
                        const numeric = __ps$match$0.numeric;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelNumericStep, numeric)); switch (__ps$match$0[__ps$tag$17]) {
                            case "next": {
                                const next = __ps$match$0.state;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["insertOffset"](offset, todo, candidate, current, tail, prefixRev, next), rest, values));
                            }
                            case "ordered": {
                                const order = __ps$match$0.order;
                                return (yield* (function* () { const __ps$match$0 = order; switch (__ps$match$0[__ps$tag$13]) {
                                    case "less": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["restore"](offset, todo, prefixRev, PsKernelList["cons"](current, tail)), rest, values));
                                    case "same": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["restore"](offset, todo, prefixRev, PsKernelList["cons"](current, tail)), rest, values));
                                    case "greater": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["restore"](offset, todo, prefixRev, PsKernelList["cons"](candidate, tail)), rest, values));
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                            case "sum": {
                                const _wild0 = __ps$match$0.value;
                                return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "restore": {
                        const offset = __ps$match$0.offset;
                        const todo = __ps$match$0.todo;
                        const prefixRev = __ps$match$0.prefixRev;
                        const suffix = __ps$match$0.suffix;
                        return (yield* (function* () { const __ps$match$0 = prefixRev; switch (__ps$match$0[__ps$tag$8]) {
                            case "nil": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["sort"](offset, todo, suffix), rest, values));
                            case "cons": {
                                const head = __ps$match$0.head;
                                const tail = __ps$match$0.tail;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["restore"](offset, todo, tail, PsKernelList["cons"](head, suffix)), rest, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "prune": {
                        const offset = __ps$match$0.offset;
                        const sorted = __ps$match$0.sorted;
                        return (yield* (function* () { const __ps$match$0 = sorted; switch (__ps$match$0[__ps$tag$8]) {
                            case "nil": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                            case "cons": {
                                const first = __ps$match$0.head;
                                const tail = __ps$match$0.tail;
                                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, first)); switch (__ps$match$0[__ps$tag$29]) {
                                    case "parts": {
                                        const base = __ps$match$0.base;
                                        const count = __ps$match$0.count;
                                        return (yield* (function* () { const __ps$match$0 = base; switch (__ps$match$0[__ps$tag$7]) {
                                            case "zero": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["constantScan"](offset, first, tail, tail), rest, values));
                                            case "succ": {
                                                const _wild0 = __ps$match$0.value;
                                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrapList"](offset, sorted, PsKernelList["nil"]()), rest, values));
                                            }
                                            case "max": {
                                                const _wild0 = __ps$match$0.left;
                                                const _wild1 = __ps$match$0.right;
                                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrapList"](offset, sorted, PsKernelList["nil"]()), rest, values));
                                            }
                                            case "imax": {
                                                const _wild0 = __ps$match$0.left;
                                                const _wild1 = __ps$match$0.right;
                                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrapList"](offset, sorted, PsKernelList["nil"]()), rest, values));
                                            }
                                            case "param": {
                                                const _wild0 = __ps$match$0.name;
                                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrapList"](offset, sorted, PsKernelList["nil"]()), rest, values));
                                            }
                                        } throw new Error("invalid ProofScript constructor tag"); })());
                                    }
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "constantScan": {
                        const offset = __ps$match$0.offset;
                        const constant = __ps$match$0.constant;
                        const others = __ps$match$0.others;
                        const scan = __ps$match$0.scan;
                        return (yield* (function* () { const __ps$match$0 = scan; switch (__ps$match$0[__ps$tag$8]) {
                            case "nil": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrapList"](offset, PsKernelList["cons"](constant, others), PsKernelList["nil"]()), rest, values));
                            case "cons": {
                                const head = __ps$match$0.head;
                                const tail = __ps$match$0.tail;
                                return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, constant)); switch (__ps$match$0[__ps$tag$29]) {
                                    case "parts": {
                                        const unusedA = __ps$match$0.base;
                                        const a = __ps$match$0.count;
                                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelOffset, head)); switch (__ps$match$0[__ps$tag$29]) {
                                            case "parts": {
                                                const unusedB = __ps$match$0.base;
                                                const b = __ps$match$0.count;
                                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["constantCompare"](offset, constant, others, tail, PsKernelNumericState["order"](b, a, PsKernelOrder["same"])), rest, values));
                                            }
                                        } throw new Error("invalid ProofScript constructor tag"); })());
                                    }
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "constantCompare": {
                        const offset = __ps$match$0.offset;
                        const constant = __ps$match$0.constant;
                        const others = __ps$match$0.others;
                        const scan = __ps$match$0.scan;
                        const numeric = __ps$match$0.numeric;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelNumericStep, numeric)); switch (__ps$match$0[__ps$tag$17]) {
                            case "next": {
                                const next = __ps$match$0.state;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["constantCompare"](offset, constant, others, scan, next), rest, values));
                            }
                            case "ordered": {
                                const order = __ps$match$0.order;
                                return (yield* (function* () { const __ps$match$0 = order; switch (__ps$match$0[__ps$tag$13]) {
                                    case "less": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["constantScan"](offset, constant, others, scan), rest, values));
                                    case "same": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrapList"](offset, others, PsKernelList["nil"]()), rest, values));
                                    case "greater": return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrapList"](offset, others, PsKernelList["nil"]()), rest, values));
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                            case "sum": {
                                const _wild0 = __ps$match$0.value;
                                return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "wrapList": {
                        const offset = __ps$match$0.offset;
                        const todo = __ps$match$0.todo;
                        const doneRev = __ps$match$0.doneRev;
                        return (yield* (function* () { const __ps$match$0 = todo; switch (__ps$match$0[__ps$tag$8]) {
                            case "nil": return (yield* (function* () { const __ps$match$0 = doneRev; switch (__ps$match$0[__ps$tag$8]) {
                                case "nil": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                                case "cons": {
                                    const last = __ps$match$0.head;
                                    const tail = __ps$match$0.tail;
                                    return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["assemble"](tail, last), rest, values));
                                }
                            } throw new Error("invalid ProofScript constructor tag"); })());
                            case "cons": {
                                const head = __ps$match$0.head;
                                const tail = __ps$match$0.tail;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrap"](head, offset), PsKernelList["cons"](PsKernelUniverseTask["wrapped"](offset, tail, doneRev), rest), values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "wrapped": {
                        const offset = __ps$match$0.offset;
                        const todo = __ps$match$0.todo;
                        const doneRev = __ps$match$0.doneRev;
                        return (yield* (function* () { const __ps$match$0 = values; switch (__ps$match$0[__ps$tag$8]) {
                            case "nil": return PsKernelUniverseStep["final"](PsKernelUniverseResult["invalidState"]);
                            case "cons": {
                                const wrapped = __ps$match$0.head;
                                const tail = __ps$match$0.tail;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["wrapList"](offset, todo, PsKernelList["cons"](wrapped, doneRev)), rest, tail));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "assemble": {
                        const todo = __ps$match$0.todo;
                        const value = __ps$match$0.value;
                        return (yield* (function* () { const __ps$match$0 = todo; switch (__ps$match$0[__ps$tag$8]) {
                            case "nil": return (yield* __ps$invoke(psKernelUniversePush, value, rest, values));
                            case "cons": {
                                const head = __ps$match$0.head;
                                const tail = __ps$match$0.tail;
                                return (yield* __ps$invoke(psKernelUniverseSchedule, PsKernelUniverseTask["assemble"](tail, PsKernelLevel["max"](head, value)), rest, values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelUniverseStep, __ps$impl$psKernelUniverseStep);
export function psKernelUniverseStart(value) { while (true) {
    return PsKernelUniverseState["state"](PsKernelList["cons"](PsKernelUniverseTask["normalize"](value, PsKernelNatural["zero"]), PsKernelList["nil"]()), PsKernelList["nil"]());
} }
export function psKernelUniverseRun(fuel, __ps_eta_0) { return __ps$run(__ps$impl$psKernelUniverseRun(fuel, __ps_eta_0)); }
function* __ps$impl$psKernelUniverseRun(fuel, __ps_eta_0) { return (yield* (function* () { const __ps$match$0 = fuel; switch (__ps$match$0[__ps$tag$11]) {
    case "stop": return (yield* (function* () { {
        const state = __ps_eta_0;
        return (yield* (function* () { const __ps$match$0 = state; switch (__ps$match$0[__ps$tag$32]) {
            case "state": {
                const tasks = __ps$match$0.tasks;
                const values = __ps$match$0.values;
                return (yield* (function* () { const __ps$match$0 = tasks; switch (__ps$match$0[__ps$tag$8]) {
                    case "nil": return (yield* __ps$invoke(psKernelUniverseFinish, values));
                    case "cons": {
                        const _wild0 = __ps$match$0.head;
                        const _wild1 = __ps$match$0.tail;
                        return PsKernelUniverseResult["outOfFuel"];
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    } })());
    case "more": {
        const remaining = __ps$match$0.remaining;
        return (yield* (function* () { {
            const state = __ps_eta_0;
            return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelUniverseStep, state)); switch (__ps$match$0[__ps$tag$34]) {
                case "next": {
                    const next = __ps$match$0.state;
                    return (yield* (function* () { {
                        const smaller = __ps$wrap(function* (_$3) { return (yield* __ps$invoke(psKernelUniverseRun, remaining, _$3)); });
                        return (yield* __ps$invoke(smaller, next));
                    } })());
                }
                case "final": {
                    const result = __ps$match$0.result;
                    return result;
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
        } })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelUniverseRun, __ps$impl$psKernelUniverseRun);
export function psKernelLevelCheckStart(left, right) { return __ps$run(__ps$impl$psKernelLevelCheckStart(left, right)); }
function* __ps$impl$psKernelLevelCheckStart(left, right) { return PsKernelLevelCheckState["left"](right, (yield* __ps$invoke(psKernelUniverseStart, left))); }
__ps$implementations.set(psKernelLevelCheckStart, __ps$impl$psKernelLevelCheckStart);
export function psKernelLevelCheckStep(state) { return __ps$run(__ps$impl$psKernelLevelCheckStep(state)); }
function* __ps$impl$psKernelLevelCheckStep(state) { return (yield* (function* () { const __ps$match$0 = state; switch (__ps$match$0[__ps$tag$35]) {
    case "left": {
        const right = __ps$match$0.right;
        const current = __ps$match$0.state;
        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelUniverseStep, current)); switch (__ps$match$0[__ps$tag$34]) {
            case "next": {
                const next = __ps$match$0.state;
                return PsKernelLevelCheckStep["next"](PsKernelLevelCheckState["left"](right, next));
            }
            case "final": {
                const result = __ps$match$0.result;
                return (yield* (function* () { const __ps$match$0 = result; switch (__ps$match$0[__ps$tag$33]) {
                    case "outOfFuel": return PsKernelLevelCheckStep["final"](PsKernelLevelCheckResult["invalidState"]);
                    case "invalidState": return PsKernelLevelCheckStep["final"](PsKernelLevelCheckResult["invalidState"]);
                    case "done": {
                        const left = __ps$match$0.value;
                        return PsKernelLevelCheckStep["next"](PsKernelLevelCheckState["right"](left, (yield* __ps$invoke(psKernelUniverseStart, right))));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "right": {
        const left = __ps$match$0.left;
        const current = __ps$match$0.state;
        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelUniverseStep, current)); switch (__ps$match$0[__ps$tag$34]) {
            case "next": {
                const next = __ps$match$0.state;
                return PsKernelLevelCheckStep["next"](PsKernelLevelCheckState["right"](left, next));
            }
            case "final": {
                const result = __ps$match$0.result;
                return (yield* (function* () { const __ps$match$0 = result; switch (__ps$match$0[__ps$tag$33]) {
                    case "outOfFuel": return PsKernelLevelCheckStep["final"](PsKernelLevelCheckResult["invalidState"]);
                    case "invalidState": return PsKernelLevelCheckStep["final"](PsKernelLevelCheckResult["invalidState"]);
                    case "done": {
                        const right = __ps$match$0.value;
                        return PsKernelLevelCheckStep["next"](PsKernelLevelCheckState["order"](PsKernelList["cons"](PsKernelOrderTask["level"](left, right), PsKernelList["nil"]())));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "order": {
        const tasks = __ps$match$0.tasks;
        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelOrderStep, tasks)); switch (__ps$match$0[__ps$tag$28]) {
            case "next": {
                const next = __ps$match$0.tasks;
                return PsKernelLevelCheckStep["next"](PsKernelLevelCheckState["order"](next));
            }
            case "done": {
                const order = __ps$match$0.order;
                return (yield* (function* () { const __ps$match$0 = order; switch (__ps$match$0[__ps$tag$13]) {
                    case "less": return PsKernelLevelCheckStep["final"](PsKernelLevelCheckResult["different"]);
                    case "same": return PsKernelLevelCheckStep["final"](PsKernelLevelCheckResult["equal"]);
                    case "greater": return PsKernelLevelCheckStep["final"](PsKernelLevelCheckResult["different"]);
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "invalidState": return PsKernelLevelCheckStep["final"](PsKernelLevelCheckResult["invalidState"]);
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelLevelCheckStep, __ps$impl$psKernelLevelCheckStep);
export function psKernelLevelCheckRun(fuel, __ps_eta_0) { return __ps$run(__ps$impl$psKernelLevelCheckRun(fuel, __ps_eta_0)); }
function* __ps$impl$psKernelLevelCheckRun(fuel, __ps_eta_0) { return (yield* (function* () { const __ps$match$0 = fuel; switch (__ps$match$0[__ps$tag$11]) {
    case "stop": return (yield* (function* () { {
        const state = __ps_eta_0;
        return PsKernelLevelCheckResult["outOfFuel"];
    } })());
    case "more": {
        const remaining = __ps$match$0.remaining;
        return (yield* (function* () { {
            const state = __ps_eta_0;
            return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelCheckStep, state)); switch (__ps$match$0[__ps$tag$37]) {
                case "next": {
                    const next = __ps$match$0.state;
                    return (yield* (function* () { {
                        const smaller = __ps$wrap(function* (_$3) { return (yield* __ps$invoke(psKernelLevelCheckRun, remaining, _$3)); });
                        return (yield* __ps$invoke(smaller, next));
                    } })());
                }
                case "final": {
                    const result = __ps$match$0.result;
                    return result;
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
        } })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelLevelCheckRun, __ps$impl$psKernelLevelCheckRun);
export function psKernelLevelInstantiateNext(assignments, tasks, values) { while (true) {
    return PsKernelLevelInstantiateStep["next"](PsKernelLevelInstantiateState["running"](assignments, tasks, values));
} }
export function psKernelLevelInstantiateVisit(assignments, value, rest, values) { return __ps$run(__ps$impl$psKernelLevelInstantiateVisit(assignments, value, rest, values)); }
function* __ps$impl$psKernelLevelInstantiateVisit(assignments, value, rest, values) { return (yield* (function* () { const __ps$match$0 = value; switch (__ps$match$0[__ps$tag$7]) {
    case "zero": return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, rest, PsKernelList["cons"](value, values)));
    case "succ": {
        const inner = __ps$match$0.value;
        return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, PsKernelList["cons"](PsKernelLevelInstantiateTask["visit"](inner), PsKernelList["cons"](PsKernelLevelInstantiateTask["succ"], rest)), values));
    }
    case "max": {
        const left = __ps$match$0.left;
        const right = __ps$match$0.right;
        return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, PsKernelList["cons"](PsKernelLevelInstantiateTask["visit"](left), PsKernelList["cons"](PsKernelLevelInstantiateTask["visit"](right), PsKernelList["cons"](PsKernelLevelInstantiateTask["max"], rest))), values));
    }
    case "imax": {
        const left = __ps$match$0.left;
        const right = __ps$match$0.right;
        return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, PsKernelList["cons"](PsKernelLevelInstantiateTask["visit"](left), PsKernelList["cons"](PsKernelLevelInstantiateTask["visit"](right), PsKernelList["cons"](PsKernelLevelInstantiateTask["imax"], rest))), values));
    }
    case "param": {
        const name = __ps$match$0.name;
        return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, PsKernelList["cons"](PsKernelLevelInstantiateTask["lookup"](name, assignments), rest), values));
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelLevelInstantiateVisit, __ps$impl$psKernelLevelInstantiateVisit);
export function psKernelLevelInstantiateRebuild(assignments, task, rest, values) { return __ps$run(__ps$impl$psKernelLevelInstantiateRebuild(assignments, task, rest, values)); }
function* __ps$impl$psKernelLevelInstantiateRebuild(assignments, task, rest, values) { return (yield* (function* () { const __ps$match$0 = values; switch (__ps$match$0[__ps$tag$8]) {
    case "nil": return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
    case "cons": {
        const right = __ps$match$0.head;
        const tail = __ps$match$0.tail;
        return (yield* (function* () { const __ps$match$0 = task; switch (__ps$match$0[__ps$tag$39]) {
            case "visit": {
                const _wild0 = __ps$match$0.value;
                return (yield* (function* () { const __ps$match$0 = tail; switch (__ps$match$0[__ps$tag$8]) {
                    case "nil": return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                    case "cons": {
                        const left = __ps$match$0.head;
                        const remaining = __ps$match$0.tail;
                        return (yield* (function* () { const __ps$match$0 = task; switch (__ps$match$0[__ps$tag$39]) {
                            case "visit": {
                                const _wild0$11 = __ps$match$0.value;
                                return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                            }
                            case "succ": return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                            case "max": return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, rest, PsKernelList["cons"](PsKernelLevel["max"](left, right), remaining)));
                            case "imax": return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, rest, PsKernelList["cons"](PsKernelLevel["imax"](left, right), remaining)));
                            case "lookup": {
                                const _wild0$11 = __ps$match$0.name;
                                const _wild1 = __ps$match$0.remaining;
                                return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                            }
                            case "compare": {
                                const _wild0$11 = __ps$match$0.name;
                                const _wild1 = __ps$match$0.replacement;
                                const _wild2 = __ps$match$0.remaining;
                                const _wild3 = __ps$match$0.work;
                                return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "succ": return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, rest, PsKernelList["cons"](PsKernelLevel["succ"](right), tail)));
            case "max": return (yield* (function* () { const __ps$match$0 = tail; switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                case "cons": {
                    const left = __ps$match$0.head;
                    const remaining = __ps$match$0.tail;
                    return (yield* (function* () { const __ps$match$0 = task; switch (__ps$match$0[__ps$tag$39]) {
                        case "visit": {
                            const _wild0 = __ps$match$0.value;
                            return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                        }
                        case "succ": return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                        case "max": return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, rest, PsKernelList["cons"](PsKernelLevel["max"](left, right), remaining)));
                        case "imax": return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, rest, PsKernelList["cons"](PsKernelLevel["imax"](left, right), remaining)));
                        case "lookup": {
                            const _wild0 = __ps$match$0.name;
                            const _wild1 = __ps$match$0.remaining;
                            return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                        }
                        case "compare": {
                            const _wild0 = __ps$match$0.name;
                            const _wild1 = __ps$match$0.replacement;
                            const _wild2 = __ps$match$0.remaining;
                            const _wild3 = __ps$match$0.work;
                            return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                        }
                    } throw new Error("invalid ProofScript constructor tag"); })());
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
            case "imax": return (yield* (function* () { const __ps$match$0 = tail; switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                case "cons": {
                    const left = __ps$match$0.head;
                    const remaining = __ps$match$0.tail;
                    return (yield* (function* () { const __ps$match$0 = task; switch (__ps$match$0[__ps$tag$39]) {
                        case "visit": {
                            const _wild0 = __ps$match$0.value;
                            return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                        }
                        case "succ": return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                        case "max": return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, rest, PsKernelList["cons"](PsKernelLevel["max"](left, right), remaining)));
                        case "imax": return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, rest, PsKernelList["cons"](PsKernelLevel["imax"](left, right), remaining)));
                        case "lookup": {
                            const _wild0 = __ps$match$0.name;
                            const _wild1 = __ps$match$0.remaining;
                            return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                        }
                        case "compare": {
                            const _wild0 = __ps$match$0.name;
                            const _wild1 = __ps$match$0.replacement;
                            const _wild2 = __ps$match$0.remaining;
                            const _wild3 = __ps$match$0.work;
                            return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                        }
                    } throw new Error("invalid ProofScript constructor tag"); })());
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
            case "lookup": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.remaining;
                return (yield* (function* () { const __ps$match$0 = tail; switch (__ps$match$0[__ps$tag$8]) {
                    case "nil": return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                    case "cons": {
                        const left = __ps$match$0.head;
                        const remaining = __ps$match$0.tail;
                        return (yield* (function* () { const __ps$match$0 = task; switch (__ps$match$0[__ps$tag$39]) {
                            case "visit": {
                                const _wild0$12 = __ps$match$0.value;
                                return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                            }
                            case "succ": return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                            case "max": return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, rest, PsKernelList["cons"](PsKernelLevel["max"](left, right), remaining)));
                            case "imax": return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, rest, PsKernelList["cons"](PsKernelLevel["imax"](left, right), remaining)));
                            case "lookup": {
                                const _wild0$12 = __ps$match$0.name;
                                const _wild1$13 = __ps$match$0.remaining;
                                return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                            }
                            case "compare": {
                                const _wild0$12 = __ps$match$0.name;
                                const _wild1$13 = __ps$match$0.replacement;
                                const _wild2 = __ps$match$0.remaining;
                                const _wild3 = __ps$match$0.work;
                                return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "compare": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.replacement;
                const _wild2 = __ps$match$0.remaining;
                const _wild3 = __ps$match$0.work;
                return (yield* (function* () { const __ps$match$0 = tail; switch (__ps$match$0[__ps$tag$8]) {
                    case "nil": return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                    case "cons": {
                        const left = __ps$match$0.head;
                        const remaining = __ps$match$0.tail;
                        return (yield* (function* () { const __ps$match$0 = task; switch (__ps$match$0[__ps$tag$39]) {
                            case "visit": {
                                const _wild0$14 = __ps$match$0.value;
                                return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                            }
                            case "succ": return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                            case "max": return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, rest, PsKernelList["cons"](PsKernelLevel["max"](left, right), remaining)));
                            case "imax": return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, rest, PsKernelList["cons"](PsKernelLevel["imax"](left, right), remaining)));
                            case "lookup": {
                                const _wild0$14 = __ps$match$0.name;
                                const _wild1$15 = __ps$match$0.remaining;
                                return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                            }
                            case "compare": {
                                const _wild0$14 = __ps$match$0.name;
                                const _wild1$15 = __ps$match$0.replacement;
                                const _wild2$16 = __ps$match$0.remaining;
                                const _wild3$17 = __ps$match$0.work;
                                return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelLevelInstantiateRebuild, __ps$impl$psKernelLevelInstantiateRebuild);
export function psKernelLevelInstantiateTaskStep(assignments, task, rest, values) { return __ps$run(__ps$impl$psKernelLevelInstantiateTaskStep(assignments, task, rest, values)); }
function* __ps$impl$psKernelLevelInstantiateTaskStep(assignments, task, rest, values) { return (yield* (function* () { const __ps$match$0 = task; switch (__ps$match$0[__ps$tag$39]) {
    case "visit": {
        const value = __ps$match$0.value;
        return (yield* __ps$invoke(psKernelLevelInstantiateVisit, assignments, value, rest, values));
    }
    case "succ": return (yield* __ps$invoke(psKernelLevelInstantiateRebuild, assignments, task, rest, values));
    case "max": return (yield* __ps$invoke(psKernelLevelInstantiateRebuild, assignments, task, rest, values));
    case "imax": return (yield* __ps$invoke(psKernelLevelInstantiateRebuild, assignments, task, rest, values));
    case "lookup": {
        const name = __ps$match$0.name;
        const remaining = __ps$match$0.remaining;
        return (yield* (function* () { const __ps$match$0 = remaining; switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["undeclaredParameter"]);
            case "cons": {
                const entry = __ps$match$0.head;
                const tail = __ps$match$0.tail;
                return (yield* (function* () { const __ps$match$0 = entry; switch (__ps$match$0[__ps$tag$38]) {
                    case "assignment": {
                        const candidate = __ps$match$0.name;
                        const replacement = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, PsKernelList["cons"](PsKernelLevelInstantiateTask["compare"](name, replacement, tail, PsKernelList["cons"](PsKernelOrderTask["name"](name, candidate), PsKernelList["nil"]())), rest), values));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "compare": {
        const name = __ps$match$0.name;
        const replacement = __ps$match$0.replacement;
        const remaining = __ps$match$0.remaining;
        const work = __ps$match$0.work;
        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelOrderStep, work)); switch (__ps$match$0[__ps$tag$28]) {
            case "next": {
                const next = __ps$match$0.tasks;
                return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, PsKernelList["cons"](PsKernelLevelInstantiateTask["compare"](name, replacement, remaining, next), rest), values));
            }
            case "done": {
                const order = __ps$match$0.order;
                return (yield* (function* () { const __ps$match$0 = order; switch (__ps$match$0[__ps$tag$13]) {
                    case "less": return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, PsKernelList["cons"](PsKernelLevelInstantiateTask["lookup"](name, remaining), rest), values));
                    case "same": return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, rest, PsKernelList["cons"](replacement, values)));
                    case "greater": return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, PsKernelList["cons"](PsKernelLevelInstantiateTask["lookup"](name, remaining), rest), values));
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "invalidState": return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelLevelInstantiateTaskStep, __ps$impl$psKernelLevelInstantiateTaskStep);
export function psKernelLevelInstantiateStep(state) { return __ps$run(__ps$impl$psKernelLevelInstantiateStep(state)); }
function* __ps$impl$psKernelLevelInstantiateStep(state) { return (yield* (function* () { const __ps$match$0 = state; switch (__ps$match$0[__ps$tag$40]) {
    case "parameters": {
        const names = __ps$match$0.names;
        const levels = __ps$match$0.levels;
        const assignments = __ps$match$0.assignments;
        const target = __ps$match$0.target;
        return (yield* (function* () { const __ps$match$0 = names; switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return (yield* (function* () { const __ps$match$0 = levels; switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return (yield* __ps$invoke(psKernelLevelInstantiateNext, assignments, PsKernelList["cons"](PsKernelLevelInstantiateTask["visit"](target), PsKernelList["nil"]()), PsKernelList["nil"]()));
                case "cons": {
                    const _wild0 = __ps$match$0.head;
                    const _wild1 = __ps$match$0.tail;
                    return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidParameters"]);
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
            case "cons": {
                const name = __ps$match$0.head;
                const rest = __ps$match$0.tail;
                return (yield* (function* () { const __ps$match$0 = levels; switch (__ps$match$0[__ps$tag$8]) {
                    case "nil": return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidParameters"]);
                    case "cons": {
                        const value = __ps$match$0.head;
                        const tail = __ps$match$0.tail;
                        return (yield* (function* () { const __ps$match$0 = name; switch (__ps$match$0[__ps$tag$6]) {
                            case "anonymous": return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidParameters"]);
                            case "str": {
                                const _wild0 = __ps$match$0.parent;
                                const _wild1 = __ps$match$0.value;
                                return PsKernelLevelInstantiateStep["next"](PsKernelLevelInstantiateState["unique"](name, value, rest, tail, assignments, assignments, target));
                            }
                            case "num": {
                                const _wild0 = __ps$match$0.parent;
                                const _wild1 = __ps$match$0.value;
                                return PsKernelLevelInstantiateStep["next"](PsKernelLevelInstantiateState["unique"](name, value, rest, tail, assignments, assignments, target));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "unique": {
        const name = __ps$match$0.name;
        const value = __ps$match$0.value;
        const names = __ps$match$0.names;
        const levels = __ps$match$0.levels;
        const assignments = __ps$match$0.assignments;
        const remaining = __ps$match$0.remaining;
        const target = __ps$match$0.target;
        return (yield* (function* () { const __ps$match$0 = remaining; switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return PsKernelLevelInstantiateStep["next"](PsKernelLevelInstantiateState["parameters"](names, levels, PsKernelList["cons"](PsKernelLevelAssignment["assignment"](name, value), assignments), target));
            case "cons": {
                const entry = __ps$match$0.head;
                const tail = __ps$match$0.tail;
                return (yield* (function* () { const __ps$match$0 = entry; switch (__ps$match$0[__ps$tag$38]) {
                    case "assignment": {
                        const candidate = __ps$match$0.name;
                        const unusedValue = __ps$match$0.value;
                        return PsKernelLevelInstantiateStep["next"](PsKernelLevelInstantiateState["compare"](name, value, names, levels, assignments, tail, target, PsKernelList["cons"](PsKernelOrderTask["name"](name, candidate), PsKernelList["nil"]())));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "compare": {
        const name = __ps$match$0.name;
        const value = __ps$match$0.value;
        const names = __ps$match$0.names;
        const levels = __ps$match$0.levels;
        const assignments = __ps$match$0.assignments;
        const remaining = __ps$match$0.remaining;
        const target = __ps$match$0.target;
        const work = __ps$match$0.work;
        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelOrderStep, work)); switch (__ps$match$0[__ps$tag$28]) {
            case "next": {
                const next = __ps$match$0.tasks;
                return PsKernelLevelInstantiateStep["next"](PsKernelLevelInstantiateState["compare"](name, value, names, levels, assignments, remaining, target, next));
            }
            case "done": {
                const order = __ps$match$0.order;
                return (yield* (function* () { const __ps$match$0 = order; switch (__ps$match$0[__ps$tag$13]) {
                    case "less": return PsKernelLevelInstantiateStep["next"](PsKernelLevelInstantiateState["unique"](name, value, names, levels, assignments, remaining, target));
                    case "same": return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidParameters"]);
                    case "greater": return PsKernelLevelInstantiateStep["next"](PsKernelLevelInstantiateState["unique"](name, value, names, levels, assignments, remaining, target));
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "invalidState": return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "running": {
        const assignments = __ps$match$0.assignments;
        const tasks = __ps$match$0.tasks;
        const values = __ps$match$0.values;
        return (yield* (function* () { const __ps$match$0 = tasks; switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return (yield* (function* () { const __ps$match$0 = values; switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                case "cons": {
                    const value = __ps$match$0.head;
                    const rest = __ps$match$0.tail;
                    return (yield* (function* () { const __ps$match$0 = rest; switch (__ps$match$0[__ps$tag$8]) {
                        case "nil": return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["done"](value));
                        case "cons": {
                            const _wild0 = __ps$match$0.head;
                            const _wild1 = __ps$match$0.tail;
                            return PsKernelLevelInstantiateStep["final"](PsKernelLevelInstantiateResult["invalidState"]);
                        }
                    } throw new Error("invalid ProofScript constructor tag"); })());
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
            case "cons": {
                const task = __ps$match$0.head;
                const rest = __ps$match$0.tail;
                return (yield* __ps$invoke(psKernelLevelInstantiateTaskStep, assignments, task, rest, values));
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelLevelInstantiateStep, __ps$impl$psKernelLevelInstantiateStep);
export function psKernelLevelInstantiateStart(names, levels, target) { while (true) {
    return PsKernelLevelInstantiateState["parameters"](names, levels, PsKernelList["nil"](), target);
} }
export function psKernelLevelInstantiateRun(fuel, __ps_eta_0) { return __ps$run(__ps$impl$psKernelLevelInstantiateRun(fuel, __ps_eta_0)); }
function* __ps$impl$psKernelLevelInstantiateRun(fuel, __ps_eta_0) { return (yield* (function* () { const __ps$match$0 = fuel; switch (__ps$match$0[__ps$tag$11]) {
    case "stop": return (yield* (function* () { {
        const state = __ps_eta_0;
        return PsKernelLevelInstantiateResult["outOfFuel"];
    } })());
    case "more": {
        const remaining = __ps$match$0.remaining;
        return (yield* (function* () { {
            const state = __ps_eta_0;
            return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelInstantiateStep, state)); switch (__ps$match$0[__ps$tag$42]) {
                case "next": {
                    const next = __ps$match$0.state;
                    return (yield* (function* () { {
                        const smaller = __ps$wrap(function* (_$3) { return (yield* __ps$invoke(psKernelLevelInstantiateRun, remaining, _$3)); });
                        return (yield* __ps$invoke(smaller, next));
                    } })());
                }
                case "final": {
                    const result = __ps$match$0.result;
                    return result;
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
        } })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelLevelInstantiateRun, __ps$impl$psKernelLevelInstantiateRun);
export function psKernelExprInstantiateNext(names, levels, tasks, values) { while (true) {
    return PsKernelExprInstantiateStep["next"](PsKernelExprInstantiateState["state"](names, levels, tasks, values));
} }
export function psKernelExprInstantiateLevelError(result) { while (true) {
    {
        const __ps$match$0 = result;
        switch (__ps$match$0[__ps$tag$41]) {
            case "outOfFuel": {
                return PsKernelExprInstantiateStep["final"](PsKernelExprInstantiateResult["invalidState"]);
            }
            case "invalidState": {
                return PsKernelExprInstantiateStep["final"](PsKernelExprInstantiateResult["invalidState"]);
            }
            case "invalidParameters": {
                return PsKernelExprInstantiateStep["final"](PsKernelExprInstantiateResult["invalidParameters"]);
            }
            case "undeclaredParameter": {
                return PsKernelExprInstantiateStep["final"](PsKernelExprInstantiateResult["undeclaredParameter"]);
            }
            case "done": {
                const _wild0 = __ps$match$0.value;
                return PsKernelExprInstantiateStep["final"](PsKernelExprInstantiateResult["invalidState"]);
            }
        }
        throw new Error("invalid ProofScript constructor tag");
    }
} }
export function psKernelExprInstantiateVisit(names, levels, value, tasks, values) { return __ps$run(__ps$impl$psKernelExprInstantiateVisit(names, levels, value, tasks, values)); }
function* __ps$impl$psKernelExprInstantiateVisit(names, levels, value, tasks, values) { return (yield* (function* () { const __ps$match$0 = value; switch (__ps$match$0[__ps$tag$21]) {
    case "bvar": {
        const _wild0 = __ps$match$0.index;
        return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, tasks, PsKernelList["cons"](value, values)));
    }
    case "fvar": {
        const _wild0 = __ps$match$0.id;
        return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, tasks, PsKernelList["cons"](value, values)));
    }
    case "sortE": {
        const level = __ps$match$0.level;
        return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, PsKernelList["cons"](PsKernelExprInstantiateTask["sort"]((yield* __ps$invoke(psKernelLevelInstantiateStart, names, levels, level))), tasks), values));
    }
    case "constE": {
        const name = __ps$match$0.name;
        const _arguments = __ps$match$0.levels;
        return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, PsKernelList["cons"](PsKernelExprInstantiateTask["constant"](name, _arguments, PsKernelList["nil"]()), tasks), values));
    }
    case "app": {
        const fn = __ps$match$0.fn;
        const arg = __ps$match$0.arg;
        return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, PsKernelList["cons"](PsKernelExprInstantiateTask["visit"](fn), PsKernelList["cons"](PsKernelExprInstantiateTask["visit"](arg), PsKernelList["cons"](PsKernelExprInstantiateTask["rebuild"](PsKernelBindingTask["app"]), tasks))), values));
    }
    case "lam": {
        const name = __ps$match$0.name;
        const type = __ps$match$0.type;
        const body = __ps$match$0.body;
        const binder = __ps$match$0.binder;
        return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, PsKernelList["cons"](PsKernelExprInstantiateTask["visit"](type), PsKernelList["cons"](PsKernelExprInstantiateTask["visit"](body), PsKernelList["cons"](PsKernelExprInstantiateTask["rebuild"](PsKernelBindingTask["lam"](name, binder)), tasks))), values));
    }
    case "forallE": {
        const name = __ps$match$0.name;
        const type = __ps$match$0.type;
        const body = __ps$match$0.body;
        const binder = __ps$match$0.binder;
        return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, PsKernelList["cons"](PsKernelExprInstantiateTask["visit"](type), PsKernelList["cons"](PsKernelExprInstantiateTask["visit"](body), PsKernelList["cons"](PsKernelExprInstantiateTask["rebuild"](PsKernelBindingTask["forallE"](name, binder)), tasks))), values));
    }
    case "letE": {
        const name = __ps$match$0.name;
        const type = __ps$match$0.type;
        const val = __ps$match$0.value;
        const body = __ps$match$0.body;
        return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, PsKernelList["cons"](PsKernelExprInstantiateTask["visit"](type), PsKernelList["cons"](PsKernelExprInstantiateTask["visit"](val), PsKernelList["cons"](PsKernelExprInstantiateTask["visit"](body), PsKernelList["cons"](PsKernelExprInstantiateTask["rebuild"](PsKernelBindingTask["letE"](name)), tasks)))), values));
    }
    case "lit": {
        const _wild0 = __ps$match$0.value;
        return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, tasks, PsKernelList["cons"](value, values)));
    }
    case "proj": {
        const family = __ps$match$0.family;
        const index = __ps$match$0.index;
        const val = __ps$match$0.value;
        return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, PsKernelList["cons"](PsKernelExprInstantiateTask["visit"](val), PsKernelList["cons"](PsKernelExprInstantiateTask["rebuild"](PsKernelBindingTask["proj"](family, index)), tasks)), values));
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelExprInstantiateVisit, __ps$impl$psKernelExprInstantiateVisit);
export function psKernelExprInstantiateTaskStep(names, levels, task, rest, values) { return __ps$run(__ps$impl$psKernelExprInstantiateTaskStep(names, levels, task, rest, values)); }
function* __ps$impl$psKernelExprInstantiateTaskStep(names, levels, task, rest, values) { return (yield* (function* () { const __ps$match$0 = task; switch (__ps$match$0[__ps$tag$43]) {
    case "validate": {
        const target = __ps$match$0.target;
        const current = __ps$match$0.state;
        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelInstantiateStep, current)); switch (__ps$match$0[__ps$tag$42]) {
            case "next": {
                const next = __ps$match$0.state;
                return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, PsKernelList["cons"](PsKernelExprInstantiateTask["validate"](target, next), rest), values));
            }
            case "final": {
                const result = __ps$match$0.result;
                return (yield* (function* () { const __ps$match$0 = result; switch (__ps$match$0[__ps$tag$41]) {
                    case "outOfFuel": return (yield* __ps$invoke(psKernelExprInstantiateLevelError, result));
                    case "invalidState": return (yield* __ps$invoke(psKernelExprInstantiateLevelError, result));
                    case "invalidParameters": return (yield* __ps$invoke(psKernelExprInstantiateLevelError, result));
                    case "undeclaredParameter": return (yield* __ps$invoke(psKernelExprInstantiateLevelError, result));
                    case "done": {
                        const unused = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, PsKernelList["cons"](PsKernelExprInstantiateTask["visit"](target), rest), values));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "visit": {
        const value = __ps$match$0.value;
        return (yield* __ps$invoke(psKernelExprInstantiateVisit, names, levels, value, rest, values));
    }
    case "sort": {
        const current = __ps$match$0.state;
        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelInstantiateStep, current)); switch (__ps$match$0[__ps$tag$42]) {
            case "next": {
                const next = __ps$match$0.state;
                return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, PsKernelList["cons"](PsKernelExprInstantiateTask["sort"](next), rest), values));
            }
            case "final": {
                const result = __ps$match$0.result;
                return (yield* (function* () { const __ps$match$0 = result; switch (__ps$match$0[__ps$tag$41]) {
                    case "outOfFuel": return (yield* __ps$invoke(psKernelExprInstantiateLevelError, result));
                    case "invalidState": return (yield* __ps$invoke(psKernelExprInstantiateLevelError, result));
                    case "invalidParameters": return (yield* __ps$invoke(psKernelExprInstantiateLevelError, result));
                    case "undeclaredParameter": return (yield* __ps$invoke(psKernelExprInstantiateLevelError, result));
                    case "done": {
                        const value = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, rest, PsKernelList["cons"](PsKernelExpr["sortE"](value), values)));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "constant": {
        const name = __ps$match$0.name;
        const remaining = __ps$match$0.remaining;
        const reversed = __ps$match$0.reversed;
        return (yield* (function* () { const __ps$match$0 = remaining; switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, PsKernelList["cons"](PsKernelExprInstantiateTask["constantReverse"](name, reversed, PsKernelList["nil"]()), rest), values));
            case "cons": {
                const level = __ps$match$0.head;
                const tail = __ps$match$0.tail;
                return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, PsKernelList["cons"](PsKernelExprInstantiateTask["constantLevel"](name, tail, reversed, (yield* __ps$invoke(psKernelLevelInstantiateStart, names, levels, level))), rest), values));
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "constantLevel": {
        const name = __ps$match$0.name;
        const remaining = __ps$match$0.remaining;
        const reversed = __ps$match$0.reversed;
        const current = __ps$match$0.state;
        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelInstantiateStep, current)); switch (__ps$match$0[__ps$tag$42]) {
            case "next": {
                const next = __ps$match$0.state;
                return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, PsKernelList["cons"](PsKernelExprInstantiateTask["constantLevel"](name, remaining, reversed, next), rest), values));
            }
            case "final": {
                const result = __ps$match$0.result;
                return (yield* (function* () { const __ps$match$0 = result; switch (__ps$match$0[__ps$tag$41]) {
                    case "outOfFuel": return (yield* __ps$invoke(psKernelExprInstantiateLevelError, result));
                    case "invalidState": return (yield* __ps$invoke(psKernelExprInstantiateLevelError, result));
                    case "invalidParameters": return (yield* __ps$invoke(psKernelExprInstantiateLevelError, result));
                    case "undeclaredParameter": return (yield* __ps$invoke(psKernelExprInstantiateLevelError, result));
                    case "done": {
                        const value = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, PsKernelList["cons"](PsKernelExprInstantiateTask["constant"](name, remaining, PsKernelList["cons"](value, reversed)), rest), values));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "constantReverse": {
        const name = __ps$match$0.name;
        const remaining = __ps$match$0.remaining;
        const _arguments = __ps$match$0.levels;
        return (yield* (function* () { const __ps$match$0 = remaining; switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, rest, PsKernelList["cons"](PsKernelExpr["constE"](name, _arguments), values)));
            case "cons": {
                const value = __ps$match$0.head;
                const tail = __ps$match$0.tail;
                return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, PsKernelList["cons"](PsKernelExprInstantiateTask["constantReverse"](name, tail, PsKernelList["cons"](value, _arguments)), rest), values));
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "rebuild": {
        const rebuild = __ps$match$0.task;
        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelBindingRebuild, rebuild, PsKernelList["nil"](), values)); switch (__ps$match$0[__ps$tag$26]) {
            case "next": {
                const next = __ps$match$0.state;
                return (yield* (function* () { const __ps$match$0 = next; switch (__ps$match$0[__ps$tag$24]) {
                    case "state": {
                        const unusedTasks = __ps$match$0.tasks;
                        const updated = __ps$match$0.values;
                        return (yield* __ps$invoke(psKernelExprInstantiateNext, names, levels, rest, updated));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "final": {
                const _wild0 = __ps$match$0.result;
                return PsKernelExprInstantiateStep["final"](PsKernelExprInstantiateResult["invalidState"]);
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelExprInstantiateTaskStep, __ps$impl$psKernelExprInstantiateTaskStep);
export function psKernelExprInstantiateStep(state) { return __ps$run(__ps$impl$psKernelExprInstantiateStep(state)); }
function* __ps$impl$psKernelExprInstantiateStep(state) { return (yield* (function* () { const __ps$match$0 = state; switch (__ps$match$0[__ps$tag$44]) {
    case "state": {
        const names = __ps$match$0.names;
        const levels = __ps$match$0.levels;
        const tasks = __ps$match$0.tasks;
        const values = __ps$match$0.values;
        return (yield* (function* () { const __ps$match$0 = tasks; switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelBindingFinish, values)); switch (__ps$match$0[__ps$tag$25]) {
                case "outOfFuel": return PsKernelExprInstantiateStep["final"](PsKernelExprInstantiateResult["invalidState"]);
                case "invalidState": return PsKernelExprInstantiateStep["final"](PsKernelExprInstantiateResult["invalidState"]);
                case "invalidScope": return PsKernelExprInstantiateStep["final"](PsKernelExprInstantiateResult["invalidState"]);
                case "done": {
                    const value = __ps$match$0.value;
                    return PsKernelExprInstantiateStep["final"](PsKernelExprInstantiateResult["done"](value));
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
            case "cons": {
                const task = __ps$match$0.head;
                const rest = __ps$match$0.tail;
                return (yield* __ps$invoke(psKernelExprInstantiateTaskStep, names, levels, task, rest, values));
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelExprInstantiateStep, __ps$impl$psKernelExprInstantiateStep);
export function psKernelExprInstantiateStart(names, levels, target) { return __ps$run(__ps$impl$psKernelExprInstantiateStart(names, levels, target)); }
function* __ps$impl$psKernelExprInstantiateStart(names, levels, target) { return PsKernelExprInstantiateState["state"](names, levels, PsKernelList["cons"](PsKernelExprInstantiateTask["validate"](target, (yield* __ps$invoke(psKernelLevelInstantiateStart, names, levels, PsKernelLevel["zero"]))), PsKernelList["nil"]()), PsKernelList["nil"]()); }
__ps$implementations.set(psKernelExprInstantiateStart, __ps$impl$psKernelExprInstantiateStart);
export function psKernelExprInstantiateRun(fuel, __ps_eta_0) { return __ps$run(__ps$impl$psKernelExprInstantiateRun(fuel, __ps_eta_0)); }
function* __ps$impl$psKernelExprInstantiateRun(fuel, __ps_eta_0) { return (yield* (function* () { const __ps$match$0 = fuel; switch (__ps$match$0[__ps$tag$11]) {
    case "stop": return (yield* (function* () { {
        const state = __ps_eta_0;
        return PsKernelExprInstantiateResult["outOfFuel"];
    } })());
    case "more": {
        const remaining = __ps$match$0.remaining;
        return (yield* (function* () { {
            const state = __ps_eta_0;
            return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelExprInstantiateStep, state)); switch (__ps$match$0[__ps$tag$46]) {
                case "next": {
                    const next = __ps$match$0.state;
                    return (yield* (function* () { {
                        const smaller = __ps$wrap(function* (_$3) { return (yield* __ps$invoke(psKernelExprInstantiateRun, remaining, _$3)); });
                        return (yield* __ps$invoke(smaller, next));
                    } })());
                }
                case "final": {
                    const result = __ps$match$0.result;
                    return result;
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
        } })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelExprInstantiateRun, __ps$impl$psKernelExprInstantiateRun);
export function psKernelDefinitionName(entry) { while (true) {
    {
        const __ps$match$0 = entry;
        switch (__ps$match$0[__ps$tag$47]) {
            case "definition": {
                const name = __ps$match$0.name;
                const unusedType = __ps$match$0.type;
                const unusedValue = __ps$match$0.value;
                return name;
            }
            case "polymorphic": {
                const name = __ps$match$0.name;
                const unusedParameters = __ps$match$0.parameters;
                const unusedType = __ps$match$0.type;
                const unusedValue = __ps$match$0.value;
                return name;
            }
        }
        throw new Error("invalid ProofScript constructor tag");
    }
} }
export function psKernelDefinitionParameters(entry) { while (true) {
    {
        const __ps$match$0 = entry;
        switch (__ps$match$0[__ps$tag$47]) {
            case "definition": {
                const unusedName = __ps$match$0.name;
                const unusedType = __ps$match$0.type;
                const unusedValue = __ps$match$0.value;
                return PsKernelList["nil"]();
            }
            case "polymorphic": {
                const unusedName = __ps$match$0.name;
                const parameters = __ps$match$0.parameters;
                const unusedType = __ps$match$0.type;
                const unusedValue = __ps$match$0.value;
                return parameters;
            }
        }
        throw new Error("invalid ProofScript constructor tag");
    }
} }
export function psKernelDefinitionType(entry) { while (true) {
    {
        const __ps$match$0 = entry;
        switch (__ps$match$0[__ps$tag$47]) {
            case "definition": {
                const unusedName = __ps$match$0.name;
                const type = __ps$match$0.type;
                const unusedValue = __ps$match$0.value;
                return type;
            }
            case "polymorphic": {
                const unusedName = __ps$match$0.name;
                const unusedParameters = __ps$match$0.parameters;
                const type = __ps$match$0.type;
                const unusedValue = __ps$match$0.value;
                return type;
            }
        }
        throw new Error("invalid ProofScript constructor tag");
    }
} }
export function psKernelDefinitionValue(entry) { while (true) {
    {
        const __ps$match$0 = entry;
        switch (__ps$match$0[__ps$tag$47]) {
            case "definition": {
                const unusedName = __ps$match$0.name;
                const unusedType = __ps$match$0.type;
                const value = __ps$match$0.value;
                return value;
            }
            case "polymorphic": {
                const unusedName = __ps$match$0.name;
                const unusedParameters = __ps$match$0.parameters;
                const unusedType = __ps$match$0.type;
                const value = __ps$match$0.value;
                return value;
            }
        }
        throw new Error("invalid ProofScript constructor tag");
    }
} }
export function psKernelTypingDeclarations(context) { while (true) {
    {
        const __ps$match$0 = context;
        switch (__ps$match$0[__ps$tag$48]) {
            case "context": {
                const declarations = __ps$match$0.declarations;
                const unusedParameters = __ps$match$0.parameters;
                return declarations;
            }
        }
        throw new Error("invalid ProofScript constructor tag");
    }
} }
export function psKernelTypingParameters(context) { while (true) {
    {
        const __ps$match$0 = context;
        switch (__ps$match$0[__ps$tag$48]) {
            case "context": {
                const unusedDeclarations = __ps$match$0.declarations;
                const parameters = __ps$match$0.parameters;
                return parameters;
            }
        }
        throw new Error("invalid ProofScript constructor tag");
    }
} }
export function psKernelLookupStep(state) { return __ps$run(__ps$impl$psKernelLookupStep(state)); }
function* __ps$impl$psKernelLookupStep(state) { return (yield* (function* () { const __ps$match$0 = state; switch (__ps$match$0[__ps$tag$50]) {
    case "search": {
        const name = __ps$match$0.name;
        const entries = __ps$match$0.entries;
        return (yield* (function* () { const __ps$match$0 = entries; switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return PsKernelLookupStep["missing"];
            case "cons": {
                const entry = __ps$match$0.head;
                const rest = __ps$match$0.tail;
                return PsKernelLookupStep["next"](PsKernelLookupState["compare"](name, entry, rest, PsKernelList["cons"](PsKernelOrderTask["name"](name, (yield* __ps$invoke(psKernelDefinitionName, entry))), PsKernelList["nil"]())));
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "compare": {
        const name = __ps$match$0.name;
        const entry = __ps$match$0.entry;
        const rest = __ps$match$0.rest;
        const tasks = __ps$match$0.tasks;
        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelOrderStep, tasks)); switch (__ps$match$0[__ps$tag$28]) {
            case "next": {
                const next = __ps$match$0.tasks;
                return PsKernelLookupStep["next"](PsKernelLookupState["compare"](name, entry, rest, next));
            }
            case "done": {
                const order = __ps$match$0.order;
                return (yield* (function* () { const __ps$match$0 = order; switch (__ps$match$0[__ps$tag$13]) {
                    case "less": return PsKernelLookupStep["next"](PsKernelLookupState["search"](name, rest));
                    case "same": return PsKernelLookupStep["found"](entry);
                    case "greater": return PsKernelLookupStep["next"](PsKernelLookupState["search"](name, rest));
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "invalidState": return PsKernelLookupStep["invalidState"];
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelLookupStep, __ps$impl$psKernelLookupStep);
export function psKernelReduceReject(error) { while (true) {
    return PsKernelReduceStep["final"](PsKernelReduceResult["rejected"](error));
} }
export function psKernelReduceNext(env, tasks, values) { while (true) {
    return PsKernelReduceStep["next"](PsKernelReduceState["state"](env, tasks, values));
} }
export function psKernelReducePush(env, tasks, values, value) { return __ps$run(__ps$impl$psKernelReducePush(env, tasks, values, value)); }
function* __ps$impl$psKernelReducePush(env, tasks, values, value) { return (yield* __ps$invoke(psKernelReduceNext, env, tasks, PsKernelList["cons"](value, values))); }
__ps$implementations.set(psKernelReducePush, __ps$impl$psKernelReducePush);
export function psKernelReduceWhnf(env, tasks, values, value) { return __ps$run(__ps$impl$psKernelReduceWhnf(env, tasks, values, value)); }
function* __ps$impl$psKernelReduceWhnf(env, tasks, values, value) { return (yield* (function* () { const __ps$match$0 = value; switch (__ps$match$0[__ps$tag$21]) {
    case "bvar": {
        const _wild0 = __ps$match$0.index;
        return (yield* __ps$invoke(psKernelReducePush, env, tasks, values, value));
    }
    case "fvar": {
        const unused = __ps$match$0.id;
        return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["invalidScope"]));
    }
    case "sortE": {
        const _wild0 = __ps$match$0.level;
        return (yield* __ps$invoke(psKernelReducePush, env, tasks, values, value));
    }
    case "constE": {
        const name = __ps$match$0.name;
        const levels = __ps$match$0.levels;
        return (yield* __ps$invoke(psKernelReduceNext, env, PsKernelList["cons"](PsKernelReduceTask["lookup"](levels, PsKernelLookupState["search"](name, env)), tasks), values));
    }
    case "app": {
        const fn = __ps$match$0.fn;
        const arg = __ps$match$0.arg;
        return (yield* __ps$invoke(psKernelReduceNext, env, PsKernelList["cons"](PsKernelReduceTask["whnf"](fn), PsKernelList["cons"](PsKernelReduceTask["apply"](arg), tasks)), values));
    }
    case "lam": {
        const _wild0 = __ps$match$0.name;
        const _wild1 = __ps$match$0.type;
        const _wild2 = __ps$match$0.body;
        const _wild3 = __ps$match$0.binder;
        return (yield* __ps$invoke(psKernelReducePush, env, tasks, values, value));
    }
    case "forallE": {
        const _wild0 = __ps$match$0.name;
        const _wild1 = __ps$match$0.type;
        const _wild2 = __ps$match$0.body;
        const _wild3 = __ps$match$0.binder;
        return (yield* __ps$invoke(psKernelReducePush, env, tasks, values, value));
    }
    case "letE": {
        const unusedName = __ps$match$0.name;
        const unusedType = __ps$match$0.type;
        const val = __ps$match$0.value;
        const body = __ps$match$0.body;
        return (yield* __ps$invoke(psKernelReduceNext, env, PsKernelList["cons"](PsKernelReduceTask["binding"]((yield* __ps$invoke(psKernelBindingStart, PsKernelBindingMode["instantiate"](val), PsKernelNatural["zero"], body))), PsKernelList["cons"](PsKernelReduceTask["resumeWhnf"], tasks)), values));
    }
    case "lit": {
        const unused = __ps$match$0.value;
        return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["unsupported"]));
    }
    case "proj": {
        const unusedName = __ps$match$0.family;
        const unusedIndex = __ps$match$0.index;
        const unusedValue = __ps$match$0.value;
        return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["unsupported"]));
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelReduceWhnf, __ps$impl$psKernelReduceWhnf);
export function psKernelReduceValueTask(env, task, tasks, values) { return __ps$run(__ps$impl$psKernelReduceValueTask(env, task, tasks, values)); }
function* __ps$impl$psKernelReduceValueTask(env, task, tasks, values) { return (yield* (function* () { const __ps$match$0 = values; switch (__ps$match$0[__ps$tag$8]) {
    case "nil": return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["invalidState"]));
    case "cons": {
        const top = __ps$match$0.head;
        const rest = __ps$match$0.tail;
        return (yield* (function* () { const __ps$match$0 = task; switch (__ps$match$0[__ps$tag$52]) {
            case "whnf": {
                const _wild0 = __ps$match$0.value;
                return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["invalidState"]));
            }
            case "apply": {
                const arg = __ps$match$0.arg;
                return (yield* (function* () { const __ps$match$0 = top; switch (__ps$match$0[__ps$tag$21]) {
                    case "bvar": {
                        const _wild0 = __ps$match$0.index;
                        return (yield* __ps$invoke(psKernelReducePush, env, tasks, rest, PsKernelExpr["app"](top, arg)));
                    }
                    case "fvar": {
                        const _wild0 = __ps$match$0.id;
                        return (yield* __ps$invoke(psKernelReducePush, env, tasks, rest, PsKernelExpr["app"](top, arg)));
                    }
                    case "sortE": {
                        const _wild0 = __ps$match$0.level;
                        return (yield* __ps$invoke(psKernelReducePush, env, tasks, rest, PsKernelExpr["app"](top, arg)));
                    }
                    case "constE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.levels;
                        return (yield* __ps$invoke(psKernelReducePush, env, tasks, rest, PsKernelExpr["app"](top, arg)));
                    }
                    case "app": {
                        const _wild0 = __ps$match$0.fn;
                        const _wild1 = __ps$match$0.arg;
                        return (yield* __ps$invoke(psKernelReducePush, env, tasks, rest, PsKernelExpr["app"](top, arg)));
                    }
                    case "lam": {
                        const unusedName = __ps$match$0.name;
                        const unusedType = __ps$match$0.type;
                        const body = __ps$match$0.body;
                        const unusedBinder = __ps$match$0.binder;
                        return (yield* __ps$invoke(psKernelReduceNext, env, PsKernelList["cons"](PsKernelReduceTask["binding"]((yield* __ps$invoke(psKernelBindingStart, PsKernelBindingMode["instantiate"](arg), PsKernelNatural["zero"], body))), PsKernelList["cons"](PsKernelReduceTask["resumeWhnf"], tasks)), rest));
                    }
                    case "forallE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.body;
                        const _wild3 = __ps$match$0.binder;
                        return (yield* __ps$invoke(psKernelReducePush, env, tasks, rest, PsKernelExpr["app"](top, arg)));
                    }
                    case "letE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.value;
                        const _wild3 = __ps$match$0.body;
                        return (yield* __ps$invoke(psKernelReducePush, env, tasks, rest, PsKernelExpr["app"](top, arg)));
                    }
                    case "lit": {
                        const _wild0 = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelReducePush, env, tasks, rest, PsKernelExpr["app"](top, arg)));
                    }
                    case "proj": {
                        const _wild0 = __ps$match$0.family;
                        const _wild1 = __ps$match$0.index;
                        const _wild2 = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelReducePush, env, tasks, rest, PsKernelExpr["app"](top, arg)));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "lookup": {
                const _wild0 = __ps$match$0.levels;
                const _wild1 = __ps$match$0.state;
                return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["invalidState"]));
            }
            case "instantiate": {
                const _wild0 = __ps$match$0.state;
                return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["invalidState"]));
            }
            case "binding": {
                const _wild0 = __ps$match$0.state;
                return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["invalidState"]));
            }
            case "resumeWhnf": return (yield* __ps$invoke(psKernelReduceNext, env, PsKernelList["cons"](PsKernelReduceTask["whnf"](top), tasks), rest));
            case "normal": {
                const _wild0 = __ps$match$0.value;
                return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["invalidState"]));
            }
            case "expand": return (yield* (function* () { const __ps$match$0 = top; switch (__ps$match$0[__ps$tag$21]) {
                case "bvar": {
                    const _wild0 = __ps$match$0.index;
                    return (yield* __ps$invoke(psKernelReducePush, env, tasks, rest, top));
                }
                case "fvar": {
                    const _wild0 = __ps$match$0.id;
                    return (yield* __ps$invoke(psKernelReducePush, env, tasks, rest, top));
                }
                case "sortE": {
                    const _wild0 = __ps$match$0.level;
                    return (yield* __ps$invoke(psKernelReducePush, env, tasks, rest, top));
                }
                case "constE": {
                    const _wild0 = __ps$match$0.name;
                    const _wild1 = __ps$match$0.levels;
                    return (yield* __ps$invoke(psKernelReducePush, env, tasks, rest, top));
                }
                case "app": {
                    const fn = __ps$match$0.fn;
                    const arg = __ps$match$0.arg;
                    return (yield* __ps$invoke(psKernelReduceNext, env, PsKernelList["cons"](PsKernelReduceTask["normal"](fn), PsKernelList["cons"](PsKernelReduceTask["normal"](arg), PsKernelList["cons"](PsKernelReduceTask["app"], tasks))), rest));
                }
                case "lam": {
                    const name = __ps$match$0.name;
                    const type = __ps$match$0.type;
                    const body = __ps$match$0.body;
                    const binder = __ps$match$0.binder;
                    return (yield* __ps$invoke(psKernelReduceNext, env, PsKernelList["cons"](PsKernelReduceTask["normal"](type), PsKernelList["cons"](PsKernelReduceTask["normal"](body), PsKernelList["cons"](PsKernelReduceTask["lam"](name, binder), tasks))), rest));
                }
                case "forallE": {
                    const name = __ps$match$0.name;
                    const type = __ps$match$0.type;
                    const body = __ps$match$0.body;
                    const binder = __ps$match$0.binder;
                    return (yield* __ps$invoke(psKernelReduceNext, env, PsKernelList["cons"](PsKernelReduceTask["normal"](type), PsKernelList["cons"](PsKernelReduceTask["normal"](body), PsKernelList["cons"](PsKernelReduceTask["forallE"](name, binder), tasks))), rest));
                }
                case "letE": {
                    const _wild0 = __ps$match$0.name;
                    const _wild1 = __ps$match$0.type;
                    const _wild2 = __ps$match$0.value;
                    const _wild3 = __ps$match$0.body;
                    return (yield* __ps$invoke(psKernelReducePush, env, tasks, rest, top));
                }
                case "lit": {
                    const _wild0 = __ps$match$0.value;
                    return (yield* __ps$invoke(psKernelReducePush, env, tasks, rest, top));
                }
                case "proj": {
                    const _wild0 = __ps$match$0.family;
                    const _wild1 = __ps$match$0.index;
                    const _wild2 = __ps$match$0.value;
                    return (yield* __ps$invoke(psKernelReducePush, env, tasks, rest, top));
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
            case "app": return (yield* (function* () { const __ps$match$0 = rest; switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["invalidState"]));
                case "cons": {
                    const fn = __ps$match$0.head;
                    const tail = __ps$match$0.tail;
                    return (yield* __ps$invoke(psKernelReducePush, env, tasks, tail, PsKernelExpr["app"](fn, top)));
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
            case "lam": {
                const name = __ps$match$0.name;
                const binder = __ps$match$0.binder;
                return (yield* (function* () { const __ps$match$0 = rest; switch (__ps$match$0[__ps$tag$8]) {
                    case "nil": return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["invalidState"]));
                    case "cons": {
                        const type = __ps$match$0.head;
                        const tail = __ps$match$0.tail;
                        return (yield* __ps$invoke(psKernelReducePush, env, tasks, tail, PsKernelExpr["lam"](name, type, top, binder)));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "forallE": {
                const name = __ps$match$0.name;
                const binder = __ps$match$0.binder;
                return (yield* (function* () { const __ps$match$0 = rest; switch (__ps$match$0[__ps$tag$8]) {
                    case "nil": return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["invalidState"]));
                    case "cons": {
                        const type = __ps$match$0.head;
                        const tail = __ps$match$0.tail;
                        return (yield* __ps$invoke(psKernelReducePush, env, tasks, tail, PsKernelExpr["forallE"](name, type, top, binder)));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelReduceValueTask, __ps$impl$psKernelReduceValueTask);
export function psKernelReduceStep(state) { return __ps$run(__ps$impl$psKernelReduceStep(state)); }
function* __ps$impl$psKernelReduceStep(state) { return (yield* (function* () { const __ps$match$0 = state; switch (__ps$match$0[__ps$tag$53]) {
    case "state": {
        const env = __ps$match$0.environment;
        const tasks = __ps$match$0.tasks;
        const values = __ps$match$0.values;
        return (yield* (function* () { const __ps$match$0 = tasks; switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return (yield* (function* () { const __ps$match$0 = values; switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["invalidState"]));
                case "cons": {
                    const value = __ps$match$0.head;
                    const rest = __ps$match$0.tail;
                    return (yield* (function* () { const __ps$match$0 = rest; switch (__ps$match$0[__ps$tag$8]) {
                        case "nil": return PsKernelReduceStep["final"](PsKernelReduceResult["done"](value));
                        case "cons": {
                            const _wild0 = __ps$match$0.head;
                            const _wild1 = __ps$match$0.tail;
                            return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["invalidState"]));
                        }
                    } throw new Error("invalid ProofScript constructor tag"); })());
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
            case "cons": {
                const task = __ps$match$0.head;
                const rest = __ps$match$0.tail;
                return (yield* (function* () { const __ps$match$0 = task; switch (__ps$match$0[__ps$tag$52]) {
                    case "whnf": {
                        const value = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelReduceWhnf, env, rest, values, value));
                    }
                    case "apply": {
                        const _wild0 = __ps$match$0.arg;
                        return (yield* __ps$invoke(psKernelReduceValueTask, env, task, rest, values));
                    }
                    case "lookup": {
                        const levels = __ps$match$0.levels;
                        const current = __ps$match$0.state;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLookupStep, current)); switch (__ps$match$0[__ps$tag$51]) {
                            case "next": {
                                const next = __ps$match$0.state;
                                return (yield* __ps$invoke(psKernelReduceNext, env, PsKernelList["cons"](PsKernelReduceTask["lookup"](levels, next), rest), values));
                            }
                            case "found": {
                                const entry = __ps$match$0.entry;
                                return (yield* __ps$invoke(psKernelReduceNext, env, PsKernelList["cons"](PsKernelReduceTask["instantiate"]((yield* __ps$invoke(psKernelExprInstantiateStart, (yield* __ps$invoke(psKernelDefinitionParameters, entry)), levels, (yield* __ps$invoke(psKernelDefinitionValue, entry))))), PsKernelList["cons"](PsKernelReduceTask["resumeWhnf"], rest)), values));
                            }
                            case "missing": return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["unknownConstant"]));
                            case "invalidState": return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["invalidState"]));
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "instantiate": {
                        const current = __ps$match$0.state;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelExprInstantiateStep, current)); switch (__ps$match$0[__ps$tag$46]) {
                            case "next": {
                                const next = __ps$match$0.state;
                                return (yield* __ps$invoke(psKernelReduceNext, env, PsKernelList["cons"](PsKernelReduceTask["instantiate"](next), rest), values));
                            }
                            case "final": {
                                const result = __ps$match$0.result;
                                return (yield* (function* () { const __ps$match$0 = result; switch (__ps$match$0[__ps$tag$45]) {
                                    case "outOfFuel": return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["invalidState"]));
                                    case "invalidState": return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["invalidState"]));
                                    case "invalidParameters": return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["invalidUniverse"]));
                                    case "undeclaredParameter": return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["invalidUniverse"]));
                                    case "done": {
                                        const value = __ps$match$0.value;
                                        return (yield* __ps$invoke(psKernelReducePush, env, rest, values, value));
                                    }
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "binding": {
                        const current = __ps$match$0.state;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelBindingStep, current)); switch (__ps$match$0[__ps$tag$26]) {
                            case "next": {
                                const next = __ps$match$0.state;
                                return (yield* __ps$invoke(psKernelReduceNext, env, PsKernelList["cons"](PsKernelReduceTask["binding"](next), rest), values));
                            }
                            case "final": {
                                const result = __ps$match$0.result;
                                return (yield* (function* () { const __ps$match$0 = result; switch (__ps$match$0[__ps$tag$25]) {
                                    case "outOfFuel": return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["invalidState"]));
                                    case "invalidState": return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["invalidState"]));
                                    case "invalidScope": return (yield* __ps$invoke(psKernelReduceReject, PsKernelCheckError["invalidScope"]));
                                    case "done": {
                                        const value = __ps$match$0.value;
                                        return (yield* __ps$invoke(psKernelReducePush, env, rest, values, value));
                                    }
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "resumeWhnf": return (yield* __ps$invoke(psKernelReduceValueTask, env, task, rest, values));
                    case "normal": {
                        const value = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelReduceNext, env, PsKernelList["cons"](PsKernelReduceTask["whnf"](value), PsKernelList["cons"](PsKernelReduceTask["expand"], rest)), values));
                    }
                    case "expand": return (yield* __ps$invoke(psKernelReduceValueTask, env, task, rest, values));
                    case "app": return (yield* __ps$invoke(psKernelReduceValueTask, env, task, rest, values));
                    case "lam": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.binder;
                        return (yield* __ps$invoke(psKernelReduceValueTask, env, task, rest, values));
                    }
                    case "forallE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.binder;
                        return (yield* __ps$invoke(psKernelReduceValueTask, env, task, rest, values));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelReduceStep, __ps$impl$psKernelReduceStep);
export function psKernelWhnfStart(env, value) { while (true) {
    return PsKernelReduceState["state"](env, PsKernelList["cons"](PsKernelReduceTask["whnf"](value), PsKernelList["nil"]()), PsKernelList["nil"]());
} }
export function psKernelNormalStart(env, value) { while (true) {
    return PsKernelReduceState["state"](env, PsKernelList["cons"](PsKernelReduceTask["normal"](value), PsKernelList["nil"]()), PsKernelList["nil"]());
} }
export function psKernelReduceRun(fuel, __ps_eta_0) { return __ps$run(__ps$impl$psKernelReduceRun(fuel, __ps_eta_0)); }
function* __ps$impl$psKernelReduceRun(fuel, __ps_eta_0) { return (yield* (function* () { const __ps$match$0 = fuel; switch (__ps$match$0[__ps$tag$11]) {
    case "stop": return (yield* (function* () { {
        const state = __ps_eta_0;
        return PsKernelReduceResult["outOfFuel"];
    } })());
    case "more": {
        const remaining = __ps$match$0.remaining;
        return (yield* (function* () { {
            const state = __ps_eta_0;
            return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelReduceStep, state)); switch (__ps$match$0[__ps$tag$55]) {
                case "next": {
                    const next = __ps$match$0.state;
                    return (yield* (function* () { {
                        const smaller = __ps$wrap(function* (_$3) { return (yield* __ps$invoke(psKernelReduceRun, remaining, _$3)); });
                        return (yield* __ps$invoke(smaller, next));
                    } })());
                }
                case "final": {
                    const result = __ps$match$0.result;
                    return result;
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
        } })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelReduceRun, __ps$impl$psKernelReduceRun);
export function psKernelConversionReject(error) { while (true) {
    return PsKernelConversionStep["final"](PsKernelConversionResult["rejected"](error));
} }
export function psKernelConversionTasks(tasks) { while (true) {
    return PsKernelConversionStep["next"](PsKernelConversionState["compare"](tasks));
} }
export function psKernelConversionExpr(left, right, tasks) { return __ps$run(__ps$impl$psKernelConversionExpr(left, right, tasks)); }
function* __ps$impl$psKernelConversionExpr(left, right, tasks) { return (yield* (function* () { const __ps$match$0 = left; switch (__ps$match$0[__ps$tag$21]) {
    case "bvar": {
        const index = __ps$match$0.index;
        return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$21]) {
            case "bvar": {
                const other = __ps$match$0.index;
                return (yield* __ps$invoke(psKernelConversionTasks, PsKernelList["cons"](PsKernelConversionTask["natural"](PsKernelNumericState["order"](index, other, PsKernelOrder["same"])), tasks)));
            }
            case "fvar": {
                const _wild0 = __ps$match$0.id;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "sortE": {
                const _wild0 = __ps$match$0.level;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "constE": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.levels;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "app": {
                const _wild0 = __ps$match$0.fn;
                const _wild1 = __ps$match$0.arg;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "lam": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.type;
                const _wild2 = __ps$match$0.body;
                const _wild3 = __ps$match$0.binder;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "forallE": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.type;
                const _wild2 = __ps$match$0.body;
                const _wild3 = __ps$match$0.binder;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "letE": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.type;
                const _wild2 = __ps$match$0.value;
                const _wild3 = __ps$match$0.body;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "lit": {
                const _wild0 = __ps$match$0.value;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "proj": {
                const _wild0 = __ps$match$0.family;
                const _wild1 = __ps$match$0.index;
                const _wild2 = __ps$match$0.value;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "fvar": {
        const _wild0 = __ps$match$0.id;
        return (yield* __ps$invoke(psKernelConversionReject, PsKernelCheckError["unsupported"]));
    }
    case "sortE": {
        const level = __ps$match$0.level;
        return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$21]) {
            case "bvar": {
                const _wild0 = __ps$match$0.index;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "fvar": {
                const _wild0 = __ps$match$0.id;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "sortE": {
                const other = __ps$match$0.level;
                return (yield* __ps$invoke(psKernelConversionTasks, PsKernelList["cons"](PsKernelConversionTask["level"]((yield* __ps$invoke(psKernelLevelCheckStart, level, other))), tasks)));
            }
            case "constE": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.levels;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "app": {
                const _wild0 = __ps$match$0.fn;
                const _wild1 = __ps$match$0.arg;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "lam": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.type;
                const _wild2 = __ps$match$0.body;
                const _wild3 = __ps$match$0.binder;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "forallE": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.type;
                const _wild2 = __ps$match$0.body;
                const _wild3 = __ps$match$0.binder;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "letE": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.type;
                const _wild2 = __ps$match$0.value;
                const _wild3 = __ps$match$0.body;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "lit": {
                const _wild0 = __ps$match$0.value;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "proj": {
                const _wild0 = __ps$match$0.family;
                const _wild1 = __ps$match$0.index;
                const _wild2 = __ps$match$0.value;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "constE": {
        const _wild0 = __ps$match$0.name;
        const _wild1 = __ps$match$0.levels;
        return (yield* __ps$invoke(psKernelConversionReject, PsKernelCheckError["unsupported"]));
    }
    case "app": {
        const fn = __ps$match$0.fn;
        const arg = __ps$match$0.arg;
        return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$21]) {
            case "bvar": {
                const _wild0 = __ps$match$0.index;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "fvar": {
                const _wild0 = __ps$match$0.id;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "sortE": {
                const _wild0 = __ps$match$0.level;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "constE": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.levels;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "app": {
                const otherFn = __ps$match$0.fn;
                const otherArg = __ps$match$0.arg;
                return (yield* __ps$invoke(psKernelConversionTasks, PsKernelList["cons"](PsKernelConversionTask["expr"](fn, otherFn), PsKernelList["cons"](PsKernelConversionTask["expr"](arg, otherArg), tasks))));
            }
            case "lam": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.type;
                const _wild2 = __ps$match$0.body;
                const _wild3 = __ps$match$0.binder;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "forallE": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.type;
                const _wild2 = __ps$match$0.body;
                const _wild3 = __ps$match$0.binder;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "letE": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.type;
                const _wild2 = __ps$match$0.value;
                const _wild3 = __ps$match$0.body;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "lit": {
                const _wild0 = __ps$match$0.value;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "proj": {
                const _wild0 = __ps$match$0.family;
                const _wild1 = __ps$match$0.index;
                const _wild2 = __ps$match$0.value;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "lam": {
        const unusedName = __ps$match$0.name;
        const type = __ps$match$0.type;
        const body = __ps$match$0.body;
        const unusedBinder = __ps$match$0.binder;
        return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$21]) {
            case "bvar": {
                const _wild0 = __ps$match$0.index;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "fvar": {
                const _wild0 = __ps$match$0.id;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "sortE": {
                const _wild0 = __ps$match$0.level;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "constE": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.levels;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "app": {
                const _wild0 = __ps$match$0.fn;
                const _wild1 = __ps$match$0.arg;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "lam": {
                const unusedOtherName = __ps$match$0.name;
                const otherType = __ps$match$0.type;
                const otherBody = __ps$match$0.body;
                const unusedOtherBinder = __ps$match$0.binder;
                return (yield* __ps$invoke(psKernelConversionTasks, PsKernelList["cons"](PsKernelConversionTask["expr"](type, otherType), PsKernelList["cons"](PsKernelConversionTask["expr"](body, otherBody), tasks))));
            }
            case "forallE": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.type;
                const _wild2 = __ps$match$0.body;
                const _wild3 = __ps$match$0.binder;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "letE": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.type;
                const _wild2 = __ps$match$0.value;
                const _wild3 = __ps$match$0.body;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "lit": {
                const _wild0 = __ps$match$0.value;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "proj": {
                const _wild0 = __ps$match$0.family;
                const _wild1 = __ps$match$0.index;
                const _wild2 = __ps$match$0.value;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "forallE": {
        const unusedName = __ps$match$0.name;
        const type = __ps$match$0.type;
        const body = __ps$match$0.body;
        const unusedBinder = __ps$match$0.binder;
        return (yield* (function* () { const __ps$match$0 = right; switch (__ps$match$0[__ps$tag$21]) {
            case "bvar": {
                const _wild0 = __ps$match$0.index;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "fvar": {
                const _wild0 = __ps$match$0.id;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "sortE": {
                const _wild0 = __ps$match$0.level;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "constE": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.levels;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "app": {
                const _wild0 = __ps$match$0.fn;
                const _wild1 = __ps$match$0.arg;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "lam": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.type;
                const _wild2 = __ps$match$0.body;
                const _wild3 = __ps$match$0.binder;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "forallE": {
                const unusedOtherName = __ps$match$0.name;
                const otherType = __ps$match$0.type;
                const otherBody = __ps$match$0.body;
                const unusedOtherBinder = __ps$match$0.binder;
                return (yield* __ps$invoke(psKernelConversionTasks, PsKernelList["cons"](PsKernelConversionTask["expr"](type, otherType), PsKernelList["cons"](PsKernelConversionTask["expr"](body, otherBody), tasks))));
            }
            case "letE": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.type;
                const _wild2 = __ps$match$0.value;
                const _wild3 = __ps$match$0.body;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "lit": {
                const _wild0 = __ps$match$0.value;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
            case "proj": {
                const _wild0 = __ps$match$0.family;
                const _wild1 = __ps$match$0.index;
                const _wild2 = __ps$match$0.value;
                return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "letE": {
        const _wild0 = __ps$match$0.name;
        const _wild1 = __ps$match$0.type;
        const _wild2 = __ps$match$0.value;
        const _wild3 = __ps$match$0.body;
        return (yield* __ps$invoke(psKernelConversionReject, PsKernelCheckError["unsupported"]));
    }
    case "lit": {
        const _wild0 = __ps$match$0.value;
        return (yield* __ps$invoke(psKernelConversionReject, PsKernelCheckError["unsupported"]));
    }
    case "proj": {
        const _wild0 = __ps$match$0.family;
        const _wild1 = __ps$match$0.index;
        const _wild2 = __ps$match$0.value;
        return (yield* __ps$invoke(psKernelConversionReject, PsKernelCheckError["unsupported"]));
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelConversionExpr, __ps$impl$psKernelConversionExpr);
export function psKernelConversionStep(state) { return __ps$run(__ps$impl$psKernelConversionStep(state)); }
function* __ps$impl$psKernelConversionStep(state) { return (yield* (function* () { const __ps$match$0 = state; switch (__ps$match$0[__ps$tag$57]) {
    case "left": {
        const env = __ps$match$0.environment;
        const right = __ps$match$0.right;
        const current = __ps$match$0.state;
        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelReduceStep, current)); switch (__ps$match$0[__ps$tag$55]) {
            case "next": {
                const next = __ps$match$0.state;
                return PsKernelConversionStep["next"](PsKernelConversionState["left"](env, right, next));
            }
            case "final": {
                const result = __ps$match$0.result;
                return (yield* (function* () { const __ps$match$0 = result; switch (__ps$match$0[__ps$tag$54]) {
                    case "outOfFuel": return (yield* __ps$invoke(psKernelConversionReject, PsKernelCheckError["invalidState"]));
                    case "rejected": {
                        const error = __ps$match$0.error;
                        return (yield* __ps$invoke(psKernelConversionReject, error));
                    }
                    case "done": {
                        const left = __ps$match$0.value;
                        return PsKernelConversionStep["next"](PsKernelConversionState["right"](left, (yield* __ps$invoke(psKernelNormalStart, env, right))));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "right": {
        const left = __ps$match$0.left;
        const current = __ps$match$0.state;
        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelReduceStep, current)); switch (__ps$match$0[__ps$tag$55]) {
            case "next": {
                const next = __ps$match$0.state;
                return PsKernelConversionStep["next"](PsKernelConversionState["right"](left, next));
            }
            case "final": {
                const result = __ps$match$0.result;
                return (yield* (function* () { const __ps$match$0 = result; switch (__ps$match$0[__ps$tag$54]) {
                    case "outOfFuel": return (yield* __ps$invoke(psKernelConversionReject, PsKernelCheckError["invalidState"]));
                    case "rejected": {
                        const error = __ps$match$0.error;
                        return (yield* __ps$invoke(psKernelConversionReject, error));
                    }
                    case "done": {
                        const right = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelConversionTasks, PsKernelList["cons"](PsKernelConversionTask["expr"](left, right), PsKernelList["nil"]())));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "compare": {
        const tasks = __ps$match$0.tasks;
        return (yield* (function* () { const __ps$match$0 = tasks; switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return PsKernelConversionStep["final"](PsKernelConversionResult["equal"]);
            case "cons": {
                const task = __ps$match$0.head;
                const rest = __ps$match$0.tail;
                return (yield* (function* () { const __ps$match$0 = task; switch (__ps$match$0[__ps$tag$56]) {
                    case "expr": {
                        const left = __ps$match$0.left;
                        const right = __ps$match$0.right;
                        return (yield* __ps$invoke(psKernelConversionExpr, left, right, rest));
                    }
                    case "natural": {
                        const current = __ps$match$0.state;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelNumericStep, current)); switch (__ps$match$0[__ps$tag$17]) {
                            case "next": {
                                const next = __ps$match$0.state;
                                return (yield* __ps$invoke(psKernelConversionTasks, PsKernelList["cons"](PsKernelConversionTask["natural"](next), rest)));
                            }
                            case "ordered": {
                                const order = __ps$match$0.order;
                                return (yield* (function* () { const __ps$match$0 = order; switch (__ps$match$0[__ps$tag$13]) {
                                    case "less": return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
                                    case "same": return (yield* __ps$invoke(psKernelConversionTasks, rest));
                                    case "greater": return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                            case "sum": {
                                const _wild0 = __ps$match$0.value;
                                return (yield* __ps$invoke(psKernelConversionReject, PsKernelCheckError["invalidState"]));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "level": {
                        const current = __ps$match$0.state;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelCheckStep, current)); switch (__ps$match$0[__ps$tag$37]) {
                            case "next": {
                                const next = __ps$match$0.state;
                                return (yield* __ps$invoke(psKernelConversionTasks, PsKernelList["cons"](PsKernelConversionTask["level"](next), rest)));
                            }
                            case "final": {
                                const result = __ps$match$0.result;
                                return (yield* (function* () { const __ps$match$0 = result; switch (__ps$match$0[__ps$tag$36]) {
                                    case "outOfFuel": return (yield* __ps$invoke(psKernelConversionReject, PsKernelCheckError["invalidState"]));
                                    case "invalidState": return (yield* __ps$invoke(psKernelConversionReject, PsKernelCheckError["invalidState"]));
                                    case "equal": return (yield* __ps$invoke(psKernelConversionTasks, rest));
                                    case "different": return PsKernelConversionStep["final"](PsKernelConversionResult["different"]);
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelConversionStep, __ps$impl$psKernelConversionStep);
export function psKernelConversionStart(env, left, right) { return __ps$run(__ps$impl$psKernelConversionStart(env, left, right)); }
function* __ps$impl$psKernelConversionStart(env, left, right) { return PsKernelConversionState["left"](env, right, (yield* __ps$invoke(psKernelNormalStart, env, left))); }
__ps$implementations.set(psKernelConversionStart, __ps$impl$psKernelConversionStart);
export function psKernelConversionRun(fuel, __ps_eta_0) { return __ps$run(__ps$impl$psKernelConversionRun(fuel, __ps_eta_0)); }
function* __ps$impl$psKernelConversionRun(fuel, __ps_eta_0) { return (yield* (function* () { const __ps$match$0 = fuel; switch (__ps$match$0[__ps$tag$11]) {
    case "stop": return (yield* (function* () { {
        const state = __ps_eta_0;
        return PsKernelConversionResult["outOfFuel"];
    } })());
    case "more": {
        const remaining = __ps$match$0.remaining;
        return (yield* (function* () { {
            const state = __ps_eta_0;
            return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelConversionStep, state)); switch (__ps$match$0[__ps$tag$59]) {
                case "next": {
                    const next = __ps$match$0.state;
                    return (yield* (function* () { {
                        const smaller = __ps$wrap(function* (_$3) { return (yield* __ps$invoke(psKernelConversionRun, remaining, _$3)); });
                        return (yield* __ps$invoke(smaller, next));
                    } })());
                }
                case "final": {
                    const result = __ps$match$0.result;
                    return result;
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
        } })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelConversionRun, __ps$impl$psKernelConversionRun);
export function psKernelTypeReject(error) { while (true) {
    return PsKernelTypeStep["final"](PsKernelTypeResult["rejected"](error));
} }
export function psKernelTypeNext(env, tasks, values) { while (true) {
    return PsKernelTypeStep["next"](PsKernelTypeState["state"](env, tasks, values));
} }
export function psKernelTypePush(env, tasks, values, value) { return __ps$run(__ps$impl$psKernelTypePush(env, tasks, values, value)); }
function* __ps$impl$psKernelTypePush(env, tasks, values, value) { return (yield* __ps$invoke(psKernelTypeNext, env, tasks, PsKernelList["cons"](value, values))); }
__ps$implementations.set(psKernelTypePush, __ps$impl$psKernelTypePush);
export function psKernelTypeInfer(env, context, value, tasks, values) { return __ps$run(__ps$impl$psKernelTypeInfer(env, context, value, tasks, values)); }
function* __ps$impl$psKernelTypeInfer(env, context, value, tasks, values) { return (yield* (function* () { const __ps$match$0 = value; switch (__ps$match$0[__ps$tag$21]) {
    case "bvar": {
        const index = __ps$match$0.index;
        return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["bound"](context, index, (yield* __ps$invoke(psKernelNaturalSucc, index))), tasks), values));
    }
    case "fvar": {
        const unused = __ps$match$0.id;
        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidScope"]));
    }
    case "sortE": {
        const level = __ps$match$0.level;
        return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["levels"](PsKernelList["cons"](level, PsKernelList["nil"]())), PsKernelList["cons"](PsKernelTypeTask["returnE"](PsKernelExpr["sortE"](PsKernelLevel["succ"](level))), tasks)), values));
    }
    case "constE": {
        const name = __ps$match$0.name;
        const levels = __ps$match$0.levels;
        return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["levels"](levels), PsKernelList["cons"](PsKernelTypeTask["lookup"](levels, PsKernelLookupState["search"](name, (yield* __ps$invoke(psKernelTypingDeclarations, env)))), tasks)), values));
    }
    case "app": {
        const fn = __ps$match$0.fn;
        const arg = __ps$match$0.arg;
        return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["infer"](context, fn), PsKernelList["cons"](PsKernelTypeTask["reduceTop"], PsKernelList["cons"](PsKernelTypeTask["appPi"](context, arg), tasks))), values));
    }
    case "lam": {
        const name = __ps$match$0.name;
        const type = __ps$match$0.type;
        const body = __ps$match$0.body;
        const binder = __ps$match$0.binder;
        return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["infer"](context, type), PsKernelList["cons"](PsKernelTypeTask["reduceTop"], PsKernelList["cons"](PsKernelTypeTask["lamSort"](context, name, type, body, binder), tasks))), values));
    }
    case "forallE": {
        const unusedName = __ps$match$0.name;
        const type = __ps$match$0.type;
        const body = __ps$match$0.body;
        const unusedBinder = __ps$match$0.binder;
        return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["infer"](context, type), PsKernelList["cons"](PsKernelTypeTask["reduceTop"], PsKernelList["cons"](PsKernelTypeTask["piDomain"](context, type, body), tasks))), values));
    }
    case "letE": {
        const unusedName = __ps$match$0.name;
        const type = __ps$match$0.type;
        const val = __ps$match$0.value;
        const body = __ps$match$0.body;
        return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["infer"](context, type), PsKernelList["cons"](PsKernelTypeTask["reduceTop"], PsKernelList["cons"](PsKernelTypeTask["letSort"](context, type, val, body), tasks))), values));
    }
    case "lit": {
        const _wild0 = __ps$match$0.value;
        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["unsupported"]));
    }
    case "proj": {
        const _wild0 = __ps$match$0.family;
        const _wild1 = __ps$match$0.index;
        const _wild2 = __ps$match$0.value;
        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["unsupported"]));
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelTypeInfer, __ps$impl$psKernelTypeInfer);
export function psKernelTypeValueTask(env, task, tasks, values) { return __ps$run(__ps$impl$psKernelTypeValueTask(env, task, tasks, values)); }
function* __ps$impl$psKernelTypeValueTask(env, task, tasks, values) { return (yield* (function* () { const __ps$match$0 = values; switch (__ps$match$0[__ps$tag$8]) {
    case "nil": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
    case "cons": {
        const top = __ps$match$0.head;
        const rest = __ps$match$0.tail;
        return (yield* (function* () { const __ps$match$0 = task; switch (__ps$match$0[__ps$tag$60]) {
            case "infer": {
                const _wild0 = __ps$match$0.context;
                const _wild1 = __ps$match$0.value;
                return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
            }
            case "levels": {
                const _wild0 = __ps$match$0.pending;
                return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
            }
            case "levelName": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.remaining;
                const _wild2 = __ps$match$0.pending;
                return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
            }
            case "levelNameCompare": {
                const _wild0 = __ps$match$0.name;
                const _wild1 = __ps$match$0.remaining;
                const _wild2 = __ps$match$0.pending;
                const _wild3 = __ps$match$0.work;
                return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
            }
            case "parameterArguments": {
                const _wild0 = __ps$match$0.remaining;
                const _wild1 = __ps$match$0.reversed;
                const _wild2 = __ps$match$0.value;
                const _wild3 = __ps$match$0.type;
                return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
            }
            case "parameters": {
                const _wild0 = __ps$match$0.state;
                const _wild1 = __ps$match$0.value;
                const _wild2 = __ps$match$0.type;
                return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
            }
            case "instantiate": {
                const _wild0 = __ps$match$0.state;
                return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
            }
            case "bound": {
                const _wild0 = __ps$match$0.context;
                const _wild1 = __ps$match$0.index;
                const _wild2 = __ps$match$0.shift;
                return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
            }
            case "lookup": {
                const _wild0 = __ps$match$0.levels;
                const _wild1 = __ps$match$0.state;
                return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
            }
            case "binding": {
                const _wild0 = __ps$match$0.state;
                return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
            }
            case "reduce": {
                const _wild0 = __ps$match$0.state;
                return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
            }
            case "reduceTop": return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["reduce"]((yield* __ps$invoke(psKernelWhnfStart, (yield* __ps$invoke(psKernelTypingDeclarations, env)), top))), tasks), rest));
            case "conversion": {
                const _wild0 = __ps$match$0.state;
                return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
            }
            case "returnE": {
                const _wild0 = __ps$match$0.value;
                return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
            }
            case "lamSort": {
                const context = __ps$match$0.context;
                const name = __ps$match$0.name;
                const type = __ps$match$0.type;
                const body = __ps$match$0.body;
                const binder = __ps$match$0.binder;
                return (yield* (function* () { const __ps$match$0 = top; switch (__ps$match$0[__ps$tag$21]) {
                    case "bvar": {
                        const _wild0 = __ps$match$0.index;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "fvar": {
                        const _wild0 = __ps$match$0.id;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "sortE": {
                        const unusedLevel = __ps$match$0.level;
                        return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["infer"](PsKernelList["cons"](type, context), body), PsKernelList["cons"](PsKernelTypeTask["lamFinish"](name, type, binder), tasks)), rest));
                    }
                    case "constE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.levels;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "app": {
                        const _wild0 = __ps$match$0.fn;
                        const _wild1 = __ps$match$0.arg;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "lam": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.body;
                        const _wild3 = __ps$match$0.binder;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "forallE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.body;
                        const _wild3 = __ps$match$0.binder;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "letE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.value;
                        const _wild3 = __ps$match$0.body;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "lit": {
                        const _wild0 = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "proj": {
                        const _wild0 = __ps$match$0.family;
                        const _wild1 = __ps$match$0.index;
                        const _wild2 = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "lamFinish": {
                const name = __ps$match$0.name;
                const type = __ps$match$0.type;
                const binder = __ps$match$0.binder;
                return (yield* __ps$invoke(psKernelTypePush, env, tasks, rest, PsKernelExpr["forallE"](name, type, top, binder)));
            }
            case "piDomain": {
                const context = __ps$match$0.context;
                const type = __ps$match$0.type;
                const body = __ps$match$0.body;
                return (yield* (function* () { const __ps$match$0 = top; switch (__ps$match$0[__ps$tag$21]) {
                    case "bvar": {
                        const _wild0 = __ps$match$0.index;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "fvar": {
                        const _wild0 = __ps$match$0.id;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "sortE": {
                        const level = __ps$match$0.level;
                        return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["infer"](PsKernelList["cons"](type, context), body), PsKernelList["cons"](PsKernelTypeTask["reduceTop"], PsKernelList["cons"](PsKernelTypeTask["piFinish"](level), tasks))), rest));
                    }
                    case "constE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.levels;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "app": {
                        const _wild0 = __ps$match$0.fn;
                        const _wild1 = __ps$match$0.arg;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "lam": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.body;
                        const _wild3 = __ps$match$0.binder;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "forallE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.body;
                        const _wild3 = __ps$match$0.binder;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "letE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.value;
                        const _wild3 = __ps$match$0.body;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "lit": {
                        const _wild0 = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "proj": {
                        const _wild0 = __ps$match$0.family;
                        const _wild1 = __ps$match$0.index;
                        const _wild2 = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "piFinish": {
                const domainLevel = __ps$match$0.domainLevel;
                return (yield* (function* () { const __ps$match$0 = top; switch (__ps$match$0[__ps$tag$21]) {
                    case "bvar": {
                        const _wild0 = __ps$match$0.index;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "fvar": {
                        const _wild0 = __ps$match$0.id;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "sortE": {
                        const bodyLevel = __ps$match$0.level;
                        return (yield* __ps$invoke(psKernelTypePush, env, tasks, rest, PsKernelExpr["sortE"](PsKernelLevel["imax"](domainLevel, bodyLevel))));
                    }
                    case "constE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.levels;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "app": {
                        const _wild0 = __ps$match$0.fn;
                        const _wild1 = __ps$match$0.arg;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "lam": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.body;
                        const _wild3 = __ps$match$0.binder;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "forallE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.body;
                        const _wild3 = __ps$match$0.binder;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "letE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.value;
                        const _wild3 = __ps$match$0.body;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "lit": {
                        const _wild0 = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "proj": {
                        const _wild0 = __ps$match$0.family;
                        const _wild1 = __ps$match$0.index;
                        const _wild2 = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "appPi": {
                const context = __ps$match$0.context;
                const arg = __ps$match$0.arg;
                return (yield* (function* () { const __ps$match$0 = top; switch (__ps$match$0[__ps$tag$21]) {
                    case "bvar": {
                        const _wild0 = __ps$match$0.index;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["functionExpected"]));
                    }
                    case "fvar": {
                        const _wild0 = __ps$match$0.id;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["functionExpected"]));
                    }
                    case "sortE": {
                        const _wild0 = __ps$match$0.level;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["functionExpected"]));
                    }
                    case "constE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.levels;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["functionExpected"]));
                    }
                    case "app": {
                        const _wild0 = __ps$match$0.fn;
                        const _wild1 = __ps$match$0.arg;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["functionExpected"]));
                    }
                    case "lam": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.body;
                        const _wild3 = __ps$match$0.binder;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["functionExpected"]));
                    }
                    case "forallE": {
                        const unusedName = __ps$match$0.name;
                        const domain = __ps$match$0.type;
                        const body = __ps$match$0.body;
                        const unusedBinder = __ps$match$0.binder;
                        return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["infer"](context, arg), PsKernelList["cons"](PsKernelTypeTask["appArgument"](domain, body, arg), tasks)), rest));
                    }
                    case "letE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.value;
                        const _wild3 = __ps$match$0.body;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["functionExpected"]));
                    }
                    case "lit": {
                        const _wild0 = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["functionExpected"]));
                    }
                    case "proj": {
                        const _wild0 = __ps$match$0.family;
                        const _wild1 = __ps$match$0.index;
                        const _wild2 = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["functionExpected"]));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "appArgument": {
                const domain = __ps$match$0.domain;
                const body = __ps$match$0.body;
                const arg = __ps$match$0.arg;
                return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["conversion"]((yield* __ps$invoke(psKernelConversionStart, (yield* __ps$invoke(psKernelTypingDeclarations, env)), top, domain))), PsKernelList["cons"](PsKernelTypeTask["binding"]((yield* __ps$invoke(psKernelBindingStart, PsKernelBindingMode["instantiate"](arg), PsKernelNatural["zero"], body))), tasks)), rest));
            }
            case "letSort": {
                const context = __ps$match$0.context;
                const type = __ps$match$0.type;
                const value = __ps$match$0.value;
                const body = __ps$match$0.body;
                return (yield* (function* () { const __ps$match$0 = top; switch (__ps$match$0[__ps$tag$21]) {
                    case "bvar": {
                        const _wild0 = __ps$match$0.index;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "fvar": {
                        const _wild0 = __ps$match$0.id;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "sortE": {
                        const unusedLevel = __ps$match$0.level;
                        return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["infer"](context, value), PsKernelList["cons"](PsKernelTypeTask["letValue"](context, type, value, body), tasks)), rest));
                    }
                    case "constE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.levels;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "app": {
                        const _wild0 = __ps$match$0.fn;
                        const _wild1 = __ps$match$0.arg;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "lam": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.body;
                        const _wild3 = __ps$match$0.binder;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "forallE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.body;
                        const _wild3 = __ps$match$0.binder;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "letE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.value;
                        const _wild3 = __ps$match$0.body;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "lit": {
                        const _wild0 = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "proj": {
                        const _wild0 = __ps$match$0.family;
                        const _wild1 = __ps$match$0.index;
                        const _wild2 = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "letValue": {
                const context = __ps$match$0.context;
                const type = __ps$match$0.type;
                const value = __ps$match$0.value;
                const body = __ps$match$0.body;
                return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["conversion"]((yield* __ps$invoke(psKernelConversionStart, (yield* __ps$invoke(psKernelTypingDeclarations, env)), top, type))), PsKernelList["cons"](PsKernelTypeTask["binding"]((yield* __ps$invoke(psKernelBindingStart, PsKernelBindingMode["instantiate"](value), PsKernelNatural["zero"], body))), PsKernelList["cons"](PsKernelTypeTask["letBody"](context), tasks))), rest));
            }
            case "letBody": {
                const context = __ps$match$0.context;
                return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["infer"](context, top), tasks), rest));
            }
            case "checkSort": {
                const value = __ps$match$0.value;
                const type = __ps$match$0.type;
                return (yield* (function* () { const __ps$match$0 = top; switch (__ps$match$0[__ps$tag$21]) {
                    case "bvar": {
                        const _wild0 = __ps$match$0.index;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "fvar": {
                        const _wild0 = __ps$match$0.id;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "sortE": {
                        const unusedLevel = __ps$match$0.level;
                        return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["infer"](PsKernelList["nil"](), value), PsKernelList["cons"](PsKernelTypeTask["checkValue"](type), tasks)), rest));
                    }
                    case "constE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.levels;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "app": {
                        const _wild0 = __ps$match$0.fn;
                        const _wild1 = __ps$match$0.arg;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "lam": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.body;
                        const _wild3 = __ps$match$0.binder;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "forallE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.body;
                        const _wild3 = __ps$match$0.binder;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "letE": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.value;
                        const _wild3 = __ps$match$0.body;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "lit": {
                        const _wild0 = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                    case "proj": {
                        const _wild0 = __ps$match$0.family;
                        const _wild1 = __ps$match$0.index;
                        const _wild2 = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeExpected"]));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
            case "checkValue": {
                const type = __ps$match$0.type;
                return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["conversion"]((yield* __ps$invoke(psKernelConversionStart, (yield* __ps$invoke(psKernelTypingDeclarations, env)), top, type))), PsKernelList["cons"](PsKernelTypeTask["returnE"](type), tasks)), rest));
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelTypeValueTask, __ps$impl$psKernelTypeValueTask);
export function psKernelTypeLevels(env, pending, tasks, values) { return __ps$run(__ps$impl$psKernelTypeLevels(env, pending, tasks, values)); }
function* __ps$impl$psKernelTypeLevels(env, pending, tasks, values) { return (yield* (function* () { const __ps$match$0 = pending; switch (__ps$match$0[__ps$tag$8]) {
    case "nil": return (yield* __ps$invoke(psKernelTypeNext, env, tasks, values));
    case "cons": {
        const level = __ps$match$0.head;
        const rest = __ps$match$0.tail;
        return (yield* (function* () { const __ps$match$0 = level; switch (__ps$match$0[__ps$tag$7]) {
            case "zero": return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["levels"](rest), tasks), values));
            case "succ": {
                const next = __ps$match$0.value;
                return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["levels"](PsKernelList["cons"](next, rest)), tasks), values));
            }
            case "max": {
                const left = __ps$match$0.left;
                const right = __ps$match$0.right;
                return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["levels"](PsKernelList["cons"](left, PsKernelList["cons"](right, rest))), tasks), values));
            }
            case "imax": {
                const left = __ps$match$0.left;
                const right = __ps$match$0.right;
                return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["levels"](PsKernelList["cons"](left, PsKernelList["cons"](right, rest))), tasks), values));
            }
            case "param": {
                const name = __ps$match$0.name;
                return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["levelName"](name, (yield* __ps$invoke(psKernelTypingParameters, env)), rest), tasks), values));
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelTypeLevels, __ps$impl$psKernelTypeLevels);
export function psKernelTypeStep(state) { return __ps$run(__ps$impl$psKernelTypeStep(state)); }
function* __ps$impl$psKernelTypeStep(state) { return (yield* (function* () { const __ps$match$0 = state; switch (__ps$match$0[__ps$tag$61]) {
    case "state": {
        const env = __ps$match$0.environment;
        const tasks = __ps$match$0.tasks;
        const values = __ps$match$0.values;
        return (yield* (function* () { const __ps$match$0 = tasks; switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return (yield* (function* () { const __ps$match$0 = values; switch (__ps$match$0[__ps$tag$8]) {
                case "nil": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
                case "cons": {
                    const type = __ps$match$0.head;
                    const rest = __ps$match$0.tail;
                    return (yield* (function* () { const __ps$match$0 = rest; switch (__ps$match$0[__ps$tag$8]) {
                        case "nil": return PsKernelTypeStep["final"](PsKernelTypeResult["done"](type));
                        case "cons": {
                            const _wild0 = __ps$match$0.head;
                            const _wild1 = __ps$match$0.tail;
                            return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
                        }
                    } throw new Error("invalid ProofScript constructor tag"); })());
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
            case "cons": {
                const task = __ps$match$0.head;
                const rest = __ps$match$0.tail;
                return (yield* (function* () { const __ps$match$0 = task; switch (__ps$match$0[__ps$tag$60]) {
                    case "infer": {
                        const context = __ps$match$0.context;
                        const value = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelTypeInfer, env, context, value, rest, values));
                    }
                    case "levels": {
                        const pending = __ps$match$0.pending;
                        return (yield* __ps$invoke(psKernelTypeLevels, env, pending, rest, values));
                    }
                    case "levelName": {
                        const name = __ps$match$0.name;
                        const remaining = __ps$match$0.remaining;
                        const pending = __ps$match$0.pending;
                        return (yield* (function* () { const __ps$match$0 = remaining; switch (__ps$match$0[__ps$tag$8]) {
                            case "nil": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidUniverse"]));
                            case "cons": {
                                const candidate = __ps$match$0.head;
                                const tail = __ps$match$0.tail;
                                return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["levelNameCompare"](name, tail, pending, PsKernelList["cons"](PsKernelOrderTask["name"](name, candidate), PsKernelList["nil"]())), rest), values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "levelNameCompare": {
                        const name = __ps$match$0.name;
                        const remaining = __ps$match$0.remaining;
                        const pending = __ps$match$0.pending;
                        const work = __ps$match$0.work;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelOrderStep, work)); switch (__ps$match$0[__ps$tag$28]) {
                            case "next": {
                                const next = __ps$match$0.tasks;
                                return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["levelNameCompare"](name, remaining, pending, next), rest), values));
                            }
                            case "done": {
                                const order = __ps$match$0.order;
                                return (yield* (function* () { const __ps$match$0 = order; switch (__ps$match$0[__ps$tag$13]) {
                                    case "less": return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["levelName"](name, remaining, pending), rest), values));
                                    case "same": return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["levels"](pending), rest), values));
                                    case "greater": return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["levelName"](name, remaining, pending), rest), values));
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                            case "invalidState": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "parameterArguments": {
                        const remaining = __ps$match$0.remaining;
                        const reversed = __ps$match$0.reversed;
                        const value = __ps$match$0.value;
                        const type = __ps$match$0.type;
                        return (yield* (function* () { const __ps$match$0 = remaining; switch (__ps$match$0[__ps$tag$8]) {
                            case "nil": return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["parameters"]((yield* __ps$invoke(psKernelLevelInstantiateStart, (yield* __ps$invoke(psKernelTypingParameters, env)), reversed, PsKernelLevel["zero"])), value, type), rest), values));
                            case "cons": {
                                const unusedName = __ps$match$0.head;
                                const tail = __ps$match$0.tail;
                                return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["parameterArguments"](tail, PsKernelList["cons"](PsKernelLevel["zero"], reversed), value, type), rest), values));
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "parameters": {
                        const current = __ps$match$0.state;
                        const value = __ps$match$0.value;
                        const type = __ps$match$0.type;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLevelInstantiateStep, current)); switch (__ps$match$0[__ps$tag$42]) {
                            case "next": {
                                const next = __ps$match$0.state;
                                return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["parameters"](next, value, type), rest), values));
                            }
                            case "final": {
                                const result = __ps$match$0.result;
                                return (yield* (function* () { const __ps$match$0 = result; switch (__ps$match$0[__ps$tag$41]) {
                                    case "outOfFuel": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
                                    case "invalidState": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
                                    case "invalidParameters": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidUniverse"]));
                                    case "undeclaredParameter": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
                                    case "done": {
                                        const unused = __ps$match$0.value;
                                        return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["infer"](PsKernelList["nil"](), type), PsKernelList["cons"](PsKernelTypeTask["reduceTop"], PsKernelList["cons"](PsKernelTypeTask["checkSort"](value, type), rest))), values));
                                    }
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "instantiate": {
                        const current = __ps$match$0.state;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelExprInstantiateStep, current)); switch (__ps$match$0[__ps$tag$46]) {
                            case "next": {
                                const next = __ps$match$0.state;
                                return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["instantiate"](next), rest), values));
                            }
                            case "final": {
                                const result = __ps$match$0.result;
                                return (yield* (function* () { const __ps$match$0 = result; switch (__ps$match$0[__ps$tag$45]) {
                                    case "outOfFuel": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
                                    case "invalidState": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
                                    case "invalidParameters": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidUniverse"]));
                                    case "undeclaredParameter": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidUniverse"]));
                                    case "done": {
                                        const value = __ps$match$0.value;
                                        return (yield* __ps$invoke(psKernelTypePush, env, rest, values, value));
                                    }
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "bound": {
                        const context = __ps$match$0.context;
                        const index = __ps$match$0.index;
                        const shift = __ps$match$0.shift;
                        return (yield* (function* () { const __ps$match$0 = context; switch (__ps$match$0[__ps$tag$8]) {
                            case "nil": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidScope"]));
                            case "cons": {
                                const type = __ps$match$0.head;
                                const tail = __ps$match$0.tail;
                                return (yield* (function* () { const __ps$match$0 = index; switch (__ps$match$0[__ps$tag$4]) {
                                    case "zero": return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["binding"]((yield* __ps$invoke(psKernelBindingStart, PsKernelBindingMode["lift"](shift), PsKernelNatural["zero"], type))), rest), values));
                                    case "positive": {
                                        const _wild0 = __ps$match$0.value;
                                        return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["bound"](tail, (yield* __ps$invoke(psKernelNaturalPred, index)), shift), rest), values));
                                    }
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "lookup": {
                        const levels = __ps$match$0.levels;
                        const current = __ps$match$0.state;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLookupStep, current)); switch (__ps$match$0[__ps$tag$51]) {
                            case "next": {
                                const next = __ps$match$0.state;
                                return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["lookup"](levels, next), rest), values));
                            }
                            case "found": {
                                const entry = __ps$match$0.entry;
                                return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["instantiate"]((yield* __ps$invoke(psKernelExprInstantiateStart, (yield* __ps$invoke(psKernelDefinitionParameters, entry)), levels, (yield* __ps$invoke(psKernelDefinitionType, entry))))), rest), values));
                            }
                            case "missing": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["unknownConstant"]));
                            case "invalidState": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "binding": {
                        const current = __ps$match$0.state;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelBindingStep, current)); switch (__ps$match$0[__ps$tag$26]) {
                            case "next": {
                                const next = __ps$match$0.state;
                                return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["binding"](next), rest), values));
                            }
                            case "final": {
                                const result = __ps$match$0.result;
                                return (yield* (function* () { const __ps$match$0 = result; switch (__ps$match$0[__ps$tag$25]) {
                                    case "outOfFuel": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
                                    case "invalidState": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
                                    case "invalidScope": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidScope"]));
                                    case "done": {
                                        const value = __ps$match$0.value;
                                        return (yield* __ps$invoke(psKernelTypePush, env, rest, values, value));
                                    }
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "reduce": {
                        const current = __ps$match$0.state;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelReduceStep, current)); switch (__ps$match$0[__ps$tag$55]) {
                            case "next": {
                                const next = __ps$match$0.state;
                                return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["reduce"](next), rest), values));
                            }
                            case "final": {
                                const result = __ps$match$0.result;
                                return (yield* (function* () { const __ps$match$0 = result; switch (__ps$match$0[__ps$tag$54]) {
                                    case "outOfFuel": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
                                    case "rejected": {
                                        const error = __ps$match$0.error;
                                        return (yield* __ps$invoke(psKernelTypeReject, error));
                                    }
                                    case "done": {
                                        const value = __ps$match$0.value;
                                        return (yield* __ps$invoke(psKernelTypePush, env, rest, values, value));
                                    }
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "reduceTop": return (yield* __ps$invoke(psKernelTypeValueTask, env, task, rest, values));
                    case "conversion": {
                        const current = __ps$match$0.state;
                        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelConversionStep, current)); switch (__ps$match$0[__ps$tag$59]) {
                            case "next": {
                                const next = __ps$match$0.state;
                                return (yield* __ps$invoke(psKernelTypeNext, env, PsKernelList["cons"](PsKernelTypeTask["conversion"](next), rest), values));
                            }
                            case "final": {
                                const result = __ps$match$0.result;
                                return (yield* (function* () { const __ps$match$0 = result; switch (__ps$match$0[__ps$tag$58]) {
                                    case "outOfFuel": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["invalidState"]));
                                    case "rejected": {
                                        const error = __ps$match$0.error;
                                        return (yield* __ps$invoke(psKernelTypeReject, error));
                                    }
                                    case "equal": return (yield* __ps$invoke(psKernelTypeNext, env, rest, values));
                                    case "different": return (yield* __ps$invoke(psKernelTypeReject, PsKernelCheckError["typeMismatch"]));
                                } throw new Error("invalid ProofScript constructor tag"); })());
                            }
                        } throw new Error("invalid ProofScript constructor tag"); })());
                    }
                    case "returnE": {
                        const value = __ps$match$0.value;
                        return (yield* __ps$invoke(psKernelTypePush, env, rest, values, value));
                    }
                    case "lamSort": {
                        const _wild0 = __ps$match$0.context;
                        const _wild1 = __ps$match$0.name;
                        const _wild2 = __ps$match$0.type;
                        const _wild3 = __ps$match$0.body;
                        const _wild4 = __ps$match$0.binder;
                        return (yield* __ps$invoke(psKernelTypeValueTask, env, task, rest, values));
                    }
                    case "lamFinish": {
                        const _wild0 = __ps$match$0.name;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.binder;
                        return (yield* __ps$invoke(psKernelTypeValueTask, env, task, rest, values));
                    }
                    case "piDomain": {
                        const _wild0 = __ps$match$0.context;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.body;
                        return (yield* __ps$invoke(psKernelTypeValueTask, env, task, rest, values));
                    }
                    case "piFinish": {
                        const _wild0 = __ps$match$0.domainLevel;
                        return (yield* __ps$invoke(psKernelTypeValueTask, env, task, rest, values));
                    }
                    case "appPi": {
                        const _wild0 = __ps$match$0.context;
                        const _wild1 = __ps$match$0.arg;
                        return (yield* __ps$invoke(psKernelTypeValueTask, env, task, rest, values));
                    }
                    case "appArgument": {
                        const _wild0 = __ps$match$0.domain;
                        const _wild1 = __ps$match$0.body;
                        const _wild2 = __ps$match$0.arg;
                        return (yield* __ps$invoke(psKernelTypeValueTask, env, task, rest, values));
                    }
                    case "letSort": {
                        const _wild0 = __ps$match$0.context;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.value;
                        const _wild3 = __ps$match$0.body;
                        return (yield* __ps$invoke(psKernelTypeValueTask, env, task, rest, values));
                    }
                    case "letValue": {
                        const _wild0 = __ps$match$0.context;
                        const _wild1 = __ps$match$0.type;
                        const _wild2 = __ps$match$0.value;
                        const _wild3 = __ps$match$0.body;
                        return (yield* __ps$invoke(psKernelTypeValueTask, env, task, rest, values));
                    }
                    case "letBody": {
                        const _wild0 = __ps$match$0.context;
                        return (yield* __ps$invoke(psKernelTypeValueTask, env, task, rest, values));
                    }
                    case "checkSort": {
                        const _wild0 = __ps$match$0.value;
                        const _wild1 = __ps$match$0.type;
                        return (yield* __ps$invoke(psKernelTypeValueTask, env, task, rest, values));
                    }
                    case "checkValue": {
                        const _wild0 = __ps$match$0.type;
                        return (yield* __ps$invoke(psKernelTypeValueTask, env, task, rest, values));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelTypeStep, __ps$impl$psKernelTypeStep);
export function psKernelInferStart(env, value) { while (true) {
    return PsKernelTypeState["state"](PsKernelTypingContext["context"](env, PsKernelList["nil"]()), PsKernelList["cons"](PsKernelTypeTask["infer"](PsKernelList["nil"](), value), PsKernelList["nil"]()), PsKernelList["nil"]());
} }
export function psKernelCheckWithParametersStart(env, parameters, value, type) { while (true) {
    return PsKernelTypeState["state"](PsKernelTypingContext["context"](env, parameters), PsKernelList["cons"](PsKernelTypeTask["parameterArguments"](parameters, PsKernelList["nil"](), value, type), PsKernelList["nil"]()), PsKernelList["nil"]());
} }
export function psKernelCheckStart(env, value, type) { return __ps$run(__ps$impl$psKernelCheckStart(env, value, type)); }
function* __ps$impl$psKernelCheckStart(env, value, type) { return (yield* __ps$invoke(psKernelCheckWithParametersStart, env, PsKernelList["nil"](), value, type)); }
__ps$implementations.set(psKernelCheckStart, __ps$impl$psKernelCheckStart);
export function psKernelTypeRun(fuel, __ps_eta_0) { return __ps$run(__ps$impl$psKernelTypeRun(fuel, __ps_eta_0)); }
function* __ps$impl$psKernelTypeRun(fuel, __ps_eta_0) { return (yield* (function* () { const __ps$match$0 = fuel; switch (__ps$match$0[__ps$tag$11]) {
    case "stop": return (yield* (function* () { {
        const state = __ps_eta_0;
        return PsKernelTypeResult["outOfFuel"];
    } })());
    case "more": {
        const remaining = __ps$match$0.remaining;
        return (yield* (function* () { {
            const state = __ps_eta_0;
            return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelTypeStep, state)); switch (__ps$match$0[__ps$tag$63]) {
                case "next": {
                    const next = __ps$match$0.state;
                    return (yield* (function* () { {
                        const smaller = __ps$wrap(function* (_$3) { return (yield* __ps$invoke(psKernelTypeRun, remaining, _$3)); });
                        return (yield* __ps$invoke(smaller, next));
                    } })());
                }
                case "final": {
                    const result = __ps$match$0.result;
                    return result;
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
        } })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelTypeRun, __ps$impl$psKernelTypeRun);
export function psKernelAdmissionReject(error) { while (true) {
    return PsKernelAdmissionStep["final"](PsKernelAdmissionResult["rejected"](error));
} }
export function psKernelAdmissionStep(state) { return __ps$run(__ps$impl$psKernelAdmissionStep(state)); }
function* __ps$impl$psKernelAdmissionStep(state) { return (yield* (function* () { const __ps$match$0 = state; switch (__ps$match$0[__ps$tag$64]) {
    case "pending": {
        const env = __ps$match$0.environment;
        const entries = __ps$match$0.entries;
        return (yield* (function* () { const __ps$match$0 = entries; switch (__ps$match$0[__ps$tag$8]) {
            case "nil": return PsKernelAdmissionStep["final"](PsKernelAdmissionResult["admitted"](env));
            case "cons": {
                const entry = __ps$match$0.head;
                const rest = __ps$match$0.tail;
                return (yield* (function* () { {
                    const name = (yield* __ps$invoke(psKernelDefinitionName, entry));
                    return (yield* (function* () { const __ps$match$0 = name; switch (__ps$match$0[__ps$tag$6]) {
                        case "anonymous": return (yield* __ps$invoke(psKernelAdmissionReject, PsKernelCheckError["invalidName"]));
                        case "str": {
                            const _wild0 = __ps$match$0.parent;
                            const _wild1 = __ps$match$0.value;
                            return PsKernelAdmissionStep["next"](PsKernelAdmissionState["duplicate"](env, entry, rest, PsKernelLookupState["search"](name, env)));
                        }
                        case "num": {
                            const _wild0 = __ps$match$0.parent;
                            const _wild1 = __ps$match$0.value;
                            return PsKernelAdmissionStep["next"](PsKernelAdmissionState["duplicate"](env, entry, rest, PsKernelLookupState["search"](name, env)));
                        }
                    } throw new Error("invalid ProofScript constructor tag"); })());
                } })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "duplicate": {
        const env = __ps$match$0.environment;
        const entry = __ps$match$0.entry;
        const rest = __ps$match$0.rest;
        const current = __ps$match$0.state;
        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelLookupStep, current)); switch (__ps$match$0[__ps$tag$51]) {
            case "next": {
                const next = __ps$match$0.state;
                return PsKernelAdmissionStep["next"](PsKernelAdmissionState["duplicate"](env, entry, rest, next));
            }
            case "found": {
                const unusedEntry = __ps$match$0.entry;
                return (yield* __ps$invoke(psKernelAdmissionReject, PsKernelCheckError["duplicateName"]));
            }
            case "missing": return PsKernelAdmissionStep["next"](PsKernelAdmissionState["checking"](env, entry, rest, (yield* __ps$invoke(psKernelCheckWithParametersStart, env, (yield* __ps$invoke(psKernelDefinitionParameters, entry)), (yield* __ps$invoke(psKernelDefinitionValue, entry)), (yield* __ps$invoke(psKernelDefinitionType, entry))))));
            case "invalidState": return (yield* __ps$invoke(psKernelAdmissionReject, PsKernelCheckError["invalidState"]));
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
    case "checking": {
        const env = __ps$match$0.environment;
        const entry = __ps$match$0.entry;
        const rest = __ps$match$0.rest;
        const current = __ps$match$0.state;
        return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelTypeStep, current)); switch (__ps$match$0[__ps$tag$63]) {
            case "next": {
                const next = __ps$match$0.state;
                return PsKernelAdmissionStep["next"](PsKernelAdmissionState["checking"](env, entry, rest, next));
            }
            case "final": {
                const result = __ps$match$0.result;
                return (yield* (function* () { const __ps$match$0 = result; switch (__ps$match$0[__ps$tag$62]) {
                    case "outOfFuel": return (yield* __ps$invoke(psKernelAdmissionReject, PsKernelCheckError["invalidState"]));
                    case "rejected": {
                        const error = __ps$match$0.error;
                        return (yield* __ps$invoke(psKernelAdmissionReject, error));
                    }
                    case "done": {
                        const unusedType = __ps$match$0.type;
                        return PsKernelAdmissionStep["next"](PsKernelAdmissionState["pending"](PsKernelList["cons"](entry, env), rest));
                    }
                } throw new Error("invalid ProofScript constructor tag"); })());
            }
        } throw new Error("invalid ProofScript constructor tag"); })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelAdmissionStep, __ps$impl$psKernelAdmissionStep);
export function psKernelAdmissionStart(entries) { while (true) {
    return PsKernelAdmissionState["pending"](PsKernelList["nil"](), entries);
} }
export function psKernelAdmissionRun(fuel, __ps_eta_0) { return __ps$run(__ps$impl$psKernelAdmissionRun(fuel, __ps_eta_0)); }
function* __ps$impl$psKernelAdmissionRun(fuel, __ps_eta_0) { return (yield* (function* () { const __ps$match$0 = fuel; switch (__ps$match$0[__ps$tag$11]) {
    case "stop": return (yield* (function* () { {
        const state = __ps_eta_0;
        return PsKernelAdmissionResult["outOfFuel"];
    } })());
    case "more": {
        const remaining = __ps$match$0.remaining;
        return (yield* (function* () { {
            const state = __ps_eta_0;
            return (yield* (function* () { const __ps$match$0 = (yield* __ps$invoke(psKernelAdmissionStep, state)); switch (__ps$match$0[__ps$tag$66]) {
                case "next": {
                    const next = __ps$match$0.state;
                    return (yield* (function* () { {
                        const smaller = __ps$wrap(function* (_$3) { return (yield* __ps$invoke(psKernelAdmissionRun, remaining, _$3)); });
                        return (yield* __ps$invoke(smaller, next));
                    } })());
                }
                case "final": {
                    const result = __ps$match$0.result;
                    return result;
                }
            } throw new Error("invalid ProofScript constructor tag"); })());
        } })());
    }
} throw new Error("invalid ProofScript constructor tag"); })()); }
__ps$implementations.set(psKernelAdmissionRun, __ps$impl$psKernelAdmissionRun);
