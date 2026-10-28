import RegularIngressWire

namespace Ps.MinKernel.RegularIngressEncoding
open Ps.MinKernel.RegularIngressWire
open Ps.MinKernel.RegularIngressModel

-- A separate mathematical token grammar for canonical structure and numeral values.
def quotedNumberTokens (expected : Nat) : List Token :=
  ((([] ++ [.literal [34]]) ++ [.number expected]) ++ [.literal [34]])


def textTokens (text : List Nat) : List Token :=
  ((([] ++ [.literal [34]]) ++ [.literal text]) ++ [.literal [34]])


def nameTokens (name : PsMinCoreName) : List Token :=
  match name with
  | .anonymous => [.literal [123, 34, 107, 34, 58, 34, 97, 34, 125]]
  | .str parent text =>
    ((((([] ++ [.literal [123, 34, 107, 34, 58, 34, 115, 34, 44, 34, 112, 34, 58]]) ++ (nameTokens parent)) ++ [.literal [44, 34, 118, 34, 58]]) ++ (textTokens text)) ++ [.literal [125]])
  | .num parent value =>
    ((((([] ++ [.literal [123, 34, 107, 34, 58, 34, 110, 34, 44, 34, 112, 34, 58]]) ++ (nameTokens parent)) ++ [.literal [44, 34, 118, 34, 58]]) ++ (quotedNumberTokens value)) ++ [.literal [125]])


def levelTokens (level : Nat) : List Token :=
  match level with
  | Nat.zero => [.literal [123, 34, 107, 34, 58, 34, 122, 34, 125]]
  | Nat.succ rest =>
    ((([] ++ [.literal [123, 34, 107, 34, 58, 34, 115, 34, 44, 34, 111, 34, 58]]) ++ (levelTokens rest)) ++ [.literal [125]])


def levelsTailTokens (levels : List Nat) : List Token :=
  match levels with
  | List.nil => []
  | List.cons level rest =>
    ((([] ++ [.literal [44]]) ++ (levelTokens level)) ++ (levelsTailTokens rest))


def levelsTokens (levels : List Nat) : List Token :=
  match levels with
  | List.nil => [.literal [91, 93]]
  | List.cons level rest =>
    (((([] ++ [.literal [91]]) ++ (levelTokens level)) ++ (levelsTailTokens rest)) ++ [.literal [93]])


def binderTokens (binder : Nat) : List Token :=
  if Nat.beq binder 0 then [.literal [34, 100, 101, 102, 97, 117, 108, 116, 34]] else
  if Nat.beq binder 1 then [.literal [34, 105, 109, 112, 108, 105, 99, 105, 116, 34]] else
  if Nat.beq binder 2 then [.literal [34, 115, 116, 114, 105, 99, 116, 73, 109, 112, 108, 105, 99, 105, 116, 34]] else
  if Nat.beq binder 3 then [.literal [34, 105, 110, 115, 116, 73, 109, 112, 108, 105, 99, 105, 116, 34]] else []


def exprTokens (expr : PsMinCoreExpr) : List Token :=
  match expr with
  | .bvar index =>
    ((([] ++ [.literal [123, 34, 105, 34, 58]]) ++ [.number index]) ++ [.literal [44, 34, 107, 34, 58, 34, 98, 34, 125]])
  | .natural value =>
    ((([] ++ [.literal [123, 34, 107, 34, 58, 34, 110, 97, 116, 34, 44, 34, 118, 34, 58]]) ++ (quotedNumberTokens value)) ++ [.literal [125]])
  | .sort level =>
    ((([] ++ [.literal [123, 34, 107, 34, 58, 34, 115, 111, 114, 116, 34, 44, 34, 108, 34, 58]]) ++ (levelTokens level)) ++ [.literal [125]])
  | .constant name levels =>
    ((((([] ++ [.literal [123, 34, 107, 34, 58, 34, 99, 111, 110, 115, 116, 34, 44, 34, 108, 115, 34, 58]]) ++ (levelsTokens levels)) ++ [.literal [44, 34, 110, 34, 58]]) ++ (nameTokens name)) ++ [.literal [125]])
  | .app fn arg =>
    ((((([] ++ [.literal [123, 34, 97, 34, 58]]) ++ (exprTokens arg)) ++ [.literal [44, 34, 102, 34, 58]]) ++ (exprTokens fn)) ++ [.literal [44, 34, 107, 34, 58, 34, 97, 112, 112, 34, 125]])
  | .lam name binder type body =>
    ((((((((([] ++ [.literal [123, 34, 98, 34, 58]]) ++ (exprTokens body)) ++ [.literal [44, 34, 98, 105, 34, 58]]) ++ (binderTokens binder)) ++ [.literal [44, 34, 107, 34, 58, 34, 108, 97, 109, 34, 44, 34, 110, 34, 58]]) ++ (nameTokens name)) ++ [.literal [44, 34, 116, 34, 58]]) ++ (exprTokens type)) ++ [.literal [125]])
  | .forallE name binder type body =>
    ((((((((([] ++ [.literal [123, 34, 98, 34, 58]]) ++ (exprTokens body)) ++ [.literal [44, 34, 98, 105, 34, 58]]) ++ (binderTokens binder)) ++ [.literal [44, 34, 107, 34, 58, 34, 102, 111, 114, 97, 108, 108, 34, 44, 34, 110, 34, 58]]) ++ (nameTokens name)) ++ [.literal [44, 34, 116, 34, 58]]) ++ (exprTokens type)) ++ [.literal [125]])
  | .letE name type value body =>
    ((((((((([] ++ [.literal [123, 34, 98, 34, 58]]) ++ (exprTokens body)) ++ [.literal [44, 34, 107, 34, 58, 34, 108, 101, 116, 34, 44, 34, 110, 34, 58]]) ++ (nameTokens name)) ++ [.literal [44, 34, 116, 34, 58]]) ++ (exprTokens type)) ++ [.literal [44, 34, 118, 34, 58]]) ++ (exprTokens value)) ++ [.literal [125]])
  | .projection name index value =>
    ((((((([] ++ [.literal [123, 34, 101, 34, 58]]) ++ (exprTokens value)) ++ [.literal [44, 34, 105, 34, 58]]) ++ [.number index]) ++ [.literal [44, 34, 107, 34, 58, 34, 112, 114, 111, 106, 34, 44, 34, 110, 34, 58]]) ++ (nameTokens name)) ++ [.literal [125]])


