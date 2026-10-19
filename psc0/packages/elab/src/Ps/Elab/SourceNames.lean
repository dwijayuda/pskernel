import Ps.Elab.Basic

-- Public source AST entry points cannot manufacture the internal name slots
-- which Scope supplies after resolving a checked private/exported alias.
-- This walk does not resolve ordinary names or elaborate unused source hints.
def psElabSourceName (name : PsSyntaxName) : Except PsElabError Unit := do
  if name.resolvedName.isSome then
    throw (.scope "source syntax contains an internal resolved name")
  if !name.universeBinders.isEmpty then
    throw (.scope "declaration universe binders occur outside a declaration head")

def psElabSourceDeclarationName (name : PsSyntaxName) : Except PsElabError Unit := do
  psElabSourceName { name with universeBinders := [] }
  for binder in name.universeBinders do
    if binder.segments.isEmpty || (!binder.escaped && binder.segments == ["_"]) then
      throw (.scope "invalid declaration universe binder")

def psElabSourceBinderNames (head : PsSyntaxBinderHead) : Except PsElabError Unit := do
  for name in psSyntaxBinderNames head do psElabSourceName name
  for origin in head.origin.toList do
    for name in origin.names do psElabSourceName name

def psElabSourcePatternNames (fuel : Nat) (pattern : PsSyntaxPattern) :
    Except PsElabError Unit := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match pattern with
    | .variable name => psElabSourceName name
    | .ctor name fields _ | .dotCtor name fields _ =>
      psElabSourceName name
      for field in fields do psElabSourcePatternNames fuel field
    | .inaccessible value => psElabSourcePatternNames fuel value
    | _ => pure ()

def psElabSourceRCasesPatternNames (visit : PsSyntaxTerm → Except PsElabError Unit)
    (fuel : Nat) (pattern : PsSyntaxRCasesPattern) : Except PsElabError Unit := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match pattern with
    | .one name => psElabSourceName name
    | .clear _ => pure ()
    | .typed pattern type _ =>
      psElabSourceRCasesPatternNames visit fuel pattern
      visit type
    | .explicit pattern _ | .paren pattern _ =>
      psElabSourceRCasesPatternNames visit fuel pattern
    | .tuple patterns _ | .alternatives patterns _ =>
      for pattern in patterns do psElabSourceRCasesPatternNames visit fuel pattern

def psElabSourceRIntroPatternNames (visit : PsSyntaxTerm → Except PsElabError Unit)
    (fuel : Nat) (pattern : PsSyntaxRIntroPattern) : Except PsElabError Unit := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match pattern with
    | .pattern pattern => psElabSourceRCasesPatternNames visit fuel pattern
    | .group patterns type _ =>
      for pattern in patterns do psElabSourceRIntroPatternNames visit fuel pattern
      for type in type.toList do visit type

def psElabSourceTacticNames (visit : PsSyntaxTerm → Except PsElabError Unit)
    (fuel : Nat) (tactics : List PsSyntaxTactic) : Except PsElabError Unit := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    for tactic in tactics do
      match tactic with
      | .exactE value _ _ | .applyE value _ | .change value _ _ | .eliminate value _ _ =>
        visit value
      | .localE name type value _ _ =>
        psElabSourceName name
        for type in type.toList do visit type
        visit value
      | .suffices name type value _ =>
        psElabSourceName name
        visit type
        visit value
      | .rcasesE targets pattern _ =>
        for target in targets do
          for name in target.equationName?.toList do psElabSourceName name
          visit target.term
        for pattern in pattern.toList do psElabSourceRCasesPatternNames visit fuel pattern
      | .rintroE patterns type _ =>
        for pattern in patterns do psElabSourceRIntroPatternNames visit fuel pattern
        for type in type.toList do visit type
      | .obtainE pattern type values _ =>
        for pattern in pattern.toList do psElabSourceRCasesPatternNames visit fuel pattern
        for type in type.toList do visit type
        for value in values.toList.flatten do visit value
      | .byCases name proposition _ =>
        for name in name.toList do psElabSourceName name
        visit proposition
      | .extE patterns _ _ =>
        for pattern in patterns do psElabSourceRIntroPatternNames visit fuel pattern
      | .intro names _ | .intros names _ =>
        for name in names do psElabSourceName name
      | .caseE tag names body _ =>
        for name in tag.toList ++ names do psElabSourceName name
        psElabSourceTacticNames visit fuel body
      | .focus body _ _ | .each body _ _ | .classicalE body _ =>
        psElabSourceTacticNames visit fuel body
      | _ => pure ()

def psElabSourceDoNames (visit : PsSyntaxTerm → Except PsElabError Unit)
    (fuel : Nat) (items : List PsSyntaxDoItem) : Except PsElabError Unit := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    for item in items do
      match item with
      | .binding pattern type value _ _ =>
        psElabSourcePatternNames fuel pattern
        for type in type.toList do visit type
        visit value
      | .action value _ | .returnValue value _ => visit value
      | .conditional name condition yes no _ =>
        for name in name.toList do psElabSourceName name
        visit condition
        psElabSourceDoNames visit fuel yes
        psElabSourceDoNames visit fuel no
      | .conditionalPattern pattern value yes no _ =>
        psElabSourcePatternNames fuel pattern
        visit value
        psElabSourceDoNames visit fuel yes
        psElabSourceDoNames visit fuel no

