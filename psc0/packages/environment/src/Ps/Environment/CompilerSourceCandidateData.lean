/-
Copyright (c) Microsoft Corporation and Lean FRO, LLC.
Apache-2.0; see THIRD_PARTY_NOTICES.md.
Pinned Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Independent native candidate for the complete Ps.Foundation.Source/List source workload.
Empty boundary; actual reached declarations; no Full fallback or added assumptions.
Source registry metadata and source acceptance require separate qualification.
-/
import Ps.Environment.Basic

set_option maxRecDepth 20000

private def coreFoundationCandidateDeclNode0 : PsName := (.str .anonymous "And")
private def coreFoundationCandidateDeclNode1 : PsName := (.str .anonymous "a")
private def coreFoundationCandidateDeclNode2 : PsExpr := (.sortE .zero)
private def coreFoundationCandidateDeclNode3 : PsName := (.str .anonymous "b")
private def coreFoundationCandidateDeclNode4 : PsExpr := (.forallE coreFoundationCandidateDeclNode3 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode2 .explicit)
private def coreFoundationCandidateDeclNode5 : PsExpr := (.forallE coreFoundationCandidateDeclNode1 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode4 .explicit)
private def coreFoundationCandidateDeclNode6 : PsName := (.str coreFoundationCandidateDeclNode0 "intro")
private def coreFoundationCandidateDeclNode7 : PsName := (.str .anonymous "Bool")
private def coreFoundationCandidateDeclNode8 : PsLevel := (.succ .zero)
private def coreFoundationCandidateDeclNode9 : PsExpr := (.sortE coreFoundationCandidateDeclNode8)
private def coreFoundationCandidateDeclNode10 : PsName := (.str coreFoundationCandidateDeclNode7 "false")
private def coreFoundationCandidateDeclNode11 : PsName := (.str coreFoundationCandidateDeclNode7 "true")
private def coreFoundationCandidateDeclNode12 : PsName := (.str .anonymous "Decidable")
private def coreFoundationCandidateDeclNode13 : PsName := (.str .anonymous "p")
private def coreFoundationCandidateDeclNode14 : PsExpr := (.forallE coreFoundationCandidateDeclNode13 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode9 .explicit)
private def coreFoundationCandidateDeclNode15 : PsName := (.str coreFoundationCandidateDeclNode12 "intro")
private def coreFoundationCandidateDeclNode16 : PsName := (.str .anonymous "Empty")
private def coreFoundationCandidateDeclNode17 : PsName := (.str .anonymous "Eq")
private def coreFoundationCandidateDeclNode18 : PsName := (.str .anonymous "u_1")
private def coreFoundationCandidateDeclNode19 : PsName := (.str .anonymous "α")
private def coreFoundationCandidateDeclNode20 : PsLevel := (.param coreFoundationCandidateDeclNode18)
private def coreFoundationCandidateDeclNode21 : PsExpr := (.sortE coreFoundationCandidateDeclNode20)
private def coreFoundationCandidateDeclNode22 : PsName := (.str coreFoundationCandidateDeclNode1 "_@")
private def coreFoundationCandidateDeclNode23 : PsName := (.str coreFoundationCandidateDeclNode22 "_internal")
private def coreFoundationCandidateDeclNode24 : PsName := (.str coreFoundationCandidateDeclNode23 "_hyg")
private def coreFoundationCandidateDeclNode25 : PsName := (.num coreFoundationCandidateDeclNode24 0)
private def coreFoundationCandidateDeclNode26 : PsExpr := (.forallE coreFoundationCandidateDeclNode25 (.bvar 1) coreFoundationCandidateDeclNode2 .explicit)
private def coreFoundationCandidateDeclNode27 : PsExpr := (.forallE coreFoundationCandidateDeclNode25 (.bvar 0) coreFoundationCandidateDeclNode26 .explicit)
private def coreFoundationCandidateDeclNode28 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode21 coreFoundationCandidateDeclNode27 .implicit)
private def coreFoundationCandidateDeclNode29 : PsName := (.str coreFoundationCandidateDeclNode17 "refl")
private def coreFoundationCandidateDeclNode30 : PsName := (.str .anonymous "Except")
private def coreFoundationCandidateDeclNode31 : PsName := (.str .anonymous "u")
private def coreFoundationCandidateDeclNode32 : PsName := (.str .anonymous "v")
private def coreFoundationCandidateDeclNode33 : PsName := (.str .anonymous "ε")
private def coreFoundationCandidateDeclNode34 : PsLevel := (.param coreFoundationCandidateDeclNode31)
private def coreFoundationCandidateDeclNode35 : PsLevel := (.succ coreFoundationCandidateDeclNode34)
private def coreFoundationCandidateDeclNode36 : PsExpr := (.sortE coreFoundationCandidateDeclNode35)
private def coreFoundationCandidateDeclNode37 : PsLevel := (.param coreFoundationCandidateDeclNode32)
private def coreFoundationCandidateDeclNode38 : PsLevel := (.succ coreFoundationCandidateDeclNode37)
private def coreFoundationCandidateDeclNode39 : PsExpr := (.sortE coreFoundationCandidateDeclNode38)
private def coreFoundationCandidateDeclNode40 : PsLevel := (.max coreFoundationCandidateDeclNode35 coreFoundationCandidateDeclNode38)
private def coreFoundationCandidateDeclNode41 : PsExpr := (.sortE coreFoundationCandidateDeclNode40)
private def coreFoundationCandidateDeclNode42 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode39 coreFoundationCandidateDeclNode41 .explicit)
private def coreFoundationCandidateDeclNode43 : PsExpr := (.forallE coreFoundationCandidateDeclNode33 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode42 .explicit)
private def coreFoundationCandidateDeclNode44 : PsName := (.str coreFoundationCandidateDeclNode30 "error")
private def coreFoundationCandidateDeclNode45 : PsName := (.str coreFoundationCandidateDeclNode30 "ok")
private def coreFoundationCandidateDeclNode46 : PsName := (.str .anonymous "Exists")
private def coreFoundationCandidateDeclNode47 : PsExpr := (.sortE coreFoundationCandidateDeclNode34)
private def coreFoundationCandidateDeclNode48 : PsExpr := (.forallE coreFoundationCandidateDeclNode25 (.bvar 0) coreFoundationCandidateDeclNode2 .explicit)
private def coreFoundationCandidateDeclNode49 : PsExpr := (.forallE coreFoundationCandidateDeclNode13 coreFoundationCandidateDeclNode48 coreFoundationCandidateDeclNode2 .explicit)
private def coreFoundationCandidateDeclNode50 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode49 .implicit)
private def coreFoundationCandidateDeclNode51 : PsName := (.str coreFoundationCandidateDeclNode46 "intro")
private def coreFoundationCandidateDeclNode52 : PsName := (.str .anonymous "False")
private def coreFoundationCandidateDeclNode53 : PsName := (.str .anonymous "HEq")
private def coreFoundationCandidateDeclNode54 : PsName := (.str .anonymous "β")
private def coreFoundationCandidateDeclNode55 : PsExpr := (.forallE coreFoundationCandidateDeclNode54 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode48 .implicit)
private def coreFoundationCandidateDeclNode56 : PsExpr := (.forallE coreFoundationCandidateDeclNode25 (.bvar 0) coreFoundationCandidateDeclNode55 .explicit)
private def coreFoundationCandidateDeclNode57 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode56 .implicit)
private def coreFoundationCandidateDeclNode58 : PsName := (.str coreFoundationCandidateDeclNode53 "refl")
private def coreFoundationCandidateDeclNode59 : PsName := (.str .anonymous "List")
private def coreFoundationCandidateDeclNode60 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode36 .explicit)
private def coreFoundationCandidateDeclNode61 : PsName := (.str coreFoundationCandidateDeclNode59 "nil")
private def coreFoundationCandidateDeclNode62 : PsName := (.str coreFoundationCandidateDeclNode59 "cons")
private def coreFoundationCandidateDeclNode63 : PsName := (.str .anonymous "Nat")
private def coreFoundationCandidateDeclNode64 : PsName := (.str coreFoundationCandidateDeclNode63 "zero")
private def coreFoundationCandidateDeclNode65 : PsName := (.str coreFoundationCandidateDeclNode63 "succ")
private def coreFoundationCandidateDeclNode66 : PsName := (.str .anonymous "Nonempty")
private def coreFoundationCandidateDeclNode67 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode2 .explicit)
private def coreFoundationCandidateDeclNode68 : PsName := (.str coreFoundationCandidateDeclNode66 "intro")
private def coreFoundationCandidateDeclNode69 : PsName := (.str .anonymous "Not")
private def coreFoundationCandidateDeclNode70 : PsExpr := (.forallE coreFoundationCandidateDeclNode1 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode2 .explicit)
private def coreFoundationCandidateDeclNode71 : PsExpr := (.constE coreFoundationCandidateDeclNode52 [])
private def coreFoundationCandidateDeclNode72 : PsExpr := (.forallE coreFoundationCandidateDeclNode25 (.bvar 0) coreFoundationCandidateDeclNode71 .explicit)
private def coreFoundationCandidateDeclNode73 : PsExpr := (.lam coreFoundationCandidateDeclNode1 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode72 .explicit)
private def coreFoundationCandidateDeclNode74 : PsName := (.str .anonymous "OfNat")
private def coreFoundationCandidateDeclNode75 : PsName := (.str .anonymous "x")
private def coreFoundationCandidateDeclNode76 : PsName := (.str coreFoundationCandidateDeclNode75 "_@")
private def coreFoundationCandidateDeclNode77 : PsName := (.str coreFoundationCandidateDeclNode76 "Init")
private def coreFoundationCandidateDeclNode78 : PsName := (.str coreFoundationCandidateDeclNode77 "Prelude")
private def coreFoundationCandidateDeclNode79 : PsName := (.num coreFoundationCandidateDeclNode78 1822880135)
private def coreFoundationCandidateDeclNode80 : PsName := (.str coreFoundationCandidateDeclNode79 "_hygCtx")
private def coreFoundationCandidateDeclNode81 : PsName := (.str coreFoundationCandidateDeclNode80 "_hyg")
private def coreFoundationCandidateDeclNode82 : PsName := (.num coreFoundationCandidateDeclNode81 3)
private def coreFoundationCandidateDeclNode83 : PsExpr := (.constE coreFoundationCandidateDeclNode63 [])
private def coreFoundationCandidateDeclNode84 : PsExpr := (.forallE coreFoundationCandidateDeclNode82 coreFoundationCandidateDeclNode83 coreFoundationCandidateDeclNode36 .explicit)
private def coreFoundationCandidateDeclNode85 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode84 .explicit)
private def coreFoundationCandidateDeclNode86 : PsName := (.str coreFoundationCandidateDeclNode74 "mk")
private def coreFoundationCandidateDeclNode87 : PsName := (.str .anonymous "Option")
private def coreFoundationCandidateDeclNode88 : PsName := (.str coreFoundationCandidateDeclNode87 "none")
private def coreFoundationCandidateDeclNode89 : PsName := (.str coreFoundationCandidateDeclNode87 "some")
private def coreFoundationCandidateDeclNode90 : PsName := (.str .anonymous "Or")
private def coreFoundationCandidateDeclNode91 : PsName := (.str coreFoundationCandidateDeclNode90 "inl")
private def coreFoundationCandidateDeclNode92 : PsName := (.str coreFoundationCandidateDeclNode90 "inr")
private def coreFoundationCandidateDeclNode93 : PsName := (.str .anonymous "PEmpty")
private def coreFoundationCandidateDeclNode94 : PsName := (.str .anonymous "PProd")
private def coreFoundationCandidateDeclNode95 : PsExpr := (.sortE coreFoundationCandidateDeclNode37)
private def coreFoundationCandidateDeclNode96 : PsLevel := (.max coreFoundationCandidateDeclNode8 coreFoundationCandidateDeclNode34)
private def coreFoundationCandidateDeclNode97 : PsLevel := (.max coreFoundationCandidateDeclNode96 coreFoundationCandidateDeclNode37)
private def coreFoundationCandidateDeclNode98 : PsExpr := (.sortE coreFoundationCandidateDeclNode97)
private def coreFoundationCandidateDeclNode99 : PsExpr := (.forallE coreFoundationCandidateDeclNode54 coreFoundationCandidateDeclNode95 coreFoundationCandidateDeclNode98 .explicit)
private def coreFoundationCandidateDeclNode100 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode99 .explicit)
private def coreFoundationCandidateDeclNode101 : PsName := (.str coreFoundationCandidateDeclNode94 "mk")
private def coreFoundationCandidateDeclNode102 : PsName := (.str .anonymous "PUnit")
private def coreFoundationCandidateDeclNode103 : PsName := (.str coreFoundationCandidateDeclNode102 "unit")
private def coreFoundationCandidateDeclNode104 : PsName := (.str .anonymous "Prod")
private def coreFoundationCandidateDeclNode105 : PsExpr := (.forallE coreFoundationCandidateDeclNode54 coreFoundationCandidateDeclNode39 coreFoundationCandidateDeclNode41 .explicit)
private def coreFoundationCandidateDeclNode106 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode105 .explicit)
private def coreFoundationCandidateDeclNode107 : PsName := (.str coreFoundationCandidateDeclNode104 "mk")
private def coreFoundationCandidateDeclNode108 : PsName := (.str .anonymous "Sum")
private def coreFoundationCandidateDeclNode109 : PsName := (.str coreFoundationCandidateDeclNode108 "inl")
private def coreFoundationCandidateDeclNode110 : PsName := (.str coreFoundationCandidateDeclNode108 "inr")
private def coreFoundationCandidateDeclNode111 : PsName := (.str .anonymous "True")
private def coreFoundationCandidateDeclNode112 : PsName := (.str coreFoundationCandidateDeclNode111 "intro")
private def coreFoundationCandidateDeclNode113 : PsName := (.str .anonymous "Unit")
private def coreFoundationCandidateDeclNode114 : PsExpr := (.constE coreFoundationCandidateDeclNode102 [coreFoundationCandidateDeclNode8])
private def coreFoundationCandidateDeclNode115 : PsName := (.str .anonymous "dite")
private def coreFoundationCandidateDeclNode116 : PsName := (.str .anonymous "c")
private def coreFoundationCandidateDeclNode117 : PsName := (.str .anonymous "h")
private def coreFoundationCandidateDeclNode118 : PsExpr := (.constE coreFoundationCandidateDeclNode12 [])
private def coreFoundationCandidateDeclNode119 : PsExpr := (.app coreFoundationCandidateDeclNode118 (.bvar 0))
private def coreFoundationCandidateDeclNode120 : PsName := (.str .anonymous "t")
private def coreFoundationCandidateDeclNode121 : PsExpr := (.forallE coreFoundationCandidateDeclNode25 (.bvar 1) (.bvar 3) .explicit)
private def coreFoundationCandidateDeclNode122 : PsName := (.str .anonymous "e")
private def coreFoundationCandidateDeclNode123 : PsExpr := (.constE coreFoundationCandidateDeclNode69 [])
private def coreFoundationCandidateDeclNode124 : PsExpr := (.app coreFoundationCandidateDeclNode123 (.bvar 2))
private def coreFoundationCandidateDeclNode125 : PsExpr := (.forallE coreFoundationCandidateDeclNode25 coreFoundationCandidateDeclNode124 (.bvar 4) .explicit)
private def coreFoundationCandidateDeclNode126 : PsExpr := (.forallE coreFoundationCandidateDeclNode122 coreFoundationCandidateDeclNode125 (.bvar 4) .explicit)
private def coreFoundationCandidateDeclNode127 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode121 coreFoundationCandidateDeclNode126 .explicit)
private def coreFoundationCandidateDeclNode128 : PsExpr := (.forallE coreFoundationCandidateDeclNode117 coreFoundationCandidateDeclNode119 coreFoundationCandidateDeclNode127 .instanceImplicit)
private def coreFoundationCandidateDeclNode129 : PsExpr := (.forallE coreFoundationCandidateDeclNode116 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode128 .explicit)
private def coreFoundationCandidateDeclNode130 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode129 .implicit)
private def coreFoundationCandidateDeclNode131 : PsName := (.str coreFoundationCandidateDeclNode7 "casesOn")
private def coreFoundationCandidateDeclNode132 : PsExpr := (.constE coreFoundationCandidateDeclNode131 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode133 : PsName := (.num coreFoundationCandidateDeclNode78 3893281826)
private def coreFoundationCandidateDeclNode134 : PsName := (.str coreFoundationCandidateDeclNode133 "_hygCtx")
private def coreFoundationCandidateDeclNode135 : PsName := (.str coreFoundationCandidateDeclNode134 "_hyg")
private def coreFoundationCandidateDeclNode136 : PsName := (.num coreFoundationCandidateDeclNode135 17)
private def coreFoundationCandidateDeclNode137 : PsExpr := (.constE coreFoundationCandidateDeclNode7 [])
private def coreFoundationCandidateDeclNode138 : PsName := (.num coreFoundationCandidateDeclNode135 16)
private def coreFoundationCandidateDeclNode139 : PsName := (.str coreFoundationCandidateDeclNode7 "Reflects")
private def coreFoundationCandidateDeclNode140 : PsExpr := (.constE coreFoundationCandidateDeclNode139 [])
private def coreFoundationCandidateDeclNode141 : PsExpr := (.app coreFoundationCandidateDeclNode140 (.bvar 0))
private def coreFoundationCandidateDeclNode142 : PsExpr := (.app coreFoundationCandidateDeclNode141 (.bvar 4))
private def coreFoundationCandidateDeclNode143 : PsExpr := (.forallE coreFoundationCandidateDeclNode138 coreFoundationCandidateDeclNode142 (.bvar 6) .explicit)
private def coreFoundationCandidateDeclNode144 : PsExpr := (.lam coreFoundationCandidateDeclNode136 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode143 .explicit)
private def coreFoundationCandidateDeclNode145 : PsExpr := (.app coreFoundationCandidateDeclNode132 coreFoundationCandidateDeclNode144)
private def coreFoundationCandidateDeclNode146 : PsName := (.str coreFoundationCandidateDeclNode12 "decide")
private def coreFoundationCandidateDeclNode147 : PsExpr := (.constE coreFoundationCandidateDeclNode146 [])
private def coreFoundationCandidateDeclNode148 : PsExpr := (.app coreFoundationCandidateDeclNode147 (.bvar 3))
private def coreFoundationCandidateDeclNode149 : PsExpr := (.app coreFoundationCandidateDeclNode148 (.bvar 2))
private def coreFoundationCandidateDeclNode150 : PsExpr := (.app coreFoundationCandidateDeclNode145 coreFoundationCandidateDeclNode149)
private def coreFoundationCandidateDeclNode151 : PsExpr := (.app coreFoundationCandidateDeclNode150 (.bvar 0))
private def coreFoundationCandidateDeclNode152 : PsExpr := (.app coreFoundationCandidateDeclNode151 (.bvar 1))
private def coreFoundationCandidateDeclNode153 : PsName := (.str coreFoundationCandidateDeclNode12 "reflects_decide")
private def coreFoundationCandidateDeclNode154 : PsExpr := (.constE coreFoundationCandidateDeclNode153 [])
private def coreFoundationCandidateDeclNode155 : PsExpr := (.app coreFoundationCandidateDeclNode154 (.bvar 3))
private def coreFoundationCandidateDeclNode156 : PsExpr := (.app coreFoundationCandidateDeclNode155 (.bvar 2))
private def coreFoundationCandidateDeclNode157 : PsExpr := (.app coreFoundationCandidateDeclNode152 coreFoundationCandidateDeclNode156)
private def coreFoundationCandidateDeclNode158 : PsExpr := (.lam coreFoundationCandidateDeclNode122 coreFoundationCandidateDeclNode125 coreFoundationCandidateDeclNode157 .explicit)
private def coreFoundationCandidateDeclNode159 : PsExpr := (.lam coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode121 coreFoundationCandidateDeclNode158 .explicit)
private def coreFoundationCandidateDeclNode160 : PsExpr := (.lam coreFoundationCandidateDeclNode117 coreFoundationCandidateDeclNode119 coreFoundationCandidateDeclNode159 .instanceImplicit)
private def coreFoundationCandidateDeclNode161 : PsExpr := (.lam coreFoundationCandidateDeclNode116 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode160 .explicit)
private def coreFoundationCandidateDeclNode162 : PsExpr := (.lam coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode161 .implicit)
private def coreFoundationCandidateDeclNode163 : PsName := (.str .anonymous "id")
private def coreFoundationCandidateDeclNode164 : PsExpr := (.forallE coreFoundationCandidateDeclNode1 (.bvar 0) (.bvar 1) .explicit)
private def coreFoundationCandidateDeclNode165 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode164 .implicit)
private def coreFoundationCandidateDeclNode166 : PsExpr := (.lam coreFoundationCandidateDeclNode1 (.bvar 0) (.bvar 0) .explicit)
private def coreFoundationCandidateDeclNode167 : PsExpr := (.lam coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode166 .implicit)
private def coreFoundationCandidateDeclNode168 : PsName := (.str .anonymous "instOfNatNat")
private def coreFoundationCandidateDeclNode169 : PsName := (.str .anonymous "n")
private def coreFoundationCandidateDeclNode170 : PsExpr := (.constE coreFoundationCandidateDeclNode74 [.zero])
private def coreFoundationCandidateDeclNode171 : PsExpr := (.app coreFoundationCandidateDeclNode170 coreFoundationCandidateDeclNode83)
private def coreFoundationCandidateDeclNode172 : PsExpr := (.app coreFoundationCandidateDeclNode171 (.bvar 0))
private def coreFoundationCandidateDeclNode173 : PsExpr := (.forallE coreFoundationCandidateDeclNode169 coreFoundationCandidateDeclNode83 coreFoundationCandidateDeclNode172 .explicit)
private def coreFoundationCandidateDeclNode174 : PsExpr := (.constE coreFoundationCandidateDeclNode86 [.zero])
private def coreFoundationCandidateDeclNode175 : PsExpr := (.app coreFoundationCandidateDeclNode174 coreFoundationCandidateDeclNode83)
private def coreFoundationCandidateDeclNode176 : PsExpr := (.app coreFoundationCandidateDeclNode175 (.bvar 0))
private def coreFoundationCandidateDeclNode177 : PsExpr := (.app coreFoundationCandidateDeclNode176 (.bvar 0))
private def coreFoundationCandidateDeclNode178 : PsExpr := (.lam coreFoundationCandidateDeclNode169 coreFoundationCandidateDeclNode83 coreFoundationCandidateDeclNode177 .explicit)
private def coreFoundationCandidateDeclNode179 : PsName := (.str .anonymous "ite")
private def coreFoundationCandidateDeclNode180 : PsExpr := (.forallE coreFoundationCandidateDeclNode122 (.bvar 3) (.bvar 4) .explicit)
private def coreFoundationCandidateDeclNode181 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 (.bvar 2) coreFoundationCandidateDeclNode180 .explicit)
private def coreFoundationCandidateDeclNode182 : PsExpr := (.forallE coreFoundationCandidateDeclNode117 coreFoundationCandidateDeclNode119 coreFoundationCandidateDeclNode181 .instanceImplicit)
private def coreFoundationCandidateDeclNode183 : PsExpr := (.forallE coreFoundationCandidateDeclNode116 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode182 .explicit)
private def coreFoundationCandidateDeclNode184 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode183 .implicit)
private def coreFoundationCandidateDeclNode185 : PsExpr := (.constE coreFoundationCandidateDeclNode115 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode186 : PsExpr := (.app coreFoundationCandidateDeclNode185 (.bvar 4))
private def coreFoundationCandidateDeclNode187 : PsExpr := (.app coreFoundationCandidateDeclNode186 (.bvar 3))
private def coreFoundationCandidateDeclNode188 : PsExpr := (.app coreFoundationCandidateDeclNode187 (.bvar 2))
private def coreFoundationCandidateDeclNode189 : PsName := (.num coreFoundationCandidateDeclNode78 1596968041)
private def coreFoundationCandidateDeclNode190 : PsName := (.str coreFoundationCandidateDeclNode189 "_hygCtx")
private def coreFoundationCandidateDeclNode191 : PsName := (.str coreFoundationCandidateDeclNode190 "_hyg")
private def coreFoundationCandidateDeclNode192 : PsName := (.num coreFoundationCandidateDeclNode191 15)
private def coreFoundationCandidateDeclNode193 : PsExpr := (.lam coreFoundationCandidateDeclNode192 (.bvar 3) (.bvar 2) .explicit)
private def coreFoundationCandidateDeclNode194 : PsExpr := (.app coreFoundationCandidateDeclNode188 coreFoundationCandidateDeclNode193)
private def coreFoundationCandidateDeclNode195 : PsName := (.num coreFoundationCandidateDeclNode191 22)
private def coreFoundationCandidateDeclNode196 : PsExpr := (.app coreFoundationCandidateDeclNode123 (.bvar 3))
private def coreFoundationCandidateDeclNode197 : PsExpr := (.lam coreFoundationCandidateDeclNode195 coreFoundationCandidateDeclNode196 (.bvar 1) .explicit)
private def coreFoundationCandidateDeclNode198 : PsExpr := (.app coreFoundationCandidateDeclNode194 coreFoundationCandidateDeclNode197)
private def coreFoundationCandidateDeclNode199 : PsExpr := (.lam coreFoundationCandidateDeclNode122 (.bvar 3) coreFoundationCandidateDeclNode198 .explicit)
private def coreFoundationCandidateDeclNode200 : PsExpr := (.lam coreFoundationCandidateDeclNode120 (.bvar 2) coreFoundationCandidateDeclNode199 .explicit)
private def coreFoundationCandidateDeclNode201 : PsExpr := (.lam coreFoundationCandidateDeclNode117 coreFoundationCandidateDeclNode119 coreFoundationCandidateDeclNode200 .instanceImplicit)
private def coreFoundationCandidateDeclNode202 : PsExpr := (.lam coreFoundationCandidateDeclNode116 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode201 .explicit)
private def coreFoundationCandidateDeclNode203 : PsExpr := (.lam coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode202 .implicit)
private def coreFoundationCandidateDeclNode204 : PsName := (.str .anonymous "optParam")
private def coreFoundationCandidateDeclNode205 : PsName := (.str .anonymous "default")
private def coreFoundationCandidateDeclNode206 : PsExpr := (.forallE coreFoundationCandidateDeclNode205 (.bvar 0) coreFoundationCandidateDeclNode47 .explicit)
private def coreFoundationCandidateDeclNode207 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode206 .explicit)
private def coreFoundationCandidateDeclNode208 : PsExpr := (.lam coreFoundationCandidateDeclNode205 (.bvar 0) (.bvar 1) .explicit)
private def coreFoundationCandidateDeclNode209 : PsExpr := (.lam coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode208 .explicit)
private def coreFoundationCandidateDeclNode210 : PsName := (.str .anonymous "outParam")
private def coreFoundationCandidateDeclNode211 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode47 .explicit)
private def coreFoundationCandidateDeclNode212 : PsExpr := (.lam coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 (.bvar 0) .explicit)
private def coreFoundationCandidateDeclNode213 : PsName := (.str .anonymous "rfl")
private def coreFoundationCandidateDeclNode214 : PsExpr := (.constE coreFoundationCandidateDeclNode17 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode215 : PsExpr := (.app coreFoundationCandidateDeclNode214 (.bvar 1))
private def coreFoundationCandidateDeclNode216 : PsExpr := (.app coreFoundationCandidateDeclNode215 (.bvar 0))
private def coreFoundationCandidateDeclNode217 : PsExpr := (.app coreFoundationCandidateDeclNode216 (.bvar 0))
private def coreFoundationCandidateDeclNode218 : PsExpr := (.forallE coreFoundationCandidateDeclNode1 (.bvar 0) coreFoundationCandidateDeclNode217 .implicit)
private def coreFoundationCandidateDeclNode219 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode218 .implicit)
private def coreFoundationCandidateDeclNode220 : PsExpr := (.constE coreFoundationCandidateDeclNode29 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode221 : PsExpr := (.app coreFoundationCandidateDeclNode220 (.bvar 1))
private def coreFoundationCandidateDeclNode222 : PsExpr := (.app coreFoundationCandidateDeclNode221 (.bvar 0))
private def coreFoundationCandidateDeclNode223 : PsExpr := (.lam coreFoundationCandidateDeclNode1 (.bvar 0) coreFoundationCandidateDeclNode222 .implicit)
private def coreFoundationCandidateDeclNode224 : PsExpr := (.lam coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode223 .implicit)
private def coreFoundationCandidateDeclNode225 : PsName := (.str .anonymous "left")
private def coreFoundationCandidateDeclNode226 : PsName := (.str .anonymous "right")
private def coreFoundationCandidateDeclNode227 : PsExpr := (.constE coreFoundationCandidateDeclNode0 [])
private def coreFoundationCandidateDeclNode228 : PsExpr := (.app coreFoundationCandidateDeclNode227 (.bvar 3))
private def coreFoundationCandidateDeclNode229 : PsExpr := (.app coreFoundationCandidateDeclNode228 (.bvar 2))
private def coreFoundationCandidateDeclNode230 : PsExpr := (.forallE coreFoundationCandidateDeclNode226 (.bvar 1) coreFoundationCandidateDeclNode229 .explicit)
private def coreFoundationCandidateDeclNode231 : PsExpr := (.forallE coreFoundationCandidateDeclNode225 (.bvar 1) coreFoundationCandidateDeclNode230 .explicit)
private def coreFoundationCandidateDeclNode232 : PsExpr := (.forallE coreFoundationCandidateDeclNode3 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode231 .implicit)
private def coreFoundationCandidateDeclNode233 : PsExpr := (.forallE coreFoundationCandidateDeclNode1 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode232 .implicit)
private def coreFoundationCandidateDeclNode234 : PsName := (.str coreFoundationCandidateDeclNode0 "rec")
private def coreFoundationCandidateDeclNode235 : PsName := (.str .anonymous "motive")
private def coreFoundationCandidateDeclNode236 : PsExpr := (.app coreFoundationCandidateDeclNode227 (.bvar 1))
private def coreFoundationCandidateDeclNode237 : PsExpr := (.app coreFoundationCandidateDeclNode236 (.bvar 0))
private def coreFoundationCandidateDeclNode238 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode237 coreFoundationCandidateDeclNode47 .explicit)
private def coreFoundationCandidateDeclNode239 : PsName := (.str .anonymous "intro")
private def coreFoundationCandidateDeclNode240 : PsExpr := (.constE coreFoundationCandidateDeclNode6 [])
private def coreFoundationCandidateDeclNode241 : PsExpr := (.app coreFoundationCandidateDeclNode240 (.bvar 4))
private def coreFoundationCandidateDeclNode242 : PsExpr := (.app coreFoundationCandidateDeclNode241 (.bvar 3))
private def coreFoundationCandidateDeclNode243 : PsExpr := (.app coreFoundationCandidateDeclNode242 (.bvar 1))
private def coreFoundationCandidateDeclNode244 : PsExpr := (.app coreFoundationCandidateDeclNode243 (.bvar 0))
private def coreFoundationCandidateDeclNode245 : PsExpr := (.app (.bvar 2) coreFoundationCandidateDeclNode244)
private def coreFoundationCandidateDeclNode246 : PsExpr := (.forallE coreFoundationCandidateDeclNode226 (.bvar 2) coreFoundationCandidateDeclNode245 .explicit)
private def coreFoundationCandidateDeclNode247 : PsExpr := (.forallE coreFoundationCandidateDeclNode225 (.bvar 2) coreFoundationCandidateDeclNode246 .explicit)
private def coreFoundationCandidateDeclNode248 : PsExpr := (.app (.bvar 2) (.bvar 0))
private def coreFoundationCandidateDeclNode249 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode229 coreFoundationCandidateDeclNode248 .explicit)
private def coreFoundationCandidateDeclNode250 : PsExpr := (.forallE coreFoundationCandidateDeclNode239 coreFoundationCandidateDeclNode247 coreFoundationCandidateDeclNode249 .explicit)
private def coreFoundationCandidateDeclNode251 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode238 coreFoundationCandidateDeclNode250 .implicit)
private def coreFoundationCandidateDeclNode252 : PsExpr := (.forallE coreFoundationCandidateDeclNode3 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode251 .implicit)
private def coreFoundationCandidateDeclNode253 : PsExpr := (.forallE coreFoundationCandidateDeclNode1 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode252 .implicit)
private def coreFoundationCandidateDeclNode254 : PsExpr := (.forallE coreFoundationCandidateDeclNode25 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode2 .explicit)
private def coreFoundationCandidateDeclNode255 : PsExpr := (.forallE coreFoundationCandidateDeclNode25 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode254 .explicit)
private def coreFoundationCandidateDeclNode256 : PsName := (.num coreFoundationCandidateDeclNode78 3273385309)
private def coreFoundationCandidateDeclNode257 : PsName := (.str coreFoundationCandidateDeclNode256 "_hygCtx")
private def coreFoundationCandidateDeclNode258 : PsName := (.str coreFoundationCandidateDeclNode257 "_hyg")
private def coreFoundationCandidateDeclNode259 : PsName := (.num coreFoundationCandidateDeclNode258 7)
private def coreFoundationCandidateDeclNode260 : PsName := (.num coreFoundationCandidateDeclNode258 8)
private def coreFoundationCandidateDeclNode261 : PsName := (.str coreFoundationCandidateDeclNode139 "match_1")
private def coreFoundationCandidateDeclNode262 : PsExpr := (.constE coreFoundationCandidateDeclNode261 [coreFoundationCandidateDeclNode8])
private def coreFoundationCandidateDeclNode263 : PsName := (.num coreFoundationCandidateDeclNode257 7)
private def coreFoundationCandidateDeclNode264 : PsName := (.str coreFoundationCandidateDeclNode263 "Init")
private def coreFoundationCandidateDeclNode265 : PsName := (.str coreFoundationCandidateDeclNode264 "Prelude")
private def coreFoundationCandidateDeclNode266 : PsName := (.num coreFoundationCandidateDeclNode265 3273385309)
private def coreFoundationCandidateDeclNode267 : PsName := (.str coreFoundationCandidateDeclNode266 "_hygCtx")
private def coreFoundationCandidateDeclNode268 : PsName := (.str coreFoundationCandidateDeclNode267 "_hyg")
private def coreFoundationCandidateDeclNode269 : PsName := (.num coreFoundationCandidateDeclNode268 26)
private def coreFoundationCandidateDeclNode270 : PsName := (.num coreFoundationCandidateDeclNode257 8)
private def coreFoundationCandidateDeclNode271 : PsName := (.str coreFoundationCandidateDeclNode270 "Init")
private def coreFoundationCandidateDeclNode272 : PsName := (.str coreFoundationCandidateDeclNode271 "Prelude")
private def coreFoundationCandidateDeclNode273 : PsName := (.num coreFoundationCandidateDeclNode272 3273385309)
private def coreFoundationCandidateDeclNode274 : PsName := (.str coreFoundationCandidateDeclNode273 "_hygCtx")
private def coreFoundationCandidateDeclNode275 : PsName := (.str coreFoundationCandidateDeclNode274 "_hyg")
private def coreFoundationCandidateDeclNode276 : PsName := (.num coreFoundationCandidateDeclNode275 29)
private def coreFoundationCandidateDeclNode277 : PsExpr := (.lam coreFoundationCandidateDeclNode276 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode2 .explicit)
private def coreFoundationCandidateDeclNode278 : PsExpr := (.lam coreFoundationCandidateDeclNode269 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode277 .explicit)
private def coreFoundationCandidateDeclNode279 : PsExpr := (.app coreFoundationCandidateDeclNode262 coreFoundationCandidateDeclNode278)
private def coreFoundationCandidateDeclNode280 : PsExpr := (.app coreFoundationCandidateDeclNode279 (.bvar 1))
private def coreFoundationCandidateDeclNode281 : PsExpr := (.app coreFoundationCandidateDeclNode280 (.bvar 0))
private def coreFoundationCandidateDeclNode282 : PsExpr := (.app coreFoundationCandidateDeclNode123 (.bvar 0))
private def coreFoundationCandidateDeclNode283 : PsExpr := (.lam coreFoundationCandidateDeclNode13 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode282 .explicit)
private def coreFoundationCandidateDeclNode284 : PsExpr := (.app coreFoundationCandidateDeclNode281 coreFoundationCandidateDeclNode283)
private def coreFoundationCandidateDeclNode285 : PsExpr := (.lam coreFoundationCandidateDeclNode13 coreFoundationCandidateDeclNode2 (.bvar 0) .explicit)
private def coreFoundationCandidateDeclNode286 : PsExpr := (.app coreFoundationCandidateDeclNode284 coreFoundationCandidateDeclNode285)
private def coreFoundationCandidateDeclNode287 : PsExpr := (.lam coreFoundationCandidateDeclNode260 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode286 .explicit)
private def coreFoundationCandidateDeclNode288 : PsExpr := (.lam coreFoundationCandidateDeclNode259 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode287 .explicit)
private def coreFoundationCandidateDeclNode289 : PsName := (.str coreFoundationCandidateDeclNode7 "beq")
private def coreFoundationCandidateDeclNode290 : PsExpr := (.forallE coreFoundationCandidateDeclNode3 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode137 .explicit)
private def coreFoundationCandidateDeclNode291 : PsExpr := (.forallE coreFoundationCandidateDeclNode1 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode290 .explicit)
private def coreFoundationCandidateDeclNode292 : PsName := (.str coreFoundationCandidateDeclNode7 "Internal")
private def coreFoundationCandidateDeclNode293 : PsName := (.str coreFoundationCandidateDeclNode292 "and")
private def coreFoundationCandidateDeclNode294 : PsName := (.str coreFoundationCandidateDeclNode293 "match_1")
private def coreFoundationCandidateDeclNode295 : PsExpr := (.constE coreFoundationCandidateDeclNode294 [coreFoundationCandidateDeclNode8])
private def coreFoundationCandidateDeclNode296 : PsName := (.str coreFoundationCandidateDeclNode3 "_@")
private def coreFoundationCandidateDeclNode297 : PsName := (.str coreFoundationCandidateDeclNode296 "Init")
private def coreFoundationCandidateDeclNode298 : PsName := (.str coreFoundationCandidateDeclNode297 "Prelude")
private def coreFoundationCandidateDeclNode299 : PsName := (.num coreFoundationCandidateDeclNode298 2408276647)
private def coreFoundationCandidateDeclNode300 : PsName := (.str coreFoundationCandidateDeclNode299 "_hygCtx")
private def coreFoundationCandidateDeclNode301 : PsName := (.str coreFoundationCandidateDeclNode300 "_hyg")
private def coreFoundationCandidateDeclNode302 : PsName := (.num coreFoundationCandidateDeclNode301 8)
private def coreFoundationCandidateDeclNode303 : PsExpr := (.lam coreFoundationCandidateDeclNode302 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode137 .explicit)
private def coreFoundationCandidateDeclNode304 : PsExpr := (.app coreFoundationCandidateDeclNode295 coreFoundationCandidateDeclNode303)
private def coreFoundationCandidateDeclNode305 : PsExpr := (.app coreFoundationCandidateDeclNode304 (.bvar 0))
private def coreFoundationCandidateDeclNode306 : PsName := (.str .anonymous "_")
private def coreFoundationCandidateDeclNode307 : PsExpr := (.constE coreFoundationCandidateDeclNode113 [])
private def coreFoundationCandidateDeclNode308 : PsName := (.str coreFoundationCandidateDeclNode7 "not")
private def coreFoundationCandidateDeclNode309 : PsExpr := (.constE coreFoundationCandidateDeclNode308 [])
private def coreFoundationCandidateDeclNode310 : PsExpr := (.app coreFoundationCandidateDeclNode309 (.bvar 2))
private def coreFoundationCandidateDeclNode311 : PsExpr := (.lam coreFoundationCandidateDeclNode306 coreFoundationCandidateDeclNode307 coreFoundationCandidateDeclNode310 .explicit)
private def coreFoundationCandidateDeclNode312 : PsExpr := (.app coreFoundationCandidateDeclNode305 coreFoundationCandidateDeclNode311)
private def coreFoundationCandidateDeclNode313 : PsExpr := (.lam coreFoundationCandidateDeclNode306 coreFoundationCandidateDeclNode307 (.bvar 2) .explicit)
private def coreFoundationCandidateDeclNode314 : PsExpr := (.app coreFoundationCandidateDeclNode312 coreFoundationCandidateDeclNode313)
private def coreFoundationCandidateDeclNode315 : PsExpr := (.lam coreFoundationCandidateDeclNode3 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode314 .explicit)
private def coreFoundationCandidateDeclNode316 : PsExpr := (.lam coreFoundationCandidateDeclNode1 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode315 .explicit)
private def coreFoundationCandidateDeclNode317 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode47 .explicit)
private def coreFoundationCandidateDeclNode318 : PsName := (.str .anonymous "false")
private def coreFoundationCandidateDeclNode319 : PsExpr := (.constE coreFoundationCandidateDeclNode10 [])
private def coreFoundationCandidateDeclNode320 : PsExpr := (.app (.bvar 1) coreFoundationCandidateDeclNode319)
private def coreFoundationCandidateDeclNode321 : PsName := (.str .anonymous "true")
private def coreFoundationCandidateDeclNode322 : PsExpr := (.constE coreFoundationCandidateDeclNode11 [])
private def coreFoundationCandidateDeclNode323 : PsExpr := (.app (.bvar 2) coreFoundationCandidateDeclNode322)
private def coreFoundationCandidateDeclNode324 : PsExpr := (.app (.bvar 3) (.bvar 2))
private def coreFoundationCandidateDeclNode325 : PsExpr := (.forallE coreFoundationCandidateDeclNode321 coreFoundationCandidateDeclNode323 coreFoundationCandidateDeclNode324 .explicit)
private def coreFoundationCandidateDeclNode326 : PsExpr := (.forallE coreFoundationCandidateDeclNode318 coreFoundationCandidateDeclNode320 coreFoundationCandidateDeclNode325 .explicit)
private def coreFoundationCandidateDeclNode327 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode326 .explicit)
private def coreFoundationCandidateDeclNode328 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode317 coreFoundationCandidateDeclNode327 .implicit)
private def coreFoundationCandidateDeclNode329 : PsName := (.str coreFoundationCandidateDeclNode7 "rec")
private def coreFoundationCandidateDeclNode330 : PsExpr := (.constE coreFoundationCandidateDeclNode329 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode331 : PsExpr := (.app coreFoundationCandidateDeclNode330 (.bvar 3))
private def coreFoundationCandidateDeclNode332 : PsExpr := (.app coreFoundationCandidateDeclNode331 (.bvar 1))
private def coreFoundationCandidateDeclNode333 : PsExpr := (.app coreFoundationCandidateDeclNode332 (.bvar 0))
private def coreFoundationCandidateDeclNode334 : PsExpr := (.app coreFoundationCandidateDeclNode333 (.bvar 2))
private def coreFoundationCandidateDeclNode335 : PsExpr := (.lam coreFoundationCandidateDeclNode321 coreFoundationCandidateDeclNode323 coreFoundationCandidateDeclNode334 .explicit)
private def coreFoundationCandidateDeclNode336 : PsExpr := (.lam coreFoundationCandidateDeclNode318 coreFoundationCandidateDeclNode320 coreFoundationCandidateDeclNode335 .explicit)
private def coreFoundationCandidateDeclNode337 : PsExpr := (.lam coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode336 .explicit)
private def coreFoundationCandidateDeclNode338 : PsExpr := (.lam coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode317 coreFoundationCandidateDeclNode337 .implicit)
private def coreFoundationCandidateDeclNode339 : PsName := (.str coreFoundationCandidateDeclNode7 "decEq")
private def coreFoundationCandidateDeclNode340 : PsExpr := (.constE coreFoundationCandidateDeclNode17 [coreFoundationCandidateDeclNode8])
private def coreFoundationCandidateDeclNode341 : PsExpr := (.app coreFoundationCandidateDeclNode340 coreFoundationCandidateDeclNode137)
private def coreFoundationCandidateDeclNode342 : PsExpr := (.app coreFoundationCandidateDeclNode341 (.bvar 1))
private def coreFoundationCandidateDeclNode343 : PsExpr := (.app coreFoundationCandidateDeclNode342 (.bvar 0))
private def coreFoundationCandidateDeclNode344 : PsExpr := (.app coreFoundationCandidateDeclNode118 coreFoundationCandidateDeclNode343)
private def coreFoundationCandidateDeclNode345 : PsExpr := (.forallE coreFoundationCandidateDeclNode3 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode344 .explicit)
private def coreFoundationCandidateDeclNode346 : PsExpr := (.forallE coreFoundationCandidateDeclNode1 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode345 .explicit)
private def coreFoundationCandidateDeclNode347 : PsExpr := (.constE coreFoundationCandidateDeclNode15 [])
private def coreFoundationCandidateDeclNode348 : PsExpr := (.app coreFoundationCandidateDeclNode347 coreFoundationCandidateDeclNode343)
private def coreFoundationCandidateDeclNode349 : PsExpr := (.constE coreFoundationCandidateDeclNode289 [])
private def coreFoundationCandidateDeclNode350 : PsExpr := (.app coreFoundationCandidateDeclNode349 (.bvar 1))
private def coreFoundationCandidateDeclNode351 : PsExpr := (.app coreFoundationCandidateDeclNode350 (.bvar 0))
private def coreFoundationCandidateDeclNode352 : PsExpr := (.app coreFoundationCandidateDeclNode348 coreFoundationCandidateDeclNode351)
private def coreFoundationCandidateDeclNode353 : PsName := (.str coreFoundationCandidateDeclNode339 "_proof_1")
private def coreFoundationCandidateDeclNode354 : PsExpr := (.constE coreFoundationCandidateDeclNode353 [])
private def coreFoundationCandidateDeclNode355 : PsExpr := (.app coreFoundationCandidateDeclNode354 (.bvar 1))
private def coreFoundationCandidateDeclNode356 : PsExpr := (.app coreFoundationCandidateDeclNode355 (.bvar 0))
private def coreFoundationCandidateDeclNode357 : PsExpr := (.app coreFoundationCandidateDeclNode352 coreFoundationCandidateDeclNode356)
private def coreFoundationCandidateDeclNode358 : PsExpr := (.lam coreFoundationCandidateDeclNode3 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode357 .explicit)
private def coreFoundationCandidateDeclNode359 : PsExpr := (.lam coreFoundationCandidateDeclNode1 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode358 .explicit)
private def coreFoundationCandidateDeclNode360 : PsName := (.str coreFoundationCandidateDeclNode7 "noConfusion")
private def coreFoundationCandidateDeclNode361 : PsName := (.str .anonymous "P")
private def coreFoundationCandidateDeclNode362 : PsName := (.str .anonymous "t'")
private def coreFoundationCandidateDeclNode363 : PsName := (.str .anonymous "eq")
private def coreFoundationCandidateDeclNode364 : PsName := (.str coreFoundationCandidateDeclNode7 "noConfusionType")
private def coreFoundationCandidateDeclNode365 : PsExpr := (.constE coreFoundationCandidateDeclNode364 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode366 : PsExpr := (.app coreFoundationCandidateDeclNode365 (.bvar 3))
private def coreFoundationCandidateDeclNode367 : PsExpr := (.app coreFoundationCandidateDeclNode366 (.bvar 2))
private def coreFoundationCandidateDeclNode368 : PsExpr := (.app coreFoundationCandidateDeclNode367 (.bvar 1))
private def coreFoundationCandidateDeclNode369 : PsExpr := (.forallE coreFoundationCandidateDeclNode363 coreFoundationCandidateDeclNode343 coreFoundationCandidateDeclNode368 .explicit)
private def coreFoundationCandidateDeclNode370 : PsExpr := (.forallE coreFoundationCandidateDeclNode362 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode369 .implicit)
private def coreFoundationCandidateDeclNode371 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode370 .implicit)
private def coreFoundationCandidateDeclNode372 : PsExpr := (.forallE coreFoundationCandidateDeclNode361 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode371 .implicit)
private def coreFoundationCandidateDeclNode373 : PsName := (.str coreFoundationCandidateDeclNode17 "ndrec")
private def coreFoundationCandidateDeclNode374 : PsExpr := (.constE coreFoundationCandidateDeclNode373 [coreFoundationCandidateDeclNode34, coreFoundationCandidateDeclNode8])
private def coreFoundationCandidateDeclNode375 : PsExpr := (.app coreFoundationCandidateDeclNode374 coreFoundationCandidateDeclNode137)
private def coreFoundationCandidateDeclNode376 : PsExpr := (.app coreFoundationCandidateDeclNode375 (.bvar 2))
private def coreFoundationCandidateDeclNode377 : PsExpr := (.app coreFoundationCandidateDeclNode365 (.bvar 4))
private def coreFoundationCandidateDeclNode378 : PsExpr := (.app coreFoundationCandidateDeclNode377 (.bvar 3))
private def coreFoundationCandidateDeclNode379 : PsExpr := (.app coreFoundationCandidateDeclNode378 (.bvar 0))
private def coreFoundationCandidateDeclNode380 : PsExpr := (.lam coreFoundationCandidateDeclNode362 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode379 .implicit)
private def coreFoundationCandidateDeclNode381 : PsExpr := (.app coreFoundationCandidateDeclNode376 coreFoundationCandidateDeclNode380)
private def coreFoundationCandidateDeclNode382 : PsExpr := (.app coreFoundationCandidateDeclNode377 (.bvar 0))
private def coreFoundationCandidateDeclNode383 : PsExpr := (.app coreFoundationCandidateDeclNode382 (.bvar 0))
private def coreFoundationCandidateDeclNode384 : PsExpr := (.lam coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode383 .implicit)
private def coreFoundationCandidateDeclNode385 : PsExpr := (.app coreFoundationCandidateDeclNode132 coreFoundationCandidateDeclNode384)
private def coreFoundationCandidateDeclNode386 : PsExpr := (.app coreFoundationCandidateDeclNode385 (.bvar 2))
private def coreFoundationCandidateDeclNode387 : PsName := (.str .anonymous "k")
private def coreFoundationCandidateDeclNode388 : PsExpr := (.lam coreFoundationCandidateDeclNode387 (.bvar 3) (.bvar 0) .explicit)
private def coreFoundationCandidateDeclNode389 : PsExpr := (.app coreFoundationCandidateDeclNode386 coreFoundationCandidateDeclNode388)
private def coreFoundationCandidateDeclNode390 : PsExpr := (.app coreFoundationCandidateDeclNode389 coreFoundationCandidateDeclNode388)
private def coreFoundationCandidateDeclNode391 : PsExpr := (.app coreFoundationCandidateDeclNode381 coreFoundationCandidateDeclNode390)
private def coreFoundationCandidateDeclNode392 : PsExpr := (.app coreFoundationCandidateDeclNode391 (.bvar 1))
private def coreFoundationCandidateDeclNode393 : PsExpr := (.app coreFoundationCandidateDeclNode392 (.bvar 0))
private def coreFoundationCandidateDeclNode394 : PsExpr := (.lam coreFoundationCandidateDeclNode363 coreFoundationCandidateDeclNode343 coreFoundationCandidateDeclNode393 .explicit)
private def coreFoundationCandidateDeclNode395 : PsExpr := (.lam coreFoundationCandidateDeclNode362 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode394 .implicit)
private def coreFoundationCandidateDeclNode396 : PsExpr := (.lam coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode395 .implicit)
private def coreFoundationCandidateDeclNode397 : PsExpr := (.lam coreFoundationCandidateDeclNode361 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode396 .implicit)
private def coreFoundationCandidateDeclNode398 : PsExpr := (.forallE coreFoundationCandidateDeclNode362 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode47 .explicit)
private def coreFoundationCandidateDeclNode399 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode398 .explicit)
private def coreFoundationCandidateDeclNode400 : PsExpr := (.forallE coreFoundationCandidateDeclNode361 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode399 .explicit)
private def coreFoundationCandidateDeclNode401 : PsExpr := (.constE coreFoundationCandidateDeclNode131 [coreFoundationCandidateDeclNode35])
private def coreFoundationCandidateDeclNode402 : PsExpr := (.lam coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode47 .explicit)
private def coreFoundationCandidateDeclNode403 : PsExpr := (.app coreFoundationCandidateDeclNode401 coreFoundationCandidateDeclNode402)
private def coreFoundationCandidateDeclNode404 : PsExpr := (.app coreFoundationCandidateDeclNode403 (.bvar 1))
private def coreFoundationCandidateDeclNode405 : PsExpr := (.app coreFoundationCandidateDeclNode403 (.bvar 0))
private def coreFoundationCandidateDeclNode406 : PsName := (.num coreFoundationCandidateDeclNode78 3636866298)
private def coreFoundationCandidateDeclNode407 : PsName := (.str coreFoundationCandidateDeclNode406 "_hygCtx")
private def coreFoundationCandidateDeclNode408 : PsName := (.str coreFoundationCandidateDeclNode407 "_hyg")
private def coreFoundationCandidateDeclNode409 : PsName := (.num coreFoundationCandidateDeclNode408 5)
private def coreFoundationCandidateDeclNode410 : PsExpr := (.forallE coreFoundationCandidateDeclNode409 (.bvar 2) (.bvar 3) .explicit)
private def coreFoundationCandidateDeclNode411 : PsExpr := (.app coreFoundationCandidateDeclNode405 coreFoundationCandidateDeclNode410)
private def coreFoundationCandidateDeclNode412 : PsExpr := (.app coreFoundationCandidateDeclNode411 (.bvar 2))
private def coreFoundationCandidateDeclNode413 : PsExpr := (.app coreFoundationCandidateDeclNode404 coreFoundationCandidateDeclNode412)
private def coreFoundationCandidateDeclNode414 : PsExpr := (.app coreFoundationCandidateDeclNode405 (.bvar 2))
private def coreFoundationCandidateDeclNode415 : PsName := (.num coreFoundationCandidateDeclNode408 6)
private def coreFoundationCandidateDeclNode416 : PsExpr := (.forallE coreFoundationCandidateDeclNode415 (.bvar 2) (.bvar 3) .explicit)
private def coreFoundationCandidateDeclNode417 : PsExpr := (.app coreFoundationCandidateDeclNode414 coreFoundationCandidateDeclNode416)
private def coreFoundationCandidateDeclNode418 : PsExpr := (.app coreFoundationCandidateDeclNode413 coreFoundationCandidateDeclNode417)
private def coreFoundationCandidateDeclNode419 : PsExpr := (.lam coreFoundationCandidateDeclNode362 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode418 .explicit)
private def coreFoundationCandidateDeclNode420 : PsExpr := (.lam coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode419 .explicit)
private def coreFoundationCandidateDeclNode421 : PsExpr := (.lam coreFoundationCandidateDeclNode361 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode420 .explicit)
private def coreFoundationCandidateDeclNode422 : PsExpr := (.forallE coreFoundationCandidateDeclNode75 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode137 .explicit)
private def coreFoundationCandidateDeclNode423 : PsExpr := (.constE coreFoundationCandidateDeclNode329 [coreFoundationCandidateDeclNode8])
private def coreFoundationCandidateDeclNode424 : PsName := (.num coreFoundationCandidateDeclNode78 2709464109)
private def coreFoundationCandidateDeclNode425 : PsName := (.str coreFoundationCandidateDeclNode424 "_hygCtx")
private def coreFoundationCandidateDeclNode426 : PsName := (.str coreFoundationCandidateDeclNode425 "_hyg")
private def coreFoundationCandidateDeclNode427 : PsName := (.num coreFoundationCandidateDeclNode426 6)
private def coreFoundationCandidateDeclNode428 : PsExpr := (.lam coreFoundationCandidateDeclNode427 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode137 .explicit)
private def coreFoundationCandidateDeclNode429 : PsExpr := (.app coreFoundationCandidateDeclNode423 coreFoundationCandidateDeclNode428)
private def coreFoundationCandidateDeclNode430 : PsExpr := (.app coreFoundationCandidateDeclNode429 coreFoundationCandidateDeclNode322)
private def coreFoundationCandidateDeclNode431 : PsExpr := (.app coreFoundationCandidateDeclNode430 coreFoundationCandidateDeclNode319)
private def coreFoundationCandidateDeclNode432 : PsExpr := (.app coreFoundationCandidateDeclNode431 (.bvar 0))
private def coreFoundationCandidateDeclNode433 : PsExpr := (.lam coreFoundationCandidateDeclNode75 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode432 .explicit)
private def coreFoundationCandidateDeclNode434 : PsExpr := (.app (.bvar 0) coreFoundationCandidateDeclNode319)
private def coreFoundationCandidateDeclNode435 : PsExpr := (.app (.bvar 1) coreFoundationCandidateDeclNode322)
private def coreFoundationCandidateDeclNode436 : PsExpr := (.app (.bvar 3) (.bvar 0))
private def coreFoundationCandidateDeclNode437 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode436 .explicit)
private def coreFoundationCandidateDeclNode438 : PsExpr := (.forallE coreFoundationCandidateDeclNode321 coreFoundationCandidateDeclNode435 coreFoundationCandidateDeclNode437 .explicit)
private def coreFoundationCandidateDeclNode439 : PsExpr := (.forallE coreFoundationCandidateDeclNode318 coreFoundationCandidateDeclNode434 coreFoundationCandidateDeclNode438 .explicit)
private def coreFoundationCandidateDeclNode440 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode317 coreFoundationCandidateDeclNode439 .implicit)
private def coreFoundationCandidateDeclNode441 : PsName := (.str .anonymous "self")
private def coreFoundationCandidateDeclNode442 : PsExpr := (.forallE coreFoundationCandidateDeclNode441 coreFoundationCandidateDeclNode119 coreFoundationCandidateDeclNode137 .instanceImplicit)
private def coreFoundationCandidateDeclNode443 : PsExpr := (.forallE coreFoundationCandidateDeclNode13 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode442 .explicit)
private def coreFoundationCandidateDeclNode444 : PsExpr := (.proj coreFoundationCandidateDeclNode12 0 (.bvar 0))
private def coreFoundationCandidateDeclNode445 : PsExpr := (.lam coreFoundationCandidateDeclNode441 coreFoundationCandidateDeclNode119 coreFoundationCandidateDeclNode444 .instanceImplicit)
private def coreFoundationCandidateDeclNode446 : PsExpr := (.lam coreFoundationCandidateDeclNode13 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode445 .explicit)
private def coreFoundationCandidateDeclNode447 : PsName := (.str .anonymous "decide")
private def coreFoundationCandidateDeclNode448 : PsName := (.str .anonymous "reflects_decide")
private def coreFoundationCandidateDeclNode449 : PsExpr := (.app coreFoundationCandidateDeclNode141 (.bvar 1))
private def coreFoundationCandidateDeclNode450 : PsExpr := (.app coreFoundationCandidateDeclNode118 (.bvar 2))
private def coreFoundationCandidateDeclNode451 : PsExpr := (.forallE coreFoundationCandidateDeclNode448 coreFoundationCandidateDeclNode449 coreFoundationCandidateDeclNode450 .explicit)
private def coreFoundationCandidateDeclNode452 : PsExpr := (.forallE coreFoundationCandidateDeclNode447 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode451 .explicit)
private def coreFoundationCandidateDeclNode453 : PsExpr := (.forallE coreFoundationCandidateDeclNode13 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode452 .implicit)
private def coreFoundationCandidateDeclNode454 : PsName := (.str coreFoundationCandidateDeclNode12 "rec")
private def coreFoundationCandidateDeclNode455 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode119 coreFoundationCandidateDeclNode47 .explicit)
private def coreFoundationCandidateDeclNode456 : PsExpr := (.app coreFoundationCandidateDeclNode141 (.bvar 2))
private def coreFoundationCandidateDeclNode457 : PsExpr := (.app coreFoundationCandidateDeclNode347 (.bvar 3))
private def coreFoundationCandidateDeclNode458 : PsExpr := (.app coreFoundationCandidateDeclNode457 (.bvar 1))
private def coreFoundationCandidateDeclNode459 : PsExpr := (.app coreFoundationCandidateDeclNode458 (.bvar 0))
private def coreFoundationCandidateDeclNode460 : PsExpr := (.app (.bvar 2) coreFoundationCandidateDeclNode459)
private def coreFoundationCandidateDeclNode461 : PsExpr := (.forallE coreFoundationCandidateDeclNode448 coreFoundationCandidateDeclNode456 coreFoundationCandidateDeclNode460 .explicit)
private def coreFoundationCandidateDeclNode462 : PsExpr := (.forallE coreFoundationCandidateDeclNode447 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode461 .explicit)
private def coreFoundationCandidateDeclNode463 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode450 coreFoundationCandidateDeclNode248 .explicit)
private def coreFoundationCandidateDeclNode464 : PsExpr := (.forallE coreFoundationCandidateDeclNode239 coreFoundationCandidateDeclNode462 coreFoundationCandidateDeclNode463 .explicit)
private def coreFoundationCandidateDeclNode465 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode455 coreFoundationCandidateDeclNode464 .implicit)
private def coreFoundationCandidateDeclNode466 : PsExpr := (.forallE coreFoundationCandidateDeclNode13 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode465 .implicit)
private def coreFoundationCandidateDeclNode467 : PsExpr := (.app coreFoundationCandidateDeclNode147 (.bvar 1))
private def coreFoundationCandidateDeclNode468 : PsExpr := (.app coreFoundationCandidateDeclNode467 (.bvar 0))
private def coreFoundationCandidateDeclNode469 : PsExpr := (.app coreFoundationCandidateDeclNode140 coreFoundationCandidateDeclNode468)
private def coreFoundationCandidateDeclNode470 : PsExpr := (.app coreFoundationCandidateDeclNode469 (.bvar 1))
private def coreFoundationCandidateDeclNode471 : PsExpr := (.forallE coreFoundationCandidateDeclNode441 coreFoundationCandidateDeclNode119 coreFoundationCandidateDeclNode470 .instanceImplicit)
private def coreFoundationCandidateDeclNode472 : PsExpr := (.forallE coreFoundationCandidateDeclNode13 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode471 .explicit)
private def coreFoundationCandidateDeclNode473 : PsExpr := (.proj coreFoundationCandidateDeclNode12 1 (.bvar 0))
private def coreFoundationCandidateDeclNode474 : PsExpr := (.lam coreFoundationCandidateDeclNode441 coreFoundationCandidateDeclNode119 coreFoundationCandidateDeclNode473 .instanceImplicit)
private def coreFoundationCandidateDeclNode475 : PsExpr := (.lam coreFoundationCandidateDeclNode13 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode474 .explicit)
private def coreFoundationCandidateDeclNode476 : PsName := (.str coreFoundationCandidateDeclNode16 "rec")
private def coreFoundationCandidateDeclNode477 : PsExpr := (.constE coreFoundationCandidateDeclNode16 [])
private def coreFoundationCandidateDeclNode478 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode477 coreFoundationCandidateDeclNode47 .explicit)
private def coreFoundationCandidateDeclNode479 : PsExpr := (.app (.bvar 1) (.bvar 0))
private def coreFoundationCandidateDeclNode480 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode477 coreFoundationCandidateDeclNode479 .explicit)
private def coreFoundationCandidateDeclNode481 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode478 coreFoundationCandidateDeclNode480 .explicit)
private def coreFoundationCandidateDeclNode482 : PsName := (.str .anonymous "u1")
private def coreFoundationCandidateDeclNode483 : PsName := (.str .anonymous "u2")
private def coreFoundationCandidateDeclNode484 : PsLevel := (.param coreFoundationCandidateDeclNode483)
private def coreFoundationCandidateDeclNode485 : PsExpr := (.sortE coreFoundationCandidateDeclNode484)
private def coreFoundationCandidateDeclNode486 : PsLevel := (.param coreFoundationCandidateDeclNode482)
private def coreFoundationCandidateDeclNode487 : PsExpr := (.sortE coreFoundationCandidateDeclNode486)
private def coreFoundationCandidateDeclNode488 : PsExpr := (.forallE coreFoundationCandidateDeclNode25 (.bvar 1) coreFoundationCandidateDeclNode487 .explicit)
private def coreFoundationCandidateDeclNode489 : PsName := (.str .anonymous "m")
private def coreFoundationCandidateDeclNode490 : PsExpr := (.app (.bvar 0) (.bvar 1))
private def coreFoundationCandidateDeclNode491 : PsExpr := (.constE coreFoundationCandidateDeclNode17 [coreFoundationCandidateDeclNode484])
private def coreFoundationCandidateDeclNode492 : PsExpr := (.app coreFoundationCandidateDeclNode491 (.bvar 4))
private def coreFoundationCandidateDeclNode493 : PsExpr := (.app coreFoundationCandidateDeclNode492 (.bvar 3))
private def coreFoundationCandidateDeclNode494 : PsExpr := (.app coreFoundationCandidateDeclNode493 (.bvar 0))
private def coreFoundationCandidateDeclNode495 : PsExpr := (.app (.bvar 3) (.bvar 1))
private def coreFoundationCandidateDeclNode496 : PsExpr := (.forallE coreFoundationCandidateDeclNode117 coreFoundationCandidateDeclNode494 coreFoundationCandidateDeclNode495 .explicit)
private def coreFoundationCandidateDeclNode497 : PsExpr := (.forallE coreFoundationCandidateDeclNode3 (.bvar 3) coreFoundationCandidateDeclNode496 .implicit)
private def coreFoundationCandidateDeclNode498 : PsExpr := (.forallE coreFoundationCandidateDeclNode489 coreFoundationCandidateDeclNode490 coreFoundationCandidateDeclNode497 .explicit)
private def coreFoundationCandidateDeclNode499 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode488 coreFoundationCandidateDeclNode498 .implicit)
private def coreFoundationCandidateDeclNode500 : PsExpr := (.forallE coreFoundationCandidateDeclNode1 (.bvar 0) coreFoundationCandidateDeclNode499 .implicit)
private def coreFoundationCandidateDeclNode501 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode485 coreFoundationCandidateDeclNode500 .implicit)
private def coreFoundationCandidateDeclNode502 : PsName := (.str coreFoundationCandidateDeclNode17 "rec")
private def coreFoundationCandidateDeclNode503 : PsExpr := (.constE coreFoundationCandidateDeclNode502 [coreFoundationCandidateDeclNode486, coreFoundationCandidateDeclNode484])
private def coreFoundationCandidateDeclNode504 : PsExpr := (.app coreFoundationCandidateDeclNode503 (.bvar 5))
private def coreFoundationCandidateDeclNode505 : PsExpr := (.app coreFoundationCandidateDeclNode504 (.bvar 4))
private def coreFoundationCandidateDeclNode506 : PsName := (.num coreFoundationCandidateDeclNode78 2055208596)
private def coreFoundationCandidateDeclNode507 : PsName := (.str coreFoundationCandidateDeclNode506 "_hygCtx")
private def coreFoundationCandidateDeclNode508 : PsName := (.str coreFoundationCandidateDeclNode507 "_hyg")
private def coreFoundationCandidateDeclNode509 : PsName := (.num coreFoundationCandidateDeclNode508 17)
private def coreFoundationCandidateDeclNode510 : PsName := (.num coreFoundationCandidateDeclNode508 16)
private def coreFoundationCandidateDeclNode511 : PsExpr := (.app coreFoundationCandidateDeclNode491 (.bvar 6))
private def coreFoundationCandidateDeclNode512 : PsExpr := (.app coreFoundationCandidateDeclNode511 (.bvar 5))
private def coreFoundationCandidateDeclNode513 : PsExpr := (.app coreFoundationCandidateDeclNode512 (.bvar 0))
private def coreFoundationCandidateDeclNode514 : PsExpr := (.app (.bvar 5) (.bvar 1))
private def coreFoundationCandidateDeclNode515 : PsExpr := (.lam coreFoundationCandidateDeclNode510 coreFoundationCandidateDeclNode513 coreFoundationCandidateDeclNode514 .explicit)
private def coreFoundationCandidateDeclNode516 : PsExpr := (.lam coreFoundationCandidateDeclNode509 (.bvar 5) coreFoundationCandidateDeclNode515 .explicit)
private def coreFoundationCandidateDeclNode517 : PsExpr := (.app coreFoundationCandidateDeclNode505 coreFoundationCandidateDeclNode516)
private def coreFoundationCandidateDeclNode518 : PsExpr := (.app coreFoundationCandidateDeclNode517 (.bvar 2))
private def coreFoundationCandidateDeclNode519 : PsExpr := (.app coreFoundationCandidateDeclNode518 (.bvar 1))
private def coreFoundationCandidateDeclNode520 : PsExpr := (.app coreFoundationCandidateDeclNode519 (.bvar 0))
private def coreFoundationCandidateDeclNode521 : PsExpr := (.lam coreFoundationCandidateDeclNode117 coreFoundationCandidateDeclNode494 coreFoundationCandidateDeclNode520 .explicit)
private def coreFoundationCandidateDeclNode522 : PsExpr := (.lam coreFoundationCandidateDeclNode3 (.bvar 3) coreFoundationCandidateDeclNode521 .implicit)
private def coreFoundationCandidateDeclNode523 : PsExpr := (.lam coreFoundationCandidateDeclNode489 coreFoundationCandidateDeclNode490 coreFoundationCandidateDeclNode522 .explicit)
private def coreFoundationCandidateDeclNode524 : PsExpr := (.lam coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode488 coreFoundationCandidateDeclNode523 .implicit)
private def coreFoundationCandidateDeclNode525 : PsExpr := (.lam coreFoundationCandidateDeclNode1 (.bvar 0) coreFoundationCandidateDeclNode524 .implicit)
private def coreFoundationCandidateDeclNode526 : PsExpr := (.lam coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode485 coreFoundationCandidateDeclNode525 .implicit)
private def coreFoundationCandidateDeclNode527 : PsExpr := (.constE coreFoundationCandidateDeclNode17 [coreFoundationCandidateDeclNode20])
private def coreFoundationCandidateDeclNode528 : PsExpr := (.app coreFoundationCandidateDeclNode527 (.bvar 2))
private def coreFoundationCandidateDeclNode529 : PsExpr := (.app coreFoundationCandidateDeclNode528 (.bvar 1))
private def coreFoundationCandidateDeclNode530 : PsExpr := (.app coreFoundationCandidateDeclNode529 (.bvar 0))
private def coreFoundationCandidateDeclNode531 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode530 coreFoundationCandidateDeclNode47 .explicit)
private def coreFoundationCandidateDeclNode532 : PsExpr := (.forallE coreFoundationCandidateDeclNode25 (.bvar 1) coreFoundationCandidateDeclNode531 .explicit)
private def coreFoundationCandidateDeclNode533 : PsName := (.str .anonymous "refl")
private def coreFoundationCandidateDeclNode534 : PsExpr := (.constE coreFoundationCandidateDeclNode29 [coreFoundationCandidateDeclNode20])
private def coreFoundationCandidateDeclNode535 : PsExpr := (.app coreFoundationCandidateDeclNode534 (.bvar 2))
private def coreFoundationCandidateDeclNode536 : PsExpr := (.app coreFoundationCandidateDeclNode535 (.bvar 1))
private def coreFoundationCandidateDeclNode537 : PsExpr := (.app coreFoundationCandidateDeclNode490 coreFoundationCandidateDeclNode536)
private def coreFoundationCandidateDeclNode538 : PsExpr := (.app coreFoundationCandidateDeclNode527 (.bvar 4))
private def coreFoundationCandidateDeclNode539 : PsExpr := (.app coreFoundationCandidateDeclNode538 (.bvar 3))
private def coreFoundationCandidateDeclNode540 : PsExpr := (.app coreFoundationCandidateDeclNode539 (.bvar 0))
private def coreFoundationCandidateDeclNode541 : PsExpr := (.app coreFoundationCandidateDeclNode495 (.bvar 0))
private def coreFoundationCandidateDeclNode542 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode540 coreFoundationCandidateDeclNode541 .explicit)
private def coreFoundationCandidateDeclNode543 : PsExpr := (.forallE coreFoundationCandidateDeclNode25 (.bvar 3) coreFoundationCandidateDeclNode542 .implicit)
private def coreFoundationCandidateDeclNode544 : PsExpr := (.forallE coreFoundationCandidateDeclNode533 coreFoundationCandidateDeclNode537 coreFoundationCandidateDeclNode543 .explicit)
private def coreFoundationCandidateDeclNode545 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode532 coreFoundationCandidateDeclNode544 .implicit)
private def coreFoundationCandidateDeclNode546 : PsExpr := (.forallE coreFoundationCandidateDeclNode25 (.bvar 0) coreFoundationCandidateDeclNode545 .implicit)
private def coreFoundationCandidateDeclNode547 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode21 coreFoundationCandidateDeclNode546 .implicit)
private def coreFoundationCandidateDeclNode548 : PsExpr := (.app coreFoundationCandidateDeclNode527 (.bvar 1))
private def coreFoundationCandidateDeclNode549 : PsExpr := (.app coreFoundationCandidateDeclNode548 (.bvar 0))
private def coreFoundationCandidateDeclNode550 : PsExpr := (.app coreFoundationCandidateDeclNode549 (.bvar 0))
private def coreFoundationCandidateDeclNode551 : PsExpr := (.forallE coreFoundationCandidateDeclNode1 (.bvar 0) coreFoundationCandidateDeclNode550 .explicit)
private def coreFoundationCandidateDeclNode552 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode21 coreFoundationCandidateDeclNode551 .implicit)
private def coreFoundationCandidateDeclNode553 : PsExpr := (.constE coreFoundationCandidateDeclNode30 [coreFoundationCandidateDeclNode34, coreFoundationCandidateDeclNode37])
private def coreFoundationCandidateDeclNode554 : PsExpr := (.app coreFoundationCandidateDeclNode553 (.bvar 2))
private def coreFoundationCandidateDeclNode555 : PsExpr := (.app coreFoundationCandidateDeclNode554 (.bvar 1))
private def coreFoundationCandidateDeclNode556 : PsExpr := (.forallE coreFoundationCandidateDeclNode25 (.bvar 1) coreFoundationCandidateDeclNode555 .explicit)
private def coreFoundationCandidateDeclNode557 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode39 coreFoundationCandidateDeclNode556 .implicit)
private def coreFoundationCandidateDeclNode558 : PsExpr := (.forallE coreFoundationCandidateDeclNode33 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode557 .implicit)
private def coreFoundationCandidateDeclNode559 : PsExpr := (.forallE coreFoundationCandidateDeclNode25 (.bvar 0) coreFoundationCandidateDeclNode555 .explicit)
private def coreFoundationCandidateDeclNode560 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode39 coreFoundationCandidateDeclNode559 .implicit)
private def coreFoundationCandidateDeclNode561 : PsExpr := (.forallE coreFoundationCandidateDeclNode33 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode560 .implicit)
private def coreFoundationCandidateDeclNode562 : PsName := (.str coreFoundationCandidateDeclNode30 "rec")
private def coreFoundationCandidateDeclNode563 : PsExpr := (.app coreFoundationCandidateDeclNode553 (.bvar 1))
private def coreFoundationCandidateDeclNode564 : PsExpr := (.app coreFoundationCandidateDeclNode563 (.bvar 0))
private def coreFoundationCandidateDeclNode565 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode564 coreFoundationCandidateDeclNode21 .explicit)
private def coreFoundationCandidateDeclNode566 : PsName := (.str .anonymous "error")
private def coreFoundationCandidateDeclNode567 : PsExpr := (.constE coreFoundationCandidateDeclNode44 [coreFoundationCandidateDeclNode34, coreFoundationCandidateDeclNode37])
private def coreFoundationCandidateDeclNode568 : PsExpr := (.app coreFoundationCandidateDeclNode567 (.bvar 3))
private def coreFoundationCandidateDeclNode569 : PsExpr := (.app coreFoundationCandidateDeclNode568 (.bvar 2))
private def coreFoundationCandidateDeclNode570 : PsExpr := (.app coreFoundationCandidateDeclNode569 (.bvar 0))
private def coreFoundationCandidateDeclNode571 : PsExpr := (.app (.bvar 1) coreFoundationCandidateDeclNode570)
private def coreFoundationCandidateDeclNode572 : PsExpr := (.forallE coreFoundationCandidateDeclNode25 (.bvar 2) coreFoundationCandidateDeclNode571 .explicit)
private def coreFoundationCandidateDeclNode573 : PsName := (.str .anonymous "ok")
private def coreFoundationCandidateDeclNode574 : PsExpr := (.constE coreFoundationCandidateDeclNode45 [coreFoundationCandidateDeclNode34, coreFoundationCandidateDeclNode37])
private def coreFoundationCandidateDeclNode575 : PsExpr := (.app coreFoundationCandidateDeclNode574 (.bvar 4))
private def coreFoundationCandidateDeclNode576 : PsExpr := (.app coreFoundationCandidateDeclNode575 (.bvar 3))
private def coreFoundationCandidateDeclNode577 : PsExpr := (.app coreFoundationCandidateDeclNode576 (.bvar 0))
private def coreFoundationCandidateDeclNode578 : PsExpr := (.app (.bvar 2) coreFoundationCandidateDeclNode577)
private def coreFoundationCandidateDeclNode579 : PsExpr := (.forallE coreFoundationCandidateDeclNode25 (.bvar 2) coreFoundationCandidateDeclNode578 .explicit)
private def coreFoundationCandidateDeclNode580 : PsExpr := (.app coreFoundationCandidateDeclNode553 (.bvar 4))
private def coreFoundationCandidateDeclNode581 : PsExpr := (.app coreFoundationCandidateDeclNode580 (.bvar 3))
private def coreFoundationCandidateDeclNode582 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode581 coreFoundationCandidateDeclNode436 .explicit)
private def coreFoundationCandidateDeclNode583 : PsExpr := (.forallE coreFoundationCandidateDeclNode573 coreFoundationCandidateDeclNode579 coreFoundationCandidateDeclNode582 .explicit)
private def coreFoundationCandidateDeclNode584 : PsExpr := (.forallE coreFoundationCandidateDeclNode566 coreFoundationCandidateDeclNode572 coreFoundationCandidateDeclNode583 .explicit)
private def coreFoundationCandidateDeclNode585 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode565 coreFoundationCandidateDeclNode584 .implicit)
private def coreFoundationCandidateDeclNode586 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode39 coreFoundationCandidateDeclNode585 .implicit)
private def coreFoundationCandidateDeclNode587 : PsExpr := (.forallE coreFoundationCandidateDeclNode33 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode586 .implicit)
private def coreFoundationCandidateDeclNode588 : PsName := (.str .anonymous "w")
private def coreFoundationCandidateDeclNode589 : PsExpr := (.constE coreFoundationCandidateDeclNode46 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode590 : PsExpr := (.app coreFoundationCandidateDeclNode589 (.bvar 3))
private def coreFoundationCandidateDeclNode591 : PsExpr := (.app coreFoundationCandidateDeclNode590 (.bvar 2))
private def coreFoundationCandidateDeclNode592 : PsExpr := (.forallE coreFoundationCandidateDeclNode117 coreFoundationCandidateDeclNode479 coreFoundationCandidateDeclNode591 .explicit)
private def coreFoundationCandidateDeclNode593 : PsExpr := (.forallE coreFoundationCandidateDeclNode588 (.bvar 1) coreFoundationCandidateDeclNode592 .explicit)
private def coreFoundationCandidateDeclNode594 : PsExpr := (.forallE coreFoundationCandidateDeclNode13 coreFoundationCandidateDeclNode48 coreFoundationCandidateDeclNode593 .implicit)
private def coreFoundationCandidateDeclNode595 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode594 .implicit)
private def coreFoundationCandidateDeclNode596 : PsName := (.str coreFoundationCandidateDeclNode46 "rec")
private def coreFoundationCandidateDeclNode597 : PsExpr := (.app coreFoundationCandidateDeclNode589 (.bvar 1))
private def coreFoundationCandidateDeclNode598 : PsExpr := (.app coreFoundationCandidateDeclNode597 (.bvar 0))
private def coreFoundationCandidateDeclNode599 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode598 coreFoundationCandidateDeclNode2 .explicit)
private def coreFoundationCandidateDeclNode600 : PsExpr := (.constE coreFoundationCandidateDeclNode51 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode601 : PsExpr := (.app coreFoundationCandidateDeclNode600 (.bvar 4))
private def coreFoundationCandidateDeclNode602 : PsExpr := (.app coreFoundationCandidateDeclNode601 (.bvar 3))
private def coreFoundationCandidateDeclNode603 : PsExpr := (.app coreFoundationCandidateDeclNode602 (.bvar 1))
private def coreFoundationCandidateDeclNode604 : PsExpr := (.app coreFoundationCandidateDeclNode603 (.bvar 0))
private def coreFoundationCandidateDeclNode605 : PsExpr := (.app (.bvar 2) coreFoundationCandidateDeclNode604)
private def coreFoundationCandidateDeclNode606 : PsExpr := (.forallE coreFoundationCandidateDeclNode117 coreFoundationCandidateDeclNode248 coreFoundationCandidateDeclNode605 .explicit)
private def coreFoundationCandidateDeclNode607 : PsExpr := (.forallE coreFoundationCandidateDeclNode588 (.bvar 2) coreFoundationCandidateDeclNode606 .explicit)
private def coreFoundationCandidateDeclNode608 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode591 coreFoundationCandidateDeclNode248 .explicit)
private def coreFoundationCandidateDeclNode609 : PsExpr := (.forallE coreFoundationCandidateDeclNode239 coreFoundationCandidateDeclNode607 coreFoundationCandidateDeclNode608 .explicit)
private def coreFoundationCandidateDeclNode610 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode599 coreFoundationCandidateDeclNode609 .implicit)
private def coreFoundationCandidateDeclNode611 : PsExpr := (.forallE coreFoundationCandidateDeclNode13 coreFoundationCandidateDeclNode48 coreFoundationCandidateDeclNode610 .implicit)
private def coreFoundationCandidateDeclNode612 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode611 .implicit)
private def coreFoundationCandidateDeclNode613 : PsName := (.str coreFoundationCandidateDeclNode52 "rec")
private def coreFoundationCandidateDeclNode614 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode71 coreFoundationCandidateDeclNode47 .explicit)
private def coreFoundationCandidateDeclNode615 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode71 coreFoundationCandidateDeclNode479 .explicit)
private def coreFoundationCandidateDeclNode616 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode614 coreFoundationCandidateDeclNode615 .explicit)
private def coreFoundationCandidateDeclNode617 : PsName := (.str coreFoundationCandidateDeclNode53 "rec")
private def coreFoundationCandidateDeclNode618 : PsExpr := (.constE coreFoundationCandidateDeclNode53 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode619 : PsExpr := (.app coreFoundationCandidateDeclNode618 (.bvar 3))
private def coreFoundationCandidateDeclNode620 : PsExpr := (.app coreFoundationCandidateDeclNode619 (.bvar 2))
private def coreFoundationCandidateDeclNode621 : PsExpr := (.app coreFoundationCandidateDeclNode620 (.bvar 1))
private def coreFoundationCandidateDeclNode622 : PsExpr := (.app coreFoundationCandidateDeclNode621 (.bvar 0))
private def coreFoundationCandidateDeclNode623 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode622 coreFoundationCandidateDeclNode21 .explicit)
private def coreFoundationCandidateDeclNode624 : PsExpr := (.forallE coreFoundationCandidateDeclNode25 (.bvar 0) coreFoundationCandidateDeclNode623 .explicit)
private def coreFoundationCandidateDeclNode625 : PsExpr := (.forallE coreFoundationCandidateDeclNode54 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode624 .implicit)
private def coreFoundationCandidateDeclNode626 : PsExpr := (.app (.bvar 0) (.bvar 2))
private def coreFoundationCandidateDeclNode627 : PsExpr := (.app coreFoundationCandidateDeclNode626 (.bvar 1))
private def coreFoundationCandidateDeclNode628 : PsExpr := (.constE coreFoundationCandidateDeclNode58 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode629 : PsExpr := (.app coreFoundationCandidateDeclNode628 (.bvar 2))
private def coreFoundationCandidateDeclNode630 : PsExpr := (.app coreFoundationCandidateDeclNode629 (.bvar 1))
private def coreFoundationCandidateDeclNode631 : PsExpr := (.app coreFoundationCandidateDeclNode627 coreFoundationCandidateDeclNode630)
private def coreFoundationCandidateDeclNode632 : PsExpr := (.app coreFoundationCandidateDeclNode618 (.bvar 5))
private def coreFoundationCandidateDeclNode633 : PsExpr := (.app coreFoundationCandidateDeclNode632 (.bvar 4))
private def coreFoundationCandidateDeclNode634 : PsExpr := (.app coreFoundationCandidateDeclNode633 (.bvar 1))
private def coreFoundationCandidateDeclNode635 : PsExpr := (.app coreFoundationCandidateDeclNode634 (.bvar 0))
private def coreFoundationCandidateDeclNode636 : PsExpr := (.app (.bvar 4) (.bvar 2))
private def coreFoundationCandidateDeclNode637 : PsExpr := (.app coreFoundationCandidateDeclNode636 (.bvar 1))
private def coreFoundationCandidateDeclNode638 : PsExpr := (.app coreFoundationCandidateDeclNode637 (.bvar 0))
private def coreFoundationCandidateDeclNode639 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode635 coreFoundationCandidateDeclNode638 .explicit)
private def coreFoundationCandidateDeclNode640 : PsExpr := (.forallE coreFoundationCandidateDeclNode25 (.bvar 0) coreFoundationCandidateDeclNode639 .implicit)
private def coreFoundationCandidateDeclNode641 : PsExpr := (.forallE coreFoundationCandidateDeclNode54 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode640 .implicit)
private def coreFoundationCandidateDeclNode642 : PsExpr := (.forallE coreFoundationCandidateDeclNode533 coreFoundationCandidateDeclNode631 coreFoundationCandidateDeclNode641 .explicit)
private def coreFoundationCandidateDeclNode643 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode625 coreFoundationCandidateDeclNode642 .implicit)
private def coreFoundationCandidateDeclNode644 : PsExpr := (.forallE coreFoundationCandidateDeclNode25 (.bvar 0) coreFoundationCandidateDeclNode643 .implicit)
private def coreFoundationCandidateDeclNode645 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode644 .implicit)
private def coreFoundationCandidateDeclNode646 : PsExpr := (.app coreFoundationCandidateDeclNode618 (.bvar 1))
private def coreFoundationCandidateDeclNode647 : PsExpr := (.app coreFoundationCandidateDeclNode646 (.bvar 0))
private def coreFoundationCandidateDeclNode648 : PsExpr := (.app coreFoundationCandidateDeclNode647 (.bvar 1))
private def coreFoundationCandidateDeclNode649 : PsExpr := (.app coreFoundationCandidateDeclNode648 (.bvar 0))
private def coreFoundationCandidateDeclNode650 : PsExpr := (.forallE coreFoundationCandidateDeclNode1 (.bvar 0) coreFoundationCandidateDeclNode649 .explicit)
private def coreFoundationCandidateDeclNode651 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode650 .implicit)
private def coreFoundationCandidateDeclNode652 : PsName := (.str .anonymous "head")
private def coreFoundationCandidateDeclNode653 : PsName := (.str .anonymous "tail")
private def coreFoundationCandidateDeclNode654 : PsExpr := (.constE coreFoundationCandidateDeclNode59 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode655 : PsExpr := (.app coreFoundationCandidateDeclNode654 (.bvar 1))
private def coreFoundationCandidateDeclNode656 : PsExpr := (.app coreFoundationCandidateDeclNode654 (.bvar 2))
private def coreFoundationCandidateDeclNode657 : PsExpr := (.forallE coreFoundationCandidateDeclNode653 coreFoundationCandidateDeclNode655 coreFoundationCandidateDeclNode656 .explicit)
private def coreFoundationCandidateDeclNode658 : PsExpr := (.forallE coreFoundationCandidateDeclNode652 (.bvar 0) coreFoundationCandidateDeclNode657 .explicit)
private def coreFoundationCandidateDeclNode659 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode658 .implicit)
private def coreFoundationCandidateDeclNode660 : PsExpr := (.app coreFoundationCandidateDeclNode654 (.bvar 0))
private def coreFoundationCandidateDeclNode661 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode660 .implicit)
private def coreFoundationCandidateDeclNode662 : PsName := (.str coreFoundationCandidateDeclNode59 "rec")
private def coreFoundationCandidateDeclNode663 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode660 coreFoundationCandidateDeclNode21 .explicit)
private def coreFoundationCandidateDeclNode664 : PsName := (.str .anonymous "nil")
private def coreFoundationCandidateDeclNode665 : PsExpr := (.constE coreFoundationCandidateDeclNode61 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode666 : PsExpr := (.app coreFoundationCandidateDeclNode665 (.bvar 1))
private def coreFoundationCandidateDeclNode667 : PsExpr := (.app (.bvar 0) coreFoundationCandidateDeclNode666)
private def coreFoundationCandidateDeclNode668 : PsName := (.str .anonymous "cons")
private def coreFoundationCandidateDeclNode669 : PsExpr := (.app coreFoundationCandidateDeclNode654 (.bvar 3))
private def coreFoundationCandidateDeclNode670 : PsName := (.str .anonymous "tail_ih")
private def coreFoundationCandidateDeclNode671 : PsExpr := (.constE coreFoundationCandidateDeclNode62 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode672 : PsExpr := (.app coreFoundationCandidateDeclNode671 (.bvar 5))
private def coreFoundationCandidateDeclNode673 : PsExpr := (.app coreFoundationCandidateDeclNode672 (.bvar 2))
private def coreFoundationCandidateDeclNode674 : PsExpr := (.app coreFoundationCandidateDeclNode673 (.bvar 1))
private def coreFoundationCandidateDeclNode675 : PsExpr := (.app (.bvar 4) coreFoundationCandidateDeclNode674)
private def coreFoundationCandidateDeclNode676 : PsExpr := (.forallE coreFoundationCandidateDeclNode670 coreFoundationCandidateDeclNode436 coreFoundationCandidateDeclNode675 .explicit)
private def coreFoundationCandidateDeclNode677 : PsExpr := (.forallE coreFoundationCandidateDeclNode653 coreFoundationCandidateDeclNode669 coreFoundationCandidateDeclNode676 .explicit)
private def coreFoundationCandidateDeclNode678 : PsExpr := (.forallE coreFoundationCandidateDeclNode652 (.bvar 2) coreFoundationCandidateDeclNode677 .explicit)
private def coreFoundationCandidateDeclNode679 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode669 coreFoundationCandidateDeclNode436 .explicit)
private def coreFoundationCandidateDeclNode680 : PsExpr := (.forallE coreFoundationCandidateDeclNode668 coreFoundationCandidateDeclNode678 coreFoundationCandidateDeclNode679 .explicit)
private def coreFoundationCandidateDeclNode681 : PsExpr := (.forallE coreFoundationCandidateDeclNode664 coreFoundationCandidateDeclNode667 coreFoundationCandidateDeclNode680 .explicit)
private def coreFoundationCandidateDeclNode682 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode663 coreFoundationCandidateDeclNode681 .implicit)
private def coreFoundationCandidateDeclNode683 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode682 .implicit)
private def coreFoundationCandidateDeclNode684 : PsName := (.str coreFoundationCandidateDeclNode63 "rec")
private def coreFoundationCandidateDeclNode685 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode83 coreFoundationCandidateDeclNode47 .explicit)
private def coreFoundationCandidateDeclNode686 : PsName := (.str .anonymous "zero")
private def coreFoundationCandidateDeclNode687 : PsExpr := (.constE coreFoundationCandidateDeclNode64 [])
private def coreFoundationCandidateDeclNode688 : PsExpr := (.app (.bvar 0) coreFoundationCandidateDeclNode687)
private def coreFoundationCandidateDeclNode689 : PsName := (.str .anonymous "succ")
private def coreFoundationCandidateDeclNode690 : PsName := (.str .anonymous "n_ih")
private def coreFoundationCandidateDeclNode691 : PsExpr := (.constE coreFoundationCandidateDeclNode65 [])
private def coreFoundationCandidateDeclNode692 : PsExpr := (.app coreFoundationCandidateDeclNode691 (.bvar 1))
private def coreFoundationCandidateDeclNode693 : PsExpr := (.app (.bvar 3) coreFoundationCandidateDeclNode692)
private def coreFoundationCandidateDeclNode694 : PsExpr := (.forallE coreFoundationCandidateDeclNode690 coreFoundationCandidateDeclNode248 coreFoundationCandidateDeclNode693 .explicit)
private def coreFoundationCandidateDeclNode695 : PsExpr := (.forallE coreFoundationCandidateDeclNode169 coreFoundationCandidateDeclNode83 coreFoundationCandidateDeclNode694 .explicit)
private def coreFoundationCandidateDeclNode696 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode83 coreFoundationCandidateDeclNode436 .explicit)
private def coreFoundationCandidateDeclNode697 : PsExpr := (.forallE coreFoundationCandidateDeclNode689 coreFoundationCandidateDeclNode695 coreFoundationCandidateDeclNode696 .explicit)
private def coreFoundationCandidateDeclNode698 : PsExpr := (.forallE coreFoundationCandidateDeclNode686 coreFoundationCandidateDeclNode688 coreFoundationCandidateDeclNode697 .explicit)
private def coreFoundationCandidateDeclNode699 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode685 coreFoundationCandidateDeclNode698 .implicit)
private def coreFoundationCandidateDeclNode700 : PsExpr := (.forallE coreFoundationCandidateDeclNode169 coreFoundationCandidateDeclNode83 coreFoundationCandidateDeclNode83 .explicit)
private def coreFoundationCandidateDeclNode701 : PsName := (.str .anonymous "val")
private def coreFoundationCandidateDeclNode702 : PsExpr := (.constE coreFoundationCandidateDeclNode66 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode703 : PsExpr := (.app coreFoundationCandidateDeclNode702 (.bvar 1))
private def coreFoundationCandidateDeclNode704 : PsExpr := (.forallE coreFoundationCandidateDeclNode701 (.bvar 0) coreFoundationCandidateDeclNode703 .explicit)
private def coreFoundationCandidateDeclNode705 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode704 .implicit)
private def coreFoundationCandidateDeclNode706 : PsName := (.str coreFoundationCandidateDeclNode66 "rec")
private def coreFoundationCandidateDeclNode707 : PsExpr := (.app coreFoundationCandidateDeclNode702 (.bvar 0))
private def coreFoundationCandidateDeclNode708 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode707 coreFoundationCandidateDeclNode2 .explicit)
private def coreFoundationCandidateDeclNode709 : PsExpr := (.constE coreFoundationCandidateDeclNode68 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode710 : PsExpr := (.app coreFoundationCandidateDeclNode709 (.bvar 2))
private def coreFoundationCandidateDeclNode711 : PsExpr := (.app coreFoundationCandidateDeclNode710 (.bvar 0))
private def coreFoundationCandidateDeclNode712 : PsExpr := (.app (.bvar 1) coreFoundationCandidateDeclNode711)
private def coreFoundationCandidateDeclNode713 : PsExpr := (.forallE coreFoundationCandidateDeclNode701 (.bvar 1) coreFoundationCandidateDeclNode712 .explicit)
private def coreFoundationCandidateDeclNode714 : PsExpr := (.app coreFoundationCandidateDeclNode702 (.bvar 2))
private def coreFoundationCandidateDeclNode715 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode714 coreFoundationCandidateDeclNode248 .explicit)
private def coreFoundationCandidateDeclNode716 : PsExpr := (.forallE coreFoundationCandidateDeclNode239 coreFoundationCandidateDeclNode713 coreFoundationCandidateDeclNode715 .explicit)
private def coreFoundationCandidateDeclNode717 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode708 coreFoundationCandidateDeclNode716 .implicit)
private def coreFoundationCandidateDeclNode718 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode717 .implicit)
private def coreFoundationCandidateDeclNode719 : PsName := (.str .anonymous "ofNat")
private def coreFoundationCandidateDeclNode720 : PsExpr := (.constE coreFoundationCandidateDeclNode74 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode721 : PsExpr := (.app coreFoundationCandidateDeclNode720 (.bvar 2))
private def coreFoundationCandidateDeclNode722 : PsExpr := (.app coreFoundationCandidateDeclNode721 (.bvar 1))
private def coreFoundationCandidateDeclNode723 : PsExpr := (.forallE coreFoundationCandidateDeclNode719 (.bvar 1) coreFoundationCandidateDeclNode722 .explicit)
private def coreFoundationCandidateDeclNode724 : PsExpr := (.forallE coreFoundationCandidateDeclNode82 coreFoundationCandidateDeclNode83 coreFoundationCandidateDeclNode723 .implicit)
private def coreFoundationCandidateDeclNode725 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode724 .implicit)
private def coreFoundationCandidateDeclNode726 : PsName := (.str coreFoundationCandidateDeclNode74 "ofNat")
private def coreFoundationCandidateDeclNode727 : PsExpr := (.app coreFoundationCandidateDeclNode720 (.bvar 1))
private def coreFoundationCandidateDeclNode728 : PsExpr := (.app coreFoundationCandidateDeclNode727 (.bvar 0))
private def coreFoundationCandidateDeclNode729 : PsExpr := (.forallE coreFoundationCandidateDeclNode441 coreFoundationCandidateDeclNode728 (.bvar 2) .instanceImplicit)
private def coreFoundationCandidateDeclNode730 : PsExpr := (.forallE coreFoundationCandidateDeclNode82 coreFoundationCandidateDeclNode83 coreFoundationCandidateDeclNode729 .explicit)
private def coreFoundationCandidateDeclNode731 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode730 .implicit)
private def coreFoundationCandidateDeclNode732 : PsExpr := (.proj coreFoundationCandidateDeclNode74 0 (.bvar 0))
private def coreFoundationCandidateDeclNode733 : PsExpr := (.lam coreFoundationCandidateDeclNode441 coreFoundationCandidateDeclNode728 coreFoundationCandidateDeclNode732 .instanceImplicit)
private def coreFoundationCandidateDeclNode734 : PsExpr := (.lam coreFoundationCandidateDeclNode82 coreFoundationCandidateDeclNode83 coreFoundationCandidateDeclNode733 .explicit)
private def coreFoundationCandidateDeclNode735 : PsExpr := (.lam coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode734 .explicit)
private def coreFoundationCandidateDeclNode736 : PsName := (.str coreFoundationCandidateDeclNode74 "rec")
private def coreFoundationCandidateDeclNode737 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode728 coreFoundationCandidateDeclNode21 .explicit)
private def coreFoundationCandidateDeclNode738 : PsName := (.str .anonymous "mk")
private def coreFoundationCandidateDeclNode739 : PsExpr := (.constE coreFoundationCandidateDeclNode86 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode740 : PsExpr := (.app coreFoundationCandidateDeclNode739 (.bvar 3))
private def coreFoundationCandidateDeclNode741 : PsExpr := (.app coreFoundationCandidateDeclNode740 (.bvar 2))
private def coreFoundationCandidateDeclNode742 : PsExpr := (.app coreFoundationCandidateDeclNode741 (.bvar 0))
private def coreFoundationCandidateDeclNode743 : PsExpr := (.app (.bvar 1) coreFoundationCandidateDeclNode742)
private def coreFoundationCandidateDeclNode744 : PsExpr := (.forallE coreFoundationCandidateDeclNode719 (.bvar 2) coreFoundationCandidateDeclNode743 .explicit)
private def coreFoundationCandidateDeclNode745 : PsExpr := (.app coreFoundationCandidateDeclNode720 (.bvar 3))
private def coreFoundationCandidateDeclNode746 : PsExpr := (.app coreFoundationCandidateDeclNode745 (.bvar 2))
private def coreFoundationCandidateDeclNode747 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode746 coreFoundationCandidateDeclNode248 .explicit)
private def coreFoundationCandidateDeclNode748 : PsExpr := (.forallE coreFoundationCandidateDeclNode738 coreFoundationCandidateDeclNode744 coreFoundationCandidateDeclNode747 .explicit)
private def coreFoundationCandidateDeclNode749 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode737 coreFoundationCandidateDeclNode748 .implicit)
private def coreFoundationCandidateDeclNode750 : PsExpr := (.forallE coreFoundationCandidateDeclNode82 coreFoundationCandidateDeclNode83 coreFoundationCandidateDeclNode749 .implicit)
private def coreFoundationCandidateDeclNode751 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode750 .implicit)
private def coreFoundationCandidateDeclNode752 : PsExpr := (.constE coreFoundationCandidateDeclNode87 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode753 : PsExpr := (.app coreFoundationCandidateDeclNode752 (.bvar 0))
private def coreFoundationCandidateDeclNode754 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode753 .implicit)
private def coreFoundationCandidateDeclNode755 : PsName := (.str coreFoundationCandidateDeclNode87 "rec")
private def coreFoundationCandidateDeclNode756 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode753 coreFoundationCandidateDeclNode21 .explicit)
private def coreFoundationCandidateDeclNode757 : PsName := (.str .anonymous "none")
private def coreFoundationCandidateDeclNode758 : PsExpr := (.constE coreFoundationCandidateDeclNode88 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode759 : PsExpr := (.app coreFoundationCandidateDeclNode758 (.bvar 1))
private def coreFoundationCandidateDeclNode760 : PsExpr := (.app (.bvar 0) coreFoundationCandidateDeclNode759)
private def coreFoundationCandidateDeclNode761 : PsName := (.str .anonymous "some")
private def coreFoundationCandidateDeclNode762 : PsExpr := (.constE coreFoundationCandidateDeclNode89 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode763 : PsExpr := (.app coreFoundationCandidateDeclNode762 (.bvar 3))
private def coreFoundationCandidateDeclNode764 : PsExpr := (.app coreFoundationCandidateDeclNode763 (.bvar 0))
private def coreFoundationCandidateDeclNode765 : PsExpr := (.app (.bvar 2) coreFoundationCandidateDeclNode764)
private def coreFoundationCandidateDeclNode766 : PsExpr := (.forallE coreFoundationCandidateDeclNode701 (.bvar 2) coreFoundationCandidateDeclNode765 .explicit)
private def coreFoundationCandidateDeclNode767 : PsExpr := (.app coreFoundationCandidateDeclNode752 (.bvar 3))
private def coreFoundationCandidateDeclNode768 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode767 coreFoundationCandidateDeclNode436 .explicit)
private def coreFoundationCandidateDeclNode769 : PsExpr := (.forallE coreFoundationCandidateDeclNode761 coreFoundationCandidateDeclNode766 coreFoundationCandidateDeclNode768 .explicit)
private def coreFoundationCandidateDeclNode770 : PsExpr := (.forallE coreFoundationCandidateDeclNode757 coreFoundationCandidateDeclNode760 coreFoundationCandidateDeclNode769 .explicit)
private def coreFoundationCandidateDeclNode771 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode756 coreFoundationCandidateDeclNode770 .implicit)
private def coreFoundationCandidateDeclNode772 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode771 .implicit)
private def coreFoundationCandidateDeclNode773 : PsExpr := (.app coreFoundationCandidateDeclNode752 (.bvar 1))
private def coreFoundationCandidateDeclNode774 : PsExpr := (.forallE coreFoundationCandidateDeclNode701 (.bvar 0) coreFoundationCandidateDeclNode773 .explicit)
private def coreFoundationCandidateDeclNode775 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode774 .implicit)
private def coreFoundationCandidateDeclNode776 : PsExpr := (.constE coreFoundationCandidateDeclNode90 [])
private def coreFoundationCandidateDeclNode777 : PsExpr := (.app coreFoundationCandidateDeclNode776 (.bvar 2))
private def coreFoundationCandidateDeclNode778 : PsExpr := (.app coreFoundationCandidateDeclNode777 (.bvar 1))
private def coreFoundationCandidateDeclNode779 : PsExpr := (.forallE coreFoundationCandidateDeclNode117 (.bvar 1) coreFoundationCandidateDeclNode778 .explicit)
private def coreFoundationCandidateDeclNode780 : PsExpr := (.forallE coreFoundationCandidateDeclNode3 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode779 .implicit)
private def coreFoundationCandidateDeclNode781 : PsExpr := (.forallE coreFoundationCandidateDeclNode1 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode780 .implicit)
private def coreFoundationCandidateDeclNode782 : PsExpr := (.forallE coreFoundationCandidateDeclNode117 (.bvar 0) coreFoundationCandidateDeclNode778 .explicit)
private def coreFoundationCandidateDeclNode783 : PsExpr := (.forallE coreFoundationCandidateDeclNode3 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode782 .implicit)
private def coreFoundationCandidateDeclNode784 : PsExpr := (.forallE coreFoundationCandidateDeclNode1 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode783 .implicit)
private def coreFoundationCandidateDeclNode785 : PsName := (.str coreFoundationCandidateDeclNode90 "rec")
private def coreFoundationCandidateDeclNode786 : PsExpr := (.app coreFoundationCandidateDeclNode776 (.bvar 1))
private def coreFoundationCandidateDeclNode787 : PsExpr := (.app coreFoundationCandidateDeclNode786 (.bvar 0))
private def coreFoundationCandidateDeclNode788 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode787 coreFoundationCandidateDeclNode2 .explicit)
private def coreFoundationCandidateDeclNode789 : PsName := (.str .anonymous "inl")
private def coreFoundationCandidateDeclNode790 : PsExpr := (.constE coreFoundationCandidateDeclNode91 [])
private def coreFoundationCandidateDeclNode791 : PsExpr := (.app coreFoundationCandidateDeclNode790 (.bvar 3))
private def coreFoundationCandidateDeclNode792 : PsExpr := (.app coreFoundationCandidateDeclNode791 (.bvar 2))
private def coreFoundationCandidateDeclNode793 : PsExpr := (.app coreFoundationCandidateDeclNode792 (.bvar 0))
private def coreFoundationCandidateDeclNode794 : PsExpr := (.app (.bvar 1) coreFoundationCandidateDeclNode793)
private def coreFoundationCandidateDeclNode795 : PsExpr := (.forallE coreFoundationCandidateDeclNode117 (.bvar 2) coreFoundationCandidateDeclNode794 .explicit)
private def coreFoundationCandidateDeclNode796 : PsName := (.str .anonymous "inr")
private def coreFoundationCandidateDeclNode797 : PsExpr := (.constE coreFoundationCandidateDeclNode92 [])
private def coreFoundationCandidateDeclNode798 : PsExpr := (.app coreFoundationCandidateDeclNode797 (.bvar 4))
private def coreFoundationCandidateDeclNode799 : PsExpr := (.app coreFoundationCandidateDeclNode798 (.bvar 3))
private def coreFoundationCandidateDeclNode800 : PsExpr := (.app coreFoundationCandidateDeclNode799 (.bvar 0))
private def coreFoundationCandidateDeclNode801 : PsExpr := (.app (.bvar 2) coreFoundationCandidateDeclNode800)
private def coreFoundationCandidateDeclNode802 : PsExpr := (.forallE coreFoundationCandidateDeclNode117 (.bvar 2) coreFoundationCandidateDeclNode801 .explicit)
private def coreFoundationCandidateDeclNode803 : PsExpr := (.app coreFoundationCandidateDeclNode776 (.bvar 4))
private def coreFoundationCandidateDeclNode804 : PsExpr := (.app coreFoundationCandidateDeclNode803 (.bvar 3))
private def coreFoundationCandidateDeclNode805 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode804 coreFoundationCandidateDeclNode436 .explicit)
private def coreFoundationCandidateDeclNode806 : PsExpr := (.forallE coreFoundationCandidateDeclNode796 coreFoundationCandidateDeclNode802 coreFoundationCandidateDeclNode805 .explicit)
private def coreFoundationCandidateDeclNode807 : PsExpr := (.forallE coreFoundationCandidateDeclNode789 coreFoundationCandidateDeclNode795 coreFoundationCandidateDeclNode806 .explicit)
private def coreFoundationCandidateDeclNode808 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode788 coreFoundationCandidateDeclNode807 .implicit)
private def coreFoundationCandidateDeclNode809 : PsExpr := (.forallE coreFoundationCandidateDeclNode3 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode808 .implicit)
private def coreFoundationCandidateDeclNode810 : PsExpr := (.forallE coreFoundationCandidateDeclNode1 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode809 .implicit)
private def coreFoundationCandidateDeclNode811 : PsName := (.str coreFoundationCandidateDeclNode93 "rec")
private def coreFoundationCandidateDeclNode812 : PsExpr := (.constE coreFoundationCandidateDeclNode93 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode813 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode812 coreFoundationCandidateDeclNode21 .explicit)
private def coreFoundationCandidateDeclNode814 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode812 coreFoundationCandidateDeclNode479 .explicit)
private def coreFoundationCandidateDeclNode815 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode813 coreFoundationCandidateDeclNode814 .explicit)
private def coreFoundationCandidateDeclNode816 : PsName := (.str .anonymous "fst")
private def coreFoundationCandidateDeclNode817 : PsName := (.str .anonymous "snd")
private def coreFoundationCandidateDeclNode818 : PsExpr := (.constE coreFoundationCandidateDeclNode94 [coreFoundationCandidateDeclNode34, coreFoundationCandidateDeclNode37])
private def coreFoundationCandidateDeclNode819 : PsExpr := (.app coreFoundationCandidateDeclNode818 (.bvar 3))
private def coreFoundationCandidateDeclNode820 : PsExpr := (.app coreFoundationCandidateDeclNode819 (.bvar 2))
private def coreFoundationCandidateDeclNode821 : PsExpr := (.forallE coreFoundationCandidateDeclNode817 (.bvar 1) coreFoundationCandidateDeclNode820 .explicit)
private def coreFoundationCandidateDeclNode822 : PsExpr := (.forallE coreFoundationCandidateDeclNode816 (.bvar 1) coreFoundationCandidateDeclNode821 .explicit)
private def coreFoundationCandidateDeclNode823 : PsExpr := (.forallE coreFoundationCandidateDeclNode54 coreFoundationCandidateDeclNode95 coreFoundationCandidateDeclNode822 .implicit)
private def coreFoundationCandidateDeclNode824 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode823 .implicit)
private def coreFoundationCandidateDeclNode825 : PsName := (.str coreFoundationCandidateDeclNode94 "rec")
private def coreFoundationCandidateDeclNode826 : PsExpr := (.app coreFoundationCandidateDeclNode818 (.bvar 1))
private def coreFoundationCandidateDeclNode827 : PsExpr := (.app coreFoundationCandidateDeclNode826 (.bvar 0))
private def coreFoundationCandidateDeclNode828 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode827 coreFoundationCandidateDeclNode21 .explicit)
private def coreFoundationCandidateDeclNode829 : PsExpr := (.constE coreFoundationCandidateDeclNode101 [coreFoundationCandidateDeclNode34, coreFoundationCandidateDeclNode37])
private def coreFoundationCandidateDeclNode830 : PsExpr := (.app coreFoundationCandidateDeclNode829 (.bvar 4))
private def coreFoundationCandidateDeclNode831 : PsExpr := (.app coreFoundationCandidateDeclNode830 (.bvar 3))
private def coreFoundationCandidateDeclNode832 : PsExpr := (.app coreFoundationCandidateDeclNode831 (.bvar 1))
private def coreFoundationCandidateDeclNode833 : PsExpr := (.app coreFoundationCandidateDeclNode832 (.bvar 0))
private def coreFoundationCandidateDeclNode834 : PsExpr := (.app (.bvar 2) coreFoundationCandidateDeclNode833)
private def coreFoundationCandidateDeclNode835 : PsExpr := (.forallE coreFoundationCandidateDeclNode817 (.bvar 2) coreFoundationCandidateDeclNode834 .explicit)
private def coreFoundationCandidateDeclNode836 : PsExpr := (.forallE coreFoundationCandidateDeclNode816 (.bvar 2) coreFoundationCandidateDeclNode835 .explicit)
private def coreFoundationCandidateDeclNode837 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode820 coreFoundationCandidateDeclNode248 .explicit)
private def coreFoundationCandidateDeclNode838 : PsExpr := (.forallE coreFoundationCandidateDeclNode738 coreFoundationCandidateDeclNode836 coreFoundationCandidateDeclNode837 .explicit)
private def coreFoundationCandidateDeclNode839 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode828 coreFoundationCandidateDeclNode838 .implicit)
private def coreFoundationCandidateDeclNode840 : PsExpr := (.forallE coreFoundationCandidateDeclNode54 coreFoundationCandidateDeclNode95 coreFoundationCandidateDeclNode839 .implicit)
private def coreFoundationCandidateDeclNode841 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode47 coreFoundationCandidateDeclNode840 .implicit)
private def coreFoundationCandidateDeclNode842 : PsName := (.str coreFoundationCandidateDeclNode102 "rec")
private def coreFoundationCandidateDeclNode843 : PsExpr := (.constE coreFoundationCandidateDeclNode102 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode844 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode843 coreFoundationCandidateDeclNode21 .explicit)
private def coreFoundationCandidateDeclNode845 : PsName := (.str .anonymous "unit")
private def coreFoundationCandidateDeclNode846 : PsExpr := (.constE coreFoundationCandidateDeclNode103 [coreFoundationCandidateDeclNode34])
private def coreFoundationCandidateDeclNode847 : PsExpr := (.app (.bvar 0) coreFoundationCandidateDeclNode846)
private def coreFoundationCandidateDeclNode848 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode843 coreFoundationCandidateDeclNode248 .explicit)
private def coreFoundationCandidateDeclNode849 : PsExpr := (.forallE coreFoundationCandidateDeclNode845 coreFoundationCandidateDeclNode847 coreFoundationCandidateDeclNode848 .explicit)
private def coreFoundationCandidateDeclNode850 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode844 coreFoundationCandidateDeclNode849 .implicit)
private def coreFoundationCandidateDeclNode851 : PsExpr := (.constE coreFoundationCandidateDeclNode104 [coreFoundationCandidateDeclNode34, coreFoundationCandidateDeclNode37])
private def coreFoundationCandidateDeclNode852 : PsExpr := (.app coreFoundationCandidateDeclNode851 (.bvar 3))
private def coreFoundationCandidateDeclNode853 : PsExpr := (.app coreFoundationCandidateDeclNode852 (.bvar 2))
private def coreFoundationCandidateDeclNode854 : PsExpr := (.forallE coreFoundationCandidateDeclNode817 (.bvar 1) coreFoundationCandidateDeclNode853 .explicit)
private def coreFoundationCandidateDeclNode855 : PsExpr := (.forallE coreFoundationCandidateDeclNode816 (.bvar 1) coreFoundationCandidateDeclNode854 .explicit)
private def coreFoundationCandidateDeclNode856 : PsExpr := (.forallE coreFoundationCandidateDeclNode54 coreFoundationCandidateDeclNode39 coreFoundationCandidateDeclNode855 .implicit)
private def coreFoundationCandidateDeclNode857 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode856 .implicit)
private def coreFoundationCandidateDeclNode858 : PsName := (.str coreFoundationCandidateDeclNode104 "rec")
private def coreFoundationCandidateDeclNode859 : PsExpr := (.app coreFoundationCandidateDeclNode851 (.bvar 1))
private def coreFoundationCandidateDeclNode860 : PsExpr := (.app coreFoundationCandidateDeclNode859 (.bvar 0))
private def coreFoundationCandidateDeclNode861 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode860 coreFoundationCandidateDeclNode21 .explicit)
private def coreFoundationCandidateDeclNode862 : PsExpr := (.constE coreFoundationCandidateDeclNode107 [coreFoundationCandidateDeclNode34, coreFoundationCandidateDeclNode37])
private def coreFoundationCandidateDeclNode863 : PsExpr := (.app coreFoundationCandidateDeclNode862 (.bvar 4))
private def coreFoundationCandidateDeclNode864 : PsExpr := (.app coreFoundationCandidateDeclNode863 (.bvar 3))
private def coreFoundationCandidateDeclNode865 : PsExpr := (.app coreFoundationCandidateDeclNode864 (.bvar 1))
private def coreFoundationCandidateDeclNode866 : PsExpr := (.app coreFoundationCandidateDeclNode865 (.bvar 0))
private def coreFoundationCandidateDeclNode867 : PsExpr := (.app (.bvar 2) coreFoundationCandidateDeclNode866)
private def coreFoundationCandidateDeclNode868 : PsExpr := (.forallE coreFoundationCandidateDeclNode817 (.bvar 2) coreFoundationCandidateDeclNode867 .explicit)
private def coreFoundationCandidateDeclNode869 : PsExpr := (.forallE coreFoundationCandidateDeclNode816 (.bvar 2) coreFoundationCandidateDeclNode868 .explicit)
private def coreFoundationCandidateDeclNode870 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode853 coreFoundationCandidateDeclNode248 .explicit)
private def coreFoundationCandidateDeclNode871 : PsExpr := (.forallE coreFoundationCandidateDeclNode738 coreFoundationCandidateDeclNode869 coreFoundationCandidateDeclNode870 .explicit)
private def coreFoundationCandidateDeclNode872 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode861 coreFoundationCandidateDeclNode871 .implicit)
private def coreFoundationCandidateDeclNode873 : PsExpr := (.forallE coreFoundationCandidateDeclNode54 coreFoundationCandidateDeclNode39 coreFoundationCandidateDeclNode872 .implicit)
private def coreFoundationCandidateDeclNode874 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode873 .implicit)
private def coreFoundationCandidateDeclNode875 : PsExpr := (.constE coreFoundationCandidateDeclNode108 [coreFoundationCandidateDeclNode34, coreFoundationCandidateDeclNode37])
private def coreFoundationCandidateDeclNode876 : PsExpr := (.app coreFoundationCandidateDeclNode875 (.bvar 2))
private def coreFoundationCandidateDeclNode877 : PsExpr := (.app coreFoundationCandidateDeclNode876 (.bvar 1))
private def coreFoundationCandidateDeclNode878 : PsExpr := (.forallE coreFoundationCandidateDeclNode701 (.bvar 1) coreFoundationCandidateDeclNode877 .explicit)
private def coreFoundationCandidateDeclNode879 : PsExpr := (.forallE coreFoundationCandidateDeclNode54 coreFoundationCandidateDeclNode39 coreFoundationCandidateDeclNode878 .implicit)
private def coreFoundationCandidateDeclNode880 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode879 .implicit)
private def coreFoundationCandidateDeclNode881 : PsExpr := (.forallE coreFoundationCandidateDeclNode701 (.bvar 0) coreFoundationCandidateDeclNode877 .explicit)
private def coreFoundationCandidateDeclNode882 : PsExpr := (.forallE coreFoundationCandidateDeclNode54 coreFoundationCandidateDeclNode39 coreFoundationCandidateDeclNode881 .implicit)
private def coreFoundationCandidateDeclNode883 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode882 .implicit)
private def coreFoundationCandidateDeclNode884 : PsName := (.str coreFoundationCandidateDeclNode108 "rec")
private def coreFoundationCandidateDeclNode885 : PsExpr := (.app coreFoundationCandidateDeclNode875 (.bvar 1))
private def coreFoundationCandidateDeclNode886 : PsExpr := (.app coreFoundationCandidateDeclNode885 (.bvar 0))
private def coreFoundationCandidateDeclNode887 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode886 coreFoundationCandidateDeclNode21 .explicit)
private def coreFoundationCandidateDeclNode888 : PsExpr := (.constE coreFoundationCandidateDeclNode109 [coreFoundationCandidateDeclNode34, coreFoundationCandidateDeclNode37])
private def coreFoundationCandidateDeclNode889 : PsExpr := (.app coreFoundationCandidateDeclNode888 (.bvar 3))
private def coreFoundationCandidateDeclNode890 : PsExpr := (.app coreFoundationCandidateDeclNode889 (.bvar 2))
private def coreFoundationCandidateDeclNode891 : PsExpr := (.app coreFoundationCandidateDeclNode890 (.bvar 0))
private def coreFoundationCandidateDeclNode892 : PsExpr := (.app (.bvar 1) coreFoundationCandidateDeclNode891)
private def coreFoundationCandidateDeclNode893 : PsExpr := (.forallE coreFoundationCandidateDeclNode701 (.bvar 2) coreFoundationCandidateDeclNode892 .explicit)
private def coreFoundationCandidateDeclNode894 : PsExpr := (.constE coreFoundationCandidateDeclNode110 [coreFoundationCandidateDeclNode34, coreFoundationCandidateDeclNode37])
private def coreFoundationCandidateDeclNode895 : PsExpr := (.app coreFoundationCandidateDeclNode894 (.bvar 4))
private def coreFoundationCandidateDeclNode896 : PsExpr := (.app coreFoundationCandidateDeclNode895 (.bvar 3))
private def coreFoundationCandidateDeclNode897 : PsExpr := (.app coreFoundationCandidateDeclNode896 (.bvar 0))
private def coreFoundationCandidateDeclNode898 : PsExpr := (.app (.bvar 2) coreFoundationCandidateDeclNode897)
private def coreFoundationCandidateDeclNode899 : PsExpr := (.forallE coreFoundationCandidateDeclNode701 (.bvar 2) coreFoundationCandidateDeclNode898 .explicit)
private def coreFoundationCandidateDeclNode900 : PsExpr := (.app coreFoundationCandidateDeclNode875 (.bvar 4))
private def coreFoundationCandidateDeclNode901 : PsExpr := (.app coreFoundationCandidateDeclNode900 (.bvar 3))
private def coreFoundationCandidateDeclNode902 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode901 coreFoundationCandidateDeclNode436 .explicit)
private def coreFoundationCandidateDeclNode903 : PsExpr := (.forallE coreFoundationCandidateDeclNode796 coreFoundationCandidateDeclNode899 coreFoundationCandidateDeclNode902 .explicit)
private def coreFoundationCandidateDeclNode904 : PsExpr := (.forallE coreFoundationCandidateDeclNode789 coreFoundationCandidateDeclNode893 coreFoundationCandidateDeclNode903 .explicit)
private def coreFoundationCandidateDeclNode905 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode887 coreFoundationCandidateDeclNode904 .implicit)
private def coreFoundationCandidateDeclNode906 : PsExpr := (.forallE coreFoundationCandidateDeclNode54 coreFoundationCandidateDeclNode39 coreFoundationCandidateDeclNode905 .implicit)
private def coreFoundationCandidateDeclNode907 : PsExpr := (.forallE coreFoundationCandidateDeclNode19 coreFoundationCandidateDeclNode36 coreFoundationCandidateDeclNode906 .implicit)
private def coreFoundationCandidateDeclNode908 : PsExpr := (.constE coreFoundationCandidateDeclNode111 [])
private def coreFoundationCandidateDeclNode909 : PsName := (.str coreFoundationCandidateDeclNode111 "rec")
private def coreFoundationCandidateDeclNode910 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode908 coreFoundationCandidateDeclNode47 .explicit)
private def coreFoundationCandidateDeclNode911 : PsExpr := (.constE coreFoundationCandidateDeclNode112 [])
private def coreFoundationCandidateDeclNode912 : PsExpr := (.app (.bvar 0) coreFoundationCandidateDeclNode911)
private def coreFoundationCandidateDeclNode913 : PsExpr := (.forallE coreFoundationCandidateDeclNode120 coreFoundationCandidateDeclNode908 coreFoundationCandidateDeclNode248 .explicit)
private def coreFoundationCandidateDeclNode914 : PsExpr := (.forallE coreFoundationCandidateDeclNode239 coreFoundationCandidateDeclNode912 coreFoundationCandidateDeclNode913 .explicit)
private def coreFoundationCandidateDeclNode915 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode910 coreFoundationCandidateDeclNode914 .implicit)
private def coreFoundationCandidateDeclNode916 : PsName := (.str coreFoundationCandidateDeclNode113 "unit")
private def coreFoundationCandidateDeclNode917 : PsExpr := (.constE coreFoundationCandidateDeclNode103 [coreFoundationCandidateDeclNode8])
private def coreFoundationCandidateDeclNode918 : PsExpr := (.forallE coreFoundationCandidateDeclNode276 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode21 .explicit)
private def coreFoundationCandidateDeclNode919 : PsExpr := (.forallE coreFoundationCandidateDeclNode269 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode918 .explicit)
private def coreFoundationCandidateDeclNode920 : PsName := (.str .anonymous "h_1")
private def coreFoundationCandidateDeclNode921 : PsExpr := (.app (.bvar 3) coreFoundationCandidateDeclNode319)
private def coreFoundationCandidateDeclNode922 : PsExpr := (.app coreFoundationCandidateDeclNode921 (.bvar 0))
private def coreFoundationCandidateDeclNode923 : PsExpr := (.forallE coreFoundationCandidateDeclNode13 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode922 .explicit)
private def coreFoundationCandidateDeclNode924 : PsName := (.str .anonymous "h_2")
private def coreFoundationCandidateDeclNode925 : PsExpr := (.app (.bvar 4) coreFoundationCandidateDeclNode322)
private def coreFoundationCandidateDeclNode926 : PsExpr := (.app coreFoundationCandidateDeclNode925 (.bvar 0))
private def coreFoundationCandidateDeclNode927 : PsExpr := (.forallE coreFoundationCandidateDeclNode13 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode926 .explicit)
private def coreFoundationCandidateDeclNode928 : PsExpr := (.app (.bvar 4) (.bvar 3))
private def coreFoundationCandidateDeclNode929 : PsExpr := (.app coreFoundationCandidateDeclNode928 (.bvar 2))
private def coreFoundationCandidateDeclNode930 : PsExpr := (.forallE coreFoundationCandidateDeclNode924 coreFoundationCandidateDeclNode927 coreFoundationCandidateDeclNode929 .explicit)
private def coreFoundationCandidateDeclNode931 : PsExpr := (.forallE coreFoundationCandidateDeclNode920 coreFoundationCandidateDeclNode923 coreFoundationCandidateDeclNode930 .explicit)
private def coreFoundationCandidateDeclNode932 : PsExpr := (.forallE coreFoundationCandidateDeclNode276 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode931 .explicit)
private def coreFoundationCandidateDeclNode933 : PsExpr := (.forallE coreFoundationCandidateDeclNode269 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode932 .explicit)
private def coreFoundationCandidateDeclNode934 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode919 coreFoundationCandidateDeclNode933 .explicit)
private def coreFoundationCandidateDeclNode935 : PsExpr := (.constE coreFoundationCandidateDeclNode131 [coreFoundationCandidateDeclNode20])
private def coreFoundationCandidateDeclNode936 : PsExpr := (.app (.bvar 5) (.bvar 0))
private def coreFoundationCandidateDeclNode937 : PsExpr := (.app coreFoundationCandidateDeclNode936 (.bvar 3))
private def coreFoundationCandidateDeclNode938 : PsExpr := (.lam coreFoundationCandidateDeclNode75 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode937 .explicit)
private def coreFoundationCandidateDeclNode939 : PsExpr := (.app coreFoundationCandidateDeclNode935 coreFoundationCandidateDeclNode938)
private def coreFoundationCandidateDeclNode940 : PsExpr := (.app coreFoundationCandidateDeclNode939 (.bvar 3))
private def coreFoundationCandidateDeclNode941 : PsExpr := (.app (.bvar 1) (.bvar 2))
private def coreFoundationCandidateDeclNode942 : PsExpr := (.app coreFoundationCandidateDeclNode940 coreFoundationCandidateDeclNode941)
private def coreFoundationCandidateDeclNode943 : PsExpr := (.app coreFoundationCandidateDeclNode942 coreFoundationCandidateDeclNode626)
private def coreFoundationCandidateDeclNode944 : PsExpr := (.lam coreFoundationCandidateDeclNode924 coreFoundationCandidateDeclNode927 coreFoundationCandidateDeclNode943 .explicit)
private def coreFoundationCandidateDeclNode945 : PsExpr := (.lam coreFoundationCandidateDeclNode920 coreFoundationCandidateDeclNode923 coreFoundationCandidateDeclNode944 .explicit)
private def coreFoundationCandidateDeclNode946 : PsExpr := (.lam coreFoundationCandidateDeclNode276 coreFoundationCandidateDeclNode2 coreFoundationCandidateDeclNode945 .explicit)
private def coreFoundationCandidateDeclNode947 : PsExpr := (.lam coreFoundationCandidateDeclNode269 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode946 .explicit)
private def coreFoundationCandidateDeclNode948 : PsExpr := (.lam coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode919 coreFoundationCandidateDeclNode947 .explicit)
private def coreFoundationCandidateDeclNode949 : PsExpr := (.app coreFoundationCandidateDeclNode140 coreFoundationCandidateDeclNode351)
private def coreFoundationCandidateDeclNode950 : PsExpr := (.app coreFoundationCandidateDeclNode949 coreFoundationCandidateDeclNode343)
private def coreFoundationCandidateDeclNode951 : PsExpr := (.forallE coreFoundationCandidateDeclNode3 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode950 .explicit)
private def coreFoundationCandidateDeclNode952 : PsExpr := (.forallE coreFoundationCandidateDeclNode1 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode951 .explicit)
private def coreFoundationCandidateDeclNode953 : PsName := (.str coreFoundationCandidateDeclNode339 "match_1")
private def coreFoundationCandidateDeclNode954 : PsExpr := (.constE coreFoundationCandidateDeclNode953 [])
private def coreFoundationCandidateDeclNode955 : PsName := (.str coreFoundationCandidateDeclNode22 "Init")
private def coreFoundationCandidateDeclNode956 : PsName := (.str coreFoundationCandidateDeclNode955 "Prelude")
private def coreFoundationCandidateDeclNode957 : PsName := (.num coreFoundationCandidateDeclNode956 18944135)
private def coreFoundationCandidateDeclNode958 : PsName := (.str coreFoundationCandidateDeclNode957 "_hygCtx")
private def coreFoundationCandidateDeclNode959 : PsName := (.str coreFoundationCandidateDeclNode958 "_hyg")
private def coreFoundationCandidateDeclNode960 : PsName := (.num coreFoundationCandidateDeclNode959 19)
private def coreFoundationCandidateDeclNode961 : PsName := (.num coreFoundationCandidateDeclNode298 18944135)
private def coreFoundationCandidateDeclNode962 : PsName := (.str coreFoundationCandidateDeclNode961 "_hygCtx")
private def coreFoundationCandidateDeclNode963 : PsName := (.str coreFoundationCandidateDeclNode962 "_hyg")
private def coreFoundationCandidateDeclNode964 : PsName := (.num coreFoundationCandidateDeclNode963 21)
private def coreFoundationCandidateDeclNode965 : PsExpr := (.lam coreFoundationCandidateDeclNode964 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode950 .explicit)
private def coreFoundationCandidateDeclNode966 : PsExpr := (.lam coreFoundationCandidateDeclNode960 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode965 .explicit)
private def coreFoundationCandidateDeclNode967 : PsExpr := (.app coreFoundationCandidateDeclNode954 coreFoundationCandidateDeclNode966)
private def coreFoundationCandidateDeclNode968 : PsExpr := (.app coreFoundationCandidateDeclNode967 (.bvar 1))
private def coreFoundationCandidateDeclNode969 : PsExpr := (.app coreFoundationCandidateDeclNode968 (.bvar 0))
private def coreFoundationCandidateDeclNode970 : PsExpr := (.constE coreFoundationCandidateDeclNode213 [coreFoundationCandidateDeclNode8])
private def coreFoundationCandidateDeclNode971 : PsExpr := (.app coreFoundationCandidateDeclNode970 coreFoundationCandidateDeclNode137)
private def coreFoundationCandidateDeclNode972 : PsExpr := (.app coreFoundationCandidateDeclNode971 coreFoundationCandidateDeclNode319)
private def coreFoundationCandidateDeclNode973 : PsExpr := (.lam coreFoundationCandidateDeclNode306 coreFoundationCandidateDeclNode307 coreFoundationCandidateDeclNode972 .explicit)
private def coreFoundationCandidateDeclNode974 : PsExpr := (.app coreFoundationCandidateDeclNode969 coreFoundationCandidateDeclNode973)
private def coreFoundationCandidateDeclNode975 : PsExpr := (.constE coreFoundationCandidateDeclNode360 [.zero])
private def coreFoundationCandidateDeclNode976 : PsExpr := (.app coreFoundationCandidateDeclNode975 coreFoundationCandidateDeclNode71)
private def coreFoundationCandidateDeclNode977 : PsExpr := (.app coreFoundationCandidateDeclNode976 coreFoundationCandidateDeclNode319)
private def coreFoundationCandidateDeclNode978 : PsExpr := (.app coreFoundationCandidateDeclNode977 coreFoundationCandidateDeclNode322)
private def coreFoundationCandidateDeclNode979 : PsExpr := (.lam coreFoundationCandidateDeclNode306 coreFoundationCandidateDeclNode307 coreFoundationCandidateDeclNode978 .explicit)
private def coreFoundationCandidateDeclNode980 : PsExpr := (.app coreFoundationCandidateDeclNode974 coreFoundationCandidateDeclNode979)
private def coreFoundationCandidateDeclNode981 : PsExpr := (.app coreFoundationCandidateDeclNode976 coreFoundationCandidateDeclNode322)
private def coreFoundationCandidateDeclNode982 : PsExpr := (.app coreFoundationCandidateDeclNode981 coreFoundationCandidateDeclNode319)
private def coreFoundationCandidateDeclNode983 : PsExpr := (.lam coreFoundationCandidateDeclNode306 coreFoundationCandidateDeclNode307 coreFoundationCandidateDeclNode982 .explicit)
private def coreFoundationCandidateDeclNode984 : PsExpr := (.app coreFoundationCandidateDeclNode980 coreFoundationCandidateDeclNode983)
private def coreFoundationCandidateDeclNode985 : PsExpr := (.app coreFoundationCandidateDeclNode971 coreFoundationCandidateDeclNode322)
private def coreFoundationCandidateDeclNode986 : PsExpr := (.lam coreFoundationCandidateDeclNode306 coreFoundationCandidateDeclNode307 coreFoundationCandidateDeclNode985 .explicit)
private def coreFoundationCandidateDeclNode987 : PsExpr := (.app coreFoundationCandidateDeclNode984 coreFoundationCandidateDeclNode986)
private def coreFoundationCandidateDeclNode988 : PsExpr := (.lam coreFoundationCandidateDeclNode3 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode987 .explicit)
private def coreFoundationCandidateDeclNode989 : PsExpr := (.lam coreFoundationCandidateDeclNode1 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode988 .explicit)
private def coreFoundationCandidateDeclNode990 : PsExpr := (.forallE coreFoundationCandidateDeclNode964 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode2 .explicit)
private def coreFoundationCandidateDeclNode991 : PsExpr := (.forallE coreFoundationCandidateDeclNode960 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode990 .explicit)
private def coreFoundationCandidateDeclNode992 : PsExpr := (.app coreFoundationCandidateDeclNode921 coreFoundationCandidateDeclNode319)
private def coreFoundationCandidateDeclNode993 : PsExpr := (.forallE coreFoundationCandidateDeclNode306 coreFoundationCandidateDeclNode307 coreFoundationCandidateDeclNode992 .explicit)
private def coreFoundationCandidateDeclNode994 : PsExpr := (.app (.bvar 4) coreFoundationCandidateDeclNode319)
private def coreFoundationCandidateDeclNode995 : PsExpr := (.app coreFoundationCandidateDeclNode994 coreFoundationCandidateDeclNode322)
private def coreFoundationCandidateDeclNode996 : PsExpr := (.forallE coreFoundationCandidateDeclNode306 coreFoundationCandidateDeclNode307 coreFoundationCandidateDeclNode995 .explicit)
private def coreFoundationCandidateDeclNode997 : PsName := (.str .anonymous "h_3")
private def coreFoundationCandidateDeclNode998 : PsExpr := (.app (.bvar 5) coreFoundationCandidateDeclNode322)
private def coreFoundationCandidateDeclNode999 : PsExpr := (.app coreFoundationCandidateDeclNode998 coreFoundationCandidateDeclNode319)
private def coreFoundationCandidateDeclNode1000 : PsExpr := (.forallE coreFoundationCandidateDeclNode306 coreFoundationCandidateDeclNode307 coreFoundationCandidateDeclNode999 .explicit)
private def coreFoundationCandidateDeclNode1001 : PsName := (.str .anonymous "h_4")
private def coreFoundationCandidateDeclNode1002 : PsExpr := (.app (.bvar 6) coreFoundationCandidateDeclNode322)
private def coreFoundationCandidateDeclNode1003 : PsExpr := (.app coreFoundationCandidateDeclNode1002 coreFoundationCandidateDeclNode322)
private def coreFoundationCandidateDeclNode1004 : PsExpr := (.forallE coreFoundationCandidateDeclNode306 coreFoundationCandidateDeclNode307 coreFoundationCandidateDeclNode1003 .explicit)
private def coreFoundationCandidateDeclNode1005 : PsExpr := (.app (.bvar 6) (.bvar 5))
private def coreFoundationCandidateDeclNode1006 : PsExpr := (.app coreFoundationCandidateDeclNode1005 (.bvar 4))
private def coreFoundationCandidateDeclNode1007 : PsExpr := (.forallE coreFoundationCandidateDeclNode1001 coreFoundationCandidateDeclNode1004 coreFoundationCandidateDeclNode1006 .explicit)
private def coreFoundationCandidateDeclNode1008 : PsExpr := (.forallE coreFoundationCandidateDeclNode997 coreFoundationCandidateDeclNode1000 coreFoundationCandidateDeclNode1007 .explicit)
private def coreFoundationCandidateDeclNode1009 : PsExpr := (.forallE coreFoundationCandidateDeclNode924 coreFoundationCandidateDeclNode996 coreFoundationCandidateDeclNode1008 .explicit)
private def coreFoundationCandidateDeclNode1010 : PsExpr := (.forallE coreFoundationCandidateDeclNode920 coreFoundationCandidateDeclNode993 coreFoundationCandidateDeclNode1009 .explicit)
private def coreFoundationCandidateDeclNode1011 : PsExpr := (.forallE coreFoundationCandidateDeclNode964 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode1010 .explicit)
private def coreFoundationCandidateDeclNode1012 : PsExpr := (.forallE coreFoundationCandidateDeclNode960 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode1011 .explicit)
private def coreFoundationCandidateDeclNode1013 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode991 coreFoundationCandidateDeclNode1012 .explicit)
private def coreFoundationCandidateDeclNode1014 : PsExpr := (.constE coreFoundationCandidateDeclNode131 [.zero])
private def coreFoundationCandidateDeclNode1015 : PsExpr := (.app (.bvar 7) (.bvar 0))
private def coreFoundationCandidateDeclNode1016 : PsExpr := (.app coreFoundationCandidateDeclNode1015 (.bvar 5))
private def coreFoundationCandidateDeclNode1017 : PsExpr := (.lam coreFoundationCandidateDeclNode75 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode1016 .explicit)
private def coreFoundationCandidateDeclNode1018 : PsExpr := (.app coreFoundationCandidateDeclNode1014 coreFoundationCandidateDeclNode1017)
private def coreFoundationCandidateDeclNode1019 : PsExpr := (.app coreFoundationCandidateDeclNode1018 (.bvar 5))
private def coreFoundationCandidateDeclNode1020 : PsExpr := (.app (.bvar 7) coreFoundationCandidateDeclNode319)
private def coreFoundationCandidateDeclNode1021 : PsExpr := (.app coreFoundationCandidateDeclNode1020 (.bvar 0))
private def coreFoundationCandidateDeclNode1022 : PsExpr := (.lam coreFoundationCandidateDeclNode75 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode1021 .explicit)
private def coreFoundationCandidateDeclNode1023 : PsExpr := (.app coreFoundationCandidateDeclNode1014 coreFoundationCandidateDeclNode1022)
private def coreFoundationCandidateDeclNode1024 : PsExpr := (.app coreFoundationCandidateDeclNode1023 (.bvar 4))
private def coreFoundationCandidateDeclNode1025 : PsExpr := (.constE coreFoundationCandidateDeclNode916 [])
private def coreFoundationCandidateDeclNode1026 : PsExpr := (.app (.bvar 3) coreFoundationCandidateDeclNode1025)
private def coreFoundationCandidateDeclNode1027 : PsExpr := (.app coreFoundationCandidateDeclNode1024 coreFoundationCandidateDeclNode1026)
private def coreFoundationCandidateDeclNode1028 : PsExpr := (.app (.bvar 2) coreFoundationCandidateDeclNode1025)
private def coreFoundationCandidateDeclNode1029 : PsExpr := (.app coreFoundationCandidateDeclNode1027 coreFoundationCandidateDeclNode1028)
private def coreFoundationCandidateDeclNode1030 : PsExpr := (.app coreFoundationCandidateDeclNode1019 coreFoundationCandidateDeclNode1029)
private def coreFoundationCandidateDeclNode1031 : PsExpr := (.app (.bvar 7) coreFoundationCandidateDeclNode322)
private def coreFoundationCandidateDeclNode1032 : PsExpr := (.app coreFoundationCandidateDeclNode1031 (.bvar 0))
private def coreFoundationCandidateDeclNode1033 : PsExpr := (.lam coreFoundationCandidateDeclNode75 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode1032 .explicit)
private def coreFoundationCandidateDeclNode1034 : PsExpr := (.app coreFoundationCandidateDeclNode1014 coreFoundationCandidateDeclNode1033)
private def coreFoundationCandidateDeclNode1035 : PsExpr := (.app coreFoundationCandidateDeclNode1034 (.bvar 4))
private def coreFoundationCandidateDeclNode1036 : PsExpr := (.app (.bvar 1) coreFoundationCandidateDeclNode1025)
private def coreFoundationCandidateDeclNode1037 : PsExpr := (.app coreFoundationCandidateDeclNode1035 coreFoundationCandidateDeclNode1036)
private def coreFoundationCandidateDeclNode1038 : PsExpr := (.app (.bvar 0) coreFoundationCandidateDeclNode1025)
private def coreFoundationCandidateDeclNode1039 : PsExpr := (.app coreFoundationCandidateDeclNode1037 coreFoundationCandidateDeclNode1038)
private def coreFoundationCandidateDeclNode1040 : PsExpr := (.app coreFoundationCandidateDeclNode1030 coreFoundationCandidateDeclNode1039)
private def coreFoundationCandidateDeclNode1041 : PsExpr := (.lam coreFoundationCandidateDeclNode1001 coreFoundationCandidateDeclNode1004 coreFoundationCandidateDeclNode1040 .explicit)
private def coreFoundationCandidateDeclNode1042 : PsExpr := (.lam coreFoundationCandidateDeclNode997 coreFoundationCandidateDeclNode1000 coreFoundationCandidateDeclNode1041 .explicit)
private def coreFoundationCandidateDeclNode1043 : PsExpr := (.lam coreFoundationCandidateDeclNode924 coreFoundationCandidateDeclNode996 coreFoundationCandidateDeclNode1042 .explicit)
private def coreFoundationCandidateDeclNode1044 : PsExpr := (.lam coreFoundationCandidateDeclNode920 coreFoundationCandidateDeclNode993 coreFoundationCandidateDeclNode1043 .explicit)
private def coreFoundationCandidateDeclNode1045 : PsExpr := (.lam coreFoundationCandidateDeclNode964 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode1044 .explicit)
private def coreFoundationCandidateDeclNode1046 : PsExpr := (.lam coreFoundationCandidateDeclNode960 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode1045 .explicit)
private def coreFoundationCandidateDeclNode1047 : PsExpr := (.lam coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode991 coreFoundationCandidateDeclNode1046 .explicit)
private def coreFoundationCandidateDeclNode1048 : PsName := (.num coreFoundationCandidateDeclNode78 2579035303)
private def coreFoundationCandidateDeclNode1049 : PsName := (.str coreFoundationCandidateDeclNode1048 "_hygCtx")
private def coreFoundationCandidateDeclNode1050 : PsName := (.str coreFoundationCandidateDeclNode1049 "_hyg")
private def coreFoundationCandidateDeclNode1051 : PsName := (.num coreFoundationCandidateDeclNode1050 8)
private def coreFoundationCandidateDeclNode1052 : PsExpr := (.forallE coreFoundationCandidateDeclNode1051 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode21 .explicit)
private def coreFoundationCandidateDeclNode1053 : PsExpr := (.app (.bvar 2) coreFoundationCandidateDeclNode319)
private def coreFoundationCandidateDeclNode1054 : PsExpr := (.forallE coreFoundationCandidateDeclNode306 coreFoundationCandidateDeclNode307 coreFoundationCandidateDeclNode1053 .explicit)
private def coreFoundationCandidateDeclNode1055 : PsExpr := (.app (.bvar 3) coreFoundationCandidateDeclNode322)
private def coreFoundationCandidateDeclNode1056 : PsExpr := (.forallE coreFoundationCandidateDeclNode306 coreFoundationCandidateDeclNode307 coreFoundationCandidateDeclNode1055 .explicit)
private def coreFoundationCandidateDeclNode1057 : PsExpr := (.forallE coreFoundationCandidateDeclNode924 coreFoundationCandidateDeclNode1056 coreFoundationCandidateDeclNode324 .explicit)
private def coreFoundationCandidateDeclNode1058 : PsExpr := (.forallE coreFoundationCandidateDeclNode920 coreFoundationCandidateDeclNode1054 coreFoundationCandidateDeclNode1057 .explicit)
private def coreFoundationCandidateDeclNode1059 : PsExpr := (.forallE coreFoundationCandidateDeclNode1051 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode1058 .explicit)
private def coreFoundationCandidateDeclNode1060 : PsExpr := (.forallE coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode1052 coreFoundationCandidateDeclNode1059 .explicit)
private def coreFoundationCandidateDeclNode1061 : PsExpr := (.app (.bvar 4) (.bvar 0))
private def coreFoundationCandidateDeclNode1062 : PsExpr := (.lam coreFoundationCandidateDeclNode75 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode1061 .explicit)
private def coreFoundationCandidateDeclNode1063 : PsExpr := (.app coreFoundationCandidateDeclNode935 coreFoundationCandidateDeclNode1062)
private def coreFoundationCandidateDeclNode1064 : PsExpr := (.app coreFoundationCandidateDeclNode1063 (.bvar 2))
private def coreFoundationCandidateDeclNode1065 : PsExpr := (.app coreFoundationCandidateDeclNode1064 coreFoundationCandidateDeclNode1036)
private def coreFoundationCandidateDeclNode1066 : PsExpr := (.app coreFoundationCandidateDeclNode1065 coreFoundationCandidateDeclNode1038)
private def coreFoundationCandidateDeclNode1067 : PsExpr := (.lam coreFoundationCandidateDeclNode924 coreFoundationCandidateDeclNode1056 coreFoundationCandidateDeclNode1066 .explicit)
private def coreFoundationCandidateDeclNode1068 : PsExpr := (.lam coreFoundationCandidateDeclNode920 coreFoundationCandidateDeclNode1054 coreFoundationCandidateDeclNode1067 .explicit)
private def coreFoundationCandidateDeclNode1069 : PsExpr := (.lam coreFoundationCandidateDeclNode1051 coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode1068 .explicit)
private def coreFoundationCandidateDeclNode1070 : PsExpr := (.lam coreFoundationCandidateDeclNode235 coreFoundationCandidateDeclNode1052 coreFoundationCandidateDeclNode1069 .explicit)

