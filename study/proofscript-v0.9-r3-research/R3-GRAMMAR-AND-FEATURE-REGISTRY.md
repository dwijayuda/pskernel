# r3 Exact Overlay Grammar and Feature Registry

Status: **normative for `ps-0.9-r3` surface ownership**

This document specifies the r3-owned overlay. Native categories not replaced here are inherited from the exact r2/Lean 4.34 baseline through `R3-AUTHORITY-AND-DELTA.md`.

## 1. Lexical rule for parenthesized calls

`CallGap` permits:
- zero or more spaces/tabs;
- Lean comments that contain **no physical line terminator**.

A physical line terminator ends the possibility of r3 parenthesized-call ownership between the completed head and the opening `(`.

Thus:

~~~proofscript
f(x)
f (x)
f/- comment -/(x)
~~~

are the same r3 call form, but:

~~~proofscript
f
(x)
~~~

is **not** one r3 parenthesized call.

Multiline argument lists remain valid **after** the opening parenthesis:

~~~proofscript
f(
  x,
  y,
)
~~~

A block comment containing a newline breaks `CallGap`.

This rule avoids calls crossing native `do`, tactic, local-declaration or other sequence boundaries invisibly.

## 2. Field notation

r3 does not change Lean field-notation adjacency.

~~~proofscript
users.map(render)   -- field notation + r3 call
users .map(render)  -- not added by r3
~~~

The dot must retain the inherited native adjacency rule.

## 3. Empty-call semantics

`f()` is an **empty source-level invocation**, not textually identical to `f(())`.

The elaboration rule is:

1. infer the callable head using the native-compatible environment;
2. insert implicit and instance-implicit arguments according to native rules;
3. insert optional/default and automatic parameters when they are omitted;
4. if the next still-required explicit parameter is definitionally `Unit`, synthesize exactly one explicit `()` for the empty-call sugar;
5. continue inserting trailing implicit, instance, optional/default and automatic parameters;
6. if any required non-Unit explicit parameter remains unsatisfied, reject with `PS_EMPTY_CALL_REQUIRES_ARGUMENT`;
7. do not eta-abstract missing required arguments for an empty call.

Consequences:

~~~proofscript
function now(): Time := ...
now()                         -- supplies Unit

function greet(name: String := "world"): String := ...
greet()                       -- uses the native default

function add(x: Nat): Nat := x + 1
add()                         -- reject: required non-Unit argument

function staged(_: Unit, x: Nat): Nat := x
staged()                      -- reject: x remains required
staged(())                    -- ordinary explicit Unit call; native partial application may remain
~~~

A nonempty call retains native-compatible partial-application behavior.

`function f()` lowers to one explicit Unit binder. The empty-call rule is what makes the declaration/call pair ergonomic without redefining core arity.

## 4. Owned grammar

~~~ebnf
PSFile              ::= StandardCommandSequence EOF

PSCommand           ::= OwnedValueDecl
                      | BracedStructure
                      | BracedClass
                      | BracedInductive
                      | BracedInstance
                      | Lift<AllowedNativeCommand>

OwnedValueDecl      ::= Native<DefModifiers> ConstDecl
                      | Native<DefModifiers> FunctionDecl
                      | Native<DefModifiers> DecoratedDef

ConstDecl           ::= "const" Native<DeclId> ResultSpec? OwnedValue

FunctionDecl        ::= "function" Native<DeclId> FunctionBinders
                        ResultSpec? ContractClauses? OwnedValue

DecoratedDef        ::= "def" Native<DeclId> HeaderBinders?
                        ResultSpec? ContractClauses? OwnedValue

FunctionBinders     ::= EmptyFunctionGroup
                      | HeaderBinder+

EmptyFunctionGroup  ::= "(" ")"
HeaderBinders       ::= HeaderBinder+
HeaderBinder        ::= ExplicitGroup | Native<OtherDeclarationBinder>

ExplicitGroup       ::= "(" ExplicitEntry ("," ExplicitEntry)* ","? ")"
ExplicitEntry       ::= Native<BinderIdent> ":" PSTerm Native<DefaultSuffix>?

ResultSpec          ::= ":" PSTerm
OwnedValue          ::= ":=" PSDeclBody Native<TerminationSuffix>? WhereSuffix?
PSDeclBody          ::= Lift<NativeDeclBody>

WhereSuffix         ::= BracedWhere | Lift<NativeWhereDecls>
BracedWhere         ::= "where" "{" WhereField (";" WhereField)* ";"? "}"

