import Ps.Environment.StandardPlatformWords
import Ps.Environment.StandardWellFounded
import Ps.Environment.StandardClassical
import Ps.Environment.StandardPSum
import Ps.Environment.StandardRecursorSurfaceData
import Ps.Environment.StandardPartialFixpoint
import Ps.Environment.StandardOptionBind
import Ps.Environment.StandardArrayFilter
import Ps.Environment.StandardLogicInstances
import Ps.Environment.StandardOperatorProtocol
import Ps.Environment.StandardUtf8
import Ps.Environment.StandardFloatDisplay
import Ps.Environment.StandardScientific
import Ps.Environment.StandardOperatorDefaults
import Ps.Environment.StandardIntArithmetic
import Ps.Environment.StandardScalarArithmetic
import Ps.Environment.StandardUnsigned
import Ps.Environment.StandardUnsignedOperations
import Ps.Environment.StandardFloatIdentity
import Ps.Environment.StandardSignedIdentity
import Ps.Environment.StandardSignedOperations
import Ps.Environment.StandardFloatToBits
import Ps.Environment.StandardFloatCanonical
import Ps.Environment.StandardFloatOperations
import Ps.Environment.StandardFloatConstructors
import Ps.Environment.StandardSignedScalar
import Ps.Environment.StandardSignedToInt
import Ps.Environment.StandardSignedOfInt
import Ps.Environment.StandardSignedShift
import Ps.Environment.StandardSignedClamp
import Ps.Environment.StandardSignedAbs
import Ps.Environment.StandardSignedOrder
import Ps.Environment.StandardSignedNumeric
import Ps.Environment.StandardBoolWord
import Ps.Environment.StandardUnsignedOrder
import Ps.Environment.StandardUnsignedPower
import Ps.Environment.StandardUnsignedOfInt
import Ps.Environment.StandardUnsignedClamp
import Ps.Environment.StandardSum
import Ps.Environment.StandardByteArray
import Ps.Environment.StandardByteArrayCollection
import Ps.Environment.StandardHashable
import Ps.Environment.StandardCoercion
import Ps.Environment.StandardReducibility
import Ps.Environment.StandardReprCollections

def psSelfHostProdRecName : PsName :=
  psNameAppendStr psProdName "rec"

def psSelfHostProdCorePreludeEnvironment : PsEnvironment :=
  let withProduct := psStandardProductDataDeclarations.foldl
    psEnvironmentInsert psSelfHostPreludeEnvironment
  psStandardReducibilityExtend <| psStandardReprCollectionsExtend <|
    psStandardFormatStringExtend <| psStandardReprExtend <|
    psStandardToFormatExtend <| psStandardFormatExtend <| psStandardIntExtend <|
    psStandardStringExtend <| psStandardCoercionExtend <| psStandardNumericExtend <|
    psStandardArrayExtend <| psStandardListIndexExtend <| psStandardFinExtend <|
    psStandardNatOrderExtend <| psStandardGetElemOptionalDefaultExtend <|
    (fun env => [psStandardOutOfBoundsDeclaration,
      psStandardGetElemBangDefaultDeclaration].foldl psPreludeAdd env) <|
    psStandardLawfulGetElemExtend <| psStandardExceptExtend <|
    psStandardProductExtend <| psStandardInhabitedExtend withProduct

-- Explicit library stages also own the frozen authoring-export boundaries.
-- Later structure replacements cannot change an earlier asset's replay base.
def psSelfHostProdScalarPreludeEnvironment : PsEnvironment :=
  psStandardScalarArithmeticExtend psSelfHostProdCorePreludeEnvironment

def psSelfHostProdUnsignedPreludeEnvironment : PsEnvironment :=
  psStandardUnsignedExtend psSelfHostProdScalarPreludeEnvironment

def psSelfHostProdHashPreludeEnvironment : PsEnvironment :=
  psStandardHashableExtend psSelfHostProdUnsignedPreludeEnvironment

-- Separate immutable exporter stage: the selected F0 environment must
-- never serve as its own checked-asset boundary.
def psSelfHostProdPreFloatPreludeEnvironment : PsEnvironment :=
  psStandardUnsignedOperationsExtend psSelfHostProdHashPreludeEnvironment

-- Frozen pre-signed environment serves as the authoring boundary for
-- exact checked SInt family regeneration. Do not close over its own output.
def psSelfHostProdPreSignedPreludeEnvironment : PsEnvironment :=
  psStandardFloatIdentityExtend psSelfHostProdPreFloatPreludeEnvironment

-- Both independent checked method assets are generated against this
-- immutable pre-method boundary. Replaying either cannot depend on itself.
def psSelfHostProdPreM2AMethodPreludeEnvironment : PsEnvironment :=
  psStandardSignedIdentityExtend psSelfHostProdPreSignedPreludeEnvironment

def psSelfHostProdPreSignedScalarPreludeEnvironment : PsEnvironment :=
  psStandardFloatToBitsExtend <|
    psStandardSignedOperationsExtend psSelfHostProdPreM2AMethodPreludeEnvironment