def psCoreFoundationCandidateBoundary : List PsName :=
  []

-- And
private def coreFoundationCandidateDecl0 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode0 [] coreFoundationCandidateDeclNode5 2 0 [coreFoundationCandidateDeclNode6] true)

-- Bool
private def coreFoundationCandidateDecl1 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode7 [] coreFoundationCandidateDeclNode9 0 0 [coreFoundationCandidateDeclNode10, coreFoundationCandidateDeclNode11] false)

-- Decidable
private def coreFoundationCandidateDecl2 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode12 [] coreFoundationCandidateDeclNode14 1 0 [coreFoundationCandidateDeclNode15] true)

-- Empty
private def coreFoundationCandidateDecl3 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode16 [] coreFoundationCandidateDeclNode9 0 0 [] false)

-- Eq
private def coreFoundationCandidateDecl4 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode17 [coreFoundationCandidateDeclNode18] coreFoundationCandidateDeclNode28 2 1 [coreFoundationCandidateDeclNode29] false)

-- Except
private def coreFoundationCandidateDecl5 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode30 [coreFoundationCandidateDeclNode31, coreFoundationCandidateDeclNode32] coreFoundationCandidateDeclNode43 2 0 [coreFoundationCandidateDeclNode44, coreFoundationCandidateDeclNode45] false)

