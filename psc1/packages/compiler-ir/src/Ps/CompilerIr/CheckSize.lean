import Ps.CompilerIr.CheckTypes

-- Preflight counts every model occurrence and list cell before module helpers run.
-- Each string is bounded by the original input budget. Scalar carriers are supplied
-- by the native model or validated by the host boundary before this operation.
inductive PsIrCheckSizeTask where
  | moduleNode (value : PsVerifiedIrModule)
  | imports (value : List PsVerifiedIrExternalImport)
  | externalImport (value : PsVerifiedIrExternalImport)
  | structures (value : List PsVerifiedIrStructure)
  | structureNode (value : PsVerifiedIrStructure)
  | structureFields (value : List PsVerifiedIrStructureField)
  | structureField (value : PsVerifiedIrStructureField)
  | inductives (value : List PsVerifiedIrInductive)
  | inductiveNode (value : PsVerifiedIrInductive)
  | constructors (value : List PsVerifiedIrConstructor)
  | constructor (value : PsVerifiedIrConstructor)
  | constructorFields (value : List PsVerifiedIrConstructorField)
  | constructorField (value : PsVerifiedIrConstructorField)
  | declarations (value : List PsVerifiedIrDeclaration)
  | declaration (value : PsVerifiedIrDeclaration)
  | typeParameters (value : List PsVerifiedIrTypeParameter)
  | typeParameter (value : PsVerifiedIrTypeParameter)
  | parameters (value : List PsVerifiedIrParameter)
  | parameter (value : PsVerifiedIrParameter)
  | bindings (value : List PsVerifiedIrMatchBinding)
  | binding (value : PsVerifiedIrMatchBinding)
  | type (value : PsVerifiedIrType)
  | types (value : List PsVerifiedIrType)
  | expression (value : PsVerifiedIrExpr)
  | expressions (value : List PsVerifiedIrExpr)
  | literal (value : PsVerifiedIrLiteral)
  | intrinsic (value : PsVerifiedIrIntrinsic)
  | fields (value : List (String × PsVerifiedIrExpr))
  | field (value : String × PsVerifiedIrExpr)
  | alternatives (value : List (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr))
  | alternative (value : String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr)
  | alternativeBody (value : List PsVerifiedIrMatchBinding × PsVerifiedIrExpr)
  | text (value : String)
  | scalar

