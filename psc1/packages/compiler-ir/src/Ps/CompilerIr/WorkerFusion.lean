import Ps.CompilerIr.Validate
import Ps.Foundation.StringSet

-- Bounded typed IR optimization. Original declarations remain available for
-- every escaping/partial use. A successful wrapper still rechecks exact data.
namespace Ps.Internal.WorkerFusion

def foldExcept {alpha state : Type} (step : state -> alpha -> Except String state)
    (values : List alpha) (current : state) : Except String state :=
  match values with
  | List.nil => Except.ok current
  | List.cons value rest =>
      match step current value with
      | Except.error error => Except.error error
      | Except.ok next => foldExcept step rest next

def mapOption {alpha beta : Type} (convert : alpha -> Option beta) (values : List alpha) :
    Option (List beta) :=
  match values with
  | List.nil => Option.some []
  | List.cons value rest =>
      match convert value with
      | Option.none => Option.none
      | Option.some head =>
          match mapOption convert rest with
          | Option.none => Option.none
          | Option.some tail => Option.some (List.cons head tail)

def drop {alpha : Type} (count : Nat) (values : List alpha) : List alpha :=
  match count with
  | Nat.zero => values
  | Nat.succ remaining =>
      match values with
      | List.nil => List.nil
      | List.cons _ rest => drop remaining rest

def seen (names : List String) (name : String) : Bool :=
  psListAny (fun (value : String) => psStringEq value name) names

def addParameters (used : PsStringSet) (values : List PsVerifiedIrParameter) : PsStringSet :=
  match values with
  | List.nil => used
  | List.cons value rest => addParameters (psStringSetInsert used value.name) rest

def names (fuel : Nat) (expression : PsVerifiedIrExpr) (used : PsStringSet) : Except String PsStringSet :=
  match fuel with
  | Nat.zero => Except.error "PSC1_WORKER_FUSION_TRAVERSAL_EXHAUSTED"
  | Nat.succ remaining =>
      let visit : PsStringSet -> PsVerifiedIrExpr -> Except String PsStringSet :=
        fun (current : PsStringSet) (child : PsVerifiedIrExpr) => names remaining child current;
      let fields : PsStringSet -> Prod String PsVerifiedIrExpr -> Except String PsStringSet :=
        fun (current : PsStringSet) (field : Prod String PsVerifiedIrExpr) =>
          names remaining field.snd (psStringSetInsert current field.fst);
      match expression with
      | PsVerifiedIrExpr.literal _ => Except.ok used
      | PsVerifiedIrExpr.var name => Except.ok (psStringSetInsert used name)
      | PsVerifiedIrExpr.intrinsic _ _ arguments => foldExcept visit arguments used
      | PsVerifiedIrExpr.lambda parameters _ body => names remaining body (addParameters used parameters)
      | PsVerifiedIrExpr.call fn _ arguments =>
          match names remaining fn used with
          | Except.error error => Except.error error
          | Except.ok next => foldExcept visit arguments next
      | PsVerifiedIrExpr.letE name _ value body =>
          match names remaining value (psStringSetInsert used name) with
          | Except.error error => Except.error error
          | Except.ok next => names remaining body next
      | PsVerifiedIrExpr.ifE condition yes no => foldExcept visit [condition, yes, no] used
      | PsVerifiedIrExpr.record owner _ values => foldExcept fields values (psStringSetInsert used owner)
      | PsVerifiedIrExpr.projection owner _ target field =>
          names remaining target (psStringSetInsert (psStringSetInsert used owner) field)
      | PsVerifiedIrExpr.constructor owner constructor _ values =>
          foldExcept fields values (psStringSetInsert (psStringSetInsert used owner) constructor)
      | PsVerifiedIrExpr.matchE owner _ major alternatives =>
          let branch : PsStringSet -> Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr) ->
              Except String PsStringSet :=
            fun (current : PsStringSet)
                (alternative : Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) =>
              let bindingNames : List String := psListMap
                (fun (binding : PsVerifiedIrMatchBinding) => binding.name) alternative.snd.fst;
              let withBindings : PsStringSet := psStringSetFromListWorker bindingNames
                (psStringSetInsert current alternative.fst);
              names remaining alternative.snd.snd withBindings;
          match names remaining major (psStringSetInsert used owner) with
          | Except.error error => Except.error error
          | Except.ok next => foldExcept branch alternatives next

