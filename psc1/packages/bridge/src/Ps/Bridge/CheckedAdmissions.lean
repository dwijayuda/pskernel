import Ps.Bridge.Json
import Ps.Core.Declaration
import Ps.Core.Abstract
import Ps.Core.Subst
import Ps.Core.Equality
import Ps.Foundation.List
import Ps.Environment.Basic

inductive PsCheckedAdmissionCodecError where
  | universeMetavariable
  | freeVariable
  | expressionMetavariable
  | missingConstructor (name : PsName)
  | mismatchedConstructor (name : PsName)
  | unsupportedDeclaration

def psCheckedAdmissionBoolNot (value : Bool) : Bool :=
  if value then false else true

def psCheckedAdmissionJsonField
    (key value : String) : Prod String String :=
  Prod.mk key value

def psCheckedAdmissionIncrementDecimalDigits
    (digits : List Nat) : List Nat :=
  match digits with
  | List.nil =>
      List.cons 1 List.nil
  | List.cons digit rest =>
      if Nat.beq digit 9 then
        List.cons
          0
          (psCheckedAdmissionIncrementDecimalDigits rest)
      else
        List.cons (Nat.succ digit) rest

def psCheckedAdmissionDecimalDigits
    (value : Nat) : List Nat :=
  match value with
  | Nat.zero =>
      List.cons 0 List.nil
  | Nat.succ predecessor =>
      psCheckedAdmissionIncrementDecimalDigits
        (psCheckedAdmissionDecimalDigits predecessor)

def psCheckedAdmissionDecimalDigitsToString
    (digits : List Nat) : String :=
  match digits with
  | List.nil =>
      ""
  | List.cons digit rest =>
      String.Internal.append
        (psCheckedAdmissionDecimalDigitsToString rest)
        (String.singleton
          (Char.ofNat (Nat.add 48 digit)))

def psCheckedAdmissionNatToString
    (value : Nat) : String :=
  Int.repr (Int.ofNat value)

-- Shared closed values retain the original opaque string semantics. Targets
-- with eager value declarations evaluate each fixed quote once per module.
def psCodecQuotedA : String := psJsonQuote "a"
def psCodecQuotedS : String := psJsonQuote "s"
def psCodecQuotedN : String := psJsonQuote "n"
def psCodecQuotedZ : String := psJsonQuote "z"
def psCodecQuotedMax : String := psJsonQuote "max"
def psCodecQuotedImax : String := psJsonQuote "imax"
def psCodecQuotedP : String := psJsonQuote "p"
def psCodecQuotedB : String := psJsonQuote "b"
def psCodecQuotedSort : String := psJsonQuote "sort"
def psCodecQuotedConst : String := psJsonQuote "const"
def psCodecQuotedApp : String := psJsonQuote "app"
def psCodecQuotedLam : String := psJsonQuote "lam"
def psCodecQuotedForall : String := psJsonQuote "forall"
def psCodecQuotedLet : String := psJsonQuote "let"
def psCodecQuotedNat : String := psJsonQuote "nat"
def psCodecQuotedStr : String := psJsonQuote "str"
def psCodecQuotedProj : String := psJsonQuote "proj"
def psCodecQuotedE : String := psJsonQuote "e"
def psCodecQuotedI : String := psJsonQuote "i"
def psCodecQuotedK : String := psJsonQuote "k"
def psCodecQuotedV : String := psJsonQuote "v"
def psCodecQuotedT : String := psJsonQuote "t"
def psCodecQuotedBi : String := psJsonQuote "bi"
def psCodecQuotedF : String := psJsonQuote "f"
def psCodecQuotedLs : String := psJsonQuote "ls"
def psCodecQuotedL : String := psJsonQuote "l"
def psCodecQuotedR : String := psJsonQuote "r"
def psCodecQuotedO : String := psJsonQuote "o"

def psEncodeCodecName (name : PsName) : String :=
  match name with
  | .anonymous =>
      (String.Internal.append ("{") (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedA)))) ("}")))
  | .str parent value =>
      let encodedParent : String :=
        psEncodeCodecName parent;
      (String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedS)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedP) (String.Internal.append (":") (encodedParent))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedV) (String.Internal.append (":") ((psJsonQuote value)))))))) ("}")))
  | .num parent value =>
      let encodedParent : String :=
        psEncodeCodecName parent;
      (String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedN)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedP) (String.Internal.append (":") (encodedParent))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedV) (String.Internal.append (":") ((psJsonQuote (psCheckedAdmissionNatToString value))))))))) ("}")))

def psEncodeCodecLevel
    (level : PsLevel) :
    Except PsCheckedAdmissionCodecError String :=
  match level with
  | .zero =>
      Except.ok
        ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedZ)))) ("}"))))
  | .succ inner =>
      match psEncodeCodecLevel inner with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          Except.ok
            ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedS)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedO) (String.Internal.append (":") ((encoded)))))) ("}"))))
  | .max left right =>
      match psEncodeCodecLevel left with
      | Except.error error => Except.error error
      | Except.ok encodedLeft =>
          match psEncodeCodecLevel right with
          | Except.error error => Except.error error
          | Except.ok encodedRight =>
              Except.ok
                ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedMax)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedL) (String.Internal.append (":") ((encodedLeft)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedR) (String.Internal.append (":") ((encodedRight)))))))) ("}"))))
  | .imax left right =>
      match psEncodeCodecLevel left with
      | Except.error error => Except.error error
      | Except.ok encodedLeft =>
          match psEncodeCodecLevel right with
          | Except.error error => Except.error error
          | Except.ok encodedRight =>
              Except.ok
                ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedImax)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedL) (String.Internal.append (":") ((encodedLeft)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedR) (String.Internal.append (":") ((encodedRight)))))))) ("}"))))
  | .param name =>
      Except.ok
        ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedP)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedN) (String.Internal.append (":") ((psEncodeCodecName name)))))) ("}"))))
  | .mvar _ =>
      Except.error PsCheckedAdmissionCodecError.universeMetavariable

def psEncodeCodecBinderInfo (binder : PsBinderInfo) : String :=
  match binder with
  | .explicit => "default"
  | .implicit => "implicit"
  | .strictImplicit => "strictImplicit"
  | .instanceImplicit => "instImplicit"

def psEncodeCodecLevelList
    (levels : List PsLevel) :
    Except PsCheckedAdmissionCodecError (List String) :=
  match levels with
  | List.nil =>
      Except.ok List.nil
  | List.cons level rest =>
      match psEncodeCodecLevel level with
      | Except.error error =>
          Except.error error
      | Except.ok encodedHead =>
          match psEncodeCodecLevelList rest with
          | Except.error error =>
              Except.error error
          | Except.ok encodedTail =>
              Except.ok (List.cons encodedHead encodedTail)

def psEncodeCodecLevels
    (levels : List PsLevel) :
    Except PsCheckedAdmissionCodecError String :=
  match psEncodeCodecLevelList levels with
  | Except.error error => Except.error error
  | Except.ok encoded => Except.ok (psJsonArray encoded)

