import Ps.Kernel.Data
import Ps.Kernel.Natural
import Ps.Kernel.Order

/- Normalization implementation studied against Lean 4.34 kernel/level.cpp.
Internal canonical ordering differs from Lean name ordering. Compatibility must
be measured, not inferred from these rules. Helpers require bounded-depth input.
Native evaluation and complete universe-algebra solving are not implemented. -/
inductive PsKernelLevelOffset where
  | parts (base : PsKernelLevel) (count : PsKernelNatural)

def psKernelLevelOffset (value : PsKernelLevel) : PsKernelLevelOffset :=
  match value with
  | PsKernelLevel.succ child =>
      match psKernelLevelOffset child with
      | PsKernelLevelOffset.parts base count => PsKernelLevelOffset.parts base (psKernelNaturalSucc count)
  | PsKernelLevel.zero => PsKernelLevelOffset.parts PsKernelLevel.zero PsKernelNatural.zero
  | PsKernelLevel.param name => PsKernelLevelOffset.parts (PsKernelLevel.param name) PsKernelNatural.zero
  | PsKernelLevel.max left right => PsKernelLevelOffset.parts (PsKernelLevel.max left right) PsKernelNatural.zero
  | PsKernelLevel.imax left right => PsKernelLevelOffset.parts (PsKernelLevel.imax left right) PsKernelNatural.zero

def psKernelLevelNeverZero (value : PsKernelLevel) : PsKernelFlag :=
  match value with
  | PsKernelLevel.zero => PsKernelFlag.no
  | PsKernelLevel.param name => PsKernelFlag.no
  | PsKernelLevel.succ child => PsKernelFlag.yes
  | PsKernelLevel.max left right =>
      match psKernelLevelNeverZero left with
      | PsKernelFlag.yes => PsKernelFlag.yes
      | PsKernelFlag.no => psKernelLevelNeverZero right
  | PsKernelLevel.imax left right => psKernelLevelNeverZero right

def psKernelLevelAlwaysZero (value : PsKernelLevel) : PsKernelFlag :=
  match value with
  | PsKernelLevel.zero => PsKernelFlag.yes
  | PsKernelLevel.param name => PsKernelFlag.no
  | PsKernelLevel.succ child => PsKernelFlag.no
  | PsKernelLevel.max left right =>
      match psKernelLevelAlwaysZero left with
      | PsKernelFlag.yes => psKernelLevelAlwaysZero right
      | PsKernelFlag.no => PsKernelFlag.no
  | PsKernelLevel.imax left right => psKernelLevelAlwaysZero right

inductive PsKernelMaxProbe where
  | probe (left : PsKernelLevel) (right : PsKernelLevel) (result : PsKernelLevel)

