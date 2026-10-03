declare const __ps$brand$0: unique symbol;
export interface Prod<T0, T1> {
    readonly [__ps$brand$0]: true;
    readonly fst: T0;
    readonly snd: T1;
}
declare const __ps$tag$0: unique symbol;
export type List<T0> = {
    readonly [__ps$tag$0]: "nil";
} | {
    readonly [__ps$tag$0]: "cons";
    readonly head: T0;
    readonly tail: List<T0>;
};
export declare const List: {
    readonly nil: <T0>() => List<T0>;
    readonly cons: <T0>(__field0: T0, __field1: List<T0>) => List<T0>;
};
declare const __ps$tag$1: unique symbol;
export type Option<T0> = {
    readonly [__ps$tag$1]: "none";
} | {
    readonly [__ps$tag$1]: "some";
    readonly value: T0;
};
export declare const Option: {
    readonly none: <T0>() => Option<T0>;
    readonly some: <T0>(__field0: T0) => Option<T0>;
};
declare const __ps$tag$2: unique symbol;
export type Except<T0, T1> = {
    readonly [__ps$tag$2]: "error";
    readonly error: T0;
} | {
    readonly [__ps$tag$2]: "ok";
    readonly value: T1;
};
export declare const Except: {
    readonly error: <T0, T1>(__field0: T0) => Except<T0, T1>;
    readonly ok: <T0, T1>(__field0: T1) => Except<T0, T1>;
};
declare const __ps$tag$3: unique symbol;
export type PsKernelPositive = {
    readonly [__ps$tag$3]: "one";
} | {
    readonly [__ps$tag$3]: "bit0";
    readonly high: PsKernelPositive;
} | {
    readonly [__ps$tag$3]: "bit1";
    readonly high: PsKernelPositive;
};
export declare const PsKernelPositive: {
    readonly one: PsKernelPositive;
    readonly bit0: (__field0: PsKernelPositive) => PsKernelPositive;
    readonly bit1: (__field0: PsKernelPositive) => PsKernelPositive;
};
declare const __ps$tag$4: unique symbol;
export type PsKernelNatural = {
    readonly [__ps$tag$4]: "zero";
} | {
    readonly [__ps$tag$4]: "positive";
    readonly value: PsKernelPositive;
};
export declare const PsKernelNatural: {
    readonly zero: PsKernelNatural;
    readonly positive: (__field0: PsKernelPositive) => PsKernelNatural;
};
declare const __ps$tag$5: unique symbol;
export type PsKernelText = {
    readonly [__ps$tag$5]: "empty";
} | {
    readonly [__ps$tag$5]: "byte";
    readonly value: PsKernelNatural;
    readonly rest: PsKernelText;
};
export declare const PsKernelText: {
    readonly empty: PsKernelText;
    readonly byte: (__field0: PsKernelNatural, __field1: PsKernelText) => PsKernelText;
};
declare const __ps$tag$6: unique symbol;
export type PsKernelName = {
    readonly [__ps$tag$6]: "anonymous";
} | {
    readonly [__ps$tag$6]: "str";
    readonly parent: PsKernelName;
    readonly value: PsKernelText;
} | {
    readonly [__ps$tag$6]: "num";
    readonly parent: PsKernelName;
    readonly value: PsKernelNatural;
};
export declare const PsKernelName: {
    readonly anonymous: PsKernelName;
    readonly str: (__field0: PsKernelName, __field1: PsKernelText) => PsKernelName;
    readonly num: (__field0: PsKernelName, __field1: PsKernelNatural) => PsKernelName;
};
declare const __ps$tag$7: unique symbol;
export type PsKernelLevel = {
    readonly [__ps$tag$7]: "zero";
} | {
    readonly [__ps$tag$7]: "succ";
    readonly value: PsKernelLevel;
} | {
    readonly [__ps$tag$7]: "max";
    readonly left: PsKernelLevel;
    readonly right: PsKernelLevel;
} | {
    readonly [__ps$tag$7]: "imax";
    readonly left: PsKernelLevel;
    readonly right: PsKernelLevel;
} | {
    readonly [__ps$tag$7]: "param";
    readonly name: PsKernelName;
};
export declare const PsKernelLevel: {
    readonly zero: PsKernelLevel;
    readonly succ: (__field0: PsKernelLevel) => PsKernelLevel;
    readonly max: (__field0: PsKernelLevel, __field1: PsKernelLevel) => PsKernelLevel;
    readonly imax: (__field0: PsKernelLevel, __field1: PsKernelLevel) => PsKernelLevel;
    readonly param: (__field0: PsKernelName) => PsKernelLevel;
};
declare const __ps$tag$8: unique symbol;
export type PsKernelList<T0> = {
    readonly [__ps$tag$8]: "nil";
} | {
    readonly [__ps$tag$8]: "cons";
    readonly head: T0;
    readonly tail: PsKernelList<T0>;
};
export declare const PsKernelList: {
    readonly nil: <T0>() => PsKernelList<T0>;
    readonly cons: <T0>(__field0: T0, __field1: PsKernelList<T0>) => PsKernelList<T0>;
};
declare const __ps$tag$9: unique symbol;
export type PsKernelCompareResult = {
    readonly [__ps$tag$9]: "outOfFuel";
} | {
    readonly [__ps$tag$9]: "equal";
} | {
    readonly [__ps$tag$9]: "different";
};
export declare const PsKernelCompareResult: {
    readonly outOfFuel: PsKernelCompareResult;
    readonly equal: PsKernelCompareResult;
    readonly different: PsKernelCompareResult;
};
declare const __ps$tag$10: unique symbol;
export type PsKernelCompareTask = {
    readonly [__ps$tag$10]: "positive";
    readonly left: PsKernelPositive;
    readonly right: PsKernelPositive;
} | {
    readonly [__ps$tag$10]: "natural";
    readonly left: PsKernelNatural;
    readonly right: PsKernelNatural;
} | {
    readonly [__ps$tag$10]: "name";
    readonly left: PsKernelName;
    readonly right: PsKernelName;
} | {
    readonly [__ps$tag$10]: "text";
    readonly left: PsKernelText;
    readonly right: PsKernelText;
} | {
    readonly [__ps$tag$10]: "level";
    readonly left: PsKernelLevel;
    readonly right: PsKernelLevel;
};
export declare const PsKernelCompareTask: {
    readonly positive: (__field0: PsKernelPositive, __field1: PsKernelPositive) => PsKernelCompareTask;
    readonly natural: (__field0: PsKernelNatural, __field1: PsKernelNatural) => PsKernelCompareTask;
    readonly name: (__field0: PsKernelName, __field1: PsKernelName) => PsKernelCompareTask;
    readonly text: (__field0: PsKernelText, __field1: PsKernelText) => PsKernelCompareTask;
    readonly level: (__field0: PsKernelLevel, __field1: PsKernelLevel) => PsKernelCompareTask;
};
declare const __ps$tag$11: unique symbol;
export type PsKernelFuel = {
    readonly [__ps$tag$11]: "stop";
} | {
    readonly [__ps$tag$11]: "more";
    readonly remaining: PsKernelFuel;
};
export declare const PsKernelFuel: {
    readonly stop: PsKernelFuel;
    readonly more: (__field0: PsKernelFuel) => PsKernelFuel;
};
declare const __ps$tag$12: unique symbol;
export type PsKernelFlag = {
    readonly [__ps$tag$12]: "no";
} | {
    readonly [__ps$tag$12]: "yes";
};
export declare const PsKernelFlag: {
    readonly no: PsKernelFlag;
    readonly yes: PsKernelFlag;
};
declare const __ps$tag$13: unique symbol;
export type PsKernelOrder = {
    readonly [__ps$tag$13]: "less";
} | {
    readonly [__ps$tag$13]: "same";
} | {
    readonly [__ps$tag$13]: "greater";
};
export declare const PsKernelOrder: {
    readonly less: PsKernelOrder;
    readonly same: PsKernelOrder;
    readonly greater: PsKernelOrder;
};
declare const __ps$tag$14: unique symbol;
export type PsKernelBit = {
    readonly [__ps$tag$14]: "zero";
} | {
    readonly [__ps$tag$14]: "one";
};
export declare const PsKernelBit: {
    readonly zero: PsKernelBit;
    readonly one: PsKernelBit;
};
declare const __ps$tag$15: unique symbol;
export type PsKernelDigit = {
    readonly [__ps$tag$15]: "digit";
    readonly low: PsKernelBit;
    readonly high: PsKernelNatural;
};
export declare const PsKernelDigit: {
    readonly digit: (__field0: PsKernelBit, __field1: PsKernelNatural) => PsKernelDigit;
};
declare const __ps$tag$16: unique symbol;
export type PsKernelNumericState = {
    readonly [__ps$tag$16]: "order";
    readonly left: PsKernelNatural;
    readonly right: PsKernelNatural;
    readonly lower: PsKernelOrder;
} | {
    readonly [__ps$tag$16]: "add";
    readonly left: PsKernelNatural;
    readonly right: PsKernelNatural;
    readonly carry: PsKernelBit;
    readonly bits: PsKernelList<PsKernelBit>;
} | {
    readonly [__ps$tag$16]: "rebuild";
    readonly bits: PsKernelList<PsKernelBit>;
    readonly value: PsKernelNatural;
};
export declare const PsKernelNumericState: {
    readonly order: (__field0: PsKernelNatural, __field1: PsKernelNatural, __field2: PsKernelOrder) => PsKernelNumericState;
    readonly add: (__field0: PsKernelNatural, __field1: PsKernelNatural, __field2: PsKernelBit, __field3: PsKernelList<PsKernelBit>) => PsKernelNumericState;
    readonly rebuild: (__field0: PsKernelList<PsKernelBit>, __field1: PsKernelNatural) => PsKernelNumericState;
};
declare const __ps$tag$17: unique symbol;
export type PsKernelNumericStep = {
    readonly [__ps$tag$17]: "next";
    readonly state: PsKernelNumericState;
} | {
    readonly [__ps$tag$17]: "ordered";
    readonly order: PsKernelOrder;
} | {
    readonly [__ps$tag$17]: "sum";
    readonly value: PsKernelNatural;
};
export declare const PsKernelNumericStep: {
    readonly next: (__field0: PsKernelNumericState) => PsKernelNumericStep;
    readonly ordered: (__field0: PsKernelOrder) => PsKernelNumericStep;
    readonly sum: (__field0: PsKernelNatural) => PsKernelNumericStep;
};
declare const __ps$tag$18: unique symbol;
export type PsKernelNumericResult = {
    readonly [__ps$tag$18]: "outOfFuel";
} | {
    readonly [__ps$tag$18]: "ordered";
    readonly order: PsKernelOrder;
} | {
    readonly [__ps$tag$18]: "sum";
    readonly value: PsKernelNatural;
};
export declare const PsKernelNumericResult: {
    readonly outOfFuel: PsKernelNumericResult;
    readonly ordered: (__field0: PsKernelOrder) => PsKernelNumericResult;
    readonly sum: (__field0: PsKernelNatural) => PsKernelNumericResult;
};
declare const __ps$tag$19: unique symbol;
export type PsKernelBinder = {
    readonly [__ps$tag$19]: "explicit";
} | {
    readonly [__ps$tag$19]: "implicit";
} | {
    readonly [__ps$tag$19]: "strictImplicit";
} | {
    readonly [__ps$tag$19]: "instanceImplicit";
};
export declare const PsKernelBinder: {
    readonly explicit: PsKernelBinder;
    readonly implicit: PsKernelBinder;
    readonly strictImplicit: PsKernelBinder;
    readonly instanceImplicit: PsKernelBinder;
};
declare const __ps$tag$20: unique symbol;
export type PsKernelLiteral = {
    readonly [__ps$tag$20]: "natural";
    readonly value: PsKernelNatural;
} | {
    readonly [__ps$tag$20]: "text";
    readonly value: PsKernelText;
};
export declare const PsKernelLiteral: {
    readonly natural: (__field0: PsKernelNatural) => PsKernelLiteral;
    readonly text: (__field0: PsKernelText) => PsKernelLiteral;
};
declare const __ps$tag$21: unique symbol;
export type PsKernelExpr = {
    readonly [__ps$tag$21]: "bvar";
    readonly index: PsKernelNatural;
} | {
    readonly [__ps$tag$21]: "fvar";
    readonly id: PsKernelNatural;
} | {
    readonly [__ps$tag$21]: "sortE";
    readonly level: PsKernelLevel;
} | {
    readonly [__ps$tag$21]: "constE";
    readonly name: PsKernelName;
    readonly levels: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$21]: "app";
    readonly fn: PsKernelExpr;
    readonly arg: PsKernelExpr;
} | {
    readonly [__ps$tag$21]: "lam";
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
    readonly body: PsKernelExpr;
    readonly binder: PsKernelBinder;
} | {
    readonly [__ps$tag$21]: "forallE";
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
    readonly body: PsKernelExpr;
    readonly binder: PsKernelBinder;
} | {
    readonly [__ps$tag$21]: "letE";
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
    readonly value: PsKernelExpr;
    readonly body: PsKernelExpr;
} | {
    readonly [__ps$tag$21]: "lit";
    readonly value: PsKernelLiteral;
} | {
    readonly [__ps$tag$21]: "proj";
    readonly family: PsKernelName;
    readonly index: PsKernelNatural;
    readonly value: PsKernelExpr;
};
export declare const PsKernelExpr: {
    readonly bvar: (__field0: PsKernelNatural) => PsKernelExpr;
    readonly fvar: (__field0: PsKernelNatural) => PsKernelExpr;
    readonly sortE: (__field0: PsKernelLevel) => PsKernelExpr;
    readonly constE: (__field0: PsKernelName, __field1: PsKernelList<PsKernelLevel>) => PsKernelExpr;
    readonly app: (__field0: PsKernelExpr, __field1: PsKernelExpr) => PsKernelExpr;
    readonly lam: (__field0: PsKernelName, __field1: PsKernelExpr, __field2: PsKernelExpr, __field3: PsKernelBinder) => PsKernelExpr;
    readonly forallE: (__field0: PsKernelName, __field1: PsKernelExpr, __field2: PsKernelExpr, __field3: PsKernelBinder) => PsKernelExpr;
    readonly letE: (__field0: PsKernelName, __field1: PsKernelExpr, __field2: PsKernelExpr, __field3: PsKernelExpr) => PsKernelExpr;
    readonly lit: (__field0: PsKernelLiteral) => PsKernelExpr;
    readonly proj: (__field0: PsKernelName, __field1: PsKernelNatural, __field2: PsKernelExpr) => PsKernelExpr;
};
declare const __ps$tag$22: unique symbol;
export type PsKernelBindingMode = {
    readonly [__ps$tag$22]: "lift";
    readonly amount: PsKernelNatural;
} | {
    readonly [__ps$tag$22]: "instantiate";
    readonly replacement: PsKernelExpr;
} | {
    readonly [__ps$tag$22]: "abstract";
    readonly id: PsKernelNatural;
} | {
    readonly [__ps$tag$22]: "closed";
};
export declare const PsKernelBindingMode: {
    readonly lift: (__field0: PsKernelNatural) => PsKernelBindingMode;
    readonly instantiate: (__field0: PsKernelExpr) => PsKernelBindingMode;
    readonly abstract: (__field0: PsKernelNatural) => PsKernelBindingMode;
    readonly closed: PsKernelBindingMode;
};
declare const __ps$tag$23: unique symbol;
export type PsKernelBindingTask = {
    readonly [__ps$tag$23]: "visit";
    readonly mode: PsKernelBindingMode;
    readonly depth: PsKernelNatural;
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$23]: "orderIndex";
    readonly mode: PsKernelBindingMode;
    readonly depth: PsKernelNatural;
    readonly index: PsKernelNatural;
    readonly state: PsKernelNumericState;
} | {
    readonly [__ps$tag$23]: "orderFree";
    readonly depth: PsKernelNatural;
    readonly id: PsKernelNatural;
    readonly state: PsKernelNumericState;
} | {
    readonly [__ps$tag$23]: "sumIndex";
    readonly state: PsKernelNumericState;
} | {
    readonly [__ps$tag$23]: "app";
} | {
    readonly [__ps$tag$23]: "lam";
    readonly name: PsKernelName;
    readonly binder: PsKernelBinder;
} | {
    readonly [__ps$tag$23]: "forallE";
    readonly name: PsKernelName;
    readonly binder: PsKernelBinder;
} | {
    readonly [__ps$tag$23]: "letE";
    readonly name: PsKernelName;
} | {
    readonly [__ps$tag$23]: "proj";
    readonly family: PsKernelName;
    readonly index: PsKernelNatural;
};
export declare const PsKernelBindingTask: {
    readonly visit: (__field0: PsKernelBindingMode, __field1: PsKernelNatural, __field2: PsKernelExpr) => PsKernelBindingTask;
    readonly orderIndex: (__field0: PsKernelBindingMode, __field1: PsKernelNatural, __field2: PsKernelNatural, __field3: PsKernelNumericState) => PsKernelBindingTask;
    readonly orderFree: (__field0: PsKernelNatural, __field1: PsKernelNatural, __field2: PsKernelNumericState) => PsKernelBindingTask;
    readonly sumIndex: (__field0: PsKernelNumericState) => PsKernelBindingTask;
    readonly app: PsKernelBindingTask;
    readonly lam: (__field0: PsKernelName, __field1: PsKernelBinder) => PsKernelBindingTask;
    readonly forallE: (__field0: PsKernelName, __field1: PsKernelBinder) => PsKernelBindingTask;
    readonly letE: (__field0: PsKernelName) => PsKernelBindingTask;
    readonly proj: (__field0: PsKernelName, __field1: PsKernelNatural) => PsKernelBindingTask;
};
declare const __ps$tag$24: unique symbol;
export type PsKernelBindingState = {
    readonly [__ps$tag$24]: "state";
    readonly tasks: PsKernelList<PsKernelBindingTask>;
    readonly values: PsKernelList<PsKernelExpr>;
};
export declare const PsKernelBindingState: {
    readonly state: (__field0: PsKernelList<PsKernelBindingTask>, __field1: PsKernelList<PsKernelExpr>) => PsKernelBindingState;
};
declare const __ps$tag$25: unique symbol;
export type PsKernelBindingResult = {
    readonly [__ps$tag$25]: "outOfFuel";
} | {
    readonly [__ps$tag$25]: "invalidState";
} | {
    readonly [__ps$tag$25]: "invalidScope";
} | {
    readonly [__ps$tag$25]: "done";
    readonly value: PsKernelExpr;
};
export declare const PsKernelBindingResult: {
    readonly outOfFuel: PsKernelBindingResult;
    readonly invalidState: PsKernelBindingResult;
    readonly invalidScope: PsKernelBindingResult;
    readonly done: (__field0: PsKernelExpr) => PsKernelBindingResult;
};
declare const __ps$tag$26: unique symbol;
export type PsKernelBindingStep = {
    readonly [__ps$tag$26]: "next";
    readonly state: PsKernelBindingState;
} | {
    readonly [__ps$tag$26]: "final";
    readonly result: PsKernelBindingResult;
};
export declare const PsKernelBindingStep: {
    readonly next: (__field0: PsKernelBindingState) => PsKernelBindingStep;
    readonly final: (__field0: PsKernelBindingResult) => PsKernelBindingStep;
};
declare const __ps$tag$27: unique symbol;
export type PsKernelOrderTask = {
    readonly [__ps$tag$27]: "name";
    readonly left: PsKernelName;
    readonly right: PsKernelName;
} | {
    readonly [__ps$tag$27]: "text";
    readonly left: PsKernelText;
    readonly right: PsKernelText;
} | {
    readonly [__ps$tag$27]: "level";
    readonly left: PsKernelLevel;
    readonly right: PsKernelLevel;
} | {
    readonly [__ps$tag$27]: "number";
    readonly state: PsKernelNumericState;
};
export declare const PsKernelOrderTask: {
    readonly name: (__field0: PsKernelName, __field1: PsKernelName) => PsKernelOrderTask;
    readonly text: (__field0: PsKernelText, __field1: PsKernelText) => PsKernelOrderTask;
    readonly level: (__field0: PsKernelLevel, __field1: PsKernelLevel) => PsKernelOrderTask;
    readonly number: (__field0: PsKernelNumericState) => PsKernelOrderTask;
};
declare const __ps$tag$28: unique symbol;
export type PsKernelOrderStep = {
    readonly [__ps$tag$28]: "next";
    readonly tasks: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$28]: "done";
    readonly order: PsKernelOrder;
} | {
    readonly [__ps$tag$28]: "invalidState";
};
export declare const PsKernelOrderStep: {
    readonly next: (__field0: PsKernelList<PsKernelOrderTask>) => PsKernelOrderStep;
    readonly done: (__field0: PsKernelOrder) => PsKernelOrderStep;
    readonly invalidState: PsKernelOrderStep;
};
declare const __ps$tag$29: unique symbol;
export type PsKernelLevelOffset = {
    readonly [__ps$tag$29]: "parts";
    readonly base: PsKernelLevel;
    readonly count: PsKernelNatural;
};
export declare const PsKernelLevelOffset: {
    readonly parts: (__field0: PsKernelLevel, __field1: PsKernelNatural) => PsKernelLevelOffset;
};
declare const __ps$tag$30: unique symbol;
export type PsKernelMaxProbe = {
    readonly [__ps$tag$30]: "probe";
    readonly left: PsKernelLevel;
    readonly right: PsKernelLevel;
    readonly result: PsKernelLevel;
};
export declare const PsKernelMaxProbe: {
    readonly probe: (__field0: PsKernelLevel, __field1: PsKernelLevel, __field2: PsKernelLevel) => PsKernelMaxProbe;
};
declare const __ps$tag$31: unique symbol;
export type PsKernelUniverseTask = {
    readonly [__ps$tag$31]: "normalize";
    readonly value: PsKernelLevel;
    readonly offset: PsKernelNatural;
} | {
    readonly [__ps$tag$31]: "joinMax";
    readonly offset: PsKernelNatural;
} | {
    readonly [__ps$tag$31]: "joinIMax";
    readonly offset: PsKernelNatural;
} | {
    readonly [__ps$tag$31]: "wrap";
    readonly value: PsKernelLevel;
    readonly offset: PsKernelNatural;
} | {
    readonly [__ps$tag$31]: "imaxCompare";
    readonly left: PsKernelLevel;
    readonly right: PsKernelLevel;
    readonly offset: PsKernelNatural;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$31]: "maxBases";
    readonly left: PsKernelLevel;
    readonly right: PsKernelLevel;
    readonly offset: PsKernelNatural;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$31]: "maxOffsets";
    readonly left: PsKernelLevel;
    readonly right: PsKernelLevel;
    readonly offset: PsKernelNatural;
    readonly numeric: PsKernelNumericState;
} | {
    readonly [__ps$tag$31]: "probeMax";
    readonly left: PsKernelLevel;
    readonly right: PsKernelLevel;
    readonly offset: PsKernelNatural;
    readonly probes: PsKernelList<PsKernelMaxProbe>;
} | {
    readonly [__ps$tag$31]: "probeCompare";
    readonly left: PsKernelLevel;
    readonly right: PsKernelLevel;
    readonly offset: PsKernelNatural;
    readonly result: PsKernelLevel;
    readonly probes: PsKernelList<PsKernelMaxProbe>;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$31]: "collect";
    readonly offset: PsKernelNatural;
    readonly todo: PsKernelList<PsKernelLevel>;
    readonly leaves: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$31]: "sort";
    readonly offset: PsKernelNatural;
    readonly todo: PsKernelList<PsKernelLevel>;
    readonly sorted: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$31]: "insert";
    readonly offset: PsKernelNatural;
    readonly todo: PsKernelList<PsKernelLevel>;
    readonly candidate: PsKernelLevel;
    readonly scan: PsKernelList<PsKernelLevel>;
    readonly prefixRev: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$31]: "insertCompare";
    readonly offset: PsKernelNatural;
    readonly todo: PsKernelList<PsKernelLevel>;
    readonly candidate: PsKernelLevel;
    readonly current: PsKernelLevel;
    readonly tail: PsKernelList<PsKernelLevel>;
    readonly prefixRev: PsKernelList<PsKernelLevel>;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$31]: "insertOffset";
    readonly offset: PsKernelNatural;
    readonly todo: PsKernelList<PsKernelLevel>;
    readonly candidate: PsKernelLevel;
    readonly current: PsKernelLevel;
    readonly tail: PsKernelList<PsKernelLevel>;
    readonly prefixRev: PsKernelList<PsKernelLevel>;
    readonly numeric: PsKernelNumericState;
} | {
    readonly [__ps$tag$31]: "restore";
    readonly offset: PsKernelNatural;
    readonly todo: PsKernelList<PsKernelLevel>;
    readonly prefixRev: PsKernelList<PsKernelLevel>;
    readonly suffix: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$31]: "prune";
    readonly offset: PsKernelNatural;
    readonly sorted: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$31]: "constantScan";
    readonly offset: PsKernelNatural;
    readonly constant: PsKernelLevel;
    readonly others: PsKernelList<PsKernelLevel>;
    readonly scan: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$31]: "constantCompare";
    readonly offset: PsKernelNatural;
    readonly constant: PsKernelLevel;
    readonly others: PsKernelList<PsKernelLevel>;
    readonly scan: PsKernelList<PsKernelLevel>;
    readonly numeric: PsKernelNumericState;
} | {
    readonly [__ps$tag$31]: "wrapList";
    readonly offset: PsKernelNatural;
    readonly todo: PsKernelList<PsKernelLevel>;
    readonly doneRev: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$31]: "wrapped";
    readonly offset: PsKernelNatural;
    readonly todo: PsKernelList<PsKernelLevel>;
    readonly doneRev: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$31]: "assemble";
    readonly todo: PsKernelList<PsKernelLevel>;
    readonly value: PsKernelLevel;
};
export declare const PsKernelUniverseTask: {
    readonly normalize: (__field0: PsKernelLevel, __field1: PsKernelNatural) => PsKernelUniverseTask;
    readonly joinMax: (__field0: PsKernelNatural) => PsKernelUniverseTask;
    readonly joinIMax: (__field0: PsKernelNatural) => PsKernelUniverseTask;
    readonly wrap: (__field0: PsKernelLevel, __field1: PsKernelNatural) => PsKernelUniverseTask;
    readonly imaxCompare: (__field0: PsKernelLevel, __field1: PsKernelLevel, __field2: PsKernelNatural, __field3: PsKernelList<PsKernelOrderTask>) => PsKernelUniverseTask;
    readonly maxBases: (__field0: PsKernelLevel, __field1: PsKernelLevel, __field2: PsKernelNatural, __field3: PsKernelList<PsKernelOrderTask>) => PsKernelUniverseTask;
    readonly maxOffsets: (__field0: PsKernelLevel, __field1: PsKernelLevel, __field2: PsKernelNatural, __field3: PsKernelNumericState) => PsKernelUniverseTask;
    readonly probeMax: (__field0: PsKernelLevel, __field1: PsKernelLevel, __field2: PsKernelNatural, __field3: PsKernelList<PsKernelMaxProbe>) => PsKernelUniverseTask;
    readonly probeCompare: (__field0: PsKernelLevel, __field1: PsKernelLevel, __field2: PsKernelNatural, __field3: PsKernelLevel, __field4: PsKernelList<PsKernelMaxProbe>, __field5: PsKernelList<PsKernelOrderTask>) => PsKernelUniverseTask;
    readonly collect: (__field0: PsKernelNatural, __field1: PsKernelList<PsKernelLevel>, __field2: PsKernelList<PsKernelLevel>) => PsKernelUniverseTask;
    readonly sort: (__field0: PsKernelNatural, __field1: PsKernelList<PsKernelLevel>, __field2: PsKernelList<PsKernelLevel>) => PsKernelUniverseTask;
    readonly insert: (__field0: PsKernelNatural, __field1: PsKernelList<PsKernelLevel>, __field2: PsKernelLevel, __field3: PsKernelList<PsKernelLevel>, __field4: PsKernelList<PsKernelLevel>) => PsKernelUniverseTask;
    readonly insertCompare: (__field0: PsKernelNatural, __field1: PsKernelList<PsKernelLevel>, __field2: PsKernelLevel, __field3: PsKernelLevel, __field4: PsKernelList<PsKernelLevel>, __field5: PsKernelList<PsKernelLevel>, __field6: PsKernelList<PsKernelOrderTask>) => PsKernelUniverseTask;
    readonly insertOffset: (__field0: PsKernelNatural, __field1: PsKernelList<PsKernelLevel>, __field2: PsKernelLevel, __field3: PsKernelLevel, __field4: PsKernelList<PsKernelLevel>, __field5: PsKernelList<PsKernelLevel>, __field6: PsKernelNumericState) => PsKernelUniverseTask;
    readonly restore: (__field0: PsKernelNatural, __field1: PsKernelList<PsKernelLevel>, __field2: PsKernelList<PsKernelLevel>, __field3: PsKernelList<PsKernelLevel>) => PsKernelUniverseTask;
    readonly prune: (__field0: PsKernelNatural, __field1: PsKernelList<PsKernelLevel>) => PsKernelUniverseTask;
    readonly constantScan: (__field0: PsKernelNatural, __field1: PsKernelLevel, __field2: PsKernelList<PsKernelLevel>, __field3: PsKernelList<PsKernelLevel>) => PsKernelUniverseTask;
    readonly constantCompare: (__field0: PsKernelNatural, __field1: PsKernelLevel, __field2: PsKernelList<PsKernelLevel>, __field3: PsKernelList<PsKernelLevel>, __field4: PsKernelNumericState) => PsKernelUniverseTask;
    readonly wrapList: (__field0: PsKernelNatural, __field1: PsKernelList<PsKernelLevel>, __field2: PsKernelList<PsKernelLevel>) => PsKernelUniverseTask;
    readonly wrapped: (__field0: PsKernelNatural, __field1: PsKernelList<PsKernelLevel>, __field2: PsKernelList<PsKernelLevel>) => PsKernelUniverseTask;
    readonly assemble: (__field0: PsKernelList<PsKernelLevel>, __field1: PsKernelLevel) => PsKernelUniverseTask;
};
declare const __ps$tag$32: unique symbol;
export type PsKernelUniverseState = {
    readonly [__ps$tag$32]: "state";
    readonly tasks: PsKernelList<PsKernelUniverseTask>;
    readonly values: PsKernelList<PsKernelLevel>;
};
export declare const PsKernelUniverseState: {
    readonly state: (__field0: PsKernelList<PsKernelUniverseTask>, __field1: PsKernelList<PsKernelLevel>) => PsKernelUniverseState;
};
declare const __ps$tag$33: unique symbol;
export type PsKernelUniverseResult = {
    readonly [__ps$tag$33]: "outOfFuel";
} | {
    readonly [__ps$tag$33]: "invalidState";
} | {
    readonly [__ps$tag$33]: "done";
    readonly value: PsKernelLevel;
};
export declare const PsKernelUniverseResult: {
    readonly outOfFuel: PsKernelUniverseResult;
    readonly invalidState: PsKernelUniverseResult;
    readonly done: (__field0: PsKernelLevel) => PsKernelUniverseResult;
};
declare const __ps$tag$34: unique symbol;
export type PsKernelUniverseStep = {
    readonly [__ps$tag$34]: "next";
    readonly state: PsKernelUniverseState;
} | {
    readonly [__ps$tag$34]: "final";
    readonly result: PsKernelUniverseResult;
};
export declare const PsKernelUniverseStep: {
    readonly next: (__field0: PsKernelUniverseState) => PsKernelUniverseStep;
    readonly final: (__field0: PsKernelUniverseResult) => PsKernelUniverseStep;
};
declare const __ps$tag$35: unique symbol;
export type PsKernelLevelCheckState = {
    readonly [__ps$tag$35]: "left";
    readonly right: PsKernelLevel;
    readonly state: PsKernelUniverseState;
} | {
    readonly [__ps$tag$35]: "right";
    readonly left: PsKernelLevel;
    readonly state: PsKernelUniverseState;
} | {
    readonly [__ps$tag$35]: "order";
    readonly tasks: PsKernelList<PsKernelOrderTask>;
};
export declare const PsKernelLevelCheckState: {
    readonly left: (__field0: PsKernelLevel, __field1: PsKernelUniverseState) => PsKernelLevelCheckState;
    readonly right: (__field0: PsKernelLevel, __field1: PsKernelUniverseState) => PsKernelLevelCheckState;
    readonly order: (__field0: PsKernelList<PsKernelOrderTask>) => PsKernelLevelCheckState;
};
declare const __ps$tag$36: unique symbol;
export type PsKernelLevelCheckResult = {
    readonly [__ps$tag$36]: "outOfFuel";
} | {
    readonly [__ps$tag$36]: "invalidState";
} | {
    readonly [__ps$tag$36]: "equal";
} | {
    readonly [__ps$tag$36]: "different";
};
export declare const PsKernelLevelCheckResult: {
    readonly outOfFuel: PsKernelLevelCheckResult;
    readonly invalidState: PsKernelLevelCheckResult;
    readonly equal: PsKernelLevelCheckResult;
    readonly different: PsKernelLevelCheckResult;
};
declare const __ps$tag$37: unique symbol;
export type PsKernelLevelCheckStep = {
    readonly [__ps$tag$37]: "next";
    readonly state: PsKernelLevelCheckState;
} | {
    readonly [__ps$tag$37]: "final";
    readonly result: PsKernelLevelCheckResult;
};
export declare const PsKernelLevelCheckStep: {
    readonly next: (__field0: PsKernelLevelCheckState) => PsKernelLevelCheckStep;
    readonly final: (__field0: PsKernelLevelCheckResult) => PsKernelLevelCheckStep;
};
declare const __ps$tag$38: unique symbol;
export type PsKernelLevelAssignment = {
    readonly [__ps$tag$38]: "assignment";
    readonly name: PsKernelName;
    readonly value: PsKernelLevel;
};
export declare const PsKernelLevelAssignment: {
    readonly assignment: (__field0: PsKernelName, __field1: PsKernelLevel) => PsKernelLevelAssignment;
};
declare const __ps$tag$39: unique symbol;
export type PsKernelLevelInstantiateTask = {
    readonly [__ps$tag$39]: "visit";
    readonly value: PsKernelLevel;
} | {
    readonly [__ps$tag$39]: "succ";
} | {
    readonly [__ps$tag$39]: "max";
} | {
    readonly [__ps$tag$39]: "imax";
} | {
    readonly [__ps$tag$39]: "lookup";
    readonly name: PsKernelName;
    readonly remaining: PsKernelList<PsKernelLevelAssignment>;
} | {
    readonly [__ps$tag$39]: "compare";
    readonly name: PsKernelName;
    readonly replacement: PsKernelLevel;
    readonly remaining: PsKernelList<PsKernelLevelAssignment>;
    readonly work: PsKernelList<PsKernelOrderTask>;
};
export declare const PsKernelLevelInstantiateTask: {
    readonly visit: (__field0: PsKernelLevel) => PsKernelLevelInstantiateTask;
    readonly succ: PsKernelLevelInstantiateTask;
    readonly max: PsKernelLevelInstantiateTask;
    readonly imax: PsKernelLevelInstantiateTask;
    readonly lookup: (__field0: PsKernelName, __field1: PsKernelList<PsKernelLevelAssignment>) => PsKernelLevelInstantiateTask;
    readonly compare: (__field0: PsKernelName, __field1: PsKernelLevel, __field2: PsKernelList<PsKernelLevelAssignment>, __field3: PsKernelList<PsKernelOrderTask>) => PsKernelLevelInstantiateTask;
};
declare const __ps$tag$40: unique symbol;
export type PsKernelLevelInstantiateState = {
    readonly [__ps$tag$40]: "parameters";
    readonly names: PsKernelList<PsKernelName>;
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly assignments: PsKernelList<PsKernelLevelAssignment>;
    readonly target: PsKernelLevel;
} | {
    readonly [__ps$tag$40]: "unique";
    readonly name: PsKernelName;
    readonly value: PsKernelLevel;
    readonly names: PsKernelList<PsKernelName>;
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly assignments: PsKernelList<PsKernelLevelAssignment>;
    readonly remaining: PsKernelList<PsKernelLevelAssignment>;
    readonly target: PsKernelLevel;
} | {
    readonly [__ps$tag$40]: "compare";
    readonly name: PsKernelName;
    readonly value: PsKernelLevel;
    readonly names: PsKernelList<PsKernelName>;
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly assignments: PsKernelList<PsKernelLevelAssignment>;
    readonly remaining: PsKernelList<PsKernelLevelAssignment>;
    readonly target: PsKernelLevel;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$40]: "running";
    readonly assignments: PsKernelList<PsKernelLevelAssignment>;
    readonly tasks: PsKernelList<PsKernelLevelInstantiateTask>;
    readonly values: PsKernelList<PsKernelLevel>;
};
export declare const PsKernelLevelInstantiateState: {
    readonly parameters: (__field0: PsKernelList<PsKernelName>, __field1: PsKernelList<PsKernelLevel>, __field2: PsKernelList<PsKernelLevelAssignment>, __field3: PsKernelLevel) => PsKernelLevelInstantiateState;
    readonly unique: (__field0: PsKernelName, __field1: PsKernelLevel, __field2: PsKernelList<PsKernelName>, __field3: PsKernelList<PsKernelLevel>, __field4: PsKernelList<PsKernelLevelAssignment>, __field5: PsKernelList<PsKernelLevelAssignment>, __field6: PsKernelLevel) => PsKernelLevelInstantiateState;
    readonly compare: (__field0: PsKernelName, __field1: PsKernelLevel, __field2: PsKernelList<PsKernelName>, __field3: PsKernelList<PsKernelLevel>, __field4: PsKernelList<PsKernelLevelAssignment>, __field5: PsKernelList<PsKernelLevelAssignment>, __field6: PsKernelLevel, __field7: PsKernelList<PsKernelOrderTask>) => PsKernelLevelInstantiateState;
    readonly running: (__field0: PsKernelList<PsKernelLevelAssignment>, __field1: PsKernelList<PsKernelLevelInstantiateTask>, __field2: PsKernelList<PsKernelLevel>) => PsKernelLevelInstantiateState;
};
declare const __ps$tag$41: unique symbol;
export type PsKernelLevelInstantiateResult = {
    readonly [__ps$tag$41]: "outOfFuel";
} | {
    readonly [__ps$tag$41]: "invalidState";
} | {
    readonly [__ps$tag$41]: "invalidParameters";
} | {
    readonly [__ps$tag$41]: "undeclaredParameter";
} | {
    readonly [__ps$tag$41]: "done";
    readonly value: PsKernelLevel;
};
export declare const PsKernelLevelInstantiateResult: {
    readonly outOfFuel: PsKernelLevelInstantiateResult;
    readonly invalidState: PsKernelLevelInstantiateResult;
    readonly invalidParameters: PsKernelLevelInstantiateResult;
    readonly undeclaredParameter: PsKernelLevelInstantiateResult;
    readonly done: (__field0: PsKernelLevel) => PsKernelLevelInstantiateResult;
};
declare const __ps$tag$42: unique symbol;
export type PsKernelLevelInstantiateStep = {
    readonly [__ps$tag$42]: "next";
    readonly state: PsKernelLevelInstantiateState;
} | {
    readonly [__ps$tag$42]: "final";
    readonly result: PsKernelLevelInstantiateResult;
};
export declare const PsKernelLevelInstantiateStep: {
    readonly next: (__field0: PsKernelLevelInstantiateState) => PsKernelLevelInstantiateStep;
    readonly final: (__field0: PsKernelLevelInstantiateResult) => PsKernelLevelInstantiateStep;
};
declare const __ps$tag$43: unique symbol;
export type PsKernelExprInstantiateTask = {
    readonly [__ps$tag$43]: "validate";
    readonly target: PsKernelExpr;
    readonly state: PsKernelLevelInstantiateState;
} | {
    readonly [__ps$tag$43]: "visit";
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$43]: "sort";
    readonly state: PsKernelLevelInstantiateState;
} | {
    readonly [__ps$tag$43]: "constant";
    readonly name: PsKernelName;
    readonly remaining: PsKernelList<PsKernelLevel>;
    readonly reversed: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$43]: "constantLevel";
    readonly name: PsKernelName;
    readonly remaining: PsKernelList<PsKernelLevel>;
    readonly reversed: PsKernelList<PsKernelLevel>;
    readonly state: PsKernelLevelInstantiateState;
} | {
    readonly [__ps$tag$43]: "constantReverse";
    readonly name: PsKernelName;
    readonly remaining: PsKernelList<PsKernelLevel>;
    readonly levels: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$43]: "rebuild";
    readonly task: PsKernelBindingTask;
};
export declare const PsKernelExprInstantiateTask: {
    readonly validate: (__field0: PsKernelExpr, __field1: PsKernelLevelInstantiateState) => PsKernelExprInstantiateTask;
    readonly visit: (__field0: PsKernelExpr) => PsKernelExprInstantiateTask;
    readonly sort: (__field0: PsKernelLevelInstantiateState) => PsKernelExprInstantiateTask;
    readonly constant: (__field0: PsKernelName, __field1: PsKernelList<PsKernelLevel>, __field2: PsKernelList<PsKernelLevel>) => PsKernelExprInstantiateTask;
    readonly constantLevel: (__field0: PsKernelName, __field1: PsKernelList<PsKernelLevel>, __field2: PsKernelList<PsKernelLevel>, __field3: PsKernelLevelInstantiateState) => PsKernelExprInstantiateTask;
    readonly constantReverse: (__field0: PsKernelName, __field1: PsKernelList<PsKernelLevel>, __field2: PsKernelList<PsKernelLevel>) => PsKernelExprInstantiateTask;
    readonly rebuild: (__field0: PsKernelBindingTask) => PsKernelExprInstantiateTask;
};
declare const __ps$tag$44: unique symbol;
export type PsKernelExprInstantiateState = {
    readonly [__ps$tag$44]: "state";
    readonly names: PsKernelList<PsKernelName>;
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly tasks: PsKernelList<PsKernelExprInstantiateTask>;
    readonly values: PsKernelList<PsKernelExpr>;
};
export declare const PsKernelExprInstantiateState: {
    readonly state: (__field0: PsKernelList<PsKernelName>, __field1: PsKernelList<PsKernelLevel>, __field2: PsKernelList<PsKernelExprInstantiateTask>, __field3: PsKernelList<PsKernelExpr>) => PsKernelExprInstantiateState;
};
declare const __ps$tag$45: unique symbol;
export type PsKernelExprInstantiateResult = {
    readonly [__ps$tag$45]: "outOfFuel";
} | {
    readonly [__ps$tag$45]: "invalidState";
} | {
    readonly [__ps$tag$45]: "invalidParameters";
} | {
    readonly [__ps$tag$45]: "undeclaredParameter";
} | {
    readonly [__ps$tag$45]: "done";
    readonly value: PsKernelExpr;
};
export declare const PsKernelExprInstantiateResult: {
    readonly outOfFuel: PsKernelExprInstantiateResult;
    readonly invalidState: PsKernelExprInstantiateResult;
    readonly invalidParameters: PsKernelExprInstantiateResult;
    readonly undeclaredParameter: PsKernelExprInstantiateResult;
    readonly done: (__field0: PsKernelExpr) => PsKernelExprInstantiateResult;
};
declare const __ps$tag$46: unique symbol;
export type PsKernelExprInstantiateStep = {
    readonly [__ps$tag$46]: "next";
    readonly state: PsKernelExprInstantiateState;
} | {
    readonly [__ps$tag$46]: "final";
    readonly result: PsKernelExprInstantiateResult;
};
export declare const PsKernelExprInstantiateStep: {
    readonly next: (__field0: PsKernelExprInstantiateState) => PsKernelExprInstantiateStep;
    readonly final: (__field0: PsKernelExprInstantiateResult) => PsKernelExprInstantiateStep;
};
declare const __ps$tag$47: unique symbol;
export type PsKernelOption<T0> = {
    readonly [__ps$tag$47]: "none";
} | {
    readonly [__ps$tag$47]: "some";
    readonly value: T0;
};
export declare const PsKernelOption: {
    readonly none: <T0>() => PsKernelOption<T0>;
    readonly some: <T0>(__field0: T0) => PsKernelOption<T0>;
};
declare const __ps$tag$48: unique symbol;
export type PsKernelAlgInputConstructor = {
    readonly [__ps$tag$48]: "constructor";
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
};
export declare const PsKernelAlgInputConstructor: {
    readonly constructor: (__field0: PsKernelName, __field1: PsKernelExpr) => PsKernelAlgInputConstructor;
};
declare const __ps$tag$49: unique symbol;
export type PsKernelAlgDeclaration = {
    readonly [__ps$tag$49]: "declaration";
    readonly name: PsKernelName;
    readonly parameters: PsKernelNatural;
    readonly type: PsKernelExpr;
    readonly constructors: PsKernelList<PsKernelAlgInputConstructor>;
};
export declare const PsKernelAlgDeclaration: {
    readonly declaration: (__field0: PsKernelName, __field1: PsKernelNatural, __field2: PsKernelExpr, __field3: PsKernelList<PsKernelAlgInputConstructor>) => PsKernelAlgDeclaration;
};
declare const __ps$tag$50: unique symbol;
export type PsKernelAlgConstructor = {
    readonly [__ps$tag$50]: "constructor";
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
    readonly fields: PsKernelList<PsKernelExpr>;
};
export declare const PsKernelAlgConstructor: {
    readonly constructor: (__field0: PsKernelName, __field1: PsKernelExpr, __field2: PsKernelList<PsKernelExpr>) => PsKernelAlgConstructor;
};
declare const __ps$tag$51: unique symbol;
export type PsKernelAlgRule = {
    readonly [__ps$tag$51]: "rule";
    readonly constructor: PsKernelName;
    readonly constructorParameters: PsKernelNatural;
    readonly minorIndex: PsKernelNatural;
    readonly recursiveFields: PsKernelList<PsKernelOption<PsKernelName>>;
};
export declare const PsKernelAlgRule: {
    readonly rule: (__field0: PsKernelName, __field1: PsKernelNatural, __field2: PsKernelNatural, __field3: PsKernelList<PsKernelOption<PsKernelName>>) => PsKernelAlgRule;
};
declare const __ps$tag$52: unique symbol;
export type PsKernelAlgBinder = {
    readonly [__ps$tag$52]: "binder";
    readonly id: PsKernelNatural;
    readonly type: PsKernelExpr;
    readonly visibility: PsKernelBinder;
};
export declare const PsKernelAlgBinder: {
    readonly binder: (__field0: PsKernelNatural, __field1: PsKernelExpr, __field2: PsKernelBinder) => PsKernelAlgBinder;
};
declare const __ps$tag$53: unique symbol;
export type PsKernelAlgTargetReference = {
    readonly [__ps$tag$53]: "reference";
    readonly index: PsKernelNatural;
    readonly recursor: PsKernelName;
};
export declare const PsKernelAlgTargetReference: {
    readonly reference: (__field0: PsKernelNatural, __field1: PsKernelName) => PsKernelAlgTargetReference;
};
declare const __ps$tag$54: unique symbol;
export type PsKernelAlgTarget = {
    readonly [__ps$tag$54]: "target";
    readonly type: PsKernelExpr;
    readonly reference: PsKernelAlgTargetReference;
    readonly arguments: PsKernelList<PsKernelExpr>;
    readonly constructors: PsKernelList<PsKernelAlgConstructor>;
};
export declare const PsKernelAlgTarget: {
    readonly target: (__field0: PsKernelExpr, __field1: PsKernelAlgTargetReference, __field2: PsKernelList<PsKernelExpr>, __field3: PsKernelList<PsKernelAlgConstructor>) => PsKernelAlgTarget;
};
declare const __ps$tag$55: unique symbol;
export type PsKernelAlgMinor = {
    readonly [__ps$tag$55]: "minor";
    readonly target: PsKernelAlgTargetReference;
    readonly constructor: PsKernelName;
    readonly arguments: PsKernelList<PsKernelExpr>;
    readonly fields: PsKernelList<PsKernelExpr>;
    readonly recursiveFields: PsKernelList<PsKernelOption<PsKernelAlgTargetReference>>;
};
export declare const PsKernelAlgMinor: {
    readonly minor: (__field0: PsKernelAlgTargetReference, __field1: PsKernelName, __field2: PsKernelList<PsKernelExpr>, __field3: PsKernelList<PsKernelExpr>, __field4: PsKernelList<PsKernelOption<PsKernelAlgTargetReference>>) => PsKernelAlgMinor;
};
declare const __ps$tag$56: unique symbol;
export type PsKernelAlgHeader = {
    readonly [__ps$tag$56]: "header";
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
    readonly parameters: PsKernelNatural;
    readonly arguments: PsKernelList<PsKernelExpr>;
    readonly binders: PsKernelList<PsKernelAlgBinder>;
    readonly uniform: PsKernelExpr;
};
export declare const PsKernelAlgHeader: {
    readonly header: (__field0: PsKernelName, __field1: PsKernelExpr, __field2: PsKernelNatural, __field3: PsKernelList<PsKernelExpr>, __field4: PsKernelList<PsKernelAlgBinder>, __field5: PsKernelExpr) => PsKernelAlgHeader;
};
declare const __ps$tag$57: unique symbol;
export type PsKernelDefinitionBody = {
    readonly [__ps$tag$57]: "transparent";
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$57]: "opaque";
};
export declare const PsKernelDefinitionBody: {
    readonly transparent: (__field0: PsKernelExpr) => PsKernelDefinitionBody;
    readonly opaque: PsKernelDefinitionBody;
};
declare const __ps$tag$58: unique symbol;
export type PsKernelSumRule = {
    readonly [__ps$tag$58]: "rule";
    readonly name: PsKernelName;
    readonly reversedFields: PsKernelList<PsKernelExpr>;
    readonly fieldCount: PsKernelNatural;
};
export declare const PsKernelSumRule: {
    readonly rule: (__field0: PsKernelName, __field1: PsKernelList<PsKernelExpr>, __field2: PsKernelNatural) => PsKernelSumRule;
};
declare const __ps$tag$59: unique symbol;
export type PsKernelDefinition = {
    readonly [__ps$tag$59]: "algebraicFamily";
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
    readonly parameters: PsKernelNatural;
    readonly constructors: PsKernelList<PsKernelAlgConstructor>;
} | {
    readonly [__ps$tag$59]: "algebraicRecursor";
    readonly name: PsKernelName;
    readonly levels: PsKernelList<PsKernelName>;
    readonly type: PsKernelExpr;
    readonly parameters: PsKernelNatural;
    readonly rules: PsKernelList<PsKernelAlgRule>;
} | {
    readonly [__ps$tag$59]: "stringType";
    readonly name: PsKernelName;
} | {
    readonly [__ps$tag$59]: "definition";
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$59]: "polymorphic";
    readonly name: PsKernelName;
    readonly parameters: PsKernelList<PsKernelName>;
    readonly type: PsKernelExpr;
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$59]: "constant";
    readonly name: PsKernelName;
    readonly parameters: PsKernelList<PsKernelName>;
    readonly type: PsKernelExpr;
} | {
    readonly [__ps$tag$59]: "unitRecursor";
    readonly name: PsKernelName;
    readonly parameters: PsKernelList<PsKernelName>;
    readonly type: PsKernelExpr;
    readonly ctorName: PsKernelName;
} | {
    readonly [__ps$tag$59]: "enumRecursor";
    readonly name: PsKernelName;
    readonly parameters: PsKernelList<PsKernelName>;
    readonly type: PsKernelExpr;
    readonly constructors: PsKernelList<PsKernelName>;
} | {
    readonly [__ps$tag$59]: "sumRecursor";
    readonly name: PsKernelName;
    readonly parameters: PsKernelList<PsKernelName>;
    readonly type: PsKernelExpr;
    readonly rules: PsKernelList<PsKernelSumRule>;
} | {
    readonly [__ps$tag$59]: "recordFamily";
    readonly name: PsKernelName;
    readonly ctorName: PsKernelName;
    readonly fields: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$59]: "recordRecursor";
    readonly name: PsKernelName;
    readonly parameters: PsKernelList<PsKernelName>;
    readonly type: PsKernelExpr;
    readonly ctorName: PsKernelName;
    readonly fields: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$59]: "natFamily";
    readonly name: PsKernelName;
    readonly zeroName: PsKernelName;
    readonly succName: PsKernelName;
} | {
    readonly [__ps$tag$59]: "natRecursor";
    readonly name: PsKernelName;
    readonly parameters: PsKernelList<PsKernelName>;
    readonly type: PsKernelExpr;
    readonly zeroName: PsKernelName;
    readonly succName: PsKernelName;
};
export declare const PsKernelDefinition: {
    readonly algebraicFamily: (__field0: PsKernelName, __field1: PsKernelExpr, __field2: PsKernelNatural, __field3: PsKernelList<PsKernelAlgConstructor>) => PsKernelDefinition;
    readonly algebraicRecursor: (__field0: PsKernelName, __field1: PsKernelList<PsKernelName>, __field2: PsKernelExpr, __field3: PsKernelNatural, __field4: PsKernelList<PsKernelAlgRule>) => PsKernelDefinition;
    readonly stringType: (__field0: PsKernelName) => PsKernelDefinition;
    readonly definition: (__field0: PsKernelName, __field1: PsKernelExpr, __field2: PsKernelExpr) => PsKernelDefinition;
    readonly polymorphic: (__field0: PsKernelName, __field1: PsKernelList<PsKernelName>, __field2: PsKernelExpr, __field3: PsKernelExpr) => PsKernelDefinition;
    readonly constant: (__field0: PsKernelName, __field1: PsKernelList<PsKernelName>, __field2: PsKernelExpr) => PsKernelDefinition;
    readonly unitRecursor: (__field0: PsKernelName, __field1: PsKernelList<PsKernelName>, __field2: PsKernelExpr, __field3: PsKernelName) => PsKernelDefinition;
    readonly enumRecursor: (__field0: PsKernelName, __field1: PsKernelList<PsKernelName>, __field2: PsKernelExpr, __field3: PsKernelList<PsKernelName>) => PsKernelDefinition;
    readonly sumRecursor: (__field0: PsKernelName, __field1: PsKernelList<PsKernelName>, __field2: PsKernelExpr, __field3: PsKernelList<PsKernelSumRule>) => PsKernelDefinition;
    readonly recordFamily: (__field0: PsKernelName, __field1: PsKernelName, __field2: PsKernelList<PsKernelExpr>) => PsKernelDefinition;
    readonly recordRecursor: (__field0: PsKernelName, __field1: PsKernelList<PsKernelName>, __field2: PsKernelExpr, __field3: PsKernelName, __field4: PsKernelList<PsKernelExpr>) => PsKernelDefinition;
    readonly natFamily: (__field0: PsKernelName, __field1: PsKernelName, __field2: PsKernelName) => PsKernelDefinition;
    readonly natRecursor: (__field0: PsKernelName, __field1: PsKernelList<PsKernelName>, __field2: PsKernelExpr, __field3: PsKernelName, __field4: PsKernelName) => PsKernelDefinition;
};
declare const __ps$tag$60: unique symbol;
export type PsKernelTypingContext = {
    readonly [__ps$tag$60]: "context";
    readonly declarations: PsKernelList<PsKernelDefinition>;
    readonly parameters: PsKernelList<PsKernelName>;
};
export declare const PsKernelTypingContext: {
    readonly context: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelList<PsKernelName>) => PsKernelTypingContext;
};
declare const __ps$tag$61: unique symbol;
export type PsKernelCheckError = {
    readonly [__ps$tag$61]: "invalidText";
} | {
    readonly [__ps$tag$61]: "invalidState";
} | {
    readonly [__ps$tag$61]: "invalidScope";
} | {
    readonly [__ps$tag$61]: "unknownConstant";
} | {
    readonly [__ps$tag$61]: "unsupported";
} | {
    readonly [__ps$tag$61]: "typeExpected";
} | {
    readonly [__ps$tag$61]: "functionExpected";
} | {
    readonly [__ps$tag$61]: "typeMismatch";
} | {
    readonly [__ps$tag$61]: "duplicateName";
} | {
    readonly [__ps$tag$61]: "invalidName";
} | {
    readonly [__ps$tag$61]: "invalidUniverse";
};
export declare const PsKernelCheckError: {
    readonly invalidText: PsKernelCheckError;
    readonly invalidState: PsKernelCheckError;
    readonly invalidScope: PsKernelCheckError;
    readonly unknownConstant: PsKernelCheckError;
    readonly unsupported: PsKernelCheckError;
    readonly typeExpected: PsKernelCheckError;
    readonly functionExpected: PsKernelCheckError;
    readonly typeMismatch: PsKernelCheckError;
    readonly duplicateName: PsKernelCheckError;
    readonly invalidName: PsKernelCheckError;
    readonly invalidUniverse: PsKernelCheckError;
};
declare const __ps$tag$62: unique symbol;
export type PsKernelLookupState = {
    readonly [__ps$tag$62]: "search";
    readonly name: PsKernelName;
    readonly entries: PsKernelList<PsKernelDefinition>;
} | {
    readonly [__ps$tag$62]: "compare";
    readonly name: PsKernelName;
    readonly entry: PsKernelDefinition;
    readonly rest: PsKernelList<PsKernelDefinition>;
    readonly tasks: PsKernelList<PsKernelOrderTask>;
};
export declare const PsKernelLookupState: {
    readonly search: (__field0: PsKernelName, __field1: PsKernelList<PsKernelDefinition>) => PsKernelLookupState;
    readonly compare: (__field0: PsKernelName, __field1: PsKernelDefinition, __field2: PsKernelList<PsKernelDefinition>, __field3: PsKernelList<PsKernelOrderTask>) => PsKernelLookupState;
};
declare const __ps$tag$63: unique symbol;
export type PsKernelLookupStep = {
    readonly [__ps$tag$63]: "next";
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$63]: "found";
    readonly entry: PsKernelDefinition;
} | {
    readonly [__ps$tag$63]: "missing";
} | {
    readonly [__ps$tag$63]: "invalidState";
};
export declare const PsKernelLookupStep: {
    readonly next: (__field0: PsKernelLookupState) => PsKernelLookupStep;
    readonly found: (__field0: PsKernelDefinition) => PsKernelLookupStep;
    readonly missing: PsKernelLookupStep;
    readonly invalidState: PsKernelLookupStep;
};
declare const __ps$tag$64: unique symbol;
export type PsKernelBuiltinNatState = {
    readonly [__ps$tag$64]: "lookup";
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$64]: "names";
    readonly tasks: PsKernelList<PsKernelOrderTask>;
};
export declare const PsKernelBuiltinNatState: {
    readonly lookup: (__field0: PsKernelLookupState) => PsKernelBuiltinNatState;
    readonly names: (__field0: PsKernelList<PsKernelOrderTask>) => PsKernelBuiltinNatState;
};
declare const __ps$tag$65: unique symbol;
export type PsKernelBuiltinNatStep = {
    readonly [__ps$tag$65]: "next";
    readonly state: PsKernelBuiltinNatState;
} | {
    readonly [__ps$tag$65]: "ready";
} | {
    readonly [__ps$tag$65]: "rejected";
    readonly error: PsKernelCheckError;
};
export declare const PsKernelBuiltinNatStep: {
    readonly next: (__field0: PsKernelBuiltinNatState) => PsKernelBuiltinNatStep;
    readonly ready: PsKernelBuiltinNatStep;
    readonly rejected: (__field0: PsKernelCheckError) => PsKernelBuiltinNatStep;
};
declare const __ps$tag$66: unique symbol;
export type PsKernelUtf8Mode = {
    readonly [__ps$tag$66]: "start";
} | {
    readonly [__ps$tag$66]: "one";
} | {
    readonly [__ps$tag$66]: "two";
} | {
    readonly [__ps$tag$66]: "three";
} | {
    readonly [__ps$tag$66]: "e0";
} | {
    readonly [__ps$tag$66]: "ed";
} | {
    readonly [__ps$tag$66]: "f0";
} | {
    readonly [__ps$tag$66]: "f4";
};
export declare const PsKernelUtf8Mode: {
    readonly start: PsKernelUtf8Mode;
    readonly one: PsKernelUtf8Mode;
    readonly two: PsKernelUtf8Mode;
    readonly three: PsKernelUtf8Mode;
    readonly e0: PsKernelUtf8Mode;
    readonly ed: PsKernelUtf8Mode;
    readonly f0: PsKernelUtf8Mode;
    readonly f4: PsKernelUtf8Mode;
};
declare const __ps$tag$67: unique symbol;
export type PsKernelUtf8Range = {
    readonly [__ps$tag$67]: "range";
    readonly low: PsKernelNatural;
    readonly high: PsKernelNatural;
    readonly next: PsKernelUtf8Mode;
};
export declare const PsKernelUtf8Range: {
    readonly range: (__field0: PsKernelNatural, __field1: PsKernelNatural, __field2: PsKernelUtf8Mode) => PsKernelUtf8Range;
};
declare const __ps$tag$68: unique symbol;
export type PsKernelUtf8State = {
    readonly [__ps$tag$68]: "scan";
    readonly mode: PsKernelUtf8Mode;
    readonly text: PsKernelText;
} | {
    readonly [__ps$tag$68]: "ranges";
    readonly value: PsKernelNatural;
    readonly text: PsKernelText;
    readonly ranges: PsKernelList<PsKernelUtf8Range>;
} | {
    readonly [__ps$tag$68]: "lower";
    readonly value: PsKernelNatural;
    readonly text: PsKernelText;
    readonly high: PsKernelNatural;
    readonly mode: PsKernelUtf8Mode;
    readonly ranges: PsKernelList<PsKernelUtf8Range>;
    readonly state: PsKernelNumericState;
} | {
    readonly [__ps$tag$68]: "upper";
    readonly value: PsKernelNatural;
    readonly text: PsKernelText;
    readonly mode: PsKernelUtf8Mode;
    readonly ranges: PsKernelList<PsKernelUtf8Range>;
    readonly state: PsKernelNumericState;
};
export declare const PsKernelUtf8State: {
    readonly scan: (__field0: PsKernelUtf8Mode, __field1: PsKernelText) => PsKernelUtf8State;
    readonly ranges: (__field0: PsKernelNatural, __field1: PsKernelText, __field2: PsKernelList<PsKernelUtf8Range>) => PsKernelUtf8State;
    readonly lower: (__field0: PsKernelNatural, __field1: PsKernelText, __field2: PsKernelNatural, __field3: PsKernelUtf8Mode, __field4: PsKernelList<PsKernelUtf8Range>, __field5: PsKernelNumericState) => PsKernelUtf8State;
    readonly upper: (__field0: PsKernelNatural, __field1: PsKernelText, __field2: PsKernelUtf8Mode, __field3: PsKernelList<PsKernelUtf8Range>, __field4: PsKernelNumericState) => PsKernelUtf8State;
};
declare const __ps$tag$69: unique symbol;
export type PsKernelUtf8Step = {
    readonly [__ps$tag$69]: "next";
    readonly state: PsKernelUtf8State;
} | {
    readonly [__ps$tag$69]: "valid";
} | {
    readonly [__ps$tag$69]: "invalid";
} | {
    readonly [__ps$tag$69]: "invalidState";
};
export declare const PsKernelUtf8Step: {
    readonly next: (__field0: PsKernelUtf8State) => PsKernelUtf8Step;
    readonly valid: PsKernelUtf8Step;
    readonly invalid: PsKernelUtf8Step;
    readonly invalidState: PsKernelUtf8Step;
};
declare const __ps$tag$70: unique symbol;
export type PsKernelTextCheckState = {
    readonly [__ps$tag$70]: "lookup";
    readonly text: PsKernelText;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$70]: "validate";
    readonly state: PsKernelUtf8State;
};
export declare const PsKernelTextCheckState: {
    readonly lookup: (__field0: PsKernelText, __field1: PsKernelLookupState) => PsKernelTextCheckState;
    readonly validate: (__field0: PsKernelUtf8State) => PsKernelTextCheckState;
};
declare const __ps$tag$71: unique symbol;
export type PsKernelTextCheckStep = {
    readonly [__ps$tag$71]: "next";
    readonly state: PsKernelTextCheckState;
} | {
    readonly [__ps$tag$71]: "ready";
} | {
    readonly [__ps$tag$71]: "rejected";
    readonly error: PsKernelCheckError;
};
export declare const PsKernelTextCheckStep: {
    readonly next: (__field0: PsKernelTextCheckState) => PsKernelTextCheckStep;
    readonly ready: PsKernelTextCheckStep;
    readonly rejected: (__field0: PsKernelCheckError) => PsKernelTextCheckStep;
};
declare const __ps$tag$72: unique symbol;
export type PsKernelStringPreludeState = {
    readonly [__ps$tag$72]: "check";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly state: PsKernelLookupState;
};
export declare const PsKernelStringPreludeState: {
    readonly check: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelLookupState) => PsKernelStringPreludeState;
};
declare const __ps$tag$73: unique symbol;
export type PsKernelStringPreludeStep = {
    readonly [__ps$tag$73]: "next";
    readonly state: PsKernelStringPreludeState;
} | {
    readonly [__ps$tag$73]: "ready";
    readonly environment: PsKernelList<PsKernelDefinition>;
} | {
    readonly [__ps$tag$73]: "rejected";
    readonly error: PsKernelCheckError;
};
export declare const PsKernelStringPreludeStep: {
    readonly next: (__field0: PsKernelStringPreludeState) => PsKernelStringPreludeStep;
    readonly ready: (__field0: PsKernelList<PsKernelDefinition>) => PsKernelStringPreludeStep;
    readonly rejected: (__field0: PsKernelCheckError) => PsKernelStringPreludeStep;
};
declare const __ps$tag$74: unique symbol;
export type PsKernelAlgBranch = {
    readonly [__ps$tag$74]: "branch";
    readonly name: PsKernelName;
    readonly parameters: PsKernelNatural;
    readonly fields: PsKernelList<PsKernelOption<PsKernelName>>;
    readonly minor: PsKernelExpr;
};
export declare const PsKernelAlgBranch: {
    readonly branch: (__field0: PsKernelName, __field1: PsKernelNatural, __field2: PsKernelList<PsKernelOption<PsKernelName>>, __field3: PsKernelExpr) => PsKernelAlgBranch;
};
declare const __ps$tag$75: unique symbol;
export type PsKernelAlgReduceContinuation = {
    readonly [__ps$tag$75]: "continuation";
    readonly recHead: PsKernelExpr;
    readonly branches: PsKernelList<PsKernelAlgBranch>;
};
export declare const PsKernelAlgReduceContinuation: {
    readonly continuation: (__field0: PsKernelExpr, __field1: PsKernelList<PsKernelAlgBranch>) => PsKernelAlgReduceContinuation;
};
declare const __ps$tag$76: unique symbol;
export type PsKernelAlgReduceState = {
    readonly [__ps$tag$76]: "parameters";
    readonly original: PsKernelExpr;
    readonly recHead: PsKernelExpr;
    readonly remaining: PsKernelNatural;
    readonly rules: PsKernelList<PsKernelAlgRule>;
    readonly args: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$76]: "motive";
    readonly original: PsKernelExpr;
    readonly recHead: PsKernelExpr;
    readonly rules: PsKernelList<PsKernelAlgRule>;
    readonly args: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$76]: "minors";
    readonly original: PsKernelExpr;
    readonly recHead: PsKernelExpr;
    readonly rules: PsKernelList<PsKernelAlgRule>;
    readonly args: PsKernelList<PsKernelExpr>;
    readonly branches: PsKernelList<PsKernelAlgBranch>;
} | {
    readonly [__ps$tag$76]: "spine";
    readonly recHead: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly cursor: PsKernelExpr;
    readonly args: PsKernelList<PsKernelExpr>;
    readonly branches: PsKernelList<PsKernelAlgBranch>;
} | {
    readonly [__ps$tag$76]: "find";
    readonly recHead: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly name: PsKernelName;
    readonly args: PsKernelList<PsKernelExpr>;
    readonly branches: PsKernelList<PsKernelAlgBranch>;
} | {
    readonly [__ps$tag$76]: "compare";
    readonly recHead: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly name: PsKernelName;
    readonly args: PsKernelList<PsKernelExpr>;
    readonly branch: PsKernelAlgBranch;
    readonly branches: PsKernelList<PsKernelAlgBranch>;
    readonly tasks: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$76]: "drop";
    readonly recHead: PsKernelExpr;
    readonly minor: PsKernelExpr;
    readonly remaining: PsKernelNatural;
    readonly fields: PsKernelList<PsKernelOption<PsKernelName>>;
    readonly args: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$76]: "fields";
    readonly recHead: PsKernelExpr;
    readonly minor: PsKernelExpr;
    readonly fields: PsKernelList<PsKernelOption<PsKernelName>>;
    readonly args: PsKernelList<PsKernelExpr>;
    readonly recursive: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$76]: "reverse";
    readonly recHead: PsKernelExpr;
    readonly minor: PsKernelExpr;
    readonly pending: PsKernelList<PsKernelExpr>;
    readonly recursive: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$76]: "hypotheses";
    readonly recHead: PsKernelExpr;
    readonly minor: PsKernelExpr;
    readonly recursive: PsKernelList<PsKernelExpr>;
};
export declare const PsKernelAlgReduceState: {
    readonly parameters: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelNatural, __field3: PsKernelList<PsKernelAlgRule>, __field4: PsKernelList<PsKernelExpr>) => PsKernelAlgReduceState;
    readonly motive: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelList<PsKernelAlgRule>, __field3: PsKernelList<PsKernelExpr>) => PsKernelAlgReduceState;
    readonly minors: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelList<PsKernelAlgRule>, __field3: PsKernelList<PsKernelExpr>, __field4: PsKernelList<PsKernelAlgBranch>) => PsKernelAlgReduceState;
    readonly spine: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelExpr, __field3: PsKernelList<PsKernelExpr>, __field4: PsKernelList<PsKernelAlgBranch>) => PsKernelAlgReduceState;
    readonly find: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelName, __field3: PsKernelList<PsKernelExpr>, __field4: PsKernelList<PsKernelAlgBranch>) => PsKernelAlgReduceState;
    readonly compare: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelName, __field3: PsKernelList<PsKernelExpr>, __field4: PsKernelAlgBranch, __field5: PsKernelList<PsKernelAlgBranch>, __field6: PsKernelList<PsKernelOrderTask>) => PsKernelAlgReduceState;
    readonly drop: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelNatural, __field3: PsKernelList<PsKernelOption<PsKernelName>>, __field4: PsKernelList<PsKernelExpr>) => PsKernelAlgReduceState;
    readonly fields: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelList<PsKernelOption<PsKernelName>>, __field3: PsKernelList<PsKernelExpr>, __field4: PsKernelList<PsKernelExpr>) => PsKernelAlgReduceState;
    readonly reverse: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelList<PsKernelExpr>, __field3: PsKernelList<PsKernelExpr>) => PsKernelAlgReduceState;
    readonly hypotheses: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelList<PsKernelExpr>) => PsKernelAlgReduceState;
};
declare const __ps$tag$77: unique symbol;
export type PsKernelAlgReduceStep = {
    readonly [__ps$tag$77]: "next";
    readonly state: PsKernelAlgReduceState;
} | {
    readonly [__ps$tag$77]: "major";
    readonly value: PsKernelExpr;
    readonly continuation: PsKernelAlgReduceContinuation;
} | {
    readonly [__ps$tag$77]: "neutral";
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$77]: "reduced";
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$77]: "rejected";
    readonly error: PsKernelCheckError;
};
export declare const PsKernelAlgReduceStep: {
    readonly next: (__field0: PsKernelAlgReduceState) => PsKernelAlgReduceStep;
    readonly major: (__field0: PsKernelExpr, __field1: PsKernelAlgReduceContinuation) => PsKernelAlgReduceStep;
    readonly neutral: (__field0: PsKernelExpr) => PsKernelAlgReduceStep;
    readonly reduced: (__field0: PsKernelExpr) => PsKernelAlgReduceStep;
    readonly rejected: (__field0: PsKernelCheckError) => PsKernelAlgReduceStep;
};
declare const __ps$tag$78: unique symbol;
export type PsKernelEnumBranch = {
    readonly [__ps$tag$78]: "branch";
    readonly name: PsKernelName;
    readonly minor: PsKernelExpr;
};
export declare const PsKernelEnumBranch: {
    readonly branch: (__field0: PsKernelName, __field1: PsKernelExpr) => PsKernelEnumBranch;
};
declare const __ps$tag$79: unique symbol;
export type PsKernelSumBranch = {
    readonly [__ps$tag$79]: "branch";
    readonly name: PsKernelName;
    readonly fields: PsKernelNatural;
    readonly minor: PsKernelExpr;
};
export declare const PsKernelSumBranch: {
    readonly branch: (__field0: PsKernelName, __field1: PsKernelNatural, __field2: PsKernelExpr) => PsKernelSumBranch;
};
declare const __ps$tag$80: unique symbol;
export type PsKernelRecordAction = {
    readonly [__ps$tag$80]: "project";
    readonly family: PsKernelName;
    readonly index: PsKernelNatural;
} | {
    readonly [__ps$tag$80]: "eliminate";
    readonly fn: PsKernelExpr;
    readonly minor: PsKernelExpr;
};
export declare const PsKernelRecordAction: {
    readonly project: (__field0: PsKernelName, __field1: PsKernelNatural) => PsKernelRecordAction;
    readonly eliminate: (__field0: PsKernelExpr, __field1: PsKernelExpr) => PsKernelRecordAction;
};
declare const __ps$tag$81: unique symbol;
export type PsKernelReduceTask = {
    readonly [__ps$tag$81]: "algebraic";
    readonly state: PsKernelAlgReduceState;
} | {
    readonly [__ps$tag$81]: "algebraicMajor";
    readonly continuation: PsKernelAlgReduceContinuation;
} | {
    readonly [__ps$tag$81]: "sumMinors";
    readonly original: PsKernelExpr;
    readonly rules: PsKernelList<PsKernelSumRule>;
    readonly args: PsKernelList<PsKernelExpr>;
    readonly branches: PsKernelList<PsKernelSumBranch>;
} | {
    readonly [__ps$tag$81]: "sumMajor";
    readonly fn: PsKernelExpr;
    readonly branches: PsKernelList<PsKernelSumBranch>;
} | {
    readonly [__ps$tag$81]: "sumSpine";
    readonly fn: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly cursor: PsKernelExpr;
    readonly args: PsKernelList<PsKernelExpr>;
    readonly branches: PsKernelList<PsKernelSumBranch>;
} | {
    readonly [__ps$tag$81]: "sumFind";
    readonly fn: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly name: PsKernelName;
    readonly args: PsKernelList<PsKernelExpr>;
    readonly branches: PsKernelList<PsKernelSumBranch>;
} | {
    readonly [__ps$tag$81]: "sumName";
    readonly fn: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly name: PsKernelName;
    readonly args: PsKernelList<PsKernelExpr>;
    readonly fields: PsKernelNatural;
    readonly minor: PsKernelExpr;
    readonly remaining: PsKernelList<PsKernelSumBranch>;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$81]: "sumFields";
    readonly minor: PsKernelExpr;
    readonly args: PsKernelList<PsKernelExpr>;
    readonly remaining: PsKernelNatural;
} | {
    readonly [__ps$tag$81]: "enumSpine";
    readonly original: PsKernelExpr;
    readonly cursor: PsKernelExpr;
    readonly args: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$81]: "enumLookup";
    readonly original: PsKernelExpr;
    readonly args: PsKernelList<PsKernelExpr>;
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$81]: "enumMinors";
    readonly original: PsKernelExpr;
    readonly constructors: PsKernelList<PsKernelName>;
    readonly args: PsKernelList<PsKernelExpr>;
    readonly branches: PsKernelList<PsKernelEnumBranch>;
} | {
    readonly [__ps$tag$81]: "enumMajor";
    readonly fn: PsKernelExpr;
    readonly branches: PsKernelList<PsKernelEnumBranch>;
} | {
    readonly [__ps$tag$81]: "enumFind";
    readonly fn: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly name: PsKernelName;
    readonly branches: PsKernelList<PsKernelEnumBranch>;
} | {
    readonly [__ps$tag$81]: "enumName";
    readonly fn: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly name: PsKernelName;
    readonly minor: PsKernelExpr;
    readonly remaining: PsKernelList<PsKernelEnumBranch>;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$81]: "projectLookup";
    readonly family: PsKernelName;
    readonly index: PsKernelNatural;
    readonly major: PsKernelExpr;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$81]: "projectBound";
    readonly family: PsKernelName;
    readonly index: PsKernelNatural;
    readonly major: PsKernelExpr;
    readonly ctor: PsKernelName;
    readonly fields: PsKernelList<PsKernelExpr>;
    readonly pending: PsKernelList<PsKernelExpr>;
    readonly cursor: PsKernelNatural;
} | {
    readonly [__ps$tag$81]: "recordMajor";
    readonly action: PsKernelRecordAction;
    readonly ctor: PsKernelName;
    readonly fields: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$81]: "recordSpine";
    readonly action: PsKernelRecordAction;
    readonly major: PsKernelExpr;
    readonly cursor: PsKernelExpr;
    readonly ctor: PsKernelName;
    readonly fields: PsKernelList<PsKernelExpr>;
    readonly args: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$81]: "recordName";
    readonly action: PsKernelRecordAction;
    readonly major: PsKernelExpr;
    readonly fields: PsKernelList<PsKernelExpr>;
    readonly args: PsKernelList<PsKernelExpr>;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$81]: "recordArity";
    readonly action: PsKernelRecordAction;
    readonly major: PsKernelExpr;
    readonly fields: PsKernelList<PsKernelExpr>;
    readonly args: PsKernelList<PsKernelExpr>;
    readonly original: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$81]: "recordSelect";
    readonly index: PsKernelNatural;
    readonly args: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$81]: "recordApply";
    readonly minor: PsKernelExpr;
    readonly args: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$81]: "proj";
    readonly family: PsKernelName;
    readonly index: PsKernelNatural;
} | {
    readonly [__ps$tag$81]: "text";
    readonly value: PsKernelText;
    readonly state: PsKernelTextCheckState;
} | {
    readonly [__ps$tag$81]: "natural";
    readonly value: PsKernelNatural;
    readonly state: PsKernelBuiltinNatState;
} | {
    readonly [__ps$tag$81]: "whnf";
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$81]: "apply";
    readonly arg: PsKernelExpr;
} | {
    readonly [__ps$tag$81]: "lookup";
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$81]: "unitLookup";
    readonly fn: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly minor: PsKernelExpr;
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$81]: "unitMajor";
    readonly fn: PsKernelExpr;
    readonly minor: PsKernelExpr;
    readonly ctorName: PsKernelName;
    readonly levels: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$81]: "unitName";
    readonly fn: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly minor: PsKernelExpr;
    readonly left: PsKernelList<PsKernelLevel>;
    readonly right: PsKernelList<PsKernelLevel>;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$81]: "unitLevels";
    readonly fn: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly minor: PsKernelExpr;
    readonly left: PsKernelList<PsKernelLevel>;
    readonly right: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$81]: "unitLevel";
    readonly fn: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly minor: PsKernelExpr;
    readonly left: PsKernelList<PsKernelLevel>;
    readonly right: PsKernelList<PsKernelLevel>;
    readonly state: PsKernelLevelCheckState;
} | {
    readonly [__ps$tag$81]: "natLookup";
    readonly fn: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly zeroCase: PsKernelExpr;
    readonly succCase: PsKernelExpr;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$81]: "natMajor";
    readonly fn: PsKernelExpr;
    readonly zeroCase: PsKernelExpr;
    readonly succCase: PsKernelExpr;
    readonly zeroName: PsKernelName;
    readonly succName: PsKernelName;
} | {
    readonly [__ps$tag$81]: "natZeroName";
    readonly fn: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly zeroCase: PsKernelExpr;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$81]: "natSuccName";
    readonly fn: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly succCase: PsKernelExpr;
    readonly predecessor: PsKernelExpr;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$81]: "opaqueConstant";
    readonly value: PsKernelExpr;
    readonly state: PsKernelLevelInstantiateState;
} | {
    readonly [__ps$tag$81]: "instantiate";
    readonly state: PsKernelExprInstantiateState;
} | {
    readonly [__ps$tag$81]: "binding";
    readonly state: PsKernelBindingState;
} | {
    readonly [__ps$tag$81]: "resumeWhnf";
} | {
    readonly [__ps$tag$81]: "normal";
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$81]: "expand";
} | {
    readonly [__ps$tag$81]: "app";
} | {
    readonly [__ps$tag$81]: "lam";
    readonly name: PsKernelName;
    readonly binder: PsKernelBinder;
} | {
    readonly [__ps$tag$81]: "forallE";
    readonly name: PsKernelName;
    readonly binder: PsKernelBinder;
};
export declare const PsKernelReduceTask: {
    readonly algebraic: (__field0: PsKernelAlgReduceState) => PsKernelReduceTask;
    readonly algebraicMajor: (__field0: PsKernelAlgReduceContinuation) => PsKernelReduceTask;
    readonly sumMinors: (__field0: PsKernelExpr, __field1: PsKernelList<PsKernelSumRule>, __field2: PsKernelList<PsKernelExpr>, __field3: PsKernelList<PsKernelSumBranch>) => PsKernelReduceTask;
    readonly sumMajor: (__field0: PsKernelExpr, __field1: PsKernelList<PsKernelSumBranch>) => PsKernelReduceTask;
    readonly sumSpine: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelExpr, __field3: PsKernelList<PsKernelExpr>, __field4: PsKernelList<PsKernelSumBranch>) => PsKernelReduceTask;
    readonly sumFind: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelName, __field3: PsKernelList<PsKernelExpr>, __field4: PsKernelList<PsKernelSumBranch>) => PsKernelReduceTask;
    readonly sumName: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelName, __field3: PsKernelList<PsKernelExpr>, __field4: PsKernelNatural, __field5: PsKernelExpr, __field6: PsKernelList<PsKernelSumBranch>, __field7: PsKernelList<PsKernelOrderTask>) => PsKernelReduceTask;
    readonly sumFields: (__field0: PsKernelExpr, __field1: PsKernelList<PsKernelExpr>, __field2: PsKernelNatural) => PsKernelReduceTask;
    readonly enumSpine: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelList<PsKernelExpr>) => PsKernelReduceTask;
    readonly enumLookup: (__field0: PsKernelExpr, __field1: PsKernelList<PsKernelExpr>, __field2: PsKernelList<PsKernelLevel>, __field3: PsKernelLookupState) => PsKernelReduceTask;
    readonly enumMinors: (__field0: PsKernelExpr, __field1: PsKernelList<PsKernelName>, __field2: PsKernelList<PsKernelExpr>, __field3: PsKernelList<PsKernelEnumBranch>) => PsKernelReduceTask;
    readonly enumMajor: (__field0: PsKernelExpr, __field1: PsKernelList<PsKernelEnumBranch>) => PsKernelReduceTask;
    readonly enumFind: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelName, __field3: PsKernelList<PsKernelEnumBranch>) => PsKernelReduceTask;
    readonly enumName: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelName, __field3: PsKernelExpr, __field4: PsKernelList<PsKernelEnumBranch>, __field5: PsKernelList<PsKernelOrderTask>) => PsKernelReduceTask;
    readonly projectLookup: (__field0: PsKernelName, __field1: PsKernelNatural, __field2: PsKernelExpr, __field3: PsKernelLookupState) => PsKernelReduceTask;
    readonly projectBound: (__field0: PsKernelName, __field1: PsKernelNatural, __field2: PsKernelExpr, __field3: PsKernelName, __field4: PsKernelList<PsKernelExpr>, __field5: PsKernelList<PsKernelExpr>, __field6: PsKernelNatural) => PsKernelReduceTask;
    readonly recordMajor: (__field0: PsKernelRecordAction, __field1: PsKernelName, __field2: PsKernelList<PsKernelExpr>) => PsKernelReduceTask;
    readonly recordSpine: (__field0: PsKernelRecordAction, __field1: PsKernelExpr, __field2: PsKernelExpr, __field3: PsKernelName, __field4: PsKernelList<PsKernelExpr>, __field5: PsKernelList<PsKernelExpr>) => PsKernelReduceTask;
    readonly recordName: (__field0: PsKernelRecordAction, __field1: PsKernelExpr, __field2: PsKernelList<PsKernelExpr>, __field3: PsKernelList<PsKernelExpr>, __field4: PsKernelList<PsKernelOrderTask>) => PsKernelReduceTask;
    readonly recordArity: (__field0: PsKernelRecordAction, __field1: PsKernelExpr, __field2: PsKernelList<PsKernelExpr>, __field3: PsKernelList<PsKernelExpr>, __field4: PsKernelList<PsKernelExpr>) => PsKernelReduceTask;
    readonly recordSelect: (__field0: PsKernelNatural, __field1: PsKernelList<PsKernelExpr>) => PsKernelReduceTask;
    readonly recordApply: (__field0: PsKernelExpr, __field1: PsKernelList<PsKernelExpr>) => PsKernelReduceTask;
    readonly proj: (__field0: PsKernelName, __field1: PsKernelNatural) => PsKernelReduceTask;
    readonly text: (__field0: PsKernelText, __field1: PsKernelTextCheckState) => PsKernelReduceTask;
    readonly natural: (__field0: PsKernelNatural, __field1: PsKernelBuiltinNatState) => PsKernelReduceTask;
    readonly whnf: (__field0: PsKernelExpr) => PsKernelReduceTask;
    readonly apply: (__field0: PsKernelExpr) => PsKernelReduceTask;
    readonly lookup: (__field0: PsKernelList<PsKernelLevel>, __field1: PsKernelLookupState) => PsKernelReduceTask;
    readonly unitLookup: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelExpr, __field3: PsKernelList<PsKernelLevel>, __field4: PsKernelLookupState) => PsKernelReduceTask;
    readonly unitMajor: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelName, __field3: PsKernelList<PsKernelLevel>) => PsKernelReduceTask;
    readonly unitName: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelExpr, __field3: PsKernelList<PsKernelLevel>, __field4: PsKernelList<PsKernelLevel>, __field5: PsKernelList<PsKernelOrderTask>) => PsKernelReduceTask;
    readonly unitLevels: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelExpr, __field3: PsKernelList<PsKernelLevel>, __field4: PsKernelList<PsKernelLevel>) => PsKernelReduceTask;
    readonly unitLevel: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelExpr, __field3: PsKernelList<PsKernelLevel>, __field4: PsKernelList<PsKernelLevel>, __field5: PsKernelLevelCheckState) => PsKernelReduceTask;
    readonly natLookup: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelExpr, __field3: PsKernelExpr, __field4: PsKernelLookupState) => PsKernelReduceTask;
    readonly natMajor: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelExpr, __field3: PsKernelName, __field4: PsKernelName) => PsKernelReduceTask;
    readonly natZeroName: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelExpr, __field3: PsKernelList<PsKernelOrderTask>) => PsKernelReduceTask;
    readonly natSuccName: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelExpr, __field3: PsKernelExpr, __field4: PsKernelList<PsKernelOrderTask>) => PsKernelReduceTask;
    readonly opaqueConstant: (__field0: PsKernelExpr, __field1: PsKernelLevelInstantiateState) => PsKernelReduceTask;
    readonly instantiate: (__field0: PsKernelExprInstantiateState) => PsKernelReduceTask;
    readonly binding: (__field0: PsKernelBindingState) => PsKernelReduceTask;
    readonly resumeWhnf: PsKernelReduceTask;
    readonly normal: (__field0: PsKernelExpr) => PsKernelReduceTask;
    readonly expand: PsKernelReduceTask;
    readonly app: PsKernelReduceTask;
    readonly lam: (__field0: PsKernelName, __field1: PsKernelBinder) => PsKernelReduceTask;
    readonly forallE: (__field0: PsKernelName, __field1: PsKernelBinder) => PsKernelReduceTask;
};
declare const __ps$tag$82: unique symbol;
export type PsKernelReduceState = {
    readonly [__ps$tag$82]: "state";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly tasks: PsKernelList<PsKernelReduceTask>;
    readonly values: PsKernelList<PsKernelExpr>;
};
export declare const PsKernelReduceState: {
    readonly state: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelList<PsKernelReduceTask>, __field2: PsKernelList<PsKernelExpr>) => PsKernelReduceState;
};
declare const __ps$tag$83: unique symbol;
export type PsKernelReduceResult = {
    readonly [__ps$tag$83]: "outOfFuel";
} | {
    readonly [__ps$tag$83]: "rejected";
    readonly error: PsKernelCheckError;
} | {
    readonly [__ps$tag$83]: "done";
    readonly value: PsKernelExpr;
};
export declare const PsKernelReduceResult: {
    readonly outOfFuel: PsKernelReduceResult;
    readonly rejected: (__field0: PsKernelCheckError) => PsKernelReduceResult;
    readonly done: (__field0: PsKernelExpr) => PsKernelReduceResult;
};
declare const __ps$tag$84: unique symbol;
export type PsKernelReduceStep = {
    readonly [__ps$tag$84]: "next";
    readonly state: PsKernelReduceState;
} | {
    readonly [__ps$tag$84]: "final";
    readonly result: PsKernelReduceResult;
};
export declare const PsKernelReduceStep: {
    readonly next: (__field0: PsKernelReduceState) => PsKernelReduceStep;
    readonly final: (__field0: PsKernelReduceResult) => PsKernelReduceStep;
};
declare const __ps$tag$85: unique symbol;
export type PsKernelConversionTask = {
    readonly [__ps$tag$85]: "expr";
    readonly left: PsKernelExpr;
    readonly right: PsKernelExpr;
} | {
    readonly [__ps$tag$85]: "names";
    readonly state: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$85]: "levels";
    readonly left: PsKernelList<PsKernelLevel>;
    readonly right: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$85]: "natural";
    readonly state: PsKernelNumericState;
} | {
    readonly [__ps$tag$85]: "level";
    readonly state: PsKernelLevelCheckState;
};
export declare const PsKernelConversionTask: {
    readonly expr: (__field0: PsKernelExpr, __field1: PsKernelExpr) => PsKernelConversionTask;
    readonly names: (__field0: PsKernelList<PsKernelOrderTask>) => PsKernelConversionTask;
    readonly levels: (__field0: PsKernelList<PsKernelLevel>, __field1: PsKernelList<PsKernelLevel>) => PsKernelConversionTask;
    readonly natural: (__field0: PsKernelNumericState) => PsKernelConversionTask;
    readonly level: (__field0: PsKernelLevelCheckState) => PsKernelConversionTask;
};
declare const __ps$tag$86: unique symbol;
export type PsKernelConversionState = {
    readonly [__ps$tag$86]: "left";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly right: PsKernelExpr;
    readonly state: PsKernelReduceState;
} | {
    readonly [__ps$tag$86]: "right";
    readonly left: PsKernelExpr;
    readonly state: PsKernelReduceState;
} | {
    readonly [__ps$tag$86]: "compare";
    readonly tasks: PsKernelList<PsKernelConversionTask>;
};
export declare const PsKernelConversionState: {
    readonly left: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelExpr, __field2: PsKernelReduceState) => PsKernelConversionState;
    readonly right: (__field0: PsKernelExpr, __field1: PsKernelReduceState) => PsKernelConversionState;
    readonly compare: (__field0: PsKernelList<PsKernelConversionTask>) => PsKernelConversionState;
};
declare const __ps$tag$87: unique symbol;
export type PsKernelConversionResult = {
    readonly [__ps$tag$87]: "outOfFuel";
} | {
    readonly [__ps$tag$87]: "rejected";
    readonly error: PsKernelCheckError;
} | {
    readonly [__ps$tag$87]: "equal";
} | {
    readonly [__ps$tag$87]: "different";
};
export declare const PsKernelConversionResult: {
    readonly outOfFuel: PsKernelConversionResult;
    readonly rejected: (__field0: PsKernelCheckError) => PsKernelConversionResult;
    readonly equal: PsKernelConversionResult;
    readonly different: PsKernelConversionResult;
};
declare const __ps$tag$88: unique symbol;
export type PsKernelConversionStep = {
    readonly [__ps$tag$88]: "next";
    readonly state: PsKernelConversionState;
} | {
    readonly [__ps$tag$88]: "final";
    readonly result: PsKernelConversionResult;
};
export declare const PsKernelConversionStep: {
    readonly next: (__field0: PsKernelConversionState) => PsKernelConversionStep;
    readonly final: (__field0: PsKernelConversionResult) => PsKernelConversionStep;
};
declare const __ps$tag$89: unique symbol;
export type PsKernelTypeTask = {
    readonly [__ps$tag$89]: "text";
    readonly state: PsKernelTextCheckState;
} | {
    readonly [__ps$tag$89]: "natural";
    readonly state: PsKernelBuiltinNatState;
} | {
    readonly [__ps$tag$89]: "infer";
    readonly context: PsKernelList<PsKernelExpr>;
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$89]: "levels";
    readonly pending: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$89]: "levelName";
    readonly name: PsKernelName;
    readonly remaining: PsKernelList<PsKernelName>;
    readonly pending: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$89]: "levelNameCompare";
    readonly name: PsKernelName;
    readonly remaining: PsKernelList<PsKernelName>;
    readonly pending: PsKernelList<PsKernelLevel>;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$89]: "parameterArguments";
    readonly remaining: PsKernelList<PsKernelName>;
    readonly reversed: PsKernelList<PsKernelLevel>;
    readonly value: PsKernelExpr;
    readonly type: PsKernelExpr;
} | {
    readonly [__ps$tag$89]: "parameters";
    readonly state: PsKernelLevelInstantiateState;
    readonly value: PsKernelExpr;
    readonly type: PsKernelExpr;
} | {
    readonly [__ps$tag$89]: "instantiate";
    readonly state: PsKernelExprInstantiateState;
} | {
    readonly [__ps$tag$89]: "bound";
    readonly context: PsKernelList<PsKernelExpr>;
    readonly index: PsKernelNatural;
    readonly shift: PsKernelNatural;
} | {
    readonly [__ps$tag$89]: "lookup";
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$89]: "binding";
    readonly state: PsKernelBindingState;
} | {
    readonly [__ps$tag$89]: "reduce";
    readonly state: PsKernelReduceState;
} | {
    readonly [__ps$tag$89]: "reduceTop";
} | {
    readonly [__ps$tag$89]: "projectType";
    readonly family: PsKernelName;
    readonly index: PsKernelNatural;
} | {
    readonly [__ps$tag$89]: "projectName";
    readonly family: PsKernelName;
    readonly index: PsKernelNatural;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$89]: "projectLookup";
    readonly index: PsKernelNatural;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$89]: "projectField";
    readonly index: PsKernelNatural;
    readonly fields: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$89]: "conversion";
    readonly state: PsKernelConversionState;
} | {
    readonly [__ps$tag$89]: "returnE";
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$89]: "lamSort";
    readonly context: PsKernelList<PsKernelExpr>;
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
    readonly body: PsKernelExpr;
    readonly binder: PsKernelBinder;
} | {
    readonly [__ps$tag$89]: "lamFinish";
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
    readonly binder: PsKernelBinder;
} | {
    readonly [__ps$tag$89]: "piDomain";
    readonly context: PsKernelList<PsKernelExpr>;
    readonly type: PsKernelExpr;
    readonly body: PsKernelExpr;
} | {
    readonly [__ps$tag$89]: "piFinish";
    readonly domainLevel: PsKernelLevel;
} | {
    readonly [__ps$tag$89]: "appPi";
    readonly context: PsKernelList<PsKernelExpr>;
    readonly arg: PsKernelExpr;
} | {
    readonly [__ps$tag$89]: "appArgument";
    readonly domain: PsKernelExpr;
    readonly body: PsKernelExpr;
    readonly arg: PsKernelExpr;
} | {
    readonly [__ps$tag$89]: "letSort";
    readonly context: PsKernelList<PsKernelExpr>;
    readonly type: PsKernelExpr;
    readonly value: PsKernelExpr;
    readonly body: PsKernelExpr;
} | {
    readonly [__ps$tag$89]: "letValue";
    readonly context: PsKernelList<PsKernelExpr>;
    readonly type: PsKernelExpr;
    readonly value: PsKernelExpr;
    readonly body: PsKernelExpr;
} | {
    readonly [__ps$tag$89]: "letBody";
    readonly context: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$89]: "checkSort";
    readonly value: PsKernelExpr;
    readonly type: PsKernelExpr;
} | {
    readonly [__ps$tag$89]: "checkValue";
    readonly type: PsKernelExpr;
};
export declare const PsKernelTypeTask: {
    readonly text: (__field0: PsKernelTextCheckState) => PsKernelTypeTask;
    readonly natural: (__field0: PsKernelBuiltinNatState) => PsKernelTypeTask;
    readonly infer: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelExpr) => PsKernelTypeTask;
    readonly levels: (__field0: PsKernelList<PsKernelLevel>) => PsKernelTypeTask;
    readonly levelName: (__field0: PsKernelName, __field1: PsKernelList<PsKernelName>, __field2: PsKernelList<PsKernelLevel>) => PsKernelTypeTask;
    readonly levelNameCompare: (__field0: PsKernelName, __field1: PsKernelList<PsKernelName>, __field2: PsKernelList<PsKernelLevel>, __field3: PsKernelList<PsKernelOrderTask>) => PsKernelTypeTask;
    readonly parameterArguments: (__field0: PsKernelList<PsKernelName>, __field1: PsKernelList<PsKernelLevel>, __field2: PsKernelExpr, __field3: PsKernelExpr) => PsKernelTypeTask;
    readonly parameters: (__field0: PsKernelLevelInstantiateState, __field1: PsKernelExpr, __field2: PsKernelExpr) => PsKernelTypeTask;
    readonly instantiate: (__field0: PsKernelExprInstantiateState) => PsKernelTypeTask;
    readonly bound: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelNatural, __field2: PsKernelNatural) => PsKernelTypeTask;
    readonly lookup: (__field0: PsKernelList<PsKernelLevel>, __field1: PsKernelLookupState) => PsKernelTypeTask;
    readonly binding: (__field0: PsKernelBindingState) => PsKernelTypeTask;
    readonly reduce: (__field0: PsKernelReduceState) => PsKernelTypeTask;
    readonly reduceTop: PsKernelTypeTask;
    readonly projectType: (__field0: PsKernelName, __field1: PsKernelNatural) => PsKernelTypeTask;
    readonly projectName: (__field0: PsKernelName, __field1: PsKernelNatural, __field2: PsKernelList<PsKernelOrderTask>) => PsKernelTypeTask;
    readonly projectLookup: (__field0: PsKernelNatural, __field1: PsKernelLookupState) => PsKernelTypeTask;
    readonly projectField: (__field0: PsKernelNatural, __field1: PsKernelList<PsKernelExpr>) => PsKernelTypeTask;
    readonly conversion: (__field0: PsKernelConversionState) => PsKernelTypeTask;
    readonly returnE: (__field0: PsKernelExpr) => PsKernelTypeTask;
    readonly lamSort: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelName, __field2: PsKernelExpr, __field3: PsKernelExpr, __field4: PsKernelBinder) => PsKernelTypeTask;
    readonly lamFinish: (__field0: PsKernelName, __field1: PsKernelExpr, __field2: PsKernelBinder) => PsKernelTypeTask;
    readonly piDomain: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelExpr, __field2: PsKernelExpr) => PsKernelTypeTask;
    readonly piFinish: (__field0: PsKernelLevel) => PsKernelTypeTask;
    readonly appPi: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelExpr) => PsKernelTypeTask;
    readonly appArgument: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelExpr) => PsKernelTypeTask;
    readonly letSort: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelExpr, __field2: PsKernelExpr, __field3: PsKernelExpr) => PsKernelTypeTask;
    readonly letValue: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelExpr, __field2: PsKernelExpr, __field3: PsKernelExpr) => PsKernelTypeTask;
    readonly letBody: (__field0: PsKernelList<PsKernelExpr>) => PsKernelTypeTask;
    readonly checkSort: (__field0: PsKernelExpr, __field1: PsKernelExpr) => PsKernelTypeTask;
    readonly checkValue: (__field0: PsKernelExpr) => PsKernelTypeTask;
};
declare const __ps$tag$90: unique symbol;
export type PsKernelTypeState = {
    readonly [__ps$tag$90]: "state";
    readonly environment: PsKernelTypingContext;
    readonly tasks: PsKernelList<PsKernelTypeTask>;
    readonly values: PsKernelList<PsKernelExpr>;
};
export declare const PsKernelTypeState: {
    readonly state: (__field0: PsKernelTypingContext, __field1: PsKernelList<PsKernelTypeTask>, __field2: PsKernelList<PsKernelExpr>) => PsKernelTypeState;
};
declare const __ps$tag$91: unique symbol;
export type PsKernelTypeResult = {
    readonly [__ps$tag$91]: "outOfFuel";
} | {
    readonly [__ps$tag$91]: "rejected";
    readonly error: PsKernelCheckError;
} | {
    readonly [__ps$tag$91]: "done";
    readonly type: PsKernelExpr;
};
export declare const PsKernelTypeResult: {
    readonly outOfFuel: PsKernelTypeResult;
    readonly rejected: (__field0: PsKernelCheckError) => PsKernelTypeResult;
    readonly done: (__field0: PsKernelExpr) => PsKernelTypeResult;
};
declare const __ps$tag$92: unique symbol;
export type PsKernelTypeStep = {
    readonly [__ps$tag$92]: "next";
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$92]: "final";
    readonly result: PsKernelTypeResult;
};
export declare const PsKernelTypeStep: {
    readonly next: (__field0: PsKernelTypeState) => PsKernelTypeStep;
    readonly final: (__field0: PsKernelTypeResult) => PsKernelTypeStep;
};
declare const __ps$tag$93: unique symbol;
export type PsKernelAdmissionState = {
    readonly [__ps$tag$93]: "pending";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly entries: PsKernelList<PsKernelDefinition>;
} | {
    readonly [__ps$tag$93]: "duplicate";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly entry: PsKernelDefinition;
    readonly rest: PsKernelList<PsKernelDefinition>;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$93]: "checking";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly entry: PsKernelDefinition;
    readonly rest: PsKernelList<PsKernelDefinition>;
    readonly state: PsKernelTypeState;
};
export declare const PsKernelAdmissionState: {
    readonly pending: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelList<PsKernelDefinition>) => PsKernelAdmissionState;
    readonly duplicate: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelDefinition, __field2: PsKernelList<PsKernelDefinition>, __field3: PsKernelLookupState) => PsKernelAdmissionState;
    readonly checking: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelDefinition, __field2: PsKernelList<PsKernelDefinition>, __field3: PsKernelTypeState) => PsKernelAdmissionState;
};
declare const __ps$tag$94: unique symbol;
export type PsKernelAdmissionResult = {
    readonly [__ps$tag$94]: "outOfFuel";
} | {
    readonly [__ps$tag$94]: "rejected";
    readonly error: PsKernelCheckError;
} | {
    readonly [__ps$tag$94]: "admitted";
    readonly environment: PsKernelList<PsKernelDefinition>;
};
export declare const PsKernelAdmissionResult: {
    readonly outOfFuel: PsKernelAdmissionResult;
    readonly rejected: (__field0: PsKernelCheckError) => PsKernelAdmissionResult;
    readonly admitted: (__field0: PsKernelList<PsKernelDefinition>) => PsKernelAdmissionResult;
};
declare const __ps$tag$95: unique symbol;
export type PsKernelAdmissionStep = {
    readonly [__ps$tag$95]: "next";
    readonly state: PsKernelAdmissionState;
} | {
    readonly [__ps$tag$95]: "final";
    readonly result: PsKernelAdmissionResult;
};
export declare const PsKernelAdmissionStep: {
    readonly next: (__field0: PsKernelAdmissionState) => PsKernelAdmissionStep;
    readonly final: (__field0: PsKernelAdmissionResult) => PsKernelAdmissionStep;
};
declare const __ps$tag$96: unique symbol;
export type PsKernelUnitDeclaration = {
    readonly [__ps$tag$96]: "declaration";
    readonly name: PsKernelName;
    readonly parameters: PsKernelList<PsKernelName>;
    readonly level: PsKernelLevel;
    readonly ctorName: PsKernelName;
    readonly ctorType: PsKernelExpr;
};
export declare const PsKernelUnitDeclaration: {
    readonly declaration: (__field0: PsKernelName, __field1: PsKernelList<PsKernelName>, __field2: PsKernelLevel, __field3: PsKernelName, __field4: PsKernelExpr) => PsKernelUnitDeclaration;
};
declare const __ps$tag$97: unique symbol;
export type PsKernelUnitTask = {
    readonly [__ps$tag$97]: "initial";
} | {
    readonly [__ps$tag$97]: "parameters";
    readonly remaining: PsKernelList<PsKernelName>;
    readonly reversed: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$97]: "reverse";
    readonly remaining: PsKernelList<PsKernelLevel>;
    readonly levels: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$97]: "validate";
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$97]: "family";
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$97]: "constructorName";
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$97]: "constructorType";
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$97]: "constructorResult";
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly state: PsKernelConversionState;
} | {
    readonly [__ps$tag$97]: "fresh";
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly candidate: PsKernelNatural;
    readonly remaining: PsKernelList<PsKernelName>;
} | {
    readonly [__ps$tag$97]: "freshCompare";
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly candidate: PsKernelNatural;
    readonly remaining: PsKernelList<PsKernelName>;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$97]: "recursorName";
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly motive: PsKernelName;
    readonly state: PsKernelLookupState;
};
export declare const PsKernelUnitTask: {
    readonly initial: PsKernelUnitTask;
    readonly parameters: (__field0: PsKernelList<PsKernelName>, __field1: PsKernelList<PsKernelLevel>) => PsKernelUnitTask;
    readonly reverse: (__field0: PsKernelList<PsKernelLevel>, __field1: PsKernelList<PsKernelLevel>) => PsKernelUnitTask;
    readonly validate: (__field0: PsKernelList<PsKernelLevel>, __field1: PsKernelTypeState) => PsKernelUnitTask;
    readonly family: (__field0: PsKernelList<PsKernelLevel>, __field1: PsKernelLookupState) => PsKernelUnitTask;
    readonly constructorName: (__field0: PsKernelList<PsKernelLevel>, __field1: PsKernelLookupState) => PsKernelUnitTask;
    readonly constructorType: (__field0: PsKernelList<PsKernelLevel>, __field1: PsKernelTypeState) => PsKernelUnitTask;
    readonly constructorResult: (__field0: PsKernelList<PsKernelLevel>, __field1: PsKernelConversionState) => PsKernelUnitTask;
    readonly fresh: (__field0: PsKernelList<PsKernelLevel>, __field1: PsKernelNatural, __field2: PsKernelList<PsKernelName>) => PsKernelUnitTask;
    readonly freshCompare: (__field0: PsKernelList<PsKernelLevel>, __field1: PsKernelNatural, __field2: PsKernelList<PsKernelName>, __field3: PsKernelList<PsKernelOrderTask>) => PsKernelUnitTask;
    readonly recursorName: (__field0: PsKernelList<PsKernelLevel>, __field1: PsKernelName, __field2: PsKernelLookupState) => PsKernelUnitTask;
};
declare const __ps$tag$98: unique symbol;
export type PsKernelUnitState = {
    readonly [__ps$tag$98]: "state";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly declaration: PsKernelUnitDeclaration;
    readonly task: PsKernelUnitTask;
};
export declare const PsKernelUnitState: {
    readonly state: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelUnitDeclaration, __field2: PsKernelUnitTask) => PsKernelUnitState;
};
declare const __ps$tag$99: unique symbol;
export type PsKernelUnitStep = {
    readonly [__ps$tag$99]: "next";
    readonly state: PsKernelUnitState;
} | {
    readonly [__ps$tag$99]: "final";
    readonly result: PsKernelAdmissionResult;
};
export declare const PsKernelUnitStep: {
    readonly next: (__field0: PsKernelUnitState) => PsKernelUnitStep;
    readonly final: (__field0: PsKernelAdmissionResult) => PsKernelUnitStep;
};
declare const __ps$tag$100: unique symbol;
export type PsKernelNatDeclaration = {
    readonly [__ps$tag$100]: "declaration";
    readonly name: PsKernelName;
    readonly familyType: PsKernelExpr;
    readonly zeroName: PsKernelName;
    readonly zeroType: PsKernelExpr;
    readonly succName: PsKernelName;
    readonly succType: PsKernelExpr;
};
export declare const PsKernelNatDeclaration: {
    readonly declaration: (__field0: PsKernelName, __field1: PsKernelExpr, __field2: PsKernelName, __field3: PsKernelExpr, __field4: PsKernelName, __field5: PsKernelExpr) => PsKernelNatDeclaration;
};
declare const __ps$tag$101: unique symbol;
export type PsKernelNatPhase = {
    readonly [__ps$tag$101]: "zero";
} | {
    readonly [__ps$tag$101]: "succ";
};
export declare const PsKernelNatPhase: {
    readonly zero: PsKernelNatPhase;
    readonly succ: PsKernelNatPhase;
};
declare const __ps$tag$102: unique symbol;
export type PsKernelNatAdmissionTask = {
    readonly [__ps$tag$102]: "initial";
} | {
    readonly [__ps$tag$102]: "familyType";
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$102]: "familySort";
    readonly state: PsKernelConversionState;
} | {
    readonly [__ps$tag$102]: "familyName";
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$102]: "ctorName";
    readonly phase: PsKernelNatPhase;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$102]: "ctorType";
    readonly phase: PsKernelNatPhase;
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$102]: "ctorResult";
    readonly phase: PsKernelNatPhase;
    readonly state: PsKernelConversionState;
} | {
    readonly [__ps$tag$102]: "recursorName";
    readonly state: PsKernelLookupState;
};
export declare const PsKernelNatAdmissionTask: {
    readonly initial: PsKernelNatAdmissionTask;
    readonly familyType: (__field0: PsKernelTypeState) => PsKernelNatAdmissionTask;
    readonly familySort: (__field0: PsKernelConversionState) => PsKernelNatAdmissionTask;
    readonly familyName: (__field0: PsKernelLookupState) => PsKernelNatAdmissionTask;
    readonly ctorName: (__field0: PsKernelNatPhase, __field1: PsKernelLookupState) => PsKernelNatAdmissionTask;
    readonly ctorType: (__field0: PsKernelNatPhase, __field1: PsKernelTypeState) => PsKernelNatAdmissionTask;
    readonly ctorResult: (__field0: PsKernelNatPhase, __field1: PsKernelConversionState) => PsKernelNatAdmissionTask;
    readonly recursorName: (__field0: PsKernelLookupState) => PsKernelNatAdmissionTask;
};
declare const __ps$tag$103: unique symbol;
export type PsKernelNatAdmissionState = {
    readonly [__ps$tag$103]: "state";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly declaration: PsKernelNatDeclaration;
    readonly task: PsKernelNatAdmissionTask;
};
export declare const PsKernelNatAdmissionState: {
    readonly state: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelNatDeclaration, __field2: PsKernelNatAdmissionTask) => PsKernelNatAdmissionState;
};
declare const __ps$tag$104: unique symbol;
export type PsKernelNatAdmissionStep = {
    readonly [__ps$tag$104]: "next";
    readonly state: PsKernelNatAdmissionState;
} | {
    readonly [__ps$tag$104]: "final";
    readonly result: PsKernelAdmissionResult;
};
export declare const PsKernelNatAdmissionStep: {
    readonly next: (__field0: PsKernelNatAdmissionState) => PsKernelNatAdmissionStep;
    readonly final: (__field0: PsKernelAdmissionResult) => PsKernelNatAdmissionStep;
};
declare const __ps$tag$105: unique symbol;
export type PsKernelRecordTask = {
    readonly [__ps$tag$105]: "initial";
} | {
    readonly [__ps$tag$105]: "familyName";
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$105]: "fields";
    readonly remaining: PsKernelExpr;
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly count: PsKernelNatural;
} | {
    readonly [__ps$tag$105]: "fieldType";
    readonly remaining: PsKernelExpr;
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly count: PsKernelNatural;
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$105]: "result";
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly count: PsKernelNatural;
    readonly tasks: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$105]: "constructorType";
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly count: PsKernelNatural;
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$105]: "constructorName";
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly count: PsKernelNatural;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$105]: "recursorName";
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly count: PsKernelNatural;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$105]: "arguments";
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly count: PsKernelNatural;
    readonly index: PsKernelNatural;
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$105]: "minor";
    readonly remaining: PsKernelList<PsKernelExpr>;
    readonly fields: PsKernelList<PsKernelExpr>;
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$105]: "recursorType";
    readonly fields: PsKernelList<PsKernelExpr>;
    readonly type: PsKernelExpr;
    readonly state: PsKernelTypeState;
};
export declare const PsKernelRecordTask: {
    readonly initial: PsKernelRecordTask;
    readonly familyName: (__field0: PsKernelLookupState) => PsKernelRecordTask;
    readonly fields: (__field0: PsKernelExpr, __field1: PsKernelList<PsKernelExpr>, __field2: PsKernelNatural) => PsKernelRecordTask;
    readonly fieldType: (__field0: PsKernelExpr, __field1: PsKernelList<PsKernelExpr>, __field2: PsKernelNatural, __field3: PsKernelTypeState) => PsKernelRecordTask;
    readonly result: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelNatural, __field2: PsKernelList<PsKernelOrderTask>) => PsKernelRecordTask;
    readonly constructorType: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelNatural, __field2: PsKernelTypeState) => PsKernelRecordTask;
    readonly constructorName: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelNatural, __field2: PsKernelLookupState) => PsKernelRecordTask;
    readonly recursorName: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelNatural, __field2: PsKernelLookupState) => PsKernelRecordTask;
    readonly arguments: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelNatural, __field2: PsKernelNatural, __field3: PsKernelExpr) => PsKernelRecordTask;
    readonly minor: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelList<PsKernelExpr>, __field2: PsKernelExpr) => PsKernelRecordTask;
    readonly recursorType: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelExpr, __field2: PsKernelTypeState) => PsKernelRecordTask;
};
declare const __ps$tag$106: unique symbol;
export type PsKernelRecordState = {
    readonly [__ps$tag$106]: "state";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly declaration: PsKernelUnitDeclaration;
    readonly task: PsKernelRecordTask;
};
export declare const PsKernelRecordState: {
    readonly state: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelUnitDeclaration, __field2: PsKernelRecordTask) => PsKernelRecordState;
};
declare const __ps$tag$107: unique symbol;
export type PsKernelRecordStep = {
    readonly [__ps$tag$107]: "next";
    readonly state: PsKernelRecordState;
} | {
    readonly [__ps$tag$107]: "final";
    readonly result: PsKernelAdmissionResult;
};
export declare const PsKernelRecordStep: {
    readonly next: (__field0: PsKernelRecordState) => PsKernelRecordStep;
    readonly final: (__field0: PsKernelAdmissionResult) => PsKernelRecordStep;
};
declare const __ps$tag$108: unique symbol;
export type PsKernelEnumConstructor = {
    readonly [__ps$tag$108]: "ctor";
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
};
export declare const PsKernelEnumConstructor: {
    readonly ctor: (__field0: PsKernelName, __field1: PsKernelExpr) => PsKernelEnumConstructor;
};
declare const __ps$tag$109: unique symbol;
export type PsKernelEnumDeclaration = {
    readonly [__ps$tag$109]: "declaration";
    readonly name: PsKernelName;
    readonly parameters: PsKernelList<PsKernelName>;
    readonly level: PsKernelLevel;
    readonly constructors: PsKernelList<PsKernelEnumConstructor>;
};
export declare const PsKernelEnumDeclaration: {
    readonly declaration: (__field0: PsKernelName, __field1: PsKernelList<PsKernelName>, __field2: PsKernelLevel, __field3: PsKernelList<PsKernelEnumConstructor>) => PsKernelEnumDeclaration;
};
declare const __ps$tag$110: unique symbol;
export type PsKernelEnumTask = {
    readonly [__ps$tag$110]: "initial";
} | {
    readonly [__ps$tag$110]: "familyName";
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$110]: "constructors";
    readonly pending: PsKernelList<PsKernelEnumConstructor>;
    readonly current: PsKernelList<PsKernelDefinition>;
    readonly reversed: PsKernelList<PsKernelName>;
    readonly count: PsKernelNatural;
} | {
    readonly [__ps$tag$110]: "constructorName";
    readonly pending: PsKernelList<PsKernelEnumConstructor>;
    readonly current: PsKernelList<PsKernelDefinition>;
    readonly reversed: PsKernelList<PsKernelName>;
    readonly count: PsKernelNatural;
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$110]: "constructorResult";
    readonly pending: PsKernelList<PsKernelEnumConstructor>;
    readonly current: PsKernelList<PsKernelDefinition>;
    readonly reversed: PsKernelList<PsKernelName>;
    readonly count: PsKernelNatural;
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$110]: "constructorType";
    readonly pending: PsKernelList<PsKernelEnumConstructor>;
    readonly current: PsKernelList<PsKernelDefinition>;
    readonly reversed: PsKernelList<PsKernelName>;
    readonly count: PsKernelNatural;
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$110]: "recursorName";
    readonly current: PsKernelList<PsKernelDefinition>;
    readonly reversed: PsKernelList<PsKernelName>;
    readonly count: PsKernelNatural;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$110]: "minors";
    readonly current: PsKernelList<PsKernelDefinition>;
    readonly pending: PsKernelList<PsKernelName>;
    readonly forward: PsKernelList<PsKernelName>;
    readonly count: PsKernelNatural;
    readonly body: PsKernelExpr;
} | {
    readonly [__ps$tag$110]: "recursorType";
    readonly current: PsKernelList<PsKernelDefinition>;
    readonly constructors: PsKernelList<PsKernelName>;
    readonly type: PsKernelExpr;
    readonly state: PsKernelTypeState;
};
export declare const PsKernelEnumTask: {
    readonly initial: PsKernelEnumTask;
    readonly familyName: (__field0: PsKernelLookupState) => PsKernelEnumTask;
    readonly constructors: (__field0: PsKernelList<PsKernelEnumConstructor>, __field1: PsKernelList<PsKernelDefinition>, __field2: PsKernelList<PsKernelName>, __field3: PsKernelNatural) => PsKernelEnumTask;
    readonly constructorName: (__field0: PsKernelList<PsKernelEnumConstructor>, __field1: PsKernelList<PsKernelDefinition>, __field2: PsKernelList<PsKernelName>, __field3: PsKernelNatural, __field4: PsKernelName, __field5: PsKernelExpr, __field6: PsKernelLookupState) => PsKernelEnumTask;
    readonly constructorResult: (__field0: PsKernelList<PsKernelEnumConstructor>, __field1: PsKernelList<PsKernelDefinition>, __field2: PsKernelList<PsKernelName>, __field3: PsKernelNatural, __field4: PsKernelName, __field5: PsKernelExpr, __field6: PsKernelList<PsKernelOrderTask>) => PsKernelEnumTask;
    readonly constructorType: (__field0: PsKernelList<PsKernelEnumConstructor>, __field1: PsKernelList<PsKernelDefinition>, __field2: PsKernelList<PsKernelName>, __field3: PsKernelNatural, __field4: PsKernelName, __field5: PsKernelExpr, __field6: PsKernelTypeState) => PsKernelEnumTask;
    readonly recursorName: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelList<PsKernelName>, __field2: PsKernelNatural, __field3: PsKernelLookupState) => PsKernelEnumTask;
    readonly minors: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelList<PsKernelName>, __field2: PsKernelList<PsKernelName>, __field3: PsKernelNatural, __field4: PsKernelExpr) => PsKernelEnumTask;
    readonly recursorType: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelList<PsKernelName>, __field2: PsKernelExpr, __field3: PsKernelTypeState) => PsKernelEnumTask;
};
declare const __ps$tag$111: unique symbol;
export type PsKernelEnumState = {
    readonly [__ps$tag$111]: "state";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly declaration: PsKernelEnumDeclaration;
    readonly task: PsKernelEnumTask;
};
export declare const PsKernelEnumState: {
    readonly state: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelEnumDeclaration, __field2: PsKernelEnumTask) => PsKernelEnumState;
};
declare const __ps$tag$112: unique symbol;
export type PsKernelEnumStep = {
    readonly [__ps$tag$112]: "next";
    readonly state: PsKernelEnumState;
} | {
    readonly [__ps$tag$112]: "final";
    readonly result: PsKernelAdmissionResult;
};
export declare const PsKernelEnumStep: {
    readonly next: (__field0: PsKernelEnumState) => PsKernelEnumStep;
    readonly final: (__field0: PsKernelAdmissionResult) => PsKernelEnumStep;
};
declare const __ps$tag$113: unique symbol;
export type PsKernelSumProgress = {
    readonly [__ps$tag$113]: "progress";
    readonly pending: PsKernelList<PsKernelEnumConstructor>;
    readonly current: PsKernelList<PsKernelDefinition>;
    readonly reversed: PsKernelList<PsKernelSumRule>;
    readonly count: PsKernelNatural;
};
export declare const PsKernelSumProgress: {
    readonly progress: (__field0: PsKernelList<PsKernelEnumConstructor>, __field1: PsKernelList<PsKernelDefinition>, __field2: PsKernelList<PsKernelSumRule>, __field3: PsKernelNatural) => PsKernelSumProgress;
};
declare const __ps$tag$114: unique symbol;
export type PsKernelSumMinorContext = {
    readonly [__ps$tag$114]: "context";
    readonly current: PsKernelList<PsKernelDefinition>;
    readonly pending: PsKernelList<PsKernelSumRule>;
    readonly forward: PsKernelList<PsKernelSumRule>;
    readonly count: PsKernelNatural;
    readonly body: PsKernelExpr;
};
export declare const PsKernelSumMinorContext: {
    readonly context: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelList<PsKernelSumRule>, __field2: PsKernelList<PsKernelSumRule>, __field3: PsKernelNatural, __field4: PsKernelExpr) => PsKernelSumMinorContext;
};
declare const __ps$tag$115: unique symbol;
export type PsKernelSumTask = {
    readonly [__ps$tag$115]: "initial";
} | {
    readonly [__ps$tag$115]: "selectNat";
    readonly zero: PsKernelEnumConstructor;
    readonly successor: PsKernelEnumConstructor;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$115]: "natAdmission";
    readonly state: PsKernelNatAdmissionState;
} | {
    readonly [__ps$tag$115]: "familyName";
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$115]: "constructors";
    readonly progress: PsKernelSumProgress;
} | {
    readonly [__ps$tag$115]: "constructorName";
    readonly progress: PsKernelSumProgress;
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$115]: "fields";
    readonly progress: PsKernelSumProgress;
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
    readonly remaining: PsKernelExpr;
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly count: PsKernelNatural;
} | {
    readonly [__ps$tag$115]: "fieldType";
    readonly progress: PsKernelSumProgress;
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
    readonly remaining: PsKernelExpr;
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly count: PsKernelNatural;
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$115]: "result";
    readonly progress: PsKernelSumProgress;
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly count: PsKernelNatural;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$115]: "constructorType";
    readonly progress: PsKernelSumProgress;
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly count: PsKernelNatural;
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$115]: "recursorName";
    readonly current: PsKernelList<PsKernelDefinition>;
    readonly reversed: PsKernelList<PsKernelSumRule>;
    readonly count: PsKernelNatural;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$115]: "minors";
    readonly current: PsKernelList<PsKernelDefinition>;
    readonly pending: PsKernelList<PsKernelSumRule>;
    readonly forward: PsKernelList<PsKernelSumRule>;
    readonly count: PsKernelNatural;
    readonly body: PsKernelExpr;
} | {
    readonly [__ps$tag$115]: "arguments";
    readonly context: PsKernelSumMinorContext;
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly index: PsKernelNatural;
    readonly motiveIndex: PsKernelNatural;
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$115]: "minor";
    readonly context: PsKernelSumMinorContext;
    readonly remaining: PsKernelList<PsKernelExpr>;
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$115]: "recursorType";
    readonly current: PsKernelList<PsKernelDefinition>;
    readonly rules: PsKernelList<PsKernelSumRule>;
    readonly type: PsKernelExpr;
    readonly state: PsKernelTypeState;
};
export declare const PsKernelSumTask: {
    readonly initial: PsKernelSumTask;
    readonly selectNat: (__field0: PsKernelEnumConstructor, __field1: PsKernelEnumConstructor, __field2: PsKernelList<PsKernelOrderTask>) => PsKernelSumTask;
    readonly natAdmission: (__field0: PsKernelNatAdmissionState) => PsKernelSumTask;
    readonly familyName: (__field0: PsKernelLookupState) => PsKernelSumTask;
    readonly constructors: (__field0: PsKernelSumProgress) => PsKernelSumTask;
    readonly constructorName: (__field0: PsKernelSumProgress, __field1: PsKernelName, __field2: PsKernelExpr, __field3: PsKernelLookupState) => PsKernelSumTask;
    readonly fields: (__field0: PsKernelSumProgress, __field1: PsKernelName, __field2: PsKernelExpr, __field3: PsKernelExpr, __field4: PsKernelList<PsKernelExpr>, __field5: PsKernelNatural) => PsKernelSumTask;
    readonly fieldType: (__field0: PsKernelSumProgress, __field1: PsKernelName, __field2: PsKernelExpr, __field3: PsKernelExpr, __field4: PsKernelList<PsKernelExpr>, __field5: PsKernelNatural, __field6: PsKernelTypeState) => PsKernelSumTask;
    readonly result: (__field0: PsKernelSumProgress, __field1: PsKernelName, __field2: PsKernelExpr, __field3: PsKernelList<PsKernelExpr>, __field4: PsKernelNatural, __field5: PsKernelList<PsKernelOrderTask>) => PsKernelSumTask;
    readonly constructorType: (__field0: PsKernelSumProgress, __field1: PsKernelName, __field2: PsKernelExpr, __field3: PsKernelList<PsKernelExpr>, __field4: PsKernelNatural, __field5: PsKernelTypeState) => PsKernelSumTask;
    readonly recursorName: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelList<PsKernelSumRule>, __field2: PsKernelNatural, __field3: PsKernelLookupState) => PsKernelSumTask;
    readonly minors: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelList<PsKernelSumRule>, __field2: PsKernelList<PsKernelSumRule>, __field3: PsKernelNatural, __field4: PsKernelExpr) => PsKernelSumTask;
    readonly arguments: (__field0: PsKernelSumMinorContext, __field1: PsKernelList<PsKernelExpr>, __field2: PsKernelNatural, __field3: PsKernelNatural, __field4: PsKernelExpr) => PsKernelSumTask;
    readonly minor: (__field0: PsKernelSumMinorContext, __field1: PsKernelList<PsKernelExpr>, __field2: PsKernelExpr) => PsKernelSumTask;
    readonly recursorType: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelList<PsKernelSumRule>, __field2: PsKernelExpr, __field3: PsKernelTypeState) => PsKernelSumTask;
};
declare const __ps$tag$116: unique symbol;
export type PsKernelSumState = {
    readonly [__ps$tag$116]: "state";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly declaration: PsKernelEnumDeclaration;
    readonly task: PsKernelSumTask;
};
export declare const PsKernelSumState: {
    readonly state: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelEnumDeclaration, __field2: PsKernelSumTask) => PsKernelSumState;
};
declare const __ps$tag$117: unique symbol;
export type PsKernelSumStep = {
    readonly [__ps$tag$117]: "next";
    readonly state: PsKernelSumState;
} | {
    readonly [__ps$tag$117]: "final";
    readonly result: PsKernelAdmissionResult;
};
export declare const PsKernelSumStep: {
    readonly next: (__field0: PsKernelSumState) => PsKernelSumStep;
    readonly final: (__field0: PsKernelAdmissionResult) => PsKernelSumStep;
};
declare const __ps$tag$118: unique symbol;
export type PsKernelAlgHeaderTask = {
    readonly [__ps$tag$118]: "initial";
} | {
    readonly [__ps$tag$118]: "scope";
    readonly state: PsKernelBindingState;
} | {
    readonly [__ps$tag$118]: "name";
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$118]: "type";
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$118]: "parameters";
    readonly remainingType: PsKernelExpr;
    readonly remaining: PsKernelNatural;
    readonly nextId: PsKernelNatural;
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly binders: PsKernelList<PsKernelAlgBinder>;
    readonly uniform: PsKernelExpr;
} | {
    readonly [__ps$tag$118]: "reverse";
    readonly pending: PsKernelList<PsKernelExpr>;
    readonly arguments: PsKernelList<PsKernelExpr>;
    readonly binders: PsKernelList<PsKernelAlgBinder>;
    readonly uniform: PsKernelExpr;
};
export declare const PsKernelAlgHeaderTask: {
    readonly initial: PsKernelAlgHeaderTask;
    readonly scope: (__field0: PsKernelBindingState) => PsKernelAlgHeaderTask;
    readonly name: (__field0: PsKernelLookupState) => PsKernelAlgHeaderTask;
    readonly type: (__field0: PsKernelTypeState) => PsKernelAlgHeaderTask;
    readonly parameters: (__field0: PsKernelExpr, __field1: PsKernelNatural, __field2: PsKernelNatural, __field3: PsKernelList<PsKernelExpr>, __field4: PsKernelList<PsKernelAlgBinder>, __field5: PsKernelExpr) => PsKernelAlgHeaderTask;
    readonly reverse: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelList<PsKernelExpr>, __field2: PsKernelList<PsKernelAlgBinder>, __field3: PsKernelExpr) => PsKernelAlgHeaderTask;
};
declare const __ps$tag$119: unique symbol;
export type PsKernelAlgHeaderState = {
    readonly [__ps$tag$119]: "state";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly declaration: PsKernelAlgDeclaration;
    readonly task: PsKernelAlgHeaderTask;
};
export declare const PsKernelAlgHeaderState: {
    readonly state: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelAlgDeclaration, __field2: PsKernelAlgHeaderTask) => PsKernelAlgHeaderState;
};
declare const __ps$tag$120: unique symbol;
export type PsKernelAlgHeaderStep = {
    readonly [__ps$tag$120]: "next";
    readonly state: PsKernelAlgHeaderState;
} | {
    readonly [__ps$tag$120]: "accepted";
    readonly header: PsKernelAlgHeader;
} | {
    readonly [__ps$tag$120]: "rejected";
    readonly error: PsKernelCheckError;
};
export declare const PsKernelAlgHeaderStep: {
    readonly next: (__field0: PsKernelAlgHeaderState) => PsKernelAlgHeaderStep;
    readonly accepted: (__field0: PsKernelAlgHeader) => PsKernelAlgHeaderStep;
    readonly rejected: (__field0: PsKernelCheckError) => PsKernelAlgHeaderStep;
};
declare const __ps$tag$121: unique symbol;
export type PsKernelCloseMode = {
    readonly [__ps$tag$121]: "pi";
} | {
    readonly [__ps$tag$121]: "lambda";
};
export declare const PsKernelCloseMode: {
    readonly pi: PsKernelCloseMode;
    readonly lambda: PsKernelCloseMode;
};
declare const __ps$tag$122: unique symbol;
export type PsKernelCloseTask = {
    readonly [__ps$tag$122]: "binders";
    readonly pending: PsKernelList<PsKernelAlgBinder>;
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$122]: "abstract";
    readonly binder: PsKernelAlgBinder;
    readonly pending: PsKernelList<PsKernelAlgBinder>;
    readonly state: PsKernelBindingState;
};
export declare const PsKernelCloseTask: {
    readonly binders: (__field0: PsKernelList<PsKernelAlgBinder>, __field1: PsKernelExpr) => PsKernelCloseTask;
    readonly abstract: (__field0: PsKernelAlgBinder, __field1: PsKernelList<PsKernelAlgBinder>, __field2: PsKernelBindingState) => PsKernelCloseTask;
};
declare const __ps$tag$123: unique symbol;
export type PsKernelCloseState = {
    readonly [__ps$tag$123]: "state";
    readonly mode: PsKernelCloseMode;
    readonly task: PsKernelCloseTask;
};
export declare const PsKernelCloseState: {
    readonly state: (__field0: PsKernelCloseMode, __field1: PsKernelCloseTask) => PsKernelCloseState;
};
declare const __ps$tag$124: unique symbol;
export type PsKernelCloseStep = {
    readonly [__ps$tag$124]: "next";
    readonly state: PsKernelCloseState;
} | {
    readonly [__ps$tag$124]: "done";
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$124]: "invalidState";
};
export declare const PsKernelCloseStep: {
    readonly next: (__field0: PsKernelCloseState) => PsKernelCloseStep;
    readonly done: (__field0: PsKernelExpr) => PsKernelCloseStep;
    readonly invalidState: PsKernelCloseStep;
};
declare const __ps$tag$125: unique symbol;
export type PsKernelCloseResult = {
    readonly [__ps$tag$125]: "done";
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$125]: "invalidState";
} | {
    readonly [__ps$tag$125]: "outOfFuel";
};
export declare const PsKernelCloseResult: {
    readonly done: (__field0: PsKernelExpr) => PsKernelCloseResult;
    readonly invalidState: PsKernelCloseResult;
    readonly outOfFuel: PsKernelCloseResult;
};
declare const __ps$tag$126: unique symbol;
export type PsKernelOccurrenceTask = {
    readonly [__ps$tag$126]: "visit";
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$126]: "name";
    readonly work: PsKernelList<PsKernelOrderTask>;
};
export declare const PsKernelOccurrenceTask: {
    readonly visit: (__field0: PsKernelExpr) => PsKernelOccurrenceTask;
    readonly name: (__field0: PsKernelList<PsKernelOrderTask>) => PsKernelOccurrenceTask;
};
declare const __ps$tag$127: unique symbol;
export type PsKernelOccurrenceState = {
    readonly [__ps$tag$127]: "state";
    readonly family: PsKernelName;
    readonly parameters: PsKernelFlag;
    readonly tasks: PsKernelList<PsKernelOccurrenceTask>;
};
export declare const PsKernelOccurrenceState: {
    readonly state: (__field0: PsKernelName, __field1: PsKernelFlag, __field2: PsKernelList<PsKernelOccurrenceTask>) => PsKernelOccurrenceState;
};
declare const __ps$tag$128: unique symbol;
export type PsKernelOccurrenceStep = {
    readonly [__ps$tag$128]: "next";
    readonly state: PsKernelOccurrenceState;
} | {
    readonly [__ps$tag$128]: "found";
} | {
    readonly [__ps$tag$128]: "absent";
} | {
    readonly [__ps$tag$128]: "invalidState";
};
export declare const PsKernelOccurrenceStep: {
    readonly next: (__field0: PsKernelOccurrenceState) => PsKernelOccurrenceStep;
    readonly found: PsKernelOccurrenceStep;
    readonly absent: PsKernelOccurrenceStep;
    readonly invalidState: PsKernelOccurrenceStep;
};
declare const __ps$tag$129: unique symbol;
export type PsKernelExprEqualTask = {
    readonly [__ps$tag$129]: "pair";
    readonly left: PsKernelExpr;
    readonly right: PsKernelExpr;
} | {
    readonly [__ps$tag$129]: "order";
    readonly tasks: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$129]: "levels";
    readonly left: PsKernelList<PsKernelLevel>;
    readonly right: PsKernelList<PsKernelLevel>;
};
export declare const PsKernelExprEqualTask: {
    readonly pair: (__field0: PsKernelExpr, __field1: PsKernelExpr) => PsKernelExprEqualTask;
    readonly order: (__field0: PsKernelList<PsKernelOrderTask>) => PsKernelExprEqualTask;
    readonly levels: (__field0: PsKernelList<PsKernelLevel>, __field1: PsKernelList<PsKernelLevel>) => PsKernelExprEqualTask;
};
declare const __ps$tag$130: unique symbol;
export type PsKernelExprEqualState = {
    readonly [__ps$tag$130]: "state";
    readonly tasks: PsKernelList<PsKernelExprEqualTask>;
};
export declare const PsKernelExprEqualState: {
    readonly state: (__field0: PsKernelList<PsKernelExprEqualTask>) => PsKernelExprEqualState;
};
declare const __ps$tag$131: unique symbol;
export type PsKernelExprEqualStep = {
    readonly [__ps$tag$131]: "next";
    readonly state: PsKernelExprEqualState;
} | {
    readonly [__ps$tag$131]: "equal";
} | {
    readonly [__ps$tag$131]: "different";
} | {
    readonly [__ps$tag$131]: "invalidState";
};
export declare const PsKernelExprEqualStep: {
    readonly next: (__field0: PsKernelExprEqualState) => PsKernelExprEqualStep;
    readonly equal: PsKernelExprEqualStep;
    readonly different: PsKernelExprEqualStep;
    readonly invalidState: PsKernelExprEqualStep;
};
declare const __ps$tag$132: unique symbol;
export type PsKernelPositiveFieldTask = {
    readonly [__ps$tag$132]: "fields";
    readonly pending: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$132]: "occurrence";
    readonly value: PsKernelExpr;
    readonly pending: PsKernelList<PsKernelExpr>;
    readonly state: PsKernelOccurrenceState;
} | {
    readonly [__ps$tag$132]: "uniform";
    readonly value: PsKernelExpr;
    readonly pending: PsKernelList<PsKernelExpr>;
    readonly state: PsKernelExprEqualState;
} | {
    readonly [__ps$tag$132]: "spine";
    readonly value: PsKernelExpr;
    readonly arguments: PsKernelList<PsKernelExpr>;
    readonly pending: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$132]: "lookup";
    readonly arguments: PsKernelList<PsKernelExpr>;
    readonly pending: PsKernelList<PsKernelExpr>;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$132]: "arity";
    readonly remaining: PsKernelNatural;
    readonly arguments: PsKernelList<PsKernelExpr>;
    readonly pending: PsKernelList<PsKernelExpr>;
};
export declare const PsKernelPositiveFieldTask: {
    readonly fields: (__field0: PsKernelList<PsKernelExpr>) => PsKernelPositiveFieldTask;
    readonly occurrence: (__field0: PsKernelExpr, __field1: PsKernelList<PsKernelExpr>, __field2: PsKernelOccurrenceState) => PsKernelPositiveFieldTask;
    readonly uniform: (__field0: PsKernelExpr, __field1: PsKernelList<PsKernelExpr>, __field2: PsKernelExprEqualState) => PsKernelPositiveFieldTask;
    readonly spine: (__field0: PsKernelExpr, __field1: PsKernelList<PsKernelExpr>, __field2: PsKernelList<PsKernelExpr>) => PsKernelPositiveFieldTask;
    readonly lookup: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelList<PsKernelExpr>, __field2: PsKernelLookupState) => PsKernelPositiveFieldTask;
    readonly arity: (__field0: PsKernelNatural, __field1: PsKernelList<PsKernelExpr>, __field2: PsKernelList<PsKernelExpr>) => PsKernelPositiveFieldTask;
};
declare const __ps$tag$133: unique symbol;
export type PsKernelPositiveFieldState = {
    readonly [__ps$tag$133]: "state";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly family: PsKernelName;
    readonly uniform: PsKernelExpr;
    readonly task: PsKernelPositiveFieldTask;
};
export declare const PsKernelPositiveFieldState: {
    readonly state: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelName, __field2: PsKernelExpr, __field3: PsKernelPositiveFieldTask) => PsKernelPositiveFieldState;
};
declare const __ps$tag$134: unique symbol;
export type PsKernelPositiveFieldStep = {
    readonly [__ps$tag$134]: "next";
    readonly state: PsKernelPositiveFieldState;
} | {
    readonly [__ps$tag$134]: "accepted";
} | {
    readonly [__ps$tag$134]: "rejected";
    readonly error: PsKernelCheckError;
};
export declare const PsKernelPositiveFieldStep: {
    readonly next: (__field0: PsKernelPositiveFieldState) => PsKernelPositiveFieldStep;
    readonly accepted: PsKernelPositiveFieldStep;
    readonly rejected: (__field0: PsKernelCheckError) => PsKernelPositiveFieldStep;
};
declare const __ps$tag$135: unique symbol;
export type PsKernelPositiveFieldResult = {
    readonly [__ps$tag$135]: "accepted";
} | {
    readonly [__ps$tag$135]: "rejected";
    readonly error: PsKernelCheckError;
} | {
    readonly [__ps$tag$135]: "outOfFuel";
};
export declare const PsKernelPositiveFieldResult: {
    readonly accepted: PsKernelPositiveFieldResult;
    readonly rejected: (__field0: PsKernelCheckError) => PsKernelPositiveFieldResult;
    readonly outOfFuel: PsKernelPositiveFieldResult;
};
declare const __ps$tag$136: unique symbol;
export type PsKernelAlgConstructorTask = {
    readonly [__ps$tag$136]: "scope";
    readonly state: PsKernelBindingState;
} | {
    readonly [__ps$tag$136]: "name";
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$136]: "parameters";
    readonly remaining: PsKernelExpr;
    readonly arguments: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$136]: "parameter";
    readonly arguments: PsKernelList<PsKernelExpr>;
    readonly state: PsKernelBindingState;
} | {
    readonly [__ps$tag$136]: "fields";
    readonly remaining: PsKernelExpr;
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly nextId: PsKernelNatural;
} | {
    readonly [__ps$tag$136]: "closeField";
    readonly field: PsKernelExpr;
    readonly body: PsKernelExpr;
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly id: PsKernelNatural;
    readonly state: PsKernelCloseState;
} | {
    readonly [__ps$tag$136]: "fieldType";
    readonly field: PsKernelExpr;
    readonly body: PsKernelExpr;
    readonly closed: PsKernelExpr;
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly id: PsKernelNatural;
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$136]: "template";
    readonly field: PsKernelExpr;
    readonly body: PsKernelExpr;
    readonly closed: PsKernelExpr;
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly id: PsKernelNatural;
    readonly remaining: PsKernelNatural;
} | {
    readonly [__ps$tag$136]: "positive";
    readonly body: PsKernelExpr;
    readonly template: PsKernelExpr;
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly id: PsKernelNatural;
    readonly state: PsKernelPositiveFieldState;
} | {
    readonly [__ps$tag$136]: "fieldBody";
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly id: PsKernelNatural;
    readonly state: PsKernelBindingState;
} | {
    readonly [__ps$tag$136]: "result";
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly state: PsKernelExprEqualState;
} | {
    readonly [__ps$tag$136]: "constructorType";
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$136]: "reverse";
    readonly pending: PsKernelList<PsKernelExpr>;
    readonly fields: PsKernelList<PsKernelExpr>;
};
export declare const PsKernelAlgConstructorTask: {
    readonly scope: (__field0: PsKernelBindingState) => PsKernelAlgConstructorTask;
    readonly name: (__field0: PsKernelLookupState) => PsKernelAlgConstructorTask;
    readonly parameters: (__field0: PsKernelExpr, __field1: PsKernelList<PsKernelExpr>) => PsKernelAlgConstructorTask;
    readonly parameter: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelBindingState) => PsKernelAlgConstructorTask;
    readonly fields: (__field0: PsKernelExpr, __field1: PsKernelList<PsKernelExpr>, __field2: PsKernelNatural) => PsKernelAlgConstructorTask;
    readonly closeField: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelList<PsKernelExpr>, __field3: PsKernelNatural, __field4: PsKernelCloseState) => PsKernelAlgConstructorTask;
    readonly fieldType: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelExpr, __field3: PsKernelList<PsKernelExpr>, __field4: PsKernelNatural, __field5: PsKernelTypeState) => PsKernelAlgConstructorTask;
    readonly template: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelExpr, __field3: PsKernelList<PsKernelExpr>, __field4: PsKernelNatural, __field5: PsKernelNatural) => PsKernelAlgConstructorTask;
    readonly positive: (__field0: PsKernelExpr, __field1: PsKernelExpr, __field2: PsKernelList<PsKernelExpr>, __field3: PsKernelNatural, __field4: PsKernelPositiveFieldState) => PsKernelAlgConstructorTask;
    readonly fieldBody: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelNatural, __field2: PsKernelBindingState) => PsKernelAlgConstructorTask;
    readonly result: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelExprEqualState) => PsKernelAlgConstructorTask;
    readonly constructorType: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelTypeState) => PsKernelAlgConstructorTask;
    readonly reverse: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelList<PsKernelExpr>) => PsKernelAlgConstructorTask;
};
declare const __ps$tag$137: unique symbol;
export type PsKernelAlgConstructorState = {
    readonly [__ps$tag$137]: "state";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly header: PsKernelAlgHeader;
    readonly input: PsKernelAlgInputConstructor;
    readonly task: PsKernelAlgConstructorTask;
};
export declare const PsKernelAlgConstructorState: {
    readonly state: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelAlgHeader, __field2: PsKernelAlgInputConstructor, __field3: PsKernelAlgConstructorTask) => PsKernelAlgConstructorState;
};
declare const __ps$tag$138: unique symbol;
export type PsKernelAlgConstructorStep = {
    readonly [__ps$tag$138]: "next";
    readonly state: PsKernelAlgConstructorState;
} | {
    readonly [__ps$tag$138]: "accepted";
    readonly constructor: PsKernelAlgConstructor;
} | {
    readonly [__ps$tag$138]: "rejected";
    readonly error: PsKernelCheckError;
};
export declare const PsKernelAlgConstructorStep: {
    readonly next: (__field0: PsKernelAlgConstructorState) => PsKernelAlgConstructorStep;
    readonly accepted: (__field0: PsKernelAlgConstructor) => PsKernelAlgConstructorStep;
    readonly rejected: (__field0: PsKernelCheckError) => PsKernelAlgConstructorStep;
};
declare const __ps$tag$139: unique symbol;
export type PsKernelAlgConstructorResult = {
    readonly [__ps$tag$139]: "accepted";
    readonly constructor: PsKernelAlgConstructor;
} | {
    readonly [__ps$tag$139]: "rejected";
    readonly error: PsKernelCheckError;
} | {
    readonly [__ps$tag$139]: "outOfFuel";
};
export declare const PsKernelAlgConstructorResult: {
    readonly accepted: (__field0: PsKernelAlgConstructor) => PsKernelAlgConstructorResult;
    readonly rejected: (__field0: PsKernelCheckError) => PsKernelAlgConstructorResult;
    readonly outOfFuel: PsKernelAlgConstructorResult;
};
declare const __ps$tag$140: unique symbol;
export type PsKernelParameterTask = {
    readonly [__ps$tag$140]: "reverse";
    readonly pending: PsKernelList<PsKernelExpr>;
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$140]: "visit";
    readonly depth: PsKernelNatural;
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$140]: "bound";
    readonly original: PsKernelNatural;
    readonly index: PsKernelNatural;
    readonly remainingDepth: PsKernelNatural;
    readonly depth: PsKernelNatural;
} | {
    readonly [__ps$tag$140]: "select";
    readonly index: PsKernelNatural;
    readonly depth: PsKernelNatural;
    readonly arguments: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$140]: "lift";
    readonly state: PsKernelBindingState;
} | {
    readonly [__ps$tag$140]: "app";
} | {
    readonly [__ps$tag$140]: "lam";
    readonly name: PsKernelName;
    readonly binder: PsKernelBinder;
} | {
    readonly [__ps$tag$140]: "forallE";
    readonly name: PsKernelName;
    readonly binder: PsKernelBinder;
} | {
    readonly [__ps$tag$140]: "letE";
    readonly name: PsKernelName;
} | {
    readonly [__ps$tag$140]: "proj";
    readonly family: PsKernelName;
    readonly index: PsKernelNatural;
};
export declare const PsKernelParameterTask: {
    readonly reverse: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelList<PsKernelExpr>, __field2: PsKernelExpr) => PsKernelParameterTask;
    readonly visit: (__field0: PsKernelNatural, __field1: PsKernelExpr) => PsKernelParameterTask;
    readonly bound: (__field0: PsKernelNatural, __field1: PsKernelNatural, __field2: PsKernelNatural, __field3: PsKernelNatural) => PsKernelParameterTask;
    readonly select: (__field0: PsKernelNatural, __field1: PsKernelNatural, __field2: PsKernelList<PsKernelExpr>) => PsKernelParameterTask;
    readonly lift: (__field0: PsKernelBindingState) => PsKernelParameterTask;
    readonly app: PsKernelParameterTask;
    readonly lam: (__field0: PsKernelName, __field1: PsKernelBinder) => PsKernelParameterTask;
    readonly forallE: (__field0: PsKernelName, __field1: PsKernelBinder) => PsKernelParameterTask;
    readonly letE: (__field0: PsKernelName) => PsKernelParameterTask;
    readonly proj: (__field0: PsKernelName, __field1: PsKernelNatural) => PsKernelParameterTask;
};
declare const __ps$tag$141: unique symbol;
export type PsKernelParameterState = {
    readonly [__ps$tag$141]: "state";
    readonly arguments: PsKernelList<PsKernelExpr>;
    readonly tasks: PsKernelList<PsKernelParameterTask>;
    readonly values: PsKernelList<PsKernelExpr>;
};
export declare const PsKernelParameterState: {
    readonly state: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelList<PsKernelParameterTask>, __field2: PsKernelList<PsKernelExpr>) => PsKernelParameterState;
};
declare const __ps$tag$142: unique symbol;
export type PsKernelParameterResult = {
    readonly [__ps$tag$142]: "done";
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$142]: "invalidScope";
} | {
    readonly [__ps$tag$142]: "invalidState";
} | {
    readonly [__ps$tag$142]: "outOfFuel";
};
export declare const PsKernelParameterResult: {
    readonly done: (__field0: PsKernelExpr) => PsKernelParameterResult;
    readonly invalidScope: PsKernelParameterResult;
    readonly invalidState: PsKernelParameterResult;
    readonly outOfFuel: PsKernelParameterResult;
};
declare const __ps$tag$143: unique symbol;
export type PsKernelParameterStep = {
    readonly [__ps$tag$143]: "next";
    readonly state: PsKernelParameterState;
} | {
    readonly [__ps$tag$143]: "final";
    readonly result: PsKernelParameterResult;
};
export declare const PsKernelParameterStep: {
    readonly next: (__field0: PsKernelParameterState) => PsKernelParameterStep;
    readonly final: (__field0: PsKernelParameterResult) => PsKernelParameterStep;
};
declare const __ps$tag$144: unique symbol;
export type PsKernelAlgMinorFrame = {
    readonly [__ps$tag$144]: "frame";
    readonly pending: PsKernelList<PsKernelExpr>;
    readonly value: PsKernelExpr;
    readonly nextId: PsKernelNatural;
    readonly binders: PsKernelList<PsKernelAlgBinder>;
    readonly recursive: PsKernelList<PsKernelExpr>;
    readonly flags: PsKernelList<PsKernelOption<PsKernelName>>;
};
export declare const PsKernelAlgMinorFrame: {
    readonly frame: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelExpr, __field2: PsKernelNatural, __field3: PsKernelList<PsKernelAlgBinder>, __field4: PsKernelList<PsKernelExpr>, __field5: PsKernelList<PsKernelOption<PsKernelName>>) => PsKernelAlgMinorFrame;
};
declare const __ps$tag$145: unique symbol;
export type PsKernelAlgMinorTask = {
    readonly [__ps$tag$145]: "parameters";
    readonly pending: PsKernelList<PsKernelExpr>;
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$145]: "fields";
    readonly frame: PsKernelAlgMinorFrame;
} | {
    readonly [__ps$tag$145]: "instantiate";
    readonly frame: PsKernelAlgMinorFrame;
    readonly state: PsKernelParameterState;
} | {
    readonly [__ps$tag$145]: "equal";
    readonly frame: PsKernelAlgMinorFrame;
    readonly type: PsKernelExpr;
    readonly state: PsKernelExprEqualState;
} | {
    readonly [__ps$tag$145]: "occurrence";
    readonly frame: PsKernelAlgMinorFrame;
    readonly type: PsKernelExpr;
    readonly state: PsKernelOccurrenceState;
} | {
    readonly [__ps$tag$145]: "reverseFlags";
    readonly frame: PsKernelAlgMinorFrame;
    readonly pending: PsKernelList<PsKernelOption<PsKernelName>>;
    readonly flags: PsKernelList<PsKernelOption<PsKernelName>>;
} | {
    readonly [__ps$tag$145]: "reverseRecursive";
    readonly frame: PsKernelAlgMinorFrame;
    readonly flags: PsKernelList<PsKernelOption<PsKernelName>>;
    readonly pending: PsKernelList<PsKernelExpr>;
    readonly recursive: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$145]: "hypotheses";
    readonly value: PsKernelExpr;
    readonly nextId: PsKernelNatural;
    readonly binders: PsKernelList<PsKernelAlgBinder>;
    readonly flags: PsKernelList<PsKernelOption<PsKernelName>>;
    readonly pending: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$145]: "close";
    readonly flags: PsKernelList<PsKernelOption<PsKernelName>>;
    readonly state: PsKernelCloseState;
};
export declare const PsKernelAlgMinorTask: {
    readonly parameters: (__field0: PsKernelList<PsKernelExpr>, __field1: PsKernelExpr) => PsKernelAlgMinorTask;
    readonly fields: (__field0: PsKernelAlgMinorFrame) => PsKernelAlgMinorTask;
    readonly instantiate: (__field0: PsKernelAlgMinorFrame, __field1: PsKernelParameterState) => PsKernelAlgMinorTask;
    readonly equal: (__field0: PsKernelAlgMinorFrame, __field1: PsKernelExpr, __field2: PsKernelExprEqualState) => PsKernelAlgMinorTask;
    readonly occurrence: (__field0: PsKernelAlgMinorFrame, __field1: PsKernelExpr, __field2: PsKernelOccurrenceState) => PsKernelAlgMinorTask;
    readonly reverseFlags: (__field0: PsKernelAlgMinorFrame, __field1: PsKernelList<PsKernelOption<PsKernelName>>, __field2: PsKernelList<PsKernelOption<PsKernelName>>) => PsKernelAlgMinorTask;
    readonly reverseRecursive: (__field0: PsKernelAlgMinorFrame, __field1: PsKernelList<PsKernelOption<PsKernelName>>, __field2: PsKernelList<PsKernelExpr>, __field3: PsKernelList<PsKernelExpr>) => PsKernelAlgMinorTask;
    readonly hypotheses: (__field0: PsKernelExpr, __field1: PsKernelNatural, __field2: PsKernelList<PsKernelAlgBinder>, __field3: PsKernelList<PsKernelOption<PsKernelName>>, __field4: PsKernelList<PsKernelExpr>) => PsKernelAlgMinorTask;
    readonly close: (__field0: PsKernelList<PsKernelOption<PsKernelName>>, __field1: PsKernelCloseState) => PsKernelAlgMinorTask;
};
declare const __ps$tag$146: unique symbol;
export type PsKernelAlgMinorState = {
    readonly [__ps$tag$146]: "state";
    readonly header: PsKernelAlgHeader;
    readonly constructor: PsKernelAlgConstructor;
    readonly fieldStart: PsKernelNatural;
    readonly task: PsKernelAlgMinorTask;
};
export declare const PsKernelAlgMinorState: {
    readonly state: (__field0: PsKernelAlgHeader, __field1: PsKernelAlgConstructor, __field2: PsKernelNatural, __field3: PsKernelAlgMinorTask) => PsKernelAlgMinorState;
};
declare const __ps$tag$147: unique symbol;
export type PsKernelAlgMinorStep = {
    readonly [__ps$tag$147]: "next";
    readonly state: PsKernelAlgMinorState;
} | {
    readonly [__ps$tag$147]: "ready";
    readonly type: PsKernelExpr;
    readonly recursiveFields: PsKernelList<PsKernelOption<PsKernelName>>;
} | {
    readonly [__ps$tag$147]: "rejected";
    readonly error: PsKernelCheckError;
};
export declare const PsKernelAlgMinorStep: {
    readonly next: (__field0: PsKernelAlgMinorState) => PsKernelAlgMinorStep;
    readonly ready: (__field0: PsKernelExpr, __field1: PsKernelList<PsKernelOption<PsKernelName>>) => PsKernelAlgMinorStep;
    readonly rejected: (__field0: PsKernelCheckError) => PsKernelAlgMinorStep;
};
declare const __ps$tag$148: unique symbol;
export type PsKernelAlgRecursorFrame = {
    readonly [__ps$tag$148]: "frame";
    readonly pending: PsKernelList<PsKernelAlgConstructor>;
    readonly index: PsKernelNatural;
    readonly minorId: PsKernelNatural;
    readonly fieldStart: PsKernelNatural;
    readonly binders: PsKernelList<PsKernelAlgBinder>;
    readonly rules: PsKernelList<PsKernelAlgRule>;
};
export declare const PsKernelAlgRecursorFrame: {
    readonly frame: (__field0: PsKernelList<PsKernelAlgConstructor>, __field1: PsKernelNatural, __field2: PsKernelNatural, __field3: PsKernelNatural, __field4: PsKernelList<PsKernelAlgBinder>, __field5: PsKernelList<PsKernelAlgRule>) => PsKernelAlgRecursorFrame;
};
declare const __ps$tag$149: unique symbol;
export type PsKernelAlgRecursorTask = {
    readonly [__ps$tag$149]: "count";
    readonly pending: PsKernelList<PsKernelAlgConstructor>;
    readonly fieldStart: PsKernelNatural;
} | {
    readonly [__ps$tag$149]: "minors";
    readonly frame: PsKernelAlgRecursorFrame;
} | {
    readonly [__ps$tag$149]: "minor";
    readonly frame: PsKernelAlgRecursorFrame;
    readonly constructor: PsKernelAlgConstructor;
    readonly state: PsKernelAlgMinorState;
} | {
    readonly [__ps$tag$149]: "reverseBinders";
    readonly fieldStart: PsKernelNatural;
    readonly pending: PsKernelList<PsKernelAlgBinder>;
    readonly forward: PsKernelList<PsKernelAlgBinder>;
    readonly rules: PsKernelList<PsKernelAlgRule>;
} | {
    readonly [__ps$tag$149]: "binders";
    readonly fieldStart: PsKernelNatural;
    readonly pending: PsKernelList<PsKernelAlgBinder>;
    readonly binders: PsKernelList<PsKernelAlgBinder>;
    readonly rules: PsKernelList<PsKernelAlgRule>;
} | {
    readonly [__ps$tag$149]: "reverseRules";
    readonly fieldStart: PsKernelNatural;
    readonly binders: PsKernelList<PsKernelAlgBinder>;
    readonly pending: PsKernelList<PsKernelAlgRule>;
    readonly rules: PsKernelList<PsKernelAlgRule>;
} | {
    readonly [__ps$tag$149]: "close";
    readonly rules: PsKernelList<PsKernelAlgRule>;
    readonly state: PsKernelCloseState;
};
export declare const PsKernelAlgRecursorTask: {
    readonly count: (__field0: PsKernelList<PsKernelAlgConstructor>, __field1: PsKernelNatural) => PsKernelAlgRecursorTask;
    readonly minors: (__field0: PsKernelAlgRecursorFrame) => PsKernelAlgRecursorTask;
    readonly minor: (__field0: PsKernelAlgRecursorFrame, __field1: PsKernelAlgConstructor, __field2: PsKernelAlgMinorState) => PsKernelAlgRecursorTask;
    readonly reverseBinders: (__field0: PsKernelNatural, __field1: PsKernelList<PsKernelAlgBinder>, __field2: PsKernelList<PsKernelAlgBinder>, __field3: PsKernelList<PsKernelAlgRule>) => PsKernelAlgRecursorTask;
    readonly binders: (__field0: PsKernelNatural, __field1: PsKernelList<PsKernelAlgBinder>, __field2: PsKernelList<PsKernelAlgBinder>, __field3: PsKernelList<PsKernelAlgRule>) => PsKernelAlgRecursorTask;
    readonly reverseRules: (__field0: PsKernelNatural, __field1: PsKernelList<PsKernelAlgBinder>, __field2: PsKernelList<PsKernelAlgRule>, __field3: PsKernelList<PsKernelAlgRule>) => PsKernelAlgRecursorTask;
    readonly close: (__field0: PsKernelList<PsKernelAlgRule>, __field1: PsKernelCloseState) => PsKernelAlgRecursorTask;
};
declare const __ps$tag$150: unique symbol;
export type PsKernelAlgRecursorState = {
    readonly [__ps$tag$150]: "state";
    readonly header: PsKernelAlgHeader;
    readonly constructors: PsKernelList<PsKernelAlgConstructor>;
    readonly task: PsKernelAlgRecursorTask;
};
export declare const PsKernelAlgRecursorState: {
    readonly state: (__field0: PsKernelAlgHeader, __field1: PsKernelList<PsKernelAlgConstructor>, __field2: PsKernelAlgRecursorTask) => PsKernelAlgRecursorState;
};
declare const __ps$tag$151: unique symbol;
export type PsKernelAlgRecursorStep = {
    readonly [__ps$tag$151]: "next";
    readonly state: PsKernelAlgRecursorState;
} | {
    readonly [__ps$tag$151]: "ready";
    readonly type: PsKernelExpr;
    readonly rules: PsKernelList<PsKernelAlgRule>;
} | {
    readonly [__ps$tag$151]: "rejected";
    readonly error: PsKernelCheckError;
};
export declare const PsKernelAlgRecursorStep: {
    readonly next: (__field0: PsKernelAlgRecursorState) => PsKernelAlgRecursorStep;
    readonly ready: (__field0: PsKernelExpr, __field1: PsKernelList<PsKernelAlgRule>) => PsKernelAlgRecursorStep;
    readonly rejected: (__field0: PsKernelCheckError) => PsKernelAlgRecursorStep;
};
declare const __ps$tag$152: unique symbol;
export type PsKernelAlgAdmissionFrame = {
    readonly [__ps$tag$152]: "frame";
    readonly header: PsKernelAlgHeader;
    readonly working: PsKernelList<PsKernelDefinition>;
    readonly pending: PsKernelList<PsKernelAlgInputConstructor>;
    readonly reversed: PsKernelList<PsKernelAlgConstructor>;
};
export declare const PsKernelAlgAdmissionFrame: {
    readonly frame: (__field0: PsKernelAlgHeader, __field1: PsKernelList<PsKernelDefinition>, __field2: PsKernelList<PsKernelAlgInputConstructor>, __field3: PsKernelList<PsKernelAlgConstructor>) => PsKernelAlgAdmissionFrame;
};
declare const __ps$tag$153: unique symbol;
export type PsKernelAlgAdmissionTask = {
    readonly [__ps$tag$153]: "header";
    readonly state: PsKernelAlgHeaderState;
} | {
    readonly [__ps$tag$153]: "recursorName";
    readonly header: PsKernelAlgHeader;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$153]: "constructors";
    readonly frame: PsKernelAlgAdmissionFrame;
} | {
    readonly [__ps$tag$153]: "constructorName";
    readonly frame: PsKernelAlgAdmissionFrame;
    readonly input: PsKernelAlgInputConstructor;
    readonly tasks: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$153]: "constructor";
    readonly frame: PsKernelAlgAdmissionFrame;
    readonly state: PsKernelAlgConstructorState;
} | {
    readonly [__ps$tag$153]: "reverse";
    readonly header: PsKernelAlgHeader;
    readonly working: PsKernelList<PsKernelDefinition>;
    readonly pending: PsKernelList<PsKernelAlgConstructor>;
    readonly constructors: PsKernelList<PsKernelAlgConstructor>;
} | {
    readonly [__ps$tag$153]: "recursor";
    readonly header: PsKernelAlgHeader;
    readonly working: PsKernelList<PsKernelDefinition>;
    readonly constructors: PsKernelList<PsKernelAlgConstructor>;
    readonly state: PsKernelAlgRecursorState;
} | {
    readonly [__ps$tag$153]: "check";
    readonly header: PsKernelAlgHeader;
    readonly constructors: PsKernelList<PsKernelAlgConstructor>;
    readonly type: PsKernelExpr;
    readonly rules: PsKernelList<PsKernelAlgRule>;
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$153]: "install";
    readonly header: PsKernelAlgHeader;
    readonly pending: PsKernelList<PsKernelAlgConstructor>;
    readonly type: PsKernelExpr;
    readonly rules: PsKernelList<PsKernelAlgRule>;
    readonly environment: PsKernelList<PsKernelDefinition>;
};
export declare const PsKernelAlgAdmissionTask: {
    readonly header: (__field0: PsKernelAlgHeaderState) => PsKernelAlgAdmissionTask;
    readonly recursorName: (__field0: PsKernelAlgHeader, __field1: PsKernelLookupState) => PsKernelAlgAdmissionTask;
    readonly constructors: (__field0: PsKernelAlgAdmissionFrame) => PsKernelAlgAdmissionTask;
    readonly constructorName: (__field0: PsKernelAlgAdmissionFrame, __field1: PsKernelAlgInputConstructor, __field2: PsKernelList<PsKernelOrderTask>) => PsKernelAlgAdmissionTask;
    readonly constructor: (__field0: PsKernelAlgAdmissionFrame, __field1: PsKernelAlgConstructorState) => PsKernelAlgAdmissionTask;
    readonly reverse: (__field0: PsKernelAlgHeader, __field1: PsKernelList<PsKernelDefinition>, __field2: PsKernelList<PsKernelAlgConstructor>, __field3: PsKernelList<PsKernelAlgConstructor>) => PsKernelAlgAdmissionTask;
    readonly recursor: (__field0: PsKernelAlgHeader, __field1: PsKernelList<PsKernelDefinition>, __field2: PsKernelList<PsKernelAlgConstructor>, __field3: PsKernelAlgRecursorState) => PsKernelAlgAdmissionTask;
    readonly check: (__field0: PsKernelAlgHeader, __field1: PsKernelList<PsKernelAlgConstructor>, __field2: PsKernelExpr, __field3: PsKernelList<PsKernelAlgRule>, __field4: PsKernelTypeState) => PsKernelAlgAdmissionTask;
    readonly install: (__field0: PsKernelAlgHeader, __field1: PsKernelList<PsKernelAlgConstructor>, __field2: PsKernelExpr, __field3: PsKernelList<PsKernelAlgRule>, __field4: PsKernelList<PsKernelDefinition>) => PsKernelAlgAdmissionTask;
};
declare const __ps$tag$154: unique symbol;
export type PsKernelAlgAdmissionState = {
    readonly [__ps$tag$154]: "state";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly declaration: PsKernelAlgDeclaration;
    readonly task: PsKernelAlgAdmissionTask;
};
export declare const PsKernelAlgAdmissionState: {
    readonly state: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelAlgDeclaration, __field2: PsKernelAlgAdmissionTask) => PsKernelAlgAdmissionState;
};
declare const __ps$tag$155: unique symbol;
export type PsKernelAlgAdmissionStep = {
    readonly [__ps$tag$155]: "next";
    readonly state: PsKernelAlgAdmissionState;
} | {
    readonly [__ps$tag$155]: "final";
    readonly result: PsKernelAdmissionResult;
};
export declare const PsKernelAlgAdmissionStep: {
    readonly next: (__field0: PsKernelAlgAdmissionState) => PsKernelAlgAdmissionStep;
    readonly final: (__field0: PsKernelAdmissionResult) => PsKernelAlgAdmissionStep;
};
declare const __ps$tag$156: unique symbol;
export type PsKernelJointEntry = {
    readonly [__ps$tag$156]: "algebraic";
    readonly entry: PsKernelAlgDeclaration;
} | {
    readonly [__ps$tag$156]: "definition";
    readonly entry: PsKernelDefinition;
} | {
    readonly [__ps$tag$156]: "unitInductive";
    readonly entry: PsKernelUnitDeclaration;
} | {
    readonly [__ps$tag$156]: "recordInductive";
    readonly entry: PsKernelUnitDeclaration;
} | {
    readonly [__ps$tag$156]: "enumInductive";
    readonly entry: PsKernelEnumDeclaration;
} | {
    readonly [__ps$tag$156]: "sumInductive";
    readonly entry: PsKernelEnumDeclaration;
} | {
    readonly [__ps$tag$156]: "natInductive";
    readonly entry: PsKernelNatDeclaration;
};
export declare const PsKernelJointEntry: {
    readonly algebraic: (__field0: PsKernelAlgDeclaration) => PsKernelJointEntry;
    readonly definition: (__field0: PsKernelDefinition) => PsKernelJointEntry;
    readonly unitInductive: (__field0: PsKernelUnitDeclaration) => PsKernelJointEntry;
    readonly recordInductive: (__field0: PsKernelUnitDeclaration) => PsKernelJointEntry;
    readonly enumInductive: (__field0: PsKernelEnumDeclaration) => PsKernelJointEntry;
    readonly sumInductive: (__field0: PsKernelEnumDeclaration) => PsKernelJointEntry;
    readonly natInductive: (__field0: PsKernelNatDeclaration) => PsKernelJointEntry;
};
declare const __ps$tag$157: unique symbol;
export type PsKernelJointState = {
    readonly [__ps$tag$157]: "algebraic";
    readonly rest: PsKernelList<PsKernelJointEntry>;
    readonly state: PsKernelAlgAdmissionState;
} | {
    readonly [__ps$tag$157]: "pending";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly entries: PsKernelList<PsKernelJointEntry>;
} | {
    readonly [__ps$tag$157]: "definition";
    readonly rest: PsKernelList<PsKernelJointEntry>;
    readonly state: PsKernelAdmissionState;
} | {
    readonly [__ps$tag$157]: "unitInductive";
    readonly rest: PsKernelList<PsKernelJointEntry>;
    readonly state: PsKernelUnitState;
} | {
    readonly [__ps$tag$157]: "recordInductive";
    readonly rest: PsKernelList<PsKernelJointEntry>;
    readonly state: PsKernelRecordState;
} | {
    readonly [__ps$tag$157]: "enumInductive";
    readonly rest: PsKernelList<PsKernelJointEntry>;
    readonly state: PsKernelEnumState;
} | {
    readonly [__ps$tag$157]: "sumInductive";
    readonly rest: PsKernelList<PsKernelJointEntry>;
    readonly state: PsKernelSumState;
} | {
    readonly [__ps$tag$157]: "natInductive";
    readonly rest: PsKernelList<PsKernelJointEntry>;
    readonly state: PsKernelNatAdmissionState;
};
export declare const PsKernelJointState: {
    readonly algebraic: (__field0: PsKernelList<PsKernelJointEntry>, __field1: PsKernelAlgAdmissionState) => PsKernelJointState;
    readonly pending: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelList<PsKernelJointEntry>) => PsKernelJointState;
    readonly definition: (__field0: PsKernelList<PsKernelJointEntry>, __field1: PsKernelAdmissionState) => PsKernelJointState;
    readonly unitInductive: (__field0: PsKernelList<PsKernelJointEntry>, __field1: PsKernelUnitState) => PsKernelJointState;
    readonly recordInductive: (__field0: PsKernelList<PsKernelJointEntry>, __field1: PsKernelRecordState) => PsKernelJointState;
    readonly enumInductive: (__field0: PsKernelList<PsKernelJointEntry>, __field1: PsKernelEnumState) => PsKernelJointState;
    readonly sumInductive: (__field0: PsKernelList<PsKernelJointEntry>, __field1: PsKernelSumState) => PsKernelJointState;
    readonly natInductive: (__field0: PsKernelList<PsKernelJointEntry>, __field1: PsKernelNatAdmissionState) => PsKernelJointState;
};
declare const __ps$tag$158: unique symbol;
export type PsKernelJointStep = {
    readonly [__ps$tag$158]: "next";
    readonly state: PsKernelJointState;
} | {
    readonly [__ps$tag$158]: "final";
    readonly result: PsKernelAdmissionResult;
};
export declare const PsKernelJointStep: {
    readonly next: (__field0: PsKernelJointState) => PsKernelJointStep;
    readonly final: (__field0: PsKernelAdmissionResult) => PsKernelJointStep;
};
declare const __ps$tag$159: unique symbol;
export type PsKernelBootstrapState = {
    readonly [__ps$tag$159]: "prelude";
    readonly entries: PsKernelList<PsKernelJointEntry>;
    readonly state: PsKernelNatAdmissionState;
} | {
    readonly [__ps$tag$159]: "textPrelude";
    readonly entries: PsKernelList<PsKernelJointEntry>;
    readonly state: PsKernelStringPreludeState;
} | {
    readonly [__ps$tag$159]: "declarations";
    readonly state: PsKernelJointState;
};
export declare const PsKernelBootstrapState: {
    readonly prelude: (__field0: PsKernelList<PsKernelJointEntry>, __field1: PsKernelNatAdmissionState) => PsKernelBootstrapState;
    readonly textPrelude: (__field0: PsKernelList<PsKernelJointEntry>, __field1: PsKernelStringPreludeState) => PsKernelBootstrapState;
    readonly declarations: (__field0: PsKernelJointState) => PsKernelBootstrapState;
};
declare const __ps$tag$160: unique symbol;
export type PsKernelBootstrapStep = {
    readonly [__ps$tag$160]: "next";
    readonly state: PsKernelBootstrapState;
} | {
    readonly [__ps$tag$160]: "final";
    readonly result: PsKernelAdmissionResult;
};
export declare const PsKernelBootstrapStep: {
    readonly next: (__field0: PsKernelBootstrapState) => PsKernelBootstrapStep;
    readonly final: (__field0: PsKernelAdmissionResult) => PsKernelBootstrapStep;
};
export declare function psKernelCompareTasks(fuel: PsKernelFuel, __ps_eta_0: PsKernelList<PsKernelCompareTask>): PsKernelCompareResult;
export declare function psKernelPositiveSucc(value: PsKernelPositive): PsKernelPositive;
export declare function psKernelNaturalSucc(value: PsKernelNatural): PsKernelNatural;
export declare function psKernelPositivePred(value: PsKernelPositive): PsKernelNatural;
export declare function psKernelNaturalPred(value: PsKernelNatural): PsKernelNatural;
export declare function psKernelNaturalDigit(value: PsKernelNatural): PsKernelDigit;
export declare function psKernelNaturalDoubleBit(value: PsKernelNatural, bit: PsKernelBit): PsKernelNatural;
export declare function psKernelNumericAddContinue(left: PsKernelNatural, right: PsKernelNatural, carry: PsKernelBit, bit: PsKernelBit, bits: PsKernelList<PsKernelBit>): PsKernelNumericStep;
export declare function psKernelNumericAddDigits(left: PsKernelNatural, right: PsKernelNatural, a: PsKernelBit, b: PsKernelBit, carry: PsKernelBit, bits: PsKernelList<PsKernelBit>): PsKernelNumericStep;
export declare function psKernelNumericStep(state: PsKernelNumericState): PsKernelNumericStep;
export declare function psKernelNumericRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelNumericState): PsKernelNumericResult;
export declare function psKernelBindingPush(tasks: PsKernelList<PsKernelBindingTask>, values: PsKernelList<PsKernelExpr>, value: PsKernelExpr): PsKernelBindingStep;
export declare function psKernelBindingAfterOrder(mode: PsKernelBindingMode, depth: PsKernelNatural, index: PsKernelNatural, order: PsKernelOrder, tasks: PsKernelList<PsKernelBindingTask>, values: PsKernelList<PsKernelExpr>): PsKernelBindingStep;
export declare function psKernelBindingVisit(mode: PsKernelBindingMode, depth: PsKernelNatural, value: PsKernelExpr, tasks: PsKernelList<PsKernelBindingTask>, values: PsKernelList<PsKernelExpr>): PsKernelBindingStep;
export declare function psKernelBindingRebuild(task: PsKernelBindingTask, tasks: PsKernelList<PsKernelBindingTask>, values: PsKernelList<PsKernelExpr>): PsKernelBindingStep;
export declare function psKernelBindingFinish(values: PsKernelList<PsKernelExpr>): PsKernelBindingResult;
export declare function psKernelBindingStep(state: PsKernelBindingState): PsKernelBindingStep;
export declare function psKernelBindingStart(mode: PsKernelBindingMode, depth: PsKernelNatural, value: PsKernelExpr): PsKernelBindingState;
export declare function psKernelBindingRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelBindingState): PsKernelBindingResult;
export declare function psKernelOrderStep(tasks: PsKernelList<PsKernelOrderTask>): PsKernelOrderStep;
export declare function psKernelLevelOffset(value: PsKernelLevel): PsKernelLevelOffset;
export declare function psKernelLevelNeverZero(value: PsKernelLevel): PsKernelFlag;
export declare function psKernelLevelAlwaysZero(value: PsKernelLevel): PsKernelFlag;
export declare function psKernelUniverseSchedule(task: PsKernelUniverseTask, tasks: PsKernelList<PsKernelUniverseTask>, values: PsKernelList<PsKernelLevel>): PsKernelUniverseStep;
export declare function psKernelUniversePush(value: PsKernelLevel, tasks: PsKernelList<PsKernelUniverseTask>, values: PsKernelList<PsKernelLevel>): PsKernelUniverseStep;
export declare function psKernelUniverseSmartMax(left: PsKernelLevel, right: PsKernelLevel, offset: PsKernelNatural, tasks: PsKernelList<PsKernelUniverseTask>, values: PsKernelList<PsKernelLevel>): PsKernelUniverseStep;
export declare function psKernelUniverseIMax(left: PsKernelLevel, right: PsKernelLevel, offset: PsKernelNatural, tasks: PsKernelList<PsKernelUniverseTask>, values: PsKernelList<PsKernelLevel>): PsKernelUniverseStep;
export declare function psKernelUniverseProbes(left: PsKernelLevel, right: PsKernelLevel): PsKernelList<PsKernelMaxProbe>;
export declare function psKernelUniverseFinish(values: PsKernelList<PsKernelLevel>): PsKernelUniverseResult;
export declare function psKernelUniverseStep(state: PsKernelUniverseState): PsKernelUniverseStep;
export declare function psKernelUniverseStart(value: PsKernelLevel): PsKernelUniverseState;
export declare function psKernelUniverseRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelUniverseState): PsKernelUniverseResult;
export declare function psKernelLevelCheckStart(left: PsKernelLevel, right: PsKernelLevel): PsKernelLevelCheckState;
export declare function psKernelLevelCheckStep(state: PsKernelLevelCheckState): PsKernelLevelCheckStep;
export declare function psKernelLevelCheckRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelLevelCheckState): PsKernelLevelCheckResult;
export declare function psKernelLevelInstantiateNext(assignments: PsKernelList<PsKernelLevelAssignment>, tasks: PsKernelList<PsKernelLevelInstantiateTask>, values: PsKernelList<PsKernelLevel>): PsKernelLevelInstantiateStep;
export declare function psKernelLevelInstantiateVisit(assignments: PsKernelList<PsKernelLevelAssignment>, value: PsKernelLevel, rest: PsKernelList<PsKernelLevelInstantiateTask>, values: PsKernelList<PsKernelLevel>): PsKernelLevelInstantiateStep;
export declare function psKernelLevelInstantiateRebuild(assignments: PsKernelList<PsKernelLevelAssignment>, task: PsKernelLevelInstantiateTask, rest: PsKernelList<PsKernelLevelInstantiateTask>, values: PsKernelList<PsKernelLevel>): PsKernelLevelInstantiateStep;
export declare function psKernelLevelInstantiateTaskStep(assignments: PsKernelList<PsKernelLevelAssignment>, task: PsKernelLevelInstantiateTask, rest: PsKernelList<PsKernelLevelInstantiateTask>, values: PsKernelList<PsKernelLevel>): PsKernelLevelInstantiateStep;
export declare function psKernelLevelInstantiateStep(state: PsKernelLevelInstantiateState): PsKernelLevelInstantiateStep;
export declare function psKernelLevelInstantiateStart(names: PsKernelList<PsKernelName>, levels: PsKernelList<PsKernelLevel>, target: PsKernelLevel): PsKernelLevelInstantiateState;
export declare function psKernelLevelInstantiateRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelLevelInstantiateState): PsKernelLevelInstantiateResult;
export declare function psKernelExprInstantiateNext(names: PsKernelList<PsKernelName>, levels: PsKernelList<PsKernelLevel>, tasks: PsKernelList<PsKernelExprInstantiateTask>, values: PsKernelList<PsKernelExpr>): PsKernelExprInstantiateStep;
export declare function psKernelExprInstantiateLevelError(result: PsKernelLevelInstantiateResult): PsKernelExprInstantiateStep;
export declare function psKernelExprInstantiateVisit(names: PsKernelList<PsKernelName>, levels: PsKernelList<PsKernelLevel>, value: PsKernelExpr, tasks: PsKernelList<PsKernelExprInstantiateTask>, values: PsKernelList<PsKernelExpr>): PsKernelExprInstantiateStep;
export declare function psKernelExprInstantiateTaskStep(names: PsKernelList<PsKernelName>, levels: PsKernelList<PsKernelLevel>, task: PsKernelExprInstantiateTask, rest: PsKernelList<PsKernelExprInstantiateTask>, values: PsKernelList<PsKernelExpr>): PsKernelExprInstantiateStep;
export declare function psKernelExprInstantiateStep(state: PsKernelExprInstantiateState): PsKernelExprInstantiateStep;
export declare function psKernelExprInstantiateStart(names: PsKernelList<PsKernelName>, levels: PsKernelList<PsKernelLevel>, target: PsKernelExpr): PsKernelExprInstantiateState;
export declare function psKernelExprInstantiateRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelExprInstantiateState): PsKernelExprInstantiateResult;
export declare function psKernelDefinitionName(entry: PsKernelDefinition): PsKernelName;
export declare function psKernelDefinitionParameters(entry: PsKernelDefinition): PsKernelList<PsKernelName>;
export declare function psKernelDefinitionType(entry: PsKernelDefinition): PsKernelExpr;
export declare function psKernelDefinitionBody(entry: PsKernelDefinition): PsKernelDefinitionBody;
export declare function psKernelTypingDeclarations(context: PsKernelTypingContext): PsKernelList<PsKernelDefinition>;
export declare function psKernelTypingParameters(context: PsKernelTypingContext): PsKernelList<PsKernelName>;
export declare function psKernelLookupStep(state: PsKernelLookupState): PsKernelLookupStep;
export declare const psKernelBuiltinNatName: PsKernelName;
export declare const psKernelBuiltinNatZeroName: PsKernelName;
export declare const psKernelBuiltinNatSuccName: PsKernelName;
export declare function psKernelBuiltinNatStart(env: PsKernelList<PsKernelDefinition>): PsKernelBuiltinNatState;
export declare function psKernelBuiltinNatStep(state: PsKernelBuiltinNatState): PsKernelBuiltinNatStep;
export declare const psKernelBuiltinStringName: PsKernelName;
export declare function psKernelUtf8Ranges(mode: PsKernelUtf8Mode): PsKernelList<PsKernelUtf8Range>;
export declare function psKernelUtf8Start(text: PsKernelText): PsKernelUtf8State;
export declare function psKernelUtf8Step(state: PsKernelUtf8State): PsKernelUtf8Step;
export declare function psKernelTextCheckStart(env: PsKernelList<PsKernelDefinition>, text: PsKernelText): PsKernelTextCheckState;
export declare function psKernelTextCheckStep(state: PsKernelTextCheckState): PsKernelTextCheckStep;
export declare function psKernelStringPreludeStart(env: PsKernelList<PsKernelDefinition>): PsKernelStringPreludeState;
export declare function psKernelStringPreludeStep(state: PsKernelStringPreludeState): PsKernelStringPreludeStep;
export declare function psKernelAlgReduceStep(state: PsKernelAlgReduceState): PsKernelAlgReduceStep;
export declare function psKernelAlgReduceStart(original: PsKernelExpr, head: PsKernelExpr, parameters: PsKernelNatural, rules: PsKernelList<PsKernelAlgRule>, args: PsKernelList<PsKernelExpr>): PsKernelAlgReduceState;
export declare function psKernelAlgReduceResume(continuation: PsKernelAlgReduceContinuation, major: PsKernelExpr): PsKernelAlgReduceState;
export declare function psKernelRecordNeutral(action: PsKernelRecordAction, major: PsKernelExpr): PsKernelExpr;
export declare function psKernelReduceReject(error: PsKernelCheckError): PsKernelReduceStep;
export declare function psKernelReduceNext(env: PsKernelList<PsKernelDefinition>, tasks: PsKernelList<PsKernelReduceTask>, values: PsKernelList<PsKernelExpr>): PsKernelReduceStep;
export declare function psKernelReducePush(env: PsKernelList<PsKernelDefinition>, tasks: PsKernelList<PsKernelReduceTask>, values: PsKernelList<PsKernelExpr>, value: PsKernelExpr): PsKernelReduceStep;
export declare function psKernelReduceWhnf(env: PsKernelList<PsKernelDefinition>, tasks: PsKernelList<PsKernelReduceTask>, values: PsKernelList<PsKernelExpr>, value: PsKernelExpr): PsKernelReduceStep;
export declare function psKernelReduceEnumApply(env: PsKernelList<PsKernelDefinition>, tasks: PsKernelList<PsKernelReduceTask>, values: PsKernelList<PsKernelExpr>, fn: PsKernelExpr, arg: PsKernelExpr): PsKernelReduceStep;
export declare function psKernelReduceNeutralApply(env: PsKernelList<PsKernelDefinition>, tasks: PsKernelList<PsKernelReduceTask>, values: PsKernelList<PsKernelExpr>, fn: PsKernelExpr, arg: PsKernelExpr): PsKernelReduceStep;
export declare function psKernelReduceValueTask(env: PsKernelList<PsKernelDefinition>, task: PsKernelReduceTask, tasks: PsKernelList<PsKernelReduceTask>, values: PsKernelList<PsKernelExpr>): PsKernelReduceStep;
export declare function psKernelReduceStep(state: PsKernelReduceState): PsKernelReduceStep;
export declare function psKernelWhnfStart(env: PsKernelList<PsKernelDefinition>, value: PsKernelExpr): PsKernelReduceState;
export declare function psKernelNormalStart(env: PsKernelList<PsKernelDefinition>, value: PsKernelExpr): PsKernelReduceState;
export declare function psKernelReduceRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelReduceState): PsKernelReduceResult;
export declare function psKernelConversionReject(error: PsKernelCheckError): PsKernelConversionStep;
export declare function psKernelConversionTasks(tasks: PsKernelList<PsKernelConversionTask>): PsKernelConversionStep;
export declare function psKernelConversionExpr(left: PsKernelExpr, right: PsKernelExpr, tasks: PsKernelList<PsKernelConversionTask>): PsKernelConversionStep;
export declare function psKernelConversionStep(state: PsKernelConversionState): PsKernelConversionStep;
export declare function psKernelConversionStart(env: PsKernelList<PsKernelDefinition>, left: PsKernelExpr, right: PsKernelExpr): PsKernelConversionState;
export declare function psKernelConversionRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelConversionState): PsKernelConversionResult;
export declare function psKernelTypeReject(error: PsKernelCheckError): PsKernelTypeStep;
export declare function psKernelTypeNext(env: PsKernelTypingContext, tasks: PsKernelList<PsKernelTypeTask>, values: PsKernelList<PsKernelExpr>): PsKernelTypeStep;
export declare function psKernelTypePush(env: PsKernelTypingContext, tasks: PsKernelList<PsKernelTypeTask>, values: PsKernelList<PsKernelExpr>, value: PsKernelExpr): PsKernelTypeStep;
export declare function psKernelTypeInfer(env: PsKernelTypingContext, context: PsKernelList<PsKernelExpr>, value: PsKernelExpr, tasks: PsKernelList<PsKernelTypeTask>, values: PsKernelList<PsKernelExpr>): PsKernelTypeStep;
export declare function psKernelTypeValueTask(env: PsKernelTypingContext, task: PsKernelTypeTask, tasks: PsKernelList<PsKernelTypeTask>, values: PsKernelList<PsKernelExpr>): PsKernelTypeStep;
export declare function psKernelTypeLevels(env: PsKernelTypingContext, pending: PsKernelList<PsKernelLevel>, tasks: PsKernelList<PsKernelTypeTask>, values: PsKernelList<PsKernelExpr>): PsKernelTypeStep;
export declare function psKernelTypeStep(state: PsKernelTypeState): PsKernelTypeStep;
export declare function psKernelInferStart(env: PsKernelList<PsKernelDefinition>, value: PsKernelExpr): PsKernelTypeState;
export declare function psKernelCheckWithParametersStart(env: PsKernelList<PsKernelDefinition>, parameters: PsKernelList<PsKernelName>, value: PsKernelExpr, type: PsKernelExpr): PsKernelTypeState;
export declare function psKernelCheckStart(env: PsKernelList<PsKernelDefinition>, value: PsKernelExpr, type: PsKernelExpr): PsKernelTypeState;
export declare function psKernelTypeRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelTypeState): PsKernelTypeResult;
export declare function psKernelAdmissionReject(error: PsKernelCheckError): PsKernelAdmissionStep;
export declare function psKernelAdmissionStep(state: PsKernelAdmissionState): PsKernelAdmissionStep;
export declare function psKernelAdmissionStart(entries: PsKernelList<PsKernelDefinition>): PsKernelAdmissionState;
export declare function psKernelAdmissionRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelAdmissionState): PsKernelAdmissionResult;
export declare function psKernelUnitNext(env: PsKernelList<PsKernelDefinition>, declaration: PsKernelUnitDeclaration, task: PsKernelUnitTask): PsKernelUnitStep;
export declare function psKernelUnitReject(error: PsKernelCheckError): PsKernelUnitStep;
export declare function psKernelUnitRecursorName(family: PsKernelName): PsKernelName;
export declare function psKernelUnitRecursorType(family: PsKernelExpr, ctor: PsKernelExpr, motive: PsKernelName): PsKernelExpr;
export declare function psKernelUnitStep(state: PsKernelUnitState): PsKernelUnitStep;
export declare function psKernelUnitStart(env: PsKernelList<PsKernelDefinition>, declaration: PsKernelUnitDeclaration): PsKernelUnitState;
export declare function psKernelUnitRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelUnitState): PsKernelAdmissionResult;
export declare const psKernelNatFamilySort: PsKernelExpr;
export declare function psKernelNatConstructorName(declaration: PsKernelNatDeclaration, phase: PsKernelNatPhase): PsKernelName;
export declare function psKernelNatConstructorType(declaration: PsKernelNatDeclaration, phase: PsKernelNatPhase): PsKernelExpr;
export declare function psKernelNatExpectedConstructor(name: PsKernelName, phase: PsKernelNatPhase): PsKernelExpr;
export declare function psKernelNatRecursorType(family: PsKernelExpr, zero: PsKernelExpr, succ: PsKernelExpr, motive: PsKernelName): PsKernelExpr;
export declare function psKernelNatAdmissionNext(env: PsKernelList<PsKernelDefinition>, declaration: PsKernelNatDeclaration, task: PsKernelNatAdmissionTask): PsKernelNatAdmissionStep;
export declare function psKernelNatAdmissionReject(error: PsKernelCheckError): PsKernelNatAdmissionStep;
export declare function psKernelNatAdmissionStep(state: PsKernelNatAdmissionState): PsKernelNatAdmissionStep;
export declare function psKernelNatAdmissionStart(env: PsKernelList<PsKernelDefinition>, declaration: PsKernelNatDeclaration): PsKernelNatAdmissionState;
export declare function psKernelNatAdmissionRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelNatAdmissionState): PsKernelAdmissionResult;
export declare function psKernelRecordNext(env: PsKernelList<PsKernelDefinition>, declaration: PsKernelUnitDeclaration, task: PsKernelRecordTask): PsKernelRecordStep;
export declare function psKernelRecordReject(error: PsKernelCheckError): PsKernelRecordStep;
export declare function psKernelRecordMotive(name: PsKernelName): PsKernelName;
export declare function psKernelRecordFamilyEnvironment(env: PsKernelList<PsKernelDefinition>, name: PsKernelName): PsKernelList<PsKernelDefinition>;
export declare function psKernelRecordConstructorEnvironment(env: PsKernelList<PsKernelDefinition>, name: PsKernelName, ctorName: PsKernelName, ctorType: PsKernelExpr): PsKernelList<PsKernelDefinition>;
export declare function psKernelRecordRecursorType(family: PsKernelExpr, minor: PsKernelExpr, motive: PsKernelName): PsKernelExpr;
export declare function psKernelRecordStep(state: PsKernelRecordState): PsKernelRecordStep;
export declare function psKernelRecordStart(env: PsKernelList<PsKernelDefinition>, declaration: PsKernelUnitDeclaration): PsKernelRecordState;
export declare function psKernelRecordRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelRecordState): PsKernelAdmissionResult;
export declare function psKernelEnumNext(env: PsKernelList<PsKernelDefinition>, declaration: PsKernelEnumDeclaration, task: PsKernelEnumTask): PsKernelEnumStep;
export declare function psKernelEnumReject(error: PsKernelCheckError): PsKernelEnumStep;
export declare const psKernelEnumType: PsKernelExpr;
export declare function psKernelEnumRecursorType(name: PsKernelName, body: PsKernelExpr): PsKernelExpr;
export declare function psKernelEnumStep(state: PsKernelEnumState): PsKernelEnumStep;
export declare function psKernelEnumStart(env: PsKernelList<PsKernelDefinition>, declaration: PsKernelEnumDeclaration): PsKernelEnumState;
export declare function psKernelEnumRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelEnumState): PsKernelAdmissionResult;
export declare function psKernelSumNext(env: PsKernelList<PsKernelDefinition>, declaration: PsKernelEnumDeclaration, task: PsKernelSumTask): PsKernelSumStep;
export declare function psKernelSumReject(error: PsKernelCheckError): PsKernelSumStep;
export declare function psKernelSumCurrent(progress: PsKernelSumProgress): PsKernelList<PsKernelDefinition>;
export declare function psKernelSumFamilyName(env: PsKernelList<PsKernelDefinition>, declaration: PsKernelEnumDeclaration): PsKernelSumStep;
export declare function psKernelSumChoose(env: PsKernelList<PsKernelDefinition>, declaration: PsKernelEnumDeclaration): PsKernelSumStep;
export declare function psKernelSumStep(state: PsKernelSumState): PsKernelSumStep;
export declare function psKernelSumStart(env: PsKernelList<PsKernelDefinition>, declaration: PsKernelEnumDeclaration): PsKernelSumState;
export declare function psKernelSumRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelSumState): PsKernelAdmissionResult;
export declare const psKernelAlgType: PsKernelExpr;
export declare function psKernelAlgHeaderNext(env: PsKernelList<PsKernelDefinition>, declaration: PsKernelAlgDeclaration, task: PsKernelAlgHeaderTask): PsKernelAlgHeaderStep;
export declare function psKernelAlgHeaderStep(state: PsKernelAlgHeaderState): PsKernelAlgHeaderStep;
export declare function psKernelAlgHeaderStart(env: PsKernelList<PsKernelDefinition>, declaration: PsKernelAlgDeclaration): PsKernelAlgHeaderState;
export declare function psKernelCloseNext(mode: PsKernelCloseMode, task: PsKernelCloseTask): PsKernelCloseStep;
export declare function psKernelCloseStep(state: PsKernelCloseState): PsKernelCloseStep;
export declare function psKernelCloseStart(mode: PsKernelCloseMode, reversedBinders: PsKernelList<PsKernelAlgBinder>, value: PsKernelExpr): PsKernelCloseState;
export declare function psKernelCloseRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelCloseState): PsKernelCloseResult;
export declare function psKernelOccurrenceNext(family: PsKernelName, parameters: PsKernelFlag, tasks: PsKernelList<PsKernelOccurrenceTask>): PsKernelOccurrenceStep;
export declare function psKernelOccurrenceStep(state: PsKernelOccurrenceState): PsKernelOccurrenceStep;
export declare function psKernelOccurrenceStart(family: PsKernelName, parameters: PsKernelFlag, value: PsKernelExpr): PsKernelOccurrenceState;
export declare function psKernelExprEqualNext(tasks: PsKernelList<PsKernelExprEqualTask>): PsKernelExprEqualStep;
export declare function psKernelExprEqualOrder(task: PsKernelOrderTask, rest: PsKernelList<PsKernelExprEqualTask>): PsKernelExprEqualStep;
export declare function psKernelExprEqualPair(left: PsKernelExpr, right: PsKernelExpr, rest: PsKernelList<PsKernelExprEqualTask>): PsKernelExprEqualStep;
export declare function psKernelExprEqualStep(state: PsKernelExprEqualState): PsKernelExprEqualStep;
export declare function psKernelExprEqualStart(left: PsKernelExpr, right: PsKernelExpr): PsKernelExprEqualState;
export declare function psKernelPositiveFieldNext(env: PsKernelList<PsKernelDefinition>, family: PsKernelName, uniform: PsKernelExpr, task: PsKernelPositiveFieldTask): PsKernelPositiveFieldStep;
export declare function psKernelPositiveFieldStep(state: PsKernelPositiveFieldState): PsKernelPositiveFieldStep;
export declare function psKernelPositiveFieldStart(env: PsKernelList<PsKernelDefinition>, family: PsKernelName, uniform: PsKernelExpr, value: PsKernelExpr): PsKernelPositiveFieldState;
export declare function psKernelPositiveFieldRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelPositiveFieldState): PsKernelPositiveFieldResult;
export declare function psKernelAlgConstructorNext(env: PsKernelList<PsKernelDefinition>, header: PsKernelAlgHeader, input: PsKernelAlgInputConstructor, task: PsKernelAlgConstructorTask): PsKernelAlgConstructorStep;
export declare function psKernelAlgConstructorStep(state: PsKernelAlgConstructorState): PsKernelAlgConstructorStep;
export declare function psKernelAlgConstructorStart(env: PsKernelList<PsKernelDefinition>, header: PsKernelAlgHeader, input: PsKernelAlgInputConstructor): PsKernelAlgConstructorState;
export declare function psKernelAlgConstructorRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelAlgConstructorState): PsKernelAlgConstructorResult;
export declare function psKernelParameterNext(_arguments: PsKernelList<PsKernelExpr>, tasks: PsKernelList<PsKernelParameterTask>, values: PsKernelList<PsKernelExpr>): PsKernelParameterStep;
export declare function psKernelParameterPush(_arguments: PsKernelList<PsKernelExpr>, tasks: PsKernelList<PsKernelParameterTask>, values: PsKernelList<PsKernelExpr>, value: PsKernelExpr): PsKernelParameterStep;
export declare function psKernelParameterVisit(_arguments: PsKernelList<PsKernelExpr>, depth: PsKernelNatural, value: PsKernelExpr, tasks: PsKernelList<PsKernelParameterTask>, values: PsKernelList<PsKernelExpr>): PsKernelParameterStep;
export declare function psKernelParameterRebuild(_arguments: PsKernelList<PsKernelExpr>, task: PsKernelParameterTask, tasks: PsKernelList<PsKernelParameterTask>, values: PsKernelList<PsKernelExpr>): PsKernelParameterStep;
export declare function psKernelParameterStep(state: PsKernelParameterState): PsKernelParameterStep;
export declare function psKernelParameterStart(_arguments: PsKernelList<PsKernelExpr>, value: PsKernelExpr): PsKernelParameterState;
export declare function psKernelParameterRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelParameterState): PsKernelParameterResult;
export declare function psKernelAlgMinorNext(header: PsKernelAlgHeader, constructor: PsKernelAlgConstructor, fieldStart: PsKernelNatural, task: PsKernelAlgMinorTask): PsKernelAlgMinorStep;
export declare function psKernelAlgMinorContinue(header: PsKernelAlgHeader, constructor: PsKernelAlgConstructor, fieldStart: PsKernelNatural, frame: PsKernelAlgMinorFrame, type: PsKernelExpr, flag: PsKernelOption<PsKernelName>, recursive: PsKernelList<PsKernelExpr>): PsKernelAlgMinorStep;
export declare function psKernelAlgMinorStep(state: PsKernelAlgMinorState): PsKernelAlgMinorStep;
export declare function psKernelAlgMinorStart(header: PsKernelAlgHeader, constructor: PsKernelAlgConstructor, fieldStart: PsKernelNatural): PsKernelAlgMinorState;
export declare const psKernelAlgRecursorLevelName: PsKernelName;
export declare function psKernelAlgRecursorNext(header: PsKernelAlgHeader, constructors: PsKernelList<PsKernelAlgConstructor>, task: PsKernelAlgRecursorTask): PsKernelAlgRecursorStep;
export declare function psKernelAlgRecursorStep(state: PsKernelAlgRecursorState): PsKernelAlgRecursorStep;
export declare function psKernelAlgRecursorStart(header: PsKernelAlgHeader, constructors: PsKernelList<PsKernelAlgConstructor>): PsKernelAlgRecursorState;
export declare function psKernelAlgAdmissionNext(env: PsKernelList<PsKernelDefinition>, declaration: PsKernelAlgDeclaration, task: PsKernelAlgAdmissionTask): PsKernelAlgAdmissionStep;
export declare function psKernelAlgAdmissionReject(error: PsKernelCheckError): PsKernelAlgAdmissionStep;
export declare function psKernelAlgAdmissionStep(state: PsKernelAlgAdmissionState): PsKernelAlgAdmissionStep;
export declare function psKernelAlgAdmissionStart(env: PsKernelList<PsKernelDefinition>, declaration: PsKernelAlgDeclaration): PsKernelAlgAdmissionState;
export declare function psKernelAlgAdmissionRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelAlgAdmissionState): PsKernelAdmissionResult;
export declare function psKernelJointContinue(rest: PsKernelList<PsKernelJointEntry>, result: PsKernelAdmissionResult): PsKernelJointStep;
export declare function psKernelJointStep(state: PsKernelJointState): PsKernelJointStep;
export declare function psKernelJointStart(entries: PsKernelList<PsKernelJointEntry>): PsKernelJointState;
export declare function psKernelJointRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelJointState): PsKernelAdmissionResult;
export declare const psKernelBootstrapNatName: PsKernelName;
export declare const psKernelBootstrapNat: PsKernelNatDeclaration;
export declare function psKernelBootstrapStep(state: PsKernelBootstrapState): PsKernelBootstrapStep;
export declare function psKernelBootstrapStart(entries: PsKernelList<PsKernelJointEntry>): PsKernelBootstrapState;
export declare function psKernelBootstrapRun(fuel: PsKernelFuel, __ps_eta_0: PsKernelBootstrapState): PsKernelAdmissionResult;
export {};