-- Explicit return frames preserve the original opaque append tree exactly.
-- Only side branches recurse normally; expression spines and frame unwinding
-- use direct tail calls. No additional semantic fuel or stack allowance.
inductive PsCodecExprFrame where
  | app (encodedArg : String)
  | appArg (encodedFn : Except PsCheckedAdmissionCodecError String)
  | lam (name : PsName) (type : Except PsCheckedAdmissionCodecError String) (binder : PsBinderInfo)
  | forallE (name : PsName) (type : Except PsCheckedAdmissionCodecError String) (binder : PsBinderInfo)
  | letE (name : PsName) (type : Except PsCheckedAdmissionCodecError String) (value : Except PsCheckedAdmissionCodecError String)
  | proj (name : PsName) (index : Nat)

def psCodecExprApplyFrame (frame : PsCodecExprFrame)
    (result : Except PsCheckedAdmissionCodecError String) :
    Except PsCheckedAdmissionCodecError String :=
  match frame with
  | .app encodedArg =>
      match result with
      | Except.error error => Except.error error
      | Except.ok encodedFn =>
          Except.ok
            ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedA) (String.Internal.append (":") ((encodedArg)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedF) (String.Internal.append (":") ((encodedFn)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedApp)))))))) ("}"))))
  | .appArg encodedFn =>
      match result with
      | Except.error error => Except.error error
      | Except.ok encodedArg =>
          match encodedFn with
          | Except.error error => Except.error error
          | Except.ok encodedFn =>
              Except.ok
                ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedA) (String.Internal.append (":") ((encodedArg)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedF) (String.Internal.append (":") ((encodedFn)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedApp)))))))) ("}"))))
  | .lam name type binder =>
      match result with
      | Except.error error => Except.error error
      | Except.ok encodedBody =>
          match type with
          | Except.error error => Except.error error
          | Except.ok encodedType =>
              Except.ok
                ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedB) (String.Internal.append (":") ((encodedBody)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedBi) (String.Internal.append (":") ((psJsonQuote (psEncodeCodecBinderInfo binder))))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedLam)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedN) (String.Internal.append (":") ((psEncodeCodecName name)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedT) (String.Internal.append (":") ((encodedType)))))))))))) ("}"))))
  | .forallE name type binder =>
      match result with
      | Except.error error => Except.error error
      | Except.ok encodedBody =>
          match type with
          | Except.error error => Except.error error
          | Except.ok encodedType =>
              Except.ok
                ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedB) (String.Internal.append (":") ((encodedBody)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedBi) (String.Internal.append (":") ((psJsonQuote (psEncodeCodecBinderInfo binder))))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedForall)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedN) (String.Internal.append (":") ((psEncodeCodecName name)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedT) (String.Internal.append (":") ((encodedType)))))))))))) ("}"))))
  | .letE name type value =>
      match result with
      | Except.error error => Except.error error
      | Except.ok encodedBody =>
          match type with
          | Except.error error => Except.error error
          | Except.ok encodedType =>
              match value with
              | Except.error error => Except.error error
              | Except.ok encodedValue =>
                  Except.ok
                    ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedB) (String.Internal.append (":") ((encodedBody)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedLet)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedN) (String.Internal.append (":") ((psEncodeCodecName name)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedT) (String.Internal.append (":") ((encodedType)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedV) (String.Internal.append (":") ((encodedValue)))))))))))) ("}"))))
  | .proj typeName index =>
      match result with
      | Except.error error => Except.error error
      | Except.ok encodedValue =>
          Except.ok
            ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedE) (String.Internal.append (":") ((encodedValue)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedI) (String.Internal.append (":") ((psCheckedAdmissionNatToString index)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedProj)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedN) (String.Internal.append (":") ((psEncodeCodecName typeName)))))))))) ("}"))))

def psCodecExprResume (frames : List PsCodecExprFrame)
    (result : Except PsCheckedAdmissionCodecError String) :
    Except PsCheckedAdmissionCodecError String :=
  match frames with
  | List.nil => result
  | List.cons frame rest =>
      psCodecExprResume rest (psCodecExprApplyFrame frame result)

-- Compare the two return spines by an unbounded structural tail walk.
-- This chooses traversal order only, without a fuel or acceptance cutoff.
def psCodecPreferAppArg (fn : PsExpr) (arg : PsExpr) : Bool :=
  match fn with
  | .app parent _ =>
      match arg with
      | .app _ child => psCodecPreferAppArg parent child
      | .lam _ _ child _ => psCodecPreferAppArg parent child
      | .forallE _ _ child _ => psCodecPreferAppArg parent child
      | .letE _ _ _ child => psCodecPreferAppArg parent child
      | .proj _ _ child => psCodecPreferAppArg parent child
      | _ => false
  | .lam _ _ body _ =>
      match arg with
      | .app _ child => psCodecPreferAppArg body child
      | .lam _ _ child _ => psCodecPreferAppArg body child
      | .forallE _ _ child _ => psCodecPreferAppArg body child
      | .letE _ _ _ child => psCodecPreferAppArg body child
      | .proj _ _ child => psCodecPreferAppArg body child
      | _ => false
  | .forallE _ _ body _ =>
      match arg with
      | .app _ child => psCodecPreferAppArg body child
      | .lam _ _ child _ => psCodecPreferAppArg body child
      | .forallE _ _ child _ => psCodecPreferAppArg body child
      | .letE _ _ _ child => psCodecPreferAppArg body child
      | .proj _ _ child => psCodecPreferAppArg body child
      | _ => false
  | .letE _ _ _ body =>
      match arg with
      | .app _ child => psCodecPreferAppArg body child
      | .lam _ _ child _ => psCodecPreferAppArg body child
      | .forallE _ _ child _ => psCodecPreferAppArg body child
      | .letE _ _ _ child => psCodecPreferAppArg body child
      | .proj _ _ child => psCodecPreferAppArg body child
      | _ => false
  | .proj _ _ value =>
      match arg with
      | .app _ child => psCodecPreferAppArg value child
      | .lam _ _ child _ => psCodecPreferAppArg value child
      | .forallE _ _ child _ => psCodecPreferAppArg value child
      | .letE _ _ _ child => psCodecPreferAppArg value child
      | .proj _ _ child => psCodecPreferAppArg value child
      | _ => false
  | _ => true

