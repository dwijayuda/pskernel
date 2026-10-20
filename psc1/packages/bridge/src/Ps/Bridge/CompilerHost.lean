import Ps.Bridge.Json

/-- Portable transport only. These bytes are a request, never checking authority. -/
def psCompilerHostAdmissionRequest
    (requestId sourceClosureDigest target canonicalAdmissions : String) : String :=
  psJsonObject [
    ("admissions", psJsonQuote canonicalAdmissions),
    ("op", psJsonQuote "admit"),
    ("protocol", psJsonQuote "psc1-compiler-host/1"),
    ("requestId", psJsonQuote requestId),
    ("sourceClosureDigest", psJsonQuote sourceClosureDigest),
    ("target", psJsonQuote target)
  ]

/-- Compiler continuation correlation. Publication remains owned by the external
host, which independently checks and retains the exact canonical graph bytes. -/
def psCompilerHostReceiptMatches
    (expectedId expectedSource expectedGraph expectedTarget
     actualId actualSource actualGraph actualTarget checkerCommit : String)
    (accepted : Bool) : Bool :=
  if accepted then
    if psJsonStringEq expectedId actualId then
      if psJsonStringEq expectedSource actualSource then
        if psJsonStringEq expectedGraph actualGraph then
          if psJsonStringEq expectedTarget actualTarget then
            psJsonStringEq checkerCommit "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
          else false
        else false
      else false
    else false
  else false
