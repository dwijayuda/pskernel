import Ps.Environment.StandardScalarArithmetic
import Ps.Environment.StandardUnsigned
import Ps.Environment.StandardUnsignedOperations
import Ps.Environment.StandardFloatIdentity
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

def psSelfHostProdPreludeEnvironment : PsEnvironment :=
  psStandardFloatIdentityExtend psSelfHostProdPreFloatPreludeEnvironment

def psSelfHostRuntimePreludeDeclarationsWithProd :
    List PsDeclaration :=
  let prodDeclarations := psStandardProductDataDeclarations
  psStandardUnsignedOperationsRuntimeDeclarations ++ psStandardHashRuntimeDeclarations ++ psStandardUnsignedRuntimeDeclarations ++ psStandardReprCollectionDeclarations ++ psStandardFormatStringDeclarations ++ psStandardReprDeclarations ++ psStandardToFormatDeclarations ++ psStandardFormatDeclarations ++ psStandardStringDeclarations ++ psStandardCoercionDeclarations ++ psStandardNumericDeclarations ++ psEmptyDeclarations ++ psDecisionEqualityDeclarations ++ psStandardPreludeDeclarationsWithInhabited ++
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