def psEncodeCodecExprAcc (expr : PsExpr) (frames : List PsCodecExprFrame) :
    Except PsCheckedAdmissionCodecError String :=
  match expr with
  | .bvar index =>
      psCodecExprResume frames
        (Except.ok
            ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedI) (String.Internal.append (":") ((psCheckedAdmissionNatToString index)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedB)))))) ("}")))))
  | .fvar _ =>
      psCodecExprResume frames
        (Except.error PsCheckedAdmissionCodecError.freeVariable)
  | .mvar _ =>
      psCodecExprResume frames
        (Except.error PsCheckedAdmissionCodecError.expressionMetavariable)
  | .sortE level =>
      psCodecExprResume frames
        (match psEncodeCodecLevel level with
          | Except.error error => Except.error error
          | Except.ok encodedLevel =>
              Except.ok
                ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedSort)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedL) (String.Internal.append (":") ((encodedLevel)))))) ("}")))))
  | .constE name levels =>
      psCodecExprResume frames
        (match psEncodeCodecLevels levels with
          | Except.error error => Except.error error
          | Except.ok encodedLevels =>
              Except.ok
                ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedConst)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedLs) (String.Internal.append (":") ((encodedLevels)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedN) (String.Internal.append (":") ((psEncodeCodecName name)))))))) ("}")))))
  | .app fn arg =>
      if psCodecPreferAppArg fn arg then
        let encodedFn : Except PsCheckedAdmissionCodecError String :=
          psEncodeCodecExprAcc fn List.nil;
        psEncodeCodecExprAcc arg (List.cons (PsCodecExprFrame.appArg encodedFn) frames)
      else
        match psEncodeCodecExprAcc arg List.nil with
        | Except.error error => psCodecExprResume frames (Except.error error)
        | Except.ok encodedArg =>
            psEncodeCodecExprAcc fn (List.cons (PsCodecExprFrame.app encodedArg) frames)
  | .lam name type body binder =>
      let encodedType : Except PsCheckedAdmissionCodecError String :=
        psEncodeCodecExprAcc type List.nil;
      psEncodeCodecExprAcc body (List.cons (PsCodecExprFrame.lam name encodedType binder) frames)
  | .forallE name type body binder =>
      let encodedType : Except PsCheckedAdmissionCodecError String :=
        psEncodeCodecExprAcc type List.nil;
      psEncodeCodecExprAcc body (List.cons (PsCodecExprFrame.forallE name encodedType binder) frames)
  | .letE name type value body =>
      let encodedType : Except PsCheckedAdmissionCodecError String :=
        psEncodeCodecExprAcc type List.nil;
      let encodedValue : Except PsCheckedAdmissionCodecError String :=
        psEncodeCodecExprAcc value List.nil;
      psEncodeCodecExprAcc body (List.cons (PsCodecExprFrame.letE name encodedType encodedValue) frames)
  | .lit literal =>
      psCodecExprResume frames
        (match literal with
          | .natural value =>
              Except.ok
                ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedNat)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedV) (String.Internal.append (":") ((psJsonQuote (psCheckedAdmissionNatToString value))))))) ("}"))))
          | .string value =>
              Except.ok
                ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedStr)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedV) (String.Internal.append (":") ((psJsonQuote value)))))) ("}")))))
  | .proj typeName index value =>
      psEncodeCodecExprAcc value (List.cons (PsCodecExprFrame.proj typeName index) frames)

def psEncodeCodecExpr (expr : PsExpr) : Except PsCheckedAdmissionCodecError String :=
  psEncodeCodecExprAcc expr List.nil

def psEncodeCodecNames
    (names : List PsName) : List String :=
  match names with
  | List.nil =>
      List.nil
  | List.cons name rest =>
      List.cons
        (psEncodeCodecName name)
        (psEncodeCodecNames rest)

def psEncodeCodecNameList (names : List PsName) : String :=
  psJsonArray (psEncodeCodecNames names)

def psBridgeFindConstructorWorker
    (declarations : List PsDeclaration)
    (name : PsName) : Option PsConstructorInfo :=
  match declarations with
  | List.nil => Option.none
  | List.cons declaration rest =>
      match declaration with
      | .constructorDecl info =>
          if psNameEq info.name name then Option.some info
          else psBridgeFindConstructorWorker rest name
      | _ => psBridgeFindConstructorWorker rest name

def psBridgeFindConstructor
    (declarations : List PsDeclaration) : PsName -> Option PsConstructorInfo :=
  fun (name : PsName) => psBridgeFindConstructorWorker declarations name

def psEncodeCodecConstructor
    (allDeclarations : List PsDeclaration)
    (inductiveName : PsName)
    (constructorName : PsName) :
    Except PsCheckedAdmissionCodecError String :=
  match psBridgeFindConstructor allDeclarations constructorName with
  | none =>
      Except.error
        (PsCheckedAdmissionCodecError.missingConstructor constructorName)
  | some info =>
      if psCheckedAdmissionBoolNot (psNameEq info.inductiveName inductiveName) then
        Except.error
          (PsCheckedAdmissionCodecError.mismatchedConstructor constructorName)
      else
        match psEncodeCodecExpr info.type with
        | Except.error error => Except.error error
        | Except.ok encodedType =>
            Except.ok
              (psJsonObject [
                psCheckedAdmissionJsonField "n" (psEncodeCodecName info.name),
                psCheckedAdmissionJsonField "t" (encodedType)
              ])

def psEncodeCodecConstructors
    (allDeclarations : List PsDeclaration)
    (inductiveName : PsName)
    (constructors : List PsName) :
    Except PsCheckedAdmissionCodecError (List String) :=
  match constructors with
  | List.nil =>
      Except.ok List.nil
  | List.cons constructorName rest =>
      match
          psEncodeCodecConstructor
            allDeclarations
            inductiveName
            constructorName with
      | Except.error error =>
          Except.error error
      | Except.ok encodedHead =>
          match
              psEncodeCodecConstructors
                allDeclarations
                inductiveName
                rest with
          | Except.error error =>
              Except.error error
          | Except.ok encodedTail =>
              Except.ok (List.cons encodedHead encodedTail)

def psEncodeCodecInductive
    (allDeclarations : List PsDeclaration)
    (info : PsInductiveInfo) :
    Except PsCheckedAdmissionCodecError String :=
  match
      psEncodeCodecConstructors
        allDeclarations
        info.name
        info.constructors with
  | Except.error error => Except.error error
  | Except.ok encodedConstructors =>
      match psEncodeCodecExpr info.type with
      | Except.error error => Except.error error
      | Except.ok encodedType =>
          let encodedTypeEntry :=
            psJsonObject [
              psCheckedAdmissionJsonField "cs" (psJsonArray encodedConstructors),
              psCheckedAdmissionJsonField "n" (psEncodeCodecName info.name),
              psCheckedAdmissionJsonField "t" (encodedType)
            ];
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "lp" (psEncodeCodecNameList info.levelParams),
              psCheckedAdmissionJsonField "np" (psCheckedAdmissionNatToString info.numParams),
              psCheckedAdmissionJsonField "ts" (psJsonArray [encodedTypeEntry])
            ])

def psBridgeFindRegularHeightInBucketWorker
    (entries : List (PsName × Nat))
    (name : PsName) : Nat :=
  match entries with
  | List.nil => 0
  | List.cons entry rest =>
      if psNameEq (Prod.fst entry) name then Prod.snd entry
      else psBridgeFindRegularHeightInBucketWorker rest name

def psBridgeFindRegularHeightInBucket
    (entries : List (PsName × Nat)) : PsName -> Nat :=
  fun (name : PsName) => psBridgeFindRegularHeightInBucketWorker entries name

