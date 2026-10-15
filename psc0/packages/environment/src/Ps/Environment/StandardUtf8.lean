import Ps.Environment.StandardByteArrayCollection
import Ps.Environment.StandardString

/-!
Selected UTF-8 model; Lean 4.35.0 Init/Data/String/{Decode,Basic,Defs}.lean.
Reference algorithms: Microsoft Corporation / Lean FRO, LLC, Apache-2.0.
Independently authored total Core builders over existing audited primitives.
The input byte count bounds recursion; no arbitrary evaluator fuel enters
the source semantics. Public optional decoding rejects invalid UTF-8.
-/
namespace PsStandardUtf8

private def n (value : Nat) : PsExpr := .lit (.natural value)
private def b (value : Bool) : PsExpr :=
  .constE (if value then psBoolTrueName else psBoolFalseName) []
private def call := psOrderCall
private def name (suffix : String) := psNameAppendStr (psRootName "$psc0Utf8") suffix
private def helper (suffix : String) (args : List PsExpr) : PsExpr :=
  psLogicApply (.constE (name suffix) []) args
private def nat := psOrderNat
private def bool : PsExpr := .constE psBoolName []
private def str : PsExpr := .constE psStringName []
private def bytes := psStandardByteArrayType
private def choose := psStandardStringIf
private def and (left right : PsExpr) := choose bool left right (b false)
private def lt (left right : PsExpr) := call "Nat.blt" [left,right]
private def le (left right : PsExpr) := call "Nat.ble" [left,right]
private def eq (left right : PsExpr) := call "Nat.beq" [left,right]
private def add (left right : PsExpr) := call "Nat.add" [left,right]
private def mul (left right : PsExpr) := call "Nat.mul" [left,right]
private def rem (value modulus : PsExpr) := call "Nat.mod" [value,modulus]
private def byte (source index : PsExpr) := call "UInt8.toNat"
  [psStandardArrayCall "getD" [psStandardByteArrayElement,
    psStandardByteArrayData source, index, call "UInt8.ofNat" [n 0]]]
private def decl (suffix : String) (type value : PsExpr) : PsDeclaration :=
  .definitionDecl (name suffix) [] type value

def width : PsDeclaration :=
  let v := PsExpr.fvar 0
  let body := choose nat (lt v (n 128)) (n 1)
    (choose nat (lt v (n 194)) (n 0)
      (choose nat (lt v (n 224)) (n 2)
        (choose nat (lt v (n 240)) (n 3)
          (choose nat (lt v (n 245)) (n 4) (n 0)))))
  decl "width" (psLogicPi 0 "lead" nat nat) (psLogicLam 0 "lead" nat body)

def code : PsDeclaration :=
  let source := PsExpr.fvar 0
  let index := PsExpr.fvar 1
  let width := PsExpr.fvar 2
  let lead := byte source index
  let tail := fun offset => rem (byte source (add index (n offset))) (n 64)
  let body := choose nat (eq width (n 1)) lead
    (choose nat (eq width (n 2))
      (add (mul (rem lead (n 32)) (n 64)) (tail 1))
      (choose nat (eq width (n 3))
        (add (add (mul (rem lead (n 16)) (n 4096)) (mul (tail 1) (n 64))) (tail 2))
        (add (add (add (mul (rem lead (n 8)) (n 262144))
          (mul (tail 1) (n 4096))) (mul (tail 2) (n 64))) (tail 3))))
  decl "code" (psLogicPi 0 "bytes" bytes (psLogicPi 1 "index" nat (psLogicPi 2 "width" nat nat)))
    (psLogicLam 0 "bytes" bytes (psLogicLam 1 "index" nat (psLogicLam 2 "width" nat body)))

