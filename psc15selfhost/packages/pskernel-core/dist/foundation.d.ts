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
export type PsKernelDefinitionBody = {
    readonly [__ps$tag$47]: "transparent";
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$47]: "opaque";
};
export declare const PsKernelDefinitionBody: {
    readonly transparent: (__field0: PsKernelExpr) => PsKernelDefinitionBody;
    readonly opaque: PsKernelDefinitionBody;
};
declare const __ps$tag$48: unique symbol;
export type PsKernelDefinition = {
    readonly [__ps$tag$48]: "definition";
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$48]: "polymorphic";
    readonly name: PsKernelName;
    readonly parameters: PsKernelList<PsKernelName>;
    readonly type: PsKernelExpr;
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$48]: "constant";
    readonly name: PsKernelName;
    readonly parameters: PsKernelList<PsKernelName>;
    readonly type: PsKernelExpr;
} | {
    readonly [__ps$tag$48]: "unitRecursor";
    readonly name: PsKernelName;
    readonly parameters: PsKernelList<PsKernelName>;
    readonly type: PsKernelExpr;
    readonly ctorName: PsKernelName;
} | {
    readonly [__ps$tag$48]: "recordFamily";
    readonly name: PsKernelName;
    readonly ctorName: PsKernelName;
    readonly fields: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$48]: "recordRecursor";
    readonly name: PsKernelName;
    readonly parameters: PsKernelList<PsKernelName>;
    readonly type: PsKernelExpr;
    readonly ctorName: PsKernelName;
    readonly fields: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$48]: "natFamily";
    readonly name: PsKernelName;
    readonly zeroName: PsKernelName;
    readonly succName: PsKernelName;
} | {
    readonly [__ps$tag$48]: "natRecursor";
    readonly name: PsKernelName;
    readonly parameters: PsKernelList<PsKernelName>;
    readonly type: PsKernelExpr;
    readonly zeroName: PsKernelName;
    readonly succName: PsKernelName;
};
export declare const PsKernelDefinition: {
    readonly definition: (__field0: PsKernelName, __field1: PsKernelExpr, __field2: PsKernelExpr) => PsKernelDefinition;
    readonly polymorphic: (__field0: PsKernelName, __field1: PsKernelList<PsKernelName>, __field2: PsKernelExpr, __field3: PsKernelExpr) => PsKernelDefinition;
    readonly constant: (__field0: PsKernelName, __field1: PsKernelList<PsKernelName>, __field2: PsKernelExpr) => PsKernelDefinition;
    readonly unitRecursor: (__field0: PsKernelName, __field1: PsKernelList<PsKernelName>, __field2: PsKernelExpr, __field3: PsKernelName) => PsKernelDefinition;
    readonly recordFamily: (__field0: PsKernelName, __field1: PsKernelName, __field2: PsKernelList<PsKernelExpr>) => PsKernelDefinition;
    readonly recordRecursor: (__field0: PsKernelName, __field1: PsKernelList<PsKernelName>, __field2: PsKernelExpr, __field3: PsKernelName, __field4: PsKernelList<PsKernelExpr>) => PsKernelDefinition;
    readonly natFamily: (__field0: PsKernelName, __field1: PsKernelName, __field2: PsKernelName) => PsKernelDefinition;
    readonly natRecursor: (__field0: PsKernelName, __field1: PsKernelList<PsKernelName>, __field2: PsKernelExpr, __field3: PsKernelName, __field4: PsKernelName) => PsKernelDefinition;
};
declare const __ps$tag$49: unique symbol;
export type PsKernelTypingContext = {
    readonly [__ps$tag$49]: "context";
    readonly declarations: PsKernelList<PsKernelDefinition>;
    readonly parameters: PsKernelList<PsKernelName>;
};
export declare const PsKernelTypingContext: {
    readonly context: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelList<PsKernelName>) => PsKernelTypingContext;
};
declare const __ps$tag$50: unique symbol;
export type PsKernelCheckError = {
    readonly [__ps$tag$50]: "invalidState";
} | {
    readonly [__ps$tag$50]: "invalidScope";
} | {
    readonly [__ps$tag$50]: "unknownConstant";
} | {
    readonly [__ps$tag$50]: "unsupported";
} | {
    readonly [__ps$tag$50]: "typeExpected";
} | {
    readonly [__ps$tag$50]: "functionExpected";
} | {
    readonly [__ps$tag$50]: "typeMismatch";
} | {
    readonly [__ps$tag$50]: "duplicateName";
} | {
    readonly [__ps$tag$50]: "invalidName";
} | {
    readonly [__ps$tag$50]: "invalidUniverse";
};
export declare const PsKernelCheckError: {
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
declare const __ps$tag$51: unique symbol;
export type PsKernelLookupState = {
    readonly [__ps$tag$51]: "search";
    readonly name: PsKernelName;
    readonly entries: PsKernelList<PsKernelDefinition>;
} | {
    readonly [__ps$tag$51]: "compare";
    readonly name: PsKernelName;
    readonly entry: PsKernelDefinition;
    readonly rest: PsKernelList<PsKernelDefinition>;
    readonly tasks: PsKernelList<PsKernelOrderTask>;
};
export declare const PsKernelLookupState: {
    readonly search: (__field0: PsKernelName, __field1: PsKernelList<PsKernelDefinition>) => PsKernelLookupState;
    readonly compare: (__field0: PsKernelName, __field1: PsKernelDefinition, __field2: PsKernelList<PsKernelDefinition>, __field3: PsKernelList<PsKernelOrderTask>) => PsKernelLookupState;
};
declare const __ps$tag$52: unique symbol;
export type PsKernelLookupStep = {
    readonly [__ps$tag$52]: "next";
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$52]: "found";
    readonly entry: PsKernelDefinition;
} | {
    readonly [__ps$tag$52]: "missing";
} | {
    readonly [__ps$tag$52]: "invalidState";
};
export declare const PsKernelLookupStep: {
    readonly next: (__field0: PsKernelLookupState) => PsKernelLookupStep;
    readonly found: (__field0: PsKernelDefinition) => PsKernelLookupStep;
    readonly missing: PsKernelLookupStep;
    readonly invalidState: PsKernelLookupStep;
};
declare const __ps$tag$53: unique symbol;
export type PsKernelBuiltinNatState = {
    readonly [__ps$tag$53]: "lookup";
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$53]: "names";
    readonly tasks: PsKernelList<PsKernelOrderTask>;
};
export declare const PsKernelBuiltinNatState: {
    readonly lookup: (__field0: PsKernelLookupState) => PsKernelBuiltinNatState;
    readonly names: (__field0: PsKernelList<PsKernelOrderTask>) => PsKernelBuiltinNatState;
};
declare const __ps$tag$54: unique symbol;
export type PsKernelBuiltinNatStep = {
    readonly [__ps$tag$54]: "next";
    readonly state: PsKernelBuiltinNatState;
} | {
    readonly [__ps$tag$54]: "ready";
} | {
    readonly [__ps$tag$54]: "rejected";
    readonly error: PsKernelCheckError;
};
export declare const PsKernelBuiltinNatStep: {
    readonly next: (__field0: PsKernelBuiltinNatState) => PsKernelBuiltinNatStep;
    readonly ready: PsKernelBuiltinNatStep;
    readonly rejected: (__field0: PsKernelCheckError) => PsKernelBuiltinNatStep;
};
declare const __ps$tag$55: unique symbol;
export type PsKernelReduceTask = {
    readonly [__ps$tag$55]: "natural";
    readonly value: PsKernelNatural;
    readonly state: PsKernelBuiltinNatState;
} | {
    readonly [__ps$tag$55]: "whnf";
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$55]: "apply";
    readonly arg: PsKernelExpr;
} | {
    readonly [__ps$tag$55]: "lookup";
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$55]: "unitLookup";
    readonly fn: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly minor: PsKernelExpr;
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$55]: "unitMajor";
    readonly fn: PsKernelExpr;
    readonly minor: PsKernelExpr;
    readonly ctorName: PsKernelName;
    readonly levels: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$55]: "unitName";
    readonly fn: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly minor: PsKernelExpr;
    readonly left: PsKernelList<PsKernelLevel>;
    readonly right: PsKernelList<PsKernelLevel>;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$55]: "unitLevels";
    readonly fn: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly minor: PsKernelExpr;
    readonly left: PsKernelList<PsKernelLevel>;
    readonly right: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$55]: "unitLevel";
    readonly fn: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly minor: PsKernelExpr;
    readonly left: PsKernelList<PsKernelLevel>;
    readonly right: PsKernelList<PsKernelLevel>;
    readonly state: PsKernelLevelCheckState;
} | {
    readonly [__ps$tag$55]: "natLookup";
    readonly fn: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly zeroCase: PsKernelExpr;
    readonly succCase: PsKernelExpr;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$55]: "natMajor";
    readonly fn: PsKernelExpr;
    readonly zeroCase: PsKernelExpr;
    readonly succCase: PsKernelExpr;
    readonly zeroName: PsKernelName;
    readonly succName: PsKernelName;
} | {
    readonly [__ps$tag$55]: "natZeroName";
    readonly fn: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly zeroCase: PsKernelExpr;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$55]: "natSuccName";
    readonly fn: PsKernelExpr;
    readonly major: PsKernelExpr;
    readonly succCase: PsKernelExpr;
    readonly predecessor: PsKernelExpr;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$55]: "opaqueConstant";
    readonly value: PsKernelExpr;
    readonly state: PsKernelLevelInstantiateState;
} | {
    readonly [__ps$tag$55]: "instantiate";
    readonly state: PsKernelExprInstantiateState;
} | {
    readonly [__ps$tag$55]: "binding";
    readonly state: PsKernelBindingState;
} | {
    readonly [__ps$tag$55]: "resumeWhnf";
} | {
    readonly [__ps$tag$55]: "normal";
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$55]: "expand";
} | {
    readonly [__ps$tag$55]: "app";
} | {
    readonly [__ps$tag$55]: "lam";
    readonly name: PsKernelName;
    readonly binder: PsKernelBinder;
} | {
    readonly [__ps$tag$55]: "forallE";
    readonly name: PsKernelName;
    readonly binder: PsKernelBinder;
};
export declare const PsKernelReduceTask: {
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
declare const __ps$tag$56: unique symbol;
export type PsKernelReduceState = {
    readonly [__ps$tag$56]: "state";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly tasks: PsKernelList<PsKernelReduceTask>;
    readonly values: PsKernelList<PsKernelExpr>;
};
export declare const PsKernelReduceState: {
    readonly state: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelList<PsKernelReduceTask>, __field2: PsKernelList<PsKernelExpr>) => PsKernelReduceState;
};
declare const __ps$tag$57: unique symbol;
export type PsKernelReduceResult = {
    readonly [__ps$tag$57]: "outOfFuel";
} | {
    readonly [__ps$tag$57]: "rejected";
    readonly error: PsKernelCheckError;
} | {
    readonly [__ps$tag$57]: "done";
    readonly value: PsKernelExpr;
};
export declare const PsKernelReduceResult: {
    readonly outOfFuel: PsKernelReduceResult;
    readonly rejected: (__field0: PsKernelCheckError) => PsKernelReduceResult;
    readonly done: (__field0: PsKernelExpr) => PsKernelReduceResult;
};
declare const __ps$tag$58: unique symbol;
export type PsKernelReduceStep = {
    readonly [__ps$tag$58]: "next";
    readonly state: PsKernelReduceState;
} | {
    readonly [__ps$tag$58]: "final";
    readonly result: PsKernelReduceResult;
};
export declare const PsKernelReduceStep: {
    readonly next: (__field0: PsKernelReduceState) => PsKernelReduceStep;
    readonly final: (__field0: PsKernelReduceResult) => PsKernelReduceStep;
};
declare const __ps$tag$59: unique symbol;
export type PsKernelConversionTask = {
    readonly [__ps$tag$59]: "expr";
    readonly left: PsKernelExpr;
    readonly right: PsKernelExpr;
} | {
    readonly [__ps$tag$59]: "names";
    readonly state: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$59]: "levels";
    readonly left: PsKernelList<PsKernelLevel>;
    readonly right: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$59]: "natural";
    readonly state: PsKernelNumericState;
} | {
    readonly [__ps$tag$59]: "level";
    readonly state: PsKernelLevelCheckState;
};
export declare const PsKernelConversionTask: {
    readonly expr: (__field0: PsKernelExpr, __field1: PsKernelExpr) => PsKernelConversionTask;
    readonly names: (__field0: PsKernelList<PsKernelOrderTask>) => PsKernelConversionTask;
    readonly levels: (__field0: PsKernelList<PsKernelLevel>, __field1: PsKernelList<PsKernelLevel>) => PsKernelConversionTask;
    readonly natural: (__field0: PsKernelNumericState) => PsKernelConversionTask;
    readonly level: (__field0: PsKernelLevelCheckState) => PsKernelConversionTask;
};
declare const __ps$tag$60: unique symbol;
export type PsKernelConversionState = {
    readonly [__ps$tag$60]: "left";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly right: PsKernelExpr;
    readonly state: PsKernelReduceState;
} | {
    readonly [__ps$tag$60]: "right";
    readonly left: PsKernelExpr;
    readonly state: PsKernelReduceState;
} | {
    readonly [__ps$tag$60]: "compare";
    readonly tasks: PsKernelList<PsKernelConversionTask>;
};
export declare const PsKernelConversionState: {
    readonly left: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelExpr, __field2: PsKernelReduceState) => PsKernelConversionState;
    readonly right: (__field0: PsKernelExpr, __field1: PsKernelReduceState) => PsKernelConversionState;
    readonly compare: (__field0: PsKernelList<PsKernelConversionTask>) => PsKernelConversionState;
};
declare const __ps$tag$61: unique symbol;
export type PsKernelConversionResult = {
    readonly [__ps$tag$61]: "outOfFuel";
} | {
    readonly [__ps$tag$61]: "rejected";
    readonly error: PsKernelCheckError;
} | {
    readonly [__ps$tag$61]: "equal";
} | {
    readonly [__ps$tag$61]: "different";
};
export declare const PsKernelConversionResult: {
    readonly outOfFuel: PsKernelConversionResult;
    readonly rejected: (__field0: PsKernelCheckError) => PsKernelConversionResult;
    readonly equal: PsKernelConversionResult;
    readonly different: PsKernelConversionResult;
};
declare const __ps$tag$62: unique symbol;
export type PsKernelConversionStep = {
    readonly [__ps$tag$62]: "next";
    readonly state: PsKernelConversionState;
} | {
    readonly [__ps$tag$62]: "final";
    readonly result: PsKernelConversionResult;
};
export declare const PsKernelConversionStep: {
    readonly next: (__field0: PsKernelConversionState) => PsKernelConversionStep;
    readonly final: (__field0: PsKernelConversionResult) => PsKernelConversionStep;
};
declare const __ps$tag$63: unique symbol;
export type PsKernelTypeTask = {
    readonly [__ps$tag$63]: "natural";
    readonly state: PsKernelBuiltinNatState;
} | {
    readonly [__ps$tag$63]: "infer";
    readonly context: PsKernelList<PsKernelExpr>;
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$63]: "levels";
    readonly pending: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$63]: "levelName";
    readonly name: PsKernelName;
    readonly remaining: PsKernelList<PsKernelName>;
    readonly pending: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$63]: "levelNameCompare";
    readonly name: PsKernelName;
    readonly remaining: PsKernelList<PsKernelName>;
    readonly pending: PsKernelList<PsKernelLevel>;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$63]: "parameterArguments";
    readonly remaining: PsKernelList<PsKernelName>;
    readonly reversed: PsKernelList<PsKernelLevel>;
    readonly value: PsKernelExpr;
    readonly type: PsKernelExpr;
} | {
    readonly [__ps$tag$63]: "parameters";
    readonly state: PsKernelLevelInstantiateState;
    readonly value: PsKernelExpr;
    readonly type: PsKernelExpr;
} | {
    readonly [__ps$tag$63]: "instantiate";
    readonly state: PsKernelExprInstantiateState;
} | {
    readonly [__ps$tag$63]: "bound";
    readonly context: PsKernelList<PsKernelExpr>;
    readonly index: PsKernelNatural;
    readonly shift: PsKernelNatural;
} | {
    readonly [__ps$tag$63]: "lookup";
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$63]: "binding";
    readonly state: PsKernelBindingState;
} | {
    readonly [__ps$tag$63]: "reduce";
    readonly state: PsKernelReduceState;
} | {
    readonly [__ps$tag$63]: "reduceTop";
} | {
    readonly [__ps$tag$63]: "conversion";
    readonly state: PsKernelConversionState;
} | {
    readonly [__ps$tag$63]: "returnE";
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$63]: "lamSort";
    readonly context: PsKernelList<PsKernelExpr>;
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
    readonly body: PsKernelExpr;
    readonly binder: PsKernelBinder;
} | {
    readonly [__ps$tag$63]: "lamFinish";
    readonly name: PsKernelName;
    readonly type: PsKernelExpr;
    readonly binder: PsKernelBinder;
} | {
    readonly [__ps$tag$63]: "piDomain";
    readonly context: PsKernelList<PsKernelExpr>;
    readonly type: PsKernelExpr;
    readonly body: PsKernelExpr;
} | {
    readonly [__ps$tag$63]: "piFinish";
    readonly domainLevel: PsKernelLevel;
} | {
    readonly [__ps$tag$63]: "appPi";
    readonly context: PsKernelList<PsKernelExpr>;
    readonly arg: PsKernelExpr;
} | {
    readonly [__ps$tag$63]: "appArgument";
    readonly domain: PsKernelExpr;
    readonly body: PsKernelExpr;
    readonly arg: PsKernelExpr;
} | {
    readonly [__ps$tag$63]: "letSort";
    readonly context: PsKernelList<PsKernelExpr>;
    readonly type: PsKernelExpr;
    readonly value: PsKernelExpr;
    readonly body: PsKernelExpr;
} | {
    readonly [__ps$tag$63]: "letValue";
    readonly context: PsKernelList<PsKernelExpr>;
    readonly type: PsKernelExpr;
    readonly value: PsKernelExpr;
    readonly body: PsKernelExpr;
} | {
    readonly [__ps$tag$63]: "letBody";
    readonly context: PsKernelList<PsKernelExpr>;
} | {
    readonly [__ps$tag$63]: "checkSort";
    readonly value: PsKernelExpr;
    readonly type: PsKernelExpr;
} | {
    readonly [__ps$tag$63]: "checkValue";
    readonly type: PsKernelExpr;
};
export declare const PsKernelTypeTask: {
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
declare const __ps$tag$64: unique symbol;
export type PsKernelTypeState = {
    readonly [__ps$tag$64]: "state";
    readonly environment: PsKernelTypingContext;
    readonly tasks: PsKernelList<PsKernelTypeTask>;
    readonly values: PsKernelList<PsKernelExpr>;
};
export declare const PsKernelTypeState: {
    readonly state: (__field0: PsKernelTypingContext, __field1: PsKernelList<PsKernelTypeTask>, __field2: PsKernelList<PsKernelExpr>) => PsKernelTypeState;
};
declare const __ps$tag$65: unique symbol;
export type PsKernelTypeResult = {
    readonly [__ps$tag$65]: "outOfFuel";
} | {
    readonly [__ps$tag$65]: "rejected";
    readonly error: PsKernelCheckError;
} | {
    readonly [__ps$tag$65]: "done";
    readonly type: PsKernelExpr;
};
export declare const PsKernelTypeResult: {
    readonly outOfFuel: PsKernelTypeResult;
    readonly rejected: (__field0: PsKernelCheckError) => PsKernelTypeResult;
    readonly done: (__field0: PsKernelExpr) => PsKernelTypeResult;
};
declare const __ps$tag$66: unique symbol;
export type PsKernelTypeStep = {
    readonly [__ps$tag$66]: "next";
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$66]: "final";
    readonly result: PsKernelTypeResult;
};
export declare const PsKernelTypeStep: {
    readonly next: (__field0: PsKernelTypeState) => PsKernelTypeStep;
    readonly final: (__field0: PsKernelTypeResult) => PsKernelTypeStep;
};
declare const __ps$tag$67: unique symbol;
export type PsKernelAdmissionState = {
    readonly [__ps$tag$67]: "pending";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly entries: PsKernelList<PsKernelDefinition>;
} | {
    readonly [__ps$tag$67]: "duplicate";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly entry: PsKernelDefinition;
    readonly rest: PsKernelList<PsKernelDefinition>;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$67]: "checking";
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
declare const __ps$tag$68: unique symbol;
export type PsKernelAdmissionResult = {
    readonly [__ps$tag$68]: "outOfFuel";
} | {
    readonly [__ps$tag$68]: "rejected";
    readonly error: PsKernelCheckError;
} | {
    readonly [__ps$tag$68]: "admitted";
    readonly environment: PsKernelList<PsKernelDefinition>;
};
export declare const PsKernelAdmissionResult: {
    readonly outOfFuel: PsKernelAdmissionResult;
    readonly rejected: (__field0: PsKernelCheckError) => PsKernelAdmissionResult;
    readonly admitted: (__field0: PsKernelList<PsKernelDefinition>) => PsKernelAdmissionResult;
};
declare const __ps$tag$69: unique symbol;
export type PsKernelAdmissionStep = {
    readonly [__ps$tag$69]: "next";
    readonly state: PsKernelAdmissionState;
} | {
    readonly [__ps$tag$69]: "final";
    readonly result: PsKernelAdmissionResult;
};
export declare const PsKernelAdmissionStep: {
    readonly next: (__field0: PsKernelAdmissionState) => PsKernelAdmissionStep;
    readonly final: (__field0: PsKernelAdmissionResult) => PsKernelAdmissionStep;
};
declare const __ps$tag$70: unique symbol;
export type PsKernelUnitDeclaration = {
    readonly [__ps$tag$70]: "declaration";
    readonly name: PsKernelName;
    readonly parameters: PsKernelList<PsKernelName>;
    readonly level: PsKernelLevel;
    readonly ctorName: PsKernelName;
    readonly ctorType: PsKernelExpr;
};
export declare const PsKernelUnitDeclaration: {
    readonly declaration: (__field0: PsKernelName, __field1: PsKernelList<PsKernelName>, __field2: PsKernelLevel, __field3: PsKernelName, __field4: PsKernelExpr) => PsKernelUnitDeclaration;
};
declare const __ps$tag$71: unique symbol;
export type PsKernelUnitTask = {
    readonly [__ps$tag$71]: "initial";
} | {
    readonly [__ps$tag$71]: "parameters";
    readonly remaining: PsKernelList<PsKernelName>;
    readonly reversed: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$71]: "reverse";
    readonly remaining: PsKernelList<PsKernelLevel>;
    readonly levels: PsKernelList<PsKernelLevel>;
} | {
    readonly [__ps$tag$71]: "validate";
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$71]: "family";
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$71]: "constructorName";
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$71]: "constructorType";
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$71]: "constructorResult";
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly state: PsKernelConversionState;
} | {
    readonly [__ps$tag$71]: "fresh";
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly candidate: PsKernelNatural;
    readonly remaining: PsKernelList<PsKernelName>;
} | {
    readonly [__ps$tag$71]: "freshCompare";
    readonly levels: PsKernelList<PsKernelLevel>;
    readonly candidate: PsKernelNatural;
    readonly remaining: PsKernelList<PsKernelName>;
    readonly work: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$71]: "recursorName";
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
declare const __ps$tag$72: unique symbol;
export type PsKernelUnitState = {
    readonly [__ps$tag$72]: "state";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly declaration: PsKernelUnitDeclaration;
    readonly task: PsKernelUnitTask;
};
export declare const PsKernelUnitState: {
    readonly state: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelUnitDeclaration, __field2: PsKernelUnitTask) => PsKernelUnitState;
};
declare const __ps$tag$73: unique symbol;
export type PsKernelUnitStep = {
    readonly [__ps$tag$73]: "next";
    readonly state: PsKernelUnitState;
} | {
    readonly [__ps$tag$73]: "final";
    readonly result: PsKernelAdmissionResult;
};
export declare const PsKernelUnitStep: {
    readonly next: (__field0: PsKernelUnitState) => PsKernelUnitStep;
    readonly final: (__field0: PsKernelAdmissionResult) => PsKernelUnitStep;
};
declare const __ps$tag$74: unique symbol;
export type PsKernelNatDeclaration = {
    readonly [__ps$tag$74]: "declaration";
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
declare const __ps$tag$75: unique symbol;
export type PsKernelNatPhase = {
    readonly [__ps$tag$75]: "zero";
} | {
    readonly [__ps$tag$75]: "succ";
};
export declare const PsKernelNatPhase: {
    readonly zero: PsKernelNatPhase;
    readonly succ: PsKernelNatPhase;
};
declare const __ps$tag$76: unique symbol;
export type PsKernelNatAdmissionTask = {
    readonly [__ps$tag$76]: "initial";
} | {
    readonly [__ps$tag$76]: "familyType";
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$76]: "familySort";
    readonly state: PsKernelConversionState;
} | {
    readonly [__ps$tag$76]: "familyName";
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$76]: "ctorName";
    readonly phase: PsKernelNatPhase;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$76]: "ctorType";
    readonly phase: PsKernelNatPhase;
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$76]: "ctorResult";
    readonly phase: PsKernelNatPhase;
    readonly state: PsKernelConversionState;
} | {
    readonly [__ps$tag$76]: "recursorName";
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
declare const __ps$tag$77: unique symbol;
export type PsKernelNatAdmissionState = {
    readonly [__ps$tag$77]: "state";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly declaration: PsKernelNatDeclaration;
    readonly task: PsKernelNatAdmissionTask;
};
export declare const PsKernelNatAdmissionState: {
    readonly state: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelNatDeclaration, __field2: PsKernelNatAdmissionTask) => PsKernelNatAdmissionState;
};
declare const __ps$tag$78: unique symbol;
export type PsKernelNatAdmissionStep = {
    readonly [__ps$tag$78]: "next";
    readonly state: PsKernelNatAdmissionState;
} | {
    readonly [__ps$tag$78]: "final";
    readonly result: PsKernelAdmissionResult;
};
export declare const PsKernelNatAdmissionStep: {
    readonly next: (__field0: PsKernelNatAdmissionState) => PsKernelNatAdmissionStep;
    readonly final: (__field0: PsKernelAdmissionResult) => PsKernelNatAdmissionStep;
};
declare const __ps$tag$79: unique symbol;
export type PsKernelRecordTask = {
    readonly [__ps$tag$79]: "initial";
} | {
    readonly [__ps$tag$79]: "familyName";
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$79]: "fields";
    readonly remaining: PsKernelExpr;
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly count: PsKernelNatural;
} | {
    readonly [__ps$tag$79]: "fieldType";
    readonly remaining: PsKernelExpr;
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly count: PsKernelNatural;
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$79]: "result";
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly count: PsKernelNatural;
    readonly tasks: PsKernelList<PsKernelOrderTask>;
} | {
    readonly [__ps$tag$79]: "constructorType";
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly count: PsKernelNatural;
    readonly state: PsKernelTypeState;
} | {
    readonly [__ps$tag$79]: "constructorName";
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly count: PsKernelNatural;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$79]: "recursorName";
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly count: PsKernelNatural;
    readonly state: PsKernelLookupState;
} | {
    readonly [__ps$tag$79]: "arguments";
    readonly reversed: PsKernelList<PsKernelExpr>;
    readonly count: PsKernelNatural;
    readonly index: PsKernelNatural;
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$79]: "minor";
    readonly remaining: PsKernelList<PsKernelExpr>;
    readonly fields: PsKernelList<PsKernelExpr>;
    readonly value: PsKernelExpr;
} | {
    readonly [__ps$tag$79]: "recursorType";
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
declare const __ps$tag$80: unique symbol;
export type PsKernelRecordState = {
    readonly [__ps$tag$80]: "state";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly declaration: PsKernelUnitDeclaration;
    readonly task: PsKernelRecordTask;
};
export declare const PsKernelRecordState: {
    readonly state: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelUnitDeclaration, __field2: PsKernelRecordTask) => PsKernelRecordState;
};
declare const __ps$tag$81: unique symbol;
export type PsKernelRecordStep = {
    readonly [__ps$tag$81]: "next";
    readonly state: PsKernelRecordState;
} | {
    readonly [__ps$tag$81]: "final";
    readonly result: PsKernelAdmissionResult;
};
export declare const PsKernelRecordStep: {
    readonly next: (__field0: PsKernelRecordState) => PsKernelRecordStep;
    readonly final: (__field0: PsKernelAdmissionResult) => PsKernelRecordStep;
};
declare const __ps$tag$82: unique symbol;
export type PsKernelJointEntry = {
    readonly [__ps$tag$82]: "definition";
    readonly entry: PsKernelDefinition;
} | {
    readonly [__ps$tag$82]: "unitInductive";
    readonly entry: PsKernelUnitDeclaration;
} | {
    readonly [__ps$tag$82]: "recordInductive";
    readonly entry: PsKernelUnitDeclaration;
} | {
    readonly [__ps$tag$82]: "natInductive";
    readonly entry: PsKernelNatDeclaration;
};
export declare const PsKernelJointEntry: {
    readonly definition: (__field0: PsKernelDefinition) => PsKernelJointEntry;
    readonly unitInductive: (__field0: PsKernelUnitDeclaration) => PsKernelJointEntry;
    readonly recordInductive: (__field0: PsKernelUnitDeclaration) => PsKernelJointEntry;
    readonly natInductive: (__field0: PsKernelNatDeclaration) => PsKernelJointEntry;
};
declare const __ps$tag$83: unique symbol;
export type PsKernelJointState = {
    readonly [__ps$tag$83]: "pending";
    readonly environment: PsKernelList<PsKernelDefinition>;
    readonly entries: PsKernelList<PsKernelJointEntry>;
} | {
    readonly [__ps$tag$83]: "definition";
    readonly rest: PsKernelList<PsKernelJointEntry>;
    readonly state: PsKernelAdmissionState;
} | {
    readonly [__ps$tag$83]: "unitInductive";
    readonly rest: PsKernelList<PsKernelJointEntry>;
    readonly state: PsKernelUnitState;
} | {
    readonly [__ps$tag$83]: "recordInductive";
    readonly rest: PsKernelList<PsKernelJointEntry>;
    readonly state: PsKernelRecordState;
} | {
    readonly [__ps$tag$83]: "natInductive";
    readonly rest: PsKernelList<PsKernelJointEntry>;
    readonly state: PsKernelNatAdmissionState;
};
export declare const PsKernelJointState: {
    readonly pending: (__field0: PsKernelList<PsKernelDefinition>, __field1: PsKernelList<PsKernelJointEntry>) => PsKernelJointState;
    readonly definition: (__field0: PsKernelList<PsKernelJointEntry>, __field1: PsKernelAdmissionState) => PsKernelJointState;
    readonly unitInductive: (__field0: PsKernelList<PsKernelJointEntry>, __field1: PsKernelUnitState) => PsKernelJointState;
    readonly recordInductive: (__field0: PsKernelList<PsKernelJointEntry>, __field1: PsKernelRecordState) => PsKernelJointState;
    readonly natInductive: (__field0: PsKernelList<PsKernelJointEntry>, __field1: PsKernelNatAdmissionState) => PsKernelJointState;
};
declare const __ps$tag$84: unique symbol;
export type PsKernelJointStep = {
    readonly [__ps$tag$84]: "next";
    readonly state: PsKernelJointState;
} | {
    readonly [__ps$tag$84]: "final";
    readonly result: PsKernelAdmissionResult;
};
export declare const PsKernelJointStep: {
    readonly next: (__field0: PsKernelJointState) => PsKernelJointStep;
    readonly final: (__field0: PsKernelAdmissionResult) => PsKernelJointStep;
};
declare const __ps$tag$85: unique symbol;
export type PsKernelBootstrapState = {
    readonly [__ps$tag$85]: "prelude";
    readonly entries: PsKernelList<PsKernelJointEntry>;
    readonly state: PsKernelNatAdmissionState;
} | {
    readonly [__ps$tag$85]: "declarations";
    readonly state: PsKernelJointState;
};
export declare const PsKernelBootstrapState: {
    readonly prelude: (__field0: PsKernelList<PsKernelJointEntry>, __field1: PsKernelNatAdmissionState) => PsKernelBootstrapState;
    readonly declarations: (__field0: PsKernelJointState) => PsKernelBootstrapState;
};
declare const __ps$tag$86: unique symbol;
export type PsKernelBootstrapStep = {
    readonly [__ps$tag$86]: "next";
    readonly state: PsKernelBootstrapState;
} | {
    readonly [__ps$tag$86]: "final";
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
export declare function psKernelReduceReject(error: PsKernelCheckError): PsKernelReduceStep;
export declare function psKernelReduceNext(env: PsKernelList<PsKernelDefinition>, tasks: PsKernelList<PsKernelReduceTask>, values: PsKernelList<PsKernelExpr>): PsKernelReduceStep;
export declare function psKernelReducePush(env: PsKernelList<PsKernelDefinition>, tasks: PsKernelList<PsKernelReduceTask>, values: PsKernelList<PsKernelExpr>, value: PsKernelExpr): PsKernelReduceStep;
export declare function psKernelReduceWhnf(env: PsKernelList<PsKernelDefinition>, tasks: PsKernelList<PsKernelReduceTask>, values: PsKernelList<PsKernelExpr>, value: PsKernelExpr): PsKernelReduceStep;
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
