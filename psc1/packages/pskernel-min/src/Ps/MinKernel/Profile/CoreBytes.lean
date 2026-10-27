-- Exact-byte certificate validation. Parser proposals are untrusted.
-- No String/Char, generic JSON value, IO, proof or official provider is imported.
import Ps.MinKernel.Profile.OperationalCheck

inductive PsMinCoreName where
  | anonymous
  | str (parent : PsMinCoreName) (bytes : List Nat)
  | num (parent : PsMinCoreName) (value : Nat)

inductive PsMinCoreExpr where
  | bvar (index : Nat)
  | constant (name : PsMinCoreName) (levels : List Nat)
  | app (fn arg : PsMinCoreExpr)
  | lam (name : PsMinCoreName) (binder : Nat) (type body : PsMinCoreExpr)
  | forallE (name : PsMinCoreName) (binder : Nat) (type body : PsMinCoreExpr)
  | letE (name : PsMinCoreName) (type value body : PsMinCoreExpr)
  | natural (value : Nat)
  | sort (level : Nat)
  | projection (name : PsMinCoreName) (index : Nat) (value : PsMinCoreExpr)

structure PsMinCoreDeclaration where
  name : PsMinCoreName
  height : Nat
  type : PsMinCoreExpr
  value : PsMinCoreExpr

def psMinByteAppend (left : List Nat) : List Nat -> List Nat :=
  match left with
  | List.nil => fun right => right
  | List.cons head tail => fun right => let smaller : List Nat -> List Nat := psMinByteAppend tail;
      List.cons head (smaller right)

def psMinByteEq (left : List Nat) : List Nat -> Bool :=
  match left with
  | List.nil => fun right => match right with
    | List.nil => true
    | List.cons _ _ => false
  | List.cons head tail => fun right => match right with
    | List.nil => false
    | List.cons other rest => let smaller : List Nat -> Bool := psMinByteEq tail;
      if Nat.beq head other then smaller rest else false

def psMinByteLengthAtMost (fuel : Nat) : List Nat -> Bool :=
  match fuel with
  | Nat.zero => fun bytes => match bytes with
    | List.nil => true
    | List.cons _ _ => false
  | Nat.succ rest => fun bytes => match bytes with
    | List.nil => true
    | List.cons _ tail =>
      let smaller : List Nat -> Bool := psMinByteLengthAtMost rest; smaller tail

def psMinCoreNameEq (left : PsMinCoreName) : PsMinCoreName -> Bool :=
  match left with
  | .anonymous => fun right => match right with
    | .anonymous => true
    | _ => false
  | .str parent bytes => fun right =>
    let smaller : PsMinCoreName -> Bool := psMinCoreNameEq parent;
    match right with
    | .str other rest => if smaller other then psMinByteEq bytes rest else false
    | _ => false
  | .num parent value => fun right =>
    let smaller : PsMinCoreName -> Bool := psMinCoreNameEq parent;
    match right with
    | .num other number => if smaller other then Nat.beq value number else false
    | _ => false

def psMinCoreSafeText (fuel : Nat) : List Nat -> Bool :=
  match fuel with
  | Nat.zero => fun bytes => match bytes with
    | List.nil => true
    | List.cons _ _ => false
  | Nat.succ rest => fun bytes => match bytes with
    | List.nil => true
    | List.cons head tail =>
      if Nat.blt head 32 then false else
      if Nat.blt 126 head then false else
      if Nat.beq head 34 then false else
      if Nat.beq head 92 then false else
      let smaller : List Nat -> Bool := psMinCoreSafeText rest; smaller tail

def psMinCoreNameValid (fuel : Nat) : PsMinCoreName -> Bool :=
  match fuel with
  | Nat.zero => fun _ => false
  | Nat.succ rest => fun name =>
    let smaller : PsMinCoreName -> Bool := psMinCoreNameValid rest;
    match name with
    | .anonymous => true
    | .str parent bytes => if psMinCoreSafeText 128 bytes then smaller parent else false
    | .num parent value => if Nat.blt value 4096 then smaller parent else false

