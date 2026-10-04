import fs from "node:fs";
const file="C:/Users/user/Documents/Codex/2026-10-02/referenced-chatgpt-conversation-this-is-an/work/psc1kernel-selfhost-portable-wt/psc15selfhost/packages/pskernel-selfhost/src/Ps/KernelSelfHost/Inductive.lean";
let s=fs.readFileSync(file,"utf8");
const a=s.indexOf("def psKernelOpenSimpleHeaderParamsWorker");
const b=s.indexOf("\ndef psKernelOpenSimpleHeaderParams\n",a);
if(a<0||b<0) throw new Error("markers");
const repl=`def psKernelOpenSimpleHeaderParamsWorker
    (remainingParams : Nat) :
    Nat ->
    PsKernelCheckerSession ->
    PsKernelExpr ->
    List PsKernelOpenBinder ->
    Except String PsKernelOpenBindersResult :=
  match remainingParams with
  | Nat.zero =>
      fun
        (_fuel : Nat)
        (_session : PsKernelCheckerSession)
        (_type : PsKernelExpr)
        (_revParams : List PsKernelOpenBinder) =>
        Except.error "base"
  | Nat.succ remaining =>
      let smaller :
          Nat ->
          PsKernelCheckerSession ->
          PsKernelExpr ->
          List PsKernelOpenBinder ->
          Except String PsKernelOpenBindersResult :=
        psKernelOpenSimpleHeaderParamsWorker remaining;
      fun
        (fuel : Nat)
        (session : PsKernelCheckerSession)
        (type : PsKernelExpr)
        (revParams : List PsKernelOpenBinder) =>
        match psKernelOpenSimpleHeaderParamStep fuel session type with
        | Except.error error => Except.error error
        | Except.ok step =>
            let pair := Prod.fst step;
            smaller fuel (Prod.fst pair) (Prod.snd step)
              (List.cons (Prod.snd pair) revParams)
`;
fs.writeFileSync(file,s.slice(0,a)+repl+s.slice(b));
