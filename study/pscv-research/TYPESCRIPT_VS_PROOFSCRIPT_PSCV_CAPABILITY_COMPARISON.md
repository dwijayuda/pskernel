# TypeScript vs ProofScript PSCV — Capability-by-Capability Code Comparison

**Status:** research / design comparison, non-normative  
**Research date:** 2026-10-05  
**TypeScript baseline:** TypeScript 7.0.x language behavior and current TypeScript Handbook  
**ProofScript baseline:** current ProofScript/PSC2 direction plus the assumed **full PSCV** language discussed for the verified-software profile  
**Purpose:** compare how developers solve the same ordinary application-programming problems in TypeScript and ProofScript PSCV without requiring PSCV to clone TypeScript's type system.

---

# 1. Executive conclusion

ProofScript PSCV does **not** need to reproduce TypeScript feature-for-feature in order to replace TypeScript for ordinary application development.

The TypeScript capabilities that dominate day-to-day programming are comparatively compact:

- type inference and annotations;
- functions and callbacks;
- object shapes;
- interfaces/type aliases;
- unions and literal types;
- narrowing;
- discriminated unions;
- generics;
- optional/nullable values;
- arrays, tuples and dictionaries;
- modules;
- async/Promise code;
- classes or object-oriented APIs where libraries use them;
- utility types such as Partial, Pick, Omit and Record;
- type-query operators such as keyof, typeof and indexed access;
- mapped/conditional types in reusable libraries;
- JavaScript/npm interoperability.

PSCV can handle the same application problems with a different center of gravity:

- structures instead of open structural object types;
- inductive types instead of ad-hoc unions;
- pattern matching instead of control-flow narrowing;
- Option instead of null/undefined as ordinary native absence;
- Except / typed application effects instead of arbitrary throw;
- parametric polymorphism and typeclasses instead of much of TypeScript's type-level object computation;
- dependent/refined types for invariants that TypeScript can only approximate structurally;
- requires / ensures / assert / invariant / decreasing for verified contracts;
- theorem/proof terms where TypeScript has no corresponding correctness mechanism;
- explicit InterfaceIR/adapters at the JavaScript/TypeScript boundary for features that are specific to JavaScript's object model.

The right compatibility principle is therefore:

~~~text
TypeScript source/API shape
        |
        v
TypeScript/.d.ts normalization
        |
        v
InterfaceIR / binding model
        |
        +--> native PSCV type/function when semantics align
        +--> generated wrapper when adaptation is needed
        +--> opaque foreign handle for identity-bearing JS objects
        +--> runtime validator for dynamic structural data
        +--> reject when a sound mapping is unavailable
~~~

Do **not** turn PSCV core into another TypeScript merely to import TypeScript libraries.

---

# 2. Research basis and how "most used" is interpreted

There is no authoritative public telemetry that ranks every individual TypeScript type-system feature by real-world frequency.

This study therefore uses several signals together:

1. The current TypeScript Handbook's "daily work" progression: Everyday Types, Narrowing, Functions, Object Types, Generics, Classes and Modules.
2. The TypeScript team's own introductory material, which explicitly highlights unions and generics as popular ways to compose types.
3. TypeScript's standard utility types and type-manipulation reference.
4. State of JavaScript 2025 ecosystem evidence showing that respondents now write an average of about 77% of their JS/TS code in TypeScript, with 4,367 of 10,934 respondents reporting 100% TypeScript.
5. State of JavaScript 2025 evidence that static typing is the most-cited advantage of the build step.
6. Practical ecosystem/style guidance, including Google's TypeScript style guide.
7. The existing ProofScript repository design rule that TypeScript type computation should generally be normalized at the foreign-interface boundary rather than copied into ProofScript core.

The capability tiers below should therefore be read as engineering priorities, not exact usage percentages.

## 2.1 Capability tiers

### Tier A — everyday / must feel excellent

- primitive values and inference;
- functions;
- object/record data;
- unions / variants;
- narrowing / pattern matching;
- generics;
- Option/nullability;
- arrays, tuples, maps/dictionaries;
- callbacks and higher-order functions;
- modules/imports;
- async/effects;
- typed error handling;
- readonly/immutability;
- basic classes/object APIs at the JS boundary.

### Tier B — frequently used advanced TypeScript

- discriminated unions;
- utility types;
- keyof / typeof / indexed access;
- mapped types;
- conditional types;
- generic constraints;
- overloads;
- user-defined type guards;
- intersections;
- literal preservation / as const;
- satisfies;
- branded types;
- record/index signatures.

### Tier C — important ecosystem/boundary capabilities

- .d.ts ingestion;
- declaration merging;
- module augmentation;
- JavaScript classes and this;
- decorators;
- JSX/framework embedding;
- CommonJS;
- dynamic import;
- DOM/Node/npm bindings.

---

# 3. Current TypeScript baseline

TypeScript 7.0 was released on 2026-07-08. TypeScript 7 is a native Go implementation of the compiler/tooling and is intended to preserve TypeScript language/type-checking behavior while substantially improving performance.

This comparison is about the **language and programming model**, not the implementation language of tsc.

Important TypeScript properties for this comparison:

- TypeScript is a superset-style static type system for JavaScript.
- Its type compatibility is primarily structural.
- The official documentation explicitly notes that TypeScript intentionally permits some unsound operations for JavaScript compatibility.
- Most TypeScript-specific types disappear at JavaScript runtime.
- JavaScript runtime identity, mutation, exceptions, Promise semantics and object behavior remain JavaScript semantics.

PSCV has a different goal:

- Lean-grounded semantics;
- proofs as checked terms;
- totality for verified executable closure;
- explicit assumption/effect boundaries;
- verified-build gating;
- proof/spec material erased only after its obligations are closed.

---

# 4. Quick capability map

