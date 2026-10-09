import Ps.KernelCore.Admission.Inductive.Nested.Admission
import PSC1Kernel.NestedInductive

def psKernelNameToReference
    (name : PsKernelName) : PSC1Kernel.Name :=
  match name with
  | PsKernelName.anonymous =>
      PSC1Kernel.Name.anonymous
  | PsKernelName.str parent value =>
      PSC1Kernel.Name.str
        (psKernelNameToReference parent)
        value
  | PsKernelName.num parent value =>
      PSC1Kernel.Name.num
        (psKernelNameToReference parent)
        value


def psKernelNameFromReference
    (name : PSC1Kernel.Name) : PsKernelName :=
  match name with
  | PSC1Kernel.Name.anonymous =>
      PsKernelName.anonymous
  | PSC1Kernel.Name.str parent value =>
      PsKernelName.str
        (psKernelNameFromReference parent)
        value
  | PSC1Kernel.Name.num parent value =>
      PsKernelName.num
        (psKernelNameFromReference parent)
        value

def psKernelOrderingToReference
    (value : PsKernelOrdering) : Ordering :=
  match value with
  | PsKernelOrdering.lt => Ordering.lt
  | PsKernelOrdering.eq => Ordering.eq
  | PsKernelOrdering.gt => Ordering.gt

def psKernelNameOptionToReference
    (value : Option PsKernelName) :
    Option PSC1Kernel.Name :=
  match value with
  | Option.none =>
      Option.none
  | Option.some name =>
      Option.some (psKernelNameToReference name)

def psKernelReferenceNameOptionEq
    (left right : Option PSC1Kernel.Name) : Bool :=
  match left with
  | Option.none =>
      match right with
      | Option.none => true
      | Option.some _ => false
  | Option.some leftName =>
      match right with
      | Option.none => false
      | Option.some rightName =>
          PSC1Kernel.Name.eq leftName rightName

def psKernelNameDifferentialCase
    (left right : PsKernelName) : Bool :=
  Bool.and
    ((psKernelNameEq left right) ==
      (PSC1Kernel.Name.eq
        (psKernelNameToReference left)
        (psKernelNameToReference right)))
    (psKernelOrderingToReference
      (psKernelNameCmp left right) ==
      PSC1Kernel.Name.cmp
        (psKernelNameToReference left)
        (psKernelNameToReference right))

def psKernelNamePrefixDifferentialCase
    (needle candidate : PsKernelName) : Bool :=
  (psKernelNameIsPrefixOf needle candidate) ==
    (PSC1Kernel.Name.isPrefixOf
      (psKernelNameToReference needle)
      (psKernelNameToReference candidate))

def psKernelNameReplaceDifferentialCase
    (name oldPrefix newPrefix : PsKernelName) : Bool :=
  psKernelReferenceNameOptionEq
    (psKernelNameOptionToReference
      (psKernelNameReplacePrefix
        name
        oldPrefix
        newPrefix))
    (PSC1Kernel.Name.replacePrefix
      (psKernelNameToReference name)
      (psKernelNameToReference oldPrefix)
      (psKernelNameToReference newPrefix))

def psKernelNameTestRoot : PsKernelName :=
  PsKernelName.str
    (PsKernelName.str
      PsKernelName.anonymous
      "PSC1Kernel")
    "Expr"

def psKernelNameTestNested : PsKernelName :=
  PsKernelName.num
    (PsKernelName.str
      psKernelNameTestRoot
      "field")
    3

def psKernelNameTestReplacement : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "Portable"

-- Exercise native UTF-8 cursor boundaries and repeated candidate collisions.
-- This is conformance evidence; quantified freshness is checked in metatheory.
def psKernelSpecifiedStringMigrationTests : Bool :=
  let samples := ["", "a", "b", "é", "ê", "λ", "中", "😀", "aλ中😀", "u_10", "a\\nb"]
  let equality := samples.all fun left =>
    samples.all fun right => psKernelStringEq left right == (left == right)
  let cursors := samples.all fun value =>
    (List.range (value.utf8ByteSize + 2)).all fun pos =>
      let raw := String.Pos.Raw.mk pos
      String.Pos.Raw.atEnd value raw == String.Internal.atEnd value raw &&
      (String.Pos.Raw.next value raw).byteIdx == (String.Internal.next value raw).byteIdx
  let candidates := (List.range 40).all fun i =>
    psKernelNameEq (psKernelSimpleElimNameCandidate i)
      (PsKernelName.str PsKernelName.anonymous
        (if i == 0 then "u" else String.Internal.append "u_" (psKernelNatToString i)))
  let occupied := (List.range 32).map psKernelSimpleElimNameCandidate
  equality && cursors && candidates &&
    psKernelNameEq (psKernelSimpleFreshElimName occupied) (psKernelSimpleElimNameCandidate 32) &&
    psKernelNameEq (psKernelSimpleFreshElimName (occupied ++ occupied))
      (psKernelSimpleElimNameCandidate 32)

