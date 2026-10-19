/-
Copyright (c) Microsoft Corporation and Lean FRO, LLC.
Apache-2.0; see THIRD_PARTY_NOTICES.md.
Pinned Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Independent Core-first bootstrap candidate from an empty kernel environment.
Actual native declarations; no Full boundary or legacy primitive assumptions.
-/
import Ps.Environment.Basic

set_option maxRecDepth 20000

private def coreBootstrapCandidateDeclNode0 : PsName := (.str .anonymous "And")
private def coreBootstrapCandidateDeclNode1 : PsName := (.str .anonymous "a")
private def coreBootstrapCandidateDeclNode2 : PsExpr := (.sortE .zero)
private def coreBootstrapCandidateDeclNode3 : PsName := (.str .anonymous "b")
private def coreBootstrapCandidateDeclNode4 : PsExpr := (.forallE coreBootstrapCandidateDeclNode3 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode2 .explicit)
private def coreBootstrapCandidateDeclNode5 : PsExpr := (.forallE coreBootstrapCandidateDeclNode1 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode4 .explicit)
private def coreBootstrapCandidateDeclNode6 : PsName := (.str coreBootstrapCandidateDeclNode0 "intro")
private def coreBootstrapCandidateDeclNode7 : PsName := (.str .anonymous "Bool")
private def coreBootstrapCandidateDeclNode8 : PsLevel := (.succ .zero)
private def coreBootstrapCandidateDeclNode9 : PsExpr := (.sortE coreBootstrapCandidateDeclNode8)
private def coreBootstrapCandidateDeclNode10 : PsName := (.str coreBootstrapCandidateDeclNode7 "false")
private def coreBootstrapCandidateDeclNode11 : PsName := (.str coreBootstrapCandidateDeclNode7 "true")
private def coreBootstrapCandidateDeclNode12 : PsName := (.str .anonymous "Decidable")
private def coreBootstrapCandidateDeclNode13 : PsName := (.str .anonymous "p")
private def coreBootstrapCandidateDeclNode14 : PsExpr := (.forallE coreBootstrapCandidateDeclNode13 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode9 .explicit)
private def coreBootstrapCandidateDeclNode15 : PsName := (.str coreBootstrapCandidateDeclNode12 "intro")
private def coreBootstrapCandidateDeclNode16 : PsName := (.str .anonymous "Empty")
private def coreBootstrapCandidateDeclNode17 : PsName := (.str .anonymous "Eq")
private def coreBootstrapCandidateDeclNode18 : PsName := (.str .anonymous "u_1")
private def coreBootstrapCandidateDeclNode19 : PsName := (.str .anonymous "α")
private def coreBootstrapCandidateDeclNode20 : PsLevel := (.param coreBootstrapCandidateDeclNode18)
private def coreBootstrapCandidateDeclNode21 : PsExpr := (.sortE coreBootstrapCandidateDeclNode20)
private def coreBootstrapCandidateDeclNode22 : PsName := (.str coreBootstrapCandidateDeclNode1 "_@")
private def coreBootstrapCandidateDeclNode23 : PsName := (.str coreBootstrapCandidateDeclNode22 "_internal")
private def coreBootstrapCandidateDeclNode24 : PsName := (.str coreBootstrapCandidateDeclNode23 "_hyg")
private def coreBootstrapCandidateDeclNode25 : PsName := (.num coreBootstrapCandidateDeclNode24 0)
private def coreBootstrapCandidateDeclNode26 : PsExpr := (.forallE coreBootstrapCandidateDeclNode25 (.bvar 1) coreBootstrapCandidateDeclNode2 .explicit)
private def coreBootstrapCandidateDeclNode27 : PsExpr := (.forallE coreBootstrapCandidateDeclNode25 (.bvar 0) coreBootstrapCandidateDeclNode26 .explicit)
private def coreBootstrapCandidateDeclNode28 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode21 coreBootstrapCandidateDeclNode27 .implicit)
private def coreBootstrapCandidateDeclNode29 : PsName := (.str coreBootstrapCandidateDeclNode17 "refl")
private def coreBootstrapCandidateDeclNode30 : PsName := (.str .anonymous "Except")
private def coreBootstrapCandidateDeclNode31 : PsName := (.str .anonymous "u")
private def coreBootstrapCandidateDeclNode32 : PsName := (.str .anonymous "v")
private def coreBootstrapCandidateDeclNode33 : PsName := (.str .anonymous "ε")
private def coreBootstrapCandidateDeclNode34 : PsLevel := (.param coreBootstrapCandidateDeclNode31)
private def coreBootstrapCandidateDeclNode35 : PsLevel := (.succ coreBootstrapCandidateDeclNode34)
private def coreBootstrapCandidateDeclNode36 : PsExpr := (.sortE coreBootstrapCandidateDeclNode35)
private def coreBootstrapCandidateDeclNode37 : PsLevel := (.param coreBootstrapCandidateDeclNode32)
private def coreBootstrapCandidateDeclNode38 : PsLevel := (.succ coreBootstrapCandidateDeclNode37)
private def coreBootstrapCandidateDeclNode39 : PsExpr := (.sortE coreBootstrapCandidateDeclNode38)
private def coreBootstrapCandidateDeclNode40 : PsLevel := (.max coreBootstrapCandidateDeclNode35 coreBootstrapCandidateDeclNode38)
private def coreBootstrapCandidateDeclNode41 : PsExpr := (.sortE coreBootstrapCandidateDeclNode40)
private def coreBootstrapCandidateDeclNode42 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode39 coreBootstrapCandidateDeclNode41 .explicit)
private def coreBootstrapCandidateDeclNode43 : PsExpr := (.forallE coreBootstrapCandidateDeclNode33 coreBootstrapCandidateDeclNode36 coreBootstrapCandidateDeclNode42 .explicit)
private def coreBootstrapCandidateDeclNode44 : PsName := (.str coreBootstrapCandidateDeclNode30 "error")
private def coreBootstrapCandidateDeclNode45 : PsName := (.str coreBootstrapCandidateDeclNode30 "ok")
private def coreBootstrapCandidateDeclNode46 : PsName := (.str .anonymous "Exists")
private def coreBootstrapCandidateDeclNode47 : PsExpr := (.sortE coreBootstrapCandidateDeclNode34)
private def coreBootstrapCandidateDeclNode48 : PsExpr := (.forallE coreBootstrapCandidateDeclNode25 (.bvar 0) coreBootstrapCandidateDeclNode2 .explicit)
private def coreBootstrapCandidateDeclNode49 : PsExpr := (.forallE coreBootstrapCandidateDeclNode13 coreBootstrapCandidateDeclNode48 coreBootstrapCandidateDeclNode2 .explicit)
private def coreBootstrapCandidateDeclNode50 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode49 .implicit)
private def coreBootstrapCandidateDeclNode51 : PsName := (.str coreBootstrapCandidateDeclNode46 "intro")
private def coreBootstrapCandidateDeclNode52 : PsName := (.str .anonymous "False")
private def coreBootstrapCandidateDeclNode53 : PsName := (.str .anonymous "HEq")
private def coreBootstrapCandidateDeclNode54 : PsName := (.str .anonymous "β")
private def coreBootstrapCandidateDeclNode55 : PsExpr := (.forallE coreBootstrapCandidateDeclNode54 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode48 .implicit)
private def coreBootstrapCandidateDeclNode56 : PsExpr := (.forallE coreBootstrapCandidateDeclNode25 (.bvar 0) coreBootstrapCandidateDeclNode55 .explicit)
private def coreBootstrapCandidateDeclNode57 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode56 .implicit)
private def coreBootstrapCandidateDeclNode58 : PsName := (.str coreBootstrapCandidateDeclNode53 "refl")
private def coreBootstrapCandidateDeclNode59 : PsName := (.str .anonymous "List")
private def coreBootstrapCandidateDeclNode60 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode36 coreBootstrapCandidateDeclNode36 .explicit)
private def coreBootstrapCandidateDeclNode61 : PsName := (.str coreBootstrapCandidateDeclNode59 "nil")
private def coreBootstrapCandidateDeclNode62 : PsName := (.str coreBootstrapCandidateDeclNode59 "cons")
private def coreBootstrapCandidateDeclNode63 : PsName := (.str .anonymous "Nat")
private def coreBootstrapCandidateDeclNode64 : PsName := (.str coreBootstrapCandidateDeclNode63 "zero")
private def coreBootstrapCandidateDeclNode65 : PsName := (.str coreBootstrapCandidateDeclNode63 "succ")
private def coreBootstrapCandidateDeclNode66 : PsName := (.str .anonymous "Nonempty")
private def coreBootstrapCandidateDeclNode67 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode2 .explicit)
private def coreBootstrapCandidateDeclNode68 : PsName := (.str coreBootstrapCandidateDeclNode66 "intro")
private def coreBootstrapCandidateDeclNode69 : PsName := (.str .anonymous "Not")
private def coreBootstrapCandidateDeclNode70 : PsExpr := (.forallE coreBootstrapCandidateDeclNode1 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode2 .explicit)
private def coreBootstrapCandidateDeclNode71 : PsExpr := (.constE coreBootstrapCandidateDeclNode52 [])
private def coreBootstrapCandidateDeclNode72 : PsExpr := (.forallE coreBootstrapCandidateDeclNode25 (.bvar 0) coreBootstrapCandidateDeclNode71 .explicit)
private def coreBootstrapCandidateDeclNode73 : PsExpr := (.lam coreBootstrapCandidateDeclNode1 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode72 .explicit)
private def coreBootstrapCandidateDeclNode74 : PsName := (.str .anonymous "Option")
private def coreBootstrapCandidateDeclNode75 : PsName := (.str coreBootstrapCandidateDeclNode74 "none")
private def coreBootstrapCandidateDeclNode76 : PsName := (.str coreBootstrapCandidateDeclNode74 "some")
private def coreBootstrapCandidateDeclNode77 : PsName := (.str .anonymous "Or")
private def coreBootstrapCandidateDeclNode78 : PsName := (.str coreBootstrapCandidateDeclNode77 "inl")
private def coreBootstrapCandidateDeclNode79 : PsName := (.str coreBootstrapCandidateDeclNode77 "inr")
private def coreBootstrapCandidateDeclNode80 : PsName := (.str .anonymous "PEmpty")
private def coreBootstrapCandidateDeclNode81 : PsName := (.str .anonymous "PProd")
private def coreBootstrapCandidateDeclNode82 : PsExpr := (.sortE coreBootstrapCandidateDeclNode37)
private def coreBootstrapCandidateDeclNode83 : PsLevel := (.max coreBootstrapCandidateDeclNode8 coreBootstrapCandidateDeclNode34)
private def coreBootstrapCandidateDeclNode84 : PsLevel := (.max coreBootstrapCandidateDeclNode83 coreBootstrapCandidateDeclNode37)
private def coreBootstrapCandidateDeclNode85 : PsExpr := (.sortE coreBootstrapCandidateDeclNode84)
private def coreBootstrapCandidateDeclNode86 : PsExpr := (.forallE coreBootstrapCandidateDeclNode54 coreBootstrapCandidateDeclNode82 coreBootstrapCandidateDeclNode85 .explicit)
private def coreBootstrapCandidateDeclNode87 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode86 .explicit)
private def coreBootstrapCandidateDeclNode88 : PsName := (.str coreBootstrapCandidateDeclNode81 "mk")
private def coreBootstrapCandidateDeclNode89 : PsName := (.str .anonymous "PUnit")
private def coreBootstrapCandidateDeclNode90 : PsName := (.str coreBootstrapCandidateDeclNode89 "unit")
private def coreBootstrapCandidateDeclNode91 : PsName := (.str .anonymous "Prod")
private def coreBootstrapCandidateDeclNode92 : PsExpr := (.forallE coreBootstrapCandidateDeclNode54 coreBootstrapCandidateDeclNode39 coreBootstrapCandidateDeclNode41 .explicit)
private def coreBootstrapCandidateDeclNode93 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode36 coreBootstrapCandidateDeclNode92 .explicit)
private def coreBootstrapCandidateDeclNode94 : PsName := (.str coreBootstrapCandidateDeclNode91 "mk")
private def coreBootstrapCandidateDeclNode95 : PsName := (.str .anonymous "Sum")
private def coreBootstrapCandidateDeclNode96 : PsName := (.str coreBootstrapCandidateDeclNode95 "inl")
private def coreBootstrapCandidateDeclNode97 : PsName := (.str coreBootstrapCandidateDeclNode95 "inr")
private def coreBootstrapCandidateDeclNode98 : PsName := (.str .anonymous "True")
private def coreBootstrapCandidateDeclNode99 : PsName := (.str coreBootstrapCandidateDeclNode98 "intro")
private def coreBootstrapCandidateDeclNode100 : PsName := (.str .anonymous "Unit")
private def coreBootstrapCandidateDeclNode101 : PsExpr := (.constE coreBootstrapCandidateDeclNode89 [coreBootstrapCandidateDeclNode8])
private def coreBootstrapCandidateDeclNode102 : PsName := (.str .anonymous "dite")
private def coreBootstrapCandidateDeclNode103 : PsName := (.str .anonymous "c")
private def coreBootstrapCandidateDeclNode104 : PsName := (.str .anonymous "h")
private def coreBootstrapCandidateDeclNode105 : PsExpr := (.constE coreBootstrapCandidateDeclNode12 [])
private def coreBootstrapCandidateDeclNode106 : PsExpr := (.app coreBootstrapCandidateDeclNode105 (.bvar 0))
private def coreBootstrapCandidateDeclNode107 : PsName := (.str .anonymous "t")
private def coreBootstrapCandidateDeclNode108 : PsExpr := (.forallE coreBootstrapCandidateDeclNode25 (.bvar 1) (.bvar 3) .explicit)
private def coreBootstrapCandidateDeclNode109 : PsName := (.str .anonymous "e")
private def coreBootstrapCandidateDeclNode110 : PsExpr := (.constE coreBootstrapCandidateDeclNode69 [])
private def coreBootstrapCandidateDeclNode111 : PsExpr := (.app coreBootstrapCandidateDeclNode110 (.bvar 2))
private def coreBootstrapCandidateDeclNode112 : PsExpr := (.forallE coreBootstrapCandidateDeclNode25 coreBootstrapCandidateDeclNode111 (.bvar 4) .explicit)
private def coreBootstrapCandidateDeclNode113 : PsExpr := (.forallE coreBootstrapCandidateDeclNode109 coreBootstrapCandidateDeclNode112 (.bvar 4) .explicit)
private def coreBootstrapCandidateDeclNode114 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode108 coreBootstrapCandidateDeclNode113 .explicit)
private def coreBootstrapCandidateDeclNode115 : PsExpr := (.forallE coreBootstrapCandidateDeclNode104 coreBootstrapCandidateDeclNode106 coreBootstrapCandidateDeclNode114 .instanceImplicit)
private def coreBootstrapCandidateDeclNode116 : PsExpr := (.forallE coreBootstrapCandidateDeclNode103 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode115 .explicit)
private def coreBootstrapCandidateDeclNode117 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode116 .implicit)
private def coreBootstrapCandidateDeclNode118 : PsName := (.str coreBootstrapCandidateDeclNode7 "casesOn")
private def coreBootstrapCandidateDeclNode119 : PsExpr := (.constE coreBootstrapCandidateDeclNode118 [coreBootstrapCandidateDeclNode34])
private def coreBootstrapCandidateDeclNode120 : PsName := (.str .anonymous "x")
private def coreBootstrapCandidateDeclNode121 : PsName := (.str coreBootstrapCandidateDeclNode120 "_@")
private def coreBootstrapCandidateDeclNode122 : PsName := (.str coreBootstrapCandidateDeclNode121 "Init")
private def coreBootstrapCandidateDeclNode123 : PsName := (.str coreBootstrapCandidateDeclNode122 "Prelude")
private def coreBootstrapCandidateDeclNode124 : PsName := (.num coreBootstrapCandidateDeclNode123 3893281826)
private def coreBootstrapCandidateDeclNode125 : PsName := (.str coreBootstrapCandidateDeclNode124 "_hygCtx")
private def coreBootstrapCandidateDeclNode126 : PsName := (.str coreBootstrapCandidateDeclNode125 "_hyg")
private def coreBootstrapCandidateDeclNode127 : PsName := (.num coreBootstrapCandidateDeclNode126 17)
private def coreBootstrapCandidateDeclNode128 : PsExpr := (.constE coreBootstrapCandidateDeclNode7 [])
private def coreBootstrapCandidateDeclNode129 : PsName := (.num coreBootstrapCandidateDeclNode126 16)
private def coreBootstrapCandidateDeclNode130 : PsName := (.str coreBootstrapCandidateDeclNode7 "Reflects")
private def coreBootstrapCandidateDeclNode131 : PsExpr := (.constE coreBootstrapCandidateDeclNode130 [])
private def coreBootstrapCandidateDeclNode132 : PsExpr := (.app coreBootstrapCandidateDeclNode131 (.bvar 0))
private def coreBootstrapCandidateDeclNode133 : PsExpr := (.app coreBootstrapCandidateDeclNode132 (.bvar 4))
private def coreBootstrapCandidateDeclNode134 : PsExpr := (.forallE coreBootstrapCandidateDeclNode129 coreBootstrapCandidateDeclNode133 (.bvar 6) .explicit)
private def coreBootstrapCandidateDeclNode135 : PsExpr := (.lam coreBootstrapCandidateDeclNode127 coreBootstrapCandidateDeclNode128 coreBootstrapCandidateDeclNode134 .explicit)
private def coreBootstrapCandidateDeclNode136 : PsExpr := (.app coreBootstrapCandidateDeclNode119 coreBootstrapCandidateDeclNode135)
private def coreBootstrapCandidateDeclNode137 : PsName := (.str coreBootstrapCandidateDeclNode12 "decide")
private def coreBootstrapCandidateDeclNode138 : PsExpr := (.constE coreBootstrapCandidateDeclNode137 [])
private def coreBootstrapCandidateDeclNode139 : PsExpr := (.app coreBootstrapCandidateDeclNode138 (.bvar 3))
private def coreBootstrapCandidateDeclNode140 : PsExpr := (.app coreBootstrapCandidateDeclNode139 (.bvar 2))
private def coreBootstrapCandidateDeclNode141 : PsExpr := (.app coreBootstrapCandidateDeclNode136 coreBootstrapCandidateDeclNode140)
private def coreBootstrapCandidateDeclNode142 : PsExpr := (.app coreBootstrapCandidateDeclNode141 (.bvar 0))
private def coreBootstrapCandidateDeclNode143 : PsExpr := (.app coreBootstrapCandidateDeclNode142 (.bvar 1))
private def coreBootstrapCandidateDeclNode144 : PsName := (.str coreBootstrapCandidateDeclNode12 "reflects_decide")
private def coreBootstrapCandidateDeclNode145 : PsExpr := (.constE coreBootstrapCandidateDeclNode144 [])
private def coreBootstrapCandidateDeclNode146 : PsExpr := (.app coreBootstrapCandidateDeclNode145 (.bvar 3))
private def coreBootstrapCandidateDeclNode147 : PsExpr := (.app coreBootstrapCandidateDeclNode146 (.bvar 2))
private def coreBootstrapCandidateDeclNode148 : PsExpr := (.app coreBootstrapCandidateDeclNode143 coreBootstrapCandidateDeclNode147)
private def coreBootstrapCandidateDeclNode149 : PsExpr := (.lam coreBootstrapCandidateDeclNode109 coreBootstrapCandidateDeclNode112 coreBootstrapCandidateDeclNode148 .explicit)
private def coreBootstrapCandidateDeclNode150 : PsExpr := (.lam coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode108 coreBootstrapCandidateDeclNode149 .explicit)
private def coreBootstrapCandidateDeclNode151 : PsExpr := (.lam coreBootstrapCandidateDeclNode104 coreBootstrapCandidateDeclNode106 coreBootstrapCandidateDeclNode150 .instanceImplicit)
private def coreBootstrapCandidateDeclNode152 : PsExpr := (.lam coreBootstrapCandidateDeclNode103 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode151 .explicit)
private def coreBootstrapCandidateDeclNode153 : PsExpr := (.lam coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode152 .implicit)
private def coreBootstrapCandidateDeclNode154 : PsName := (.str .anonymous "id")
private def coreBootstrapCandidateDeclNode155 : PsExpr := (.forallE coreBootstrapCandidateDeclNode1 (.bvar 0) (.bvar 1) .explicit)
private def coreBootstrapCandidateDeclNode156 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode155 .implicit)
private def coreBootstrapCandidateDeclNode157 : PsExpr := (.lam coreBootstrapCandidateDeclNode1 (.bvar 0) (.bvar 0) .explicit)
private def coreBootstrapCandidateDeclNode158 : PsExpr := (.lam coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode157 .implicit)
private def coreBootstrapCandidateDeclNode159 : PsName := (.str .anonymous "ite")
private def coreBootstrapCandidateDeclNode160 : PsExpr := (.forallE coreBootstrapCandidateDeclNode109 (.bvar 3) (.bvar 4) .explicit)
private def coreBootstrapCandidateDeclNode161 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 (.bvar 2) coreBootstrapCandidateDeclNode160 .explicit)
private def coreBootstrapCandidateDeclNode162 : PsExpr := (.forallE coreBootstrapCandidateDeclNode104 coreBootstrapCandidateDeclNode106 coreBootstrapCandidateDeclNode161 .instanceImplicit)
private def coreBootstrapCandidateDeclNode163 : PsExpr := (.forallE coreBootstrapCandidateDeclNode103 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode162 .explicit)
private def coreBootstrapCandidateDeclNode164 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode163 .implicit)
private def coreBootstrapCandidateDeclNode165 : PsExpr := (.constE coreBootstrapCandidateDeclNode102 [coreBootstrapCandidateDeclNode34])
private def coreBootstrapCandidateDeclNode166 : PsExpr := (.app coreBootstrapCandidateDeclNode165 (.bvar 4))
private def coreBootstrapCandidateDeclNode167 : PsExpr := (.app coreBootstrapCandidateDeclNode166 (.bvar 3))
private def coreBootstrapCandidateDeclNode168 : PsExpr := (.app coreBootstrapCandidateDeclNode167 (.bvar 2))
private def coreBootstrapCandidateDeclNode169 : PsName := (.num coreBootstrapCandidateDeclNode123 1596968041)
private def coreBootstrapCandidateDeclNode170 : PsName := (.str coreBootstrapCandidateDeclNode169 "_hygCtx")
private def coreBootstrapCandidateDeclNode171 : PsName := (.str coreBootstrapCandidateDeclNode170 "_hyg")
private def coreBootstrapCandidateDeclNode172 : PsName := (.num coreBootstrapCandidateDeclNode171 15)
private def coreBootstrapCandidateDeclNode173 : PsExpr := (.lam coreBootstrapCandidateDeclNode172 (.bvar 3) (.bvar 2) .explicit)
private def coreBootstrapCandidateDeclNode174 : PsExpr := (.app coreBootstrapCandidateDeclNode168 coreBootstrapCandidateDeclNode173)
private def coreBootstrapCandidateDeclNode175 : PsName := (.num coreBootstrapCandidateDeclNode171 22)
private def coreBootstrapCandidateDeclNode176 : PsExpr := (.app coreBootstrapCandidateDeclNode110 (.bvar 3))
private def coreBootstrapCandidateDeclNode177 : PsExpr := (.lam coreBootstrapCandidateDeclNode175 coreBootstrapCandidateDeclNode176 (.bvar 1) .explicit)
private def coreBootstrapCandidateDeclNode178 : PsExpr := (.app coreBootstrapCandidateDeclNode174 coreBootstrapCandidateDeclNode177)
private def coreBootstrapCandidateDeclNode179 : PsExpr := (.lam coreBootstrapCandidateDeclNode109 (.bvar 3) coreBootstrapCandidateDeclNode178 .explicit)
private def coreBootstrapCandidateDeclNode180 : PsExpr := (.lam coreBootstrapCandidateDeclNode107 (.bvar 2) coreBootstrapCandidateDeclNode179 .explicit)
private def coreBootstrapCandidateDeclNode181 : PsExpr := (.lam coreBootstrapCandidateDeclNode104 coreBootstrapCandidateDeclNode106 coreBootstrapCandidateDeclNode180 .instanceImplicit)
private def coreBootstrapCandidateDeclNode182 : PsExpr := (.lam coreBootstrapCandidateDeclNode103 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode181 .explicit)
private def coreBootstrapCandidateDeclNode183 : PsExpr := (.lam coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode182 .implicit)
private def coreBootstrapCandidateDeclNode184 : PsName := (.str .anonymous "optParam")
private def coreBootstrapCandidateDeclNode185 : PsName := (.str .anonymous "default")
private def coreBootstrapCandidateDeclNode186 : PsExpr := (.forallE coreBootstrapCandidateDeclNode185 (.bvar 0) coreBootstrapCandidateDeclNode47 .explicit)
private def coreBootstrapCandidateDeclNode187 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode186 .explicit)
private def coreBootstrapCandidateDeclNode188 : PsExpr := (.lam coreBootstrapCandidateDeclNode185 (.bvar 0) (.bvar 1) .explicit)
private def coreBootstrapCandidateDeclNode189 : PsExpr := (.lam coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode188 .explicit)
private def coreBootstrapCandidateDeclNode190 : PsName := (.str .anonymous "outParam")
private def coreBootstrapCandidateDeclNode191 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode47 .explicit)
private def coreBootstrapCandidateDeclNode192 : PsExpr := (.lam coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 (.bvar 0) .explicit)
private def coreBootstrapCandidateDeclNode193 : PsName := (.str .anonymous "left")
private def coreBootstrapCandidateDeclNode194 : PsName := (.str .anonymous "right")
private def coreBootstrapCandidateDeclNode195 : PsExpr := (.constE coreBootstrapCandidateDeclNode0 [])
private def coreBootstrapCandidateDeclNode196 : PsExpr := (.app coreBootstrapCandidateDeclNode195 (.bvar 3))
private def coreBootstrapCandidateDeclNode197 : PsExpr := (.app coreBootstrapCandidateDeclNode196 (.bvar 2))
private def coreBootstrapCandidateDeclNode198 : PsExpr := (.forallE coreBootstrapCandidateDeclNode194 (.bvar 1) coreBootstrapCandidateDeclNode197 .explicit)
private def coreBootstrapCandidateDeclNode199 : PsExpr := (.forallE coreBootstrapCandidateDeclNode193 (.bvar 1) coreBootstrapCandidateDeclNode198 .explicit)
private def coreBootstrapCandidateDeclNode200 : PsExpr := (.forallE coreBootstrapCandidateDeclNode3 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode199 .implicit)
private def coreBootstrapCandidateDeclNode201 : PsExpr := (.forallE coreBootstrapCandidateDeclNode1 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode200 .implicit)
private def coreBootstrapCandidateDeclNode202 : PsName := (.str coreBootstrapCandidateDeclNode0 "rec")
private def coreBootstrapCandidateDeclNode203 : PsName := (.str .anonymous "motive")
private def coreBootstrapCandidateDeclNode204 : PsExpr := (.app coreBootstrapCandidateDeclNode195 (.bvar 1))
private def coreBootstrapCandidateDeclNode205 : PsExpr := (.app coreBootstrapCandidateDeclNode204 (.bvar 0))
private def coreBootstrapCandidateDeclNode206 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode205 coreBootstrapCandidateDeclNode47 .explicit)
private def coreBootstrapCandidateDeclNode207 : PsName := (.str .anonymous "intro")
private def coreBootstrapCandidateDeclNode208 : PsExpr := (.constE coreBootstrapCandidateDeclNode6 [])
private def coreBootstrapCandidateDeclNode209 : PsExpr := (.app coreBootstrapCandidateDeclNode208 (.bvar 4))
private def coreBootstrapCandidateDeclNode210 : PsExpr := (.app coreBootstrapCandidateDeclNode209 (.bvar 3))
private def coreBootstrapCandidateDeclNode211 : PsExpr := (.app coreBootstrapCandidateDeclNode210 (.bvar 1))
private def coreBootstrapCandidateDeclNode212 : PsExpr := (.app coreBootstrapCandidateDeclNode211 (.bvar 0))
private def coreBootstrapCandidateDeclNode213 : PsExpr := (.app (.bvar 2) coreBootstrapCandidateDeclNode212)
private def coreBootstrapCandidateDeclNode214 : PsExpr := (.forallE coreBootstrapCandidateDeclNode194 (.bvar 2) coreBootstrapCandidateDeclNode213 .explicit)
private def coreBootstrapCandidateDeclNode215 : PsExpr := (.forallE coreBootstrapCandidateDeclNode193 (.bvar 2) coreBootstrapCandidateDeclNode214 .explicit)
private def coreBootstrapCandidateDeclNode216 : PsExpr := (.app (.bvar 2) (.bvar 0))
private def coreBootstrapCandidateDeclNode217 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode197 coreBootstrapCandidateDeclNode216 .explicit)
private def coreBootstrapCandidateDeclNode218 : PsExpr := (.forallE coreBootstrapCandidateDeclNode207 coreBootstrapCandidateDeclNode215 coreBootstrapCandidateDeclNode217 .explicit)
private def coreBootstrapCandidateDeclNode219 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode206 coreBootstrapCandidateDeclNode218 .implicit)
private def coreBootstrapCandidateDeclNode220 : PsExpr := (.forallE coreBootstrapCandidateDeclNode3 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode219 .implicit)
private def coreBootstrapCandidateDeclNode221 : PsExpr := (.forallE coreBootstrapCandidateDeclNode1 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode220 .implicit)
private def coreBootstrapCandidateDeclNode222 : PsExpr := (.forallE coreBootstrapCandidateDeclNode25 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode2 .explicit)
private def coreBootstrapCandidateDeclNode223 : PsExpr := (.forallE coreBootstrapCandidateDeclNode25 coreBootstrapCandidateDeclNode128 coreBootstrapCandidateDeclNode222 .explicit)
private def coreBootstrapCandidateDeclNode224 : PsName := (.num coreBootstrapCandidateDeclNode123 3273385309)
private def coreBootstrapCandidateDeclNode225 : PsName := (.str coreBootstrapCandidateDeclNode224 "_hygCtx")
private def coreBootstrapCandidateDeclNode226 : PsName := (.str coreBootstrapCandidateDeclNode225 "_hyg")
private def coreBootstrapCandidateDeclNode227 : PsName := (.num coreBootstrapCandidateDeclNode226 7)
private def coreBootstrapCandidateDeclNode228 : PsName := (.num coreBootstrapCandidateDeclNode226 8)
private def coreBootstrapCandidateDeclNode229 : PsName := (.str coreBootstrapCandidateDeclNode130 "match_1")
private def coreBootstrapCandidateDeclNode230 : PsExpr := (.constE coreBootstrapCandidateDeclNode229 [coreBootstrapCandidateDeclNode8])
private def coreBootstrapCandidateDeclNode231 : PsName := (.num coreBootstrapCandidateDeclNode225 7)
private def coreBootstrapCandidateDeclNode232 : PsName := (.str coreBootstrapCandidateDeclNode231 "Init")
private def coreBootstrapCandidateDeclNode233 : PsName := (.str coreBootstrapCandidateDeclNode232 "Prelude")
private def coreBootstrapCandidateDeclNode234 : PsName := (.num coreBootstrapCandidateDeclNode233 3273385309)
private def coreBootstrapCandidateDeclNode235 : PsName := (.str coreBootstrapCandidateDeclNode234 "_hygCtx")
private def coreBootstrapCandidateDeclNode236 : PsName := (.str coreBootstrapCandidateDeclNode235 "_hyg")
private def coreBootstrapCandidateDeclNode237 : PsName := (.num coreBootstrapCandidateDeclNode236 26)
private def coreBootstrapCandidateDeclNode238 : PsName := (.num coreBootstrapCandidateDeclNode225 8)
private def coreBootstrapCandidateDeclNode239 : PsName := (.str coreBootstrapCandidateDeclNode238 "Init")
private def coreBootstrapCandidateDeclNode240 : PsName := (.str coreBootstrapCandidateDeclNode239 "Prelude")
private def coreBootstrapCandidateDeclNode241 : PsName := (.num coreBootstrapCandidateDeclNode240 3273385309)
private def coreBootstrapCandidateDeclNode242 : PsName := (.str coreBootstrapCandidateDeclNode241 "_hygCtx")
private def coreBootstrapCandidateDeclNode243 : PsName := (.str coreBootstrapCandidateDeclNode242 "_hyg")
private def coreBootstrapCandidateDeclNode244 : PsName := (.num coreBootstrapCandidateDeclNode243 29)
private def coreBootstrapCandidateDeclNode245 : PsExpr := (.lam coreBootstrapCandidateDeclNode244 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode2 .explicit)
private def coreBootstrapCandidateDeclNode246 : PsExpr := (.lam coreBootstrapCandidateDeclNode237 coreBootstrapCandidateDeclNode128 coreBootstrapCandidateDeclNode245 .explicit)
private def coreBootstrapCandidateDeclNode247 : PsExpr := (.app coreBootstrapCandidateDeclNode230 coreBootstrapCandidateDeclNode246)
private def coreBootstrapCandidateDeclNode248 : PsExpr := (.app coreBootstrapCandidateDeclNode247 (.bvar 1))
private def coreBootstrapCandidateDeclNode249 : PsExpr := (.app coreBootstrapCandidateDeclNode248 (.bvar 0))
private def coreBootstrapCandidateDeclNode250 : PsExpr := (.app coreBootstrapCandidateDeclNode110 (.bvar 0))
private def coreBootstrapCandidateDeclNode251 : PsExpr := (.lam coreBootstrapCandidateDeclNode13 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode250 .explicit)
private def coreBootstrapCandidateDeclNode252 : PsExpr := (.app coreBootstrapCandidateDeclNode249 coreBootstrapCandidateDeclNode251)
private def coreBootstrapCandidateDeclNode253 : PsExpr := (.lam coreBootstrapCandidateDeclNode13 coreBootstrapCandidateDeclNode2 (.bvar 0) .explicit)
private def coreBootstrapCandidateDeclNode254 : PsExpr := (.app coreBootstrapCandidateDeclNode252 coreBootstrapCandidateDeclNode253)
private def coreBootstrapCandidateDeclNode255 : PsExpr := (.lam coreBootstrapCandidateDeclNode228 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode254 .explicit)
private def coreBootstrapCandidateDeclNode256 : PsExpr := (.lam coreBootstrapCandidateDeclNode227 coreBootstrapCandidateDeclNode128 coreBootstrapCandidateDeclNode255 .explicit)
private def coreBootstrapCandidateDeclNode257 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode128 coreBootstrapCandidateDeclNode47 .explicit)
private def coreBootstrapCandidateDeclNode258 : PsName := (.str .anonymous "false")
private def coreBootstrapCandidateDeclNode259 : PsExpr := (.constE coreBootstrapCandidateDeclNode10 [])
private def coreBootstrapCandidateDeclNode260 : PsExpr := (.app (.bvar 1) coreBootstrapCandidateDeclNode259)
private def coreBootstrapCandidateDeclNode261 : PsName := (.str .anonymous "true")
private def coreBootstrapCandidateDeclNode262 : PsExpr := (.constE coreBootstrapCandidateDeclNode11 [])
private def coreBootstrapCandidateDeclNode263 : PsExpr := (.app (.bvar 2) coreBootstrapCandidateDeclNode262)
private def coreBootstrapCandidateDeclNode264 : PsExpr := (.app (.bvar 3) (.bvar 2))
private def coreBootstrapCandidateDeclNode265 : PsExpr := (.forallE coreBootstrapCandidateDeclNode261 coreBootstrapCandidateDeclNode263 coreBootstrapCandidateDeclNode264 .explicit)
private def coreBootstrapCandidateDeclNode266 : PsExpr := (.forallE coreBootstrapCandidateDeclNode258 coreBootstrapCandidateDeclNode260 coreBootstrapCandidateDeclNode265 .explicit)
private def coreBootstrapCandidateDeclNode267 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode128 coreBootstrapCandidateDeclNode266 .explicit)
private def coreBootstrapCandidateDeclNode268 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode257 coreBootstrapCandidateDeclNode267 .implicit)
private def coreBootstrapCandidateDeclNode269 : PsName := (.str coreBootstrapCandidateDeclNode7 "rec")
private def coreBootstrapCandidateDeclNode270 : PsExpr := (.constE coreBootstrapCandidateDeclNode269 [coreBootstrapCandidateDeclNode34])
private def coreBootstrapCandidateDeclNode271 : PsExpr := (.app coreBootstrapCandidateDeclNode270 (.bvar 3))
private def coreBootstrapCandidateDeclNode272 : PsExpr := (.app coreBootstrapCandidateDeclNode271 (.bvar 1))
private def coreBootstrapCandidateDeclNode273 : PsExpr := (.app coreBootstrapCandidateDeclNode272 (.bvar 0))
private def coreBootstrapCandidateDeclNode274 : PsExpr := (.app coreBootstrapCandidateDeclNode273 (.bvar 2))
private def coreBootstrapCandidateDeclNode275 : PsExpr := (.lam coreBootstrapCandidateDeclNode261 coreBootstrapCandidateDeclNode263 coreBootstrapCandidateDeclNode274 .explicit)
private def coreBootstrapCandidateDeclNode276 : PsExpr := (.lam coreBootstrapCandidateDeclNode258 coreBootstrapCandidateDeclNode260 coreBootstrapCandidateDeclNode275 .explicit)
private def coreBootstrapCandidateDeclNode277 : PsExpr := (.lam coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode128 coreBootstrapCandidateDeclNode276 .explicit)
private def coreBootstrapCandidateDeclNode278 : PsExpr := (.lam coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode257 coreBootstrapCandidateDeclNode277 .implicit)
private def coreBootstrapCandidateDeclNode279 : PsExpr := (.app (.bvar 0) coreBootstrapCandidateDeclNode259)
private def coreBootstrapCandidateDeclNode280 : PsExpr := (.app (.bvar 1) coreBootstrapCandidateDeclNode262)
private def coreBootstrapCandidateDeclNode281 : PsExpr := (.app (.bvar 3) (.bvar 0))
private def coreBootstrapCandidateDeclNode282 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode128 coreBootstrapCandidateDeclNode281 .explicit)
private def coreBootstrapCandidateDeclNode283 : PsExpr := (.forallE coreBootstrapCandidateDeclNode261 coreBootstrapCandidateDeclNode280 coreBootstrapCandidateDeclNode282 .explicit)
private def coreBootstrapCandidateDeclNode284 : PsExpr := (.forallE coreBootstrapCandidateDeclNode258 coreBootstrapCandidateDeclNode279 coreBootstrapCandidateDeclNode283 .explicit)
private def coreBootstrapCandidateDeclNode285 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode257 coreBootstrapCandidateDeclNode284 .implicit)
private def coreBootstrapCandidateDeclNode286 : PsName := (.str .anonymous "self")
private def coreBootstrapCandidateDeclNode287 : PsExpr := (.forallE coreBootstrapCandidateDeclNode286 coreBootstrapCandidateDeclNode106 coreBootstrapCandidateDeclNode128 .instanceImplicit)
private def coreBootstrapCandidateDeclNode288 : PsExpr := (.forallE coreBootstrapCandidateDeclNode13 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode287 .explicit)
private def coreBootstrapCandidateDeclNode289 : PsExpr := (.proj coreBootstrapCandidateDeclNode12 0 (.bvar 0))
private def coreBootstrapCandidateDeclNode290 : PsExpr := (.lam coreBootstrapCandidateDeclNode286 coreBootstrapCandidateDeclNode106 coreBootstrapCandidateDeclNode289 .instanceImplicit)
private def coreBootstrapCandidateDeclNode291 : PsExpr := (.lam coreBootstrapCandidateDeclNode13 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode290 .explicit)
private def coreBootstrapCandidateDeclNode292 : PsName := (.str .anonymous "decide")
private def coreBootstrapCandidateDeclNode293 : PsName := (.str .anonymous "reflects_decide")
private def coreBootstrapCandidateDeclNode294 : PsExpr := (.app coreBootstrapCandidateDeclNode132 (.bvar 1))
private def coreBootstrapCandidateDeclNode295 : PsExpr := (.app coreBootstrapCandidateDeclNode105 (.bvar 2))
private def coreBootstrapCandidateDeclNode296 : PsExpr := (.forallE coreBootstrapCandidateDeclNode293 coreBootstrapCandidateDeclNode294 coreBootstrapCandidateDeclNode295 .explicit)
private def coreBootstrapCandidateDeclNode297 : PsExpr := (.forallE coreBootstrapCandidateDeclNode292 coreBootstrapCandidateDeclNode128 coreBootstrapCandidateDeclNode296 .explicit)
private def coreBootstrapCandidateDeclNode298 : PsExpr := (.forallE coreBootstrapCandidateDeclNode13 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode297 .implicit)
private def coreBootstrapCandidateDeclNode299 : PsName := (.str coreBootstrapCandidateDeclNode12 "rec")
private def coreBootstrapCandidateDeclNode300 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode106 coreBootstrapCandidateDeclNode47 .explicit)
private def coreBootstrapCandidateDeclNode301 : PsExpr := (.app coreBootstrapCandidateDeclNode132 (.bvar 2))
private def coreBootstrapCandidateDeclNode302 : PsExpr := (.constE coreBootstrapCandidateDeclNode15 [])
private def coreBootstrapCandidateDeclNode303 : PsExpr := (.app coreBootstrapCandidateDeclNode302 (.bvar 3))
private def coreBootstrapCandidateDeclNode304 : PsExpr := (.app coreBootstrapCandidateDeclNode303 (.bvar 1))
private def coreBootstrapCandidateDeclNode305 : PsExpr := (.app coreBootstrapCandidateDeclNode304 (.bvar 0))
private def coreBootstrapCandidateDeclNode306 : PsExpr := (.app (.bvar 2) coreBootstrapCandidateDeclNode305)
private def coreBootstrapCandidateDeclNode307 : PsExpr := (.forallE coreBootstrapCandidateDeclNode293 coreBootstrapCandidateDeclNode301 coreBootstrapCandidateDeclNode306 .explicit)
private def coreBootstrapCandidateDeclNode308 : PsExpr := (.forallE coreBootstrapCandidateDeclNode292 coreBootstrapCandidateDeclNode128 coreBootstrapCandidateDeclNode307 .explicit)
private def coreBootstrapCandidateDeclNode309 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode295 coreBootstrapCandidateDeclNode216 .explicit)
private def coreBootstrapCandidateDeclNode310 : PsExpr := (.forallE coreBootstrapCandidateDeclNode207 coreBootstrapCandidateDeclNode308 coreBootstrapCandidateDeclNode309 .explicit)
private def coreBootstrapCandidateDeclNode311 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode300 coreBootstrapCandidateDeclNode310 .implicit)
private def coreBootstrapCandidateDeclNode312 : PsExpr := (.forallE coreBootstrapCandidateDeclNode13 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode311 .implicit)
private def coreBootstrapCandidateDeclNode313 : PsExpr := (.app coreBootstrapCandidateDeclNode138 (.bvar 1))
private def coreBootstrapCandidateDeclNode314 : PsExpr := (.app coreBootstrapCandidateDeclNode313 (.bvar 0))
private def coreBootstrapCandidateDeclNode315 : PsExpr := (.app coreBootstrapCandidateDeclNode131 coreBootstrapCandidateDeclNode314)
private def coreBootstrapCandidateDeclNode316 : PsExpr := (.app coreBootstrapCandidateDeclNode315 (.bvar 1))
private def coreBootstrapCandidateDeclNode317 : PsExpr := (.forallE coreBootstrapCandidateDeclNode286 coreBootstrapCandidateDeclNode106 coreBootstrapCandidateDeclNode316 .instanceImplicit)
private def coreBootstrapCandidateDeclNode318 : PsExpr := (.forallE coreBootstrapCandidateDeclNode13 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode317 .explicit)
private def coreBootstrapCandidateDeclNode319 : PsExpr := (.proj coreBootstrapCandidateDeclNode12 1 (.bvar 0))
private def coreBootstrapCandidateDeclNode320 : PsExpr := (.lam coreBootstrapCandidateDeclNode286 coreBootstrapCandidateDeclNode106 coreBootstrapCandidateDeclNode319 .instanceImplicit)
private def coreBootstrapCandidateDeclNode321 : PsExpr := (.lam coreBootstrapCandidateDeclNode13 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode320 .explicit)
private def coreBootstrapCandidateDeclNode322 : PsName := (.str coreBootstrapCandidateDeclNode16 "rec")
private def coreBootstrapCandidateDeclNode323 : PsExpr := (.constE coreBootstrapCandidateDeclNode16 [])
private def coreBootstrapCandidateDeclNode324 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode323 coreBootstrapCandidateDeclNode47 .explicit)
private def coreBootstrapCandidateDeclNode325 : PsExpr := (.app (.bvar 1) (.bvar 0))
private def coreBootstrapCandidateDeclNode326 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode323 coreBootstrapCandidateDeclNode325 .explicit)
private def coreBootstrapCandidateDeclNode327 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode324 coreBootstrapCandidateDeclNode326 .explicit)
private def coreBootstrapCandidateDeclNode328 : PsName := (.str coreBootstrapCandidateDeclNode17 "rec")
private def coreBootstrapCandidateDeclNode329 : PsExpr := (.constE coreBootstrapCandidateDeclNode17 [coreBootstrapCandidateDeclNode20])
private def coreBootstrapCandidateDeclNode330 : PsExpr := (.app coreBootstrapCandidateDeclNode329 (.bvar 2))
private def coreBootstrapCandidateDeclNode331 : PsExpr := (.app coreBootstrapCandidateDeclNode330 (.bvar 1))
private def coreBootstrapCandidateDeclNode332 : PsExpr := (.app coreBootstrapCandidateDeclNode331 (.bvar 0))
private def coreBootstrapCandidateDeclNode333 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode332 coreBootstrapCandidateDeclNode47 .explicit)
private def coreBootstrapCandidateDeclNode334 : PsExpr := (.forallE coreBootstrapCandidateDeclNode25 (.bvar 1) coreBootstrapCandidateDeclNode333 .explicit)
private def coreBootstrapCandidateDeclNode335 : PsName := (.str .anonymous "refl")
private def coreBootstrapCandidateDeclNode336 : PsExpr := (.app (.bvar 0) (.bvar 1))
private def coreBootstrapCandidateDeclNode337 : PsExpr := (.constE coreBootstrapCandidateDeclNode29 [coreBootstrapCandidateDeclNode20])
private def coreBootstrapCandidateDeclNode338 : PsExpr := (.app coreBootstrapCandidateDeclNode337 (.bvar 2))
private def coreBootstrapCandidateDeclNode339 : PsExpr := (.app coreBootstrapCandidateDeclNode338 (.bvar 1))
private def coreBootstrapCandidateDeclNode340 : PsExpr := (.app coreBootstrapCandidateDeclNode336 coreBootstrapCandidateDeclNode339)
private def coreBootstrapCandidateDeclNode341 : PsExpr := (.app coreBootstrapCandidateDeclNode329 (.bvar 4))
private def coreBootstrapCandidateDeclNode342 : PsExpr := (.app coreBootstrapCandidateDeclNode341 (.bvar 3))
private def coreBootstrapCandidateDeclNode343 : PsExpr := (.app coreBootstrapCandidateDeclNode342 (.bvar 0))
private def coreBootstrapCandidateDeclNode344 : PsExpr := (.app (.bvar 3) (.bvar 1))
private def coreBootstrapCandidateDeclNode345 : PsExpr := (.app coreBootstrapCandidateDeclNode344 (.bvar 0))
private def coreBootstrapCandidateDeclNode346 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode343 coreBootstrapCandidateDeclNode345 .explicit)
private def coreBootstrapCandidateDeclNode347 : PsExpr := (.forallE coreBootstrapCandidateDeclNode25 (.bvar 3) coreBootstrapCandidateDeclNode346 .implicit)
private def coreBootstrapCandidateDeclNode348 : PsExpr := (.forallE coreBootstrapCandidateDeclNode335 coreBootstrapCandidateDeclNode340 coreBootstrapCandidateDeclNode347 .explicit)
private def coreBootstrapCandidateDeclNode349 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode334 coreBootstrapCandidateDeclNode348 .implicit)
private def coreBootstrapCandidateDeclNode350 : PsExpr := (.forallE coreBootstrapCandidateDeclNode25 (.bvar 0) coreBootstrapCandidateDeclNode349 .implicit)
private def coreBootstrapCandidateDeclNode351 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode21 coreBootstrapCandidateDeclNode350 .implicit)
private def coreBootstrapCandidateDeclNode352 : PsExpr := (.app coreBootstrapCandidateDeclNode329 (.bvar 1))
private def coreBootstrapCandidateDeclNode353 : PsExpr := (.app coreBootstrapCandidateDeclNode352 (.bvar 0))
private def coreBootstrapCandidateDeclNode354 : PsExpr := (.app coreBootstrapCandidateDeclNode353 (.bvar 0))
private def coreBootstrapCandidateDeclNode355 : PsExpr := (.forallE coreBootstrapCandidateDeclNode1 (.bvar 0) coreBootstrapCandidateDeclNode354 .explicit)
private def coreBootstrapCandidateDeclNode356 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode21 coreBootstrapCandidateDeclNode355 .implicit)
private def coreBootstrapCandidateDeclNode357 : PsExpr := (.constE coreBootstrapCandidateDeclNode30 [coreBootstrapCandidateDeclNode34, coreBootstrapCandidateDeclNode37])
private def coreBootstrapCandidateDeclNode358 : PsExpr := (.app coreBootstrapCandidateDeclNode357 (.bvar 2))
private def coreBootstrapCandidateDeclNode359 : PsExpr := (.app coreBootstrapCandidateDeclNode358 (.bvar 1))
private def coreBootstrapCandidateDeclNode360 : PsExpr := (.forallE coreBootstrapCandidateDeclNode25 (.bvar 1) coreBootstrapCandidateDeclNode359 .explicit)
private def coreBootstrapCandidateDeclNode361 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode39 coreBootstrapCandidateDeclNode360 .implicit)
private def coreBootstrapCandidateDeclNode362 : PsExpr := (.forallE coreBootstrapCandidateDeclNode33 coreBootstrapCandidateDeclNode36 coreBootstrapCandidateDeclNode361 .implicit)
private def coreBootstrapCandidateDeclNode363 : PsExpr := (.forallE coreBootstrapCandidateDeclNode25 (.bvar 0) coreBootstrapCandidateDeclNode359 .explicit)
private def coreBootstrapCandidateDeclNode364 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode39 coreBootstrapCandidateDeclNode363 .implicit)
private def coreBootstrapCandidateDeclNode365 : PsExpr := (.forallE coreBootstrapCandidateDeclNode33 coreBootstrapCandidateDeclNode36 coreBootstrapCandidateDeclNode364 .implicit)
private def coreBootstrapCandidateDeclNode366 : PsName := (.str coreBootstrapCandidateDeclNode30 "rec")
private def coreBootstrapCandidateDeclNode367 : PsExpr := (.app coreBootstrapCandidateDeclNode357 (.bvar 1))
private def coreBootstrapCandidateDeclNode368 : PsExpr := (.app coreBootstrapCandidateDeclNode367 (.bvar 0))
private def coreBootstrapCandidateDeclNode369 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode368 coreBootstrapCandidateDeclNode21 .explicit)
private def coreBootstrapCandidateDeclNode370 : PsName := (.str .anonymous "error")
private def coreBootstrapCandidateDeclNode371 : PsExpr := (.constE coreBootstrapCandidateDeclNode44 [coreBootstrapCandidateDeclNode34, coreBootstrapCandidateDeclNode37])
private def coreBootstrapCandidateDeclNode372 : PsExpr := (.app coreBootstrapCandidateDeclNode371 (.bvar 3))
private def coreBootstrapCandidateDeclNode373 : PsExpr := (.app coreBootstrapCandidateDeclNode372 (.bvar 2))
private def coreBootstrapCandidateDeclNode374 : PsExpr := (.app coreBootstrapCandidateDeclNode373 (.bvar 0))
private def coreBootstrapCandidateDeclNode375 : PsExpr := (.app (.bvar 1) coreBootstrapCandidateDeclNode374)
private def coreBootstrapCandidateDeclNode376 : PsExpr := (.forallE coreBootstrapCandidateDeclNode25 (.bvar 2) coreBootstrapCandidateDeclNode375 .explicit)
private def coreBootstrapCandidateDeclNode377 : PsName := (.str .anonymous "ok")
private def coreBootstrapCandidateDeclNode378 : PsExpr := (.constE coreBootstrapCandidateDeclNode45 [coreBootstrapCandidateDeclNode34, coreBootstrapCandidateDeclNode37])
private def coreBootstrapCandidateDeclNode379 : PsExpr := (.app coreBootstrapCandidateDeclNode378 (.bvar 4))
private def coreBootstrapCandidateDeclNode380 : PsExpr := (.app coreBootstrapCandidateDeclNode379 (.bvar 3))
private def coreBootstrapCandidateDeclNode381 : PsExpr := (.app coreBootstrapCandidateDeclNode380 (.bvar 0))
private def coreBootstrapCandidateDeclNode382 : PsExpr := (.app (.bvar 2) coreBootstrapCandidateDeclNode381)
private def coreBootstrapCandidateDeclNode383 : PsExpr := (.forallE coreBootstrapCandidateDeclNode25 (.bvar 2) coreBootstrapCandidateDeclNode382 .explicit)
private def coreBootstrapCandidateDeclNode384 : PsExpr := (.app coreBootstrapCandidateDeclNode357 (.bvar 4))
private def coreBootstrapCandidateDeclNode385 : PsExpr := (.app coreBootstrapCandidateDeclNode384 (.bvar 3))
private def coreBootstrapCandidateDeclNode386 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode385 coreBootstrapCandidateDeclNode281 .explicit)
private def coreBootstrapCandidateDeclNode387 : PsExpr := (.forallE coreBootstrapCandidateDeclNode377 coreBootstrapCandidateDeclNode383 coreBootstrapCandidateDeclNode386 .explicit)
private def coreBootstrapCandidateDeclNode388 : PsExpr := (.forallE coreBootstrapCandidateDeclNode370 coreBootstrapCandidateDeclNode376 coreBootstrapCandidateDeclNode387 .explicit)
private def coreBootstrapCandidateDeclNode389 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode369 coreBootstrapCandidateDeclNode388 .implicit)
private def coreBootstrapCandidateDeclNode390 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode39 coreBootstrapCandidateDeclNode389 .implicit)
private def coreBootstrapCandidateDeclNode391 : PsExpr := (.forallE coreBootstrapCandidateDeclNode33 coreBootstrapCandidateDeclNode36 coreBootstrapCandidateDeclNode390 .implicit)
private def coreBootstrapCandidateDeclNode392 : PsName := (.str .anonymous "w")
private def coreBootstrapCandidateDeclNode393 : PsExpr := (.constE coreBootstrapCandidateDeclNode46 [coreBootstrapCandidateDeclNode34])
private def coreBootstrapCandidateDeclNode394 : PsExpr := (.app coreBootstrapCandidateDeclNode393 (.bvar 3))
private def coreBootstrapCandidateDeclNode395 : PsExpr := (.app coreBootstrapCandidateDeclNode394 (.bvar 2))
private def coreBootstrapCandidateDeclNode396 : PsExpr := (.forallE coreBootstrapCandidateDeclNode104 coreBootstrapCandidateDeclNode325 coreBootstrapCandidateDeclNode395 .explicit)
private def coreBootstrapCandidateDeclNode397 : PsExpr := (.forallE coreBootstrapCandidateDeclNode392 (.bvar 1) coreBootstrapCandidateDeclNode396 .explicit)
private def coreBootstrapCandidateDeclNode398 : PsExpr := (.forallE coreBootstrapCandidateDeclNode13 coreBootstrapCandidateDeclNode48 coreBootstrapCandidateDeclNode397 .implicit)
private def coreBootstrapCandidateDeclNode399 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode398 .implicit)
private def coreBootstrapCandidateDeclNode400 : PsName := (.str coreBootstrapCandidateDeclNode46 "rec")
private def coreBootstrapCandidateDeclNode401 : PsExpr := (.app coreBootstrapCandidateDeclNode393 (.bvar 1))
private def coreBootstrapCandidateDeclNode402 : PsExpr := (.app coreBootstrapCandidateDeclNode401 (.bvar 0))
private def coreBootstrapCandidateDeclNode403 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode402 coreBootstrapCandidateDeclNode2 .explicit)
private def coreBootstrapCandidateDeclNode404 : PsExpr := (.constE coreBootstrapCandidateDeclNode51 [coreBootstrapCandidateDeclNode34])
private def coreBootstrapCandidateDeclNode405 : PsExpr := (.app coreBootstrapCandidateDeclNode404 (.bvar 4))
private def coreBootstrapCandidateDeclNode406 : PsExpr := (.app coreBootstrapCandidateDeclNode405 (.bvar 3))
private def coreBootstrapCandidateDeclNode407 : PsExpr := (.app coreBootstrapCandidateDeclNode406 (.bvar 1))
private def coreBootstrapCandidateDeclNode408 : PsExpr := (.app coreBootstrapCandidateDeclNode407 (.bvar 0))
private def coreBootstrapCandidateDeclNode409 : PsExpr := (.app (.bvar 2) coreBootstrapCandidateDeclNode408)
private def coreBootstrapCandidateDeclNode410 : PsExpr := (.forallE coreBootstrapCandidateDeclNode104 coreBootstrapCandidateDeclNode216 coreBootstrapCandidateDeclNode409 .explicit)
private def coreBootstrapCandidateDeclNode411 : PsExpr := (.forallE coreBootstrapCandidateDeclNode392 (.bvar 2) coreBootstrapCandidateDeclNode410 .explicit)
private def coreBootstrapCandidateDeclNode412 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode395 coreBootstrapCandidateDeclNode216 .explicit)
private def coreBootstrapCandidateDeclNode413 : PsExpr := (.forallE coreBootstrapCandidateDeclNode207 coreBootstrapCandidateDeclNode411 coreBootstrapCandidateDeclNode412 .explicit)
private def coreBootstrapCandidateDeclNode414 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode403 coreBootstrapCandidateDeclNode413 .implicit)
private def coreBootstrapCandidateDeclNode415 : PsExpr := (.forallE coreBootstrapCandidateDeclNode13 coreBootstrapCandidateDeclNode48 coreBootstrapCandidateDeclNode414 .implicit)
private def coreBootstrapCandidateDeclNode416 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode415 .implicit)
private def coreBootstrapCandidateDeclNode417 : PsName := (.str coreBootstrapCandidateDeclNode52 "rec")
private def coreBootstrapCandidateDeclNode418 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode71 coreBootstrapCandidateDeclNode47 .explicit)
private def coreBootstrapCandidateDeclNode419 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode71 coreBootstrapCandidateDeclNode325 .explicit)
private def coreBootstrapCandidateDeclNode420 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode418 coreBootstrapCandidateDeclNode419 .explicit)
private def coreBootstrapCandidateDeclNode421 : PsName := (.str coreBootstrapCandidateDeclNode53 "rec")
private def coreBootstrapCandidateDeclNode422 : PsExpr := (.constE coreBootstrapCandidateDeclNode53 [coreBootstrapCandidateDeclNode34])
private def coreBootstrapCandidateDeclNode423 : PsExpr := (.app coreBootstrapCandidateDeclNode422 (.bvar 3))
private def coreBootstrapCandidateDeclNode424 : PsExpr := (.app coreBootstrapCandidateDeclNode423 (.bvar 2))
private def coreBootstrapCandidateDeclNode425 : PsExpr := (.app coreBootstrapCandidateDeclNode424 (.bvar 1))
private def coreBootstrapCandidateDeclNode426 : PsExpr := (.app coreBootstrapCandidateDeclNode425 (.bvar 0))
private def coreBootstrapCandidateDeclNode427 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode426 coreBootstrapCandidateDeclNode21 .explicit)
private def coreBootstrapCandidateDeclNode428 : PsExpr := (.forallE coreBootstrapCandidateDeclNode25 (.bvar 0) coreBootstrapCandidateDeclNode427 .explicit)
private def coreBootstrapCandidateDeclNode429 : PsExpr := (.forallE coreBootstrapCandidateDeclNode54 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode428 .implicit)
private def coreBootstrapCandidateDeclNode430 : PsExpr := (.app (.bvar 0) (.bvar 2))
private def coreBootstrapCandidateDeclNode431 : PsExpr := (.app coreBootstrapCandidateDeclNode430 (.bvar 1))
private def coreBootstrapCandidateDeclNode432 : PsExpr := (.constE coreBootstrapCandidateDeclNode58 [coreBootstrapCandidateDeclNode34])
private def coreBootstrapCandidateDeclNode433 : PsExpr := (.app coreBootstrapCandidateDeclNode432 (.bvar 2))
private def coreBootstrapCandidateDeclNode434 : PsExpr := (.app coreBootstrapCandidateDeclNode433 (.bvar 1))
private def coreBootstrapCandidateDeclNode435 : PsExpr := (.app coreBootstrapCandidateDeclNode431 coreBootstrapCandidateDeclNode434)
private def coreBootstrapCandidateDeclNode436 : PsExpr := (.app coreBootstrapCandidateDeclNode422 (.bvar 5))
private def coreBootstrapCandidateDeclNode437 : PsExpr := (.app coreBootstrapCandidateDeclNode436 (.bvar 4))
private def coreBootstrapCandidateDeclNode438 : PsExpr := (.app coreBootstrapCandidateDeclNode437 (.bvar 1))
private def coreBootstrapCandidateDeclNode439 : PsExpr := (.app coreBootstrapCandidateDeclNode438 (.bvar 0))
private def coreBootstrapCandidateDeclNode440 : PsExpr := (.app (.bvar 4) (.bvar 2))
private def coreBootstrapCandidateDeclNode441 : PsExpr := (.app coreBootstrapCandidateDeclNode440 (.bvar 1))
private def coreBootstrapCandidateDeclNode442 : PsExpr := (.app coreBootstrapCandidateDeclNode441 (.bvar 0))
private def coreBootstrapCandidateDeclNode443 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode439 coreBootstrapCandidateDeclNode442 .explicit)
private def coreBootstrapCandidateDeclNode444 : PsExpr := (.forallE coreBootstrapCandidateDeclNode25 (.bvar 0) coreBootstrapCandidateDeclNode443 .implicit)
private def coreBootstrapCandidateDeclNode445 : PsExpr := (.forallE coreBootstrapCandidateDeclNode54 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode444 .implicit)
private def coreBootstrapCandidateDeclNode446 : PsExpr := (.forallE coreBootstrapCandidateDeclNode335 coreBootstrapCandidateDeclNode435 coreBootstrapCandidateDeclNode445 .explicit)
private def coreBootstrapCandidateDeclNode447 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode429 coreBootstrapCandidateDeclNode446 .implicit)
private def coreBootstrapCandidateDeclNode448 : PsExpr := (.forallE coreBootstrapCandidateDeclNode25 (.bvar 0) coreBootstrapCandidateDeclNode447 .implicit)
private def coreBootstrapCandidateDeclNode449 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode448 .implicit)
private def coreBootstrapCandidateDeclNode450 : PsExpr := (.app coreBootstrapCandidateDeclNode422 (.bvar 1))
private def coreBootstrapCandidateDeclNode451 : PsExpr := (.app coreBootstrapCandidateDeclNode450 (.bvar 0))
private def coreBootstrapCandidateDeclNode452 : PsExpr := (.app coreBootstrapCandidateDeclNode451 (.bvar 1))
private def coreBootstrapCandidateDeclNode453 : PsExpr := (.app coreBootstrapCandidateDeclNode452 (.bvar 0))
private def coreBootstrapCandidateDeclNode454 : PsExpr := (.forallE coreBootstrapCandidateDeclNode1 (.bvar 0) coreBootstrapCandidateDeclNode453 .explicit)
private def coreBootstrapCandidateDeclNode455 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode454 .implicit)
private def coreBootstrapCandidateDeclNode456 : PsName := (.str .anonymous "head")
private def coreBootstrapCandidateDeclNode457 : PsName := (.str .anonymous "tail")
private def coreBootstrapCandidateDeclNode458 : PsExpr := (.constE coreBootstrapCandidateDeclNode59 [coreBootstrapCandidateDeclNode34])
private def coreBootstrapCandidateDeclNode459 : PsExpr := (.app coreBootstrapCandidateDeclNode458 (.bvar 1))
private def coreBootstrapCandidateDeclNode460 : PsExpr := (.app coreBootstrapCandidateDeclNode458 (.bvar 2))
private def coreBootstrapCandidateDeclNode461 : PsExpr := (.forallE coreBootstrapCandidateDeclNode457 coreBootstrapCandidateDeclNode459 coreBootstrapCandidateDeclNode460 .explicit)
private def coreBootstrapCandidateDeclNode462 : PsExpr := (.forallE coreBootstrapCandidateDeclNode456 (.bvar 0) coreBootstrapCandidateDeclNode461 .explicit)
private def coreBootstrapCandidateDeclNode463 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode36 coreBootstrapCandidateDeclNode462 .implicit)
private def coreBootstrapCandidateDeclNode464 : PsExpr := (.app coreBootstrapCandidateDeclNode458 (.bvar 0))
private def coreBootstrapCandidateDeclNode465 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode36 coreBootstrapCandidateDeclNode464 .implicit)
private def coreBootstrapCandidateDeclNode466 : PsName := (.str coreBootstrapCandidateDeclNode59 "rec")
private def coreBootstrapCandidateDeclNode467 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode464 coreBootstrapCandidateDeclNode21 .explicit)
private def coreBootstrapCandidateDeclNode468 : PsName := (.str .anonymous "nil")
private def coreBootstrapCandidateDeclNode469 : PsExpr := (.constE coreBootstrapCandidateDeclNode61 [coreBootstrapCandidateDeclNode34])
private def coreBootstrapCandidateDeclNode470 : PsExpr := (.app coreBootstrapCandidateDeclNode469 (.bvar 1))
private def coreBootstrapCandidateDeclNode471 : PsExpr := (.app (.bvar 0) coreBootstrapCandidateDeclNode470)
private def coreBootstrapCandidateDeclNode472 : PsName := (.str .anonymous "cons")
private def coreBootstrapCandidateDeclNode473 : PsExpr := (.app coreBootstrapCandidateDeclNode458 (.bvar 3))
private def coreBootstrapCandidateDeclNode474 : PsName := (.str .anonymous "tail_ih")
private def coreBootstrapCandidateDeclNode475 : PsExpr := (.constE coreBootstrapCandidateDeclNode62 [coreBootstrapCandidateDeclNode34])
private def coreBootstrapCandidateDeclNode476 : PsExpr := (.app coreBootstrapCandidateDeclNode475 (.bvar 5))
private def coreBootstrapCandidateDeclNode477 : PsExpr := (.app coreBootstrapCandidateDeclNode476 (.bvar 2))
private def coreBootstrapCandidateDeclNode478 : PsExpr := (.app coreBootstrapCandidateDeclNode477 (.bvar 1))
private def coreBootstrapCandidateDeclNode479 : PsExpr := (.app (.bvar 4) coreBootstrapCandidateDeclNode478)
private def coreBootstrapCandidateDeclNode480 : PsExpr := (.forallE coreBootstrapCandidateDeclNode474 coreBootstrapCandidateDeclNode281 coreBootstrapCandidateDeclNode479 .explicit)
private def coreBootstrapCandidateDeclNode481 : PsExpr := (.forallE coreBootstrapCandidateDeclNode457 coreBootstrapCandidateDeclNode473 coreBootstrapCandidateDeclNode480 .explicit)
private def coreBootstrapCandidateDeclNode482 : PsExpr := (.forallE coreBootstrapCandidateDeclNode456 (.bvar 2) coreBootstrapCandidateDeclNode481 .explicit)
private def coreBootstrapCandidateDeclNode483 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode473 coreBootstrapCandidateDeclNode281 .explicit)
private def coreBootstrapCandidateDeclNode484 : PsExpr := (.forallE coreBootstrapCandidateDeclNode472 coreBootstrapCandidateDeclNode482 coreBootstrapCandidateDeclNode483 .explicit)
private def coreBootstrapCandidateDeclNode485 : PsExpr := (.forallE coreBootstrapCandidateDeclNode468 coreBootstrapCandidateDeclNode471 coreBootstrapCandidateDeclNode484 .explicit)
private def coreBootstrapCandidateDeclNode486 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode467 coreBootstrapCandidateDeclNode485 .implicit)
private def coreBootstrapCandidateDeclNode487 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode36 coreBootstrapCandidateDeclNode486 .implicit)
private def coreBootstrapCandidateDeclNode488 : PsName := (.str coreBootstrapCandidateDeclNode63 "rec")
private def coreBootstrapCandidateDeclNode489 : PsExpr := (.constE coreBootstrapCandidateDeclNode63 [])
private def coreBootstrapCandidateDeclNode490 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode489 coreBootstrapCandidateDeclNode47 .explicit)
private def coreBootstrapCandidateDeclNode491 : PsName := (.str .anonymous "zero")
private def coreBootstrapCandidateDeclNode492 : PsExpr := (.constE coreBootstrapCandidateDeclNode64 [])
private def coreBootstrapCandidateDeclNode493 : PsExpr := (.app (.bvar 0) coreBootstrapCandidateDeclNode492)
private def coreBootstrapCandidateDeclNode494 : PsName := (.str .anonymous "succ")
private def coreBootstrapCandidateDeclNode495 : PsName := (.str .anonymous "n")
private def coreBootstrapCandidateDeclNode496 : PsName := (.str .anonymous "n_ih")
private def coreBootstrapCandidateDeclNode497 : PsExpr := (.constE coreBootstrapCandidateDeclNode65 [])
private def coreBootstrapCandidateDeclNode498 : PsExpr := (.app coreBootstrapCandidateDeclNode497 (.bvar 1))
private def coreBootstrapCandidateDeclNode499 : PsExpr := (.app (.bvar 3) coreBootstrapCandidateDeclNode498)
private def coreBootstrapCandidateDeclNode500 : PsExpr := (.forallE coreBootstrapCandidateDeclNode496 coreBootstrapCandidateDeclNode216 coreBootstrapCandidateDeclNode499 .explicit)
private def coreBootstrapCandidateDeclNode501 : PsExpr := (.forallE coreBootstrapCandidateDeclNode495 coreBootstrapCandidateDeclNode489 coreBootstrapCandidateDeclNode500 .explicit)
private def coreBootstrapCandidateDeclNode502 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode489 coreBootstrapCandidateDeclNode281 .explicit)
private def coreBootstrapCandidateDeclNode503 : PsExpr := (.forallE coreBootstrapCandidateDeclNode494 coreBootstrapCandidateDeclNode501 coreBootstrapCandidateDeclNode502 .explicit)
private def coreBootstrapCandidateDeclNode504 : PsExpr := (.forallE coreBootstrapCandidateDeclNode491 coreBootstrapCandidateDeclNode493 coreBootstrapCandidateDeclNode503 .explicit)
private def coreBootstrapCandidateDeclNode505 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode490 coreBootstrapCandidateDeclNode504 .implicit)
private def coreBootstrapCandidateDeclNode506 : PsExpr := (.forallE coreBootstrapCandidateDeclNode495 coreBootstrapCandidateDeclNode489 coreBootstrapCandidateDeclNode489 .explicit)
private def coreBootstrapCandidateDeclNode507 : PsName := (.str .anonymous "val")
private def coreBootstrapCandidateDeclNode508 : PsExpr := (.constE coreBootstrapCandidateDeclNode66 [coreBootstrapCandidateDeclNode34])
private def coreBootstrapCandidateDeclNode509 : PsExpr := (.app coreBootstrapCandidateDeclNode508 (.bvar 1))
private def coreBootstrapCandidateDeclNode510 : PsExpr := (.forallE coreBootstrapCandidateDeclNode507 (.bvar 0) coreBootstrapCandidateDeclNode509 .explicit)
private def coreBootstrapCandidateDeclNode511 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode510 .implicit)
private def coreBootstrapCandidateDeclNode512 : PsName := (.str coreBootstrapCandidateDeclNode66 "rec")
private def coreBootstrapCandidateDeclNode513 : PsExpr := (.app coreBootstrapCandidateDeclNode508 (.bvar 0))
private def coreBootstrapCandidateDeclNode514 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode513 coreBootstrapCandidateDeclNode2 .explicit)
private def coreBootstrapCandidateDeclNode515 : PsExpr := (.constE coreBootstrapCandidateDeclNode68 [coreBootstrapCandidateDeclNode34])
private def coreBootstrapCandidateDeclNode516 : PsExpr := (.app coreBootstrapCandidateDeclNode515 (.bvar 2))
private def coreBootstrapCandidateDeclNode517 : PsExpr := (.app coreBootstrapCandidateDeclNode516 (.bvar 0))
private def coreBootstrapCandidateDeclNode518 : PsExpr := (.app (.bvar 1) coreBootstrapCandidateDeclNode517)
private def coreBootstrapCandidateDeclNode519 : PsExpr := (.forallE coreBootstrapCandidateDeclNode507 (.bvar 1) coreBootstrapCandidateDeclNode518 .explicit)
private def coreBootstrapCandidateDeclNode520 : PsExpr := (.app coreBootstrapCandidateDeclNode508 (.bvar 2))
private def coreBootstrapCandidateDeclNode521 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode520 coreBootstrapCandidateDeclNode216 .explicit)
private def coreBootstrapCandidateDeclNode522 : PsExpr := (.forallE coreBootstrapCandidateDeclNode207 coreBootstrapCandidateDeclNode519 coreBootstrapCandidateDeclNode521 .explicit)
private def coreBootstrapCandidateDeclNode523 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode514 coreBootstrapCandidateDeclNode522 .implicit)
private def coreBootstrapCandidateDeclNode524 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode523 .implicit)
private def coreBootstrapCandidateDeclNode525 : PsExpr := (.constE coreBootstrapCandidateDeclNode74 [coreBootstrapCandidateDeclNode34])
private def coreBootstrapCandidateDeclNode526 : PsExpr := (.app coreBootstrapCandidateDeclNode525 (.bvar 0))
private def coreBootstrapCandidateDeclNode527 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode36 coreBootstrapCandidateDeclNode526 .implicit)
private def coreBootstrapCandidateDeclNode528 : PsName := (.str coreBootstrapCandidateDeclNode74 "rec")
private def coreBootstrapCandidateDeclNode529 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode526 coreBootstrapCandidateDeclNode21 .explicit)
private def coreBootstrapCandidateDeclNode530 : PsName := (.str .anonymous "none")
private def coreBootstrapCandidateDeclNode531 : PsExpr := (.constE coreBootstrapCandidateDeclNode75 [coreBootstrapCandidateDeclNode34])
private def coreBootstrapCandidateDeclNode532 : PsExpr := (.app coreBootstrapCandidateDeclNode531 (.bvar 1))
private def coreBootstrapCandidateDeclNode533 : PsExpr := (.app (.bvar 0) coreBootstrapCandidateDeclNode532)
private def coreBootstrapCandidateDeclNode534 : PsName := (.str .anonymous "some")
private def coreBootstrapCandidateDeclNode535 : PsExpr := (.constE coreBootstrapCandidateDeclNode76 [coreBootstrapCandidateDeclNode34])
private def coreBootstrapCandidateDeclNode536 : PsExpr := (.app coreBootstrapCandidateDeclNode535 (.bvar 3))
private def coreBootstrapCandidateDeclNode537 : PsExpr := (.app coreBootstrapCandidateDeclNode536 (.bvar 0))
private def coreBootstrapCandidateDeclNode538 : PsExpr := (.app (.bvar 2) coreBootstrapCandidateDeclNode537)
private def coreBootstrapCandidateDeclNode539 : PsExpr := (.forallE coreBootstrapCandidateDeclNode507 (.bvar 2) coreBootstrapCandidateDeclNode538 .explicit)
private def coreBootstrapCandidateDeclNode540 : PsExpr := (.app coreBootstrapCandidateDeclNode525 (.bvar 3))
private def coreBootstrapCandidateDeclNode541 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode540 coreBootstrapCandidateDeclNode281 .explicit)
private def coreBootstrapCandidateDeclNode542 : PsExpr := (.forallE coreBootstrapCandidateDeclNode534 coreBootstrapCandidateDeclNode539 coreBootstrapCandidateDeclNode541 .explicit)
private def coreBootstrapCandidateDeclNode543 : PsExpr := (.forallE coreBootstrapCandidateDeclNode530 coreBootstrapCandidateDeclNode533 coreBootstrapCandidateDeclNode542 .explicit)
private def coreBootstrapCandidateDeclNode544 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode529 coreBootstrapCandidateDeclNode543 .implicit)
private def coreBootstrapCandidateDeclNode545 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode36 coreBootstrapCandidateDeclNode544 .implicit)
private def coreBootstrapCandidateDeclNode546 : PsExpr := (.app coreBootstrapCandidateDeclNode525 (.bvar 1))
private def coreBootstrapCandidateDeclNode547 : PsExpr := (.forallE coreBootstrapCandidateDeclNode507 (.bvar 0) coreBootstrapCandidateDeclNode546 .explicit)
private def coreBootstrapCandidateDeclNode548 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode36 coreBootstrapCandidateDeclNode547 .implicit)
private def coreBootstrapCandidateDeclNode549 : PsExpr := (.constE coreBootstrapCandidateDeclNode77 [])
private def coreBootstrapCandidateDeclNode550 : PsExpr := (.app coreBootstrapCandidateDeclNode549 (.bvar 2))
private def coreBootstrapCandidateDeclNode551 : PsExpr := (.app coreBootstrapCandidateDeclNode550 (.bvar 1))
private def coreBootstrapCandidateDeclNode552 : PsExpr := (.forallE coreBootstrapCandidateDeclNode104 (.bvar 1) coreBootstrapCandidateDeclNode551 .explicit)
private def coreBootstrapCandidateDeclNode553 : PsExpr := (.forallE coreBootstrapCandidateDeclNode3 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode552 .implicit)
private def coreBootstrapCandidateDeclNode554 : PsExpr := (.forallE coreBootstrapCandidateDeclNode1 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode553 .implicit)
private def coreBootstrapCandidateDeclNode555 : PsExpr := (.forallE coreBootstrapCandidateDeclNode104 (.bvar 0) coreBootstrapCandidateDeclNode551 .explicit)
private def coreBootstrapCandidateDeclNode556 : PsExpr := (.forallE coreBootstrapCandidateDeclNode3 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode555 .implicit)
private def coreBootstrapCandidateDeclNode557 : PsExpr := (.forallE coreBootstrapCandidateDeclNode1 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode556 .implicit)
private def coreBootstrapCandidateDeclNode558 : PsName := (.str coreBootstrapCandidateDeclNode77 "rec")
private def coreBootstrapCandidateDeclNode559 : PsExpr := (.app coreBootstrapCandidateDeclNode549 (.bvar 1))
private def coreBootstrapCandidateDeclNode560 : PsExpr := (.app coreBootstrapCandidateDeclNode559 (.bvar 0))
private def coreBootstrapCandidateDeclNode561 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode560 coreBootstrapCandidateDeclNode2 .explicit)
private def coreBootstrapCandidateDeclNode562 : PsName := (.str .anonymous "inl")
private def coreBootstrapCandidateDeclNode563 : PsExpr := (.constE coreBootstrapCandidateDeclNode78 [])
private def coreBootstrapCandidateDeclNode564 : PsExpr := (.app coreBootstrapCandidateDeclNode563 (.bvar 3))
private def coreBootstrapCandidateDeclNode565 : PsExpr := (.app coreBootstrapCandidateDeclNode564 (.bvar 2))
private def coreBootstrapCandidateDeclNode566 : PsExpr := (.app coreBootstrapCandidateDeclNode565 (.bvar 0))
private def coreBootstrapCandidateDeclNode567 : PsExpr := (.app (.bvar 1) coreBootstrapCandidateDeclNode566)
private def coreBootstrapCandidateDeclNode568 : PsExpr := (.forallE coreBootstrapCandidateDeclNode104 (.bvar 2) coreBootstrapCandidateDeclNode567 .explicit)
private def coreBootstrapCandidateDeclNode569 : PsName := (.str .anonymous "inr")
private def coreBootstrapCandidateDeclNode570 : PsExpr := (.constE coreBootstrapCandidateDeclNode79 [])
private def coreBootstrapCandidateDeclNode571 : PsExpr := (.app coreBootstrapCandidateDeclNode570 (.bvar 4))
private def coreBootstrapCandidateDeclNode572 : PsExpr := (.app coreBootstrapCandidateDeclNode571 (.bvar 3))
private def coreBootstrapCandidateDeclNode573 : PsExpr := (.app coreBootstrapCandidateDeclNode572 (.bvar 0))
private def coreBootstrapCandidateDeclNode574 : PsExpr := (.app (.bvar 2) coreBootstrapCandidateDeclNode573)
private def coreBootstrapCandidateDeclNode575 : PsExpr := (.forallE coreBootstrapCandidateDeclNode104 (.bvar 2) coreBootstrapCandidateDeclNode574 .explicit)
private def coreBootstrapCandidateDeclNode576 : PsExpr := (.app coreBootstrapCandidateDeclNode549 (.bvar 4))
private def coreBootstrapCandidateDeclNode577 : PsExpr := (.app coreBootstrapCandidateDeclNode576 (.bvar 3))
private def coreBootstrapCandidateDeclNode578 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode577 coreBootstrapCandidateDeclNode281 .explicit)
private def coreBootstrapCandidateDeclNode579 : PsExpr := (.forallE coreBootstrapCandidateDeclNode569 coreBootstrapCandidateDeclNode575 coreBootstrapCandidateDeclNode578 .explicit)
private def coreBootstrapCandidateDeclNode580 : PsExpr := (.forallE coreBootstrapCandidateDeclNode562 coreBootstrapCandidateDeclNode568 coreBootstrapCandidateDeclNode579 .explicit)
private def coreBootstrapCandidateDeclNode581 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode561 coreBootstrapCandidateDeclNode580 .implicit)
private def coreBootstrapCandidateDeclNode582 : PsExpr := (.forallE coreBootstrapCandidateDeclNode3 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode581 .implicit)
private def coreBootstrapCandidateDeclNode583 : PsExpr := (.forallE coreBootstrapCandidateDeclNode1 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode582 .implicit)
private def coreBootstrapCandidateDeclNode584 : PsName := (.str coreBootstrapCandidateDeclNode80 "rec")
private def coreBootstrapCandidateDeclNode585 : PsExpr := (.constE coreBootstrapCandidateDeclNode80 [coreBootstrapCandidateDeclNode34])
private def coreBootstrapCandidateDeclNode586 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode585 coreBootstrapCandidateDeclNode21 .explicit)
private def coreBootstrapCandidateDeclNode587 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode585 coreBootstrapCandidateDeclNode325 .explicit)
private def coreBootstrapCandidateDeclNode588 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode586 coreBootstrapCandidateDeclNode587 .explicit)
private def coreBootstrapCandidateDeclNode589 : PsName := (.str .anonymous "fst")
private def coreBootstrapCandidateDeclNode590 : PsName := (.str .anonymous "snd")
private def coreBootstrapCandidateDeclNode591 : PsExpr := (.constE coreBootstrapCandidateDeclNode81 [coreBootstrapCandidateDeclNode34, coreBootstrapCandidateDeclNode37])
private def coreBootstrapCandidateDeclNode592 : PsExpr := (.app coreBootstrapCandidateDeclNode591 (.bvar 3))
private def coreBootstrapCandidateDeclNode593 : PsExpr := (.app coreBootstrapCandidateDeclNode592 (.bvar 2))
private def coreBootstrapCandidateDeclNode594 : PsExpr := (.forallE coreBootstrapCandidateDeclNode590 (.bvar 1) coreBootstrapCandidateDeclNode593 .explicit)
private def coreBootstrapCandidateDeclNode595 : PsExpr := (.forallE coreBootstrapCandidateDeclNode589 (.bvar 1) coreBootstrapCandidateDeclNode594 .explicit)
private def coreBootstrapCandidateDeclNode596 : PsExpr := (.forallE coreBootstrapCandidateDeclNode54 coreBootstrapCandidateDeclNode82 coreBootstrapCandidateDeclNode595 .implicit)
private def coreBootstrapCandidateDeclNode597 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode596 .implicit)
private def coreBootstrapCandidateDeclNode598 : PsName := (.str coreBootstrapCandidateDeclNode81 "rec")
private def coreBootstrapCandidateDeclNode599 : PsExpr := (.app coreBootstrapCandidateDeclNode591 (.bvar 1))
private def coreBootstrapCandidateDeclNode600 : PsExpr := (.app coreBootstrapCandidateDeclNode599 (.bvar 0))
private def coreBootstrapCandidateDeclNode601 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode600 coreBootstrapCandidateDeclNode21 .explicit)
private def coreBootstrapCandidateDeclNode602 : PsName := (.str .anonymous "mk")
private def coreBootstrapCandidateDeclNode603 : PsExpr := (.constE coreBootstrapCandidateDeclNode88 [coreBootstrapCandidateDeclNode34, coreBootstrapCandidateDeclNode37])
private def coreBootstrapCandidateDeclNode604 : PsExpr := (.app coreBootstrapCandidateDeclNode603 (.bvar 4))
private def coreBootstrapCandidateDeclNode605 : PsExpr := (.app coreBootstrapCandidateDeclNode604 (.bvar 3))
private def coreBootstrapCandidateDeclNode606 : PsExpr := (.app coreBootstrapCandidateDeclNode605 (.bvar 1))
private def coreBootstrapCandidateDeclNode607 : PsExpr := (.app coreBootstrapCandidateDeclNode606 (.bvar 0))
private def coreBootstrapCandidateDeclNode608 : PsExpr := (.app (.bvar 2) coreBootstrapCandidateDeclNode607)
private def coreBootstrapCandidateDeclNode609 : PsExpr := (.forallE coreBootstrapCandidateDeclNode590 (.bvar 2) coreBootstrapCandidateDeclNode608 .explicit)
private def coreBootstrapCandidateDeclNode610 : PsExpr := (.forallE coreBootstrapCandidateDeclNode589 (.bvar 2) coreBootstrapCandidateDeclNode609 .explicit)
private def coreBootstrapCandidateDeclNode611 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode593 coreBootstrapCandidateDeclNode216 .explicit)
private def coreBootstrapCandidateDeclNode612 : PsExpr := (.forallE coreBootstrapCandidateDeclNode602 coreBootstrapCandidateDeclNode610 coreBootstrapCandidateDeclNode611 .explicit)
private def coreBootstrapCandidateDeclNode613 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode601 coreBootstrapCandidateDeclNode612 .implicit)
private def coreBootstrapCandidateDeclNode614 : PsExpr := (.forallE coreBootstrapCandidateDeclNode54 coreBootstrapCandidateDeclNode82 coreBootstrapCandidateDeclNode613 .implicit)
private def coreBootstrapCandidateDeclNode615 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode47 coreBootstrapCandidateDeclNode614 .implicit)
private def coreBootstrapCandidateDeclNode616 : PsName := (.str coreBootstrapCandidateDeclNode89 "rec")
private def coreBootstrapCandidateDeclNode617 : PsExpr := (.constE coreBootstrapCandidateDeclNode89 [coreBootstrapCandidateDeclNode34])
private def coreBootstrapCandidateDeclNode618 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode617 coreBootstrapCandidateDeclNode21 .explicit)
private def coreBootstrapCandidateDeclNode619 : PsName := (.str .anonymous "unit")
private def coreBootstrapCandidateDeclNode620 : PsExpr := (.constE coreBootstrapCandidateDeclNode90 [coreBootstrapCandidateDeclNode34])
private def coreBootstrapCandidateDeclNode621 : PsExpr := (.app (.bvar 0) coreBootstrapCandidateDeclNode620)
private def coreBootstrapCandidateDeclNode622 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode617 coreBootstrapCandidateDeclNode216 .explicit)
private def coreBootstrapCandidateDeclNode623 : PsExpr := (.forallE coreBootstrapCandidateDeclNode619 coreBootstrapCandidateDeclNode621 coreBootstrapCandidateDeclNode622 .explicit)
private def coreBootstrapCandidateDeclNode624 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode618 coreBootstrapCandidateDeclNode623 .implicit)
private def coreBootstrapCandidateDeclNode625 : PsExpr := (.constE coreBootstrapCandidateDeclNode91 [coreBootstrapCandidateDeclNode34, coreBootstrapCandidateDeclNode37])
private def coreBootstrapCandidateDeclNode626 : PsExpr := (.app coreBootstrapCandidateDeclNode625 (.bvar 3))
private def coreBootstrapCandidateDeclNode627 : PsExpr := (.app coreBootstrapCandidateDeclNode626 (.bvar 2))
private def coreBootstrapCandidateDeclNode628 : PsExpr := (.forallE coreBootstrapCandidateDeclNode590 (.bvar 1) coreBootstrapCandidateDeclNode627 .explicit)
private def coreBootstrapCandidateDeclNode629 : PsExpr := (.forallE coreBootstrapCandidateDeclNode589 (.bvar 1) coreBootstrapCandidateDeclNode628 .explicit)
private def coreBootstrapCandidateDeclNode630 : PsExpr := (.forallE coreBootstrapCandidateDeclNode54 coreBootstrapCandidateDeclNode39 coreBootstrapCandidateDeclNode629 .implicit)
private def coreBootstrapCandidateDeclNode631 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode36 coreBootstrapCandidateDeclNode630 .implicit)
private def coreBootstrapCandidateDeclNode632 : PsName := (.str coreBootstrapCandidateDeclNode91 "rec")
private def coreBootstrapCandidateDeclNode633 : PsExpr := (.app coreBootstrapCandidateDeclNode625 (.bvar 1))
private def coreBootstrapCandidateDeclNode634 : PsExpr := (.app coreBootstrapCandidateDeclNode633 (.bvar 0))
private def coreBootstrapCandidateDeclNode635 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode634 coreBootstrapCandidateDeclNode21 .explicit)
private def coreBootstrapCandidateDeclNode636 : PsExpr := (.constE coreBootstrapCandidateDeclNode94 [coreBootstrapCandidateDeclNode34, coreBootstrapCandidateDeclNode37])
private def coreBootstrapCandidateDeclNode637 : PsExpr := (.app coreBootstrapCandidateDeclNode636 (.bvar 4))
private def coreBootstrapCandidateDeclNode638 : PsExpr := (.app coreBootstrapCandidateDeclNode637 (.bvar 3))
private def coreBootstrapCandidateDeclNode639 : PsExpr := (.app coreBootstrapCandidateDeclNode638 (.bvar 1))
private def coreBootstrapCandidateDeclNode640 : PsExpr := (.app coreBootstrapCandidateDeclNode639 (.bvar 0))
private def coreBootstrapCandidateDeclNode641 : PsExpr := (.app (.bvar 2) coreBootstrapCandidateDeclNode640)
private def coreBootstrapCandidateDeclNode642 : PsExpr := (.forallE coreBootstrapCandidateDeclNode590 (.bvar 2) coreBootstrapCandidateDeclNode641 .explicit)
private def coreBootstrapCandidateDeclNode643 : PsExpr := (.forallE coreBootstrapCandidateDeclNode589 (.bvar 2) coreBootstrapCandidateDeclNode642 .explicit)
private def coreBootstrapCandidateDeclNode644 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode627 coreBootstrapCandidateDeclNode216 .explicit)
private def coreBootstrapCandidateDeclNode645 : PsExpr := (.forallE coreBootstrapCandidateDeclNode602 coreBootstrapCandidateDeclNode643 coreBootstrapCandidateDeclNode644 .explicit)
private def coreBootstrapCandidateDeclNode646 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode635 coreBootstrapCandidateDeclNode645 .implicit)
private def coreBootstrapCandidateDeclNode647 : PsExpr := (.forallE coreBootstrapCandidateDeclNode54 coreBootstrapCandidateDeclNode39 coreBootstrapCandidateDeclNode646 .implicit)
private def coreBootstrapCandidateDeclNode648 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode36 coreBootstrapCandidateDeclNode647 .implicit)
private def coreBootstrapCandidateDeclNode649 : PsExpr := (.constE coreBootstrapCandidateDeclNode95 [coreBootstrapCandidateDeclNode34, coreBootstrapCandidateDeclNode37])
private def coreBootstrapCandidateDeclNode650 : PsExpr := (.app coreBootstrapCandidateDeclNode649 (.bvar 2))
private def coreBootstrapCandidateDeclNode651 : PsExpr := (.app coreBootstrapCandidateDeclNode650 (.bvar 1))
private def coreBootstrapCandidateDeclNode652 : PsExpr := (.forallE coreBootstrapCandidateDeclNode507 (.bvar 1) coreBootstrapCandidateDeclNode651 .explicit)
private def coreBootstrapCandidateDeclNode653 : PsExpr := (.forallE coreBootstrapCandidateDeclNode54 coreBootstrapCandidateDeclNode39 coreBootstrapCandidateDeclNode652 .implicit)
private def coreBootstrapCandidateDeclNode654 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode36 coreBootstrapCandidateDeclNode653 .implicit)
private def coreBootstrapCandidateDeclNode655 : PsExpr := (.forallE coreBootstrapCandidateDeclNode507 (.bvar 0) coreBootstrapCandidateDeclNode651 .explicit)
private def coreBootstrapCandidateDeclNode656 : PsExpr := (.forallE coreBootstrapCandidateDeclNode54 coreBootstrapCandidateDeclNode39 coreBootstrapCandidateDeclNode655 .implicit)
private def coreBootstrapCandidateDeclNode657 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode36 coreBootstrapCandidateDeclNode656 .implicit)
private def coreBootstrapCandidateDeclNode658 : PsName := (.str coreBootstrapCandidateDeclNode95 "rec")
private def coreBootstrapCandidateDeclNode659 : PsExpr := (.app coreBootstrapCandidateDeclNode649 (.bvar 1))
private def coreBootstrapCandidateDeclNode660 : PsExpr := (.app coreBootstrapCandidateDeclNode659 (.bvar 0))
private def coreBootstrapCandidateDeclNode661 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode660 coreBootstrapCandidateDeclNode21 .explicit)
private def coreBootstrapCandidateDeclNode662 : PsExpr := (.constE coreBootstrapCandidateDeclNode96 [coreBootstrapCandidateDeclNode34, coreBootstrapCandidateDeclNode37])
private def coreBootstrapCandidateDeclNode663 : PsExpr := (.app coreBootstrapCandidateDeclNode662 (.bvar 3))
private def coreBootstrapCandidateDeclNode664 : PsExpr := (.app coreBootstrapCandidateDeclNode663 (.bvar 2))
private def coreBootstrapCandidateDeclNode665 : PsExpr := (.app coreBootstrapCandidateDeclNode664 (.bvar 0))
private def coreBootstrapCandidateDeclNode666 : PsExpr := (.app (.bvar 1) coreBootstrapCandidateDeclNode665)
private def coreBootstrapCandidateDeclNode667 : PsExpr := (.forallE coreBootstrapCandidateDeclNode507 (.bvar 2) coreBootstrapCandidateDeclNode666 .explicit)
private def coreBootstrapCandidateDeclNode668 : PsExpr := (.constE coreBootstrapCandidateDeclNode97 [coreBootstrapCandidateDeclNode34, coreBootstrapCandidateDeclNode37])
private def coreBootstrapCandidateDeclNode669 : PsExpr := (.app coreBootstrapCandidateDeclNode668 (.bvar 4))
private def coreBootstrapCandidateDeclNode670 : PsExpr := (.app coreBootstrapCandidateDeclNode669 (.bvar 3))
private def coreBootstrapCandidateDeclNode671 : PsExpr := (.app coreBootstrapCandidateDeclNode670 (.bvar 0))
private def coreBootstrapCandidateDeclNode672 : PsExpr := (.app (.bvar 2) coreBootstrapCandidateDeclNode671)
private def coreBootstrapCandidateDeclNode673 : PsExpr := (.forallE coreBootstrapCandidateDeclNode507 (.bvar 2) coreBootstrapCandidateDeclNode672 .explicit)
private def coreBootstrapCandidateDeclNode674 : PsExpr := (.app coreBootstrapCandidateDeclNode649 (.bvar 4))
private def coreBootstrapCandidateDeclNode675 : PsExpr := (.app coreBootstrapCandidateDeclNode674 (.bvar 3))
private def coreBootstrapCandidateDeclNode676 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode675 coreBootstrapCandidateDeclNode281 .explicit)
private def coreBootstrapCandidateDeclNode677 : PsExpr := (.forallE coreBootstrapCandidateDeclNode569 coreBootstrapCandidateDeclNode673 coreBootstrapCandidateDeclNode676 .explicit)
private def coreBootstrapCandidateDeclNode678 : PsExpr := (.forallE coreBootstrapCandidateDeclNode562 coreBootstrapCandidateDeclNode667 coreBootstrapCandidateDeclNode677 .explicit)
private def coreBootstrapCandidateDeclNode679 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode661 coreBootstrapCandidateDeclNode678 .implicit)
private def coreBootstrapCandidateDeclNode680 : PsExpr := (.forallE coreBootstrapCandidateDeclNode54 coreBootstrapCandidateDeclNode39 coreBootstrapCandidateDeclNode679 .implicit)
private def coreBootstrapCandidateDeclNode681 : PsExpr := (.forallE coreBootstrapCandidateDeclNode19 coreBootstrapCandidateDeclNode36 coreBootstrapCandidateDeclNode680 .implicit)
private def coreBootstrapCandidateDeclNode682 : PsExpr := (.constE coreBootstrapCandidateDeclNode98 [])
private def coreBootstrapCandidateDeclNode683 : PsName := (.str coreBootstrapCandidateDeclNode98 "rec")
private def coreBootstrapCandidateDeclNode684 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode682 coreBootstrapCandidateDeclNode47 .explicit)
private def coreBootstrapCandidateDeclNode685 : PsExpr := (.constE coreBootstrapCandidateDeclNode99 [])
private def coreBootstrapCandidateDeclNode686 : PsExpr := (.app (.bvar 0) coreBootstrapCandidateDeclNode685)
private def coreBootstrapCandidateDeclNode687 : PsExpr := (.forallE coreBootstrapCandidateDeclNode107 coreBootstrapCandidateDeclNode682 coreBootstrapCandidateDeclNode216 .explicit)
private def coreBootstrapCandidateDeclNode688 : PsExpr := (.forallE coreBootstrapCandidateDeclNode207 coreBootstrapCandidateDeclNode686 coreBootstrapCandidateDeclNode687 .explicit)
private def coreBootstrapCandidateDeclNode689 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode684 coreBootstrapCandidateDeclNode688 .implicit)
private def coreBootstrapCandidateDeclNode690 : PsExpr := (.forallE coreBootstrapCandidateDeclNode244 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode21 .explicit)
private def coreBootstrapCandidateDeclNode691 : PsExpr := (.forallE coreBootstrapCandidateDeclNode237 coreBootstrapCandidateDeclNode128 coreBootstrapCandidateDeclNode690 .explicit)
private def coreBootstrapCandidateDeclNode692 : PsName := (.str .anonymous "h_1")
private def coreBootstrapCandidateDeclNode693 : PsExpr := (.app (.bvar 3) coreBootstrapCandidateDeclNode259)
private def coreBootstrapCandidateDeclNode694 : PsExpr := (.app coreBootstrapCandidateDeclNode693 (.bvar 0))
private def coreBootstrapCandidateDeclNode695 : PsExpr := (.forallE coreBootstrapCandidateDeclNode13 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode694 .explicit)
private def coreBootstrapCandidateDeclNode696 : PsName := (.str .anonymous "h_2")
private def coreBootstrapCandidateDeclNode697 : PsExpr := (.app (.bvar 4) coreBootstrapCandidateDeclNode262)
private def coreBootstrapCandidateDeclNode698 : PsExpr := (.app coreBootstrapCandidateDeclNode697 (.bvar 0))
private def coreBootstrapCandidateDeclNode699 : PsExpr := (.forallE coreBootstrapCandidateDeclNode13 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode698 .explicit)
private def coreBootstrapCandidateDeclNode700 : PsExpr := (.app (.bvar 4) (.bvar 3))
private def coreBootstrapCandidateDeclNode701 : PsExpr := (.app coreBootstrapCandidateDeclNode700 (.bvar 2))
private def coreBootstrapCandidateDeclNode702 : PsExpr := (.forallE coreBootstrapCandidateDeclNode696 coreBootstrapCandidateDeclNode699 coreBootstrapCandidateDeclNode701 .explicit)
private def coreBootstrapCandidateDeclNode703 : PsExpr := (.forallE coreBootstrapCandidateDeclNode692 coreBootstrapCandidateDeclNode695 coreBootstrapCandidateDeclNode702 .explicit)
private def coreBootstrapCandidateDeclNode704 : PsExpr := (.forallE coreBootstrapCandidateDeclNode244 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode703 .explicit)
private def coreBootstrapCandidateDeclNode705 : PsExpr := (.forallE coreBootstrapCandidateDeclNode237 coreBootstrapCandidateDeclNode128 coreBootstrapCandidateDeclNode704 .explicit)
private def coreBootstrapCandidateDeclNode706 : PsExpr := (.forallE coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode691 coreBootstrapCandidateDeclNode705 .explicit)
private def coreBootstrapCandidateDeclNode707 : PsExpr := (.constE coreBootstrapCandidateDeclNode118 [coreBootstrapCandidateDeclNode20])
private def coreBootstrapCandidateDeclNode708 : PsExpr := (.app (.bvar 5) (.bvar 0))
private def coreBootstrapCandidateDeclNode709 : PsExpr := (.app coreBootstrapCandidateDeclNode708 (.bvar 3))
private def coreBootstrapCandidateDeclNode710 : PsExpr := (.lam coreBootstrapCandidateDeclNode120 coreBootstrapCandidateDeclNode128 coreBootstrapCandidateDeclNode709 .explicit)
private def coreBootstrapCandidateDeclNode711 : PsExpr := (.app coreBootstrapCandidateDeclNode707 coreBootstrapCandidateDeclNode710)
private def coreBootstrapCandidateDeclNode712 : PsExpr := (.app coreBootstrapCandidateDeclNode711 (.bvar 3))
private def coreBootstrapCandidateDeclNode713 : PsExpr := (.app (.bvar 1) (.bvar 2))
private def coreBootstrapCandidateDeclNode714 : PsExpr := (.app coreBootstrapCandidateDeclNode712 coreBootstrapCandidateDeclNode713)
private def coreBootstrapCandidateDeclNode715 : PsExpr := (.app coreBootstrapCandidateDeclNode714 coreBootstrapCandidateDeclNode430)
private def coreBootstrapCandidateDeclNode716 : PsExpr := (.lam coreBootstrapCandidateDeclNode696 coreBootstrapCandidateDeclNode699 coreBootstrapCandidateDeclNode715 .explicit)
private def coreBootstrapCandidateDeclNode717 : PsExpr := (.lam coreBootstrapCandidateDeclNode692 coreBootstrapCandidateDeclNode695 coreBootstrapCandidateDeclNode716 .explicit)
private def coreBootstrapCandidateDeclNode718 : PsExpr := (.lam coreBootstrapCandidateDeclNode244 coreBootstrapCandidateDeclNode2 coreBootstrapCandidateDeclNode717 .explicit)
private def coreBootstrapCandidateDeclNode719 : PsExpr := (.lam coreBootstrapCandidateDeclNode237 coreBootstrapCandidateDeclNode128 coreBootstrapCandidateDeclNode718 .explicit)
private def coreBootstrapCandidateDeclNode720 : PsExpr := (.lam coreBootstrapCandidateDeclNode203 coreBootstrapCandidateDeclNode691 coreBootstrapCandidateDeclNode719 .explicit)

