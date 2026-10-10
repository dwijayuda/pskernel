import Ps.KernelCore.Environment.Semantic

theorem psKernelNameListContains_nil
    (needle : PsKernelName) :
    psKernelNameListContains needle List.nil = false := by
  rfl

theorem psKernelNameHasDuplicates_nil :
    psKernelNameHasDuplicates List.nil = false := by
  rfl

theorem psKernelFindConstantInList_nil
    (name : PsKernelName) :
    psKernelFindConstantInList name List.nil = Option.none := by
  rfl

theorem psKernelReplaceEnvironmentConstant_nil
    (target : PsKernelName)
    (replacement : PsKernelConstantInfo) :
    psKernelReplaceEnvironmentConstant
      target replacement List.nil =
      List.nil := by
  rfl

theorem psKernelConstantListLength_eq_length
    (values : List PsKernelConstantInfo) :
    psKernelConstantListLength values = List.length values := by
  induction values with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelConstantListLength, ih]


theorem psKernelFindConstantInList_some_mem_and_matches
    (name : PsKernelName)
    (values : List PsKernelConstantInfo)
    (info : PsKernelConstantInfo)
    (hFind :
      psKernelFindConstantInList name values =
        Option.some info) :
    List.Mem info values ∧
    psKernelNameEq
        (psKernelConstantInfoName info)
        name =
      true := by
  induction values with
  | nil =>
      simp [psKernelFindConstantInList] at hFind
  | cons head tail ih =>
      cases hMatch :
          psKernelNameEq
            (psKernelConstantInfoName head)
            name with
      | true =>
          simp [
            psKernelFindConstantInList,
            hMatch
          ] at hFind
          subst info
          constructor
          · exact List.Mem.head tail
          · exact hMatch
      | false =>
          simp [
            psKernelFindConstantInList,
            hMatch
          ] at hFind
          have hTail := ih hFind
          constructor
          · exact List.mem_cons_of_mem head hTail.1
          · exact hTail.2
