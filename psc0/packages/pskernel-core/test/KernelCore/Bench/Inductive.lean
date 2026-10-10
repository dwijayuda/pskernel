import KernelCore.Bench.Inference

def psKernelBenchRecName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "BenchRec"

def psKernelBenchRecZeroName : PsKernelName :=
  PsKernelName.str
    psKernelBenchRecName
    "zero"

def psKernelBenchRecSuccName : PsKernelName :=
  PsKernelName.str
    psKernelBenchRecName
    "succ"

def psKernelBenchRecRecName : PsKernelName :=
  psKernelSimpleRecName
    psKernelBenchRecName

def psKernelBenchRecExpr : PsKernelExpr :=
  PsKernelExpr.const
    psKernelBenchRecName
    List.nil

def psKernelBenchRecDecl : PsKernelSimpleInductiveDecl :=
  {
    levelParams := List.nil
    name := psKernelBenchRecName
    type :=
      PsKernelExpr.sort
        (PsKernelLevel.succ PsKernelLevel.zero)
    ctors :=
      List.cons
        {
          name := psKernelBenchRecZeroName
          type := psKernelBenchRecExpr
        }
        (List.cons
          {
            name := psKernelBenchRecSuccName
            type :=
              PsKernelExpr.forallE
                PsKernelName.anonymous
                psKernelBenchRecExpr
                psKernelBenchRecExpr
                PsKernelBinderInfo.default
          }
          List.nil)
    isUnsafe := false
    numParams := 0
  }

def psKernelBenchRecEnvironment :
    Except String PsKernelEnvironment :=
  psKernelAddSimpleInductive
    65536
    psKernelEnvironmentEmpty
    psKernelBenchRecDecl
    0
    psKernelLeanNatMaxSizeDefault

def psKernelBenchRecMotive : PsKernelExpr :=
  PsKernelExpr.lam
    PsKernelName.anonymous
    psKernelBenchRecExpr
    psKernelBenchRecExpr
    PsKernelBinderInfo.default

def psKernelBenchRecStep : PsKernelExpr :=
  PsKernelExpr.lam
    PsKernelName.anonymous
    psKernelBenchRecExpr
    (PsKernelExpr.lam
      PsKernelName.anonymous
      psKernelBenchRecExpr
      (PsKernelExpr.bvar 0)
      PsKernelBinderInfo.default)
    PsKernelBinderInfo.default

def psKernelBenchRecMajor : PsKernelExpr :=
  PsKernelExpr.app
    (PsKernelExpr.const
      psKernelBenchRecSuccName
      List.nil)
    (PsKernelExpr.app
      (PsKernelExpr.const
        psKernelBenchRecSuccName
        List.nil)
      (PsKernelExpr.const
        psKernelBenchRecZeroName
        List.nil))

def psKernelBenchRecInput : PsKernelExpr :=
  psKernelApplyArgs
    (PsKernelExpr.const
      psKernelBenchRecRecName
      (List.cons
        (PsKernelLevel.succ PsKernelLevel.zero)
        List.nil))
    (List.cons
      psKernelBenchRecMotive
      (List.cons
        (PsKernelExpr.const
          psKernelBenchRecZeroName
          List.nil)
        (List.cons
          psKernelBenchRecStep
          (List.cons
            psKernelBenchRecMajor
            List.nil))))

def psKernelBenchLeanRecName : Lean.Name :=
  Lean.Name.str
    Lean.Name.anonymous
    "BenchRec"

def psKernelBenchLeanRecZeroName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanRecName
    "zero"

def psKernelBenchLeanRecSuccName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanRecName
    "succ"

def psKernelBenchLeanRecRecName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanRecName
    "rec"

def psKernelBenchLeanRecExpr : Lean.Expr :=
  Lean.Expr.const
    psKernelBenchLeanRecName
    []

def psKernelBenchLeanRecDecl : Lean.Declaration :=
  Lean.Declaration.inductDecl
    []
    0
    [{
      name := psKernelBenchLeanRecName
      type :=
        Lean.Expr.sort
          (Lean.Level.succ Lean.Level.zero)
      ctors := [
        {
          name := psKernelBenchLeanRecZeroName
          type := psKernelBenchLeanRecExpr
        },
        {
          name := psKernelBenchLeanRecSuccName
          type :=
            Lean.Expr.forallE
              Lean.Name.anonymous
              psKernelBenchLeanRecExpr
              psKernelBenchLeanRecExpr
              Lean.BinderInfo.default
        }
      ]
    }]
    false



def psKernelBenchIndexedName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "BenchIndexed"

def psKernelBenchIndexedReflName : PsKernelName :=
  PsKernelName.str
    psKernelBenchIndexedName
    "refl"

def psKernelBenchIndexedRecName : PsKernelName :=
  psKernelSimpleRecName
    psKernelBenchIndexedName

def psKernelBenchIndexedType1 : PsKernelExpr :=
  PsKernelExpr.sort
    (PsKernelLevel.succ PsKernelLevel.zero)

