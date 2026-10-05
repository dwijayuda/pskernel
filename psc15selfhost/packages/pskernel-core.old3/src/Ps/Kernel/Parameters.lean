import Ps.Kernel.Binding

/- Simultaneous instantiation of a template whose only free bound variables are
its declared type parameters. Replacements may themselves be open. Each lookup,
reversal, lift and reconstruction shares the enclosing transition budget. -/

inductive PsKernelParameterTask where
  | reverse (pending reversed : PsKernelList PsKernelExpr) (value : PsKernelExpr)
  | visit (depth : PsKernelNatural) (value : PsKernelExpr)
  | bound (original index remainingDepth depth : PsKernelNatural)
  | select (index depth : PsKernelNatural) (arguments : PsKernelList PsKernelExpr)
  | lift (state : PsKernelBindingState)
  | app
  | lam (name : PsKernelName) (binder : PsKernelBinder)
  | forallE (name : PsKernelName) (binder : PsKernelBinder)
  | letE (name : PsKernelName)
  | proj (family : PsKernelName) (index : PsKernelNatural)

inductive PsKernelParameterState where
  | state (arguments : PsKernelList PsKernelExpr) (tasks : PsKernelList PsKernelParameterTask) (values : PsKernelList PsKernelExpr)

inductive PsKernelParameterResult where
  | done (value : PsKernelExpr)
  | invalidScope
  | invalidState
  | outOfFuel

inductive PsKernelParameterStep where
  | next (state : PsKernelParameterState)
  | final (result : PsKernelParameterResult)

def psKernelParameterNext (arguments : PsKernelList PsKernelExpr)
    (tasks : PsKernelList PsKernelParameterTask) (values : PsKernelList PsKernelExpr) : PsKernelParameterStep :=
  PsKernelParameterStep.next (PsKernelParameterState.state arguments tasks values)

def psKernelParameterPush (arguments : PsKernelList PsKernelExpr)
    (tasks : PsKernelList PsKernelParameterTask) (values : PsKernelList PsKernelExpr) (value : PsKernelExpr) : PsKernelParameterStep :=
  psKernelParameterNext arguments tasks (PsKernelList.cons value values)

def psKernelParameterVisit (arguments : PsKernelList PsKernelExpr) (depth : PsKernelNatural) (value : PsKernelExpr)
    (tasks : PsKernelList PsKernelParameterTask) (values : PsKernelList PsKernelExpr) : PsKernelParameterStep :=
  match value with
  | PsKernelExpr.bvar index => psKernelParameterNext arguments
      (PsKernelList.cons (PsKernelParameterTask.bound index index depth depth) tasks) values
  | PsKernelExpr.fvar unused => PsKernelParameterStep.final PsKernelParameterResult.invalidScope
  | PsKernelExpr.sortE unused => psKernelParameterPush arguments tasks values value
  | PsKernelExpr.constE unusedName unusedLevels => psKernelParameterPush arguments tasks values value
  | PsKernelExpr.lit unused => psKernelParameterPush arguments tasks values value
  | PsKernelExpr.app fn arg => psKernelParameterNext arguments
      (PsKernelList.cons (PsKernelParameterTask.visit depth fn)
        (PsKernelList.cons (PsKernelParameterTask.visit depth arg)
          (PsKernelList.cons PsKernelParameterTask.app tasks))) values
  | PsKernelExpr.lam name type body binder => psKernelParameterNext arguments
      (PsKernelList.cons (PsKernelParameterTask.visit depth type)
        (PsKernelList.cons (PsKernelParameterTask.visit (psKernelNaturalSucc depth) body)
          (PsKernelList.cons (PsKernelParameterTask.lam name binder) tasks))) values
  | PsKernelExpr.forallE name type body binder => psKernelParameterNext arguments
      (PsKernelList.cons (PsKernelParameterTask.visit depth type)
        (PsKernelList.cons (PsKernelParameterTask.visit (psKernelNaturalSucc depth) body)
          (PsKernelList.cons (PsKernelParameterTask.forallE name binder) tasks))) values
  | PsKernelExpr.letE name type val body => psKernelParameterNext arguments
      (PsKernelList.cons (PsKernelParameterTask.visit depth type)
        (PsKernelList.cons (PsKernelParameterTask.visit depth val)
          (PsKernelList.cons (PsKernelParameterTask.visit (psKernelNaturalSucc depth) body)
            (PsKernelList.cons (PsKernelParameterTask.letE name) tasks)))) values
  | PsKernelExpr.proj family index major => psKernelParameterNext arguments
      (PsKernelList.cons (PsKernelParameterTask.visit depth major)
        (PsKernelList.cons (PsKernelParameterTask.proj family index) tasks)) values

