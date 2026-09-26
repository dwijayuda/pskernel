import Ps.Bridge.Protocol

def psKernelBridgeNodeScript : String :=
  "const req=JSON.parse(process.argv[1]);" ++
  "const fs=await import('node:fs');" ++
  "const prefix=fs.existsSync('./packages/checked-core/dist/src/index.js')?'./':'../';" ++
  "const cc=await import(prefix+'packages/checked-core/dist/src/index.js');" ++
  "const codec=await import(prefix+'packages/checked-core/dist/src/codec-base.js');" ++
  "const envmod=await import(prefix+'packages/environment/dist/src/node.js');" ++
  "const kernel=await import(prefix+'dist/src/index.js');" ++
  "const protocol='proofscript-kernel-bridge';" ++
  "const version=1;" ++
  "const kernelFingerprint='lean-ts-kernel@0.1.0';" ++
  "const foundation='lean4:v4.34.0@293d5d0c0c3f3dded4688b3ccd6a33939ac5102b';" ++
  "const reply=(ok,value,error)=>JSON.stringify({" ++
    "foundation,kernel:kernelFingerprint,ok,protocol,value,version," ++
    "...(error===undefined?{}:{error})});" ++
  "try{" ++
    "if(req.protocol!==protocol)throw new Error('protocol mismatch');" ++
    "if(req.version!==version)throw new Error('version mismatch');" ++
    "if(req.kernel!==kernelFingerprint)throw new Error('kernel fingerprint mismatch');" ++
    "if(req.foundation!==foundation)throw new Error('foundation fingerprint mismatch');" ++
    "const base=envmod.requireLeanEnvironment(envmod.createLeanEnvironmentProvider());" ++
    "if(req.op==='ping'){process.stdout.write(reply(true,true));}" ++
    "else if(req.op==='lookup'){" ++
      "const name=codec.decodeCodecName(req.payload.name);" ++
      "const info=base.find(name);" ++
      "const value=info===undefined?null:{" ++
        "kind:info.kind," ++
        "name:codec.encodeCodecName(info.name)," ++
        "type:('type' in info)?codec.encodeCodecExpr(info.type):null};" ++
      "process.stdout.write(reply(true,value));" ++
    "}" ++
    "else if(req.op==='infer'){" ++
      "const expr=codec.decodeCodecExpr(req.payload.expr);" ++
      "const checker=new kernel.TypeChecker(base);" ++
      "const type=checker.check(expr);" ++
      "process.stdout.write(reply(true,codec.encodeCodecExpr(type)));" ++
    "}" ++
    "else if(req.op==='defeq'){" ++
      "const left=codec.decodeCodecExpr(req.payload.left);" ++
      "const right=codec.decodeCodecExpr(req.payload.right);" ++
      "const checker=new kernel.TypeChecker(base);" ++
      "process.stdout.write(reply(true,checker.isDefEq(left,right)));" ++
    "}" ++
    "else if(req.op==='replay'){" ++
      "const admissions=cc.decodeCheckedCoreAdmissions(req.payload);" ++
      "const checked=cc.admitCheckedCoreAdmissions(base,admissions);" ++
      "process.stdout.write(reply(true,{" ++
        "admissions:checked.admissions.length," ++
        "declarations:checked.declarations.length}));" ++
    "}" ++
    "else throw new Error('unknown bridge operation');" ++
  "}catch(error){" ++
    "const message=error instanceof Error?error.message:String(error);" ++
    "process.stdout.write(reply(false,null,message));" ++
  "}"

def psHostKernelRequest
    (request : String) : IO String := do
  let output ← IO.Process.output {
    cmd := "node"
    args := #[
      "--input-type=module",
      "--eval",
      psKernelBridgeNodeScript,
      request
    ]
  }
  if output.exitCode != 0 then
    throw
      (IO.userError
        ("PSC1_KERNEL_BRIDGE_HOST_FAILED:\n" ++
          output.stderr))
  pure output.stdout.trimAscii.toString

def psHostKernelCall
    (request : PsKernelBridgeRequest) :
    IO PsKernelBridgeResponse := do
  let encoded ←
    match psEncodeKernelBridgeRequest request with
    | Except.error _ =>
        throw
          (IO.userError
            "PSC1_KERNEL_BRIDGE_REQUEST_ENCODE_FAILED")
    | Except.ok value => pure value
  let response ← psHostKernelRequest encoded
  match psDecodeKernelBridgeResponse response with
  | Except.error _ =>
      throw
        (IO.userError
          "PSC1_KERNEL_BRIDGE_RESPONSE_DECODE_FAILED")
  | Except.ok value => pure value

def psHostKernelPing : IO Bool := do
  let response ←
    psHostKernelCall PsKernelBridgeRequest.ping
  match psKernelBridgeResponseBool response with
  | Except.error _ => pure false
  | Except.ok value => pure value

def psHostKernelLookup
    (name : PsName) :
    IO PsKernelBridgeResponse :=
  psHostKernelCall (PsKernelBridgeRequest.lookup name)

def psHostKernelInfer
    (expr : PsExpr) : IO PsExpr := do
  let response ←
    psHostKernelCall (PsKernelBridgeRequest.infer expr)
  match psKernelBridgeResponseExpr response with
  | Except.error _ =>
      throw
        (IO.userError
          "PSC1_KERNEL_BRIDGE_INFER_DECODE_FAILED")
  | Except.ok value => pure value

def psHostKernelDefEq
    (left right : PsExpr) : IO Bool := do
  let response ←
    psHostKernelCall
      (PsKernelBridgeRequest.defeq left right)
  match psKernelBridgeResponseBool response with
  | Except.error _ =>
      throw
        (IO.userError
          "PSC1_KERNEL_BRIDGE_DEFEQ_DECODE_FAILED")
  | Except.ok value => pure value

def psHostKernelReplay
    (declarations : List PsDeclaration) :
    IO PsKernelBridgeResponse :=
  psHostKernelCall
    (PsKernelBridgeRequest.replayAdmissions declarations)