def psKernelBenchIndexedExpr : PsKernelExpr :=
  PsKernelExpr.const
    psKernelBenchIndexedName
    List.nil

def psKernelBenchIndexedDecl :
    PsKernelSimpleInductiveDecl :=
  {
    levelParams := List.nil
    name := psKernelBenchIndexedName
    type :=
      PsKernelExpr.forallE
        PsKernelName.anonymous
        psKernelBenchIndexedType1
        (PsKernelExpr.forallE
          PsKernelName.anonymous
          (PsKernelExpr.bvar 0)
          psKernelBenchIndexedType1
          PsKernelBinderInfo.default)
        PsKernelBinderInfo.default
    ctors :=
      List.cons
        {
          name := psKernelBenchIndexedReflName
          type :=
            PsKernelExpr.forallE
              PsKernelName.anonymous
              psKernelBenchIndexedType1
              (PsKernelExpr.forallE
                PsKernelName.anonymous
                (PsKernelExpr.bvar 0)
                (PsKernelExpr.app
                  (PsKernelExpr.app
                    psKernelBenchIndexedExpr
                    (PsKernelExpr.bvar 1))
                  (PsKernelExpr.bvar 0))
                PsKernelBinderInfo.default)
              PsKernelBinderInfo.default
        }
        List.nil
    isUnsafe := false
    numParams := 1
  }

def psKernelBenchLeanIndexedName : Lean.Name :=
  Lean.Name.str
    Lean.Name.anonymous
    "BenchIndexed"

def psKernelBenchLeanIndexedReflName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanIndexedName
    "refl"

def psKernelBenchLeanIndexedRecName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanIndexedName
    "rec"

def psKernelBenchLeanIndexedType1 : Lean.Expr :=
  Lean.Expr.sort
    (Lean.Level.succ Lean.Level.zero)

def psKernelBenchLeanIndexedExpr : Lean.Expr :=
  Lean.Expr.const
    psKernelBenchLeanIndexedName
    []

def psKernelBenchLeanIndexedDecl : Lean.Declaration :=
  Lean.Declaration.inductDecl
    []
    1
    [{
      name := psKernelBenchLeanIndexedName
      type :=
        Lean.Expr.forallE
          Lean.Name.anonymous
          psKernelBenchLeanIndexedType1
          (Lean.Expr.forallE
            Lean.Name.anonymous
            (Lean.Expr.bvar 0)
            psKernelBenchLeanIndexedType1
            Lean.BinderInfo.default)
          Lean.BinderInfo.default
      ctors := [{
        name := psKernelBenchLeanIndexedReflName
        type :=
          Lean.Expr.forallE
            Lean.Name.anonymous
            psKernelBenchLeanIndexedType1
            (Lean.Expr.forallE
              Lean.Name.anonymous
              (Lean.Expr.bvar 0)
              (Lean.Expr.app
                (Lean.Expr.app
                  psKernelBenchLeanIndexedExpr
                  (Lean.Expr.bvar 1))
                (Lean.Expr.bvar 0))
              Lean.BinderInfo.default)
            Lean.BinderInfo.default
      }]
    }]
    false

def psKernelBenchMutualEvenName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "BenchMutualEven"

def psKernelBenchMutualOddName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "BenchMutualOdd"

def psKernelBenchMutualEvenZeroName : PsKernelName :=
  PsKernelName.str
    psKernelBenchMutualEvenName
    "zero"

def psKernelBenchMutualEvenStepName : PsKernelName :=
  PsKernelName.str
    psKernelBenchMutualEvenName
    "step"

def psKernelBenchMutualOddStepName : PsKernelName :=
  PsKernelName.str
    psKernelBenchMutualOddName
    "step"

def psKernelBenchMutualEvenRecName : PsKernelName :=
  psKernelSimpleRecName
    psKernelBenchMutualEvenName

def psKernelBenchMutualOddRecName : PsKernelName :=
  psKernelSimpleRecName
    psKernelBenchMutualOddName

def psKernelBenchMutualEvenExpr : PsKernelExpr :=
  PsKernelExpr.const
    psKernelBenchMutualEvenName
    List.nil

def psKernelBenchMutualOddExpr : PsKernelExpr :=
  PsKernelExpr.const
    psKernelBenchMutualOddName
    List.nil