def psIrCheckModuleSizeWorker
    (limit : Nat)
    (fuel : Nat)
    (pending : List PsIrCheckSizeTask)
    (visited : Nat) : Except PsIrCheckIssue Nat :=
  match fuel with
  | Nat.zero =>
      match pending with
      | List.nil => Except.ok visited
      | List.cons _ _ =>
          Except.error
            (psIrCheckIssue "checker-input-resource-limit" "node budget exhausted")
  | Nat.succ remaining =>
      match pending with
      | List.nil => Except.ok visited
      | List.cons task rest =>
          let next := Nat.succ visited;
          match task with
          | .scalar =>
              psIrCheckModuleSizeWorker limit remaining
                rest next
          | .text value =>
              if Nat.ble (String.utf8ByteSize value) limit then
                psIrCheckModuleSizeWorker limit remaining
                  rest next
              else
                Except.error
                  (psIrCheckIssue "checker-input-resource-limit" "string byte bound")
          | .moduleNode value =>
              psIrCheckModuleSizeWorker limit remaining
                (List.cons (PsIrCheckSizeTask.imports value.imports) (List.cons (PsIrCheckSizeTask.structures value.structures) (List.cons (PsIrCheckSizeTask.inductives value.inductives) (List.cons (PsIrCheckSizeTask.declarations value.declarations) rest)))) next
          | .externalImport value =>
              psIrCheckModuleSizeWorker limit remaining
                (List.cons (PsIrCheckSizeTask.text value.localName) (List.cons (PsIrCheckSizeTask.text value.source) (List.cons (PsIrCheckSizeTask.text value.importedName) (List.cons (PsIrCheckSizeTask.type value.type) rest)))) next
          | .structureNode value =>
              psIrCheckModuleSizeWorker limit remaining
                (List.cons (PsIrCheckSizeTask.text value.name) (List.cons (PsIrCheckSizeTask.typeParameters value.typeParameters) (List.cons (PsIrCheckSizeTask.structureFields value.fields) rest))) next
          | .structureField value =>
              psIrCheckModuleSizeWorker limit remaining
                (List.cons (PsIrCheckSizeTask.text value.name) (List.cons (PsIrCheckSizeTask.type value.type) rest)) next
          | .inductiveNode value =>
              psIrCheckModuleSizeWorker limit remaining
                (List.cons (PsIrCheckSizeTask.text value.name) (List.cons (PsIrCheckSizeTask.typeParameters value.typeParameters) (List.cons (PsIrCheckSizeTask.constructors value.constructors) rest))) next
          | .constructor value =>
              psIrCheckModuleSizeWorker limit remaining
                (List.cons (PsIrCheckSizeTask.text value.name) (List.cons (PsIrCheckSizeTask.constructorFields value.fields) rest)) next
          | .constructorField value =>
              psIrCheckModuleSizeWorker limit remaining
                (List.cons (PsIrCheckSizeTask.text value.name) (List.cons (PsIrCheckSizeTask.type value.type) rest)) next
          | .declaration value =>
              psIrCheckModuleSizeWorker limit remaining
                (List.cons (PsIrCheckSizeTask.text value.name) (List.cons (PsIrCheckSizeTask.typeParameters value.typeParameters) (List.cons (PsIrCheckSizeTask.parameters value.parameters) (List.cons (PsIrCheckSizeTask.type value.resultType) (List.cons (PsIrCheckSizeTask.expression value.body) rest))))) next
          | .typeParameter value =>
              psIrCheckModuleSizeWorker limit remaining
                (List.cons (PsIrCheckSizeTask.text value.name) rest) next
          | .parameter value =>
              psIrCheckModuleSizeWorker limit remaining
                (List.cons (PsIrCheckSizeTask.text value.name) (List.cons (PsIrCheckSizeTask.type value.type) rest)) next
          | .binding value =>
              psIrCheckModuleSizeWorker limit remaining
                (List.cons (PsIrCheckSizeTask.text value.field) (List.cons (PsIrCheckSizeTask.text value.name) (List.cons (PsIrCheckSizeTask.type value.type) rest))) next
          | .field value =>
              psIrCheckModuleSizeWorker limit remaining
                (List.cons (PsIrCheckSizeTask.text value.fst) (List.cons (PsIrCheckSizeTask.expression value.snd) rest)) next
          | .alternative value =>
              psIrCheckModuleSizeWorker limit remaining
                (List.cons (PsIrCheckSizeTask.text value.fst) (List.cons (PsIrCheckSizeTask.alternativeBody value.snd) rest)) next
          | .alternativeBody value =>
              psIrCheckModuleSizeWorker limit remaining
                (List.cons (PsIrCheckSizeTask.bindings value.fst) (List.cons (PsIrCheckSizeTask.expression value.snd) rest)) next
          | .imports values =>
              match values with
              | List.nil =>
                  psIrCheckModuleSizeWorker limit remaining
                    rest next
              | List.cons value tail =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.externalImport value) (List.cons (PsIrCheckSizeTask.imports tail) rest)) next
          | .structures values =>
              match values with
              | List.nil =>
                  psIrCheckModuleSizeWorker limit remaining
                    rest next
              | List.cons value tail =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.structureNode value) (List.cons (PsIrCheckSizeTask.structures tail) rest)) next
          | .structureFields values =>
              match values with
              | List.nil =>
                  psIrCheckModuleSizeWorker limit remaining
                    rest next
              | List.cons value tail =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.structureField value) (List.cons (PsIrCheckSizeTask.structureFields tail) rest)) next
          | .inductives values =>
              match values with
              | List.nil =>
                  psIrCheckModuleSizeWorker limit remaining
                    rest next
              | List.cons value tail =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.inductiveNode value) (List.cons (PsIrCheckSizeTask.inductives tail) rest)) next
          | .constructors values =>
              match values with
              | List.nil =>
                  psIrCheckModuleSizeWorker limit remaining
                    rest next
              | List.cons value tail =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.constructor value) (List.cons (PsIrCheckSizeTask.constructors tail) rest)) next
          | .constructorFields values =>
              match values with
              | List.nil =>
                  psIrCheckModuleSizeWorker limit remaining
                    rest next
              | List.cons value tail =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.constructorField value) (List.cons (PsIrCheckSizeTask.constructorFields tail) rest)) next
          | .declarations values =>
              match values with
              | List.nil =>
                  psIrCheckModuleSizeWorker limit remaining
                    rest next
              | List.cons value tail =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.declaration value) (List.cons (PsIrCheckSizeTask.declarations tail) rest)) next
          | .typeParameters values =>
              match values with
              | List.nil =>
                  psIrCheckModuleSizeWorker limit remaining
                    rest next
              | List.cons value tail =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.typeParameter value) (List.cons (PsIrCheckSizeTask.typeParameters tail) rest)) next
          | .parameters values =>
              match values with
              | List.nil =>
                  psIrCheckModuleSizeWorker limit remaining
                    rest next
              | List.cons value tail =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.parameter value) (List.cons (PsIrCheckSizeTask.parameters tail) rest)) next
          | .bindings values =>
              match values with
              | List.nil =>
                  psIrCheckModuleSizeWorker limit remaining
                    rest next
              | List.cons value tail =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.binding value) (List.cons (PsIrCheckSizeTask.bindings tail) rest)) next
          | .types values =>
              match values with
              | List.nil =>
                  psIrCheckModuleSizeWorker limit remaining
                    rest next
              | List.cons value tail =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.type value) (List.cons (PsIrCheckSizeTask.types tail) rest)) next
          | .expressions values =>
              match values with
              | List.nil =>
                  psIrCheckModuleSizeWorker limit remaining
                    rest next
              | List.cons value tail =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.expression value) (List.cons (PsIrCheckSizeTask.expressions tail) rest)) next
          | .fields values =>
              match values with
              | List.nil =>
                  psIrCheckModuleSizeWorker limit remaining
                    rest next
              | List.cons value tail =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.field value) (List.cons (PsIrCheckSizeTask.fields tail) rest)) next
          | .alternatives values =>
              match values with
              | List.nil =>
                  psIrCheckModuleSizeWorker limit remaining
                    rest next
              | List.cons value tail =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.alternative value) (List.cons (PsIrCheckSizeTask.alternatives tail) rest)) next
          | .type value =>
              match value with
              | .unknown =>
                  psIrCheckModuleSizeWorker limit remaining
                    rest next
              | .typeParameter name =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.text name) rest) next
              | .primitive _ =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons PsIrCheckSizeTask.scalar rest) next
              | .function parameters result =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.types parameters) (List.cons (PsIrCheckSizeTask.type result) rest)) next
              | .named name arguments =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.text name) (List.cons (PsIrCheckSizeTask.types arguments) rest)) next
          | .expression value =>
              match value with
              | .literal literal =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.literal literal) rest) next
              | .var name =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.text name) rest) next
              | .intrinsic operation typeArguments arguments =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.intrinsic operation) (List.cons (PsIrCheckSizeTask.types typeArguments) (List.cons (PsIrCheckSizeTask.expressions arguments) rest))) next
              | .lambda parameters resultType body =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.parameters parameters) (List.cons (PsIrCheckSizeTask.type resultType) (List.cons (PsIrCheckSizeTask.expression body) rest))) next
              | .call fn typeArguments arguments =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.expression fn) (List.cons (PsIrCheckSizeTask.types typeArguments) (List.cons (PsIrCheckSizeTask.expressions arguments) rest))) next
              | .letE name type value body =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.text name) (List.cons (PsIrCheckSizeTask.type type) (List.cons (PsIrCheckSizeTask.expression value) (List.cons (PsIrCheckSizeTask.expression body) rest)))) next
              | .ifE condition thenBranch elseBranch =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.expression condition) (List.cons (PsIrCheckSizeTask.expression thenBranch) (List.cons (PsIrCheckSizeTask.expression elseBranch) rest))) next
              | .record name typeArguments fields =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.text name) (List.cons (PsIrCheckSizeTask.types typeArguments) (List.cons (PsIrCheckSizeTask.fields fields) rest))) next
              | .projection name typeArguments target field =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.text name) (List.cons (PsIrCheckSizeTask.types typeArguments) (List.cons (PsIrCheckSizeTask.expression target) (List.cons (PsIrCheckSizeTask.text field) rest)))) next
              | .constructor name constructorName typeArguments fields =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.text name) (List.cons (PsIrCheckSizeTask.text constructorName) (List.cons (PsIrCheckSizeTask.types typeArguments) (List.cons (PsIrCheckSizeTask.fields fields) rest)))) next
              | .matchE name typeArguments scrutinee alternatives =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.text name) (List.cons (PsIrCheckSizeTask.types typeArguments) (List.cons (PsIrCheckSizeTask.expression scrutinee) (List.cons (PsIrCheckSizeTask.alternatives alternatives) rest)))) next
          | .literal value =>
              match value with
              | .natural _ =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons PsIrCheckSizeTask.scalar rest) next
              | .integer _ =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons PsIrCheckSizeTask.scalar rest) next
              | .machineInteger _ _ =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons PsIrCheckSizeTask.scalar (List.cons PsIrCheckSizeTask.scalar rest)) next
              | .string value =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons (PsIrCheckSizeTask.text value) rest) next
              | .bool _ =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons PsIrCheckSizeTask.scalar rest) next
              | .unit =>
                  psIrCheckModuleSizeWorker limit remaining
                    rest next
          | .intrinsic value =>
              match value with
              | .machineIntBinary _ _ =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons PsIrCheckSizeTask.scalar (List.cons PsIrCheckSizeTask.scalar rest)) next
              | .machineIntCompare _ _ =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons PsIrCheckSizeTask.scalar (List.cons PsIrCheckSizeTask.scalar rest)) next
              | .floatBinary _ _ =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons PsIrCheckSizeTask.scalar (List.cons PsIrCheckSizeTask.scalar rest)) next
              | .floatCompare _ _ =>
                  psIrCheckModuleSizeWorker limit remaining
                    (List.cons PsIrCheckSizeTask.scalar (List.cons PsIrCheckSizeTask.scalar rest)) next
              | _ =>
                  psIrCheckModuleSizeWorker limit remaining
                    rest next

def psIrCheckModuleSize
    (fuel : Nat)
    (module : PsVerifiedIrModule) : Except PsIrCheckIssue Nat :=
  psIrCheckModuleSizeWorker fuel fuel
    (List.cons (PsIrCheckSizeTask.moduleNode module) List.nil) 0
