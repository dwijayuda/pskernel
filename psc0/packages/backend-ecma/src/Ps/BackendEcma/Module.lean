import Ps.BackendEcma.Lower
import Ps.BackendEcma.Runtime
import Ps.Codegen.Artifact
import Ps.Codegen.Api
import Ps.Codegen.SourceMap

namespace PsEcma

def reservedNames : List String := psTsReservedNames ++
  ["BigInt", "String", "Symbol", "WeakMap", "Uint32Array", "Function", "Reflect",
   "Math", "Error", "Generator", "undefined", "NaN", "Infinity", "Array", "Object",
   "number", "bigint", "string", "boolean", "symbol", "unknown", "never"]

-- Types are shared by TS implementations and declaration files. Only runtime
-- exports exist here: proof declarations disappear before this boundary.
def fieldsDoc (fields : List (String × String)) : PsDoc :=
  blockDoc (fields.map fun (name,type) => txt ("readonly " ++ name ++ ": " ++ type ++ ";"))

def symbolDoc (dialect : Dialect) (declarations : Bool) (symbol owner : String) : PsDoc :=
  if declarations then txt ("declare const " ++ symbol ++ ": unique symbol;")
  else txt ("const " ++ symbol ++ annotation dialect "unique symbol" ++ " = Symbol(" ++ psJsonQuote owner ++ ");")

def structureDocs (dialect : Dialect) (declarations : Bool)
    (brands : List (String × String)) (s : PsVerifiedIrStructure) : Except String PsDoc := do
  let some brand := psTsLookup brands s.name | throw "PSCV0-ECMA: missing structure brand"
  let fields ← s.fields.mapM fun f => do return (f.name, ← irType f.type)
  let type := cat [txt ("export interface " ++ s.name ++ psTsGenericNames s.typeParameters ++ " "),
    fieldsDoc (("[" ++ brand ++ "]", "true") :: fields)]
  return .origin s.name (psDocJoin .hardline (
    [symbolDoc dialect declarations brand s.name] ++
      (if dialect == .typescript then [type] else [])))

def inductiveDocs (dialect : Dialect) (declarations : Bool)
    (tags : List (String × String)) (i : PsVerifiedIrInductive) : Except String PsDoc := do
  let some tag := psTsLookup tags i.name | throw "PSCV0-ECMA: missing inductive tag"
  let generic := psTsGenericNames i.typeParameters
  let result := i.name ++ generic
  let variants ← i.constructors.mapM fun c => do
    let fields ← c.fields.mapM fun f => do return (f.name, ← irType f.type)
    return fieldsDoc (("[" ++ tag ++ "]", psJsonQuote c.name) :: fields)
  let typeDoc := cat [txt ("export type " ++ result ++ " = "),
    if variants.isEmpty then txt "never" else psDocJoin (cat [.hardline, txt "| "]) variants, txt ";"]
  let constructors ← i.constructors.mapM fun c => do
    let parameters ← c.fields.mapM fun f => do return Parameter.mk f.name (← irType f.type) false
    if declarations then
      return txt ("readonly " ++ psJsonQuote c.name ++ ": " ++
        (if parameters.isEmpty && i.typeParameters.isEmpty then result
         else signature .typescript generic parameters "" ++ " => " ++ result) ++ ";")
    let value := Expr.cast (.object (
      ("[" ++ tag ++ "]", str c.name) :: (parameters.map fun p => (p.name, id p.name)))) result
    let value := if parameters.isEmpty && i.typeParameters.isEmpty then value
      else Expr.functionE false generic parameters result [ret value]
    return cat [txt ((if c.name == "__proto__" then "[" ++ psJsonQuote c.name ++ "]" else psJsonQuote c.name) ++ ": "), ← exprDoc dialect 4096 value, txt ","]
  let valueDoc := if declarations then
      cat [txt ("export declare const " ++ i.name ++ ": "), blockDoc constructors, txt ";"]
    else cat [txt ("export const " ++ i.name ++ " = "), blockDoc constructors,
      txt (typed dialect " as const" ++ ";")]
  return .origin i.name (psDocJoin .hardline (
    [symbolDoc dialect declarations tag i.name] ++
      (if dialect == .typescript then [typeDoc] else []) ++ [valueDoc]))