def psKernelBenchMutualDecl :
    PsKernelSimpleMutualInductiveDecl :=
  {
    levelParams := List.nil
    numParams := 0
    types :=
      List.cons
        {
          name := psKernelBenchMutualEvenName
          type :=
            PsKernelExpr.sort
              (PsKernelLevel.succ
                PsKernelLevel.zero)
          ctors :=
            List.cons
              {
                name := psKernelBenchMutualEvenZeroName
                type := psKernelBenchMutualEvenExpr
              }
              (List.cons
                {
                  name := psKernelBenchMutualEvenStepName
                  type :=
                    PsKernelExpr.forallE
                      PsKernelName.anonymous
                      psKernelBenchMutualOddExpr
                      psKernelBenchMutualEvenExpr
                      PsKernelBinderInfo.default
                }
                List.nil)
        }
        (List.cons
          {
            name := psKernelBenchMutualOddName
            type :=
              PsKernelExpr.sort
                (PsKernelLevel.succ
                  PsKernelLevel.zero)
            ctors :=
              List.cons
                {
                  name := psKernelBenchMutualOddStepName
                  type :=
                    PsKernelExpr.forallE
                      PsKernelName.anonymous
                      psKernelBenchMutualEvenExpr
                      psKernelBenchMutualOddExpr
                      PsKernelBinderInfo.default
                }
                List.nil
          }
          List.nil)
    isUnsafe := false
  }

def psKernelBenchLeanMutualEvenName : Lean.Name :=
  Lean.Name.str
    Lean.Name.anonymous
    "BenchMutualEven"

def psKernelBenchLeanMutualOddName : Lean.Name :=
  Lean.Name.str
    Lean.Name.anonymous
    "BenchMutualOdd"

def psKernelBenchLeanMutualEvenZeroName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanMutualEvenName
    "zero"

def psKernelBenchLeanMutualEvenStepName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanMutualEvenName
    "step"

def psKernelBenchLeanMutualOddStepName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanMutualOddName
    "step"

def psKernelBenchLeanMutualEvenRecName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanMutualEvenName
    "rec"

def psKernelBenchLeanMutualOddRecName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanMutualOddName
    "rec"

def psKernelBenchLeanMutualEvenExpr : Lean.Expr :=
  Lean.Expr.const
    psKernelBenchLeanMutualEvenName
    []

def psKernelBenchLeanMutualOddExpr : Lean.Expr :=
  Lean.Expr.const
    psKernelBenchLeanMutualOddName
    []

def psKernelBenchLeanMutualDecl : Lean.Declaration :=
  Lean.Declaration.inductDecl
    []
    0
    [
      {
        name := psKernelBenchLeanMutualEvenName
        type :=
          Lean.Expr.sort
            (Lean.Level.succ Lean.Level.zero)
        ctors := [
          {
            name := psKernelBenchLeanMutualEvenZeroName
            type := psKernelBenchLeanMutualEvenExpr
          },
          {
            name := psKernelBenchLeanMutualEvenStepName
            type :=
              Lean.Expr.forallE
                Lean.Name.anonymous
                psKernelBenchLeanMutualOddExpr
                psKernelBenchLeanMutualEvenExpr
                Lean.BinderInfo.default
          }
        ]
      },
      {
        name := psKernelBenchLeanMutualOddName
        type :=
          Lean.Expr.sort
            (Lean.Level.succ Lean.Level.zero)
        ctors := [
          {
            name := psKernelBenchLeanMutualOddStepName
            type :=
              Lean.Expr.forallE
                Lean.Name.anonymous
                psKernelBenchLeanMutualEvenExpr
                psKernelBenchLeanMutualOddExpr
                Lean.BinderInfo.default
          }
        ]
      }
    ]
    false


def psKernelBenchNestedBoxName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "BenchNestedBox"

def psKernelBenchNestedBoxMkName : PsKernelName :=
  PsKernelName.str
    psKernelBenchNestedBoxName
    "mk"

def psKernelBenchNestedTreeName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "BenchNestedTree"

def psKernelBenchNestedTreeLeafName : PsKernelName :=
  PsKernelName.str
    psKernelBenchNestedTreeName
    "leaf"

def psKernelBenchNestedTreeNodeName : PsKernelName :=
  PsKernelName.str
    psKernelBenchNestedTreeName
    "node"

def psKernelBenchNestedTreeRecName : PsKernelName :=
  psKernelSimpleRecName
    psKernelBenchNestedTreeName

def psKernelBenchNestedType1 : PsKernelExpr :=
  PsKernelExpr.sort
    (PsKernelLevel.succ PsKernelLevel.zero)

def psKernelBenchNestedBoxExpr : PsKernelExpr :=
  PsKernelExpr.const
    psKernelBenchNestedBoxName
    List.nil

def psKernelBenchNestedTreeExpr : PsKernelExpr :=
  PsKernelExpr.const
    psKernelBenchNestedTreeName
    List.nil

def psKernelBenchNestedBoxTreeExpr : PsKernelExpr :=
  PsKernelExpr.app
    psKernelBenchNestedBoxExpr
    psKernelBenchNestedTreeExpr