def definitionTokens (decl : PsMinCoreDeclaration) : List Token :=
  ((((((((([] ++ [.literal [123, 34, 100, 101, 99, 108, 97, 114, 97, 116, 105, 111, 110, 34, 58, 123, 34, 104, 34, 58, 123, 34, 104, 34, 58]]) ++ (quotedNumberTokens decl.height)) ++ [.literal [44, 34, 107, 34, 58, 34, 114, 101, 103, 117, 108, 97, 114, 34, 125, 44, 34, 107, 34, 58, 34, 100, 101, 102, 105, 110, 105, 116, 105, 111, 110, 34, 44, 34, 108, 112, 34, 58, 91, 93, 44, 34, 110, 34, 58]]) ++ (nameTokens decl.name)) ++ [.literal [44, 34, 115, 34, 58, 34, 115, 97, 102, 101, 34, 44, 34, 116, 34, 58]]) ++ (exprTokens decl.type)) ++ [.literal [44, 34, 118, 34, 58]]) ++ (exprTokens decl.value)) ++ [.literal [125, 44, 34, 107, 105, 110, 100, 34, 58, 34, 99, 111, 110, 115, 116, 97, 110, 116, 34, 125]])


def constructorTokens (ctor : PsMinRegCoreConstructor) : List Token :=
  ((((([] ++ [.literal [123, 34, 110, 34, 58]]) ++ (nameTokens ctor.name)) ++ [.literal [44, 34, 116, 34, 58]]) ++ (exprTokens ctor.type)) ++ [.literal [125]])


def constructorsTailTokens (constructors : List PsMinRegCoreConstructor) : List Token :=
  match constructors with
  | List.nil => []
  | List.cons ctor rest =>
    ((([] ++ [.literal [44]]) ++ (constructorTokens ctor)) ++ (constructorsTailTokens rest))


def constructorsTokens (constructors : List PsMinRegCoreConstructor) : List Token :=
  match constructors with
  | List.nil => [.literal [91, 93]]
  | List.cons ctor rest =>
    (((([] ++ [.literal [91]]) ++ (constructorTokens ctor)) ++ (constructorsTailTokens rest)) ++ [.literal [93]])


def groupTokens (group : PsMinRegCoreGroup) : List Token :=
  ((((((([] ++ [.literal [123, 34, 100, 101, 99, 108, 97, 114, 97, 116, 105, 111, 110, 34, 58, 123, 34, 108, 112, 34, 58, 91, 93, 44, 34, 110, 112, 34, 58, 48, 44, 34, 116, 115, 34, 58, 91, 123, 34, 99, 115, 34, 58]]) ++ (constructorsTokens group.constructors)) ++ [.literal [44, 34, 110, 34, 58]]) ++ (nameTokens group.name)) ++ [.literal [44, 34, 116, 34, 58]]) ++ (exprTokens group.type)) ++ [.literal [125, 93, 125, 44, 34, 107, 105, 110, 100, 34, 58, 34, 105, 110, 100, 117, 99, 116, 105, 118, 101, 34, 125]])


def entryTokens (entry : PsMinRegCoreEntry) : List Token :=
  match entry with
  | .definition decl => (definitionTokens decl)
  | .inductiveE group => (groupTokens group)


def entriesTailTokens (entries : List PsMinRegCoreEntry) : List Token :=
  match entries with
  | List.nil => []
  | List.cons entry rest =>
    ((([] ++ [.literal [44]]) ++ (entryTokens entry)) ++ (entriesTailTokens rest))


def entriesTokens (entries : List PsMinRegCoreEntry) : List Token :=
  match entries with
  | List.nil => [.literal [91, 93]]
  | List.cons entry rest =>
    (((([] ++ [.literal [91]]) ++ (entryTokens entry)) ++ (entriesTailTokens rest)) ++ [.literal [93]])


def packetTokens (entries : List PsMinRegCoreEntry) : List Token :=
  ((([] ++ [.literal [123, 34, 97, 100, 109, 105, 115, 115, 105, 111, 110, 115, 34, 58]]) ++ (entriesTokens entries)) ++ [.literal [44, 34, 102, 111, 114, 109, 97, 116, 34, 58, 34, 112, 114, 111, 111, 102, 115, 99, 114, 105, 112, 116, 45, 99, 104, 101, 99, 107, 101, 100, 45, 97, 100, 109, 105, 115, 115, 105, 111, 110, 115, 34, 44, 34, 118, 101, 114, 115, 105, 111, 110, 34, 58, 50, 125]])

theorem quotedNumber_recognizes (expected : Nat) :
    Recognizes (quotedNumberTokens expected) (psMinRegByteQuotedNumber expected) := by
  change Recognizes (((([] ++ [.literal [34]]) ++ [.number expected]) ++ [.literal [34]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [34] byteTail0)) (fun byteTail1 => psMinRegByteNumber expected byteTail1)) (fun byteTail2 => psMinRegByteLiteral [34] byteTail2))
  repeat' first
    | apply recognizes_then
    | exact recognizes_empty
    | exact recognizes_literal _
    | exact recognizes_number _

theorem text_recognizes (text : List Nat) :
    Recognizes (textTokens text) (psMinRegByteText text) := by
  change Recognizes (((([] ++ [.literal [34]]) ++ [.literal text]) ++ [.literal [34]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [34] byteTail0)) (fun byteTail1 => psMinRegByteLiteral text byteTail1)) (fun byteTail2 => psMinRegByteLiteral [34] byteTail2))
  repeat' first
    | apply recognizes_then
    | exact recognizes_empty
    | exact recognizes_literal _
    | exact recognizes_number _
    | exact quotedNumber_recognizes _