| Programming need | TypeScript idiom | PSCV idiom | PSCV should clone TS feature? |
|---|---|---|---|
| Plain data record | interface/type/object | structure | No |
| Finite alternatives | literal union / discriminated union | inductive | No |
| Missing value | undefined/null/optional | Option | No |
| Error result | throw / union / Result library | Except / typed App error | No |
| Generic code | generics | parametric polymorphism | Native equivalent |
| Constraint on generic | extends constraint | typeclass / explicit evidence / dependent constraint | No |
| Runtime narrowing | typeof/in/guards | pattern matching / evidence | No |
| Exhaustiveness | never trick / switch | exhaustive match | No |
| Readonly | readonly modifier | immutable native value; explicit mutable capability | No |
| Partial object update | Partial<T> | explicit patch structure with Option fields | Usually no |
| Pick/Omit | utility type computation | explicit domain/API structure | Usually no |
| keyof | type-level key union | explicit field-key inductive or boundary normalization | No |
| Mapped type | mapped type | generated structure / abstraction / boundary normalization | No |
| Conditional type | conditional type/infer | typeclass/type family/domain abstraction | Usually no |
| Brand | intersection with phantom property | subtype/refinement/opaque wrapper | No |
| Function overload | overload signatures | sum input / distinct functions / typeclass | No |
| Promise | Promise<T> | App/Fiber/foreign Promise adapter | No |
| JS class | class | structure + functions natively; opaque handle at JS boundary | No |
| Dynamic unknown data | unknown/any | ForeignValue + decoder/validator | No |
| API declarations | .d.ts | InterfaceIR + generated PSCV bindings | Boundary feature |
| Correctness contract | no native equivalent | requires / ensures | PSCV advantage |
| Loop invariant | no native equivalent | invariant / decreasing | PSCV advantage |
| Formal theorem | no native equivalent | theorem / proof | PSCV advantage |

---

# 5. Side-by-side examples

All PSCV examples below assume the planned **full PSCV** profile. They are design examples, not claims that the current PSC2 compiler already accepts every shown surface form.

## 5.1 Local values and type inference

### TypeScript

~~~ts
const name = "Ada";
const count = 3;
const active: boolean = true;
~~~

### PSCV

~~~proofscript
const name := "Ada"
const count := 3
const active: Bool := true
~~~

### Difference

Both should infer obvious local/static types.

TypeScript may widen literals depending on context. PSCV should prefer mathematically stable elaboration rather than JavaScript-oriented widening rules.

---

## 5.2 Typed functions

### TypeScript

~~~ts
function add(x: number, y: number): number {
  return x + y;
}
~~~

### PSCV

~~~proofscript
function add(x: Int, y: Int): Int :=
  x + y
~~~

### Difference

TypeScript's number means JavaScript IEEE-754 Number semantics.

PSCV must choose the semantic numeric type explicitly. Int, Nat, Float and fixed-width machine integers should not be silently interchangeable.

---

## 5.3 Object types / records

### TypeScript

~~~ts
interface User {
  id: string;
  name: string;
  age: number;
}

const user: User = {
  id: "u1",
  name: "Ada",
  age: 36,
};
~~~

### PSCV

~~~proofscript
structure User {
  id: String
  name: String
  age: Nat
}

const user: User := {
  id := "u1"
  name := "Ada"
  age := 36
}
~~~

### Difference

TypeScript interfaces describe structural object shapes.

PSCV native structures should remain nominal/dependent mathematical data, not become structurally assignable merely to mimic TypeScript.

At a JS boundary, an object matching a .d.ts shape can be validated/adapted into User.

---

## 5.4 Structural compatibility

### TypeScript

~~~ts
interface Named {
  name: string;
}

const employee = {
  name: "Ada",
  employeeId: 42,
};

const named: Named = employee; // OK structurally
~~~

### PSCV

~~~proofscript
structure Named {
  name: String
}

structure Employee {
  name: String
  employeeId: Nat
}

function employeeToNamed(e: Employee): Named := {
  name := e.name
}
~~~

### Difference

PSCV should favor explicit conversions.

TypeScript structural typing is extremely convenient for JavaScript, but the official TypeScript docs explicitly acknowledge intentional unsoundness in parts of compatibility.

For verified native PSCV code, explicit representation and conversion are easier to specify and prove.

---

## 5.5 Type aliases

### TypeScript

~~~ts
type UserId = string;
type Point = { x: number; y: number };
~~~

### PSCV

Documentation-only alias:

~~~proofscript
abbrev UserId := String
~~~

Semantic distinction:

~~~proofscript
structure UserId {
  value: String
}
~~~

### Difference

A TypeScript alias does not create a new nominal type.

PSCV should make the distinction between a transparent abbreviation and a real domain type obvious.

---

## 5.6 Literal unions

### TypeScript

~~~ts
type Direction = "up" | "down" | "left" | "right";

function move(direction: Direction) {
  // ...
}
~~~

### PSCV

~~~proofscript
inductive Direction where {
  | up
  | down
  | left
  | right
}

function move(direction: Direction): Unit :=
  ...
~~~

### Difference

TypeScript literal unions are excellent for finite JS string domains.

PSCV's native equivalent should normally be an inductive type.

When binding a JS API that literally requires strings, generated adapters can map the inductive constructors to exact foreign strings.

---

## 5.7 Enums

### TypeScript

~~~ts
enum Status {
  Idle,
  Running,
  Done,
}
~~~

Modern TypeScript also commonly uses const objects or literal unions.

### PSCV

~~~proofscript
inductive Status where {
  | idle
  | running
  | done
}
~~~

### Difference

PSCV does not need TypeScript/JavaScript enum runtime semantics.

Inductives provide the closed set of cases directly.

---

## 5.8 Discriminated unions

### TypeScript

~~~ts
type LoadState<T> =
  | { kind: "idle" }
  | { kind: "loading" }
  | { kind: "success"; value: T }
  | { kind: "failure"; message: string };

function render<T>(state: LoadState<T>): string {
  switch (state.kind) {
    case "idle":
      return "Idle";
    case "loading":
      return "Loading";
    case "success":
      return String(state.value);
    case "failure":
      return state.message;
  }
}
~~~

### PSCV

~~~proofscript
inductive LoadState (α: Type) where {
  | idle
  | loading
  | success(value: α)
  | failure(message: String)
}

function render {α: Type}(show: α -> String, state: LoadState α): String :=
  match state with {
    | .idle => "Idle"
    | .loading => "Loading"
    | .success value => show(value)
    | .failure message => message
  }
~~~

### Difference

This is one of the strongest PSCV mappings.

TypeScript simulates algebraic data types through structural unions and a discriminator field.

PSCV uses the algebraic datatype directly.

---

## 5.9 Narrowing

### TypeScript

~~~ts
function format(value: string | number): string {
  if (typeof value === "string") {
    return value.trim();
  }
  return value.toFixed(2);
}
~~~

### PSCV

Use an explicit sum:

~~~proofscript
inductive TextOrNumber where {
  | text(value: String)
  | number(value: Float)
}

function format(value: TextOrNumber): String :=
  match value with {
    | .text text => text.trim()
    | .number number => number.toString()
  }
