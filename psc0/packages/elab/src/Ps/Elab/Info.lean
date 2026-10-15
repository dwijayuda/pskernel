import Ps.Environment.Resolve
import Ps.Meta.Context
import Ps.Syntax.Ast

/-!
Source-owned elaboration evidence, outside Core identity and kernel admission.
Design reference: Lean 4.35.0 Elab/InfoTree/{Types,Main}.lean, Apache-2.0,
Wojciech Nawrocki, Leonardo de Moura and Sebastian Ullrich. PSCV0 keeps a
compact ordered stream, without editor widgets, macro expansion or IO state.
-/
inductive PsElabInsertedArgumentKind where
  | implicit | strictImplicit | instanceImplicit | defaultValue
  deriving BEq

inductive PsElabInfo where
  | reference (source : PsSyntaxName) (resolved : PsResolvedName)
      (projection : List String) (term type : PsExpr)
  | instanceSelection (span : Option PsSourceSpan) (goal evidence : PsExpr)
  | binderGroup (head : PsSyntaxBinderHead) (annotation : PsSyntaxTerm)
      (ids : List Nat)
  | insertedArgument (span : Option PsSourceSpan)
      (kind : PsElabInsertedArgumentKind) (name : PsName)
      (function value type : PsExpr)

structure PsElabInfoEntry where
  localContext : PsLocalContext
  info : PsElabInfo

-- A single final assignment context owns the metavariables in all entries.
-- Locals remain scoped free identities; never close them against a different
-- telescope or infer a reference from its printed name after elaboration.
structure PsElabSourceInfo where
  owner : PsName
  metaContext : PsMetaContext
  entries : List PsElabInfoEntry

def psElabInfoExpressions : PsElabInfo → List PsExpr
  | .reference _ _ _ term type => [term, type]
  | .instanceSelection _ goal evidence => [goal, evidence]
  | .binderGroup _ _ _ => []
  | .insertedArgument _ _ _ fn value type => [fn, value, type]

def psElabInfoInstantiate (metaContext : PsMetaContext) : PsElabInfo → PsElabInfo
  | .reference source resolved projection term type =>
    .reference source resolved projection (psMetaInstantiate metaContext term)
      (psMetaInstantiate metaContext type)
  | .instanceSelection span goal evidence =>
    .instanceSelection span (psMetaInstantiate metaContext goal)
      (psMetaInstantiate metaContext evidence)
  | .binderGroup head annotation ids => .binderGroup head annotation ids
  | .insertedArgument span kind name fn value type =>
    .insertedArgument span kind name (psMetaInstantiate metaContext fn)
      (psMetaInstantiate metaContext value) (psMetaInstantiate metaContext type)