-- Heights are internal encoding metadata. Keep full structured-name equality
-- in collision buckets and retain the newest binding, as the original list did.
inductive PsBridgeHeightIndex where
  | empty
  | bucket (entries : List (PsName × Nat))
  | branch (left right : PsBridgeHeightIndex)

def psBridgeHeightBucketWorker
    (fuel : Nat) (index : PsBridgeHeightIndex) (hash : Nat) : List (PsName × Nat) :=
  match fuel with
  | Nat.zero =>
      match index with
      | PsBridgeHeightIndex.bucket entries => entries
      | _ => List.nil
  | Nat.succ remaining =>
      match index with
      | PsBridgeHeightIndex.branch left right =>
          if Nat.beq (Nat.mod hash 2) 0 then
            psBridgeHeightBucketWorker remaining left (Nat.div hash 2)
          else psBridgeHeightBucketWorker remaining right (Nat.div hash 2)
      | _ => List.nil

def psBridgeHeightBucket
    (fuel : Nat) : PsBridgeHeightIndex -> Nat -> List (PsName × Nat) :=
  fun (index : PsBridgeHeightIndex) (hash : Nat) =>
    psBridgeHeightBucketWorker fuel index hash

def psBridgeHeightInsertWorker (fuel : Nat) : PsBridgeHeightIndex -> Nat -> PsName -> Nat -> PsBridgeHeightIndex :=
  match fuel with
  | Nat.zero => fun (index : PsBridgeHeightIndex) (_hash : Nat) (name : PsName) (height : Nat) =>
      let entries : List (PsName × Nat) := match index with
        | PsBridgeHeightIndex.bucket values => values
        | _ => List.nil;
      PsBridgeHeightIndex.bucket (List.cons (Prod.mk name height) entries)
  | Nat.succ remaining =>
      fun (index : PsBridgeHeightIndex) (hash : Nat) (name : PsName) (height : Nat) =>
        let smaller : PsBridgeHeightIndex -> Nat -> PsName -> Nat -> PsBridgeHeightIndex := psBridgeHeightInsertWorker remaining;
        let left : PsBridgeHeightIndex := match index with
          | PsBridgeHeightIndex.branch value _ => value
          | _ => PsBridgeHeightIndex.empty;
        let right : PsBridgeHeightIndex := match index with
          | PsBridgeHeightIndex.branch _ value => value
          | _ => PsBridgeHeightIndex.empty;
        if Nat.beq (Nat.mod hash 2) 0 then
          PsBridgeHeightIndex.branch (smaller left (Nat.div hash 2) name height) right
        else PsBridgeHeightIndex.branch left (smaller right (Nat.div hash 2) name height)

def psBridgeHeightInsert (index : PsBridgeHeightIndex) (name : PsName) (height : Nat) : PsBridgeHeightIndex :=
  psBridgeHeightInsertWorker 16 index (psEnvironmentNameHash name) name height

def psBridgeFindRegularHeight (index : PsBridgeHeightIndex) (name : PsName) : Nat :=
  psBridgeFindRegularHeightInBucket (psBridgeHeightBucket 16 index (psEnvironmentNameHash name)) name

def psBridgeNatMax (left : Nat) : Nat -> Nat :=
  match left with
  | Nat.zero =>
      fun (right : Nat) => right
  | Nat.succ leftPred =>
      fun (right : Nat) =>
        let smaller : Nat -> Nat :=
          psBridgeNatMax leftPred;
        match right with
        | Nat.zero =>
            left
        | Nat.succ rightPred =>
            Nat.succ (smaller rightPred)

def psBridgeExprMaxRegularHeight
    (heights : PsBridgeHeightIndex)
    (expr : PsExpr) : Nat :=
  match expr with
  | .constE name _ =>
      psBridgeFindRegularHeight heights name
  | .app fn arg =>
      psBridgeNatMax
        (psBridgeExprMaxRegularHeight heights fn)
        (psBridgeExprMaxRegularHeight heights arg)
  | .lam _ type body _ =>
      psBridgeNatMax
        (psBridgeExprMaxRegularHeight heights type)
        (psBridgeExprMaxRegularHeight heights body)
  | .forallE _ type body _ =>
      psBridgeNatMax
        (psBridgeExprMaxRegularHeight heights type)
        (psBridgeExprMaxRegularHeight heights body)
  | .letE _ type value body =>
      psBridgeNatMax
        (psBridgeExprMaxRegularHeight heights type)
        (psBridgeNatMax
          (psBridgeExprMaxRegularHeight heights value)
          (psBridgeExprMaxRegularHeight heights body))
  | .proj _ _ value =>
      psBridgeExprMaxRegularHeight heights value
  | _ => 0

def psEncodeCodecDefinition
    (name : PsName)
    (levelParams : List PsName)
    (type value : PsExpr)
    (height : Nat) :
    Except PsCheckedAdmissionCodecError String :=
  match psEncodeCodecExpr type with
  | Except.error error => Except.error error
  | Except.ok encodedType =>
      match psEncodeCodecExpr value with
      | Except.error error => Except.error error
      | Except.ok encodedValue =>
          let hints :=
            psJsonObject [
              psCheckedAdmissionJsonField "h" (psJsonQuote (psCheckedAdmissionNatToString height)),
              psCheckedAdmissionJsonField "k" (psJsonQuote "regular")
            ];
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "h" (hints),
              psCheckedAdmissionJsonField "k" (psJsonQuote "definition"),
              psCheckedAdmissionJsonField "lp" (psEncodeCodecNameList levelParams),
              psCheckedAdmissionJsonField "n" (psEncodeCodecName name),
              psCheckedAdmissionJsonField "s" (psJsonQuote "safe"),
              psCheckedAdmissionJsonField "t" (encodedType),
              psCheckedAdmissionJsonField "v" (encodedValue)
            ])

def psEncodeCodecTheorem
    (name : PsName)
    (levelParams : List PsName)
    (type value : PsExpr) :
    Except PsCheckedAdmissionCodecError String :=
  match psEncodeCodecExpr type with
  | Except.error error => Except.error error
  | Except.ok encodedType =>
      match psEncodeCodecExpr value with
      | Except.error error => Except.error error
      | Except.ok encodedValue =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "k" (psJsonQuote "theorem"),
              psCheckedAdmissionJsonField "lp" (psEncodeCodecNameList levelParams),
              psCheckedAdmissionJsonField "n" (psEncodeCodecName name),
              psCheckedAdmissionJsonField "t" (encodedType),
              psCheckedAdmissionJsonField "v" (encodedValue)
            ])

def psEncodeCodecOpaque
    (name : PsName) (levelParams : List PsName) (type value : PsExpr) :
    Except PsCheckedAdmissionCodecError String := do
  let encodedType ← psEncodeCodecExpr type
  let encodedValue ← psEncodeCodecExpr value
  return psJsonObject [
    psCheckedAdmissionJsonField "k" (psJsonQuote "opaque"),
    psCheckedAdmissionJsonField "lp" (psEncodeCodecNameList levelParams),
    psCheckedAdmissionJsonField "n" (psEncodeCodecName name),
    psCheckedAdmissionJsonField "s" (psJsonQuote "safe"),
    psCheckedAdmissionJsonField "t" encodedType,
    psCheckedAdmissionJsonField "v" encodedValue
  ]

