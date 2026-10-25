import Ps.KernelCore.SelfHost

-- Literal transcription of the original authenticated Arena body.
-- Elaboration depth only; checked kernel resources remain unchanged.
set_option maxRecDepth 10000

def psKernelChurchSource : Except String (PsKernelExprV2PagedArena × List PsKernelDagDeclarationRequest) := do
  let n0 : PsKernelName := .anonymous
  let u0 : PsKernelLevel := .zero
  let a0 := psKernelExprV2PagedEmpty
  let n1 : PsKernelName := .str n0 "Eq"
  let n2 : PsKernelName := .str n0 "u_1"
  let u1 : PsKernelLevel := .param n2
  let n3 : PsKernelName := .str n0 "α"
  let p0 ← psKernelExprV2PagedMkSort a0 u1
  let a1 := p0.fst
  let e0 := p0.snd
  let n4 : PsKernelName := .str n0 "a"
  let n5 : PsKernelName := .str n4 "_@"
  let n6 : PsKernelName := .str n5 "_internal"
  let n7 : PsKernelName := .str n6 "_hyg"
  let n8 : PsKernelName := .num n7 0
  let p1 ← psKernelExprV2PagedMkBVar a1 0
  let a2 := p1.fst
  let e1 := p1.snd
  let p2 ← psKernelExprV2PagedMkBVar a2 1
  let a3 := p2.fst
  let e2 := p2.snd
  let p3 ← psKernelExprV2PagedMkSort a3 u0
  let a4 := p3.fst
  let e3 := p3.snd
  let p4 ← psKernelExprV2PagedMkForall a4 n8 e2 e3 .default
  let a5 := p4.fst
  let e4 := p4.snd
  let p5 ← psKernelExprV2PagedMkForall a5 n8 e1 e4 .default
  let a6 := p5.fst
  let e5 := p5.snd
  let p6 ← psKernelExprV2PagedMkForall a6 n3 e0 e5 .implicit
  let a7 := p6.fst
  let e6 := p6.snd
  let n9 : PsKernelName := .str n1 "refl"
  let p7 ← psKernelExprV2PagedMkConst a7 n1 [u1]
  let a8 := p7.fst
  let e7 := p7.snd
  let p8 ← psKernelExprV2PagedMkApp a8 e7 e2
  let a9 := p8.fst
  let e8 := p8.snd
  let p9 ← psKernelExprV2PagedMkApp a9 e8 e1
  let a10 := p9.fst
  let e9 := p9.snd
  let p10 ← psKernelExprV2PagedMkApp a10 e9 e1
  let a11 := p10.fst
  let e10 := p10.snd
  let p11 ← psKernelExprV2PagedMkForall a11 n4 e1 e10 .default
  let a12 := p11.fst
  let e11 := p11.snd
  let p12 ← psKernelExprV2PagedMkForall a12 n3 e0 e11 .implicit
  let a13 := p12.fst
  let e12 := p12.snd
  let n10 : PsKernelName := .str n1 "rec"
  let n11 : PsKernelName := .str n0 "u"
  let u2 : PsKernelLevel := .param n11
  let n12 : PsKernelName := .str n0 "motive"
  let n13 : PsKernelName := .str n0 "t"
  let p13 ← psKernelExprV2PagedMkBVar a13 2
  let a14 := p13.fst
  let e13 := p13.snd
  let p14 ← psKernelExprV2PagedMkApp a14 e7 e13
  let a15 := p14.fst
  let e14 := p14.snd
  let p15 ← psKernelExprV2PagedMkApp a15 e14 e2
  let a16 := p15.fst
  let e15 := p15.snd
  let p16 ← psKernelExprV2PagedMkApp a16 e15 e1
  let a17 := p16.fst
  let e16 := p16.snd
  let p17 ← psKernelExprV2PagedMkSort a17 u2
  let a18 := p17.fst
  let e17 := p17.snd
  let p18 ← psKernelExprV2PagedMkForall a18 n13 e16 e17 .default
  let a19 := p18.fst
  let e18 := p18.snd
  let p19 ← psKernelExprV2PagedMkForall a19 n8 e2 e18 .default
  let a20 := p19.fst
  let e19 := p19.snd
  let n14 : PsKernelName := .str n0 "refl"
  let p20 ← psKernelExprV2PagedMkApp a20 e1 e2
  let a21 := p20.fst
  let e20 := p20.snd
  let p21 ← psKernelExprV2PagedMkConst a21 n9 [u1]
  let a22 := p21.fst
  let e21 := p21.snd
  let p22 ← psKernelExprV2PagedMkApp a22 e21 e13
  let a23 := p22.fst
  let e22 := p22.snd
  let p23 ← psKernelExprV2PagedMkApp a23 e22 e2
  let a24 := p23.fst
  let e23 := p23.snd
  let p24 ← psKernelExprV2PagedMkApp a24 e20 e23
  let a25 := p24.fst
  let e24 := p24.snd
  let p25 ← psKernelExprV2PagedMkBVar a25 3
  let a26 := p25.fst
  let e25 := p25.snd
  let p26 ← psKernelExprV2PagedMkBVar a26 4
  let a27 := p26.fst
  let e26 := p26.snd
  let p27 ← psKernelExprV2PagedMkApp a27 e7 e26
  let a28 := p27.fst
  let e27 := p27.snd
  let p28 ← psKernelExprV2PagedMkApp a28 e27 e25
  let a29 := p28.fst
  let e28 := p28.snd
  let p29 ← psKernelExprV2PagedMkApp a29 e28 e1
  let a30 := p29.fst
  let e29 := p29.snd
  let p30 ← psKernelExprV2PagedMkApp a30 e25 e2
  let a31 := p30.fst
  let e30 := p30.snd
  let p31 ← psKernelExprV2PagedMkApp a31 e30 e1
  let a32 := p31.fst
  let e31 := p31.snd
  let p32 ← psKernelExprV2PagedMkForall a32 n13 e29 e31 .default
  let a33 := p32.fst
  let e32 := p32.snd
  let p33 ← psKernelExprV2PagedMkForall a33 n8 e25 e32 .implicit
  let a34 := p33.fst
  let e33 := p33.snd
  let p34 ← psKernelExprV2PagedMkForall a34 n14 e24 e33 .default
  let a35 := p34.fst
  let e34 := p34.snd
  let p35 ← psKernelExprV2PagedMkForall a35 n12 e19 e34 .implicit
  let a36 := p35.fst
  let e35 := p35.snd
  let p36 ← psKernelExprV2PagedMkForall a36 n8 e1 e35 .implicit
  let a37 := p36.fst
  let e36 := p36.snd
  let p37 ← psKernelExprV2PagedMkForall a37 n3 e0 e36 .implicit
  let a38 := p37.fst
  let e37 := p37.snd
  let p38 ← psKernelExprV2PagedMkLam a38 n14 e24 e1 .default
  let a39 := p38.fst
  let e38 := p38.snd
  let p39 ← psKernelExprV2PagedMkLam a39 n12 e19 e38 .default
  let a40 := p39.fst
  let e39 := p39.snd
  let p40 ← psKernelExprV2PagedMkLam a40 n8 e1 e39 .default
  let a41 := p40.fst
  let e40 := p40.snd
  let p41 ← psKernelExprV2PagedMkLam a41 n3 e0 e40 .implicit
  let a42 := p41.fst
  let e41 := p41.snd
  let n15 : PsKernelName := .str n0 "CNat"
  let u3 : PsKernelLevel := .succ u0
  let u4 : PsKernelLevel := .succ u3
  let p42 ← psKernelExprV2PagedMkSort a42 u4
  let a43 := p42.fst
  let e42 := p42.snd
  let n16 : PsKernelName := .str n0 "X"
  let p43 ← psKernelExprV2PagedMkSort a43 u3
  let a44 := p43.fst
  let e43 := p43.snd
  let p44 ← psKernelExprV2PagedMkForall a44 n8 e1 e2 .default
  let a45 := p44.fst
  let e44 := p44.snd
  let p45 ← psKernelExprV2PagedMkForall a45 n8 e2 e13 .default
  let a46 := p45.fst
  let e45 := p45.snd
  let p46 ← psKernelExprV2PagedMkForall a46 n8 e44 e45 .default
  let a47 := p46.fst
  let e46 := p46.snd
  let p47 ← psKernelExprV2PagedMkForall a47 n16 e43 e46 .default
  let a48 := p47.fst
  let e47 := p47.snd
  let n17 : PsKernelName := .str n0 "cmul"
  let p48 ← psKernelExprV2PagedMkConst a48 n15 []
  let a49 := p48.fst
  let e48 := p48.snd
  let n18 : PsKernelName := .str n0 "b"
  let p49 ← psKernelExprV2PagedMkForall a49 n18 e48 e48 .default
  let a50 := p49.fst
  let e49 := p49.snd
  let p50 ← psKernelExprV2PagedMkForall a50 n4 e48 e49 .default
  let a51 := p50.fst
  let e50 := p50.snd
  let n19 : PsKernelName := .str n0 "s"
  let p51 ← psKernelExprV2PagedMkApp a51 e13 e2
  let a52 := p51.fst
  let e51 := p51.snd
  let p52 ← psKernelExprV2PagedMkApp a52 e51 e1
  let a53 := p52.fst
  let e52 := p52.snd
  let p53 ← psKernelExprV2PagedMkApp a53 e30 e52
  let a54 := p53.fst
  let e53 := p53.snd
  let p54 ← psKernelExprV2PagedMkLam a54 n19 e44 e53 .default
  let a55 := p54.fst
  let e54 := p54.snd
  let p55 ← psKernelExprV2PagedMkLam a55 n16 e43 e54 .default
  let a56 := p55.fst
  let e55 := p55.snd
  let p56 ← psKernelExprV2PagedMkLam a56 n18 e48 e55 .default
  let a57 := p56.fst
  let e56 := p56.snd
  let p57 ← psKernelExprV2PagedMkLam a57 n4 e48 e56 .default
  let a58 := p57.fst
  let e57 := p57.snd
  let n20 : PsKernelName := .str n0 "kernel_church_numerals"
  let p58 ← psKernelExprV2PagedMkConst a58 n1 [u4]
  let a59 := p58.fst
  let e58 := p58.snd
  let p59 ← psKernelExprV2PagedMkApp a59 e58 e48
  let a60 := p59.fst
  let e59 := p59.snd
  let p60 ← psKernelExprV2PagedMkConst a60 n17 []
  let a61 := p60.fst
  let e60 := p60.snd
  let n21 : PsKernelName := .str n0 "z"
  let p61 ← psKernelExprV2PagedMkApp a61 e2 e1
  let a62 := p61.fst
  let e61 := p61.snd
  let p62 ← psKernelExprV2PagedMkApp a62 e2 e61
  let a63 := p62.fst
  let e62 := p62.snd
  let p63 ← psKernelExprV2PagedMkApp a63 e2 e62
  let a64 := p63.fst
  let e63 := p63.snd
  let p64 ← psKernelExprV2PagedMkApp a64 e2 e63
  let a65 := p64.fst
  let e64 := p64.snd
  let p65 ← psKernelExprV2PagedMkApp a65 e2 e64
  let a66 := p65.fst
  let e65 := p65.snd
  let p66 ← psKernelExprV2PagedMkApp a66 e2 e65
  let a67 := p66.fst
  let e66 := p66.snd
  let p67 ← psKernelExprV2PagedMkApp a67 e2 e66
  let a68 := p67.fst
  let e67 := p67.snd
  let p68 ← psKernelExprV2PagedMkApp a68 e2 e67
  let a69 := p68.fst
  let e68 := p68.snd
  let p69 ← psKernelExprV2PagedMkApp a69 e2 e68
  let a70 := p69.fst
  let e69 := p69.snd
  let p70 ← psKernelExprV2PagedMkApp a70 e2 e69
  let a71 := p70.fst
  let e70 := p70.snd
  let p71 ← psKernelExprV2PagedMkApp a71 e2 e70
  let a72 := p71.fst
  let e71 := p71.snd
  let p72 ← psKernelExprV2PagedMkApp a72 e2 e71
  let a73 := p72.fst
  let e72 := p72.snd
  let p73 ← psKernelExprV2PagedMkApp a73 e2 e72
  let a74 := p73.fst
  let e73 := p73.snd
  let p74 ← psKernelExprV2PagedMkApp a74 e2 e73
  let a75 := p74.fst
  let e74 := p74.snd
  let p75 ← psKernelExprV2PagedMkApp a75 e2 e74
  let a76 := p75.fst
  let e75 := p75.snd
  let p76 ← psKernelExprV2PagedMkApp a76 e2 e75
  let a77 := p76.fst
  let e76 := p76.snd
  let p77 ← psKernelExprV2PagedMkApp a77 e2 e76
  let a78 := p77.fst
  let e77 := p77.snd
  let p78 ← psKernelExprV2PagedMkApp a78 e2 e77
  let a79 := p78.fst
  let e78 := p78.snd
  let p79 ← psKernelExprV2PagedMkApp a79 e2 e78
  let a80 := p79.fst
  let e79 := p79.snd
  let p80 ← psKernelExprV2PagedMkApp a80 e2 e79
  let a81 := p80.fst
  let e80 := p80.snd
  let p81 ← psKernelExprV2PagedMkApp a81 e2 e80
  let a82 := p81.fst
  let e81 := p81.snd
  let p82 ← psKernelExprV2PagedMkApp a82 e2 e81
  let a83 := p82.fst
  let e82 := p82.snd
  let p83 ← psKernelExprV2PagedMkApp a83 e2 e82
  let a84 := p83.fst
  let e83 := p83.snd
  let p84 ← psKernelExprV2PagedMkApp a84 e2 e83
  let a85 := p84.fst
  let e84 := p84.snd
  let p85 ← psKernelExprV2PagedMkApp a85 e2 e84
  let a86 := p85.fst
  let e85 := p85.snd
  let p86 ← psKernelExprV2PagedMkApp a86 e2 e85
  let a87 := p86.fst
  let e86 := p86.snd
  let p87 ← psKernelExprV2PagedMkApp a87 e2 e86
  let a88 := p87.fst
  let e87 := p87.snd
  let p88 ← psKernelExprV2PagedMkApp a88 e2 e87
  let a89 := p88.fst
  let e88 := p88.snd
  let p89 ← psKernelExprV2PagedMkApp a89 e2 e88
  let a90 := p89.fst
  let e89 := p89.snd
  let p90 ← psKernelExprV2PagedMkApp a90 e2 e89
  let a91 := p90.fst
  let e90 := p90.snd
  let p91 ← psKernelExprV2PagedMkApp a91 e2 e90
  let a92 := p91.fst
  let e91 := p91.snd
  let p92 ← psKernelExprV2PagedMkApp a92 e2 e91
  let a93 := p92.fst
  let e92 := p92.snd
  let p93 ← psKernelExprV2PagedMkApp a93 e2 e92
  let a94 := p93.fst
  let e93 := p93.snd
  let p94 ← psKernelExprV2PagedMkApp a94 e2 e93
  let a95 := p94.fst
  let e94 := p94.snd
  let p95 ← psKernelExprV2PagedMkApp a95 e2 e94
  let a96 := p95.fst
  let e95 := p95.snd
  let p96 ← psKernelExprV2PagedMkApp a96 e2 e95
  let a97 := p96.fst
  let e96 := p96.snd
  let p97 ← psKernelExprV2PagedMkApp a97 e2 e96
  let a98 := p97.fst
  let e97 := p97.snd
  let p98 ← psKernelExprV2PagedMkApp a98 e2 e97
  let a99 := p98.fst
  let e98 := p98.snd
  let p99 ← psKernelExprV2PagedMkApp a99 e2 e98
  let a100 := p99.fst
  let e99 := p99.snd
  let p100 ← psKernelExprV2PagedMkApp a100 e2 e99
  let a101 := p100.fst
  let e100 := p100.snd
  let p101 ← psKernelExprV2PagedMkApp a101 e2 e100
  let a102 := p101.fst
  let e101 := p101.snd
  let p102 ← psKernelExprV2PagedMkApp a102 e2 e101
  let a103 := p102.fst
  let e102 := p102.snd
  let p103 ← psKernelExprV2PagedMkApp a103 e2 e102
  let a104 := p103.fst
  let e103 := p103.snd
  let p104 ← psKernelExprV2PagedMkApp a104 e2 e103
  let a105 := p104.fst
  let e104 := p104.snd
  let p105 ← psKernelExprV2PagedMkApp a105 e2 e104
  let a106 := p105.fst
  let e105 := p105.snd
  let p106 ← psKernelExprV2PagedMkApp a106 e2 e105
  let a107 := p106.fst
  let e106 := p106.snd
  let p107 ← psKernelExprV2PagedMkApp a107 e2 e106
  let a108 := p107.fst
  let e107 := p107.snd
  let p108 ← psKernelExprV2PagedMkApp a108 e2 e107
  let a109 := p108.fst
  let e108 := p108.snd
  let p109 ← psKernelExprV2PagedMkApp a109 e2 e108
  let a110 := p109.fst
  let e109 := p109.snd
  let p110 ← psKernelExprV2PagedMkApp a110 e2 e109
  let a111 := p110.fst
  let e110 := p110.snd
  let p111 ← psKernelExprV2PagedMkApp a111 e2 e110
  let a112 := p111.fst
  let e111 := p111.snd
  let p112 ← psKernelExprV2PagedMkApp a112 e2 e111
  let a113 := p112.fst
  let e112 := p112.snd
  let p113 ← psKernelExprV2PagedMkApp a113 e2 e112
  let a114 := p113.fst
  let e113 := p113.snd
  let p114 ← psKernelExprV2PagedMkApp a114 e2 e113
  let a115 := p114.fst
  let e114 := p114.snd
  let p115 ← psKernelExprV2PagedMkApp a115 e2 e114
  let a116 := p115.fst
  let e115 := p115.snd
  let p116 ← psKernelExprV2PagedMkApp a116 e2 e115
  let a117 := p116.fst
  let e116 := p116.snd
  let p117 ← psKernelExprV2PagedMkApp a117 e2 e116
  let a118 := p117.fst
  let e117 := p117.snd
  let p118 ← psKernelExprV2PagedMkApp a118 e2 e117
  let a119 := p118.fst
  let e118 := p118.snd
  let p119 ← psKernelExprV2PagedMkApp a119 e2 e118
  let a120 := p119.fst
  let e119 := p119.snd
  let p120 ← psKernelExprV2PagedMkApp a120 e2 e119
  let a121 := p120.fst
  let e120 := p120.snd
  let p121 ← psKernelExprV2PagedMkApp a121 e2 e120
  let a122 := p121.fst
  let e121 := p121.snd
  let p122 ← psKernelExprV2PagedMkApp a122 e2 e121
  let a123 := p122.fst
  let e122 := p122.snd
  let p123 ← psKernelExprV2PagedMkApp a123 e2 e122
  let a124 := p123.fst
  let e123 := p123.snd
  let p124 ← psKernelExprV2PagedMkApp a124 e2 e123
  let a125 := p124.fst
  let e124 := p124.snd
  let p125 ← psKernelExprV2PagedMkApp a125 e2 e124
  let a126 := p125.fst
  let e125 := p125.snd
  let p126 ← psKernelExprV2PagedMkApp a126 e2 e125
  let a127 := p126.fst
  let e126 := p126.snd
  let p127 ← psKernelExprV2PagedMkApp a127 e2 e126
  let a128 := p127.fst
  let e127 := p127.snd
  let p128 ← psKernelExprV2PagedMkApp a128 e2 e127
  let a129 := p128.fst
  let e128 := p128.snd
  let p129 ← psKernelExprV2PagedMkApp a129 e2 e128
  let a130 := p129.fst
  let e129 := p129.snd
  let p130 ← psKernelExprV2PagedMkApp a130 e2 e129
  let a131 := p130.fst
  let e130 := p130.snd
  let p131 ← psKernelExprV2PagedMkApp a131 e2 e130
  let a132 := p131.fst
  let e131 := p131.snd
  let p132 ← psKernelExprV2PagedMkApp a132 e2 e131
  let a133 := p132.fst
  let e132 := p132.snd
  let p133 ← psKernelExprV2PagedMkApp a133 e2 e132
  let a134 := p133.fst
  let e133 := p133.snd
  let p134 ← psKernelExprV2PagedMkApp a134 e2 e133
  let a135 := p134.fst
  let e134 := p134.snd
  let p135 ← psKernelExprV2PagedMkApp a135 e2 e134
  let a136 := p135.fst
  let e135 := p135.snd
  let p136 ← psKernelExprV2PagedMkApp a136 e2 e135
  let a137 := p136.fst
  let e136 := p136.snd
  let p137 ← psKernelExprV2PagedMkApp a137 e2 e136
  let a138 := p137.fst
  let e137 := p137.snd
  let p138 ← psKernelExprV2PagedMkApp a138 e2 e137
  let a139 := p138.fst
  let e138 := p138.snd
  let p139 ← psKernelExprV2PagedMkApp a139 e2 e138
  let a140 := p139.fst
  let e139 := p139.snd
  let p140 ← psKernelExprV2PagedMkApp a140 e2 e139
  let a141 := p140.fst
  let e140 := p140.snd
  let p141 ← psKernelExprV2PagedMkApp a141 e2 e140
  let a142 := p141.fst
  let e141 := p141.snd
  let p142 ← psKernelExprV2PagedMkApp a142 e2 e141
  let a143 := p142.fst
  let e142 := p142.snd
  let p143 ← psKernelExprV2PagedMkApp a143 e2 e142
  let a144 := p143.fst
  let e143 := p143.snd
  let p144 ← psKernelExprV2PagedMkApp a144 e2 e143
  let a145 := p144.fst
  let e144 := p144.snd
  let p145 ← psKernelExprV2PagedMkApp a145 e2 e144
  let a146 := p145.fst
  let e145 := p145.snd
  let p146 ← psKernelExprV2PagedMkApp a146 e2 e145
  let a147 := p146.fst
  let e146 := p146.snd
  let p147 ← psKernelExprV2PagedMkApp a147 e2 e146
  let a148 := p147.fst
  let e147 := p147.snd
  let p148 ← psKernelExprV2PagedMkApp a148 e2 e147
  let a149 := p148.fst
  let e148 := p148.snd
  let p149 ← psKernelExprV2PagedMkApp a149 e2 e148
  let a150 := p149.fst
  let e149 := p149.snd
  let p150 ← psKernelExprV2PagedMkApp a150 e2 e149
  let a151 := p150.fst
  let e150 := p150.snd
  let p151 ← psKernelExprV2PagedMkApp a151 e2 e150
  let a152 := p151.fst
  let e151 := p151.snd
  let p152 ← psKernelExprV2PagedMkApp a152 e2 e151
  let a153 := p152.fst
  let e152 := p152.snd
  let p153 ← psKernelExprV2PagedMkApp a153 e2 e152
  let a154 := p153.fst
  let e153 := p153.snd
  let p154 ← psKernelExprV2PagedMkApp a154 e2 e153
  let a155 := p154.fst
  let e154 := p154.snd
  let p155 ← psKernelExprV2PagedMkApp a155 e2 e154
  let a156 := p155.fst
  let e155 := p155.snd
  let p156 ← psKernelExprV2PagedMkApp a156 e2 e155
  let a157 := p156.fst
  let e156 := p156.snd
  let p157 ← psKernelExprV2PagedMkApp a157 e2 e156
  let a158 := p157.fst
  let e157 := p157.snd
  let p158 ← psKernelExprV2PagedMkApp a158 e2 e157
  let a159 := p158.fst
  let e158 := p158.snd
  let p159 ← psKernelExprV2PagedMkApp a159 e2 e158
  let a160 := p159.fst
  let e159 := p159.snd
  let p160 ← psKernelExprV2PagedMkApp a160 e2 e159
  let a161 := p160.fst
  let e160 := p160.snd
  let p161 ← psKernelExprV2PagedMkApp a161 e2 e160
  let a162 := p161.fst
  let e161 := p161.snd
  let p162 ← psKernelExprV2PagedMkApp a162 e2 e161
  let a163 := p162.fst
  let e162 := p162.snd
  let p163 ← psKernelExprV2PagedMkApp a163 e2 e162
  let a164 := p163.fst
  let e163 := p163.snd
  let p164 ← psKernelExprV2PagedMkApp a164 e2 e163
  let a165 := p164.fst
  let e164 := p164.snd
  let p165 ← psKernelExprV2PagedMkApp a165 e2 e164
  let a166 := p165.fst
  let e165 := p165.snd
  let p166 ← psKernelExprV2PagedMkApp a166 e2 e165
  let a167 := p166.fst
  let e166 := p166.snd
  let p167 ← psKernelExprV2PagedMkApp a167 e2 e166
  let a168 := p167.fst
  let e167 := p167.snd
  let p168 ← psKernelExprV2PagedMkApp a168 e2 e167
  let a169 := p168.fst
  let e168 := p168.snd
  let p169 ← psKernelExprV2PagedMkApp a169 e2 e168
  let a170 := p169.fst
  let e169 := p169.snd
  let p170 ← psKernelExprV2PagedMkApp a170 e2 e169
  let a171 := p170.fst
  let e170 := p170.snd
  let p171 ← psKernelExprV2PagedMkApp a171 e2 e170
  let a172 := p171.fst
  let e171 := p171.snd
  let p172 ← psKernelExprV2PagedMkApp a172 e2 e171
  let a173 := p172.fst
  let e172 := p172.snd
  let p173 ← psKernelExprV2PagedMkApp a173 e2 e172
  let a174 := p173.fst
  let e173 := p173.snd
  let p174 ← psKernelExprV2PagedMkApp a174 e2 e173
  let a175 := p174.fst
  let e174 := p174.snd
  let p175 ← psKernelExprV2PagedMkApp a175 e2 e174
  let a176 := p175.fst
  let e175 := p175.snd
  let p176 ← psKernelExprV2PagedMkApp a176 e2 e175
  let a177 := p176.fst
  let e176 := p176.snd
  let p177 ← psKernelExprV2PagedMkApp a177 e2 e176
  let a178 := p177.fst
  let e177 := p177.snd
  let p178 ← psKernelExprV2PagedMkApp a178 e2 e177
  let a179 := p178.fst
  let e178 := p178.snd
  let p179 ← psKernelExprV2PagedMkApp a179 e2 e178
  let a180 := p179.fst
  let e179 := p179.snd
  let p180 ← psKernelExprV2PagedMkApp a180 e2 e179
  let a181 := p180.fst
  let e180 := p180.snd
  let p181 ← psKernelExprV2PagedMkLam a181 n21 e2 e180 .default
  let a182 := p181.fst
  let e181 := p181.snd
  let p182 ← psKernelExprV2PagedMkLam a182 n19 e44 e181 .default
  let a183 := p182.fst
  let e182 := p182.snd
  let p183 ← psKernelExprV2PagedMkLam a183 n16 e43 e182 .default
  let a184 := p183.fst
  let e183 := p183.snd
  let p184 ← psKernelExprV2PagedMkApp a184 e60 e183
  let a185 := p184.fst
  let e184 := p184.snd
  let p185 ← psKernelExprV2PagedMkApp a185 e2 e180
  let a186 := p185.fst
  let e185 := p185.snd
  let p186 ← psKernelExprV2PagedMkLam a186 n21 e2 e185 .default
  let a187 := p186.fst
  let e186 := p186.snd
  let p187 ← psKernelExprV2PagedMkLam a187 n19 e44 e186 .default
  let a188 := p187.fst
  let e187 := p187.snd
  let p188 ← psKernelExprV2PagedMkLam a188 n16 e43 e187 .default
  let a189 := p188.fst
  let e188 := p188.snd
  let p189 ← psKernelExprV2PagedMkApp a189 e184 e188
  let a190 := p189.fst
  let e189 := p189.snd
  let p190 ← psKernelExprV2PagedMkApp a190 e59 e189
  let a191 := p190.fst
  let e190 := p190.snd
  let p191 ← psKernelExprV2PagedMkApp a191 e60 e188
  let a192 := p191.fst
  let e191 := p191.snd
  let p192 ← psKernelExprV2PagedMkApp a192 e191 e183
  let a193 := p192.fst
  let e192 := p192.snd
  let p193 ← psKernelExprV2PagedMkApp a193 e190 e192
  let a194 := p193.fst
  let e193 := p193.snd
  let p194 ← psKernelExprV2PagedMkConst a194 n9 [u4]
  let a195 := p194.fst
  let e194 := p194.snd
  let p195 ← psKernelExprV2PagedMkApp a195 e194 e48
  let a196 := p195.fst
  let e195 := p195.snd
  let p196 ← psKernelExprV2PagedMkApp a196 e195 e189
  let a197 := p196.fst
  let e196 := p196.snd
  pure (a197, [(.ordinaryInductive [n2] 2 (PsKernelDagInductive.mk n1 e6 [PsKernelDagConstructor.mk n9 e12]) false), (.definitionDecl (PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk n15 [] e42) e47 (.regular 1) .safe)), (.definitionDecl (PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk n17 [] e50) e57 (.regular 2) .safe)), (.theoremDecl (PsKernelDagConstantBase.mk n20 [] e193) e196)])