def declarationNames (used : PsStringSet) (declaration : PsVerifiedIrDeclaration) :
    Except String PsStringSet :=
  names 4096 declaration.body (addParameters (psStringSetInsert used declaration.name) declaration.parameters)

def fresh (fuel : Nat) (used : PsStringSet) (base : String) : Except String String :=
  match fuel with
  | Nat.zero => Except.error "PSC1_WORKER_FUSION_FRESH_NAME_EXHAUSTED"
  | Nat.succ remaining =>
      if psStringSetContains used base then fresh remaining used (String.Internal.append base "_")
      else Except.ok base

structure Arrow where
  arguments : List PsVerifiedIrType
  result : PsVerifiedIrType

def arrow (fuel : Nat) (type : PsVerifiedIrType) : Option Arrow :=
  match fuel with
  | Nat.zero => Option.none
  | Nat.succ remaining =>
      match type with
      | PsVerifiedIrType.function parameters result =>
          match arrow remaining result with
          | Option.none => Option.none
          | Option.some tail => Option.some (Arrow.mk (psListAppend parameters tail.arguments) tail.result)
      | _ => Option.some (Arrow.mk [] type)

structure NewParameters where
  used : PsStringSet
  parameters : List PsVerifiedIrParameter

def newParameters (types : List PsVerifiedIrType) (index : Nat) (used : PsStringSet) :
    Except String NewParameters :=
  match types with
  | List.nil => Except.ok (NewParameters.mk used [])
  | List.cons type rest =>
      match fresh 4096 used (String.Internal.append "__pscWorkerArg$" (psNatToString index)) with
      | Except.error error => Except.error error
      | Except.ok name =>
          match newParameters rest (Nat.succ index) (psStringSetInsert used name) with
          | Except.error error => Except.error error
          | Except.ok tail =>
              Except.ok (NewParameters.mk tail.used (List.cons (PsVerifiedIrParameter.mk name type) tail.parameters))

-- Only total administrative work can move across a later argument evaluation.
-- Exact Nat addition/subtraction/equality are total on already computed inputs.
-- Calls, projections and indexing never qualify here.
def administrative (fuel : Nat) (locals : List String) (expression : PsVerifiedIrExpr) : Bool :=
  match fuel with
  | Nat.zero => false
  | Nat.succ remaining =>
      match expression with
      | PsVerifiedIrExpr.var name => seen locals name
      | PsVerifiedIrExpr.literal _ => true
      | PsVerifiedIrExpr.intrinsic operation types arguments =>
          let allowed : Bool :=
            match operation with
            | PsVerifiedIrIntrinsic.natEq => true
            | PsVerifiedIrIntrinsic.natAdd => true
            | PsVerifiedIrIntrinsic.natSub => true
            | _ => false;
          allowed && psListIsEmpty types &&
            !(psListAny (fun (value : PsVerifiedIrExpr) => !administrative remaining locals value) arguments)
      | _ => false

def bindParameters (parameters : List PsVerifiedIrParameter) (arguments : List PsVerifiedIrExpr)
    (body : PsVerifiedIrExpr) : Option PsVerifiedIrExpr :=
  match parameters with
  | List.nil => Option.some body
  | List.cons parameter rest =>
      match arguments with
      | List.nil => Option.none
      | List.cons argument others =>
          match bindParameters rest others body with
          | Option.none => Option.none
          | Option.some nested =>
              Option.some (PsVerifiedIrExpr.letE parameter.name parameter.type argument nested)