def psKernelBenchNestedBoxDecl :
    PsKernelSimpleInductiveDecl :=
  {
    levelParams := List.nil
    name := psKernelBenchNestedBoxName
    type :=
      PsKernelExpr.forallE
        PsKernelName.anonymous
        psKernelBenchNestedType1
        psKernelBenchNestedType1
        PsKernelBinderInfo.default
    ctors :=
      List.cons
        {
          name := psKernelBenchNestedBoxMkName
          type :=
            PsKernelExpr.forallE
              PsKernelName.anonymous
              psKernelBenchNestedType1
              (PsKernelExpr.forallE
                PsKernelName.anonymous
                (PsKernelExpr.bvar 0)
                (PsKernelExpr.app
                  psKernelBenchNestedBoxExpr
                  (PsKernelExpr.bvar 1))
                PsKernelBinderInfo.default)
              PsKernelBinderInfo.default
        }
        List.nil
    isUnsafe := false
    numParams := 1
  }

def psKernelBenchNestedDecl :
    PsKernelSimpleMutualInductiveDecl :=
  {
    levelParams := List.nil
    numParams := 0
    types :=
      List.cons
        {
          name := psKernelBenchNestedTreeName
          type := psKernelBenchNestedType1
          ctors :=
            List.cons
              {
                name := psKernelBenchNestedTreeLeafName
                type := psKernelBenchNestedTreeExpr
              }
              (List.cons
                {
                  name := psKernelBenchNestedTreeNodeName
                  type :=
                    PsKernelExpr.forallE
                      PsKernelName.anonymous
                      psKernelBenchNestedBoxTreeExpr
                      psKernelBenchNestedTreeExpr
                      PsKernelBinderInfo.default
                }
                List.nil)
        }
        List.nil
    isUnsafe := false
  }

def psKernelBenchNestedBaseEnvironment :
    IO PsKernelEnvironment := do
  match
      psKernelAddSimpleInductive
        65536
        psKernelEnvironmentEmpty
        psKernelBenchNestedBoxDecl
        0
        psKernelLeanNatMaxSizeDefault with
  | Except.ok environment =>
      pure environment
  | Except.error _ =>
      throw
        (IO.userError
          "PSKERNEL_BENCH failed to create nested-inductive base fixture")

def psKernelBenchLeanNestedBoxName : Lean.Name :=
  Lean.Name.str
    Lean.Name.anonymous
    "BenchNestedBox"

def psKernelBenchLeanNestedBoxMkName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanNestedBoxName
    "mk"

def psKernelBenchLeanNestedTreeName : Lean.Name :=
  Lean.Name.str
    Lean.Name.anonymous
    "BenchNestedTree"

def psKernelBenchLeanNestedTreeLeafName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanNestedTreeName
    "leaf"

def psKernelBenchLeanNestedTreeNodeName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanNestedTreeName
    "node"

def psKernelBenchLeanNestedTreeRecName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanNestedTreeName
    "rec"

def psKernelBenchLeanNestedType1 : Lean.Expr :=
  Lean.Expr.sort
    (Lean.Level.succ Lean.Level.zero)

def psKernelBenchLeanNestedBoxExpr : Lean.Expr :=
  Lean.Expr.const
    psKernelBenchLeanNestedBoxName
    []

def psKernelBenchLeanNestedTreeExpr : Lean.Expr :=
  Lean.Expr.const
    psKernelBenchLeanNestedTreeName
    []

def psKernelBenchLeanNestedBoxTreeExpr : Lean.Expr :=
  Lean.Expr.app
    psKernelBenchLeanNestedBoxExpr
    psKernelBenchLeanNestedTreeExpr

def psKernelBenchLeanNestedBoxDecl : Lean.Declaration :=
  Lean.Declaration.inductDecl
    []
    1
    [{
      name := psKernelBenchLeanNestedBoxName
      type :=
        Lean.Expr.forallE
          Lean.Name.anonymous
          psKernelBenchLeanNestedType1
          psKernelBenchLeanNestedType1
          Lean.BinderInfo.default
      ctors := [{
        name := psKernelBenchLeanNestedBoxMkName
        type :=
          Lean.Expr.forallE
            Lean.Name.anonymous
            psKernelBenchLeanNestedType1
            (Lean.Expr.forallE
              Lean.Name.anonymous
              (Lean.Expr.bvar 0)
              (Lean.Expr.app
                psKernelBenchLeanNestedBoxExpr
                (Lean.Expr.bvar 1))
              Lean.BinderInfo.default)
            Lean.BinderInfo.default
      }]
    }]
    false

def psKernelBenchLeanNestedDecl : Lean.Declaration :=
  Lean.Declaration.inductDecl
    []
    0
    [{
      name := psKernelBenchLeanNestedTreeName
      type := psKernelBenchLeanNestedType1
      ctors := [
        {
          name := psKernelBenchLeanNestedTreeLeafName
          type := psKernelBenchLeanNestedTreeExpr
        },
        {
          name := psKernelBenchLeanNestedTreeNodeName
          type :=
            Lean.Expr.forallE
              Lean.Name.anonymous
              psKernelBenchLeanNestedBoxTreeExpr
              psKernelBenchLeanNestedTreeExpr
              Lean.BinderInfo.default
        }
      ]
    }]
    false