-- Exists
private def coreFoundationCandidateDecl6 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode46 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode50 2 0 [coreFoundationCandidateDeclNode51] false)

-- False
private def coreFoundationCandidateDecl7 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode52 [] coreFoundationCandidateDeclNode2 0 0 [] false)

-- HEq
private def coreFoundationCandidateDecl8 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode53 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode57 2 2 [coreFoundationCandidateDeclNode58] false)

-- List
private def coreFoundationCandidateDecl9 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode59 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode60 1 0 [coreFoundationCandidateDeclNode61, coreFoundationCandidateDeclNode62] false)

-- Nat
private def coreFoundationCandidateDecl10 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode63 [] coreFoundationCandidateDeclNode9 0 0 [coreFoundationCandidateDeclNode64, coreFoundationCandidateDeclNode65] false)

-- Nonempty
private def coreFoundationCandidateDecl11 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode66 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode67 1 0 [coreFoundationCandidateDeclNode68] false)

-- Not
private def coreFoundationCandidateDecl12 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode69 [] coreFoundationCandidateDeclNode70
    coreFoundationCandidateDeclNode73

-- OfNat
private def coreFoundationCandidateDecl13 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode74 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode85 2 0 [coreFoundationCandidateDeclNode86] true)

