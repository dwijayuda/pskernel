import Ps.BackendEcma.Syntax

namespace PsEcma

-- The validator is shared by JS and TS, including the legacy printer.
-- Fatal decoding is reached only after validation; ignoreBOM preserves U+FEFF.
def utf8CodecRuntime : List Stmt := [
  const "__ps$utf8Encoder" (.newE "TextEncoder" "" []),
  const "__ps$utf8Decoder" (.newE "TextDecoder" ""
    [str "utf-8", .object [("fatal",id "true"),("ignoreBOM",id "true")]]),
  .functionD false false "__ps$stringToUtf8" "" [{ name := "text", type := "string" }] "number[]" [
    ret (call "Array.from" [method (id "__ps$utf8Encoder") "encode" [id "text"]])],
  .functionD false false "__ps$utf8Valid" "" [{ name := "bytes", type := "readonly number[]" }] "boolean" [
    letE "index" (num 0),
    .whileE (bin "<" (id "index") (field (id "bytes") "length")) [
      const "lead" (.index (id "bytes") (id "index")),
      .ifE (bin "||" (bin "&&" (bin ">=" (id "lead") (num 128)) (bin "<" (id "lead") (num 194)))
        (bin ">=" (id "lead") (num 245))) [ret (id "false")] [],
      const "width" (.conditional (bin "<" (id "lead") (num 128)) (num 1)
        (.conditional (bin "<" (id "lead") (num 224)) (num 2)
          (.conditional (bin "<" (id "lead") (num 240)) (num 3) (num 4)))),
      .ifE (bin ">" (bin "+" (id "index") (id "width")) (field (id "bytes") "length"))
        [ret (id "false")] [],
      letE "code" (.conditional (bin "===" (id "width") (num 1)) (id "lead")
        (bin "&" (id "lead") (bin ">>" (num 127) (id "width")))),
      letE "offset" (num 1),
      .whileE (bin "<" (id "offset") (id "width")) [
        const "tail" (.index (id "bytes") (bin "+" (id "index") (id "offset"))),
        .ifE (bin "!==" (bin "&" (id "tail") (num 192)) (num 128)) [ret (id "false")] [],
        set (id "code") (bin "|" (bin "<<" (id "code") (num 6)) (bin "&" (id "tail") (num 63))),
        inc "offset" (num 1)],
      const "minimum" (.conditional (bin "===" (id "width") (num 1)) (num 0)
        (.conditional (bin "===" (id "width") (num 2)) (num 128)
          (.conditional (bin "===" (id "width") (num 3)) (num 2048) (num 65536)))),
      .ifE (bin "||" (bin "<" (id "code") (id "minimum"))
        (bin "||" (bin ">=" (id "code") (num 1114112))
          (bin "&&" (bin ">=" (id "code") (num 55296)) (bin "<" (id "code") (num 57344)))))
        [ret (id "false")] [],
      inc "index" (id "width")],
    ret (id "true")],
  .functionD false false "__ps$utf8Decode" "" [{ name := "bytes", type := "readonly number[]" }] "string" [
    .ifE (unary "!" (call "__ps$utf8Valid" [id "bytes"])) [ret (str "")] [],
    ret (method (id "__ps$utf8Decoder") "decode" [.newE "Uint8Array" "" [id "bytes"]])]
]
end PsEcma