def psKernelBenchLeanNestedBaseEnvironment :
    IO Lean.Environment := do
  let base :=
    (← Lean.mkEmptyEnvironment).toKernelEnv
  match
      Lean.Kernel.Environment.addDecl
        base
        {}
        psKernelBenchLeanNestedBoxDecl with
  | .ok environment =>
      pure
        (Lean.Environment.ofKernelEnv environment)
  | .error _ =>
      throw
        (IO.userError
          "PSKERNEL_BENCH failed to create Lean nested-inductive base fixture")

def psKernelBenchNestedWrapName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "BenchNestedWrap"

def psKernelBenchNestedWrapMkName : PsKernelName :=
  PsKernelName.str
    psKernelBenchNestedWrapName
    "mk"

def psKernelBenchNestedWideTreeName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "BenchNestedWideTree"

def psKernelBenchNestedWideLeafName : PsKernelName :=
  PsKernelName.str
    psKernelBenchNestedWideTreeName
    "leaf"

def psKernelBenchNestedWideBoxName : PsKernelName :=
  PsKernelName.str
    psKernelBenchNestedWideTreeName
    "boxNode"

def psKernelBenchNestedWideWrapName : PsKernelName :=
  PsKernelName.str
    psKernelBenchNestedWideTreeName
    "wrapNode"

def psKernelBenchNestedWideRecName : PsKernelName :=
  psKernelSimpleRecName
    psKernelBenchNestedWideTreeName

def psKernelBenchNestedWrapExpr : PsKernelExpr :=
  PsKernelExpr.const
    psKernelBenchNestedWrapName
    List.nil

def psKernelBenchNestedWideTreeExpr : PsKernelExpr :=
  PsKernelExpr.const
    psKernelBenchNestedWideTreeName
    List.nil

def psKernelBenchNestedBoxWideTreeExpr : PsKernelExpr :=
  PsKernelExpr.app
    psKernelBenchNestedBoxExpr
    psKernelBenchNestedWideTreeExpr

def psKernelBenchNestedWrapWideTreeExpr : PsKernelExpr :=
  PsKernelExpr.app
    psKernelBenchNestedWrapExpr
    psKernelBenchNestedWideTreeExpr

def psKernelBenchNestedWrapDecl :
    PsKernelSimpleInductiveDecl :=
  {
    levelParams := List.nil
    name := psKernelBenchNestedWrapName
    type :=
      PsKernelExpr.forallE
        PsKernelName.anonymous
        psKernelBenchNestedType1
        psKernelBenchNestedType1
        PsKernelBinderInfo.default
    ctors :=
      List.cons
        {
          name := psKernelBenchNestedWrapMkName
          type :=
            PsKernelExpr.forallE
              PsKernelName.anonymous
              psKernelBenchNestedType1
              (PsKernelExpr.forallE
                PsKernelName.anonymous
                (PsKernelExpr.bvar 0)
                (PsKernelExpr.app
                  psKernelBenchNestedWrapExpr
                  (PsKernelExpr.bvar 1))
                PsKernelBinderInfo.default)
              PsKernelBinderInfo.default
        }
        List.nil
    isUnsafe := false
    numParams := 1
  }

def psKernelBenchNestedWideDecl :
    PsKernelSimpleMutualInductiveDecl :=
  {
    levelParams := List.nil
    numParams := 0
    types :=
      List.cons
        {
          name := psKernelBenchNestedWideTreeName
          type := psKernelBenchNestedType1
          ctors :=
            List.cons
              {
                name := psKernelBenchNestedWideLeafName
                type := psKernelBenchNestedWideTreeExpr
              }
              (List.cons
                {
                  name := psKernelBenchNestedWideBoxName
                  type :=
                    PsKernelExpr.forallE
                      PsKernelName.anonymous
                      psKernelBenchNestedBoxWideTreeExpr
                      psKernelBenchNestedWideTreeExpr
                      PsKernelBinderInfo.default
                }
                (List.cons
                  {
                    name := psKernelBenchNestedWideWrapName
                    type :=
                      PsKernelExpr.forallE
                        PsKernelName.anonymous
                        psKernelBenchNestedWrapWideTreeExpr
                        psKernelBenchNestedWideTreeExpr
                        PsKernelBinderInfo.default
                  }
                  List.nil))
        }
        List.nil
    isUnsafe := false
  }

def psKernelBenchNestedWideBaseEnvironment :
    IO PsKernelEnvironment := do
  match
      psKernelAddSimpleInductive
        65536
        psKernelEnvironmentEmpty
        psKernelBenchNestedBoxDecl
        0
        psKernelLeanNatMaxSizeDefault with
  | Except.error _ =>
      throw
        (IO.userError
          "PSKERNEL_BENCH failed to create wide nested Box fixture")
  | Except.ok boxEnvironment =>
      match
          psKernelAddSimpleInductive
            65536
            boxEnvironment
            psKernelBenchNestedWrapDecl
            0
            psKernelLeanNatMaxSizeDefault with
      | Except.ok environment =>
          pure environment
      | Except.error _ =>
          throw
            (IO.userError
              "PSKERNEL_BENCH failed to create wide nested Wrap fixture")