-- Beta application is represented by typed lets rather than textual substitution.
-- Original lambda shadowing/capture scopes therefore remain exactly nested.
def sink (fuel : Nat) (locals : List String) (expression : PsVerifiedIrExpr) (arguments : List PsVerifiedIrExpr) :
    Option PsVerifiedIrExpr :=
  match fuel with
  | Nat.zero => if psListIsEmpty arguments then Option.some expression else Option.none
  | Nat.succ remaining =>
      if psListIsEmpty arguments then Option.some expression
      else
        match expression with
        | PsVerifiedIrExpr.lambda parameters _ body =>
            let count : Nat := psListLength parameters;
            if Nat.blt (psListLength arguments) count || Nat.beq count 0 then Option.none
            else
              match sink remaining (psListAppend (psListMap (fun (parameter : PsVerifiedIrParameter) => parameter.name) parameters) locals) body (drop count arguments) with
              | Option.none => Option.none
              | Option.some nested => bindParameters parameters (psListTake count arguments) nested
        | PsVerifiedIrExpr.letE name type value body =>
            if administrative 64 locals value then
              match sink remaining (List.cons name locals) body arguments with
              | Option.none => Option.none
              | Option.some nested => Option.some (PsVerifiedIrExpr.letE name type value nested)
            else Option.none
        | PsVerifiedIrExpr.ifE condition yes no =>
            if administrative 64 locals condition then
              match sink remaining locals yes arguments with
              | Option.none => Option.none
              | Option.some left =>
                  match sink remaining locals no arguments with
                  | Option.none => Option.none
                  | Option.some right => Option.some (PsVerifiedIrExpr.ifE condition left right)
            else Option.none
        | PsVerifiedIrExpr.matchE owner types major alternatives =>
            if administrative 64 locals major then
              let branch :
                  Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr) ->
                  Option (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) :=
                fun (alternative : Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) =>
                  match sink remaining (psListAppend (psListMap (fun (binding : PsVerifiedIrMatchBinding) => binding.name) alternative.snd.fst) locals) alternative.snd.snd arguments with
                  | Option.none => Option.none
                  | Option.some body =>
                      Option.some (Prod.mk alternative.fst (Prod.mk alternative.snd.fst body));
              let collect :
                  List (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) ->
                  Option (List (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr))) :=
                mapOption branch;
              match collect alternatives with
              | Option.none => Option.none
              | Option.some values => Option.some (PsVerifiedIrExpr.matchE owner types major values)
            else Option.none
        | _ => Option.none

structure Spec where
  original : PsVerifiedIrDeclaration
  companion : String
  parameters : List PsVerifiedIrParameter
  result : PsVerifiedIrType
  body : PsVerifiedIrExpr

structure Plan where
  used : PsStringSet
  specs : List Spec

def addSpec (plan : Plan) (declaration : PsVerifiedIrDeclaration) : Except String Plan :=
  if !(psListIsEmpty declaration.typeParameters) || psListIsEmpty declaration.parameters then Except.ok plan
  else
    match arrow 64 declaration.resultType with
    | Option.none => Except.ok plan
    | Option.some signature =>
        if psListIsEmpty signature.arguments || Nat.blt 64 (Nat.add (psListLength declaration.parameters) (psListLength signature.arguments)) then Except.ok plan
        else
          match fresh 4096 plan.used (String.Internal.append declaration.name "$worker") with
          | Except.error error => Except.error error
          | Except.ok name =>
              match newParameters signature.arguments 0 (psStringSetInsert plan.used name) with
              | Except.error error => Except.error error
              | Except.ok extra =>
                  let arguments : List PsVerifiedIrExpr := psListMap
                    (fun (parameter : PsVerifiedIrParameter) => PsVerifiedIrExpr.var parameter.name) extra.parameters;
                  match sink 4096 (psListMap (fun (parameter : PsVerifiedIrParameter) => parameter.name) declaration.parameters) declaration.body arguments with
                  | Option.none => Except.ok plan
                  | Option.some body =>
                      let parameters : List PsVerifiedIrParameter :=
                        psListAppend declaration.parameters extra.parameters;
                      Except.ok (Plan.mk extra.used
                        (List.cons (Spec.mk declaration name parameters signature.result body) plan.specs))

