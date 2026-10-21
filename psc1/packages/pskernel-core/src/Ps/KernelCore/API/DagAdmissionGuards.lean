import Ps.KernelCore.Admission.Declaration.Validation
import Ps.KernelCore.Core.ExprV2.Validation

/-
Static declaration guards over an owning, replay-validated expression DAG.

Entry.hasExprMVar covers expression metavariables only. Universe metavariables
must be inspected before a free-variable error can be returned. The traversal
also retains the first undefined universe parameter in the reference's
left-to-right order; a later metavariable still takes precedence.

The exact-ID index contains only completely scanned nodes from this call.
Its sixteen routing bits are an index, never an equality certificate: every
bucket lookup compares the complete Nat ID. No memo crosses an arena,
declaration, or allowed-universe-parameter scope. The traversal's recursive
bound comes from validated DAG depth, not the kernel's checker fuel.
-/

inductive PsKernelExprV2AdmissionSeen where
  | empty
  | bucket (ids : List Nat)
  | branch (left right : PsKernelExprV2AdmissionSeen)

def psKernelExprV2AdmissionSeenBucket
    (fuel : Nat) :
    PsKernelExprV2AdmissionSeen -> Nat -> List Nat :=
  match fuel with
  | Nat.zero =>
      fun (seen : PsKernelExprV2AdmissionSeen) (_key : Nat) =>
        match seen with
        | PsKernelExprV2AdmissionSeen.bucket ids => ids
        | _ => List.nil
  | Nat.succ remaining =>
      fun (seen : PsKernelExprV2AdmissionSeen) (key : Nat) =>
        let recur := psKernelExprV2AdmissionSeenBucket remaining;
        match seen with
        | PsKernelExprV2AdmissionSeen.branch left right =>
            if Nat.beq (Nat.mod key 2) 0 then
              recur left (Nat.div key 2)
            else
              recur right (Nat.div key 2)
        | _ => List.nil

def psKernelExprV2AdmissionSeenSet
    (fuel : Nat) :
    PsKernelExprV2AdmissionSeen -> Nat -> List Nat -> PsKernelExprV2AdmissionSeen :=
  match fuel with
  | Nat.zero =>
      fun (_seen : PsKernelExprV2AdmissionSeen) (_key : Nat) (ids : List Nat) =>
        PsKernelExprV2AdmissionSeen.bucket ids
  | Nat.succ remaining =>
      fun (seen : PsKernelExprV2AdmissionSeen) (key : Nat) (ids : List Nat) =>
        let left : PsKernelExprV2AdmissionSeen :=
          match seen with
          | PsKernelExprV2AdmissionSeen.branch value _ => value
          | _ => PsKernelExprV2AdmissionSeen.empty;
        let right : PsKernelExprV2AdmissionSeen :=
          match seen with
          | PsKernelExprV2AdmissionSeen.branch _ value => value
          | _ => PsKernelExprV2AdmissionSeen.empty;
        let recur := psKernelExprV2AdmissionSeenSet remaining;
        if Nat.beq (Nat.mod key 2) 0 then
          PsKernelExprV2AdmissionSeen.branch
            (recur left (Nat.div key 2) ids) right
        else
          PsKernelExprV2AdmissionSeen.branch left
            (recur right (Nat.div key 2) ids)

def psKernelExprV2AdmissionIdMember
    (id : Nat) (ids : List Nat) : Bool :=
  match ids with
  | List.nil => false
  | List.cons first rest =>
      if Nat.beq id first then true
      else psKernelExprV2AdmissionIdMember id rest

def psKernelExprV2AdmissionSeenContains
    (seen : PsKernelExprV2AdmissionSeen) (id : Nat) : Bool :=
  psKernelExprV2AdmissionIdMember id
    (psKernelExprV2AdmissionSeenBucket 16 seen id)

def psKernelExprV2AdmissionSeenInsert
    (seen : PsKernelExprV2AdmissionSeen) (id : Nat) : PsKernelExprV2AdmissionSeen :=
  let bucket := psKernelExprV2AdmissionSeenBucket 16 seen id;
  psKernelExprV2AdmissionSeenSet 16 seen id (List.cons id bucket)

def psKernelExprV2AdmissionFirstUndef
    (first next : Option PsKernelName) : Option PsKernelName :=
  match first with
  | Option.some name => Option.some name
  | Option.none => next

def psKernelExprV2AdmissionNodeLevels
    (node : PsKernelExprV2Node) (allowed : List PsKernelName) :
    Except String (Option PsKernelName) :=
  match node with
  | PsKernelExprV2Node.mvar _ =>
      Except.error "declaration has metavariables"
  | PsKernelExprV2Node.sort level =>
      if psKernelLevelHasMVar level then
        Except.error "declaration has metavariables"
      else Except.ok (psKernelFindUndefLevelParam level allowed)
  | PsKernelExprV2Node.const _ levels =>
      if psKernelLevelsHaveMVar levels then
        Except.error "declaration has metavariables"
      else Except.ok (psKernelFindUndefInLevels levels allowed)
  | _ => Except.ok Option.none