def psKernelBenchLeanNestedWrapName : Lean.Name :=
  Lean.Name.str
    Lean.Name.anonymous
    "BenchNestedWrap"

def psKernelBenchLeanNestedWrapMkName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanNestedWrapName
    "mk"

def psKernelBenchLeanNestedWideTreeName : Lean.Name :=
  Lean.Name.str
    Lean.Name.anonymous
    "BenchNestedWideTree"

def psKernelBenchLeanNestedWideLeafName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanNestedWideTreeName
    "leaf"

def psKernelBenchLeanNestedWideBoxName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanNestedWideTreeName
    "boxNode"

def psKernelBenchLeanNestedWideWrapName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanNestedWideTreeName
    "wrapNode"

def psKernelBenchLeanNestedWideRecName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanNestedWideTreeName
    "rec"

def psKernelBenchLeanNestedWrapExpr : Lean.Expr :=
  Lean.Expr.const
    psKernelBenchLeanNestedWrapName
    []

def psKernelBenchLeanNestedWideTreeExpr : Lean.Expr :=
  Lean.Expr.const
    psKernelBenchLeanNestedWideTreeName
    []

def psKernelBenchLeanNestedBoxWideTreeExpr : Lean.Expr :=
  Lean.Expr.app
    psKernelBenchLeanNestedBoxExpr
    psKernelBenchLeanNestedWideTreeExpr

def psKernelBenchLeanNestedWrapWideTreeExpr : Lean.Expr :=
  Lean.Expr.app
    psKernelBenchLeanNestedWrapExpr
    psKernelBenchLeanNestedWideTreeExpr

def psKernelBenchLeanNestedWrapDecl : Lean.Declaration :=
  Lean.Declaration.inductDecl
    []
    1
    [{
      name := psKernelBenchLeanNestedWrapName
      type :=
        Lean.Expr.forallE
          Lean.Name.anonymous
          psKernelBenchLeanNestedType1
          psKernelBenchLeanNestedType1
          Lean.BinderInfo.default
      ctors := [{
        name := psKernelBenchLeanNestedWrapMkName
        type :=
          Lean.Expr.forallE
            Lean.Name.anonymous
            psKernelBenchLeanNestedType1
            (Lean.Expr.forallE
              Lean.Name.anonymous
              (Lean.Expr.bvar 0)
              (Lean.Expr.app
                psKernelBenchLeanNestedWrapExpr
                (Lean.Expr.bvar 1))
              Lean.BinderInfo.default)
            Lean.BinderInfo.default
      }]
    }]
    false

def psKernelBenchLeanNestedWideDecl : Lean.Declaration :=
  Lean.Declaration.inductDecl
    []
    0
    [{
      name := psKernelBenchLeanNestedWideTreeName
      type := psKernelBenchLeanNestedType1
      ctors := [
        {
          name := psKernelBenchLeanNestedWideLeafName
          type := psKernelBenchLeanNestedWideTreeExpr
        },
        {
          name := psKernelBenchLeanNestedWideBoxName
          type :=
            Lean.Expr.forallE
              Lean.Name.anonymous
              psKernelBenchLeanNestedBoxWideTreeExpr
              psKernelBenchLeanNestedWideTreeExpr
              Lean.BinderInfo.default
        },
        {
          name := psKernelBenchLeanNestedWideWrapName
          type :=
            Lean.Expr.forallE
              Lean.Name.anonymous
              psKernelBenchLeanNestedWrapWideTreeExpr
              psKernelBenchLeanNestedWideTreeExpr
              Lean.BinderInfo.default
        }
      ]
    }]
    false

def psKernelBenchLeanNestedWideBaseEnvironment :
    IO Lean.Environment := do
  let base :=
    (← Lean.mkEmptyEnvironment).toKernelEnv
  match
      Lean.Kernel.Environment.addDecl
        base
        {}
        psKernelBenchLeanNestedBoxDecl with
  | .error _ =>
      throw
        (IO.userError
          "PSKERNEL_BENCH failed to create Lean wide nested Box fixture")
  | .ok boxEnvironment =>
      match
          Lean.Kernel.Environment.addDecl
            boxEnvironment
            {}
            psKernelBenchLeanNestedWrapDecl with
      | .ok environment =>
          pure
            (Lean.Environment.ofKernelEnv environment)
      | .error _ =>
          throw
            (IO.userError
              "PSKERNEL_BENCH failed to create Lean wide nested Wrap fixture")

def psKernelBenchLeanRecEnvironment :
    IO Lean.Environment := do
  let base :=
    (← Lean.mkEmptyEnvironment).toKernelEnv
  match
      Lean.Kernel.Environment.addDecl
        base
        {}
        psKernelBenchLeanRecDecl with
  | .ok environment =>
      pure
        (Lean.Environment.ofKernelEnv environment)
  | .error _ =>
      throw
        (IO.userError
          "PSKERNEL_BENCH failed to create recursive inductive fixture")

