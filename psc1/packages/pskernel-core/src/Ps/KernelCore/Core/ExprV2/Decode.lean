import Ps.KernelCore.Core.Expr
import Ps.KernelCore.Research.ExprV2PagedValidation

/-
Transitional, sharing-preserving input boundary for the complete kernel.

Validation and decoding are separate: the public checked entry replays the
untrusted graph once, then materializes each topological node exactly once.
Children reuse previously materialized immutable expressions. No graph walk
is repeated inside WHNF, inference, DefEq or declaration admission.

The paged output avoids the portable backend's growing-array append copies.
This is a migration adapter, not a DAG-native checker. Decoded values and
caller-constructed records are never proof certificates.
-/
structure PsKernelExprV2Decoded where
  pages : Array (Array PsKernelExpr)
  active : Array PsKernelExpr
  size : Nat

def psKernelExprV2DecodedEmpty : PsKernelExprV2Decoded :=
  PsKernelExprV2Decoded.mk
    (Array.emptyWithCapacity 0) (Array.emptyWithCapacity 0) 0

def psKernelExprV2DecodedPush
    (built : PsKernelExprV2Decoded)
    (expr : PsKernelExpr) : PsKernelExprV2Decoded :=
  if Nat.blt (Array.size built.active) 64 then
    PsKernelExprV2Decoded.mk built.pages
      (Array.push built.active expr) (Nat.succ built.size)
  else
    PsKernelExprV2Decoded.mk
      (Array.push built.pages built.active)
      (Array.push (Array.emptyWithCapacity 0) expr)
      (Nat.succ built.size)

def psKernelExprV2DecodedRequire
    (built : PsKernelExprV2Decoded)
    (id : Nat) : Except String PsKernelExpr :=
  if Nat.blt id built.size then
    let page := Nat.div id 64;
    let offset := Nat.mod id 64;
    let full := Array.size built.pages;
    let chunk :=
      if Nat.blt page full then
        Array.getD built.pages page (Array.emptyWithCapacity 0)
      else if Nat.beq page full then
        built.active
      else
        Array.emptyWithCapacity 0;
    if Nat.blt offset (Array.size chunk) then
      Except.ok
        (Array.getD chunk offset (PsKernelExpr.bvar 0))
    else
      Except.error "PSKERNEL_V2_DECODE_MISSING_NODE"
  else
    Except.error "PSKERNEL_V2_DECODE_INVALID_REFERENCE"

def psKernelExprV2DecodedWith1
    (built : PsKernelExprV2Decoded) (child : Nat)
    (make : PsKernelExpr -> PsKernelExpr) :
    Except String PsKernelExpr :=
  match psKernelExprV2DecodedRequire built child with
  | Except.error error => Except.error error
  | Except.ok value => Except.ok (make value)

def psKernelExprV2DecodedWith2
    (built : PsKernelExprV2Decoded) (left right : Nat)
    (make : PsKernelExpr -> PsKernelExpr -> PsKernelExpr) :
    Except String PsKernelExpr :=
  match psKernelExprV2DecodedRequire built left with
  | Except.error error => Except.error error
  | Except.ok a =>
      match psKernelExprV2DecodedRequire built right with
      | Except.error error => Except.error error
      | Except.ok b => Except.ok (make a b)

def psKernelExprV2DecodedWith3
    (built : PsKernelExprV2Decoded) (first second third : Nat)
    (make : PsKernelExpr -> PsKernelExpr -> PsKernelExpr -> PsKernelExpr) :
    Except String PsKernelExpr :=
  match psKernelExprV2DecodedRequire built first with
  | Except.error error => Except.error error
  | Except.ok a =>
      match psKernelExprV2DecodedRequire built second with
      | Except.error error => Except.error error
      | Except.ok b =>
          match psKernelExprV2DecodedRequire built third with
          | Except.error error => Except.error error
          | Except.ok c => Except.ok (make a b c)

