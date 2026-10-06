import Ps.Foundation.Name
import Ps.Foundation.List

-- Foreign interfaces have their own versioned value/ownership contract. They
-- do not silently extend psc-runtime-values/1 or the VerifiedIR type system.
inductive PsForeignScalar where
  | bool | u8 | u16 | u32 | u64 | s8 | s16 | s32 | s64
  | f32 | f64 | char | string

inductive PsForeignType where
  | scalar (type : PsForeignScalar)
  | named (name : String)
  | list (element : PsForeignType)
  | option (element : PsForeignType)
  | result (ok : Option PsForeignType) (error : Option PsForeignType)
  | tuple (elements : List PsForeignType)
  | own (resource : String)
  | borrow (resource : String)
  | future (element : Option PsForeignType)
  | stream (element : Option PsForeignType)

structure PsForeignField where
  name : String
  type : PsForeignType

structure PsForeignCase where
  name : String
  payload : Option PsForeignType

inductive PsForeignDefinitionBody where
  | alias (type : PsForeignType)
  | record (fields : List PsForeignField)
  | variant (cases : List PsForeignCase)
  | enumeration (cases : List String)
  | resource

structure PsForeignDefinition where
  name : String
  body : PsForeignDefinitionBody

structure PsForeignFunction where
  name : String
  parameters : List PsForeignField
  result : Option PsForeignType
  asynchronous : Bool
  targets : List String

structure PsForeignInterface where
  name : String
  definitions : List PsForeignDefinition
  functions : List PsForeignFunction
  requiredCapabilities : List String
  providedCapabilities : List String

structure PsForeignWorld where
  contract : String
  packageNamespace : String
  packageName : String
  name : String
  interfaces : List PsForeignInterface
  imports : List String
  exports : List String

structure PsForeignPolicy where
  target : String
  allowedImports : List String
  allowedExports : List String
  allowAsync : Bool
  typeDepth : Nat

inductive PsForeignError where
  | unsupportedContract
  | invalidName
  | duplicateName
  | missingInterface
  | capabilityDenied
  | targetUnavailable
  | invalidOrUnsupportedType
  | resourceExhausted