def psKernelExprV2AdmissionChildren
    (node : PsKernelExprV2Node) : List Nat :=
  match node with
  | PsKernelExprV2Node.app fn arg =>
      List.cons fn (List.cons arg List.nil)
  | PsKernelExprV2Node.lam _ type body _ =>
      List.cons type (List.cons body List.nil)
  | PsKernelExprV2Node.forallE _ type body _ =>
      List.cons type (List.cons body List.nil)
  | PsKernelExprV2Node.letE _ type value body _ =>
      List.cons type (List.cons value (List.cons body List.nil))
  | PsKernelExprV2Node.mdata _ body => List.cons body List.nil
  | PsKernelExprV2Node.proj _ _ body => List.cons body List.nil
  | _ => List.nil

def psKernelExprV2AdmissionScanChildren
    (children : List Nat)
    (recurse : PsKernelExprV2AdmissionSeen -> Nat -> Option PsKernelName ->
      Except String (Prod PsKernelExprV2AdmissionSeen (Option PsKernelName)))
    (seen : PsKernelExprV2AdmissionSeen) (first : Option PsKernelName) :
    Except String (Prod PsKernelExprV2AdmissionSeen (Option PsKernelName)) :=
  match children with
  | List.nil => Except.ok (Prod.mk seen first)
  | List.cons child rest =>
      match recurse seen child first with
      | Except.error error => Except.error error
      | Except.ok scanned =>
          psKernelExprV2AdmissionScanChildren rest recurse
            (Prod.fst scanned) (Prod.snd scanned)

def psKernelExprV2AdmissionScanWithFuel
    (fuel : Nat) :
    PsKernelExprV2PagedArena -> List PsKernelName -> PsKernelExprV2AdmissionSeen ->
    Nat -> Option PsKernelName ->
    Except String (Prod PsKernelExprV2AdmissionSeen (Option PsKernelName)) :=
  match fuel with
  | Nat.zero =>
      fun (_arena : PsKernelExprV2PagedArena) (_allowed : List PsKernelName)
          (_seen : PsKernelExprV2AdmissionSeen) (_root : Nat)
          (_first : Option PsKernelName) =>
        Except.error "PSKERNEL_V2_ADMISSION_GUARD_FUEL"
  | Nat.succ remaining =>
      fun (arena : PsKernelExprV2PagedArena) (allowed : List PsKernelName)
          (seen : PsKernelExprV2AdmissionSeen) (root : Nat)
          (first : Option PsKernelName) =>
        if psKernelExprV2AdmissionSeenContains seen root then
          Except.ok (Prod.mk seen first)
        else
          match psKernelExprV2PagedRequire arena root with
          | Except.error error => Except.error error
          | Except.ok entry =>
              if entry.hasExprMVar then
                Except.error "declaration has metavariables"
              else
                match psKernelExprV2AdmissionNodeLevels entry.node allowed with
                | Except.error error => Except.error error
                | Except.ok localUndef =>
                    let nextFirst := psKernelExprV2AdmissionFirstUndef first localUndef;
                    let recur := psKernelExprV2AdmissionScanWithFuel remaining;
                    let recurse :=
                      fun (nextSeen : PsKernelExprV2AdmissionSeen) (nextRoot : Nat)
                          (nextFirst : Option PsKernelName) =>
                        recur arena allowed nextSeen nextRoot nextFirst;
                    match psKernelExprV2AdmissionScanChildren
                        (psKernelExprV2AdmissionChildren entry.node) recurse seen nextFirst with
                    | Except.error error => Except.error error
                    | Except.ok scanned =>
                        Except.ok (Prod.mk
                          (psKernelExprV2AdmissionSeenInsert (Prod.fst scanned) root)
                          (Prod.snd scanned))

def psKernelExprV2AdmissionStaticFinish
    (hasFVar : Bool) (undefinedParam : Option PsKernelName) : Except String Unit :=
  if hasFVar then Except.error "declaration has free variables"
  else
    match undefinedParam with
    | Option.some _ =>
        Except.error "invalid reference to undefined universe level parameter"
    | Option.none => Except.ok ()

/- Internal entry: its arena must already be canonical. It takes no supplied
   memo or scan summary; the allowed-parameter scope is fixed for this call. -/
def psKernelExprV2AdmissionStaticOnCanonical
    (arena : PsKernelExprV2PagedArena) (root : Nat) (allowed : List PsKernelName) :
    Except String Unit :=
  match psKernelExprV2PagedRequire arena root with
  | Except.error error => Except.error error
  | Except.ok entry =>
      if entry.hasExprMVar then
        Except.error "declaration has metavariables"
      else
        match psKernelExprV2AdmissionScanWithFuel
            (Nat.succ entry.depth) arena allowed PsKernelExprV2AdmissionSeen.empty
            root Option.none with
        | Except.error error => Except.error error
        | Except.ok scanned =>
            psKernelExprV2AdmissionStaticFinish entry.hasFVar (Prod.snd scanned)

/- Untrusted arenas must be replayed before their flags or depth can decide
   a static guard. Production RunDag already performs this validation once. -/
def psKernelExprV2AdmissionStaticChecked
    (source : PsKernelExprV2PagedArena) (root : Nat) (allowed : List PsKernelName) :
    Except String Unit :=
  match psKernelExprV2PagedValidate source with
  | Except.error error => Except.error error
  | Except.ok canonical =>
      psKernelExprV2AdmissionStaticOnCanonical canonical root allowed