-- Option
private def coreFoundationCandidateDecl14 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode87 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode60 1 0 [coreFoundationCandidateDeclNode88, coreFoundationCandidateDeclNode89] false)

-- Or
private def coreFoundationCandidateDecl15 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode90 [] coreFoundationCandidateDeclNode5 2 0 [coreFoundationCandidateDeclNode91, coreFoundationCandidateDeclNode92] false)

-- PEmpty
private def coreFoundationCandidateDecl16 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode93 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode47 0 0 [] false)

-- PProd
private def coreFoundationCandidateDecl17 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode94 [coreFoundationCandidateDeclNode31, coreFoundationCandidateDeclNode32] coreFoundationCandidateDeclNode100 2 0 [coreFoundationCandidateDeclNode101] true)

-- PUnit
private def coreFoundationCandidateDecl18 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode102 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode47 0 0 [coreFoundationCandidateDeclNode103] false)

-- Prod
private def coreFoundationCandidateDecl19 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode104 [coreFoundationCandidateDeclNode31, coreFoundationCandidateDeclNode32] coreFoundationCandidateDeclNode106 2 0 [coreFoundationCandidateDeclNode107] true)

-- Sum
private def coreFoundationCandidateDecl20 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode108 [coreFoundationCandidateDeclNode31, coreFoundationCandidateDeclNode32] coreFoundationCandidateDeclNode106 2 0 [coreFoundationCandidateDeclNode109, coreFoundationCandidateDeclNode110] false)