def psCoreBootstrapCandidateBoundary : List PsName :=
  []

-- And
private def coreBootstrapCandidateDecl0 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreBootstrapCandidateDeclNode0 [] coreBootstrapCandidateDeclNode5 2 0 [coreBootstrapCandidateDeclNode6] true)

-- Bool
private def coreBootstrapCandidateDecl1 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreBootstrapCandidateDeclNode7 [] coreBootstrapCandidateDeclNode9 0 0 [coreBootstrapCandidateDeclNode10, coreBootstrapCandidateDeclNode11] false)

-- Decidable
private def coreBootstrapCandidateDecl2 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreBootstrapCandidateDeclNode12 [] coreBootstrapCandidateDeclNode14 1 0 [coreBootstrapCandidateDeclNode15] true)

-- Empty
private def coreBootstrapCandidateDecl3 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreBootstrapCandidateDeclNode16 [] coreBootstrapCandidateDeclNode9 0 0 [] false)

-- Eq
private def coreBootstrapCandidateDecl4 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreBootstrapCandidateDeclNode17 [coreBootstrapCandidateDeclNode18] coreBootstrapCandidateDeclNode28 2 1 [coreBootstrapCandidateDeclNode29] false)

-- Except
private def coreBootstrapCandidateDecl5 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreBootstrapCandidateDeclNode30 [coreBootstrapCandidateDeclNode31, coreBootstrapCandidateDeclNode32] coreBootstrapCandidateDeclNode43 2 0 [coreBootstrapCandidateDeclNode44, coreBootstrapCandidateDeclNode45] false)