structure Program where
  view : PsVerifiedIrModule
  symbols : List PsCodegenSymbol
  exports : List PsApiExport
  definitions : List (String × List Stmt)

-- Name allocation and lowering happen once for the requested JS/TS dialects.
def plan (ir : PsVerifiedIrModule) : Except String Program := do
  if !ir.imports.isEmpty then throw "PSCV0-ECMA: external capabilities are not qualified"
  let exports ← psApiExports ir
  let (view, names) ← psCodegenNamesFor ir reservedNames
  let brands := psTsBuildBrandMap view
  let tags := psTsBuildTagMap view
  let definitions ← view.declarations.mapM fun d => do
    return (d.name, ← declaration brands tags d)
  return { view, symbols := names.symbols.reverse, exports, definitions }

def signatureDoc (d : PsVerifiedIrDeclaration) : Except String PsDoc := do
  let result ← irType d.resultType
  let parameters ← irParameters d.parameters
  let text := if d.parameters.isEmpty then "export declare const " ++ d.name ++ ": " ++ result ++ ";"
    else "export declare function " ++ d.name ++
      signature .typescript (psTsGenericNames d.typeParameters) parameters result ++ ";"
  return .origin d.name (txt text)

def definitionDoc (dialect : Dialect) (definition : String × List Stmt) : Except String PsDoc := do
  let docs ← definition.snd.mapM fun statement => do
    let doc ← stmtDoc dialect 4096 statement
    match statement with
    | .binding .. => return cat [txt "export ", doc]
    | _ => return doc
  return .origin definition.fst (psDocJoin .hardline docs)

def moduleDoc (dialect : Dialect) (declarations : Bool) (program : Program) :
    Except String PsDoc := do
  let view := program.view
  let brands := psTsBuildBrandMap view
  let tags := psTsBuildTagMap view
  let structures ← view.structures.mapM (structureDocs dialect declarations brands)
  let inductives ← view.inductives.mapM (inductiveDocs dialect declarations tags)
  let definitions ← if declarations then view.declarations.mapM signatureDoc
    else program.definitions.mapM (definitionDoc dialect)
  let header := txt "// Generated by native PSCV0; see the emission manifest."
  let runtime ← if declarations then pure ([] : List PsDoc)
    else (runtimeDoc dialect).map (fun doc => [doc])
  return cat [psDocJoin (cat [.hardline, .hardline])
    ([header] ++ runtime ++ structures ++ inductives ++ definitions), .hardline]

def emitProgram (program : Program) (dialect : Dialect) (context : PsEmissionContext := {}) :
    Except String PsEmissionArtifact := do
  let source ← psRenderDoc (← moduleDoc dialect false program)
  let symbols := program.symbols
  let base : PsEmissionArtifact := {
    target := if dialect == .typescript then .typescript else .javascript
    source := source
    symbols := symbols
    exports := program.exports
    origins := context.origins }
  match dialect with
  | .typescript =>
    psValidateArtifact { base with
      files := [{ path := context.outputStem ++ ".ts", role := .implementation, payload := .text source.text }] }
  | .javascript =>
    let declarations ← psRenderDoc (← moduleDoc .typescript true program)
    let map ← psSourceMap context symbols source
    let source := { source with text := source.text ++ "//# sourceMappingURL=" ++ psSourceMapUrl (context.outputStem ++ ".js.map") ++ "\n" }
    psValidateArtifact { base with
      source := source
      files := [
        { path := context.outputStem ++ ".js", role := .implementation, payload := .text source.text },
        { path := context.outputStem ++ ".d.ts", role := .declaration, payload := .text declarations.text },
        { path := context.outputStem ++ ".js.map", role := .sourceMap, payload := .text map }] }

def emit (ir : PsVerifiedIrModule) (dialect : Dialect) (context : PsEmissionContext := {}) :
    Except String PsEmissionArtifact := do
  emitProgram (← plan ir) dialect context

end PsEcma
