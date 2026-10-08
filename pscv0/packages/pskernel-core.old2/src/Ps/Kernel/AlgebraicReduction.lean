import Ps.Kernel.Environment

/- Charged iota spine traversal. The outer reduction machine normalizes the
major when requested and resumes this machine with the result. Metadata comes
only from completed algebraic admission. Full typing checks every argument,
including discarded fields, before a declaration can be admitted. -/

inductive PsKernelAlgBranch where
  | branch (name : PsKernelName) (parameters : PsKernelNatural)
      (fields : PsKernelList (PsKernelOption PsKernelName)) (minor : PsKernelExpr)

inductive PsKernelAlgReduceContinuation where
  | continuation (recHead : PsKernelExpr) (branches : PsKernelList PsKernelAlgBranch)

inductive PsKernelAlgReduceState where
  | parameters (original recHead : PsKernelExpr) (remaining : PsKernelNatural)
      (rules : PsKernelList PsKernelAlgRule) (args : PsKernelList PsKernelExpr)
  | motive (original recHead : PsKernelExpr) (rules : PsKernelList PsKernelAlgRule) (args : PsKernelList PsKernelExpr)
  | minors (original recHead : PsKernelExpr) (rules : PsKernelList PsKernelAlgRule)
      (args : PsKernelList PsKernelExpr) (branches : PsKernelList PsKernelAlgBranch)
  | spine (recHead major cursor : PsKernelExpr) (args : PsKernelList PsKernelExpr)
      (branches : PsKernelList PsKernelAlgBranch)
  | find (recHead major : PsKernelExpr) (name : PsKernelName) (args : PsKernelList PsKernelExpr)
      (branches : PsKernelList PsKernelAlgBranch)
  | compare (recHead major : PsKernelExpr) (name : PsKernelName) (args : PsKernelList PsKernelExpr)
      (branch : PsKernelAlgBranch) (branches : PsKernelList PsKernelAlgBranch) (tasks : PsKernelList PsKernelOrderTask)
  | drop (recHead minor : PsKernelExpr) (remaining : PsKernelNatural)
      (fields : PsKernelList (PsKernelOption PsKernelName)) (args : PsKernelList PsKernelExpr)
  | fields (recHead minor : PsKernelExpr) (fields : PsKernelList (PsKernelOption PsKernelName))
      (args recursive : PsKernelList PsKernelExpr)
  | reverse (recHead minor : PsKernelExpr) (pending recursive : PsKernelList PsKernelExpr)
  | hypotheses (recHead minor : PsKernelExpr) (recursive : PsKernelList PsKernelExpr)

inductive PsKernelAlgReduceStep where
  | next (state : PsKernelAlgReduceState)
  | major (value : PsKernelExpr) (continuation : PsKernelAlgReduceContinuation)
  | neutral (value : PsKernelExpr)
  | reduced (value : PsKernelExpr)
  | rejected (error : PsKernelCheckError)