-- Exists
private def coreBootstrapCandidateDecl6 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreBootstrapCandidateDeclNode46 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode50 2 0 [coreBootstrapCandidateDeclNode51] false)

-- False
private def coreBootstrapCandidateDecl7 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreBootstrapCandidateDeclNode52 [] coreBootstrapCandidateDeclNode2 0 0 [] false)

-- HEq
private def coreBootstrapCandidateDecl8 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreBootstrapCandidateDeclNode53 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode57 2 2 [coreBootstrapCandidateDeclNode58] false)

-- List
private def coreBootstrapCandidateDecl9 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreBootstrapCandidateDeclNode59 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode60 1 0 [coreBootstrapCandidateDeclNode61, coreBootstrapCandidateDeclNode62] false)

-- Nat
private def coreBootstrapCandidateDecl10 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreBootstrapCandidateDeclNode63 [] coreBootstrapCandidateDeclNode9 0 0 [coreBootstrapCandidateDeclNode64, coreBootstrapCandidateDeclNode65] false)

-- Nonempty
private def coreBootstrapCandidateDecl11 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreBootstrapCandidateDeclNode66 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode67 1 0 [coreBootstrapCandidateDeclNode68] false)

-- Not
private def coreBootstrapCandidateDecl12 : PsDeclaration :=
  .definitionDecl coreBootstrapCandidateDeclNode69 [] coreBootstrapCandidateDeclNode70
    coreBootstrapCandidateDeclNode73