def lookup (specs : List Spec) (name : String) : Option Spec :=
  match specs with
  | List.nil => Option.none
  | List.cons spec rest => if psStringEq spec.original.name name then Option.some spec else lookup rest name

structure Spine where
  name : String
  arguments : List PsVerifiedIrExpr

def spine (fuel : Nat) (expression : PsVerifiedIrExpr) : Option Spine :=
  match fuel with
  | Nat.zero => Option.none
  | Nat.succ remaining =>
      match expression with
      | PsVerifiedIrExpr.var name => Option.some (Spine.mk name [])
      | PsVerifiedIrExpr.call fn types arguments =>
          if !(psListIsEmpty types) then Option.none
          else
            match spine remaining fn with
            | Option.none => Option.none
            | Option.some inner => Option.some (Spine.mk inner.name (psListAppend inner.arguments arguments))
      | _ => Option.none

structure Alias where
  name : String
  spec : Spec
  captures : List PsVerifiedIrExpr

def aliasLookup (aliases : List Alias) (name : String) : Option Alias :=
  match aliases with
  | List.nil => Option.none
  | List.cons alias rest => if psStringEq alias.name name then Option.some alias else aliasLookup rest name

def hide (names : List String) (aliases : List Alias) : List Alias :=
  match aliases with
  | List.nil => []
  | List.cons alias rest =>
      let others : List Alias := hide names rest;
      if seen names alias.name then others else List.cons alias others

structure Resolved where
  spec : Spec
  arguments : List PsVerifiedIrExpr

def resolve (plan : Plan) (locals : List String) (aliases : List Alias)
    (expression : PsVerifiedIrExpr) : Option Resolved :=
  match spine 4096 expression with
  | Option.none => Option.none
  | Option.some found =>
      match aliasLookup aliases found.name with
      | Option.some alias =>
          Option.some (Resolved.mk alias.spec (psListAppend alias.captures found.arguments))
      | Option.none =>
          if seen locals found.name then Option.none
          else
            match lookup plan.specs found.name with
            | Option.none => Option.none
            | Option.some spec => Option.some (Resolved.mk spec found.arguments)

def valueOperand (expression : PsVerifiedIrExpr) : Bool :=
  match expression with
  | PsVerifiedIrExpr.var _ => true
  | PsVerifiedIrExpr.literal _ => true
  | _ => false

-- Overapproximate mentions, including shadowed occurrences, so only genuinely
-- dead aliases are removed. Exhaustion conservatively keeps the old binding.
def mentions (fuel : Nat) (name : String) (expression : PsVerifiedIrExpr) : Bool :=
  match fuel with
  | Nat.zero => true
  | Nat.succ remaining =>
      let visit : PsVerifiedIrExpr -> Bool :=
        fun (value : PsVerifiedIrExpr) => mentions remaining name value;
      match expression with
      | PsVerifiedIrExpr.literal _ => false
      | PsVerifiedIrExpr.var value => psStringEq value name
      | PsVerifiedIrExpr.intrinsic _ _ arguments => psListAny visit arguments
      | PsVerifiedIrExpr.lambda _ _ body => visit body
      | PsVerifiedIrExpr.call fn _ arguments => visit fn || psListAny visit arguments
      | PsVerifiedIrExpr.letE _ _ value body => visit value || visit body
      | PsVerifiedIrExpr.ifE condition yes no => visit condition || visit yes || visit no
      | PsVerifiedIrExpr.record _ _ fields =>
          psListAny (fun (field : Prod String PsVerifiedIrExpr) => visit field.snd) fields
      | PsVerifiedIrExpr.projection _ _ target _ => visit target
      | PsVerifiedIrExpr.constructor _ _ _ fields =>
          psListAny (fun (field : Prod String PsVerifiedIrExpr) => visit field.snd) fields
      | PsVerifiedIrExpr.matchE _ _ major alternatives =>
          visit major || psListAny
            (fun (alternative : Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) =>
              visit alternative.snd.snd) alternatives

