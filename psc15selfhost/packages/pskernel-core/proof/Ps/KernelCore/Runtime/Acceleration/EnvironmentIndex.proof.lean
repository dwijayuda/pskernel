import Ps.KernelCore.Metatheory.EnvironmentIndexCanonical

/- Source-companion regression: inserting into any root representation
   exposes the new declaration at its own name. -/
theorem psKernelEnvironmentIndexInsert_companion_new_head
    (index : PsKernelEnvironmentIndex)
    (info : PsKernelConstantInfo) :
    ∃ rest : List PsKernelConstantInfo,
      psKernelEnvironmentIndexFind
          (psKernelEnvironmentIndexInsert index info)
          (psKernelConstantInfoName info) =
        List.cons info rest :=
  psKernelEnvironmentIndexFind_insert_has_head index info

/- Root buckets are readable through the public lookup API. Insertion must
   preserve their existing authoritative lookups as well. -/
theorem psKernelEnvironmentIndexInsert_bucket_companion_refines
    (values : List PsKernelConstantInfo)
    (info : PsKernelConstantInfo)
    (name : PsKernelName) :
    psKernelFindConstantInList
        name
        (psKernelEnvironmentIndexFind
          (psKernelEnvironmentIndexInsert
            (PsKernelEnvironmentIndex.bucket values) info)
          name) =
      psKernelFindConstantInList
        name
        (List.cons info values) :=
  psKernelEnvironmentIndexInsert_bucket_refines_authoritative
    values info name