-- Option
private def coreBootstrapCandidateDecl13 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreBootstrapCandidateDeclNode74 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode60 1 0 [coreBootstrapCandidateDeclNode75, coreBootstrapCandidateDeclNode76] false)

-- Or
private def coreBootstrapCandidateDecl14 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreBootstrapCandidateDeclNode77 [] coreBootstrapCandidateDeclNode5 2 0 [coreBootstrapCandidateDeclNode78, coreBootstrapCandidateDeclNode79] false)

-- PEmpty
private def coreBootstrapCandidateDecl15 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreBootstrapCandidateDeclNode80 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode47 0 0 [] false)

-- PProd
private def coreBootstrapCandidateDecl16 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreBootstrapCandidateDeclNode81 [coreBootstrapCandidateDeclNode31, coreBootstrapCandidateDeclNode32] coreBootstrapCandidateDeclNode87 2 0 [coreBootstrapCandidateDeclNode88] true)

-- PUnit
private def coreBootstrapCandidateDecl17 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreBootstrapCandidateDeclNode89 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode47 0 0 [coreBootstrapCandidateDeclNode90] false)

-- Prod
private def coreBootstrapCandidateDecl18 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreBootstrapCandidateDeclNode91 [coreBootstrapCandidateDeclNode31, coreBootstrapCandidateDeclNode32] coreBootstrapCandidateDeclNode93 2 0 [coreBootstrapCandidateDeclNode94] true)