def validAt : PsDeclaration :=
  let source := PsExpr.fvar 0
  let index := PsExpr.fvar 1
  let width := PsExpr.fvar 2
  let value := PsExpr.fvar 3
  let continuation := fun offset =>
    let value := byte source (add index (n offset))
    and (le (n 128) value) (lt value (n 192))
  let tails := choose bool (le width (n 1)) (b true)
    (and (continuation 1) (choose bool (le width (n 2)) (b true)
      (and (continuation 2) (choose bool (le width (n 3)) (b true) (continuation 3)))))
  let minimum := choose nat (eq width (n 1)) (n 0)
    (choose nat (eq width (n 2)) (n 128) (choose nat (eq width (n 3)) (n 2048) (n 65536)))
  let scalar := and (le minimum value) (and (lt value (n 1114112))
    (choose bool (lt value (n 55296)) (b true) (le (n 57344) value)))
  let checked := psLogicApply
    (psLogicLam 3 "code" nat scalar) [helper "code" [source,index,width]]
  let body := and (lt (n 0) width)
    (and (le (add index width) (call "ByteArray.size" [source])) (and tails checked))
  decl "validAt" (psLogicPi 0 "bytes" bytes (psLogicPi 1 "index" nat (psLogicPi 2 "width" nat bool)))
    (psLogicLam 0 "bytes" bytes (psLogicLam 1 "index" nat (psLogicLam 2 "width" nat body)))

def validateWorker : PsDeclaration :=
  let source := PsExpr.fvar 0
  let fuel := PsExpr.fvar 1
  let index := PsExpr.fvar 2
  let ih := PsExpr.fvar 4
  let width := PsExpr.fvar 5
  let size := call "ByteArray.size" [source]
  let arrow := psLogicPi 2 "index" nat bool
  let finished := eq index size
  let step := choose bool (lt index size)
    (psLogicApply (psLogicLam 5 "width" nat
      (and (helper "validAt" [source,index,width]) (.app ih (add index width))))
      [helper "width" [byte source index]]) finished
  let body := psOrderNatRec (.succ .zero) (psLogicLam 3 "_" nat arrow)
    (psLogicLam 2 "index" nat finished)
    (psLogicLam 3 "_" nat (psLogicLam 4 "ih" arrow (psLogicLam 2 "index" nat step))) fuel
  decl "validateWorker" (psLogicPi 0 "bytes" bytes (psLogicPi 1 "fuel" nat arrow))
    (psLogicLam 0 "bytes" bytes (psLogicLam 1 "fuel" nat body))

def decodeWorker : PsDeclaration :=
  let source := PsExpr.fvar 0
  let fuel := PsExpr.fvar 1
  let index := PsExpr.fvar 2
  let acc := PsExpr.fvar 3
  let ih := PsExpr.fvar 5
  let width := PsExpr.fvar 6
  let size := call "ByteArray.size" [source]
  let arrow := psLogicPi 2 "index" nat (psLogicPi 3 "acc" str str)
  let bind := fun body => psLogicLam 2 "index" nat (psLogicLam 3 "acc" str body)
  let empty := PsExpr.lit (.string "")
  let finished := choose str (eq index size) acc empty
  let scalar : PsExpr := .app (.constE psCharOfNatName []) (helper "code" [source,index,width])
  let step := choose str (lt index size)
    (psLogicApply (psLogicLam 6 "width" nat
      (choose str (helper "validAt" [source,index,width])
        (psLogicApply ih [add index width, psLogicApply (.constE psStringPushName []) [acc,scalar]])
        empty)) [helper "width" [byte source index]]) finished
  let body := psOrderNatRec (.succ .zero) (psLogicLam 4 "_" nat arrow)
    (bind finished)
    (psLogicLam 4 "_" nat (psLogicLam 5 "ih" arrow (bind step))) fuel
  decl "decodeWorker" (psLogicPi 0 "bytes" bytes (psLogicPi 1 "fuel" nat arrow))
    (psLogicLam 0 "bytes" bytes (psLogicLam 1 "fuel" nat body))