def psKernelBenchLeanRecMotive : Lean.Expr :=
  Lean.Expr.lam
    Lean.Name.anonymous
    psKernelBenchLeanRecExpr
    psKernelBenchLeanRecExpr
    Lean.BinderInfo.default

def psKernelBenchLeanRecStep : Lean.Expr :=
  Lean.Expr.lam
    Lean.Name.anonymous
    psKernelBenchLeanRecExpr
    (Lean.Expr.lam
      Lean.Name.anonymous
      psKernelBenchLeanRecExpr
      (Lean.Expr.bvar 0)
      Lean.BinderInfo.default)
    Lean.BinderInfo.default

def psKernelBenchLeanRecMajor : Lean.Expr :=
  Lean.Expr.app
    (Lean.Expr.const
      psKernelBenchLeanRecSuccName
      [])
    (Lean.Expr.app
      (Lean.Expr.const
        psKernelBenchLeanRecSuccName
        [])
      (Lean.Expr.const
        psKernelBenchLeanRecZeroName
        []))

def psKernelBenchLeanRecInput : Lean.Expr :=
  Lean.mkAppN
    (Lean.Expr.const
      psKernelBenchLeanRecRecName
      [Lean.Level.succ Lean.Level.zero])
    #[
      psKernelBenchLeanRecMotive,
      Lean.Expr.const psKernelBenchLeanRecZeroName [],
      psKernelBenchLeanRecStep,
      psKernelBenchLeanRecMajor
    ]

-- Prepare matching, distinct ambient environments outside the timed loops.
-- Admission must consume a runtime-selected input, not a closed expression
-- which Lean can lift into a shared initializer.
def psKernelBenchAdmissionBases : IO (Array PsKernelEnvironment × Array Lean.Environment) := do
  let mut portable := #[]
  let mut official := #[]
  for index in [0:16] do
    let psName := PsKernelName.num (PsKernelName.str PsKernelName.anonymous "BenchAmbient") index
    let leanName := Lean.Name.num (Lean.Name.str Lean.Name.anonymous "BenchAmbient") index
    let psInfo : PsKernelAxiomInfo := {
      base := {
        name := psName
        levelParams := []
        type := .sort (.succ .zero)
      }
      isUnsafe := false
    }
    let psBase := psKernelEnvironmentAddUnchecked psKernelEnvironmentEmpty (.axiomInfo psInfo)
    let leanBase ← Lean.mkEmptyEnvironment
    let .ok leanNext := Lean.Kernel.Environment.addDecl leanBase.toKernelEnv {}
      (.axiomDecl {
        name := leanName
        levelParams := []
        type := .sort (.succ .zero)
        isUnsafe := false
      })
      | throw (IO.userError "admission ambient fixture failed")
    portable := portable.push psBase
    official := official.push (Lean.Environment.ofKernelEnv leanNext)
  return (portable, official)