theorem name_recognizes (name : PsMinCoreName) :
    Recognizes (nameTokens name) (psMinRegByteName name) := by
  induction name with
  | anonymous =>
    change Recognizes ([.literal [123, 34, 107, 34, 58, 34, 97, 34, 125]]) (fun bytes => psMinRegByteLiteral [123, 34, 107, 34, 58, 34, 97, 34, 125] bytes)
    repeat' first
      | apply recognizes_then
      | exact recognizes_empty
      | exact recognizes_literal _
      | exact recognizes_number _
      | exact quotedNumber_recognizes _
      | exact text_recognizes _
  | str parent text ih =>
    change Recognizes (((((([] ++ [.literal [123, 34, 107, 34, 58, 34, 115, 34, 44, 34, 112, 34, 58]]) ++ (nameTokens parent)) ++ [.literal [44, 34, 118, 34, 58]]) ++ (textTokens text)) ++ [.literal [125]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 107, 34, 58, 34, 115, 34, 44, 34, 112, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteName parent byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 118, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteText text byteTail3)) (fun byteTail4 => psMinRegByteLiteral [125] byteTail4))
    repeat' first
      | apply recognizes_then
      | exact recognizes_empty
      | exact recognizes_literal _
      | exact recognizes_number _
      | exact quotedNumber_recognizes _
      | exact text_recognizes _
      | exact ih
  | num parent value ih =>
    change Recognizes (((((([] ++ [.literal [123, 34, 107, 34, 58, 34, 110, 34, 44, 34, 112, 34, 58]]) ++ (nameTokens parent)) ++ [.literal [44, 34, 118, 34, 58]]) ++ (quotedNumberTokens value)) ++ [.literal [125]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 107, 34, 58, 34, 110, 34, 44, 34, 112, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteName parent byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 118, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteQuotedNumber value byteTail3)) (fun byteTail4 => psMinRegByteLiteral [125] byteTail4))
    repeat' first
      | apply recognizes_then
      | exact recognizes_empty
      | exact recognizes_literal _
      | exact recognizes_number _
      | exact quotedNumber_recognizes _
      | exact text_recognizes _
      | exact ih

theorem level_recognizes (level : Nat) :
    Recognizes (levelTokens level) (psMinRegByteLevel level) := by
  induction level with
  | zero =>
    change Recognizes ([.literal [123, 34, 107, 34, 58, 34, 122, 34, 125]]) (fun bytes => psMinRegByteLiteral [123, 34, 107, 34, 58, 34, 122, 34, 125] bytes)
    repeat' first
      | apply recognizes_then
      | exact recognizes_empty
      | exact recognizes_literal _
      | exact recognizes_number _
      | exact quotedNumber_recognizes _
      | exact text_recognizes _
      | exact name_recognizes _
  | succ rest ih =>
    change Recognizes (((([] ++ [.literal [123, 34, 107, 34, 58, 34, 115, 34, 44, 34, 111, 34, 58]]) ++ (levelTokens rest)) ++ [.literal [125]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 107, 34, 58, 34, 115, 34, 44, 34, 111, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteLevel rest byteTail1)) (fun byteTail2 => psMinRegByteLiteral [125] byteTail2))
    repeat' first
      | apply recognizes_then
      | exact recognizes_empty
      | exact recognizes_literal _
      | exact recognizes_number _
      | exact quotedNumber_recognizes _
      | exact text_recognizes _
      | exact name_recognizes _
      | exact ih

theorem levelsTail_recognizes (levels : List Nat) :
    Recognizes (levelsTailTokens levels) (psMinRegByteLevelsTail levels) := by
  induction levels with
  | nil =>
    change Recognizes ([]) (fun bytes => Option.some bytes)
    repeat' first
      | apply recognizes_then
      | exact recognizes_empty
      | exact recognizes_literal _
      | exact recognizes_number _
      | exact quotedNumber_recognizes _
      | exact text_recognizes _
      | exact name_recognizes _
      | exact level_recognizes _
  | cons level rest ih =>
    change Recognizes (((([] ++ [.literal [44]]) ++ (levelTokens level)) ++ (levelsTailTokens rest))) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [44] byteTail0)) (fun byteTail1 => psMinRegByteLevel level byteTail1)) (fun byteTail2 => psMinRegByteLevelsTail rest byteTail2))
    repeat' first
      | apply recognizes_then
      | exact recognizes_empty
      | exact recognizes_literal _
      | exact recognizes_number _
      | exact quotedNumber_recognizes _
      | exact text_recognizes _
      | exact name_recognizes _
      | exact level_recognizes _
      | exact ih

theorem levels_recognizes (levels : List Nat) :
    Recognizes (levelsTokens levels) (psMinRegByteLevels levels) := by
  cases levels with
  | nil =>
    change Recognizes ([.literal [91, 93]]) (fun bytes => psMinRegByteLiteral [91, 93] bytes)
    repeat' first
      | apply recognizes_then
      | exact recognizes_empty
      | exact recognizes_literal _
      | exact recognizes_number _
      | exact quotedNumber_recognizes _
      | exact text_recognizes _
      | exact name_recognizes _
      | exact level_recognizes _
      | exact levelsTail_recognizes _
  | cons level rest =>
    change Recognizes ((((([] ++ [.literal [91]]) ++ (levelTokens level)) ++ (levelsTailTokens rest)) ++ [.literal [93]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [91] byteTail0)) (fun byteTail1 => psMinRegByteLevel level byteTail1)) (fun byteTail2 => psMinRegByteLevelsTail rest byteTail2)) (fun byteTail3 => psMinRegByteLiteral [93] byteTail3))
    repeat' first
      | apply recognizes_then
      | exact recognizes_empty
      | exact recognizes_literal _
      | exact recognizes_number _
      | exact quotedNumber_recognizes _
      | exact text_recognizes _
      | exact name_recognizes _
      | exact level_recognizes _
      | exact levelsTail_recognizes _