def aliasNameValues (add : PsStringSet -> PsVerifiedIrExpr -> PsStringSet)
    (values : List PsVerifiedIrExpr) (used : PsStringSet) : PsStringSet :=
  match values with
  | List.nil => used
  | List.cons value rest => aliasNameValues add rest (add used value)

def aliasNames (aliases : List Alias) (used : PsStringSet) : PsStringSet :=
  match aliases with
  | List.nil => used
  | List.cons alias rest =>
      let add : PsStringSet -> PsVerifiedIrExpr -> PsStringSet :=
        fun (current : PsStringSet) (expression : PsVerifiedIrExpr) =>
          match expression with
          | PsVerifiedIrExpr.var name => psStringSetInsert current name
          | _ => current;
      let fold : List PsVerifiedIrExpr -> PsStringSet -> PsStringSet := aliasNameValues add;
      aliasNames rest (fold alias.captures used)

structure Captures where
  used : PsStringSet
  bindings : List (Prod PsVerifiedIrParameter PsVerifiedIrExpr)
  arguments : List PsVerifiedIrExpr

def captureArguments (parameters : List PsVerifiedIrParameter) (arguments : List PsVerifiedIrExpr)
    (depth index : Nat) (used : PsStringSet) : Except String Captures :=
  match arguments with
  | List.nil => Except.ok (Captures.mk used [] [])
  | List.cons value rest =>
      match parameters with
      | List.nil => Except.error "PSC1_WORKER_FUSION_CAPTURE_ARITY"
      | List.cons parameter others =>
          let base : String := String.Internal.append "__pscWorkerCapture$"
            (String.Internal.append (psNatToString depth) (String.Internal.append "$" (psNatToString index)));
          match fresh 4096 used base with
          | Except.error error => Except.error error
          | Except.ok name =>
              match captureArguments others rest depth (Nat.succ index) (psStringSetInsert used name) with
              | Except.error error => Except.error error
              | Except.ok tail =>
                  Except.ok (Captures.mk tail.used
                    (List.cons (Prod.mk (PsVerifiedIrParameter.mk name parameter.type) value) tail.bindings)
                    (List.cons (PsVerifiedIrExpr.var name) tail.arguments))

def captureLets (bindings : List (Prod PsVerifiedIrParameter PsVerifiedIrExpr)) (body : PsVerifiedIrExpr) :
    PsVerifiedIrExpr :=
  match bindings with
  | List.nil => body
  | List.cons binding rest =>
      PsVerifiedIrExpr.letE binding.fst.name binding.fst.type binding.snd (captureLets rest body)

def rewriteCall (visit : PsVerifiedIrExpr -> Except String PsVerifiedIrExpr)
    (fn : PsVerifiedIrExpr) (types : List PsVerifiedIrType) (arguments : List PsVerifiedIrExpr) :
    Except String PsVerifiedIrExpr :=
  match visit fn with
  | Except.error error => Except.error error
  | Except.ok head =>
      match psListMapExcept visit arguments with
      | Except.error error => Except.error error
      | Except.ok values => Except.ok (PsVerifiedIrExpr.call head types values)

def rewriteLet (visit visitBody : PsVerifiedIrExpr -> Except String PsVerifiedIrExpr)
    (name : String) (type : PsVerifiedIrType) (value body : PsVerifiedIrExpr) :
    Except String PsVerifiedIrExpr :=
  match visit value with
  | Except.error error => Except.error error
  | Except.ok first =>
      match visitBody body with
      | Except.error error => Except.error error
      | Except.ok second => Except.ok (PsVerifiedIrExpr.letE name type first second)

