import Ps.BackendEcma.Hash

namespace PsEcma

-- Runtime bodies use the same AST and layout as user code. These are trusted
-- implementations of the primitive ledger, not kernel-checked JS semantics.
def stackRuntime : List Stmt := [
  .binding false "__ps$implementations" "" (some (.newE "WeakMap" "<Function, Function>" [])),
  .functionD false false "__ps$run" "<R>" [{ name := "root", type := "__ps$Computation<R>" }] "R" [
    .binding false "pending" "__ps$Computation<unknown>[]" (some (.array [id "root"])),
    .binding true "value" "unknown" (some (id "undefined")),
    .whileE (bin "!==" (field (id "pending") "length") (num 0)) [
      const "next" (method (.index (id "pending") (bin "-" (field (id "pending") "length") (num 1))) "next" [id "value"]),
      .ifE (field (id "next") "done") [
        .expression (method (id "pending") "pop" []),
        set (id "value") (field (id "next") "value")
      ] [
        const "request" (field (id "next") "value"),
        const "implementation" (method (id "__ps$implementations") "get" [field (id "request") "fn"]),
        .ifE (id "implementation") [
          .expression (method (id "pending") "push" [
            call "Reflect.apply" [id "implementation", id "undefined", field (id "request") "args"]]),
          set (id "value") (id "undefined")
        ] [set (id "value") (call "Reflect.apply" [
          field (id "request") "fn", id "undefined", field (id "request") "args"])]
      ]
    ],
    ret (.cast (id "value") "R")
  ],
  .functionD false false "__ps$wrap" "<A extends unknown[], R>"
    [{ name := "implementation", type := "(...args: A) => __ps$Computation<R>" }]
    "(...args: A) => R" [
      const "fn" (.functionE false "" [{ name := "args", type := "A", rest := true }] "R" [
        ret (call "__ps$run" [call "implementation" [unary "..." (id "args")]])]),
      .expression (method (id "__ps$implementations") "set" [id "fn", id "implementation"]),
      ret (id "fn")
    ],
  .functionD false true "__ps$invoke" "<A extends unknown[], R>"
    [{ name := "fn", type := "(...args: A) => R" }, { name := "args", type := "A", rest := true }]
    "__ps$Computation<R>" [
      ret (.cast (unary "yield " (.object [("fn", id "fn"), ("args", id "args")])) "R")
    ]
]