~~~

### Difference

TypeScript uses control-flow analysis to refine a structural union.

PSCV should generally encode the alternatives in the type and use pattern matching, which introduces the corresponding evidence automatically.

---

## 5.10 User-defined type guards

### TypeScript

~~~ts
interface Fish {
  swim(): void;
}

interface Bird {
  fly(): void;
}

function isFish(x: Fish | Bird): x is Fish {
  return "swim" in x;
}
~~~

### PSCV

For native data, use an inductive and pattern matching.

For dynamic foreign data:

~~~proofscript
function decodeFish(value: ForeignValue): Except DecodeError Fish :=
  ...
~~~

A stronger verified decoder can state:

~~~proofscript
function decodeFish(value: ForeignValue): Except DecodeError Fish
  ensures result =>
    match result with {
      | .ok fish => foreignRepresentsFish(value, fish)
      | .error _ => true
    }
:=
  ...
~~~

### Difference

A TypeScript predicate declaration influences static narrowing but is not a proof that runtime logic is correct.

PSCV can require the correspondence theorem when a runtime refinement is security/correctness relevant.

---

## 5.11 Generics

### TypeScript

~~~ts
function identity<T>(value: T): T {
  return value;
}

const x = identity(42);
~~~

### PSCV

~~~proofscript
function identity {α: Type}(value: α): α :=
  value

const x := identity(42)
~~~

### Difference

This is a direct conceptual match: parametric polymorphism.

---

## 5.12 Generic constraints

### TypeScript

~~~ts
function getLength<T extends { length: number }>(value: T): number {
  return value.length;
}
~~~

### PSCV — capability/typeclass style

~~~proofscript
class HasLength (α: Type) where {
  length: α -> Nat
}

function getLength {α: Type} [HasLength α](value: α): Nat :=
  HasLength.length(value)
~~~

### Difference

TypeScript's constraint is structural.

PSCV should normally use a named capability/typeclass or an explicit dependent argument.

This makes the required abstraction an explicit part of the mathematical interface.

---

## 5.13 Arrays and readonly arrays

### TypeScript

~~~ts
function sum(values: readonly number[]): number {
  return values.reduce((a, b) => a + b, 0);
}
~~~

### PSCV

~~~proofscript
function sum(values: Array Int): Int :=
  values.foldl(0, fun total value => total + value)
~~~

### Difference

Native PSCV values should be immutable by default unless mutation is explicit.

TypeScript readonly is static metadata over JavaScript objects/arrays; it does not prove deep runtime immutability.

Foreign mutable JS arrays should therefore use an adapter or explicit mutable-handle semantics.

---

## 5.14 Tuples

### TypeScript

~~~ts
type Point = readonly [number, number];

const p: Point = [10, 20];
~~~

### PSCV

~~~proofscript
abbrev Point := Int × Int

const p: Point := (10, 20)
~~~

Or use a structure when field names matter.

---

## 5.15 Optional values and nullability

### TypeScript

~~~ts
function findUser(id: string): User | undefined {
  // ...
}

const user = findUser("u1");

if (user !== undefined) {
  console.log(user.name);
}
~~~

### PSCV

~~~proofscript
function findUser(id: String): Option User :=
  ...

match findUser("u1") with {
  | .none => ...
  | .some user => print(user.name)
}
~~~

### Difference

Option is the normal PSCV representation for native optionality.

At a JavaScript boundary PSCV must preserve the distinct foreign states:

~~~text
missing
undefined
null
value
~~~

unless an adapter explicitly chooses to collapse them.

---

## 5.16 Optional properties

### TypeScript

~~~ts
interface UpdateUser {
  name?: string;
  age?: number;
}
~~~

### PSCV

~~~proofscript
structure UpdateUser {
  name: Option String
  age: Option Nat
}
~~~

### Difference

For native PSCV, explicit Option fields avoid configuration-dependent optional-property semantics.

For imported TypeScript objects, missing and explicit undefined may need a richer Presence type.

---

## 5.17 Optional chaining and nullish coalescing

### TypeScript

~~~ts
const city =
  user.profile?.address?.city ?? "Unknown";
~~~

### PSCV

Explicit Option composition:

~~~proofscript
const city :=
  match user.profile with {
    | .none => "Unknown"
    | .some profile =>
        match profile.address with {
          | .none => "Unknown"
          | .some address => address.city
        }
  }
~~~

A standard Option library can make this shorter using map/bind/getD.

### Difference

PSCV does not need to copy JavaScript's nullish operators if ordinary Option combinators provide equally pleasant code.

---

## 5.18 Dictionary / Record

### TypeScript

~~~ts
type UserById = Record<string, User>;

const users: UserById = {};
users["u1"] = user;
~~~

### PSCV

Immutable/native map:

~~~proofscript
abbrev UserById := Map String User

const users :=
  Map.empty.insert("u1", user)
~~~

### Difference

TypeScript Record is a type-level object/index-signature convenience.

PSCV should use an actual Map abstraction when dictionary semantics are intended.

---

## 5.19 Higher-order functions and callbacks

### TypeScript

~~~ts
function map<T, U>(
  values: readonly T[],
  f: (value: T) => U,
): U[] {
  return values.map(f);
}
~~~

### PSCV

~~~proofscript
function map {α β: Type}(
  values: List α,
  f: α -> β,
): List β :=
  values.map(f)
~~~

### Difference

Direct conceptual correspondence.

Foreign JavaScript callbacks additionally need lifetime/effect metadata: synchronous/deferred, retained, reentrant, repeated, cancellation behavior, and so on.

---

## 5.20 Exceptions vs typed errors

### TypeScript

~~~ts
function parsePort(text: string): number {
  const value = Number(text);

  if (!Number.isInteger(value) || value <= 0) {
    throw new Error("invalid port");
  }

  return value;
}
~~~

### PSCV

~~~proofscript
inductive PortError where {
  | invalid
}

function parsePort(text: String): Except PortError Nat :=
  match parseNat(text) with {
    | .none => .error(.invalid)
    | .some value =>
        if value > 0 {
          .ok(value)
        } else {
          .error(.invalid)
        }
  }
~~~

### Difference

PSCV should prefer typed failures.

Host/runtime faults remain a separate category instead of pretending every JavaScript throw inhabits a declared application error.

---

## 5.21 Async / Promise

### TypeScript

~~~ts
async function loadUser(id: string): Promise<User> {
  const response = await fetch("/api/users/" + id);

  if (!response.ok) {
    throw new Error("request failed");
  }

  return response.json();
}
~~~

