# API, syntax and tactic index

This is an index of inherited reference entries, not an implementation checklist. Full signatures are in `research/API_INVENTORY.json` and the linked article. Repeated entries are retained. Signatures in this table are abbreviated to keep navigation readable.

| Kind | Name or topic | Signature preview | Detail |
|---|---|---|---|
| inductive predicate | Even | Even : Nat → Prop | [Reference](pages/Introduction/index.md#Even___zero-next) |
| option | pp___match | pp.match | [Reference](pages/Elaboration-and-Compilation/index.md#pp___match) |
| syntax | Initialization Blocks |  | [Reference](pages/Elaboration-and-Compilation/index.md#command) |
| syntax | Compiler-Internal Initializers |  | [Reference](pages/Elaboration-and-Compilation/index.md#command-next) |
| syntax | Evaluating Terms |  | [Reference](pages/Interacting-with-Lean/index.md#command-next-next) |
| option | eval___pp | eval.pp | [Reference](pages/Interacting-with-Lean/index.md#eval___pp) |
| option | eval___type | eval.type | [Reference](pages/Interacting-with-Lean/index.md#eval___type) |
| option | eval___derive___repr | eval.derive.repr | [Reference](pages/Interacting-with-Lean/index.md#eval___derive___repr) |
| type class | MonadEval | MonadEval.{u, v, w} (m : semiOutParam (Type u → Type v)) (n : Type u → Type w) : Type (max (max (u + 1) v) w) | [Reference](pages/Interacting-with-Lean/index.md#MonadEval___mk) |
| type class | MonadEvalT | MonadEvalT.{u, v, w} (m : Type u → Type v) (n : Type u → Type w) : Type (max (max (u + 1) v) w) | [Reference](pages/Interacting-with-Lean/index.md#MonadEvalT___mk) |
| syntax | Reducing Terms |  | [Reference](pages/Interacting-with-Lean/index.md#command-next-next-next) |
| syntax | Checking Types |  | [Reference](pages/Interacting-with-Lean/index.md#command-next-next-next-next) |
| syntax | Testing Type Errors |  | [Reference](pages/Interacting-with-Lean/index.md#command-next-next-next-next-next) |
| syntax | Synthesizing Instances |  | [Reference](pages/Interacting-with-Lean/index.md#command-next-next-next-next-next-next) |
| syntax | Printing Definitions |  | [Reference](pages/Interacting-with-Lean/index.md#command-next-next-next-next-next-next-next) |
| syntax | Printing Strings |  | [Reference](pages/Interacting-with-Lean/index.md#command-next-next-next-next-next-next-next-next) |
| syntax | Printing Axioms |  | [Reference](pages/Interacting-with-Lean/index.md#command-next-next-next-next-next-next-next-next-next) |
| syntax | Printing Equations |  | [Reference](pages/Interacting-with-Lean/index.md#command-next-next-next-next-next-next-next-next-next-next) |
| syntax | Scope Information |  | [Reference](pages/Interacting-with-Lean/index.md#command-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Checking the Lean Version |  | [Reference](pages/Interacting-with-Lean/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Documenting Expected Output |  | [Reference](pages/Interacting-with-Lean/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Specifying #guard_msgs Behavior |  | [Reference](pages/Interacting-with-Lean/index.md#Lean___guardMsgsSpecElt) |
| syntax | Output Filters for #guard_msgs |  | [Reference](pages/Interacting-with-Lean/index.md#Lean___guardMsgsFilter) |
| syntax | Whitespace Comparison for #guard_msgs |  | [Reference](pages/Interacting-with-Lean/index.md#Lean___guardMsgsWhitespaceArg) |
| option | guard_msgs___diff | guard_msgs.diff | [Reference](pages/Interacting-with-Lean/index.md#guard_msgs___diff) |
| inductive type | Std.Format | Std.Format : Type | [Reference](pages/Interacting-with-Lean/index.md#Std___Format___nil) |
| inductive type | Std.Format.FlattenBehavior | Std.Format.FlattenBehavior : Type | [Reference](pages/Interacting-with-Lean/index.md#Std___Format___FlattenBehavior___allOrNone) |
| def | Std.Format.fill | Std.Format.fill (f : Std.Format) : Std.Format | [Reference](pages/Interacting-with-Lean/index.md#Std___Format___fill) |
| def | Std.Format.isEmpty | Std.Format.isEmpty : Std.Format → Bool | [Reference](pages/Interacting-with-Lean/index.md#Std___Format___isEmpty) |
| def | Std.Format.isNil | Std.Format.isNil : Std.Format → Bool | [Reference](pages/Interacting-with-Lean/index.md#Std___Format___isNil) |
| def | Std.Format.join | Std.Format.join (xs : List Std.Format) : Std.Format | [Reference](pages/Interacting-with-Lean/index.md#Std___Format___join) |
| def | Std.Format.joinSep | Std.Format.joinSep.{u} {α : Type u} [Std.ToFormat α] : List α → Std.Format → Std.Format | [Reference](pages/Interacting-with-Lean/index.md#Std___Format___joinSep) |
| def | Std.Format.prefixJoin | Std.Format.prefixJoin.{u} {α : Type u} [Std.ToFormat α] (pre : Std.Format) : List α → Std.Format | [Reference](pages/Interacting-with-Lean/index.md#Std___Format___prefixJoin) |
| def | Std.Format.joinSuffix | Std.Format.joinSuffix.{u} {α : Type u} [Std.ToFormat α] : List α → Std.Format → Std.Format | [Reference](pages/Interacting-with-Lean/index.md#Std___Format___joinSuffix) |
| def | Std.Format.nestD | Std.Format.nestD (f : Std.Format) : Std.Format | [Reference](pages/Interacting-with-Lean/index.md#Std___Format___nestD) |
| def | Std.Format.defIndent | Std.Format.defIndent : Nat | [Reference](pages/Interacting-with-Lean/index.md#Std___Format___defIndent) |
| def | Std.Format.indentD | Std.Format.indentD (f : Std.Format) : Std.Format | [Reference](pages/Interacting-with-Lean/index.md#Std___Format___indentD) |
| def | Std.Format.bracket | Std.Format.bracket (l : String) (f : Std.Format) (r : String) : Std.Format | [Reference](pages/Interacting-with-Lean/index.md#Std___Format___bracket) |
| def | Std.Format.sbracket | Std.Format.sbracket (f : Std.Format) : Std.Format | [Reference](pages/Interacting-with-Lean/index.md#Std___Format___sbracket) |
| def | Std.Format.paren | Std.Format.paren (f : Std.Format) : Std.Format | [Reference](pages/Interacting-with-Lean/index.md#Std___Format___paren) |
| def | Std.Format.bracketFill | Std.Format.bracketFill (l : String) (f : Std.Format) (r : String) : Std.Format | [Reference](pages/Interacting-with-Lean/index.md#Std___Format___bracketFill) |
| def | Std.Format.pretty | Std.Format.pretty (f : Std.Format) (width : Nat := Std.Format.defWidth) (indent column : Nat := 0) : String | [Reference](pages/Interacting-with-Lean/index.md#Std___Format___pretty) |
| def | Std.Format.defWidth | Std.Format.defWidth : Nat | [Reference](pages/Interacting-with-Lean/index.md#Std___Format___defWidth) |
| def | Std.Format.prettyM | Std.Format.prettyM {m : Type → Type} (f : Std.Format) (w : Nat) (indent : Nat := 0) [Monad m] [Std.Format.MonadPrettyFormat m] : m Unit | [Reference](pages/Interacting-with-Lean/index.md#Std___Format___prettyM) |
| type class | Std.Format.MonadPrettyFormat | Std.Format.MonadPrettyFormat (m : Type → Type) : Type | [Reference](pages/Interacting-with-Lean/index.md#Std___Format___MonadPrettyFormat___mk) |
| type class | Std.ToFormat | Std.ToFormat.{u} (α : Type u) : Type u | [Reference](pages/Interacting-with-Lean/index.md#Std___ToFormat___mk) |
| type class | Repr | Repr.{u} (α : Type u) : Type u | [Reference](pages/Interacting-with-Lean/index.md#Repr___mk) |
| def | repr | repr.{u_1} {α : Type u_1} [Repr α] (a : α) : Std.Format | [Reference](pages/Interacting-with-Lean/index.md#repr-next) |
| def | reprStr | reprStr.{u_1} {α : Type u_1} [Repr α] (a : α) : String | [Reference](pages/Interacting-with-Lean/index.md#reprStr) |
| def | Repr.addAppParen | Repr.addAppParen (f : Std.Format) (prec : Nat) : Std.Format | [Reference](pages/Interacting-with-Lean/index.md#Repr___addAppParen) |
| def | reprArg | reprArg.{u_1} {α : Type u_1} [Repr α] (a : α) : Std.Format | [Reference](pages/Interacting-with-Lean/index.md#reprArg) |
| type class | ReprAtom | ReprAtom.{u} (α : Type u) : Type | [Reference](pages/Interacting-with-Lean/index.md#ReprAtom___mk) |
| theorem | funext | funext.{u, v} {α : Sort u} {β : α → Sort v} {f g : (x : α) → β x} (h : ∀ (x : α), f x = g x) : f = g | [Reference](pages/The-Type-System/Functions/index.md#funext) |
| def | Function.comp | Function.comp.{u, v, w} {α : Sort u} {β : Sort v} {δ : Sort w} (f : β → δ) (g : α → β) : α → δ | [Reference](pages/The-Type-System/Functions/index.md#Function___comp) |
| def | Function.const | Function.const.{u, v} {α : Sort u} (β : Sort v) (a : α) : β → α | [Reference](pages/The-Type-System/Functions/index.md#Function___const) |
| def | Function.curry | Function.curry.{u_1, u_2, u_3} {α : Type u_1} {β : Type u_2} {φ : Sort u_3} : (α × β → φ) → α → β → φ | [Reference](pages/The-Type-System/Functions/index.md#Function___curry) |
| def | Function.uncurry | Function.uncurry.{u_1, u_2, u_3} {α : Type u_1} {β : Type u_2} {φ : Sort u_3} : (α → β → φ) → α × β → φ | [Reference](pages/The-Type-System/Functions/index.md#Function___uncurry) |
| def | Function.Injective | Function.Injective.{u_1, u_2} {α : Sort u_1} {β : Sort u_2} (f : α → β) : Prop | [Reference](pages/The-Type-System/Functions/index.md#Function___Injective) |
| def | Function.Surjective | Function.Surjective.{u_1, u_2} {α : Sort u_1} {β : Sort u_2} (f : α → β) : Prop | [Reference](pages/The-Type-System/Functions/index.md#Function___Surjective) |
| def | Function.LeftInverse | Function.LeftInverse.{u_1, u_2} {α : Sort u_1} {β : Sort u_2} (g : β → α) (f : α → β) : Prop | [Reference](pages/The-Type-System/Functions/index.md#Function___LeftInverse) |
| def | Function.HasLeftInverse | Function.HasLeftInverse.{u_1, u_2} {α : Sort u_1} {β : Sort u_2} (f : α → β) : Prop | [Reference](pages/The-Type-System/Functions/index.md#Function___HasLeftInverse) |
| def | Function.RightInverse | Function.RightInverse.{u_1, u_2} {α : Sort u_1} {β : Sort u_2} (g : β → α) (f : α → β) : Prop | [Reference](pages/The-Type-System/Functions/index.md#Function___RightInverse) |
| def | Function.HasRightInverse | Function.HasRightInverse.{u_1, u_2} {α : Sort u_1} {β : Sort u_2} (f : α → β) : Prop | [Reference](pages/The-Type-System/Functions/index.md#Function___HasRightInverse) |
| axiom | propext | propext {a b : Prop} : (a ↔ b) → a = b | [Reference](pages/The-Type-System/Propositions/index.md#propext) |
| syntax | Universe Parameter Declarations |  | [Reference](pages/The-Type-System/Universes/index.md#Lean___Parser___Command___universe) |
| structure | PLift | PLift.{u} (α : Sort u) : Type u | [Reference](pages/The-Type-System/Universes/index.md#PLift___up) |
| structure | ULift | ULift.{r, s} (α : Type s) : Type (max s r) | [Reference](pages/The-Type-System/Universes/index.md#ULift___up) |
| syntax | Inductive Type Declarations |  | [Reference](pages/The-Type-System/Inductive-Types/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| option | inductive___autoPromoteIndices | inductive.autoPromoteIndices | [Reference](pages/The-Type-System/Inductive-Types/index.md#inductive___autoPromoteIndices) |
| syntax | Anonymous Constructors |  | [Reference](pages/The-Type-System/Inductive-Types/index.md#term) |
| syntax | Structure Declarations |  | [Reference](pages/The-Type-System/Inductive-Types/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Structure Instances |  | [Reference](pages/The-Type-System/Inductive-Types/index.md#term-next) |
| syntax | Structure Updates |  | [Reference](pages/The-Type-System/Inductive-Types/index.md#term-next-next) |
| option | bootstrap___inductiveCheckResultingUniverse | bootstrap.inductiveCheckResultingUniverse | [Reference](pages/The-Type-System/Inductive-Types/index.md#bootstrap___inductiveCheckResultingUniverse) |
| type class | SizeOf | SizeOf.{u} (α : Sort u) : Sort (max 1 u) | [Reference](pages/The-Type-System/Inductive-Types/index.md#SizeOf___mk) |
| def | Quotient | Quotient.{u} {α : Sort u} (s : Setoid α) : Sort u | [Reference](pages/The-Type-System/Quotients/index.md#Quotient) |
| type class | Setoid | Setoid.{u} (α : Sort u) : Sort (max 1 u) | [Reference](pages/The-Type-System/Quotients/index.md#Setoid___mk) |
| theorem | Setoid.refl | Setoid.refl.{u} {α : Sort u} [Setoid α] (a : α) : a ≈ a | [Reference](pages/The-Type-System/Quotients/index.md#Setoid___refl) |
| theorem | Setoid.symm | Setoid.symm.{u} {α : Sort u} [Setoid α] {a b : α} (hab : a ≈ b) : b ≈ a | [Reference](pages/The-Type-System/Quotients/index.md#Setoid___symm) |
| theorem | Setoid.trans | Setoid.trans.{u} {α : Sort u} [Setoid α] {a b c : α} (hab : a ≈ b) (hbc : b ≈ c) : a ≈ c | [Reference](pages/The-Type-System/Quotients/index.md#Setoid___trans) |
| syntax | Equivalence Relations |  | [Reference](pages/The-Type-System/Quotients/index.md#term-next-next-next) |
| type class | HasEquiv | HasEquiv.{u, v} (α : Sort u) : Sort (max u (v + 1)) | [Reference](pages/The-Type-System/Quotients/index.md#HasEquiv___mk) |
| structure | Equivalence | Equivalence.{u} {α : Sort u} (r : α → α → Prop) : Prop | [Reference](pages/The-Type-System/Quotients/index.md#Equivalence___mk) |
| def | Quotient.mk | Quotient.mk.{u} {α : Sort u} (s : Setoid α) (a : α) : Quotient s | [Reference](pages/The-Type-System/Quotients/index.md#Quotient___mk) |
| def | Quotient.mk' | Quotient.mk'.{u} {α : Sort u} [s : Setoid α] (a : α) : Quotient s | [Reference](pages/The-Type-System/Quotients/index.md#Quotient___mk___) |
| def | Quotient.lift | Quotient.lift.{u, v} {α : Sort u} {β : Sort v} {s : Setoid α} (f : α → β) : (∀ (a b : α), a ≈ b → f a = f b) → Quotient s → β | [Reference](pages/The-Type-System/Quotients/index.md#Quotient___lift) |
| def | Quotient.liftOn | Quotient.liftOn.{u, v} {α : Sort u} {β : Sort v} {s : Setoid α} (q : Quotient s) (f : α → β) (c : ∀ (a b : α), a ≈ b → f a = f b) : β | [Reference](pages/The-Type-System/Quotients/index.md#Quotient___liftOn) |
| def | Quotient.lift₂ | Quotient.lift₂.{uA, uB, uC} {α : Sort uA} {β : Sort uB} {φ : Sort uC} {s₁ : Setoid α} {s₂ : Setoid β} (f : α → β → φ) (c : ∀ (a₁ : α) (b₁ : β) (a₂ : α) (b₂ : β) … | [Reference](pages/The-Type-System/Quotients/index.md#Quotient___lift___) |
| def | Quotient.liftOn₂ | Quotient.liftOn₂.{uA, uB, uC} {α : Sort uA} {β : Sort uB} {φ : Sort uC} {s₁ : Setoid α} {s₂ : Setoid β} (q₁ : Quotient s₁) (q₂ : Quotient s₂) (f : α → β → φ) (c … | [Reference](pages/The-Type-System/Quotients/index.md#Quotient___liftOn___) |
| def | Quotient.recOnSubsingleton | Quotient.recOnSubsingleton.{u, v} {α : Sort u} {s : Setoid α} {motive : Quotient s → Sort v} [h : ∀ (a : α), Subsingleton (motive (Quotient.mk s a))] (q : Quoti … | [Reference](pages/The-Type-System/Quotients/index.md#Quotient___recOnSubsingleton) |
| def | Quotient.recOnSubsingleton₂ | Quotient.recOnSubsingleton₂.{uA, uB, uC} {α : Sort uA} {β : Sort uB} {s₁ : Setoid α} {s₂ : Setoid β} {motive : Quotient s₁ → Quotient s₂ → Sort uC} [s : ∀ (a :  … | [Reference](pages/The-Type-System/Quotients/index.md#Quotient___recOnSubsingleton___) |
| theorem | Quotient.sound | Quotient.sound.{u} {α : Sort u} {s : Setoid α} {a b : α} : a ≈ b → Quotient.mk s a = Quotient.mk s b | [Reference](pages/The-Type-System/Quotients/index.md#Quotient___sound) |
| theorem | Quotient.ind | Quotient.ind.{u} {α : Sort u} {s : Setoid α} {motive : Quotient s → Prop} : (∀ (a : α), motive (Quotient.mk s a)) → ∀ (q : Quotient s), motive q | [Reference](pages/The-Type-System/Quotients/index.md#Quotient___ind) |
| def | Quotient.rec | Quotient.rec.{u, v} {α : Sort u} {s : Setoid α} {motive : Quotient s → Sort v} (f : (a : α) → motive (Quotient.mk s a)) (h : ∀ (a b : α) (p : a ≈ b), ⋯ ▸ f a =  … | [Reference](pages/The-Type-System/Quotients/index.md#Quotient___rec) |
| def | Quotient.recOn | Quotient.recOn.{u, v} {α : Sort u} {s : Setoid α} {motive : Quotient s → Sort v} (q : Quotient s) (f : (a : α) → motive (Quotient.mk s a)) (h : ∀ (a b : α) (p : … | [Reference](pages/The-Type-System/Quotients/index.md#Quotient___recOn) |
| def | Quotient.hrecOn | Quotient.hrecOn.{u, v} {α : Sort u} {s : Setoid α} {motive : Quotient s → Sort v} (q : Quotient s) (f : (a : α) → motive (Quotient.mk s a)) (c : ∀ (a b : α), a  … | [Reference](pages/The-Type-System/Quotients/index.md#Quotient___hrecOn) |
| theorem | Quotient.exact | Quotient.exact.{u} {α : Sort u} {s : Setoid α} {a b : α} : Quotient.mk s a = Quotient.mk s b → a ≈ b | [Reference](pages/The-Type-System/Quotients/index.md#Quotient___exact) |
| primitive | Quot | Quot.{u} {α : Sort u} (r : α → α → Prop) : Sort u | [Reference](pages/The-Type-System/Quotients/index.md#Quot) |
| primitive | Quot.mk | Quot.mk.{u} {α : Sort u} (r : α → α → Prop) (a : α) : Quot r | [Reference](pages/The-Type-System/Quotients/index.md#Quot___mk) |
| primitive | Quot.lift | Quot.lift.{u, v} {α : Sort u} {r : α → α → Prop} {β : Sort v} (f : α → β) (a : ∀ (a b : α), r a b → f a = f b) : Quot r → β | [Reference](pages/The-Type-System/Quotients/index.md#Quot___lift) |
| primitive | Quot.ind | Quot.ind.{u} {α : Sort u} {r : α → α → Prop} {β : Quot r → Prop} (mk : ∀ (a : α), β (Quot.mk r a)) (q : Quot r) : β q | [Reference](pages/The-Type-System/Quotients/index.md#Quot___ind) |
| axiom | Quot.sound | Quot.sound.{u} {α : Sort u} {r : α → α → Prop} {a b : α} : r a b → Quot.mk r a = Quot.mk r b | [Reference](pages/The-Type-System/Quotients/index.md#Quot___sound) |
| def | Quot.liftOn | Quot.liftOn.{u, v} {α : Sort u} {β : Sort v} {r : α → α → Prop} (q : Quot r) (f : α → β) (c : ∀ (a b : α), r a b → f a = f b) : β | [Reference](pages/The-Type-System/Quotients/index.md#Quot___liftOn) |
| def | Quot.recOnSubsingleton | Quot.recOnSubsingleton.{u, v} {α : Sort u} {r : α → α → Prop} {motive : Quot r → Sort v} [h : ∀ (a : α), Subsingleton (motive (Quot.mk r a))] (q : Quot r) (f :  … | [Reference](pages/The-Type-System/Quotients/index.md#Quot___recOnSubsingleton) |
| def | Quot.rec | Quot.rec.{u, v} {α : Sort u} {r : α → α → Prop} {motive : Quot r → Sort v} (f : (a : α) → motive (Quot.mk r a)) (h : ∀ (a b : α) (p : r a b), ⋯ ▸ f a = f b) (q  … | [Reference](pages/The-Type-System/Quotients/index.md#Quot___rec) |
| def | Quot.recOn | Quot.recOn.{u, v} {α : Sort u} {r : α → α → Prop} {motive : Quot r → Sort v} (q : Quot r) (f : (a : α) → motive (Quot.mk r a)) (h : ∀ (a b : α) (p : r a b), ⋯ ▸ … | [Reference](pages/The-Type-System/Quotients/index.md#Quot___recOn) |
| def | Quot.hrecOn | Quot.hrecOn.{u, v} {α : Sort u} {r : α → α → Prop} {motive : Quot r → Sort v} (q : Quot r) (f : (a : α) → motive (Quot.mk r a)) (c : ∀ (a b : α), r a b → f a ≍  … | [Reference](pages/The-Type-System/Quotients/index.md#Quot___hrecOn) |
| def | Squash | Squash.{u} (α : Sort u) : Sort u | [Reference](pages/The-Type-System/Quotients/index.md#Squash) |
| def | Squash.mk | Squash.mk.{u} {α : Sort u} (x : α) : Squash α | [Reference](pages/The-Type-System/Quotients/index.md#Squash___mk) |
| def | Squash.lift | Squash.lift.{u_1, u_2} {α : Sort u_1} {β : Sort u_2} [Subsingleton β] (s : Squash α) (f : α → β) : β | [Reference](pages/The-Type-System/Quotients/index.md#Squash___lift) |
| theorem | Squash.ind | Squash.ind.{u} {α : Sort u} {motive : Squash α → Prop} (h : ∀ (a : α), motive (Squash.mk a)) (q : Squash α) : motive q | [Reference](pages/The-Type-System/Quotients/index.md#Squash___ind) |
| syntax | Modules |  | [Reference](pages/Source-Files-and-Modules/index.md#Lean___Parser___Module___module) |
| syntax | Module Headers |  | [Reference](pages/Source-Files-and-Modules/index.md#Lean___Parser___Module___header) |
| syntax | Prelude Modules |  | [Reference](pages/Source-Files-and-Modules/index.md#Lean___Parser___Module___prelude) |
| syntax | Imports |  | [Reference](pages/Source-Files-and-Modules/index.md#Lean___Parser___Module___import) |
| option | backward___privateInPublic | backward.privateInPublic | [Reference](pages/Source-Files-and-Modules/index.md#backward___privateInPublic) |
| option | backward___privateInPublic___warn | backward.privateInPublic.warn | [Reference](pages/Source-Files-and-Modules/index.md#backward___privateInPublic___warn) |
| option | backward___proofsInPublic | backward.proofsInPublic | [Reference](pages/Source-Files-and-Modules/index.md#backward___proofsInPublic) |
| syntax | Opening Namespaces |  | [Reference](pages/Namespaces-and-Sections/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| open declaration | Opening Entire Namespaces |  | [Reference](pages/Namespaces-and-Sections/index.md#Lean___Parser___Command___openDecl) |
| open declaration | Hiding Names |  | [Reference](pages/Namespaces-and-Sections/index.md#Lean___Parser___Command___openDecl-next) |
| open declaration | Renaming |  | [Reference](pages/Namespaces-and-Sections/index.md#Lean___Parser___Command___openDecl-next-next) |
| open declaration | Restricted Opening |  | [Reference](pages/Namespaces-and-Sections/index.md#Lean___Parser___Command___openDecl-next-next-next) |
| open declaration | Scoped Declarations Only |  | [Reference](pages/Namespaces-and-Sections/index.md#Lean___Parser___Command___openDecl-next-next-next-next) |
| syntax | Exporting Names |  | [Reference](pages/Namespaces-and-Sections/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Sections |  | [Reference](pages/Namespaces-and-Sections/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Section Headers |  | [Reference](pages/Namespaces-and-Sections/index.md#Lean___Parser___Command___sectionHeader) |
| syntax | Namespace Declarations |  | [Reference](pages/Namespaces-and-Sections/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Section and Namespace Terminators |  | [Reference](pages/Namespaces-and-Sections/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Local Section Scopes |  | [Reference](pages/Namespaces-and-Sections/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Variable Declarations |  | [Reference](pages/Namespaces-and-Sections/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Declaration Modifiers |  | [Reference](pages/Definitions/Modifiers/index.md#declModifiers) |
| syntax | Documentation Comments |  | [Reference](pages/Definitions/Modifiers/index.md#docComment) |
| syntax | Declaration Names |  | [Reference](pages/Definitions/Headers-and-Signatures/index.md#declId) |
| syntax | Declaration Signatures |  | [Reference](pages/Definitions/Headers-and-Signatures/index.md#declSig) |
| syntax | Optional Signatures |  | [Reference](pages/Definitions/Headers-and-Signatures/index.md#optDeclSig) |
| syntax | Explicit Parameters |  | [Reference](pages/Definitions/Headers-and-Signatures/index.md#bracketedBinder) |
| syntax | Optional and Automatic Parameters |  | [Reference](pages/Definitions/Headers-and-Signatures/index.md#bracketedBinder-next) |
| syntax | Implicit Parameters |  | [Reference](pages/Definitions/Headers-and-Signatures/index.md#bracketedBinder-next-next) |
| syntax | Strict Implicit Parameters |  | [Reference](pages/Definitions/Headers-and-Signatures/index.md#bracketedBinder-next-next-next) |
| syntax | Instance Implicit Parameters |  | [Reference](pages/Definitions/Headers-and-Signatures/index.md#bracketedBinder-next-next-next-next) |
| option | relaxedAutoImplicit | relaxedAutoImplicit | [Reference](pages/Definitions/Headers-and-Signatures/index.md#relaxedAutoImplicit) |
| option | autoImplicit | autoImplicit | [Reference](pages/Definitions/Headers-and-Signatures/index.md#autoImplicit) |
| syntax | Definitions |  | [Reference](pages/Definitions/Definitions/index.md#Lean___Parser___Command___declaration-next-next) |
| syntax | Abbreviations |  | [Reference](pages/Definitions/Definitions/index.md#Lean___Parser___Command___declaration-next-next-next-next-next-next) |
| syntax | Opaque Constants |  | [Reference](pages/Definitions/Definitions/index.md#Lean___Parser___Command___declaration-next-next-next-next-next-next-next-next-next-next) |
| syntax | Theorems |  | [Reference](pages/Definitions/Theorems/index.md#Lean___Parser___Command___declaration-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Examples |  | [Reference](pages/Definitions/Example-Declarations/index.md#Lean___Parser___Command___declaration-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Mutual Declaration Blocks |  | [Reference](pages/Definitions/Recursive-Definitions/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Explicit Structural Recursion |  | [Reference](pages/Definitions/Recursive-Definitions/index.md#Lean___Parser___Termination___terminationBy) |
| syntax | Explicit Well-Founded Recursion |  | [Reference](pages/Definitions/Recursive-Definitions/index.md#Lean___Parser___Termination___terminationBy-next-next) |
| type class | WellFoundedRelation | WellFoundedRelation.{u} (α : Sort u) : Sort (max 1 u) | [Reference](pages/Definitions/Recursive-Definitions/index.md#WellFoundedRelation___mk) |
| tactic | decreasing_tactic | decreasing_tactic | [Reference](pages/Definitions/Recursive-Definitions/index.md#decreasing_tactic) |
| tactic | decreasing_trivial | decreasing_trivial | [Reference](pages/Definitions/Recursive-Definitions/index.md#decreasing_trivial) |
| attribute | Preprocessing Simp Set for Well-Founded Recursion |  | [Reference](pages/Definitions/Recursive-Definitions/index.md#attr) |
| def | wfParam | wfParam.{u} {α : Sort u} (a : α) : α | [Reference](pages/Definitions/Recursive-Definitions/index.md#wfParam) |
| option | trace___Elab___definition___wf | trace.Elab.definition.wf | [Reference](pages/Definitions/Recursive-Definitions/index.md#trace___Elab___definition___wf) |
| def | WellFounded.fix | WellFounded.fix.{u, v} {α : Sort u} {C : α → Sort v} {r : α → α → Prop} (hwf : WellFounded r) (F : (x : α) → ((y : α) → r y x → C y) → C x) (x : α) : C x | [Reference](pages/Definitions/Recursive-Definitions/index.md#WellFounded___fix) |
| def | invImage | invImage.{u_1, u_2} {α : Sort u_1} {β : Sort u_2} (f : α → β) (h : WellFoundedRelation β) : WellFoundedRelation α | [Reference](pages/Definitions/Recursive-Definitions/index.md#invImage) |
| inductive predicate | WellFounded | WellFounded.{u} {α : Sort u} (r : α → α → Prop) : Prop | [Reference](pages/Definitions/Recursive-Definitions/index.md#WellFounded___intro) |
| inductive predicate | Acc | Acc.{u} {α : Sort u} (r : α → α → Prop) : α → Prop | [Reference](pages/Definitions/Recursive-Definitions/index.md#Acc___intro) |
| type class | Lean.Order.PartialOrder | Lean.Order.PartialOrder.{u} (α : Sort u) : Sort (max 1 u) | [Reference](pages/Definitions/Recursive-Definitions/index.md#Lean___Order___PartialOrder___mk) |
| type class | Lean.Order.CCPO | Lean.Order.CCPO.{u} (α : Sort u) : Sort (max 1 u) | [Reference](pages/Definitions/Recursive-Definitions/index.md#Lean___Order___CCPO___mk) |
| def | Lean.Order.monotone | Lean.Order.monotone.{u, v} {α : Sort u} [PartialOrder α] {β : Sort v} [PartialOrder β] (f : α → β) : Prop | [Reference](pages/Definitions/Recursive-Definitions/index.md#Lean___Order___monotone) |
| def | Lean.Order.fix | Lean.Order.fix.{u} {α : Sort u} [CCPO α] (f : α → α) (hmono : monotone f) : α | [Reference](pages/Definitions/Recursive-Definitions/index.md#Lean___Order___fix) |
| theorem | Lean.Order.fix_eq | Lean.Order.fix_eq.{u} {α : Sort u} [CCPO α] {f : α → α} (hf : monotone f) : fix f hf = f (fix f hf) | [Reference](pages/Definitions/Recursive-Definitions/index.md#Lean___Order___fix_eq) |
| syntax | Coinductive Predicates |  | [Reference](pages/Definitions/Recursive-Definitions/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| type class | Lean.Order.CompleteLattice | Lean.Order.CompleteLattice.{u} (α : Sort u) : Sort (max 1 u) | [Reference](pages/Definitions/Recursive-Definitions/index.md#Lean___Order___CompleteLattice___mk) |
| def | Lean.Order.lfp | Lean.Order.lfp.{u} {α : Sort u} [CompleteLattice α] (f : α → α) : α | [Reference](pages/Definitions/Recursive-Definitions/index.md#Lean___Order___lfp) |
| theorem | Lean.Order.lfp_fix | Lean.Order.lfp_fix.{u} {α : Sort u} [CompleteLattice α] {f : α → α} (hm : monotone f) : lfp f = f (lfp f) | [Reference](pages/Definitions/Recursive-Definitions/index.md#Lean___Order___lfp_fix) |
| theorem | Lean.Order.lfp_le_of_le_monotone | Lean.Order.lfp_le_of_le_monotone.{u} {α : Sort u} [CompleteLattice α] (f : α → α) {hm : monotone f} (x : α) : f x ⊑ x → lfp_monotone f hm ⊑ x | [Reference](pages/Definitions/Recursive-Definitions/index.md#Lean___Order___lfp_le_of_le_monotone) |
| unsafe def | unsafeCast | unsafeCast.{u, v} {α : Sort u} {β : Sort v} (a : α) : β | [Reference](pages/Definitions/Recursive-Definitions/index.md#unsafeCast) |
| unsafe def | ptrEq | ptrEq.{u_1} {α : Type u_1} (a b : α) : Bool | [Reference](pages/Definitions/Recursive-Definitions/index.md#ptrEq) |
| unsafe def | ptrEqList | ptrEqList.{u_1} {α : Type u_1} (as bs : List α) : Bool | [Reference](pages/Definitions/Recursive-Definitions/index.md#ptrEqList) |
| unsafe opaque | ptrAddrUnsafe | ptrAddrUnsafe.{u} {α : Type u} (a : α) : USize | [Reference](pages/Definitions/Recursive-Definitions/index.md#ptrAddrUnsafe) |
| unsafe opaque | isExclusiveUnsafe | isExclusiveUnsafe.{u} {α : Type u} (a : α) : Bool | [Reference](pages/Definitions/Recursive-Definitions/index.md#isExclusiveUnsafe) |
| unsafe def | unsafeIO | unsafeIO {α : Type} (fn : IO α) : Except IO.Error α | [Reference](pages/Definitions/Recursive-Definitions/index.md#unsafeIO) |
| unsafe def | unsafeEIO | unsafeEIO {ε α : Type} (fn : EIO ε α) : Except ε α | [Reference](pages/Definitions/Recursive-Definitions/index.md#unsafeEIO) |
| unsafe def | unsafeBaseIO | unsafeBaseIO {α : Type} (fn : BaseIO α) : α | [Reference](pages/Definitions/Recursive-Definitions/index.md#unsafeBaseIO) |
| attribute | Replacing Run-Time Implementations |  | [Reference](pages/Definitions/Recursive-Definitions/index.md#attr-next) |
| attribute | Reducibility Annotations |  | [Reference](pages/Definitions/Recursive-Definitions/index.md#attr-next-next) |
| syntax | Local Irreducibility |  | [Reference](pages/Definitions/Recursive-Definitions/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Local Reducibility |  | [Reference](pages/Definitions/Recursive-Definitions/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| option | allowUnsafeReducibility | allowUnsafeReducibility | [Reference](pages/Definitions/Recursive-Definitions/index.md#allowUnsafeReducibility) |
| syntax | Axiom Declarations |  | [Reference](pages/Axioms/index.md#Lean___Parser___Command___axiom) |
| syntax | Attribute Instances |  | [Reference](pages/Attributes/index.md#Lean___Parser___Term___attrInstance) |
| syntax | Attributes |  | [Reference](pages/Attributes/index.md#Lean___Parser___Term___attributes) |
| syntax | Attribute Modification |  | [Reference](pages/Attributes/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Erasing Attributes |  | [Reference](pages/Attributes/index.md#Lean___Parser___Command___eraseAttr) |
| syntax | Attribute Scopes |  | [Reference](pages/Attributes/index.md#attrKind) |
| syntax | Type Class Declarations |  | [Reference](pages/Type-Classes/Class-Declarations/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Class Inductive Type Declarations |  | [Reference](pages/Type-Classes/Class-Declarations/index.md#Lean___Parser___Command___declaration-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Instance Declarations |  | [Reference](pages/Type-Classes/Instance-Declarations/index.md#Lean___Parser___Command___instance) |
| syntax | Instance Priorities |  | [Reference](pages/Type-Classes/Instance-Declarations/index.md#prio) |
| attribute | The default_instance Attribute |  | [Reference](pages/Type-Classes/Instance-Declarations/index.md#attr-next-next-next) |
| attribute | The instance Attribute |  | [Reference](pages/Type-Classes/Instance-Declarations/index.md#attr-next-next-next-next) |
| def | inferInstance | inferInstance.{u} {α : Sort u} [i : α] : α | [Reference](pages/Type-Classes/Instance-Synthesis/index.md#inferInstance) |
| def | inferInstanceAs | «inferInstanceAs».{u} (α : Sort u) [i : α] : α | [Reference](pages/Type-Classes/Instance-Synthesis/index.md#inferInstanceAs) |
| def | outParam | outParam.{u} (α : Sort u) : Sort u | [Reference](pages/Type-Classes/Instance-Synthesis/index.md#outParam) |
| def | semiOutParam | semiOutParam.{u} (α : Sort u) : Sort u | [Reference](pages/Type-Classes/Instance-Synthesis/index.md#semiOutParam) |
| option | backward___synthInstance___canonInstances | backward.synthInstance.canonInstances | [Reference](pages/Type-Classes/Instance-Synthesis/index.md#backward___synthInstance___canonInstances) |
| option | synthInstance___maxHeartbeats | synthInstance.maxHeartbeats | [Reference](pages/Type-Classes/Instance-Synthesis/index.md#synthInstance___maxHeartbeats) |
| option | synthInstance___maxSize | synthInstance.maxSize | [Reference](pages/Type-Classes/Instance-Synthesis/index.md#synthInstance___maxSize) |
| option | backward___inferInstanceAs___wrap | backward.inferInstanceAs.wrap | [Reference](pages/Type-Classes/Instance-Synthesis/index.md#backward___inferInstanceAs___wrap) |
| option | backward___inferInstanceAs___wrap___reuseSubInstances | backward.inferInstanceAs.wrap.reuseSubInstances | [Reference](pages/Type-Classes/Instance-Synthesis/index.md#backward___inferInstanceAs___wrap___reuseSubInstances) |
| option | backward___inferInstanceAs___wrap___instances | backward.inferInstanceAs.wrap.instances | [Reference](pages/Type-Classes/Instance-Synthesis/index.md#backward___inferInstanceAs___wrap___instances) |
| option | backward___inferInstanceAs___wrap___data | backward.inferInstanceAs.wrap.data | [Reference](pages/Type-Classes/Instance-Synthesis/index.md#backward___inferInstanceAs___wrap___data) |
| syntax | Instance Deriving (Optional) |  | [Reference](pages/Type-Classes/Deriving-Instances/index.md#Lean___Parser___Command___optDeriving) |
| syntax | Stand-Alone Deriving of Instances |  | [Reference](pages/Type-Classes/Deriving-Instances/index.md#Lean___Parser___Command___deriving) |
| def | Lean.Elab.registerDerivingHandler | Lean.Elab.registerDerivingHandler (className : Name) (handler : DerivingHandler) : IO Unit | [Reference](pages/Type-Classes/Deriving-Instances/index.md#Lean___Elab___registerDerivingHandler) |
| type class | BEq | BEq.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#BEq___mk) |
| type class | Hashable | Hashable.{u} (α : Sort u) : Sort (max 1 u) | [Reference](pages/Type-Classes/Basic-Classes/index.md#Hashable___mk) |
| opaque | mixHash | mixHash (u₁ u₂ : UInt64) : UInt64 | [Reference](pages/Type-Classes/Basic-Classes/index.md#mixHash) |
| type class | LawfulBEq | LawfulBEq.{u} (α : Type u) [BEq α] : Prop | [Reference](pages/Type-Classes/Basic-Classes/index.md#LawfulBEq___mk) |
| type class | ReflBEq | ReflBEq.{u_1} (α : Type u_1) [BEq α] : Prop | [Reference](pages/Type-Classes/Basic-Classes/index.md#ReflBEq___mk) |
| type class | EquivBEq | EquivBEq.{u_1} (α : Type u_1) [BEq α] : Prop | [Reference](pages/Type-Classes/Basic-Classes/index.md#EquivBEq___mk) |
| type class | LawfulHashable | LawfulHashable.{u} (α : Type u) [BEq α] [Hashable α] : Prop | [Reference](pages/Type-Classes/Basic-Classes/index.md#LawfulHashable___mk) |
| theorem | hash_eq | hash_eq.{u_1} {α : Type u_1} [BEq α] [Hashable α] [LawfulHashable α] {a b : α} : (a == b) = true → hash a = hash b | [Reference](pages/Type-Classes/Basic-Classes/index.md#hash_eq) |
| type class | Ord | Ord.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#Ord___mk) |
| def | compareOn | compareOn.{u_1, u_2} {β : Type u_1} {α : Sort u_2} [ord : Ord β] (f : α → β) (x y : α) : Ordering | [Reference](pages/Type-Classes/Basic-Classes/index.md#compareOn) |
| def | Ord.opposite | Ord.opposite.{u_1} {α : Type u_1} (ord : Ord α) : Ord α | [Reference](pages/Type-Classes/Basic-Classes/index.md#Ord___opposite) |
| inductive type | Ordering | Ordering : Type | [Reference](pages/Type-Classes/Basic-Classes/index.md#Ordering___lt) |
| def | Ordering.swap | Ordering.swap : Ordering → Ordering | [Reference](pages/Type-Classes/Basic-Classes/index.md#Ordering___swap) |
| def | Ordering.then | Ordering.then (a b : Ordering) : Ordering | [Reference](pages/Type-Classes/Basic-Classes/index.md#Ordering___then) |
| def | Ordering.isLT | Ordering.isLT : Ordering → Bool | [Reference](pages/Type-Classes/Basic-Classes/index.md#Ordering___isLT) |
| def | Ordering.isLE | Ordering.isLE : Ordering → Bool | [Reference](pages/Type-Classes/Basic-Classes/index.md#Ordering___isLE) |
| def | Ordering.isEq | Ordering.isEq : Ordering → Bool | [Reference](pages/Type-Classes/Basic-Classes/index.md#Ordering___isEq) |
| def | Ordering.isNe | Ordering.isNe : Ordering → Bool | [Reference](pages/Type-Classes/Basic-Classes/index.md#Ordering___isNe) |
| def | Ordering.isGE | Ordering.isGE : Ordering → Bool | [Reference](pages/Type-Classes/Basic-Classes/index.md#Ordering___isGE) |
| def | Ordering.isGT | Ordering.isGT : Ordering → Bool | [Reference](pages/Type-Classes/Basic-Classes/index.md#Ordering___isGT) |
| def | compareOfLessAndEq | compareOfLessAndEq.{u_1} {α : Type u_1} (x y : α) [LT α] [Decidable (x < y)] [DecidableEq α] : Ordering | [Reference](pages/Type-Classes/Basic-Classes/index.md#compareOfLessAndEq) |
| def | compareOfLessAndBEq | compareOfLessAndBEq.{u_1} {α : Type u_1} (x y : α) [LT α] [Decidable (x < y)] [BEq α] : Ordering | [Reference](pages/Type-Classes/Basic-Classes/index.md#compareOfLessAndBEq) |
| def | compareLex | compareLex.{u_1, u_2} {α : Sort u_1} {β : Sort u_2} (cmp₁ cmp₂ : α → β → Ordering) (a : α) (b : β) : Ordering | [Reference](pages/Type-Classes/Basic-Classes/index.md#compareLex) |
| syntax | Ordering Operators |  | [Reference](pages/Type-Classes/Basic-Classes/index.md#term-next-next-next-next) |
| type class | LT | LT.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#LT___mk) |
| type class | LE | LE.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#LE___mk) |
| def | ltOfOrd | ltOfOrd.{u_1} {α : Type u_1} [Ord α] : LT α | [Reference](pages/Type-Classes/Basic-Classes/index.md#ltOfOrd) |
| def | leOfOrd | leOfOrd.{u_1} {α : Type u_1} [Ord α] : LE α | [Reference](pages/Type-Classes/Basic-Classes/index.md#leOfOrd) |
| def | Ord.toBEq | Ord.toBEq.{u_1} {α : Type u_1} (ord : Ord α) : BEq α | [Reference](pages/Type-Classes/Basic-Classes/index.md#Ord___toBEq) |
| def | Ord.toLE | Ord.toLE.{u_1} {α : Type u_1} (ord : Ord α) : LE α | [Reference](pages/Type-Classes/Basic-Classes/index.md#Ord___toLE) |
| def | Ord.toLT | Ord.toLT.{u_1} {α : Type u_1} (ord : Ord α) : LT α | [Reference](pages/Type-Classes/Basic-Classes/index.md#Ord___toLT) |
| def | Ord.lex | Ord.lex.{u_1, u_2} {α : Type u_1} {β : Type u_2} : Ord α → Ord β → Ord (α × β) | [Reference](pages/Type-Classes/Basic-Classes/index.md#Ord___lex) |
| def | Ord.lex' | Ord.lex'.{u_1} {α : Type u_1} (ord₁ ord₂ : Ord α) : Ord α | [Reference](pages/Type-Classes/Basic-Classes/index.md#Ord___lex___) |
| def | Ord.on | Ord.on.{u_1, u_2} {β : Type u_1} {α : Type u_2} : Ord β → (f : α → β) → Ord α | [Reference](pages/Type-Classes/Basic-Classes/index.md#Ord___on) |
| type class | Min | Min.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#Min___mk) |
| type class | Max | Max.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#Max___mk) |
| def | minOfLe | minOfLe.{u_1} {α : Type u_1} [LE α] [DecidableRel LE.le] : Min α | [Reference](pages/Type-Classes/Basic-Classes/index.md#minOfLe) |
| def | maxOfLe | maxOfLe.{u_1} {α : Type u_1} [LE α] [DecidableRel LE.le] : Max α | [Reference](pages/Type-Classes/Basic-Classes/index.md#maxOfLe) |
| inductive type | Decidable | Decidable (p : Prop) : Type | [Reference](pages/Type-Classes/Basic-Classes/index.md#Decidable___isFalse) |
| def | DecidablePred | DecidablePred.{u} {α : Sort u} (r : α → Prop) : Sort (max 1 u) | [Reference](pages/Type-Classes/Basic-Classes/index.md#DecidablePred) |
| def | DecidableRel | DecidableRel.{u, v} {α : Sort u} {β : Sort v} (r : α → β → Prop) : Sort (max (max 1 u) v) | [Reference](pages/Type-Classes/Basic-Classes/index.md#DecidableRel) |
| def | DecidableEq | DecidableEq.{u} (α : Sort u) : Sort (max 1 u) | [Reference](pages/Type-Classes/Basic-Classes/index.md#DecidableEq) |
| def | DecidableLT | DecidableLT.{u} (α : Type u) [LT α] : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#DecidableLT) |
| def | DecidableLE | DecidableLE.{u} (α : Type u) [LE α] : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#DecidableLE) |
| def | Decidable.decide | Decidable.decide (p : Prop) [h : Decidable p] : Bool | [Reference](pages/Type-Classes/Basic-Classes/index.md#Decidable___decide) |
| def | Decidable.byCases | Decidable.byCases.{u} {p : Prop} {q : Sort u} [dec : Decidable p] (h1 : p → q) (h2 : ¬p → q) : q | [Reference](pages/Type-Classes/Basic-Classes/index.md#Decidable___byCases) |
| type class | Inhabited | Inhabited.{u} (α : Sort u) : Sort (max 1 u) | [Reference](pages/Type-Classes/Basic-Classes/index.md#Inhabited___mk) |
| inductive predicate | Nonempty | Nonempty.{u} (α : Sort u) : Prop | [Reference](pages/Type-Classes/Basic-Classes/index.md#Nonempty___intro) |
| type class | Subsingleton | Subsingleton.{u} (α : Sort u) : Prop | [Reference](pages/Type-Classes/Basic-Classes/index.md#Subsingleton___intro) |
| theorem | Subsingleton.elim | Subsingleton.elim.{u} {α : Sort u} [h : Subsingleton α] (a b : α) : a = b | [Reference](pages/Type-Classes/Basic-Classes/index.md#Subsingleton___elim) |
| theorem | Subsingleton.helim | Subsingleton.helim.{u} {α β : Sort u} [h₁ : Subsingleton α] (h₂ : α = β) (a : α) (b : β) : a ≍ b | [Reference](pages/Type-Classes/Basic-Classes/index.md#Subsingleton___helim) |
| type class | Zero | Zero.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#Zero___mk) |
| type class | NeZero | NeZero.{u_1} {R : Type u_1} [Zero R] (n : R) : Prop | [Reference](pages/Type-Classes/Basic-Classes/index.md#NeZero___mk) |
| type class | HAdd | HAdd.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) : Type (max (max u v) w) | [Reference](pages/Type-Classes/Basic-Classes/index.md#HAdd___mk) |
| type class | Add | Add.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#Add___mk) |
| type class | HSub | HSub.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) : Type (max (max u v) w) | [Reference](pages/Type-Classes/Basic-Classes/index.md#HSub___mk) |
| type class | Sub | Sub.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#Sub___mk) |
| type class | HMul | HMul.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) : Type (max (max u v) w) | [Reference](pages/Type-Classes/Basic-Classes/index.md#HMul___mk) |
| type class | SMul | SMul.{u, v} (M : Type u) (α : Type v) : Type (max u v) | [Reference](pages/Type-Classes/Basic-Classes/index.md#SMul___mk) |
| type class | Mul | Mul.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#Mul___mk) |
| type class | HDiv | HDiv.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) : Type (max (max u v) w) | [Reference](pages/Type-Classes/Basic-Classes/index.md#HDiv___mk) |
| type class | Div | Div.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#Div___mk) |
| type class | Dvd | Dvd.{u_1} (α : Type u_1) : Type u_1 | [Reference](pages/Type-Classes/Basic-Classes/index.md#Dvd___mk) |
| type class | HMod | HMod.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) : Type (max (max u v) w) | [Reference](pages/Type-Classes/Basic-Classes/index.md#HMod___mk) |
| type class | Mod | Mod.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#Mod___mk) |
| type class | HPow | HPow.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) : Type (max (max u v) w) | [Reference](pages/Type-Classes/Basic-Classes/index.md#HPow___mk) |
| type class | Pow | Pow.{u, v} (α : Type u) (β : Type v) : Type (max u v) | [Reference](pages/Type-Classes/Basic-Classes/index.md#Pow___mk) |
| type class | NatPow | NatPow.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#NatPow___mk) |
| type class | HomogeneousPow | HomogeneousPow.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#HomogeneousPow___mk) |
| type class | HShiftLeft | HShiftLeft.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) : Type (max (max u v) w) | [Reference](pages/Type-Classes/Basic-Classes/index.md#HShiftLeft___mk) |
| type class | ShiftLeft | ShiftLeft.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#ShiftLeft___mk) |
| type class | HShiftRight | HShiftRight.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) : Type (max (max u v) w) | [Reference](pages/Type-Classes/Basic-Classes/index.md#HShiftRight___mk) |
| type class | ShiftRight | ShiftRight.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#ShiftRight___mk) |
| type class | Neg | Neg.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#Neg___mk) |
| type class | HAnd | HAnd.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) : Type (max (max u v) w) | [Reference](pages/Type-Classes/Basic-Classes/index.md#HAnd___mk) |
| type class | AndOp | AndOp.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#AndOp___mk) |
| type class | HOr | HOr.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) : Type (max (max u v) w) | [Reference](pages/Type-Classes/Basic-Classes/index.md#HOr___mk) |
| type class | OrOp | OrOp.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#OrOp___mk) |
| type class | HXor | HXor.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) : Type (max (max u v) w) | [Reference](pages/Type-Classes/Basic-Classes/index.md#HXor___mk) |
| type class | XorOp | XorOp.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#XorOp___mk) |
| type class | HAppend | HAppend.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) : Type (max (max u v) w) | [Reference](pages/Type-Classes/Basic-Classes/index.md#HAppend___mk) |
| type class | Append | Append.{u} (α : Type u) : Type u | [Reference](pages/Type-Classes/Basic-Classes/index.md#Append___mk) |
| type class | GetElem | GetElem.{u, v, w} (coll : Type u) (idx : Type v) (elem : outParam (Type w)) (valid : outParam (coll → idx → Prop)) : Type (max (max u v) w) | [Reference](pages/Type-Classes/Basic-Classes/index.md#GetElem___mk) |
| type class | GetElem? | GetElem?.{u, v, w} (coll : Type u) (idx : Type v) (elem : outParam (Type w)) (valid : outParam (coll → idx → Prop)) : Type (max (max u v) w) | [Reference](pages/Type-Classes/Basic-Classes/index.md#GetElem______mk) |
| type class | LawfulGetElem | LawfulGetElem.{u, v, w} (cont : Type u) (idx : Type v) (elem : outParam (Type w)) (dom : outParam (cont → idx → Prop)) [ge : GetElem? cont idx elem dom] : Prop … | [Reference](pages/Type-Classes/Basic-Classes/index.md#LawfulGetElem___mk) |
| type class | Coe | Coe.{u, v} (α : semiOutParam (Sort u)) (β : Sort v) : Sort (max (max 1 u) v) | [Reference](pages/Coercions/index.md#Coe___mk) |
| type class | CoeHead | CoeHead.{u, v} (α : Sort u) (β : semiOutParam (Sort v)) : Sort (max (max 1 u) v) | [Reference](pages/Coercions/Coercing-Between-Types/index.md#CoeHead___mk) |
| type class | CoeOut | CoeOut.{u, v} (α : Sort u) (β : semiOutParam (Sort v)) : Sort (max (max 1 u) v) | [Reference](pages/Coercions/Coercing-Between-Types/index.md#CoeOut___mk) |
| type class | CoeTail | CoeTail.{u, v} (α : semiOutParam (Sort u)) (β : Sort v) : Sort (max (max 1 u) v) | [Reference](pages/Coercions/Coercing-Between-Types/index.md#CoeTail___mk) |
| type class | CoeT | CoeT.{u, v} (α : Sort u) : α → (β : Sort v) → Sort (max 1 v) | [Reference](pages/Coercions/Coercing-Between-Types/index.md#CoeT___mk) |
| type class | CoeDep | CoeDep.{u, v} (α : Sort u) : α → (β : Sort v) → Sort (max 1 v) | [Reference](pages/Coercions/Coercing-Between-Types/index.md#CoeDep___mk) |
| syntax | Coercions |  | [Reference](pages/Coercions/Coercing-Between-Types/index.md#term-next-next-next-next-next) |
| attribute | Coercion Declarations |  | [Reference](pages/Coercions/Coercing-Between-Types/index.md#attr-next-next-next-next-next) |
| type class | NatCast | NatCast.{u} (R : Type u) : Type u | [Reference](pages/Coercions/Coercing-Between-Types/index.md#NatCast___mk) |
| def | Nat.cast | Nat.cast.{u} {R : Type u} [NatCast R] : Nat → R | [Reference](pages/Coercions/Coercing-Between-Types/index.md#Nat___cast) |
| type class | IntCast | IntCast.{u} (R : Type u) : Type u | [Reference](pages/Coercions/Coercing-Between-Types/index.md#IntCast___mk) |
| def | Int.cast | Int.cast.{u} {R : Type u} [IntCast R] : Int → R | [Reference](pages/Coercions/Coercing-Between-Types/index.md#Int___cast) |
| type class | CoeSort | CoeSort.{u, v} (α : Sort u) (β : outParam (Sort v)) : Sort (max (max 1 u) v) | [Reference](pages/Coercions/Coercing-to-Sorts/index.md#CoeSort___mk) |
| syntax | Explicit Coercion to Sorts |  | [Reference](pages/Coercions/Coercing-to-Sorts/index.md#term-next-next-next-next-next-next) |
| type class | CoeFun | CoeFun.{u, v} (α : Sort u) (γ : outParam (α → Sort v)) : Sort (max (max 1 u) v) | [Reference](pages/Coercions/Coercing-to-Function-Types/index.md#CoeFun___mk) |
| syntax | Explicit Coercion to Functions |  | [Reference](pages/Coercions/Coercing-to-Function-Types/index.md#term-next-next-next-next-next-next-next) |
| type class | CoeHTCT | CoeHTCT.{u, v} (α : Sort u) (β : Sort v) : Sort (max (max 1 u) v) | [Reference](pages/Coercions/Implementation-Details/index.md#CoeHTCT___mk) |
| type class | CoeHTC | CoeHTC.{u, v} (α : Sort u) (β : Sort v) : Sort (max (max 1 u) v) | [Reference](pages/Coercions/Implementation-Details/index.md#CoeHTC___mk) |
| type class | CoeOTC | CoeOTC.{u, v} (α : Sort u) (β : Sort v) : Sort (max (max 1 u) v) | [Reference](pages/Coercions/Implementation-Details/index.md#CoeOTC___mk) |
| type class | CoeTC | CoeTC.{u, v} (α : Sort u) (β : Sort v) : Sort (max (max 1 u) v) | [Reference](pages/Coercions/Implementation-Details/index.md#CoeTC___mk) |
| def | dbgTraceIfShared | dbgTraceIfShared.{u} {α : Type u} (s : String) (a : α) : α | [Reference](pages/Run-Time-Code/Reference-Counting/index.md#dbgTraceIfShared) |
| option | trace___compiler___ir___result | trace.compiler.ir.result | [Reference](pages/Run-Time-Code/Reference-Counting/index.md#trace___compiler___ir___result) |
| attribute | External Symbols |  | [Reference](pages/Run-Time-Code/Foreign-Function-Interface/index.md#attr-next-next-next-next-next-next) |
| attribute | Exported Symbols |  | [Reference](pages/Run-Time-Code/Foreign-Function-Interface/index.md#attr-next-next-next-next-next-next-next) |
| syntax | Borrowed Parameters |  | [Reference](pages/Run-Time-Code/Foreign-Function-Interface/index.md#term-next-next-next-next-next-next-next-next) |
| syntax | Identifiers |  | [Reference](pages/Terms/Identifiers/index.md#term-next-next-next-next-next-next-next-next-next) |
| syntax | Function types |  | [Reference](pages/Terms/Function-Types/index.md#term-next-next-next-next-next-next-next-next-next-next) |
| syntax | Curried Function Types |  | [Reference](pages/Terms/Function-Types/index.md#term-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Implicit, Optional, and Auto Parameters |  | [Reference](pages/Terms/Function-Types/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Function Abstraction |  | [Reference](pages/Terms/Functions/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Curried Functions |  | [Reference](pages/Terms/Functions/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Functions with Varying Binders |  | [Reference](pages/Terms/Functions/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Function Binders |  | [Reference](pages/Terms/Functions/index.md#Lean___Parser___Term___funBinder) |
| syntax | Function Application |  | [Reference](pages/Terms/Function-Application/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Arguments |  | [Reference](pages/Terms/Function-Application/index.md#Lean___Parser___Term___argument) |
| def | optParam | optParam.{u} (α : Sort u) (default : α) : Sort u | [Reference](pages/Terms/Function-Application/index.md#optParam) |
| def | autoParam | autoParam.{u} (α : Sort u) (tactic : Lean.Syntax) : Sort u | [Reference](pages/Terms/Function-Application/index.md#autoParam) |
| syntax | Field Notation |  | [Reference](pages/Terms/Function-Application/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| option | pp___fieldNotation | pp.fieldNotation | [Reference](pages/Terms/Function-Application/index.md#pp___fieldNotation) |
| attribute | Controlling Field Notation |  | [Reference](pages/Terms/Function-Application/index.md#attr-next-next-next-next-next-next-next-next) |
| syntax | Pipelines |  | [Reference](pages/Terms/Function-Application/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Pipeline Fields |  | [Reference](pages/Terms/Function-Application/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| type class | OfNat | OfNat.{u} (α : Type u) : Nat → Type u | [Reference](pages/Terms/Numeric-Literals/index.md#OfNat___mk) |
| type class | OfScientific | OfScientific.{u} (α : Type u) : Type u | [Reference](pages/Terms/Numeric-Literals/index.md#OfScientific___mk) |
| syntax | List Literals |  | [Reference](pages/Terms/Numeric-Literals/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Array Literals |  | [Reference](pages/Terms/Numeric-Literals/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Conditionals |  | [Reference](pages/Terms/Conditionals/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Pattern-Matching Conditionals |  | [Reference](pages/Terms/Conditionals/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Boolean-Only Conditional |  | [Reference](pages/Terms/Conditionals/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Pattern Matching |  | [Reference](pages/Terms/Pattern-Matching/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Match Discriminants |  | [Reference](pages/Terms/Pattern-Matching/index.md#matchDiscr) |
| syntax | Inaccessible Patterns |  | [Reference](pages/Terms/Pattern-Matching/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Named Patterns |  | [Reference](pages/Terms/Pattern-Matching/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| attribute | Attribute for Match Patterns |  | [Reference](pages/Terms/Pattern-Matching/index.md#attr-next-next-next-next-next-next-next-next-next) |
| syntax | Pattern-Matching Functions |  | [Reference](pages/Terms/Pattern-Matching/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | The matches Operator |  | [Reference](pages/Terms/Pattern-Matching/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Caseless Pattern Matches |  | [Reference](pages/Terms/Pattern-Matching/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Caseless Functions |  | [Reference](pages/Terms/Pattern-Matching/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Holes |  | [Reference](pages/Terms/Holes/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Synthetic Holes |  | [Reference](pages/Terms/Holes/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Postfix Type Ascriptions |  | [Reference](pages/Terms/Type-Ascription/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Prefix Type Ascriptions |  | [Reference](pages/Terms/Type-Ascription/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Tactic Proofs with by |  | [Reference](pages/Tactic-Proofs/Running-Tactics/index.md#Lean___Parser___Term___byTactic) |
| syntax | Assumptions by Type |  | [Reference](pages/Tactic-Proofs/Reading-Proof-States/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| option | pp___proofs | pp.proofs | [Reference](pages/Tactic-Proofs/Reading-Proof-States/index.md#pp___proofs) |
| option | pp___proofs___threshold | pp.proofs.threshold | [Reference](pages/Tactic-Proofs/Reading-Proof-States/index.md#pp___proofs___threshold) |
| option | pp___deepTerms | pp.deepTerms | [Reference](pages/Tactic-Proofs/Reading-Proof-States/index.md#pp___deepTerms) |
| option | pp___deepTerms___threshold | pp.deepTerms.threshold | [Reference](pages/Tactic-Proofs/Reading-Proof-States/index.md#pp___deepTerms___threshold) |
| option | pp___maxSteps | pp.maxSteps | [Reference](pages/Tactic-Proofs/Reading-Proof-States/index.md#pp___maxSteps) |
| option | pp___mvars | pp.mvars | [Reference](pages/Tactic-Proofs/Reading-Proof-States/index.md#pp___mvars) |
| tactic | fail | fail | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#fail) |
| tactic | fail_if_success | fail_if_success | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#fail_if_success) |
| tactic | try | try | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#try) |
| tactic | first | first | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#first) |
| tactic | if | if | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#if) |
| tactic | match | match | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#match) |
| tactic | case | case | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#case) |
| tactic | case___ | case' | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#case___) |
| tactic | rotate_left | rotate_left | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#rotate_left) |
| tactic | rotate_right | rotate_right | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#rotate_right) |
| tactic | _LT__SEMI__GT_ | <;> | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#_LT__SEMI__GT_) |
| tactic | all_goals | all_goals | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#all_goals) |
| tactic | any_goals | any_goals | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#any_goals) |
| tactic | ___ | · | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#___) |
| tactic | next | next | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#next) |
| tactic | focus | focus | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#focus) |
| tactic | iterate | iterate | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#iterate) |
| tactic | repeat | repeat | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#repeat) |
| tactic | repeat___ | repeat' | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#repeat___) |
| tactic | repeat1___ | repeat1' | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#repeat1___) |
| option | tactic___hygienic | tactic.hygienic | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#tactic___hygienic) |
| tactic | rename_i | rename_i | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#rename_i) |
| tactic | rename | rename | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#rename) |
| tactic | revert | revert | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#revert) |
| tactic | clear | clear | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#clear) |
| tactic | have | have | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#have) |
| tactic | have___ | have' | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#have___) |
| tactic | let | let | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#let) |
| tactic | let-rec | let rec | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#let-rec) |
| tactic | letI | letI | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#letI) |
| tactic | let___ | let' | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#let___) |
| syntax | Tactic Configuration |  | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#Lean___Parser___Tactic___optConfig) |
| syntax | Tactic Configuration Items |  | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#Lean___Parser___Tactic___configItem) |
| tactic | set_option | set_option | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#set_option) |
| tactic | open | open | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#open) |
| tactic | with_reducible_and_instances | with_reducible_and_instances | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#with_reducible_and_instances) |
| tactic | with_reducible | with_reducible | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#with_reducible) |
| tactic | with_unfolding_all | with_unfolding_all | [Reference](pages/Tactic-Proofs/The-Tactic-Language/index.md#with_unfolding_all) |
| option | tactic___customEliminators | tactic.customEliminators | [Reference](pages/Tactic-Proofs/Options/index.md#tactic___customEliminators) |
| option | tactic___skipAssignedInstances | tactic.skipAssignedInstances | [Reference](pages/Tactic-Proofs/Options/index.md#tactic___skipAssignedInstances) |
| option | tactic___simp___trace | tactic.simp.trace | [Reference](pages/Tactic-Proofs/Options/index.md#tactic___simp___trace) |
| tactic | classical | classical | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#classical) |
| tactic | assumption | assumption | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#assumption) |
| tactic | apply_assumption | apply_assumption | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#apply_assumption) |
| tactic | exists | exists | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#exists) |
| tactic | intro | intro | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#intro) |
| tactic | intros | intros | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#intros) |
| tactic | rintro | rintro | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#rintro) |
| tactic | rfl | rfl | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#rfl) |
| tactic | rfl___ | rfl' | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#rfl___) |
| tactic | apply_rfl | apply_rfl | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#apply_rfl) |
| attribute | Reflexive Relations |  | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#attr-next-next-next-next-next-next-next-next-next-next) |
| tactic | symm | symm | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#symm) |
| tactic | symm_saturate | symm_saturate | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#symm_saturate) |
| attribute | Symmetric Relations |  | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#attr-next-next-next-next-next-next-next-next-next-next-next) |
| tactic | calc | calc | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#calc) |
| type class | Trans | Trans.{u, v, w, u_1, u_2, u_3} {α : Sort u_1} {β : Sort u_2} {γ : Sort u_3} (r : α → β → Sort u) (s : β → γ → Sort v) (t : outParam (α → γ → Sort w)) : Sort (ma … | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#Trans___mk) |
| tactic | subst | subst | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#subst) |
| tactic | subst_eqs | subst_eqs | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#subst_eqs) |
| tactic | subst_vars | subst_vars | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#subst_vars) |
| tactic | congr | congr | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#congr) |
| tactic | eq_refl | eq_refl | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#eq_refl) |
| tactic | ac_rfl | ac_rfl | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#ac_rfl) |
| tactic | ac_nf | ac_nf | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#ac_nf) |
| tactic | ac_nf0 | ac_nf0 | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#ac_nf0) |
| tactic | exact | exact | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#exact) |
| tactic | apply | apply | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#apply) |
| tactic | refine | refine | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#refine) |
| tactic | refine___ | refine' | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#refine___) |
| tactic | solve_by_elim | solve_by_elim | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#solve_by_elim) |
| tactic | apply_rules | apply_rules | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#apply_rules) |
| tactic | as_aux_lemma | as_aux_lemma | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#as_aux_lemma) |
| tactic | exfalso | exfalso | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#exfalso) |
| tactic | contradiction | contradiction | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#contradiction) |
| tactic | false_or_by_contra | false_or_by_contra | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#false_or_by_contra) |
| tactic | suffices | suffices | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#suffices) |
| tactic | change | change | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#change) |
| tactic | generalize | generalize | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#generalize) |
| tactic | specialize | specialize | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#specialize) |
| tactic | obtain | obtain | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#obtain) |
| tactic | show | show | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#show) |
| tactic | show_term | show_term | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#show_term) |
| tactic | norm_cast | norm_cast | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#norm_cast) |
| tactic | push_cast | push_cast | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#push_cast) |
| tactic | exact_mod_cast | exact_mod_cast | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#exact_mod_cast) |
| tactic | apply_mod_cast | apply_mod_cast | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#apply_mod_cast) |
| tactic | rw_mod_cast | rw_mod_cast | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#rw_mod_cast) |
| tactic | assumption_mod_cast | assumption_mod_cast | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#assumption_mod_cast) |
| tactic | extract_lets | extract_lets | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#extract_lets) |
| tactic | lift_lets | lift_lets | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#lift_lets) |
| tactic | let_to_have | let_to_have | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#let_to_have) |
| tactic | clear_value | clear_value | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#clear_value) |
| tactic | ext | ext | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#ext) |
| tactic | ext1 | ext1 | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#ext1) |
| tactic | apply_ext_theorem | apply_ext_theorem | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#apply_ext_theorem) |
| tactic | funext-next | funext | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#funext-next) |
| tactic | grind | grind | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#grind) |
| tactic | grind___ | grind? | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#grind___) |
| tactic | lia | lia | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#lia) |
| tactic | grobner | grobner | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#grobner) |
| tactic | simp | simp | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#simp) |
| tactic | simp___ | simp! | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#simp___) |
| tactic | simp___-next | simp? | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#simp___-next) |
| tactic | simp______ | simp?! | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#simp______) |
| tactic | simp_arith | simp_arith | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#simp_arith) |
| tactic | simp_arith___ | simp_arith! | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#simp_arith___) |
| tactic | dsimp | dsimp | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#dsimp) |
| tactic | dsimp___ | dsimp! | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#dsimp___) |
| tactic | dsimp___-next | dsimp? | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#dsimp___-next) |
| tactic | dsimp______ | dsimp?! | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#dsimp______) |
| tactic | simp_all | simp_all | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#simp_all) |
| tactic | simp_all___ | simp_all! | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#simp_all___) |
| tactic | simp_all___-next | simp_all? | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#simp_all___-next) |
| tactic | simp_all______ | simp_all?! | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#simp_all______) |
| tactic | simp_all_arith | simp_all_arith | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#simp_all_arith) |
| tactic | simp_all_arith___ | simp_all_arith! | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#simp_all_arith___) |
| tactic | simpa | simpa | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#simpa) |
| tactic | simpa___ | simpa! | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#simpa___) |
| tactic | simpa___-next | simpa? | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#simpa___-next) |
| tactic | simpa______ | simpa?! | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#simpa______) |
| tactic | simp_wf | simp_wf | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#simp_wf) |
| tactic | rw | rw | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#rw) |
| tactic | rewrite | rewrite | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#rewrite) |
| tactic | erw | erw | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#erw) |
| tactic | rwa | rwa | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#rwa) |
| structure | Lean.Meta.Rewrite.Config | Lean.Meta.Rewrite.Config : Type | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#Lean___Meta___Rewrite___Config___mk) |
| inductive type | Lean.Meta.Occurrences | Lean.Meta.Occurrences : Type | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#Lean___Meta___Occurrences___all) |
| inductive type | Lean.Meta.TransparencyMode | Lean.Meta.TransparencyMode : Type | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#Lean___Meta___TransparencyMode___all) |
| def | Lean.Meta.Rewrite.NewGoals | Lean.Meta.Rewrite.NewGoals : Type | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#Lean___Meta___Rewrite___NewGoals) |
| tactic | unfold | unfold | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#unfold) |
| tactic | replace | replace | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#replace) |
| tactic | delta | delta | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#delta) |
| tactic | constructor | constructor | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#constructor) |
| tactic | injection | injection | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#injection) |
| tactic | injections | injections | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#injections) |
| tactic | left | left | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#left) |
| tactic | right | right | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#right) |
| attribute | Custom Eliminators |  | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#attr-next-next-next-next-next-next-next-next-next-next-next-next) |
| tactic | cases | cases | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#cases) |
| tactic | rcases | rcases | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#rcases) |
| tactic | fun_cases | fun_cases | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#fun_cases) |
| tactic | induction | induction | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#induction) |
| tactic | fun_induction | fun_induction | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#fun_induction) |
| tactic | nofun | nofun | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#nofun) |
| tactic | nomatch | nomatch | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#nomatch) |
| tactic | exact___ | exact? | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#exact___) |
| tactic | apply___ | apply? | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#apply___) |
| tactic | rw___ | rw? | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#rw___) |
| tactic | split | split | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#split) |
| tactic | by_cases | by_cases | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#by_cases) |
| tactic | decide | decide | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#decide) |
| tactic | native_decide | native_decide | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#native_decide) |
| tactic | omega | omega | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#omega) |
| tactic | bv_omega | bv_omega | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#bv_omega) |
| tactic | bv_decide | bv_decide | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#bv_decide) |
| tactic | bv_normalize | bv_normalize | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#bv_normalize) |
| tactic | bv_check | bv_check | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#bv_check) |
| tactic | bv_decide___ | bv_decide? | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#bv_decide___) |
| syntax | Call-by-Value Evaluation |  | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#tactic) |
| tactic | cbv | cbv | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#cbv) |
| tactic | decide_cbv | decide_cbv | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#decide_cbv) |
| attribute | Custom cbv Rewrite Rules |  | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#attr-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| attribute | Opaque Declarations for cbv |  | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Custom cbv Simplification Procedures |  | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| attribute | Simplification Procedure Attribute for cbv |  | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| option | cbv___maxSteps | cbv.maxSteps | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#cbv___maxSteps) |
| option | cbv___warning | cbv.warning | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#cbv___warning) |
| tactic | with_reducible-next | with_reducible | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#with_reducible-next) |
| tactic | with_reducible_and_instances-next | with_reducible_and_instances | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#with_reducible_and_instances-next) |
| tactic | with_unfolding_all-next | with_unfolding_all | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#with_unfolding_all-next) |
| tactic | with_unfolding_none | with_unfolding_none | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#with_unfolding_none) |
| tactic | skip | skip | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#skip) |
| tactic | guard_hyp | guard_hyp | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#guard_hyp) |
| tactic | guard_target | guard_target | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#guard_target) |
| tactic | guard_expr | guard_expr | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#guard_expr) |
| tactic | done | done | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#done) |
| tactic | sleep | sleep | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#sleep) |
| tactic | stop | stop | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#stop) |
| tactic | decreasing_with | decreasing_with | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#decreasing_with) |
| tactic | get_elem_tactic | get_elem_tactic | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#get_elem_tactic) |
| tactic | get_elem_tactic_trivial | get_elem_tactic_trivial | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#get_elem_tactic_trivial) |
| tactic | sorry | sorry | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#sorry) |
| tactic | admit | admit | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#admit) |
| tactic | dbg_trace | dbg_trace | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#dbg_trace) |
| tactic | trace_state | trace_state | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#trace_state) |
| tactic | trace | trace | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#trace) |
| tactic | ___-next | ∎ | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#___-next) |
| tactic | suggestions | suggestions | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#suggestions) |
| tactic | trivial | trivial | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#trivial) |
| tactic | solve | solve | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#solve) |
| tactic | and_intros | and_intros | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#and_intros) |
| tactic | infer_instance | infer_instance | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#infer_instance) |
| tactic | expose_names | expose_names | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#expose_names) |
| tactic | unhygienic | unhygienic | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#unhygienic) |
| tactic | run_tac | run_tac | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#run_tac) |
| tactic | mvcgen | mvcgen | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mvcgen) |
| tactic | mstart | mstart | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mstart) |
| tactic | mstop | mstop | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mstop) |
| tactic | mleave | mleave | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mleave) |
| tactic | mspec | mspec | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mspec) |
| tactic | mintro | mintro | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mintro) |
| tactic | mexact | mexact | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mexact) |
| tactic | massumption | massumption | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#massumption) |
| tactic | mrefine | mrefine | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mrefine) |
| tactic | mconstructor | mconstructor | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mconstructor) |
| tactic | mleft | mleft | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mleft) |
| tactic | mright | mright | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mright) |
| tactic | mexists | mexists | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mexists) |
| tactic | mpure_intro | mpure_intro | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mpure_intro) |
| tactic | mexfalso | mexfalso | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mexfalso) |
| tactic | mclear | mclear | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mclear) |
| tactic | mdup | mdup | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mdup) |
| tactic | mhave | mhave | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mhave) |
| tactic | mreplace | mreplace | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mreplace) |
| tactic | mspecialize | mspecialize | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mspecialize) |
| tactic | mspecialize_pure | mspecialize_pure | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mspecialize_pure) |
| tactic | mcases | mcases | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mcases) |
| tactic | mrename_i | mrename_i | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mrename_i) |
| tactic | mpure | mpure | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mpure) |
| tactic | mframe | mframe | [Reference](pages/Tactic-Proofs/Tactic-Reference/index.md#mframe) |
| tactic | conv-next | conv | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#conv-next) |
| conv tactic | Lean___Parser___Tactic___Conv___first | first | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___first) |
| conv tactic | Lean___Parser___Tactic___Conv___convTry_ | try | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___convTry_) |
| conv tactic | Lean___Parser___Tactic___Conv____FLQQ_conv__LT__SEMI__GT___FLQQ_ | <;> | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv____FLQQ_conv__LT__SEMI__GT___FLQQ_) |
| conv tactic | Lean___Parser___Tactic___Conv___convRepeat_ | repeat | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___convRepeat_) |
| conv tactic | Lean___Parser___Tactic___Conv___skip | skip | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___skip) |
| conv tactic | Lean___Parser___Tactic___Conv___nestedConv | { ... } | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___nestedConv) |
| conv tactic | Lean___Parser___Tactic___Conv___paren | ( ... ) | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___paren) |
| conv tactic | Lean___Parser___Tactic___Conv___convDone | done | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___convDone) |
| conv tactic | Lean___Parser___Tactic___Conv___allGoals | all_goals | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___allGoals) |
| conv tactic | Lean___Parser___Tactic___Conv___anyGoals | any_goals | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___anyGoals) |
| conv tactic | Lean___Parser___Tactic___Conv___case | case ... => ... | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___case) |
| conv tactic | Lean___Parser___Tactic___Conv___case___ | case' ... => ... | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___case___) |
| conv tactic | Lean___Parser___Tactic___Conv____FLQQ_convNext______GT___FLQQ_ | next ... => ... | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv____FLQQ_convNext______GT___FLQQ_) |
| conv tactic | Lean___Parser___Tactic___Conv___focus | focus | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___focus) |
| conv tactic | Lean___Parser___Tactic___Conv____FLQQ_conv_____FLQQ_ | · ... | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv____FLQQ_conv_____FLQQ_) |
| conv tactic | Lean___Parser___Tactic___Conv___failIfSuccess | fail_if_success | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___failIfSuccess) |
| conv tactic | Lean___Parser___Tactic___Conv___lhs | lhs | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___lhs) |
| conv tactic | Lean___Parser___Tactic___Conv___rhs | rhs | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___rhs) |
| conv tactic | Lean___Parser___Tactic___Conv___fun | fun | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___fun) |
| conv tactic | Lean___Parser___Tactic___Conv___congr | congr | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___congr) |
| conv tactic | Lean___Parser___Tactic___Conv___arg | arg [@]i | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___arg) |
| syntax | Arguments to enter |  | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___enterArg) |
| conv tactic | Lean___Parser___Tactic___Conv___enter | enter | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___enter) |
| conv tactic | Lean___Parser___Tactic___Conv___pattern | pattern | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___pattern) |
| conv tactic | Lean___Parser___Tactic___Conv___ext | ext | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___ext) |
| conv tactic | Lean___Parser___Tactic___Conv___convArgs | args | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___convArgs) |
| conv tactic | Lean___Parser___Tactic___Conv___convLeft | left | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___convLeft) |
| conv tactic | Lean___Parser___Tactic___Conv___convRight | right | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___convRight) |
| conv tactic | Lean___Parser___Tactic___Conv___convIntro___ | intro | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___convIntro___) |
| conv tactic | Lean___Parser___Tactic___Conv___cbv | cbv | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___cbv) |
| conv tactic | Lean___Parser___Tactic___Conv___whnf | whnf | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___whnf) |
| conv tactic | Lean___Parser___Tactic___Conv___reduce | reduce | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___reduce) |
| conv tactic | Lean___Parser___Tactic___Conv___zeta | zeta | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___zeta) |
| conv tactic | Lean___Parser___Tactic___Conv___delta | delta | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___delta) |
| conv tactic | Lean___Parser___Tactic___Conv___unfold | unfold | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___unfold) |
| conv tactic | Lean___Parser___Tactic___Conv___simp | simp | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___simp) |
| conv tactic | Lean___Parser___Tactic___Conv___dsimp | dsimp | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___dsimp) |
| conv tactic | Lean___Parser___Tactic___Conv___simpMatch | simp_match | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___simpMatch) |
| conv tactic | Lean___Parser___Tactic___Conv___change | change | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___change) |
| conv tactic | Lean___Parser___Tactic___Conv___rewrite | rewrite | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___rewrite) |
| conv tactic | Lean___Parser___Tactic___Conv___convRw__ | rw | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___convRw__) |
| conv tactic | Lean___Parser___Tactic___Conv___convErw__ | erw | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___convErw__) |
| conv tactic | Lean___Parser___Tactic___Conv___convApply_ | apply | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___convApply_) |
| tactic | conv___ | conv' | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#conv___) |
| conv tactic | Lean___Parser___Tactic___Conv___nestedTactic | tactic | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___nestedTactic) |
| conv tactic | Lean___Parser___Tactic___Conv___nestedTacticCore | tactic' | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___nestedTacticCore) |
| tactic | conv___-next | conv' | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#conv___-next) |
| conv tactic | Lean___Parser___Tactic___Conv___convConvSeq | conv => ... | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___convConvSeq) |
| conv tactic | Lean___Parser___Tactic___Conv___convTrace_state | trace_state | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___convTrace_state) |
| conv tactic | Lean___Parser___Tactic___Conv___convRfl | rfl | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___convRfl) |
| conv tactic | Lean___Parser___Tactic___Conv___normCast | norm_cast | [Reference](pages/Tactic-Proofs/Targeted-Rewriting-with--conv/index.md#Lean___Parser___Tactic___Conv___normCast) |
| def | binderNameHint | binderNameHint.{u, v, w} {α : Sort u} {β : Sort v} {γ : Sort w} (v : α) (binder : β) (e : γ) : γ | [Reference](pages/Tactic-Proofs/Naming-Bound-Variables/index.md#binderNameHint) |
| syntax | Simplification Tactics |  | [Reference](pages/The-Simplifier/Invoking-the-Simplifier/index.md#tactic-next) |
| attribute | Registering simp Lemmas |  | [Reference](pages/The-Simplifier/Simp-sets/index.md#attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Lean.Meta.registerSimpAttr | Lean.Meta.registerSimpAttr (attrName : Lean.Name) (attrDescr : String) (ref : Lean.Name := by exact decl_name%) : IO Lean.Meta.SimpExtension | [Reference](pages/The-Simplifier/Simp-sets/index.md#Lean___Meta___registerSimpAttr) |
| def | Lean.Meta.SimpExtension | Lean.Meta.SimpExtension : Type | [Reference](pages/The-Simplifier/Simp-sets/index.md#Lean___Meta___SimpExtension) |
| structure | Lean.Meta.Simp.Config | Lean.Meta.Simp.Config : Type | [Reference](pages/The-Simplifier/Configuring-Simplification/index.md#Lean___Meta___Simp___Config___mk) |
| def | Lean.Meta.Simp.neutralConfig | Lean.Meta.Simp.neutralConfig : Lean.Meta.Simp.Config | [Reference](pages/The-Simplifier/Configuring-Simplification/index.md#Lean___Meta___Simp___neutralConfig) |
| structure | Lean.Meta.DSimp.Config | Lean.Meta.DSimp.Config : Type | [Reference](pages/The-Simplifier/Configuring-Simplification/index.md#Lean___Meta___DSimp___Config___mk) |
| option | simprocs | simprocs | [Reference](pages/The-Simplifier/Configuring-Simplification/index.md#simprocs) |
| option | tactic___simp___trace-next | tactic.simp.trace | [Reference](pages/The-Simplifier/Configuring-Simplification/index.md#tactic___simp___trace-next) |
| option | linter___unnecessarySimpa | linter.unnecessarySimpa | [Reference](pages/The-Simplifier/Configuring-Simplification/index.md#linter___unnecessarySimpa) |
| option | trace___Meta___Tactic___simp___rewrite | trace.Meta.Tactic.simp.rewrite | [Reference](pages/The-Simplifier/Configuring-Simplification/index.md#trace___Meta___Tactic___simp___rewrite) |
| option | trace___Meta___Tactic___simp___discharge | trace.Meta.Tactic.simp.discharge | [Reference](pages/The-Simplifier/Configuring-Simplification/index.md#trace___Meta___Tactic___simp___discharge) |
| attribute | Case Analysis |  | [Reference](pages/The--grind--tactic/Case-Analysis/index.md#attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| attribute | Eager Case Analysis |  | [Reference](pages/The--grind--tactic/Case-Analysis/index.md#attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| option | trace___grind___split | trace.grind.split | [Reference](pages/The--grind--tactic/Case-Analysis/index.md#trace___grind___split) |
| syntax | E-matching Pattern Selection |  | [Reference](pages/The--grind--tactic/E___matching/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| attribute | Grind Patterns |  | [Reference](pages/The--grind--tactic/E___matching/index.md#attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Default Pattern |  | [Reference](pages/The--grind--tactic/E___matching/index.md#Lean___Parser___Attr___grindMod) |
| syntax | Equality Rewrites |  | [Reference](pages/The--grind--tactic/E___matching/index.md#Lean___Parser___Attr___grindMod-next-next-next) |
| syntax | Backward Equality Rewrites |  | [Reference](pages/The--grind--tactic/E___matching/index.md#Lean___Parser___Attr___grindMod-next-next-next-next-next) |
| syntax | Bidirectional Equality Rewrites |  | [Reference](pages/The--grind--tactic/E___matching/index.md#Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next) |
| syntax | Forward Reasoning |  | [Reference](pages/The--grind--tactic/E___matching/index.md#Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next) |
| syntax | Backward Reasoning |  | [Reference](pages/The--grind--tactic/E___matching/index.md#Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Left-to-Right Traversal |  | [Reference](pages/The--grind--tactic/E___matching/index.md#Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Right-to-Left Traversal |  | [Reference](pages/The--grind--tactic/E___matching/index.md#Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Backward Reasoning on Equality |  | [Reference](pages/The--grind--tactic/E___matching/index.md#Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Function-Valued Congruence Closure |  | [Reference](pages/The--grind--tactic/E___matching/index.md#Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Extensionality |  | [Reference](pages/The--grind--tactic/E___matching/index.md#Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Injectivity |  | [Reference](pages/The--grind--tactic/E___matching/index.md#Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Constructor Patterns |  | [Reference](pages/The--grind--tactic/E___matching/index.md#Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Unfolding During Preprocessing |  | [Reference](pages/The--grind--tactic/E___matching/index.md#Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Normalization Rules |  | [Reference](pages/The--grind--tactic/E___matching/index.md#Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Homomorphism Rules |  | [Reference](pages/The--grind--tactic/E___matching/index.md#Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Homomorphism Predicates |  | [Reference](pages/The--grind--tactic/E___matching/index.md#Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| option | trace___grind___ematch___instance | trace.grind.ematch.instance | [Reference](pages/The--grind--tactic/E___matching/index.md#trace___grind___ematch___instance) |
| type class | Std.Associative | Std.Associative.{u} {α : Sort u} (op : α → α → α) : Prop | [Reference](pages/The--grind--tactic/Associativity-and-Commutativity/index.md#Std___Associative___mk) |
| type class | Std.Commutative | Std.Commutative.{u} {α : Sort u} (op : α → α → α) : Prop | [Reference](pages/The--grind--tactic/Associativity-and-Commutativity/index.md#Std___Commutative___mk) |
| type class | Std.IdempotentOp | Std.IdempotentOp.{u} {α : Sort u} (op : α → α → α) : Prop | [Reference](pages/The--grind--tactic/Associativity-and-Commutativity/index.md#Std___IdempotentOp___mk) |
| type class | Std.LawfulIdentity | Std.LawfulIdentity.{u} {α : Sort u} (op : α → α → α) (o : outParam α) : Prop | [Reference](pages/The--grind--tactic/Associativity-and-Commutativity/index.md#Std___LawfulIdentity___mk) |
| option | trace___grind___ac | trace.grind.ac | [Reference](pages/The--grind--tactic/Associativity-and-Commutativity/index.md#trace___grind___ac) |
| option | trace___grind___ac___assert | trace.grind.ac.assert | [Reference](pages/The--grind--tactic/Associativity-and-Commutativity/index.md#trace___grind___ac___assert) |
| option | trace___grind___ac___internalize | trace.grind.ac.internalize | [Reference](pages/The--grind--tactic/Associativity-and-Commutativity/index.md#trace___grind___ac___internalize) |
| option | trace___grind___ac___basis | trace.grind.ac.basis | [Reference](pages/The--grind--tactic/Associativity-and-Commutativity/index.md#trace___grind___ac___basis) |
| type class | Lean.Grind.ToInt | Lean.Grind.ToInt.{u} (α : Type u) (range : outParam Lean.Grind.IntInterval) : Type u | [Reference](pages/The--grind--tactic/Linear-Integer-Arithmetic/index.md#Lean___Grind___ToInt___mk) |
| inductive type | Lean.Grind.IntInterval | Lean.Grind.IntInterval : Type | [Reference](pages/The--grind--tactic/Linear-Integer-Arithmetic/index.md#Lean___Grind___IntInterval___co) |
| type class | Lean.Grind.Semiring | Lean.Grind.Semiring.{u} (α : Type u) : Type u | [Reference](pages/The--grind--tactic/Algebraic-Solver-_LPAR_Commutative-Rings___-Fields_RPAR_/index.md#Lean___Grind___Semiring___mk) |
| type class | Lean.Grind.CommSemiring | Lean.Grind.CommSemiring.{u} (α : Type u) : Type u | [Reference](pages/The--grind--tactic/Algebraic-Solver-_LPAR_Commutative-Rings___-Fields_RPAR_/index.md#Lean___Grind___CommSemiring___mk) |
| type class | Lean.Grind.Ring | Lean.Grind.Ring.{u} (α : Type u) : Type u | [Reference](pages/The--grind--tactic/Algebraic-Solver-_LPAR_Commutative-Rings___-Fields_RPAR_/index.md#Lean___Grind___Ring___mk) |
| type class | Lean.Grind.CommRing | Lean.Grind.CommRing.{u} (α : Type u) : Type u | [Reference](pages/The--grind--tactic/Algebraic-Solver-_LPAR_Commutative-Rings___-Fields_RPAR_/index.md#Lean___Grind___CommRing___mk) |
| type class | Lean.Grind.Field | Lean.Grind.Field.{u} (α : Type u) : Type u | [Reference](pages/The--grind--tactic/Algebraic-Solver-_LPAR_Commutative-Rings___-Fields_RPAR_/index.md#Lean___Grind___Field___mk) |
| type class | Lean.Grind.IsCharP | Lean.Grind.IsCharP.{u} (α : Type u) [Lean.Grind.Semiring α] (p : outParam Nat) : Prop | [Reference](pages/The--grind--tactic/Algebraic-Solver-_LPAR_Commutative-Rings___-Fields_RPAR_/index.md#Lean___Grind___IsCharP___mk) |
| type class | Lean.Grind.NoNatZeroDivisors | Lean.Grind.NoNatZeroDivisors.{u} (α : Type u) [Lean.Grind.NatModule α] : Prop | [Reference](pages/The--grind--tactic/Algebraic-Solver-_LPAR_Commutative-Rings___-Fields_RPAR_/index.md#Lean___Grind___NoNatZeroDivisors___mk) |
| def | Lean.Grind.NoNatZeroDivisors.mk' | Lean.Grind.NoNatZeroDivisors.mk'.{u_1} {α : Type u_1} [Lean.Grind.IntModule α] (eq_zero_of_mul_eq_zero : ∀ (k : Nat) (a : α), k ≠ 0 → k • a = 0 → a = 0) : Lean. … | [Reference](pages/The--grind--tactic/Algebraic-Solver-_LPAR_Commutative-Rings___-Fields_RPAR_/index.md#Lean___Grind___NoNatZeroDivisors___mk___) |
| type class | Lean.Grind.AddRightCancel | Lean.Grind.AddRightCancel.{u} (M : Type u) [Add M] : Prop | [Reference](pages/The--grind--tactic/Algebraic-Solver-_LPAR_Commutative-Rings___-Fields_RPAR_/index.md#Lean___Grind___AddRightCancel___mk) |
| type class | Lean.Grind.NatModule | Lean.Grind.NatModule.{u} (M : Type u) : Type u | [Reference](pages/The--grind--tactic/Linear-Arithmetic-Solver/index.md#Lean___Grind___NatModule___mk) |
| type class | Lean.Grind.IntModule | Lean.Grind.IntModule.{u} (M : Type u) : Type u | [Reference](pages/The--grind--tactic/Linear-Arithmetic-Solver/index.md#Lean___Grind___IntModule___mk) |
| type class | Lean.Grind.OrderedAdd | Lean.Grind.OrderedAdd.{u} (M : Type u) [HAdd M M M] [LE M] [Std.IsPreorder M] : Prop | [Reference](pages/The--grind--tactic/Linear-Arithmetic-Solver/index.md#Lean___Grind___OrderedAdd___mk) |
| type class | Lean.Grind.OrderedRing | Lean.Grind.OrderedRing.{u} (R : Type u) [Semiring R] [LE R] [LT R] [Std.IsPreorder R] : Prop | [Reference](pages/The--grind--tactic/Linear-Arithmetic-Solver/index.md#Lean___Grind___OrderedRing___mk) |
| def | Std.Do.SPred | Std.Do.SPred.{u} (σs : List (Type u)) : Type u | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___SPred) |
| syntax | Notation for SPred |  | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Std.Do.SPred.pure | Std.Do.SPred.pure.{u} {σs : List (Type u)} (P : Prop) : SPred σs | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___SPred___pure) |
| def | Std.Do.SPred.entails | Std.Do.SPred.entails.{u} {σs : List (Type u)} (P Q : SPred σs) : Prop | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___SPred___entails) |
| def | Std.Do.SPred.bientails | Std.Do.SPred.bientails.{u} {σs : List (Type u)} (P Q : SPred σs) : Prop | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___SPred___bientails) |
| syntax | Notation for SPred |  | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Predicate Terms |  | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Predicate Connectives |  | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Std.Do.SPred.and | Std.Do.SPred.and.{u} {σs : List (Type u)} (P Q : SPred σs) : SPred σs | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___SPred___and) |
| def | Std.Do.SPred.conjunction | Std.Do.SPred.conjunction.{u} {σs : List (Type u)} (env : List (SPred σs)) : SPred σs | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___SPred___conjunction) |
| def | Std.Do.SPred.or | Std.Do.SPred.or.{u} {σs : List (Type u)} (P Q : SPred σs) : SPred σs | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___SPred___or) |
| def | Std.Do.SPred.not | Std.Do.SPred.not.{u} {σs : List (Type u)} (P : SPred σs) : SPred σs | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___SPred___not) |
| def | Std.Do.SPred.imp | Std.Do.SPred.imp.{u} {σs : List (Type u)} (P Q : SPred σs) : SPred σs | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___SPred___imp) |
| def | Std.Do.SPred.iff | Std.Do.SPred.iff.{u} {σs : List (Type u)} (P Q : SPred σs) : SPred σs | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___SPred___iff) |
| syntax | Predicate Quantifiers |  | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Std.Do.SPred.forall | Std.Do.SPred.forall.{u, v} {α : Sort u} {σs : List (Type v)} (P : α → SPred σs) : SPred σs | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___SPred___forall) |
| def | Std.Do.SPred.exists | Std.Do.SPred.exists.{u, v} {α : Sort u} {σs : List (Type v)} (P : α → SPred σs) : SPred σs | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___SPred___exists) |
| def | Std.Do.SVal | Std.Do.SVal.{u} (σs : List (Type u)) (α : Type u) : Type u | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___SVal) |
| def | Std.Do.SVal.getThe | Std.Do.SVal.getThe.{u} {σs : List (Type u)} (σ : Type u) [SVal.GetTy σ σs] : SVal σs σ | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___SVal___getThe) |
| def | Std.Do.SVal.StateTuple | Std.Do.SVal.StateTuple.{u} (σs : List (Type u)) : Type u | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___SVal___StateTuple) |
| def | Std.Do.SVal.curry | Std.Do.SVal.curry.{u} {α : Type u} {σs : List (Type u)} (f : SVal.StateTuple σs → α) : SVal σs α | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___SVal___curry) |
| def | Std.Do.SVal.uncurry | Std.Do.SVal.uncurry.{u} {α : Type u} {σs : List (Type u)} (f : SVal σs α) : SVal.StateTuple σs → α | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___SVal___uncurry) |
| inductive type | Std.Do.PostShape | Std.Do.PostShape.{u} : Type (u + 1) | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___PostShape___pure) |
| def | Std.Do.PostShape.args | Std.Do.PostShape.args.{u} : PostShape → List (Type u) | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___PostShape___args) |
| def | Std.Do.Assertion | Std.Do.Assertion.{u} (ps : PostShape) : Type u | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___Assertion) |
| def | Std.Do.PostCond | Std.Do.PostCond.{u} (α : Type u) (ps : PostShape) : Type u | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___PostCond) |
| syntax | Postconditions |  | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Std.Do.ExceptConds | Std.Do.ExceptConds.{u} : PostShape → Type u | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___ExceptConds) |
| syntax | Exception-Free Postconditions |  | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Std.Do.PostCond.noThrow | Std.Do.PostCond.noThrow.{u_1} {α : Type u_1} {ps : PostShape} (p : α → Assertion ps) : PostCond α ps | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___PostCond___noThrow) |
| syntax | Partial Postconditions |  | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Std.Do.PostCond.mayThrow | Std.Do.PostCond.mayThrow.{u_1} {α : Type u_1} {ps : PostShape} (p : α → Assertion ps) : PostCond α ps | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___PostCond___mayThrow) |
| syntax | Postcondition Entailment |  | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Std.Do.PostCond.entails | Std.Do.PostCond.entails.{u_1} {α : Type u_1} {ps : PostShape} (p q : PostCond α ps) : Prop | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___PostCond___entails) |
| syntax | Postcondition Conjunction |  | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Std.Do.PostCond.and | Std.Do.PostCond.and.{u_1} {α : Type u_1} {ps : PostShape} (p q : PostCond α ps) : PostCond α ps | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___PostCond___and) |
| syntax | Postcondition Implication |  | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Std.Do.PostCond.imp | Std.Do.PostCond.imp.{u_1} {α : Type u_1} {ps : PostShape} (p q : PostCond α ps) : PostCond α ps | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___PostCond___imp) |
| structure | Std.Do.PredTrans | Std.Do.PredTrans.{u} (ps : PostShape) (α : Type u) : Type u | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___PredTrans___mk) |
| def | Std.Do.PredTrans.Conjunctive | Std.Do.PredTrans.Conjunctive.{u} {ps : PostShape} {α : Type u} (t : PostCond α ps → Assertion ps) : Prop | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___PredTrans___Conjunctive) |
| def | Std.Do.PredTrans.Monotonic | Std.Do.PredTrans.Monotonic.{u} {ps : PostShape} {α : Type u} (t : PostCond α ps → Assertion ps) : Prop | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___PredTrans___Monotonic) |
| def | Std.Do.PredTrans.pure | Std.Do.PredTrans.pure.{u} {ps : PostShape} {α : Type u} (a : α) : PredTrans ps α | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___PredTrans___pure) |
| def | Std.Do.PredTrans.bind | Std.Do.PredTrans.bind.{u} {ps : PostShape} {α β : Type u} (x : PredTrans ps α) (f : α → PredTrans ps β) : PredTrans ps β | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___PredTrans___bind) |
| def | Std.Do.PredTrans.pushArg | Std.Do.PredTrans.pushArg.{u} {ps : PostShape} {α σ : Type u} (x : StateT σ (PredTrans ps) α) : PredTrans (PostShape.arg σ ps) α | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___PredTrans___pushArg) |
| def | Std.Do.PredTrans.pushExcept | Std.Do.PredTrans.pushExcept.{u_1} {ps : PostShape} {α ε : Type u_1} (x : ExceptT ε (PredTrans ps) α) : PredTrans (PostShape.except ε ps) α | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___PredTrans___pushExcept) |
| def | Std.Do.PredTrans.pushOption | Std.Do.PredTrans.pushOption.{u_1} {ps : PostShape} {α : Type u_1} (x : OptionT (PredTrans ps) α) : PredTrans (PostShape.except PUnit ps) α | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___PredTrans___pushOption) |
| type class | Std.Do.WP | Std.Do.WP.{u, v} (m : Type u → Type v) (ps : outParam PostShape) : Type (max (u + 1) v) | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___WP___mk) |
| syntax | Weakest Preconditions |  | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| type class | Std.Do.WPMonad | Std.Do.WPMonad.{u, v} (m : Type u → Type v) (ps : outParam PostShape) [Monad m] : Type (max (u + 1) v) | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___WPMonad___mk) |
| theorem | Std.Do.Id.of_wp_run_eq | Std.Do.Id.of_wp_run_eq.{u} {α : Type u} {x : α} {prog : Id α} (h : prog.run = x) (P : α → Prop) : (⊢ₛ wp⟦prog⟧ (PostCond.noThrow fun a => { down := P a })) → P  … | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___Id___of_wp_run_eq) |
| theorem | Std.Do.StateM.of_wp_run_eq | Std.Do.StateM.of_wp_run_eq {α σ : Type} {x : α × σ} {s : σ} {prog : StateM σ α} (h : StateT.run prog s = x) (P : α × σ → Prop) : (⊢ₛ wp⟦prog⟧ (PostCond.noThrow  … | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___StateM___of_wp_run_eq) |
| theorem | Std.Do.StateM.of_wp_run'_eq | Std.Do.StateM.of_wp_run'_eq {α σ : Type} {x : α} {s : σ} {prog : StateM σ α} (h : StateT.run' prog s = x) (P : α → Prop) : (⊢ₛ wp⟦prog⟧ (PostCond.noThrow fun a  … | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___StateM___of_wp_run____eq) |
| theorem | Std.Do.ReaderM.of_wp_run_eq | Std.Do.ReaderM.of_wp_run_eq.{u} {α ρ : Type u} {x : α} {r : ρ} {prog : ReaderM ρ α} (h : ReaderT.run prog r = x) (P : α → Prop) : (⊢ₛ wp⟦prog⟧ (PostCond.noThrow … | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___ReaderM___of_wp_run_eq) |
| theorem | Std.Do.Except.of_wp_eq | Std.Do.Except.of_wp_eq {ε α : Type} {x prog : Except ε α} (h : prog = x) (P : Except ε α → Prop) : (⊢ₛ wp⟦prog⟧ (fun a => ⌜P (Except.ok a)⌝, fun e => ⌜P (Except … | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___Except___of_wp_eq) |
| theorem | Std.Do.EStateM.of_wp_run_eq | Std.Do.EStateM.of_wp_run_eq.{u_1} {ε σ : Type u_1} {s : σ} {α : Type u_1} {x : EStateM.Result ε σ α} {prog : EStateM ε σ α} (h : prog.run s = x) (P : EStateM.Re … | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___EStateM___of_wp_run_eq) |
| def | Std.Do.Triple | Std.Do.Triple.{u, v} {m : Type u → Type v} {ps : PostShape} [WP m ps] {α : Type u} (x : m α) (P : Assertion ps) (Q : PostCond α ps) : Prop | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___Triple) |
| syntax | Hoare Triples |  | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| theorem | Std.Do.Triple.and | Std.Do.Triple.and.{u, v} {m : Type u → Type v} {ps : PostShape} {α : Type u} {P₁ : Assertion ps} {Q₁ : PostCond α ps} {P₂ : Assertion ps} {Q₂ : PostCond α ps} [ … | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___Triple___and) |
| theorem | Std.Do.Triple.mp | Std.Do.Triple.mp.{u, v} {m : Type u → Type v} {ps : PostShape} {α : Type u} {P₁ : Assertion ps} {Q₁ : PostCond α ps} {P₂ : Assertion ps} {Q₂ : PostCond α ps} [W … | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___Triple___mp) |
| attribute | Specification Lemmas |  | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Std.Do.Invariant | Std.Do.Invariant.{u₁, u₂} {α : Type u₁} (xs : List α) (β : Type u₂) (ps : PostShape) : Type (max u₂ u₁) | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___Invariant) |
| def | Std.Do.Invariant.withEarlyReturn | Std.Do.Invariant.withEarlyReturn.{u₁, u₂} {β : Type (max u₁ u₂)} {ps : PostShape} {α : Type (max u₁ u₂)} {xs : List α} {γ : Type (max u₁ u₂)} (onContinue : xs.C … | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#Std___Do___Invariant___withEarlyReturn) |
| structure | List.Cursor | List.Cursor.{u} {α : Type u} (l : List α) : Type u | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#List___Cursor___mk) |
| def | List.Cursor.at | List.Cursor.at.{u_1} {α : Type u_1} (l : List α) (n : Nat) : l.Cursor | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#List___Cursor___at) |
| def | List.Cursor.pos | List.Cursor.pos.{u_1} {α✝ : Type u_1} {l : List α✝} (c : l.Cursor) : Nat | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#List___Cursor___pos) |
| def | List.Cursor.current | List.Cursor.current.{u_1} {α : Type u_1} {l : List α} (c : l.Cursor) (h : 0 < c.suffix.length := by get_elem_tactic) : α | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#List___Cursor___current) |
| def | List.Cursor.tail | List.Cursor.tail.{u_1} {α✝ : Type u_1} {l : List α✝} (s : l.Cursor) (h : 0 < s.suffix.length := by get_elem_tactic) : l.Cursor | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#List___Cursor___tail) |
| def | List.Cursor.begin | List.Cursor.begin.{u_1} {α : Type u_1} (l : List α) : l.Cursor | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#List___Cursor___begin) |
| def | List.Cursor.end | List.Cursor.end.{u_1} {α : Type u_1} (l : List α) : l.Cursor | [Reference](pages/The--mvcgen--tactic/Predicate-Transformers/index.md#List___Cursor___end) |
| syntax | Proof Mode Goals |  | [Reference](pages/The--mvcgen--tactic/Proof-Mode/index.md#Std___Tactic___Do___mgoalStx) |
| type class | Functor | Functor.{u, v} (f : Type u → Type v) : Type (max (u + 1) v) | [Reference](pages/Functors___-Monads-and--do--Notation/index.md#Functor___mk) |
| type class | Pure | Pure.{u, v} (f : Type u → Type v) : Type (max (u + 1) v) | [Reference](pages/Functors___-Monads-and--do--Notation/index.md#Pure___mk) |
| type class | Seq | Seq.{u, v} (f : Type u → Type v) : Type (max (u + 1) v) | [Reference](pages/Functors___-Monads-and--do--Notation/index.md#Seq___mk) |
| type class | SeqLeft | SeqLeft.{u, v} (f : Type u → Type v) : Type (max (u + 1) v) | [Reference](pages/Functors___-Monads-and--do--Notation/index.md#SeqLeft___mk) |
| type class | SeqRight | SeqRight.{u, v} (f : Type u → Type v) : Type (max (u + 1) v) | [Reference](pages/Functors___-Monads-and--do--Notation/index.md#SeqRight___mk) |
| type class | Applicative | Applicative.{u, v} (f : Type u → Type v) : Type (max (u + 1) v) | [Reference](pages/Functors___-Monads-and--do--Notation/index.md#Applicative___mk) |
| type class | Alternative | Alternative.{u, v} (f : Type u → Type v) : Type (max (u + 1) v) | [Reference](pages/Functors___-Monads-and--do--Notation/index.md#Alternative___mk) |
| type class | Bind | Bind.{u, v} (m : Type u → Type v) : Type (max (u + 1) v) | [Reference](pages/Functors___-Monads-and--do--Notation/index.md#Bind___mk) |
| type class | Monad | Monad.{u, v} (m : Type u → Type v) : Type (max (u + 1) v) | [Reference](pages/Functors___-Monads-and--do--Notation/index.md#Monad___mk) |
| type class | LawfulFunctor | LawfulFunctor.{u, v} (f : Type u → Type v) [Functor f] : Prop | [Reference](pages/Functors___-Monads-and--do--Notation/Laws/index.md#LawfulFunctor___mk) |
| type class | LawfulApplicative | LawfulApplicative.{u, v} (f : Type u → Type v) [Applicative f] : Prop | [Reference](pages/Functors___-Monads-and--do--Notation/Laws/index.md#LawfulApplicative___mk) |
| type class | LawfulMonad | LawfulMonad.{u, v} (m : Type u → Type v) [Monad m] : Prop | [Reference](pages/Functors___-Monads-and--do--Notation/Laws/index.md#LawfulMonad___mk) |
| theorem | LawfulMonad.mk' | LawfulMonad.mk'.{u, v} (m : Type u → Type v) [Monad m] (id_map : ∀ {α : Type u} (x : m α), id <$> x = x) (pure_bind : ∀ {α β : Type u} (x : α) (f : α → m β), pu … | [Reference](pages/Functors___-Monads-and--do--Notation/Laws/index.md#LawfulMonad___mk___) |
| type class | MonadLift | MonadLift.{u, v, w} (m : semiOutParam (Type u → Type v)) (n : Type u → Type w) : Type (max (max (u + 1) v) w) | [Reference](pages/Functors___-Monads-and--do--Notation/Lifting-Monads/index.md#MonadLift___mk) |
| type class | MonadLiftT | MonadLiftT.{u, v, w} (m : Type u → Type v) (n : Type u → Type w) : Type (max (max (u + 1) v) w) | [Reference](pages/Functors___-Monads-and--do--Notation/Lifting-Monads/index.md#MonadLiftT___mk) |
| option | autoLift | autoLift | [Reference](pages/Functors___-Monads-and--do--Notation/Lifting-Monads/index.md#autoLift) |
| type class | MonadFunctor | MonadFunctor.{u, v, w} (m : semiOutParam (Type u → Type v)) (n : Type u → Type w) : Type (max (max (u + 1) v) w) | [Reference](pages/Functors___-Monads-and--do--Notation/Lifting-Monads/index.md#MonadFunctor___mk) |
| type class | MonadFunctorT | MonadFunctorT.{u, v, w} (m : Type u → Type v) (n : Type u → Type w) : Type (max (max (u + 1) v) w) | [Reference](pages/Functors___-Monads-and--do--Notation/Lifting-Monads/index.md#MonadFunctorT___mk) |
| type class | MonadControl | MonadControl.{u, v, w} (m : semiOutParam (Type u → Type v)) (n : Type u → Type w) : Type (max (max (u + 1) v) w) | [Reference](pages/Functors___-Monads-and--do--Notation/Lifting-Monads/index.md#MonadControl___mk) |
| type class | MonadControlT | MonadControlT.{u, v, w} (m : Type u → Type v) (n : Type u → Type w) : Type (max (max (u + 1) v) w) | [Reference](pages/Functors___-Monads-and--do--Notation/Lifting-Monads/index.md#MonadControlT___mk) |
| def | control | control.{u, v, w} {m : Type u → Type v} {n : Type u → Type w} [MonadControlT m n] [Bind n] {α : Type u} (f : ({β : Type u} → n β → m (stM m n β)) → m (stM m n α … | [Reference](pages/Functors___-Monads-and--do--Notation/Lifting-Monads/index.md#control) |
| def | controlAt | controlAt.{u, v, w} (m : Type u → Type v) {n : Type u → Type w} [MonadControlT m n] [Bind n] {α : Type u} (f : ({β : Type u} → n β → m (stM m n β)) → m (stM m n … | [Reference](pages/Functors___-Monads-and--do--Notation/Lifting-Monads/index.md#controlAt) |
| syntax | Functor Operators |  | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Applicative Operators |  | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Alternative Operators |  | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Monad Operators |  | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | do-Notation |  | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Terms in do-Notation |  | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___doSeqItem) |
| syntax | Data Dependence in do-Notation |  | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___doSeqItem-next-next) |
| syntax | Local Definitions in do-Notation |  | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___doSeqItem-next-next-next-next-next) |
| syntax | Early Return |  | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___doSeqItem-next-next-next-next-next-next-next) |
| syntax | Local Mutability |  | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___doSeqItem-next-next-next-next-next-next-next-next-next-next) |
| syntax | Conditionals |  | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___doSeqItem-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Reverse Conditionals |  | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___doSeqItem-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Pattern Matching |  | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___doSeqItem-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Iteration over Collections |  | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___doSeqItem-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Conditional Loops |  | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___doSeqItem-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Post-Tested Loops |  | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___doSeqItem-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Unconditional Loops |  | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___doSeqItem-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Loop Control Statements |  | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___doSeqItem-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| type class | ForIn | ForIn.{u, v, u₁, u₂} (m : Type u₁ → Type u₂) (ρ : Type u) (α : outParam (Type v)) : Type (max (max (max u (u₁ + 1)) u₂) v) | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#ForIn___mk) |
| type class | ForIn' | ForIn'.{u, v, u₁, u₂} (m : Type u₁ → Type u₂) (ρ : Type u) (α : outParam (Type v)) (d : outParam (Membership α ρ)) : Type (max (max (max u (u₁ + 1)) u₂) v) | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#ForIn______mk) |
| inductive type | ForInStep | ForInStep.{u} (α : Type u) : Type u | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#ForInStep___done) |
| def | ForInStep.value | ForInStep.value.{u_1} {α : Type u_1} (x : ForInStep α) : α | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#ForInStep___value) |
| type class | ForM | ForM.{u, v, w₁, w₂} (m : Type u → Type v) (γ : Type w₁) (α : outParam (Type w₂)) : Type (max (max v w₁) w₂) | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#ForM___mk) |
| def | ForM.forIn | ForM.forIn.{u_1, u_2, u_3, u_4} {m : Type u_1 → Type u_2} {β : Type u_1} {ρ : Type u_3} {α : Type u_4} [Monad m] [ForM (StateT β (ExceptT β m)) ρ α] (x : ρ) (b  … | [Reference](pages/Functors___-Monads-and--do--Notation/Syntax/index.md#ForM___forIn) |
| def | Functor.discard | Functor.discard.{u, v} {f : Type u → Type v} {α : Type u} [Functor f] (x : f α) : f PUnit | [Reference](pages/Functors___-Monads-and--do--Notation/API-Reference/index.md#Functor___discard) |
| def | guard | guard.{v} {f : Type → Type v} [Alternative f] (p : Prop) [Decidable p] : f Unit | [Reference](pages/Functors___-Monads-and--do--Notation/API-Reference/index.md#guard) |
| def | optional | optional.{u, v} {f : Type u → Type v} [Alternative f] {α : Type u} (x : f α) : f (Option α) | [Reference](pages/Functors___-Monads-and--do--Notation/API-Reference/index.md#optional) |
| def | andM | andM.{u, v} {m : Type u → Type v} {β : Type u} [Monad m] [ToBool β] (x y : m β) : m β | [Reference](pages/Functors___-Monads-and--do--Notation/API-Reference/index.md#andM) |
| def | orM | orM.{u, v} {m : Type u → Type v} {β : Type u} [Monad m] [ToBool β] (x y : m β) : m β | [Reference](pages/Functors___-Monads-and--do--Notation/API-Reference/index.md#orM) |
| def | notM | notM.{v} {m : Type → Type v} [Functor m] (x : m Bool) : m Bool | [Reference](pages/Functors___-Monads-and--do--Notation/API-Reference/index.md#notM) |
| def | Bind.kleisliRight | Bind.kleisliRight.{u, u_1, u_2} {α : Type u} {m : Type u_1 → Type u_2} {β γ : Type u_1} [Bind m] (f₁ : α → m β) (f₂ : β → m γ) (a : α) : m γ | [Reference](pages/Functors___-Monads-and--do--Notation/API-Reference/index.md#Bind___kleisliRight) |
| def | Bind.kleisliLeft | Bind.kleisliLeft.{u, u_1, u_2} {α : Type u} {m : Type u_1 → Type u_2} {β γ : Type u_1} [Bind m] (f₂ : β → m γ) (f₁ : α → m β) (a : α) : m γ | [Reference](pages/Functors___-Monads-and--do--Notation/API-Reference/index.md#Bind___kleisliLeft) |
| def | Functor.mapRev | Functor.mapRev.{u, v} {f : Type u → Type v} [Functor f] {α β : Type u} : f α → (α → β) → f β | [Reference](pages/Functors___-Monads-and--do--Notation/API-Reference/index.md#Functor___mapRev) |
| def | Bind.bindLeft | Bind.bindLeft.{u, u_1} {α : Type u} {m : Type u → Type u_1} {β : Type u} [Bind m] (f : α → m β) (ma : m α) : m β | [Reference](pages/Functors___-Monads-and--do--Notation/API-Reference/index.md#Bind___bindLeft) |
| def | Id | Id.{u} (type : Type u) : Type u | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#Id) |
| def | Id.run | Id.run.{u_1} {α : Type u_1} (x : Id α) : α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#Id___run) |
| type class | MonadState | MonadState.{u, v} (σ : outParam (Type u)) (m : Type u → Type v) : Type (max (u + 1) v) | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#MonadState___mk) |
| def | MonadState.get | MonadState.get.{u, v} {σ : outParam (Type u)} {m : Type u → Type v} [self : MonadState σ m] : m σ | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#MonadState___get) |
| def | modify | modify.{u, v} {σ : Type u} {m : Type u → Type v} [MonadState σ m] (f : σ → σ) : m PUnit | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#modify) |
| def | MonadState.modifyGet | MonadState.modifyGet.{u, v} {σ : outParam (Type u)} {m : Type u → Type v} [self : MonadState σ m] {α : Type u} : (σ → α × σ) → m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#MonadState___modifyGet) |
| def | getModify | getModify.{u, v} {σ : Type u} {m : Type u → Type v} [MonadState σ m] (f : σ → σ) : m σ | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#getModify) |
| type class | MonadStateOf | MonadStateOf.{u, v} (σ : semiOutParam (Type u)) (m : Type u → Type v) : Type (max (u + 1) v) | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#MonadStateOf___mk) |
| def | getThe | getThe.{u, v} (σ : Type u) {m : Type u → Type v} [MonadStateOf σ m] : m σ | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#getThe) |
| def | modifyThe | modifyThe.{u, v} (σ : Type u) {m : Type u → Type v} [MonadStateOf σ m] (f : σ → σ) : m PUnit | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#modifyThe) |
| def | modifyGetThe | modifyGetThe.{u, v} {α : Type u} (σ : Type u) {m : Type u → Type v} [MonadStateOf σ m] (f : σ → α × σ) : m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#modifyGetThe) |
| def | StateM | StateM.{u} (σ α : Type u) : Type u | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateM) |
| def | StateT | StateT.{u, v} (σ : Type u) (m : Type u → Type v) (α : Type u) : Type (max u v) | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateT) |
| def | StateT.run | StateT.run.{u, v} {σ : Type u} {m : Type u → Type v} {α : Type u} (x : StateT σ m α) (s : σ) : m (α × σ) | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateT___run) |
| def | StateT.get | StateT.get.{u, v} {σ : Type u} {m : Type u → Type v} [Monad m] : StateT σ m σ | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateT___get) |
| def | Monad | StateT.set.{u, v} {σ : Type u} {m : Type u → Type v} [Monad m] : σ → StateT σ m PUnit | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateT___set) |
| def | StateT.orElse | StateT.orElse.{u, v} {σ : Type u} {m : Type u → Type v} [Alternative m] {α : Type u} (x₁ : StateT σ m α) (x₂ : Unit → StateT σ m α) : StateT σ m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateT___orElse) |
| def | StateT.failure | StateT.failure.{u, v} {σ : Type u} {m : Type u → Type v} [Alternative m] {α : Type u} : StateT σ m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateT___failure) |
| def | StateT.run' | StateT.run'.{u, v} {σ : Type u} {m : Type u → Type v} [Functor m] {α : Type u} (x : StateT σ m α) (s : σ) : m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateT___run___) |
| def | StateT.bind | StateT.bind.{u, v} {σ : Type u} {m : Type u → Type v} [Monad m] {α β : Type u} (x : StateT σ m α) (f : α → StateT σ m β) : StateT σ m β | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateT___bind) |
| def | StateT.modifyGet | StateT.modifyGet.{u, v} {σ : Type u} {m : Type u → Type v} [Monad m] {α : Type u} (f : σ → α × σ) : StateT σ m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateT___modifyGet) |
| def | StateT.lift | StateT.lift.{u, v} {σ : Type u} {m : Type u → Type v} [Monad m] {α : Type u} (t : m α) : StateT σ m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateT___lift) |
| def | StateT.map | StateT.map.{u, v} {σ : Type u} {m : Type u → Type v} [Monad m] {α β : Type u} (f : α → β) (x : StateT σ m α) : StateT σ m β | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateT___map) |
| def | StateT.pure | StateT.pure.{u, v} {σ : Type u} {m : Type u → Type v} [Monad m] {α : Type u} (a : α) : StateT σ m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateT___pure) |
| def | StateCpsT | StateCpsT.{u, v} (σ : Type u) (m : Type u → Type v) (α : Type u) : Type (max (u + 1) v) | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateCpsT) |
| def | StateCpsT.lift | StateCpsT.lift.{u, v} {α σ : Type u} {m : Type u → Type v} [Monad m] (x : m α) : StateCpsT σ m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateCpsT___lift) |
| def | StateCpsT.runK | StateCpsT.runK.{u, v} {α σ : Type u} {m : Type u → Type v} {β : Type u} (x : StateCpsT σ m α) (s : σ) (k : α → σ → m β) : m β | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateCpsT___runK) |
| def | StateCpsT.run' | StateCpsT.run'.{u, v} {α σ : Type u} {m : Type u → Type v} [Monad m] (x : StateCpsT σ m α) (s : σ) : m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateCpsT___run___) |
| def | StateCpsT.run | StateCpsT.run.{u, v} {α σ : Type u} {m : Type u → Type v} [Monad m] (x : StateCpsT σ m α) (s : σ) : m (α × σ) | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateCpsT___run) |
| type class | STWorld | STWorld (σ : outParam Type) (m : Type → Type) : Type | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#STWorld___mk) |
| syntax | StateRefT |  | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | StateRefT' | StateRefT' (ω σ : Type) (m : Type → Type) (α : Type) : Type | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateRefT___) |
| def | StateRefT'.get | StateRefT'.get {ω σ : Type} {m : Type → Type} [MonadLiftT (ST ω) m] : StateRefT' ω σ m σ | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateRefT______get) |
| def | StateRefT'.set | StateRefT'.set {ω σ : Type} {m : Type → Type} [MonadLiftT (ST ω) m] (s : σ) : StateRefT' ω σ m PUnit | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateRefT______set) |
| def | StateRefT'.modifyGet | StateRefT'.modifyGet {ω σ : Type} {m : Type → Type} {α : Type} [MonadLiftT (ST ω) m] (f : σ → α × σ) : StateRefT' ω σ m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateRefT______modifyGet) |
| def | StateRefT'.run | StateRefT'.run {ω σ : Type} {m : Type → Type} [Monad m] [MonadLiftT (ST ω) m] {α : Type} (x : StateRefT' ω σ m α) (s : σ) : m (α × σ) | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateRefT______run) |
| def | StateRefT'.run' | StateRefT'.run' {ω σ : Type} {m : Type → Type} [Monad m] [MonadLiftT (ST ω) m] {α : Type} (x : StateRefT' ω σ m α) (s : σ) : m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateRefT______run___) |
| def | StateRefT'.lift | StateRefT'.lift {ω σ : Type} {m : Type → Type} {α : Type} (x : m α) : StateRefT' ω σ m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#StateRefT______lift) |
| type class | MonadReader | MonadReader.{u, v} (ρ : outParam (Type u)) (m : Type u → Type v) : Type v | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#MonadReader___mk) |
| type class | MonadReaderOf | MonadReaderOf.{u, v} (ρ : semiOutParam (Type u)) (m : Type u → Type v) : Type v | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#MonadReaderOf___mk) |
| def | readThe | readThe.{u, v} (ρ : Type u) {m : Type u → Type v} [MonadReaderOf ρ m] : m ρ | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#readThe) |
| type class | MonadWithReader | MonadWithReader.{u, v} (ρ : outParam (Type u)) (m : Type u → Type v) : Type (max (u + 1) v) | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#MonadWithReader___mk) |
| type class | MonadWithReaderOf | MonadWithReaderOf.{u, v} (ρ : semiOutParam (Type u)) (m : Type u → Type v) : Type (max (u + 1) v) | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#MonadWithReaderOf___mk) |
| def | withTheReader | withTheReader.{u, v} (ρ : Type u) {m : Type u → Type v} [MonadWithReaderOf ρ m] {α : Type u} (f : ρ → ρ) (x : m α) : m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#withTheReader) |
| def | ReaderT | ReaderT.{u, v} (ρ : Type u) (m : Type u → Type v) (α : Type u) : Type (max u v) | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ReaderT) |
| def | ReaderM | ReaderM.{u} (ρ α : Type u) : Type u | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ReaderM) |
| def | ReaderT.run | ReaderT.run.{u, v} {ρ : Type u} {m : Type u → Type v} {α : Type u} (x : ReaderT ρ m α) (r : ρ) : m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ReaderT___run) |
| def | ReaderT.read | ReaderT.read.{u, v} {ρ : Type u} {m : Type u → Type v} [Monad m] : ReaderT ρ m ρ | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ReaderT___read) |
| def | ReaderT.adapt | ReaderT.adapt.{u, v} {ρ : Type u} {m : Type u → Type v} {ρ' α : Type u} (f : ρ' → ρ) : ReaderT ρ m α → ReaderT ρ' m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ReaderT___adapt) |
| def | ReaderT.pure | ReaderT.pure.{u, v} {ρ : Type u} {m : Type u → Type v} [Monad m] {α : Type u} (a : α) : ReaderT ρ m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ReaderT___pure) |
| def | ReaderT.bind | ReaderT.bind.{u, v} {ρ : Type u} {m : Type u → Type v} [Monad m] {α β : Type u} (x : ReaderT ρ m α) (f : α → ReaderT ρ m β) : ReaderT ρ m β | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ReaderT___bind) |
| def | ReaderT.orElse | ReaderT.orElse.{u_1, u_2} {m : Type u_1 → Type u_2} {ρ α : Type u_1} [Alternative m] (x₁ : ReaderT ρ m α) (x₂ : Unit → ReaderT ρ m α) : ReaderT ρ m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ReaderT___orElse) |
| def | ReaderT.failure | ReaderT.failure.{u_1, u_2} {m : Type u_1 → Type u_2} {ρ α : Type u_1} [Alternative m] : ReaderT ρ m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ReaderT___failure) |
| def | OptionT | OptionT.{u, v} (m : Type u → Type v) (α : Type u) : Type v | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#OptionT) |
| def | OptionT.run | OptionT.run.{u, v} {m : Type u → Type v} {α : Type u} (x : OptionT m α) : m (Option α) | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#OptionT___run) |
| def | OptionT.lift | OptionT.lift.{u, v} {m : Type u → Type v} [Monad m] {α : Type u} (x : m α) : OptionT m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#OptionT___lift) |
| def | OptionT.mk | OptionT.mk.{u, v} {m : Type u → Type v} {α : Type u} (x : m (Option α)) : OptionT m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#OptionT___mk) |
| def | OptionT.pure | OptionT.pure.{u, v} {m : Type u → Type v} [Monad m] {α : Type u} (a : α) : OptionT m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#OptionT___pure) |
| def | OptionT.bind | OptionT.bind.{u, v} {m : Type u → Type v} [Monad m] {α β : Type u} (x : OptionT m α) (f : α → OptionT m β) : OptionT m β | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#OptionT___bind) |
| def | OptionT.fail | OptionT.fail.{u, v} {m : Type u → Type v} [Monad m] {α : Type u} : OptionT m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#OptionT___fail) |
| def | OptionT.orElse | OptionT.orElse.{u, v} {m : Type u → Type v} [Monad m] {α : Type u} (x : OptionT m α) (y : Unit → OptionT m α) : OptionT m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#OptionT___orElse) |
| def | OptionT.tryCatch | OptionT.tryCatch.{u, v, u_1} {m : Type u → Type v} [Monad m] {α : Type u} (x : OptionT m α) (handle : PUnit → OptionT m α) : OptionT m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#OptionT___tryCatch) |
| inductive type | Except | Except.{u, v} (ε : Type u) (α : Type v) : Type (max u v) | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#Except___error) |
| def | Except.pure | Except.pure.{u, u_1} {ε : Type u} {α : Type u_1} (a : α) : Except ε α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#Except___pure) |
| def | Except.bind | Except.bind.{u, u_1, u_2} {ε : Type u} {α : Type u_1} {β : Type u_2} (ma : Except ε α) (f : α → Except ε β) : Except ε β | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#Except___bind) |
| def | Except.map | Except.map.{u, u_1, u_2} {ε : Type u} {α : Type u_1} {β : Type u_2} (f : α → β) : Except ε α → Except ε β | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#Except___map) |
| def | Except.mapError | Except.mapError.{u, u_1, u_2} {ε : Type u} {ε' : Type u_1} {α : Type u_2} (f : ε → ε') : Except ε α → Except ε' α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#Except___mapError) |
| def | Except.tryCatch | Except.tryCatch.{u, u_1} {ε : Type u} {α : Type u_1} (ma : Except ε α) (handle : ε → Except ε α) : Except ε α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#Except___tryCatch) |
| def | Except.orElseLazy | Except.orElseLazy.{u, u_1} {ε : Type u} {α : Type u_1} (x : Except ε α) (y : Unit → Except ε α) : Except ε α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#Except___orElseLazy) |
| def | Except.isOk | Except.isOk.{u, u_1} {ε : Type u} {α : Type u_1} : Except ε α → Bool | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#Except___isOk) |
| def | Except.toOption | Except.toOption.{u, u_1} {ε : Type u} {α : Type u_1} : Except ε α → Option α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#Except___toOption) |
| def | Except.toBool | Except.toBool.{u, u_1} {ε : Type u} {α : Type u_1} : Except ε α → Bool | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#Except___toBool) |
| type class | MonadExcept | MonadExcept.{u, v, w} (ε : outParam (Type u)) (m : Type v → Type w) : Type (max (max u (v + 1)) w) | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#MonadExcept___mk) |
| def | MonadExcept.ofExcept | MonadExcept.ofExcept.{u_1, u_2, u_3} {m : Type u_1 → Type u_2} {ε : Type u_3} {α : Type u_1} [Monad m] [MonadExcept ε m] : Except ε α → m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#MonadExcept___ofExcept) |
| def | MonadExcept.orElse | MonadExcept.orElse.{u, v, w} {ε : Type u} {m : Type v → Type w} [MonadExcept ε m] {α : Type v} (t₁ : m α) (t₂ : Unit → m α) : m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#MonadExcept___orElse) |
| def | MonadExcept.orelse' | MonadExcept.orelse'.{u, v, w} {ε : Type u} {m : Type v → Type w} [MonadExcept ε m] {α : Type v} (t₁ t₂ : m α) (useFirstEx : Bool := true) : m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#MonadExcept___orelse___) |
| type class | MonadExceptOf | MonadExceptOf.{u, v, w} (ε : semiOutParam (Type u)) (m : Type v → Type w) : Type (max (max u (v + 1)) w) | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#MonadExceptOf___mk) |
| def | throwThe | throwThe.{u, v, w} (ε : Type u) {m : Type v → Type w} [MonadExceptOf ε m] {α : Type v} (e : ε) : m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#throwThe) |
| def | tryCatchThe | tryCatchThe.{u, v, w} (ε : Type u) {m : Type v → Type w} [MonadExceptOf ε m] {α : Type v} (x : m α) (handle : ε → m α) : m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#tryCatchThe) |
| type class | MonadFinally | MonadFinally.{u, v} (m : Type u → Type v) : Type (max (u + 1) v) | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#MonadFinally___mk) |
| def | ExceptT | ExceptT.{u, v} (ε : Type u) (m : Type u → Type v) (α : Type u) : Type v | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ExceptT) |
| def | ExceptT.lift | ExceptT.lift.{u, v} {ε : Type u} {m : Type u → Type v} [Monad m] {α : Type u} (t : m α) : ExceptT ε m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ExceptT___lift) |
| def | ExceptT.run | ExceptT.run.{u, v} {ε : Type u} {m : Type u → Type v} {α : Type u} (x : ExceptT ε m α) : m (Except ε α) | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ExceptT___run) |
| def | ExceptT.pure | ExceptT.pure.{u, v} {ε : Type u} {m : Type u → Type v} [Monad m] {α : Type u} (a : α) : ExceptT ε m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ExceptT___pure) |
| def | ExceptT.bind | ExceptT.bind.{u, v} {ε : Type u} {m : Type u → Type v} [Monad m] {α β : Type u} (ma : ExceptT ε m α) (f : α → ExceptT ε m β) : ExceptT ε m β | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ExceptT___bind) |
| def | ExceptT.bindCont | ExceptT.bindCont.{u, v} {ε : Type u} {m : Type u → Type v} [Monad m] {α β : Type u} (f : α → ExceptT ε m β) : Except ε α → m (Except ε β) | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ExceptT___bindCont) |
| def | ExceptT.tryCatch | ExceptT.tryCatch.{u, v} {ε : Type u} {m : Type u → Type v} [Monad m] {α : Type u} (ma : ExceptT ε m α) (handle : ε → ExceptT ε m α) : ExceptT ε m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ExceptT___tryCatch) |
| def | ExceptT.mk | ExceptT.mk.{u, v} {ε : Type u} {m : Type u → Type v} {α : Type u} (x : m (Except ε α)) : ExceptT ε m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ExceptT___mk) |
| def | ExceptT.map | ExceptT.map.{u, v} {ε : Type u} {m : Type u → Type v} [Monad m] {α β : Type u} (f : α → β) (x : ExceptT ε m α) : ExceptT ε m β | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ExceptT___map) |
| def | ExceptT.adapt | ExceptT.adapt.{u, v} {ε : Type u} {m : Type u → Type v} [Monad m] {ε' α : Type u} (f : ε → ε') : ExceptT ε m α → ExceptT ε' m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ExceptT___adapt) |
| def | ExceptCpsT | ExceptCpsT.{u, v} (ε : Type u) (m : Type u → Type v) (α : Type u) : Type (max (u + 1) v) | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ExceptCpsT) |
| def | ExceptCpsT.runCatch | ExceptCpsT.runCatch.{u_1, u_2} {m : Type u_1 → Type u_2} {α : Type u_1} [Monad m] (x : ExceptCpsT α m α) : m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ExceptCpsT___runCatch) |
| def | ExceptCpsT.runK | ExceptCpsT.runK.{u, u_1} {m : Type u → Type u_1} {β ε α : Type u} (x : ExceptCpsT ε m α) (ok : α → m β) (error : ε → m β) : m β | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ExceptCpsT___runK) |
| def | ExceptCpsT.run | ExceptCpsT.run.{u, u_1} {m : Type u → Type u_1} {ε α : Type u} [Monad m] (x : ExceptCpsT ε m α) : m (Except ε α) | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ExceptCpsT___run) |
| def | ExceptCpsT.lift | ExceptCpsT.lift.{u_1, u_2} {m : Type u_1 → Type u_2} {α ε : Type u_1} [Monad m] (x : m α) : ExceptCpsT ε m α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#ExceptCpsT___lift) |
| def | EStateM | EStateM.{u} (ε σ α : Type u) : Type u | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#EStateM) |
| inductive type | EStateM.Result | EStateM.Result.{u} (ε σ α : Type u) : Type u | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#EStateM___Result___ok) |
| def | EStateM.run | EStateM.run.{u} {ε σ α : Type u} (x : EStateM ε σ α) (s : σ) : EStateM.Result ε σ α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#EStateM___run) |
| def | EStateM.run' | EStateM.run'.{u} {ε σ α : Type u} (x : EStateM ε σ α) (s : σ) : Option α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#EStateM___run___) |
| def | EStateM.adaptExcept | EStateM.adaptExcept.{u} {ε σ α ε' : Type u} (f : ε → ε') (x : EStateM ε σ α) : EStateM ε' σ α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#EStateM___adaptExcept) |
| def | EStateM.fromStateM | EStateM.fromStateM {ε σ α : Type} (x : StateM σ α) : EStateM ε σ α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#EStateM___fromStateM) |
| type class | EStateM.Backtrackable | EStateM.Backtrackable.{u} (δ : outParam (Type u)) (σ : Type u) : Type u | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#EStateM___Backtrackable___mk) |
| def | EStateM.nonBacktrackable | EStateM.nonBacktrackable.{u} {σ : Type u} : EStateM.Backtrackable PUnit σ | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#EStateM___nonBacktrackable) |
| def | EStateM.map | EStateM.map.{u} {ε σ α β : Type u} (f : α → β) (x : EStateM ε σ α) : EStateM ε σ β | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#EStateM___map) |
| def | EStateM.pure | EStateM.pure.{u} {ε σ α : Type u} (a : α) : EStateM ε σ α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#EStateM___pure) |
| def | EStateM.bind | EStateM.bind.{u} {ε σ α β : Type u} (x : EStateM ε σ α) (f : α → EStateM ε σ β) : EStateM ε σ β | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#EStateM___bind) |
| def | EStateM.orElse | EStateM.orElse.{u} {ε σ α δ : Type u} [EStateM.Backtrackable δ σ] (x₁ : EStateM ε σ α) (x₂ : Unit → EStateM ε σ α) : EStateM ε σ α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#EStateM___orElse) |
| def | EStateM.orElse' | EStateM.orElse'.{u} {ε σ α δ : Type u} [EStateM.Backtrackable δ σ] (x₁ x₂ : EStateM ε σ α) (useFirstEx : Bool := true) : EStateM ε σ α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#EStateM___orElse___) |
| def | EStateM.seqRight | EStateM.seqRight.{u} {ε σ α β : Type u} (x : EStateM ε σ α) (y : Unit → EStateM ε σ β) : EStateM ε σ β | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#EStateM___seqRight) |
| def | EStateM.tryCatch | EStateM.tryCatch.{u} {ε σ δ : Type u} [EStateM.Backtrackable δ σ] {α : Type u} (x : EStateM ε σ α) (handle : ε → EStateM ε σ α) : EStateM ε σ α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#EStateM___tryCatch) |
| def | EStateM.throw | EStateM.throw.{u} {ε σ α : Type u} (e : ε) : EStateM ε σ α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#EStateM___throw) |
| def | EStateM.get | EStateM.get.{u} {ε σ : Type u} : EStateM ε σ σ | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#EStateM___get) |
| def | EStateM | EStateM.set.{u} {ε σ : Type u} (s : σ) : EStateM ε σ PUnit | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#EStateM___set) |
| def | EStateM.modifyGet | EStateM.modifyGet.{u} {ε σ α : Type u} (f : σ → α × σ) : EStateM ε σ α | [Reference](pages/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#EStateM___modifyGet) |
| inductive proposition | True | True : Prop | [Reference](pages/Basic-Propositions/Truth/index.md#True___intro) |
| inductive proposition | False | False : Prop | [Reference](pages/Basic-Propositions/Truth/index.md#False) |
| def | False.elim | False.elim.{u} {C : Sort u} (h : False) : C | [Reference](pages/Basic-Propositions/Truth/index.md#False___elim) |
| structure | And | And (a b : Prop) : Prop | [Reference](pages/Basic-Propositions/Logical-Connectives/index.md#And___intro) |
| def | And.elim | And.elim.{u_1} {a b : Prop} {α : Sort u_1} (f : a → b → α) (h : a ∧ b) : α | [Reference](pages/Basic-Propositions/Logical-Connectives/index.md#And___elim) |
| inductive predicate | Or | Or (a b : Prop) : Prop | [Reference](pages/Basic-Propositions/Logical-Connectives/index.md#Or___inl) |
| def | Or.by_cases | Or.by_cases.{u} {p q : Prop} [Decidable p] {α : Sort u} (h : p ∨ q) (h₁ : p → α) (h₂ : q → α) : α | [Reference](pages/Basic-Propositions/Logical-Connectives/index.md#Or___by_cases) |
| def | Or.by_cases' | Or.by_cases'.{u} {q p : Prop} [Decidable q] {α : Sort u} (h : p ∨ q) (h₁ : p → α) (h₂ : q → α) : α | [Reference](pages/Basic-Propositions/Logical-Connectives/index.md#Or___by_cases___) |
| def | Not | Not (a : Prop) : Prop | [Reference](pages/Basic-Propositions/Logical-Connectives/index.md#Not) |
| def | absurd | absurd.{v} {a : Prop} {b : Sort v} (h₁ : a) (h₂ : ¬a) : b | [Reference](pages/Basic-Propositions/Logical-Connectives/index.md#absurd) |
| def | Not.elim | Not.elim.{u_1} {a : Prop} {α : Sort u_1} (H1 : ¬a) (H2 : a) : α | [Reference](pages/Basic-Propositions/Logical-Connectives/index.md#Not___elim) |
| structure | Iff | Iff (a b : Prop) : Prop | [Reference](pages/Basic-Propositions/Logical-Connectives/index.md#Iff___intro) |
| def | Iff.elim | Iff.elim.{u_1} {a b : Prop} {α : Sort u_1} (f : (a → b) → (b → a) → α) (h : a ↔ b) : α | [Reference](pages/Basic-Propositions/Logical-Connectives/index.md#Iff___elim) |
| syntax | Propositional Connectives |  | [Reference](pages/Basic-Propositions/Logical-Connectives/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Universal Quantification |  | [Reference](pages/Basic-Propositions/Quantifiers/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| inductive predicate | Exists | Exists.{u} {α : Sort u} (p : α → Prop) : Prop | [Reference](pages/Basic-Propositions/Quantifiers/index.md#Exists___intro) |
| syntax | Existential Quantification |  | [Reference](pages/Basic-Propositions/Quantifiers/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Exists.choose | Exists.choose.{u_1} {α : Sort u_1} {p : α → Prop} (P : ∃ a, p a) : α | [Reference](pages/Basic-Propositions/Quantifiers/index.md#Exists___choose) |
| inductive predicate | Eq | Eq.{u_1} {α : Sort u_1} : α → α → Prop | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#Eq___refl) |
| syntax | Propositional Equality |  | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | rfl | rfl.{u} {α : Sort u} {a : α} : a = a | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#rfl-next) |
| theorem | Eq.symm | Eq.symm.{u} {α : Sort u} {a b : α} (h : a = b) : b = a | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#Eq___symm) |
| theorem | Eq.trans | Eq.trans.{u} {α : Sort u} {a b c : α} (h₁ : a = b) (h₂ : b = c) : a = c | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#Eq___trans) |
| theorem | Eq.subst | Eq.subst.{u} {α : Sort u} {motive : α → Prop} {a b : α} (h₁ : a = b) (h₂ : motive a) : motive b | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#Eq___subst) |
| def | cast | cast.{u} {α β : Sort u} (h : α = β) (a : α) : β | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#cast) |
| theorem | congr | congr.{u, v} {α : Sort u} {β : Sort v} {f₁ f₂ : α → β} {a₁ a₂ : α} (h₁ : f₁ = f₂) (h₂ : a₁ = a₂) : f₁ a₁ = f₂ a₂ | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#congr-next) |
| theorem | congrFun | congrFun.{u, v} {α : Sort u} {β : α → Sort v} {f g : (x : α) → β x} (h : f = g) (a : α) : f a = g a | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#congrFun) |
| theorem | congrArg | congrArg.{u, v} {α : Sort u} {β : Sort v} {a₁ a₂ : α} (f : α → β) (h : a₁ = a₂) : f a₁ = f a₂ | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#congrArg) |
| def | Eq.mp | Eq.mp.{u} {α β : Sort u} (h : α = β) (a : α) : β | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#Eq___mp) |
| def | Eq.mpr | Eq.mpr.{u} {α β : Sort u} (h : α = β) (b : β) : α | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#Eq___mpr) |
| syntax | Casting |  | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| inductive predicate | HEq | HEq.{u} {α : Sort u} : α → {β : Sort u} → β → Prop | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#HEq___refl) |
| syntax | Heterogeneous Equality |  | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | HEq.rfl | HEq.rfl.{u} {α : Sort u} {a : α} : a ≍ a | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#HEq___rfl) |
| def | HEq.elim | HEq.elim.{u, v} {α : Sort u} {a : α} {p : α → Sort v} {b : α} (h₁ : a ≍ b) (h₂ : p a) : p b | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#HEq___elim) |
| def | HEq.ndrec | HEq.ndrec.{u1, u2} {α : Sort u2} {a : α} {motive : {β : Sort u2} → β → Sort u1} (m : motive a) {β : Sort u2} {b : β} (h : a ≍ b) : motive b | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#HEq___ndrec) |
| def | HEq.ndrecOn | HEq.ndrecOn.{u1, u2} {α : Sort u2} {a : α} {motive : {β : Sort u2} → β → Sort u1} {β : Sort u2} {b : β} (h : a ≍ b) (m : motive a) : motive b | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#HEq___ndrecOn) |
| theorem | HEq.subst | HEq.subst.{u} {α β : Sort u} {a : α} {b : β} {p : (T : Sort u) → T → Prop} (h₁ : a ≍ b) (h₂ : p α a) : p β b | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#HEq___subst) |
| theorem | eq_of_heq | eq_of_heq.{u} {α : Sort u} {a a' : α} (h : a ≍ a') : a = a' | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#eq_of_heq) |
| theorem | heq_of_eq | heq_of_eq.{u_1} {α✝ : Sort u_1} {a a' : α✝} (h : a = a') : a ≍ a' | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#heq_of_eq) |
| theorem | heq_of_eqRec_eq | heq_of_eqRec_eq.{u} {α β : Sort u} {a : α} {b : β} (h₁ : α = β) (h₂ : h₁ ▸ a = b) : a ≍ b | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#heq_of_eqRec_eq) |
| theorem | eqRec_heq | eqRec_heq.{u, v} {α : Sort u} {φ : α → Sort v} {a a' : α} (h : a = a') (p : φ a) : Eq.recOn h p ≍ p | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#eqRec_heq) |
| theorem | cast_heq | cast_heq.{u} {α β : Sort u} (h : α = β) (a : α) : cast h a ≍ a | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#cast_heq) |
| theorem | heq_of_heq_of_eq | heq_of_heq_of_eq.{u} {α β : Sort u} {a : α} {b b' : β} (h₁ : a ≍ b) (h₂ : b = b') : a ≍ b' | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#heq_of_heq_of_eq) |
| theorem | type_eq_of_heq | type_eq_of_heq.{u} {α β : Sort u} {a : α} {b : β} (h : a ≍ b) : α = β | [Reference](pages/Basic-Propositions/Propositional-Equality/index.md#type_eq_of_heq) |
| inductive type | Nat | Nat : Type | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___zero) |
| def | Nat.pred | Nat.pred : Nat → Nat | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___pred) |
| def | Nat.add | Nat.add : Nat → Nat → Nat | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___add) |
| def | Nat.sub | Nat.sub : Nat → Nat → Nat | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___sub) |
| def | Nat.mul | Nat.mul : Nat → Nat → Nat | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___mul) |
| def | Nat.div | Nat.div (x y : Nat) : Nat | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___div) |
| def | Nat.mod | Nat.mod : Nat → Nat → Nat | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___mod) |
| def | Nat.modCore | Nat.modCore (x y : Nat) : Nat | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___modCore) |
| def | Nat.pow | Nat.pow (m : Nat) : Nat → Nat | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___pow) |
| def | Nat.log2 | Nat.log2 (n : Nat) : Nat | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___log2) |
| def | Nat.shiftLeft | Nat.shiftLeft : Nat → Nat → Nat | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___shiftLeft) |
| def | Nat.shiftRight | Nat.shiftRight : Nat → Nat → Nat | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___shiftRight) |
| def | Nat.xor | Nat.xor : Nat → Nat → Nat | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___xor) |
| def | Nat.lor | Nat.lor : Nat → Nat → Nat | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___lor) |
| def | Nat.land | Nat.land : Nat → Nat → Nat | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___land) |
| def | Nat.bitwise | Nat.bitwise (f : Bool → Bool → Bool) (n m : Nat) : Nat | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___bitwise) |
| def | Nat.testBit | Nat.testBit (m n : Nat) : Bool | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___testBit) |
| def | Nat.min | Nat.min (n m : Nat) : Nat | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___min) |
| def | Nat.max | Nat.max (n m : Nat) : Nat | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___max) |
| def | Nat.gcd | Nat.gcd (m n : Nat) : Nat | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___gcd) |
| def | Nat.lcm | Nat.lcm (m n : Nat) : Nat | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___lcm) |
| def | Nat.isPowerOfTwo | Nat.isPowerOfTwo (n : Nat) : Prop | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___isPowerOfTwo) |
| def | Nat.nextPowerOfTwo | Nat.nextPowerOfTwo (n : Nat) : Nat | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___nextPowerOfTwo) |
| def | Nat.beq | Nat.beq : Nat → Nat → Bool | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___beq) |
| def | Nat.ble | Nat.ble : Nat → Nat → Bool | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___ble) |
| def | Nat.blt | Nat.blt (a b : Nat) : Bool | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___blt) |
| def | Nat.decEq | Nat.decEq (n m : Nat) : Decidable (n = m) | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___decEq) |
| def | Nat.decLe | Nat.decLe (n m : Nat) : Decidable (n ≤ m) | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___decLe) |
| def | Nat.decLt | Nat.decLt (n m : Nat) : Decidable (n < m) | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___decLt) |
| inductive predicate | Nat.le | Nat.le (n : Nat) : Nat → Prop | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___le___refl) |
| def | Nat.lt | Nat.lt (n m : Nat) : Prop | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___lt) |
| def | Nat.repeat | Nat.repeat.{u} {α : Type u} (f : α → α) (n : Nat) (a : α) : α | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___repeat) |
| def | Nat.repeatTR | Nat.repeatTR.{u} {α : Type u} (f : α → α) (n : Nat) (a : α) : α | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___repeatTR) |
| def | Nat.fold | Nat.fold.{u} {α : Type u} (n : Nat) (f : (i : Nat) → i < n → α → α) (init : α) : α | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___fold) |
| def | Nat.foldTR | Nat.foldTR.{u} {α : Type u} (n : Nat) (f : (i : Nat) → i < n → α → α) (init : α) : α | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___foldTR) |
| def | Nat.foldM | Nat.foldM.{u, v} {α : Type u} {m : Type u → Type v} [Monad m] (n : Nat) (f : (i : Nat) → i < n → α → m α) (init : α) : m α | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___foldM) |
| def | Nat.foldRev | Nat.foldRev.{u} {α : Type u} (n : Nat) (f : (i : Nat) → i < n → α → α) (init : α) : α | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___foldRev) |
| def | Nat.foldRevM | Nat.foldRevM.{u, v} {α : Type u} {m : Type u → Type v} [Monad m] (n : Nat) (f : (i : Nat) → i < n → α → m α) (init : α) : m α | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___foldRevM) |
| def | Nat.forM | Nat.forM.{u_1} {m : Type → Type u_1} [Monad m] (n : Nat) (f : (i : Nat) → i < n → m Unit) : m Unit | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___forM) |
| def | Nat.forRevM | Nat.forRevM.{u_1} {m : Type → Type u_1} [Monad m] (n : Nat) (f : (i : Nat) → i < n → m Unit) : m Unit | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___forRevM) |
| def | Nat.all | Nat.all (n : Nat) (f : (i : Nat) → i < n → Bool) : Bool | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___all) |
| def | Nat.allTR | Nat.allTR (n : Nat) (f : (i : Nat) → i < n → Bool) : Bool | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___allTR) |
| def | Nat.any | Nat.any (n : Nat) (f : (i : Nat) → i < n → Bool) : Bool | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___any) |
| def | Nat.anyTR | Nat.anyTR (n : Nat) (f : (i : Nat) → i < n → Bool) : Bool | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___anyTR) |
| def | Nat.allM | Nat.allM.{u_1} {m : Type → Type u_1} [Monad m] (n : Nat) (p : (i : Nat) → i < n → m Bool) : m Bool | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___allM) |
| def | Nat.anyM | Nat.anyM.{u_1} {m : Type → Type u_1} [Monad m] (n : Nat) (p : (i : Nat) → i < n → m Bool) : m Bool | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___anyM) |
| def | Nat.toUInt8 | Nat.toUInt8 (n : Nat) : UInt8 | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___toUInt8) |
| def | Nat.toUInt16 | Nat.toUInt16 (n : Nat) : UInt16 | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___toUInt16) |
| def | Nat.toUInt32 | Nat.toUInt32 (n : Nat) : UInt32 | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___toUInt32) |
| def | Nat.toUInt64 | Nat.toUInt64 (n : Nat) : UInt64 | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___toUInt64) |
| def | Nat.toUSize | Nat.toUSize (n : Nat) : USize | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___toUSize) |
| def | Nat.toInt8 | Nat.toInt8 (n : Nat) : Int8 | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___toInt8) |
| def | Nat.toInt16 | Nat.toInt16 (n : Nat) : Int16 | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___toInt16) |
| def | Nat.toInt32 | Nat.toInt32 (n : Nat) : Int32 | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___toInt32) |
| def | Nat.toInt64 | Nat.toInt64 (n : Nat) : Int64 | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___toInt64) |
| def | Nat.toISize | Nat.toISize (n : Nat) : ISize | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___toISize) |
| def | Nat.toFloat | Nat.toFloat (n : Nat) : Float | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___toFloat) |
| def | Nat.toFloat32 | Nat.toFloat32 (n : Nat) : Float32 | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___toFloat32) |
| def | Nat.isValidChar | Nat.isValidChar (n : Nat) : Prop | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___isValidChar) |
| def | Nat.repr | Nat.repr (n : Nat) : String | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___repr) |
| def | Nat.toDigits | Nat.toDigits (base n : Nat) : List Char | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___toDigits) |
| def | Nat.digitChar | Nat.digitChar (n : Nat) : Char | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___digitChar) |
| def | Nat.toSubscriptString | Nat.toSubscriptString (n : Nat) : String | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___toSubscriptString) |
| def | Nat.toSuperscriptString | Nat.toSuperscriptString (n : Nat) : String | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___toSuperscriptString) |
| def | Nat.toSuperDigits | Nat.toSuperDigits (n : Nat) : List Char | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___toSuperDigits) |
| def | Nat.toSubDigits | Nat.toSubDigits (n : Nat) : List Char | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___toSubDigits) |
| def | Nat.subDigitChar | Nat.subDigitChar (n : Nat) : Char | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___subDigitChar) |
| def | Nat.superDigitChar | Nat.superDigitChar (n : Nat) : Char | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___superDigitChar) |
| def | Nat.recAux | Nat.recAux.{u} {motive : Nat → Sort u} (zero : motive 0) (succ : (n : Nat) → motive n → motive (n + 1)) (t : Nat) : motive t | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___recAux) |
| def | Nat.casesAuxOn | Nat.casesAuxOn.{u} {motive : Nat → Sort u} (t : Nat) (zero : motive 0) (succ : (n : Nat) → motive (n + 1)) : motive t | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___casesAuxOn) |
| def | Nat.strongRecOn | Nat.strongRecOn.{u} {motive : Nat → Sort u} (n : Nat) (ind : (n : Nat) → ((m : Nat) → m < n → motive m) → motive n) : motive n | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___strongRecOn) |
| def | Nat.caseStrongRecOn | Nat.caseStrongRecOn.{u} {motive : Nat → Sort u} (a : Nat) (zero : motive 0) (ind : (n : Nat) → ((m : Nat) → m ≤ n → motive m) → motive n.succ) : motive a | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___caseStrongRecOn) |
| def | Nat.div.inductionOn | Nat.div.inductionOn.{u} {motive : Nat → Nat → Sort u} (x y : Nat) (ind : (x y : Nat) → 0 < y ∧ y ≤ x → motive (x - y) y → motive x y) (base : (x y : Nat) → ¬(0  … | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___div___inductionOn) |
| def | Nat.div2Induction | Nat.div2Induction.{u} {motive : Nat → Sort u} (n : Nat) (ind : (n : Nat) → (n > 0 → motive (n / 2)) → motive n) : motive n | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___div2Induction) |
| def | Nat.mod.inductionOn | Nat.mod.inductionOn.{u} {motive : Nat → Nat → Sort u} (x y : Nat) (ind : (x y : Nat) → 0 < y ∧ y ≤ x → motive (x - y) y → motive x y) (base : (x y : Nat) → ¬(0  … | [Reference](pages/Basic-Types/Natural-Numbers/index.md#Nat___mod___inductionOn) |
| inductive type | Int | Int : Type | [Reference](pages/Basic-Types/Integers/index.md#Int___ofNat) |
| syntax | Negative Successor |  | [Reference](pages/Basic-Types/Integers/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Int.sign | Int.sign : Int → Int | [Reference](pages/Basic-Types/Integers/index.md#Int___sign) |
| def | Int.natAbs | Int.natAbs (m : Int) : Nat | [Reference](pages/Basic-Types/Integers/index.md#Int___natAbs) |
| def | Int.toNat | Int.toNat : Int → Nat | [Reference](pages/Basic-Types/Integers/index.md#Int___toNat) |
| def | Int.toNat? | Int.toNat? : Int → Option Nat | [Reference](pages/Basic-Types/Integers/index.md#Int___toNat___) |
| def | Int.toISize | Int.toISize (i : Int) : ISize | [Reference](pages/Basic-Types/Integers/index.md#Int___toISize) |
| def | Int.toInt8 | Int.toInt8 (i : Int) : Int8 | [Reference](pages/Basic-Types/Integers/index.md#Int___toInt8) |
| def | Int.toInt16 | Int.toInt16 (i : Int) : Int16 | [Reference](pages/Basic-Types/Integers/index.md#Int___toInt16) |
| def | Int.toInt32 | Int.toInt32 (i : Int) : Int32 | [Reference](pages/Basic-Types/Integers/index.md#Int___toInt32) |
| def | Int.toInt64 | Int.toInt64 (i : Int) : Int64 | [Reference](pages/Basic-Types/Integers/index.md#Int___toInt64) |
| def | Int.repr | Int.repr : Int → String | [Reference](pages/Basic-Types/Integers/index.md#Int___repr) |
| def | Int.add | Int.add (m n : Int) : Int | [Reference](pages/Basic-Types/Integers/index.md#Int___add) |
| def | Int.sub | Int.sub (m n : Int) : Int | [Reference](pages/Basic-Types/Integers/index.md#Int___sub) |
| def | Int.subNatNat | Int.subNatNat (m n : Nat) : Int | [Reference](pages/Basic-Types/Integers/index.md#Int___subNatNat) |
| def | Int.neg | Int.neg (n : Int) : Int | [Reference](pages/Basic-Types/Integers/index.md#Int___neg) |
| def | Int.negOfNat | Int.negOfNat : Nat → Int | [Reference](pages/Basic-Types/Integers/index.md#Int___negOfNat) |
| def | Int.mul | Int.mul (m n : Int) : Int | [Reference](pages/Basic-Types/Integers/index.md#Int___mul) |
| def | Int.pow | Int.pow : Int → Nat → Int | [Reference](pages/Basic-Types/Integers/index.md#Int___pow) |
| def | Int.gcd | Int.gcd (m n : Int) : Nat | [Reference](pages/Basic-Types/Integers/index.md#Int___gcd) |
| def | Int.lcm | Int.lcm (m n : Int) : Nat | [Reference](pages/Basic-Types/Integers/index.md#Int___lcm) |
| def | Int.ediv | Int.ediv : Int → Int → Int | [Reference](pages/Basic-Types/Integers/index.md#Int___ediv) |
| def | Int.emod | Int.emod : Int → Int → Int | [Reference](pages/Basic-Types/Integers/index.md#Int___emod) |
| def | Int.tdiv | Int.tdiv : Int → Int → Int | [Reference](pages/Basic-Types/Integers/index.md#Int___tdiv) |
| def | Int.tmod | Int.tmod : Int → Int → Int | [Reference](pages/Basic-Types/Integers/index.md#Int___tmod) |
| def | Int.bdiv | Int.bdiv (x : Int) (m : Nat) : Int | [Reference](pages/Basic-Types/Integers/index.md#Int___bdiv) |
| def | Int.bmod | Int.bmod (x : Int) (m : Nat) : Int | [Reference](pages/Basic-Types/Integers/index.md#Int___bmod) |
| def | Int.fdiv | Int.fdiv : Int → Int → Int | [Reference](pages/Basic-Types/Integers/index.md#Int___fdiv) |
| def | Int.fmod | Int.fmod : Int → Int → Int | [Reference](pages/Basic-Types/Integers/index.md#Int___fmod) |
| def | Int.not | Int.not : Int → Int | [Reference](pages/Basic-Types/Integers/index.md#Int___not) |
| def | Int.shiftRight | Int.shiftRight : Int → Nat → Int | [Reference](pages/Basic-Types/Integers/index.md#Int___shiftRight) |
| def | Int.le | Int.le (a b : Int) : Prop | [Reference](pages/Basic-Types/Integers/index.md#Int___le) |
| def | Int.lt | Int.lt (a b : Int) : Prop | [Reference](pages/Basic-Types/Integers/index.md#Int___lt) |
| def | Int.decEq | Int.decEq (a b : Int) : Decidable (a = b) | [Reference](pages/Basic-Types/Integers/index.md#Int___decEq) |
| structure | Fin | Fin (n : Nat) : Type | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___mk) |
| def | Fin.last | Fin.last (n : Nat) : Fin (n + 1) | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___last) |
| def | Fin.succ | Fin.succ {n : Nat} : Fin n → Fin (n + 1) | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___succ) |
| def | Fin.pred | Fin.pred {n : Nat} (i : Fin (n + 1)) (h : i ≠ 0) : Fin n | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___pred) |
| def | Fin.add | Fin.add {n : Nat} : Fin n → Fin n → Fin n | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___add) |
| def | Fin.natAdd | Fin.natAdd {m : Nat} (n : Nat) (i : Fin m) : Fin (n + m) | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___natAdd) |
| def | Fin.addNat | Fin.addNat {n : Nat} (i : Fin n) (m : Nat) : Fin (n + m) | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___addNat) |
| def | Fin.mul | Fin.mul {n : Nat} : Fin n → Fin n → Fin n | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___mul) |
| def | Fin.sub | Fin.sub {n : Nat} : Fin n → Fin n → Fin n | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___sub) |
| def | Fin.subNat | Fin.subNat {n : Nat} (m : Nat) (i : Fin (n + m)) (h : m ≤ ↑i) : Fin n | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___subNat) |
| def | Fin.div | Fin.div {n : Nat} : Fin n → Fin n → Fin n | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___div) |
| def | Fin.mod | Fin.mod {n : Nat} : Fin n → Fin n → Fin n | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___mod) |
| def | Fin.modn | Fin.modn {n : Nat} : Fin n → Nat → Fin n | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___modn) |
| def | Fin.log2 | Fin.log2 {m : Nat} (n : Fin m) : Fin m | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___log2) |
| def | Fin.shiftLeft | Fin.shiftLeft {n : Nat} : Fin n → Fin n → Fin n | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___shiftLeft) |
| def | Fin.shiftRight | Fin.shiftRight {n : Nat} : Fin n → Fin n → Fin n | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___shiftRight) |
| def | Fin.land | Fin.land {n : Nat} : Fin n → Fin n → Fin n | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___land) |
| def | Fin.lor | Fin.lor {n : Nat} : Fin n → Fin n → Fin n | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___lor) |
| def | Fin.xor | Fin.xor {n : Nat} : Fin n → Fin n → Fin n | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___xor) |
| def | Fin.toNat | Fin.toNat {n : Nat} (i : Fin n) : Nat | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___toNat) |
| def | Fin.ofNat | Fin.ofNat (n : Nat) [NeZero n] (a : Nat) : Fin n | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___ofNat) |
| def | Fin.cast | Fin.cast {n m : Nat} (eq : n = m) (i : Fin n) : Fin m | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___cast) |
| def | Fin.castLT | Fin.castLT {n m : Nat} (i : Fin m) (h : ↑i < n) : Fin n | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___castLT) |
| def | Fin.castLE | Fin.castLE {n m : Nat} (h : n ≤ m) (i : Fin n) : Fin m | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___castLE) |
| def | Fin.castAdd | Fin.castAdd {n : Nat} (m : Nat) : Fin n → Fin (n + m) | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___castAdd) |
| def | Fin.castSucc | Fin.castSucc {n : Nat} : Fin n → Fin (n + 1) | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___castSucc) |
| def | Fin.rev | Fin.rev {n : Nat} (i : Fin n) : Fin n | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___rev) |
| def | Fin.elim0 | Fin.elim0.{u} {α : Sort u} : Fin 0 → α | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___elim0) |
| def | Fin.foldr | Fin.foldr.{u_1} {α : Sort u_1} (n : Nat) (f : Fin n → α → α) (init : α) : α | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___foldr) |
| def | Fin.foldrM | Fin.foldrM.{u_1, u_2} {m : Type u_1 → Type u_2} {α : Type u_1} [Monad m] (n : Nat) (f : Fin n → α → m α) (init : α) : m α | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___foldrM) |
| def | Fin.foldl | Fin.foldl.{u_1} {α : Sort u_1} (n : Nat) (f : α → Fin n → α) (init : α) : α | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___foldl) |
| def | Fin.foldlM | Fin.foldlM.{u_1, u_2} {m : Type u_1 → Type u_2} {α : Type u_1} [Monad m] (n : Nat) (f : α → Fin n → m α) (init : α) : m α | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___foldlM) |
| def | Fin.hIterate | Fin.hIterate.{u_1} (P : Nat → Sort u_1) {n : Nat} (init : P 0) (f : (i : Fin n) → P ↑i → P (↑i + 1)) : P n | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___hIterate) |
| def | Fin.hIterateFrom | Fin.hIterateFrom.{u_1} (P : Nat → Sort u_1) {n : Nat} (f : (i : Fin n) → P ↑i → P (↑i + 1)) (i : Nat) (ubnd : i ≤ n) (a : P i) : P n | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___hIterateFrom) |
| def | Fin.induction | Fin.induction.{u_1} {n : Nat} {motive : Fin (n + 1) → Sort u_1} (zero : motive 0) (succ : (i : Fin n) → motive i.castSucc → motive i.succ) (i : Fin (n + 1)) : m … | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___induction) |
| def | Fin.inductionOn | Fin.inductionOn.{u_1} {n : Nat} (i : Fin (n + 1)) {motive : Fin (n + 1) → Sort u_1} (zero : motive 0) (succ : (i : Fin n) → motive i.castSucc → motive i.succ) : … | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___inductionOn) |
| def | Fin.reverseInduction | Fin.reverseInduction.{u_1} {n : Nat} {motive : Fin (n + 1) → Sort u_1} (last : motive (Fin.last n)) (cast : (i : Fin n) → motive i.succ → motive i.castSucc) (i  … | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___reverseInduction) |
| def | Fin.cases | Fin.cases.{u_1} {n : Nat} {motive : Fin (n + 1) → Sort u_1} (zero : motive 0) (succ : (i : Fin n) → motive i.succ) (i : Fin (n + 1)) : motive i | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___cases) |
| def | Fin.lastCases | Fin.lastCases.{u_1} {n : Nat} {motive : Fin (n + 1) → Sort u_1} (last : motive (Fin.last n)) (cast : (i : Fin n) → motive i.castSucc) (i : Fin (n + 1)) : motive … | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___lastCases) |
| def | Fin.addCases | Fin.addCases.{u} {m n : Nat} {motive : Fin (m + n) → Sort u} (left : (i : Fin m) → motive (Fin.castAdd n i)) (right : (i : Fin n) → motive (Fin.natAdd m i)) (i  … | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___addCases) |
| def | Fin.succRec | Fin.succRec.{u_1} {motive : (n : Nat) → Fin n → Sort u_1} (zero : (n : Nat) → motive n.succ 0) (succ : (n : Nat) → (i : Fin n) → motive n i → motive n.succ i.su … | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___succRec) |
| def | Fin.succRecOn | Fin.succRecOn.{u_1} {n : Nat} (i : Fin n) {motive : (n : Nat) → Fin n → Sort u_1} (zero : (n : Nat) → motive (n + 1) 0) (succ : (n : Nat) → (i : Fin n) → motive … | [Reference](pages/Basic-Types/Finite-Natural-Numbers/index.md#Fin___succRecOn) |
| structure | USize | USize : Type | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___ofBitVec) |
| structure | UInt8 | UInt8 : Type | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___ofBitVec) |
| structure | UInt16 | UInt16 : Type | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___ofBitVec) |
| structure | UInt32 | UInt32 : Type | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___ofBitVec) |
| structure | UInt64 | UInt64 : Type | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___ofBitVec) |
| structure | ISize | ISize : Type | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___ofUSize) |
| structure | Int8 | Int8 : Type | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___ofUInt8) |
| structure | Int16 | Int16 : Type | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___ofUInt16) |
| structure | Int32 | Int32 : Type | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___ofUInt32) |
| structure | Int64 | Int64 : Type | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___ofUInt64) |
| def | USize.size | USize.size : Nat | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___size) |
| def | ISize.size | ISize.size : Nat | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___size) |
| def | UInt8.size | UInt8.size : Nat | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___size) |
| def | Int8.size | Int8.size : Nat | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___size) |
| def | UInt16.size | UInt16.size : Nat | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___size) |
| def | Int16.size | Int16.size : Nat | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___size) |
| def | UInt32.size | UInt32.size : Nat | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___size) |
| def | Int32.size | Int32.size : Nat | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___size) |
| def | UInt64.size | UInt64.size : Nat | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___size) |
| def | Int64.size | Int64.size : Nat | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___size) |
| def | ISize.minValue | ISize.minValue : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___minValue) |
| def | ISize.maxValue | ISize.maxValue : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___maxValue) |
| def | Int8.minValue | Int8.minValue : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___minValue) |
| def | Int8.maxValue | Int8.maxValue : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___maxValue) |
| def | Int16.minValue | Int16.minValue : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___minValue) |
| def | Int16.maxValue | Int16.maxValue : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___maxValue) |
| def | Int32.minValue | Int32.minValue : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___minValue) |
| def | Int32.maxValue | Int32.maxValue : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___maxValue) |
| def | Int64.minValue | Int64.minValue : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___minValue) |
| def | Int64.maxValue | Int64.maxValue : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___maxValue) |
| def | ISize.toInt | ISize.toInt (i : ISize) : Int | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___toInt) |
| def | Int8.toInt | Int8.toInt (i : Int8) : Int | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___toInt) |
| def | Int16.toInt | Int16.toInt (i : Int16) : Int | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___toInt) |
| def | Int32.toInt | Int32.toInt (i : Int32) : Int | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___toInt) |
| def | Int64.toInt | Int64.toInt (i : Int64) : Int | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___toInt) |
| def | ISize.ofInt | ISize.ofInt (i : Int) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___ofInt) |
| def | Int8.ofInt | Int8.ofInt (i : Int) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___ofInt) |
| def | Int16.ofInt | Int16.ofInt (i : Int) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___ofInt) |
| def | Int32.ofInt | Int32.ofInt (i : Int) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___ofInt) |
| def | Int64.ofInt | Int64.ofInt (i : Int) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___ofInt) |
| def | ISize.ofIntClamp | ISize.ofIntClamp (i : Int) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___ofIntClamp) |
| def | Int8.ofIntClamp | Int8.ofIntClamp (i : Int) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___ofIntClamp) |
| def | Int16.ofIntClamp | Int16.ofIntClamp (i : Int) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___ofIntClamp) |
| def | Int32.ofIntClamp | Int32.ofIntClamp (i : Int) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___ofIntClamp) |
| def | Int64.ofIntClamp | Int64.ofIntClamp (i : Int) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___ofIntClamp) |
| def | ISize.ofIntLE | ISize.ofIntLE (i : Int) (_hl : ISize.minValue.toInt ≤ i) (_hr : i ≤ ISize.maxValue.toInt) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___ofIntLE) |
| def | Int8.ofIntLE | Int8.ofIntLE (i : Int) (_hl : Int8.minValue.toInt ≤ i) (_hr : i ≤ Int8.maxValue.toInt) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___ofIntLE) |
| def | Int16.ofIntLE | Int16.ofIntLE (i : Int) (_hl : Int16.minValue.toInt ≤ i) (_hr : i ≤ Int16.maxValue.toInt) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___ofIntLE) |
| def | Int32.ofIntLE | Int32.ofIntLE (i : Int) (_hl : Int32.minValue.toInt ≤ i) (_hr : i ≤ Int32.maxValue.toInt) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___ofIntLE) |
| def | Int64.ofIntLE | Int64.ofIntLE (i : Int) (_hl : Int64.minValue.toInt ≤ i) (_hr : i ≤ Int64.maxValue.toInt) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___ofIntLE) |
| def | USize.ofNat | USize.ofNat (n : Nat) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___ofNat) |
| def | ISize.ofNat | ISize.ofNat (n : Nat) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___ofNat) |
| def | UInt8.ofNat | UInt8.ofNat (n : Nat) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___ofNat) |
| def | Int8.ofNat | Int8.ofNat (n : Nat) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___ofNat) |
| def | UInt16.ofNat | UInt16.ofNat (n : Nat) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___ofNat) |
| def | Int16.ofNat | Int16.ofNat (n : Nat) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___ofNat) |
| def | UInt32.ofNat | UInt32.ofNat (n : Nat) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___ofNat) |
| def | Int32.ofNat | Int32.ofNat (n : Nat) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___ofNat) |
| def | UInt64.ofNat | UInt64.ofNat (n : Nat) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___ofNat) |
| def | Int64.ofNat | Int64.ofNat (n : Nat) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___ofNat) |
| def | USize.ofNat32 | USize.ofNat32 (n : Nat) (h : n < 4294967296) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___ofNat32) |
| def | USize.ofNatLT | USize.ofNatLT (n : Nat) (h : n < USize.size) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___ofNatLT) |
| def | UInt8.ofNatLT | UInt8.ofNatLT (n : Nat) (h : n < UInt8.size) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___ofNatLT) |
| def | UInt16.ofNatLT | UInt16.ofNatLT (n : Nat) (h : n < UInt16.size) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___ofNatLT) |
| def | UInt32.ofNatLT | UInt32.ofNatLT (n : Nat) (h : n < UInt32.size) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___ofNatLT) |
| def | UInt64.ofNatLT | UInt64.ofNatLT (n : Nat) (h : n < UInt64.size) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___ofNatLT) |
| def | USize.ofNatClamp | USize.ofNatClamp (n : Nat) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___ofNatClamp) |
| def | UInt8.ofNatClamp | UInt8.ofNatClamp (n : Nat) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___ofNatClamp) |
| def | UInt16.ofNatClamp | UInt16.ofNatClamp (n : Nat) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___ofNatClamp) |
| def | UInt32.ofNatClamp | UInt32.ofNatClamp (n : Nat) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___ofNatClamp) |
| def | UInt64.ofNatClamp | UInt64.ofNatClamp (n : Nat) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___ofNatClamp) |
| def | USize.toNat | USize.toNat (n : USize) : Nat | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___toNat) |
| def | ISize.toNatClampNeg | ISize.toNatClampNeg (i : ISize) : Nat | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___toNatClampNeg) |
| def | UInt8.toNat | UInt8.toNat (n : UInt8) : Nat | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___toNat) |
| def | Int8.toNatClampNeg | Int8.toNatClampNeg (i : Int8) : Nat | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___toNatClampNeg) |
| def | UInt16.toNat | UInt16.toNat (n : UInt16) : Nat | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___toNat) |
| def | Int16.toNatClampNeg | Int16.toNatClampNeg (i : Int16) : Nat | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___toNatClampNeg) |
| def | UInt32.toNat | UInt32.toNat (n : UInt32) : Nat | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___toNat) |
| def | Int32.toNatClampNeg | Int32.toNatClampNeg (i : Int32) : Nat | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___toNatClampNeg) |
| def | UInt64.toNat | UInt64.toNat (n : UInt64) : Nat | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___toNat) |
| def | Int64.toNatClampNeg | Int64.toNatClampNeg (i : Int64) : Nat | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___toNatClampNeg) |
| def | USize.toUInt8 | USize.toUInt8 (a : USize) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___toUInt8) |
| def | USize.toUInt16 | USize.toUInt16 (a : USize) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___toUInt16) |
| def | USize.toUInt32 | USize.toUInt32 (a : USize) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___toUInt32) |
| def | USize.toUInt64 | USize.toUInt64 (a : USize) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___toUInt64) |
| def | USize.toISize | USize.toISize (i : USize) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___toISize) |
| def | UInt8.toInt8 | UInt8.toInt8 (i : UInt8) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___toInt8) |
| def | UInt8.toUInt16 | UInt8.toUInt16 (a : UInt8) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___toUInt16) |
| def | UInt8.toUInt32 | UInt8.toUInt32 (a : UInt8) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___toUInt32) |
| def | UInt8.toUInt64 | UInt8.toUInt64 (a : UInt8) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___toUInt64) |
| def | UInt8.toUSize | UInt8.toUSize (a : UInt8) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___toUSize) |
| def | UInt16.toUInt8 | UInt16.toUInt8 (a : UInt16) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___toUInt8) |
| def | UInt16.toInt16 | UInt16.toInt16 (i : UInt16) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___toInt16) |
| def | UInt16.toUInt32 | UInt16.toUInt32 (a : UInt16) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___toUInt32) |
| def | UInt16.toUInt64 | UInt16.toUInt64 (a : UInt16) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___toUInt64) |
| def | UInt16.toUSize | UInt16.toUSize (a : UInt16) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___toUSize) |
| def | UInt32.toUInt8 | UInt32.toUInt8 (a : UInt32) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___toUInt8) |
| def | UInt32.toUInt16 | UInt32.toUInt16 (a : UInt32) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___toUInt16) |
| def | UInt32.toInt32 | UInt32.toInt32 (i : UInt32) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___toInt32) |
| def | UInt32.toUInt64 | UInt32.toUInt64 (a : UInt32) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___toUInt64) |
| def | UInt32.toUSize | UInt32.toUSize (a : UInt32) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___toUSize) |
| def | UInt64.toUInt8 | UInt64.toUInt8 (a : UInt64) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___toUInt8) |
| def | UInt64.toUInt16 | UInt64.toUInt16 (a : UInt64) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___toUInt16) |
| def | UInt64.toUInt32 | UInt64.toUInt32 (a : UInt64) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___toUInt32) |
| def | UInt64.toInt64 | UInt64.toInt64 (i : UInt64) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___toInt64) |
| def | UInt64.toUSize | UInt64.toUSize (a : UInt64) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___toUSize) |
| def | ISize.toInt8 | ISize.toInt8 (a : ISize) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___toInt8) |
| def | ISize.toInt16 | ISize.toInt16 (a : ISize) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___toInt16) |
| def | ISize.toInt32 | ISize.toInt32 (a : ISize) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___toInt32) |
| def | ISize.toInt64 | ISize.toInt64 (a : ISize) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___toInt64) |
| def | Int8.toInt16 | Int8.toInt16 (a : Int8) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___toInt16) |
| def | Int8.toInt32 | Int8.toInt32 (a : Int8) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___toInt32) |
| def | Int8.toInt64 | Int8.toInt64 (a : Int8) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___toInt64) |
| def | Int8.toISize | Int8.toISize (a : Int8) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___toISize) |
| def | Int16.toInt8 | Int16.toInt8 (a : Int16) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___toInt8) |
| def | Int16.toInt32 | Int16.toInt32 (a : Int16) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___toInt32) |
| def | Int16.toInt64 | Int16.toInt64 (a : Int16) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___toInt64) |
| def | Int16.toISize | Int16.toISize (a : Int16) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___toISize) |
| def | Int32.toInt8 | Int32.toInt8 (a : Int32) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___toInt8) |
| def | Int32.toInt16 | Int32.toInt16 (a : Int32) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___toInt16) |
| def | Int32.toInt64 | Int32.toInt64 (a : Int32) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___toInt64) |
| def | Int32.toISize | Int32.toISize (a : Int32) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___toISize) |
| def | Int64.toInt8 | Int64.toInt8 (a : Int64) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___toInt8) |
| def | Int64.toInt16 | Int64.toInt16 (a : Int64) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___toInt16) |
| def | Int64.toInt32 | Int64.toInt32 (a : Int64) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___toInt32) |
| def | Int64.toISize | Int64.toISize (a : Int64) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___toISize) |
| def | ISize.toFloat | ISize.toFloat (n : ISize) : Float | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___toFloat) |
| def | ISize.toFloat32 | ISize.toFloat32 (n : ISize) : Float32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___toFloat32) |
| def | Int8.toFloat | Int8.toFloat (n : Int8) : Float | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___toFloat) |
| def | Int8.toFloat32 | Int8.toFloat32 (n : Int8) : Float32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___toFloat32) |
| def | Int16.toFloat | Int16.toFloat (n : Int16) : Float | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___toFloat) |
| def | Int16.toFloat32 | Int16.toFloat32 (n : Int16) : Float32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___toFloat32) |
| def | Int32.toFloat | Int32.toFloat (n : Int32) : Float | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___toFloat) |
| def | Int32.toFloat32 | Int32.toFloat32 (n : Int32) : Float32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___toFloat32) |
| def | Int64.toFloat | Int64.toFloat (n : Int64) : Float | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___toFloat) |
| def | Int64.toFloat32 | Int64.toFloat32 (n : Int64) : Float32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___toFloat32) |
| def | USize.toFloat | USize.toFloat (n : USize) : Float | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___toFloat) |
| def | USize.toFloat32 | USize.toFloat32 (n : USize) : Float32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___toFloat32) |
| def | UInt8.toFloat | UInt8.toFloat (n : UInt8) : Float | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___toFloat) |
| def | UInt8.toFloat32 | UInt8.toFloat32 (n : UInt8) : Float32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___toFloat32) |
| def | UInt16.toFloat | UInt16.toFloat (n : UInt16) : Float | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___toFloat) |
| def | UInt16.toFloat32 | UInt16.toFloat32 (n : UInt16) : Float32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___toFloat32) |
| def | UInt32.toFloat | UInt32.toFloat (n : UInt32) : Float | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___toFloat) |
| def | UInt32.toFloat32 | UInt32.toFloat32 (n : UInt32) : Float32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___toFloat32) |
| def | UInt64.toFloat | UInt64.toFloat (n : UInt64) : Float | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___toFloat) |
| def | UInt64.toFloat32 | UInt64.toFloat32 (n : UInt64) : Float32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___toFloat32) |
| def | ISize.toBitVec | ISize.toBitVec (x : ISize) : BitVec System.Platform.numBits | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___toBitVec) |
| def | ISize.ofBitVec | ISize.ofBitVec (b : BitVec System.Platform.numBits) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___ofBitVec) |
| def | Int8.toBitVec | Int8.toBitVec (x : Int8) : BitVec 8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___toBitVec) |
| def | Int8.ofBitVec | Int8.ofBitVec (b : BitVec 8) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___ofBitVec) |
| def | Int16.toBitVec | Int16.toBitVec (x : Int16) : BitVec 16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___toBitVec) |
| def | Int16.ofBitVec | Int16.ofBitVec (b : BitVec 16) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___ofBitVec) |
| def | Int32.toBitVec | Int32.toBitVec (x : Int32) : BitVec 32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___toBitVec) |
| def | Int32.ofBitVec | Int32.ofBitVec (b : BitVec 32) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___ofBitVec) |
| def | Int64.toBitVec | Int64.toBitVec (x : Int64) : BitVec 64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___toBitVec) |
| def | Int64.ofBitVec | Int64.ofBitVec (b : BitVec 64) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___ofBitVec) |
| def | USize.toFin | USize.toFin (x : USize) : Fin USize.size | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___toFin) |
| def | UInt8.toFin | UInt8.toFin (x : UInt8) : Fin UInt8.size | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___toFin) |
| def | UInt16.toFin | UInt16.toFin (x : UInt16) : Fin UInt16.size | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___toFin) |
| def | UInt32.toFin | UInt32.toFin (x : UInt32) : Fin UInt32.size | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___toFin) |
| def | UInt64.toFin | UInt64.toFin (x : UInt64) : Fin UInt64.size | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___toFin) |
| def | USize.ofFin | USize.ofFin (a : Fin USize.size) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___ofFin) |
| def | UInt8.ofFin | UInt8.ofFin (a : Fin UInt8.size) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___ofFin) |
| def | UInt16.ofFin | UInt16.ofFin (a : Fin UInt16.size) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___ofFin) |
| def | UInt32.ofFin | UInt32.ofFin (a : Fin UInt32.size) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___ofFin) |
| def | UInt64.ofFin | UInt64.ofFin (a : Fin UInt64.size) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___ofFin) |
| def | USize.repr | USize.repr (n : USize) : String | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___repr) |
| def | UInt32.isValidChar | UInt32.isValidChar (n : UInt32) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___isValidChar) |
| def | USize.le | USize.le (a b : USize) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___le) |
| def | ISize.le | ISize.le (a b : ISize) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___le) |
| def | UInt8.le | UInt8.le (a b : UInt8) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___le) |
| def | Int8.le | Int8.le (a b : Int8) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___le) |
| def | UInt16.le | UInt16.le (a b : UInt16) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___le) |
| def | Int16.le | Int16.le (a b : Int16) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___le) |
| def | UInt32.le | UInt32.le (a b : UInt32) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___le) |
| def | Int32.le | Int32.le (a b : Int32) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___le) |
| def | UInt64.le | UInt64.le (a b : UInt64) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___le) |
| def | Int64.le | Int64.le (a b : Int64) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___le) |
| def | USize.lt | USize.lt (a b : USize) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___lt) |
| def | ISize.lt | ISize.lt (a b : ISize) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___lt) |
| def | UInt8.lt | UInt8.lt (a b : UInt8) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___lt) |
| def | Int8.lt | Int8.lt (a b : Int8) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___lt) |
| def | UInt16.lt | UInt16.lt (a b : UInt16) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___lt) |
| def | Int16.lt | Int16.lt (a b : Int16) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___lt) |
| def | UInt32.lt | UInt32.lt (a b : UInt32) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___lt) |
| def | Int32.lt | Int32.lt (a b : Int32) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___lt) |
| def | UInt64.lt | UInt64.lt (a b : UInt64) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___lt) |
| def | Int64.lt | Int64.lt (a b : Int64) : Prop | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___lt) |
| def | USize.decEq | USize.decEq (a b : USize) : Decidable (a = b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___decEq) |
| def | ISize.decEq | ISize.decEq (a b : ISize) : Decidable (a = b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___decEq) |
| def | UInt8.decEq | UInt8.decEq (a b : UInt8) : Decidable (a = b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___decEq) |
| def | Int8.decEq | Int8.decEq (a b : Int8) : Decidable (a = b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___decEq) |
| def | UInt16.decEq | UInt16.decEq (a b : UInt16) : Decidable (a = b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___decEq) |
| def | Int16.decEq | Int16.decEq (a b : Int16) : Decidable (a = b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___decEq) |
| def | UInt32.decEq | UInt32.decEq (a b : UInt32) : Decidable (a = b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___decEq) |
| def | Int32.decEq | Int32.decEq (a b : Int32) : Decidable (a = b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___decEq) |
| def | UInt64.decEq | UInt64.decEq (a b : UInt64) : Decidable (a = b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___decEq) |
| def | Int64.decEq | Int64.decEq (a b : Int64) : Decidable (a = b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___decEq) |
| def | USize.decLe | USize.decLe (a b : USize) : Decidable (a ≤ b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___decLe) |
| def | ISize.decLe | ISize.decLe (a b : ISize) : Decidable (a ≤ b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___decLe) |
| def | UInt8.decLe | UInt8.decLe (a b : UInt8) : Decidable (a ≤ b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___decLe) |
| def | Int8.decLe | Int8.decLe (a b : Int8) : Decidable (a ≤ b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___decLe) |
| def | UInt16.decLe | UInt16.decLe (a b : UInt16) : Decidable (a ≤ b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___decLe) |
| def | Int16.decLe | Int16.decLe (a b : Int16) : Decidable (a ≤ b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___decLe) |
| def | UInt32.decLe | UInt32.decLe (a b : UInt32) : Decidable (a ≤ b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___decLe) |
| def | Int32.decLe | Int32.decLe (a b : Int32) : Decidable (a ≤ b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___decLe) |
| def | UInt64.decLe | UInt64.decLe (a b : UInt64) : Decidable (a ≤ b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___decLe) |
| def | Int64.decLe | Int64.decLe (a b : Int64) : Decidable (a ≤ b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___decLe) |
| def | USize.decLt | USize.decLt (a b : USize) : Decidable (a < b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___decLt) |
| def | ISize.decLt | ISize.decLt (a b : ISize) : Decidable (a < b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___decLt) |
| def | UInt8.decLt | UInt8.decLt (a b : UInt8) : Decidable (a < b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___decLt) |
| def | Int8.decLt | Int8.decLt (a b : Int8) : Decidable (a < b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___decLt) |
| def | UInt16.decLt | UInt16.decLt (a b : UInt16) : Decidable (a < b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___decLt) |
| def | Int16.decLt | Int16.decLt (a b : Int16) : Decidable (a < b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___decLt) |
| def | UInt32.decLt | UInt32.decLt (a b : UInt32) : Decidable (a < b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___decLt) |
| def | Int32.decLt | Int32.decLt (a b : Int32) : Decidable (a < b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___decLt) |
| def | UInt64.decLt | UInt64.decLt (a b : UInt64) : Decidable (a < b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___decLt) |
| def | Int64.decLt | Int64.decLt (a b : Int64) : Decidable (a < b) | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___decLt) |
| def | ISize.neg | ISize.neg (i : ISize) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___neg) |
| def | Int8.neg | Int8.neg (i : Int8) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___neg) |
| def | Int16.neg | Int16.neg (i : Int16) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___neg) |
| def | Int32.neg | Int32.neg (i : Int32) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___neg) |
| def | Int64.neg | Int64.neg (i : Int64) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___neg) |
| def | USize.neg | USize.neg (a : USize) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___neg) |
| def | UInt8.neg | UInt8.neg (a : UInt8) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___neg) |
| def | UInt16.neg | UInt16.neg (a : UInt16) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___neg) |
| def | UInt32.neg | UInt32.neg (a : UInt32) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___neg) |
| def | UInt64.neg | UInt64.neg (a : UInt64) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___neg) |
| def | USize.add | USize.add (a b : USize) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___add) |
| def | ISize.add | ISize.add (a b : ISize) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___add) |
| def | UInt8.add | UInt8.add (a b : UInt8) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___add) |
| def | Int8.add | Int8.add (a b : Int8) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___add) |
| def | UInt16.add | UInt16.add (a b : UInt16) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___add) |
| def | Int16.add | Int16.add (a b : Int16) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___add) |
| def | UInt32.add | UInt32.add (a b : UInt32) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___add) |
| def | Int32.add | Int32.add (a b : Int32) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___add) |
| def | UInt64.add | UInt64.add (a b : UInt64) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___add) |
| def | Int64.add | Int64.add (a b : Int64) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___add) |
| def | USize.sub | USize.sub (a b : USize) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___sub) |
| def | ISize.sub | ISize.sub (a b : ISize) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___sub) |
| def | UInt8.sub | UInt8.sub (a b : UInt8) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___sub) |
| def | Int8.sub | Int8.sub (a b : Int8) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___sub) |
| def | UInt16.sub | UInt16.sub (a b : UInt16) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___sub) |
| def | Int16.sub | Int16.sub (a b : Int16) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___sub) |
| def | UInt32.sub | UInt32.sub (a b : UInt32) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___sub) |
| def | Int32.sub | Int32.sub (a b : Int32) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___sub) |
| def | UInt64.sub | UInt64.sub (a b : UInt64) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___sub) |
| def | Int64.sub | Int64.sub (a b : Int64) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___sub) |
| def | USize.mul | USize.mul (a b : USize) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___mul) |
| def | ISize.mul | ISize.mul (a b : ISize) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___mul) |
| def | UInt8.mul | UInt8.mul (a b : UInt8) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___mul) |
| def | Int8.mul | Int8.mul (a b : Int8) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___mul) |
| def | UInt16.mul | UInt16.mul (a b : UInt16) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___mul) |
| def | Int16.mul | Int16.mul (a b : Int16) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___mul) |
| def | UInt32.mul | UInt32.mul (a b : UInt32) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___mul) |
| def | Int32.mul | Int32.mul (a b : Int32) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___mul) |
| def | UInt64.mul | UInt64.mul (a b : UInt64) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___mul) |
| def | Int64.mul | Int64.mul (a b : Int64) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___mul) |
| def | USize.div | USize.div (a b : USize) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___div) |
| def | ISize.div | ISize.div (a b : ISize) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___div) |
| def | UInt8.div | UInt8.div (a b : UInt8) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___div) |
| def | Int8.div | Int8.div (a b : Int8) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___div) |
| def | UInt16.div | UInt16.div (a b : UInt16) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___div) |
| def | Int16.div | Int16.div (a b : Int16) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___div) |
| def | UInt32.div | UInt32.div (a b : UInt32) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___div) |
| def | Int32.div | Int32.div (a b : Int32) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___div) |
| def | UInt64.div | UInt64.div (a b : UInt64) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___div) |
| def | Int64.div | Int64.div (a b : Int64) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___div) |
| def | USize.mod | USize.mod (a b : USize) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___mod) |
| def | ISize.mod | ISize.mod (a b : ISize) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___mod) |
| def | UInt8.mod | UInt8.mod (a b : UInt8) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___mod) |
| def | Int8.mod | Int8.mod (a b : Int8) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___mod) |
| def | UInt16.mod | UInt16.mod (a b : UInt16) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___mod) |
| def | Int16.mod | Int16.mod (a b : Int16) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___mod) |
| def | UInt32.mod | UInt32.mod (a b : UInt32) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___mod) |
| def | Int32.mod | Int32.mod (a b : Int32) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___mod) |
| def | UInt64.mod | UInt64.mod (a b : UInt64) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___mod) |
| def | Int64.mod | Int64.mod (a b : Int64) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___mod) |
| def | USize.log2 | USize.log2 (a : USize) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___log2) |
| def | UInt8.log2 | UInt8.log2 (a : UInt8) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___log2) |
| def | UInt16.log2 | UInt16.log2 (a : UInt16) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___log2) |
| def | UInt32.log2 | UInt32.log2 (a : UInt32) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___log2) |
| def | UInt64.log2 | UInt64.log2 (a : UInt64) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___log2) |
| def | ISize.abs | ISize.abs (a : ISize) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___abs) |
| def | Int8.abs | Int8.abs (a : Int8) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___abs) |
| def | Int16.abs | Int16.abs (a : Int16) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___abs) |
| def | Int32.abs | Int32.abs (a : Int32) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___abs) |
| def | Int64.abs | Int64.abs (a : Int64) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___abs) |
| def | USize.land | USize.land (a b : USize) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___land) |
| def | ISize.land | ISize.land (a b : ISize) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___land) |
| def | UInt8.land | UInt8.land (a b : UInt8) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___land) |
| def | Int8.land | Int8.land (a b : Int8) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___land) |
| def | UInt16.land | UInt16.land (a b : UInt16) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___land) |
| def | Int16.land | Int16.land (a b : Int16) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___land) |
| def | UInt32.land | UInt32.land (a b : UInt32) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___land) |
| def | Int32.land | Int32.land (a b : Int32) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___land) |
| def | UInt64.land | UInt64.land (a b : UInt64) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___land) |
| def | Int64.land | Int64.land (a b : Int64) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___land) |
| def | USize.lor | USize.lor (a b : USize) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___lor) |
| def | ISize.lor | ISize.lor (a b : ISize) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___lor) |
| def | UInt8.lor | UInt8.lor (a b : UInt8) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___lor) |
| def | Int8.lor | Int8.lor (a b : Int8) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___lor) |
| def | UInt16.lor | UInt16.lor (a b : UInt16) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___lor) |
| def | Int16.lor | Int16.lor (a b : Int16) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___lor) |
| def | UInt32.lor | UInt32.lor (a b : UInt32) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___lor) |
| def | Int32.lor | Int32.lor (a b : Int32) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___lor) |
| def | UInt64.lor | UInt64.lor (a b : UInt64) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___lor) |
| def | Int64.lor | Int64.lor (a b : Int64) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___lor) |
| def | USize.xor | USize.xor (a b : USize) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___xor) |
| def | ISize.xor | ISize.xor (a b : ISize) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___xor) |
| def | UInt8.xor | UInt8.xor (a b : UInt8) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___xor) |
| def | Int8.xor | Int8.xor (a b : Int8) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___xor) |
| def | UInt16.xor | UInt16.xor (a b : UInt16) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___xor) |
| def | Int16.xor | Int16.xor (a b : Int16) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___xor) |
| def | UInt32.xor | UInt32.xor (a b : UInt32) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___xor) |
| def | Int32.xor | Int32.xor (a b : Int32) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___xor) |
| def | UInt64.xor | UInt64.xor (a b : UInt64) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___xor) |
| def | Int64.xor | Int64.xor (a b : Int64) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___xor) |
| def | USize.complement | USize.complement (a : USize) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___complement) |
| def | ISize.complement | ISize.complement (a : ISize) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___complement) |
| def | UInt8.complement | UInt8.complement (a : UInt8) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___complement) |
| def | Int8.complement | Int8.complement (a : Int8) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___complement) |
| def | UInt16.complement | UInt16.complement (a : UInt16) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___complement) |
| def | Int16.complement | Int16.complement (a : Int16) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___complement) |
| def | UInt32.complement | UInt32.complement (a : UInt32) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___complement) |
| def | Int32.complement | Int32.complement (a : Int32) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___complement) |
| def | UInt64.complement | UInt64.complement (a : UInt64) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___complement) |
| def | Int64.complement | Int64.complement (a : Int64) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___complement) |
| def | USize.shiftLeft | USize.shiftLeft (a b : USize) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___shiftLeft) |
| def | ISize.shiftLeft | ISize.shiftLeft (a b : ISize) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___shiftLeft) |
| def | UInt8.shiftLeft | UInt8.shiftLeft (a b : UInt8) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___shiftLeft) |
| def | Int8.shiftLeft | Int8.shiftLeft (a b : Int8) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___shiftLeft) |
| def | UInt16.shiftLeft | UInt16.shiftLeft (a b : UInt16) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___shiftLeft) |
| def | Int16.shiftLeft | Int16.shiftLeft (a b : Int16) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___shiftLeft) |
| def | UInt32.shiftLeft | UInt32.shiftLeft (a b : UInt32) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___shiftLeft) |
| def | Int32.shiftLeft | Int32.shiftLeft (a b : Int32) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___shiftLeft) |
| def | UInt64.shiftLeft | UInt64.shiftLeft (a b : UInt64) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___shiftLeft) |
| def | Int64.shiftLeft | Int64.shiftLeft (a b : Int64) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___shiftLeft) |
| def | USize.shiftRight | USize.shiftRight (a b : USize) : USize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#USize___shiftRight) |
| def | ISize.shiftRight | ISize.shiftRight (a b : ISize) : ISize | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#ISize___shiftRight) |
| def | UInt8.shiftRight | UInt8.shiftRight (a b : UInt8) : UInt8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt8___shiftRight) |
| def | Int8.shiftRight | Int8.shiftRight (a b : Int8) : Int8 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int8___shiftRight) |
| def | UInt16.shiftRight | UInt16.shiftRight (a b : UInt16) : UInt16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt16___shiftRight) |
| def | Int16.shiftRight | Int16.shiftRight (a b : Int16) : Int16 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int16___shiftRight) |
| def | UInt32.shiftRight | UInt32.shiftRight (a b : UInt32) : UInt32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt32___shiftRight) |
| def | Int32.shiftRight | Int32.shiftRight (a b : Int32) : Int32 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int32___shiftRight) |
| def | UInt64.shiftRight | UInt64.shiftRight (a b : UInt64) : UInt64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#UInt64___shiftRight) |
| def | Int64.shiftRight | Int64.shiftRight (a b : Int64) : Int64 | [Reference](pages/Basic-Types/Fixed-Precision-Integers/index.md#Int64___shiftRight) |
| structure | BitVec | BitVec (w : Nat) : Type | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___ofFin) |
| syntax | Fixed-Width Bitvector Literals |  | [Reference](pages/Basic-Types/Bitvectors/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Bounded Bitvector Literals |  | [Reference](pages/Basic-Types/Bitvectors/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | BitVec.intMax | BitVec.intMax (w : Nat) : BitVec w | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___intMax) |
| def | BitVec.intMin | BitVec.intMin (w : Nat) : BitVec w | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___intMin) |
| def | BitVec.fill | BitVec.fill (w : Nat) (b : Bool) : BitVec w | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___fill) |
| def | BitVec.zero | BitVec.zero (n : Nat) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___zero) |
| def | BitVec.allOnes | BitVec.allOnes (n : Nat) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___allOnes) |
| def | BitVec.twoPow | BitVec.twoPow (w i : Nat) : BitVec w | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___twoPow) |
| def | BitVec.toHex | BitVec.toHex {n : Nat} (x : BitVec n) : String | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___toHex) |
| def | BitVec.toInt | BitVec.toInt {n : Nat} (x : BitVec n) : Int | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___toInt) |
| def | BitVec.toNat | BitVec.toNat {w : Nat} (x : BitVec w) : Nat | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___toNat) |
| def | BitVec.ofBool | BitVec.ofBool (b : Bool) : BitVec 1 | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___ofBool) |
| def | BitVec.ofBoolListBE | BitVec.ofBoolListBE (bs : List Bool) : BitVec bs.length | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___ofBoolListBE) |
| def | BitVec.ofBoolListLE | BitVec.ofBoolListLE (bs : List Bool) : BitVec bs.length | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___ofBoolListLE) |
| def | BitVec.ofInt | BitVec.ofInt (n : Nat) (i : Int) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___ofInt) |
| def | BitVec.ofNat | BitVec.ofNat (n i : Nat) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___ofNat) |
| def | BitVec.ofNatLT | BitVec.ofNatLT {w : Nat} (i : Nat) (p : i < 2 ^ w) : BitVec w | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___ofNatLT) |
| def | BitVec.cast | BitVec.cast {n m : Nat} (eq : n = m) (x : BitVec n) : BitVec m | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___cast) |
| def | BitVec.ule | BitVec.ule {n : Nat} (x y : BitVec n) : Bool | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___ule) |
| def | BitVec.sle | BitVec.sle {n : Nat} (x y : BitVec n) : Bool | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___sle) |
| def | BitVec.ult | BitVec.ult {n : Nat} (x y : BitVec n) : Bool | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___ult) |
| def | BitVec.slt | BitVec.slt {n : Nat} (x y : BitVec n) : Bool | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___slt) |
| def | BitVec.decEq | BitVec.decEq {w : Nat} (x y : BitVec w) : Decidable (x = y) | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___decEq) |
| def | BitVec.hash | BitVec.hash {n : Nat} (bv : BitVec n) : UInt64 | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___hash) |
| def | BitVec.nil | BitVec.nil : BitVec 0 | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___nil) |
| def | BitVec.cons | BitVec.cons {n : Nat} (msb : Bool) (lsbs : BitVec n) : BitVec (n + 1) | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___cons) |
| def | BitVec.concat | BitVec.concat {n : Nat} (msbs : BitVec n) (lsb : Bool) : BitVec (n + 1) | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___concat) |
| def | BitVec.shiftConcat | BitVec.shiftConcat {n : Nat} (x : BitVec n) (b : Bool) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___shiftConcat) |
| def | BitVec.truncate | BitVec.truncate {w : Nat} (v : Nat) (x : BitVec w) : BitVec v | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___truncate) |
| def | BitVec.setWidth | BitVec.setWidth {w : Nat} (v : Nat) (x : BitVec w) : BitVec v | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___setWidth) |
| def | BitVec.setWidth' | BitVec.setWidth' {n w : Nat} (le : n ≤ w) (x : BitVec n) : BitVec w | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___setWidth___) |
| def | BitVec.append | BitVec.append {n m : Nat} (msbs : BitVec n) (lsbs : BitVec m) : BitVec (n + m) | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___append) |
| def | BitVec.replicate | BitVec.replicate {w : Nat} (i : Nat) : BitVec w → BitVec (w * i) | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___replicate) |
| def | BitVec.reverse | BitVec.reverse {w : Nat} : BitVec w → BitVec w | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___reverse) |
| def | BitVec.rotateLeft | BitVec.rotateLeft {w : Nat} (x : BitVec w) (n : Nat) : BitVec w | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___rotateLeft) |
| def | BitVec.rotateRight | BitVec.rotateRight {w : Nat} (x : BitVec w) (n : Nat) : BitVec w | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___rotateRight) |
| def | BitVec.msb | BitVec.msb {n : Nat} (x : BitVec n) : Bool | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___msb) |
| def | BitVec.getMsbD | BitVec.getMsbD {w : Nat} (x : BitVec w) (i : Nat) : Bool | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___getMsbD) |
| def | BitVec.getMsb | BitVec.getMsb {w : Nat} (x : BitVec w) (i : Fin w) : Bool | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___getMsb) |
| def | BitVec.getMsb? | BitVec.getMsb? {w : Nat} (x : BitVec w) (i : Nat) : Option Bool | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___getMsb___) |
| def | BitVec.getLsbD | BitVec.getLsbD {w : Nat} (x : BitVec w) (i : Nat) : Bool | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___getLsbD) |
| def | BitVec.getLsb | BitVec.getLsb {w : Nat} (x : BitVec w) (i : Fin w) : Bool | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___getLsb) |
| def | BitVec.getLsb? | BitVec.getLsb? {w : Nat} (x : BitVec w) (i : Nat) : Option Bool | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___getLsb___) |
| def | BitVec.extractLsb | BitVec.extractLsb {n : Nat} (hi lo : Nat) (x : BitVec n) : BitVec (hi - lo + 1) | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___extractLsb) |
| def | BitVec.extractLsb' | BitVec.extractLsb' {n : Nat} (start len : Nat) (x : BitVec n) : BitVec len | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___extractLsb___) |
| def | BitVec.and | BitVec.and {n : Nat} (x y : BitVec n) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___and) |
| def | BitVec.or | BitVec.or {n : Nat} (x y : BitVec n) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___or) |
| def | BitVec.not | BitVec.not {n : Nat} (x : BitVec n) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___not) |
| def | BitVec.xor | BitVec.xor {n : Nat} (x y : BitVec n) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___xor) |
| def | BitVec.zeroExtend | BitVec.zeroExtend {w : Nat} (v : Nat) (x : BitVec w) : BitVec v | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___zeroExtend) |
| def | BitVec.signExtend | BitVec.signExtend {w : Nat} (v : Nat) (x : BitVec w) : BitVec v | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___signExtend) |
| def | BitVec.ushiftRight | BitVec.ushiftRight {n : Nat} (x : BitVec n) (s : Nat) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___ushiftRight) |
| def | BitVec.sshiftRight | BitVec.sshiftRight {n : Nat} (x : BitVec n) (s : Nat) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___sshiftRight) |
| def | BitVec.sshiftRight' | BitVec.sshiftRight' {n m : Nat} (a : BitVec n) (s : BitVec m) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___sshiftRight___) |
| def | BitVec.shiftLeft | BitVec.shiftLeft {n : Nat} (x : BitVec n) (s : Nat) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___shiftLeft) |
| def | BitVec.shiftLeftZeroExtend | BitVec.shiftLeftZeroExtend {w : Nat} (msbs : BitVec w) (m : Nat) : BitVec (w + m) | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___shiftLeftZeroExtend) |
| def | BitVec.add | BitVec.add {n : Nat} (x y : BitVec n) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___add) |
| def | BitVec.sub | BitVec.sub {n : Nat} (x y : BitVec n) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___sub) |
| def | BitVec.mul | BitVec.mul {n : Nat} (x y : BitVec n) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___mul) |
| def | BitVec.udiv | BitVec.udiv {n : Nat} (x y : BitVec n) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___udiv) |
| def | BitVec.smtUDiv | BitVec.smtUDiv {n : Nat} (x y : BitVec n) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___smtUDiv) |
| def | BitVec.umod | BitVec.umod {n : Nat} (x y : BitVec n) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___umod) |
| def | BitVec.uaddOverflow | BitVec.uaddOverflow {w : Nat} (x y : BitVec w) : Bool | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___uaddOverflow) |
| def | BitVec.usubOverflow | BitVec.usubOverflow {w : Nat} (x y : BitVec w) : Bool | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___usubOverflow) |
| def | BitVec.abs | BitVec.abs {n : Nat} (x : BitVec n) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___abs) |
| def | BitVec.neg | BitVec.neg {n : Nat} (x : BitVec n) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___neg) |
| def | BitVec.sdiv | BitVec.sdiv {n : Nat} (x y : BitVec n) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___sdiv) |
| def | BitVec.smtSDiv | BitVec.smtSDiv {n : Nat} (x y : BitVec n) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___smtSDiv) |
| def | BitVec.smod | BitVec.smod {m : Nat} (x y : BitVec m) : BitVec m | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___smod) |
| def | BitVec.srem | BitVec.srem {n : Nat} (x y : BitVec n) : BitVec n | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___srem) |
| def | BitVec.saddOverflow | BitVec.saddOverflow {w : Nat} (x y : BitVec w) : Bool | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___saddOverflow) |
| def | BitVec.ssubOverflow | BitVec.ssubOverflow {w : Nat} (x y : BitVec w) : Bool | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___ssubOverflow) |
| def | BitVec.iunfoldr | BitVec.iunfoldr.{u_1} {w : Nat} {α : Type u_1} (f : Fin w → α → α × Bool) (s : α) : α × BitVec w | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___iunfoldr) |
| theorem | BitVec.iunfoldr_replace | BitVec.iunfoldr_replace.{u_1} {w : Nat} {α : Type u_1} {f : Fin w → α → α × Bool} (state : Nat → α) (value : BitVec w) (a : α) (init : state 0 = a) (step : ∀ (i … | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___iunfoldr_replace) |
| def | BitVec.adc | BitVec.adc {w : Nat} (x y : BitVec w) : Bool → Bool × BitVec w | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___adc) |
| def | BitVec.adcb | BitVec.adcb (x y c : Bool) : Bool × Bool | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___adcb) |
| def | BitVec.carry | BitVec.carry {w : Nat} (i : Nat) (x y : BitVec w) (c : Bool) : Bool | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___carry) |
| def | BitVec.mulRec | BitVec.mulRec {w : Nat} (x y : BitVec w) (s : Nat) : BitVec w | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___mulRec) |
| def | BitVec.divRec | BitVec.divRec {w : Nat} (m : Nat) (args : BitVec.DivModArgs w) (qr : BitVec.DivModState w) : BitVec.DivModState w | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___divRec) |
| def | BitVec.divSubtractShift | BitVec.divSubtractShift {w : Nat} (args : BitVec.DivModArgs w) (qr : BitVec.DivModState w) : BitVec.DivModState w | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___divSubtractShift) |
| def | BitVec.shiftLeftRec | BitVec.shiftLeftRec {w₁ w₂ : Nat} (x : BitVec w₁) (y : BitVec w₂) (n : Nat) : BitVec w₁ | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___shiftLeftRec) |
| def | BitVec.sshiftRightRec | BitVec.sshiftRightRec {w₁ w₂ : Nat} (x : BitVec w₁) (y : BitVec w₂) (n : Nat) : BitVec w₁ | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___sshiftRightRec) |
| def | BitVec.ushiftRightRec | BitVec.ushiftRightRec {w₁ w₂ : Nat} (x : BitVec w₁) (y : BitVec w₂) (n : Nat) : BitVec w₁ | [Reference](pages/Basic-Types/Bitvectors/index.md#BitVec___ushiftRightRec) |
| structure | Float | Float : Type | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___ofModel) |
| structure | Float32 | Float32 : Type | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___ofModel) |
| structure | Float.Model | Float.Model : Type | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___mk) |
| structure | Float32.Model | Float32.Model : Type | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___Model___mk) |
| def | Float.Model.pack | Float.Model.pack (f : Float.Model.UnpackedFloat) : Float.Model | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___pack) |
| def | Float32.Model.pack | Float32.Model.pack (f : Float.Model.UnpackedFloat) : Float32.Model | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___Model___pack) |
| def | Float.Model.unpack | Float.Model.unpack (f : Float.Model) : Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___unpack) |
| def | Float32.Model.unpack | Float32.Model.unpack (f : Float32.Model) : Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___Model___unpack) |
| inductive type | Float.Model.UnpackedFloat | Float.Model.UnpackedFloat : Type | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___infinity) |
| def | Float.Model.UnpackedFloat.add | Float.Model.UnpackedFloat.add (spec : Float.Model.Format) : Float.Model.UnpackedFloat → Float.Model.UnpackedFloat → Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___add) |
| def | Float.Model.UnpackedFloat.sub | Float.Model.UnpackedFloat.sub (spec : Float.Model.Format) : Float.Model.UnpackedFloat → Float.Model.UnpackedFloat → Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___sub) |
| def | Float.Model.UnpackedFloat.mul | Float.Model.UnpackedFloat.mul (spec : Float.Model.Format) : Float.Model.UnpackedFloat → Float.Model.UnpackedFloat → Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___mul) |
| def | Float.Model.UnpackedFloat.div | Float.Model.UnpackedFloat.div (spec : Float.Model.Format) : Float.Model.UnpackedFloat → Float.Model.UnpackedFloat → Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___div) |
| def | Float.Model.UnpackedFloat.sqrt | Float.Model.UnpackedFloat.sqrt (spec : Float.Model.Format) : Float.Model.UnpackedFloat → Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___sqrt) |
| def | Float.Model.UnpackedFloat.neg | Float.Model.UnpackedFloat.neg : Float.Model.UnpackedFloat → Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___neg) |
| def | Float.Model.UnpackedFloat.abs | Float.Model.UnpackedFloat.abs : Float.Model.UnpackedFloat → Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___abs) |
| def | Float.Model.UnpackedFloat.isNaN | Float.Model.UnpackedFloat.isNaN : Float.Model.UnpackedFloat → Bool | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___isNaN) |
| def | Float.Model.UnpackedFloat.isInf | Float.Model.UnpackedFloat.isInf : Float.Model.UnpackedFloat → Bool | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___isInf) |
| def | Float.Model.UnpackedFloat.isFinite | Float.Model.UnpackedFloat.isFinite : Float.Model.UnpackedFloat → Bool | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___isFinite) |
| def | Float.Model.UnpackedFloat.compare | Float.Model.UnpackedFloat.compare : Float.Model.UnpackedFloat → Float.Model.UnpackedFloat → Option Ordering | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___compare) |
| def | Float.Model.UnpackedFloat.beq | Float.Model.UnpackedFloat.beq (a b : Float.Model.UnpackedFloat) : Bool | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___beq) |
| def | Float.Model.UnpackedFloat.lt | Float.Model.UnpackedFloat.lt (a b : Float.Model.UnpackedFloat) : Bool | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___lt) |
| def | Float.Model.UnpackedFloat.le | Float.Model.UnpackedFloat.le (a b : Float.Model.UnpackedFloat) : Bool | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___le) |
| def | Float.Model.UnpackedFloat.ofNat | Float.Model.UnpackedFloat.ofNat (spec : Float.Model.Format) (n : Nat) : Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___ofNat) |
| def | Float.Model.UnpackedFloat.ofInt | Float.Model.UnpackedFloat.ofInt (spec : Float.Model.Format) (n : Int) : Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___ofInt) |
| def | Float.Model.UnpackedFloat.ofScientific | Float.Model.UnpackedFloat.ofScientific (spec : Float.Model.Format) (m : Nat) (e : Int) : Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___ofScientific) |
| def | Float.Model.UnpackedFloat.toInt8 | Float.Model.UnpackedFloat.toInt8 (f : Float.Model.UnpackedFloat) : Int8 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___toInt8) |
| def | Float.Model.UnpackedFloat.ofInt8 | Float.Model.UnpackedFloat.ofInt8 (spec : Float.Model.Format) (n : Int8) : Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___ofInt8) |
| def | Float.Model.UnpackedFloat.toInt16 | Float.Model.UnpackedFloat.toInt16 (f : Float.Model.UnpackedFloat) : Int16 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___toInt16) |
| def | Float.Model.UnpackedFloat.ofInt16 | Float.Model.UnpackedFloat.ofInt16 (spec : Float.Model.Format) (n : Int16) : Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___ofInt16) |
| def | Float.Model.UnpackedFloat.toInt32 | Float.Model.UnpackedFloat.toInt32 (f : Float.Model.UnpackedFloat) : Int32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___toInt32) |
| def | Float.Model.UnpackedFloat.ofInt32 | Float.Model.UnpackedFloat.ofInt32 (spec : Float.Model.Format) (n : Int32) : Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___ofInt32) |
| def | Float.Model.UnpackedFloat.toInt64 | Float.Model.UnpackedFloat.toInt64 (f : Float.Model.UnpackedFloat) : Int64 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___toInt64) |
| def | Float.Model.UnpackedFloat.ofInt64 | Float.Model.UnpackedFloat.ofInt64 (spec : Float.Model.Format) (n : Int64) : Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___ofInt64) |
| def | Float.Model.UnpackedFloat.toISize | Float.Model.UnpackedFloat.toISize (f : Float.Model.UnpackedFloat) : ISize | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___toISize) |
| def | Float.Model.UnpackedFloat.ofISize | Float.Model.UnpackedFloat.ofISize (spec : Float.Model.Format) (n : ISize) : Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___ofISize) |
| def | Float.Model.UnpackedFloat.toUInt8 | Float.Model.UnpackedFloat.toUInt8 (f : Float.Model.UnpackedFloat) : UInt8 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___toUInt8) |
| def | Float.Model.UnpackedFloat.ofUInt8 | Float.Model.UnpackedFloat.ofUInt8 (spec : Float.Model.Format) (n : UInt8) : Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___ofUInt8) |
| def | Float.Model.UnpackedFloat.toUInt16 | Float.Model.UnpackedFloat.toUInt16 (f : Float.Model.UnpackedFloat) : UInt16 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___toUInt16) |
| def | Float.Model.UnpackedFloat.ofUInt16 | Float.Model.UnpackedFloat.ofUInt16 (spec : Float.Model.Format) (n : UInt16) : Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___ofUInt16) |
| def | Float.Model.UnpackedFloat.toUInt32 | Float.Model.UnpackedFloat.toUInt32 (f : Float.Model.UnpackedFloat) : UInt32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___toUInt32) |
| def | Float.Model.UnpackedFloat.ofUInt32 | Float.Model.UnpackedFloat.ofUInt32 (spec : Float.Model.Format) (n : UInt32) : Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___ofUInt32) |
| def | Float.Model.UnpackedFloat.toUInt64 | Float.Model.UnpackedFloat.toUInt64 (f : Float.Model.UnpackedFloat) : UInt64 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___toUInt64) |
| def | Float.Model.UnpackedFloat.ofUInt64 | Float.Model.UnpackedFloat.ofUInt64 (spec : Float.Model.Format) (n : UInt64) : Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___ofUInt64) |
| def | Float.Model.UnpackedFloat.toUSize | Float.Model.UnpackedFloat.toUSize (f : Float.Model.UnpackedFloat) : USize | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___toUSize) |
| def | Float.Model.UnpackedFloat.ofUSize | Float.Model.UnpackedFloat.ofUSize (spec : Float.Model.Format) (n : USize) : Float.Model.UnpackedFloat | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___Model___UnpackedFloat___ofUSize) |
| def | Float.isInf | Float.isInf : Float → Bool | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___isInf) |
| def | Float32.isInf | Float32.isInf : Float32 → Bool | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___isInf) |
| def | Float.isNaN | Float.isNaN : Float → Bool | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___isNaN) |
| def | Float32.isNaN | Float32.isNaN : Float32 → Bool | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___isNaN) |
| def | Float.isFinite | Float.isFinite : Float → Bool | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___isFinite) |
| def | Float32.isFinite | Float32.isFinite : Float32 → Bool | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___isFinite) |
| def | Float.toBits | Float.toBits : Float → UInt64 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___toBits) |
| def | Float32.toBits | Float32.toBits : Float32 → UInt32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___toBits) |
| def | Float.ofBits | Float.ofBits : UInt64 → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___ofBits) |
| def | Float32.ofBits | Float32.ofBits : UInt32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___ofBits) |
| opaque | Float.toFloat32 | Float.toFloat32 : Float → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___toFloat32) |
| opaque | Float32.toFloat | Float32.toFloat : Float32 → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___toFloat) |
| opaque | Float.toString | Float.toString : Float → String | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___toString) |
| opaque | Float32.toString | Float32.toString : Float32 → String | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___toString) |
| def | Float.toUInt8 | Float.toUInt8 : Float → UInt8 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___toUInt8) |
| def | Float.toInt8 | Float.toInt8 : Float → Int8 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___toInt8) |
| def | Float32.toUInt8 | Float32.toUInt8 : Float32 → UInt8 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___toUInt8) |
| def | Float32.toInt8 | Float32.toInt8 : Float32 → Int8 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___toInt8) |
| def | Float.toUInt16 | Float.toUInt16 : Float → UInt16 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___toUInt16) |
| def | Float.toInt16 | Float.toInt16 : Float → Int16 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___toInt16) |
| def | Float32.toUInt16 | Float32.toUInt16 : Float32 → UInt16 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___toUInt16) |
| def | Float32.toInt16 | Float32.toInt16 : Float32 → Int16 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___toInt16) |
| def | Float.toUInt32 | Float.toUInt32 : Float → UInt32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___toUInt32) |
| def | Float32.toUInt32 | Float32.toUInt32 : Float32 → UInt32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___toUInt32) |
| def | Float.toInt32 | Float.toInt32 : Float → Int32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___toInt32) |
| def | Float32.toInt32 | Float32.toInt32 : Float32 → Int32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___toInt32) |
| def | Float.toUInt64 | Float.toUInt64 : Float → UInt64 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___toUInt64) |
| def | Float.toInt64 | Float.toInt64 : Float → Int64 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___toInt64) |
| def | Float32.toUInt64 | Float32.toUInt64 : Float32 → UInt64 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___toUInt64) |
| def | Float32.toInt64 | Float32.toInt64 : Float32 → Int64 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___toInt64) |
| def | Float.toUSize | Float.toUSize : Float → USize | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___toUSize) |
| def | Float32.toUSize | Float32.toUSize : Float32 → USize | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___toUSize) |
| def | Float.toISize | Float.toISize : Float → ISize | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___toISize) |
| def | Float32.toISize | Float32.toISize : Float32 → ISize | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___toISize) |
| def | Float.ofInt | Float.ofInt : Int → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___ofInt) |
| def | Float32.ofInt | Float32.ofInt : Int → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___ofInt) |
| def | Float.ofNat | Float.ofNat (n : Nat) : Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___ofNat) |
| def | Float32.ofNat | Float32.ofNat (n : Nat) : Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___ofNat) |
| opaque | Float.frExp | Float.frExp : Float → Float × Int | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___frExp) |
| opaque | Float32.frExp | Float32.frExp : Float32 → Float32 × Int | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___frExp) |
| def | Float.beq | Float.beq (a b : Float) : Bool | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___beq) |
| def | Float32.beq | Float32.beq (a b : Float32) : Bool | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___beq) |
| def | Float.le | Float.le : Float → Float → Bool | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___le) |
| def | Float32.le | Float32.le : Float32 → Float32 → Bool | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___le) |
| def | Float.lt | Float.lt : Float → Float → Bool | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___lt) |
| def | Float32.lt | Float32.lt : Float32 → Float32 → Bool | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___lt) |
| def | Float.decLe | Float.decLe (a b : Float) : Decidable (a ≤ b) | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___decLe) |
| def | Float32.decLe | Float32.decLe (a b : Float32) : Decidable (a ≤ b) | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___decLe) |
| def | Float.decLt | Float.decLt (a b : Float) : Decidable (a < b) | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___decLt) |
| def | Float32.decLt | Float32.decLt (a b : Float32) : Decidable (a < b) | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___decLt) |
| def | Float.add | Float.add : Float → Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___add) |
| def | Float32.add | Float32.add : Float32 → Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___add) |
| def | Float.sub | Float.sub : Float → Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___sub) |
| def | Float32.sub | Float32.sub : Float32 → Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___sub) |
| def | Float.mul | Float.mul : Float → Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___mul) |
| def | Float32.mul | Float32.mul : Float32 → Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___mul) |
| def | Float.div | Float.div : Float → Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___div) |
| def | Float32.div | Float32.div : Float32 → Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___div) |
| opaque | Float.pow | Float.pow : Float → Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___pow) |
| opaque | Float32.pow | Float32.pow : Float32 → Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___pow) |
| opaque | Float.exp | Float.exp (x : Float) : Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___exp) |
| opaque | Float32.exp | Float32.exp : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___exp) |
| opaque | Float.exp2 | Float.exp2 (x : Float) : Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___exp2) |
| opaque | Float32.exp2 | Float32.exp2 : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___exp2) |
| def | Float.sqrt | Float.sqrt : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___sqrt) |
| def | Float32.sqrt | Float32.sqrt : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___sqrt) |
| opaque | Float.cbrt | Float.cbrt : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___cbrt) |
| opaque | Float32.cbrt | Float32.cbrt : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___cbrt) |
| opaque | Float.log | Float.log (x : Float) : Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___log) |
| opaque | Float32.log | Float32.log : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___log) |
| opaque | Float.log10 | Float.log10 : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___log10) |
| opaque | Float32.log10 | Float32.log10 : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___log10) |
| opaque | Float.log2 | Float.log2 : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___log2) |
| opaque | Float32.log2 | Float32.log2 : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___log2) |
| opaque | Float.scaleB | Float.scaleB (x : Float) (i : Int) : Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___scaleB) |
| opaque | Float32.scaleB | Float32.scaleB (x : Float32) (i : Int) : Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___scaleB) |
| opaque | Float.round | Float.round : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___round) |
| opaque | Float32.round | Float32.round : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___round) |
| opaque | Float.floor | Float.floor : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___floor) |
| opaque | Float32.floor | Float32.floor : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___floor) |
| opaque | Float.ceil | Float.ceil : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___ceil) |
| opaque | Float32.ceil | Float32.ceil : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___ceil) |
| opaque | Float.sin | Float.sin : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___sin) |
| opaque | Float32.sin | Float32.sin : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___sin) |
| opaque | Float.sinh | Float.sinh : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___sinh) |
| opaque | Float32.sinh | Float32.sinh : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___sinh) |
| opaque | Float.asin | Float.asin : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___asin) |
| opaque | Float32.asin | Float32.asin : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___asin) |
| opaque | Float.asinh | Float.asinh : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___asinh) |
| opaque | Float32.asinh | Float32.asinh : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___asinh) |
| opaque | Float.cos | Float.cos : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___cos) |
| opaque | Float32.cos | Float32.cos : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___cos) |
| opaque | Float.cosh | Float.cosh : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___cosh) |
| opaque | Float32.cosh | Float32.cosh : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___cosh) |
| opaque | Float.acos | Float.acos : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___acos) |
| opaque | Float32.acos | Float32.acos : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___acos) |
| opaque | Float.acosh | Float.acosh : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___acosh) |
| opaque | Float32.acosh | Float32.acosh : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___acosh) |
| opaque | Float.tan | Float.tan : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___tan) |
| opaque | Float32.tan | Float32.tan : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___tan) |
| opaque | Float.tanh | Float.tanh : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___tanh) |
| opaque | Float32.tanh | Float32.tanh : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___tanh) |
| opaque | Float.atan | Float.atan : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___atan) |
| opaque | Float32.atan | Float32.atan : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___atan) |
| opaque | Float.atanh | Float.atanh : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___atanh) |
| opaque | Float32.atanh | Float32.atanh : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___atanh) |
| opaque | Float.atan2 | Float.atan2 (y x : Float) : Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___atan2) |
| opaque | Float32.atan2 | Float32.atan2 : Float32 → Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___atan2) |
| def | Float.abs | Float.abs : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___abs) |
| def | Float32.abs | Float32.abs : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___abs) |
| def | Float.neg | Float.neg : Float → Float | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float___neg) |
| def | Float32.neg | Float32.neg : Float32 → Float32 | [Reference](pages/Basic-Types/Floating-Point-Numbers/index.md#Float32___neg) |
| structure | Char | Char : Type | [Reference](pages/Basic-Types/Characters/index.md#Char___mk) |
| def | Char.ofNat | Char.ofNat (n : Nat) : Char | [Reference](pages/Basic-Types/Characters/index.md#Char___ofNat) |
| def | Char.toNat | Char.toNat (c : Char) : Nat | [Reference](pages/Basic-Types/Characters/index.md#Char___toNat) |
| def | Char.isValidCharNat | Char.isValidCharNat (n : Nat) : Prop | [Reference](pages/Basic-Types/Characters/index.md#Char___isValidCharNat) |
| def | Char.ofUInt8 | Char.ofUInt8 (n : UInt8) : Char | [Reference](pages/Basic-Types/Characters/index.md#Char___ofUInt8) |
| def | Char.toUInt8 | Char.toUInt8 (c : Char) : UInt8 | [Reference](pages/Basic-Types/Characters/index.md#Char___toUInt8) |
| def | Char.toString | Char.toString (c : Char) : String | [Reference](pages/Basic-Types/Characters/index.md#Char___toString) |
| def | Char.quote | Char.quote (c : Char) : String | [Reference](pages/Basic-Types/Characters/index.md#Char___quote) |
| def | Char.isAlpha | Char.isAlpha (c : Char) : Bool | [Reference](pages/Basic-Types/Characters/index.md#Char___isAlpha) |
| def | Char.isAlphanum | Char.isAlphanum (c : Char) : Bool | [Reference](pages/Basic-Types/Characters/index.md#Char___isAlphanum) |
| def | Char.isDigit | Char.isDigit (c : Char) : Bool | [Reference](pages/Basic-Types/Characters/index.md#Char___isDigit) |
| def | Char.isLower | Char.isLower (c : Char) : Bool | [Reference](pages/Basic-Types/Characters/index.md#Char___isLower) |
| def | Char.isUpper | Char.isUpper (c : Char) : Bool | [Reference](pages/Basic-Types/Characters/index.md#Char___isUpper) |
| def | Char.isWhitespace | Char.isWhitespace (c : Char) : Bool | [Reference](pages/Basic-Types/Characters/index.md#Char___isWhitespace) |
| def | Char.toUpper | Char.toUpper (c : Char) : Char | [Reference](pages/Basic-Types/Characters/index.md#Char___toUpper) |
| def | Char.toLower | Char.toLower (c : Char) : Char | [Reference](pages/Basic-Types/Characters/index.md#Char___toLower) |
| def | Char.le | Char.le (a b : Char) : Prop | [Reference](pages/Basic-Types/Characters/index.md#Char___le) |
| def | Char.lt | Char.lt (a b : Char) : Prop | [Reference](pages/Basic-Types/Characters/index.md#Char___lt) |
| def | Char.utf8Size | Char.utf8Size (c : Char) : Nat | [Reference](pages/Basic-Types/Characters/index.md#Char___utf8Size) |
| structure | String | String : Type | [Reference](pages/Basic-Types/Strings/index.md#String___ofByteArray) |
| def | String.ofList | String.ofList (data : List Char) : String | [Reference](pages/Basic-Types/Strings/index.md#String___ofList) |
| def | String.toList | String.toList (s : String) : List Char | [Reference](pages/Basic-Types/Strings/index.md#String___toList) |
| def | String.singleton | String.singleton (c : Char) : String | [Reference](pages/Basic-Types/Strings/index.md#String___singleton) |
| def | String.append | String.append (s : String) (t : String) : String | [Reference](pages/Basic-Types/Strings/index.md#String___append) |
| def | String.join | String.join (l : List String) : String | [Reference](pages/Basic-Types/Strings/index.md#String___join) |
| def | String.intercalate | String.intercalate (s : String) : List String → String | [Reference](pages/Basic-Types/Strings/index.md#String___intercalate) |
| def | String.toList | String.toList (s : String) : List Char | [Reference](pages/Basic-Types/Strings/index.md#String___toList-next) |
| def | String.isNat | String.isNat (s : String) : Bool | [Reference](pages/Basic-Types/Strings/index.md#String___isNat) |
| def | String.toNat? | String.toNat? (s : String) : Option Nat | [Reference](pages/Basic-Types/Strings/index.md#String___toNat___) |
| def | String.toNat! | String.toNat! (s : String) : Nat | [Reference](pages/Basic-Types/Strings/index.md#String___toNat___-next) |
| def | String.isInt | String.isInt (s : String) : Bool | [Reference](pages/Basic-Types/Strings/index.md#String___isInt) |
| def | String.toInt? | String.toInt? (s : String) : Option Int | [Reference](pages/Basic-Types/Strings/index.md#String___toInt___) |
| def | String.toInt! | String.toInt! (s : String) : Int | [Reference](pages/Basic-Types/Strings/index.md#String___toInt___-next) |
| def | String.toFormat | String.toFormat (s : String) : Std.Format | [Reference](pages/Basic-Types/Strings/index.md#String___toFormat) |
| def | String.isEmpty | String.isEmpty (s : String) : Bool | [Reference](pages/Basic-Types/Strings/index.md#String___isEmpty) |
| def | String.length | String.length (b : String) : Nat | [Reference](pages/Basic-Types/Strings/index.md#String___length) |
| structure | String.Pos | String.Pos (s : String) : Type | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___mk) |
| def | String.startPos | String.startPos (s : String) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___startPos) |
| def | String.endPos | String.endPos (s : String) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___endPos) |
| def | String.pos | String.pos (s : String) (off : String.Pos.Raw) (h : String.Pos.Raw.IsValid s off) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___pos) |
| def | String.pos? | String.pos? (s : String) (off : String.Pos.Raw) : Option s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___pos___) |
| def | String.pos! | String.pos! (s : String) (off : String.Pos.Raw) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___pos___-next) |
| def | String.extract | String.extract {s : String} (b e : s.Pos) : String | [Reference](pages/Basic-Types/Strings/index.md#String___extract) |
| def | String.Pos.get | String.Pos.get {s : String} (pos : s.Pos) (h : pos ≠ s.endPos) : Char | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___get) |
| def | String.Pos.get! | String.Pos.get! {s : String} (pos : s.Pos) : Char | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___get___) |
| def | String.Pos.get? | String.Pos.get? {s : String} (pos : s.Pos) : Option Char | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___get___-next) |
| def | String | String.Pos.set {s : String} (p : s.Pos) (c : Char) (hp : p ≠ s.endPos) : String | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___set) |
| def | String.Pos.modify | String.Pos.modify {s : String} (p : s.Pos) (f : Char → Char) (hp : p ≠ s.endPos) : String | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___modify) |
| def | String.Pos.byte | String.Pos.byte {s : String} (pos : s.Pos) (h : pos ≠ s.endPos) : UInt8 | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___byte) |
| def | String.Pos.prev | String.Pos.prev {s : String} (pos : s.Pos) (h : pos ≠ s.startPos) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___prev) |
| def | String.Pos.prev! | String.Pos.prev! {s : String} (pos : s.Pos) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___prev___) |
| def | String.Pos.prev? | String.Pos.prev? {s : String} (pos : s.Pos) : Option s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___prev___-next) |
| def | String.Pos.next | String.Pos.next {s : String} (pos : s.Pos) (h : pos ≠ s.endPos) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___next) |
| def | String.Pos.next! | String.Pos.next! {s : String} (pos : s.Pos) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___next___) |
| def | String.Pos.next? | String.Pos.next? {s : String} (pos : s.Pos) : Option s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___next___-next) |
| def | String.Pos.cast | String.Pos.cast {s t : String} (pos : s.Pos) (h : s = t) : t.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___cast) |
| def | String.Pos.ofCopy | String.Pos.ofCopy {s : String.Slice} (pos : s.copy.Pos) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___ofCopy) |
| def | String.Pos.toSetOfLE | String.Pos.toSetOfLE {s : String} (q p : s.Pos) (c : Char) (hp : p ≠ s.endPos) (hpq : q ≤ p) : (p.set c hp).Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___toSetOfLE) |
| def | String.Pos.toModifyOfLE | String.Pos.toModifyOfLE {s : String} (q p : s.Pos) (f : Char → Char) (hp : p ≠ s.endPos) (hpq : q ≤ p) : (p.modify f hp).Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___toModifyOfLE) |
| def | String.Pos.toSlice | String.Pos.toSlice {s : String} (pos : s.Pos) : s.toSlice.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___toSlice) |
| structure | String.Pos.Raw | String.Pos.Raw : Type | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___mk) |
| def | String.Pos.Raw.offsetOfPos | String.Pos.Raw.offsetOfPos (s : String) (pos : String.Pos.Raw) : Nat | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___offsetOfPos) |
| def | String.Pos.Raw.isValid | String.Pos.Raw.isValid (s : String) (p : String.Pos.Raw) : Bool | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___isValid) |
| def | String.Pos.Raw.isValidForSlice | String.Pos.Raw.isValidForSlice (s : String.Slice) (p : String.Pos.Raw) : Bool | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___isValidForSlice) |
| def | String.rawEndPos | String.rawEndPos (s : String) : String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#String___rawEndPos) |
| def | String.Pos.Raw.atEnd | String.Pos.Raw.atEnd : String → String.Pos.Raw → Bool | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___atEnd) |
| def | String.Pos.Raw.min | String.Pos.Raw.min (p₁ p₂ : String.Pos.Raw) : String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___min) |
| def | String.Pos.Raw.byteDistance | String.Pos.Raw.byteDistance (lo hi : String.Pos.Raw) : Nat | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___byteDistance) |
| def | String.Pos.Raw.substrEq | String.Pos.Raw.substrEq (s1 : String) (pos1 : String.Pos.Raw) (s2 : String) (pos2 : String.Pos.Raw) (sz : Nat) : Bool | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___substrEq) |
| def | String.Pos.Raw.prev | String.Pos.Raw.prev : String → String.Pos.Raw → String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___prev) |
| def | String.Pos.Raw.next | String.Pos.Raw.next (s : String) (p : String.Pos.Raw) : String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___next) |
| def | String.Pos.Raw.next' | String.Pos.Raw.next' (s : String) (p : String.Pos.Raw) (h : ¬String.Pos.Raw.atEnd s p = true) : String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___next___) |
| def | String.Pos.Raw.nextUntil | String.Pos.Raw.nextUntil (s : String) (p : Char → Bool) (i : String.Pos.Raw) : String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___nextUntil) |
| def | String.Pos.Raw.nextWhile | String.Pos.Raw.nextWhile (s : String) (p : Char → Bool) (i : String.Pos.Raw) : String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___nextWhile) |
| def | String.Pos.Raw.inc | String.Pos.Raw.inc (p : String.Pos.Raw) : String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___inc) |
| def | String.Pos.Raw.increaseBy | String.Pos.Raw.increaseBy (p : String.Pos.Raw) (n : Nat) : String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___increaseBy) |
| def | String.Pos.Raw.offsetBy | String.Pos.Raw.offsetBy (p offset : String.Pos.Raw) : String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___offsetBy) |
| def | String.Pos.Raw.dec | String.Pos.Raw.dec (p : String.Pos.Raw) : String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___dec) |
| def | String.Pos.Raw.decreaseBy | String.Pos.Raw.decreaseBy (p : String.Pos.Raw) (n : Nat) : String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___decreaseBy) |
| def | String.Pos.Raw.unoffsetBy | String.Pos.Raw.unoffsetBy (p offset : String.Pos.Raw) : String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___unoffsetBy) |
| def | String.Pos.Raw.extract | String.Pos.Raw.extract : String → String.Pos.Raw → String.Pos.Raw → String | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___extract) |
| def | String.Pos.Raw.get | String.Pos.Raw.get (s : String) (p : String.Pos.Raw) : Char | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___get) |
| def | String.Pos.Raw.get! | String.Pos.Raw.get! (s : String) (p : String.Pos.Raw) : Char | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___get___) |
| def | String.Pos.Raw.get' | String.Pos.Raw.get' (s : String) (p : String.Pos.Raw) (h : ¬String.Pos.Raw.atEnd s p = true) : Char | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___get___-next) |
| def | String.Pos.Raw.get? | String.Pos.Raw.get? : String → String.Pos.Raw → Option Char | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___get___-next-next) |
| def | String | String.Pos.Raw.set : String → String.Pos.Raw → Char → String | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___set) |
| def | String.Pos.Raw.modify | String.Pos.Raw.modify (s : String) (i : String.Pos.Raw) (f : Char → Char) : String | [Reference](pages/Basic-Types/Strings/index.md#String___Pos___Raw___modify) |
| def | String.take | String.take (s : String) (n : Nat) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___take) |
| def | String.takeWhile | String.takeWhile {ρ : Type} (s : String) (pat : ρ) [String.Slice.Pattern.ForwardPattern pat] : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___takeWhile) |
| def | String.takeEnd | String.takeEnd (s : String) (n : Nat) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___takeEnd) |
| def | String.takeEndWhile | String.takeEndWhile {ρ : Type} (s : String) (pat : ρ) [String.Slice.Pattern.BackwardPattern pat] : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___takeEndWhile) |
| def | String.drop | String.drop (s : String) (n : Nat) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___drop) |
| def | String.dropWhile | String.dropWhile {ρ : Type} (s : String) (pat : ρ) [String.Slice.Pattern.ForwardPattern pat] : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___dropWhile) |
| def | String.dropEnd | String.dropEnd (s : String) (n : Nat) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___dropEnd) |
| def | String.dropEndWhile | String.dropEndWhile {ρ : Type} (s : String) (pat : ρ) [String.Slice.Pattern.BackwardPattern pat] : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___dropEndWhile) |
| def | String.dropPrefix? | String.dropPrefix? {ρ : Type} (s : String) (pat : ρ) [String.Slice.Pattern.ForwardPattern pat] : Option String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___dropPrefix___) |
| def | String.dropPrefix | String.dropPrefix {ρ : Type} (s : String) (pat : ρ) [String.Slice.Pattern.ForwardPattern pat] : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___dropPrefix) |
| def | String.dropSuffix? | String.dropSuffix? {ρ : Type} (s : String) (pat : ρ) [String.Slice.Pattern.BackwardPattern pat] : Option String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___dropSuffix___) |
| def | String.dropSuffix | String.dropSuffix {ρ : Type} (s : String) (pat : ρ) [String.Slice.Pattern.BackwardPattern pat] : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___dropSuffix) |
| def | String.trimAscii | String.trimAscii (s : String) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___trimAscii) |
| def | String.trimAsciiStart | String.trimAsciiStart (s : String) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___trimAsciiStart) |
| def | String.trimAsciiEnd | String.trimAsciiEnd (s : String) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___trimAsciiEnd) |
| def | String.removeLeadingSpaces | String.removeLeadingSpaces (s : String) : String | [Reference](pages/Basic-Types/Strings/index.md#String___removeLeadingSpaces) |
| def | String.front | String.front (s : String) : Char | [Reference](pages/Basic-Types/Strings/index.md#String___front) |
| def | String.back | String.back (s : String) : Char | [Reference](pages/Basic-Types/Strings/index.md#String___back) |
| def | String.find | String.find {ρ : Type} {σ : String.Slice → Type} [(s : String.Slice) → Std.Iterator (σ s) Id (String.Slice.Pattern.SearchStep s)] [(s : String.Slice) → Std.Iter … | [Reference](pages/Basic-Types/Strings/index.md#String___find) |
| def | String.revFind? | String.revFind? {ρ : Type} {σ : String.Slice → Type} [(s : String.Slice) → Std.Iterator (σ s) Id (String.Slice.Pattern.SearchStep s)] [(s : String.Slice) → Std. … | [Reference](pages/Basic-Types/Strings/index.md#String___revFind___) |
| def | String.contains | String.contains {ρ : Type} {σ : String.Slice → Type} [(s : String.Slice) → Std.Iterator (σ s) Id (String.Slice.Pattern.SearchStep s)] [(s : String.Slice) → Std. … | [Reference](pages/Basic-Types/Strings/index.md#String___contains) |
| def | String.replace | String.replace.{u_1} {ρ : Type} {σ : String.Slice → Type} [(s : String.Slice) → Std.Iterator (σ s) Id (String.Slice.Pattern.SearchStep s)] [(s : String.Slice) → … | [Reference](pages/Basic-Types/Strings/index.md#String___replace) |
| def | String.find | String.find {ρ : Type} {σ : String.Slice → Type} [(s : String.Slice) → Std.Iterator (σ s) Id (String.Slice.Pattern.SearchStep s)] [(s : String.Slice) → Std.Iter … | [Reference](pages/Basic-Types/Strings/index.md#String___find-next) |
| def | String.map | String.map (f : Char → Char) (s : String) : String | [Reference](pages/Basic-Types/Strings/index.md#String___map) |
| def | String.foldl | String.foldl.{u} {α : Type u} (f : α → Char → α) (init : α) (s : String) : α | [Reference](pages/Basic-Types/Strings/index.md#String___foldl) |
| def | String.foldr | String.foldr.{u} {α : Type u} (f : Char → α → α) (init : α) (s : String) : α | [Reference](pages/Basic-Types/Strings/index.md#String___foldr) |
| def | String.all | String.all {ρ : Type} (s : String) (pat : ρ) [String.Slice.Pattern.ForwardPattern pat] : Bool | [Reference](pages/Basic-Types/Strings/index.md#String___all) |
| def | String.any | String.any {ρ : Type} {σ : String.Slice → Type} [(s : String.Slice) → Std.Iterator (σ s) Id (String.Slice.Pattern.SearchStep s)] [(s : String.Slice) → Std.Itera … | [Reference](pages/Basic-Types/Strings/index.md#String___any) |
| def | String.le | String.le (a b : String) : Prop | [Reference](pages/Basic-Types/Strings/index.md#String___le) |
| def | String.firstDiffPos | String.firstDiffPos (a b : String) : String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#String___firstDiffPos) |
| def | String.isPrefixOf | String.isPrefixOf (p s : String) : Bool | [Reference](pages/Basic-Types/Strings/index.md#String___isPrefixOf) |
| def | String.startsWith | String.startsWith {ρ : Type} (s : String) (pat : ρ) [String.Slice.Pattern.ForwardPattern pat] : Bool | [Reference](pages/Basic-Types/Strings/index.md#String___startsWith) |
| def | String.endsWith | String.endsWith {ρ : Type} (s : String) (pat : ρ) [String.Slice.Pattern.BackwardPattern pat] : Bool | [Reference](pages/Basic-Types/Strings/index.md#String___endsWith) |
| def | String.decEq | String.decEq (s₁ s₂ : String) : Decidable (s₁ = s₂) | [Reference](pages/Basic-Types/Strings/index.md#String___decEq) |
| opaque | String.hash | String.hash (s : String) : UInt64 | [Reference](pages/Basic-Types/Strings/index.md#String___hash) |
| def | String.splitToList | String.splitToList (s : String) (p : Char → Bool) : List String | [Reference](pages/Basic-Types/Strings/index.md#String___splitToList) |
| def | String.splitOn | String.splitOn (s : String) (sep : String := " ") : List String | [Reference](pages/Basic-Types/Strings/index.md#String___splitOn) |
| def | String.push | String.push : String → Char → String | [Reference](pages/Basic-Types/Strings/index.md#String___push) |
| def | String.pushn | String.pushn (s : String) (c : Char) (n : Nat) : String | [Reference](pages/Basic-Types/Strings/index.md#String___pushn) |
| def | String.capitalize | String.capitalize (s : String) : String | [Reference](pages/Basic-Types/Strings/index.md#String___capitalize) |
| def | String.decapitalize | String.decapitalize (s : String) : String | [Reference](pages/Basic-Types/Strings/index.md#String___decapitalize) |
| def | String.toUpper | String.toUpper (s : String) : String | [Reference](pages/Basic-Types/Strings/index.md#String___toUpper) |
| def | String.toLower | String.toLower (s : String) : String | [Reference](pages/Basic-Types/Strings/index.md#String___toLower) |
| structure | String.Legacy.Iterator | String.Legacy.Iterator : Type | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___mk) |
| def | String.Legacy.iter | String.Legacy.iter (s : String) : String.Legacy.Iterator | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___iter) |
| def | String.Legacy.mkIterator | String.Legacy.mkIterator (s : String) : String.Legacy.Iterator | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___mkIterator) |
| def | String.Legacy.Iterator.curr | String.Legacy.Iterator.curr : String.Legacy.Iterator → Char | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___curr) |
| def | String.Legacy.Iterator.curr' | String.Legacy.Iterator.curr' (it : String.Legacy.Iterator) (h : it.hasNext = true) : Char | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___curr___) |
| def | String.Legacy.Iterator.hasNext | String.Legacy.Iterator.hasNext : String.Legacy.Iterator → Bool | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___hasNext) |
| def | String.Legacy.Iterator.next | String.Legacy.Iterator.next : String.Legacy.Iterator → String.Legacy.Iterator | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___next) |
| def | String.Legacy.Iterator.next' | String.Legacy.Iterator.next' (it : String.Legacy.Iterator) (h : it.hasNext = true) : String.Legacy.Iterator | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___next___) |
| def | String.Legacy.Iterator.forward | String.Legacy.Iterator.forward : String.Legacy.Iterator → Nat → String.Legacy.Iterator | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___forward) |
| def | String.Legacy.Iterator.nextn | String.Legacy.Iterator.nextn : String.Legacy.Iterator → Nat → String.Legacy.Iterator | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___nextn) |
| def | String.Legacy.Iterator.hasPrev | String.Legacy.Iterator.hasPrev : String.Legacy.Iterator → Bool | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___hasPrev) |
| def | String.Legacy.Iterator.prev | String.Legacy.Iterator.prev : String.Legacy.Iterator → String.Legacy.Iterator | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___prev) |
| def | String.Legacy.Iterator.prevn | String.Legacy.Iterator.prevn : String.Legacy.Iterator → Nat → String.Legacy.Iterator | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___prevn) |
| def | String.Legacy.Iterator.atEnd | String.Legacy.Iterator.atEnd : String.Legacy.Iterator → Bool | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___atEnd) |
| def | String.Legacy.Iterator.toEnd | String.Legacy.Iterator.toEnd : String.Legacy.Iterator → String.Legacy.Iterator | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___toEnd) |
| def | String.Legacy.Iterator.setCurr | String.Legacy.Iterator.setCurr : String.Legacy.Iterator → Char → String.Legacy.Iterator | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___setCurr) |
| def | String.Legacy.Iterator.find | String.Legacy.Iterator.find (it : String.Legacy.Iterator) (p : Char → Bool) : String.Legacy.Iterator | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___find) |
| def | String.Legacy.Iterator.foldUntil | String.Legacy.Iterator.foldUntil.{u_1} {α : Type u_1} (it : String.Legacy.Iterator) (init : α) (f : α → Char → Option α) : α × String.Legacy.Iterator | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___foldUntil) |
| def | String.Legacy.Iterator.extract | String.Legacy.Iterator.extract : String.Legacy.Iterator → String.Legacy.Iterator → String | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___extract) |
| def | String.Legacy.Iterator.remainingToString | String.Legacy.Iterator.remainingToString : String.Legacy.Iterator → String | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___remainingToString) |
| def | String.Legacy.Iterator.remainingBytes | String.Legacy.Iterator.remainingBytes : String.Legacy.Iterator → Nat | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___remainingBytes) |
| def | String.Legacy.Iterator.pos | String.Legacy.Iterator.pos (self : String.Legacy.Iterator) : String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___pos) |
| def | String.Legacy.Iterator.toString | String.Legacy.Iterator.toString (self : String.Legacy.Iterator) : String | [Reference](pages/Basic-Types/Strings/index.md#String___Legacy___Iterator___toString) |
| structure | String.Slice | String.Slice : Type | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___mk) |
| def | String.toSlice | String.toSlice (s : String) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___toSlice) |
| def | String.sliceFrom | String.sliceFrom (s : String) (p : s.Pos) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___sliceFrom) |
| def | String.sliceTo | String.sliceTo (s : String) (p : s.Pos) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___sliceTo) |
| structure | String.Slice.Pos | String.Slice.Pos (s : String.Slice) : Type | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pos___mk) |
| def | String.Slice.copy | String.Slice.copy (s : String.Slice) : String | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___copy) |
| def | String.Slice.isEmpty | String.Slice.isEmpty (s : String.Slice) : Bool | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___isEmpty) |
| def | String.Slice.utf8ByteSize | String.Slice.utf8ByteSize (s : String.Slice) : Nat | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___utf8ByteSize) |
| def | String.Slice.pos | String.Slice.pos (s : String.Slice) (off : String.Pos.Raw) (h : String.Pos.Raw.IsValidForSlice s off) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___pos) |
| def | String.Slice.pos! | String.Slice.pos! (s : String.Slice) (off : String.Pos.Raw) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___pos___) |
| def | String.Slice.pos? | String.Slice.pos? (s : String.Slice) (off : String.Pos.Raw) : Option s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___pos___-next) |
| def | String.Slice.startPos | String.Slice.startPos (s : String.Slice) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___startPos) |
| def | String.Slice.endPos | String.Slice.endPos (s : String.Slice) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___endPos) |
| def | String.Slice.rawEndPos | String.Slice.rawEndPos (s : String.Slice) : String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___rawEndPos) |
| def | String.Slice.sliceFrom | String.Slice.sliceFrom (s : String.Slice) (pos : s.Pos) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___sliceFrom) |
| def | String.Slice.sliceTo | String.Slice.sliceTo (s : String.Slice) (pos : s.Pos) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___sliceTo) |
| def | String.Slice.slice | String.Slice.slice (s : String.Slice) (newStart newEnd : s.Pos) (h : newStart ≤ newEnd) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___slice) |
| def | String.Slice.slice! | String.Slice.slice! (s : String.Slice) (newStart newEnd : s.Pos) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___slice___) |
| def | String.Slice.drop | String.Slice.drop (s : String.Slice) (n : Nat) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___drop) |
| def | String.Slice.dropEnd | String.Slice.dropEnd (s : String.Slice) (n : Nat) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___dropEnd) |
| def | String.Slice.dropEndWhile | String.Slice.dropEndWhile {ρ : Type} (s : String.Slice) (pat : ρ) [String.Slice.Pattern.BackwardPattern pat] : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___dropEndWhile) |
| def | String.Slice.dropPrefix | String.Slice.dropPrefix {ρ : Type} (s : String.Slice) (pat : ρ) [String.Slice.Pattern.ForwardPattern pat] : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___dropPrefix) |
| def | String.Slice.dropPrefix? | String.Slice.dropPrefix? {ρ : Type} (s : String.Slice) (pat : ρ) [String.Slice.Pattern.ForwardPattern pat] : Option String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___dropPrefix___) |
| def | String.Slice.dropSuffix | String.Slice.dropSuffix {ρ : Type} (s : String.Slice) (pat : ρ) [String.Slice.Pattern.BackwardPattern pat] : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___dropSuffix) |
| def | String.Slice.dropSuffix? | String.Slice.dropSuffix? {ρ : Type} (s : String.Slice) (pat : ρ) [String.Slice.Pattern.BackwardPattern pat] : Option String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___dropSuffix___) |
| def | String.Slice.dropWhile | String.Slice.dropWhile {ρ : Type} (s : String.Slice) (pat : ρ) [String.Slice.Pattern.ForwardPattern pat] : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___dropWhile) |
| def | String.Slice.take | String.Slice.take (s : String.Slice) (n : Nat) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___take) |
| def | String.Slice.takeEnd | String.Slice.takeEnd (s : String.Slice) (n : Nat) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___takeEnd) |
| def | String.Slice.takeEndWhile | String.Slice.takeEndWhile {ρ : Type} (s : String.Slice) (pat : ρ) [String.Slice.Pattern.BackwardPattern pat] : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___takeEndWhile) |
| def | String.Slice.takeWhile | String.Slice.takeWhile {ρ : Type} (s : String.Slice) (pat : ρ) [String.Slice.Pattern.ForwardPattern pat] : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___takeWhile) |
| def | String.Slice.front | String.Slice.front (s : String.Slice) : Char | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___front) |
| def | String.Slice.front? | String.Slice.front? (s : String.Slice) : Option Char | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___front___) |
| def | String.Slice.back | String.Slice.back (s : String.Slice) : Char | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___back) |
| def | String.Slice.back? | String.Slice.back? (s : String.Slice) : Option Char | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___back___) |
| def | String.Slice.getUTF8Byte | String.Slice.getUTF8Byte (s : String.Slice) (p : String.Pos.Raw) (h : p < s.rawEndPos) : UInt8 | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___getUTF8Byte) |
| def | String.Slice.getUTF8Byte! | String.Slice.getUTF8Byte! (s : String.Slice) (p : String.Pos.Raw) : UInt8 | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___getUTF8Byte___) |
| def | String.Slice.posGE | String.Slice.posGE (s : String.Slice) (offset : String.Pos.Raw) (h : offset ≤ s.rawEndPos) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___posGE) |
| def | String.Slice.posGT | String.Slice.posGT (s : String.Slice) (offset : String.Pos.Raw) (h : offset < s.rawEndPos) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___posGT) |
| def | String.Slice.contains | String.Slice.contains {ρ : Type} {σ : String.Slice → Type} [(s : String.Slice) → Std.Iterator (σ s) Id (String.Slice.Pattern.SearchStep s)] [(s : String.Slice)  … | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___contains) |
| def | String.Slice.startsWith | String.Slice.startsWith {ρ : Type} (s : String.Slice) (pat : ρ) [String.Slice.Pattern.ForwardPattern pat] : Bool | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___startsWith) |
| def | String.Slice.endsWith | String.Slice.endsWith {ρ : Type} (s : String.Slice) (pat : ρ) [String.Slice.Pattern.BackwardPattern pat] : Bool | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___endsWith) |
| def | String.Slice.all | String.Slice.all {ρ : Type} (s : String.Slice) (pat : ρ) [String.Slice.Pattern.ForwardPattern pat] : Bool | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___all) |
| def | String.Slice.find? | String.Slice.find? {ρ : Type} {σ : String.Slice → Type} [(s : String.Slice) → Std.Iterator (σ s) Id (String.Slice.Pattern.SearchStep s)] [(s : String.Slice) → S … | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___find___) |
| def | String.Slice.revFind? | String.Slice.revFind? {σ : String.Slice → Type} [(s : String.Slice) → Std.Iterator (σ s) Id (String.Slice.Pattern.SearchStep s)] [(s : String.Slice) → Std.Itera … | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___revFind___) |
| def | String.Slice.split | String.Slice.split {ρ : Type} {σ : String.Slice → Type} [(s : String.Slice) → Std.Iterator (σ s) Id (String.Slice.Pattern.SearchStep s)] (s : String.Slice) (pat … | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___split) |
| def | String.Slice.splitInclusive | String.Slice.splitInclusive {ρ : Type} {σ : String.Slice → Type} (s : String.Slice) (pat : ρ) [String.Slice.Pattern.ToForwardSearcher pat σ] : Std.Iter String.S … | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___splitInclusive) |
| def | String.Slice.lines | String.Slice.lines (s : String.Slice) : Std.Iter String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___lines) |
| def | String.Slice.trimAscii | String.Slice.trimAscii (s : String.Slice) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___trimAscii) |
| def | String.Slice.trimAsciiEnd | String.Slice.trimAsciiEnd (s : String.Slice) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___trimAsciiEnd) |
| def | String.Slice.trimAsciiStart | String.Slice.trimAsciiStart (s : String.Slice) : String.Slice | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___trimAsciiStart) |
| def | String.Slice.chars | String.Slice.chars (s : String.Slice) : Std.Iter Char | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___chars) |
| def | String.Slice.revChars | String.Slice.revChars (s : String.Slice) : Std.Iter Char | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___revChars) |
| def | String.Slice.positions | String.Slice.positions (s : String.Slice) : Std.Iter { p // p ≠ s.endPos } | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___positions) |
| def | String.Slice.revPositions | String.Slice.revPositions (s : String.Slice) : Std.Iter { p // p ≠ s.endPos } | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___revPositions) |
| def | String.Slice.bytes | String.Slice.bytes (s : String.Slice) : Std.Iter UInt8 | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___bytes) |
| def | String.Slice.revBytes | String.Slice.revBytes (s : String.Slice) : Std.Iter UInt8 | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___revBytes) |
| def | String.Slice.revSplit | String.Slice.revSplit {σ : String.Slice → Type} {ρ : Type} (s : String.Slice) (pat : ρ) [String.Slice.Pattern.ToBackwardSearcher pat σ] : Std.Iter String.Slice … | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___revSplit) |
| def | String.Slice.foldl | String.Slice.foldl.{u} {α : Type u} (f : α → Char → α) (init : α) (s : String.Slice) : α | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___foldl) |
| def | String.Slice.foldr | String.Slice.foldr.{u} {α : Type u} (f : Char → α → α) (init : α) (s : String.Slice) : α | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___foldr) |
| def | String.Slice.isNat | String.Slice.isNat (s : String.Slice) : Bool | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___isNat) |
| def | String.Slice.toNat! | String.Slice.toNat! (s : String.Slice) : Nat | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___toNat___) |
| def | String.Slice.toNat? | String.Slice.toNat? (s : String.Slice) : Option Nat | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___toNat___-next) |
| def | String.Slice.beq | String.Slice.beq (s1 s2 : String.Slice) : Bool | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___beq) |
| def | String.Slice.eqIgnoreAsciiCase | String.Slice.eqIgnoreAsciiCase (s1 s2 : String.Slice) : Bool | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___eqIgnoreAsciiCase) |
| type class | String.Slice.Pattern.ToForwardSearcher | String.Slice.Pattern.ToForwardSearcher {ρ : Type} (pat : ρ) (σ : outParam (String.Slice → Type)) : Type | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pattern___ToForwardSearcher___mk) |
| type class | String.Slice.Pattern.ForwardPattern | String.Slice.Pattern.ForwardPattern {ρ : Type} (pat : ρ) : Type | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pattern___ForwardPattern___mk) |
| type class | String.Slice.Pattern.ToBackwardSearcher | String.Slice.Pattern.ToBackwardSearcher {ρ : Type} (pat : ρ) (σ : outParam (String.Slice → Type)) : Type | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pattern___ToBackwardSearcher___mk) |
| type class | String.Slice.Pattern.BackwardPattern | String.Slice.Pattern.BackwardPattern {ρ : Type} (pat : ρ) : Type | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pattern___BackwardPattern___mk) |
| def | String.Slice.Pos.byte | String.Slice.Pos.byte {s : String.Slice} (pos : s.Pos) (h : pos ≠ s.endPos) : UInt8 | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pos___byte) |
| def | String.Slice.Pos.get | String.Slice.Pos.get {s : String.Slice} (pos : s.Pos) (h : pos ≠ s.endPos) : Char | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pos___get) |
| def | String.Slice.Pos.get! | String.Slice.Pos.get! {s : String.Slice} (pos : s.Pos) : Char | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pos___get___) |
| def | String.Slice.Pos.get? | String.Slice.Pos.get? {s : String.Slice} (pos : s.Pos) : Option Char | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pos___get___-next) |
| def | String.Slice.Pos.prev | String.Slice.Pos.prev {s : String.Slice} (pos : s.Pos) (h : pos ≠ s.startPos) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pos___prev) |
| def | String.Slice.Pos.prev! | String.Slice.Pos.prev! {s : String.Slice} (pos : s.Pos) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pos___prev___) |
| def | String.Slice.Pos.prev? | String.Slice.Pos.prev? {s : String.Slice} (pos : s.Pos) : Option s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pos___prev___-next) |
| def | String.Slice.Pos.prevn | String.Slice.Pos.prevn {s : String.Slice} (p : s.Pos) (n : Nat) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pos___prevn) |
| def | String.Slice.Pos.next | String.Slice.Pos.next {s : String.Slice} (pos : s.Pos) (h : pos ≠ s.endPos) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pos___next) |
| def | String.Slice.Pos.next! | String.Slice.Pos.next! {s : String.Slice} (pos : s.Pos) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pos___next___) |
| def | String.Slice.Pos.next? | String.Slice.Pos.next? {s : String.Slice} (pos : s.Pos) : Option s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pos___next___-next) |
| def | String.Slice.Pos.nextn | String.Slice.Pos.nextn {s : String.Slice} (p : s.Pos) (n : Nat) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pos___nextn) |
| def | String.Slice.Pos.cast | String.Slice.Pos.cast {s t : String.Slice} (pos : s.Pos) (h : s.copy = t.copy) : t.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pos___cast) |
| def | String.Slice.Pos.ofSlice | String.Slice.Pos.ofSlice {s : String.Slice} {p₀ p₁ : s.Pos} {h : p₀ ≤ p₁} (pos : (s.slice p₀ p₁ h).Pos) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pos___ofSlice) |
| def | String.Slice.Pos.str | String.Slice.Pos.str {s : String.Slice} (pos : s.Pos) : s.str.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pos___str) |
| def | String.Slice.Pos.copy | String.Slice.Pos.copy {s : String.Slice} (pos : s.Pos) : s.copy.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pos___copy) |
| def | String.Slice.Pos.ofSliceFrom | String.Slice.Pos.ofSliceFrom {s : String.Slice} {p₀ : s.Pos} (pos : (s.sliceFrom p₀).Pos) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pos___ofSliceFrom) |
| def | String.Slice.Pos.ofSliceTo | String.Slice.Pos.ofSliceTo {s : String.Slice} {p₀ : s.Pos} (pos : (s.sliceTo p₀).Pos) : s.Pos | [Reference](pages/Basic-Types/Strings/index.md#String___Slice___Pos___ofSliceTo) |
| def | String.toRawSubstring | String.toRawSubstring (s : String) : Substring.Raw | [Reference](pages/Basic-Types/Strings/index.md#String___toRawSubstring) |
| def | String.toRawSubstring' | String.toRawSubstring' (s : String) : Substring.Raw | [Reference](pages/Basic-Types/Strings/index.md#String___toRawSubstring___) |
| structure | Substring.Raw | Substring.Raw : Type | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___mk) |
| def | Substring.Raw.isEmpty | Substring.Raw.isEmpty (ss : Substring.Raw) : Bool | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___isEmpty) |
| def | Substring.Raw.bsize | Substring.Raw.bsize : Substring.Raw → Nat | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___bsize) |
| def | Substring.Raw.atEnd | Substring.Raw.atEnd : Substring.Raw → String.Pos.Raw → Bool | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___atEnd) |
| def | Substring.Raw.posOf | Substring.Raw.posOf (s : Substring.Raw) (c : Char) : String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___posOf) |
| def | Substring.Raw.next | Substring.Raw.next : Substring.Raw → String.Pos.Raw → String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___next) |
| def | Substring.Raw.nextn | Substring.Raw.nextn : Substring.Raw → Nat → String.Pos.Raw → String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___nextn) |
| def | Substring.Raw.prev | Substring.Raw.prev : Substring.Raw → String.Pos.Raw → String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___prev) |
| def | Substring.Raw.prevn | Substring.Raw.prevn : Substring.Raw → Nat → String.Pos.Raw → String.Pos.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___prevn) |
| def | Substring.Raw.foldl | Substring.Raw.foldl.{u} {α : Type u} (f : α → Char → α) (init : α) (s : Substring.Raw) : α | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___foldl) |
| def | Substring.Raw.foldr | Substring.Raw.foldr.{u} {α : Type u} (f : Char → α → α) (init : α) (s : Substring.Raw) : α | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___foldr) |
| def | Substring.Raw.all | Substring.Raw.all (s : Substring.Raw) (p : Char → Bool) : Bool | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___all) |
| def | Substring.Raw.any | Substring.Raw.any (s : Substring.Raw) (p : Char → Bool) : Bool | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___any) |
| def | Substring.Raw.beq | Substring.Raw.beq (ss1 ss2 : Substring.Raw) : Bool | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___beq) |
| def | Substring.Raw.sameAs | Substring.Raw.sameAs (ss1 ss2 : Substring.Raw) : Bool | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___sameAs) |
| def | Substring.Raw.commonPrefix | Substring.Raw.commonPrefix (s t : Substring.Raw) : Substring.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___commonPrefix) |
| def | Substring.Raw.commonSuffix | Substring.Raw.commonSuffix (s t : Substring.Raw) : Substring.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___commonSuffix) |
| def | Substring.Raw.dropPrefix? | Substring.Raw.dropPrefix? (s pre : Substring.Raw) : Option Substring.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___dropPrefix___) |
| def | Substring.Raw.dropSuffix? | Substring.Raw.dropSuffix? (s suff : Substring.Raw) : Option Substring.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___dropSuffix___) |
| def | Substring.Raw.get | Substring.Raw.get : Substring.Raw → String.Pos.Raw → Char | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___get) |
| def | Substring.Raw.contains | Substring.Raw.contains (s : Substring.Raw) (c : Char) : Bool | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___contains) |
| def | Substring.Raw.front | Substring.Raw.front (s : Substring.Raw) : Char | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___front) |
| def | Substring.Raw.drop | Substring.Raw.drop : Substring.Raw → Nat → Substring.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___drop) |
| def | Substring.Raw.dropWhile | Substring.Raw.dropWhile : Substring.Raw → (Char → Bool) → Substring.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___dropWhile) |
| def | Substring.Raw.dropRight | Substring.Raw.dropRight : Substring.Raw → Nat → Substring.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___dropRight) |
| def | Substring.Raw.dropRightWhile | Substring.Raw.dropRightWhile : Substring.Raw → (Char → Bool) → Substring.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___dropRightWhile) |
| def | Substring.Raw.take | Substring.Raw.take : Substring.Raw → Nat → Substring.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___take) |
| def | Substring.Raw.takeWhile | Substring.Raw.takeWhile : Substring.Raw → (Char → Bool) → Substring.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___takeWhile) |
| def | Substring.Raw.takeRight | Substring.Raw.takeRight : Substring.Raw → Nat → Substring.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___takeRight) |
| def | Substring.Raw.takeRightWhile | Substring.Raw.takeRightWhile : Substring.Raw → (Char → Bool) → Substring.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___takeRightWhile) |
| def | Substring.Raw.extract | Substring.Raw.extract : Substring.Raw → String.Pos.Raw → String.Pos.Raw → Substring.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___extract) |
| def | Substring.Raw.trim | Substring.Raw.trim : Substring.Raw → Substring.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___trim) |
| def | Substring.Raw.trimLeft | Substring.Raw.trimLeft (s : Substring.Raw) : Substring.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___trimLeft) |
| def | Substring.Raw.trimRight | Substring.Raw.trimRight (s : Substring.Raw) : Substring.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___trimRight) |
| def | Substring.Raw.splitOn | Substring.Raw.splitOn (s : Substring.Raw) (sep : String := " ") : List Substring.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___splitOn) |
| def | Substring.Raw.repair | Substring.Raw.repair : Substring.Raw → Substring.Raw | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___repair) |
| def | Substring.Raw.toString | Substring.Raw.toString : Substring.Raw → String | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___toString) |
| def | Substring.Raw.isNat | Substring.Raw.isNat (s : Substring.Raw) : Bool | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___isNat) |
| def | Substring.Raw.toNat? | Substring.Raw.toNat? (s : Substring.Raw) : Option Nat | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___toNat___) |
| def | Substring.Raw.toLegacyIterator | Substring.Raw.toLegacyIterator : Substring.Raw → String.Legacy.Iterator | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___toLegacyIterator) |
| def | Substring.Raw.toName | Substring.Raw.toName (s : Substring.Raw) : Lean.Name | [Reference](pages/Basic-Types/Strings/index.md#Substring___Raw___toName) |
| def | String.toName | String.toName (s : String) : Lean.Name | [Reference](pages/Basic-Types/Strings/index.md#String___toName) |
| def | String.quote | String.quote (s : String) : String | [Reference](pages/Basic-Types/Strings/index.md#String___quote) |
| def | String.getUTF8Byte | String.getUTF8Byte (s : String) (p : String.Pos.Raw) (h : p < s.rawEndPos) : UInt8 | [Reference](pages/Basic-Types/Strings/index.md#String___getUTF8Byte) |
| def | String.utf8ByteSize | String.utf8ByteSize (s : String) : Nat | [Reference](pages/Basic-Types/Strings/index.md#String___utf8ByteSize) |
| def | String.utf8EncodeChar | String.utf8EncodeChar (c : Char) : List UInt8 | [Reference](pages/Basic-Types/Strings/index.md#String___utf8EncodeChar) |
| def | String.fromUTF8 | String.fromUTF8 (a : ByteArray) (h : a.IsValidUTF8) : String | [Reference](pages/Basic-Types/Strings/index.md#String___fromUTF8) |
| def | String.fromUTF8? | String.fromUTF8? (a : ByteArray) : Option String | [Reference](pages/Basic-Types/Strings/index.md#String___fromUTF8___) |
| def | String.fromUTF8! | String.fromUTF8! (a : ByteArray) : String | [Reference](pages/Basic-Types/Strings/index.md#String___fromUTF8___-next) |
| def | String.toUTF8 | String.toUTF8 (a : String) : ByteArray | [Reference](pages/Basic-Types/Strings/index.md#String___toUTF8) |
| def | String.crlfToLf | String.crlfToLf (text : String) : String | [Reference](pages/Basic-Types/Strings/index.md#String___crlfToLf) |
| FFI type | lean_string_object | typedef struct { lean_object m_header; /* byte length including '\0' terminator */ size_t m_size; size_t m_capacity; /* UTF8 length */ size_t m_length; char m_d … | [Reference](pages/Basic-Types/Strings/index.md#lean_string_object) |
| FFI function | lean_is_string | bool lean_is_string(lean_object * o) | [Reference](pages/Basic-Types/Strings/index.md#lean_is_string) |
| FFI function | lean_to_string | lean_string_object * lean_to_string(lean_object * o) | [Reference](pages/Basic-Types/Strings/index.md#lean_to_string) |
| def | Unit | Unit : Type | [Reference](pages/Basic-Types/The-Unit-Type/index.md#Unit) |
| def | Unit.unit | Unit.unit : Unit | [Reference](pages/Basic-Types/The-Unit-Type/index.md#Unit___unit) |
| inductive type | PUnit | PUnit.{u} : Sort u | [Reference](pages/Basic-Types/The-Unit-Type/index.md#PUnit___unit) |
| inductive type | Empty | Empty : Type | [Reference](pages/Basic-Types/The-Empty-Type/index.md#Empty) |
| inductive type | PEmpty | PEmpty.{u} : Sort u | [Reference](pages/Basic-Types/The-Empty-Type/index.md#PEmpty) |
| def | Empty.elim | Empty.elim.{u} {C : Sort u} : Empty → C | [Reference](pages/Basic-Types/The-Empty-Type/index.md#Empty___elim) |
| def | PEmpty.elim | PEmpty.elim.{u_1, u_2} {C : Sort u_1} : PEmpty → C | [Reference](pages/Basic-Types/The-Empty-Type/index.md#PEmpty___elim) |
| inductive type | Bool | Bool : Type | [Reference](pages/Basic-Types/Booleans/index.md#Bool___false) |
| syntax | Boolean Infix Operators |  | [Reference](pages/Basic-Types/Booleans/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Boolean Negation |  | [Reference](pages/Basic-Types/Booleans/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | cond | cond.{u} {α : Sort u} (c : Bool) (x y : α) : α | [Reference](pages/Basic-Types/Booleans/index.md#cond) |
| def | Bool.dcond | Bool.dcond.{u} {α : Sort u} (c : Bool) (x : c = true → α) (y : c = false → α) : α | [Reference](pages/Basic-Types/Booleans/index.md#Bool___dcond) |
| def | Bool.not | Bool.not (x : Bool) : Bool | [Reference](pages/Basic-Types/Booleans/index.md#Bool___not) |
| def | Bool.and | Bool.and (x y : Bool) : Bool | [Reference](pages/Basic-Types/Booleans/index.md#Bool___and) |
| def | Bool.or | Bool.or (x y : Bool) : Bool | [Reference](pages/Basic-Types/Booleans/index.md#Bool___or) |
| def | Bool.xor | Bool.xor : Bool → Bool → Bool | [Reference](pages/Basic-Types/Booleans/index.md#Bool___xor) |
| def | Bool.decEq | Bool.decEq (a b : Bool) : Decidable (a = b) | [Reference](pages/Basic-Types/Booleans/index.md#Bool___decEq) |
| def | Bool.toISize | Bool.toISize (b : Bool) : ISize | [Reference](pages/Basic-Types/Booleans/index.md#Bool___toISize) |
| def | Bool.toUInt8 | Bool.toUInt8 (b : Bool) : UInt8 | [Reference](pages/Basic-Types/Booleans/index.md#Bool___toUInt8) |
| def | Bool.toUInt16 | Bool.toUInt16 (b : Bool) : UInt16 | [Reference](pages/Basic-Types/Booleans/index.md#Bool___toUInt16) |
| def | Bool.toUInt32 | Bool.toUInt32 (b : Bool) : UInt32 | [Reference](pages/Basic-Types/Booleans/index.md#Bool___toUInt32) |
| def | Bool.toUInt64 | Bool.toUInt64 (b : Bool) : UInt64 | [Reference](pages/Basic-Types/Booleans/index.md#Bool___toUInt64) |
| def | Bool.toUSize | Bool.toUSize (b : Bool) : USize | [Reference](pages/Basic-Types/Booleans/index.md#Bool___toUSize) |
| def | Bool.toInt8 | Bool.toInt8 (b : Bool) : Int8 | [Reference](pages/Basic-Types/Booleans/index.md#Bool___toInt8) |
| def | Bool.toInt16 | Bool.toInt16 (b : Bool) : Int16 | [Reference](pages/Basic-Types/Booleans/index.md#Bool___toInt16) |
| def | Bool.toInt32 | Bool.toInt32 (b : Bool) : Int32 | [Reference](pages/Basic-Types/Booleans/index.md#Bool___toInt32) |
| def | Bool.toInt64 | Bool.toInt64 (b : Bool) : Int64 | [Reference](pages/Basic-Types/Booleans/index.md#Bool___toInt64) |
| def | Bool.toNat | Bool.toNat (b : Bool) : Nat | [Reference](pages/Basic-Types/Booleans/index.md#Bool___toNat) |
| def | Bool.toInt | Bool.toInt (b : Bool) : Int | [Reference](pages/Basic-Types/Booleans/index.md#Bool___toInt) |
| inductive type | Option | Option.{u} (α : Type u) : Type u | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___none) |
| def | Option.get | Option.get.{u} {α : Type u} (o : Option α) : o.isSome = true → α | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___get) |
| def | Option.get! | Option.get!.{u} {α : Type u} [Inhabited α] : Option α → α | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___get___) |
| def | Option.getD | Option.getD.{u_1} {α : Type u_1} (opt : Option α) (dflt : α) : α | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___getD) |
| def | Option.getDM | Option.getDM.{u_1, u_2} {m : Type u_1 → Type u_2} {α : Type u_1} [Pure m] (x : Option α) (y : m α) : m α | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___getDM) |
| def | Option.getM | Option.getM.{u_1, u_2} {m : Type u_1 → Type u_2} {α : Type u_1} [Alternative m] : Option α → m α | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___getM) |
| def | Option.elim | Option.elim.{u_1, u_2} {α : Type u_1} {β : Sort u_2} : Option α → β → (α → β) → β | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___elim) |
| def | Option.elimM | Option.elimM.{u_1, u_2} {m : Type u_1 → Type u_2} {α β : Type u_1} [Monad m] (x : m (Option α)) (y : m β) (z : α → m β) : m β | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___elimM) |
| def | Option.merge | Option.merge.{u_1} {α : Type u_1} (fn : α → α → α) : Option α → Option α → Option α | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___merge) |
| def | Option.isNone | Option.isNone.{u_1} {α : Type u_1} : Option α → Bool | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___isNone) |
| def | Option.isSome | Option.isSome.{u_1} {α : Type u_1} : Option α → Bool | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___isSome) |
| def | Option.isEqSome | Option.isEqSome.{u_1} {α : Type u_1} [BEq α] : Option α → α → Bool | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___isEqSome) |
| def | Option.min | Option.min.{u_1} {α : Type u_1} [Min α] : Option α → Option α → Option α | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___min) |
| def | Option.max | Option.max.{u_1} {α : Type u_1} [Max α] : Option α → Option α → Option α | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___max) |
| def | Option.lt | Option.lt.{u_1, u_2} {α : Type u_1} {β : Type u_2} (r : α → β → Prop) : Option α → Option β → Prop | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___lt) |
| def | Option.decidableEqNone | Option.decidableEqNone.{u_1} {α : Type u_1} (o : Option α) : Decidable (o = none) | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___decidableEqNone) |
| def | Option.toArray | Option.toArray.{u_1} {α : Type u_1} : Option α → Array α | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___toArray) |
| def | Option.toList | Option.toList.{u_1} {α : Type u_1} : Option α → List α | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___toList) |
| def | Option.repr | Option.repr.{u_1} {α : Type u_1} [Repr α] : Option α → Nat → Std.Format | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___repr) |
| def | Option.format | Option.format.{u} {α : Type u} [Std.ToFormat α] : Option α → Std.Format | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___format) |
| def | Option.guard | Option.guard.{u_1} {α : Type u_1} (p : α → Bool) (a : α) : Option α | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___guard) |
| def | Option.bind | Option.bind.{u_1, u_2} {α : Type u_1} {β : Type u_2} : Option α → (α → Option β) → Option β | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___bind) |
| def | Option.bindM | Option.bindM.{u_1, u_2, u_3} {m : Type u_1 → Type u_2} {α : Type u_3} {β : Type u_1} [Pure m] (f : α → m (Option β)) : Option α → m (Option β) | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___bindM) |
| def | Option.join | Option.join.{u_1} {α : Type u_1} (x : Option (Option α)) : Option α | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___join) |
| def | Option.sequence | Option.sequence.{u, u_1} {m : Type u → Type u_1} [Applicative m] {α : Type u} : Option (m α) → m (Option α) | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___sequence) |
| def | Option.tryCatch | Option.tryCatch.{u_1} {α : Type u_1} (x : Option α) (handle : Unit → Option α) : Option α | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___tryCatch) |
| def | Option.or | Option.or.{u_1} {α : Type u_1} : Option α → Option α → Option α | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___or) |
| def | Option.orElse | Option.orElse.{u_1} {α : Type u_1} : Option α → (Unit → Option α) → Option α | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___orElse) |
| def | Option.all | Option.all.{u_1} {α : Type u_1} (p : α → Bool) : Option α → Bool | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___all) |
| def | Option.any | Option.any.{u_1} {α : Type u_1} (p : α → Bool) : Option α → Bool | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___any) |
| def | Option.filter | Option.filter.{u_1} {α : Type u_1} (p : α → Bool) : Option α → Option α | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___filter) |
| def | Option.filterM | Option.filterM.{u_1} {m : Type → Type u_1} {α : Type} [Applicative m] (p : α → m Bool) : Option α → m (Option α) | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___filterM) |
| def | Option.forM | Option.forM.{u_1, u_2, u_3} {m : Type u_1 → Type u_2} {α : Type u_3} [Pure m] : Option α → (α → m PUnit) → m PUnit | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___forM) |
| def | Option.map | Option.map.{u_1, u_2} {α : Type u_1} {β : Type u_2} (f : α → β) : Option α → Option β | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___map) |
| def | Option.mapA | Option.mapA.{u_1, u_2, u_3} {m : Type u_1 → Type u_2} {α : Type u_3} {β : Type u_1} [Applicative m] (f : α → m β) : Option α → m (Option β) | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___mapA) |
| def | Option.mapM | Option.mapM.{u_1, u_2, u_3} {m : Type u_1 → Type u_2} {α : Type u_3} {β : Type u_1} [Applicative m] (f : α → m β) : Option α → m (Option β) | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___mapM) |
| def | Option.attach | Option.attach.{u_1} {α : Type u_1} (xs : Option α) : Option { x // xs = some x } | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___attach) |
| def | Option.attachWith | Option.attachWith.{u_1} {α : Type u_1} (xs : Option α) (P : α → Prop) (H : ∀ (x : α), xs = some x → P x) : Option { x // P x } | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___attachWith) |
| def | Option.unattach | Option.unattach.{u_1} {α : Type u_1} {p : α → Prop} (o : Option { x // p x }) : Option α | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___unattach) |
| def | Option.choice | Option.choice.{u_1} (α : Type u_1) : Option α | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___choice) |
| def | Option.pbind | Option.pbind.{u_1, u_2} {α : Type u_1} {β : Type u_2} (o : Option α) (f : (a : α) → o = some a → Option β) : Option β | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___pbind) |
| def | Option.pelim | Option.pelim.{u_1, u_2} {α : Type u_1} {β : Sort u_2} (o : Option α) (b : β) (f : (a : α) → o = some a → β) : β | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___pelim) |
| def | Option.pmap | Option.pmap.{u_1, u_2} {α : Type u_1} {β : Type u_2} {p : α → Prop} (f : (a : α) → p a → β) (o : Option α) : (∀ (a : α), o = some a → p a) → Option β | [Reference](pages/Basic-Types/Optional-Values/index.md#Option___pmap) |
| syntax | Product Types |  | [Reference](pages/Basic-Types/Tuples/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Pairs |  | [Reference](pages/Basic-Types/Tuples/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| structure | Prod | Prod.{u, v} (α : Type u) (β : Type v) : Type (max u v) | [Reference](pages/Basic-Types/Tuples/index.md#Prod___mk) |
| syntax | Products of Arbitrary Sorts |  | [Reference](pages/Basic-Types/Tuples/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| structure | PProd | PProd.{u, v} (α : Sort u) (β : Sort v) : Sort (max (max 1 u) v) | [Reference](pages/Basic-Types/Tuples/index.md#PProd___mk) |
| structure | MProd | MProd.{u} (α β : Type u) : Type u | [Reference](pages/Basic-Types/Tuples/index.md#MProd___mk) |
| def | Prod.map | Prod.map.{u₁, u₂, v₁, v₂} {α₁ : Type u₁} {α₂ : Type u₂} {β₁ : Type v₁} {β₂ : Type v₂} (f : α₁ → α₂) (g : β₁ → β₂) : α₁ × β₁ → α₂ × β₂ | [Reference](pages/Basic-Types/Tuples/index.md#Prod___map) |
| def | Prod.swap | Prod.swap.{u_1, u_2} {α : Type u_1} {β : Type u_2} : α × β → β × α | [Reference](pages/Basic-Types/Tuples/index.md#Prod___swap) |
| def | Prod.allI | Prod.allI (i : Nat × Nat) (f : (j : Nat) → i.fst ≤ j → j < i.snd → Bool) : Bool | [Reference](pages/Basic-Types/Tuples/index.md#Prod___allI) |
| def | Prod.anyI | Prod.anyI (i : Nat × Nat) (f : (j : Nat) → i.fst ≤ j → j < i.snd → Bool) : Bool | [Reference](pages/Basic-Types/Tuples/index.md#Prod___anyI) |
| def | Prod.foldI | Prod.foldI.{u} {α : Type u} (i : Nat × Nat) (f : (j : Nat) → i.fst ≤ j → j < i.snd → α → α) (init : α) : α | [Reference](pages/Basic-Types/Tuples/index.md#Prod___foldI) |
| def | Prod.lexLt | Prod.lexLt.{u_1, u_2} {α : Type u_1} {β : Type u_2} [LT α] [LT β] (s t : α × β) : Prop | [Reference](pages/Basic-Types/Tuples/index.md#Prod___lexLt) |
| syntax | Dependent Pair Types |  | [Reference](pages/Basic-Types/Tuples/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| structure | Sigma | Sigma.{u, v} {α : Type u} (β : α → Type v) : Type (max u v) | [Reference](pages/Basic-Types/Tuples/index.md#Sigma___mk) |
| syntax | Fully-Polymorphic Dependent Pair Types |  | [Reference](pages/Basic-Types/Tuples/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| structure | PSigma | PSigma.{u, v} {α : Sort u} (β : α → Sort v) : Sort (max (max 1 u) v) | [Reference](pages/Basic-Types/Tuples/index.md#PSigma___mk) |
| inductive type | Sum | Sum.{u, v} (α : Type u) (β : Type v) : Type (max u v) | [Reference](pages/Basic-Types/Sum-Types/index.md#Sum___inl) |
| inductive type | PSum | PSum.{u, v} (α : Sort u) (β : Sort v) : Sort (max (max 1 u) v) | [Reference](pages/Basic-Types/Sum-Types/index.md#PSum___inl) |
| syntax | Sum Types |  | [Reference](pages/Basic-Types/Sum-Types/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Potentially-Propositional Sum Types |  | [Reference](pages/Basic-Types/Sum-Types/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Sum.isLeft | Sum.isLeft.{u_1, u_2} {α : Type u_1} {β : Type u_2} : α ⊕ β → Bool | [Reference](pages/Basic-Types/Sum-Types/index.md#Sum___isLeft) |
| def | Sum.isRight | Sum.isRight.{u_1, u_2} {α : Type u_1} {β : Type u_2} : α ⊕ β → Bool | [Reference](pages/Basic-Types/Sum-Types/index.md#Sum___isRight) |
| def | Sum.elim | Sum.elim.{u_1, u_2, u_3} {α : Type u_1} {β : Type u_2} {γ : Sort u_3} (f : α → γ) (g : β → γ) : α ⊕ β → γ | [Reference](pages/Basic-Types/Sum-Types/index.md#Sum___elim) |
| def | Sum.getLeft | Sum.getLeft.{u_1, u_2} {α : Type u_1} {β : Type u_2} (ab : α ⊕ β) : ab.isLeft = true → α | [Reference](pages/Basic-Types/Sum-Types/index.md#Sum___getLeft) |
| def | Sum.getLeft? | Sum.getLeft?.{u_1, u_2} {α : Type u_1} {β : Type u_2} : α ⊕ β → Option α | [Reference](pages/Basic-Types/Sum-Types/index.md#Sum___getLeft___) |
| def | Sum.getRight | Sum.getRight.{u_1, u_2} {α : Type u_1} {β : Type u_2} (ab : α ⊕ β) : ab.isRight = true → β | [Reference](pages/Basic-Types/Sum-Types/index.md#Sum___getRight) |
| def | Sum.getRight? | Sum.getRight?.{u_1, u_2} {α : Type u_1} {β : Type u_2} : α ⊕ β → Option β | [Reference](pages/Basic-Types/Sum-Types/index.md#Sum___getRight___) |
| def | Sum.map | Sum.map.{u_1, u_2, u_3, u_4} {α : Type u_1} {α' : Type u_2} {β : Type u_3} {β' : Type u_4} (f : α → α') (g : β → β') : α ⊕ β → α' ⊕ β' | [Reference](pages/Basic-Types/Sum-Types/index.md#Sum___map) |
| def | Sum.swap | Sum.swap.{u_1, u_2} {α : Type u_1} {β : Type u_2} : α ⊕ β → β ⊕ α | [Reference](pages/Basic-Types/Sum-Types/index.md#Sum___swap) |
| def | Sum.inhabitedLeft | Sum.inhabitedLeft.{u, v} {α : Type u} {β : Type v} [Inhabited α] : Inhabited (α ⊕ β) | [Reference](pages/Basic-Types/Sum-Types/index.md#Sum___inhabitedLeft) |
| def | Sum.inhabitedRight | Sum.inhabitedRight.{u, v} {α : Type u} {β : Type v} [Inhabited β] : Inhabited (α ⊕ β) | [Reference](pages/Basic-Types/Sum-Types/index.md#Sum___inhabitedRight) |
| def | PSum.inhabitedLeft | PSum.inhabitedLeft.{u_1, u_2} {α : Sort u_1} {β : Sort u_2} [Inhabited α] : Inhabited (α ⊕' β) | [Reference](pages/Basic-Types/Sum-Types/index.md#PSum___inhabitedLeft) |
| def | PSum.inhabitedRight | PSum.inhabitedRight.{u_1, u_2} {α : Sort u_1} {β : Sort u_2} [Inhabited β] : Inhabited (α ⊕' β) | [Reference](pages/Basic-Types/Sum-Types/index.md#PSum___inhabitedRight) |
| inductive type | List | List.{u} (α : Type u) : Type u | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___nil) |
| syntax | List Literals |  | [Reference](pages/Basic-Types/Linked-Lists/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | List Construction |  | [Reference](pages/Basic-Types/Linked-Lists/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | List.IsPrefix | List.IsPrefix.{u} {α : Type u} (l₁ l₂ : List α) : Prop | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___IsPrefix) |
| syntax | List Prefix |  | [Reference](pages/Basic-Types/Linked-Lists/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | List.IsSuffix | List.IsSuffix.{u} {α : Type u} (l₁ l₂ : List α) : Prop | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___IsSuffix) |
| syntax | List Suffix |  | [Reference](pages/Basic-Types/Linked-Lists/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | List.IsInfix | List.IsInfix.{u} {α : Type u} (l₁ l₂ : List α) : Prop | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___IsInfix) |
| syntax | List Infix |  | [Reference](pages/Basic-Types/Linked-Lists/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| inductive predicate | List.Sublist | List.Sublist.{u_1} {α : Type u_1} : List α → List α → Prop | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___Sublist___slnil) |
| syntax | Sublists |  | [Reference](pages/Basic-Types/Linked-Lists/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| inductive predicate | List.Perm | List.Perm.{u} {α : Type u} : List α → List α → Prop | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___Perm___nil) |
| syntax | List Permutation |  | [Reference](pages/Basic-Types/Linked-Lists/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| inductive predicate | List.Pairwise | List.Pairwise.{u} {α : Type u} (R : α → α → Prop) : List α → Prop | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___Pairwise___nil) |
| def | List.Nodup | List.Nodup.{u} {α : Type u} : List α → Prop | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___Nodup) |
| inductive predicate | List.Lex | List.Lex.{u} {α : Type u} (r : α → α → Prop) (as bs : List α) : Prop | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___Lex___nil) |
| inductive predicate | List.Mem | List.Mem.{u} {α : Type u} (a : α) : List α → Prop | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___Mem___head) |
| def | List.singleton | List.singleton.{u} {α : Type u} (a : α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___singleton) |
| def | List.concat | List.concat.{u} {α : Type u} : List α → α → List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___concat) |
| def | List.replicate | List.replicate.{u} {α : Type u} (n : Nat) (a : α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___replicate) |
| def | List.replicateTR | List.replicateTR.{u} {α : Type u} (n : Nat) (a : α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___replicateTR) |
| def | List.ofFn | List.ofFn.{u_1} {α : Type u_1} {n : Nat} (f : Fin n → α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___ofFn) |
| def | List.append | List.append.{u_1} {α : Type u_1} (xs ys : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___append) |
| def | List.appendTR | List.appendTR.{u} {α : Type u} (as bs : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___appendTR) |
| def | List.range | List.range (n : Nat) : List Nat | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___range) |
| def | List.range' | List.range' (start len : Nat) (step : Nat := 1) : List Nat | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___range___) |
| def | List.range'TR | List.range'TR (s n : Nat) (step : Nat := 1) : List Nat | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___range___TR) |
| def | List.finRange | List.finRange (n : Nat) : List (Fin n) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___finRange) |
| def | List.length | List.length.{u_1} {α : Type u_1} : List α → Nat | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___length) |
| def | List.lengthTR | List.lengthTR.{u_1} {α : Type u_1} (as : List α) : Nat | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___lengthTR) |
| def | List.isEmpty | List.isEmpty.{u} {α : Type u} : List α → Bool | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___isEmpty) |
| def | List.head | List.head.{u} {α : Type u} (as : List α) : as ≠ [] → α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___head) |
| def | List.head? | List.head?.{u} {α : Type u} : List α → Option α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___head___) |
| def | List.headD | List.headD.{u} {α : Type u} (as : List α) (fallback : α) : α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___headD) |
| def | List.head! | List.head!.{u_1} {α : Type u_1} [Inhabited α] : List α → α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___head___-next) |
| def | List.tail | List.tail.{u} {α : Type u} : List α → List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___tail) |
| def | List.tail! | List.tail!.{u_1} {α : Type u_1} : List α → List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___tail___) |
| def | List.tail? | List.tail?.{u} {α : Type u} : List α → Option (List α) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___tail___-next) |
| def | List.tailD | List.tailD.{u} {α : Type u} (l fallback : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___tailD) |
| def | List.get | List.get.{u} {α : Type u} (as : List α) : Fin as.length → α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___get) |
| def | List.getD | List.getD.{u_1} {α : Type u_1} (as : List α) (i : Nat) (fallback : α) : α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___getD) |
| def | List.getLast | List.getLast.{u} {α : Type u} (as : List α) : as ≠ [] → α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___getLast) |
| def | List.getLast? | List.getLast?.{u} {α : Type u} : List α → Option α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___getLast___) |
| def | List.getLastD | List.getLastD.{u} {α : Type u} (as : List α) (fallback : α) : α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___getLastD) |
| def | List.getLast! | List.getLast!.{u_1} {α : Type u_1} [Inhabited α] : List α → α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___getLast___-next) |
| def | List.lookup | List.lookup.{u, v} {α : Type u} {β : Type v} [BEq α] : α → List (α × β) → Option β | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___lookup) |
| def | List.max? | List.max?.{u} {α : Type u} [Max α] : List α → Option α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___max___) |
| def | List.min? | List.min?.{u} {α : Type u} [Min α] : List α → Option α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___min___) |
| def | List.count | List.count.{u} {α : Type u} [BEq α] (a : α) : List α → Nat | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___count) |
| def | List.countP | List.countP.{u} {α : Type u} (p : α → Bool) (l : List α) : Nat | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___countP) |
| def | List.idxOf | List.idxOf.{u} {α : Type u} [BEq α] (a : α) : List α → Nat | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___idxOf) |
| def | List.idxOf? | List.idxOf?.{u} {α : Type u} [BEq α] (a : α) : List α → Option Nat | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___idxOf___) |
| def | List.finIdxOf? | List.finIdxOf?.{u} {α : Type u} [BEq α] (a : α) (l : List α) : Option (Fin l.length) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___finIdxOf___) |
| def | List.find? | List.find?.{u} {α : Type u} (p : α → Bool) : List α → Option α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___find___) |
| def | List.findFinIdx? | List.findFinIdx?.{u} {α : Type u} (p : α → Bool) (l : List α) : Option (Fin l.length) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___findFinIdx___) |
| def | List.findIdx | List.findIdx.{u} {α : Type u} (p : α → Bool) (l : List α) : Nat | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___findIdx) |
| def | List.findIdx? | List.findIdx?.{u} {α : Type u} (p : α → Bool) (l : List α) : Option Nat | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___findIdx___) |
| def | List.findM? | List.findM?.{u} {m : Type → Type u} [Monad m] {α : Type} (p : α → m Bool) : List α → m (Option α) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___findM___) |
| def | List.findSome? | List.findSome?.{u, v} {α : Type u} {β : Type v} (f : α → Option β) : List α → Option β | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___findSome___) |
| def | List.findSomeM? | List.findSomeM?.{u, v, w} {m : Type u → Type v} [Monad m] {α : Type w} {β : Type u} (f : α → m (Option β)) : List α → m (Option β) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___findSomeM___) |
| def | List.toArray | List.toArray.{u_1} {α : Type u_1} (xs : List α) : Array α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___toArray) |
| def | List.toArrayImpl | List.toArrayImpl.{u_1} {α : Type u_1} (xs : List α) : Array α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___toArrayImpl) |
| def | List.toByteArray | List.toByteArray (bs : List UInt8) : ByteArray | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___toByteArray) |
| def | List.toFloatArray | List.toFloatArray (ds : List Float) : FloatArray | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___toFloatArray) |
| def | List.toString | List.toString.{u_1} {α : Type u_1} [ToString α] : List α → String | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___toString) |
| def | List | List.set.{u_1} {α : Type u_1} (l : List α) (n : Nat) (a : α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___set) |
| def | List.setTR | List.setTR.{u_1} {α : Type u_1} (l : List α) (n : Nat) (a : α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___setTR) |
| def | List.modify | List.modify.{u} {α : Type u} (l : List α) (i : Nat) (f : α → α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___modify) |
| def | List.modifyTR | List.modifyTR.{u_1} {α : Type u_1} (l : List α) (i : Nat) (f : α → α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___modifyTR) |
| def | List.modifyHead | List.modifyHead.{u} {α : Type u} (f : α → α) : List α → List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___modifyHead) |
| def | List.modifyTailIdx | List.modifyTailIdx.{u} {α : Type u} (l : List α) (i : Nat) (f : List α → List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___modifyTailIdx) |
| def | List.erase | List.erase.{u_1} {α : Type u_1} [BEq α] : List α → α → List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___erase) |
| def | List.eraseTR | List.eraseTR.{u_1} {α : Type u_1} [BEq α] (l : List α) (a : α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___eraseTR) |
| def | List.eraseDups | List.eraseDups.{u_1} {α : Type u_1} [BEq α] (as : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___eraseDups) |
| def | List.eraseIdx | List.eraseIdx.{u} {α : Type u} (l : List α) (i : Nat) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___eraseIdx) |
| def | List.eraseIdxTR | List.eraseIdxTR.{u_1} {α : Type u_1} (l : List α) (n : Nat) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___eraseIdxTR) |
| def | List.eraseP | List.eraseP.{u} {α : Type u} (p : α → Bool) : List α → List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___eraseP) |
| def | List.erasePTR | List.erasePTR.{u_1} {α : Type u_1} (p : α → Bool) (l : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___erasePTR) |
| def | List.eraseReps | List.eraseReps.{u_1} {α : Type u_1} [BEq α] (as : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___eraseReps) |
| def | List.extract | List.extract.{u} {α : Type u} (l : List α) (start : Nat := 0) (stop : Nat := l.length) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___extract) |
| def | List.removeAll | List.removeAll.{u} {α : Type u} [BEq α] (xs ys : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___removeAll) |
| def | List.replace | List.replace.{u} {α : Type u} [BEq α] (l : List α) (a b : α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___replace) |
| def | List.replaceTR | List.replaceTR.{u_1} {α : Type u_1} [BEq α] (l : List α) (b c : α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___replaceTR) |
| def | List.reverse | List.reverse.{u} {α : Type u} (as : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___reverse) |
| def | List.flatten | List.flatten.{u_1} {α : Type u_1} : List (List α) → List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___flatten) |
| def | List.flattenTR | List.flattenTR.{u_1} {α : Type u_1} (l : List (List α)) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___flattenTR) |
| def | List.rotateLeft | List.rotateLeft.{u} {α : Type u} (xs : List α) (i : Nat := 1) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___rotateLeft) |
| def | List.rotateRight | List.rotateRight.{u} {α : Type u} (xs : List α) (i : Nat := 1) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___rotateRight) |
| def | List.leftpad | List.leftpad.{u} {α : Type u} (n : Nat) (a : α) (l : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___leftpad) |
| def | List.leftpadTR | List.leftpadTR.{u} {α : Type u} (n : Nat) (a : α) (l : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___leftpadTR) |
| def | List.rightpad | List.rightpad.{u} {α : Type u} (n : Nat) (a : α) (l : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___rightpad) |
| def | List.insert | List.insert.{u} {α : Type u} [BEq α] (a : α) (l : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___insert) |
| def | List.insertIdx | List.insertIdx.{u} {α : Type u} (xs : List α) (i : Nat) (a : α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___insertIdx) |
| def | List.insertIdxTR | List.insertIdxTR.{u_1} {α : Type u_1} (l : List α) (n : Nat) (a : α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___insertIdxTR) |
| def | List.intersperse | List.intersperse.{u} {α : Type u} (sep : α) (l : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___intersperse) |
| def | List.intersperseTR | List.intersperseTR.{u} {α : Type u} (sep : α) (l : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___intersperseTR) |
| def | List.intercalate | List.intercalate.{u} {α : Type u} (sep : List α) (xs : List (List α)) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___intercalate) |
| def | List.intercalateTR | List.intercalateTR.{u_1} {α : Type u_1} (sep : List α) (xs : List (List α)) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___intercalateTR) |
| def | List.mergeSort | List.mergeSort.{u_1} {α : Type u_1} (xs : List α) (le : α → α → Bool := by exact fun a b => a ≤ b) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___mergeSort) |
| def | List.merge | List.merge.{u_1} {α : Type u_1} (xs ys : List α) (le : α → α → Bool := by exact fun a b => a ≤ b) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___merge) |
| def | List.iter | List.iter.{w} {α : Type w} (l : List α) : Std.Iter α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___iter) |
| def | List.iterM | List.iterM.{w, w'} {α : Type w} (l : List α) (m : Type w → Type w') [Pure m] : Std.IterM m α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___iterM) |
| def | List.forA | List.forA.{u, v, w} {m : Type u → Type v} [Applicative m] {α : Type w} (as : List α) (f : α → m PUnit) : m PUnit | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___forA) |
| def | List.forM | List.forM.{u, v, w} {m : Type u → Type v} [Monad m] {α : Type w} (as : List α) (f : α → m PUnit) : m PUnit | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___forM) |
| def | List.firstM | List.firstM.{u, v, w} {m : Type u → Type v} [Alternative m] {α : Type w} {β : Type u} (f : α → m β) : List α → m β | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___firstM) |
| def | List.sum | List.sum.{u_1} {α : Type u_1} [Add α] [Zero α] : List α → α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___sum) |
| def | List.foldl | List.foldl.{u, v} {α : Type u} {β : Type v} (f : α → β → α) (init : α) : List β → α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___foldl) |
| def | List.foldlM | List.foldlM.{u, v, w} {m : Type u → Type v} [Monad m] {s : Type u} {α : Type w} (f : s → α → m s) (init : s) : List α → m s | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___foldlM) |
| def | List.foldlRecOn | List.foldlRecOn.{u_1, u_2, u_3} {β : Type u_1} {α : Type u_2} {motive : β → Sort u_3} (l : List α) (op : β → α → β) {b : β} : motive b → ((b : β) → motive b → ( … | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___foldlRecOn) |
| def | List.foldr | List.foldr.{u, v} {α : Type u} {β : Type v} (f : α → β → β) (init : β) (l : List α) : β | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___foldr) |
| def | List.foldrM | List.foldrM.{u, v, w} {m : Type u → Type v} [Monad m] {s : Type u} {α : Type w} (f : α → s → m s) (init : s) (l : List α) : m s | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___foldrM) |
| def | List.foldrRecOn | List.foldrRecOn.{u_1, u_2, u_3} {β : Type u_1} {α : Type u_2} {motive : β → Sort u_3} (l : List α) (op : α → β → β) {b : β} : motive b → ((b : β) → motive b → ( … | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___foldrRecOn) |
| def | List.foldrTR | List.foldrTR.{u_1, u_2} {α : Type u_1} {β : Type u_2} (f : α → β → β) (init : β) (l : List α) : β | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___foldrTR) |
| def | List.map | List.map.{u_1, u_2} {α : Type u_1} {β : Type u_2} (f : α → β) (l : List α) : List β | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___map) |
| def | List.mapTR | List.mapTR.{u, v} {α : Type u} {β : Type v} (f : α → β) (as : List α) : List β | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___mapTR) |
| def | List.mapM | List.mapM.{u, v, w} {m : Type u → Type v} [Monad m] {α : Type w} {β : Type u} (f : α → m β) (as : List α) : m (List β) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___mapM) |
| def | List.mapM' | List.mapM'.{u_1, u_2, u_3} {m : Type u_1 → Type u_2} {α : Type u_3} {β : Type u_1} [Monad m] (f : α → m β) : List α → m (List β) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___mapM___) |
| def | List.mapA | List.mapA.{u, v, w} {m : Type u → Type v} [Applicative m] {α : Type w} {β : Type u} (f : α → m β) : List α → m (List β) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___mapA) |
| def | List.mapFinIdx | List.mapFinIdx.{u_1, u_2} {α : Type u_1} {β : Type u_2} (as : List α) (f : (i : Nat) → α → i < as.length → β) : List β | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___mapFinIdx) |
| def | List.mapFinIdxM | List.mapFinIdxM.{u_1, u_2, u_3} {m : Type u_1 → Type u_2} {α : Type u_3} {β : Type u_1} [Monad m] (as : List α) (f : (i : Nat) → α → i < as.length → m β) : m (L … | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___mapFinIdxM) |
| def | List.mapIdx | List.mapIdx.{u_1, u_2} {α : Type u_1} {β : Type u_2} (f : Nat → α → β) (as : List α) : List β | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___mapIdx) |
| def | List.mapIdxM | List.mapIdxM.{u_1, u_2, u_3} {m : Type u_1 → Type u_2} {α : Type u_3} {β : Type u_1} [Monad m] (f : Nat → α → m β) (as : List α) : m (List β) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___mapIdxM) |
| def | List.mapMono | List.mapMono.{u_1} {α : Type u_1} (as : List α) (f : α → α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___mapMono) |
| def | List.mapMonoM | List.mapMonoM.{u_1, u_2} {m : Type u_1 → Type u_2} {α : Type u_1} [Monad m] (as : List α) (f : α → m α) : m (List α) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___mapMonoM) |
| def | List.flatMap | List.flatMap.{u, v} {α : Type u} {β : Type v} (b : α → List β) (as : List α) : List β | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___flatMap) |
| def | List.flatMapTR | List.flatMapTR.{u_1, u_2} {α : Type u_1} {β : Type u_2} (f : α → List β) (as : List α) : List β | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___flatMapTR) |
| def | List.flatMapM | List.flatMapM.{u, v, w} {m : Type u → Type v} [Monad m] {α : Type w} {β : Type u} (f : α → m (List β)) (as : List α) : m (List β) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___flatMapM) |
| def | List | List.zip.{u, v} {α : Type u} {β : Type v} : List α → List β → List (α × β) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___zip) |
| def | List.zipIdx | List.zipIdx.{u} {α : Type u} (l : List α) (n : Nat := 0) : List (α × Nat) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___zipIdx) |
| def | List.zipIdxTR | List.zipIdxTR.{u_1} {α : Type u_1} (l : List α) (n : Nat := 0) : List (α × Nat) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___zipIdxTR) |
| def | List.zipWith | List.zipWith.{u, v, w} {α : Type u} {β : Type v} {γ : Type w} (f : α → β → γ) (xs : List α) (ys : List β) : List γ | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___zipWith) |
| def | List.zipWithTR | List.zipWithTR.{u_1, u_2, u_3} {α : Type u_1} {β : Type u_2} {γ : Type u_3} (f : α → β → γ) (as : List α) (bs : List β) : List γ | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___zipWithTR) |
| def | List.zipWithAll | List.zipWithAll.{u, v, w} {α : Type u} {β : Type v} {γ : Type w} (f : Option α → Option β → γ) : List α → List β → List γ | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___zipWithAll) |
| def | List.unzip | List.unzip.{u, v} {α : Type u} {β : Type v} (l : List (α × β)) : List α × List β | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___unzip) |
| def | List.unzipTR | List.unzipTR.{u, v} {α : Type u} {β : Type v} (l : List (α × β)) : List α × List β | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___unzipTR) |
| def | List.filter | List.filter.{u} {α : Type u} (p : α → Bool) (l : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___filter) |
| def | List.filterTR | List.filterTR.{u} {α : Type u} (p : α → Bool) (as : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___filterTR) |
| def | List.filterM | List.filterM.{v} {m : Type → Type v} [Monad m] {α : Type} (p : α → m Bool) (as : List α) : m (List α) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___filterM) |
| def | List.filterRevM | List.filterRevM.{v} {m : Type → Type v} [Monad m] {α : Type} (p : α → m Bool) (as : List α) : m (List α) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___filterRevM) |
| def | List.filterMap | List.filterMap.{u, v} {α : Type u} {β : Type v} (f : α → Option β) : List α → List β | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___filterMap) |
| def | List.filterMapTR | List.filterMapTR.{u_1, u_2} {α : Type u_1} {β : Type u_2} (f : α → Option β) (l : List α) : List β | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___filterMapTR) |
| def | List.filterMapM | List.filterMapM.{u, v, w} {m : Type u → Type v} [Monad m] {α : Type w} {β : Type u} (f : α → m (Option β)) (as : List α) : m (List β) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___filterMapM) |
| def | List.take | List.take.{u} {α : Type u} (n : Nat) (xs : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___take) |
| def | List.takeTR | List.takeTR.{u_1} {α : Type u_1} (n : Nat) (l : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___takeTR) |
| def | List.takeWhile | List.takeWhile.{u} {α : Type u} (p : α → Bool) (xs : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___takeWhile) |
| def | List.takeWhileTR | List.takeWhileTR.{u_1} {α : Type u_1} (p : α → Bool) (l : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___takeWhileTR) |
| def | List.drop | List.drop.{u} {α : Type u} (n : Nat) (xs : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___drop) |
| def | List.dropWhile | List.dropWhile.{u} {α : Type u} (p : α → Bool) : List α → List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___dropWhile) |
| def | List.dropLast | List.dropLast.{u_1} {α : Type u_1} : List α → List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___dropLast) |
| def | List.dropLastTR | List.dropLastTR.{u_1} {α : Type u_1} (l : List α) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___dropLastTR) |
| def | List.splitAt | List.splitAt.{u} {α : Type u} (n : Nat) (l : List α) : List α × List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___splitAt) |
| def | List.span | List.span.{u} {α : Type u} (p : α → Bool) (as : List α) : List α × List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___span) |
| def | List.splitBy | List.splitBy.{u} {α : Type u} (R : α → α → Bool) : List α → List (List α) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___splitBy) |
| def | List.partition | List.partition.{u} {α : Type u} (p : α → Bool) (as : List α) : List α × List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___partition) |
| def | List.partitionM | List.partitionM.{u_1} {m : Type → Type u_1} {α : Type} [Monad m] (p : α → m Bool) (l : List α) : m (List α × List α) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___partitionM) |
| def | List.partitionMap | List.partitionMap.{u_1, u_2, u_3} {α : Type u_1} {β : Type u_2} {γ : Type u_3} (f : α → β ⊕ γ) (l : List α) : List β × List γ | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___partitionMap) |
| def | List.groupByKey | List.groupByKey.{u, v} {α : Type u} {β : Type v} [BEq α] [Hashable α] (key : β → α) (xs : List β) : Std.HashMap α (List β) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___groupByKey) |
| def | List.contains | List.contains.{u} {α : Type u} [BEq α] (as : List α) (a : α) : Bool | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___contains) |
| def | List.elem | List.elem.{u} {α : Type u} [BEq α] (a : α) (l : List α) : Bool | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___elem) |
| def | List.all | List.all.{u} {α : Type u} : List α → (α → Bool) → Bool | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___all) |
| def | List.allM | List.allM.{u, v} {m : Type → Type u} [Monad m] {α : Type v} (p : α → m Bool) (l : List α) : m Bool | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___allM) |
| def | List.any | List.any.{u} {α : Type u} (l : List α) (p : α → Bool) : Bool | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___any) |
| def | List.anyM | List.anyM.{u, v} {m : Type → Type u} [Monad m] {α : Type v} (p : α → m Bool) (l : List α) : m Bool | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___anyM) |
| def | List.and | List.and (bs : List Bool) : Bool | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___and) |
| def | List.or | List.or (bs : List Bool) : Bool | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___or) |
| def | List.beq | List.beq.{u} {α : Type u} [BEq α] : List α → List α → Bool | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___beq) |
| def | List.isEqv | List.isEqv.{u} {α : Type u} (as bs : List α) (eqv : α → α → Bool) : Bool | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___isEqv) |
| def | List.isPerm | List.isPerm.{u} {α : Type u} [BEq α] : List α → List α → Bool | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___isPerm) |
| def | List.isPrefixOf | List.isPrefixOf.{u} {α : Type u} [BEq α] : List α → List α → Bool | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___isPrefixOf) |
| def | List.isPrefixOf? | List.isPrefixOf?.{u} {α : Type u} [BEq α] (l₁ l₂ : List α) : Option (List α) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___isPrefixOf___) |
| def | List.isSublist | List.isSublist.{u} {α : Type u} [BEq α] : List α → List α → Bool | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___isSublist) |
| def | List.isSuffixOf | List.isSuffixOf.{u} {α : Type u} [BEq α] (l₁ l₂ : List α) : Bool | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___isSuffixOf) |
| def | List.isSuffixOf? | List.isSuffixOf?.{u} {α : Type u} [BEq α] (l₁ l₂ : List α) : Option (List α) | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___isSuffixOf___) |
| def | List.le | List.le.{u} {α : Type u} [LT α] (as bs : List α) : Prop | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___le) |
| def | List.lt | List.lt.{u} {α : Type u} [LT α] : List α → List α → Prop | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___lt) |
| def | List.lex | List.lex.{u} {α : Type u} [BEq α] (l₁ l₂ : List α) (lt : α → α → Bool := by exact (· < ·)) : Bool | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___lex) |
| def | List.attach | List.attach.{u_1} {α : Type u_1} (l : List α) : List { x // x ∈ l } | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___attach) |
| def | List.attachWith | List.attachWith.{u_1} {α : Type u_1} (l : List α) (P : α → Prop) (H : ∀ (x : α), x ∈ l → P x) : List { x // P x } | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___attachWith) |
| def | List.unattach | List.unattach.{u_1} {α : Type u_1} {p : α → Prop} (l : List { x // p x }) : List α | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___unattach) |
| def | List.pmap | List.pmap.{u_1, u_2} {α : Type u_1} {β : Type u_2} {P : α → Prop} (f : (a : α) → P a → β) (l : List α) (H : ∀ (a : α), a ∈ l → P a) : List β | [Reference](pages/Basic-Types/Linked-Lists/index.md#List___pmap) |
| structure | Array | Array.{u} (α : Type u) : Type u | [Reference](pages/Basic-Types/Arrays/index.md#Array___mk) |
| syntax | Array Literals |  | [Reference](pages/Basic-Types/Arrays/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Sub-Arrays |  | [Reference](pages/Basic-Types/Arrays/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Array.empty | Array.empty.{u} {α : Type u} : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___empty) |
| def | Array.emptyWithCapacity | Array.emptyWithCapacity.{u} {α : Type u} (c : Nat) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___emptyWithCapacity) |
| def | Array.singleton | Array.singleton.{u} {α : Type u} (v : α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___singleton) |
| def | Array.range | Array.range (n : Nat) : Array Nat | [Reference](pages/Basic-Types/Arrays/index.md#Array___range) |
| def | Array.range' | Array.range' (start size : Nat) (step : Nat := 1) : Array Nat | [Reference](pages/Basic-Types/Arrays/index.md#Array___range___) |
| def | Array.finRange | Array.finRange (n : Nat) : Array (Fin n) | [Reference](pages/Basic-Types/Arrays/index.md#Array___finRange) |
| def | Array.ofFn | Array.ofFn.{u} {α : Type u} {n : Nat} (f : Fin n → α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___ofFn) |
| def | Array.replicate | Array.replicate.{u} {α : Type u} (n : Nat) (v : α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___replicate) |
| def | Array.append | Array.append.{u} {α : Type u} (as bs : Array α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___append) |
| def | Array.appendList | Array.appendList.{u} {α : Type u} (as : Array α) (bs : List α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___appendList) |
| def | Array.leftpad | Array.leftpad.{u} {α : Type u} (n : Nat) (a : α) (xs : Array α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___leftpad) |
| def | Array.rightpad | Array.rightpad.{u} {α : Type u} (n : Nat) (a : α) (xs : Array α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___rightpad) |
| def | Array.size | Array.size.{u} {α : Type u} (a : Array α) : Nat | [Reference](pages/Basic-Types/Arrays/index.md#Array___size) |
| def | Array.usize | Array.usize.{u} {α : Type u} (xs : Array α) : USize | [Reference](pages/Basic-Types/Arrays/index.md#Array___usize) |
| def | Array.isEmpty | Array.isEmpty.{u} {α : Type u} (xs : Array α) : Bool | [Reference](pages/Basic-Types/Arrays/index.md#Array___isEmpty) |
| def | Array.extract | Array.extract.{u_1} {α : Type u_1} (as : Array α) (start : Nat := 0) (stop : Nat := as.size) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___extract) |
| def | Array.getD | Array.getD.{u_1} {α : Type u_1} (a : Array α) (i : Nat) (v₀ : α) : α | [Reference](pages/Basic-Types/Arrays/index.md#Array___getD) |
| def | Array.uget | Array.uget.{u} {α : Type u} (xs : Array α) (i : USize) (h : i.toNat < xs.size) : α | [Reference](pages/Basic-Types/Arrays/index.md#Array___uget) |
| def | Array.back | Array.back.{u} {α : Type u} (xs : Array α) (h : 0 < xs.size := by get_elem_tactic) : α | [Reference](pages/Basic-Types/Arrays/index.md#Array___back) |
| def | Array.back? | Array.back?.{u} {α : Type u} (xs : Array α) : Option α | [Reference](pages/Basic-Types/Arrays/index.md#Array___back___) |
| def | Array.back! | Array.back!.{u} {α : Type u} [Inhabited α] (xs : Array α) : α | [Reference](pages/Basic-Types/Arrays/index.md#Array___back___-next) |
| def | Array.getMax? | Array.getMax?.{u} {α : Type u} (as : Array α) (lt : α → α → Bool) : Option α | [Reference](pages/Basic-Types/Arrays/index.md#Array___getMax___) |
| def | Array.count | Array.count.{u} {α : Type u} [BEq α] (a : α) (as : Array α) : Nat | [Reference](pages/Basic-Types/Arrays/index.md#Array___count) |
| def | Array.countP | Array.countP.{u} {α : Type u} (p : α → Bool) (as : Array α) : Nat | [Reference](pages/Basic-Types/Arrays/index.md#Array___countP) |
| def | Array.idxOf | Array.idxOf.{u} {α : Type u} [BEq α] (a : α) : Array α → Nat | [Reference](pages/Basic-Types/Arrays/index.md#Array___idxOf) |
| def | Array.idxOf? | Array.idxOf?.{u} {α : Type u} [BEq α] (xs : Array α) (v : α) : Option Nat | [Reference](pages/Basic-Types/Arrays/index.md#Array___idxOf___) |
| def | Array.finIdxOf? | Array.finIdxOf?.{u} {α : Type u} [BEq α] (xs : Array α) (v : α) : Option (Fin xs.size) | [Reference](pages/Basic-Types/Arrays/index.md#Array___finIdxOf___) |
| def | Array.toList | Array.toList.{u} {α : Type u} (self : Array α) : List α | [Reference](pages/Basic-Types/Arrays/index.md#Array___toList) |
| def | Array.toListRev | Array.toListRev.{u_1} {α : Type u_1} (xs : Array α) : List α | [Reference](pages/Basic-Types/Arrays/index.md#Array___toListRev) |
| def | Array.toListAppend | Array.toListAppend.{u} {α : Type u} (as : Array α) (l : List α) : List α | [Reference](pages/Basic-Types/Arrays/index.md#Array___toListAppend) |
| def | Array.toVector | Array.toVector.{u_1} {α : Type u_1} (xs : Array α) : Vector α xs.size | [Reference](pages/Basic-Types/Arrays/index.md#Array___toVector) |
| def | Array.toSubarray | Array.toSubarray.{u} {α : Type u} (as : Array α) (start : Nat := 0) (stop : Nat := as.size) : Subarray α | [Reference](pages/Basic-Types/Arrays/index.md#Array___toSubarray) |
| def | Array.ofSubarray | Array.ofSubarray.{u} {α : Type u} (s : Subarray α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___ofSubarray) |
| def | Array.push | Array.push.{u} {α : Type u} (a : Array α) (v : α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___push) |
| def | Array.pop | Array.pop.{u} {α : Type u} (xs : Array α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___pop) |
| def | Array.popWhile | Array.popWhile.{u} {α : Type u} (p : α → Bool) (as : Array α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___popWhile) |
| def | Array.erase | Array.erase.{u} {α : Type u} [BEq α] (as : Array α) (a : α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___erase) |
| def | Array.eraseP | Array.eraseP.{u} {α : Type u} (as : Array α) (p : α → Bool) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___eraseP) |
| def | Array.eraseIdx | Array.eraseIdx.{u} {α : Type u} (xs : Array α) (i : Nat) (h : i < xs.size := by get_elem_tactic) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___eraseIdx) |
| def | Array.eraseIdx! | Array.eraseIdx!.{u} {α : Type u} (xs : Array α) (i : Nat) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___eraseIdx___) |
| def | Array.eraseIdxIfInBounds | Array.eraseIdxIfInBounds.{u} {α : Type u} (xs : Array α) (i : Nat) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___eraseIdxIfInBounds) |
| def | Array.eraseReps | Array.eraseReps.{u_1} {α : Type u_1} [BEq α] (as : Array α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___eraseReps) |
| def | Array.swap | Array.swap.{u} {α : Type u} (xs : Array α) (i j : Nat) (hi : i < xs.size := by get_elem_tactic) (hj : j < xs.size := by get_elem_tactic) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___swap) |
| def | Array.swapIfInBounds | Array.swapIfInBounds.{u} {α : Type u} (xs : Array α) (i j : Nat) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___swapIfInBounds) |
| def | Array.swapAt | Array.swapAt.{u} {α : Type u} (xs : Array α) (i : Nat) (v : α) (hi : i < xs.size := by get_elem_tactic) : α × Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___swapAt) |
| def | Array.swapAt! | Array.swapAt!.{u} {α : Type u} (xs : Array α) (i : Nat) (v : α) : α × Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___swapAt___) |
| def | Array.replace | Array.replace.{u} {α : Type u} [BEq α] (xs : Array α) (a b : α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___replace) |
| def | Array | Array.set.{u_1} {α : Type u_1} (xs : Array α) (i : Nat) (v : α) (h : i < xs.size := by get_elem_tactic) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___set) |
| def | Array.set! | Array.set!.{u_1} {α : Type u_1} (xs : Array α) (i : Nat) (v : α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___set___) |
| def | Array.setIfInBounds | Array.setIfInBounds.{u_1} {α : Type u_1} (xs : Array α) (i : Nat) (v : α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___setIfInBounds) |
| def | Array.uset | Array.uset.{u} {α : Type u} (xs : Array α) (i : USize) (v : α) (h : i.toNat < xs.size) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___uset) |
| def | Array.modify | Array.modify.{u} {α : Type u} (xs : Array α) (i : Nat) (f : α → α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___modify) |
| def | Array.modifyM | Array.modifyM.{u, u_1} {α : Type u} {m : Type u → Type u_1} [Monad m] (xs : Array α) (i : Nat) (f : α → m α) : m (Array α) | [Reference](pages/Basic-Types/Arrays/index.md#Array___modifyM) |
| def | Array.modifyOp | Array.modifyOp.{u} {α : Type u} (xs : Array α) (idx : Nat) (f : α → α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___modifyOp) |
| def | Array.insertIdx | Array.insertIdx.{u} {α : Type u} (as : Array α) (i : Nat) (a : α) : autoParam (i ≤ as.size) Array.insertIdx._auto_1 → Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___insertIdx) |
| def | Array.insertIdx! | Array.insertIdx!.{u} {α : Type u} (as : Array α) (i : Nat) (a : α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___insertIdx___) |
| def | Array.insertIdxIfInBounds | Array.insertIdxIfInBounds.{u} {α : Type u} (as : Array α) (i : Nat) (a : α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___insertIdxIfInBounds) |
| def | Array.reverse | Array.reverse.{u} {α : Type u} (as : Array α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___reverse) |
| def | Array.take | Array.take.{u} {α : Type u} (xs : Array α) (i : Nat) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___take) |
| def | Array.takeWhile | Array.takeWhile.{u} {α : Type u} (p : α → Bool) (as : Array α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___takeWhile) |
| def | Array.drop | Array.drop.{u} {α : Type u} (xs : Array α) (i : Nat) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___drop) |
| def | Array.shrink | Array.shrink.{u} {α : Type u} (xs : Array α) (n : Nat) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___shrink) |
| def | Array.flatten | Array.flatten.{u} {α : Type u} (xss : Array (Array α)) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___flatten) |
| def | Array.getEvenElems | Array.getEvenElems.{u} {α : Type u} (as : Array α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___getEvenElems) |
| def | Array.qsort | Array.qsort.{u_1} {α : Type u_1} (as : Array α) (lt : α → α → Bool := by exact (· < ·)) (lo : Nat := 0) (hi : Nat := as.size - 1) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___qsort) |
| def | Array.qsortOrd | Array.qsortOrd.{u_1} {α : Type u_1} [ord : Ord α] (xs : Array α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___qsortOrd) |
| def | Array.insertionSort | Array.insertionSort.{u_1} {α : Type u_1} (xs : Array α) (lt : α → α → Bool := by exact (· < ·)) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___insertionSort) |
| def | Array.binInsert | Array.binInsert.{u} {α : Type u} (lt : α → α → Bool) (as : Array α) (k : α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___binInsert) |
| def | Array.binInsertM | Array.binInsertM.{u, v} {α : Type u} {m : Type u → Type v} [Monad m] (lt : α → α → Bool) (merge : α → m α) (add : Unit → m α) (as : Array α) (k : α) : m (Array  … | [Reference](pages/Basic-Types/Arrays/index.md#Array___binInsertM) |
| def | Array.binSearch | Array.binSearch {α : Type} (as : Array α) (k : α) (lt : α → α → Bool) (lo : Nat := 0) (hi : Nat := as.size - 1) : Option α | [Reference](pages/Basic-Types/Arrays/index.md#Array___binSearch) |
| def | Array.binSearchContains | Array.binSearchContains {α : Type} (as : Array α) (k : α) (lt : α → α → Bool) (lo : Nat := 0) (hi : Nat := as.size - 1) : Bool | [Reference](pages/Basic-Types/Arrays/index.md#Array___binSearchContains) |
| def | Array.iter | Array.iter.{w} {α : Type w} (l : Array α) : Std.Iter α | [Reference](pages/Basic-Types/Arrays/index.md#Array___iter) |
| def | Array.iterFromIdx | Array.iterFromIdx.{w} {α : Type w} (l : Array α) (pos : Nat) : Std.Iter α | [Reference](pages/Basic-Types/Arrays/index.md#Array___iterFromIdx) |
| def | Array.iterM | Array.iterM.{w, w'} {α : Type w} (array : Array α) (m : Type w → Type w') [Pure m] : Std.IterM m α | [Reference](pages/Basic-Types/Arrays/index.md#Array___iterM) |
| def | Array.iterFromIdxM | Array.iterFromIdxM.{w, w'} {α : Type w} (array : Array α) (m : Type w → Type w') (pos : Nat) [Pure m] : Std.IterM m α | [Reference](pages/Basic-Types/Arrays/index.md#Array___iterFromIdxM) |
| def | Array.foldr | Array.foldr.{u, v} {α : Type u} {β : Type v} (f : α → β → β) (init : β) (as : Array α) (start : Nat := as.size) (stop : Nat := 0) : β | [Reference](pages/Basic-Types/Arrays/index.md#Array___foldr) |
| def | Array.foldrM | Array.foldrM.{u, v, w} {α : Type u} {β : Type v} {m : Type v → Type w} [Monad m] (f : α → β → m β) (init : β) (as : Array α) (start : Nat := as.size) (stop : Na … | [Reference](pages/Basic-Types/Arrays/index.md#Array___foldrM) |
| def | Array.foldl | Array.foldl.{u, v} {α : Type u} {β : Type v} (f : β → α → β) (init : β) (as : Array α) (start : Nat := 0) (stop : Nat := as.size) : β | [Reference](pages/Basic-Types/Arrays/index.md#Array___foldl) |
| def | Array.foldlM | Array.foldlM.{u, v, w} {α : Type u} {β : Type v} {m : Type v → Type w} [Monad m] (f : β → α → m β) (init : β) (as : Array α) (start : Nat := 0) (stop : Nat := a … | [Reference](pages/Basic-Types/Arrays/index.md#Array___foldlM) |
| def | Array.forM | Array.forM.{u, v, w} {α : Type u} {m : Type v → Type w} [Monad m] (f : α → m PUnit) (as : Array α) (start : Nat := 0) (stop : Nat := as.size) : m PUnit | [Reference](pages/Basic-Types/Arrays/index.md#Array___forM) |
| def | Array.forRevM | Array.forRevM.{u, v, w} {α : Type u} {m : Type v → Type w} [Monad m] (f : α → m PUnit) (as : Array α) (start : Nat := as.size) (stop : Nat := 0) : m PUnit | [Reference](pages/Basic-Types/Arrays/index.md#Array___forRevM) |
| def | Array.firstM | Array.firstM.{u, v, w} {β : Type v} {α : Type u} {m : Type v → Type w} [Alternative m] (f : α → m β) (as : Array α) : m β | [Reference](pages/Basic-Types/Arrays/index.md#Array___firstM) |
| def | Array.sum | Array.sum.{u_1} {α : Type u_1} [Add α] [Zero α] : Array α → α | [Reference](pages/Basic-Types/Arrays/index.md#Array___sum) |
| def | Array.map | Array.map.{u, v} {α : Type u} {β : Type v} (f : α → β) (as : Array α) : Array β | [Reference](pages/Basic-Types/Arrays/index.md#Array___map) |
| def | Array.mapMono | Array.mapMono.{u_1} {α : Type u_1} (as : Array α) (f : α → α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___mapMono) |
| def | Array.mapM | Array.mapM.{u, v, w} {α : Type u} {β : Type v} {m : Type v → Type w} [Monad m] (f : α → m β) (as : Array α) : m (Array β) | [Reference](pages/Basic-Types/Arrays/index.md#Array___mapM) |
| def | Array.mapM' | Array.mapM'.{u_1, u_2, u_3} {m : Type u_1 → Type u_2} {α : Type u_3} {β : Type u_1} [Monad m] (f : α → m β) (as : Array α) : m { bs // bs.size = as.size } | [Reference](pages/Basic-Types/Arrays/index.md#Array___mapM___) |
| def | Array.mapMonoM | Array.mapMonoM.{u_1, u_2} {m : Type u_1 → Type u_2} {α : Type u_1} [Monad m] (as : Array α) (f : α → m α) : m (Array α) | [Reference](pages/Basic-Types/Arrays/index.md#Array___mapMonoM) |
| def | Array.mapIdx | Array.mapIdx.{u, v} {α : Type u} {β : Type v} (f : Nat → α → β) (as : Array α) : Array β | [Reference](pages/Basic-Types/Arrays/index.md#Array___mapIdx) |
| def | Array.mapIdxM | Array.mapIdxM.{u, v, w} {α : Type u} {β : Type v} {m : Type v → Type w} [Monad m] (f : Nat → α → m β) (as : Array α) : m (Array β) | [Reference](pages/Basic-Types/Arrays/index.md#Array___mapIdxM) |
| def | Array.mapFinIdx | Array.mapFinIdx.{u, v} {α : Type u} {β : Type v} (as : Array α) (f : (i : Nat) → α → i < as.size → β) : Array β | [Reference](pages/Basic-Types/Arrays/index.md#Array___mapFinIdx) |
| def | Array.mapFinIdxM | Array.mapFinIdxM.{u, v, w} {α : Type u} {β : Type v} {m : Type v → Type w} [Monad m] (as : Array α) (f : (i : Nat) → α → i < as.size → m β) : m (Array β) | [Reference](pages/Basic-Types/Arrays/index.md#Array___mapFinIdxM) |
| def | Array.flatMap | Array.flatMap.{u, u_1} {α : Type u} {β : Type u_1} (f : α → Array β) (as : Array α) : Array β | [Reference](pages/Basic-Types/Arrays/index.md#Array___flatMap) |
| def | Array.flatMapM | Array.flatMapM.{u, u_1, u_2} {α : Type u} {m : Type u_1 → Type u_2} {β : Type u_1} [Monad m] (f : α → m (Array β)) (as : Array α) : m (Array β) | [Reference](pages/Basic-Types/Arrays/index.md#Array___flatMapM) |
| def | Array | Array.zip.{u, u_1} {α : Type u} {β : Type u_1} (as : Array α) (bs : Array β) : Array (α × β) | [Reference](pages/Basic-Types/Arrays/index.md#Array___zip) |
| def | Array.zipWith | Array.zipWith.{u, u_1, u_2} {α : Type u} {β : Type u_1} {γ : Type u_2} (f : α → β → γ) (as : Array α) (bs : Array β) : Array γ | [Reference](pages/Basic-Types/Arrays/index.md#Array___zipWith) |
| def | Array.zipWithAll | Array.zipWithAll.{u, u_1, u_2} {α : Type u} {β : Type u_1} {γ : Type u_2} (f : Option α → Option β → γ) (as : Array α) (bs : Array β) : Array γ | [Reference](pages/Basic-Types/Arrays/index.md#Array___zipWithAll) |
| def | Array.zipIdx | Array.zipIdx.{u} {α : Type u} (xs : Array α) (start : Nat := 0) : Array (α × Nat) | [Reference](pages/Basic-Types/Arrays/index.md#Array___zipIdx) |
| def | Array.unzip | Array.unzip.{u, u_1} {α : Type u} {β : Type u_1} (as : Array (α × β)) : Array α × Array β | [Reference](pages/Basic-Types/Arrays/index.md#Array___unzip) |
| def | Array.filter | Array.filter.{u} {α : Type u} (p : α → Bool) (as : Array α) (start : Nat := 0) (stop : Nat := as.size) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___filter) |
| def | Array.filterM | Array.filterM.{u_1} {m : Type → Type u_1} {α : Type} [Monad m] (p : α → m Bool) (as : Array α) (start : Nat := 0) (stop : Nat := as.size) : m (Array α) | [Reference](pages/Basic-Types/Arrays/index.md#Array___filterM) |
| def | Array.filterRevM | Array.filterRevM.{u_1} {m : Type → Type u_1} {α : Type} [Monad m] (p : α → m Bool) (as : Array α) (start : Nat := as.size) (stop : Nat := 0) : m (Array α) | [Reference](pages/Basic-Types/Arrays/index.md#Array___filterRevM) |
| def | Array.filterMap | Array.filterMap.{u, u_1} {α : Type u} {β : Type u_1} (f : α → Option β) (as : Array α) (start : Nat := 0) (stop : Nat := as.size) : Array β | [Reference](pages/Basic-Types/Arrays/index.md#Array___filterMap) |
| def | Array.filterMapM | Array.filterMapM.{u, u_1, u_2} {α : Type u} {m : Type u_1 → Type u_2} {β : Type u_1} [Monad m] (f : α → m (Option β)) (as : Array α) (start : Nat := 0) (stop :  … | [Reference](pages/Basic-Types/Arrays/index.md#Array___filterMapM) |
| def | Array.filterSepElems | Array.filterSepElems (a : Array Lean.Syntax) (p : Lean.Syntax → Bool) : Array Lean.Syntax | [Reference](pages/Basic-Types/Arrays/index.md#Array___filterSepElems) |
| def | Array.filterSepElemsM | Array.filterSepElemsM {m : Type → Type} [Monad m] (a : Array Lean.Syntax) (p : Lean.Syntax → m Bool) : m (Array Lean.Syntax) | [Reference](pages/Basic-Types/Arrays/index.md#Array___filterSepElemsM) |
| def | Array.partition | Array.partition.{u} {α : Type u} (p : α → Bool) (as : Array α) : Array α × Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___partition) |
| def | Array.groupByKey | Array.groupByKey.{u, v} {α : Type u} {β : Type v} [BEq α] [Hashable α] (key : β → α) (xs : Array β) : Std.HashMap α (Array β) | [Reference](pages/Basic-Types/Arrays/index.md#Array___groupByKey) |
| def | Array.contains | Array.contains.{u} {α : Type u} [BEq α] (as : Array α) (a : α) : Bool | [Reference](pages/Basic-Types/Arrays/index.md#Array___contains) |
| def | Array.elem | Array.elem.{u} {α : Type u} [BEq α] (a : α) (as : Array α) : Bool | [Reference](pages/Basic-Types/Arrays/index.md#Array___elem) |
| def | Array.find? | Array.find?.{u} {α : Type u} (p : α → Bool) (as : Array α) : Option α | [Reference](pages/Basic-Types/Arrays/index.md#Array___find___) |
| def | Array.findRev? | Array.findRev? {α : Type} (p : α → Bool) (as : Array α) : Option α | [Reference](pages/Basic-Types/Arrays/index.md#Array___findRev___) |
| def | Array.findIdx | Array.findIdx.{u} {α : Type u} (p : α → Bool) (as : Array α) : Nat | [Reference](pages/Basic-Types/Arrays/index.md#Array___findIdx) |
| def | Array.findIdx? | Array.findIdx?.{u} {α : Type u} (p : α → Bool) (as : Array α) : Option Nat | [Reference](pages/Basic-Types/Arrays/index.md#Array___findIdx___) |
| def | Array.findIdxM? | Array.findIdxM?.{u, u_1} {α : Type u} {m : Type → Type u_1} [Monad m] (p : α → m Bool) (as : Array α) : m (Option Nat) | [Reference](pages/Basic-Types/Arrays/index.md#Array___findIdxM___) |
| def | Array.findFinIdx? | Array.findFinIdx?.{u} {α : Type u} (p : α → Bool) (as : Array α) : Option (Fin as.size) | [Reference](pages/Basic-Types/Arrays/index.md#Array___findFinIdx___) |
| def | Array.findM? | Array.findM?.{u_1} {m : Type → Type u_1} {α : Type} [Monad m] (p : α → m Bool) (as : Array α) : m (Option α) | [Reference](pages/Basic-Types/Arrays/index.md#Array___findM___) |
| def | Array.findRevM? | Array.findRevM?.{w} {α : Type} {m : Type → Type w} [Monad m] (p : α → m Bool) (as : Array α) : m (Option α) | [Reference](pages/Basic-Types/Arrays/index.md#Array___findRevM___) |
| def | Array.findSome? | Array.findSome?.{u, v} {α : Type u} {β : Type v} (f : α → Option β) (as : Array α) : Option β | [Reference](pages/Basic-Types/Arrays/index.md#Array___findSome___) |
| def | Array.findSome! | Array.findSome!.{u, v} {α : Type u} {β : Type v} [Inhabited β] (f : α → Option β) (xs : Array α) : β | [Reference](pages/Basic-Types/Arrays/index.md#Array___findSome___-next) |
| def | Array.findSomeM? | Array.findSomeM?.{u, v, w} {α : Type u} {β : Type v} {m : Type v → Type w} [Monad m] (f : α → m (Option β)) (as : Array α) : m (Option β) | [Reference](pages/Basic-Types/Arrays/index.md#Array___findSomeM___) |
| def | Array.findSomeRev? | Array.findSomeRev?.{u, v} {α : Type u} {β : Type v} (f : α → Option β) (as : Array α) : Option β | [Reference](pages/Basic-Types/Arrays/index.md#Array___findSomeRev___) |
| def | Array.findSomeRevM? | Array.findSomeRevM?.{u, v, w} {α : Type u} {β : Type v} {m : Type v → Type w} [Monad m] (f : α → m (Option β)) (as : Array α) : m (Option β) | [Reference](pages/Basic-Types/Arrays/index.md#Array___findSomeRevM___) |
| def | Array.all | Array.all.{u} {α : Type u} (as : Array α) (p : α → Bool) (start : Nat := 0) (stop : Nat := as.size) : Bool | [Reference](pages/Basic-Types/Arrays/index.md#Array___all) |
| def | Array.allM | Array.allM.{u, w} {α : Type u} {m : Type → Type w} [Monad m] (p : α → m Bool) (as : Array α) (start : Nat := 0) (stop : Nat := as.size) : m Bool | [Reference](pages/Basic-Types/Arrays/index.md#Array___allM) |
| def | Array.any | Array.any.{u} {α : Type u} (as : Array α) (p : α → Bool) (start : Nat := 0) (stop : Nat := as.size) : Bool | [Reference](pages/Basic-Types/Arrays/index.md#Array___any) |
| def | Array.anyM | Array.anyM.{u, w} {α : Type u} {m : Type → Type w} [Monad m] (p : α → m Bool) (as : Array α) (start : Nat := 0) (stop : Nat := as.size) : m Bool | [Reference](pages/Basic-Types/Arrays/index.md#Array___anyM) |
| def | Array.allDiff | Array.allDiff.{u} {α : Type u} [BEq α] (as : Array α) : Bool | [Reference](pages/Basic-Types/Arrays/index.md#Array___allDiff) |
| def | Array.isEqv | Array.isEqv.{u} {α : Type u} (xs ys : Array α) (p : α → α → Bool) : Bool | [Reference](pages/Basic-Types/Arrays/index.md#Array___isEqv) |
| def | Array.isPrefixOf | Array.isPrefixOf.{u} {α : Type u} [BEq α] (as bs : Array α) : Bool | [Reference](pages/Basic-Types/Arrays/index.md#Array___isPrefixOf) |
| def | Array.lex | Array.lex.{u_1} {α : Type u_1} [BEq α] (as bs : Array α) (lt : α → α → Bool := by exact (· < ·)) : Bool | [Reference](pages/Basic-Types/Arrays/index.md#Array___lex) |
| def | Array.attach | Array.attach.{u_1} {α : Type u_1} (xs : Array α) : Array { x // x ∈ xs } | [Reference](pages/Basic-Types/Arrays/index.md#Array___attach) |
| def | Array.attachWith | Array.attachWith.{u_1} {α : Type u_1} (xs : Array α) (P : α → Prop) (H : ∀ (x : α), x ∈ xs → P x) : Array { x // P x } | [Reference](pages/Basic-Types/Arrays/index.md#Array___attachWith) |
| def | Array.unattach | Array.unattach.{u_1} {α : Type u_1} {p : α → Prop} (xs : Array { x // p x }) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Array___unattach) |
| def | Array.pmap | Array.pmap.{u_1, u_2} {α : Type u_1} {β : Type u_2} {P : α → Prop} (f : (a : α) → P a → β) (xs : Array α) (H : ∀ (a : α), a ∈ xs → P a) : Array β | [Reference](pages/Basic-Types/Arrays/index.md#Array___pmap) |
| def | Subarray | Subarray.{u} (α : Type u) : Type u | [Reference](pages/Basic-Types/Arrays/index.md#Subarray) |
| def | Subarray.empty | Subarray.empty.{u_1} {α : Type u_1} : Subarray α | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___empty) |
| def | Subarray.array | Subarray.array.{u_1} {α : Type u_1} (xs : Subarray α) : Array α | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___array) |
| def | Subarray.start | Subarray.start.{u_1} {α : Type u_1} (xs : Subarray α) : Nat | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___start) |
| def | Subarray.stop | Subarray.stop.{u_1} {α : Type u_1} (xs : Subarray α) : Nat | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___stop) |
| def | Subarray.start_le_stop | Subarray.start_le_stop.{u_1} {α : Type u_1} (xs : Subarray α) : xs.start ≤ xs.stop | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___start_le_stop) |
| def | Subarray.stop_le_array_size | Subarray.stop_le_array_size.{u_1} {α : Type u_1} (xs : Subarray α) : xs.stop ≤ xs.array.size | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___stop_le_array_size) |
| def | Subarray.drop | Subarray.drop.{u_1} {α : Type u_1} (arr : Subarray α) (i : Nat) : Subarray α | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___drop) |
| def | Subarray.take | Subarray.take.{u_1} {α : Type u_1} (arr : Subarray α) (i : Nat) : Subarray α | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___take) |
| def | Subarray.popFront | Subarray.popFront.{u_1} {α : Type u_1} (s : Subarray α) : Subarray α | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___popFront) |
| def | Subarray.split | Subarray.split.{u_1} {α : Type u_1} (s : Subarray α) (i : Fin (Std.Slice.size s).succ) : Subarray α × Subarray α | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___split) |
| def | Subarray.get | Subarray.get.{u_1} {α : Type u_1} (s : Subarray α) (i : Fin (Std.Slice.size s)) : α | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___get) |
| def | Subarray.get! | Subarray.get!.{u_1} {α : Type u_1} [Inhabited α] (s : Subarray α) (i : Nat) : α | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___get___) |
| def | Subarray.getD | Subarray.getD.{u_1} {α : Type u_1} (s : Subarray α) (i : Nat) (v₀ : α) : α | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___getD) |
| def | Subarray.foldr | Subarray.foldr.{u, v} {α : Type u} {β : Type v} (f : α → β → β) (init : β) (as : Subarray α) : β | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___foldr) |
| def | Subarray.foldrM | Subarray.foldrM.{u, v, w} {α : Type u} {β : Type v} {m : Type v → Type w} [Monad m] (f : α → β → m β) (init : β) (as : Subarray α) : m β | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___foldrM) |
| def | Subarray.forM | Subarray.forM.{u, v, w} {α : Type u} {m : Type v → Type w} [Monad m] (f : α → m PUnit) (as : Subarray α) : m PUnit | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___forM) |
| def | Subarray.forRevM | Subarray.forRevM.{u, v, w} {α : Type u} {m : Type v → Type w} [Monad m] (f : α → m PUnit) (as : Subarray α) : m PUnit | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___forRevM) |
| def | Subarray.forIn | Subarray.forIn.{v, w, u} {α : Type u} {β : Type v} {m : Type v → Type w} [Monad m] (s : Subarray α) (b : β) (f : α → β → m (ForInStep β)) : m β | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___forIn) |
| def | Subarray.findRev? | Subarray.findRev? {α : Type} (as : Subarray α) (p : α → Bool) : Option α | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___findRev___) |
| def | Subarray.findRevM? | Subarray.findRevM?.{w} {α : Type} {m : Type → Type w} [Monad m] (as : Subarray α) (p : α → m Bool) : m (Option α) | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___findRevM___) |
| def | Subarray.findSomeRevM? | Subarray.findSomeRevM?.{u, v, w} {α : Type u} {β : Type v} {m : Type v → Type w} [Monad m] (as : Subarray α) (f : α → m (Option β)) : m (Option β) | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___findSomeRevM___) |
| def | Subarray.all | Subarray.all.{u} {α : Type u} (p : α → Bool) (as : Subarray α) : Bool | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___all) |
| def | Subarray.allM | Subarray.allM.{u, w} {α : Type u} {m : Type → Type w} [Monad m] (p : α → m Bool) (as : Subarray α) : m Bool | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___allM) |
| def | Subarray.any | Subarray.any.{u} {α : Type u} (p : α → Bool) (as : Subarray α) : Bool | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___any) |
| def | Subarray.anyM | Subarray.anyM.{u, w} {α : Type u} {m : Type → Type w} [Monad m] (p : α → m Bool) (as : Subarray α) : m Bool | [Reference](pages/Basic-Types/Arrays/index.md#Subarray___anyM) |
| FFI type | lean_string_object-next | typedef struct { lean_object m_header; size_t m_size; size_t m_capacity; lean_object * m_data[]; } lean_array_object; | [Reference](pages/Basic-Types/Arrays/index.md#lean_string_object-next) |
| FFI function | lean_is_array | bool lean_is_array(lean_object * o) | [Reference](pages/Basic-Types/Arrays/index.md#lean_is_array) |
| FFI function | lean_to_array | lean_array_object * lean_to_array(lean_object * o) | [Reference](pages/Basic-Types/Arrays/index.md#lean_to_array) |
| structure | ByteArray | ByteArray : Type | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___mk) |
| def | ByteArray.empty | ByteArray.empty : ByteArray | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___empty) |
| def | ByteArray.emptyWithCapacity | ByteArray.emptyWithCapacity (c : Nat) : ByteArray | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___emptyWithCapacity) |
| def | ByteArray.append | ByteArray.append (a b : ByteArray) : ByteArray | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___append) |
| def | ByteArray.fastAppend | ByteArray.fastAppend (a b : ByteArray) : ByteArray | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___fastAppend) |
| def | ByteArray.copySlice | ByteArray.copySlice (src : ByteArray) (srcOff : Nat) (dest : ByteArray) (destOff len : Nat) (exact : Bool := true) : ByteArray | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___copySlice) |
| def | ByteArray.size | ByteArray.size : ByteArray → Nat | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___size) |
| def | ByteArray.usize | ByteArray.usize (a : ByteArray) : USize | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___usize) |
| def | ByteArray.isEmpty | ByteArray.isEmpty (s : ByteArray) : Bool | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___isEmpty) |
| def | ByteArray.get | ByteArray.get (a : ByteArray) (i : Nat) (h : i < a.size := by get_elem_tactic) : UInt8 | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___get) |
| def | ByteArray.uget | ByteArray.uget (a : ByteArray) (i : USize) (h : i.toNat < a.size := by get_elem_tactic) : UInt8 | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___uget) |
| def | ByteArray.get! | ByteArray.get! : ByteArray → Nat → UInt8 | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___get___) |
| def | ByteArray.extract | ByteArray.extract (a : ByteArray) (b e : Nat) : ByteArray | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___extract) |
| def | ByteArray.toList | ByteArray.toList (bs : ByteArray) : List UInt8 | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___toList) |
| def | ByteArray.toUInt64BE! | ByteArray.toUInt64BE! (bs : ByteArray) : UInt64 | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___toUInt64BE___) |
| def | ByteArray.toUInt64LE! | ByteArray.toUInt64LE! (bs : ByteArray) : UInt64 | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___toUInt64LE___) |
| def | ByteArray.utf8Decode? | ByteArray.utf8Decode? (b : ByteArray) : Option (Array Char) | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___utf8Decode___) |
| def | ByteArray.utf8DecodeChar? | ByteArray.utf8DecodeChar? (bytes : ByteArray) (i : Nat) : Option Char | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___utf8DecodeChar___) |
| def | ByteArray.utf8DecodeChar | ByteArray.utf8DecodeChar (bytes : ByteArray) (i : Nat) (h : (bytes.utf8DecodeChar? i).isSome = true) : Char | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___utf8DecodeChar) |
| def | ByteArray.push | ByteArray.push : ByteArray → UInt8 → ByteArray | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___push) |
| def | ByteArray | ByteArray.set (a : ByteArray) (i : Nat) : UInt8 → (h : autoParam (i < a.size) ByteArray.set._auto_1) → ByteArray | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___set) |
| def | ByteArray.uset | ByteArray.uset (a : ByteArray) (i : USize) : UInt8 → (h : autoParam (i.toNat < a.size) ByteArray.uset._auto_1) → ByteArray | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___uset) |
| def | ByteArray.set! | ByteArray.set! : ByteArray → Nat → UInt8 → ByteArray | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___set___) |
| def | ByteArray.foldl | ByteArray.foldl.{v} {β : Type v} (f : β → UInt8 → β) (init : β) (as : ByteArray) (start : Nat := 0) (stop : Nat := as.size) : β | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___foldl) |
| def | ByteArray.foldlM | ByteArray.foldlM.{v, w} {β : Type v} {m : Type v → Type w} [Monad m] (f : β → UInt8 → m β) (init : β) (as : ByteArray) (start : Nat := 0) (stop : Nat := as.size … | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___foldlM) |
| def | ByteArray.forIn | ByteArray.forIn.{v, w} {β : Type v} {m : Type v → Type w} [Monad m] (as : ByteArray) (b : β) (f : UInt8 → β → m (ForInStep β)) : m β | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___forIn) |
| def | ByteArray.iter | ByteArray.iter (arr : ByteArray) : ByteArray.Iterator | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___iter) |
| structure | ByteArray.Iterator | ByteArray.Iterator : Type | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___Iterator___mk) |
| def | ByteArray.Iterator.pos | ByteArray.Iterator.pos (self : ByteArray.Iterator) : Nat | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___Iterator___pos) |
| def | ByteArray.Iterator.atEnd | ByteArray.Iterator.atEnd : ByteArray.Iterator → Bool | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___Iterator___atEnd) |
| def | ByteArray.Iterator.hasNext | ByteArray.Iterator.hasNext : ByteArray.Iterator → Bool | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___Iterator___hasNext) |
| def | ByteArray.Iterator.hasPrev | ByteArray.Iterator.hasPrev : ByteArray.Iterator → Bool | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___Iterator___hasPrev) |
| def | ByteArray.Iterator.curr | ByteArray.Iterator.curr : ByteArray.Iterator → UInt8 | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___Iterator___curr) |
| def | ByteArray.Iterator.curr' | ByteArray.Iterator.curr' (it : ByteArray.Iterator) (h : it.hasNext = true) : UInt8 | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___Iterator___curr___) |
| def | ByteArray.Iterator.next | ByteArray.Iterator.next : ByteArray.Iterator → ByteArray.Iterator | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___Iterator___next) |
| def | ByteArray.Iterator.next' | ByteArray.Iterator.next' (it : ByteArray.Iterator) (_h : it.hasNext = true) : ByteArray.Iterator | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___Iterator___next___) |
| def | ByteArray.Iterator.forward | ByteArray.Iterator.forward : ByteArray.Iterator → Nat → ByteArray.Iterator | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___Iterator___forward) |
| def | ByteArray.Iterator.nextn | ByteArray.Iterator.nextn : ByteArray.Iterator → Nat → ByteArray.Iterator | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___Iterator___nextn) |
| def | ByteArray.Iterator.prev | ByteArray.Iterator.prev : ByteArray.Iterator → ByteArray.Iterator | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___Iterator___prev) |
| def | ByteArray.Iterator.prevn | ByteArray.Iterator.prevn : ByteArray.Iterator → Nat → ByteArray.Iterator | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___Iterator___prevn) |
| def | ByteArray.Iterator.remainingBytes | ByteArray.Iterator.remainingBytes : ByteArray.Iterator → Nat | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___Iterator___remainingBytes) |
| def | ByteArray.Iterator.toEnd | ByteArray.Iterator.toEnd : ByteArray.Iterator → ByteArray.Iterator | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___Iterator___toEnd) |
| def | ByteArray.toByteSlice | ByteArray.toByteSlice (as : ByteArray) (start : Nat := 0) (stop : Nat := as.size) : ByteSlice | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___toByteSlice) |
| def | ByteSlice | ByteSlice : Type | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteSlice) |
| def | ByteSlice.beq | ByteSlice.beq (a b : ByteSlice) : Bool | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteSlice___beq) |
| def | ByteSlice.byteArray | ByteSlice.byteArray (xs : ByteSlice) : ByteArray | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteSlice___byteArray) |
| def | ByteSlice.contains | ByteSlice.contains (s : ByteSlice) (byte : UInt8) : Bool | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteSlice___contains) |
| def | ByteSlice.empty | ByteSlice.empty : ByteSlice | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteSlice___empty) |
| def | ByteSlice.foldr | ByteSlice.foldr.{v} {β : Type v} (f : UInt8 → β → β) (init : β) (as : ByteSlice) : β | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteSlice___foldr) |
| def | ByteSlice.foldrM | ByteSlice.foldrM.{v, w} {β : Type v} {m : Type v → Type w} [Monad m] (f : UInt8 → β → m β) (init : β) (as : ByteSlice) : m β | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteSlice___foldrM) |
| def | ByteSlice.forM | ByteSlice.forM.{v, w} {m : Type v → Type w} [Monad m] (f : UInt8 → m PUnit) (as : ByteSlice) : m PUnit | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteSlice___forM) |
| def | ByteSlice.get | ByteSlice.get (s : ByteSlice) (i : Fin s.size) : UInt8 | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteSlice___get) |
| def | ByteSlice.get! | ByteSlice.get! (s : ByteSlice) (i : Nat) : UInt8 | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteSlice___get___) |
| def | ByteSlice.getD | ByteSlice.getD (s : ByteSlice) (i : Nat) (v₀ : UInt8) : UInt8 | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteSlice___getD) |
| def | ByteSlice.ofByteArray | ByteSlice.ofByteArray (ba : ByteArray) : ByteSlice | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteSlice___ofByteArray) |
| def | ByteSlice.size | ByteSlice.size (s : ByteSlice) : Nat | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteSlice___size) |
| def | ByteSlice.slice | ByteSlice.slice (s : ByteSlice) (start : Nat := 0) (stop : Nat := s.size) : ByteSlice | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteSlice___slice) |
| def | ByteSlice.start | ByteSlice.start (xs : ByteSlice) : Nat | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteSlice___start) |
| def | ByteSlice.stop | ByteSlice.stop (xs : ByteSlice) : Nat | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteSlice___stop) |
| def | ByteSlice.toByteArray | ByteSlice.toByteArray (s : ByteSlice) : ByteArray | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteSlice___toByteArray) |
| def | ByteArray.findIdx? | ByteArray.findIdx? (a : ByteArray) (p : UInt8 → Bool) (start : Nat := 0) : Option Nat | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___findIdx___) |
| def | ByteArray.findFinIdx? | ByteArray.findFinIdx? (a : ByteArray) (p : UInt8 → Bool) (start : Nat := 0) : Option (Fin a.size) | [Reference](pages/Basic-Types/Byte-Arrays/index.md#ByteArray___findFinIdx___) |
| syntax | Range Syntax |  | [Reference](pages/Basic-Types/Ranges/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| structure | Std.Rco | Std.Rco.{u} (α : Type u) : Type u | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rco___mk) |
| def | Std.Rco.iter | Std.Rco.iter.{u_1} {α : Type u_1} (r : Std.Rco α) : Std.Iter α | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rco___iter) |
| def | Std.Rco.toArray | Std.Rco.toArray.{u} {α : Type u} [LT α] [DecidableLT α] [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxo.IsAlwaysFinite α] (r : St … | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rco___toArray) |
| def | Std.Rco.toList | Std.Rco.toList.{u} {α : Type u} [LT α] [DecidableLT α] [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxo.IsAlwaysFinite α] (r : Std … | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rco___toList) |
| def | Std.Rco.size | Std.Rco.size.{u} {α : Type u} [Std.Rxo.HasSize α] (r : Std.Rco α) : Nat | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rco___size) |
| def | Std.Rco.isEmpty | Std.Rco.isEmpty.{u} {α : Type u} [LT α] [DecidableLT α] [Std.PRange.UpwardEnumerable α] (r : Std.Rco α) : Bool | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rco___isEmpty) |
| structure | Std.Rcc | Std.Rcc.{u} (α : Type u) : Type u | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rcc___mk) |
| def | Std.Rcc.iter | Std.Rcc.iter.{u_1} {α : Type u_1} (r : Std.Rcc α) : Std.Iter α | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rcc___iter) |
| def | Std.Rcc.toArray | Std.Rcc.toArray.{u} {α : Type u} [LE α] [DecidableLE α] [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxc.IsAlwaysFinite α] (r : St … | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rcc___toArray) |
| def | Std.Rcc.toList | Std.Rcc.toList.{u} {α : Type u} [LE α] [DecidableLE α] [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxc.IsAlwaysFinite α] (r : Std … | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rcc___toList) |
| def | Std.Rcc.size | Std.Rcc.size.{u} {α : Type u} [Std.Rxc.HasSize α] (r : Std.Rcc α) : Nat | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rcc___size) |
| def | Std.Rcc.isEmpty | Std.Rcc.isEmpty.{u} {α : Type u} [LE α] [DecidableLE α] [Std.PRange.UpwardEnumerable α] (r : Std.Rcc α) : Bool | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rcc___isEmpty) |
| structure | Std.Rci | Std.Rci.{u} (α : Type u) : Type u | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rci___mk) |
| def | Std.Rci.iter | Std.Rci.iter.{u_1} {α : Type u_1} (r : Std.Rci α) : Std.Iter α | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rci___iter) |
| def | Std.Rci.toArray | Std.Rci.toArray.{u} {α : Type u} [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxi.IsAlwaysFinite α] (r : Std.Rci α) : Array α | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rci___toArray) |
| def | Std.Rci.toList | Std.Rci.toList.{u} {α : Type u} [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxi.IsAlwaysFinite α] (r : Std.Rci α) : List α | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rci___toList) |
| def | Std.Rci.size | Std.Rci.size.{u} {α : Type u} [Std.Rxi.HasSize α] (r : Std.Rci α) : Nat | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rci___size) |
| def | Std.Rci.isEmpty | Std.Rci.isEmpty.{u} {α : Type u} [Std.PRange.UpwardEnumerable α] : Std.Rci α → Bool | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rci___isEmpty) |
| structure | Std.Roo | Std.Roo.{u} (α : Type u) : Type u | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roo___mk) |
| def | Std.Roo.iter | Std.Roo.iter.{u_1} {α : Type u_1} [Std.PRange.UpwardEnumerable α] (r : Std.Roo α) : Std.Iter α | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roo___iter) |
| def | Std.Roo.toArray | Std.Roo.toArray.{u} {α : Type u} [LT α] [DecidableLT α] [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxo.IsAlwaysFinite α] (r : St … | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roo___toArray) |
| def | Std.Roo.toList | Std.Roo.toList.{u} {α : Type u} [LT α] [DecidableLT α] [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxo.IsAlwaysFinite α] (r : Std … | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roo___toList) |
| def | Std.Roo.size | Std.Roo.size.{u} {α : Type u} [Std.Rxo.HasSize α] [Std.PRange.UpwardEnumerable α] (r : Std.Roo α) : Nat | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roo___size) |
| def | Std.Roo.isEmpty | Std.Roo.isEmpty.{u} {α : Type u} [LT α] [DecidableLT α] [Std.PRange.UpwardEnumerable α] (r : Std.Roo α) : Bool | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roo___isEmpty) |
| structure | Std.Roc | Std.Roc.{u} (α : Type u) : Type u | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roc___mk) |
| def | Std.Roc.iter | Std.Roc.iter.{u_1} {α : Type u_1} [Std.PRange.UpwardEnumerable α] (r : Std.Roc α) : Std.Iter α | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roc___iter) |
| def | Std.Roc.toArray | Std.Roc.toArray.{u} {α : Type u} [LE α] [DecidableLE α] [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxc.IsAlwaysFinite α] (r : St … | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roc___toArray) |
| def | Std.Roc.toList | Std.Roc.toList.{u} {α : Type u} [LE α] [DecidableLE α] [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxc.IsAlwaysFinite α] (r : Std … | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roc___toList) |
| def | Std.Roc.size | Std.Roc.size.{u} {α : Type u} [Std.Rxc.HasSize α] [Std.PRange.UpwardEnumerable α] (r : Std.Roc α) : Nat | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roc___size) |
| def | Std.Roc.isEmpty | Std.Roc.isEmpty.{u} {α : Type u} [LT α] [DecidableLT α] [Std.PRange.UpwardEnumerable α] (r : Std.Roc α) : Bool | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roc___isEmpty) |
| structure | Std.Roi | Std.Roi.{u} (α : Type u) : Type u | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roi___mk) |
| def | Std.Roi.iter | Std.Roi.iter.{u_1} {α : Type u_1} [Std.PRange.UpwardEnumerable α] (r : Std.Roi α) : Std.Iter α | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roi___iter) |
| def | Std.Roi.toArray | Std.Roi.toArray.{u} {α : Type u} [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxi.IsAlwaysFinite α] (r : Std.Roi α) : Array α | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roi___toArray) |
| def | Std.Roi.toList | Std.Roi.toList.{u} {α : Type u} [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxi.IsAlwaysFinite α] (r : Std.Roi α) : List α | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roi___toList) |
| def | Std.Roi.size | Std.Roi.size.{u} {α : Type u} [Std.Rxi.HasSize α] [Std.PRange.UpwardEnumerable α] (r : Std.Roi α) : Nat | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roi___size) |
| def | Std.Roi.isEmpty | Std.Roi.isEmpty.{u} {α : Type u} [Std.PRange.UpwardEnumerable α] (r : Std.Roi α) : Bool | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roi___isEmpty) |
| structure | Std.Rio | Std.Rio.{u} (α : Type u) : Type u | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rio___mk) |
| def | Std.Rio.iter | Std.Rio.iter.{u_1} {α : Type u_1} [Std.PRange.Least? α] (r : Std.Rio α) : Std.Iter α | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rio___iter) |
| def | Std.Rio.toArray | Std.Rio.toArray.{u} {α : Type u} [Std.PRange.Least? α] [LT α] [DecidableLT α] [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxo.IsA … | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rio___toArray) |
| def | Std.Rio.toList | Std.Rio.toList.{u} {α : Type u} [Std.PRange.Least? α] [LT α] [DecidableLT α] [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxo.IsAl … | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rio___toList) |
| def | Std.Rio.size | Std.Rio.size.{u} {α : Type u} [Std.Rxo.HasSize α] [Std.PRange.Least? α] (r : Std.Rio α) : Nat | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rio___size) |
| def | Std.Rio.isEmpty | Std.Rio.isEmpty.{u} {α : Type u} [LT α] [DecidableLT α] [Std.PRange.UpwardEnumerable α] [Std.PRange.Least? α] (r : Std.Rio α) : Bool | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rio___isEmpty) |
| structure | Std.Ric | Std.Ric.{u} (α : Type u) : Type u | [Reference](pages/Basic-Types/Ranges/index.md#Std___Ric___mk) |
| def | Std.Ric.iter | Std.Ric.iter.{u_1} {α : Type u_1} [Std.PRange.Least? α] (r : Std.Ric α) : Std.Iter α | [Reference](pages/Basic-Types/Ranges/index.md#Std___Ric___iter) |
| def | Std.Ric.toArray | Std.Ric.toArray.{u} {α : Type u} [Std.PRange.Least? α] [LE α] [DecidableLE α] [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxc.IsA … | [Reference](pages/Basic-Types/Ranges/index.md#Std___Ric___toArray) |
| def | Std.Ric.toList | Std.Ric.toList.{u} {α : Type u} [Std.PRange.Least? α] [LE α] [DecidableLE α] [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxc.IsAl … | [Reference](pages/Basic-Types/Ranges/index.md#Std___Ric___toList) |
| def | Std.Ric.size | Std.Ric.size.{u} {α : Type u} [Std.Rxc.HasSize α] [Std.PRange.Least? α] (r : Std.Ric α) : Nat | [Reference](pages/Basic-Types/Ranges/index.md#Std___Ric___size) |
| def | Std.Ric.isEmpty | Std.Ric.isEmpty.{u} {α : Type u} [Std.PRange.UpwardEnumerable α] : Std.Ric α → Bool | [Reference](pages/Basic-Types/Ranges/index.md#Std___Ric___isEmpty) |
| structure | Std.Rii | Std.Rii.{u} (α : Type u) : Type | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rii___mk) |
| def | Std.Rii.iter | Std.Rii.iter.{u_1} {α : Type u_1} [Std.PRange.Least? α] : Std.Rii α → Std.Iter α | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rii___iter) |
| def | Std.Rii.toArray | Std.Rii.toArray.{u_1} {α : Type u_1} [Std.PRange.UpwardEnumerable α] [Std.PRange.Least? α] (r : Std.Rii α) [Std.Iterator (Std.Rxi.Iterator α) Id α] [Std.Iterato … | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rii___toArray) |
| def | Std.Rii.toList | Std.Rii.toList.{u} {α : Type u} [Std.PRange.UpwardEnumerable α] [Std.PRange.Least? α] (r : Std.Rii α) [Std.Iterator (Std.Rxi.Iterator α) Id α] [Std.Iterators.Fi … | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rii___toList) |
| def | Std.Rii.size | Std.Rii.size.{u} {α : Type u} : Std.Rii α → [Std.PRange.Least? α] → [Std.Rxi.HasSize α] → Nat | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rii___size) |
| def | Std.Rii.isEmpty | Std.Rii.isEmpty.{u} {α : Type u} [Std.PRange.Least? α] : Std.Rii α → Bool | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rii___isEmpty) |
| type class | Std.PRange.UpwardEnumerable | Std.PRange.UpwardEnumerable.{u} (α : Type u) : Type u | [Reference](pages/Basic-Types/Ranges/index.md#Std___PRange___UpwardEnumerable___mk) |
| def | Std.PRange.UpwardEnumerable.LE | Std.PRange.UpwardEnumerable.LE.{u} {α : Type u} [Std.PRange.UpwardEnumerable α] (a b : α) : Prop | [Reference](pages/Basic-Types/Ranges/index.md#Std___PRange___UpwardEnumerable___LE) |
| def | Std.PRange.UpwardEnumerable.LT | Std.PRange.UpwardEnumerable.LT.{u} {α : Type u} [Std.PRange.UpwardEnumerable α] (a b : α) : Prop | [Reference](pages/Basic-Types/Ranges/index.md#Std___PRange___UpwardEnumerable___LT) |
| type class | Std.PRange.LawfulUpwardEnumerable | Std.PRange.LawfulUpwardEnumerable.{u} (α : Type u) [Std.PRange.UpwardEnumerable α] : Prop | [Reference](pages/Basic-Types/Ranges/index.md#Std___PRange___LawfulUpwardEnumerable___mk) |
| type class | Std.PRange.Least? | Std.PRange.Least?.{u} (α : Type u) : Type u | [Reference](pages/Basic-Types/Ranges/index.md#Std___PRange___Least______mk) |
| type class | Std.PRange.InfinitelyUpwardEnumerable | Std.PRange.InfinitelyUpwardEnumerable.{u} (α : Type u) [Std.PRange.UpwardEnumerable α] : Prop | [Reference](pages/Basic-Types/Ranges/index.md#Std___PRange___InfinitelyUpwardEnumerable___mk) |
| type class | Std.PRange.LinearlyUpwardEnumerable | Std.PRange.LinearlyUpwardEnumerable.{u} (α : Type u) [Std.PRange.UpwardEnumerable α] : Prop | [Reference](pages/Basic-Types/Ranges/index.md#Std___PRange___LinearlyUpwardEnumerable___mk) |
| type class | Std.Rxi.IsAlwaysFinite | Std.Rxi.IsAlwaysFinite.{u} (α : Type u) [Std.PRange.UpwardEnumerable α] : Prop | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rxi___IsAlwaysFinite___mk) |
| type class | Std.Rxi.HasSize | Std.Rxi.HasSize.{u} (α : Type u) : Type u | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rxi___HasSize___mk) |
| type class | Std.Rxc.IsAlwaysFinite | Std.Rxc.IsAlwaysFinite.{u} (α : Type u) [Std.PRange.UpwardEnumerable α] [LE α] : Prop | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rxc___IsAlwaysFinite___mk) |
| type class | Std.Rxc.HasSize | Std.Rxc.HasSize.{u} (α : Type u) : Type u | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rxc___HasSize___mk) |
| type class | Std.Rco.Sliceable | Std.Rco.Sliceable.{u, v, w} (α : Type u) (β : outParam (Type v)) (γ : outParam (Type w)) : Type (max (max u v) w) | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rco___Sliceable___mk) |
| type class | Std.Rcc.Sliceable | Std.Rcc.Sliceable.{u, v, w} (α : Type u) (β : outParam (Type v)) (γ : outParam (Type w)) : Type (max (max u v) w) | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rcc___Sliceable___mk) |
| type class | Std.Rci.Sliceable | Std.Rci.Sliceable.{u, v, w} (α : Type u) (β : outParam (Type v)) (γ : outParam (Type w)) : Type (max (max u v) w) | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rci___Sliceable___mk) |
| type class | Std.Roo.Sliceable | Std.Roo.Sliceable.{u, v, w} (α : Type u) (β : outParam (Type v)) (γ : outParam (Type w)) : Type (max (max u v) w) | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roo___Sliceable___mk) |
| type class | Std.Roc.Sliceable | Std.Roc.Sliceable.{u, v, w} (α : Type u) (β : outParam (Type v)) (γ : outParam (Type w)) : Type (max (max u v) w) | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roc___Sliceable___mk) |
| type class | Std.Roi.Sliceable | Std.Roi.Sliceable.{u, v, w} (α : Type u) (β : outParam (Type v)) (γ : outParam (Type w)) : Type (max (max u v) w) | [Reference](pages/Basic-Types/Ranges/index.md#Std___Roi___Sliceable___mk) |
| type class | Std.Rio.Sliceable | Std.Rio.Sliceable.{u, v, w} (α : Type u) (β : outParam (Type v)) (γ : outParam (Type w)) : Type (max (max u v) w) | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rio___Sliceable___mk) |
| type class | Std.Ric.Sliceable | Std.Ric.Sliceable.{u, v, w} (α : Type u) (β : outParam (Type v)) (γ : outParam (Type w)) : Type (max (max u v) w) | [Reference](pages/Basic-Types/Ranges/index.md#Std___Ric___Sliceable___mk) |
| type class | Std.Rii.Sliceable | Std.Rii.Sliceable.{u, v, w} (α : Type u) (β : outParam (Type v)) (γ : outParam (Type w)) : Type (max u w) | [Reference](pages/Basic-Types/Ranges/index.md#Std___Rii___Sliceable___mk) |
| structure | Std.HashMap | Std.HashMap.{u, v} (α : Type u) (β : Type v) [BEq α] [Hashable α] : Type (max u v) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap) |
| def | Std.HashMap.emptyWithCapacity | Std.HashMap.emptyWithCapacity.{u, v} {α : Type u} {β : Type v} [BEq α] [Hashable α] (capacity : Nat := 8) : Std.HashMap α β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___emptyWithCapacity) |
| def | Std.HashMap.size | Std.HashMap.size.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) : Nat | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___size) |
| def | Std.HashMap.isEmpty | Std.HashMap.isEmpty.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___isEmpty) |
| structure | Std.HashMap.Equiv | Std.HashMap.Equiv.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m₁ m₂ : Std.HashMap α β) : Prop | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___Equiv___mk) |
| syntax | Equivalence |  | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Std.HashMap.contains | Std.HashMap.contains.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___contains) |
| def | Std.HashMap.get | Std.HashMap.get.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) (h : a ∈ m) : β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___get) |
| def | Std.HashMap.get! | Std.HashMap.get!.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [Inhabited β] (m : Std.HashMap α β) (a : α) : β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___get___) |
| def | Std.HashMap.get? | Std.HashMap.get?.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) : Option β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___get___-next) |
| def | Std.HashMap.getD | Std.HashMap.getD.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) (fallback : β) : β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___getD) |
| def | Std.HashMap.getKey | Std.HashMap.getKey.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) (h : a ∈ m) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___getKey) |
| def | Std.HashMap.getKey! | Std.HashMap.getKey!.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [Inhabited α] (m : Std.HashMap α β) (a : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___getKey___) |
| def | Std.HashMap.getKey? | Std.HashMap.getKey?.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___getKey___-next) |
| def | Std.HashMap.getKeyD | Std.HashMap.getKeyD.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) (a fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___getKeyD) |
| def | Std.HashMap.keys | Std.HashMap.keys.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) : List α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___keys) |
| def | Std.HashMap.keysArray | Std.HashMap.keysArray.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) : Array α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___keysArray) |
| def | Std.HashMap.values | Std.HashMap.values.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) : List β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___values) |
| def | Std.HashMap.valuesArray | Std.HashMap.valuesArray.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) : Array β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___valuesArray) |
| def | Std.HashMap.alter | Std.HashMap.alter.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) (f : Option β → Option β) : Std.HashMap α β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___alter) |
| def | Std.HashMap.modify | Std.HashMap.modify.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) (f : β → β) : Std.HashMap α β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___modify) |
| def | Std.HashMap.containsThenInsert | Std.HashMap.containsThenInsert.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) (b : β) : Bool × Std.HashMap α β … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___containsThenInsert) |
| def | Std.HashMap.containsThenInsertIfNew | Std.HashMap.containsThenInsertIfNew.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) (b : β) : Bool × Std.HashMap  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___containsThenInsertIfNew) |
| def | Std.HashMap.erase | Std.HashMap.erase.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) : Std.HashMap α β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___erase) |
| def | Std.HashMap.filter | Std.HashMap.filter.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (f : α → β → Bool) (m : Std.HashMap α β) : Std.HashMap α β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___filter) |
| def | Std.HashMap.filterMap | Std.HashMap.filterMap.{u, v, w} {α : Type u} {β : Type v} {γ : Type w} [BEq α] [Hashable α] (f : α → β → Option γ) (m : Std.HashMap α β) : Std.HashMap α γ | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___filterMap) |
| def | Std.HashMap.insert | Std.HashMap.insert.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) (b : β) : Std.HashMap α β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___insert) |
| def | Std.HashMap.insertIfNew | Std.HashMap.insertIfNew.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) (b : β) : Std.HashMap α β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___insertIfNew) |
| def | Std.HashMap.getThenInsertIfNew? | Std.HashMap.getThenInsertIfNew?.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) (b : β) : Option β × Std.HashMap  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___getThenInsertIfNew___) |
| def | Std.HashMap.insertMany | Std.HashMap.insertMany.{u, v, w} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} {ρ : Type w} [ForIn Id ρ (α × β)] (m : Std.HashMap α β) (l : ρ) : Std … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___insertMany) |
| def | Std.HashMap.insertManyIfNewUnit | Std.HashMap.insertManyIfNewUnit.{u, w} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} {ρ : Type w} [ForIn Id ρ α] (m : Std.HashMap α Unit) (l : ρ) : Std.HashMap α … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___insertManyIfNewUnit) |
| def | Std.HashMap.partition | Std.HashMap.partition.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (f : α → β → Bool) (m : Std.HashMap α β) : Std.HashMap α β × Std.HashMap  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___partition) |
| def | Std.HashMap.union | Std.HashMap.union.{u, v} {α : Type u} {β : Type v} [BEq α] [Hashable α] (m₁ m₂ : Std.HashMap α β) : Std.HashMap α β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___union) |
| def | Std.HashMap.iter | Std.HashMap.iter.{u, v} {α : Type u} {β : Type v} [BEq α] [Hashable α] (m : Std.HashMap α β) : Std.Iter (α × β) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___iter) |
| def | Std.HashMap.keysIter | Std.HashMap.keysIter.{u} {α β : Type u} [BEq α] [Hashable α] (m : Std.HashMap α β) : Std.Iter α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___keysIter) |
| def | Std.HashMap.valuesIter | Std.HashMap.valuesIter.{u} {α β : Type u} [BEq α] [Hashable α] (m : Std.HashMap α β) : Std.Iter β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___valuesIter) |
| def | Std.HashMap.map | Std.HashMap.map.{u, v, w} {α : Type u} {β : Type v} {γ : Type w} [BEq α] [Hashable α] (f : α → β → γ) (m : Std.HashMap α β) : Std.HashMap α γ | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___map) |
| def | Std.HashMap.fold | Std.HashMap.fold.{u, v, w} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} {γ : Type w} (f : γ → α → β → γ) (init : γ) (b : Std.HashMap α β) : γ | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___fold) |
| def | Std.HashMap.foldM | Std.HashMap.foldM.{u, v, w, w'} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} {m : Type w → Type w'} [Monad m] {γ : Type w} (f : γ → α → β → m γ) (i … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___foldM) |
| def | Std.HashMap.forIn | Std.HashMap.forIn.{u, v, w, w'} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} {m : Type w → Type w'} [Monad m] {γ : Type w} (f : α → β → γ → m (ForI … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___forIn) |
| def | Std.HashMap.forM | Std.HashMap.forM.{u, v, w, w'} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} {m : Type w → Type w'} [Monad m] (f : α → β → m PUnit) (b : Std.HashMap … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___forM) |
| def | Std.HashMap.ofList | Std.HashMap.ofList.{u, v} {α : Type u} {β : Type v} [BEq α] [Hashable α] (l : List (α × β)) : Std.HashMap α β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___ofList) |
| def | Std.HashMap.toArray | Std.HashMap.toArray.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) : Array (α × β) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___toArray) |
| def | Std.HashMap.toList | Std.HashMap.toList.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) : List (α × β) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___toList) |
| def | Std.HashMap.unitOfArray | Std.HashMap.unitOfArray.{u} {α : Type u} [BEq α] [Hashable α] (l : Array α) : Std.HashMap α Unit | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___unitOfArray) |
| def | Std.HashMap.unitOfList | Std.HashMap.unitOfList.{u} {α : Type u} [BEq α] [Hashable α] (l : List α) : Std.HashMap α Unit | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___unitOfList) |
| structure | Std.HashMap.Raw | Std.HashMap.Raw.{u, v} (α : Type u) (β : Type v) : Type (max u v) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___Raw___mk) |
| structure | Std.HashMap.Raw.WF | Std.HashMap.Raw.WF.{u, v} {α : Type u} {β : Type v} [BEq α] [Hashable α] (m : Std.HashMap.Raw α β) : Prop | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashMap___Raw___WF___mk) |
| structure | Std.DHashMap | Std.DHashMap.{u, v} (α : Type u) (β : α → Type v) [BEq α] [Hashable α] : Type (max u v) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap) |
| def | Std.DHashMap.emptyWithCapacity | Std.DHashMap.emptyWithCapacity.{u, v} {α : Type u} {β : α → Type v} [BEq α] [Hashable α] (capacity : Nat := 8) : Std.DHashMap α β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___emptyWithCapacity) |
| def | Std.DHashMap.size | Std.DHashMap.size.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.DHashMap α β) : Nat | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___size) |
| def | Std.DHashMap.isEmpty | Std.DHashMap.isEmpty.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.DHashMap α β) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___isEmpty) |
| structure | Std.DHashMap.Equiv | Std.DHashMap.Equiv.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m₁ m₂ : Std.DHashMap α β) : Prop | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___Equiv___mk) |
| syntax | Equivalence |  | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Std.DHashMap.contains | Std.DHashMap.contains.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.DHashMap α β) (a : α) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___contains) |
| def | Std.DHashMap.get | Std.DHashMap.get.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.DHashMap α β) (a : α) (h : a ∈ m) : β a | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___get) |
| def | Std.DHashMap.get! | Std.DHashMap.get!.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.DHashMap α β) (a : α) [Inhabited (β a)] : β a | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___get___) |
| def | Std.DHashMap.get? | Std.DHashMap.get?.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.DHashMap α β) (a : α) : Option (β a) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___get___-next) |
| def | Std.DHashMap.getD | Std.DHashMap.getD.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.DHashMap α β) (a : α) (fallback : β a) : β a | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___getD) |
| def | Std.DHashMap.getKey | Std.DHashMap.getKey.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.DHashMap α β) (a : α) (h : a ∈ m) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___getKey) |
| def | Std.DHashMap.getKey! | Std.DHashMap.getKey!.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [Inhabited α] (m : Std.DHashMap α β) (a : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___getKey___) |
| def | Std.DHashMap.getKey? | Std.DHashMap.getKey?.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.DHashMap α β) (a : α) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___getKey___-next) |
| def | Std.DHashMap.getKeyD | Std.DHashMap.getKeyD.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.DHashMap α β) (a fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___getKeyD) |
| def | Std.DHashMap.keys | Std.DHashMap.keys.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.DHashMap α β) : List α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___keys) |
| def | Std.DHashMap.keysArray | Std.DHashMap.keysArray.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.DHashMap α β) : Array α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___keysArray) |
| def | Std.DHashMap.values | Std.DHashMap.values.{u, v} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} {β : Type v} (m : Std.DHashMap α fun x => β) : List β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___values) |
| def | Std.DHashMap.valuesArray | Std.DHashMap.valuesArray.{u, v} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} {β : Type v} (m : Std.DHashMap α fun x => β) : Array β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___valuesArray) |
| def | Std.DHashMap.alter | Std.DHashMap.alter.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.DHashMap α β) (a : α) (f : Option (β a) → Option  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___alter) |
| def | Std.DHashMap.modify | Std.DHashMap.modify.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.DHashMap α β) (a : α) (f : β a → β a) : Std.DHas … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___modify) |
| def | Std.DHashMap.containsThenInsert | Std.DHashMap.containsThenInsert.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.DHashMap α β) (a : α) (b : β a) : Bool × Std.DHash … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___containsThenInsert) |
| def | Std.DHashMap.containsThenInsertIfNew | Std.DHashMap.containsThenInsertIfNew.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.DHashMap α β) (a : α) (b : β a) : Bool × Std. … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___containsThenInsertIfNew) |
| def | Std.DHashMap.erase | Std.DHashMap.erase.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.DHashMap α β) (a : α) : Std.DHashMap α β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___erase) |
| def | Std.DHashMap.filter | Std.DHashMap.filter.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (f : (a : α) → β a → Bool) (m : Std.DHashMap α β) : Std.DHashMap α β … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___filter) |
| def | Std.DHashMap.filterMap | Std.DHashMap.filterMap.{u, v, w} {α : Type u} {β : α → Type v} {δ : α → Type w} [BEq α] [Hashable α] (f : (a : α) → β a → Option (δ a)) (m : Std.DHashMap α β) : … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___filterMap) |
| def | Std.DHashMap.insert | Std.DHashMap.insert.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.DHashMap α β) (a : α) (b : β a) : Std.DHashMap α β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___insert) |
| def | Std.DHashMap.insertIfNew | Std.DHashMap.insertIfNew.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.DHashMap α β) (a : α) (b : β a) : Std.DHashMap α β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___insertIfNew) |
| def | Std.DHashMap.getThenInsertIfNew? | Std.DHashMap.getThenInsertIfNew?.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.DHashMap α β) (a : α) (b : β a) : O … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___getThenInsertIfNew___) |
| def | Std.DHashMap.insertMany | Std.DHashMap.insertMany.{u, v, w} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} {ρ : Type w} [ForIn Id ρ ((a : α) × β a)] (m : Std.DHashMap α β) … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___insertMany) |
| def | Std.DHashMap.partition | Std.DHashMap.partition.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (f : (a : α) → β a → Bool) (m : Std.DHashMap α β) : Std.DHashMap α β … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___partition) |
| def | Std.DHashMap.union | Std.DHashMap.union.{u, v} {α : Type u} {β : α → Type v} [BEq α] [Hashable α] (m₁ m₂ : Std.DHashMap α β) : Std.DHashMap α β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___union) |
| def | Std.DHashMap.iter | Std.DHashMap.iter.{u, v} {α : Type u} {β : α → Type v} [BEq α] [Hashable α] (m : Std.DHashMap α β) : Std.Iter ((a : α) × β a) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___iter) |
| def | Std.DHashMap.keysIter | Std.DHashMap.keysIter.{u} {α : Type u} {β : α → Type u} [BEq α] [Hashable α] (m : Std.DHashMap α β) : Std.Iter α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___keysIter) |
| def | Std.DHashMap.valuesIter | Std.DHashMap.valuesIter.{u} {α β : Type u} [BEq α] [Hashable α] (m : Std.DHashMap α fun x => β) : Std.Iter β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___valuesIter) |
| def | Std.DHashMap.map | Std.DHashMap.map.{u, v, w} {α : Type u} {β : α → Type v} {δ : α → Type w} [BEq α] [Hashable α] (f : (a : α) → β a → δ a) (m : Std.DHashMap α β) : Std.DHashMap α … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___map) |
| def | Std.DHashMap.fold | Std.DHashMap.fold.{u, v, w} {α : Type u} {β : α → Type v} {δ : Type w} {x✝ : BEq α} {x✝¹ : Hashable α} (f : δ → (a : α) → β a → δ) (init : δ) (b : Std.DHashMap  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___fold) |
| def | Std.DHashMap.foldM | Std.DHashMap.foldM.{u, v, w, w'} {α : Type u} {β : α → Type v} {δ : Type w} {m : Type w → Type w'} [Monad m] {x✝ : BEq α} {x✝¹ : Hashable α} (f : δ → (a : α) →  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___foldM) |
| def | Std.DHashMap.forIn | Std.DHashMap.forIn.{u, v, w, w'} {α : Type u} {β : α → Type v} {δ : Type w} {m : Type w → Type w'} [Monad m] {x✝ : BEq α} {x✝¹ : Hashable α} (f : (a : α) → β a  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___forIn) |
| def | Std.DHashMap.forM | Std.DHashMap.forM.{u, v, w, w'} {α : Type u} {β : α → Type v} {m : Type w → Type w'} [Monad m] {x✝ : BEq α} {x✝¹ : Hashable α} (f : (a : α) → β a → m PUnit) (b  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___forM) |
| def | Std.DHashMap.ofList | Std.DHashMap.ofList.{u, v} {α : Type u} {β : α → Type v} [BEq α] [Hashable α] (l : List ((a : α) × β a)) : Std.DHashMap α β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___ofList) |
| def | Std.DHashMap.toArray | Std.DHashMap.toArray.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.DHashMap α β) : Array ((a : α) × β a) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___toArray) |
| def | Std.DHashMap.toList | Std.DHashMap.toList.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.DHashMap α β) : List ((a : α) × β a) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___toList) |
| structure | Std.DHashMap.Raw | Std.DHashMap.Raw.{u, v} (α : Type u) (β : α → Type v) : Type (max u v) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___Raw___mk) |
| inductive predicate | Std.DHashMap.Raw.WF | Std.DHashMap.Raw.WF.{u, v} {α : Type u} {β : α → Type v} [BEq α] [Hashable α] : Std.DHashMap.Raw α β → Prop | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DHashMap___Raw___WF___wf) |
| structure | Std.ExtHashMap | Std.ExtHashMap.{u, v} (α : Type u) (β : Type v) [BEq α] [Hashable α] : Type (max u v) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap) |
| def | Std.ExtHashMap.emptyWithCapacity | Std.ExtHashMap.emptyWithCapacity.{u, v} {α : Type u} {β : Type v} [BEq α] [Hashable α] (capacity : Nat := 8) : Std.ExtHashMap α β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___emptyWithCapacity) |
| def | Std.ExtHashMap.size | Std.ExtHashMap.size.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashMap α β) : Nat | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___size) |
| def | Std.ExtHashMap.isEmpty | Std.ExtHashMap.isEmpty.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashMap α β) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___isEmpty) |
| def | Std.ExtHashMap.contains | Std.ExtHashMap.contains.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashMap α β) (a : α) : Bool … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___contains) |
| def | Std.ExtHashMap.get | Std.ExtHashMap.get.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashMap α β) (a : α) (h : a ∈ m) … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___get) |
| def | Std.ExtHashMap.get! | Std.ExtHashMap.get!.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] [Inhabited β] (m : Std.ExtHashMap α β) (a : … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___get___) |
| def | Std.ExtHashMap.get? | Std.ExtHashMap.get?.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashMap α β) (a : α) : Option β … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___get___-next) |
| def | Std.ExtHashMap.getD | Std.ExtHashMap.getD.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashMap α β) (a : α) (fallback  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___getD) |
| def | Std.ExtHashMap.getKey | Std.ExtHashMap.getKey.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashMap α β) (a : α) (h : a ∈ … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___getKey) |
| def | Std.ExtHashMap.getKey! | Std.ExtHashMap.getKey!.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] [Inhabited α] (m : Std.ExtHashMap α β) ( … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___getKey___) |
| def | Std.ExtHashMap.getKey? | Std.ExtHashMap.getKey?.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashMap α β) (a : α) : Optio … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___getKey___-next) |
| def | Std.ExtHashMap.getKeyD | Std.ExtHashMap.getKeyD.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashMap α β) (a fallback : α … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___getKeyD) |
| def | Std.ExtHashMap.alter | Std.ExtHashMap.alter.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashMap α β) (a : α) (f : Opti … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___alter) |
| def | Std.ExtHashMap.modify | Std.ExtHashMap.modify.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashMap α β) (a : α) (f : β → … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___modify) |
| def | Std.ExtHashMap.containsThenInsert | Std.ExtHashMap.containsThenInsert.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashMap α β) (a : … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___containsThenInsert) |
| def | Std.ExtHashMap.containsThenInsertIfNew | Std.ExtHashMap.containsThenInsertIfNew.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashMap α β) … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___containsThenInsertIfNew) |
| def | Std.ExtHashMap.erase | Std.ExtHashMap.erase.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashMap α β) (a : α) : Std.Ext … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___erase) |
| def | Std.ExtHashMap.filter | Std.ExtHashMap.filter.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (f : α → β → Bool) (m : Std.ExtHashMap α  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___filter) |
| def | Std.ExtHashMap.filterMap | Std.ExtHashMap.filterMap.{u, v, w} {α : Type u} {β : Type v} {γ : Type w} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (f : α → β → Option γ) … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___filterMap) |
| def | Std.ExtHashMap.insert | Std.ExtHashMap.insert.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashMap α β) (a : α) (b : β)  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___insert) |
| def | Std.ExtHashMap.insertIfNew | Std.ExtHashMap.insertIfNew.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashMap α β) (a : α) (b  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___insertIfNew) |
| def | Std.ExtHashMap.getThenInsertIfNew? | Std.ExtHashMap.getThenInsertIfNew?.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashMap α β) (a  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___getThenInsertIfNew___) |
| def | Std.ExtHashMap.insertMany | Std.ExtHashMap.insertMany.{u, v, w} {α : Type u} {β : Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] {ρ : Type w} [ForIn Id ρ (α × β)]  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___insertMany) |
| def | Std.ExtHashMap.insertManyIfNewUnit | Std.ExtHashMap.insertManyIfNewUnit.{u, w} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] {ρ : Type w} [ForIn Id ρ α] (m : Std.ExtH … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___insertManyIfNewUnit) |
| def | Std.ExtHashMap.map | Std.ExtHashMap.map.{u, v, w} {α : Type u} {β : Type v} {γ : Type w} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (f : α → β → γ) (m : Std.Ext … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___map) |
| def | Std.ExtHashMap.ofList | Std.ExtHashMap.ofList.{u, v} {α : Type u} {β : Type v} [BEq α] [Hashable α] (l : List (α × β)) : Std.ExtHashMap α β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___ofList) |
| def | Std.ExtHashMap.unitOfArray | Std.ExtHashMap.unitOfArray.{u} {α : Type u} [BEq α] [Hashable α] (l : Array α) : Std.ExtHashMap α Unit | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___unitOfArray) |
| def | Std.ExtHashMap.unitOfList | Std.ExtHashMap.unitOfList.{u} {α : Type u} [BEq α] [Hashable α] (l : List α) : Std.ExtHashMap α Unit | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashMap___unitOfList) |
| structure | Std.ExtDHashMap | Std.ExtDHashMap.{u, v} (α : Type u) (β : α → Type v) [BEq α] [Hashable α] : Type (max u v) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap) |
| def | Std.ExtDHashMap.emptyWithCapacity | Std.ExtDHashMap.emptyWithCapacity.{u, v} {α : Type u} {β : α → Type v} [BEq α] [Hashable α] (capacity : Nat := 8) : Std.ExtDHashMap α β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___emptyWithCapacity) |
| def | Std.ExtDHashMap.size | Std.ExtDHashMap.size.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtDHashMap α β) : Nat | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___size) |
| def | Std.ExtDHashMap.isEmpty | Std.ExtDHashMap.isEmpty.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtDHashMap α β) : Bool … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___isEmpty) |
| def | Std.ExtDHashMap.contains | Std.ExtDHashMap.contains.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtDHashMap α β) (a : α)  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___contains) |
| def | Std.ExtDHashMap.get | Std.ExtDHashMap.get.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.ExtDHashMap α β) (a : α) (h : a ∈ m) : β a | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___get) |
| def | Std.ExtDHashMap.get! | Std.ExtDHashMap.get!.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.ExtDHashMap α β) (a : α) [Inhabited (β a)] : β  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___get___) |
| def | Std.ExtDHashMap.get? | Std.ExtDHashMap.get?.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.ExtDHashMap α β) (a : α) : Option (β a) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___get___-next) |
| def | Std.ExtDHashMap.getD | Std.ExtDHashMap.getD.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.ExtDHashMap α β) (a : α) (fallback : β a) : β a … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___getD) |
| def | Std.ExtDHashMap.getKey | Std.ExtDHashMap.getKey.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtDHashMap α β) (a : α) (h … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___getKey) |
| def | Std.ExtDHashMap.getKey! | Std.ExtDHashMap.getKey!.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] [Inhabited α] (m : Std.ExtDHashMap  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___getKey___) |
| def | Std.ExtDHashMap.getKey? | Std.ExtDHashMap.getKey?.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtDHashMap α β) (a : α) : … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___getKey___-next) |
| def | Std.ExtDHashMap.getKeyD | Std.ExtDHashMap.getKeyD.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtDHashMap α β) (a fallba … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___getKeyD) |
| def | Std.ExtDHashMap.alter | Std.ExtDHashMap.alter.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.ExtDHashMap α β) (a : α) (f : Option (β a) → O … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___alter) |
| def | Std.ExtDHashMap.modify | Std.ExtDHashMap.modify.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.ExtDHashMap α β) (a : α) (f : β a → β a) : St … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___modify) |
| def | Std.ExtDHashMap.containsThenInsert | Std.ExtDHashMap.containsThenInsert.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtDHashMap α β … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___containsThenInsert) |
| def | Std.ExtDHashMap.containsThenInsertIfNew | Std.ExtDHashMap.containsThenInsertIfNew.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtDHashMa … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___containsThenInsertIfNew) |
| def | Std.ExtDHashMap.erase | Std.ExtDHashMap.erase.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtDHashMap α β) (a : α) : S … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___erase) |
| def | Std.ExtDHashMap.filter | Std.ExtDHashMap.filter.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (f : (a : α) → β a → Bool) (m : Std. … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___filter) |
| def | Std.ExtDHashMap.filterMap | Std.ExtDHashMap.filterMap.{u, v, w} {α : Type u} {β : α → Type v} {γ : α → Type w} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (f : (a : α)  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___filterMap) |
| def | Std.ExtDHashMap.insert | Std.ExtDHashMap.insert.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtDHashMap α β) (a : α) (b … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___insert) |
| def | Std.ExtDHashMap.insertIfNew | Std.ExtDHashMap.insertIfNew.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtDHashMap α β) (a :  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___insertIfNew) |
| def | Std.ExtDHashMap.getThenInsertIfNew? | Std.ExtDHashMap.getThenInsertIfNew?.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.ExtDHashMap α β) (a : α) (b : β  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___getThenInsertIfNew___) |
| def | Std.ExtDHashMap.insertMany | Std.ExtDHashMap.insertMany.{u, v, w} {α : Type u} {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] {ρ : Type w} [ForIn Id ρ ((a  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___insertMany) |
| def | Std.ExtDHashMap.map | Std.ExtDHashMap.map.{u, v, w} {α : Type u} {β : α → Type v} {γ : α → Type w} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (f : (a : α) → β a  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___map) |
| def | Std.ExtDHashMap.ofList | Std.ExtDHashMap.ofList.{u, v} {α : Type u} {β : α → Type v} [BEq α] [Hashable α] (l : List ((a : α) × β a)) : Std.ExtDHashMap α β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtDHashMap___ofList) |
| structure | Std.HashSet | Std.HashSet.{u} (α : Type u) [BEq α] [Hashable α] : Type u | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___mk) |
| def | Std.HashSet.emptyWithCapacity | Std.HashSet.emptyWithCapacity.{u} {α : Type u} [BEq α] [Hashable α] (capacity : Nat := 8) : Std.HashSet α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___emptyWithCapacity) |
| def | Std.HashSet.isEmpty | Std.HashSet.isEmpty.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashSet α) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___isEmpty) |
| def | Std.HashSet.size | Std.HashSet.size.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashSet α) : Nat | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___size) |
| structure | Std.HashSet.Equiv | Std.HashSet.Equiv.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} (m₁ m₂ : Std.HashSet α) : Prop | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___Equiv___mk) |
| syntax | Equivalence |  | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Std.HashSet.contains | Std.HashSet.contains.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashSet α) (a : α) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___contains) |
| def | Std.HashSet.get | Std.HashSet.get.{u} {α : Type u} [BEq α] [Hashable α] (m : Std.HashSet α) (a : α) (h : a ∈ m) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___get) |
| def | Std.HashSet.get! | Std.HashSet.get!.{u} {α : Type u} [BEq α] [Hashable α] [Inhabited α] (m : Std.HashSet α) (a : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___get___) |
| def | Std.HashSet.get? | Std.HashSet.get?.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashSet α) (a : α) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___get___-next) |
| def | Std.HashSet.getD | Std.HashSet.getD.{u} {α : Type u} [BEq α] [Hashable α] (m : Std.HashSet α) (a fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___getD) |
| def | Std.HashSet.insert | Std.HashSet.insert.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashSet α) (a : α) : Std.HashSet α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___insert) |
| def | Std.HashSet.insertMany | Std.HashSet.insertMany.{u, v} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} {ρ : Type v} [ForIn Id ρ α] (m : Std.HashSet α) (l : ρ) : Std.HashSet α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___insertMany) |
| def | Std.HashSet.erase | Std.HashSet.erase.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashSet α) (a : α) : Std.HashSet α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___erase) |
| def | Std.HashSet.filter | Std.HashSet.filter.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} (f : α → Bool) (m : Std.HashSet α) : Std.HashSet α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___filter) |
| def | Std.HashSet.containsThenInsert | Std.HashSet.containsThenInsert.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashSet α) (a : α) : Bool × Std.HashSet α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___containsThenInsert) |
| def | Std.HashSet.partition | Std.HashSet.partition.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} (f : α → Bool) (m : Std.HashSet α) : Std.HashSet α × Std.HashSet α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___partition) |
| def | Std.HashSet.union | Std.HashSet.union.{u} {α : Type u} [BEq α] [Hashable α] (m₁ m₂ : Std.HashSet α) : Std.HashSet α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___union) |
| def | Std.HashSet.iter | Std.HashSet.iter.{u} {α : Type u} [BEq α] [Hashable α] (m : Std.HashSet α) : Std.Iter α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___iter) |
| def | Std.HashSet.all | Std.HashSet.all.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashSet α) (p : α → Bool) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___all) |
| def | Std.HashSet.any | Std.HashSet.any.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashSet α) (p : α → Bool) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___any) |
| def | Std.HashSet.fold | Std.HashSet.fold.{u, v} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} {β : Type v} (f : β → α → β) (init : β) (m : Std.HashSet α) : β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___fold) |
| def | Std.HashSet.foldM | Std.HashSet.foldM.{u, v, w} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} {m : Type v → Type w} [Monad m] {β : Type v} (f : β → α → m β) (init : β) (b : Std.Hash … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___foldM) |
| def | Std.HashSet.forIn | Std.HashSet.forIn.{u, v, w} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} {m : Type v → Type w} [Monad m] {β : Type v} (f : α → β → m (ForInStep β)) (init : β) ( … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___forIn) |
| def | Std.HashSet.forM | Std.HashSet.forM.{u, v, w} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} {m : Type v → Type w} [Monad m] (f : α → m PUnit) (b : Std.HashSet α) : m PUnit | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___forM) |
| def | Std.HashSet.ofList | Std.HashSet.ofList.{u} {α : Type u} [BEq α] [Hashable α] (l : List α) : Std.HashSet α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___ofList) |
| def | Std.HashSet.toList | Std.HashSet.toList.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashSet α) : List α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___toList) |
| def | Std.HashSet.ofArray | Std.HashSet.ofArray.{u} {α : Type u} [BEq α] [Hashable α] (l : Array α) : Std.HashSet α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___ofArray) |
| def | Std.HashSet.toArray | Std.HashSet.toArray.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashSet α) : Array α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___toArray) |
| structure | Std.HashSet.Raw | Std.HashSet.Raw.{u} (α : Type u) : Type u | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___Raw___mk) |
| structure | Std.HashSet.Raw.WF | Std.HashSet.Raw.WF.{u} {α : Type u} [BEq α] [Hashable α] (m : Std.HashSet.Raw α) : Prop | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___HashSet___Raw___WF___mk) |
| structure | Std.ExtHashSet | Std.ExtHashSet.{u} (α : Type u) [BEq α] [Hashable α] : Type u | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashSet___mk) |
| def | Std.ExtHashSet.emptyWithCapacity | Std.ExtHashSet.emptyWithCapacity.{u} {α : Type u} [BEq α] [Hashable α] (capacity : Nat := 8) : Std.ExtHashSet α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashSet___emptyWithCapacity) |
| def | Std.ExtHashSet.isEmpty | Std.ExtHashSet.isEmpty.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashSet α) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashSet___isEmpty) |
| def | Std.ExtHashSet.size | Std.ExtHashSet.size.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashSet α) : Nat | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashSet___size) |
| def | Std.ExtHashSet.contains | Std.ExtHashSet.contains.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashSet α) (a : α) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashSet___contains) |
| def | Std.ExtHashSet.get | Std.ExtHashSet.get.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashSet α) (a : α) (h : a ∈ m) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashSet___get) |
| def | Std.ExtHashSet.get! | Std.ExtHashSet.get!.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] [Inhabited α] (m : Std.ExtHashSet α) (a : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashSet___get___) |
| def | Std.ExtHashSet.get? | Std.ExtHashSet.get?.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashSet α) (a : α) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashSet___get___-next) |
| def | Std.ExtHashSet.getD | Std.ExtHashSet.getD.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashSet α) (a fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashSet___getD) |
| def | Std.ExtHashSet.insert | Std.ExtHashSet.insert.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashSet α) (a : α) : Std.ExtHashSet α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashSet___insert) |
| def | Std.ExtHashSet.insertMany | Std.ExtHashSet.insertMany.{u, v} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] {ρ : Type v} [ForIn Id ρ α] (m : Std.ExtHashSet α) … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashSet___insertMany) |
| def | Std.ExtHashSet.erase | Std.ExtHashSet.erase.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashSet α) (a : α) : Std.ExtHashSet α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashSet___erase) |
| def | Std.ExtHashSet.filter | Std.ExtHashSet.filter.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (f : α → Bool) (m : Std.ExtHashSet α) : Std.ExtHashSet α … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashSet___filter) |
| def | Std.ExtHashSet.containsThenInsert | Std.ExtHashSet.containsThenInsert.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashSet α) (a : α) : Bool × Std.E … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashSet___containsThenInsert) |
| def | Std.ExtHashSet.ofList | Std.ExtHashSet.ofList.{u} {α : Type u} [BEq α] [Hashable α] (l : List α) : Std.ExtHashSet α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashSet___ofList) |
| def | Std.ExtHashSet.ofArray | Std.ExtHashSet.ofArray.{u} {α : Type u} [BEq α] [Hashable α] (l : Array α) : Std.ExtHashSet α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___ExtHashSet___ofArray) |
| structure | Std.TreeMap | Std.TreeMap.{u, v} (α : Type u) (β : Type v) (cmp : α → α → Ordering := by exact compare) : Type (max u v) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap) |
| def | Std.TreeMap.empty | Std.TreeMap.empty.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} : Std.TreeMap α β cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___empty) |
| def | Std.TreeMap.size | Std.TreeMap.size.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : Nat | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___size) |
| def | Std.TreeMap.isEmpty | Std.TreeMap.isEmpty.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___isEmpty) |
| def | Std.TreeMap.contains | Std.TreeMap.contains.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (l : Std.TreeMap α β cmp) (a : α) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___contains) |
| def | Std.TreeMap.get | Std.TreeMap.get.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α) (h : a ∈ t) : β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___get) |
| def | Std.TreeMap.get! | Std.TreeMap.get!.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Inhabited β] (t : Std.TreeMap α β cmp) (a : α) : β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___get___) |
| def | Std.TreeMap.get? | Std.TreeMap.get?.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α) : Option β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___get___-next) |
| def | Std.TreeMap.getD | Std.TreeMap.getD.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α) (fallback : β) : β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getD) |
| def | Std.TreeMap.getKey | Std.TreeMap.getKey.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α) (h : a ∈ t) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getKey) |
| def | Std.TreeMap.getKey! | Std.TreeMap.getKey!.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeMap α β cmp) (a : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getKey___) |
| def | Std.TreeMap.getKey? | Std.TreeMap.getKey?.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getKey___-next) |
| def | Std.TreeMap.getKeyD | Std.TreeMap.getKeyD.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getKeyD) |
| def | Std.TreeMap.keys | Std.TreeMap.keys.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : List α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___keys) |
| def | Std.TreeMap.keysArray | Std.TreeMap.keysArray.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : Array α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___keysArray) |
| def | Std.TreeMap.values | Std.TreeMap.values.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : List β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___values) |
| def | Std.TreeMap.valuesArray | Std.TreeMap.valuesArray.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : Array β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___valuesArray) |
| def | Std.TreeMap.entryAtIdx | Std.TreeMap.entryAtIdx.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (n : Nat) (h : n < t.size) : α × β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___entryAtIdx) |
| def | Std.TreeMap.entryAtIdx! | Std.TreeMap.entryAtIdx!.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Inhabited (α × β)] (t : Std.TreeMap α β cmp) (n : Nat) : α × β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___entryAtIdx___) |
| def | Std.TreeMap.entryAtIdx? | Std.TreeMap.entryAtIdx?.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (n : Nat) : Option (α × β) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___entryAtIdx___-next) |
| def | Std.TreeMap.entryAtIdxD | Std.TreeMap.entryAtIdxD.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (n : Nat) (fallback : α × β) : α × β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___entryAtIdxD) |
| def | Std.TreeMap.getEntryGE | Std.TreeMap.getEntryGE.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Std.TransCmp cmp] (t : Std.TreeMap α β cmp) (k : α) (h : ∃ a, a ∈ t ∧ (cmp a k … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getEntryGE) |
| def | Std.TreeMap.getEntryGE! | Std.TreeMap.getEntryGE!.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Inhabited (α × β)] (t : Std.TreeMap α β cmp) (k : α) : α × β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getEntryGE___) |
| def | Std.TreeMap.getEntryGE? | Std.TreeMap.getEntryGE?.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α) : Option (α × β) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getEntryGE___-next) |
| def | Std.TreeMap.getEntryGED | Std.TreeMap.getEntryGED.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α) (fallback : α × β) : α × β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getEntryGED) |
| def | Std.TreeMap.getEntryGT | Std.TreeMap.getEntryGT.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Std.TransCmp cmp] (t : Std.TreeMap α β cmp) (k : α) (h : ∃ a, a ∈ t ∧ cmp a k  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getEntryGT) |
| def | Std.TreeMap.getEntryGT! | Std.TreeMap.getEntryGT!.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Inhabited (α × β)] (t : Std.TreeMap α β cmp) (k : α) : α × β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getEntryGT___) |
| def | Std.TreeMap.getEntryGT? | Std.TreeMap.getEntryGT?.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α) : Option (α × β) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getEntryGT___-next) |
| def | Std.TreeMap.getEntryGTD | Std.TreeMap.getEntryGTD.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α) (fallback : α × β) : α × β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getEntryGTD) |
| def | Std.TreeMap.getEntryLE | Std.TreeMap.getEntryLE.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Std.TransCmp cmp] (t : Std.TreeMap α β cmp) (k : α) (h : ∃ a, a ∈ t ∧ (cmp a k … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getEntryLE) |
| def | Std.TreeMap.getEntryLE! | Std.TreeMap.getEntryLE!.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Inhabited (α × β)] (t : Std.TreeMap α β cmp) (k : α) : α × β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getEntryLE___) |
| def | Std.TreeMap.getEntryLE? | Std.TreeMap.getEntryLE?.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α) : Option (α × β) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getEntryLE___-next) |
| def | Std.TreeMap.getEntryLED | Std.TreeMap.getEntryLED.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α) (fallback : α × β) : α × β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getEntryLED) |
| def | Std.TreeMap.getEntryLT | Std.TreeMap.getEntryLT.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Std.TransCmp cmp] (t : Std.TreeMap α β cmp) (k : α) (h : ∃ a, a ∈ t ∧ cmp a k  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getEntryLT) |
| def | Std.TreeMap.getEntryLT! | Std.TreeMap.getEntryLT!.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Inhabited (α × β)] (t : Std.TreeMap α β cmp) (k : α) : α × β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getEntryLT___) |
| def | Std.TreeMap.getEntryLT? | Std.TreeMap.getEntryLT?.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α) : Option (α × β) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getEntryLT___-next) |
| def | Std.TreeMap.getEntryLTD | Std.TreeMap.getEntryLTD.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α) (fallback : α × β) : α × β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getEntryLTD) |
| def | Std.TreeMap.getKeyGE | Std.TreeMap.getKeyGE.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Std.TransCmp cmp] (t : Std.TreeMap α β cmp) (k : α) (h : ∃ a, a ∈ t ∧ (cmp a k). … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getKeyGE) |
| def | Std.TreeMap.getKeyGE! | Std.TreeMap.getKeyGE!.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeMap α β cmp) (k : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getKeyGE___) |
| def | Std.TreeMap.getKeyGE? | Std.TreeMap.getKeyGE?.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getKeyGE___-next) |
| def | Std.TreeMap.getKeyGED | Std.TreeMap.getKeyGED.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getKeyGED) |
| def | Std.TreeMap.getKeyGT | Std.TreeMap.getKeyGT.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Std.TransCmp cmp] (t : Std.TreeMap α β cmp) (k : α) (h : ∃ a, a ∈ t ∧ cmp a k =  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getKeyGT) |
| def | Std.TreeMap.getKeyGT! | Std.TreeMap.getKeyGT!.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeMap α β cmp) (k : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getKeyGT___) |
| def | Std.TreeMap.getKeyGT? | Std.TreeMap.getKeyGT?.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getKeyGT___-next) |
| def | Std.TreeMap.getKeyGTD | Std.TreeMap.getKeyGTD.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getKeyGTD) |
| def | Std.TreeMap.getKeyLE | Std.TreeMap.getKeyLE.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Std.TransCmp cmp] (t : Std.TreeMap α β cmp) (k : α) (h : ∃ a, a ∈ t ∧ (cmp a k). … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getKeyLE) |
| def | Std.TreeMap.getKeyLE! | Std.TreeMap.getKeyLE!.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeMap α β cmp) (k : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getKeyLE___) |
| def | Std.TreeMap.getKeyLE? | Std.TreeMap.getKeyLE?.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getKeyLE___-next) |
| def | Std.TreeMap.getKeyLED | Std.TreeMap.getKeyLED.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getKeyLED) |
| def | Std.TreeMap.getKeyLT | Std.TreeMap.getKeyLT.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Std.TransCmp cmp] (t : Std.TreeMap α β cmp) (k : α) (h : ∃ a, a ∈ t ∧ cmp a k =  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getKeyLT) |
| def | Std.TreeMap.getKeyLT! | Std.TreeMap.getKeyLT!.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeMap α β cmp) (k : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getKeyLT___) |
| def | Std.TreeMap.getKeyLT? | Std.TreeMap.getKeyLT?.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getKeyLT___-next) |
| def | Std.TreeMap.getKeyLTD | Std.TreeMap.getKeyLTD.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getKeyLTD) |
| def | Std.TreeMap.keyAtIdx | Std.TreeMap.keyAtIdx.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (n : Nat) (h : n < t.size) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___keyAtIdx) |
| def | Std.TreeMap.keyAtIdx! | Std.TreeMap.keyAtIdx!.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeMap α β cmp) (n : Nat) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___keyAtIdx___) |
| def | Std.TreeMap.keyAtIdx? | Std.TreeMap.keyAtIdx?.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (n : Nat) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___keyAtIdx___-next) |
| def | Std.TreeMap.keyAtIdxD | Std.TreeMap.keyAtIdxD.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (n : Nat) (fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___keyAtIdxD) |
| def | Std.TreeMap.minEntry | Std.TreeMap.minEntry.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (h : t.isEmpty = false) : α × β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___minEntry) |
| def | Std.TreeMap.minEntry! | Std.TreeMap.minEntry!.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Inhabited (α × β)] (t : Std.TreeMap α β cmp) : α × β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___minEntry___) |
| def | Std.TreeMap.minEntry? | Std.TreeMap.minEntry?.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : Option (α × β) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___minEntry___-next) |
| def | Std.TreeMap.minEntryD | Std.TreeMap.minEntryD.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (fallback : α × β) : α × β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___minEntryD) |
| def | Std.TreeMap.minKey | Std.TreeMap.minKey.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (h : t.isEmpty = false) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___minKey) |
| def | Std.TreeMap.minKey! | Std.TreeMap.minKey!.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeMap α β cmp) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___minKey___) |
| def | Std.TreeMap.minKey? | Std.TreeMap.minKey?.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___minKey___-next) |
| def | Std.TreeMap.minKeyD | Std.TreeMap.minKeyD.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___minKeyD) |
| def | Std.TreeMap.maxEntry | Std.TreeMap.maxEntry.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (h : t.isEmpty = false) : α × β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___maxEntry) |
| def | Std.TreeMap.maxEntry! | Std.TreeMap.maxEntry!.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Inhabited (α × β)] (t : Std.TreeMap α β cmp) : α × β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___maxEntry___) |
| def | Std.TreeMap.maxEntry? | Std.TreeMap.maxEntry?.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : Option (α × β) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___maxEntry___-next) |
| def | Std.TreeMap.maxEntryD | Std.TreeMap.maxEntryD.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (fallback : α × β) : α × β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___maxEntryD) |
| def | Std.TreeMap.maxKey | Std.TreeMap.maxKey.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (h : t.isEmpty = false) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___maxKey) |
| def | Std.TreeMap.maxKey! | Std.TreeMap.maxKey!.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeMap α β cmp) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___maxKey___) |
| def | Std.TreeMap.maxKey? | Std.TreeMap.maxKey?.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___maxKey___-next) |
| def | Std.TreeMap.maxKeyD | Std.TreeMap.maxKeyD.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___maxKeyD) |
| def | Std.TreeMap.alter | Std.TreeMap.alter.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α) (f : Option β → Option β) : Std.TreeMap α β cmp … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___alter) |
| def | Std.TreeMap.modify | Std.TreeMap.modify.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α) (f : β → β) : Std.TreeMap α β cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___modify) |
| def | Std.TreeMap.containsThenInsert | Std.TreeMap.containsThenInsert.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α) (b : β) : Bool × Std.TreeMap α β cmp … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___containsThenInsert) |
| def | Std.TreeMap.containsThenInsertIfNew | Std.TreeMap.containsThenInsertIfNew.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α) (b : β) : Bool × Std.TreeMap α β … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___containsThenInsertIfNew) |
| def | Std.TreeMap.erase | Std.TreeMap.erase.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α) : Std.TreeMap α β cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___erase) |
| def | Std.TreeMap.eraseMany | Std.TreeMap.eraseMany.{u, v, u_1} {α : Type u} {β : Type v} {cmp : α → α → Ordering} {ρ : Type u_1} [ForIn Id ρ α] (t : Std.TreeMap α β cmp) (l : ρ) : Std.TreeM … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___eraseMany) |
| def | Std.TreeMap.filter | Std.TreeMap.filter.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (f : α → β → Bool) (m : Std.TreeMap α β cmp) : Std.TreeMap α β cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___filter) |
| def | Std.TreeMap.filterMap | Std.TreeMap.filterMap.{u, v, w} {α : Type u} {β : Type v} {γ : Type w} {cmp : α → α → Ordering} (f : α → β → Option γ) (m : Std.TreeMap α β cmp) : Std.TreeMap α … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___filterMap) |
| def | Std.TreeMap.insert | Std.TreeMap.insert.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (l : Std.TreeMap α β cmp) (a : α) (b : β) : Std.TreeMap α β cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___insert) |
| def | Std.TreeMap.insertIfNew | Std.TreeMap.insertIfNew.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α) (b : β) : Std.TreeMap α β cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___insertIfNew) |
| def | Std.TreeMap.getThenInsertIfNew? | Std.TreeMap.getThenInsertIfNew?.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α) (b : β) : Option β × Std.TreeMap α β … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___getThenInsertIfNew___) |
| def | Std.TreeMap.insertMany | Std.TreeMap.insertMany.{u, v, u_1} {α : Type u} {β : Type v} {cmp : α → α → Ordering} {ρ : Type u_1} [ForIn Id ρ (α × β)] (t : Std.TreeMap α β cmp) (l : ρ) : St … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___insertMany) |
| def | Std.TreeMap.insertManyIfNewUnit | Std.TreeMap.insertManyIfNewUnit.{u, u_1} {α : Type u} {cmp : α → α → Ordering} {ρ : Type u_1} [ForIn Id ρ α] (t : Std.TreeMap α Unit cmp) (l : ρ) : Std.TreeMap  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___insertManyIfNewUnit) |
| def | Std.TreeMap.mergeWith | Std.TreeMap.mergeWith.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (mergeFn : α → β → β → β) (t₁ t₂ : Std.TreeMap α β cmp) : Std.TreeMap α β cmp … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___mergeWith) |
| def | Std.TreeMap.partition | Std.TreeMap.partition.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (f : α → β → Bool) (t : Std.TreeMap α β cmp) : Std.TreeMap α β cmp × Std.TreeMap … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___partition) |
| def | Std.TreeMap.iter | Std.TreeMap.iter.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (m : Std.TreeMap α β cmp) : Std.Iter (α × β) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___iter) |
| def | Std.TreeMap.keysIter | Std.TreeMap.keysIter.{u} {α β : Type u} {cmp : α → α → Ordering} (m : Std.TreeMap α β cmp) : Std.Iter α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___keysIter) |
| def | Std.TreeMap.valuesIter | Std.TreeMap.valuesIter.{u} {α β : Type u} {cmp : α → α → Ordering} (m : Std.TreeMap α β cmp) : Std.Iter β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___valuesIter) |
| def | Std.TreeMap.map | Std.TreeMap.map.{u, v, w} {α : Type u} {β : Type v} {γ : Type w} {cmp : α → α → Ordering} (f : α → β → γ) (t : Std.TreeMap α β cmp) : Std.TreeMap α γ cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___map) |
| def | Std.TreeMap.all | Std.TreeMap.all.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (p : α → β → Bool) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___all) |
| def | Std.TreeMap.any | Std.TreeMap.any.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (p : α → β → Bool) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___any) |
| def | Std.TreeMap.foldl | Std.TreeMap.foldl.{u, v, w} {α : Type u} {β : Type v} {cmp : α → α → Ordering} {δ : Type w} (f : δ → α → β → δ) (init : δ) (t : Std.TreeMap α β cmp) : δ | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___foldl) |
| def | Std.TreeMap.foldlM | Std.TreeMap.foldlM.{u, v, w, w₂} {α : Type u} {β : Type v} {cmp : α → α → Ordering} {δ : Type w} {m : Type w → Type w₂} [Monad m] (f : δ → α → β → m δ) (init :  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___foldlM) |
| def | Std.TreeMap.foldr | Std.TreeMap.foldr.{u, v, w} {α : Type u} {β : Type v} {cmp : α → α → Ordering} {δ : Type w} (f : α → β → δ → δ) (init : δ) (t : Std.TreeMap α β cmp) : δ | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___foldr) |
| def | Std.TreeMap.foldrM | Std.TreeMap.foldrM.{u, v, w, w₂} {α : Type u} {β : Type v} {cmp : α → α → Ordering} {δ : Type w} {m : Type w → Type w₂} [Monad m] (f : α → β → δ → m δ) (init :  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___foldrM) |
| def | Std.TreeMap.forIn | Std.TreeMap.forIn.{u, v, w, w₂} {α : Type u} {β : Type v} {cmp : α → α → Ordering} {δ : Type w} {m : Type w → Type w₂} [Monad m] (f : α → β → δ → m (ForInStep δ … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___forIn) |
| def | Std.TreeMap.forM | Std.TreeMap.forM.{u, v, w, w₂} {α : Type u} {β : Type v} {cmp : α → α → Ordering} {m : Type w → Type w₂} [Monad m] (f : α → β → m PUnit) (t : Std.TreeMap α β cm … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___forM) |
| def | Std.TreeMap.ofList | Std.TreeMap.ofList.{u, v} {α : Type u} {β : Type v} (l : List (α × β)) (cmp : α → α → Ordering := by exact compare) : Std.TreeMap α β cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___ofList) |
| def | Std.TreeMap.toList | Std.TreeMap.toList.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : List (α × β) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___toList) |
| def | Std.TreeMap.ofArray | Std.TreeMap.ofArray.{u, v} {α : Type u} {β : Type v} (a : Array (α × β)) (cmp : α → α → Ordering := by exact compare) : Std.TreeMap α β cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___ofArray) |
| def | Std.TreeMap.toArray | Std.TreeMap.toArray.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : Array (α × β) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___toArray) |
| def | Std.TreeMap.unitOfArray | Std.TreeMap.unitOfArray.{u} {α : Type u} (a : Array α) (cmp : α → α → Ordering := by exact compare) : Std.TreeMap α Unit cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___unitOfArray) |
| def | Std.TreeMap.unitOfList | Std.TreeMap.unitOfList.{u} {α : Type u} (l : List α) (cmp : α → α → Ordering := by exact compare) : Std.TreeMap α Unit cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___unitOfList) |
| structure | Std.TreeMap.Raw | Std.TreeMap.Raw.{u, v} (α : Type u) (β : Type v) (cmp : α → α → Ordering := by exact compare) : Type (max u v) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___Raw___mk) |
| structure | Std.TreeMap.Raw.WF | Std.TreeMap.Raw.WF.{u, v} {α : Type u} {β : Type v} {cmp : α → α → Ordering} (t : Std.TreeMap.Raw α β cmp) : Prop | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeMap___Raw___WF___mk) |
| structure | Std.DTreeMap | Std.DTreeMap.{u, v} (α : Type u) (β : α → Type v) (cmp : α → α → Ordering := by exact compare) : Type (max u v) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap) |
| def | Std.DTreeMap.empty | Std.DTreeMap.empty.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} : Std.DTreeMap α β cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___empty) |
| def | Std.DTreeMap.size | Std.DTreeMap.size.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) : Nat | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___size) |
| def | Std.DTreeMap.isEmpty | Std.DTreeMap.isEmpty.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___isEmpty) |
| def | Std.DTreeMap.contains | Std.DTreeMap.contains.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) (a : α) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___contains) |
| def | Std.DTreeMap.get | Std.DTreeMap.get.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} [Std.LawfulEqCmp cmp] (t : Std.DTreeMap α β cmp) (a : α) (h : a ∈ t) : β a | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___get) |
| def | Std.DTreeMap.get! | Std.DTreeMap.get!.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} [Std.LawfulEqCmp cmp] (t : Std.DTreeMap α β cmp) (a : α) [Inhabited (β a)] : β a … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___get___) |
| def | Std.DTreeMap.get? | Std.DTreeMap.get?.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} [Std.LawfulEqCmp cmp] (t : Std.DTreeMap α β cmp) (a : α) : Option (β a) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___get___-next) |
| def | Std.DTreeMap.getD | Std.DTreeMap.getD.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} [Std.LawfulEqCmp cmp] (t : Std.DTreeMap α β cmp) (a : α) (fallback : β a) : β a … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___getD) |
| def | Std.DTreeMap.getKey | Std.DTreeMap.getKey.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) (a : α) (h : a ∈ t) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___getKey) |
| def | Std.DTreeMap.getKey! | Std.DTreeMap.getKey!.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} [Inhabited α] (t : Std.DTreeMap α β cmp) (a : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___getKey___) |
| def | Std.DTreeMap.getKey? | Std.DTreeMap.getKey?.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) (a : α) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___getKey___-next) |
| def | Std.DTreeMap.getKeyD | Std.DTreeMap.getKeyD.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) (a fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___getKeyD) |
| def | Std.DTreeMap.keys | Std.DTreeMap.keys.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) : List α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___keys) |
| def | Std.DTreeMap.keysArray | Std.DTreeMap.keysArray.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) : Array α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___keysArray) |
| def | Std.DTreeMap.values | Std.DTreeMap.values.{u, v} {α : Type u} {cmp : α → α → Ordering} {β : Type v} (t : Std.DTreeMap α (fun x => β) cmp) : List β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___values) |
| def | Std.DTreeMap.valuesArray | Std.DTreeMap.valuesArray.{u, v} {α : Type u} {cmp : α → α → Ordering} {β : Type v} (t : Std.DTreeMap α (fun x => β) cmp) : Array β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___valuesArray) |
| def | Std.DTreeMap.alter | Std.DTreeMap.alter.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} [Std.LawfulEqCmp cmp] (t : Std.DTreeMap α β cmp) (a : α) (f : Option (β a) → Op … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___alter) |
| def | Std.DTreeMap.modify | Std.DTreeMap.modify.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} [Std.LawfulEqCmp cmp] (t : Std.DTreeMap α β cmp) (a : α) (f : β a → β a) : Std … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___modify) |
| def | Std.DTreeMap.containsThenInsert | Std.DTreeMap.containsThenInsert.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) (a : α) (b : β a) : Bool × Std.DTreeMap … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___containsThenInsert) |
| def | Std.DTreeMap.containsThenInsertIfNew | Std.DTreeMap.containsThenInsertIfNew.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) (a : α) (b : β a) : Bool × Std.DTr … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___containsThenInsertIfNew) |
| def | Std.DTreeMap.erase | Std.DTreeMap.erase.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) (a : α) : Std.DTreeMap α β cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___erase) |
| def | Std.DTreeMap.filter | Std.DTreeMap.filter.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} (f : (a : α) → β a → Bool) (t : Std.DTreeMap α β cmp) : Std.DTreeMap α β cmp … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___filter) |
| def | Std.DTreeMap.filterMap | Std.DTreeMap.filterMap.{u, v, w} {α : Type u} {β : α → Type v} {γ : α → Type w} {cmp : α → α → Ordering} (f : (a : α) → β a → Option (γ a)) (t : Std.DTreeMap α  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___filterMap) |
| def | Std.DTreeMap.insert | Std.DTreeMap.insert.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) (a : α) (b : β a) : Std.DTreeMap α β cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___insert) |
| def | Std.DTreeMap.insertIfNew | Std.DTreeMap.insertIfNew.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) (a : α) (b : β a) : Std.DTreeMap α β cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___insertIfNew) |
| def | Std.DTreeMap.getThenInsertIfNew? | Std.DTreeMap.getThenInsertIfNew?.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} [Std.LawfulEqCmp cmp] (t : Std.DTreeMap α β cmp) (a : α) (b : β a … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___getThenInsertIfNew___) |
| def | Std.DTreeMap.insertMany | Std.DTreeMap.insertMany.{u, v, u_1} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} {ρ : Type u_1} [ForIn Id ρ ((a : α) × β a)] (t : Std.DTreeMap α β cmp … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___insertMany) |
| def | Std.DTreeMap.partition | Std.DTreeMap.partition.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} (f : (a : α) → β a → Bool) (t : Std.DTreeMap α β cmp) : Std.DTreeMap α β cm … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___partition) |
| def | Std.DTreeMap.iter | Std.DTreeMap.iter.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} (m : Std.DTreeMap α β cmp) : Std.Iter ((a : α) × β a) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___iter) |
| def | Std.DTreeMap.keysIter | Std.DTreeMap.keysIter.{u} {α : Type u} {β : α → Type u} {cmp : α → α → Ordering} (m : Std.DTreeMap α β cmp) : Std.Iter α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___keysIter) |
| def | Std.DTreeMap.valuesIter | Std.DTreeMap.valuesIter.{u} {α β : Type u} {cmp : α → α → Ordering} (m : Std.DTreeMap α (fun x => β) cmp) : Std.Iter β | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___valuesIter) |
| def | Std.DTreeMap.map | Std.DTreeMap.map.{u, v, w} {α : Type u} {β : α → Type v} {γ : α → Type w} {cmp : α → α → Ordering} (f : (a : α) → β a → γ a) (t : Std.DTreeMap α β cmp) : Std.DT … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___map) |
| def | Std.DTreeMap.foldl | Std.DTreeMap.foldl.{u, v, w} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} {δ : Type w} (f : δ → (a : α) → β a → δ) (init : δ) (t : Std.DTreeMap α β cm … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___foldl) |
| def | Std.DTreeMap.foldlM | Std.DTreeMap.foldlM.{u, v, w, w₂} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} {δ : Type w} {m : Type w → Type w₂} [Monad m] (f : δ → (a : α) → β a →  … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___foldlM) |
| def | Std.DTreeMap.forIn | Std.DTreeMap.forIn.{u, v, w, w₂} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} {δ : Type w} {m : Type w → Type w₂} [Monad m] (f : (a : α) → β a → δ → m … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___forIn) |
| def | Std.DTreeMap.forM | Std.DTreeMap.forM.{u, v, w, w₂} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} {m : Type w → Type w₂} [Monad m] (f : (a : α) → β a → m PUnit) (t : Std.D … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___forM) |
| def | Std.DTreeMap.ofList | Std.DTreeMap.ofList.{u, v} {α : Type u} {β : α → Type v} (l : List ((a : α) × β a)) (cmp : α → α → Ordering := by exact compare) : Std.DTreeMap α β cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___ofList) |
| def | Std.DTreeMap.toArray | Std.DTreeMap.toArray.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) : Array ((a : α) × β a) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___toArray) |
| def | Std.DTreeMap.toList | Std.DTreeMap.toList.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) : List ((a : α) × β a) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___toList) |
| structure | Std.DTreeMap.Raw | Std.DTreeMap.Raw.{u, v} (α : Type u) (β : α → Type v) (_cmp : α → α → Ordering := by exact compare) : Type (max u v) | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___Raw___mk) |
| structure | Std.DTreeMap.Raw.WF | Std.DTreeMap.Raw.WF.{u, v} {α : Type u} {β : α → Type v} {cmp : α → α → Ordering} (t : Std.DTreeMap.Raw α β cmp) : Prop | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___DTreeMap___Raw___WF___mk) |
| structure | Std.TreeSet | Std.TreeSet.{u} (α : Type u) (cmp : α → α → Ordering := by exact compare) : Type u | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet) |
| def | Std.TreeSet.empty | Std.TreeSet.empty.{u} {α : Type u} {cmp : α → α → Ordering} : Std.TreeSet α cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___empty) |
| def | Std.TreeSet.isEmpty | Std.TreeSet.isEmpty.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___isEmpty) |
| def | Std.TreeSet.size | Std.TreeSet.size.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) : Nat | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___size) |
| def | Std.TreeSet.contains | Std.TreeSet.contains.{u} {α : Type u} {cmp : α → α → Ordering} (l : Std.TreeSet α cmp) (a : α) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___contains) |
| def | Std.TreeSet.get | Std.TreeSet.get.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (a : α) (h : a ∈ t) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___get) |
| def | Std.TreeSet.get! | Std.TreeSet.get!.{u} {α : Type u} {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeSet α cmp) (a : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___get___) |
| def | Std.TreeSet.get? | Std.TreeSet.get?.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (a : α) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___get___-next) |
| def | Std.TreeSet.getD | Std.TreeSet.getD.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (a fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___getD) |
| def | Std.TreeSet.atIdx | Std.TreeSet.atIdx.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (n : Nat) (h : n < t.size) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___atIdx) |
| def | Std.TreeSet.atIdx! | Std.TreeSet.atIdx!.{u} {α : Type u} {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeSet α cmp) (n : Nat) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___atIdx___) |
| def | Std.TreeSet.atIdx? | Std.TreeSet.atIdx?.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (n : Nat) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___atIdx___-next) |
| def | Std.TreeSet.atIdxD | Std.TreeSet.atIdxD.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (n : Nat) (fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___atIdxD) |
| def | Std.TreeSet.getGE | Std.TreeSet.getGE.{u} {α : Type u} {cmp : α → α → Ordering} [Std.TransCmp cmp] (t : Std.TreeSet α cmp) (k : α) (h : ∃ a, a ∈ t ∧ (cmp a k).isGE = true) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___getGE) |
| def | Std.TreeSet.getGE! | Std.TreeSet.getGE!.{u} {α : Type u} {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeSet α cmp) (k : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___getGE___) |
| def | Std.TreeSet.getGE? | Std.TreeSet.getGE?.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (k : α) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___getGE___-next) |
| def | Std.TreeSet.getGED | Std.TreeSet.getGED.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (k fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___getGED) |
| def | Std.TreeSet.getGT | Std.TreeSet.getGT.{u} {α : Type u} {cmp : α → α → Ordering} [Std.TransCmp cmp] (t : Std.TreeSet α cmp) (k : α) (h : ∃ a, a ∈ t ∧ cmp a k = Ordering.gt) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___getGT) |
| def | Std.TreeSet.getGT! | Std.TreeSet.getGT!.{u} {α : Type u} {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeSet α cmp) (k : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___getGT___) |
| def | Std.TreeSet.getGT? | Std.TreeSet.getGT?.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (k : α) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___getGT___-next) |
| def | Std.TreeSet.getGTD | Std.TreeSet.getGTD.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (k fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___getGTD) |
| def | Std.TreeSet.getLE | Std.TreeSet.getLE.{u} {α : Type u} {cmp : α → α → Ordering} [Std.TransCmp cmp] (t : Std.TreeSet α cmp) (k : α) (h : ∃ a, a ∈ t ∧ (cmp a k).isLE = true) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___getLE) |
| def | Std.TreeSet.getLE! | Std.TreeSet.getLE!.{u} {α : Type u} {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeSet α cmp) (k : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___getLE___) |
| def | Std.TreeSet.getLE? | Std.TreeSet.getLE?.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (k : α) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___getLE___-next) |
| def | Std.TreeSet.getLED | Std.TreeSet.getLED.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (k fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___getLED) |
| def | Std.TreeSet.getLT | Std.TreeSet.getLT.{u} {α : Type u} {cmp : α → α → Ordering} [Std.TransCmp cmp] (t : Std.TreeSet α cmp) (k : α) (h : ∃ a, a ∈ t ∧ cmp a k = Ordering.lt) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___getLT) |
| def | Std.TreeSet.getLT! | Std.TreeSet.getLT!.{u} {α : Type u} {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeSet α cmp) (k : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___getLT___) |
| def | Std.TreeSet.getLT? | Std.TreeSet.getLT?.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (k : α) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___getLT___-next) |
| def | Std.TreeSet.getLTD | Std.TreeSet.getLTD.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (k fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___getLTD) |
| def | Std.TreeSet.min | Std.TreeSet.min.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (h : t.isEmpty = false) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___min) |
| def | Std.TreeSet.min! | Std.TreeSet.min!.{u} {α : Type u} {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeSet α cmp) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___min___) |
| def | Std.TreeSet.min? | Std.TreeSet.min?.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___min___-next) |
| def | Std.TreeSet.minD | Std.TreeSet.minD.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___minD) |
| def | Std.TreeSet.max | Std.TreeSet.max.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (h : t.isEmpty = false) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___max) |
| def | Std.TreeSet.max! | Std.TreeSet.max!.{u} {α : Type u} {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeSet α cmp) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___max___) |
| def | Std.TreeSet.max? | Std.TreeSet.max?.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) : Option α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___max___-next) |
| def | Std.TreeSet.maxD | Std.TreeSet.maxD.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (fallback : α) : α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___maxD) |
| def | Std.TreeSet.insert | Std.TreeSet.insert.{u} {α : Type u} {cmp : α → α → Ordering} (l : Std.TreeSet α cmp) (a : α) : Std.TreeSet α cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___insert) |
| def | Std.TreeSet.insertMany | Std.TreeSet.insertMany.{u, u_1} {α : Type u} {cmp : α → α → Ordering} {ρ : Type u_1} [ForIn Id ρ α] (t : Std.TreeSet α cmp) (l : ρ) : Std.TreeSet α cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___insertMany) |
| def | Std.TreeSet.containsThenInsert | Std.TreeSet.containsThenInsert.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (a : α) : Bool × Std.TreeSet α cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___containsThenInsert) |
| def | Std.TreeSet.erase | Std.TreeSet.erase.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (a : α) : Std.TreeSet α cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___erase) |
| def | Std.TreeSet.eraseMany | Std.TreeSet.eraseMany.{u, u_1} {α : Type u} {cmp : α → α → Ordering} {ρ : Type u_1} [ForIn Id ρ α] (t : Std.TreeSet α cmp) (l : ρ) : Std.TreeSet α cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___eraseMany) |
| def | Std.TreeSet.filter | Std.TreeSet.filter.{u} {α : Type u} {cmp : α → α → Ordering} (f : α → Bool) (m : Std.TreeSet α cmp) : Std.TreeSet α cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___filter) |
| def | Std.TreeSet.merge | Std.TreeSet.merge.{u} {α : Type u} {cmp : α → α → Ordering} (t₁ t₂ : Std.TreeSet α cmp) : Std.TreeSet α cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___merge) |
| def | Std.TreeSet.partition | Std.TreeSet.partition.{u} {α : Type u} {cmp : α → α → Ordering} (f : α → Bool) (t : Std.TreeSet α cmp) : Std.TreeSet α cmp × Std.TreeSet α cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___partition) |
| def | Std.TreeSet.iter | Std.TreeSet.iter.{u} {α : Type u} {cmp : α → α → Ordering} (m : Std.TreeSet α cmp) : Std.Iter α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___iter) |
| def | Std.TreeSet.all | Std.TreeSet.all.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (p : α → Bool) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___all) |
| def | Std.TreeSet.any | Std.TreeSet.any.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) (p : α → Bool) : Bool | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___any) |
| def | Std.TreeSet.foldl | Std.TreeSet.foldl.{u, w} {α : Type u} {cmp : α → α → Ordering} {δ : Type w} (f : δ → α → δ) (init : δ) (t : Std.TreeSet α cmp) : δ | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___foldl) |
| def | Std.TreeSet.foldlM | Std.TreeSet.foldlM.{u, u_1, u_2} {α : Type u} {cmp : α → α → Ordering} {m : Type u_1 → Type u_2} {δ : Type u_1} [Monad m] (f : δ → α → m δ) (init : δ) (t : Std. … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___foldlM) |
| def | Std.TreeSet.foldr | Std.TreeSet.foldr.{u, w} {α : Type u} {cmp : α → α → Ordering} {δ : Type w} (f : α → δ → δ) (init : δ) (t : Std.TreeSet α cmp) : δ | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___foldr) |
| def | Std.TreeSet.foldrM | Std.TreeSet.foldrM.{u, u_1, u_2} {α : Type u} {cmp : α → α → Ordering} {m : Type u_1 → Type u_2} {δ : Type u_1} [Monad m] (f : α → δ → m δ) (init : δ) (t : Std. … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___foldrM) |
| def | Std.TreeSet.forIn | Std.TreeSet.forIn.{u, w, w₂} {α : Type u} {cmp : α → α → Ordering} {δ : Type w} {m : Type w → Type w₂} [Monad m] (f : α → δ → m (ForInStep δ)) (init : δ) (t : S … | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___forIn) |
| def | Std.TreeSet.forM | Std.TreeSet.forM.{u, w, w₂} {α : Type u} {cmp : α → α → Ordering} {m : Type w → Type w₂} [Monad m] (f : α → m PUnit) (t : Std.TreeSet α cmp) : m PUnit | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___forM) |
| def | Std.TreeSet.toList | Std.TreeSet.toList.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) : List α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___toList) |
| def | Std.TreeSet.ofList | Std.TreeSet.ofList.{u} {α : Type u} (l : List α) (cmp : α → α → Ordering := by exact compare) : Std.TreeSet α cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___ofList) |
| def | Std.TreeSet.toArray | Std.TreeSet.toArray.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet α cmp) : Array α | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___toArray) |
| def | Std.TreeSet.ofArray | Std.TreeSet.ofArray.{u} {α : Type u} (a : Array α) (cmp : α → α → Ordering := by exact compare) : Std.TreeSet α cmp | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___ofArray) |
| structure | Std.TreeSet.Raw | Std.TreeSet.Raw.{u} (α : Type u) (cmp : α → α → Ordering := by exact compare) : Type u | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___Raw___mk) |
| structure | Std.TreeSet.Raw.WF | Std.TreeSet.Raw.WF.{u} {α : Type u} {cmp : α → α → Ordering} (t : Std.TreeSet.Raw α cmp) : Prop | [Reference](pages/Basic-Types/Maps-and-Sets/index.md#Std___TreeSet___Raw___WF___mk) |
| structure | Subtype | Subtype.{u} {α : Sort u} (p : α → Prop) : Sort (max 1 u) | [Reference](pages/Basic-Types/Subtypes/index.md#Subtype___mk) |
| syntax | Subtypes |  | [Reference](pages/Basic-Types/Subtypes/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| structure | Thunk | Thunk.{u} (α : Type u) : Type u | [Reference](pages/Basic-Types/Lazy-Computations/index.md#Thunk___mk) |
| def | Thunk.get | Thunk.get.{u_1} {α : Type u_1} (x : Thunk α) : α | [Reference](pages/Basic-Types/Lazy-Computations/index.md#Thunk___get) |
| def | Thunk.map | Thunk.map.{u_1, u_2} {α : Type u_1} {β : Type u_2} (f : α → β) (x : Thunk α) : Thunk β | [Reference](pages/Basic-Types/Lazy-Computations/index.md#Thunk___map) |
| def | Thunk.pure | Thunk.pure.{u_1} {α : Type u_1} (a : α) : Thunk α | [Reference](pages/Basic-Types/Lazy-Computations/index.md#Thunk___pure) |
| def | Thunk.bind | Thunk.bind.{u_1, u_2} {α : Type u_1} {β : Type u_2} (x : Thunk α) (f : α → Thunk β) : Thunk β | [Reference](pages/Basic-Types/Lazy-Computations/index.md#Thunk___bind) |
| def | BaseIO | BaseIO (α : Type) : Type | [Reference](pages/IO/Logical-Model/index.md#BaseIO) |
| def | IO | IO : Type → Type | [Reference](pages/IO/Logical-Model/index.md#IO) |
| def | EIO | EIO (ε α : Type) : Type | [Reference](pages/IO/Logical-Model/index.md#EIO) |
| def | IO.lazyPure | IO.lazyPure {α : Type} (fn : Unit → α) : IO α | [Reference](pages/IO/Logical-Model/index.md#IO___lazyPure) |
| def | BaseIO.toIO | BaseIO.toIO {α : Type} (act : BaseIO α) : IO α | [Reference](pages/IO/Logical-Model/index.md#BaseIO___toIO) |
| def | BaseIO.toEIO | BaseIO.toEIO {α ε : Type} (act : BaseIO α) : EIO ε α | [Reference](pages/IO/Logical-Model/index.md#BaseIO___toEIO) |
| def | EIO.toBaseIO | EIO.toBaseIO {ε α : Type} (act : EIO ε α) : BaseIO (Except ε α) | [Reference](pages/IO/Logical-Model/index.md#EIO___toBaseIO) |
| def | EIO.toIO | EIO.toIO {ε α : Type} (f : ε → IO.Error) (act : EIO ε α) : IO α | [Reference](pages/IO/Logical-Model/index.md#EIO___toIO) |
| def | EIO.toIO' | EIO.toIO' {ε α : Type} (act : EIO ε α) : IO (Except ε α) | [Reference](pages/IO/Logical-Model/index.md#EIO___toIO___) |
| def | IO.toEIO | IO.toEIO {ε α : Type} (f : IO.Error → ε) (act : IO α) : EIO ε α | [Reference](pages/IO/Logical-Model/index.md#IO___toEIO) |
| inductive type | IO.Error | IO.Error : Type | [Reference](pages/IO/Logical-Model/index.md#IO___Error___alreadyExists) |
| def | IO.Error.toString | IO.Error.toString : IO.Error → String | [Reference](pages/IO/Logical-Model/index.md#IO___Error___toString) |
| def | IO.ofExcept | IO.ofExcept.{u_1} {ε : Type u_1} {α : Type} [ToString ε] (e : Except ε α) : IO α | [Reference](pages/IO/Logical-Model/index.md#IO___ofExcept) |
| def | EIO.catchExceptions | EIO.catchExceptions {ε α : Type} (act : EIO ε α) (h : ε → BaseIO α) : BaseIO α | [Reference](pages/IO/Logical-Model/index.md#EIO___catchExceptions) |
| def | IO.userError | IO.userError (s : String) : IO.Error | [Reference](pages/IO/Logical-Model/index.md#IO___userError) |
| opaque | IO.iterate | IO.iterate {α β : Type} (a : α) (f : α → IO (α ⊕ β)) : IO β | [Reference](pages/IO/Control-Structures/index.md#IO___iterate) |
| def | IO.print | IO.print.{u_1} {α : Type u_1} [ToString α] (s : α) : IO Unit | [Reference](pages/IO/Console-Output/index.md#IO___print) |
| def | IO.println | IO.println.{u_1} {α : Type u_1} [ToString α] (s : α) : IO Unit | [Reference](pages/IO/Console-Output/index.md#IO___println) |
| def | IO.eprint | IO.eprint.{u_1} {α : Type u_1} [ToString α] (s : α) : IO Unit | [Reference](pages/IO/Console-Output/index.md#IO___eprint) |
| def | IO.eprintln | IO.eprintln.{u_1} {α : Type u_1} [ToString α] (s : α) : IO Unit | [Reference](pages/IO/Console-Output/index.md#IO___eprintln) |
| def | IO.Ref | IO.Ref (α : Type) : Type | [Reference](pages/IO/Mutable-References/index.md#IO___Ref) |
| def | IO.mkRef | IO.mkRef {α : Type} (a : α) : BaseIO (IO.Ref α) | [Reference](pages/IO/Mutable-References/index.md#IO___mkRef) |
| def | ST | ST (σ α : Type) : Type | [Reference](pages/IO/Mutable-References/index.md#ST) |
| def | runST | runST {α : Type} (x : (σ : Type) → ST σ α) : α | [Reference](pages/IO/Mutable-References/index.md#runST) |
| def | EST | EST (ε σ α : Type) : Type | [Reference](pages/IO/Mutable-References/index.md#EST) |
| def | runEST | runEST {ε α : Type} (x : (σ : Type) → EST ε σ α) : Except ε α | [Reference](pages/IO/Mutable-References/index.md#runEST) |
| structure | ST.Ref | ST.Ref (σ α : Type) : Type | [Reference](pages/IO/Mutable-References/index.md#ST___Ref___mk) |
| def | ST.mkRef | ST.mkRef {σ : Type} {m : Type → Type} [MonadLiftT (ST σ) m] {α : Type} (a : α) : m (ST.Ref σ α) | [Reference](pages/IO/Mutable-References/index.md#ST___mkRef) |
| def | ST.Ref.get | ST.Ref.get {σ : Type} {m : Type → Type} [MonadLiftT (ST σ) m] {α : Type} (r : ST.Ref σ α) : m α | [Reference](pages/IO/Mutable-References/index.md#ST___Ref___get) |
| def | MonadLiftT | ST.Ref.set {σ : Type} {m : Type → Type} [MonadLiftT (ST σ) m] {α : Type} (r : ST.Ref σ α) (a : α) : m Unit | [Reference](pages/IO/Mutable-References/index.md#ST___Ref___set) |
| def | ST.Ref.modify | ST.Ref.modify {σ : Type} {m : Type → Type} [MonadLiftT (ST σ) m] {α : Type} (r : ST.Ref σ α) (f : α → α) : m Unit | [Reference](pages/IO/Mutable-References/index.md#ST___Ref___modify) |
| def | ST.Ref.modifyGet | ST.Ref.modifyGet {σ : Type} {m : Type → Type} [MonadLiftT (ST σ) m] {α β : Type} (r : ST.Ref σ α) (f : α → β × α) : m β | [Reference](pages/IO/Mutable-References/index.md#ST___Ref___modifyGet) |
| def | ST.Ref.swap | ST.Ref.swap {σ : Type} {m : Type → Type} [MonadLiftT (ST σ) m] {α : Type} (r : ST.Ref σ α) (a : α) : m α | [Reference](pages/IO/Mutable-References/index.md#ST___Ref___swap) |
| def | ST.Ref.ptrEq | ST.Ref.ptrEq {σ : Type} {m : Type → Type} [MonadLiftT (ST σ) m] {α : Type} (r1 r2 : ST.Ref σ α) : m Bool | [Reference](pages/IO/Mutable-References/index.md#ST___Ref___ptrEq) |
| def | ST.Ref.toMonadStateOf | ST.Ref.toMonadStateOf {σ : Type} {m : Type → Type} [MonadLiftT (ST σ) m] {α : Type} (r : ST.Ref σ α) : MonadStateOf α m | [Reference](pages/IO/Mutable-References/index.md#ST___Ref___toMonadStateOf) |
| unsafe def | ST.Ref.take | ST.Ref.take {σ : Type} {m : Type → Type} [MonadLiftT (ST σ) m] {α : Type} (r : ST.Ref σ α) : m α | [Reference](pages/IO/Mutable-References/index.md#ST___Ref___take) |
| opaque | IO.FS.Handle | IO.FS.Handle : Type | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Handle) |
| opaque | IO.FS.Handle.mk | IO.FS.Handle.mk (fn : System.FilePath) (mode : IO.FS.Mode) : IO IO.FS.Handle | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Handle___mk) |
| inductive type | IO.FS.Mode | IO.FS.Mode : Type | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Mode___read) |
| opaque | IO.FS.Handle.read | IO.FS.Handle.read (h : IO.FS.Handle) (bytes : USize) : IO ByteArray | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Handle___read) |
| def | IO.FS.Handle.readToEnd | IO.FS.Handle.readToEnd (h : IO.FS.Handle) : IO String | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Handle___readToEnd) |
| def | IO.FS.Handle.readBinToEnd | IO.FS.Handle.readBinToEnd (h : IO.FS.Handle) : IO ByteArray | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Handle___readBinToEnd) |
| def | IO.FS.Handle.readBinToEndInto | IO.FS.Handle.readBinToEndInto (h : IO.FS.Handle) (buf : ByteArray) : IO ByteArray | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Handle___readBinToEndInto) |
| opaque | IO.FS.Handle.getLine | IO.FS.Handle.getLine (h : IO.FS.Handle) : IO String | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Handle___getLine) |
| opaque | IO.FS.Handle.write | IO.FS.Handle.write (h : IO.FS.Handle) (buffer : ByteArray) : IO Unit | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Handle___write) |
| opaque | IO.FS.Handle.putStr | IO.FS.Handle.putStr (h : IO.FS.Handle) (s : String) : IO Unit | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Handle___putStr) |
| def | IO.FS.Handle.putStrLn | IO.FS.Handle.putStrLn (h : IO.FS.Handle) (s : String) : IO Unit | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Handle___putStrLn) |
| opaque | IO.FS.Handle.flush | IO.FS.Handle.flush (h : IO.FS.Handle) : IO Unit | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Handle___flush) |
| opaque | IO.FS.Handle.rewind | IO.FS.Handle.rewind (h : IO.FS.Handle) : IO Unit | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Handle___rewind) |
| opaque | IO.FS.Handle.truncate | IO.FS.Handle.truncate (h : IO.FS.Handle) : IO Unit | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Handle___truncate) |
| opaque | IO.FS.Handle.isTty | IO.FS.Handle.isTty (h : IO.FS.Handle) : BaseIO Bool | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Handle___isTty) |
| opaque | IO.FS.Handle.lock | IO.FS.Handle.lock (h : IO.FS.Handle) (exclusive : Bool := true) : IO Unit | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Handle___lock) |
| opaque | IO.FS.Handle.tryLock | IO.FS.Handle.tryLock (h : IO.FS.Handle) (exclusive : Bool := true) : IO Bool | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Handle___tryLock) |
| opaque | IO.FS.Handle.unlock | IO.FS.Handle.unlock (h : IO.FS.Handle) : IO Unit | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Handle___unlock) |
| structure | IO.FS.Stream | IO.FS.Stream : Type | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Stream___mk) |
| def | IO.FS.Stream.ofBuffer | IO.FS.Stream.ofBuffer (r : IO.Ref IO.FS.Stream.Buffer) : IO.FS.Stream | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Stream___ofBuffer) |
| def | IO.FS.Stream.ofHandle | IO.FS.Stream.ofHandle (h : IO.FS.Handle) : IO.FS.Stream | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Stream___ofHandle) |
| def | IO.FS.Stream.putStrLn | IO.FS.Stream.putStrLn (strm : IO.FS.Stream) (s : String) : IO Unit | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Stream___putStrLn) |
| structure | IO.FS.Stream.Buffer | IO.FS.Stream.Buffer : Type | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Stream___Buffer___mk) |
| structure | System.FilePath | System.FilePath : Type | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___mk) |
| def | System.mkFilePath | System.mkFilePath (parts : List String) : System.FilePath | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___mkFilePath) |
| def | System.FilePath.join | System.FilePath.join (p sub : System.FilePath) : System.FilePath | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___join) |
| def | System.FilePath.normalize | System.FilePath.normalize (p : System.FilePath) : System.FilePath | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___normalize) |
| def | System.FilePath.isAbsolute | System.FilePath.isAbsolute (p : System.FilePath) : Bool | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___isAbsolute) |
| def | System.FilePath.isRelative | System.FilePath.isRelative (p : System.FilePath) : Bool | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___isRelative) |
| def | System.FilePath.parent | System.FilePath.parent (p : System.FilePath) : Option System.FilePath | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___parent) |
| def | System.FilePath.components | System.FilePath.components (p : System.FilePath) : List String | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___components) |
| def | System.FilePath.fileName | System.FilePath.fileName (p : System.FilePath) : Option String | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___fileName) |
| def | System.FilePath.fileStem | System.FilePath.fileStem (p : System.FilePath) : Option String | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___fileStem) |
| def | System.FilePath.extension | System.FilePath.extension (p : System.FilePath) : Option String | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___extension) |
| def | System.FilePath.addExtension | System.FilePath.addExtension (p : System.FilePath) (ext : String) : System.FilePath | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___addExtension) |
| def | System.FilePath.withExtension | System.FilePath.withExtension (p : System.FilePath) (ext : String) : System.FilePath | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___withExtension) |
| def | System.FilePath.withFileName | System.FilePath.withFileName (p : System.FilePath) (fname : String) : System.FilePath | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___withFileName) |
| def | System.FilePath.pathSeparator | System.FilePath.pathSeparator : Char | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___pathSeparator) |
| def | System.FilePath.pathSeparators | System.FilePath.pathSeparators : List Char | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___pathSeparators) |
| def | System.FilePath.extSeparator | System.FilePath.extSeparator : Char | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___extSeparator) |
| def | System.FilePath.exeExtension | System.FilePath.exeExtension : String | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___exeExtension) |
| structure | IO.FS.Metadata | IO.FS.Metadata : Type | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___Metadata___mk) |
| opaque | System.FilePath.metadata | System.FilePath.metadata : System.FilePath → IO IO.FS.Metadata | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___metadata) |
| opaque | System.FilePath.symlinkMetadata | System.FilePath.symlinkMetadata : System.FilePath → IO IO.FS.Metadata | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___symlinkMetadata) |
| def | System.FilePath.pathExists | System.FilePath.pathExists (p : System.FilePath) : BaseIO Bool | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___pathExists) |
| def | System.FilePath.isDir | System.FilePath.isDir (p : System.FilePath) : BaseIO Bool | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___isDir) |
| structure | IO.FS.DirEntry | IO.FS.DirEntry : Type | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___DirEntry___mk) |
| def | IO.FS.DirEntry.path | IO.FS.DirEntry.path (entry : IO.FS.DirEntry) : System.FilePath | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___DirEntry___path) |
| opaque | System.FilePath.readDir | System.FilePath.readDir : System.FilePath → IO (Array IO.FS.DirEntry) | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___readDir) |
| def | System.FilePath.walkDir | System.FilePath.walkDir (p : System.FilePath) (enter : System.FilePath → IO Bool := fun x => pure true) : IO (Array System.FilePath) | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#System___FilePath___walkDir) |
| structure | IO.AccessRight | IO.AccessRight : Type | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___AccessRight___mk) |
| def | IO.AccessRight.flags | IO.AccessRight.flags (acc : IO.AccessRight) : UInt32 | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___AccessRight___flags) |
| structure | IO.FileRight | IO.FileRight : Type | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FileRight___mk) |
| def | IO.FileRight.flags | IO.FileRight.flags (acc : IO.FileRight) : UInt32 | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FileRight___flags) |
| def | IO.setAccessRights | IO.setAccessRights (filename : System.FilePath) (mode : IO.FileRight) : IO Unit | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___setAccessRights) |
| opaque | IO.FS.removeFile | IO.FS.removeFile (fname : System.FilePath) : IO Unit | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___removeFile) |
| opaque | IO.FS.rename | IO.FS.rename (old new : System.FilePath) : IO Unit | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___rename) |
| opaque | IO.FS.removeDir | IO.FS.removeDir : System.FilePath → IO Unit | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___removeDir) |
| def | IO.FS.lines | IO.FS.lines (fname : System.FilePath) : IO (Array String) | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___lines) |
| def | IO.FS.withTempFile | IO.FS.withTempFile.{u_1} {m : Type → Type u_1} {α : Type} [Monad m] [MonadFinally m] [MonadLiftT IO m] (f : IO.FS.Handle → System.FilePath → m α) : m α | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___withTempFile) |
| def | IO.FS.withTempDir | IO.FS.withTempDir.{u_1} {m : Type → Type u_1} {α : Type} [Monad m] [MonadFinally m] [MonadLiftT IO m] (f : System.FilePath → m α) : m α | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___withTempDir) |
| opaque | IO.FS.createDirAll | IO.FS.createDirAll (p : System.FilePath) : IO Unit | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___createDirAll) |
| def | IO.FS.writeBinFile | IO.FS.writeBinFile (fname : System.FilePath) (content : ByteArray) : IO Unit | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___writeBinFile) |
| def | IO.FS.withFile | IO.FS.withFile {α : Type} (fn : System.FilePath) (mode : IO.FS.Mode) (f : IO.FS.Handle → IO α) : IO α | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___withFile) |
| opaque | IO.FS.removeDirAll | IO.FS.removeDirAll (p : System.FilePath) : IO Unit | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___removeDirAll) |
| opaque | IO.FS.createTempFile | IO.FS.createTempFile : IO (IO.FS.Handle × System.FilePath) | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___createTempFile) |
| opaque | IO.FS.createTempDir | IO.FS.createTempDir : IO System.FilePath | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___createTempDir) |
| def | IO.FS.readFile | IO.FS.readFile (fname : System.FilePath) : IO String | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___readFile) |
| opaque | IO.FS.realPath | IO.FS.realPath (fname : System.FilePath) : IO System.FilePath | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___realPath) |
| def | IO.FS.writeFile | IO.FS.writeFile (fname : System.FilePath) (content : String) : IO Unit | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___writeFile) |
| def | IO.FS.readBinFile | IO.FS.readBinFile (fname : System.FilePath) : IO ByteArray | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___readBinFile) |
| opaque | IO.FS.createDir | IO.FS.createDir : System.FilePath → IO Unit | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___createDir) |
| opaque | IO.getStdin | IO.getStdin : BaseIO IO.FS.Stream | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___getStdin) |
| opaque | IO.setStdin | IO.setStdin : IO.FS.Stream → BaseIO IO.FS.Stream | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___setStdin) |
| def | IO.withStdin | IO.withStdin.{u_1} {m : Type → Type u_1} {α : Type} [Monad m] [MonadFinally m] [MonadLiftT BaseIO m] (h : IO.FS.Stream) (x : m α) : m α | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___withStdin) |
| opaque | IO.getStdout | IO.getStdout : BaseIO IO.FS.Stream | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___getStdout) |
| opaque | IO.setStdout | IO.setStdout : IO.FS.Stream → BaseIO IO.FS.Stream | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___setStdout) |
| def | IO.withStdout | IO.withStdout.{u_1} {m : Type → Type u_1} {α : Type} [Monad m] [MonadFinally m] [MonadLiftT BaseIO m] (h : IO.FS.Stream) (x : m α) : m α | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___withStdout) |
| opaque | IO.getStderr | IO.getStderr : BaseIO IO.FS.Stream | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___getStderr) |
| opaque | IO.setStderr | IO.setStderr : IO.FS.Stream → BaseIO IO.FS.Stream | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___setStderr) |
| def | IO.withStderr | IO.withStderr.{u_1} {m : Type → Type u_1} {α : Type} [Monad m] [MonadFinally m] [MonadLiftT BaseIO m] (h : IO.FS.Stream) (x : m α) : m α | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___withStderr) |
| def | IO.FS.withIsolatedStreams | IO.FS.withIsolatedStreams.{u_1} {m : Type → Type u_1} {α : Type} [Monad m] [MonadFinally m] [MonadLiftT BaseIO m] (x : m α) (isolateStderr : Bool := true) : m ( … | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___FS___withIsolatedStreams) |
| opaque | IO.currentDir | IO.currentDir : IO System.FilePath | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___currentDir) |
| opaque | IO.appPath | IO.appPath : IO System.FilePath | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___appPath) |
| def | IO.appDir | IO.appDir : IO System.FilePath | [Reference](pages/IO/Files___-File-Handles___-and-Streams/index.md#IO___appDir) |
| def | System.Platform.numBits | System.Platform.numBits : Nat | [Reference](pages/IO/System-and-Platform-Information/index.md#System___Platform___numBits) |
| def | System.Platform.target | System.Platform.target : String | [Reference](pages/IO/System-and-Platform-Information/index.md#System___Platform___target) |
| def | System.Platform.isWindows | System.Platform.isWindows : Bool | [Reference](pages/IO/System-and-Platform-Information/index.md#System___Platform___isWindows) |
| def | System.Platform.isOSX | System.Platform.isOSX : Bool | [Reference](pages/IO/System-and-Platform-Information/index.md#System___Platform___isOSX) |
| def | System.Platform.isEmscripten | System.Platform.isEmscripten : Bool | [Reference](pages/IO/System-and-Platform-Information/index.md#System___Platform___isEmscripten) |
| opaque | IO.getEnv | IO.getEnv (var : String) : BaseIO (Option String) | [Reference](pages/IO/Environment-Variables/index.md#IO___getEnv) |
| opaque | IO.sleep | IO.sleep (ms : UInt32) : BaseIO Unit | [Reference](pages/IO/Timing/index.md#IO___sleep) |
| opaque | IO.monoNanosNow | IO.monoNanosNow : BaseIO Nat | [Reference](pages/IO/Timing/index.md#IO___monoNanosNow) |
| opaque | IO.monoMsNow | IO.monoMsNow : BaseIO Nat | [Reference](pages/IO/Timing/index.md#IO___monoMsNow) |
| opaque | IO.getNumHeartbeats | IO.getNumHeartbeats : BaseIO Nat | [Reference](pages/IO/Timing/index.md#IO___getNumHeartbeats) |
| def | IO.addHeartbeats | IO.addHeartbeats (count : Nat) : BaseIO Unit | [Reference](pages/IO/Timing/index.md#IO___addHeartbeats) |
| opaque | IO.Process.getCurrentDir | IO.Process.getCurrentDir : IO System.FilePath | [Reference](pages/IO/Processes/index.md#IO___Process___getCurrentDir) |
| opaque | IO.Process.setCurrentDir | IO.Process.setCurrentDir (path : System.FilePath) : IO Unit | [Reference](pages/IO/Processes/index.md#IO___Process___setCurrentDir) |
| opaque | IO.Process.exit | IO.Process.exit {α : Type} : UInt8 → IO α | [Reference](pages/IO/Processes/index.md#IO___Process___exit) |
| opaque | IO.Process.getPID | IO.Process.getPID : BaseIO UInt32 | [Reference](pages/IO/Processes/index.md#IO___Process___getPID) |
| def | IO.Process.run | IO.Process.run (args : IO.Process.SpawnArgs) (input? : Option String := none) : IO String | [Reference](pages/IO/Processes/index.md#IO___Process___run) |
| def | IO.Process.output | IO.Process.output (args : IO.Process.SpawnArgs) (input? : Option String := none) : IO IO.Process.Output | [Reference](pages/IO/Processes/index.md#IO___Process___output) |
| opaque | IO.Process.spawn | IO.Process.spawn (args : IO.Process.SpawnArgs) : IO (IO.Process.Child args.toStdioConfig) | [Reference](pages/IO/Processes/index.md#IO___Process___spawn) |
| structure | IO.Process.SpawnArgs | IO.Process.SpawnArgs : Type | [Reference](pages/IO/Processes/index.md#IO___Process___SpawnArgs___mk) |
| structure | IO.Process.StdioConfig | IO.Process.StdioConfig : Type | [Reference](pages/IO/Processes/index.md#IO___Process___StdioConfig___mk) |
| inductive type | IO.Process.Stdio | IO.Process.Stdio : Type | [Reference](pages/IO/Processes/index.md#IO___Process___Stdio___piped) |
| def | IO.Process.Stdio.toHandleType | IO.Process.Stdio.toHandleType : IO.Process.Stdio → Type | [Reference](pages/IO/Processes/index.md#IO___Process___Stdio___toHandleType) |
| structure | IO.Process.Child | IO.Process.Child (cfg : IO.Process.StdioConfig) : Type | [Reference](pages/IO/Processes/index.md#IO___Process___Child___stdin) |
| opaque | IO.Process.Child.wait | IO.Process.Child.wait {cfg : IO.Process.StdioConfig} : IO.Process.Child cfg → IO UInt32 | [Reference](pages/IO/Processes/index.md#IO___Process___Child___wait) |
| opaque | IO.Process.Child.tryWait | IO.Process.Child.tryWait {cfg : IO.Process.StdioConfig} : IO.Process.Child cfg → IO (Option UInt32) | [Reference](pages/IO/Processes/index.md#IO___Process___Child___tryWait) |
| opaque | IO.Process.Child.kill | IO.Process.Child.kill {cfg : IO.Process.StdioConfig} : IO.Process.Child cfg → IO Unit | [Reference](pages/IO/Processes/index.md#IO___Process___Child___kill) |
| opaque | IO.Process.Child.takeStdin | IO.Process.Child.takeStdin {cfg : IO.Process.StdioConfig} : IO.Process.Child cfg → IO (cfg.stdin.toHandleType × IO.Process.Child { stdin := IO.Process.Stdio.nul … | [Reference](pages/IO/Processes/index.md#IO___Process___Child___takeStdin) |
| structure | IO.Process.Output | IO.Process.Output : Type | [Reference](pages/IO/Processes/index.md#IO___Process___Output___mk) |
| def | IO.setRandSeed | IO.setRandSeed (n : Nat) : BaseIO Unit | [Reference](pages/IO/Random-Numbers/index.md#IO___setRandSeed) |
| def | IO.rand | IO.rand (lo hi : Nat) : BaseIO Nat | [Reference](pages/IO/Random-Numbers/index.md#IO___rand) |
| def | randBool | randBool.{u} {gen : Type u} [RandomGen gen] (g : gen) : Bool × gen | [Reference](pages/IO/Random-Numbers/index.md#randBool) |
| def | randNat | randNat.{u} {gen : Type u} [RandomGen gen] (g : gen) (lo hi : Nat) : Nat × gen | [Reference](pages/IO/Random-Numbers/index.md#randNat) |
| type class | RandomGen | RandomGen.{u} (g : Type u) : Type u | [Reference](pages/IO/Random-Numbers/index.md#RandomGen___mk) |
| structure | StdGen | StdGen : Type | [Reference](pages/IO/Random-Numbers/index.md#StdGen) |
| def | stdRange | stdRange : Nat × Nat | [Reference](pages/IO/Random-Numbers/index.md#stdRange) |
| def | stdNext | stdNext : StdGen → Nat × StdGen | [Reference](pages/IO/Random-Numbers/index.md#stdNext) |
| def | stdSplit | stdSplit : StdGen → StdGen × StdGen | [Reference](pages/IO/Random-Numbers/index.md#stdSplit) |
| def | mkStdGen | mkStdGen (s : Nat := 0) : StdGen | [Reference](pages/IO/Random-Numbers/index.md#mkStdGen) |
| opaque | IO.getRandomBytes | IO.getRandomBytes (nBytes : USize) : IO ByteArray | [Reference](pages/IO/Random-Numbers/index.md#IO___getRandomBytes) |
| type | Task | Task.{u} (α : Type u) : Type u | [Reference](pages/IO/Tasks-and-Threads/index.md#Task) |
| def | Task.spawn | Task.spawn.{u} {α : Type u} (fn : Unit → α) (prio : Task.Priority := Task.Priority.default) : Task α | [Reference](pages/IO/Tasks-and-Threads/index.md#Task___spawn) |
| constructor of Task | Task.pure | Task.pure.{u} {α : Type u} (get : α) : Task α | [Reference](pages/IO/Tasks-and-Threads/index.md#Task___pure) |
| opaque | BaseIO.asTask | BaseIO.asTask {α : Type} (act : BaseIO α) (prio : Task.Priority := Task.Priority.default) : BaseIO (Task α) | [Reference](pages/IO/Tasks-and-Threads/index.md#BaseIO___asTask) |
| def | EIO.asTask | EIO.asTask {ε α : Type} (act : EIO ε α) (prio : Task.Priority := Task.Priority.default) : BaseIO (Task (Except ε α)) | [Reference](pages/IO/Tasks-and-Threads/index.md#EIO___asTask) |
| def | IO.asTask | IO.asTask {α : Type} (act : IO α) (prio : Task.Priority := Task.Priority.default) : BaseIO (Task (Except IO.Error α)) | [Reference](pages/IO/Tasks-and-Threads/index.md#IO___asTask) |
| def | Task.Priority | Task.Priority : Type | [Reference](pages/IO/Tasks-and-Threads/index.md#Task___Priority) |
| def | Task.Priority.default | Task.Priority.default : Task.Priority | [Reference](pages/IO/Tasks-and-Threads/index.md#Task___Priority___default) |
| def | Task.Priority.max | Task.Priority.max : Task.Priority | [Reference](pages/IO/Tasks-and-Threads/index.md#Task___Priority___max) |
| def | Task.Priority.dedicated | Task.Priority.dedicated : Task.Priority | [Reference](pages/IO/Tasks-and-Threads/index.md#Task___Priority___dedicated) |
| def | Task.get | Task.get.{u} {α : Type u} (self : Task α) : α | [Reference](pages/IO/Tasks-and-Threads/index.md#Task___get) |
| opaque | IO.wait | IO.wait {α : Type} (t : Task α) : BaseIO α | [Reference](pages/IO/Tasks-and-Threads/index.md#IO___wait) |
| opaque | IO.waitAny | IO.waitAny {α : Type} (tasks : List (Task α)) (h : tasks.length > 0 := by exact Nat.zero_lt_succ _) : BaseIO α | [Reference](pages/IO/Tasks-and-Threads/index.md#IO___waitAny) |
| def | Task.map | Task.map.{u_1, u_2} {α : Type u_1} {β : Type u_2} (f : α → β) (x : Task α) (prio : Task.Priority := Task.Priority.default) (sync : Bool := false) : Task β | [Reference](pages/IO/Tasks-and-Threads/index.md#Task___map) |
| def | Task.bind | Task.bind.{u_1, u_2} {α : Type u_1} {β : Type u_2} (x : Task α) (f : α → Task β) (prio : Task.Priority := Task.Priority.default) (sync : Bool := false) : Task β … | [Reference](pages/IO/Tasks-and-Threads/index.md#Task___bind) |
| def | Task.mapList | Task.mapList.{u_1, u_2} {α : Type u_1} {β : Type u_2} (f : List α → β) (tasks : List (Task α)) (prio : Task.Priority := Task.Priority.default) (sync : Bool := f … | [Reference](pages/IO/Tasks-and-Threads/index.md#Task___mapList) |
| opaque | BaseIO.mapTask | BaseIO.mapTask.{u_1} {α : Type u_1} {β : Type} (f : α → BaseIO β) (t : Task α) (prio : Task.Priority := Task.Priority.default) (sync : Bool := false) : BaseIO ( … | [Reference](pages/IO/Tasks-and-Threads/index.md#BaseIO___mapTask) |
| def | EIO.mapTask | EIO.mapTask.{u_1} {α : Type u_1} {ε β : Type} (f : α → EIO ε β) (t : Task α) (prio : Task.Priority := Task.Priority.default) (sync : Bool := false) : BaseIO (Ta … | [Reference](pages/IO/Tasks-and-Threads/index.md#EIO___mapTask) |
| def | IO.mapTask | IO.mapTask.{u_1} {α : Type u_1} {β : Type} (f : α → IO β) (t : Task α) (prio : Task.Priority := Task.Priority.default) (sync : Bool := false) : BaseIO (Task (Ex … | [Reference](pages/IO/Tasks-and-Threads/index.md#IO___mapTask) |
| def | BaseIO.mapTasks | BaseIO.mapTasks.{u_1} {α : Type u_1} {β : Type} (f : List α → BaseIO β) (tasks : List (Task α)) (prio : Task.Priority := Task.Priority.default) (sync : Bool :=  … | [Reference](pages/IO/Tasks-and-Threads/index.md#BaseIO___mapTasks) |
| def | EIO.mapTasks | EIO.mapTasks.{u_1} {α : Type u_1} {ε β : Type} (f : List α → EIO ε β) (tasks : List (Task α)) (prio : Task.Priority := Task.Priority.default) (sync : Bool := fa … | [Reference](pages/IO/Tasks-and-Threads/index.md#EIO___mapTasks) |
| def | IO.mapTasks | IO.mapTasks.{u_1} {α : Type u_1} {β : Type} (f : List α → IO β) (tasks : List (Task α)) (prio : Task.Priority := Task.Priority.default) (sync : Bool := false) : … | [Reference](pages/IO/Tasks-and-Threads/index.md#IO___mapTasks) |
| opaque | BaseIO.bindTask | BaseIO.bindTask.{u_1} {α : Type u_1} {β : Type} (t : Task α) (f : α → BaseIO (Task β)) (prio : Task.Priority := Task.Priority.default) (sync : Bool := false) :  … | [Reference](pages/IO/Tasks-and-Threads/index.md#BaseIO___bindTask) |
| def | EIO.bindTask | EIO.bindTask.{u_1} {α : Type u_1} {ε β : Type} (t : Task α) (f : α → EIO ε (Task (Except ε β))) (prio : Task.Priority := Task.Priority.default) (sync : Bool :=  … | [Reference](pages/IO/Tasks-and-Threads/index.md#EIO___bindTask) |
| def | IO.bindTask | IO.bindTask.{u_1} {α : Type u_1} {β : Type} (t : Task α) (f : α → IO (Task (Except IO.Error β))) (prio : Task.Priority := Task.Priority.default) (sync : Bool := … | [Reference](pages/IO/Tasks-and-Threads/index.md#IO___bindTask) |
| def | BaseIO.chainTask | BaseIO.chainTask.{u_1} {α : Type u_1} (t : Task α) (f : α → BaseIO Unit) (prio : Task.Priority := Task.Priority.default) (sync : Bool := false) : BaseIO Unit … | [Reference](pages/IO/Tasks-and-Threads/index.md#BaseIO___chainTask) |
| def | EIO.chainTask | EIO.chainTask.{u_1} {α : Type u_1} {ε : Type} (t : Task α) (f : α → EIO ε Unit) (prio : Task.Priority := Task.Priority.default) (sync : Bool := false) : EIO ε U … | [Reference](pages/IO/Tasks-and-Threads/index.md#EIO___chainTask) |
| def | IO.chainTask | IO.chainTask.{u_1} {α : Type u_1} (t : Task α) (f : α → IO Unit) (prio : Task.Priority := Task.Priority.default) (sync : Bool := false) : IO Unit | [Reference](pages/IO/Tasks-and-Threads/index.md#IO___chainTask) |
| opaque | IO.cancel | IO.cancel.{u_1} {α : Type u_1} : Task α → BaseIO Unit | [Reference](pages/IO/Tasks-and-Threads/index.md#IO___cancel) |
| opaque | IO.checkCanceled | IO.checkCanceled : BaseIO Bool | [Reference](pages/IO/Tasks-and-Threads/index.md#IO___checkCanceled) |
| def | IO.hasFinished | IO.hasFinished.{u_1} {α : Type u_1} (task : Task α) : BaseIO Bool | [Reference](pages/IO/Tasks-and-Threads/index.md#IO___hasFinished) |
| opaque | IO.getTaskState | IO.getTaskState.{u_1} {α : Type u_1} : Task α → BaseIO IO.TaskState | [Reference](pages/IO/Tasks-and-Threads/index.md#IO___getTaskState) |
| inductive type | IO.TaskState | IO.TaskState : Type | [Reference](pages/IO/Tasks-and-Threads/index.md#IO___TaskState___waiting) |
| opaque | IO.getTID | IO.getTID : BaseIO UInt64 | [Reference](pages/IO/Tasks-and-Threads/index.md#IO___getTID) |
| structure | IO.Promise | IO.Promise (α : Type) : Type | [Reference](pages/IO/Tasks-and-Threads/index.md#IO___Promise) |
| opaque | IO.Promise.new | IO.Promise.new {α : Type} [Nonempty α] : BaseIO (IO.Promise α) | [Reference](pages/IO/Tasks-and-Threads/index.md#IO___Promise___new) |
| def | IO.Promise.isResolved | IO.Promise.isResolved {α : Type} (promise : IO.Promise α) : BaseIO Bool | [Reference](pages/IO/Tasks-and-Threads/index.md#IO___Promise___isResolved) |
| opaque | IO.Promise.result? | IO.Promise.result? {α : Type} (promise : IO.Promise α) : Task (Option α) | [Reference](pages/IO/Tasks-and-Threads/index.md#IO___Promise___result___) |
| def | IO.Promise.result! | IO.Promise.result! {α : Type} (promise : IO.Promise α) : Task α | [Reference](pages/IO/Tasks-and-Threads/index.md#IO___Promise___result___-next) |
| def | IO.Promise.resultD | IO.Promise.resultD {α : Type} (promise : IO.Promise α) (dflt : α) : Task α | [Reference](pages/IO/Tasks-and-Threads/index.md#IO___Promise___resultD) |
| opaque | IO.Promise.resolve | IO.Promise.resolve {α : Type} (value : α) (promise : IO.Promise α) : BaseIO Unit | [Reference](pages/IO/Tasks-and-Threads/index.md#IO___Promise___resolve) |
| structure | Std.Channel | Std.Channel (α : Type) : Type | [Reference](pages/IO/Tasks-and-Threads/index.md#Std___Channel) |
| def | Std.Channel.new | Std.Channel.new {α : Type} (capacity : Option Nat := none) : BaseIO (Std.Channel α) | [Reference](pages/IO/Tasks-and-Threads/index.md#Std___Channel___new) |
| def | Std.Channel.send | Std.Channel.send {α : Type} (ch : Std.Channel α) (v : α) : BaseIO (Task Unit) | [Reference](pages/IO/Tasks-and-Threads/index.md#Std___Channel___send) |
| def | Std.Channel.recv | Std.Channel.recv {α : Type} [Inhabited α] (ch : Std.Channel α) : BaseIO (Task α) | [Reference](pages/IO/Tasks-and-Threads/index.md#Std___Channel___recv) |
| opaque | Std.Channel.forAsync | Std.Channel.forAsync {α : Type} [Inhabited α] (f : α → BaseIO Unit) (ch : Std.Channel α) (prio : Task.Priority := Task.Priority.default) : BaseIO (Task Unit) … | [Reference](pages/IO/Tasks-and-Threads/index.md#Std___Channel___forAsync) |
| def | Std.Channel.sync | Std.Channel.sync {α : Type} (ch : Std.Channel α) : Std.Channel.Sync α | [Reference](pages/IO/Tasks-and-Threads/index.md#Std___Channel___sync) |
| def | Std.Channel.Sync | Std.Channel.Sync (α : Type) : Type | [Reference](pages/IO/Tasks-and-Threads/index.md#Std___Channel___Sync) |
| def | Std.CloseableChannel | Std.CloseableChannel (α : Type) : Type | [Reference](pages/IO/Tasks-and-Threads/index.md#Std___CloseableChannel) |
| def | Std.CloseableChannel.new | Std.CloseableChannel.new {α : Type} (capacity : Option Nat := none) : BaseIO (Std.CloseableChannel α) | [Reference](pages/IO/Tasks-and-Threads/index.md#Std___CloseableChannel___new) |
| type | Std.Mutex | Std.Mutex (α : Type) : Type | [Reference](pages/IO/Tasks-and-Threads/index.md#Std___Mutex) |
| def | Std.Mutex.new | Std.Mutex.new {α : Type} (a : α) : BaseIO (Std.Mutex α) | [Reference](pages/IO/Tasks-and-Threads/index.md#Std___Mutex___new) |
| def | Std.Mutex.atomically | Std.Mutex.atomically {m : Type → Type} {α β : Type} [Monad m] [MonadLiftT BaseIO m] [MonadFinally m] (mutex : Std.Mutex α) (k : Std.AtomicT α m β) : m β | [Reference](pages/IO/Tasks-and-Threads/index.md#Std___Mutex___atomically) |
| def | Std.Mutex.atomicallyOnce | Std.Mutex.atomicallyOnce {m : Type → Type} {α β : Type} [Monad m] [MonadLiftT BaseIO m] [MonadFinally m] (mutex : Std.Mutex α) (condvar : Std.Condvar) (pred : S … | [Reference](pages/IO/Tasks-and-Threads/index.md#Std___Mutex___atomicallyOnce) |
| def | Std.AtomicT | Std.AtomicT (σ : Type) (m : Type → Type) (α : Type) : Type | [Reference](pages/IO/Tasks-and-Threads/index.md#Std___AtomicT) |
| def | Std.Condvar | Std.Condvar : Type | [Reference](pages/IO/Tasks-and-Threads/index.md#Std___Condvar) |
| opaque | Std.Condvar.new | Std.Condvar.new : BaseIO Std.Condvar | [Reference](pages/IO/Tasks-and-Threads/index.md#Std___Condvar___new) |
| opaque | Std.Condvar.wait | Std.Condvar.wait (condvar : Std.Condvar) (mutex : Std.BaseMutex) : BaseIO Unit | [Reference](pages/IO/Tasks-and-Threads/index.md#Std___Condvar___wait) |
| opaque | Std.Condvar.notifyOne | Std.Condvar.notifyOne (condvar : Std.Condvar) : BaseIO Unit | [Reference](pages/IO/Tasks-and-Threads/index.md#Std___Condvar___notifyOne) |
| opaque | Std.Condvar.notifyAll | Std.Condvar.notifyAll (condvar : Std.Condvar) : BaseIO Unit | [Reference](pages/IO/Tasks-and-Threads/index.md#Std___Condvar___notifyAll) |
| def | Std.Condvar.waitUntil | Std.Condvar.waitUntil.{u_1} {m : Type → Type u_1} [Monad m] [MonadLiftT BaseIO m] (condvar : Std.Condvar) (mutex : Std.BaseMutex) (pred : m Bool) : m Unit | [Reference](pages/IO/Tasks-and-Threads/index.md#Std___Condvar___waitUntil) |
| structure | Std.Iter | Std.Iter.{w} {α : Type w} (β : Type w) : Type w | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___Iter___mk) |
| structure | Std.IterM | Std.IterM.{w, w'} {α : Type w} (m : Type w → Type w') (β : Type w) : Type w | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___IterM___mk) |
| inductive type | Std.IterStep | Std.IterStep.{u_1, u_2} (α : Sort u_1) (β : Sort u_2) : Sort (max (max 1 u_1) u_2) | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___IterStep___yield) |
| def | Std.Iterator | Std.Iter.Step.{w} {α β : Type w} [Iterator α Id β] (it : Iter β) : Type w | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___Iter___Step) |
| def | Std.Iterator | Std.IterM.Step.{w, w'} {α : Type w} {m : Type w → Type w'} {β : Type w} [Iterator α m β] (it : IterM m β) : Type w | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___IterM___Step) |
| type class | Std.Iterator | Std.Iterator.{w, w'} (α : Type w) (m : Type w → Type w') (β : outParam (Type w)) : Type (max w w') | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___Iterator___mk) |
| def | Std.PlausibleIterStep | Std.PlausibleIterStep.{u, w} {α : Type u} {β : Type w} (IsPlausibleStep : IterStep α β → Prop) : Type (max 0 u w) | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___PlausibleIterStep) |
| def | Std.PlausibleIterStep.yield | Std.PlausibleIterStep.yield.{u, w} {α : Type u} {β : Type w} {IsPlausibleStep : IterStep α β → Prop} (it' : α) (out : β) (h : IsPlausibleStep (IterStep.yield it … | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___PlausibleIterStep___yield) |
| def | Std.PlausibleIterStep.skip | Std.PlausibleIterStep.skip.{u, w} {α : Type u} {β : Type w} {IsPlausibleStep : IterStep α β → Prop} (it' : α) (h : IsPlausibleStep (IterStep.skip it')) : Plausi … | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___PlausibleIterStep___skip) |
| def | Std.PlausibleIterStep.done | Std.PlausibleIterStep.done.{u, w} {α : Type u} {β : Type w} {IsPlausibleStep : IterStep α β → Prop} (h : IsPlausibleStep IterStep.done) : PlausibleIterStep IsPl … | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___PlausibleIterStep___done) |
| type class | Std.Iterators.Finite | Std.Iterators.Finite.{w, w'} (α : Type w) (m : Type w → Type w') {β : Type w} [Iterator α m β] : Prop | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___Iterators___Finite___mk) |
| type class | Std.Iterators.Productive | Std.Iterators.Productive.{u_1, u_2} (α : Type u_1) (m : Type u_1 → Type u_2) {β : Type u_1} [Iterator α m β] : Prop | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___Iterators___Productive___mk) |
| def | Std.Iter.ensureTermination | Std.Iter.ensureTermination.{w} {α β : Type w} (it : Iter β) : Iter.Total β | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___Iter___ensureTermination) |
| def | Std.IterM.ensureTermination | Std.IterM.ensureTermination.{w, w'} {α β : Type w} {m : Type w → Type w'} (it : IterM m β) : IterM.Total m β | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___IterM___ensureTermination) |
| type class | Std.IteratorAccess | Std.IteratorAccess.{w, w'} (α : Type w) (m : Type w → Type w') {β : Type w} [Iterator α m β] : Type (max w w') | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___IteratorAccess___mk) |
| def | Std.IterM.nextAtIdx? | Std.IterM.nextAtIdx?.{u_1, u_2} {α : Type u_1} {m : Type u_1 → Type u_2} {β : Type u_1} [Iterator α m β] [IteratorAccess α m] (it : IterM m β) (n : Nat) : m (Pl … | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___IterM___nextAtIdx___) |
| type class | Std.IteratorLoop | Std.IteratorLoop.{w, w', x, x'} (α : Type w) (m : Type w → Type w') {β : Type w} [Iterator α m β] (n : Type x → Type x') : Type (max (max (max (w + 1) w') (x +  … | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___IteratorLoop___mk) |
| def | Std.IteratorLoop.defaultImplementation | Std.IteratorLoop.defaultImplementation.{w, w', x, x'} {β α : Type w} {m : Type w → Type w'} {n : Type x → Type x'} [Monad n] [Iterator α m β] : IteratorLoop α m … | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___IteratorLoop___defaultImplementation) |
| type class | Std.LawfulIteratorLoop | Std.LawfulIteratorLoop.{w, w', x, x'} {β : Type w} (α : Type w) (m : Type w → Type w') (n : Type x → Type x') [Monad m] [Monad n] [Iterator α m β] [i : Iterator … | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___LawfulIteratorLoop___mk) |
| def | Std.Shrink | Std.Shrink.{u} (α : Type u) : Type u | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___Shrink) |
| def | Std.Shrink.inflate | Std.Shrink.inflate.{u_1} {α : Type u_1} (x : Std.Shrink α) : α | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___Shrink___inflate) |
| def | Std.Shrink.deflate | Std.Shrink.deflate.{u_1} {α : Type u_1} (x : α) : Std.Shrink α | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___Shrink___deflate) |
| def | Std.Iter.empty | Std.Iter.empty.{w} (β : Type w) : Iter β | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___Iter___empty) |
| def | Std.IterM.empty | Std.IterM.empty.{w, w'} (m : Type w → Type w') (β : Type w) : IterM m β | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___IterM___empty) |
| def | Std.Iter.repeat | Std.Iter.repeat.{w} {α : Type w} (f : α → α) (init : α) : Iter α | [Reference](pages/Iterators/Iterator-Definitions/index.md#Std___Iter___repeat) |
| def | Std.Iterator | Std.Iter.step.{w} {α β : Type w} [Iterator α Id β] (it : Iter β) : it.Step | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___Iter___step) |
| def | Std.Iterator | Std.IterM.step.{w, w'} {α : Type w} {m : Type w → Type w'} {β : Type w} [Iterator α m β] (it : IterM m β) : m (Std.Shrink it.Step) | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___step) |
| def | Std.Iter.finitelyManySteps | Std.Iter.finitelyManySteps.{w} {α β : Type w} [Iterator α Id β] [Finite α Id] (it : Iter β) : IterM.TerminationMeasures.Finite α Id | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___Iter___finitelyManySteps) |
| def | Std.IterM.finitelyManySteps | Std.IterM.finitelyManySteps.{w, w'} {α : Type w} {m : Type w → Type w'} {β : Type w} [Iterator α m β] [Finite α m] (it : IterM m β) : IterM.TerminationMeasures. … | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___finitelyManySteps) |
| structure | Std.IterM.TerminationMeasures.Finite | Std.IterM.TerminationMeasures.Finite.{w, w'} (α : Type w) (m : Type w → Type w') {β : Type w} [Iterator α m β] : Type w | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___TerminationMeasures___Finite___mk) |
| def | Std.Iter.finitelyManySkips | Std.Iter.finitelyManySkips.{w} {α β : Type w} [Iterator α Id β] [Productive α Id] (it : Iter β) : IterM.TerminationMeasures.Productive α Id | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___Iter___finitelyManySkips) |
| def | Std.IterM.finitelyManySkips | Std.IterM.finitelyManySkips.{w, w'} {α : Type w} {m : Type w → Type w'} {β : Type w} [Iterator α m β] [Productive α m] (it : IterM m β) : IterM.TerminationMeasu … | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___finitelyManySkips) |
| structure | Std.IterM.TerminationMeasures.Productive | Std.IterM.TerminationMeasures.Productive.{w, w'} (α : Type w) (m : Type w → Type w') {β : Type w} [Iterator α m β] : Type w | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___TerminationMeasures___Productive___mk) |
| def | Std.Iter.fold | Std.Iter.fold.{w, x} {α β : Type w} {γ : Type x} [Iterator α Id β] [IteratorLoop α Id Id] (f : γ → β → γ) (init : γ) (it : Iter β) : γ | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___Iter___fold) |
| def | Std.Iter.foldM | Std.Iter.foldM.{x, x', w} {m : Type x → Type x'} [Monad m] {α β : Type w} {γ : Type x} [Iterator α Id β] [IteratorLoop α Id m] (f : γ → β → m γ) (init : γ) (it  … | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___Iter___foldM) |
| def | Std.Iter.length | Std.Iter.length.{w} {α β : Type w} [Iterator α Id β] [IteratorLoop α Id Id] (it : Iter β) : Nat | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___Iter___length) |
| def | Std.Iter.any | Std.Iter.any.{w} {α β : Type w} [Iterator α Id β] [IteratorLoop α Id Id] (p : β → Bool) (it : Iter β) : Bool | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___Iter___any) |
| def | Std.Iter.anyM | Std.Iter.anyM.{w, w'} {α β : Type w} {m : Type → Type w'} [Monad m] [Iterator α Id β] [IteratorLoop α Id m] (p : β → m Bool) (it : Iter β) : m Bool | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___Iter___anyM) |
| def | Std.Iter.all | Std.Iter.all.{w} {α β : Type w} [Iterator α Id β] [IteratorLoop α Id Id] (p : β → Bool) (it : Iter β) : Bool | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___Iter___all) |
| def | Std.Iter.allM | Std.Iter.allM.{w, w'} {α β : Type w} {m : Type → Type w'} [Monad m] [Iterator α Id β] [IteratorLoop α Id m] (p : β → m Bool) (it : Iter β) : m Bool | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___Iter___allM) |
| def | Std.Iter.find? | Std.Iter.find?.{w} {α β : Type w} [Iterator α Id β] [IteratorLoop α Id Id] (it : Iter β) (f : β → Bool) : Option β | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___Iter___find___) |
| def | Std.Iter.findM? | Std.Iter.findM?.{w, w'} {α β : Type w} {m : Type w → Type w'} [Monad m] [Iterator α Id β] [IteratorLoop α Id m] (it : Iter β) (f : β → m (ULift Bool)) : m (Opti … | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___Iter___findM___) |
| def | Std.Iter.findSome? | Std.Iter.findSome?.{w, x} {α β : Type w} {γ : Type x} [Iterator α Id β] [IteratorLoop α Id Id] (it : Iter β) (f : β → Option γ) : Option γ | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___Iter___findSome___) |
| def | Std.Iter.findSomeM? | Std.Iter.findSomeM?.{w, x, w'} {α β : Type w} {γ : Type x} {m : Type x → Type w'} [Monad m] [Iterator α Id β] [IteratorLoop α Id m] (it : Iter β) (f : β → m (Op … | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___Iter___findSomeM___) |
| def | Std.Iter.atIdx? | Std.Iter.atIdx?.{u_1} {α β : Type u_1} [Iterator α Id β] [IteratorAccess α Id] (n : Nat) (it : Iter β) : Option β | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___Iter___atIdx___) |
| def | Std.Iter.atIdxSlow? | Std.Iter.atIdxSlow?.{u_1} {α β : Type u_1} [Iterator α Id β] (n : Nat) (it : Iter β) : Option β | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___Iter___atIdxSlow___) |
| def | Std.IterM.drain | Std.IterM.drain.{w, w'} {α : Type w} {m : Type w → Type w'} [Monad m] {β : Type w} [Iterator α m β] (it : IterM m β) [IteratorLoop α m m] : m PUnit | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___drain) |
| def | Std.IterM.fold | Std.IterM.fold.{w, w'} {m : Type w → Type w'} {α β γ : Type w} [Monad m] [Iterator α m β] [IteratorLoop α m m] (f : γ → β → γ) (init : γ) (it : IterM m β) : m γ … | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___fold) |
| def | Std.IterM.foldM | Std.IterM.foldM.{w, w', w''} {m : Type w → Type w'} {n : Type w → Type w''} [Monad n] {α β γ : Type w} [Iterator α m β] [IteratorLoop α m n] [MonadLiftT m n] (f … | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___foldM) |
| def | Std.IterM.length | Std.IterM.length.{w, w'} {α : Type w} {m : Type w → Type w'} {β : Type w} [Iterator α m β] [IteratorLoop α m m] [Monad m] (it : IterM m β) : m (ULift Nat) | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___length) |
| def | Std.IterM.any | Std.IterM.any.{w, w'} {α β : Type w} {m : Type w → Type w'} [Monad m] [Iterator α m β] [IteratorLoop α m m] (p : β → Bool) (it : IterM m β) : m (ULift Bool) | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___any) |
| def | Std.IterM.anyM | Std.IterM.anyM.{w, w'} {α β : Type w} {m : Type w → Type w'} [Monad m] [Iterator α m β] [IteratorLoop α m m] (p : β → m (ULift Bool)) (it : IterM m β) : m (ULif … | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___anyM) |
| def | Std.IterM.all | Std.IterM.all.{w, w'} {α β : Type w} {m : Type w → Type w'} [Monad m] [Iterator α m β] [IteratorLoop α m m] (p : β → Bool) (it : IterM m β) : m (ULift Bool) | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___all) |
| def | Std.IterM.allM | Std.IterM.allM.{w, w'} {α β : Type w} {m : Type w → Type w'} [Monad m] [Iterator α m β] [IteratorLoop α m m] (p : β → m (ULift Bool)) (it : IterM m β) : m (ULif … | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___allM) |
| def | Std.IterM.find? | Std.IterM.find?.{w, w'} {α β : Type w} {m : Type w → Type w'} [Monad m] [Iterator α m β] [IteratorLoop α m m] (it : IterM m β) (f : β → Bool) : m (Option β) | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___find___) |
| def | Std.IterM.findM? | Std.IterM.findM?.{w, w'} {α β : Type w} {m : Type w → Type w'} [Monad m] [Iterator α m β] [IteratorLoop α m m] (it : IterM m β) (f : β → m (ULift Bool)) : m (Op … | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___findM___) |
| def | Std.IterM.findSome? | Std.IterM.findSome?.{w, w'} {α β γ : Type w} {m : Type w → Type w'} [Monad m] [Iterator α m β] [IteratorLoop α m m] (it : IterM m β) (f : β → Option γ) : m (Opt … | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___findSome___) |
| def | Std.IterM.findSomeM? | Std.IterM.findSomeM?.{w, w'} {α β γ : Type w} {m : Type w → Type w'} [Monad m] [Iterator α m β] [IteratorLoop α m m] (it : IterM m β) (f : β → m (Option γ)) : m … | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___findSomeM___) |
| def | Std.IterM.atIdx? | Std.IterM.atIdx?.{u_1, u_2} {α : Type u_1} {m : Type u_1 → Type u_2} {β : Type u_1} [Iterator α m β] [IteratorAccess α m] [Monad m] (it : IterM m β) (n : Nat) : … | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___atIdx___) |
| def | Std.Iter.toArray | Std.Iter.toArray.{w} {α β : Type w} [Iterator α Id β] (it : Iter β) : Array β | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___Iter___toArray) |
| def | Std.IterM.toArray | Std.IterM.toArray.{w, w'} {α β : Type w} {m : Type w → Type w'} [Monad m] [Iterator α m β] (it : IterM m β) : m (Array β) | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___toArray) |
| def | Std.Iter.toList | Std.Iter.toList.{w} {α β : Type w} [Iterator α Id β] (it : Iter β) : List β | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___Iter___toList) |
| def | Std.IterM.toList | Std.IterM.toList.{w, w'} {α : Type w} {m : Type w → Type w'} [Monad m] {β : Type w} [Iterator α m β] (it : IterM m β) : m (List β) | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___toList) |
| def | Std.Iter.toListRev | Std.Iter.toListRev.{w} {α β : Type w} [Iterator α Id β] (it : Iter β) : List β | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___Iter___toListRev) |
| def | Std.IterM.toListRev | Std.IterM.toListRev.{w, w'} {α : Type w} {m : Type w → Type w'} [Monad m] {β : Type w} [Iterator α m β] (it : IterM m β) : m (List β) | [Reference](pages/Iterators/Consuming-Iterators/index.md#Std___IterM___toListRev) |
| constructor of Std.IterM | Std.IterM.mk | Std.IterM.mk.{w, w'} {α : Type w} {m : Type w → Type w'} {β : Type w} (internalState : α) : IterM m β | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___mk-next) |
| def | Std.Iter.toIterM | Std.Iter.toIterM.{w} {α β : Type w} (it : Iter β) : IterM Id β | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___toIterM) |
| def | Std.Iter.take | Std.Iter.take.{w} {α β : Type w} [Iterator α Id β] (n : Nat) (it : Iter β) : Iter β | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___take) |
| def | Std.Iter.takeWhile | Std.Iter.takeWhile.{w} {α β : Type w} (P : β → Bool) (it : Iter β) : Iter β | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___takeWhile) |
| def | Std.Iter.toTake | Std.Iter.toTake.{w} {α β : Type w} [Iterator α Id β] [Finite α Id] (it : Iter β) : Iter β | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___toTake) |
| def | Std.Iter.drop | Std.Iter.drop.{w} {α β : Type w} (n : Nat) (it : Iter β) : Iter β | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___drop) |
| def | Std.Iter.dropWhile | Std.Iter.dropWhile.{w} {α β : Type w} (P : β → Bool) (it : Iter β) : Iter β | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___dropWhile) |
| def | Std.Iter.stepSize | Std.Iter.stepSize.{u_1} {α β : Type u_1} [Iterator α Id β] [IteratorAccess α Id] (it : Iter β) (n : Nat) : Iter β | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___stepSize) |
| def | Std.Iter.map | Std.Iter.map.{w} {α β γ : Type w} [Iterator α Id β] (f : β → γ) (it : Iter β) : Iter γ | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___map) |
| def | Std.Iter.mapM | Std.Iter.mapM.{w, w'} {α β γ : Type w} [Iterator α Id β] {m : Type w → Type w'} [Monad m] [MonadAttach m] (f : β → m γ) (it : Iter β) : IterM m γ | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___mapM) |
| def | Std.Iter.mapWithPostcondition | Std.Iter.mapWithPostcondition.{w, w'} {α β γ : Type w} [Iterator α Id β] {m : Type w → Type w'} [Monad m] (f : β → PostconditionT m γ) (it : Iter β) : IterM m γ … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___mapWithPostcondition) |
| def | Std.Iter.uLift | Std.Iter.uLift.{v, u} {α β : Type u} (it : Iter β) : Iter (ULift β) | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___uLift) |
| def | Std.Iter.flatMap | Std.Iter.flatMap.{w} {α β α₂ γ : Type w} [Iterator α Id β] [Iterator α₂ Id γ] (f : β → Iter γ) (it : Iter β) : Iter γ | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___flatMap) |
| def | Std.Iter.flatMapM | Std.Iter.flatMapM.{w, w'} {α β α₂ γ : Type w} {m : Type w → Type w'} [Monad m] [MonadAttach m] [Iterator α Id β] [Iterator α₂ m γ] (f : β → m (IterM m γ)) (it : … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___flatMapM) |
| def | Std.Iter.flatMapAfter | Std.Iter.flatMapAfter.{w} {α β α₂ γ : Type w} [Iterator α Id β] [Iterator α₂ Id γ] (f : β → Iter γ) (it₁ : Iter β) (it₂ : Option (Iter γ)) : Iter γ | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___flatMapAfter) |
| def | Std.Iter.flatMapAfterM | Std.Iter.flatMapAfterM.{w, w'} {α β α₂ γ : Type w} {m : Type w → Type w'} [Monad m] [MonadAttach m] [Iterator α Id β] [Iterator α₂ m γ] (f : β → m (IterM m γ))  … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___flatMapAfterM) |
| def | Std.Iter.filter | Std.Iter.filter.{w} {α β : Type w} [Iterator α Id β] (f : β → Bool) (it : Iter β) : Iter β | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___filter) |
| def | Std.Iter.filterM | Std.Iter.filterM.{w, w'} {α β : Type w} [Iterator α Id β] {m : Type w → Type w'} [Monad m] [MonadAttach m] (f : β → m (ULift Bool)) (it : Iter β) : IterM m β … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___filterM) |
| def | Std.Iter.filterWithPostcondition | Std.Iter.filterWithPostcondition.{w, w'} {α β : Type w} [Iterator α Id β] {m : Type w → Type w'} [Monad m] (f : β → PostconditionT m (ULift Bool)) (it : Iter β) … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___filterWithPostcondition) |
| def | Std.Iter.filterMap | Std.Iter.filterMap.{w} {α β γ : Type w} [Iterator α Id β] (f : β → Option γ) (it : Iter β) : Iter γ | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___filterMap) |
| def | Std.Iter.filterMapM | Std.Iter.filterMapM.{w, w'} {α β γ : Type w} [Iterator α Id β] {m : Type w → Type w'} [Monad m] [MonadAttach m] (f : β → m (Option γ)) (it : Iter β) : IterM m γ … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___filterMapM) |
| def | Std.Iter.filterMapWithPostcondition | Std.Iter.filterMapWithPostcondition.{w, w'} {α β γ : Type w} [Iterator α Id β] {m : Type w → Type w'} [Monad m] (f : β → PostconditionT m (Option γ)) (it : Iter … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___filterMapWithPostcondition) |
| def | Std.Iterator | Std.Iter.zip.{w} {α₁ β₁ α₂ β₂ : Type w} [Iterator α₁ Id β₁] [Iterator α₂ Id β₂] (left : Iter β₁) (right : Iter β₂) : Iter (β₁ × β₂) | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___zip) |
| def | Std.Iter.attachWith | Std.Iter.attachWith.{w} {α β : Type w} [Iterator α Id β] (it : Iter β) (P : β → Prop) (h : ∀ (out : β), it.IsPlausibleIndirectOutput out → P out) : Iter { out / … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___Iter___attachWith) |
| def | Std.IterM.toIter | Std.IterM.toIter.{w} {α β : Type w} (it : IterM Id β) : Iter β | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___toIter) |
| def | Std.IterM.take | Std.IterM.take.{w, w'} {α : Type w} {m : Type w → Type w'} {β : Type w} [Iterator α m β] (n : Nat) (it : IterM m β) : IterM m β | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___take) |
| def | Std.IterM.takeWhile | Std.IterM.takeWhile.{w, w'} {α : Type w} {m : Type w → Type w'} {β : Type w} [Monad m] (P : β → Bool) (it : IterM m β) : IterM m β | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___takeWhile) |
| def | Std.IterM.takeWhileM | Std.IterM.takeWhileM.{w, w'} {α : Type w} {m : Type w → Type w'} {β : Type w} [Monad m] [MonadAttach m] (P : β → m (ULift Bool)) (it : IterM m β) : IterM m β … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___takeWhileM) |
| def | Std.IterM.takeWhileWithPostcondition | Std.IterM.takeWhileWithPostcondition.{w, w'} {α : Type w} {m : Type w → Type w'} {β : Type w} (P : β → PostconditionT m (ULift Bool)) (it : IterM m β) : IterM m … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___takeWhileWithPostcondition) |
| def | Std.IterM.toTake | Std.IterM.toTake.{w, w'} {α : Type w} {m : Type w → Type w'} {β : Type w} [Iterator α m β] [Finite α m] (it : IterM m β) : IterM m β | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___toTake) |
| def | Std.IterM.drop | Std.IterM.drop.{w, w'} {α : Type w} {m : Type w → Type w'} {β : Type w} (n : Nat) (it : IterM m β) : IterM m β | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___drop) |
| def | Std.IterM.dropWhile | Std.IterM.dropWhile.{w, w'} {α : Type w} {m : Type w → Type w'} {β : Type w} [Monad m] (P : β → Bool) (it : IterM m β) : IterM m β | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___dropWhile) |
| def | Std.IterM.dropWhileM | Std.IterM.dropWhileM.{w, w'} {α : Type w} {m : Type w → Type w'} {β : Type w} [Monad m] [MonadAttach m] (P : β → m (ULift Bool)) (it : IterM m β) : IterM m β … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___dropWhileM) |
| def | Std.IterM.dropWhileWithPostcondition | Std.IterM.dropWhileWithPostcondition.{w, w'} {α : Type w} {m : Type w → Type w'} {β : Type w} (P : β → PostconditionT m (ULift Bool)) (it : IterM m β) : IterM m … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___dropWhileWithPostcondition) |
| def | Std.IterM.stepSize | Std.IterM.stepSize.{u_1, u_2} {α : Type u_1} {m : Type u_1 → Type u_2} {β : Type u_1} [Iterator α m β] [IteratorAccess α m] [Monad m] (it : IterM m β) (n : Nat) … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___stepSize) |
| def | Std.IterM.map | Std.IterM.map.{w, w'} {α β γ : Type w} {m : Type w → Type w'} [Iterator α m β] [Monad m] (f : β → γ) (it : IterM m β) : IterM m γ | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___map) |
| def | Std.IterM.mapM | Std.IterM.mapM.{w, w', w''} {α β γ : Type w} {m : Type w → Type w'} {n : Type w → Type w''} [Iterator α m β] [Monad n] [MonadAttach n] [MonadLiftT m n] (f : β → … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___mapM) |
| def | Std.IterM.mapWithPostcondition | Std.IterM.mapWithPostcondition.{w, w', w''} {α β γ : Type w} {m : Type w → Type w'} {n : Type w → Type w''} [Monad n] [MonadLiftT m n] [Iterator α m β] (f : β → … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___mapWithPostcondition) |
| def | Std.IterM.uLift | Std.IterM.uLift.{v, u, v', u'} {α β : Type u} {m : Type u → Type u'} (it : IterM m β) (n : Type (max u v) → Type v') [lift : MonadLiftT m (ULiftT n)] : IterM n  … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___uLift) |
| def | Std.IterM.flatMap | Std.IterM.flatMap.{w, w'} {α β α₂ γ : Type w} {m : Type w → Type w'} [Monad m] [Iterator α m β] [Iterator α₂ m γ] (f : β → IterM m γ) (it : IterM m β) : IterM m … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___flatMap) |
| def | Std.IterM.flatMapM | Std.IterM.flatMapM.{w, w'} {α β α₂ γ : Type w} {m : Type w → Type w'} [Monad m] [MonadAttach m] [Iterator α m β] [Iterator α₂ m γ] (f : β → m (IterM m γ)) (it : … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___flatMapM) |
| def | Std.IterM.flatMapAfter | Std.IterM.flatMapAfter.{w, w'} {α β α₂ γ : Type w} {m : Type w → Type w'} [Monad m] [Iterator α m β] [Iterator α₂ m γ] (f : β → IterM m γ) (it₁ : IterM m β) (it … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___flatMapAfter) |
| def | Std.IterM.flatMapAfterM | Std.IterM.flatMapAfterM.{w, w'} {α β α₂ γ : Type w} {m : Type w → Type w'} [Monad m] [MonadAttach m] [Iterator α m β] [Iterator α₂ m γ] (f : β → m (IterM m γ))  … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___flatMapAfterM) |
| def | Std.IterM.filter | Std.IterM.filter.{w, w'} {α β : Type w} {m : Type w → Type w'} [Iterator α m β] [Monad m] (f : β → Bool) (it : IterM m β) : IterM m β | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___filter) |
| def | Std.IterM.filterM | Std.IterM.filterM.{w, w', w''} {α β : Type w} {m : Type w → Type w'} {n : Type w → Type w''} [Iterator α m β] [Monad n] [MonadAttach n] [MonadLiftT m n] (f : β  … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___filterM) |
| def | Std.IterM.filterWithPostcondition | Std.IterM.filterWithPostcondition.{w, w', w''} {α β : Type w} {m : Type w → Type w'} {n : Type w → Type w''} [Monad n] [MonadLiftT m n] [Iterator α m β] (f : β  … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___filterWithPostcondition) |
| def | Std.IterM.filterMap | Std.IterM.filterMap.{w, w'} {α β γ : Type w} {m : Type w → Type w'} [Iterator α m β] [Monad m] (f : β → Option γ) (it : IterM m β) : IterM m γ | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___filterMap) |
| def | Std.IterM.filterMapM | Std.IterM.filterMapM.{w, w', w''} {α β γ : Type w} {m : Type w → Type w'} {n : Type w → Type w''} [Iterator α m β] [Monad n] [MonadAttach n] [MonadLiftT m n] (f … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___filterMapM) |
| def | Std.IterM.filterMapWithPostcondition | Std.IterM.filterMapWithPostcondition.{w, w', w''} {α β γ : Type w} {m : Type w → Type w'} {n : Type w → Type w''} [MonadLiftT m n] [Iterator α m β] (f : β → Pos … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___filterMapWithPostcondition) |
| def | Std.Iterator | Std.IterM.zip.{w, w'} {m : Type w → Type w'} {α₁ β₁ : Type w} [Iterator α₁ m β₁] {α₂ β₂ : Type w} (left : IterM m β₁) (right : IterM m β₂) : IterM m (β₁ × β₂) … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___zip) |
| def | Std.IterM.attachWith | Std.IterM.attachWith.{w, w'} {α β : Type w} {m : Type w → Type w'} [Monad m] [Iterator α m β] (it : IterM m β) (P : β → Prop) (h : ∀ (out : β), it.IsPlausibleIn … | [Reference](pages/Iterators/Iterator-Combinators/index.md#Std___IterM___attachWith) |
| def | Std.Iter.inductSkips | Std.Iter.inductSkips.{x, u_1} {α β : Type u_1} [Iterator α Id β] [Productive α Id] (motive : Iter β → Sort x) (step : (it : Iter β) → ({it' : Iter β} → it.IsPla … | [Reference](pages/Iterators/Reasoning-About-Iterators/index.md#Std___Iter___inductSkips) |
| def | Std.IterM.inductSkips | Std.IterM.inductSkips.{x, u_1, u_2} {α : Type u_1} {m : Type u_1 → Type u_2} {β : Type u_1} [Iterator α m β] [Productive α m] (motive : IterM m β → Sort x) (ste … | [Reference](pages/Iterators/Reasoning-About-Iterators/index.md#Std___IterM___inductSkips) |
| def | Std.Iter.inductSteps | Std.Iter.inductSteps.{x, u_1} {α β : Type u_1} [Iterator α Id β] [Finite α Id] (motive : Iter β → Sort x) (step : (it : Iter β) → ({it' : Iter β} → {out : β} →  … | [Reference](pages/Iterators/Reasoning-About-Iterators/index.md#Std___Iter___inductSteps) |
| def | Std.IterM.inductSteps | Std.IterM.inductSteps.{x, u_1, u_2} {α : Type u_1} {m : Type u_1 → Type u_2} {β : Type u_1} [Iterator α m β] [Finite α m] (motive : IterM m β → Sort x) (step :  … | [Reference](pages/Iterators/Reasoning-About-Iterators/index.md#Std___IterM___inductSteps) |
| structure | Std.Iterators.PostconditionT | Std.Iterators.PostconditionT.{w, w'} (m : Type w → Type w') (α : Type w) : Type (max w w') | [Reference](pages/Iterators/Reasoning-About-Iterators/index.md#Std___Iterators___PostconditionT___mk) |
| def | Std.Iterators.PostconditionT.run | Std.Iterators.PostconditionT.run.{w, w'} {m : Type w → Type w'} [Monad m] {α : Type w} (x : PostconditionT m α) : m α | [Reference](pages/Iterators/Reasoning-About-Iterators/index.md#Std___Iterators___PostconditionT___run) |
| def | Std.Iterators.PostconditionT.lift | Std.Iterators.PostconditionT.lift.{w, w'} {α : Type w} {m : Type w → Type w'} [Functor m] (x : m α) : PostconditionT m α | [Reference](pages/Iterators/Reasoning-About-Iterators/index.md#Std___Iterators___PostconditionT___lift) |
| def | Std.Iterators.PostconditionT.liftWithProperty | Std.Iterators.PostconditionT.liftWithProperty.{w, w'} {α : Type w} {m : Type w → Type w'} {P : α → Prop} (x : m { α // P α }) : PostconditionT m α | [Reference](pages/Iterators/Reasoning-About-Iterators/index.md#Std___Iterators___PostconditionT___liftWithProperty) |
| inductive predicate | Std.Iter.IsPlausibleIndirectOutput | Std.Iter.IsPlausibleIndirectOutput.{w} {α β : Type w} [Iterator α Id β] : Iter β → β → Prop | [Reference](pages/Iterators/Reasoning-About-Iterators/index.md#Std___Iter___IsPlausibleIndirectOutput___direct) |
| structure | Std.Iterators.HetT | Std.Iterators.HetT.{w, w', v} (m : Type w → Type w') (α : Type v) : Type (max v w') | [Reference](pages/Iterators/Reasoning-About-Iterators/index.md#Std___Iterators___HetT___mk) |
| def | Std.IterM.stepAsHetT | Std.IterM.stepAsHetT.{u_1, u_2} {α : Type u_1} {m : Type u_1 → Type u_2} {β : Type u_1} [Iterator α m β] [Monad m] (it : IterM m β) : HetT m (IterStep (IterM m  … | [Reference](pages/Iterators/Reasoning-About-Iterators/index.md#Std___IterM___stepAsHetT) |
| def | Std.Iterators.HetT.lift | Std.Iterators.HetT.lift.{w, w'} {α : Type w} {m : Type w → Type w'} [Monad m] (x : m α) : HetT m α | [Reference](pages/Iterators/Reasoning-About-Iterators/index.md#Std___Iterators___HetT___lift) |
| def | Std.Iterators.HetT.prun | Std.Iterators.HetT.prun.{u_1, u_2, u_3} {m : Type u_1 → Type u_2} {α : Type u_3} {β : Type u_1} [Monad m] (x : HetT m α) (f : (a : α) → x.Property a → m β) : m  … | [Reference](pages/Iterators/Reasoning-About-Iterators/index.md#Std___Iterators___HetT___prun) |
| def | Std.Iterators.HetT.pure | Std.Iterators.HetT.pure.{w, w', v} {m : Type w → Type w'} [Pure m] {α : Type v} (a : α) : HetT m α | [Reference](pages/Iterators/Reasoning-About-Iterators/index.md#Std___Iterators___HetT___pure) |
| def | Std.Iterators.HetT.map | Std.Iterators.HetT.map.{w, w', u, v} {m : Type w → Type w'} [Functor m] {α : Type u} {β : Type v} (f : α → β) (x : HetT m α) : HetT m β | [Reference](pages/Iterators/Reasoning-About-Iterators/index.md#Std___Iterators___HetT___map) |
| def | Std.Iterators.HetT.pmap | Std.Iterators.HetT.pmap.{w, w', u, v} {m : Type w → Type w'} [Functor m] {α : Type u} {β : Type v} (x : HetT m α) (f : (a : α) → x.Property a → β) : HetT m β … | [Reference](pages/Iterators/Reasoning-About-Iterators/index.md#Std___Iterators___HetT___pmap) |
| def | Std.Iterators.HetT.bind | Std.Iterators.HetT.bind.{w, w', u, v} {m : Type w → Type w'} [Monad m] {α : Type u} {β : Type v} (x : HetT m α) (f : α → HetT m β) : HetT m β | [Reference](pages/Iterators/Reasoning-About-Iterators/index.md#Std___Iterators___HetT___bind) |
| def | Std.Iterators.HetT.pbind | Std.Iterators.HetT.pbind.{w, w', u, v} {m : Type w → Type w'} [Monad m] {α : Type u} {β : Type v} (x : HetT m α) (f : (a : α) → x.Property a → HetT m β) : HetT  … | [Reference](pages/Iterators/Reasoning-About-Iterators/index.md#Std___Iterators___HetT___pbind) |
| def | Std.Iter.Equiv | Std.Iter.Equiv.{u_1} {α₁ α₂ β : Type u_1} [Iterator α₁ Id β] [Iterator α₂ Id β] (ita : Iter β) (itb : Iter β) : Prop | [Reference](pages/Iterators/Reasoning-About-Iterators/index.md#Std___Iter___Equiv) |
| def | Std.IterM.Equiv | Std.IterM.Equiv.{w, w'} {m : Type w → Type w'} [Monad m] [LawfulMonad m] {β α₁ α₂ : Type w} [Iterator α₁ m β] [Iterator α₂ m β] (ita : IterM m β) (itb : IterM m … | [Reference](pages/Iterators/Reasoning-About-Iterators/index.md#Std___IterM___Equiv) |
| syntax | Operator Declarations |  | [Reference](pages/Notations-and-Macros/Custom-Operators/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Parser Precedences |  | [Reference](pages/Notations-and-Macros/Precedence/index.md#prec) |
| syntax | Notation Declarations |  | [Reference](pages/Notations-and-Macros/Notations/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Notation Items |  | [Reference](pages/Notations-and-Macros/Notations/index.md#Lean___Parser___Command___notationItem) |
| inductive type | Lean.Syntax | Lean.Syntax : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___missing) |
| inductive type | Lean.Syntax.Preresolved | Lean.Syntax.Preresolved : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___Preresolved___namespace) |
| def | Lean.SyntaxNodeKind | Lean.SyntaxNodeKind : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___SyntaxNodeKind) |
| def | Lean.Syntax.isOfKind | Lean.Syntax.isOfKind (stx : Lean.Syntax) (k : Lean.SyntaxNodeKind) : Bool | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___isOfKind) |
| def | Lean.Syntax.getKind | Lean.Syntax.getKind (stx : Lean.Syntax) : Lean.SyntaxNodeKind | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___getKind) |
| def | Lean.Syntax.setKind | Lean.Syntax.setKind (stx : Lean.Syntax) (k : Lean.SyntaxNodeKind) : Lean.Syntax | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___setKind) |
| def | Lean.identKind | Lean.identKind : Lean.SyntaxNodeKind | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___identKind) |
| def | Lean.strLitKind | Lean.strLitKind : Lean.SyntaxNodeKind | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___strLitKind) |
| def | Lean.interpolatedStrKind | Lean.interpolatedStrKind : Lean.SyntaxNodeKind | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___interpolatedStrKind) |
| def | Lean.interpolatedStrLitKind | Lean.interpolatedStrLitKind : Lean.SyntaxNodeKind | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___interpolatedStrLitKind) |
| def | Lean.charLitKind | Lean.charLitKind : Lean.SyntaxNodeKind | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___charLitKind) |
| def | Lean.numLitKind | Lean.numLitKind : Lean.SyntaxNodeKind | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___numLitKind) |
| def | Lean.scientificLitKind | Lean.scientificLitKind : Lean.SyntaxNodeKind | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___scientificLitKind) |
| def | Lean.nameLitKind | Lean.nameLitKind : Lean.SyntaxNodeKind | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___nameLitKind) |
| def | Lean.fieldIdxKind | Lean.fieldIdxKind : Lean.SyntaxNodeKind | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___fieldIdxKind) |
| def | Lean.groupKind | Lean.groupKind : Lean.SyntaxNodeKind | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___groupKind) |
| def | Lean.nullKind | Lean.nullKind : Lean.SyntaxNodeKind | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___nullKind) |
| def | Lean.choiceKind | Lean.choiceKind : Lean.SyntaxNodeKind | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___choiceKind) |
| def | Lean.hygieneInfoKind | Lean.hygieneInfoKind : Lean.SyntaxNodeKind | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___hygieneInfoKind) |
| inductive type | Lean.SourceInfo | Lean.SourceInfo : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___SourceInfo___original) |
| structure | Lean.TSyntax | Lean.TSyntax (ks : Lean.SyntaxNodeKinds) : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___TSyntax___mk) |
| def | Lean.SyntaxNodeKinds | Lean.SyntaxNodeKinds : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___SyntaxNodeKinds) |
| def | Lean.TSyntaxArray | Lean.TSyntaxArray (ks : Lean.SyntaxNodeKinds) : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___TSyntaxArray) |
| opaque | Lean.TSyntaxArray.raw | Lean.TSyntaxArray.raw {ks : Lean.SyntaxNodeKinds} (as : Lean.TSyntaxArray ks) : Array Lean.Syntax | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___TSyntaxArray___raw) |
| structure | Lean.Syntax.TSepArray | Lean.Syntax.TSepArray (ks : Lean.SyntaxNodeKinds) (sep : String) : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___TSepArray___mk) |
| def | Lean.Syntax.TSepArray.getElems | Lean.Syntax.TSepArray.getElems {k : Lean.SyntaxNodeKinds} {sep : String} (sa : Lean.Syntax.TSepArray k sep) : Lean.TSyntaxArray k | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___TSepArray___getElems) |
| def | Lean.Syntax.TSepArray.elemsAndSeps | Lean.Syntax.TSepArray.elemsAndSeps {ks : Lean.SyntaxNodeKinds} {sep : String} (self : Lean.Syntax.TSepArray ks sep) : Array Lean.Syntax | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___TSepArray___elemsAndSeps) |
| def | Lean.Syntax.TSepArray.ofElems | Lean.Syntax.TSepArray.ofElems {k : Lean.SyntaxNodeKinds} {sep : String} (elems : Array (Lean.TSyntax k)) : Lean.Syntax.TSepArray k sep | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___TSepArray___ofElems) |
| def | Lean.Syntax.TSepArray.push | Lean.Syntax.TSepArray.push {k : Lean.SyntaxNodeKinds} {sep : String} (sa : Lean.Syntax.TSepArray k sep) (e : Lean.TSyntax k) : Lean.Syntax.TSepArray k sep | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___TSepArray___push) |
| def | Lean.Syntax.Term | Lean.Syntax.Term : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___Term) |
| def | Lean.Syntax.Command | Lean.Syntax.Command : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___Command) |
| def | Lean.Syntax.Level | Lean.Syntax.Level : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___Level) |
| def | Lean.Syntax.Tactic | Lean.Syntax.Tactic : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___Tactic) |
| def | Lean.Syntax.Prec | Lean.Syntax.Prec : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___Prec) |
| def | Lean.Syntax.Prio | Lean.Syntax.Prio : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___Prio) |
| def | Lean.Syntax.Ident | Lean.Syntax.Ident : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___Ident) |
| def | Lean.Syntax.StrLit | Lean.Syntax.StrLit : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___StrLit) |
| def | Lean.Syntax.CharLit | Lean.Syntax.CharLit : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___CharLit) |
| def | Lean.Syntax.NameLit | Lean.Syntax.NameLit : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___NameLit) |
| def | Lean.Syntax.NumLit | Lean.Syntax.NumLit : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___NumLit) |
| def | Lean.Syntax.ScientificLit | Lean.Syntax.ScientificLit : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___ScientificLit) |
| def | Lean.Syntax.HygieneInfo | Lean.Syntax.HygieneInfo : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___HygieneInfo) |
| def | Lean.mkIdent | Lean.mkIdent (val : Lean.Name) : Lean.Ident | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___mkIdent) |
| def | Lean.mkIdentFrom | Lean.mkIdentFrom (src : Lean.Syntax) (val : Lean.Name) (canonical : Bool := false) : Lean.Ident | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___mkIdentFrom) |
| def | Lean.mkIdentFromRef | Lean.mkIdentFromRef {m : Type → Type} [Monad m] [Lean.MonadRef m] (val : Lean.Name) (canonical : Bool := false) : m Lean.Ident | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___mkIdentFromRef) |
| def | Lean.mkCIdent | Lean.mkCIdent (c : Lean.Name) : Lean.Ident | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___mkCIdent) |
| def | Lean.mkCIdentFrom | Lean.mkCIdentFrom (src : Lean.Syntax) (c : Lean.Name) (canonical : Bool := false) : Lean.Ident | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___mkCIdentFrom) |
| def | Lean.mkCIdentFromRef | Lean.mkCIdentFromRef {m : Type → Type} [Monad m] [Lean.MonadRef m] (c : Lean.Name) (canonical : Bool := false) : m Lean.Syntax | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___mkCIdentFromRef) |
| def | Lean.Syntax.mkApp | Lean.Syntax.mkApp (fn : Lean.Term) (args : Lean.TSyntaxArray 'term) : Lean.Term | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___mkApp) |
| def | Lean.Syntax.mkCApp | Lean.Syntax.mkCApp (fn : Lean.Name) (args : Lean.TSyntaxArray 'term) : Lean.Term | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___mkCApp) |
| def | Lean.Syntax.mkLit | Lean.Syntax.mkLit (kind : Lean.SyntaxNodeKind) (val : String) (info : Lean.SourceInfo := Lean.SourceInfo.none) : Lean.TSyntax kind | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___mkLit) |
| def | Lean.Syntax.mkCharLit | Lean.Syntax.mkCharLit (val : Char) (info : Lean.SourceInfo := Lean.SourceInfo.none) : Lean.CharLit | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___mkCharLit) |
| def | Lean.Syntax.mkStrLit | Lean.Syntax.mkStrLit (val : String) (info : Lean.SourceInfo := Lean.SourceInfo.none) : Lean.StrLit | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___mkStrLit) |
| def | Lean.Syntax.mkNumLit | Lean.Syntax.mkNumLit (val : String) (info : Lean.SourceInfo := Lean.SourceInfo.none) : Lean.NumLit | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___mkNumLit) |
| def | Lean.Syntax.mkNatLit | Lean.Syntax.mkNatLit (val : Nat) (info : Lean.SourceInfo := Lean.SourceInfo.none) : Lean.NumLit | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___mkNatLit) |
| def | Lean.Syntax.mkScientificLit | Lean.Syntax.mkScientificLit (val : String) (info : Lean.SourceInfo := Lean.SourceInfo.none) : Lean.TSyntax Lean.scientificLitKind | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___mkScientificLit) |
| def | Lean.Syntax.mkNameLit | Lean.Syntax.mkNameLit (val : String) (info : Lean.SourceInfo := Lean.SourceInfo.none) : Lean.NameLit | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Syntax___mkNameLit) |
| def | Lean.mkOptionalNode | Lean.mkOptionalNode (arg : Option Lean.Syntax) : Lean.Syntax | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___mkOptionalNode) |
| def | Lean.mkGroupNode | Lean.mkGroupNode (args : Array Lean.Syntax := #[]) : Lean.Syntax | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___mkGroupNode) |
| def | Lean.mkHole | Lean.mkHole (ref : Lean.Syntax) (canonical : Bool := false) : Lean.Term | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___mkHole) |
| type class | Lean.Quote | Lean.Quote (α : Type) (k : Lean.SyntaxNodeKind := 'term) : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Quote___mk) |
| def | Lean.TSyntax.getId | Lean.TSyntax.getId (s : Lean.Ident) : Lean.Name | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___TSyntax___getId) |
| def | Lean.TSyntax.getName | Lean.TSyntax.getName (s : Lean.NameLit) : Lean.Name | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___TSyntax___getName) |
| def | Lean.TSyntax.getNat | Lean.TSyntax.getNat (s : Lean.NumLit) : Nat | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___TSyntax___getNat) |
| def | Lean.TSyntax.getScientific | Lean.TSyntax.getScientific (s : Lean.ScientificLit) : Nat × Bool × Nat | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___TSyntax___getScientific) |
| def | Lean.TSyntax.getString | Lean.TSyntax.getString (s : Lean.StrLit) : String | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___TSyntax___getString) |
| def | Lean.TSyntax.getChar | Lean.TSyntax.getChar (s : Lean.CharLit) : Char | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___TSyntax___getChar) |
| def | Lean.TSyntax.getHygieneInfo | Lean.TSyntax.getHygieneInfo (s : Lean.HygieneInfo) : Lean.Name | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___TSyntax___getHygieneInfo) |
| syntax | Declaring Syntactic Categories |  | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| inductive type | Lean.Parser.LeadingIdentBehavior | Lean.Parser.LeadingIdentBehavior : Type | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Parser___LeadingIdentBehavior___default) |
| syntax | Syntax Rules |  | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Syntax Specifiers |  | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#stx) |
| parser alias | withPosition | withPosition(p) | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#withPosition) |
| parser alias | withoutPosition | withoutPosition(p) | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#withoutPosition) |
| parser alias | withPositionAfterLinebreak | withPositionAfterLinebreak | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#withPositionAfterLinebreak) |
| parser alias | colGt | colGt | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#colGt) |
| parser alias | colGe | colGe | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#colGe) |
| parser alias | colEq | colEq | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#colEq) |
| parser alias | lineEq | lineEq | [Reference](pages/Notations-and-Macros/Defining-New-Syntax/index.md#lineEq) |
| def | Lean.MacroM | Lean.MacroM (α : Type) : Type | [Reference](pages/Notations-and-Macros/Macros/index.md#Lean___MacroM) |
| def | Lean.Macro.expandMacro? | Lean.Macro.expandMacro? (stx : Lean.Syntax) : Lean.MacroM (Option Lean.Syntax) | [Reference](pages/Notations-and-Macros/Macros/index.md#Lean___Macro___expandMacro___) |
| def | Lean.Macro.trace | Lean.Macro.trace (clsName : Lean.Name) (msg : String) : Lean.MacroM Unit | [Reference](pages/Notations-and-Macros/Macros/index.md#Lean___Macro___trace) |
| def | Lean.Macro.throwUnsupported | Lean.Macro.throwUnsupported {α : Type} : Lean.MacroM α | [Reference](pages/Notations-and-Macros/Macros/index.md#Lean___Macro___throwUnsupported) |
| constructor of Lean.Macro.Exception | Lean.Macro.Exception.unsupportedSyntax | Lean.Macro.Exception.unsupportedSyntax : Lean.Macro.Exception | [Reference](pages/Notations-and-Macros/Macros/index.md#Lean___Macro___Exception___unsupportedSyntax) |
| def | Lean.Macro.throwError | Lean.Macro.throwError {α : Type} (msg : String) : Lean.MacroM α | [Reference](pages/Notations-and-Macros/Macros/index.md#Lean___Macro___throwError) |
| def | Lean.Macro.throwErrorAt | Lean.Macro.throwErrorAt {α : Type} (ref : Lean.Syntax) (msg : String) : Lean.MacroM α | [Reference](pages/Notations-and-Macros/Macros/index.md#Lean___Macro___throwErrorAt) |
| def | Lean.Macro.withFreshMacroScope | Lean.Macro.withFreshMacroScope {α : Type} (x : Lean.MacroM α) : Lean.MacroM α | [Reference](pages/Notations-and-Macros/Macros/index.md#Lean___Macro___withFreshMacroScope) |
| def | Lean.Macro.addMacroScope | Lean.Macro.addMacroScope (n : Lean.Name) : Lean.MacroM Lean.Name | [Reference](pages/Notations-and-Macros/Macros/index.md#Lean___Macro___addMacroScope) |
| def | Lean.Macro.hasDecl | Lean.Macro.hasDecl (declName : Lean.Name) : Lean.MacroM Bool | [Reference](pages/Notations-and-Macros/Macros/index.md#Lean___Macro___hasDecl) |
| def | Lean.Macro.getCurrNamespace | Lean.Macro.getCurrNamespace : Lean.MacroM Lean.Name | [Reference](pages/Notations-and-Macros/Macros/index.md#Lean___Macro___getCurrNamespace) |
| def | Lean.Macro.resolveNamespace | Lean.Macro.resolveNamespace (n : Lean.Name) : Lean.MacroM (List Lean.Name) | [Reference](pages/Notations-and-Macros/Macros/index.md#Lean___Macro___resolveNamespace) |
| def | Lean.Macro.resolveGlobalName | Lean.Macro.resolveGlobalName (n : Lean.Name) : Lean.MacroM (List (Lean.Name × List String)) | [Reference](pages/Notations-and-Macros/Macros/index.md#Lean___Macro___resolveGlobalName) |
| syntax | Quotations |  | [Reference](pages/Notations-and-Macros/Macros/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Antiquotations |  | [Reference](pages/Notations-and-Macros/Macros/index.md#antiquot) |
| syntax | Token Antiquotations |  | [Reference](pages/Notations-and-Macros/Macros/index.md#antiquot-next) |
| syntax | Rule-Based Macros With macro_rules |  | [Reference](pages/Notations-and-Macros/Macros/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Macro Declarations |  | [Reference](pages/Notations-and-Macros/Macros/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Macro Arguments |  | [Reference](pages/Notations-and-Macros/Macros/index.md#Lean___Parser___Command___macroArg) |
| attribute | The macro Attribute |  | [Reference](pages/Notations-and-Macros/Macros/index.md#attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Elaboration Rules |  | [Reference](pages/Notations-and-Macros/Elaborators/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| attribute | Elaborator Attribute |  | [Reference](pages/Notations-and-Macros/Elaborators/index.md#attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| option | backward___do___legacy | backward.do.legacy | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#backward___do___legacy) |
| structure | Lean.Elab.Do.Context | Lean.Elab.Do.Context : Type | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___Context___mk) |
| structure | Lean.Elab.Do.MonadInfo | Lean.Elab.Do.MonadInfo : Type | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___MonadInfo___mk) |
| inductive type | Lean.Elab.Do.CodeLiveness | Lean.Elab.Do.CodeLiveness : Type | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___CodeLiveness___deadSyntactically) |
| opaque | Lean.Elab.Do.ContInfoRef.toContInfo | Lean.Elab.Do.ContInfoRef.toContInfo (m : Elab.Do.ContInfoRef) : Elab.Do.ContInfo | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___ContInfoRef___toContInfo) |
| structure | Lean.Elab.Do.ContInfo | Lean.Elab.Do.ContInfo : Type | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___ContInfo___mk) |
| opaque | Lean.Elab.Do.DoOpsRef.toDoOps | Lean.Elab.Do.DoOpsRef.toDoOps (r : Elab.Do.DoOpsRef) : Elab.Do.DoOps | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___DoOpsRef___toDoOps) |
| structure | Lean.Elab.Do.DoOps | Lean.Elab.Do.DoOps : Type | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___DoOps___mk) |
| def | Lean.Elab.Do.DoElab | Lean.Elab.Do.DoElab : Type | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___DoElab) |
| attribute | Do Element Elaborators |  | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| opaque | Lean.Elab.Do.elabDoElem | Lean.Elab.Do.elabDoElem (stx : DoElem) (cont : Elab.Do.DoElemCont) (catchExPostpone : Bool := true) : Elab.Do.DoElabM Expr | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___elabDoElem) |
| opaque | Lean.Elab.Do.elabDoSeq | Lean.Elab.Do.elabDoSeq (doSeq : DoSeq) (cont : Elab.Do.DoElemCont) (catchExPostpone : Bool := true) : Elab.Do.DoElabM Expr | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___elabDoSeq) |
| opaque | Lean.Elab.Do.elabDoElems1 | Lean.Elab.Do.elabDoElems1 (doElems : Array DoElem) (cont : Elab.Do.DoElemCont) (catchExPostpone : Bool := true) : Elab.Do.DoElabM Expr | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___elabDoElems1) |
| def | Lean.Elab.Do.mkMonadApp | Lean.Elab.Do.mkMonadApp (resultType : Expr) : Elab.Do.DoElabM Expr | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___mkMonadApp) |
| def | Lean.Elab.Do.mkPureApp | Lean.Elab.Do.mkPureApp (α e : Expr) : Elab.Do.DoElabM Expr | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___mkPureApp) |
| def | Lean.Elab.Do.mkBindApp | Lean.Elab.Do.mkBindApp (α β e k : Expr) : Elab.Do.DoElabM Expr | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___mkBindApp) |
| def | Lean.Elab.Do.mkPUnitUnit | Lean.Elab.Do.mkPUnitUnit : Elab.Do.DoElabM Expr | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___mkPUnitUnit) |
| structure | Lean.Elab.Do.DoElemCont | Lean.Elab.Do.DoElemCont : Type | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___DoElemCont___mk) |
| inductive type | Lean.Elab.Do.DoElemContKind | Lean.Elab.Do.DoElemContKind : Type | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___DoElemContKind___nonDuplicable) |
| def | Lean.Elab.Do.DoElemCont.ensureUnit | Lean.Elab.Do.DoElemCont.ensureUnit (dec : Elab.Do.DoElemCont) : Elab.Do.DoElabM Elab.Do.DoElemCont | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___DoElemCont___ensureUnit) |
| def | Lean.Elab.Do.DoElemCont.ensureUnitAt | Lean.Elab.Do.DoElemCont.ensureUnitAt (dec : Elab.Do.DoElemCont) (ref : Syntax) : Elab.Do.DoElabM Elab.Do.DoElemCont | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___DoElemCont___ensureUnitAt) |
| def | Lean.Elab.Do.DoElemCont.ensureHasTypeAt | Lean.Elab.Do.DoElemCont.ensureHasTypeAt (dec : Elab.Do.DoElemCont) (ref : Syntax) (elementType : Expr) : Elab.Do.DoElabM Elab.Do.DoElemCont | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___DoElemCont___ensureHasTypeAt) |
| def | Lean.Elab.Do.DoElemCont.continueWithUnit | Lean.Elab.Do.DoElemCont.continueWithUnit (dec : Elab.Do.DoElemCont) : Elab.Do.DoElabM Expr | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___DoElemCont___continueWithUnit) |
| def | Lean.Elab.Do.DoElemCont.elabAsSyntacticallyDeadCode | Lean.Elab.Do.DoElemCont.elabAsSyntacticallyDeadCode (dec : Elab.Do.DoElemCont) : Elab.Do.DoElabM Unit | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___DoElemCont___elabAsSyntacticallyDeadCode) |
| def | Lean.Elab.Do.DoElemCont.mkBindUnlessPure | Lean.Elab.Do.DoElemCont.mkBindUnlessPure (dec : Elab.Do.DoElemCont) (e : Expr) : Elab.Do.DoElabM Expr | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___DoElemCont___mkBindUnlessPure) |
| def | Lean.Elab.Do.DoElemCont.withDuplicableCont | Lean.Elab.Do.DoElemCont.withDuplicableCont (nondupDec : Elab.Do.DoElemCont) (callerInfo : Elab.Do.ControlInfo) (caller : Elab.Do.DoElemCont → Elab.Do.DoElabM Ex … | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___DoElemCont___withDuplicableCont) |
| def | Lean.Elab.Do.getReturnCont | Lean.Elab.Do.getReturnCont : Elab.Do.DoElabM Elab.Do.ReturnCont | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___getReturnCont) |
| def | Lean.Elab.Do.getBreakCont | Lean.Elab.Do.getBreakCont : Elab.Do.DoElabM (Option (Elab.Do.DoElabM Expr)) | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___getBreakCont) |
| def | Lean.Elab.Do.getContinueCont | Lean.Elab.Do.getContinueCont : Elab.Do.DoElabM (Option (Elab.Do.DoElabM Expr)) | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___getContinueCont) |
| def | Lean.Elab.Do.enterLoopBody | Lean.Elab.Do.enterLoopBody {α : Type} (breakCont continueCont : Elab.Do.DoElabM Expr) (returnCont : Elab.Do.ReturnCont) (body : Elab.Do.DoElabM α) : Elab.Do.DoE … | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___enterLoopBody) |
| attribute | Do Element Control Information |  | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Lean.Elab.Do.ControlInfoHandler | Lean.Elab.Do.ControlInfoHandler : Type | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___ControlInfoHandler) |
| structure | Lean.Elab.Do.ControlInfo | Lean.Elab.Do.ControlInfo : Type | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___ControlInfo___mk) |
| def | Lean.Elab.Do.ControlInfo.pure | Lean.Elab.Do.ControlInfo.pure : Elab.Do.ControlInfo | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___ControlInfo___pure) |
| def | Lean.Elab.Do.ControlInfo.empty | Lean.Elab.Do.ControlInfo.empty : Elab.Do.ControlInfo | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___ControlInfo___empty) |
| def | Lean.Elab.Do.ControlInfo.sequence | Lean.Elab.Do.ControlInfo.sequence (a b : Elab.Do.ControlInfo) : Elab.Do.ControlInfo | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___ControlInfo___sequence) |
| def | Lean.Elab.Do.ControlInfo.alternative | Lean.Elab.Do.ControlInfo.alternative (a b : Elab.Do.ControlInfo) : Elab.Do.ControlInfo | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___ControlInfo___alternative) |
| def | Lean.Elab.Do.inferControlInfoElem | Lean.Elab.Do.inferControlInfoElem (doElem : DoElem) : Elab.TermElabM Elab.Do.ControlInfo | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___inferControlInfoElem) |
| def | Lean.Elab.Do.inferControlInfoSeq | Lean.Elab.Do.inferControlInfoSeq (doSeq : DoSeq) : Elab.TermElabM Elab.Do.ControlInfo | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___inferControlInfoSeq) |
| opaque | Lean.Elab.Do.InferControlInfo.ofElem | Lean.Elab.Do.InferControlInfo.ofElem (stx : DoElem) : Elab.TermElabM Elab.Do.ControlInfo | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___InferControlInfo___ofElem) |
| opaque | Lean.Elab.Do.InferControlInfo.ofSeq | Lean.Elab.Do.InferControlInfo.ofSeq (stx : DoSeq) : Elab.TermElabM Elab.Do.ControlInfo | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___InferControlInfo___ofSeq) |
| opaque | Lean.Elab.Do.InferControlInfo.ofOptionSeq | Lean.Elab.Do.InferControlInfo.ofOptionSeq (stx? : Option DoSeq) : Elab.TermElabM Elab.Do.ControlInfo | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___InferControlInfo___ofOptionSeq) |
| opaque | Lean.Elab.Do.InferControlInfo.ofLetOrReassign | Lean.Elab.Do.InferControlInfo.ofLetOrReassign (reassigned : Array Ident) (rhs? : Option DoElem) (otherwise? body? : Option (TSyntax 'Lean.Parser.Term.doSeqInden … | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___InferControlInfo___ofLetOrReassign) |
| opaque | Lean.Elab.Do.InferControlInfo.ofLetOrReassignArrow | Lean.Elab.Do.InferControlInfo.ofLetOrReassignArrow (reassignment : Bool) (decl : TSyntax ['Lean.Parser.Term.doIdDecl, 'Lean.Parser.Term.doPatDecl]) : Elab.TermE … | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___InferControlInfo___ofLetOrReassignArrow) |
| structure | Lean.Elab.Do.MutVar | Lean.Elab.Do.MutVar : Type | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___MutVar___mk) |
| def | Lean.Elab.Do.declareMutVar | Lean.Elab.Do.declareMutVar {α : Type} (x : Ident) (k : Elab.Do.DoElabM α) : Elab.Do.DoElabM α | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___declareMutVar) |
| def | Lean.Elab.Do.declareMutVars | Lean.Elab.Do.declareMutVars {α : Type} (xs : Array Ident) (k : Elab.Do.DoElabM α) : Elab.Do.DoElabM α | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___declareMutVars) |
| def | Lean.Elab.Do.throwUnlessMutVarDeclared | Lean.Elab.Do.throwUnlessMutVarDeclared (x : Ident) : Elab.Do.DoElabM Unit | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___throwUnlessMutVarDeclared) |
| def | Lean.Elab.Do.throwUnlessMutVarsDeclared | Lean.Elab.Do.throwUnlessMutVarsDeclared (xs : Array Ident) : Elab.Do.DoElabM Unit | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___throwUnlessMutVarsDeclared) |
| structure | Lean.Elab.Do.EffectForwarder | Lean.Elab.Do.EffectForwarder : Type | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___EffectForwarder___mk) |
| def | Lean.Elab.Do.EffectForwarder.ofCont | Lean.Elab.Do.EffectForwarder.ofCont (info : Elab.Do.ControlInfo) (dec : Elab.Do.DoElemCont) : Elab.Do.DoElabM Elab.Do.EffectForwarder | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___EffectForwarder___ofCont) |
| def | Lean.Elab.Do.EffectForwarder.lift | Lean.Elab.Do.EffectForwarder.lift (l : Elab.Do.EffectForwarder) (elabElem : Elab.Do.DoElemCont → Elab.Do.DoElabM Expr) : Elab.Do.DoElabM Expr | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___EffectForwarder___lift) |
| def | Lean.Elab.Do.EffectForwarder.restoreCont | Lean.Elab.Do.EffectForwarder.restoreCont (l : Elab.Do.EffectForwarder) : Elab.Do.DoElabM Elab.Do.DoElemCont | [Reference](pages/Notations-and-Macros/Extending--do--Notation/index.md#Lean___Elab___Do___EffectForwarder___restoreCont) |
| def | Lean.PrettyPrinter.Unexpander | Lean.PrettyPrinter.Unexpander : Type | [Reference](pages/Notations-and-Macros/Extending-Lean___s-Output/index.md#Lean___PrettyPrinter___Unexpander) |
| def | Lean.PrettyPrinter.UnexpandM | Lean.PrettyPrinter.UnexpandM (α : Type) : Type | [Reference](pages/Notations-and-Macros/Extending-Lean___s-Output/index.md#Lean___PrettyPrinter___UnexpandM) |
| attribute | Unexpander Registration |  | [Reference](pages/Notations-and-Macros/Extending-Lean___s-Output/index.md#attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| attribute | Delaborator Registration |  | [Reference](pages/Notations-and-Macros/Extending-Lean___s-Output/index.md#attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| Lake command | new | lake new name [template][.language] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#new) |
| Lake command | init | lake init name [template][.language] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#init) |
| Lake command | build | lake build [targets...] [-o mappings] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#build) |
| Lake command | check-build | lake check-build | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#check-build) |
| Lake command | query | lake query [targets...] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#query) |
| Lake command | exe | lake exe exe-target [args...] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#exe) |
| Lake command | clean | lake clean [packages...] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#clean) |
| Lake command | env | lake env [cmd [args...]] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#env) |
| Lake command | lean | lake lean file [-- args...] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#lean) |
| Lake command | shake | lake shake [options...] [module ...] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#shake) |
| Lake command | test | lake test [-- args...] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#test) |
| Lake command | lint | lake lint [options...] [module...] [-- args...] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#lint) |
| Lake command | check-test | lake check-test | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#check-test) |
| Lake command | check-lint | lake check-lint | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#check-lint) |
| Lake command | script-list | lake script list | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#script-list) |
| Lake command | script-run | lake script run [[package/]script [args...]] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#script-run) |
| Lake command | script-doc | lake script doc script | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#script-doc) |
| Lake command | serve | lake serve [-- args...] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#serve) |
| Lake command | update | lake update [packages...] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#update) |
| Lake command | upload | lake upload tag | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#upload) |
| Lake command | pack | lake pack [archive.tar.gz] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#pack) |
| Lake command | unpack | lake unpack [archive.tar.gz] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#unpack) |
| Lake command | cache-get | lake cache get [mappings] [--max-revs= cn] [--rev= commit-hash] [--package= name] [--service= name] [--repo= github-repo] [--platform= target-triple] [--toolcha … | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#cache-get) |
| Lake command | cache-put | lake cache put mappings [--service= name] [--scope= remote-scope] [--repo= github-repo] [--toolchain= name] [--platform= target-triple] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#cache-put) |
| Lake command | cache-add | lake cache add mappings [--package= name] [--service= name] [--scope= remote-scope] [--repo= github-repo] [--no-overwrite] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#cache-add) |
| Lake command | cache-clean | lake cache clean | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#cache-clean) |
| Lake command | cache-services | lake cache services | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#cache-services) |
| Lake command | cache-stage | lake cache stage mappings staging-directory [--force-overwrite] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#cache-stage) |
| Lake command | cache-unstage | lake cache unstage staging-directory [--force-overwrite] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#cache-unstage) |
| Lake command | cache-put-staged | lake cache put-staged staging-directory [--rev= commit-hash] [--service= name] [--scope= remote-scope] [--repo= github-repo] [--toolchain= name] [--platform= ta … | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#cache-put-staged) |
| Lake command | translate-config | lake translate-config lang [out-file] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#translate-config) |
| TOML table | Lake___PackageConfig | Package Configuration | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___PackageConfig) |
| TOML table | Lake___Dependency | Requiring Packages — [[require]] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___Dependency) |
| TOML table | Lake___LeanLibConfig | Library Targets — [[lean_lib]] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___LeanLibConfig) |
| TOML table | Lake___LeanExeConfig | Executable Targets — [[lean_exe]] | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___LeanExeConfig) |
| syntax | Declarative Fields |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___DSL___declField) |
| syntax | Package Configuration |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Post-Update Hooks |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Requiring Packages |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Package Sources |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#fromClause) |
| attribute | Specifying Default Targets |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Library Targets |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| structure | Lake.LeanLibConfig | Lake.LeanLibConfig (name : Lean.Name) : Type | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___LeanLibConfig___mk) |
| syntax | Executable Targets |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| structure | Lake.LeanExeConfig | Lake.LeanExeConfig (name : Lean.Name) : Type | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___LeanExeConfig___mk) |
| syntax | External Library Targets |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Custom Targets |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Custom Package Facets |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Custom Library Facets |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Custom Module Facets |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| inductive type | Lake.BuildType | Lake.BuildType : Type | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___BuildType___debug) |
| syntax | Glob Syntax |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| inductive type | Lake.Glob | Lake.Glob : Type | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___Glob___one) |
| structure | Lean.LeanOption | Lean.LeanOption : Type | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lean___LeanOption___mk) |
| inductive type | Lake.Backend | Lake.Backend : Type | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___Backend___c) |
| syntax | Script Declarations |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Lake.ScriptM | Lake.ScriptM (α : Type) : Type | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___ScriptM) |
| attribute | Default Scripts |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | The Current Directory |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Configuration Options |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Compile-Time Conditionals |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| syntax | Command Sequences |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#cmdDo) |
| syntax | Compile-Time Side Effects |  | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next) |
| def | Lake.ScriptM | Lake.ScriptM (α : Type) : Type | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___ScriptM-next) |
| def | Lake.MonadLakeEnv | Lake.MonadLakeEnv.{u} (m : Type → Type u) : Type u | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___MonadLakeEnv) |
| def | Lake.getLakeEnv | Lake.getLakeEnv.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] : m Lake.Env | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getLakeEnv) |
| def | Lake.getNoCache | Lake.getNoCache.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] [Lake.MonadBuild m] : m Bool | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getNoCache) |
| def | Lake.getTryCache | Lake.getTryCache.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] [Lake.MonadBuild m] : m Bool | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getTryCache) |
| def | Lake.getPkgUrlMap | Lake.getPkgUrlMap.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m (Lean.NameMap String) | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getPkgUrlMap) |
| def | Lake.getElanToolchain | Lake.getElanToolchain.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m String | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getElanToolchain) |
| def | Lake.getEnvLeanPath | Lake.getEnvLeanPath.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m System.SearchPath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getEnvLeanPath) |
| def | Lake.getEnvLeanSrcPath | Lake.getEnvLeanSrcPath.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m System.SearchPath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getEnvLeanSrcPath) |
| def | Lake.getEnvSharedLibPath | Lake.getEnvSharedLibPath.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m System.SearchPath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getEnvSharedLibPath) |
| def | Lake.getElanInstall? | Lake.getElanInstall?.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m (Option Lake.ElanInstall) | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getElanInstall___) |
| def | Lake.getElanHome? | Lake.getElanHome?.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m (Option System.FilePath) | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getElanHome___) |
| def | Lake.getElan? | Lake.getElan?.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m (Option System.FilePath) | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getElan___) |
| def | Lake.getLeanInstall | Lake.getLeanInstall.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m Lake.LeanInstall | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getLeanInstall) |
| def | Lake.getLeanSysroot | Lake.getLeanSysroot.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m System.FilePath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getLeanSysroot) |
| def | Lake.getLeanSrcDir | Lake.getLeanSrcDir.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m System.FilePath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getLeanSrcDir) |
| def | Lake.getLeanLibDir | Lake.getLeanLibDir.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m System.FilePath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getLeanLibDir) |
| def | Lake.getLeanIncludeDir | Lake.getLeanIncludeDir.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m System.FilePath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getLeanIncludeDir) |
| def | Lake.getLeanSystemLibDir | Lake.getLeanSystemLibDir.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m System.FilePath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getLeanSystemLibDir) |
| def | Lake.getLean | Lake.getLean.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m System.FilePath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getLean) |
| def | Lake.getLeanc | Lake.getLeanc.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m System.FilePath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getLeanc) |
| def | Lake.getLeanSharedLib | Lake.getLeanSharedLib.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m System.FilePath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getLeanSharedLib) |
| def | Lake.getLeanAr | Lake.getLeanAr.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m System.FilePath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getLeanAr) |
| def | Lake.getLeanCc | Lake.getLeanCc.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m System.FilePath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getLeanCc) |
| def | Lake.getLeanCc? | Lake.getLeanCc?.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m (Option String) | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getLeanCc___) |
| def | Lake.getLakeInstall | Lake.getLakeInstall.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m Lake.LakeInstall | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getLakeInstall) |
| def | Lake.getLakeHome | Lake.getLakeHome.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m System.FilePath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getLakeHome) |
| def | Lake.getLakeSrcDir | Lake.getLakeSrcDir.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m System.FilePath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getLakeSrcDir) |
| def | Lake.getLakeLibDir | Lake.getLakeLibDir.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m System.FilePath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getLakeLibDir) |
| def | Lake.getLake | Lake.getLake.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] [Functor m] : m System.FilePath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getLake) |
| type class | Lake.MonadWorkspace | Lake.MonadWorkspace.{u} (m : Type → Type u) : Type u | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___MonadWorkspace___mk) |
| def | Lake.getRootPackage | Lake.getRootPackage.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m] [Functor m] : m Lake.Package | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getRootPackage) |
| def | Lake.findPackageByName? | Lake.findPackageByName?.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m] [Functor m] (name : Lean.Name) : m (Option Lake.Package) | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___findPackageByName___) |
| def | Lake.findPackageByKey? | Lake.findPackageByKey?.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m] [Functor m] (keyName : Lean.Name) : m (Option (Lake.NPackage keyName)) | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___findPackageByKey___) |
| def | Lake.findModule? | Lake.findModule?.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m] [Functor m] (name : Lean.Name) : m (Option Lake.Module) | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___findModule___) |
| def | Lake.findLeanExe? | Lake.findLeanExe?.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m] [Functor m] (name : Lean.Name) : m (Option Lake.LeanExe) | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___findLeanExe___) |
| def | Lake.findLeanLib? | Lake.findLeanLib?.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m] [Functor m] (name : Lean.Name) : m (Option Lake.LeanLib) | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___findLeanLib___) |
| def | Lake.findExternLib? | Lake.findExternLib?.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m] [Functor m] (name : Lean.Name) : m (Option Lake.ExternLib) | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___findExternLib___) |
| def | Lake.getLeanPath | Lake.getLeanPath.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m] [Functor m] : m System.SearchPath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getLeanPath) |
| def | Lake.getLeanSrcPath | Lake.getLeanSrcPath.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m] [Functor m] : m System.SearchPath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getLeanSrcPath) |
| def | Lake.getSharedLibPath | Lake.getSharedLibPath.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m] [Functor m] : m System.SearchPath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getSharedLibPath) |
| def | Lake.getAugmentedLeanPath | Lake.getAugmentedLeanPath.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m] [Functor m] : m System.SearchPath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getAugmentedLeanPath) |
| def | Lake.getAugmentedLeanSrcPath | Lake.getAugmentedLeanSrcPath.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m] [Functor m] : m System.SearchPath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getAugmentedLeanSrcPath) |
| def | Lake.getAugmentedSharedLibPath | Lake.getAugmentedSharedLibPath.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m] [Functor m] : m System.SearchPath | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getAugmentedSharedLibPath) |
| def | Lake.getAugmentedEnv | Lake.getAugmentedEnv.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m] [Functor m] : m (Array (String × Option String)) | [Reference](pages/Build-Tools-and-Distribution/Lake/index.md#Lake___getAugmentedEnv) |
| Elan command | show-next | elan show | [Reference](pages/Build-Tools-and-Distribution/Managing-Toolchains-with-Elan/index.md#show-next) |
| Elan command | default | elan default toolchain | [Reference](pages/Build-Tools-and-Distribution/Managing-Toolchains-with-Elan/index.md#default) |
| Elan command | toolchain-list | elan toolchain list | [Reference](pages/Build-Tools-and-Distribution/Managing-Toolchains-with-Elan/index.md#toolchain-list) |
| Elan command | toolchain-install | elan toolchain install toolchain | [Reference](pages/Build-Tools-and-Distribution/Managing-Toolchains-with-Elan/index.md#toolchain-install) |
| Elan command | toolchain-uninstall | elan toolchain uninstall toolchain | [Reference](pages/Build-Tools-and-Distribution/Managing-Toolchains-with-Elan/index.md#toolchain-uninstall) |
| Elan command | toolchain-link | elan toolchain link local-name path | [Reference](pages/Build-Tools-and-Distribution/Managing-Toolchains-with-Elan/index.md#toolchain-link) |
| Elan command | toolchain-gc | elan toolchain gc [--delete] [--json] | [Reference](pages/Build-Tools-and-Distribution/Managing-Toolchains-with-Elan/index.md#toolchain-gc) |
| Elan command | override-list | elan override list | [Reference](pages/Build-Tools-and-Distribution/Managing-Toolchains-with-Elan/index.md#override-list) |
| Elan command | override-set | elan override set toolchain | [Reference](pages/Build-Tools-and-Distribution/Managing-Toolchains-with-Elan/index.md#override-set) |
| Elan command | override-unset | elan override unset [--nonexistent] [--path path] | [Reference](pages/Build-Tools-and-Distribution/Managing-Toolchains-with-Elan/index.md#override-unset) |
| Elan command | run | elan run [--install] toolchain command ... | [Reference](pages/Build-Tools-and-Distribution/Managing-Toolchains-with-Elan/index.md#run) |
| Elan command | which | elan which command | [Reference](pages/Build-Tools-and-Distribution/Managing-Toolchains-with-Elan/index.md#which) |
| Elan command | self-update | elan self update | [Reference](pages/Build-Tools-and-Distribution/Managing-Toolchains-with-Elan/index.md#self-update) |
| Elan command | self-uninstall | elan self uninstall | [Reference](pages/Build-Tools-and-Distribution/Managing-Toolchains-with-Elan/index.md#self-uninstall) |
| Elan command | completions | elan completions shell | [Reference](pages/Build-Tools-and-Distribution/Managing-Toolchains-with-Elan/index.md#completions) |
| Warning |  |  | [Reference](pages/releases/v4.34.0/index.md#) |
