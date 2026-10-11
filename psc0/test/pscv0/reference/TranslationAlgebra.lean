-- Appended after the actual generated Translate definitions by the proof gate.
-- Abstract parser/printer results avoid importing their implementation axioms.
-- These lemmas express the refactoring, not correctness of those dependencies.
theorem pscv0_translation_do_algebra
    {epsilon alpha beta : Type}
    (wrap : epsilon -> PsTranslationError)
    (parsed : Except epsilon alpha)
    (render : alpha -> Except PsSourcePrintError beta) :
    (do
      let value <- psTranslationMapError wrap parsed
      psTranslationMapError PsTranslationError.print (render value)) =
    (match parsed with
     | Except.error error => Except.error (wrap error)
     | Except.ok value =>
       match render value with
       | Except.error error => Except.error (PsTranslationError.print error)
       | Except.ok output => Except.ok output) := by
  cases parsed with
  | error error => rfl
  | ok value =>
      change psTranslationMapError PsTranslationError.print (render value) =
        (match render value with
         | Except.error error => Except.error (PsTranslationError.print error)
         | Except.ok output => Except.ok output)
      cases render value <;> rfl

#print axioms pscv0_translation_do_algebra

theorem pscv0_translation_match_algebra
    {epsilon alpha beta : Type}
    (wrap : epsilon -> PsTranslationError)
    (parsed : Except epsilon alpha)
    (render : alpha -> Except PsSourcePrintError beta) :
    (match psTranslationMapError wrap parsed with
     | Except.error error => Except.error error
     | Except.ok value => psTranslationMapError PsTranslationError.print (render value)) =
    (match parsed with
     | Except.error error => Except.error (wrap error)
     | Except.ok value =>
       match render value with
       | Except.error error => Except.error (PsTranslationError.print error)
       | Except.ok output => Except.ok output) := by
  cases parsed with
  | error error => rfl
  | ok value =>
      change psTranslationMapError PsTranslationError.print (render value) =
        (match render value with
         | Except.error error => Except.error (PsTranslationError.print error)
         | Except.ok output => Except.ok output)
      cases render value <;> rfl

#print axioms pscv0_translation_match_algebra