def psEncodeConstantAdmission (declaration : String) : String :=
  psJsonObject [
    psCheckedAdmissionJsonField "declaration" (declaration),
    psCheckedAdmissionJsonField "kind" (psJsonQuote "constant")
  ]

def psEncodeInductiveAdmission (declaration : String) : String :=
  psJsonObject [
    psCheckedAdmissionJsonField "declaration" (declaration),
    psCheckedAdmissionJsonField "kind" (psJsonQuote "inductive")
  ]

structure PsCheckedAdmissionEncodeState where
  heights : PsBridgeHeightIndex
  admissionsRev : List String

def psEncodeCheckedAdmissionsLoopWorker
    (allDeclarations : List PsDeclaration)
    (declarations : List PsDeclaration)
    (state : PsCheckedAdmissionEncodeState) :
    Except PsCheckedAdmissionCodecError PsCheckedAdmissionEncodeState :=
  match declarations with
  | List.nil => Except.ok state
  | List.cons declaration rest =>
      match declaration with
      | .definitionDecl name levelParams type value =>
          let height :=
            Nat.succ
              (psBridgeExprMaxRegularHeight
                state.heights
                value);
          match
              psEncodeCodecDefinition
                name
                levelParams
                type
                value
                height with
          | Except.error error =>
              Except.error error
          | Except.ok encoded =>
              psEncodeCheckedAdmissionsLoopWorker allDeclarations rest {
                heights := psBridgeHeightInsert state.heights name height
                admissionsRev :=
                  List.cons
                    (psEncodeConstantAdmission encoded)
                    state.admissionsRev
              }
      | .theoremDecl name levelParams type value =>
          match psEncodeCodecTheorem name levelParams type value with
          | Except.error error =>
              Except.error error
          | Except.ok encoded =>
              psEncodeCheckedAdmissionsLoopWorker allDeclarations rest {
                heights := state.heights
                admissionsRev :=
                  List.cons
                    (psEncodeConstantAdmission encoded)
                    state.admissionsRev
              }
      | .inductiveDecl info =>
          match psEncodeCodecInductive allDeclarations info with
          | Except.error error =>
              Except.error error
          | Except.ok encoded =>
              psEncodeCheckedAdmissionsLoopWorker allDeclarations rest {
                heights := state.heights
                admissionsRev :=
                  List.cons
                    (psEncodeInductiveAdmission encoded)
                    state.admissionsRev
              }
      | .constructorDecl _ =>
          psEncodeCheckedAdmissionsLoopWorker allDeclarations rest state
      | .recursorDecl _ =>
          psEncodeCheckedAdmissionsLoopWorker allDeclarations rest state
      | .axiomDecl _ _ _ =>
          Except.error
            PsCheckedAdmissionCodecError.unsupportedDeclaration
      | .opaqueDecl name levelParams type value =>
          match psEncodeCodecOpaque name levelParams type value with
          | Except.error error => Except.error error
          | Except.ok encoded =>
              psEncodeCheckedAdmissionsLoopWorker allDeclarations rest {
                heights := state.heights
                admissionsRev :=
                  List.cons (psEncodeConstantAdmission encoded) state.admissionsRev
              }
      | .partialDecl _ _ _ _ =>
          Except.error
            PsCheckedAdmissionCodecError.unsupportedDeclaration

def psEncodeCheckedAdmissionsLoop
    (allDeclarations : List PsDeclaration)
    (declarations : List PsDeclaration) :
    PsCheckedAdmissionEncodeState -> Except PsCheckedAdmissionCodecError PsCheckedAdmissionEncodeState :=
  fun (state : PsCheckedAdmissionEncodeState) =>
    psEncodeCheckedAdmissionsLoopWorker allDeclarations declarations state

def psCheckedAdmissionReverseStringsWorker
    (values : List String) (acc : List String) : List String :=
  match values with
  | List.nil => acc
  | List.cons head tail =>
      psCheckedAdmissionReverseStringsWorker tail (List.cons head acc)

def psCheckedAdmissionReverseStringsAcc
    (values : List String) :
    List String -> List String :=
  fun (acc : List String) => psCheckedAdmissionReverseStringsWorker values acc

def psCheckedAdmissionReverseStrings
    (values : List String) : List String :=
  psCheckedAdmissionReverseStringsAcc values List.nil

-- Lean generates additional motives and minors for nested recursive containers.
-- PSC's shallow recursor is implemented by an ordinary checked definition: its
-- auxiliary motives return a private unit in the same universe as the motive.
-- This changes only the admission representation, never the portable IR.
structure PsCheckedNestedBinder where
  id : Nat
  name : PsName
  type : PsExpr

def psCheckedNestedName (text : String) : PsName :=
  PsName.str PsName.anonymous text

def psCheckedNestedUnitName : PsName := psCheckedNestedName "_pscCheckedNestedUnit"

def psCheckedNestedLevelName : PsName := psCheckedNestedName "_pscCheckedMotive"

def psCheckedNestedLevel : PsLevel := PsLevel.param psCheckedNestedLevelName

def psCheckedNestedUnit : PsExpr :=
  PsExpr.constE psCheckedNestedUnitName [psCheckedNestedLevel]

def psCheckedNestedUnitValue : PsExpr :=
  PsExpr.constE (PsName.str psCheckedNestedUnitName "unit") [psCheckedNestedLevel]

def psCheckedNestedBind (lambda : Bool) (binders : List PsCheckedNestedBinder) : PsExpr -> PsExpr :=
  match binders with
  | List.nil => fun (body : PsExpr) => body
  | List.cons binder rest =>
      let smaller : PsExpr -> PsExpr := psCheckedNestedBind lambda rest;
      fun (body : PsExpr) =>
        let bound := psExprAbstractFVar binder.id (smaller body);
        if lambda then PsExpr.lam binder.name binder.type bound PsBinderInfo.explicit
        else PsExpr.forallE binder.name binder.type bound PsBinderInfo.explicit

def psCheckedNestedSize (expr : PsExpr) : Nat :=
  match expr with
  | PsExpr.app fn arg => Nat.succ (Nat.add (psCheckedNestedSize fn) (psCheckedNestedSize arg))
  | PsExpr.lam _ type body _ => Nat.succ (Nat.add (psCheckedNestedSize type) (psCheckedNestedSize body))
  | PsExpr.forallE _ type body _ => Nat.succ (Nat.add (psCheckedNestedSize type) (psCheckedNestedSize body))
  | PsExpr.letE _ type value body => Nat.succ (Nat.add (psCheckedNestedSize type) (Nat.add (psCheckedNestedSize value) (psCheckedNestedSize body)))
  | PsExpr.proj _ _ value => Nat.succ (psCheckedNestedSize value)
  | _ => 1