-- Sum
private def coreBootstrapCandidateDecl19 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreBootstrapCandidateDeclNode95 [coreBootstrapCandidateDeclNode31, coreBootstrapCandidateDeclNode32] coreBootstrapCandidateDeclNode93 2 0 [coreBootstrapCandidateDeclNode96, coreBootstrapCandidateDeclNode97] false)

-- True
private def coreBootstrapCandidateDecl20 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreBootstrapCandidateDeclNode98 [] coreBootstrapCandidateDeclNode2 0 0 [coreBootstrapCandidateDeclNode99] false)

-- Unit
private def coreBootstrapCandidateDecl21 : PsDeclaration :=
  .definitionDecl coreBootstrapCandidateDeclNode100 [] coreBootstrapCandidateDeclNode9
    coreBootstrapCandidateDeclNode101

-- dite
private def coreBootstrapCandidateDecl22 : PsDeclaration :=
  .definitionDecl coreBootstrapCandidateDeclNode102 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode117
    coreBootstrapCandidateDeclNode153

-- id
private def coreBootstrapCandidateDecl23 : PsDeclaration :=
  .definitionDecl coreBootstrapCandidateDeclNode154 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode156
    coreBootstrapCandidateDeclNode158

-- ite
private def coreBootstrapCandidateDecl24 : PsDeclaration :=
  .definitionDecl coreBootstrapCandidateDeclNode159 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode164
    coreBootstrapCandidateDeclNode183