def psSelfHostProdPreSignedToIntPreludeEnvironment : PsEnvironment :=
  psStandardSignedScalarExtend psSelfHostProdPreSignedScalarPreludeEnvironment

def psSelfHostProdPreSignedOfIntPreludeEnvironment : PsEnvironment :=
  psStandardSignedToIntExtend psSelfHostProdPreSignedToIntPreludeEnvironment

def psSelfHostProdPreSignedShiftPreludeEnvironment : PsEnvironment :=
  psStandardSignedOfIntExtend psSelfHostProdPreSignedOfIntPreludeEnvironment

-- Frozen input for exact Int arithmetic asset regeneration.
def psSelfHostProdPreIntArithmeticPreludeEnvironment : PsEnvironment :=
  psStandardFloatCanonicalExtend <|
  psStandardByteArrayCollectionExtend <|
    psStandardByteArrayExtend <|
    psStandardSumExtend <|
    psStandardUnsignedClampExtend <|
    psStandardUnsignedOfIntExtend <|
    psStandardUnsignedPowerExtend <|
    psStandardUnsignedOrderExtend <|
    psStandardBoolWordExtend <|
    psStandardSignedNumericExtend <|
    psStandardSignedOrderExtend <|
    psStandardSignedAbsExtend <|
    psStandardSignedClampExtend <|
    psStandardSignedShiftExtend psSelfHostProdPreSignedShiftPreludeEnvironment

-- Frozen input for the small logical Float constructor asset.
def psSelfHostProdPreFloatConstructorsPreludeEnvironment : PsEnvironment :=
  psStandardIntArithmeticExtend psSelfHostProdPreIntArithmeticPreludeEnvironment

-- Frozen F2 input: selected operations must never cut their own replay.
def psSelfHostProdPreFloatOperationsPreludeEnvironment : PsEnvironment :=
  psStandardFloatConstructorsExtend psSelfHostProdPreFloatConstructorsPreludeEnvironment

def psSelfHostProdPreLiteralPreludeEnvironment : PsEnvironment :=
  psStandardFloatOperationsExtend psSelfHostProdPreFloatOperationsPreludeEnvironment

-- Immutable F3 authoring boundary, preceding OfScientific source selection.
def psSelfHostProdPreFloatConversionsPreludeEnvironment : PsEnvironment :=
  psStandardOperatorDefaultsExtend psSelfHostProdPreLiteralPreludeEnvironment

-- Frozen F4 input, prior to native display and opaque cross-width selection.
def psSelfHostProdPreFloatDisplayPreludeEnvironment : PsEnvironment :=
  psStandardScientificExtend psSelfHostProdPreFloatConversionsPreludeEnvironment

-- Frozen logical boundary for explicit target-word profile authoring.
def psSelfHostProdPrePlatformWordsPreludeEnvironment : PsEnvironment :=
  psStandardFloatDisplayExtend psSelfHostProdPreFloatDisplayPreludeEnvironment

-- Frozen input for checked well-founded relation authoring. Later relation
-- declarations must never become their own export or replay boundary.
def psSelfHostProdPreWellFoundedPreludeEnvironment : PsEnvironment :=
  psStandardOperatorProtocolExtend <| psStandardLogicExtend <| PsStandardUtf8.extend <| psStandardArrayFilterExtend <|
    psStandardPlatformExtend psSelfHostProdPrePlatformWordsPreludeEnvironment

-- Keep all preceding authoring boundaries independent of Classical.
def psSelfHostProdPreClassicalPreludeEnvironment : PsEnvironment :=
  psStandardWellFoundedExtend psSelfHostProdPreWellFoundedPreludeEnvironment

-- Frozen boundary for the reviewed Order asset; do not export against itself.
def psSelfHostProdPrePartialFixpointPreludeEnvironment : PsEnvironment :=
  psStandardClassicalExtend psSelfHostProdPreClassicalPreludeEnvironment

-- Frozen input for reviewed mutual WF component-domain selection.
def psSelfHostProdPreMutualWellFoundedPreludeEnvironment : PsEnvironment :=
  psStandardPartialFixpointExtend psSelfHostProdPrePartialFixpointPreludeEnvironment

-- Frozen source for retained public recursor metadata authoring. A later
-- final-stage correction must not alter any earlier closed asset replay base.
def psSelfHostProdPreRecursorSurfacePreludeEnvironment : PsEnvironment :=
  psStandardPSumExtend psSelfHostProdPreMutualWellFoundedPreludeEnvironment

-- Reviewed metadata-only replacements are selected only at the final stage.
-- Preserve every earlier authoring base, including the pre-recursor snapshot.
-- Freeze the complete preceding selection for the additive Option bind
-- authoring boundary. Earlier Order, PSum and recursor stages retain their
-- original declaration, metadata and registration identities.
def psSelfHostProdPreOptionBindPreludeEnvironment : PsEnvironment :=
  psStandardLawfulBEqExtend <|
    psStandardRecursorSurfaceDeclarations.foldl psEnvironmentInsert
      psSelfHostProdPreRecursorSurfacePreludeEnvironment