inductive PsKernelUniverseTask where
  | normalize (value : PsKernelLevel) (offset : PsKernelNatural)
  | joinMax (offset : PsKernelNatural)
  | joinIMax (offset : PsKernelNatural)
  | wrap (value : PsKernelLevel) (offset : PsKernelNatural)
  | imaxCompare (left : PsKernelLevel) (right : PsKernelLevel) (offset : PsKernelNatural) (work : PsKernelList PsKernelOrderTask)
  | maxBases (left : PsKernelLevel) (right : PsKernelLevel) (offset : PsKernelNatural) (work : PsKernelList PsKernelOrderTask)
  | maxOffsets (left : PsKernelLevel) (right : PsKernelLevel) (offset : PsKernelNatural) (numeric : PsKernelNumericState)
  | probeMax (left : PsKernelLevel) (right : PsKernelLevel) (offset : PsKernelNatural) (probes : PsKernelList PsKernelMaxProbe)
  | probeCompare (left : PsKernelLevel) (right : PsKernelLevel) (offset : PsKernelNatural) (result : PsKernelLevel) (probes : PsKernelList PsKernelMaxProbe) (work : PsKernelList PsKernelOrderTask)
  | collect (offset : PsKernelNatural) (todo : PsKernelList PsKernelLevel) (leaves : PsKernelList PsKernelLevel)
  | sort (offset : PsKernelNatural) (todo : PsKernelList PsKernelLevel) (sorted : PsKernelList PsKernelLevel)
  | insert (offset : PsKernelNatural) (todo : PsKernelList PsKernelLevel) (candidate : PsKernelLevel) (scan : PsKernelList PsKernelLevel) (prefixRev : PsKernelList PsKernelLevel)
  | insertCompare (offset : PsKernelNatural) (todo : PsKernelList PsKernelLevel) (candidate : PsKernelLevel) (current : PsKernelLevel) (tail : PsKernelList PsKernelLevel) (prefixRev : PsKernelList PsKernelLevel) (work : PsKernelList PsKernelOrderTask)
  | insertOffset (offset : PsKernelNatural) (todo : PsKernelList PsKernelLevel) (candidate : PsKernelLevel) (current : PsKernelLevel) (tail : PsKernelList PsKernelLevel) (prefixRev : PsKernelList PsKernelLevel) (numeric : PsKernelNumericState)
  | restore (offset : PsKernelNatural) (todo : PsKernelList PsKernelLevel) (prefixRev : PsKernelList PsKernelLevel) (suffix : PsKernelList PsKernelLevel)
  | prune (offset : PsKernelNatural) (sorted : PsKernelList PsKernelLevel)
  | constantScan (offset : PsKernelNatural) (constant : PsKernelLevel) (others : PsKernelList PsKernelLevel) (scan : PsKernelList PsKernelLevel)
  | constantCompare (offset : PsKernelNatural) (constant : PsKernelLevel) (others : PsKernelList PsKernelLevel) (scan : PsKernelList PsKernelLevel) (numeric : PsKernelNumericState)
  | wrapList (offset : PsKernelNatural) (todo : PsKernelList PsKernelLevel) (doneRev : PsKernelList PsKernelLevel)
  | wrapped (offset : PsKernelNatural) (todo : PsKernelList PsKernelLevel) (doneRev : PsKernelList PsKernelLevel)
  | assemble (todo : PsKernelList PsKernelLevel) (value : PsKernelLevel)

inductive PsKernelUniverseState where
  | state (tasks : PsKernelList PsKernelUniverseTask) (values : PsKernelList PsKernelLevel)

inductive PsKernelUniverseResult where
  | outOfFuel
  | invalidState
  | done (value : PsKernelLevel)

inductive PsKernelUniverseStep where
  | next (state : PsKernelUniverseState)
  | final (result : PsKernelUniverseResult)

def psKernelUniverseSchedule (task : PsKernelUniverseTask)
    (tasks : PsKernelList PsKernelUniverseTask) (values : PsKernelList PsKernelLevel) : PsKernelUniverseStep :=
  PsKernelUniverseStep.next (PsKernelUniverseState.state (PsKernelList.cons task tasks) values)

def psKernelUniversePush (value : PsKernelLevel)
    (tasks : PsKernelList PsKernelUniverseTask) (values : PsKernelList PsKernelLevel) : PsKernelUniverseStep :=
  PsKernelUniverseStep.next (PsKernelUniverseState.state tasks (PsKernelList.cons value values))

def psKernelUniverseSmartMax (left right : PsKernelLevel) (offset : PsKernelNatural)
    (tasks : PsKernelList PsKernelUniverseTask) (values : PsKernelList PsKernelLevel) : PsKernelUniverseStep :=
  match left with
  | PsKernelLevel.zero => psKernelUniverseSchedule (PsKernelUniverseTask.wrap right offset) tasks values
  | _ =>
      match right with
      | PsKernelLevel.zero => psKernelUniverseSchedule (PsKernelUniverseTask.wrap left offset) tasks values
      | _ =>
          match psKernelLevelOffset left with
          | PsKernelLevelOffset.parts leftBase leftCount =>
              match psKernelLevelOffset right with
              | PsKernelLevelOffset.parts rightBase rightCount =>
                  psKernelUniverseSchedule (PsKernelUniverseTask.maxBases left right offset
                    (PsKernelList.cons (PsKernelOrderTask.level leftBase rightBase) PsKernelList.nil)) tasks values