theorem binder_recognizes (binder : Nat) :
    Recognizes (binderTokens binder) (psMinRegByteBinder binder) := by
  cases binder with
  | zero => exact recognizes_literal _
  | succ first => cases first with
    | zero => exact recognizes_literal _
    | succ second => cases second with
      | zero => exact recognizes_literal _
      | succ third => cases third with
        | zero => exact recognizes_literal _
        | succ rest =>
          intro bytes tail checked
          change (none : Option (List Nat)) = some tail at checked
          cases checked

theorem expr_recognizes (fuel : Nat) (expr : PsMinCoreExpr) :
    Recognizes (exprTokens expr) (psMinRegByteExpr fuel expr) := by
  induction fuel generalizing expr with
  | zero =>
    intro bytes rest checked
    change (none : Option (List Nat)) = some rest at checked
    cases checked
  | succ fuel ih =>
    cases expr with
    | bvar index =>
      change Recognizes (((([] ++ [.literal [123, 34, 105, 34, 58]]) ++ [.number index]) ++ [.literal [44, 34, 107, 34, 58, 34, 98, 34, 125]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 105, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteNumber index byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 107, 34, 58, 34, 98, 34, 125] byteTail2))
      repeat' first
        | apply recognizes_then
        | exact recognizes_empty
        | exact recognizes_literal _
        | exact recognizes_number _
        | exact quotedNumber_recognizes _
        | exact text_recognizes _
        | exact name_recognizes _
        | exact level_recognizes _
        | exact levelsTail_recognizes _
        | exact levels_recognizes _
        | exact binder_recognizes _
        | exact ih _
    | natural value =>
      change Recognizes (((([] ++ [.literal [123, 34, 107, 34, 58, 34, 110, 97, 116, 34, 44, 34, 118, 34, 58]]) ++ (quotedNumberTokens value)) ++ [.literal [125]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 107, 34, 58, 34, 110, 97, 116, 34, 44, 34, 118, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteQuotedNumber value byteTail1)) (fun byteTail2 => psMinRegByteLiteral [125] byteTail2))
      repeat' first
        | apply recognizes_then
        | exact recognizes_empty
        | exact recognizes_literal _
        | exact recognizes_number _
        | exact quotedNumber_recognizes _
        | exact text_recognizes _
        | exact name_recognizes _
        | exact level_recognizes _
        | exact levelsTail_recognizes _
        | exact levels_recognizes _
        | exact binder_recognizes _
        | exact ih _
    | sort level =>
      change Recognizes (((([] ++ [.literal [123, 34, 107, 34, 58, 34, 115, 111, 114, 116, 34, 44, 34, 108, 34, 58]]) ++ (levelTokens level)) ++ [.literal [125]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 107, 34, 58, 34, 115, 111, 114, 116, 34, 44, 34, 108, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteLevel level byteTail1)) (fun byteTail2 => psMinRegByteLiteral [125] byteTail2))
      repeat' first
        | apply recognizes_then
        | exact recognizes_empty
        | exact recognizes_literal _
        | exact recognizes_number _
        | exact quotedNumber_recognizes _
        | exact text_recognizes _
        | exact name_recognizes _
        | exact level_recognizes _
        | exact levelsTail_recognizes _
        | exact levels_recognizes _
        | exact binder_recognizes _
        | exact ih _
    | constant name levels =>
      change Recognizes (((((([] ++ [.literal [123, 34, 107, 34, 58, 34, 99, 111, 110, 115, 116, 34, 44, 34, 108, 115, 34, 58]]) ++ (levelsTokens levels)) ++ [.literal [44, 34, 110, 34, 58]]) ++ (nameTokens name)) ++ [.literal [125]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 107, 34, 58, 34, 99, 111, 110, 115, 116, 34, 44, 34, 108, 115, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteLevels levels byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 110, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteName name byteTail3)) (fun byteTail4 => psMinRegByteLiteral [125] byteTail4))
      repeat' first
        | apply recognizes_then
        | exact recognizes_empty
        | exact recognizes_literal _
        | exact recognizes_number _
        | exact quotedNumber_recognizes _
        | exact text_recognizes _
        | exact name_recognizes _
        | exact level_recognizes _
        | exact levelsTail_recognizes _
        | exact levels_recognizes _
        | exact binder_recognizes _
        | exact ih _
    | app fn arg =>
      change Recognizes (((((([] ++ [.literal [123, 34, 97, 34, 58]]) ++ (exprTokens arg)) ++ [.literal [44, 34, 102, 34, 58]]) ++ (exprTokens fn)) ++ [.literal [44, 34, 107, 34, 58, 34, 97, 112, 112, 34, 125]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 97, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteExpr fuel arg byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 102, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteExpr fuel fn byteTail3)) (fun byteTail4 => psMinRegByteLiteral [44, 34, 107, 34, 58, 34, 97, 112, 112, 34, 125] byteTail4))
      repeat' first
        | apply recognizes_then
        | exact recognizes_empty
        | exact recognizes_literal _
        | exact recognizes_number _
        | exact quotedNumber_recognizes _
        | exact text_recognizes _
        | exact name_recognizes _
        | exact level_recognizes _
        | exact levelsTail_recognizes _
        | exact levels_recognizes _
        | exact binder_recognizes _
        | exact ih _
    | lam name binder type body =>
      change Recognizes (((((((((([] ++ [.literal [123, 34, 98, 34, 58]]) ++ (exprTokens body)) ++ [.literal [44, 34, 98, 105, 34, 58]]) ++ (binderTokens binder)) ++ [.literal [44, 34, 107, 34, 58, 34, 108, 97, 109, 34, 44, 34, 110, 34, 58]]) ++ (nameTokens name)) ++ [.literal [44, 34, 116, 34, 58]]) ++ (exprTokens type)) ++ [.literal [125]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 98, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteExpr fuel body byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 98, 105, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteBinder binder byteTail3)) (fun byteTail4 => psMinRegByteLiteral [44, 34, 107, 34, 58, 34, 108, 97, 109, 34, 44, 34, 110, 34, 58] byteTail4)) (fun byteTail5 => psMinRegByteName name byteTail5)) (fun byteTail6 => psMinRegByteLiteral [44, 34, 116, 34, 58] byteTail6)) (fun byteTail7 => psMinRegByteExpr fuel type byteTail7)) (fun byteTail8 => psMinRegByteLiteral [125] byteTail8))
      repeat' first
        | apply recognizes_then
        | exact recognizes_empty
        | exact recognizes_literal _
        | exact recognizes_number _
        | exact quotedNumber_recognizes _
        | exact text_recognizes _
        | exact name_recognizes _
        | exact level_recognizes _
        | exact levelsTail_recognizes _
        | exact levels_recognizes _
        | exact binder_recognizes _
        | exact ih _
    | forallE name binder type body =>
      change Recognizes (((((((((([] ++ [.literal [123, 34, 98, 34, 58]]) ++ (exprTokens body)) ++ [.literal [44, 34, 98, 105, 34, 58]]) ++ (binderTokens binder)) ++ [.literal [44, 34, 107, 34, 58, 34, 102, 111, 114, 97, 108, 108, 34, 44, 34, 110, 34, 58]]) ++ (nameTokens name)) ++ [.literal [44, 34, 116, 34, 58]]) ++ (exprTokens type)) ++ [.literal [125]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 98, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteExpr fuel body byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 98, 105, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteBinder binder byteTail3)) (fun byteTail4 => psMinRegByteLiteral [44, 34, 107, 34, 58, 34, 102, 111, 114, 97, 108, 108, 34, 44, 34, 110, 34, 58] byteTail4)) (fun byteTail5 => psMinRegByteName name byteTail5)) (fun byteTail6 => psMinRegByteLiteral [44, 34, 116, 34, 58] byteTail6)) (fun byteTail7 => psMinRegByteExpr fuel type byteTail7)) (fun byteTail8 => psMinRegByteLiteral [125] byteTail8))
      repeat' first
        | apply recognizes_then
        | exact recognizes_empty
        | exact recognizes_literal _
        | exact recognizes_number _
        | exact quotedNumber_recognizes _
        | exact text_recognizes _
        | exact name_recognizes _
        | exact level_recognizes _
        | exact levelsTail_recognizes _
        | exact levels_recognizes _
        | exact binder_recognizes _
        | exact ih _
    | letE name type value body =>
      change Recognizes (((((((((([] ++ [.literal [123, 34, 98, 34, 58]]) ++ (exprTokens body)) ++ [.literal [44, 34, 107, 34, 58, 34, 108, 101, 116, 34, 44, 34, 110, 34, 58]]) ++ (nameTokens name)) ++ [.literal [44, 34, 116, 34, 58]]) ++ (exprTokens type)) ++ [.literal [44, 34, 118, 34, 58]]) ++ (exprTokens value)) ++ [.literal [125]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 98, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteExpr fuel body byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 107, 34, 58, 34, 108, 101, 116, 34, 44, 34, 110, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteName name byteTail3)) (fun byteTail4 => psMinRegByteLiteral [44, 34, 116, 34, 58] byteTail4)) (fun byteTail5 => psMinRegByteExpr fuel type byteTail5)) (fun byteTail6 => psMinRegByteLiteral [44, 34, 118, 34, 58] byteTail6)) (fun byteTail7 => psMinRegByteExpr fuel value byteTail7)) (fun byteTail8 => psMinRegByteLiteral [125] byteTail8))
      repeat' first
        | apply recognizes_then
        | exact recognizes_empty
        | exact recognizes_literal _
        | exact recognizes_number _
        | exact quotedNumber_recognizes _
        | exact text_recognizes _
        | exact name_recognizes _
        | exact level_recognizes _
        | exact levelsTail_recognizes _
        | exact levels_recognizes _
        | exact binder_recognizes _
        | exact ih _
    | projection name index value =>
      change Recognizes (((((((([] ++ [.literal [123, 34, 101, 34, 58]]) ++ (exprTokens value)) ++ [.literal [44, 34, 105, 34, 58]]) ++ [.number index]) ++ [.literal [44, 34, 107, 34, 58, 34, 112, 114, 111, 106, 34, 44, 34, 110, 34, 58]]) ++ (nameTokens name)) ++ [.literal [125]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 101, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteExpr fuel value byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 105, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteNumber index byteTail3)) (fun byteTail4 => psMinRegByteLiteral [44, 34, 107, 34, 58, 34, 112, 114, 111, 106, 34, 44, 34, 110, 34, 58] byteTail4)) (fun byteTail5 => psMinRegByteName name byteTail5)) (fun byteTail6 => psMinRegByteLiteral [125] byteTail6))
      repeat' first
        | apply recognizes_then
        | exact recognizes_empty
        | exact recognizes_literal _
        | exact recognizes_number _
        | exact quotedNumber_recognizes _
        | exact text_recognizes _
        | exact name_recognizes _
        | exact level_recognizes _
        | exact levelsTail_recognizes _
        | exact levels_recognizes _
        | exact binder_recognizes _
        | exact ih _