BracedStructure     ::= Native<StructurePrefixAndHeader> "where"
                        "{" StructField ("," StructField)* "}"
                        Native<DerivingSuffix>?

BracedClass         ::= Native<ClassPrefixAndHeader> "where"
                        "{" ClassField ("," ClassField)* "}"
                        Native<DerivingSuffix>?

BracedInductive     ::= Native<InductivePrefixAndHeader> "where"
                        "{" Constructor+ "}" Native<InductiveSuffix>?
Constructor         ::= "|" Lift<NativeConstructorBody>

BracedInstance      ::= Native<InstancePrefixAndHeader> "where"
                        "{" InstanceField (";" InstanceField)* ";"? "}"

PSTerm              ::= ParenthesizedCall
                      | EmptyCall
                      | BracedIf
                      | BracedMatch
                      | Lift<AllowedNativeTerm>

ParenthesizedCall   ::= CallableHead CallGap "(" CallArguments ")"
EmptyCall           ::= CallableHead CallGap "(" ")"

CallArguments       ::= CallArgument ("," CallArgument)* ","?
CallArgument        ::= NamedCallArgument | PositionalCallArgument
NamedCallArgument   ::= Native<Ident> ":=" PSTerm
PositionalCallArgument ::= PSTerm

CallableHead        ::= Native<CompatibleCompletedHead>
                      | "(" PSTerm ")"
                      | ParenthesizedCall
                      | EmptyCall
                      | NativeProjectionOfCompletedHead

BracedIf            ::= "if" "(" PSTerm ")" "{" PSTerm "}"
                        "else" "{" PSTerm "}"

BracedMatch         ::= Native<MatchPrefixAndDiscriminantsWithLiftedTerms>
                        "with" "{" MatchAlternative+ "}"
MatchAlternative    ::= "|" Native<PatternGroup> "=>" PSTerm

ContractClauses     ::= PureContractClause*
PureContractClause  ::= "requires" PSTerm
                      | "ensures" Native<Ident> "=>" PSTerm

StructField         ::= Lift<NativeStructField>
ClassField          ::= Lift<NativeClassField>
InstanceField       ::= Lift<NativeWhereStructInstField>
WhereField          ::= Lift<NativeWhereLocalDecl>
~~~

The EBNF semicolons above are grammar notation, not ProofScript tokens.

## 5. Structural brace rules

- Structure/class fields use commas **between** fields. Trailing field commas are rejected.
- Inductive constructors and match alternatives use leading `|` markers; no comma/semicolon is added.
- Instance and local-`where` braced sequences use explicit native semicolon separators; a trailing semicolon is allowed only because those inherited native sequence categories allow it.
- Braced conditional branches contain exactly one term.
- Native `do { ... }` and `by { ... }` retain native `do`/tactic sequencing. Their semicolons are not declaration terminators.
- Indentation inside the **outer r3-owned brace sequence** is formatting. Nested inherited child categories may still use their own native layout.

## 6. Comma policy

Trailing commas are category-specific:

| Category | trailing comma |
|---|---|
| nonempty r3 call | allowed |
| nonempty explicit parameter group | allowed |
| structure fields | rejected |
| class fields | rejected |
| native tuple/pattern/record categories | inherited native rule |

There is no universal "all comma lists allow trailing comma" rule.

## 7. Contract grammar scope

The normative r3 contract surface currently freezes only:
- zero or more `requires P`;
- zero or more `ensures result => Q`;
- total pure functions.

State/loop/async contract syntax is reserved for a later profile revision even though their semantic research direction is documented.

## 8. Ownership and committed errors

Once an owned discriminator commits, failure is a committed ProofScript error rather than silent fallback.

Examples:
- `function f()` commits to Unit-function sugar;
- callable head + `CallGap` + `(` commits to r3 call parsing;
- `structure ... where {` commits to r3 structural field grammar;
- `function ... requires` commits to the r3 pure contract clause grammar.

## 9. Feature IDs

The machine-readable registry is `FEATURE-REGISTRY-r3.json`. The important r3 additions/revisions are:
- `E-CALL-PARENS-R3`;
- `E-EMPTY-CALL-R3`;
- `D-FUNCTION-UNIT-R3`;
- `E-STRUCT-BODY-R3`;
- `E-CLASS-BODY-R3`;
- `E-INDUCTIVE-BODY-R3`;
- `E-MATCH-BODY-R3`;
- `E-INSTANCE-BODY-R3`;
- `E-WHERE-BODY-R3`;
- `S-PURE-CONTRACT-R3`;
- profile records `P-STANDARD-R3` and `P-LEAN-EXTENSIBLE-R3`.