def psCheckedNestedOpenWorker (fuel : Nat) : Nat -> PsExpr -> List PsCheckedNestedBinder :=
  match fuel with
  | Nat.zero => fun (_id : Nat) (_type : PsExpr) => List.nil
  | Nat.succ remaining =>
      fun (id : Nat) (type : PsExpr) =>
        let smaller : Nat -> PsExpr -> List PsCheckedNestedBinder := psCheckedNestedOpenWorker remaining;
        match type with
        | PsExpr.forallE name domain body _ =>
            List.cons (PsCheckedNestedBinder.mk id name domain)
              (smaller (Nat.succ id) (psExprInstantiate1 body (PsExpr.fvar id)))
        | _ => List.nil

def psCheckedNestedOpen (id : Nat) (type : PsExpr) : List PsCheckedNestedBinder :=
  psCheckedNestedOpenWorker (psCheckedNestedSize type) id type

def psCheckedNestedContains (name : PsName) (expr : PsExpr) : Bool :=
  match expr with
  | PsExpr.constE other _ => psNameEq name other
  | PsExpr.app fn arg => if psCheckedNestedContains name fn then true else psCheckedNestedContains name arg
  | PsExpr.lam _ type body _ => if psCheckedNestedContains name type then true else psCheckedNestedContains name body
  | PsExpr.forallE _ type body _ => if psCheckedNestedContains name type then true else psCheckedNestedContains name body
  | PsExpr.letE _ type value body =>
      if psCheckedNestedContains name type then true
      else if psCheckedNestedContains name value then true
      else psCheckedNestedContains name body
  | PsExpr.proj _ _ value => psCheckedNestedContains name value
  | _ => false

-- A recursive family applied to its parameters/indices is still a direct
-- recursive field. Self occurrences inside an argument remain nested.
def psCheckedNestedDirect (name : PsName) (type : PsExpr) : Bool :=
  match type with
  | PsExpr.constE other _ => psNameEq name other
  | PsExpr.app fn arg =>
      if psCheckedNestedContains name arg then false else psCheckedNestedDirect name fn
  | _ => false

def psCheckedNestedAdd (name : PsName) (type : PsExpr) (shapes : List PsExpr) : List PsExpr :=
  if psCheckedNestedContains name type then
    if psCheckedNestedDirect name type then shapes
    else if psListAny (psExprAlphaEq type) shapes then shapes
    else psListAppend shapes [type]
  else shapes

def psCheckedNestedAddTypes (name : PsName) (types : List PsExpr) : List PsExpr -> List PsExpr :=
  match types with
  | List.nil => fun (shapes : List PsExpr) => shapes
  | List.cons type rest =>
      let smaller : List PsExpr -> List PsExpr := psCheckedNestedAddTypes name rest;
      fun (shapes : List PsExpr) => smaller (psCheckedNestedAdd name type shapes)

def psCheckedNestedBinderType (binder : PsCheckedNestedBinder) : PsExpr := binder.type

def psCheckedNestedBinderExpr (binder : PsCheckedNestedBinder) : PsExpr := PsExpr.fvar binder.id

def psCheckedNestedRoots (all : List PsDeclaration) (name : PsName) (constructors : List PsName) :
    List PsExpr -> Except PsCheckedAdmissionCodecError (List PsExpr) :=
  match constructors with
  | List.nil => fun (shapes : List PsExpr) => Except.ok shapes
  | List.cons constructor rest =>
      let smaller : List PsExpr -> Except PsCheckedAdmissionCodecError (List PsExpr) := psCheckedNestedRoots all name rest;
      fun (shapes : List PsExpr) =>
        match psBridgeFindConstructor all constructor with
        | Option.none => Except.error (PsCheckedAdmissionCodecError.missingConstructor constructor)
        | Option.some info =>
            smaller (psCheckedNestedAddTypes name (psListMap psCheckedNestedBinderType (psCheckedNestedOpen 0 info.type)) shapes)

def psCheckedNestedContainerFields (type : PsExpr) : Except PsCheckedAdmissionCodecError (List (List PsExpr)) :=
  match type with
  | PsExpr.app fn arg =>
      match fn with
      | PsExpr.constE name _ =>
          if psNameEq name (psCheckedNestedName "List") then
            Except.ok (List.cons List.nil (List.cons (List.cons arg (List.cons type List.nil)) List.nil))
          else if psNameEq name (psCheckedNestedName "Option") then
            Except.ok (List.cons List.nil (List.cons (List.cons arg List.nil) List.nil))
          else Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration
      | PsExpr.app head left =>
          match head with
          | PsExpr.constE name _ =>
              if psNameEq name (psCheckedNestedName "Prod") then Except.ok (List.cons (List.cons left (List.cons arg List.nil)) List.nil)
              else Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration
          | _ => Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration
      | _ => Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration
  | _ => Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration

def psCheckedNestedConcat {alpha : Type} (lists : List (List alpha)) : List alpha :=
  match lists with
  | List.nil => List.nil
  | List.cons values rest => psListAppend values (psCheckedNestedConcat rest)

def psCheckedNestedExpand (name : PsName) (fuel : Nat) : List PsExpr -> List PsExpr -> Except PsCheckedAdmissionCodecError (List PsExpr) :=
  match fuel with
  | Nat.zero => fun (pending : List PsExpr) (done : List PsExpr) =>
      if psListIsEmpty pending then Except.ok done else Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration
  | Nat.succ remaining =>
      fun (pending : List PsExpr) (done : List PsExpr) =>
        let smaller : List PsExpr -> List PsExpr -> Except PsCheckedAdmissionCodecError (List PsExpr) := psCheckedNestedExpand name remaining;
        match pending with
        | List.nil => Except.ok done
        | List.cons type rest =>
            match psCheckedNestedContainerFields type with
            | Except.error error => Except.error error
            | Except.ok fields =>
                let known := psListAppend done pending;
                let added := psCheckedNestedAddTypes name (psCheckedNestedConcat fields) known;
                let fresh := psListReverse (psListTake (Nat.sub (psListLength added) (psListLength known)) (psListReverse added));
                smaller (psListAppend rest fresh) (psListAppend done [type])

def psCheckedNestedSizes (types : List PsExpr) : Nat :=
  match types with
  | List.nil => 0
  | List.cons type rest => Nat.add (psCheckedNestedSize type) (psCheckedNestedSizes rest)

def psCheckedNestedApply (args : List PsExpr) : PsExpr -> PsExpr :=
  match args with
  | List.nil => fun (fn : PsExpr) => fn
  | List.cons arg rest =>
      let smaller : PsExpr -> PsExpr := psCheckedNestedApply rest;
      fun (fn : PsExpr) => smaller (PsExpr.app fn arg)