-- optParam
private def coreBootstrapCandidateDecl25 : PsDeclaration :=
  .definitionDecl coreBootstrapCandidateDeclNode184 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode187
    coreBootstrapCandidateDeclNode189

-- outParam
private def coreBootstrapCandidateDecl26 : PsDeclaration :=
  .definitionDecl coreBootstrapCandidateDeclNode190 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode191
    coreBootstrapCandidateDeclNode192

-- And.intro
private def coreBootstrapCandidateDecl27 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode6 [] coreBootstrapCandidateDeclNode201 coreBootstrapCandidateDeclNode0 0 2 2 [])

-- And.rec
private def coreBootstrapCandidateDecl28 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreBootstrapCandidateDeclNode202 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode221 [coreBootstrapCandidateDeclNode0] 2 0 1 1)

-- Bool.Reflects
private def coreBootstrapCandidateDecl29 : PsDeclaration :=
  .definitionDecl coreBootstrapCandidateDeclNode130 [] coreBootstrapCandidateDeclNode223
    coreBootstrapCandidateDeclNode256

-- Bool.casesOn
private def coreBootstrapCandidateDecl30 : PsDeclaration :=
  .definitionDecl coreBootstrapCandidateDeclNode118 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode268
    coreBootstrapCandidateDeclNode278

