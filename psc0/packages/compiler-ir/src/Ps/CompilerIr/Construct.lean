import Ps.CompilerIr.Model

-- Neutral runtime factories for host interoperation with generated compilers.
-- Ordinary exported functions preserve each record's runtime brand.
def psIrCheckMakeParameter (name : String) (type : PsVerifiedIrType) :
    PsVerifiedIrParameter :=
  PsVerifiedIrParameter.mk name type

def psIrCheckMakeMatchBinding (field : String) (name : String)
    (type : PsVerifiedIrType) : PsVerifiedIrMatchBinding :=
  PsVerifiedIrMatchBinding.mk field name type

def psIrCheckMakeTypeParameter (name : String) : PsVerifiedIrTypeParameter :=
  PsVerifiedIrTypeParameter.mk name

def psIrCheckMakeStructureField (name : String) (type : PsVerifiedIrType) :
    PsVerifiedIrStructureField :=
  PsVerifiedIrStructureField.mk name type

def psIrCheckMakeStructure (name : String)
    (typeParameters : List PsVerifiedIrTypeParameter)
    (fields : List PsVerifiedIrStructureField) : PsVerifiedIrStructure :=
  PsVerifiedIrStructure.mk name typeParameters fields

def psIrCheckMakeConstructorField (name : String) (type : PsVerifiedIrType) :
    PsVerifiedIrConstructorField :=
  PsVerifiedIrConstructorField.mk name type

def psIrCheckMakeConstructor (name : String)
    (fields : List PsVerifiedIrConstructorField) : PsVerifiedIrConstructor :=
  PsVerifiedIrConstructor.mk name fields

def psIrCheckMakeInductive (name : String)
    (typeParameters : List PsVerifiedIrTypeParameter)
    (constructors : List PsVerifiedIrConstructor) : PsVerifiedIrInductive :=
  PsVerifiedIrInductive.mk name typeParameters constructors

def psIrCheckMakeDeclaration (name : String)
    (typeParameters : List PsVerifiedIrTypeParameter)
    (parameters : List PsVerifiedIrParameter)
    (resultType : PsVerifiedIrType) (body : PsVerifiedIrExpr) :
    PsVerifiedIrDeclaration :=
  PsVerifiedIrDeclaration.mk name typeParameters parameters resultType body

def psIrCheckMakeExternalImport (localName : String) (source : String)
    (importedName : String) (type : PsVerifiedIrType) : PsVerifiedIrExternalImport :=
  PsVerifiedIrExternalImport.mk localName source importedName type

def psIrCheckMakeModule (imports : List PsVerifiedIrExternalImport)
    (structures : List PsVerifiedIrStructure)
    (inductives : List PsVerifiedIrInductive)
    (declarations : List PsVerifiedIrDeclaration) : PsVerifiedIrModule :=
  PsVerifiedIrModule.mk imports structures inductives declarations

def psIrCheckMakePair {alpha : Type} {beta : Type}
    (first : alpha) (second : beta) : alpha × beta :=
  Prod.mk first second