def psKernelExprV2DecodedLam
    (name : PsKernelName) (info : PsKernelBinderInfo)
    (type body : PsKernelExpr) : PsKernelExpr :=
  PsKernelExpr.lam name type body info

def psKernelExprV2DecodedForall
    (name : PsKernelName) (info : PsKernelBinderInfo)
    (type body : PsKernelExpr) : PsKernelExpr :=
  PsKernelExpr.forallE name type body info

def psKernelExprV2DecodedLet
    (name : PsKernelName) (nondep : Bool)
    (type value body : PsKernelExpr) : PsKernelExpr :=
  PsKernelExpr.letE name type value body nondep

def psKernelExprV2DecodedNode
    (built : PsKernelExprV2Decoded)
    (node : PsKernelExprV2Node) : Except String PsKernelExpr :=
  match node with
  | PsKernelExprV2Node.bvar index =>
      Except.ok (PsKernelExpr.bvar index)
  | PsKernelExprV2Node.fvar name =>
      Except.ok (PsKernelExpr.fvar name)
  | PsKernelExprV2Node.mvar name =>
      Except.ok (PsKernelExpr.mvar name)
  | PsKernelExprV2Node.sort level =>
      Except.ok (PsKernelExpr.sort level)
  | PsKernelExprV2Node.const name levels =>
      Except.ok (PsKernelExpr.const name levels)
  | PsKernelExprV2Node.lit value =>
      Except.ok (PsKernelExpr.lit value)
  | PsKernelExprV2Node.app fn arg =>
      psKernelExprV2DecodedWith2 built fn arg PsKernelExpr.app
  | PsKernelExprV2Node.lam name type body info =>
      psKernelExprV2DecodedWith2 built type body
        (psKernelExprV2DecodedLam name info)
  | PsKernelExprV2Node.forallE name type body info =>
      psKernelExprV2DecodedWith2 built type body
        (psKernelExprV2DecodedForall name info)
  | PsKernelExprV2Node.letE name type value body nondep =>
      psKernelExprV2DecodedWith3 built type value body
        (psKernelExprV2DecodedLet name nondep)
  | PsKernelExprV2Node.mdata tag body =>
      psKernelExprV2DecodedWith1 built body (PsKernelExpr.mdata tag)
  | PsKernelExprV2Node.proj name index body =>
      psKernelExprV2DecodedWith1 built body (PsKernelExpr.proj name index)

def psKernelExprV2DecodeCanonicalFuel
    (fuel : Nat) :
    PsKernelExprV2PagedArena -> PsKernelExprV2Decoded -> Nat ->
    Except String PsKernelExprV2Decoded :=
  match fuel with
  | Nat.zero =>
      fun (_source : PsKernelExprV2PagedArena)
          (_built : PsKernelExprV2Decoded) (_id : Nat) =>
        Except.error "PSKERNEL_V2_DECODE_FUEL"
  | Nat.succ remaining =>
      let smaller := psKernelExprV2DecodeCanonicalFuel remaining;
      fun (source : PsKernelExprV2PagedArena)
          (built : PsKernelExprV2Decoded) (id : Nat) =>
        if Nat.beq id source.size then
          Except.ok built
        else
          match psKernelExprV2PagedRequire source id with
          | Except.error error => Except.error error
          | Except.ok entry =>
              match psKernelExprV2DecodedNode built entry.node with
              | Except.error error => Except.error error
              | Except.ok expr =>
                  smaller source
                    (psKernelExprV2DecodedPush built expr) (Nat.succ id)

def psKernelExprV2DecodeChecked
    (source : PsKernelExprV2PagedArena) :
    Except String PsKernelExprV2Decoded :=
  match psKernelExprV2PagedValidate source with
  | Except.error error => Except.error error
  | Except.ok canonical =>
      psKernelExprV2DecodeCanonicalFuel
        (Nat.succ canonical.size) canonical psKernelExprV2DecodedEmpty 0