### PSCV

Platform-level effect model:

~~~proofscript
function loadUser(id: String): App NetworkCaps HttpError User := do {
  let response <- Http.get("/api/users/" ++ id)
  let user <- response.decodeJson(User.decoder)
  return user
}
~~~

### Difference

Promise should be treated as a foreign asynchronous mechanism, not the definition of PSCV effects.

The ProofScript platform design distinguishes App/Fiber/Stream/Resource-style semantics and adapts Promise at the JS boundary.

This allows typed errors, cancellation and resource policies to be specified independently of JavaScript Promise behavior.

---

## 5.22 Modules

### TypeScript

~~~ts
// math.ts
export function add(a: number, b: number) {
  return a + b;
}

// app.ts
import { add } from "./math";
~~~

### PSCV

~~~proofscript
-- Math.ps
function add(a: Int, b: Int): Int :=
  a + b

-- App.ps
import Math

const result := Math.add(1, 2)
~~~

For re-export:

~~~proofscript
public import Math
~~~

### Difference

PSCV should have one deterministic semantic module system.

ESM/CJS/package-exports complexity belongs to the JavaScript/npm adapter, not the language core.

---

## 5.23 Classes

### TypeScript

~~~ts
class Counter {
  private value = 0;

  increment(): void {
    this.value++;
  }

  current(): number {
    return this.value;
  }
}
~~~

### PSCV — native immutable model

~~~proofscript
structure Counter {
  value: Nat
}

function Counter.increment(counter: Counter): Counter := {
  value := counter.value + 1
}

function Counter.current(counter: Counter): Nat :=
  counter.value
~~~

### Difference

Native PSCV should not copy JavaScript class identity and mutable prototype semantics.

For actual imported JavaScript classes, use opaque foreign handles plus generated constructor/method/property wrappers.

ProofScript <code>class</code> should remain a typeclass abstraction, not JavaScript OO class semantics.

---

## 5.24 Interfaces as behavioral capabilities

### TypeScript

~~~ts
interface Show {
  show(): string;
}
~~~

### PSCV typeclass

~~~proofscript
class Show (α: Type) where {
  show: α -> String
}
~~~

### Difference

This is a better match when the TypeScript interface represents a behavioral capability rather than merely an object shape.

---

## 5.25 Readonly

### TypeScript

~~~ts
interface Config {
  readonly host: string;
  readonly port: number;
}
~~~

### PSCV

~~~proofscript
structure Config {
  host: String
  port: Nat
}
~~~

Native structures are values; mutation should be explicit.

### Difference

TypeScript readonly prevents certain writes through a static view. It is not a theorem of deep immutability.

PSCV can give native immutable values stronger semantics and treat foreign mutable objects separately.

---

## 5.26 Partial<T>

### TypeScript

~~~ts
interface User {
  name: string;
  age: number;
}

function updateUser(
  user: User,
  patch: Partial<User>,
): User {
  return { ...user, ...patch };
}
~~~

### PSCV

Use an explicit patch type:

~~~proofscript
structure UserPatch {
  name: Option String
  age: Option Nat
}

function updateUser(user: User, patch: UserPatch): User := {
  name := patch.name.getD(user.name)
  age := patch.age.getD(user.age)
}
~~~

### Difference

TypeScript utility types are excellent for manipulating object shapes.

For native verified PSCV code, an explicit domain type is often clearer, has stable semantics, and can carry its own invariants.

---

## 5.27 Pick<T, K> and Omit<T, K>

### TypeScript

~~~ts
interface User {
  id: string;
  name: string;
  passwordHash: string;
}

type PublicUser =
  Pick<User, "id" | "name">;
~~~

### PSCV

~~~proofscript
structure PublicUser {
  id: String
  name: String
}

function User.toPublic(user: User): PublicUser := {
  id := user.id
  name := user.name
}
~~~

### Difference

PSCV should usually make security-relevant API projections explicit.

A generated binding/importer may synthesize such types automatically when normalizing foreign .d.ts declarations.

---

## 5.28 keyof

### TypeScript

~~~ts
interface User {
  id: string;
  name: string;
}

type UserKey = keyof User;
// "id" | "name"

function read(user: User, key: UserKey) {
  return user[key];
}
~~~

### PSCV

When dynamic field selection is actually part of the domain:

~~~proofscript
inductive UserKey where {
  | id
  | name
}

function read(user: User, key: UserKey): String :=
  match key with {
    | .id => user.id
    | .name => user.name
  }
~~~

### Difference

PSCV does not need native keyof.

For imported finite .d.ts computations, InterfaceIR can evaluate keyof and emit an ordinary PSCV finite type.

---

## 5.29 typeof and indexed access types

### TypeScript

~~~ts
const roles = {
  admin: 10,
  user: 20,
} as const;

type Roles = typeof roles;
type RoleName = keyof Roles;
type RoleCode = Roles[RoleName];
~~~

### PSCV

For native code, model the domain directly:

~~~proofscript
inductive Role where {
  | admin
  | user
}

function roleCode(role: Role): Nat :=
  match role with {
    | .admin => 10
    | .user => 20
  }
~~~

### Difference

TypeScript type queries are extremely useful because runtime JavaScript object shapes are often the source of truth.

PSCV should normally make the type the source of truth.

Foreign declaration importers can still normalize typeof/indexed-access expressions where finite and sound.

---

## 5.30 Mapped types

### TypeScript

~~~ts
type Flags<T> = {
  [K in keyof T]: boolean;
};

interface Features {
  search: string;
  billing: string;
}

type FeatureFlags = Flags<Features>;
~~~

### PSCV

If the field set is semantically known:

~~~proofscript
structure FeatureFlags {
  search: Bool
  billing: Bool
}
~~~

Or use a typed key map:

~~~proofscript
inductive Feature where {
  | search
  | billing
}

abbrev FeatureFlags :=
  FiniteMap Feature Bool
~~~

### Difference

Mapped types are valuable TypeScript metaprogramming over structural object keys.

PSCV can usually use algebraic keys, generic collections, generated code, or explicit domain structures.

The .d.ts importer should normalize supported finite mapped types instead of adding a native mapped-type language to PSCV.

---

## 5.31 Conditional types and infer

### TypeScript

~~~ts
type Element<T> =
  T extends readonly (infer U)[] ? U : T;
~~~

### PSCV

Prefer an abstraction that states the relationship directly:

~~~proofscript
class Container (C: Type) where {
  Item: Type
  toList: C -> List Item
}
~~~

Generic algorithms then quantify over Container rather than decomposing arbitrary type syntax.

### Difference

TypeScript conditional types are a type-level pattern language used heavily by generic library authors.

PSCV should not necessarily expose reflection over arbitrary type syntax in ordinary verified programs.

Where a foreign .d.ts conditional type reduces finitely, import normalization can compute it.

---

## 5.32 Intersections

### TypeScript

~~~ts
interface Named {
  name: string;
}

interface Timestamped {
  createdAt: number;
}

type NamedEvent =
  Named & Timestamped;
~~~

### PSCV

~~~proofscript
structure NamedEvent {
  name: String
  createdAt: Instant
}
~~~

Or compose explicitly from structures when that representation is useful.

### Difference

PSCV should not adopt open structural intersection semantics just for TypeScript parity.

Foreign intersections can be normalized when their representation is finite and unambiguous.

---

## 5.33 Function overloads

### TypeScript

~~~ts
function parse(value: string): number;
function parse(value: number): string;
function parse(value: string | number) {
  return typeof value === "string"
    ? Number(value)
    : String(value);
}
~~~

### PSCV — explicit alternatives

~~~proofscript
inductive ParseInput where {
  | text(value: String)
  | number(value: Int)
}

inductive ParseOutput where {
  | number(value: Int)
  | text(value: String)
}

function parse(value: ParseInput): ParseOutput :=
  match value with {
    | .text text => .number(parseInt(text))
    | .number number => .text(number.toString())
  }
~~~

Or expose two ordinary functions when that API is clearer.

### Difference

The existing ProofScript platform direction is to normalize TypeScript overload groups into specialized wrappers, explicit dispatch wrappers, or rejection.

PSCV does not need TypeScript overload-resolution semantics in core.

---

## 5.34 Default and named parameters

### TypeScript

~~~ts
function connect(
  host: string,
  port = 443,
): Connection {
  // ...
}

connect("example.com");
~~~

### PSCV

~~~proofscript
function connect(
  host: String,
  port: Nat := 443,
): Connection :=
  ...

connect(host := "example.com")
~~~

### Difference

This is mostly an ergonomic mapping and is already aligned with the ProofScript direction.

---

## 5.35 Rest / variadic parameters

### TypeScript

~~~ts
function sum(...values: number[]): number {
  return values.reduce((a, b) => a + b, 0);
}
~~~

### PSCV

~~~proofscript
function sum(values: Array Int): Int :=
  values.foldl(0, fun total value => total + value)
~~~

### Difference

Rest parameters are not required as a core language feature.

A convenience syntax may lower to an ordinary Array/List argument.

Foreign variadic APIs can receive generated wrappers.

---

## 5.36 as const

### TypeScript

~~~ts
const methods = ["GET", "POST"] as const;

type Method = typeof methods[number];
~~~

### PSCV

~~~proofscript
inductive Method where {
  | get
  | post
}
~~~

### Difference

TypeScript uses as const to stop widening and derive precise types from runtime values.

PSCV should normally define the precise domain type directly.

---

## 5.37 satisfies

### TypeScript

~~~ts
type RouteMap =
  Record<string, { secure: boolean }>;

const routes = {
  "/": { secure: false },
  "/admin": { secure: true },
} satisfies RouteMap;
~~~

### PSCV

~~~proofscript
structure RouteInfo {
  secure: Bool
}

abbrev RouteMap :=
  Map String RouteInfo

const routes: RouteMap :=
  Map.ofList([
    ("/", { secure := false }),
    ("/admin", { secure := true }),
  ])
~~~

### Difference

TypeScript satisfies checks assignability while preserving a more specific inferred type.

PSCV can usually use an explicit expected type, refinement, or theorem depending on what is meant by "satisfies".

---

## 5.38 Branded types

### TypeScript

~~~ts
type UserId =
  string & { readonly __brand: "UserId" };

function asUserId(value: string): UserId {
  return value as UserId;
}
~~~

### PSCV

Nominal wrapper:

~~~proofscript
structure UserId {
  value: String
}
~~~

Validated/refined identifier:

~~~proofscript
structure UserId {
  value: String
  valid: isValidUserId(value)
}
~~~

### Difference

A TypeScript brand is mostly static convention and can often be asserted.

PSCV can encode the distinction as an actual type and, when useful, carry proof of the invariant.

---

## 5.39 Type assertions

### TypeScript

~~~ts
const value =
  raw as User;
~~~

The compiler trusts the assertion within TypeScript's assertion rules; this is not runtime validation.

### PSCV

For foreign/dynamic data:

~~~proofscript
function decodeUser(
  raw: ForeignValue,
): Except DecodeError User :=
  ...
~~~

### Difference

Strict PSCV should not provide an unchecked assertion that magically turns unknown foreign data into a verified native value.

Use a decoder, explicit assumption boundary, or proof.

---

## 5.40 any and unknown

### TypeScript

~~~ts
function parseJson(text: string): unknown {
  return JSON.parse(text);
}

const dangerous: any =
  JSON.parse(text);
~~~

### PSCV

~~~proofscript
function parseJson(text: String):
  Except JsonError JsonValue :=
  ...

function decodeUser(value: JsonValue):
  Except DecodeError User :=
  ...
~~~

For arbitrary foreign JS:

~~~proofscript
opaque ForeignValue
~~~

### Difference

PSCV should have no native escape hatch equivalent to TypeScript any in verified code.

Dynamic foreign values remain opaque until validated, decoded, or explicitly assumed.

---

## 5.41 Exhaustiveness and never

### TypeScript

~~~ts
type Shape =
  | { kind: "circle"; radius: number }
  | { kind: "square"; size: number };

function area(shape: Shape): number {
  switch (shape.kind) {
    case "circle":
      return Math.PI * shape.radius ** 2;
    case "square":
      return shape.size ** 2;
    default: {
      const _exhaustive: never = shape;
      return _exhaustive;
    }
  }
}
~~~

### PSCV

~~~proofscript
inductive Shape where {
  | circle(radius: Float)
  | square(size: Float)
}

function area(shape: Shape): Float :=
  match shape with {
    | .circle radius => Float.pi * radius * radius
    | .square size => size * size
  }
~~~

### Difference

Exhaustive pattern checking should be native to PSCV.

The TypeScript never idiom is unnecessary for ordinary closed inductives.

---

## 5.42 Destructuring and object spread

### TypeScript

~~~ts
const { id, name } = user;