def psKernelUniverseIMax (left right : PsKernelLevel) (offset : PsKernelNatural)
    (tasks : PsKernelList PsKernelUniverseTask) (values : PsKernelList PsKernelLevel) : PsKernelUniverseStep :=
  match psKernelLevelNeverZero right with
  | PsKernelFlag.yes => psKernelUniverseSmartMax left right offset tasks values
  | PsKernelFlag.no =>
      match right with
      | PsKernelLevel.zero => psKernelUniverseSchedule (PsKernelUniverseTask.wrap right offset) tasks values
      | _ =>
          let smallLeft : PsKernelFlag :=
            match left with
            | PsKernelLevel.zero => PsKernelFlag.yes
            | PsKernelLevel.succ child =>
                match child with
                | PsKernelLevel.zero => PsKernelFlag.yes
                | _ => PsKernelFlag.no
            | _ => PsKernelFlag.no;
          match smallLeft with
          | PsKernelFlag.yes => psKernelUniverseSchedule (PsKernelUniverseTask.wrap right offset) tasks values
          | PsKernelFlag.no => psKernelUniverseSchedule (PsKernelUniverseTask.imaxCompare left right offset
              (PsKernelList.cons (PsKernelOrderTask.level left right) PsKernelList.nil)) tasks values

def psKernelUniverseProbes (left right : PsKernelLevel) : PsKernelList PsKernelMaxProbe :=
  let fromLeft : PsKernelList PsKernelMaxProbe :=
    match left with
    | PsKernelLevel.max a b =>
        PsKernelList.cons (PsKernelMaxProbe.probe right a left)
          (PsKernelList.cons (PsKernelMaxProbe.probe right b left) PsKernelList.nil)
    | _ => PsKernelList.nil;
  match right with
  | PsKernelLevel.max a b =>
      PsKernelList.cons (PsKernelMaxProbe.probe left a right)
        (PsKernelList.cons (PsKernelMaxProbe.probe left b right) fromLeft)
  | _ => fromLeft

def psKernelUniverseFinish (values : PsKernelList PsKernelLevel) : PsKernelUniverseResult :=
  match values with
  | PsKernelList.nil => PsKernelUniverseResult.invalidState
  | PsKernelList.cons value tail =>
      match tail with
      | PsKernelList.nil => PsKernelUniverseResult.done value
      | _ => PsKernelUniverseResult.invalidState