theorem definition_recognizes (decl : PsMinCoreDeclaration) :
    Recognizes (definitionTokens decl) (psMinRegByteDefinition decl) := by
  change Recognizes (((((((((([] ++ [.literal [123, 34, 100, 101, 99, 108, 97, 114, 97, 116, 105, 111, 110, 34, 58, 123, 34, 104, 34, 58, 123, 34, 104, 34, 58]]) ++ (quotedNumberTokens decl.height)) ++ [.literal [44, 34, 107, 34, 58, 34, 114, 101, 103, 117, 108, 97, 114, 34, 125, 44, 34, 107, 34, 58, 34, 100, 101, 102, 105, 110, 105, 116, 105, 111, 110, 34, 44, 34, 108, 112, 34, 58, 91, 93, 44, 34, 110, 34, 58]]) ++ (nameTokens decl.name)) ++ [.literal [44, 34, 115, 34, 58, 34, 115, 97, 102, 101, 34, 44, 34, 116, 34, 58]]) ++ (exprTokens decl.type)) ++ [.literal [44, 34, 118, 34, 58]]) ++ (exprTokens decl.value)) ++ [.literal [125, 44, 34, 107, 105, 110, 100, 34, 58, 34, 99, 111, 110, 115, 116, 97, 110, 116, 34, 125]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 100, 101, 99, 108, 97, 114, 97, 116, 105, 111, 110, 34, 58, 123, 34, 104, 34, 58, 123, 34, 104, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteQuotedNumber decl.height byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 107, 34, 58, 34, 114, 101, 103, 117, 108, 97, 114, 34, 125, 44, 34, 107, 34, 58, 34, 100, 101, 102, 105, 110, 105, 116, 105, 111, 110, 34, 44, 34, 108, 112, 34, 58, 91, 93, 44, 34, 110, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteName decl.name byteTail3)) (fun byteTail4 => psMinRegByteLiteral [44, 34, 115, 34, 58, 34, 115, 97, 102, 101, 34, 44, 34, 116, 34, 58] byteTail4)) (fun byteTail5 => psMinRegByteExpr 256 decl.type byteTail5)) (fun byteTail6 => psMinRegByteLiteral [44, 34, 118, 34, 58] byteTail6)) (fun byteTail7 => psMinRegByteExpr 256 decl.value byteTail7)) (fun byteTail8 => psMinRegByteLiteral [125, 44, 34, 107, 105, 110, 100, 34, 58, 34, 99, 111, 110, 115, 116, 97, 110, 116, 34, 125] byteTail8))
  repeat' first
    | apply recognizes_then
    | exact recognizes_empty
    | exact recognizes_literal _
    | exact recognizes_number _
    | exact quotedNumber_recognizes _
    | exact text_recognizes _
    | exact name_recognizes _
    | exact level_recognizes _
    | exact levelsTail_recognizes _
    | exact levels_recognizes _
    | exact binder_recognizes _
    | exact expr_recognizes _ _