const renamed = {
  ...user,
  name: "Grace",
};
~~~

### PSCV

~~~proofscript
const id := user.id
const name := user.name

const renamed :=
  { user with name := "Grace" }
~~~

### Difference

PSCV can provide convenient record update syntax without adopting JavaScript's generic object-spread semantics.

---

## 5.43 Mutable locals and loops

### TypeScript

~~~ts
function factorial(n: number): number {
  let result = 1;

  for (let i = 2; i <= n; i++) {
    result *= i;
  }

  return result;
}
~~~

### PSCV — verified loop style

~~~proofscript
function factorial(n: Nat): Nat := do {
  let mut result := 1
  let mut i := 2

  while i <= n
    invariant result = factorialRange(2, i)
    decreasing n + 1 - i
  {
    result := result * i
    i := i + 1
  }

  return result
}
~~~

### PSCV — functional style

~~~proofscript
function factorial(n: Nat): Nat :=
  match n with {
    | 0 => 1
    | n + 1 => (n + 1) * factorial(n)
  }
~~~

### Difference

Full PSCV may support mutation/loops, but verified code attaches explicit invariants/termination evidence where required.

Compiler/self-host code can remain in the smaller functional profile even if application PSCV is richer.

---

## 5.44 Contracts

TypeScript has no native formal pre/postcondition system.

### TypeScript

~~~ts
function withdraw(
  balance: number,
  amount: number,
): number {
  if (amount > balance) {
    throw new Error("insufficient funds");
  }

  return balance - amount;
}
~~~

Tests or comments express most behavioral expectations.

### PSCV

~~~proofscript
function withdraw(
  balance: Nat,
  amount: Nat,
): Nat
  requires amount <= balance
  ensures result => result + amount = balance
:=
  balance - amount
~~~

### Difference

This is a fundamental PSCV advantage.

A verified PSCV build may require the generated obligation to be closed before executable emission.

---

## 5.45 Assertions

### TypeScript

~~~ts
if (index >= items.length) {
  throw new Error("out of bounds");
}

// programmer reasoning continues here
~~~

### PSCV

~~~proofscript
assert index < items.length

const item :=
  items[index]
~~~

### Difference

In PSCV, assert can mean a compile-time proof obligation rather than only a runtime test.

Whether a runtime check remains is an explicit compilation/policy decision.

---

## 5.46 Refinement / dependent API

### TypeScript

~~~ts
function head<T>(items: readonly T[]): T {
  if (items.length === 0) {
    throw new Error("empty");
  }

  return items[0]!;
}
~~~

### PSCV

~~~proofscript
structure NonEmptyList (α: Type) {
  head: α
  tail: List α
}

function head {α: Type}(items: NonEmptyList α): α :=
  items.head
~~~

Or use a dependent proof that a List is nonempty.

### Difference

PSCV can make invalid states unrepresentable rather than relying on a non-null assertion.

---

## 5.47 Theorem about code

TypeScript has no equivalent language-level mechanism.

### TypeScript

~~~ts
function reverse<T>(values: readonly T[]): T[] {
  return [...values].reverse();
}

// Correctness is tested/documented.
~~~

### PSCV

~~~proofscript
function reverse {α: Type}(values: List α): List α :=
  ...

theorem reverse_reverse {α: Type}(values: List α):
  reverse(reverse(values)) = values :=
by
  induction values <;> simp [reverse, *]
~~~

### Difference

The theorem is checked by the logical kernel and can be part of mandatory build assurance.

---

## 5.48 Specification/proof separate from executable source

PSCV proofs do not need to clutter implementation files.

~~~text
packages/example/
  src/Example.ps
  proof/Example.proof.ps
~~~

The semantic rule should be:

~~~text
source declarations
      |
      v
mandatory obligations
      |
      +-- inline proof
      +-- automatic proof
      +-- separate proof module
      |
      v
kernel-accepted evidence
~~~

A missing proof file is not itself a failure.

An unresolved mandatory obligation is.

---

# 6. TypeScript features PSCV should usually NOT copy into core

## 6.1 Structural assignability

Reason TypeScript has it:

- JavaScript programs already use anonymous object shapes pervasively.

Why PSCV should not copy it wholesale:

- nominal structures give clearer mathematical identity;
- representation-changing conversions are explicit;
- proof obligations are easier to state;
- accidental compatibility is reduced.

Interop solution:

- validate/adapt foreign structural objects at InterfaceIR boundaries.

---

## 6.2 any

Do not add an equivalent to verified PSCV.

Interop solution:

- ForeignValue / JsonValue / opaque handle;
- explicit decoder or assumption boundary.

---

## 6.3 declaration merging and module augmentation

These are valuable for modeling JavaScript libraries.

They should be normalized before native PSCV declarations are generated.

---

## 6.4 keyof, mapped, conditional and template-literal type languages

These features are powerful for describing JavaScript APIs and building reusable structural type libraries.

PSCV's native alternative is usually one or more of:

- algebraic datatypes;
- parametric polymorphism;
- dependent types;
- typeclasses;
- explicit domain structures;
- ordinary compile-time generated bindings.

The .d.ts importer still needs to understand common finite uses.

---

## 6.5 JavaScript class/this semantics

Native PSCV should keep ordinary value semantics and explicit effects.

Foreign class objects can be opaque handles with generated method wrappers preserving this binding.

---

## 6.6 arbitrary overload-resolution semantics

Normalize foreign overloads into explicit PSCV functions or dispatch types.

---

## 6.7 unchecked assertion-style casts

Verified code should use checked conversion, proof, decoder or explicit assumption boundary.

---

# 7. TypeScript capabilities PSCV SHOULD match or exceed in developer experience

Even when PSCV uses different semantics, these tasks must remain easy:

1. Define a record in a few lines.
2. Define a finite variant/sum type in a few lines.
3. Write a generic function without ceremony.
4. Infer obvious local types.
5. Work comfortably with lists/arrays/maps/sets.
6. Pass lambdas/callbacks easily.
7. Handle optional values ergonomically.
8. Handle typed errors ergonomically.
9. Write async/network/database code with do notation.
10. Import modules/packages predictably.
11. Navigate to definitions, find references and rename.
12. Generate bindings from npm/.d.ts automatically.
13. Call JS APIs without hand-writing wrappers for common cases.
14. Publish PSCV libraries to the JS/npm ecosystem where appropriate.
15. Get fast incremental checking and IDE feedback.
16. Keep proofs out of the way when automation solves them.
17. Surface proof goals clearly only when obligations remain open.

