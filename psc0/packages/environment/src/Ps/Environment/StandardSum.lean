import Ps.Environment.StandardUnsignedClamp

/-
Pinned Lean 4.35.0 src/Init/Core.lean, commit
eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Copyright Lean FRO, LLC; Apache-2.0; see THIRD_PARTY_NOTICES.md.

Sum α β is the genuine Lean disjoint union, with two one-field
constructors and one dependent recursor. Keep distinct universes
for α, β and the motive, and preserve the kernel's generated
constructor/recursor metadata. This is ordinary checked Core,
not a new source primitive, backend union shortcut or axiom.
-/

def psStandardSumName : PsName := psRootName "Sum"
def psStandardSumInlName : PsName := psNameAppendStr psStandardSumName "inl"
def psStandardSumInrName : PsName := psNameAppendStr psStandardSumName "inr"
def psStandardSumRecName : PsName := psNameAppendStr psStandardSumName "rec"

def psStandardSumOf (alpha beta : PsExpr)
    (leftLevel rightLevel : PsLevel := .zero) : PsExpr :=
  psLogicApply (.constE psStandardSumName [leftLevel, rightLevel])
    [alpha, beta]

def psStandardSumInjection (name : PsName)
    (alpha beta value : PsExpr)
    (leftLevel rightLevel : PsLevel := .zero) : PsExpr :=
  psLogicApply (.constE name [leftLevel, rightLevel])
    [alpha, beta, value]

def psStandardSumDeclarations : List PsDeclaration :=
  let u := psRootName "u"
  let v := psRootName "v"
  let w := psRootName "u_1"
  let ul := PsLevel.param u
  let vl := PsLevel.param v
  let alpha := PsExpr.fvar 0
  let beta := PsExpr.fvar 1
  let sum := psStandardSumOf alpha beta ul vl
  let bind := fun body binder => psLogicPi 0 "α" (.sortE (.succ ul))
    (psLogicPi 1 "β" (.sortE (.succ vl)) body binder) binder
  let motive := PsExpr.fvar 2
  let motiveType := psLogicPi 6 "value" sum (.sortE (.param w))
  let inlValue := psStandardSumInjection psStandardSumInlName alpha beta
    (.fvar 4) ul vl
  let inrValue := psStandardSumInjection psStandardSumInrName alpha beta
    (.fvar 5) ul vl
  let inlMinor := psLogicPi 4 "val" alpha (.app motive inlValue)
  let inrMinor := psLogicPi 5 "val" beta (.app motive inrValue)
  let recursorType := bind
    (psLogicPi 2 "motive" motiveType
      (psLogicPi 3 "inl" inlMinor
        (psLogicPi 4 "inr" inrMinor
          (psLogicPi 6 "value" sum (.app motive (.fvar 6)))))
      .implicit) .implicit
  [ .inductiveDecl (.mk psStandardSumName [u, v]
      (bind (.sortE (.succ (.max ul vl))) .explicit)
      2 0 [psStandardSumInlName, psStandardSumInrName] false),
    .constructorDecl (.mk psStandardSumInlName [u, v]
      (bind (psLogicPi 4 "val" alpha sum) .implicit)
      psStandardSumName 0 2 1 []),
    .constructorDecl (.mk psStandardSumInrName [u, v]
      (bind (psLogicPi 5 "val" beta sum) .implicit)
      psStandardSumName 1 2 1 []),
    .recursorDecl (.mk psStandardSumRecName [w, u, v]
      recursorType [psStandardSumName] 2 0 1 2) ]

def psStandardSumExtend (environment : PsEnvironment) : PsEnvironment :=
  psStandardSumDeclarations.foldl psEnvironmentInsert environment

def psStandardSumRuntimeDeclarations : List PsDeclaration :=
  psStandardSumDeclarations