def rewrite (plan : Plan) (fuel : Nat) (locals : List String) (aliases : List Alias)
    (expression : PsVerifiedIrExpr) : Except String PsVerifiedIrExpr :=
  match fuel with
  | Nat.zero => Except.error "PSC1_WORKER_FUSION_TRAVERSAL_EXHAUSTED"
  | Nat.succ remaining =>
      let visit : PsVerifiedIrExpr -> Except String PsVerifiedIrExpr :=
        fun (value : PsVerifiedIrExpr) => rewrite plan remaining locals aliases value;
      let fields : List (Prod String PsVerifiedIrExpr) -> Except String (List (Prod String PsVerifiedIrExpr)) :=
        psListMapExcept (fun (field : Prod String PsVerifiedIrExpr) =>
          match visit field.snd with
          | Except.error error => Except.error error
          | Except.ok value => Except.ok (Prod.mk field.fst value));
      match expression with
      | PsVerifiedIrExpr.literal _ => Except.ok expression
      | PsVerifiedIrExpr.var _ => Except.ok expression
      | PsVerifiedIrExpr.intrinsic operation types arguments =>
          match psListMapExcept visit arguments with
          | Except.error error => Except.error error
          | Except.ok values => Except.ok (PsVerifiedIrExpr.intrinsic operation types values)
      | PsVerifiedIrExpr.lambda parameters result body =>
          let names : List String := psListMap
            (fun (parameter : PsVerifiedIrParameter) => parameter.name) parameters;
          match rewrite plan remaining (psListAppend names locals) (hide names aliases) body with
          | Except.error error => Except.error error
          | Except.ok value => Except.ok (PsVerifiedIrExpr.lambda parameters result value)
      | PsVerifiedIrExpr.call fn types arguments =>
          let found : Option Resolved := resolve plan locals aliases expression;
          match found with
          | Option.some selected =>
              if Nat.beq (psListLength selected.arguments) (psListLength selected.spec.parameters) then
                match psListMapExcept visit selected.arguments with
                | Except.error error => Except.error error
                | Except.ok values =>
                    Except.ok (PsVerifiedIrExpr.call (PsVerifiedIrExpr.var selected.spec.companion) [] values)
              else rewriteCall visit fn types arguments
          | Option.none => rewriteCall visit fn types arguments
      | PsVerifiedIrExpr.letE name type value body =>
          let visible : List Alias := hide [name] aliases;
          let found : Option Resolved := resolve plan locals aliases value;
          match found with
          | Option.some selected =>
              let count : Nat := psListLength selected.arguments;
              if Nat.ble (psListLength selected.spec.original.parameters) count &&
                  Nat.blt count (psListLength selected.spec.parameters) &&
                  !(psListAny (fun (argument : PsVerifiedIrExpr) => !valueOperand argument) selected.arguments) then
                match captureArguments selected.spec.parameters selected.arguments remaining 0
                    (aliasNames aliases plan.used) with
                | Except.error error => Except.error error
                | Except.ok captures =>
                    let nextAliases : List Alias :=
                      List.cons (Alias.mk name selected.spec captures.arguments) visible;
                    match rewrite plan remaining (List.cons name locals) nextAliases body with
                    | Except.error error => Except.error error
                    | Except.ok nested =>
                        if mentions 4096 name nested then
                          match visit value with
                          | Except.error error => Except.error error
                          | Except.ok original =>
                              Except.ok (captureLets captures.bindings (PsVerifiedIrExpr.letE name type original nested))
                        else Except.ok (captureLets captures.bindings nested)
              else rewriteLet visit
                (fun (nested : PsVerifiedIrExpr) => rewrite plan remaining (List.cons name locals) visible nested)
                name type value body
          | Option.none => rewriteLet visit
                (fun (nested : PsVerifiedIrExpr) => rewrite plan remaining (List.cons name locals) visible nested)
                name type value body
      | PsVerifiedIrExpr.ifE condition yes no =>
          match visit condition with
          | Except.error error => Except.error error
          | Except.ok test =>
              match visit yes with
              | Except.error error => Except.error error
              | Except.ok left =>
                  match visit no with
                  | Except.error error => Except.error error
                  | Except.ok right => Except.ok (PsVerifiedIrExpr.ifE test left right)
      | PsVerifiedIrExpr.record owner types values =>
          match fields values with
          | Except.error error => Except.error error
          | Except.ok lowered => Except.ok (PsVerifiedIrExpr.record owner types lowered)
      | PsVerifiedIrExpr.projection owner types target field =>
          match visit target with
          | Except.error error => Except.error error
          | Except.ok lowered => Except.ok (PsVerifiedIrExpr.projection owner types lowered field)
      | PsVerifiedIrExpr.constructor owner constructor types values =>
          match fields values with
          | Except.error error => Except.error error
          | Except.ok lowered => Except.ok (PsVerifiedIrExpr.constructor owner constructor types lowered)
      | PsVerifiedIrExpr.matchE owner types major alternatives =>
          let branch :
              Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr) ->
              Except String (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) :=
            fun (alternative : Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) =>
              let names : List String := psListMap
                (fun (binding : PsVerifiedIrMatchBinding) => binding.name) alternative.snd.fst;
              match rewrite plan remaining (psListAppend names locals) (hide names aliases) alternative.snd.snd with
              | Except.error error => Except.error error
              | Except.ok value => Except.ok (Prod.mk alternative.fst (Prod.mk alternative.snd.fst value));
          match visit major with
          | Except.error error => Except.error error
          | Except.ok value =>
              match psListMapExcept branch alternatives with
              | Except.error error => Except.error error
              | Except.ok values => Except.ok (PsVerifiedIrExpr.matchE owner types value values)