A language that is mathematically stronger but dramatically worse at these tasks will not be an effective TypeScript replacement.

---

# 8. PSCV capabilities with no real TypeScript equivalent

These are the places PSCV should intentionally be **more capable**, not merely different.

## 8.1 Mandatory proof-gated build

~~~text
mandatory proof open
        =>
no verified executable artifact
~~~

## 8.2 Formal specification coverage

Public/critical declarations can be required to have formal behavioral specification coverage.

## 8.3 Preconditions/postconditions

Native requires / ensures generate proof obligations.

## 8.4 Loop invariants and termination

Verified loops can require invariants and decreasing measures.

## 8.5 Ghost state

Verification-only data can support proofs while being erased from runtime, subject to noninterference rules.

## 8.6 Assumption closure

A verified build can enumerate and restrict axioms/foreign assumptions.

## 8.7 Effect closure

A verified target can reject unmodeled effects or require explicit capability/boundary models.

## 8.8 Proof erasure with checked noninterference

Proofs are erased after being checked, while executable behavior remains tied to the proved program.

## 8.9 Dependent/refined data

Invalid states can be excluded by construction.

## 8.10 Kernel-checkable theorems

Properties can be checked independently of the automation that generated the proof.

---

# 9. What PSCV still needs beyond core language features to replace TypeScript

Language syntax alone is not enough.

The existing ProofScript design is correct to separate language capability from platform capability.

## 9.1 Standard application libraries

At minimum:

- List / Array;
- Map / Set;
- String / Unicode;
- JSON;
- Date/time;
- regular expressions;
- numeric conversions;
- URL;
- encoding/decoding;
- Result/Except utilities;
- validation/decoding combinators.

## 9.2 Effect/runtime libraries

- App;
- Fiber;
- Stream;
- Resource;
- cancellation;
- structured concurrency;
- filesystem capability;
- network capability;
- console/logging;
- clock;
- randomness;
- process/environment;
- storage;
- DOM/browser capabilities.

## 9.3 JavaScript/npm InterfaceIR

The TypeScript replacement story requires first-class ingestion of real package interfaces:

~~~text
package.json
exports/imports
ESM/CJS resolution
.d.ts
TypeScript structural object types
overloads
generics
optional/rest parameters
Promise/callbacks
classes/this
declaration merging
module augmentation
DOM/Node declarations
        |
        v
InterfaceIR
        |
        v
generated PSCV bindings/adapters
~~~

## 9.4 Tooling

- package manager integration;
- semantic lockfiles;
- build cache;
- incremental compiler;
- LSP;
- completion;
- hover;
- go to definition;
- references;
- rename;
- diagnostics;
- formatter;
- test runner integration;
- source maps/debugging;
- npm publication/binding generation.

---

# 10. Recommended feature ownership

| Capability | PSCV core language | Standard library | JS platform / InterfaceIR | Tooling |
|---|---:|---:|---:|---:|
| structure / inductive | yes | | | |
| pattern matching | yes | | | |
| generics / dependent types | yes | | | |
| class/instance | yes | | | |
| requires / ensures | yes | verification library support | | |
| theorem/proof | yes | tactics/prover library | | |
| Option / Except | small foundational types | rich combinators | | |
| Map / Set | | yes | | |
| async App/Fiber | | yes | adapters | |
| Resource/Stream | | yes | adapters | |
| JS Promise | | | yes | |
| callbacks | function values | | foreign lifetime/effect metadata | |
| TypeScript structural object | no | | yes | |
| keyof/indexed access | no | | normalize finite foreign cases | |
| mapped/conditional type | no | | normalize supported foreign cases | |
| .d.ts | no | | yes | |
| ESM/CJS/npm resolution | no | | yes | package/build tooling |
| JSX | no | optional controlled extension | framework adapter/plugin | IDE |
| decorators | no general unrestricted semantics | controlled attributes/extensions | adapter where needed | |
| DOM/Node | no | capability APIs | generated bindings | |
| LSP | no | | compiler service | yes |

---

# 11. Priority assessment for a TypeScript-replacement PSCV

## P0 — must be excellent

- structures/records;
- inductive variants;
- pattern matching;
- generic functions;
- type inference;
- Option;
- Except;
- arrays/lists/maps;
- lambdas/higher-order functions;
- modules;
- named/default arguments;
- practical do notation;
- typed application effects;
- JS/npm/.d.ts binding generation.

## P1 — essential verification differentiators

- requires;
- ensures;
- assert;
- invariant;
- decreasing;
- proof blocks/modules;
- automated proof discharge;
- coverage/assumption/effect/erasure gates;
- assurance reporting.

## P2 — ecosystem breadth

- Promise adapters;
- callbacks;
- classes/this wrappers;
- ESM/CJS;
- DOM;
- Node;
- React/JSX or framework adapters;
- package publication;
- source maps/debugger integration.

## P3 — optional native ergonomics

Only add after real usage demonstrates value:

- richer local mutation syntax;
- additional loop sugar;
- variadic-call sugar;
- sophisticated pattern sugar;
- selected deriving;
- selected metaprogramming.

Do not add native keyof/mapped/conditional/template-literal types merely for TypeScript surface parity.

---

# 12. A representative end-to-end comparison

## TypeScript application service

~~~ts
type UserId = string;

interface User {
  id: UserId;
  name: string;
  email?: string;
}

interface UserStore {
  get(id: UserId): Promise<User | undefined>;
  save(user: User): Promise<void>;
}

class UserService {
  constructor(private readonly store: UserStore) {}

  async rename(
    id: UserId,
    name: string,
  ): Promise<User> {
    const user = await this.store.get(id);

    if (!user) {
      throw new Error("user not found");
    }

    const updated = {
      ...user,
      name,
    };

    await this.store.save(updated);

    return updated;
  }
}
~~~

Strengths:

- concise;
- excellent ecosystem fit;
- familiar OO/service style;
- Promise and object syntax are direct JavaScript;
- structural interfaces make mocking/adaptation easy.

What is not established by the language:

- that save persists exactly the returned user;
- that rename preserves id;
- that email is unchanged;
- that missing-user behavior matches a formal API contract;
- that all effects/assumptions are known.

## PSCV application service

~~~proofscript
structure UserId {
  value: String
}

structure User {
  id: UserId
  name: String
  email: Option String
}

class UserStore (Store: Type) where {
  get:
    Store ->
    UserId ->
    App StoreCaps StoreError (Option User)