def psKernelAlgReduceStep (state : PsKernelAlgReduceState) : PsKernelAlgReduceStep :=
  match state with
  | PsKernelAlgReduceState.parameters original recHead remaining rules args =>
      match remaining with
      | PsKernelNatural.zero => PsKernelAlgReduceStep.next (PsKernelAlgReduceState.motive original recHead rules args)
      | _ =>
          match args with
          | PsKernelList.cons arg rest => PsKernelAlgReduceStep.next
              (PsKernelAlgReduceState.parameters original (PsKernelExpr.app recHead arg) (psKernelNaturalPred remaining) rules rest)
          | _ => PsKernelAlgReduceStep.neutral original
  | PsKernelAlgReduceState.motive original recHead rules args =>
      match args with
      | PsKernelList.cons motive rest => PsKernelAlgReduceStep.next
          (PsKernelAlgReduceState.minors original (PsKernelExpr.app recHead motive) rules rest PsKernelList.nil)
      | _ => PsKernelAlgReduceStep.neutral original
  | PsKernelAlgReduceState.minors original recHead rules args branches =>
      match rules with
      | PsKernelList.cons rule rest =>
          match args with
          | PsKernelList.cons minor tail =>
              match rule with
              | PsKernelAlgRule.rule name parameters unusedIndex fields => PsKernelAlgReduceStep.next
                  (PsKernelAlgReduceState.minors original (PsKernelExpr.app recHead minor) rest tail
                    (PsKernelList.cons (PsKernelAlgBranch.branch name parameters fields minor) branches))
          | _ => PsKernelAlgReduceStep.neutral original
      | PsKernelList.nil =>
          match args with
          | PsKernelList.cons major tail =>
              match tail with
              | PsKernelList.nil => PsKernelAlgReduceStep.major major (PsKernelAlgReduceContinuation.continuation recHead branches)
              | _ => PsKernelAlgReduceStep.neutral original
          | _ => PsKernelAlgReduceStep.neutral original
  | PsKernelAlgReduceState.spine recHead major cursor args branches =>
      match cursor with
      | PsKernelExpr.app fn arg => PsKernelAlgReduceStep.next
          (PsKernelAlgReduceState.spine recHead major fn (PsKernelList.cons arg args) branches)
      | PsKernelExpr.constE name levels =>
          match levels with
          | PsKernelList.nil => PsKernelAlgReduceStep.next (PsKernelAlgReduceState.find recHead major name args branches)
          | _ => PsKernelAlgReduceStep.neutral (PsKernelExpr.app recHead major)
      | _ => PsKernelAlgReduceStep.neutral (PsKernelExpr.app recHead major)
  | PsKernelAlgReduceState.find recHead major name args branches =>
      match branches with
      | PsKernelList.nil => PsKernelAlgReduceStep.neutral (PsKernelExpr.app recHead major)
      | PsKernelList.cons branch rest =>
          match branch with
          | PsKernelAlgBranch.branch constructor unusedParameters unusedFields unusedMinor => PsKernelAlgReduceStep.next
              (PsKernelAlgReduceState.compare recHead major name args branch rest
                (PsKernelList.cons (PsKernelOrderTask.name constructor name) PsKernelList.nil))
  | PsKernelAlgReduceState.compare recHead major name args branch branches current =>
      match psKernelOrderStep current with
      | PsKernelOrderStep.next next => PsKernelAlgReduceStep.next
          (PsKernelAlgReduceState.compare recHead major name args branch branches next)
      | PsKernelOrderStep.done order =>
          match order with
          | PsKernelOrder.same =>
              match branch with
              | PsKernelAlgBranch.branch unusedName parameters fields minor => PsKernelAlgReduceStep.next
                  (PsKernelAlgReduceState.drop recHead minor parameters fields args)
          | _ => PsKernelAlgReduceStep.next (PsKernelAlgReduceState.find recHead major name args branches)
      | _ => PsKernelAlgReduceStep.rejected PsKernelCheckError.invalidState
  | PsKernelAlgReduceState.drop recHead minor remaining fields args =>
      match remaining with
      | PsKernelNatural.zero => PsKernelAlgReduceStep.next (PsKernelAlgReduceState.fields recHead minor fields args PsKernelList.nil)
      | _ =>
          match args with
          | PsKernelList.cons unused rest => PsKernelAlgReduceStep.next
              (PsKernelAlgReduceState.drop recHead minor (psKernelNaturalPred remaining) fields rest)
          | _ => PsKernelAlgReduceStep.rejected PsKernelCheckError.typeMismatch
  | PsKernelAlgReduceState.fields recHead minor fields args recursive =>
      match fields with
      | PsKernelList.nil =>
          match args with
          | PsKernelList.nil => PsKernelAlgReduceStep.next (PsKernelAlgReduceState.reverse recHead minor recursive PsKernelList.nil)
          | _ => PsKernelAlgReduceStep.rejected PsKernelCheckError.typeMismatch
      | PsKernelList.cons flag rest =>
          match args with
          | PsKernelList.cons arg tail =>
              match flag with
              | PsKernelOption.none => PsKernelAlgReduceStep.next
                  (PsKernelAlgReduceState.fields recHead (PsKernelExpr.app minor arg) rest tail recursive)
              | PsKernelOption.some unusedRecursor => PsKernelAlgReduceStep.next
                  (PsKernelAlgReduceState.fields recHead (PsKernelExpr.app minor arg) rest tail (PsKernelList.cons arg recursive))
          | _ => PsKernelAlgReduceStep.rejected PsKernelCheckError.typeMismatch
  | PsKernelAlgReduceState.reverse recHead minor pending recursive =>
      match pending with
      | PsKernelList.cons arg rest => PsKernelAlgReduceStep.next
          (PsKernelAlgReduceState.reverse recHead minor rest (PsKernelList.cons arg recursive))
      | PsKernelList.nil => PsKernelAlgReduceStep.next (PsKernelAlgReduceState.hypotheses recHead minor recursive)
  | PsKernelAlgReduceState.hypotheses recHead minor recursive =>
      match recursive with
      | PsKernelList.cons arg rest => PsKernelAlgReduceStep.next
          (PsKernelAlgReduceState.hypotheses recHead (PsKernelExpr.app minor (PsKernelExpr.app recHead arg)) rest)
      | PsKernelList.nil => PsKernelAlgReduceStep.reduced minor

def psKernelAlgReduceStart (original head : PsKernelExpr) (parameters : PsKernelNatural)
    (rules : PsKernelList PsKernelAlgRule) (args : PsKernelList PsKernelExpr) : PsKernelAlgReduceState :=
  PsKernelAlgReduceState.parameters original head parameters rules args

def psKernelAlgReduceResume (continuation : PsKernelAlgReduceContinuation) (major : PsKernelExpr) : PsKernelAlgReduceState :=
  match continuation with
  | PsKernelAlgReduceContinuation.continuation recHead branches => PsKernelAlgReduceState.spine recHead major major PsKernelList.nil branches