def psKernelParameterRebuild (arguments : PsKernelList PsKernelExpr) (task : PsKernelParameterTask)
    (tasks : PsKernelList PsKernelParameterTask) (values : PsKernelList PsKernelExpr) : PsKernelParameterStep :=
  match values with
  | PsKernelList.nil => PsKernelParameterStep.final PsKernelParameterResult.invalidState
  | PsKernelList.cons top rest =>
      match task with
      | PsKernelParameterTask.proj family index => psKernelParameterPush arguments tasks rest (PsKernelExpr.proj family index top)
      | PsKernelParameterTask.app =>
          match rest with
          | PsKernelList.cons fn tail => psKernelParameterPush arguments tasks tail (PsKernelExpr.app fn top)
          | _ => PsKernelParameterStep.final PsKernelParameterResult.invalidState
      | PsKernelParameterTask.lam name binder =>
          match rest with
          | PsKernelList.cons type tail => psKernelParameterPush arguments tasks tail (PsKernelExpr.lam name type top binder)
          | _ => PsKernelParameterStep.final PsKernelParameterResult.invalidState
      | PsKernelParameterTask.forallE name binder =>
          match rest with
          | PsKernelList.cons type tail => psKernelParameterPush arguments tasks tail (PsKernelExpr.forallE name type top binder)
          | _ => PsKernelParameterStep.final PsKernelParameterResult.invalidState
      | PsKernelParameterTask.letE name =>
          match rest with
          | PsKernelList.cons val tail =>
              match tail with
              | PsKernelList.cons type remaining => psKernelParameterPush arguments tasks remaining (PsKernelExpr.letE name type val top)
              | _ => PsKernelParameterStep.final PsKernelParameterResult.invalidState
          | _ => PsKernelParameterStep.final PsKernelParameterResult.invalidState
      | _ => PsKernelParameterStep.final PsKernelParameterResult.invalidState

def psKernelParameterStep (state : PsKernelParameterState) : PsKernelParameterStep :=
  match state with
  | PsKernelParameterState.state arguments tasks values =>
      match tasks with
      | PsKernelList.nil =>
          match values with
          | PsKernelList.cons value rest =>
              match rest with
              | PsKernelList.nil => PsKernelParameterStep.final (PsKernelParameterResult.done value)
              | _ => PsKernelParameterStep.final PsKernelParameterResult.invalidState
          | _ => PsKernelParameterStep.final PsKernelParameterResult.invalidState
      | PsKernelList.cons task rest =>
          match task with
          | PsKernelParameterTask.reverse pending reversed value =>
              match pending with
              | PsKernelList.nil => psKernelParameterNext reversed
                  (PsKernelList.cons (PsKernelParameterTask.visit PsKernelNatural.zero value) rest) values
              | PsKernelList.cons arg tail => psKernelParameterNext arguments
                  (PsKernelList.cons (PsKernelParameterTask.reverse tail (PsKernelList.cons arg reversed) value) rest) values
          | PsKernelParameterTask.visit depth value => psKernelParameterVisit arguments depth value rest values
          | PsKernelParameterTask.bound original index remainingDepth depth =>
              match remainingDepth with
              | PsKernelNatural.zero => psKernelParameterNext arguments
                  (PsKernelList.cons (PsKernelParameterTask.select index depth arguments) rest) values
              | _ =>
                  match index with
                  | PsKernelNatural.zero => psKernelParameterPush arguments rest values (PsKernelExpr.bvar original)
                  | _ => psKernelParameterNext arguments
                      (PsKernelList.cons (PsKernelParameterTask.bound original (psKernelNaturalPred index)
                        (psKernelNaturalPred remainingDepth) depth) rest) values
          | PsKernelParameterTask.select index depth pending =>
              match pending with
              | PsKernelList.nil => PsKernelParameterStep.final PsKernelParameterResult.invalidScope
              | PsKernelList.cons arg tail =>
                  match index with
                  | PsKernelNatural.zero => psKernelParameterNext arguments
                      (PsKernelList.cons (PsKernelParameterTask.lift
                        (psKernelBindingStart (PsKernelBindingMode.lift depth) PsKernelNatural.zero arg)) rest) values
                  | _ => psKernelParameterNext arguments
                      (PsKernelList.cons (PsKernelParameterTask.select (psKernelNaturalPred index) depth tail) rest) values
          | PsKernelParameterTask.lift current =>
              match psKernelBindingStep current with
              | PsKernelBindingStep.next next => psKernelParameterNext arguments
                  (PsKernelList.cons (PsKernelParameterTask.lift next) rest) values
              | PsKernelBindingStep.final result =>
                  match result with
                  | PsKernelBindingResult.done value => psKernelParameterPush arguments rest values value
                  | PsKernelBindingResult.invalidScope => PsKernelParameterStep.final PsKernelParameterResult.invalidScope
                  | _ => PsKernelParameterStep.final PsKernelParameterResult.invalidState
          | _ => psKernelParameterRebuild arguments task rest values

def psKernelParameterStart (arguments : PsKernelList PsKernelExpr) (value : PsKernelExpr) : PsKernelParameterState :=
  PsKernelParameterState.state PsKernelList.nil
    (PsKernelList.cons (PsKernelParameterTask.reverse arguments PsKernelList.nil value) PsKernelList.nil) PsKernelList.nil

def psKernelParameterRun (fuel : PsKernelFuel) : PsKernelParameterState -> PsKernelParameterResult :=
  match fuel with
  | PsKernelFuel.stop => fun (state : PsKernelParameterState) => PsKernelParameterResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelParameterState) =>
        match psKernelParameterStep state with
        | PsKernelParameterStep.final result => result
        | PsKernelParameterStep.next next =>
            let smaller : PsKernelParameterState -> PsKernelParameterResult := psKernelParameterRun remaining;
            smaller next