  save:
    Store ->
    User ->
    App StoreCaps StoreError Unit
}

function rename {Store: Type} [UserStore Store](
  store: Store,
  id: UserId,
  name: String,
): App StoreCaps RenameError User
  ensures result =>
    match result with {
      | .ok user =>
          user.id = id &&
          user.name = name
      | .error _ =>
          true
    }
:=
do {
  let found <- UserStore.get(store, id)

  match found with {
    | .none =>
        fail(.notFound)

    | .some user =>
        let updated: User := {
          user with
          name := name
        }

        UserStore.save(store, updated)
        return updated
  }
}
~~~

Strengths:

- domain identities are actual types;
- absence is explicit;
- effect/error surface is typed;
- contract is machine-checkable;
- implementation and proof obligations are connected;
- a strict verified build can refuse emission if the postcondition remains unresolved.

Tradeoff:

- stronger semantics require more explicit modeling;
- JS/npm integration must be exceptionally good so that foreign code does not become painful.

---

# 13. Design implications for ProofScript

## 13.1 Do not chase TypeScript syntax count

The target should be:

~~~text
same application capability
+ better semantic precision
+ better verification
+ excellent JS interoperability
~~~

not:

~~~text
every TypeScript operator has a PSCV spelling
~~~

## 13.2 Make the common path shorter than the proof-heavy path

Most routine PSCV code should look like ordinary programming.

Proof obligations that automation solves should stay mostly invisible.

Only unresolved/high-value obligations should force the programmer into explicit proof work.

## 13.3 Use ordinary mathematical datatypes instead of structural type tricks

Prefer:

- structure;
- inductive;
- Option;
- Except;
- Map;
- typeclasses;
- dependent/refined types.

Use TS-specific type computation primarily in the importer.

## 13.4 Preserve a small compiler implementation profile

The full PSCV language can be much richer than the source profile used to implement the PSCV compiler itself.

The existing PSC1 self-host pattern already demonstrates that parsers, elaborators, unification, erasure and backends can be implemented in a small functional profile.

Full PSCV proof files can then use stronger proof ergonomics without forcing the executable compiler source to use every application feature.

---

# 14. Recommended acceptance test suite against TypeScript

Before claiming practical TypeScript replacement capability, PSCV should implement representative programs covering:

1. CRUD REST service.
2. React/JSX or equivalent frontend binding.
3. CLI application.
4. npm library publication.
5. JSON-heavy API client.
6. WebSocket/streaming client.
7. filesystem/build tool.
8. database application.
9. authentication/authorization core.
10. discriminated-union state machine.
11. generic collection library.
12. typed event emitter/callback API.
13. Promise-heavy SDK binding.
14. JS class-heavy library binding.
15. package using complex .d.ts utility/mapped/conditional types.
16. compiler/tooling application.
17. verified financial/state-transition core.

For each benchmark compare:

- source size;
- readability;
- build time;
- incremental-check time;
- required annotations;
- foreign-wrapper volume;
- proof effort;
- runtime performance;
- package ergonomics;
- diagnostics;
- editor navigation;
- assurance achieved.

---

# 15. Bottom line

For ordinary application programming, **PSCV has the semantic capacity to cover the important TypeScript use cases without adopting TypeScript's entire type-level metaprogramming language**.

The most important direct PSCV capabilities are:

~~~text
structures
inductives
pattern matching
generics
typeclasses
Option
Except
collections
modules
do/effects
requires/ensures
assert/invariant/decreasing
proofs
dependent/refined types
~~~

The most important TypeScript compatibility work belongs outside core:

~~~text
.d.ts normalization
structural object adaptation
keyof/indexed/mapped/conditional type evaluation
overload normalization
optional/rest parameter adaptation
Promise/callback adaptation
JS class/this wrappers
declaration merging
module augmentation
ESM/CJS/npm resolution
DOM/Node/framework bindings
~~~

The product goal should therefore be:

> **PSCV should feel at least as convenient as TypeScript for common application code, substantially stronger for domain invariants and correctness, and deliberately different where TypeScript's features exist mainly to model JavaScript's dynamic structural object system.**

---

# 16. Sources

## Official TypeScript sources

- TypeScript Handbook index: https://www.typescriptlang.org/docs/handbook/
- Handbook — Everyday Types: https://www.typescriptlang.org/docs/handbook/2/everyday-types.html
- Handbook — Narrowing: https://www.typescriptlang.org/docs/handbook/2/narrowing.html
- Handbook — Functions: https://www.typescriptlang.org/docs/handbook/2/functions.html
- Handbook — Object Types: https://www.typescriptlang.org/docs/handbook/2/objects.html
- Handbook — Generics: https://www.typescriptlang.org/docs/handbook/2/generics.html
- Handbook — Modules: https://www.typescriptlang.org/docs/handbook/2/modules.html
- Handbook — Utility Types: https://www.typescriptlang.org/docs/handbook/utility-types.html
- Type Compatibility: https://www.typescriptlang.org/docs/handbook/type-compatibility.html
- Declaration Files: https://www.typescriptlang.org/docs/handbook/declaration-files/introduction.html
- Declaration Merging: https://www.typescriptlang.org/docs/handbook/declaration-merging.html
- Enums: https://www.typescriptlang.org/docs/handbook/enums.html
- TSConfig strictness reference: https://www.typescriptlang.org/tsconfig/
- TypeScript 7.0 announcement: https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/

## Ecosystem evidence

- State of JavaScript 2025 — Usage: https://2025.stateofjs.com/en-US/usage/
- State of JavaScript 2025 — Features: https://2025.stateofjs.com/en-US/features/
- State of JavaScript 2025 — Libraries/Build Tools: https://2025.stateofjs.com/en-US/libraries/
- Google TypeScript Style Guide: https://google.github.io/styleguide/tsguide.html

## ProofScript repository basis

- <code>psc15selfhost/PSC2_COMPLETE_LANGUAGE_AND_JS_PLATFORM.md</code>
- <code>psc15selfhost/ARCHITECTURE.md</code>
- current PSCV design direction developed from the ProofScript/Lean verification work.

---

# 17. Non-normative status note

This document is comparative research.

It intentionally assumes the planned **full PSCV** language for the right-hand code samples. It must not be read as a claim that the current PSC2/self-host compiler already implements every shown PSCV feature.

Where a PSCV code example uses planned facilities such as verified loops, rich effects or stronger contracts, the example describes the target PSCV programming model rather than current compiler conformance.
