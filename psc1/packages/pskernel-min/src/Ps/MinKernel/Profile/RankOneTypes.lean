-- C1 type-signature experiment. Not imported by any public admission checker.
import Ps.MinKernel.Profile.CoreBytes

inductive PsMinRankTy where
  | tvar (index : Nat)
  | natural
  | boolean
  | unit
  | arr (domain result : PsMinRankTy)
  | list (element : PsMinRankTy)
  | option (element : PsMinRankTy)
  | except (error result : PsMinRankTy)
  | prod (left right : PsMinRankTy)

structure PsMinRankScheme where
  arity : Nat
  body : PsMinRankTy

-- Some is a rigid type parameter's stable level; none is a term-binder hole.
def psMinRankLookup (context : List (Option Nat)) (index : Nat) : Option Nat :=
  match context with
  | List.nil => Option.none
  | List.cons head tail => match index with
    | Nat.zero => head
    | Nat.succ previous => psMinRankLookup tail previous

def psMinRankBase (name : PsMinCoreName) : Option PsMinRankTy :=
  if psMinCoreNameEq name (PsMinCoreName.str PsMinCoreName.anonymous [78, 97, 116]) then Option.some PsMinRankTy.natural else
  if psMinCoreNameEq name (PsMinCoreName.str PsMinCoreName.anonymous [66, 111, 111, 108]) then Option.some PsMinRankTy.boolean else
  if psMinCoreNameEq name (PsMinCoreName.str PsMinCoreName.anonymous [85, 110, 105, 116]) then Option.some PsMinRankTy.unit else Option.none

def psMinRankUnary (name : PsMinCoreName) (element : PsMinRankTy) : Option PsMinRankTy :=
  if psMinCoreNameEq name (PsMinCoreName.str PsMinCoreName.anonymous [76, 105, 115, 116]) then Option.some (PsMinRankTy.list element) else
  if psMinCoreNameEq name (PsMinCoreName.str PsMinCoreName.anonymous [79, 112, 116, 105, 111, 110]) then Option.some (PsMinRankTy.option element) else Option.none

def psMinRankBinary (name : PsMinCoreName) (left right : PsMinRankTy) : Option PsMinRankTy :=
  if psMinCoreNameEq name (PsMinCoreName.str PsMinCoreName.anonymous [69, 120, 99, 101, 112, 116]) then Option.some (PsMinRankTy.except left right) else
  if psMinCoreNameEq name (PsMinCoreName.str PsMinCoreName.anonymous [80, 114, 111, 100]) then Option.some (PsMinRankTy.prod left right) else Option.none

def psMinRankMono (fuel : Nat) (context : List (Option Nat)) (source : PsMinCoreExpr) : Option PsMinRankTy :=
  match fuel with
  | Nat.zero => Option.none
  | Nat.succ rest => match source with
    | .bvar index => match psMinRankLookup context index with
      | Option.none => Option.none
      | Option.some slot => Option.some (PsMinRankTy.tvar slot)
    | .constant name levels => if psMinByteEq levels List.nil then psMinRankBase name else Option.none
    | .forallE _ _ domain body =>
      match psMinRankMono rest context domain with
      | Option.none => Option.none
      | Option.some a => match psMinRankMono rest (List.cons Option.none context) body with
        | Option.none => Option.none
        | Option.some b => Option.some (PsMinRankTy.arr a b)
    | .app fn arg => match fn with
      | .constant name levels => if psMinByteEq levels List.nil then
          match psMinRankMono rest context arg with
          | Option.none => Option.none
          | Option.some a => psMinRankUnary name a
        else Option.none
      | .app operator left => match operator with
        | .constant name levels => if psMinByteEq levels List.nil then
            match psMinRankMono rest context left with
            | Option.none => Option.none
            | Option.some a => match psMinRankMono rest context arg with
              | Option.none => Option.none
              | Option.some b => psMinRankBinary name a b
          else Option.none
        | _ => Option.none
      | _ => Option.none
    | _ => Option.none

def psMinRankFinish (fuel count : Nat) (context : List (Option Nat))
    (source : PsMinCoreExpr) : Option PsMinRankScheme :=
  match psMinRankMono fuel context source with
  | Option.none => Option.none
  | Option.some body => Option.some (PsMinRankScheme.mk count body)

def psMinRankSchemeWith (fuel count : Nat) (context : List (Option Nat))
    (source : PsMinCoreExpr) : Option PsMinRankScheme :=
  match fuel with
  | Nat.zero => Option.none
  | Nat.succ rest => match source with
    | .forallE _ _ domain body => match domain with
      | .sort level => if Nat.beq level 1 then
          psMinRankSchemeWith rest (Nat.succ count) (List.cons (Option.some count) context) body
        else psMinRankFinish (Nat.succ rest) count context source
      | _ => psMinRankFinish (Nat.succ rest) count context source
    | _ => psMinRankFinish (Nat.succ rest) count context source

def psMinRankSignature (fuel : Nat) (source : PsMinCoreExpr) : Option PsMinRankScheme :=
  psMinRankSchemeWith fuel 0 List.nil source