def psKernelCoreNameTests : Bool :=
  Bool.and
    (psKernelNameDifferentialCase
      PsKernelName.anonymous
      PsKernelName.anonymous)
    (Bool.and
      (psKernelNameDifferentialCase
        psKernelNameTestRoot
        psKernelNameTestNested)
      (Bool.and
        (psKernelNamePrefixDifferentialCase
          psKernelNameTestRoot
          psKernelNameTestNested)
        (psKernelNameReplaceDifferentialCase
          psKernelNameTestNested
          psKernelNameTestRoot
          psKernelNameTestReplacement)))

def psKernelLevelToReference
    (level : PsKernelLevel) : PSC1Kernel.Level :=
  match level with
  | PsKernelLevel.zero =>
      PSC1Kernel.Level.zero
  | PsKernelLevel.succ inner =>
      PSC1Kernel.Level.succ
        (psKernelLevelToReference inner)
  | PsKernelLevel.max left right =>
      PSC1Kernel.Level.max
        (psKernelLevelToReference left)
        (psKernelLevelToReference right)
  | PsKernelLevel.imax left right =>
      PSC1Kernel.Level.imax
        (psKernelLevelToReference left)
        (psKernelLevelToReference right)
  | PsKernelLevel.param name =>
      PSC1Kernel.Level.param
        (psKernelNameToReference name)
  | PsKernelLevel.mvar name =>
      PSC1Kernel.Level.mvar
        (psKernelNameToReference name)

def psKernelLevelDifferentialCase
    (left right : PsKernelLevel) : Bool :=
  let referenceLeft :=
    psKernelLevelToReference left
  let referenceRight :=
    psKernelLevelToReference right
  let normalizedPortable :=
    psKernelLevelToReference
      (psKernelLevelNormalize left)
  let normalizedReference :=
    PSC1Kernel.Level.normalize referenceLeft
  Bool.and
    ((psKernelLevelEquivalent left right) ==
      (PSC1Kernel.Level.equivalent
        referenceLeft
        referenceRight))
    (Bool.and
      ((psKernelLevelLe left right) ==
        (PSC1Kernel.Level.le
          referenceLeft
          referenceRight))
      (PSC1Kernel.Level.eq
        normalizedPortable
        normalizedReference))

def psKernelLevelParamU : PsKernelLevel :=
  PsKernelLevel.param
    (PsKernelName.str
      PsKernelName.anonymous
      "u")

def psKernelLevelParamV : PsKernelLevel :=
  PsKernelLevel.param
    (PsKernelName.str
      PsKernelName.anonymous
      "v")

def psKernelCoreLevelTests : Bool :=
  let explicitTwo :=
    PsKernelLevel.succ
      (PsKernelLevel.succ
        PsKernelLevel.zero)
  let left :=
    PsKernelLevel.max
      (PsKernelLevel.succ psKernelLevelParamU)
      explicitTwo
  let right :=
    PsKernelLevel.imax
      psKernelLevelParamV
      (PsKernelLevel.succ PsKernelLevel.zero)
  let functorResult :=
    PsKernelLevel.succ
      (PsKernelLevel.max
        (PsKernelLevel.succ psKernelLevelParamU)
        psKernelLevelParamV)
  let functorFieldNormalized :=
    PsKernelLevel.max
      (PsKernelLevel.succ
        (PsKernelLevel.succ psKernelLevelParamU))
      (PsKernelLevel.succ psKernelLevelParamV)
  Bool.and
    (psKernelLevelDifferentialCase
      PsKernelLevel.zero
      PsKernelLevel.zero)
    (Bool.and
      (psKernelLevelDifferentialCase
        left
        left)
      (Bool.and
        (psKernelLevelDifferentialCase
          left
          right)
        (Bool.and
          (psKernelLevelDifferentialCase
            functorResult
            functorFieldNormalized)
          (psKernelLevelLe
            functorFieldNormalized
            functorResult))))

def psKernelBinderInfoToReference
    (info : PsKernelBinderInfo) : PSC1Kernel.BinderInfo :=
  match info with
  | PsKernelBinderInfo.default => PSC1Kernel.BinderInfo.default
  | PsKernelBinderInfo.implicit => PSC1Kernel.BinderInfo.implicit
  | PsKernelBinderInfo.strictImplicit => PSC1Kernel.BinderInfo.strictImplicit
  | PsKernelBinderInfo.instImplicit => PSC1Kernel.BinderInfo.instImplicit