-- Bool.false
private def coreBootstrapCandidateDecl31 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode10 [] coreBootstrapCandidateDeclNode128 coreBootstrapCandidateDeclNode7 0 0 0 [])

-- Bool.rec
private def coreBootstrapCandidateDecl32 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreBootstrapCandidateDeclNode269 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode285 [coreBootstrapCandidateDeclNode7] 0 0 1 2)

-- Bool.true
private def coreBootstrapCandidateDecl33 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode11 [] coreBootstrapCandidateDeclNode128 coreBootstrapCandidateDeclNode7 1 0 0 [])

-- Decidable.decide
private def coreBootstrapCandidateDecl34 : PsDeclaration :=
  .definitionDecl coreBootstrapCandidateDeclNode137 [] coreBootstrapCandidateDeclNode288
    coreBootstrapCandidateDeclNode291

-- Decidable.intro
private def coreBootstrapCandidateDecl35 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode15 [] coreBootstrapCandidateDeclNode298 coreBootstrapCandidateDeclNode12 0 1 2 [])

-- Decidable.rec
private def coreBootstrapCandidateDecl36 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreBootstrapCandidateDeclNode299 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode312 [coreBootstrapCandidateDeclNode12] 1 0 1 1)

-- Decidable.reflects_decide
private def coreBootstrapCandidateDecl37 : PsDeclaration :=
  .theoremDecl coreBootstrapCandidateDeclNode144 [] coreBootstrapCandidateDeclNode318
    coreBootstrapCandidateDeclNode321