-- True
private def coreFoundationCandidateDecl21 : PsDeclaration :=
  .inductiveDecl (PsInductiveInfo.mk coreFoundationCandidateDeclNode111 [] coreFoundationCandidateDeclNode2 0 0 [coreFoundationCandidateDeclNode112] false)

-- Unit
private def coreFoundationCandidateDecl22 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode113 [] coreFoundationCandidateDeclNode9
    coreFoundationCandidateDeclNode114

-- dite
private def coreFoundationCandidateDecl23 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode115 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode130
    coreFoundationCandidateDeclNode162

-- id
private def coreFoundationCandidateDecl24 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode163 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode165
    coreFoundationCandidateDeclNode167

-- instOfNatNat
private def coreFoundationCandidateDecl25 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode168 [] coreFoundationCandidateDeclNode173
    coreFoundationCandidateDeclNode178

-- ite
private def coreFoundationCandidateDecl26 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode179 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode184
    coreFoundationCandidateDeclNode203

-- optParam
private def coreFoundationCandidateDecl27 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode204 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode207
    coreFoundationCandidateDeclNode209

-- outParam
private def coreFoundationCandidateDecl28 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode210 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode211
    coreFoundationCandidateDeclNode212

-- rfl
private def coreFoundationCandidateDecl29 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode213 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode219
    coreFoundationCandidateDeclNode224

