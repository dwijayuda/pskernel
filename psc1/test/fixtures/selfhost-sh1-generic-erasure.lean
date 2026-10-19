-- The generated compiler consumes this source before inspecting its original IR.
-- These cases distinguish declaration generic order from local-context order.
def sh1GenericCopy {alpha : Type} (values : List alpha) : List alpha :=
  match values with
  | List.nil => List.nil
  | List.cons value rest => List.cons value (sh1GenericCopy rest)

def sh1GenericMap {alpha beta : Type}
    (convert : alpha -> beta) (values : List alpha) : List beta :=
  match values with
  | List.nil => List.nil
  | List.cons value rest => List.cons (convert value) (sh1GenericMap convert rest)

-- Type binders are interleaved with an erased proposition, erased proof, and
-- runtime values. Their call arguments must still be T0, T1, T2 in that order.
def sh1GenericTriple (alpha : Type) {p : Prop} (h : p)
    (first : alpha) (beta : Type) (second : beta)
    (gamma : Type) (third : gamma) (fuel : Nat) : Prod alpha (Prod beta gamma) :=
  match fuel with
  | Nat.zero => Prod.mk first (Prod.mk second third)
  | Nat.succ remaining =>
      sh1GenericTriple alpha h first beta second gamma third remaining

def sh1GenericMono (fuel : Nat) (value : Nat) : Nat :=
  match fuel with
  | Nat.zero => value
  | Nat.succ remaining => sh1GenericMono remaining value

-- Canonical function values must commute with rank-1 type substitution.
-- These unchanged source-language forms previously lost the generic result
-- saturation boundary or disagreed with function types inside regular data.
def sh1GroupIdentity {alpha : Type} (value : alpha) : alpha := value

def sh1GroupDirect (f : Nat -> Nat) : Nat :=
  sh1GroupIdentity f 7

def sh1GroupLet (f : Nat -> Nat) : Nat :=
  let next : Nat -> Nat := sh1GroupIdentity f;
  next 7

def sh1GroupApply {alpha : Type} (f : Nat -> alpha) (value : Nat) : alpha :=
  f value

def sh1GroupHigher (f : Nat -> Nat -> Nat) : Nat :=
  sh1GroupApply f 3 7

def sh1GroupWeighted (first : Nat) (second : Nat) : Nat :=
  Nat.add (Nat.mul first 10) second

def sh1GroupKnown : Nat :=
  sh1GroupIdentity sh1GroupWeighted 3 7

structure Sh1GroupRecord (alpha : Type) where
  run : Nat -> alpha

def sh1GroupRecordUse (f : Nat -> Nat -> Nat) : Nat :=
  let holder := Sh1GroupRecord.mk f;
  let next : Nat -> Nat -> Nat := holder.run;
  next 3 7

inductive Sh1GroupBox (alpha : Type) where
  | hold (run : Nat -> alpha)

def sh1GroupBoxUse (f : Nat -> Nat -> Nat) : Nat :=
  let holder := Sh1GroupBox.hold f;
  match holder with
  | Sh1GroupBox.hold run => run 3 7

def sh1GroupArrayUse (f : Nat -> Nat -> Nat) : Nat :=
  let values := Array.push (Array.emptyWithCapacity 0) f;
  let passed := sh1GroupIdentity values;
  let next : Nat -> Nat -> Nat := Array.getD passed 0 f;
  next 3 7

def sh1GroupArrayMap (fallback : Nat -> Nat) : Nat :=
  let values := Array.push (Array.emptyWithCapacity 0) 3;
  let functions := Array.map sh1GroupWeighted values;
  let next : Nat -> Nat := Array.getD functions 0 fallback;
  next 7

def sh1GroupArrayFold : Nat :=
  let values := Array.push (Array.push (Array.emptyWithCapacity 0) 3) 5;
  let combine : Nat -> Nat -> Nat :=
    fun (acc : Nat) (value : Nat) => Nat.add acc value;
  Array.foldl combine 7 values 0 (Array.size values)

-- The entry ends before this computed returned closure. Demanding make belongs
-- to this call, even when the returned function is saved, reused or discarded.
def sh1GroupComputed (make : Unit -> Nat) (offset : Nat) : Nat -> Nat :=
  let captured : Nat := make Unit.unit;
  fun (value : Nat) => Nat.add captured (Nat.add offset value)

-- Type-only generic prefixes activate their computed body at instantiation.
-- Their internal Unit entry adapter is absent from the source telescope.
def sh1GroupTypeOnly {alpha : Type} : alpha -> alpha :=
  let identity : alpha -> alpha := fun (value : alpha) => value;
  identity

def sh1GroupTypeOnlyUse (value : Nat) : Nat :=
  sh1GroupTypeOnly value

def sh1GroupTypeOnlyHigher (f : Nat -> Nat) : Nat :=
  sh1GroupTypeOnly f 7

def sh1GroupTypeProofOnly {alpha : Type} {premise : Prop} (proof : premise) : alpha -> alpha :=
  let identity : alpha -> alpha := fun (value : alpha) => value;
  identity

def sh1GroupTypeProofOnlyUse {premise : Prop} (proof : premise) (value : Nat) : Nat :=
  sh1GroupTypeProofOnly proof value

-- Result annotations follow the checked Core spine, including function-valued
-- type arguments inside a lambda body and through an ordinary local projection.
def sh1GroupLambda (f : Nat -> Nat) : Nat :=
  let run : Nat -> Nat := fun (value : Nat) => sh1GroupIdentity f value;
  run 7

def sh1GroupProjection (f : Nat -> Nat -> Nat) : Nat :=
  let holder := sh1GroupIdentity (Sh1GroupRecord.mk f);
  holder.run 3 7

-- These finite equations inspect the actual prepared Core before erasure.
-- A minor must use the reconstructed current constructor, not a captured major.
def sh1CoreMajorCapture (n : Nat) : Nat :=
  match n with
  | Nat.zero => 0
  | Nat.succ predecessor =>
      Nat.add n (sh1CoreMajorCapture predecessor)

-- Nested inspection retains the established outer-child recursive hypothesis.
-- The newly inspected inner field is not a recursive-call permission.
def sh1CoreNestedOuter (n : Nat) : Nat :=
  match n with
  | Nat.zero => 0
  | Nat.succ outer =>
      match outer with
      | Nat.zero => Nat.add n (sh1CoreNestedOuter outer)
      | Nat.succ inner => Nat.add n (sh1CoreNestedOuter outer)

-- Recursive records remain records. These declarations are compile-only:
-- no finite canonical value of either recursive record is constructed or run.
structure Sh1RecursiveRecord where
  next : Sh1RecursiveRecord

def sh1RecursiveRecordObserve (value : Sh1RecursiveRecord) : Nat :=
  match value with
  | Sh1RecursiveRecord.mk next => 0

def sh1RecursiveRecordStep (value : Sh1RecursiveRecord) : Nat :=
  match value with
  | Sh1RecursiveRecord.mk next => sh1RecursiveRecordStep next

structure Sh1RecursiveGenericRecord (alpha : Type) where
  item : alpha
  next : Sh1RecursiveGenericRecord alpha

def sh1RecursiveGenericObserve {alpha : Type}
    (value : Sh1RecursiveGenericRecord alpha) : alpha :=
  match value with
  | Sh1RecursiveGenericRecord.mk item next => item

def sh1RecursiveGenericStep {alpha : Type}
    (value : Sh1RecursiveGenericRecord alpha) : alpha :=
  match value with
  | Sh1RecursiveGenericRecord.mk item next => sh1RecursiveGenericStep next