def utf8Runtime : List Stmt := [
  .binding true "__ps$lastUtf8" "__ps$Utf8View | undefined" none,
  .binding true "__ps$previousUtf8" "__ps$Utf8View | undefined" none,
  .functionD false false "__ps$utf8Width" "" [{ name := "code", type := "number" }] "number" [
    ret (.conditional (bin "<=" (id "code") (num 127)) (num 1)
      (.conditional (bin "<=" (id "code") (num 2047)) (num 2)
        (.conditional (bin "<=" (id "code") (num 65535)) (num 3) (num 4))))
  ],
  .functionD false false "__ps$utf8" "" [{ name := "text", type := "string" }] "__ps$Utf8View" [
    .ifE (bin "===" (.member (id "__ps$lastUtf8") "text" true) (id "text")) [ret (id "__ps$lastUtf8")] [],
    .ifE (bin "===" (.member (id "__ps$previousUtf8") "text" true) (id "text")) [ret (id "__ps$previousUtf8")] [],
    letE "size" (num 0),
    .forOf "char" (id "text") [inc "size" (call "__ps$utf8Width" [
      bin "??" (method (id "char") "codePointAt" [num 0]) (num 0)])],
    const "positions" (.newE "Uint32Array" "" [bin "+" (id "size") (num 1)]),
    letE "byte" (num 0), letE "index" (num 0),
    .forOf "char" (id "text") [
      set (.index (id "positions") (id "byte")) (bin "+" (id "index") (num 1)),
      inc "byte" (call "__ps$utf8Width" [bin "??" (method (id "char") "codePointAt" [num 0]) (num 0)]),
      inc "index" (field (id "char") "length")
    ],
    set (.index (id "positions") (id "size")) (bin "+" (field (id "text") "length") (num 1)),
    set (id "__ps$previousUtf8") (id "__ps$lastUtf8"),
    ret (bin "=" (id "__ps$lastUtf8") (.object [
      ("text", id "text"), ("size", call "BigInt" [id "size"]), ("positions", id "positions")]))
  ],
  .functionD false false "__ps$stringGet" ""
    [{ name := "text", type := "string" }, { name := "position", type := "bigint" }] "string" [
    const "view" (call "__ps$utf8" [id "text"]),
    .ifE (bin "||" (bin "<" (id "position") (id "0n"))
      (bin ">=" (id "position") (field (id "view") "size"))) [ret (str "A")] [],
    const "index" (.index (field (id "view") "positions") (call "Number" [id "position"])),
    ret (.conditional (bin "===" (id "index") (num 0)) (str "A")
      (call "String.fromCodePoint" [bin "??" (method (id "text") "codePointAt" [
        bin "-" (id "index") (num 1)]) (num 65)]))
  ],
  .functionD false false "__ps$stringNext" ""
    [{ name := "text", type := "string" }, { name := "position", type := "bigint" }] "bigint" [
    const "view" (call "__ps$utf8" [id "text"]),
    .ifE (bin "||" (bin "<" (id "position") (id "0n"))
      (bin ">=" (id "position") (field (id "view") "size"))) [ret (bin "+" (id "position") (id "1n"))] [],
    const "index" (.index (field (id "view") "positions") (call "Number" [id "position"])),
    ret (.conditional (bin "===" (id "index") (num 0)) (bin "+" (id "position") (id "1n"))
      (bin "+" (id "position") (call "BigInt" [call "__ps$utf8Width" [
        bin "??" (method (id "text") "codePointAt" [bin "-" (id "index") (num 1)]) (num 0)]])))
  ],
  .functionD false false "__ps$stringExtract" ""
    [{ name := "text", type := "string" }, { name := "start", type := "bigint" },
      { name := "stop", type := "bigint" }] "string" [
    .ifE (bin ">=" (id "start") (id "stop")) [ret (str "")] [],
    letE "position" (id "0n"), letE "started" (id "false"), letE "result" (str ""),
    .forOf "char" (id "text") [
      const "width" (call "BigInt" [call "__ps$utf8Width" [
        bin "??" (method (id "char") "codePointAt" [num 0]) (num 0)]]),
      .ifE (unary "!" (id "started")) [
        .ifE (bin "===" (id "position") (id "start"))
          [set (id "started") (id "true")] [inc "position" (id "width"), .continueE]
      ] [],
      .ifE (bin "===" (id "position") (id "stop")) [ret (id "result")] [],
      inc "result" (id "char"), inc "position" (id "width")
    ],
    ret (id "result")
  ]
]

-- A private synchronous scratch view; no user callbacks run between writes
-- and reads. BigInt retains all 64 bits, and explicit endianness is portable.
def floatRuntime : List Stmt :=
  [const "__ps$floatBits" (.newE "DataView" "" [.newE "ArrayBuffer" "" [num 8]])] ++
  (["32", "64"].flatMap fun width =>
    let narrow := width == "32"
    let bitsType := if narrow then "number" else "bigint"
    let word := if narrow then "Uint32" else "BigUint64"
    let canonical := id (if narrow then "0x7fc00000" else "0x7ff8000000000000n")
    let helperName := "__ps$float" ++ width
    [.functionD false false (helperName ++ "OfBits") "" [{ name := "bits", type := bitsType }] "number" [
      .expression (method (id "__ps$floatBits") ("set" ++ word) [num 0, id "bits", id "true"]),
      const "value" (method (id "__ps$floatBits") ("getFloat" ++ width) [num 0, id "true"]),
      ret (.conditional (call "Number.isNaN" [id "value"]) (id "NaN") (id "value"))],
     .functionD false false (helperName ++ "ToBits") "" [{ name := "value", type := "number" }] bitsType [
      .ifE (call "Number.isNaN" [id "value"]) [ret canonical] [],
      .expression (method (id "__ps$floatBits") ("setFloat" ++ width) [num 0, id "value", id "true"]),
      ret (method (id "__ps$floatBits") ("get" ++ word) [num 0, id "true"])]])

def runtimeDoc (dialect : Dialect) : Except String PsDoc := do
  let types := if dialect == .typescript then [
    txt "type __ps$Request = { readonly fn: Function; readonly args: unknown[] };",
    txt "type __ps$Computation<R> = Generator<__ps$Request, R, unknown>;",
    txt "type __ps$Utf8View = { readonly text: string; readonly size: bigint; readonly positions: Uint32Array };"
  ] else []
  let bodies ← (stackRuntime ++ utf8Runtime ++ hashRuntime ++ floatRuntime).mapM (stmtDoc dialect 4096)
  return psDocJoin (cat [.hardline, .hardline]) (types ++ bodies)
end PsEcma