-- And.intro
private def coreFoundationCandidateDecl30 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode6 [] coreFoundationCandidateDeclNode233 coreFoundationCandidateDeclNode0 0 2 2 [])

-- And.rec
private def coreFoundationCandidateDecl31 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode234 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode253 [coreFoundationCandidateDeclNode0] 2 0 1 1)

-- Bool.Reflects
private def coreFoundationCandidateDecl32 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode139 [] coreFoundationCandidateDeclNode255
    coreFoundationCandidateDeclNode288

-- Bool.beq
private def coreFoundationCandidateDecl33 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode289 [] coreFoundationCandidateDeclNode291
    coreFoundationCandidateDeclNode316

-- Bool.casesOn
private def coreFoundationCandidateDecl34 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode131 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode328
    coreFoundationCandidateDeclNode338

-- Bool.decEq
private def coreFoundationCandidateDecl35 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode339 [] coreFoundationCandidateDeclNode346
    coreFoundationCandidateDeclNode359

-- Bool.false
private def coreFoundationCandidateDecl36 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode10 [] coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode7 0 0 0 [])

-- Bool.noConfusion
private def coreFoundationCandidateDecl37 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode360 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode372
    coreFoundationCandidateDeclNode397

-- Bool.noConfusionType
private def coreFoundationCandidateDecl38 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode364 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode400
    coreFoundationCandidateDeclNode421

