import Ps.Kernel.AlgebraicMinor

/- Dependent eliminator derivation for one uniform Type0 family. Fresh private
variables are allocated beyond every parameter/motive/minor and then closed by
the capture-avoiding binding machine. No recursor type or reduction metadata is
accepted from input. The final closed type is checked by admission. -/

def psKernelAlgRecursorLevelName : PsKernelName :=
  PsKernelName.num PsKernelName.anonymous PsKernelNatural.zero

inductive PsKernelAlgRecursorFrame where
  | frame (pending : PsKernelList PsKernelAlgConstructor) (index minorId fieldStart : PsKernelNatural)
      (binders : PsKernelList PsKernelAlgBinder) (rules : PsKernelList PsKernelAlgRule)

inductive PsKernelAlgRecursorTask where
  | count (pending : PsKernelList PsKernelAlgConstructor) (fieldStart : PsKernelNatural)
  | minors (frame : PsKernelAlgRecursorFrame)
  | minor (frame : PsKernelAlgRecursorFrame) (constructor : PsKernelAlgConstructor) (state : PsKernelAlgMinorState)
  | reverseBinders (fieldStart : PsKernelNatural) (pending forward : PsKernelList PsKernelAlgBinder)
      (rules : PsKernelList PsKernelAlgRule)
  | binders (fieldStart : PsKernelNatural) (pending binders : PsKernelList PsKernelAlgBinder)
      (rules : PsKernelList PsKernelAlgRule)
  | reverseRules (fieldStart : PsKernelNatural) (binders : PsKernelList PsKernelAlgBinder)
      (pending rules : PsKernelList PsKernelAlgRule)
  | close (rules : PsKernelList PsKernelAlgRule) (state : PsKernelCloseState)

inductive PsKernelAlgRecursorState where
  | state (header : PsKernelAlgHeader) (constructors : PsKernelList PsKernelAlgConstructor) (task : PsKernelAlgRecursorTask)

inductive PsKernelAlgRecursorStep where
  | next (state : PsKernelAlgRecursorState)
  | ready (type : PsKernelExpr) (rules : PsKernelList PsKernelAlgRule)
  | rejected (error : PsKernelCheckError)

def psKernelAlgRecursorNext (header : PsKernelAlgHeader) (constructors : PsKernelList PsKernelAlgConstructor)
    (task : PsKernelAlgRecursorTask) : PsKernelAlgRecursorStep :=
  PsKernelAlgRecursorStep.next (PsKernelAlgRecursorState.state header constructors task)