def psKernelLiteralToReference
    (literal : PsKernelLiteral) : PSC1Kernel.Literal :=
  match literal with
  | PsKernelLiteral.nat value => PSC1Kernel.Literal.nat value
  | PsKernelLiteral.str value => PSC1Kernel.Literal.str value

def psKernelLevelListToReference
    (levels : List PsKernelLevel) : List PSC1Kernel.Level :=
  match levels with
  | List.nil => List.nil
  | List.cons head tail =>
      List.cons
        (psKernelLevelToReference head)
        (psKernelLevelListToReference tail)

def psKernelExprToReference
    (expr : PsKernelExpr) : PSC1Kernel.Expr :=
  match expr with
  | PsKernelExpr.bvar index =>
      PSC1Kernel.Expr.bvar index
  | PsKernelExpr.fvar name =>
      PSC1Kernel.Expr.fvar (psKernelNameToReference name)
  | PsKernelExpr.mvar name =>
      PSC1Kernel.Expr.mvar (psKernelNameToReference name)
  | PsKernelExpr.sort level =>
      PSC1Kernel.Expr.sort (psKernelLevelToReference level)
  | PsKernelExpr.const name levels =>
      PSC1Kernel.Expr.const
        (psKernelNameToReference name)
        (psKernelLevelListToReference levels)
  | PsKernelExpr.app fn arg =>
      PSC1Kernel.Expr.app
        (psKernelExprToReference fn)
        (psKernelExprToReference arg)
  | PsKernelExpr.lam name type body binderInfo =>
      PSC1Kernel.Expr.lam
        (psKernelNameToReference name)
        (psKernelExprToReference type)
        (psKernelExprToReference body)
        (psKernelBinderInfoToReference binderInfo)
  | PsKernelExpr.forallE name type body binderInfo =>
      PSC1Kernel.Expr.forallE
        (psKernelNameToReference name)
        (psKernelExprToReference type)
        (psKernelExprToReference body)
        (psKernelBinderInfoToReference binderInfo)
  | PsKernelExpr.letE name type value body nondep =>
      PSC1Kernel.Expr.letE
        (psKernelNameToReference name)
        (psKernelExprToReference type)
        (psKernelExprToReference value)
        (psKernelExprToReference body)
        nondep
  | PsKernelExpr.lit literal =>
      PSC1Kernel.Expr.lit (psKernelLiteralToReference literal)
  | PsKernelExpr.mdata metadata body =>
      PSC1Kernel.Expr.mdata metadata (psKernelExprToReference body)
  | PsKernelExpr.proj typeName index body =>
      PSC1Kernel.Expr.proj
        (psKernelNameToReference typeName)
        index
        (psKernelExprToReference body)

def psKernelExprDifferentialPair
    (left right : PsKernelExpr) : Bool :=
  let referenceLeft := psKernelExprToReference left
  let referenceRight := psKernelExprToReference right
  Bool.and
    ((psKernelExprEq left right) ==
      PSC1Kernel.Expr.eq referenceLeft referenceRight)
    ((psKernelExprEqual left right) ==
      PSC1Kernel.Expr.equal referenceLeft referenceRight)

def psKernelCoreExprTests : Bool :=
  let typeExpr := PsKernelExpr.sort PsKernelLevel.zero
  let alphaName := PsKernelName.str PsKernelName.anonymous "alpha"
  let betaName := PsKernelName.str PsKernelName.anonymous "beta"
  let alphaLam :=
    PsKernelExpr.lam
      alphaName
      typeExpr
      (PsKernelExpr.bvar 0)
      PsKernelBinderInfo.default
  let betaLam :=
    PsKernelExpr.lam
      betaName
      typeExpr
      (PsKernelExpr.bvar 0)
      PsKernelBinderInfo.implicit
  let app :=
    PsKernelExpr.app
      (PsKernelExpr.app
        (PsKernelExpr.const alphaName List.nil)
        (PsKernelExpr.bvar 2))
      (PsKernelExpr.lit (PsKernelLiteral.nat 7))
  Bool.and
    (psKernelExprDifferentialPair alphaLam betaLam)
    (Bool.and
      ((psKernelExprHasLooseAt app 2) ==
        PSC1Kernel.Expr.hasLooseAt
          (psKernelExprToReference app)
          2)
      (Bool.and
        (psKernelExprGetAppNumArgs app ==
          (PSC1Kernel.Expr.getAppArgs
            (psKernelExprToReference app)).length)
        (PSC1Kernel.Expr.eq
          (psKernelExprToReference
            (psKernelExprGetAppFn app))
          (psKernelExprToReference
            (PsKernelExpr.const alphaName List.nil)))))