-- Bool.not
private def coreFoundationCandidateDecl39 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode308 [] coreFoundationCandidateDeclNode422
    coreFoundationCandidateDeclNode433

-- Bool.rec
private def coreFoundationCandidateDecl40 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode329 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode440 [coreFoundationCandidateDeclNode7] 0 0 1 2)

-- Bool.true
private def coreFoundationCandidateDecl41 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode11 [] coreFoundationCandidateDeclNode137 coreFoundationCandidateDeclNode7 1 0 0 [])

-- Decidable.decide
private def coreFoundationCandidateDecl42 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode146 [] coreFoundationCandidateDeclNode443
    coreFoundationCandidateDeclNode446

-- Decidable.intro
private def coreFoundationCandidateDecl43 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode15 [] coreFoundationCandidateDeclNode453 coreFoundationCandidateDeclNode12 0 1 2 [])

-- Decidable.rec
private def coreFoundationCandidateDecl44 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode454 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode466 [coreFoundationCandidateDeclNode12] 1 0 1 1)

-- Decidable.reflects_decide
private def coreFoundationCandidateDecl45 : PsDeclaration :=
  .theoremDecl coreFoundationCandidateDeclNode153 [] coreFoundationCandidateDeclNode472
    coreFoundationCandidateDeclNode475

