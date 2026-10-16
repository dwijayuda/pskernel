import Ps.Elab.Binders

-- A checked header is independent of its eventual logical strategy. It owns
-- the real parameter telescope and result type, without a provisional global
-- declaration. Source and already-checked Core producers share this record.
structure PsElabCheckedHeader where
  name : PsName
  context : PsElabContext
  bindersRev : List PsElabTypedBinder
  openType : PsExpr
  type : PsExpr

inductive PsElabPreDefinitionStrategy where
  | total
  | «partial»
  | wellFounded
  | fixedpoint

-- Numeric local identities are scoped by their actual source owner. Section
-- captures share one owner; a parent's header locals remain distinct from
-- equal-numbered locals belonging to another parent. These labels describe
-- capture provenance; consumers still recheck every actual Core domain.
structure PsElabPreDefinitionCapture where
  owner : Option PsName
  id : Nat

inductive PsElabPreDefinitionSource where
  | declaration (source : PsSyntaxDeclaration)
  | localDefinition (parent : PsName) (source : PsSyntaxLocalDefinition)

def psElabPreDefinitionDeclarationExplicitPartial : PsSyntaxDeclaration → Bool
  | .whereDeclaration parent _ _ => psElabPreDefinitionDeclarationExplicitPartial parent
  | .partialDefinition .. => true
  | _ => false

def psElabPreDefinitionSourceExplicitPartial : PsElabPreDefinitionSource → Bool
  | .declaration source => psElabPreDefinitionDeclarationExplicitPartial source
  | .localDefinition .. => false

-- Pinned MutualDef.getModifiersForLetRecs derives this intent from every
-- original main header, before SCC partition. A disconnected partial main
-- therefore also governs a recursive helper belonging to a plain main.
def psElabPreDefinitionHasPartialMain (sources : List PsElabPreDefinitionSource) : Bool :=
  sources.any psElabPreDefinitionSourceExplicitPartial

def psElabPreDefinitionLocalStrategy (mainSources : List PsElabPreDefinitionSource)
    (source : PsSyntaxLocalDefinition) : Except PsElabError PsElabPreDefinitionStrategy := do
  let inheritedPartial := psElabPreDefinitionHasPartialMain mainSources
  -- Native inherited operational intent precedes unused local hints. The
  -- source still retains its suffix; it is not an explicit partial head and
  -- an ignored hint supplies no well-founded or fixed-point evidence.
  if inheritedPartial then return .partial
  match source.recursion with
  | some (.total _) => return .wellFounded
  | some (.fixedpoint _) => return .fixedpoint
  | none => return .total

-- `type` is closed. `value` has only the block's full peer locals free; its
-- leading lambdas are the capture prefix followed by the actual source
-- header. Lambdas belonging to the result are deliberately not counted.
-- Closing is performed by the source owner before dependency partitioning.
structure PsElabPreDefinition where
  name : PsName
  peerId : Nat
  type : PsExpr
  value : PsExpr
  captures : List PsElabPreDefinitionCapture
  sourceHeaderCount : Nat
  strategy : PsElabPreDefinitionStrategy
  source : PsElabPreDefinitionSource
  sourceIndex : Nat
  isPrivate : Bool
  registration : Option PsSyntaxRegistration := none
  sourceInfo : PsElabSourceInfo

-- The context contains only the complete closed-type full peer bindings.
-- Levels have already been closed over the original whole source block,
-- before any SCC can discard a disconnected member or its body-only level.
structure PsElabPreDefinitionBlock where
  context : PsElabContext
  levelNames : List PsName
  members : List PsElabPreDefinition
  span : PsSourceSpan

def psElabPreDefinitionCaptureEq (left right : PsElabPreDefinitionCapture) : Bool :=
  left.id == right.id && (match left.owner, right.owner with
    | none, none => true
    | some left, some right => psNameEq left right
    | _, _ => false)

def psElabPreDefinitionHeaderCount (member : PsElabPreDefinition) : Nat :=
  member.captures.length + member.sourceHeaderCount