def psSelfHostProdOptionBindPreludeEnvironment : PsEnvironment :=
  psStandardOptionBindExtend psSelfHostProdPreOptionBindPreludeEnvironment

def psSelfHostProdPreludeEnvironment : PsEnvironment :=
  psSelfHostProdOptionBindPreludeEnvironment

-- Structural mutual recursion bundles retained results in the checked
-- Sort-polymorphic product. Logical inclusion alone does not register its
-- runtime layout. Reuse only its existing data declarations so constructors,
-- recursors and projections take the ordinary shared structure-lowering path.
-- Do not replace the checked declaration or change any frozen replay boundary.
def psSelfHostPProdRuntimeDataDeclarations : List PsDeclaration :=
  ["PProd", "PProd.mk", "PProd.rec"].filterMap
    (fun name => psEnvironmentFind psSelfHostProdPreludeEnvironment (psDecisionName name))

def psSelfHostRuntimePreludeDeclarationsWithProd :
    List PsDeclaration :=
  let prodDeclarations := psStandardProductDataDeclarations ++
    psSelfHostPProdRuntimeDataDeclarations
  -- Preserve dependency-first order for eager nullary runtime values.
  -- The checked ByteArray.empty value must initialize before the checked
  -- Inhabited ByteArray dictionary captures it in the shared executable IR.
  -- This order is shared by JS, TypeScript, Rust and Wasm, not a JS workaround.
  let prior := psStandardFloatOperationsRuntimeDeclarations ++ psStandardFloatModelRuntimeDeclarations ++ psStandardFloatModelProjectionRuntimeDeclarations ++ psStandardFloatCanonicalRuntimeDeclarations ++ psStandardByteArrayRuntimeDeclarations ++ psStandardByteArrayCollectionRuntimeDeclarations ++ psStandardSumRuntimeDeclarations ++ psStandardUnsignedClampRuntimeDeclarations ++ psStandardUnsignedOfIntRuntimeDeclarations ++ psStandardUnsignedPowerRuntimeDeclarations ++ psStandardUnsignedOrderRuntimeDeclarations ++ psStandardBoolWordRuntimeDeclarations ++ psStandardSignedNumericRuntimeDeclarations ++ psStandardSignedOrderRuntimeDeclarations ++ psStandardSignedAbsRuntimeDeclarations ++ psStandardSignedClampRuntimeDeclarations ++ psStandardSignedShiftRuntimeDeclarations ++ psStandardSignedOfIntRuntimeDeclarations ++ psStandardSignedToIntRuntimeDeclarations ++ psStandardSignedScalarRuntimeDeclarations ++ psStandardUnsignedOperationsRuntimeDeclarations ++ psStandardHashRuntimeDeclarations ++ psStandardUnsignedRuntimeDeclarations ++ psStandardReprCollectionDeclarations ++ psStandardFormatStringDeclarations ++ psStandardReprDeclarations ++ psStandardToFormatDeclarations ++ psStandardFormatDeclarations ++ psStandardStringDeclarations ++ psStandardCoercionDeclarations ++ psStandardNumericDeclarations ++ psEmptyDeclarations ++ psDecisionEqualityDeclarations ++ psStandardPreludeDeclarationsWithInhabited ++
    prodDeclarations ++ psSelfHostRuntimePreludeDeclarations ++
    psStandardProductDeclarations ++ psStandardExceptDeclarations ++
    -- Class evidence and method projections must enter typed runtime erasure
    -- through the same pinned, officially checked Standard declarations.
    psStandardGetElemClass ++ psStandardGetElemOptionalDeclarations ++
    psStandardLawfulGetElemClass ++
    [psStandardOutOfBoundsDeclaration, psStandardGetElemBangDefaultDeclaration] ++
    psStandardGetElemOptionalDefaultDeclarations ++ psStandardNatOrderDeclarations ++
    psStandardFinAllDeclarations ++ psStandardListIndexDeclarations ++
    psStandardArrayRuntimeDeclarations

  psStandardOperatorProtocolRuntimeDeclarations psSelfHostProdPreludeEnvironment ++
    psStandardLogicRuntimeDeclarations psSelfHostProdPreludeEnvironment ++
    PsStandardUtf8.runtimeDeclarations ++ psStandardFloatDisplayRuntimeDeclarations ++ psStandardScientificRuntimeDeclarations ++
    psStandardOperatorDefaultsRuntimeDeclarations psSelfHostProdPreludeEnvironment ++
    prior.filter (fun declaration =>
      !psStandardHomogeneousReplacedNames.any (psNameEq (psDeclarationName declaration))) ++
    psStandardOptionBindRuntimeDeclarations psSelfHostProdPreludeEnvironment