-- Empty.rec
private def coreFoundationCandidateDecl46 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode476 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode481 [coreFoundationCandidateDeclNode16] 0 0 1 0)

-- Eq.ndrec
private def coreFoundationCandidateDecl47 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode373 [coreFoundationCandidateDeclNode482, coreFoundationCandidateDeclNode483] coreFoundationCandidateDeclNode501
    coreFoundationCandidateDeclNode526

-- Eq.rec
private def coreFoundationCandidateDecl48 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode502 [coreFoundationCandidateDeclNode31, coreFoundationCandidateDeclNode18] coreFoundationCandidateDeclNode547 [coreFoundationCandidateDeclNode17] 2 1 1 1)

-- Eq.refl
private def coreFoundationCandidateDecl49 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode29 [coreFoundationCandidateDeclNode18] coreFoundationCandidateDeclNode552 coreFoundationCandidateDeclNode17 0 2 0 [])

-- Except.error
private def coreFoundationCandidateDecl50 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode44 [coreFoundationCandidateDeclNode31, coreFoundationCandidateDeclNode32] coreFoundationCandidateDeclNode558 coreFoundationCandidateDeclNode30 0 2 1 [])

-- Except.ok
private def coreFoundationCandidateDecl51 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode45 [coreFoundationCandidateDeclNode31, coreFoundationCandidateDeclNode32] coreFoundationCandidateDeclNode561 coreFoundationCandidateDeclNode30 1 2 1 [])

-- Except.rec
private def coreFoundationCandidateDecl52 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode562 [coreFoundationCandidateDeclNode18, coreFoundationCandidateDeclNode31, coreFoundationCandidateDeclNode32] coreFoundationCandidateDeclNode587 [coreFoundationCandidateDeclNode30] 2 0 1 2)

-- Exists.intro
private def coreFoundationCandidateDecl53 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode51 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode595 coreFoundationCandidateDeclNode46 0 2 2 [])

-- Exists.rec
private def coreFoundationCandidateDecl54 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode596 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode612 [coreFoundationCandidateDeclNode46] 2 0 1 1)

-- False.rec
private def coreFoundationCandidateDecl55 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode613 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode616 [coreFoundationCandidateDeclNode52] 0 0 1 0)

-- HEq.rec
private def coreFoundationCandidateDecl56 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode617 [coreFoundationCandidateDeclNode18, coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode645 [coreFoundationCandidateDeclNode53] 2 2 1 1)

-- HEq.refl
private def coreFoundationCandidateDecl57 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode58 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode651 coreFoundationCandidateDeclNode53 0 2 0 [])

-- List.cons
private def coreFoundationCandidateDecl58 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode62 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode659 coreFoundationCandidateDeclNode59 1 1 2 [1])

-- List.nil
private def coreFoundationCandidateDecl59 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode61 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode661 coreFoundationCandidateDeclNode59 0 1 0 [])

-- List.rec
private def coreFoundationCandidateDecl60 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode662 [coreFoundationCandidateDeclNode18, coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode683 [coreFoundationCandidateDeclNode59] 1 0 1 2)

-- Nat.rec
private def coreFoundationCandidateDecl61 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode684 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode699 [coreFoundationCandidateDeclNode63] 0 0 1 2)

-- Nat.succ
private def coreFoundationCandidateDecl62 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode65 [] coreFoundationCandidateDeclNode700 coreFoundationCandidateDeclNode63 1 0 1 [0])

-- Nat.zero
private def coreFoundationCandidateDecl63 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode64 [] coreFoundationCandidateDeclNode83 coreFoundationCandidateDeclNode63 0 0 0 [])

-- Nonempty.intro
private def coreFoundationCandidateDecl64 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode68 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode705 coreFoundationCandidateDeclNode66 0 1 1 [])

-- Nonempty.rec
private def coreFoundationCandidateDecl65 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode706 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode718 [coreFoundationCandidateDeclNode66] 1 0 1 1)

-- OfNat.mk
private def coreFoundationCandidateDecl66 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode86 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode725 coreFoundationCandidateDeclNode74 0 2 1 [])

-- OfNat.ofNat
private def coreFoundationCandidateDecl67 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode726 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode731
    coreFoundationCandidateDeclNode735

-- OfNat.rec
private def coreFoundationCandidateDecl68 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode736 [coreFoundationCandidateDeclNode18, coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode751 [coreFoundationCandidateDeclNode74] 2 0 1 1)

-- Option.none
private def coreFoundationCandidateDecl69 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode88 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode754 coreFoundationCandidateDeclNode87 0 1 0 [])

-- Option.rec
private def coreFoundationCandidateDecl70 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode755 [coreFoundationCandidateDeclNode18, coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode772 [coreFoundationCandidateDeclNode87] 1 0 1 2)

-- Option.some
private def coreFoundationCandidateDecl71 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode89 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode775 coreFoundationCandidateDeclNode87 1 1 1 [])

-- Or.inl
private def coreFoundationCandidateDecl72 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode91 [] coreFoundationCandidateDeclNode781 coreFoundationCandidateDeclNode90 0 2 1 [])

-- Or.inr
private def coreFoundationCandidateDecl73 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode92 [] coreFoundationCandidateDeclNode784 coreFoundationCandidateDeclNode90 1 2 1 [])

-- Or.rec
private def coreFoundationCandidateDecl74 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode785 [] coreFoundationCandidateDeclNode810 [coreFoundationCandidateDeclNode90] 2 0 1 2)

-- PEmpty.rec
private def coreFoundationCandidateDecl75 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode811 [coreFoundationCandidateDeclNode18, coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode815 [coreFoundationCandidateDeclNode93] 0 0 1 0)

-- PProd.mk
private def coreFoundationCandidateDecl76 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode101 [coreFoundationCandidateDeclNode31, coreFoundationCandidateDeclNode32] coreFoundationCandidateDeclNode824 coreFoundationCandidateDeclNode94 0 2 2 [])

-- PProd.rec
private def coreFoundationCandidateDecl77 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode825 [coreFoundationCandidateDeclNode18, coreFoundationCandidateDeclNode31, coreFoundationCandidateDeclNode32] coreFoundationCandidateDeclNode841 [coreFoundationCandidateDeclNode94] 2 0 1 1)

-- PUnit.rec
private def coreFoundationCandidateDecl78 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode842 [coreFoundationCandidateDeclNode18, coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode850 [coreFoundationCandidateDeclNode102] 0 0 1 1)

-- PUnit.unit
private def coreFoundationCandidateDecl79 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode103 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode843 coreFoundationCandidateDeclNode102 0 0 0 [])

-- Prod.mk
private def coreFoundationCandidateDecl80 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode107 [coreFoundationCandidateDeclNode31, coreFoundationCandidateDeclNode32] coreFoundationCandidateDeclNode857 coreFoundationCandidateDeclNode104 0 2 2 [])

-- Prod.rec
private def coreFoundationCandidateDecl81 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode858 [coreFoundationCandidateDeclNode18, coreFoundationCandidateDeclNode31, coreFoundationCandidateDeclNode32] coreFoundationCandidateDeclNode874 [coreFoundationCandidateDeclNode104] 2 0 1 1)

-- Sum.inl
private def coreFoundationCandidateDecl82 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode109 [coreFoundationCandidateDeclNode31, coreFoundationCandidateDeclNode32] coreFoundationCandidateDeclNode880 coreFoundationCandidateDeclNode108 0 2 1 [])

-- Sum.inr
private def coreFoundationCandidateDecl83 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode110 [coreFoundationCandidateDeclNode31, coreFoundationCandidateDeclNode32] coreFoundationCandidateDeclNode883 coreFoundationCandidateDeclNode108 1 2 1 [])

-- Sum.rec
private def coreFoundationCandidateDecl84 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode884 [coreFoundationCandidateDeclNode18, coreFoundationCandidateDeclNode31, coreFoundationCandidateDeclNode32] coreFoundationCandidateDeclNode907 [coreFoundationCandidateDeclNode108] 2 0 1 2)

-- True.intro
private def coreFoundationCandidateDecl85 : PsDeclaration :=
  .constructorDecl (PsConstructorInfo.mk coreFoundationCandidateDeclNode112 [] coreFoundationCandidateDeclNode908 coreFoundationCandidateDeclNode111 0 0 0 [])

-- True.rec
private def coreFoundationCandidateDecl86 : PsDeclaration :=
  .recursorDecl (PsRecursorInfo.mk coreFoundationCandidateDeclNode909 [coreFoundationCandidateDeclNode31] coreFoundationCandidateDeclNode915 [coreFoundationCandidateDeclNode111] 0 0 1 1)

-- Unit.unit
private def coreFoundationCandidateDecl87 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode916 [] coreFoundationCandidateDeclNode307
    coreFoundationCandidateDeclNode917

-- Bool.Reflects.match_1
private def coreFoundationCandidateDecl88 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode261 [coreFoundationCandidateDeclNode18] coreFoundationCandidateDeclNode934
    coreFoundationCandidateDeclNode948

-- Bool.decEq._proof_1
private def coreFoundationCandidateDecl89 : PsDeclaration :=
  .theoremDecl coreFoundationCandidateDeclNode353 [] coreFoundationCandidateDeclNode952
    coreFoundationCandidateDeclNode989

-- Bool.decEq.match_1
private def coreFoundationCandidateDecl90 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode953 [] coreFoundationCandidateDeclNode1013
    coreFoundationCandidateDeclNode1047

-- Bool.Internal.and.match_1
private def coreFoundationCandidateDecl91 : PsDeclaration :=
  .definitionDecl coreFoundationCandidateDeclNode294 [coreFoundationCandidateDeclNode18] coreFoundationCandidateDeclNode1060
    coreFoundationCandidateDeclNode1070

def psCoreFoundationCandidateDeclarations : List PsDeclaration :=
  [coreFoundationCandidateDecl0, coreFoundationCandidateDecl1, coreFoundationCandidateDecl2, coreFoundationCandidateDecl3, coreFoundationCandidateDecl4, coreFoundationCandidateDecl5, coreFoundationCandidateDecl6, coreFoundationCandidateDecl7, coreFoundationCandidateDecl8, coreFoundationCandidateDecl9, coreFoundationCandidateDecl10, coreFoundationCandidateDecl11, coreFoundationCandidateDecl12, coreFoundationCandidateDecl13, coreFoundationCandidateDecl14, coreFoundationCandidateDecl15, coreFoundationCandidateDecl16, coreFoundationCandidateDecl17, coreFoundationCandidateDecl18, coreFoundationCandidateDecl19, coreFoundationCandidateDecl20, coreFoundationCandidateDecl21, coreFoundationCandidateDecl22, coreFoundationCandidateDecl23, coreFoundationCandidateDecl24, coreFoundationCandidateDecl25, coreFoundationCandidateDecl26, coreFoundationCandidateDecl27, coreFoundationCandidateDecl28, coreFoundationCandidateDecl29, coreFoundationCandidateDecl30, coreFoundationCandidateDecl31, coreFoundationCandidateDecl32, coreFoundationCandidateDecl33, coreFoundationCandidateDecl34, coreFoundationCandidateDecl35, coreFoundationCandidateDecl36, coreFoundationCandidateDecl37, coreFoundationCandidateDecl38, coreFoundationCandidateDecl39, coreFoundationCandidateDecl40, coreFoundationCandidateDecl41, coreFoundationCandidateDecl42, coreFoundationCandidateDecl43, coreFoundationCandidateDecl44, coreFoundationCandidateDecl45, coreFoundationCandidateDecl46, coreFoundationCandidateDecl47, coreFoundationCandidateDecl48, coreFoundationCandidateDecl49, coreFoundationCandidateDecl50, coreFoundationCandidateDecl51, coreFoundationCandidateDecl52, coreFoundationCandidateDecl53, coreFoundationCandidateDecl54, coreFoundationCandidateDecl55, coreFoundationCandidateDecl56, coreFoundationCandidateDecl57, coreFoundationCandidateDecl58, coreFoundationCandidateDecl59, coreFoundationCandidateDecl60, coreFoundationCandidateDecl61, coreFoundationCandidateDecl62, coreFoundationCandidateDecl63, coreFoundationCandidateDecl64, coreFoundationCandidateDecl65, coreFoundationCandidateDecl66, coreFoundationCandidateDecl67, coreFoundationCandidateDecl68, coreFoundationCandidateDecl69, coreFoundationCandidateDecl70, coreFoundationCandidateDecl71, coreFoundationCandidateDecl72, coreFoundationCandidateDecl73, coreFoundationCandidateDecl74, coreFoundationCandidateDecl75, coreFoundationCandidateDecl76, coreFoundationCandidateDecl77, coreFoundationCandidateDecl78, coreFoundationCandidateDecl79, coreFoundationCandidateDecl80, coreFoundationCandidateDecl81, coreFoundationCandidateDecl82, coreFoundationCandidateDecl83, coreFoundationCandidateDecl84, coreFoundationCandidateDecl85, coreFoundationCandidateDecl86, coreFoundationCandidateDecl87, coreFoundationCandidateDecl88, coreFoundationCandidateDecl89, coreFoundationCandidateDecl90, coreFoundationCandidateDecl91]

def psCoreFoundationCandidateReducibility : List (PsName × PsReducibility) :=
  [((.str .anonymous "Not"), .implicitReducible), ((.str .anonymous "Unit"), .reducible), ((.str .anonymous "dite"), .implicitReducible), ((.str .anonymous "id"), .implicitReducible), ((.str .anonymous "instOfNatNat"), .instanceReducible), ((.str .anonymous "ite"), .implicitReducible), ((.str .anonymous "optParam"), .reducible), ((.str .anonymous "outParam"), .reducible), ((.str .anonymous "rfl"), .semireducible), ((.str (.str .anonymous "Bool") "Reflects"), .reducible), ((.str (.str .anonymous "Bool") "beq"), .implicitReducible), ((.str (.str .anonymous "Bool") "casesOn"), .reducible), ((.str (.str .anonymous "Bool") "decEq"), .implicitReducible), ((.str (.str .anonymous "Bool") "noConfusion"), .reducible), ((.str (.str .anonymous "Bool") "noConfusionType"), .reducible), ((.str (.str .anonymous "Bool") "not"), .implicitReducible), ((.str (.str .anonymous "Decidable") "decide"), .implicitReducible), ((.str (.str .anonymous "Eq") "ndrec"), .reducible), ((.str (.str .anonymous "OfNat") "ofNat"), .semireducible), ((.str (.str .anonymous "Unit") "unit"), .reducible), ((.str (.str (.str .anonymous "Bool") "Reflects") "match_1"), .instanceReducible), ((.str (.str (.str .anonymous "Bool") "decEq") "match_1"), .instanceReducible), ((.str (.str (.str (.str .anonymous "Bool") "Internal") "and") "match_1"), .instanceReducible)]