theorem constructor_recognizes (ctor : PsMinRegCoreConstructor) :
    Recognizes (constructorTokens ctor) (psMinRegByteConstructor ctor) := by
  change Recognizes (((((([] ++ [.literal [123, 34, 110, 34, 58]]) ++ (nameTokens ctor.name)) ++ [.literal [44, 34, 116, 34, 58]]) ++ (exprTokens ctor.type)) ++ [.literal [125]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 110, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteName ctor.name byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 116, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteExpr 256 ctor.type byteTail3)) (fun byteTail4 => psMinRegByteLiteral [125] byteTail4))
  repeat' first
    | apply recognizes_then
    | exact recognizes_empty
    | exact recognizes_literal _
    | exact recognizes_number _
    | exact quotedNumber_recognizes _
    | exact text_recognizes _
    | exact name_recognizes _
    | exact level_recognizes _
    | exact levelsTail_recognizes _
    | exact levels_recognizes _
    | exact binder_recognizes _
    | exact expr_recognizes _ _
    | exact definition_recognizes _

theorem constructorsTail_recognizes (constructors : List PsMinRegCoreConstructor) :
    Recognizes (constructorsTailTokens constructors) (psMinRegByteConstructorsTail constructors) := by
  induction constructors with
  | nil =>
    change Recognizes ([]) (fun bytes => Option.some bytes)
    repeat' first
      | apply recognizes_then
      | exact recognizes_empty
      | exact recognizes_literal _
      | exact recognizes_number _
      | exact quotedNumber_recognizes _
      | exact text_recognizes _
      | exact name_recognizes _
      | exact level_recognizes _
      | exact levelsTail_recognizes _
      | exact levels_recognizes _
      | exact binder_recognizes _
      | exact expr_recognizes _ _
      | exact definition_recognizes _
      | exact constructor_recognizes _
  | cons ctor rest ih =>
    change Recognizes (((([] ++ [.literal [44]]) ++ (constructorTokens ctor)) ++ (constructorsTailTokens rest))) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [44] byteTail0)) (fun byteTail1 => psMinRegByteConstructor ctor byteTail1)) (fun byteTail2 => psMinRegByteConstructorsTail rest byteTail2))
    repeat' first
      | apply recognizes_then
      | exact recognizes_empty
      | exact recognizes_literal _
      | exact recognizes_number _
      | exact quotedNumber_recognizes _
      | exact text_recognizes _
      | exact name_recognizes _
      | exact level_recognizes _
      | exact levelsTail_recognizes _
      | exact levels_recognizes _
      | exact binder_recognizes _
      | exact expr_recognizes _ _
      | exact definition_recognizes _
      | exact constructor_recognizes _
      | exact ih

theorem constructors_recognizes (constructors : List PsMinRegCoreConstructor) :
    Recognizes (constructorsTokens constructors) (psMinRegByteConstructors constructors) := by
  cases constructors with
  | nil =>
    change Recognizes ([.literal [91, 93]]) (fun bytes => psMinRegByteLiteral [91, 93] bytes)
    repeat' first
      | apply recognizes_then
      | exact recognizes_empty
      | exact recognizes_literal _
      | exact recognizes_number _
      | exact quotedNumber_recognizes _
      | exact text_recognizes _
      | exact name_recognizes _
      | exact level_recognizes _
      | exact levelsTail_recognizes _
      | exact levels_recognizes _
      | exact binder_recognizes _
      | exact expr_recognizes _ _
      | exact definition_recognizes _
      | exact constructor_recognizes _
      | exact constructorsTail_recognizes _
  | cons ctor rest =>
    change Recognizes ((((([] ++ [.literal [91]]) ++ (constructorTokens ctor)) ++ (constructorsTailTokens rest)) ++ [.literal [93]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [91] byteTail0)) (fun byteTail1 => psMinRegByteConstructor ctor byteTail1)) (fun byteTail2 => psMinRegByteConstructorsTail rest byteTail2)) (fun byteTail3 => psMinRegByteLiteral [93] byteTail3))
    repeat' first
      | apply recognizes_then
      | exact recognizes_empty
      | exact recognizes_literal _
      | exact recognizes_number _
      | exact quotedNumber_recognizes _
      | exact text_recognizes _
      | exact name_recognizes _
      | exact level_recognizes _
      | exact levelsTail_recognizes _
      | exact levels_recognizes _
      | exact binder_recognizes _
      | exact expr_recognizes _ _
      | exact definition_recognizes _
      | exact constructor_recognizes _
      | exact constructorsTail_recognizes _