def psKernelExprListToReference
    (values : List PsKernelExpr) :
    List PSC1Kernel.Expr :=
  match values with
  | List.nil =>
      List.nil
  | List.cons head tail =>
      List.cons
        (psKernelExprToReference head)
        (psKernelExprListToReference tail)

def psKernelNameListToReference
    (values : List PsKernelName) :
    List PSC1Kernel.Name :=
  match values with
  | List.nil =>
      List.nil
  | List.cons head tail =>
      List.cons
        (psKernelNameToReference head)
        (psKernelNameListToReference tail)

def psKernelExprReferenceEq
    (portable : PsKernelExpr)
    (reference : PSC1Kernel.Expr) : Bool :=
  PSC1Kernel.Expr.eq
    (psKernelExprToReference portable)
    reference

def psKernelCoreInstantiateTests : Bool :=
  let typeExpr :=
    PsKernelExpr.sort PsKernelLevel.zero
  let alphaName :=
    PsKernelName.str PsKernelName.anonymous "alpha"
  let betaName :=
    PsKernelName.str PsKernelName.anonymous "beta"
  let nested :=
    PsKernelExpr.lam
      alphaName
      typeExpr
      (PsKernelExpr.app
        (PsKernelExpr.bvar 1)
        (PsKernelExpr.bvar 0))
      PsKernelBinderInfo.default
  let lifted :=
    psKernelExprLiftLooseBVars
      nested
      0
      2
  let referenceLifted :=
    PSC1Kernel.Expr.liftLooseBVars
      (psKernelExprToReference nested)
      0
      2
  let replacement :=
    PsKernelExpr.lit (PsKernelLiteral.nat 9)
  let instantiateSource :=
    PsKernelExpr.app
      (PsKernelExpr.bvar 1)
      (PsKernelExpr.bvar 0)
  let subst :=
    List.cons replacement List.nil
  let instantiated :=
    psKernelExprInstantiateAt
      instantiateSource
      0
      subst
      0
  let referenceInstantiated :=
    PSC1Kernel.Expr.instantiateAt
      (psKernelExprToReference instantiateSource)
      0
      (psKernelExprListToReference subst)
      0
  let instantiate1DependentSource :=
    PsKernelExpr.app
      (PsKernelExpr.bvar 0)
      (PsKernelExpr.lit
        (PsKernelLiteral.nat 3))
  let instantiate1Dependent :=
    psKernelExprInstantiate1
      instantiate1DependentSource
      replacement
  let referenceInstantiate1Dependent :=
    PSC1Kernel.Expr.instantiateAt
      (psKernelExprToReference
        instantiate1DependentSource)
      0
      (List.cons
        (psKernelExprToReference replacement)
        List.nil)
      0
  let instantiate1NondependentSource :=
    PsKernelExpr.const
      psKernelNatName
      List.nil
  let instantiate1Nondependent :=
    psKernelExprInstantiate1
      instantiate1NondependentSource
      replacement
  let betaSource :=
    PsKernelExpr.app
      (PsKernelExpr.lam
        alphaName
        typeExpr
        (PsKernelExpr.bvar 0)
        PsKernelBinderInfo.default)
      replacement
  let betaReduced :=
    psKernelExprCheapBetaReduce betaSource
  let referenceBetaReduced :=
    PSC1Kernel.Expr.cheapBetaReduce
      (psKernelExprToReference betaSource)
  let abstractSource :=
    PsKernelExpr.app
      (PsKernelExpr.fvar alphaName)
      (PsKernelExpr.fvar betaName)
  let fvars :=
    List.cons
      alphaName
      (List.cons betaName List.nil)
  let abstracted :=
    psKernelExprAbstractFVars
      abstractSource
      fvars
  let referenceAbstracted :=
    PSC1Kernel.Expr.abstractFVars
      (psKernelExprToReference abstractSource)
      (psKernelNameListToReference fvars)
  Bool.and
    (psKernelExprReferenceEq
      lifted
      referenceLifted)
    (Bool.and
      (psKernelExprReferenceEq
        instantiated
        referenceInstantiated)
      (Bool.and
        (psKernelExprReferenceEq
          instantiate1Dependent
          referenceInstantiate1Dependent)
        (Bool.and
          (psKernelExprEq
            instantiate1Nondependent
            instantiate1NondependentSource)
          (Bool.and
            (psKernelExprReferenceEq
              betaReduced
              referenceBetaReduced)
            (psKernelExprReferenceEq
              abstracted
              referenceAbstracted)))))