def rewriteDeclaration (plan : Plan) (declaration : PsVerifiedIrDeclaration) :
    Except String PsVerifiedIrDeclaration :=
  let locals : List String := psListMap
    (fun (parameter : PsVerifiedIrParameter) => parameter.name) declaration.parameters;
  match rewrite plan 4096 locals [] declaration.body with
  | Except.error error => Except.error error
  | Except.ok body =>
      Except.ok (PsVerifiedIrDeclaration.mk declaration.name declaration.typeParameters
        declaration.parameters declaration.resultType body)

def companionDeclaration (plan : Plan) (spec : Spec) : Except String PsVerifiedIrDeclaration :=
  rewriteDeclaration plan
    (PsVerifiedIrDeclaration.mk spec.companion [] spec.parameters spec.result spec.body)

def run (module : PsVerifiedIrModule) : Except String PsVerifiedIrModule :=
  let imported : List String := psListMap
    (fun (value : PsVerifiedIrExternalImport) => value.localName) module.imports;
  let structures : List String := psListMap
    (fun (value : PsVerifiedIrStructure) => value.name) module.structures;
  let inductives : List String := psListMap
    (fun (value : PsVerifiedIrInductive) => value.name) module.inductives;
  let initial : PsStringSet := psStringSetFromList (psListAppend imported (psListAppend structures inductives));
  match foldExcept declarationNames module.declarations initial with
  | Except.error error => Except.error error
  | Except.ok used =>
      match foldExcept addSpec module.declarations (Plan.mk used []) with
      | Except.error error => Except.error error
      | Except.ok plan =>
          match psListMapExcept (rewriteDeclaration plan) module.declarations with
          | Except.error error => Except.error error
          | Except.ok declarations =>
              match psListMapExcept (companionDeclaration plan) (psListReverse plan.specs) with
              | Except.error error => Except.error error
              | Except.ok companions =>
                  Except.ok (PsVerifiedIrModule.mk module.imports module.structures module.inductives
                    (psListAppend declarations companions))

end Ps.Internal.WorkerFusion

-- Input/output wrappers are data: independently recheck their exact raw modules.
-- This is bounded typing evidence, not a semantic-preservation theorem.
def psFuseClosedWorkers (input : PsValidatedIrModule) : Except String PsValidatedIrModule :=
  match psStrictValidateModule input.raw with
  | Except.error _ => Except.error "PSC1_WORKER_FUSION_INPUT_INVALID"
  | Except.ok checked =>
      match Ps.Internal.WorkerFusion.run checked.raw with
      | Except.error error => Except.error error
      | Except.ok raw =>
          match psStrictValidateModule raw with
          | Except.error _ => Except.error "PSC1_WORKER_FUSION_OUTPUT_INVALID"
          | Except.ok output => Except.ok output