def psMinCoreExprEq (fuel : Nat) : PsMinCoreExpr -> PsMinCoreExpr -> Bool :=
  match fuel with
  | Nat.zero => fun _ _ => false
  | Nat.succ rest => fun left right =>
    let smaller : PsMinCoreExpr -> PsMinCoreExpr -> Bool := psMinCoreExprEq rest;
    match left with
    | .sort level => match right with
      | .sort other => Nat.beq level other
      | _ => false
    | .projection name index value => match right with
      | .projection other position major => if psMinCoreNameEq name other then
          if Nat.beq index position then smaller value major else false else false
      | _ => false
    | .bvar index => match right with
      | .bvar other => Nat.beq index other
      | _ => false
    | .natural value => match right with
      | .natural other => Nat.beq value other
      | _ => false
    | .constant name levels => match right with
      | .constant other ls => if psMinCoreNameEq name other then psMinByteEq levels ls else false
      | _ => false
    | .app fn arg => match right with
      | .app f a => if smaller fn f then smaller arg a else false
      | _ => false
    | .lam name binder type body => match right with
      | .lam n bi t b => if psMinCoreNameEq name n then if Nat.beq binder bi then
          if smaller type t then smaller body b else false else false else false
      | _ => false
    | .forallE name binder type body => match right with
      | .forallE n bi t b => if psMinCoreNameEq name n then if Nat.beq binder bi then
          if smaller type t then smaller body b else false else false else false
      | _ => false
    | .letE name type value body => match right with
      | .letE n t v b => if psMinCoreNameEq name n then if smaller type t then
          if smaller value v then smaller body b else false else false else false
      | _ => false

def psMinCoreLevelsValid (levels : List Nat) : Bool :=
  match levels with
  | List.nil => true
  | List.cons level rest => if Nat.blt level 2 then psMinCoreLevelsValid rest else false

def psMinCoreExprValid (fuel : Nat) : PsMinCoreExpr -> Bool :=
  match fuel with
  | Nat.zero => fun _ => false
  | Nat.succ rest => fun expr =>
    let smaller : PsMinCoreExpr -> Bool := psMinCoreExprValid rest;
    match expr with
    | .sort level => Nat.blt level 2
    | .projection name index value => if psMinCoreNameValid 16 name then
        if Nat.blt index 4096 then smaller value else false else false
    | .bvar index => Nat.blt index 4096
    | .natural value => Nat.blt value 4096
    | .constant name levels => if psMinCoreNameValid 16 name then
        if psMinByteLengthAtMost 1 levels then psMinCoreLevelsValid levels else false else false
    | .app fn arg => if smaller fn then smaller arg else false
    | .lam name binder type body => if psMinCoreNameValid 16 name then if Nat.blt binder 4 then
        if smaller type then smaller body else false else false else false
    | .forallE name binder type body => if psMinCoreNameValid 16 name then if Nat.blt binder 4 then
        if smaller type then smaller body else false else false else false
    | .letE name type value body => if psMinCoreNameValid 16 name then if smaller type then
        if smaller value then smaller body else false else false else false

def psMinByteJoinTail (separator : List Nat) (values : List (List Nat)) : List Nat :=
  match values with
  | List.nil => List.nil
  | List.cons value rest => psMinByteAppend separator (psMinByteAppend value (psMinByteJoinTail separator rest))

def psMinByteJoin (start separator stop : List Nat) (values : List (List Nat)) : List Nat :=
  match values with
  | List.nil => psMinByteAppend start stop
  | List.cons value rest => psMinByteAppend start (psMinByteAppend value
      (psMinByteAppend (psMinByteJoinTail separator rest) stop))

def psMinDecimalIncrement (digits : List Nat) : List Nat :=
  match digits with
  | List.nil => [1]
  | List.cons digit rest => if Nat.beq digit 9 then List.cons 0 (psMinDecimalIncrement rest)
      else List.cons (Nat.succ digit) rest

def psMinDecimalDigits (value : Nat) : List Nat :=
  match value with
  | Nat.zero => [0]
  | Nat.succ rest => psMinDecimalIncrement (psMinDecimalDigits rest)

def psMinDecimalBytes (digits : List Nat) : List Nat :=
  match digits with
  | List.nil => List.nil
  | List.cons digit rest => psMinByteAppend (psMinDecimalBytes rest) [Nat.add 48 digit]

def psMinCoreNumber (value : Nat) : List Nat := psMinDecimalBytes (psMinDecimalDigits value)

def psMinCoreQuote (bytes : List Nat) : List Nat := psMinByteAppend [34] (psMinByteAppend bytes [34])

def psMinCoreEncodeName (name : PsMinCoreName) : List Nat :=
  match name with
  | .anonymous => [123, 34, 107, 34, 58, 34, 97, 34, 125]
  | .str parent bytes => psMinByteJoin [123] [44] [125] [psMinByteAppend [34, 107, 34, 58] ([34, 115, 34]), psMinByteAppend [34, 112, 34, 58] (psMinCoreEncodeName parent), psMinByteAppend [34, 118, 34, 58] (psMinCoreQuote bytes)]
  | .num parent value => psMinByteJoin [123] [44] [125] [psMinByteAppend [34, 107, 34, 58] ([34, 110, 34]), psMinByteAppend [34, 112, 34, 58] (psMinCoreEncodeName parent), psMinByteAppend [34, 118, 34, 58] (psMinCoreQuote (psMinCoreNumber value))]

