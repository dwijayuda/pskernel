/-!
PSCV0 v7 APP-04 abstract application/grouping model.
Lean 4.35.0-rc4 only; no axioms, no unsafe, no sorry.
This proves structural ownership/algebra, NOT correctness of the production parser.
-/

namespace Pscv0.App04

/-- Source syntax retains the group and application-boundary information that
must survive parsing, printing and source-map generation. It is not kernel IR. -/
inductive Surface where
  | ident (value : String)
  | group (term : Surface)
  | native (head argument : Surface)
  | postfix (head argument : Surface)
  deriving Repr, DecidableEq

/-- The kernel-facing abstract applicative form has unary application only. -/
inductive Core where
  | ident (value : String)
  | app (head argument : Core)
  deriving Repr, DecidableEq

def lower : Surface → Core
  | .ident name => .ident name
  | .group value => lower value
  | .native head argument => .app (lower head) (lower argument)
  | .postfix head argument => .app (lower head) (lower argument)

/-- `f x(y)`: postfix on the immediately preceding operand, then native app. -/
def mixed (f x y : String) : Surface :=
  .native (.ident f) (.postfix (.ident x) (.ident y))

/-- `f(x(y))`: adjacent calls can express the same argument tree. -/
def nested (f x y : String) : Surface :=
  .postfix (.ident f) (.postfix (.ident x) (.ident y))

/-- `(f x)(y)`: the grouped application is the callee of the outer call. -/
def grouped (f x y : String) : Surface :=
  .postfix (.group (.native (.ident f) (.ident x))) (.ident y)

/-- `f(x) y`: the result of the first call receives the native argument. -/
def postThenNative (f x y : String) : Surface :=
  .native (.postfix (.ident f) (.ident x)) (.ident y)

theorem grouping_does_not_add_core_constructor (term : Surface) :
    lower (.group term) = lower term := rfl

theorem mixed_and_explicit_nested_have_same_core (f x y : String) :
    lower (mixed f x y) = lower (nested f x y) := rfl

theorem grouped_has_left_application_core (f x y : String) :
    lower (grouped f x y) =
      .app (.app (.ident f) (.ident x)) (.ident y) := rfl

theorem native_after_postfix_has_left_application_core (f x y : String) :
    lower (postThenNative f x y) =
      .app (.app (.ident f) (.ident x)) (.ident y) := rfl

theorem mixed_has_right_argument_application_core (f x y : String) :
    lower (mixed f x y) =
      .app (.ident f) (.app (.ident x) (.ident y)) := rfl

theorem mixed_and_grouped_are_distinct_source_trees (f x y : String) :
    mixed f x y ≠ grouped f x y := by
  intro h
  cases h

theorem mixed_and_grouped_have_distinct_abstract_core_trees (f x y : String) :
    lower (mixed f x y) ≠ lower (grouped f x y) := by
  intro h
  cases h

/-- These two surface forms are not identical source trees despite agreeing
after lowering. That is why the printer must preserve the source partition. -/
theorem grouping_partition_is_not_erasure (f x y : String) :
    grouped f x y ≠ postThenNative f x y := by
  intro h
  cases h

#print axioms Pscv0.App04.grouping_does_not_add_core_constructor
#print axioms Pscv0.App04.mixed_and_explicit_nested_have_same_core
#print axioms Pscv0.App04.grouped_has_left_application_core
#print axioms Pscv0.App04.native_after_postfix_has_left_application_core
#print axioms Pscv0.App04.mixed_has_right_argument_application_core
#print axioms Pscv0.App04.mixed_and_grouped_are_distinct_source_trees
#print axioms Pscv0.App04.mixed_and_grouped_have_distinct_abstract_core_trees
#print axioms Pscv0.App04.grouping_partition_is_not_erasure

end Pscv0.App04
