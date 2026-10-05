import Ps.Kernel.Data
import Ps.Kernel.Natural

/- Internal total structural order, not Lean's name-hash ordering API. -/
inductive PsKernelOrderTask where
  | name (left : PsKernelName) (right : PsKernelName)
  | text (left : PsKernelText) (right : PsKernelText)
  | level (left : PsKernelLevel) (right : PsKernelLevel)
  | number (state : PsKernelNumericState)

inductive PsKernelOrderStep where
  | next (tasks : PsKernelList PsKernelOrderTask)
  | done (order : PsKernelOrder)
  | invalidState

def psKernelOrderStep (tasks : PsKernelList PsKernelOrderTask) : PsKernelOrderStep :=
  match tasks with
  | PsKernelList.nil => PsKernelOrderStep.done PsKernelOrder.same
  | PsKernelList.cons task rest =>
      match task with
      | PsKernelOrderTask.number state =>
          match psKernelNumericStep state with
          | PsKernelNumericStep.next next =>
              PsKernelOrderStep.next (PsKernelList.cons (PsKernelOrderTask.number next) rest)
          | PsKernelNumericStep.ordered order =>
              match order with
              | PsKernelOrder.same => PsKernelOrderStep.next rest
              | PsKernelOrder.less => PsKernelOrderStep.done PsKernelOrder.less
              | PsKernelOrder.greater => PsKernelOrderStep.done PsKernelOrder.greater
          | _ => PsKernelOrderStep.invalidState
      | PsKernelOrderTask.name left right =>
          match left with
          | PsKernelName.anonymous =>
              match right with
              | PsKernelName.anonymous => PsKernelOrderStep.next rest
              | PsKernelName.str rParent rValue => PsKernelOrderStep.done PsKernelOrder.less
              | PsKernelName.num rParent rValue => PsKernelOrderStep.done PsKernelOrder.less
          | PsKernelName.str lParent lValue =>
              match right with
              | PsKernelName.anonymous => PsKernelOrderStep.done PsKernelOrder.greater
              | PsKernelName.str rParent rValue => PsKernelOrderStep.next (PsKernelList.cons (PsKernelOrderTask.name lParent rParent) (PsKernelList.cons (PsKernelOrderTask.text lValue rValue) rest))
              | PsKernelName.num rParent rValue => PsKernelOrderStep.done PsKernelOrder.less
          | PsKernelName.num lParent lValue =>
              match right with
              | PsKernelName.anonymous => PsKernelOrderStep.done PsKernelOrder.greater
              | PsKernelName.str rParent rValue => PsKernelOrderStep.done PsKernelOrder.greater
              | PsKernelName.num rParent rValue => PsKernelOrderStep.next (PsKernelList.cons (PsKernelOrderTask.name lParent rParent) (PsKernelList.cons (PsKernelOrderTask.number (PsKernelNumericState.order lValue rValue PsKernelOrder.same)) rest))
      | PsKernelOrderTask.level left right =>
          match left with
          | PsKernelLevel.zero =>
              match right with
              | PsKernelLevel.zero => PsKernelOrderStep.next rest
              | PsKernelLevel.succ rValue => PsKernelOrderStep.done PsKernelOrder.less
              | PsKernelLevel.max rLeft rRight => PsKernelOrderStep.done PsKernelOrder.less
              | PsKernelLevel.imax rLeft rRight => PsKernelOrderStep.done PsKernelOrder.less
              | PsKernelLevel.param rName => PsKernelOrderStep.done PsKernelOrder.less
          | PsKernelLevel.succ lValue =>
              match right with
              | PsKernelLevel.zero => PsKernelOrderStep.done PsKernelOrder.greater
              | PsKernelLevel.succ rValue => PsKernelOrderStep.next (PsKernelList.cons (PsKernelOrderTask.level lValue rValue) rest)
              | PsKernelLevel.max rLeft rRight => PsKernelOrderStep.done PsKernelOrder.less
              | PsKernelLevel.imax rLeft rRight => PsKernelOrderStep.done PsKernelOrder.less
              | PsKernelLevel.param rName => PsKernelOrderStep.done PsKernelOrder.less
          | PsKernelLevel.max lLeft lRight =>
              match right with
              | PsKernelLevel.zero => PsKernelOrderStep.done PsKernelOrder.greater
              | PsKernelLevel.succ rValue => PsKernelOrderStep.done PsKernelOrder.greater
              | PsKernelLevel.max rLeft rRight => PsKernelOrderStep.next (PsKernelList.cons (PsKernelOrderTask.level lLeft rLeft) (PsKernelList.cons (PsKernelOrderTask.level lRight rRight) rest))
              | PsKernelLevel.imax rLeft rRight => PsKernelOrderStep.done PsKernelOrder.less
              | PsKernelLevel.param rName => PsKernelOrderStep.done PsKernelOrder.less
          | PsKernelLevel.imax lLeft lRight =>
              match right with
              | PsKernelLevel.zero => PsKernelOrderStep.done PsKernelOrder.greater
              | PsKernelLevel.succ rValue => PsKernelOrderStep.done PsKernelOrder.greater
              | PsKernelLevel.max rLeft rRight => PsKernelOrderStep.done PsKernelOrder.greater
              | PsKernelLevel.imax rLeft rRight => PsKernelOrderStep.next (PsKernelList.cons (PsKernelOrderTask.level lLeft rLeft) (PsKernelList.cons (PsKernelOrderTask.level lRight rRight) rest))
              | PsKernelLevel.param rName => PsKernelOrderStep.done PsKernelOrder.less
          | PsKernelLevel.param lName =>
              match right with
              | PsKernelLevel.zero => PsKernelOrderStep.done PsKernelOrder.greater
              | PsKernelLevel.succ rValue => PsKernelOrderStep.done PsKernelOrder.greater
              | PsKernelLevel.max rLeft rRight => PsKernelOrderStep.done PsKernelOrder.greater
              | PsKernelLevel.imax rLeft rRight => PsKernelOrderStep.done PsKernelOrder.greater
              | PsKernelLevel.param rName => PsKernelOrderStep.next (PsKernelList.cons (PsKernelOrderTask.name lName rName) rest)
      | PsKernelOrderTask.text left right =>
          match left with
          | PsKernelText.empty =>
              match right with
              | PsKernelText.empty => PsKernelOrderStep.next rest
              | PsKernelText.byte rValue rRest => PsKernelOrderStep.done PsKernelOrder.less
          | PsKernelText.byte lValue lRest =>
              match right with
              | PsKernelText.empty => PsKernelOrderStep.done PsKernelOrder.greater
              | PsKernelText.byte rValue rRest => PsKernelOrderStep.next (PsKernelList.cons (PsKernelOrderTask.number (PsKernelNumericState.order lValue rValue PsKernelOrder.same)) (PsKernelList.cons (PsKernelOrderTask.text lRest rRest) rest))