def psCheckedNestedHypotheses (name : PsName) (fields : List PsCheckedNestedBinder) : Nat -> List PsCheckedNestedBinder :=
  match fields with
  | List.nil => fun (_id : Nat) => List.nil
  | List.cons field rest =>
      let smaller : Nat -> List PsCheckedNestedBinder := psCheckedNestedHypotheses name rest;
      fun (id : Nat) =>
        if psCheckedNestedContains name field.type then
          let type := if psExprAlphaEq field.type (PsExpr.constE name List.nil)
            then PsExpr.app (PsExpr.fvar 0) (PsExpr.fvar field.id) else psCheckedNestedUnit;
          List.cons (PsCheckedNestedBinder.mk id (psCheckedNestedName "ih") type) (smaller (Nat.succ id))
        else smaller id

def psCheckedNestedDirectHypotheses (hypotheses : List PsCheckedNestedBinder) : List PsCheckedNestedBinder :=
  match hypotheses with
  | List.nil => List.nil
  | List.cons hypothesis rest =>
      let tail := psCheckedNestedDirectHypotheses rest;
      if psExprAlphaEq hypothesis.type psCheckedNestedUnit then tail else List.cons hypothesis tail

structure PsCheckedNestedMinor where
  binder : PsCheckedNestedBinder
  adapter : PsExpr

def psCheckedNestedMinors (all : List PsDeclaration) (name : PsName) (start : Nat) (constructors : List PsName) :
    Nat -> Except PsCheckedAdmissionCodecError (List PsCheckedNestedMinor) :=
  match constructors with
  | List.nil => fun (_id : Nat) => Except.ok List.nil
  | List.cons constructor rest =>
      let smaller : Nat -> Except PsCheckedAdmissionCodecError (List PsCheckedNestedMinor) := psCheckedNestedMinors all name start rest;
      fun (id : Nat) =>
        match psBridgeFindConstructor all constructor with
        | Option.none => Except.error (PsCheckedAdmissionCodecError.missingConstructor constructor)
        | Option.some info =>
            let fields := psCheckedNestedOpen start info.type;
            let hypotheses := psCheckedNestedHypotheses name fields (Nat.add start (psListLength fields));
            let direct := psCheckedNestedDirectHypotheses hypotheses;
            let value := psCheckedNestedApply (psListMap psCheckedNestedBinderExpr fields) (PsExpr.constE constructor List.nil);
            let type := psCheckedNestedBind false (psListAppend fields direct) (PsExpr.app (PsExpr.fvar 0) value);
            let body := psCheckedNestedApply (psListMap psCheckedNestedBinderExpr (psListAppend fields direct)) (PsExpr.fvar id);
            let adapter := psCheckedNestedBind true (psListAppend fields hypotheses) body;
            match smaller (Nat.succ id) with
            | Except.error error => Except.error error
            | Except.ok tail => Except.ok (List.cons (PsCheckedNestedMinor.mk (PsCheckedNestedBinder.mk id (psCheckedNestedName "minor") type) adapter) tail)

def psCheckedNestedMinorBinder (minor : PsCheckedNestedMinor) : PsCheckedNestedBinder := minor.binder

def psCheckedNestedMinorAdapter (minor : PsCheckedNestedMinor) : PsExpr := minor.adapter

def psCheckedNestedFields (types : List PsExpr) : Nat -> List PsCheckedNestedBinder :=
  match types with
  | List.nil => fun (_id : Nat) => List.nil
  | List.cons type rest =>
      let smaller : Nat -> List PsCheckedNestedBinder := psCheckedNestedFields rest;
      fun (id : Nat) => List.cons (PsCheckedNestedBinder.mk id (psCheckedNestedName "field") type) (smaller (Nat.succ id))

def psCheckedNestedAuxiliaryMinor (name : PsName) (start : Nat) (types : List PsExpr) : PsExpr :=
  let fields := psCheckedNestedFields types start;
  let hypotheses := psCheckedNestedHypotheses name fields (Nat.add start (psListLength fields));
  psCheckedNestedBind true (psListAppend fields hypotheses) psCheckedNestedUnitValue

def psCheckedNestedAuxiliaryMinors (name : PsName) (start : Nat) (shapes : List PsExpr) : Except PsCheckedAdmissionCodecError (List PsExpr) :=
  match shapes with
  | List.nil => Except.ok List.nil
  | List.cons shape rest =>
      match psCheckedNestedContainerFields shape with
      | Except.error error => Except.error error
      | Except.ok fields =>
          match psCheckedNestedAuxiliaryMinors name start rest with
          | Except.error error => Except.error error
          | Except.ok tail => Except.ok (psListAppend (psListMap (psCheckedNestedAuxiliaryMinor name start) fields) tail)

def psCheckedNestedMotive (type : PsExpr) : PsExpr :=
  PsExpr.lam (psCheckedNestedName "nested") type psCheckedNestedUnit PsBinderInfo.explicit

def psCheckedNestedWrapper (all : List PsDeclaration) (info : PsInductiveInfo) (shapes : List PsExpr) : Except PsCheckedAdmissionCodecError PsDeclaration :=
  if psListIsEmpty info.levelParams then
    if Nat.beq info.numParams 0 then
      if Nat.beq info.numIndices 0 then
        let majorId := Nat.succ (psListLength info.constructors);
        let start := Nat.succ majorId;
        let self := PsExpr.constE info.name List.nil;
        let major := PsCheckedNestedBinder.mk majorId (psCheckedNestedName "major") self;
        let motive := PsCheckedNestedBinder.mk 0 (psCheckedNestedName "motive")
          (PsExpr.forallE major.name self (PsExpr.sortE psCheckedNestedLevel) PsBinderInfo.explicit);
        match psCheckedNestedMinors all info.name start info.constructors 1 with
        | Except.error error => Except.error error
        | Except.ok minors =>
            match psCheckedNestedAuxiliaryMinors info.name start shapes with
            | Except.error error => Except.error error
            | Except.ok auxiliaries =>
                let binders := List.cons motive (psListAppend (psListMap psCheckedNestedMinorBinder minors) [major]);
                let args := List.cons (PsExpr.fvar 0) (psListAppend (psListMap psCheckedNestedMotive shapes)
                  (psListAppend (psListMap psCheckedNestedMinorAdapter minors) (psListAppend auxiliaries [PsExpr.fvar majorId])));
                let recursor := PsExpr.constE (PsName.str info.name "rec") [psCheckedNestedLevel];
                Except.ok (PsDeclaration.definitionDecl (PsName.str info.name "_pscShallowRec") [psCheckedNestedLevelName]
                  (psCheckedNestedBind false binders (PsExpr.app (PsExpr.fvar 0) (PsExpr.fvar majorId)))
                  (psCheckedNestedBind true binders (psCheckedNestedApply args recursor)))
      else Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration
    else Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration
  else Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration

-- The retained collector visits the tail first. Reverse the declaration spine
-- and thread its complete Except state to preserve exact rightmost-error order.
def psCheckedNestedCollectStep (all : List PsDeclaration) (declaration : PsDeclaration)
    (state : Except PsCheckedAdmissionCodecError (List (Prod PsName PsDeclaration))) :
    Except PsCheckedAdmissionCodecError (List (Prod PsName PsDeclaration)) :=
  match state with
  | Except.error error => Except.error error
  | Except.ok tail =>
      match declaration with
      | PsDeclaration.inductiveDecl info =>
          match psCheckedNestedRoots all info.name info.constructors List.nil with
          | Except.error error => Except.error error
          | Except.ok roots =>
              if psListIsEmpty roots then Except.ok tail
              else
                match psCheckedNestedExpand info.name (Nat.succ (psCheckedNestedSizes roots)) roots List.nil with
                | Except.error error => Except.error error
                | Except.ok shapes =>
                    match psCheckedNestedWrapper all info shapes with
                    | Except.error error => Except.error error
                    | Except.ok wrapper => Except.ok (List.cons (Prod.mk info.name wrapper) tail)
      | _ => Except.ok tail

def psCheckedNestedCollectAcc (all : List PsDeclaration) (reversed : List PsDeclaration)
    (state : Except PsCheckedAdmissionCodecError (List (Prod PsName PsDeclaration))) :
    Except PsCheckedAdmissionCodecError (List (Prod PsName PsDeclaration)) :=
  match reversed with
  | List.nil => state
  | List.cons declaration rest =>
      psCheckedNestedCollectAcc all rest (psCheckedNestedCollectStep all declaration state)

def psCheckedNestedCollect (all : List PsDeclaration) (declarations : List PsDeclaration) :
    Except PsCheckedAdmissionCodecError (List (Prod PsName PsDeclaration)) :=
  psCheckedNestedCollectAcc all (psListReverse declarations) (Except.ok List.nil)

def psCheckedNestedFind (wrappers : List (Prod PsName PsDeclaration)) : PsName -> Option PsDeclaration :=
  match wrappers with
  | List.nil => fun (_name : PsName) => Option.none
  | List.cons entry rest =>
      fun (name : PsName) =>
        let smaller : PsName -> Option PsDeclaration := psCheckedNestedFind rest;
        if psNameEq name (Prod.fst entry) then Option.some (Prod.snd entry) else smaller name

def psCheckedNestedRewrite (wrappers : List (Prod PsName PsDeclaration)) (expr : PsExpr) : PsExpr :=
  match expr with
  | PsExpr.constE name levels =>
      match name with
      | PsName.str parent component =>
          if psStringEq component "rec" then
            match psCheckedNestedFind wrappers parent with
            | Option.some _ => PsExpr.constE (PsName.str parent "_pscShallowRec") levels
            | Option.none => expr
          else expr
      | _ => expr
  | PsExpr.app fn arg => PsExpr.app (psCheckedNestedRewrite wrappers fn) (psCheckedNestedRewrite wrappers arg)
  | PsExpr.lam name type body binder => PsExpr.lam name (psCheckedNestedRewrite wrappers type) (psCheckedNestedRewrite wrappers body) binder
  | PsExpr.forallE name type body binder => PsExpr.forallE name (psCheckedNestedRewrite wrappers type) (psCheckedNestedRewrite wrappers body) binder
  | PsExpr.letE name type value body => PsExpr.letE name (psCheckedNestedRewrite wrappers type) (psCheckedNestedRewrite wrappers value) (psCheckedNestedRewrite wrappers body)
  | PsExpr.proj name index value => PsExpr.proj name index (psCheckedNestedRewrite wrappers value)
  | _ => expr

def psCheckedNestedNormalizeAcc (wrappers : List (Prod PsName PsDeclaration))
    (declarations acc : List PsDeclaration) : List PsDeclaration :=
  match declarations with
  | List.nil => psListReverse acc
  | List.cons declaration rest =>
      match declaration with
      | PsDeclaration.definitionDecl name levels type value =>
          psCheckedNestedNormalizeAcc wrappers rest
            (List.cons (PsDeclaration.definitionDecl name levels
              (psCheckedNestedRewrite wrappers type) (psCheckedNestedRewrite wrappers value)) acc)
      | PsDeclaration.theoremDecl name levels type value =>
          psCheckedNestedNormalizeAcc wrappers rest
            (List.cons (PsDeclaration.theoremDecl name levels
              (psCheckedNestedRewrite wrappers type) (psCheckedNestedRewrite wrappers value)) acc)
      | PsDeclaration.inductiveDecl info =>
          match psCheckedNestedFind wrappers info.name with
          | Option.none => psCheckedNestedNormalizeAcc wrappers rest (List.cons declaration acc)
          | Option.some wrapper =>
              psCheckedNestedNormalizeAcc wrappers rest (List.cons wrapper (List.cons declaration acc))
      | _ => psCheckedNestedNormalizeAcc wrappers rest (List.cons declaration acc)

def psCheckedNestedNormalize (wrappers : List (Prod PsName PsDeclaration))
    (declarations : List PsDeclaration) : List PsDeclaration :=
  psCheckedNestedNormalizeAcc wrappers declarations List.nil

def psCheckedNestedUnitDeclarations : List PsDeclaration :=
  let constructor := PsName.str psCheckedNestedUnitName "unit";
  List.cons (PsDeclaration.inductiveDecl
    (PsInductiveInfo.mk psCheckedNestedUnitName [psCheckedNestedLevelName]
      (PsExpr.sortE psCheckedNestedLevel) 0 0 [constructor] false))
    [PsDeclaration.constructorDecl (PsConstructorInfo.mk constructor [psCheckedNestedLevelName]
      psCheckedNestedUnit psCheckedNestedUnitName 0 0 0 List.nil)]

def psEncodeCheckedAdmissionsNormalized
    (declarations : List PsDeclaration) :
    Except PsCheckedAdmissionCodecError String :=
  match psEncodeCheckedAdmissionsLoop
      declarations
      declarations
      {
        heights := PsBridgeHeightIndex.empty
        admissionsRev := []
      } with
  | Except.error error => Except.error error
  | Except.ok state =>
      Except.ok
        (psJsonObject [
          psCheckedAdmissionJsonField "admissions" (psJsonArray (psCheckedAdmissionReverseStrings state.admissionsRev)),
          psCheckedAdmissionJsonField "format" (psJsonQuote "proofscript-checked-admissions"),
          psCheckedAdmissionJsonField "version" ("2")
        ])

def psEncodeCheckedAdmissionsCanonical
    (declarations : List PsDeclaration) : Except PsCheckedAdmissionCodecError String :=
  match psCheckedNestedCollect declarations declarations with
  | Except.error error => Except.error error
  | Except.ok wrappers =>
      if psListIsEmpty wrappers then psEncodeCheckedAdmissionsNormalized declarations
      else psEncodeCheckedAdmissionsNormalized
        (psListAppend psCheckedNestedUnitDeclarations (psCheckedNestedNormalize wrappers declarations))

def psEncodeCheckedAdmissionsText
    (declarations : List PsDeclaration) :
    Except PsCheckedAdmissionCodecError String :=
  match psEncodeCheckedAdmissionsCanonical declarations with
  | Except.error error => Except.error error
  | Except.ok encoded => Except.ok (String.Internal.append encoded "\n")