def psKernelAlgRecursorStep (state : PsKernelAlgRecursorState) : PsKernelAlgRecursorStep :=
  match state with
  | PsKernelAlgRecursorState.state header constructors task =>
      match header with
      | PsKernelAlgHeader.header unusedName unusedType parameters unusedArguments parameterBinders uniform =>
          match task with
          | PsKernelAlgRecursorTask.count pending fieldStart =>
              match pending with
              | PsKernelList.cons unused rest => psKernelAlgRecursorNext header constructors
                  (PsKernelAlgRecursorTask.count rest (psKernelNaturalSucc fieldStart))
              | PsKernelList.nil => psKernelAlgRecursorNext header constructors (PsKernelAlgRecursorTask.minors
                  (PsKernelAlgRecursorFrame.frame constructors PsKernelNatural.zero (psKernelNaturalSucc parameters)
                    fieldStart PsKernelList.nil PsKernelList.nil))
          | PsKernelAlgRecursorTask.minors frame =>
              match frame with
              | PsKernelAlgRecursorFrame.frame pending index minorId fieldStart binders rules =>
                  match pending with
                  | PsKernelList.cons constructor rest => psKernelAlgRecursorNext header constructors
                      (PsKernelAlgRecursorTask.minor
                        (PsKernelAlgRecursorFrame.frame rest index minorId fieldStart binders rules) constructor
                        (psKernelAlgMinorStart header constructor fieldStart))
                  | PsKernelList.nil => psKernelAlgRecursorNext header constructors
                      (PsKernelAlgRecursorTask.reverseBinders fieldStart binders PsKernelList.nil rules)
          | PsKernelAlgRecursorTask.minor frame constructor current =>
              match psKernelAlgMinorStep current with
              | PsKernelAlgMinorStep.next next => psKernelAlgRecursorNext header constructors
                  (PsKernelAlgRecursorTask.minor frame constructor next)
              | PsKernelAlgMinorStep.rejected error => PsKernelAlgRecursorStep.rejected error
              | PsKernelAlgMinorStep.ready type flags =>
                  match frame with
                  | PsKernelAlgRecursorFrame.frame pending index minorId fieldStart binders rules =>
                      match constructor with
                      | PsKernelAlgConstructor.constructor name unusedConstructorType unusedFields =>
                          psKernelAlgRecursorNext header constructors (PsKernelAlgRecursorTask.minors
                            (PsKernelAlgRecursorFrame.frame pending (psKernelNaturalSucc index)
                              (psKernelNaturalSucc minorId) fieldStart
                              (PsKernelList.cons (PsKernelAlgBinder.binder minorId type PsKernelBinder.explicit) binders)
                              (PsKernelList.cons (PsKernelAlgRule.rule name parameters index flags) rules)))
          | PsKernelAlgRecursorTask.reverseBinders fieldStart pending forward rules =>
              match pending with
              | PsKernelList.cons binder rest => psKernelAlgRecursorNext header constructors
                  (PsKernelAlgRecursorTask.reverseBinders fieldStart rest (PsKernelList.cons binder forward) rules)
              | PsKernelList.nil =>
                  let motiveType := PsKernelExpr.forallE PsKernelName.anonymous uniform
                    (PsKernelExpr.sortE (PsKernelLevel.param psKernelAlgRecursorLevelName)) PsKernelBinder.explicit;
                  psKernelAlgRecursorNext header constructors (PsKernelAlgRecursorTask.binders fieldStart forward
                    (PsKernelList.cons (PsKernelAlgBinder.binder parameters motiveType PsKernelBinder.implicit) parameterBinders) rules)
          | PsKernelAlgRecursorTask.binders fieldStart pending binders rules =>
              match pending with
              | PsKernelList.cons binder rest => psKernelAlgRecursorNext header constructors
                  (PsKernelAlgRecursorTask.binders fieldStart rest (PsKernelList.cons binder binders) rules)
              | PsKernelList.nil => psKernelAlgRecursorNext header constructors
                  (PsKernelAlgRecursorTask.reverseRules fieldStart binders rules PsKernelList.nil)
          | PsKernelAlgRecursorTask.reverseRules fieldStart binders pending rules =>
              match pending with
              | PsKernelList.cons rule rest => psKernelAlgRecursorNext header constructors
                  (PsKernelAlgRecursorTask.reverseRules fieldStart binders rest (PsKernelList.cons rule rules))
              | PsKernelList.nil => psKernelAlgRecursorNext header constructors
                  (PsKernelAlgRecursorTask.close rules (psKernelCloseStart PsKernelCloseMode.pi
                    (PsKernelList.cons (PsKernelAlgBinder.binder fieldStart uniform PsKernelBinder.explicit) binders)
                    (PsKernelExpr.app (PsKernelExpr.fvar parameters) (PsKernelExpr.fvar fieldStart))))
          | PsKernelAlgRecursorTask.close rules current =>
              match psKernelCloseStep current with
              | PsKernelCloseStep.next next => psKernelAlgRecursorNext header constructors
                  (PsKernelAlgRecursorTask.close rules next)
              | PsKernelCloseStep.done value => PsKernelAlgRecursorStep.ready value rules
              | _ => PsKernelAlgRecursorStep.rejected PsKernelCheckError.invalidState

def psKernelAlgRecursorStart (header : PsKernelAlgHeader)
    (constructors : PsKernelList PsKernelAlgConstructor) : PsKernelAlgRecursorState :=
  match header with
  | PsKernelAlgHeader.header unusedName unusedType parameters unusedArguments unusedBinders unusedUniform =>
      PsKernelAlgRecursorState.state header constructors
        (PsKernelAlgRecursorTask.count constructors (psKernelNaturalSucc parameters))