def psMinCoreEncodeLevel (level : Nat) : List Nat :=
  match level with
  | Nat.zero => [123, 34, 107, 34, 58, 34, 122, 34, 125]
  | Nat.succ rest => psMinByteJoin [123] [44] [125] [psMinByteAppend [34, 107, 34, 58] ([34, 115, 34]), psMinByteAppend [34, 111, 34, 58] (psMinCoreEncodeLevel rest)]

def psMinCoreEncodeLevels (levels : List Nat) : List (List Nat) :=
  match levels with
  | List.nil => List.nil
  | List.cons level rest => List.cons (psMinCoreEncodeLevel level) (psMinCoreEncodeLevels rest)

def psMinCoreBinderBytes (binder : Nat) : List Nat :=
  if Nat.beq binder 0 then [34, 100, 101, 102, 97, 117, 108, 116, 34] else
  if Nat.beq binder 1 then [34, 105, 109, 112, 108, 105, 99, 105, 116, 34] else
  if Nat.beq binder 2 then [34, 115, 116, 114, 105, 99, 116, 73, 109, 112, 108, 105, 99, 105, 116, 34] else [34, 105, 110, 115, 116, 73, 109, 112, 108, 105, 99, 105, 116, 34]

def psMinCoreEncodeExpr (expr : PsMinCoreExpr) : List Nat :=
  match expr with
  | .sort level => psMinByteJoin [123] [44] [125] [psMinByteAppend [34, 107, 34, 58] ([34, 115, 111, 114, 116, 34]), psMinByteAppend [34, 108, 34, 58] (psMinCoreEncodeLevel level)]
  | .projection name index value => psMinByteJoin [123] [44] [125] [psMinByteAppend [34, 101, 34, 58] (psMinCoreEncodeExpr value), psMinByteAppend [34, 105, 34, 58] (psMinCoreNumber index), psMinByteAppend [34, 107, 34, 58] ([34, 112, 114, 111, 106, 34]), psMinByteAppend [34, 110, 34, 58] (psMinCoreEncodeName name)]
  | .bvar index => psMinByteJoin [123] [44] [125] [psMinByteAppend [34, 105, 34, 58] (psMinCoreNumber index), psMinByteAppend [34, 107, 34, 58] ([34, 98, 34])]
  | .natural value => psMinByteJoin [123] [44] [125] [psMinByteAppend [34, 107, 34, 58] ([34, 110, 97, 116, 34]), psMinByteAppend [34, 118, 34, 58] (psMinCoreQuote (psMinCoreNumber value))]
  | .constant name levels => psMinByteJoin [123] [44] [125] [psMinByteAppend [34, 107, 34, 58] ([34, 99, 111, 110, 115, 116, 34]), psMinByteAppend [34, 108, 115, 34, 58] (psMinByteJoin [91] [44] [93] (psMinCoreEncodeLevels levels)), psMinByteAppend [34, 110, 34, 58] (psMinCoreEncodeName name)]
  | .app fn arg => psMinByteJoin [123] [44] [125] [psMinByteAppend [34, 97, 34, 58] (psMinCoreEncodeExpr arg), psMinByteAppend [34, 102, 34, 58] (psMinCoreEncodeExpr fn), psMinByteAppend [34, 107, 34, 58] ([34, 97, 112, 112, 34])]
  | .lam name binder type body => psMinByteJoin [123] [44] [125] [psMinByteAppend [34, 98, 34, 58] (psMinCoreEncodeExpr body), psMinByteAppend [34, 98, 105, 34, 58] (psMinCoreBinderBytes binder), psMinByteAppend [34, 107, 34, 58] ([34, 108, 97, 109, 34]), psMinByteAppend [34, 110, 34, 58] (psMinCoreEncodeName name), psMinByteAppend [34, 116, 34, 58] (psMinCoreEncodeExpr type)]
  | .forallE name binder type body => psMinByteJoin [123] [44] [125] [psMinByteAppend [34, 98, 34, 58] (psMinCoreEncodeExpr body), psMinByteAppend [34, 98, 105, 34, 58] (psMinCoreBinderBytes binder), psMinByteAppend [34, 107, 34, 58] ([34, 102, 111, 114, 97, 108, 108, 34]), psMinByteAppend [34, 110, 34, 58] (psMinCoreEncodeName name), psMinByteAppend [34, 116, 34, 58] (psMinCoreEncodeExpr type)]
  | .letE name type value body => psMinByteJoin [123] [44] [125] [psMinByteAppend [34, 98, 34, 58] (psMinCoreEncodeExpr body), psMinByteAppend [34, 107, 34, 58] ([34, 108, 101, 116, 34]), psMinByteAppend [34, 110, 34, 58] (psMinCoreEncodeName name), psMinByteAppend [34, 116, 34, 58] (psMinCoreEncodeExpr type), psMinByteAppend [34, 118, 34, 58] (psMinCoreEncodeExpr value)]

