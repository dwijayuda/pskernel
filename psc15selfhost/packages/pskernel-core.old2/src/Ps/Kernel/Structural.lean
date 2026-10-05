import Ps.Kernel.Data

/-
An explicit work list shares one fuel counter across ALL children and name/text
comparisons. Fuel bounds tasks, not elapsed time, allocation, or host stack use.
This is structural comparison only. It is NOT universe equivalence or conversion.
-/
def psKernelCompareTasks
    (fuel : PsKernelFuel) :
    PsKernelList PsKernelCompareTask -> PsKernelCompareResult :=
  match fuel with
  | PsKernelFuel.stop =>
      fun (tasks : PsKernelList PsKernelCompareTask) =>
        match tasks with
        | PsKernelList.nil => PsKernelCompareResult.equal
        | PsKernelList.cons unusedHead unusedTail => PsKernelCompareResult.outOfFuel
  | PsKernelFuel.more remaining =>
      let smaller : PsKernelList PsKernelCompareTask -> PsKernelCompareResult :=
        psKernelCompareTasks remaining;
      fun (tasks : PsKernelList PsKernelCompareTask) =>
        match tasks with
        | PsKernelList.nil => PsKernelCompareResult.equal
        | PsKernelList.cons task rest =>
            match task with
            | PsKernelCompareTask.positive left right =>
                match left with
                | PsKernelPositive.one =>
                    match right with
                    | PsKernelPositive.one => smaller rest
                    | _ => PsKernelCompareResult.different
                | PsKernelPositive.bit0 leftHigh =>
                    match right with
                    | PsKernelPositive.bit0 rightHigh =>
                        smaller
                          (PsKernelList.cons (PsKernelCompareTask.positive leftHigh rightHigh) rest)
                    | _ => PsKernelCompareResult.different
                | PsKernelPositive.bit1 leftHigh =>
                    match right with
                    | PsKernelPositive.bit1 rightHigh =>
                        smaller
                          (PsKernelList.cons (PsKernelCompareTask.positive leftHigh rightHigh) rest)
                    | _ => PsKernelCompareResult.different
            | PsKernelCompareTask.natural left right =>
                match left with
                | PsKernelNatural.zero =>
                    match right with
                    | PsKernelNatural.zero => smaller rest
                    | _ => PsKernelCompareResult.different
                | PsKernelNatural.positive leftValue =>
                    match right with
                    | PsKernelNatural.positive rightValue =>
                        smaller
                          (PsKernelList.cons (PsKernelCompareTask.positive leftValue rightValue) rest)
                    | _ => PsKernelCompareResult.different
            | PsKernelCompareTask.name left right =>
                match left with
                | PsKernelName.anonymous =>
                    match right with
                    | PsKernelName.anonymous => smaller rest
                    | _ => PsKernelCompareResult.different
                | PsKernelName.str leftParent leftValue =>
                    match right with
                    | PsKernelName.str rightParent rightValue =>
                        smaller
                          (PsKernelList.cons (PsKernelCompareTask.name leftParent rightParent)
                            (PsKernelList.cons (PsKernelCompareTask.text leftValue rightValue) rest))
                    | _ => PsKernelCompareResult.different
                | PsKernelName.num leftParent leftValue =>
                    match right with
                    | PsKernelName.num rightParent rightValue =>
                        smaller
                          (PsKernelList.cons (PsKernelCompareTask.name leftParent rightParent)
                            (PsKernelList.cons (PsKernelCompareTask.natural leftValue rightValue) rest))
                    | _ => PsKernelCompareResult.different
            | PsKernelCompareTask.text left right =>
                match left with
                | PsKernelText.empty =>
                    match right with
                    | PsKernelText.empty => smaller rest
                    | _ => PsKernelCompareResult.different
                | PsKernelText.byte leftByte leftRest =>
                    match right with
                    | PsKernelText.empty => PsKernelCompareResult.different
                    | PsKernelText.byte rightByte rightRest =>
                        smaller
                          (PsKernelList.cons (PsKernelCompareTask.natural leftByte rightByte)
                            (PsKernelList.cons (PsKernelCompareTask.text leftRest rightRest) rest))
            | PsKernelCompareTask.level left right =>
                match left with
                | PsKernelLevel.zero =>
                    match right with
                    | PsKernelLevel.zero => smaller rest
                    | _ => PsKernelCompareResult.different
                | PsKernelLevel.succ leftValue =>
                    match right with
                    | PsKernelLevel.succ rightValue =>
                        smaller
                          (PsKernelList.cons (PsKernelCompareTask.level leftValue rightValue) rest)
                    | _ => PsKernelCompareResult.different
                | PsKernelLevel.max leftA leftB =>
                    match right with
                    | PsKernelLevel.max rightA rightB =>
                        smaller
                          (PsKernelList.cons (PsKernelCompareTask.level leftA rightA)
                            (PsKernelList.cons (PsKernelCompareTask.level leftB rightB) rest))
                    | _ => PsKernelCompareResult.different
                | PsKernelLevel.imax leftA leftB =>
                    match right with
                    | PsKernelLevel.imax rightA rightB =>
                        smaller
                          (PsKernelList.cons (PsKernelCompareTask.level leftA rightA)
                            (PsKernelList.cons (PsKernelCompareTask.level leftB rightB) rest))
                    | _ => PsKernelCompareResult.different
                | PsKernelLevel.param leftName =>
                    match right with
                    | PsKernelLevel.param rightName =>
                        smaller
                          (PsKernelList.cons (PsKernelCompareTask.name leftName rightName) rest)
                    | _ => PsKernelCompareResult.different