def encodeChar : PsDeclaration :=
  let acc := PsExpr.fvar 0
  let code := PsExpr.fvar 1
  let div := fun n' => call "Nat.div" [code,n n']
  let push := fun array byte => call "ByteArray.push" [array,call "UInt8.ofNat" [byte]]
  let trail := fun x => add (n 128) (rem x (n 64))
  let two := push (push acc (add (n 192) (div 64))) (trail code)
  let three := push (push (push acc (add (n 224) (div 4096))) (trail (div 64))) (trail code)
  let four := push (push (push (push acc (add (n 240) (div 262144)))
    (trail (div 4096))) (trail (div 64))) (trail code)
  let body := choose bytes (lt code (n 128)) (push acc code)
    (choose bytes (lt code (n 2048)) two (choose bytes (lt code (n 65536)) three four))
  decl "encodeChar" (psLogicPi 0 "acc" bytes (psLogicPi 1 "code" nat bytes))
    (psLogicLam 0 "acc" bytes (psLogicLam 1 "code" nat body))

def encodeWorker : PsDeclaration :=
  let source := PsExpr.fvar 0
  let fuel := PsExpr.fvar 1
  let index := PsExpr.fvar 2
  let acc := PsExpr.fvar 3
  let ih := PsExpr.fvar 5
  let arrow := psLogicPi 2 "index" nat (psLogicPi 3 "acc" bytes bytes)
  let bind := fun body => psLogicLam 2 "index" nat (psLogicLam 3 "acc" bytes body)
  let scalar : PsExpr := .app (.constE psCharToNatName [])
    (psLogicApply (.constE psStringGetName []) [source,index])
  let step := choose bytes (psLogicApply (.constE psStringAtEndName []) [source,index]) acc
    (psLogicApply ih [psLogicApply (.constE psStringNextName []) [source,index],
      helper "encodeChar" [acc,scalar]])
  let body := psOrderNatRec (.succ .zero) (psLogicLam 4 "_" nat arrow)
    (bind acc) (psLogicLam 4 "_" nat (psLogicLam 5 "ih" arrow (bind step))) fuel
  decl "encodeWorker" (psLogicPi 0 "source" str (psLogicPi 1 "fuel" nat arrow))
    (psLogicLam 0 "source" str (psLogicLam 1 "fuel" nat body))

def validate : PsDeclaration := psOrderDecl "ByteArray.validateUTF8"
  (psLogicPi 0 "bytes" bytes bool)
  (psLogicLam 0 "bytes" bytes
    (helper "validateWorker" [.fvar 0,call "ByteArray.size" [.fvar 0],n 0]))

-- A total internal conversion; invalid input always returns the empty string.
-- Runtime overrides must retain this guard even when the public caller validates.
def decode : PsDeclaration := decl "decode"
  (psLogicPi 0 "bytes" bytes str)
  (psLogicLam 0 "bytes" bytes
    (helper "decodeWorker" [.fvar 0,call "ByteArray.size" [.fvar 0],n 0,.lit (.string "")]))

def encode : PsDeclaration := psOrderDecl "String.toUTF8"
  (psLogicPi 0 "a" str bytes)
  (psLogicLam 0 "a" str (helper "encodeWorker"
    [.fvar 0,.app (.constE psStringUtf8ByteSizeName []) (.fvar 0),n 0,call "ByteArray.empty" []]))

def fromOption : PsDeclaration :=
  let option := psSelfHostOptionOf str
  let body := choose option (call "ByteArray.validateUTF8" [.fvar 0])
    (psSelfHostOptionSomeOf str (helper "decode" [.fvar 0]))
    (psSelfHostOptionNoneOf str)
  psOrderDecl "String.fromUTF8?" (psLogicPi 0 "a" bytes option)
    (psLogicLam 0 "a" bytes body)

def declarations : List PsDeclaration :=
  [width,code,validAt,validateWorker,decodeWorker,encodeChar,encodeWorker,validate,decode,encode,fromOption]

def extend (environment : PsEnvironment) : PsEnvironment :=
  declarations.foldl psEnvironmentInsert environment

-- Only the public wrapper needs runtime code. Direct encode/validate/decode
-- applications use checked typed intrinsics; their total logical definitions
-- and private workers remain in the kernel environment, not the runtime closure.
def runtimeDeclarations : List PsDeclaration := [fromOption]

end PsStandardUtf8
