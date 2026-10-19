import Ps.Kernel.Expr
import Ps.Kernel.Order

/- Raw alpha equality for internal constructor templates, not definitional
conversion or admission. This can compare private fvars without granting them
scope or bypassing the ordinary checker's closed-input rejection. -/
inductive PsKernelExprEqualTask where
  | pair (left right : PsKernelExpr)
  | order (tasks : PsKernelList PsKernelOrderTask)
  | levels (left right : PsKernelList PsKernelLevel)

inductive PsKernelExprEqualState where
  | state (tasks : PsKernelList PsKernelExprEqualTask)

inductive PsKernelExprEqualStep where
  | next (state : PsKernelExprEqualState)
  | equal
  | different
  | invalidState

def psKernelExprEqualNext (tasks : PsKernelList PsKernelExprEqualTask) : PsKernelExprEqualStep :=
  PsKernelExprEqualStep.next (PsKernelExprEqualState.state tasks)

def psKernelExprEqualOrder (task : PsKernelOrderTask) (rest : PsKernelList PsKernelExprEqualTask) : PsKernelExprEqualStep :=
  psKernelExprEqualNext (PsKernelList.cons (PsKernelExprEqualTask.order (PsKernelList.cons task PsKernelList.nil)) rest)

def psKernelExprEqualPair (left right : PsKernelExpr) (rest : PsKernelList PsKernelExprEqualTask) : PsKernelExprEqualStep :=
  match left with
  | PsKernelExpr.bvar index =>
      match right with
      | PsKernelExpr.bvar other => psKernelExprEqualOrder (PsKernelOrderTask.number (PsKernelNumericState.order index other PsKernelOrder.same)) rest
      | _ => PsKernelExprEqualStep.different
  | PsKernelExpr.fvar id =>
      match right with
      | PsKernelExpr.fvar other => psKernelExprEqualOrder (PsKernelOrderTask.number (PsKernelNumericState.order id other PsKernelOrder.same)) rest
      | _ => PsKernelExprEqualStep.different
  | PsKernelExpr.sortE level =>
      match right with
      | PsKernelExpr.sortE other => psKernelExprEqualOrder (PsKernelOrderTask.level level other) rest
      | _ => PsKernelExprEqualStep.different
  | PsKernelExpr.constE name levels =>
      match right with
      | PsKernelExpr.constE otherName otherLevels => psKernelExprEqualOrder (PsKernelOrderTask.name name otherName)
          (PsKernelList.cons (PsKernelExprEqualTask.levels levels otherLevels) rest)
      | _ => PsKernelExprEqualStep.different
  | PsKernelExpr.app fn arg =>
      match right with
      | PsKernelExpr.app otherFn otherArg => psKernelExprEqualNext
          (PsKernelList.cons (PsKernelExprEqualTask.pair fn otherFn) (PsKernelList.cons (PsKernelExprEqualTask.pair arg otherArg) rest))
      | _ => PsKernelExprEqualStep.different
  | PsKernelExpr.lam unusedName type body unusedBinder =>
      match right with
      | PsKernelExpr.lam unusedOtherName otherType otherBody unusedOtherBinder => psKernelExprEqualNext
          (PsKernelList.cons (PsKernelExprEqualTask.pair type otherType) (PsKernelList.cons (PsKernelExprEqualTask.pair body otherBody) rest))
      | _ => PsKernelExprEqualStep.different
  | PsKernelExpr.forallE unusedName type body unusedBinder =>
      match right with
      | PsKernelExpr.forallE unusedOtherName otherType otherBody unusedOtherBinder => psKernelExprEqualNext
          (PsKernelList.cons (PsKernelExprEqualTask.pair type otherType) (PsKernelList.cons (PsKernelExprEqualTask.pair body otherBody) rest))
      | _ => PsKernelExprEqualStep.different
  | PsKernelExpr.letE unusedName type val body =>
      match right with
      | PsKernelExpr.letE unusedOtherName otherType otherVal otherBody => psKernelExprEqualNext
          (PsKernelList.cons (PsKernelExprEqualTask.pair type otherType)
            (PsKernelList.cons (PsKernelExprEqualTask.pair val otherVal) (PsKernelList.cons (PsKernelExprEqualTask.pair body otherBody) rest)))
      | _ => PsKernelExprEqualStep.different
  | PsKernelExpr.proj name index major =>
      match right with
      | PsKernelExpr.proj otherName otherIndex otherMajor => psKernelExprEqualOrder (PsKernelOrderTask.name name otherName)
          (PsKernelList.cons (PsKernelExprEqualTask.order (PsKernelList.cons
            (PsKernelOrderTask.number (PsKernelNumericState.order index otherIndex PsKernelOrder.same)) PsKernelList.nil))
            (PsKernelList.cons (PsKernelExprEqualTask.pair major otherMajor) rest))
      | _ => PsKernelExprEqualStep.different
  | PsKernelExpr.lit literal =>
      match right with
      | PsKernelExpr.lit other =>
          match literal with
          | PsKernelLiteral.natural value =>
              match other with
              | PsKernelLiteral.natural otherValue => psKernelExprEqualOrder
                  (PsKernelOrderTask.number (PsKernelNumericState.order value otherValue PsKernelOrder.same)) rest
              | _ => PsKernelExprEqualStep.different
          | PsKernelLiteral.text value =>
              match other with
              | PsKernelLiteral.text otherValue => psKernelExprEqualOrder (PsKernelOrderTask.text value otherValue) rest
              | _ => PsKernelExprEqualStep.different
      | _ => PsKernelExprEqualStep.different

def psKernelExprEqualStep (state : PsKernelExprEqualState) : PsKernelExprEqualStep :=
  match state with
  | PsKernelExprEqualState.state tasks =>
      match tasks with
      | PsKernelList.nil => PsKernelExprEqualStep.equal
      | PsKernelList.cons task rest =>
          match task with
          | PsKernelExprEqualTask.pair left right => psKernelExprEqualPair left right rest
          | PsKernelExprEqualTask.order current =>
              match psKernelOrderStep current with
              | PsKernelOrderStep.next next => psKernelExprEqualNext (PsKernelList.cons (PsKernelExprEqualTask.order next) rest)
              | PsKernelOrderStep.done order =>
                  match order with
                  | PsKernelOrder.same => psKernelExprEqualNext rest
                  | _ => PsKernelExprEqualStep.different
              | _ => PsKernelExprEqualStep.invalidState
          | PsKernelExprEqualTask.levels left right =>
              match left with
              | PsKernelList.nil =>
                  match right with
                  | PsKernelList.nil => psKernelExprEqualNext rest
                  | _ => PsKernelExprEqualStep.different
              | PsKernelList.cons level tail =>
                  match right with
                  | PsKernelList.cons other otherTail => psKernelExprEqualOrder (PsKernelOrderTask.level level other)
                      (PsKernelList.cons (PsKernelExprEqualTask.levels tail otherTail) rest)
                  | _ => PsKernelExprEqualStep.different

def psKernelExprEqualStart (left right : PsKernelExpr) : PsKernelExprEqualState :=
  PsKernelExprEqualState.state (PsKernelList.cons (PsKernelExprEqualTask.pair left right) PsKernelList.nil)