def psKernelUniverseStep (state : PsKernelUniverseState) : PsKernelUniverseStep :=
  match state with
  | PsKernelUniverseState.state tasks values =>
      match tasks with
      | PsKernelList.nil => PsKernelUniverseStep.final (psKernelUniverseFinish values)
      | PsKernelList.cons task rest =>
          match task with
          | PsKernelUniverseTask.normalize value offset =>
              match value with
              | PsKernelLevel.succ child => psKernelUniverseSchedule (PsKernelUniverseTask.normalize child (psKernelNaturalSucc offset)) rest values
              | PsKernelLevel.max left right =>
                  psKernelUniverseSchedule (PsKernelUniverseTask.normalize left PsKernelNatural.zero)
                    (PsKernelList.cons (PsKernelUniverseTask.normalize right PsKernelNatural.zero)
                      (PsKernelList.cons (PsKernelUniverseTask.joinMax offset) rest)) values
              | PsKernelLevel.imax left right =>
                  psKernelUniverseSchedule (PsKernelUniverseTask.normalize left PsKernelNatural.zero)
                    (PsKernelList.cons (PsKernelUniverseTask.normalize right PsKernelNatural.zero)
                      (PsKernelList.cons (PsKernelUniverseTask.joinIMax offset) rest)) values
              | _ => psKernelUniverseSchedule (PsKernelUniverseTask.wrap value offset) rest values
          | PsKernelUniverseTask.wrap value offset =>
              match offset with
              | PsKernelNatural.zero => psKernelUniversePush value rest values
              | _ => psKernelUniverseSchedule (PsKernelUniverseTask.wrap (PsKernelLevel.succ value) (psKernelNaturalPred offset)) rest values
          | PsKernelUniverseTask.joinIMax offset =>
              match values with
              | PsKernelList.cons right tail =>
                  match tail with
                  | PsKernelList.cons left remaining => psKernelUniverseIMax left right offset rest remaining
                  | _ => PsKernelUniverseStep.final PsKernelUniverseResult.invalidState
              | _ => PsKernelUniverseStep.final PsKernelUniverseResult.invalidState
          | PsKernelUniverseTask.joinMax offset =>
              match values with
              | PsKernelList.cons right tail =>
                  match tail with
                  | PsKernelList.cons left remaining =>
                      psKernelUniverseSchedule (PsKernelUniverseTask.collect offset
                        (PsKernelList.cons left (PsKernelList.cons right PsKernelList.nil)) PsKernelList.nil) rest remaining
                  | _ => PsKernelUniverseStep.final PsKernelUniverseResult.invalidState
              | _ => PsKernelUniverseStep.final PsKernelUniverseResult.invalidState
          | PsKernelUniverseTask.imaxCompare left right offset work =>
              match psKernelOrderStep work with
              | PsKernelOrderStep.next next => psKernelUniverseSchedule (PsKernelUniverseTask.imaxCompare left right offset next) rest values
              | PsKernelOrderStep.invalidState => PsKernelUniverseStep.final PsKernelUniverseResult.invalidState
              | PsKernelOrderStep.done order =>
                  match order with
                  | PsKernelOrder.same => psKernelUniverseSchedule (PsKernelUniverseTask.wrap left offset) rest values
                  | _ => psKernelUniverseSchedule (PsKernelUniverseTask.wrap (PsKernelLevel.imax left right) offset) rest values
          | PsKernelUniverseTask.maxBases left right offset work =>
              match psKernelOrderStep work with
              | PsKernelOrderStep.next next => psKernelUniverseSchedule (PsKernelUniverseTask.maxBases left right offset next) rest values
              | PsKernelOrderStep.invalidState => PsKernelUniverseStep.final PsKernelUniverseResult.invalidState
              | PsKernelOrderStep.done order =>
                  match order with
                  | PsKernelOrder.same =>
                      match psKernelLevelOffset left with
                      | PsKernelLevelOffset.parts unusedLeft leftCount =>
                          match psKernelLevelOffset right with
                          | PsKernelLevelOffset.parts unusedRight rightCount =>
                              psKernelUniverseSchedule (PsKernelUniverseTask.maxOffsets left right offset
                                (PsKernelNumericState.order leftCount rightCount PsKernelOrder.same)) rest values
                  | _ => psKernelUniverseSchedule (PsKernelUniverseTask.probeMax left right offset (psKernelUniverseProbes left right)) rest values
          | PsKernelUniverseTask.maxOffsets left right offset numeric =>
              match psKernelNumericStep numeric with
              | PsKernelNumericStep.next next => psKernelUniverseSchedule (PsKernelUniverseTask.maxOffsets left right offset next) rest values
              | PsKernelNumericStep.ordered order =>
                  match order with
                  | PsKernelOrder.less => psKernelUniverseSchedule (PsKernelUniverseTask.wrap right offset) rest values
                  | _ => psKernelUniverseSchedule (PsKernelUniverseTask.wrap left offset) rest values
              | _ => PsKernelUniverseStep.final PsKernelUniverseResult.invalidState
          | PsKernelUniverseTask.probeMax left right offset probes =>
              match probes with
              | PsKernelList.nil => psKernelUniverseSchedule (PsKernelUniverseTask.wrap (PsKernelLevel.max left right) offset) rest values
              | PsKernelList.cons probe tail =>
                  match probe with
                  | PsKernelMaxProbe.probe a b result => psKernelUniverseSchedule
                      (PsKernelUniverseTask.probeCompare left right offset result tail
                        (PsKernelList.cons (PsKernelOrderTask.level a b) PsKernelList.nil)) rest values
          | PsKernelUniverseTask.probeCompare left right offset result probes work =>
              match psKernelOrderStep work with
              | PsKernelOrderStep.next next => psKernelUniverseSchedule (PsKernelUniverseTask.probeCompare left right offset result probes next) rest values
              | PsKernelOrderStep.invalidState => PsKernelUniverseStep.final PsKernelUniverseResult.invalidState
              | PsKernelOrderStep.done order =>
                  match order with
                  | PsKernelOrder.same => psKernelUniverseSchedule (PsKernelUniverseTask.wrap result offset) rest values
                  | _ => psKernelUniverseSchedule (PsKernelUniverseTask.probeMax left right offset probes) rest values
          | PsKernelUniverseTask.collect offset todo leaves =>
              match todo with
              | PsKernelList.nil => psKernelUniverseSchedule (PsKernelUniverseTask.sort offset leaves PsKernelList.nil) rest values
              | PsKernelList.cons value tail =>
                  match value with
                  | PsKernelLevel.max a b => psKernelUniverseSchedule
                      (PsKernelUniverseTask.collect offset (PsKernelList.cons a (PsKernelList.cons b tail)) leaves) rest values
                  | _ => psKernelUniverseSchedule (PsKernelUniverseTask.collect offset tail (PsKernelList.cons value leaves)) rest values
          | PsKernelUniverseTask.sort offset todo sorted =>
              match todo with
              | PsKernelList.nil => psKernelUniverseSchedule (PsKernelUniverseTask.prune offset sorted) rest values
              | PsKernelList.cons candidate tail => psKernelUniverseSchedule (PsKernelUniverseTask.insert offset tail candidate sorted PsKernelList.nil) rest values
          | PsKernelUniverseTask.insert offset todo candidate scan prefixRev =>
              match scan with
              | PsKernelList.nil => psKernelUniverseSchedule (PsKernelUniverseTask.restore offset todo prefixRev (PsKernelList.cons candidate PsKernelList.nil)) rest values
              | PsKernelList.cons current tail =>
                  match psKernelLevelOffset candidate with
                  | PsKernelLevelOffset.parts a unusedCountA =>
                      match psKernelLevelOffset current with
                      | PsKernelLevelOffset.parts b unusedCountB => psKernelUniverseSchedule
                          (PsKernelUniverseTask.insertCompare offset todo candidate current tail prefixRev
                            (PsKernelList.cons (PsKernelOrderTask.level a b) PsKernelList.nil)) rest values
          | PsKernelUniverseTask.insertCompare offset todo candidate current tail prefixRev work =>
              match psKernelOrderStep work with
              | PsKernelOrderStep.next next => psKernelUniverseSchedule (PsKernelUniverseTask.insertCompare offset todo candidate current tail prefixRev next) rest values
              | PsKernelOrderStep.invalidState => PsKernelUniverseStep.final PsKernelUniverseResult.invalidState
              | PsKernelOrderStep.done order =>
                  match order with
                  | PsKernelOrder.less => psKernelUniverseSchedule (PsKernelUniverseTask.restore offset todo prefixRev
                      (PsKernelList.cons candidate (PsKernelList.cons current tail))) rest values
                  | PsKernelOrder.greater => psKernelUniverseSchedule (PsKernelUniverseTask.insert offset todo candidate tail (PsKernelList.cons current prefixRev)) rest values
                  | PsKernelOrder.same =>
                      match psKernelLevelOffset candidate with
                      | PsKernelLevelOffset.parts unusedA a =>
                          match psKernelLevelOffset current with
                          | PsKernelLevelOffset.parts unusedB b => psKernelUniverseSchedule
                              (PsKernelUniverseTask.insertOffset offset todo candidate current tail prefixRev
                                (PsKernelNumericState.order a b PsKernelOrder.same)) rest values
          | PsKernelUniverseTask.insertOffset offset todo candidate current tail prefixRev numeric =>
              match psKernelNumericStep numeric with
              | PsKernelNumericStep.next next => psKernelUniverseSchedule (PsKernelUniverseTask.insertOffset offset todo candidate current tail prefixRev next) rest values
              | PsKernelNumericStep.ordered order =>
                  match order with
                  | PsKernelOrder.greater => psKernelUniverseSchedule (PsKernelUniverseTask.restore offset todo prefixRev (PsKernelList.cons candidate tail)) rest values
                  | _ => psKernelUniverseSchedule (PsKernelUniverseTask.restore offset todo prefixRev (PsKernelList.cons current tail)) rest values
              | _ => PsKernelUniverseStep.final PsKernelUniverseResult.invalidState
          | PsKernelUniverseTask.restore offset todo prefixRev suffix =>
              match prefixRev with
              | PsKernelList.nil => psKernelUniverseSchedule (PsKernelUniverseTask.sort offset todo suffix) rest values
              | PsKernelList.cons head tail => psKernelUniverseSchedule (PsKernelUniverseTask.restore offset todo tail (PsKernelList.cons head suffix)) rest values
          | PsKernelUniverseTask.prune offset sorted =>
              match sorted with
              | PsKernelList.nil => PsKernelUniverseStep.final PsKernelUniverseResult.invalidState
              | PsKernelList.cons first tail =>
                  match psKernelLevelOffset first with
                  | PsKernelLevelOffset.parts base count =>
                      match base with
                      | PsKernelLevel.zero => psKernelUniverseSchedule (PsKernelUniverseTask.constantScan offset first tail tail) rest values
                      | _ => psKernelUniverseSchedule (PsKernelUniverseTask.wrapList offset sorted PsKernelList.nil) rest values
          | PsKernelUniverseTask.constantScan offset constant others scan =>
              match scan with
              | PsKernelList.nil => psKernelUniverseSchedule (PsKernelUniverseTask.wrapList offset (PsKernelList.cons constant others) PsKernelList.nil) rest values
              | PsKernelList.cons head tail =>
                  match psKernelLevelOffset constant with
                  | PsKernelLevelOffset.parts unusedA a =>
                      match psKernelLevelOffset head with
                      | PsKernelLevelOffset.parts unusedB b => psKernelUniverseSchedule
                          (PsKernelUniverseTask.constantCompare offset constant others tail
                            (PsKernelNumericState.order b a PsKernelOrder.same)) rest values
          | PsKernelUniverseTask.constantCompare offset constant others scan numeric =>
              match psKernelNumericStep numeric with
              | PsKernelNumericStep.next next => psKernelUniverseSchedule (PsKernelUniverseTask.constantCompare offset constant others scan next) rest values
              | PsKernelNumericStep.ordered order =>
                  match order with
                  | PsKernelOrder.less => psKernelUniverseSchedule (PsKernelUniverseTask.constantScan offset constant others scan) rest values
                  | _ => psKernelUniverseSchedule (PsKernelUniverseTask.wrapList offset others PsKernelList.nil) rest values
              | _ => PsKernelUniverseStep.final PsKernelUniverseResult.invalidState
          | PsKernelUniverseTask.wrapList offset todo doneRev =>
              match todo with
              | PsKernelList.nil =>
                  match doneRev with
                  | PsKernelList.nil => PsKernelUniverseStep.final PsKernelUniverseResult.invalidState
                  | PsKernelList.cons last tail => psKernelUniverseSchedule (PsKernelUniverseTask.assemble tail last) rest values
              | PsKernelList.cons head tail => psKernelUniverseSchedule (PsKernelUniverseTask.wrap head offset)
                  (PsKernelList.cons (PsKernelUniverseTask.wrapped offset tail doneRev) rest) values
          | PsKernelUniverseTask.wrapped offset todo doneRev =>
              match values with
              | PsKernelList.nil => PsKernelUniverseStep.final PsKernelUniverseResult.invalidState
              | PsKernelList.cons wrapped tail => psKernelUniverseSchedule (PsKernelUniverseTask.wrapList offset todo (PsKernelList.cons wrapped doneRev)) rest tail
          | PsKernelUniverseTask.assemble todo value =>
              match todo with
              | PsKernelList.nil => psKernelUniversePush value rest values
              | PsKernelList.cons head tail => psKernelUniverseSchedule (PsKernelUniverseTask.assemble tail (PsKernelLevel.max head value)) rest values

def psKernelUniverseStart (value : PsKernelLevel) : PsKernelUniverseState :=
  PsKernelUniverseState.state (PsKernelList.cons (PsKernelUniverseTask.normalize value PsKernelNatural.zero) PsKernelList.nil) PsKernelList.nil

def psKernelUniverseRun (fuel : PsKernelFuel) : PsKernelUniverseState -> PsKernelUniverseResult :=
  match fuel with
  | PsKernelFuel.stop =>
      fun (state : PsKernelUniverseState) =>
        match state with
        | PsKernelUniverseState.state tasks values =>
            match tasks with
            | PsKernelList.nil => psKernelUniverseFinish values
            | _ => PsKernelUniverseResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelUniverseState) =>
        match psKernelUniverseStep state with
        | PsKernelUniverseStep.final result => result
        | PsKernelUniverseStep.next next =>
            let smaller : PsKernelUniverseState -> PsKernelUniverseResult := psKernelUniverseRun remaining;
            smaller next