theorem group_recognizes (group : PsMinRegCoreGroup) :
    Recognizes (groupTokens group) (psMinRegByteGroup group) := by
  change Recognizes (((((((([] ++ [.literal [123, 34, 100, 101, 99, 108, 97, 114, 97, 116, 105, 111, 110, 34, 58, 123, 34, 108, 112, 34, 58, 91, 93, 44, 34, 110, 112, 34, 58, 48, 44, 34, 116, 115, 34, 58, 91, 123, 34, 99, 115, 34, 58]]) ++ (constructorsTokens group.constructors)) ++ [.literal [44, 34, 110, 34, 58]]) ++ (nameTokens group.name)) ++ [.literal [44, 34, 116, 34, 58]]) ++ (exprTokens group.type)) ++ [.literal [125, 93, 125, 44, 34, 107, 105, 110, 100, 34, 58, 34, 105, 110, 100, 117, 99, 116, 105, 118, 101, 34, 125]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 100, 101, 99, 108, 97, 114, 97, 116, 105, 111, 110, 34, 58, 123, 34, 108, 112, 34, 58, 91, 93, 44, 34, 110, 112, 34, 58, 48, 44, 34, 116, 115, 34, 58, 91, 123, 34, 99, 115, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteConstructors group.constructors byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 110, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteName group.name byteTail3)) (fun byteTail4 => psMinRegByteLiteral [44, 34, 116, 34, 58] byteTail4)) (fun byteTail5 => psMinRegByteExpr 256 group.type byteTail5)) (fun byteTail6 => psMinRegByteLiteral [125, 93, 125, 44, 34, 107, 105, 110, 100, 34, 58, 34, 105, 110, 100, 117, 99, 116, 105, 118, 101, 34, 125] byteTail6))
  repeat' first
    | apply recognizes_then
    | exact recognizes_empty
    | exact recognizes_literal _
    | exact recognizes_number _
    | exact quotedNumber_recognizes _
    | exact text_recognizes _
    | exact name_recognizes _
    | exact level_recognizes _
    | exact levelsTail_recognizes _
    | exact levels_recognizes _
    | exact binder_recognizes _
    | exact expr_recognizes _ _
    | exact definition_recognizes _
    | exact constructor_recognizes _
    | exact constructorsTail_recognizes _
    | exact constructors_recognizes _

theorem entry_recognizes (entry : PsMinRegCoreEntry) :
    Recognizes (entryTokens entry) (psMinRegByteEntry entry) := by
  cases entry with
  | definition decl =>
    change Recognizes ((definitionTokens decl)) (fun bytes => psMinRegByteDefinition decl bytes)
    repeat' first
      | apply recognizes_then
      | exact recognizes_empty
      | exact recognizes_literal _
      | exact recognizes_number _
      | exact quotedNumber_recognizes _
      | exact text_recognizes _
      | exact name_recognizes _
      | exact level_recognizes _
      | exact levelsTail_recognizes _
      | exact levels_recognizes _
      | exact binder_recognizes _
      | exact expr_recognizes _ _
      | exact definition_recognizes _
      | exact constructor_recognizes _
      | exact constructorsTail_recognizes _
      | exact constructors_recognizes _
      | exact group_recognizes _
  | inductiveE group =>
    change Recognizes ((groupTokens group)) (fun bytes => psMinRegByteGroup group bytes)
    repeat' first
      | apply recognizes_then
      | exact recognizes_empty
      | exact recognizes_literal _
      | exact recognizes_number _
      | exact quotedNumber_recognizes _
      | exact text_recognizes _
      | exact name_recognizes _
      | exact level_recognizes _
      | exact levelsTail_recognizes _
      | exact levels_recognizes _
      | exact binder_recognizes _
      | exact expr_recognizes _ _
      | exact definition_recognizes _
      | exact constructor_recognizes _
      | exact constructorsTail_recognizes _
      | exact constructors_recognizes _
      | exact group_recognizes _

theorem entriesTail_recognizes (entries : List PsMinRegCoreEntry) :
    Recognizes (entriesTailTokens entries) (psMinRegByteEntriesTail entries) := by
  induction entries with
  | nil =>
    change Recognizes ([]) (fun bytes => Option.some bytes)
    repeat' first
      | apply recognizes_then
      | exact recognizes_empty
      | exact recognizes_literal _
      | exact recognizes_number _
      | exact quotedNumber_recognizes _
      | exact text_recognizes _
      | exact name_recognizes _
      | exact level_recognizes _
      | exact levelsTail_recognizes _
      | exact levels_recognizes _
      | exact binder_recognizes _
      | exact expr_recognizes _ _
      | exact definition_recognizes _
      | exact constructor_recognizes _
      | exact constructorsTail_recognizes _
      | exact constructors_recognizes _
      | exact group_recognizes _
      | exact entry_recognizes _
  | cons entry rest ih =>
    change Recognizes (((([] ++ [.literal [44]]) ++ (entryTokens entry)) ++ (entriesTailTokens rest))) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [44] byteTail0)) (fun byteTail1 => psMinRegByteEntry entry byteTail1)) (fun byteTail2 => psMinRegByteEntriesTail rest byteTail2))
    repeat' first
      | apply recognizes_then
      | exact recognizes_empty
      | exact recognizes_literal _
      | exact recognizes_number _
      | exact quotedNumber_recognizes _
      | exact text_recognizes _
      | exact name_recognizes _
      | exact level_recognizes _
      | exact levelsTail_recognizes _
      | exact levels_recognizes _
      | exact binder_recognizes _
      | exact expr_recognizes _ _
      | exact definition_recognizes _
      | exact constructor_recognizes _
      | exact constructorsTail_recognizes _
      | exact constructors_recognizes _
      | exact group_recognizes _
      | exact entry_recognizes _
      | exact ih