partial def psKernelBenchInductiveAdmissionLoop
    (iterations : Nat) (environments : Array PsKernelEnvironment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let some base := environments[rest % environments.size]?
        | throw (IO.userError "empty admission fixtures")
      let tail ←
        psKernelBenchInductiveAdmissionLoop rest environments
      match
          psKernelAddSimpleInductive
            65536
            base
            psKernelBenchRecDecl
            0
            psKernelLeanNatMaxSizeDefault with
      | Except.ok environment =>
          if
              psKernelEnvironmentContains
                environment
                psKernelBenchRecRecName then
            pure (Nat.succ tail)
          else
            pure tail
      | Except.error _ =>
          pure tail

partial def psKernelBenchLeanInductiveAdmissionLoop
    (iterations : Nat)
    (environments : Array Lean.Environment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let some environment := environments[rest % environments.size]?
        | throw (IO.userError "empty admission fixtures")
      let tail ←
        psKernelBenchLeanInductiveAdmissionLoop
          rest
          environments
      match
          Lean.Kernel.Environment.addDecl
            environment.toKernelEnv
            {}
            psKernelBenchLeanRecDecl with
      | .ok next =>
          match
              next.find?
                psKernelBenchLeanRecRecName with
          | some (.recInfo _) =>
              pure (Nat.succ tail)
          | _ =>
              pure tail
      | .error _ =>
          pure tail



partial def psKernelBenchIndexedAdmissionLoop
    (iterations : Nat) (environments : Array PsKernelEnvironment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let some base := environments[rest % environments.size]?
        | throw (IO.userError "empty admission fixtures")
      let tail ←
        psKernelBenchIndexedAdmissionLoop rest environments
      match
          psKernelAddSimpleInductive
            65536
            base
            psKernelBenchIndexedDecl
            0
            psKernelLeanNatMaxSizeDefault with
      | Except.ok environment =>
          if
              psKernelEnvironmentContains
                environment
                psKernelBenchIndexedRecName then
            pure (Nat.succ tail)
          else
            pure tail
      | Except.error _ =>
          pure tail

partial def psKernelBenchLeanIndexedAdmissionLoop
    (iterations : Nat)
    (environments : Array Lean.Environment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let some environment := environments[rest % environments.size]?
        | throw (IO.userError "empty admission fixtures")
      let tail ←
        psKernelBenchLeanIndexedAdmissionLoop
          rest
          environments
      match
          Lean.Kernel.Environment.addDecl
            environment.toKernelEnv
            {}
            psKernelBenchLeanIndexedDecl with
      | .ok next =>
          match
              next.find?
                psKernelBenchLeanIndexedRecName with
          | some (.recInfo _) =>
              pure (Nat.succ tail)
          | _ =>
              pure tail
      | .error _ =>
          pure tail

partial def psKernelBenchMutualAdmissionLoop
    (iterations : Nat) (environments : Array PsKernelEnvironment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let some base := environments[rest % environments.size]?
        | throw (IO.userError "empty admission fixtures")
      let tail ←
        psKernelBenchMutualAdmissionLoop rest environments
      match
          psKernelAddSimpleMutualInductive
            65536
            base
            psKernelBenchMutualDecl
            0
            psKernelLeanNatMaxSizeDefault with
      | Except.ok environment =>
          if
              psKernelEnvironmentContains
                environment
                psKernelBenchMutualEvenRecName then
            if
                psKernelEnvironmentContains
                  environment
                  psKernelBenchMutualOddRecName then
              pure (Nat.succ tail)
            else
              pure tail
          else
            pure tail
      | Except.error _ =>
          pure tail

partial def psKernelBenchLeanMutualAdmissionLoop
    (iterations : Nat)
    (environments : Array Lean.Environment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let some environment := environments[rest % environments.size]?
        | throw (IO.userError "empty admission fixtures")
      let tail ←
        psKernelBenchLeanMutualAdmissionLoop
          rest
          environments
      match
          Lean.Kernel.Environment.addDecl
            environment.toKernelEnv
            {}
            psKernelBenchLeanMutualDecl with
      | .ok next =>
          match
              next.find?
                psKernelBenchLeanMutualEvenRecName,
              next.find?
                psKernelBenchLeanMutualOddRecName with
          | some (.recInfo _), some (.recInfo _) =>
              pure (Nat.succ tail)
          | _, _ =>
              pure tail
      | .error _ =>
          pure tail

-- Each measured loop must actually consume its environment. Re-admitting
-- an existing declaration must fail for both implementations, for all three
-- repaired cases. These checks run outside the performance interval.
def psKernelBenchAdmissionInputGuards
    (portable : Array PsKernelEnvironment) (official : Array Lean.Environment) : IO Unit := do
  if portable.size != 16 || official.size != 16 then
    throw (IO.userError "expected sixteen admission environments")
  let some psBase := portable[0]? | throw (IO.userError "missing portable fixture")
  let some leanBase := official[0]? | throw (IO.userError "missing Lean fixture")
  for kind in [0:3] do
    let psResult := if kind == 0 then
        psKernelAddSimpleInductive 65536 psBase psKernelBenchRecDecl 0 psKernelLeanNatMaxSizeDefault
      else if kind == 1 then
        psKernelAddSimpleInductive 65536 psBase psKernelBenchIndexedDecl 0 psKernelLeanNatMaxSizeDefault
      else
        psKernelAddSimpleMutualInductive 65536 psBase psKernelBenchMutualDecl 0 psKernelLeanNatMaxSizeDefault
    let .ok psOccupied := psResult | throw (IO.userError "portable admission setup failed")
    let leanDecl := if kind == 0 then psKernelBenchLeanRecDecl
      else if kind == 1 then psKernelBenchLeanIndexedDecl else psKernelBenchLeanMutualDecl
    let .ok leanOccupied := Lean.Kernel.Environment.addDecl leanBase.toKernelEnv {} leanDecl
      | throw (IO.userError "Lean admission setup failed")
    let psHits ← if kind == 0 then psKernelBenchInductiveAdmissionLoop 1 #[psOccupied]
      else if kind == 1 then psKernelBenchIndexedAdmissionLoop 1 #[psOccupied]
      else psKernelBenchMutualAdmissionLoop 1 #[psOccupied]
    let leanInputs := #[Lean.Environment.ofKernelEnv leanOccupied]
    let leanHits ← if kind == 0 then psKernelBenchLeanInductiveAdmissionLoop 1 leanInputs
      else if kind == 1 then psKernelBenchLeanIndexedAdmissionLoop 1 leanInputs
      else psKernelBenchLeanMutualAdmissionLoop 1 leanInputs
    if psHits != 0 || leanHits != 0 then
      throw (IO.userError "admission benchmark ignored occupied input")
  IO.println "PSKERNEL_ADMISSION_INPUT_GUARDS: PASS variants=16"