def psElabSourceTermNames (fuel : Nat) (term : PsSyntaxTerm) :
    Except PsElabError Unit := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let visit := psElabSourceTermNames fuel
    match term with
    | .reference name => psElabSourceName name
    | .operatorE _ name _ arguments _ =>
      psElabSourceName name
      for argument in arguments do visit argument
    | .optionalType type value _ | .ascription value type _ =>
      visit type
      visit value
    | .app fn arguments _ =>
      visit fn
      for argument in arguments do visit argument
    | .call fn arguments _ =>
      visit fn
      for (label, value) in arguments do
        for name in label.toList do psElabSourceName name
        visit value
    | .record fields _ =>
      for (name, value) in fields do
        psElabSourceName name
        visit value
    | .recordUpdate source fields _ =>
      visit source
      for (name, value) in fields do
        psElabSourceName name
        visit value
    | .lambda binders body _ | .forallE binders body _ =>
      for (head, type) in binders do
        psElabSourceBinderNames head
        visit type
      visit body
    | .letE name type value body _ | .haveE name type value body _ =>
      psElabSourceName name
      for type in type.toList do psElabSourceTermNames fuel type
      visit value
      visit body
    | .ifE name condition yes no _ =>
      for name in name.toList do psElabSourceName name
      visit condition
      visit yes
      visit no
    | .matchMany discriminants alternatives _ _ =>
      for discriminant in discriminants do
        for name in discriminant.equationName?.toList do psElabSourceName name
        visit discriminant.term
      for (patterns, body, _) in alternatives do
        for pattern in patterns do psElabSourcePatternNames fuel pattern
        visit body
    | .doE items _ => psElabSourceDoNames visit fuel items
    | .byE tactics scope _ =>
      if scope.abstractProofs || !scope.namePrefix.isEmpty || !scope.opened.isEmpty ||
          !scope.privateAliases.isEmpty || !scope.mutualAliases.isEmpty ||
          !scope.localAliases.isEmpty then
        throw (.scope "source syntax contains an internal proof scope")
      psElabSourceTacticNames visit fuel tactics
    | _ => pure ()

def psElabSourceBinders (binders : List (PsSyntaxBinderHead × PsSyntaxTerm)) :
    Except PsElabError Unit := do
  for (head, type) in binders do
    psElabSourceBinderNames head
    psElabSourceTermNames 4096 type

def psElabSourceTerminationNames (suffix : PsSyntaxTermination) :
    Except PsElabError Unit := do
  psElabSourceTermNames 4096 suffix.measure
  for proof in suffix.decreasing.toList do psElabSourceTermNames 4096 proof

def psElabSourceLocalNames (source : PsSyntaxLocalDefinition) :
    Except PsElabError Unit := do
  psElabSourceName source.name
  psElabSourceBinders source.binders
  for type in source.type.toList do psElabSourceTermNames 4096 type
  psElabSourceTermNames 4096 source.value
  match source.recursion with
  | some (.total suffix) => psElabSourceTerminationNames suffix
  | _ => pure ()

def psElabSourceDeclarationNames (fuel : Nat) (source : PsSyntaxDeclaration) :
    Except PsElabError Unit := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match source with
    | .whereDeclaration parent locals _ =>
      psElabSourceDeclarationNames fuel parent
      for localDefinition in locals do psElabSourceLocalNames localDefinition
    | .definition name binders type value _
    | .partialDefinition name binders type value _
    | .noncomputableDefinition name binders type value _
    | .fixedpointDefinition name binders type value _
    | .theoremDecl name binders type value _ =>
      psElabSourceDeclarationName name
      psElabSourceBinders binders
      psElabSourceTermNames 4096 type
      psElabSourceTermNames 4096 value
    | .wellFoundedDefinition name binders type value suffix _ =>
      psElabSourceDeclarationName name
      psElabSourceBinders binders
      psElabSourceTermNames 4096 type
      psElabSourceTermNames 4096 value
      psElabSourceTerminationNames suffix
    | .structureDecl name parameters result fields _ =>
      psElabSourceDeclarationName name
      psElabSourceBinders parameters
      for result in result.toList do psElabSourceTermNames 4096 result
      psElabSourceBinders fields
    | .inductiveDecl name parameters result constructors _ =>
      psElabSourceDeclarationName name
      psElabSourceBinders parameters
      for result in result.toList do psElabSourceTermNames 4096 result
      for constructor in constructors do
        psElabSourceName constructor.name
        psElabSourceBinders constructor.fields
        for result in constructor.resultType.toList do psElabSourceTermNames 4096 result

def psElabSourceCommandNames (command : PsSyntaxCommand) : Except PsElabError Unit := do
  match command with
  | .declaration source | .privateDeclaration source
  | .registeredDeclaration source _ | .privateRegisteredDeclaration source _
  | .attributedDeclaration source _ _ _ =>
    psElabSourceDeclarationNames 4096 source
  | .derivingDeclaration source handlers _ | .attributedDerivingDeclaration source handlers _ _ =>
    psElabSourceDeclarationNames 4096 source
    for handler in handlers do psElabSourceName handler
  | .mutualDeclarations members _ =>
    for member in members do psElabSourceDeclarationNames 4096 member.declaration
  | .universeCmd names _ | .openCmd names _ | .includeCmd names _ | .omitCmd names _ =>
    for name in names do psElabSourceName name
  | .namespaceCmd name _ => psElabSourceName name
  | .sectionCmd name _ | .endCmd name _ =>
    for name in name.toList do psElabSourceName name
  | .variableCmd binders _ => psElabSourceBinders binders
  | .inspectionCmd command _ =>
    match command with
    | .checkTerm term | .reduceTerm term | .evalTerm term => psElabSourceTermNames 4096 term
    | .printDeclaration name _ => psElabSourceName name