def psMinCoreEncodeDeclaration (decl : PsMinCoreDeclaration) : List Nat :=
  psMinByteJoin [123] [44] [125] [psMinByteAppend [34, 100, 101, 99, 108, 97, 114, 97, 116, 105, 111, 110, 34, 58] (psMinByteJoin [123] [44] [125] [psMinByteAppend [34, 104, 34, 58] (psMinByteJoin [123] [44] [125] [psMinByteAppend [34, 104, 34, 58] (psMinCoreQuote (psMinCoreNumber decl.height)), psMinByteAppend [34, 107, 34, 58] ([34, 114, 101, 103, 117, 108, 97, 114, 34])]), psMinByteAppend [34, 107, 34, 58] ([34, 100, 101, 102, 105, 110, 105, 116, 105, 111, 110, 34]), psMinByteAppend [34, 108, 112, 34, 58] ([91, 93]), psMinByteAppend [34, 110, 34, 58] (psMinCoreEncodeName decl.name), psMinByteAppend [34, 115, 34, 58] ([34, 115, 97, 102, 101, 34]), psMinByteAppend [34, 116, 34, 58] (psMinCoreEncodeExpr decl.type), psMinByteAppend [34, 118, 34, 58] (psMinCoreEncodeExpr decl.value)]), psMinByteAppend [34, 107, 105, 110, 100, 34, 58] ([34, 99, 111, 110, 115, 116, 97, 110, 116, 34])]

def psMinCoreEncodeDeclarations (decls : List PsMinCoreDeclaration) : List (List Nat) :=
  match decls with
  | List.nil => List.nil
  | List.cons decl rest => List.cons (psMinCoreEncodeDeclaration decl) (psMinCoreEncodeDeclarations rest)

def psMinCoreEncode (decls : List PsMinCoreDeclaration) : List Nat :=
  psMinByteJoin [123] [44] [125] [psMinByteAppend [34, 97, 100, 109, 105, 115, 115, 105, 111, 110, 115, 34, 58] (psMinByteJoin [91] [44] [93] (psMinCoreEncodeDeclarations decls)), psMinByteAppend [34, 102, 111, 114, 109, 97, 116, 34, 58] ([34, 112, 114, 111, 111, 102, 115, 99, 114, 105, 112, 116, 45, 99, 104, 101, 99, 107, 101, 100, 45, 97, 100, 109, 105, 115, 115, 105, 111, 110, 115, 34]), psMinByteAppend [34, 118, 101, 114, 115, 105, 111, 110, 34, 58] ([50])]

def psMinCoreDeclarationsValid (fuel : Nat) : List PsMinCoreDeclaration -> Bool :=
  match fuel with
  | Nat.zero => fun decls => match decls with
    | List.nil => true
    | List.cons _ _ => false
  | Nat.succ rest => fun decls =>
    let smaller : List PsMinCoreDeclaration -> Bool := psMinCoreDeclarationsValid rest;
    match decls with
    | List.nil => true
    | List.cons decl tail => if psMinCoreNameValid 16 decl.name then
        if Nat.blt decl.height 4096 then if psMinCoreExprValid 48 decl.type then
        if psMinCoreExprValid 48 decl.value then smaller tail
        else false else false else false else false

-- Any parser may propose a candidate; success binds *all* original bytes.
-- No JSON parser, numeric coercion, metadata or candidate field is trusted.
def psMinCoreDecodeCertificate (bytes : List Nat) (candidate : List PsMinCoreDeclaration) :
    Option (List PsMinCoreDeclaration) :=
  if psMinByteLengthAtMost 65536 bytes then
    if psMinCoreDeclarationsValid 128 candidate then
      if psMinByteEq bytes (psMinCoreEncode candidate) then Option.some candidate else Option.none
    else Option.none
  else Option.none