-- Empty.rec
private def coreBootstrapCandidateDecl38 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreBootstrapCandidateDeclNode322 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode327 [coreBootstrapCandidateDeclNode16] 0 0 1 0)

-- Eq.rec
private def coreBootstrapCandidateDecl39 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreBootstrapCandidateDeclNode328 [coreBootstrapCandidateDeclNode31, coreBootstrapCandidateDeclNode18] coreBootstrapCandidateDeclNode351 [coreBootstrapCandidateDeclNode17] 2 1 1 1)

-- Eq.refl
private def coreBootstrapCandidateDecl40 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode29 [coreBootstrapCandidateDeclNode18] coreBootstrapCandidateDeclNode356 coreBootstrapCandidateDeclNode17 0 2 0 [])

-- Except.error
private def coreBootstrapCandidateDecl41 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode44 [coreBootstrapCandidateDeclNode31, coreBootstrapCandidateDeclNode32] coreBootstrapCandidateDeclNode362 coreBootstrapCandidateDeclNode30 0 2 1 [])

-- Except.ok
private def coreBootstrapCandidateDecl42 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode45 [coreBootstrapCandidateDeclNode31, coreBootstrapCandidateDeclNode32] coreBootstrapCandidateDeclNode365 coreBootstrapCandidateDeclNode30 1 2 1 [])

-- Except.rec
private def coreBootstrapCandidateDecl43 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreBootstrapCandidateDeclNode366 [coreBootstrapCandidateDeclNode18, coreBootstrapCandidateDeclNode31, coreBootstrapCandidateDeclNode32] coreBootstrapCandidateDeclNode391 [coreBootstrapCandidateDeclNode30] 2 0 1 2)

-- Exists.intro
private def coreBootstrapCandidateDecl44 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode51 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode399 coreBootstrapCandidateDeclNode46 0 2 2 [])

-- Exists.rec
private def coreBootstrapCandidateDecl45 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreBootstrapCandidateDeclNode400 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode416 [coreBootstrapCandidateDeclNode46] 2 0 1 1)

-- False.rec
private def coreBootstrapCandidateDecl46 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreBootstrapCandidateDeclNode417 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode420 [coreBootstrapCandidateDeclNode52] 0 0 1 0)

-- HEq.rec
private def coreBootstrapCandidateDecl47 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreBootstrapCandidateDeclNode421 [coreBootstrapCandidateDeclNode18, coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode449 [coreBootstrapCandidateDeclNode53] 2 2 1 1)

-- HEq.refl
private def coreBootstrapCandidateDecl48 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode58 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode455 coreBootstrapCandidateDeclNode53 0 2 0 [])

-- List.cons
private def coreBootstrapCandidateDecl49 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode62 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode463 coreBootstrapCandidateDeclNode59 1 1 2 [1])

-- List.nil
private def coreBootstrapCandidateDecl50 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode61 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode465 coreBootstrapCandidateDeclNode59 0 1 0 [])

-- List.rec
private def coreBootstrapCandidateDecl51 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreBootstrapCandidateDeclNode466 [coreBootstrapCandidateDeclNode18, coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode487 [coreBootstrapCandidateDeclNode59] 1 0 1 2)

-- Nat.rec
private def coreBootstrapCandidateDecl52 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreBootstrapCandidateDeclNode488 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode505 [coreBootstrapCandidateDeclNode63] 0 0 1 2)

-- Nat.succ
private def coreBootstrapCandidateDecl53 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode65 [] coreBootstrapCandidateDeclNode506 coreBootstrapCandidateDeclNode63 1 0 1 [0])

-- Nat.zero
private def coreBootstrapCandidateDecl54 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode64 [] coreBootstrapCandidateDeclNode489 coreBootstrapCandidateDeclNode63 0 0 0 [])

-- Nonempty.intro
private def coreBootstrapCandidateDecl55 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode68 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode511 coreBootstrapCandidateDeclNode66 0 1 1 [])

-- Nonempty.rec
private def coreBootstrapCandidateDecl56 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreBootstrapCandidateDeclNode512 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode524 [coreBootstrapCandidateDeclNode66] 1 0 1 1)

-- Option.none
private def coreBootstrapCandidateDecl57 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode75 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode527 coreBootstrapCandidateDeclNode74 0 1 0 [])

-- Option.rec
private def coreBootstrapCandidateDecl58 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreBootstrapCandidateDeclNode528 [coreBootstrapCandidateDeclNode18, coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode545 [coreBootstrapCandidateDeclNode74] 1 0 1 2)

-- Option.some
private def coreBootstrapCandidateDecl59 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode76 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode548 coreBootstrapCandidateDeclNode74 1 1 1 [])

-- Or.inl
private def coreBootstrapCandidateDecl60 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode78 [] coreBootstrapCandidateDeclNode554 coreBootstrapCandidateDeclNode77 0 2 1 [])

-- Or.inr
private def coreBootstrapCandidateDecl61 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode79 [] coreBootstrapCandidateDeclNode557 coreBootstrapCandidateDeclNode77 1 2 1 [])

-- Or.rec
private def coreBootstrapCandidateDecl62 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreBootstrapCandidateDeclNode558 [] coreBootstrapCandidateDeclNode583 [coreBootstrapCandidateDeclNode77] 2 0 1 2)

-- PEmpty.rec
private def coreBootstrapCandidateDecl63 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreBootstrapCandidateDeclNode584 [coreBootstrapCandidateDeclNode18, coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode588 [coreBootstrapCandidateDeclNode80] 0 0 1 0)

-- PProd.mk
private def coreBootstrapCandidateDecl64 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode88 [coreBootstrapCandidateDeclNode31, coreBootstrapCandidateDeclNode32] coreBootstrapCandidateDeclNode597 coreBootstrapCandidateDeclNode81 0 2 2 [])

-- PProd.rec
private def coreBootstrapCandidateDecl65 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreBootstrapCandidateDeclNode598 [coreBootstrapCandidateDeclNode18, coreBootstrapCandidateDeclNode31, coreBootstrapCandidateDeclNode32] coreBootstrapCandidateDeclNode615 [coreBootstrapCandidateDeclNode81] 2 0 1 1)

-- PUnit.rec
private def coreBootstrapCandidateDecl66 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreBootstrapCandidateDeclNode616 [coreBootstrapCandidateDeclNode18, coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode624 [coreBootstrapCandidateDeclNode89] 0 0 1 1)

-- PUnit.unit
private def coreBootstrapCandidateDecl67 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode90 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode617 coreBootstrapCandidateDeclNode89 0 0 0 [])

-- Prod.mk
private def coreBootstrapCandidateDecl68 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode94 [coreBootstrapCandidateDeclNode31, coreBootstrapCandidateDeclNode32] coreBootstrapCandidateDeclNode631 coreBootstrapCandidateDeclNode91 0 2 2 [])

-- Prod.rec
private def coreBootstrapCandidateDecl69 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreBootstrapCandidateDeclNode632 [coreBootstrapCandidateDeclNode18, coreBootstrapCandidateDeclNode31, coreBootstrapCandidateDeclNode32] coreBootstrapCandidateDeclNode648 [coreBootstrapCandidateDeclNode91] 2 0 1 1)

-- Sum.inl
private def coreBootstrapCandidateDecl70 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode96 [coreBootstrapCandidateDeclNode31, coreBootstrapCandidateDeclNode32] coreBootstrapCandidateDeclNode654 coreBootstrapCandidateDeclNode95 0 2 1 [])

-- Sum.inr
private def coreBootstrapCandidateDecl71 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode97 [coreBootstrapCandidateDeclNode31, coreBootstrapCandidateDeclNode32] coreBootstrapCandidateDeclNode657 coreBootstrapCandidateDeclNode95 1 2 1 [])

-- Sum.rec
private def coreBootstrapCandidateDecl72 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreBootstrapCandidateDeclNode658 [coreBootstrapCandidateDeclNode18, coreBootstrapCandidateDeclNode31, coreBootstrapCandidateDeclNode32] coreBootstrapCandidateDeclNode681 [coreBootstrapCandidateDeclNode95] 2 0 1 2)

-- True.intro
private def coreBootstrapCandidateDecl73 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreBootstrapCandidateDeclNode99 [] coreBootstrapCandidateDeclNode682 coreBootstrapCandidateDeclNode98 0 0 0 [])

-- True.rec
private def coreBootstrapCandidateDecl74 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreBootstrapCandidateDeclNode683 [coreBootstrapCandidateDeclNode31] coreBootstrapCandidateDeclNode689 [coreBootstrapCandidateDeclNode98] 0 0 1 1)

-- Bool.Reflects.match_1
private def coreBootstrapCandidateDecl75 : PsDeclaration :=
  .definitionDecl coreBootstrapCandidateDeclNode229 [coreBootstrapCandidateDeclNode18] coreBootstrapCandidateDeclNode706
    coreBootstrapCandidateDeclNode720

def psCoreBootstrapCandidateDeclarations : List PsDeclaration :=
  [coreBootstrapCandidateDecl0, coreBootstrapCandidateDecl1, coreBootstrapCandidateDecl2, coreBootstrapCandidateDecl3, coreBootstrapCandidateDecl4, coreBootstrapCandidateDecl5, coreBootstrapCandidateDecl6, coreBootstrapCandidateDecl7, coreBootstrapCandidateDecl8, coreBootstrapCandidateDecl9, coreBootstrapCandidateDecl10, coreBootstrapCandidateDecl11, coreBootstrapCandidateDecl12, coreBootstrapCandidateDecl13, coreBootstrapCandidateDecl14, coreBootstrapCandidateDecl15, coreBootstrapCandidateDecl16, coreBootstrapCandidateDecl17, coreBootstrapCandidateDecl18, coreBootstrapCandidateDecl19, coreBootstrapCandidateDecl20, coreBootstrapCandidateDecl21, coreBootstrapCandidateDecl22, coreBootstrapCandidateDecl23, coreBootstrapCandidateDecl24, coreBootstrapCandidateDecl25, coreBootstrapCandidateDecl26, coreBootstrapCandidateDecl27, coreBootstrapCandidateDecl28, coreBootstrapCandidateDecl29, coreBootstrapCandidateDecl30, coreBootstrapCandidateDecl31, coreBootstrapCandidateDecl32, coreBootstrapCandidateDecl33, coreBootstrapCandidateDecl34, coreBootstrapCandidateDecl35, coreBootstrapCandidateDecl36, coreBootstrapCandidateDecl37, coreBootstrapCandidateDecl38, coreBootstrapCandidateDecl39, coreBootstrapCandidateDecl40, coreBootstrapCandidateDecl41, coreBootstrapCandidateDecl42, coreBootstrapCandidateDecl43, coreBootstrapCandidateDecl44, coreBootstrapCandidateDecl45, coreBootstrapCandidateDecl46, coreBootstrapCandidateDecl47, coreBootstrapCandidateDecl48, coreBootstrapCandidateDecl49, coreBootstrapCandidateDecl50, coreBootstrapCandidateDecl51, coreBootstrapCandidateDecl52, coreBootstrapCandidateDecl53, coreBootstrapCandidateDecl54, coreBootstrapCandidateDecl55, coreBootstrapCandidateDecl56, coreBootstrapCandidateDecl57, coreBootstrapCandidateDecl58, coreBootstrapCandidateDecl59, coreBootstrapCandidateDecl60, coreBootstrapCandidateDecl61, coreBootstrapCandidateDecl62, coreBootstrapCandidateDecl63, coreBootstrapCandidateDecl64, coreBootstrapCandidateDecl65, coreBootstrapCandidateDecl66, coreBootstrapCandidateDecl67, coreBootstrapCandidateDecl68, coreBootstrapCandidateDecl69, coreBootstrapCandidateDecl70, coreBootstrapCandidateDecl71, coreBootstrapCandidateDecl72, coreBootstrapCandidateDecl73, coreBootstrapCandidateDecl74, coreBootstrapCandidateDecl75]

def psCoreBootstrapCandidateReducibility : List (PsName × PsReducibility) :=
  [((.str .anonymous "Not"), .implicitReducible), ((.str .anonymous "Unit"), .reducible), ((.str .anonymous "dite"), .implicitReducible), ((.str .anonymous "id"), .implicitReducible), ((.str .anonymous "ite"), .implicitReducible), ((.str .anonymous "optParam"), .reducible), ((.str .anonymous "outParam"), .reducible), ((.str (.str .anonymous "Bool") "Reflects"), .reducible), ((.str (.str .anonymous "Bool") "casesOn"), .reducible), ((.str (.str .anonymous "Decidable") "decide"), .implicitReducible), ((.str (.str (.str .anonymous "Bool") "Reflects") "match_1"), .instanceReducible)]