theorem entries_recognizes (entries : List PsMinRegCoreEntry) :
    Recognizes (entriesTokens entries) (psMinRegByteEntries entries) := by
  cases entries with
  | nil =>
    change Recognizes ([.literal [91, 93]]) (fun bytes => psMinRegByteLiteral [91, 93] bytes)
    repeat' first
      | apply recognizes_then
      | exact recognizes_empty
      | exact recognizes_literal _
      | exact recognizes_number _
      | exact quotedNumber_recognizes _
      | exact text_recognizes _
      | exact name_recognizes _
      | exact level_recognizes _
      | exact levelsTail_recognizes _
      | exact levels_recognizes _
      | exact binder_recognizes _
      | exact expr_recognizes _ _
      | exact definition_recognizes _
      | exact constructor_recognizes _
      | exact constructorsTail_recognizes _
      | exact constructors_recognizes _
      | exact group_recognizes _
      | exact entry_recognizes _
      | exact entriesTail_recognizes _
  | cons entry rest =>
    change Recognizes ((((([] ++ [.literal [91]]) ++ (entryTokens entry)) ++ (entriesTailTokens rest)) ++ [.literal [93]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [91] byteTail0)) (fun byteTail1 => psMinRegByteEntry entry byteTail1)) (fun byteTail2 => psMinRegByteEntriesTail rest byteTail2)) (fun byteTail3 => psMinRegByteLiteral [93] byteTail3))
    repeat' first
      | apply recognizes_then
      | exact recognizes_empty
      | exact recognizes_literal _
      | exact recognizes_number _
      | exact quotedNumber_recognizes _
      | exact text_recognizes _
      | exact name_recognizes _
      | exact level_recognizes _
      | exact levelsTail_recognizes _
      | exact levels_recognizes _
      | exact binder_recognizes _
      | exact expr_recognizes _ _
      | exact definition_recognizes _
      | exact constructor_recognizes _
      | exact constructorsTail_recognizes _
      | exact constructors_recognizes _
      | exact group_recognizes _
      | exact entry_recognizes _
      | exact entriesTail_recognizes _

theorem packet_recognizes (entries : List PsMinRegCoreEntry) :
    Recognizes (packetTokens entries) (psMinRegBytePacket entries) := by
  change Recognizes (((([] ++ [.literal [123, 34, 97, 100, 109, 105, 115, 115, 105, 111, 110, 115, 34, 58]]) ++ (entriesTokens entries)) ++ [.literal [44, 34, 102, 111, 114, 109, 97, 116, 34, 58, 34, 112, 114, 111, 111, 102, 115, 99, 114, 105, 112, 116, 45, 99, 104, 101, 99, 107, 101, 100, 45, 97, 100, 109, 105, 115, 115, 105, 111, 110, 115, 34, 44, 34, 118, 101, 114, 115, 105, 111, 110, 34, 58, 50, 125]])) (fun bytes => psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 97, 100, 109, 105, 115, 115, 105, 111, 110, 115, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteEntries entries byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 102, 111, 114, 109, 97, 116, 34, 58, 34, 112, 114, 111, 111, 102, 115, 99, 114, 105, 112, 116, 45, 99, 104, 101, 99, 107, 101, 100, 45, 97, 100, 109, 105, 115, 115, 105, 111, 110, 115, 34, 44, 34, 118, 101, 114, 115, 105, 111, 110, 34, 58, 50, 125] byteTail2))
  repeat' first
    | apply recognizes_then
    | exact recognizes_empty
    | exact recognizes_literal _
    | exact recognizes_number _
    | exact quotedNumber_recognizes _
    | exact text_recognizes _
    | exact name_recognizes _
    | exact level_recognizes _
    | exact levelsTail_recognizes _
    | exact levels_recognizes _
    | exact binder_recognizes _
    | exact expr_recognizes _ _
    | exact definition_recognizes _
    | exact constructor_recognizes _
    | exact constructorsTail_recognizes _
    | exact constructors_recognizes _
    | exact group_recognizes _
    | exact entry_recognizes _
    | exact entriesTail_recognizes _
    | exact entries_recognizes _

theorem decode_has_wire_derivation (bytes : List Nat) (candidate source : List PsMinRegCoreEntry)
    (h : psMinRegCoreDecodeCertificate bytes candidate = some source) :
    source = candidate ∧ psMinRegCoreEntriesValid 512 source = true ∧ Wire (packetTokens source) bytes := by
  obtain ⟨identity, bounded, valid, exactPacket⟩ := decode_preserves_source bytes candidate source h
  obtain ⟨consumed, grammar, equation⟩ := packet_recognizes source bytes [] exactPacket
  have same : bytes = consumed := by simpa only [List.append_nil] using equation
  rw [same]
  exact ⟨identity, valid, grammar⟩

#print axioms quotedNumber_recognizes
#print axioms text_recognizes
#print axioms name_recognizes
#print axioms level_recognizes
#print axioms levelsTail_recognizes
#print axioms levels_recognizes
#print axioms binder_recognizes
#print axioms expr_recognizes
#print axioms definition_recognizes
#print axioms constructor_recognizes
#print axioms constructorsTail_recognizes
#print axioms constructors_recognizes
#print axioms group_recognizes
#print axioms entry_recognizes
#print axioms entriesTail_recognizes
#print axioms entries_recognizes
#print axioms packet_recognizes
#print axioms decode_has_wire_derivation
end Ps.MinKernel.RegularIngressEncoding
