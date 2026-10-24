import Ps.Bridge.CheckedAdmissions

namespace PsCodecSpineReference
def psEncodeCodecExpr
    (expr : PsExpr) :
    Except PsCheckedAdmissionCodecError String :=
  match expr with
  | .bvar index =>
      Except.ok
        ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedI) (String.Internal.append (":") ((psCheckedAdmissionNatToString index)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedB)))))) ("}"))))
  | .fvar _ =>
      Except.error PsCheckedAdmissionCodecError.freeVariable
  | .mvar _ =>
      Except.error PsCheckedAdmissionCodecError.expressionMetavariable
  | .sortE level =>
      match psEncodeCodecLevel level with
      | Except.error error => Except.error error
      | Except.ok encodedLevel =>
          Except.ok
            ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedSort)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedL) (String.Internal.append (":") ((encodedLevel)))))) ("}"))))
  | .constE name levels =>
      match psEncodeCodecLevels levels with
      | Except.error error => Except.error error
      | Except.ok encodedLevels =>
          Except.ok
            ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedConst)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedLs) (String.Internal.append (":") ((encodedLevels)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedN) (String.Internal.append (":") ((psEncodeCodecName name)))))))) ("}"))))
  | .app fn arg =>
      match psEncodeCodecExpr arg with
      | Except.error error => Except.error error
      | Except.ok encodedArg =>
          match psEncodeCodecExpr fn with
          | Except.error error => Except.error error
          | Except.ok encodedFn =>
              Except.ok
                ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedA) (String.Internal.append (":") ((encodedArg)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedF) (String.Internal.append (":") ((encodedFn)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedApp)))))))) ("}"))))
  | .lam name type body binder =>
      match psEncodeCodecExpr body with
      | Except.error error => Except.error error
      | Except.ok encodedBody =>
          match psEncodeCodecExpr type with
          | Except.error error => Except.error error
          | Except.ok encodedType =>
              Except.ok
                ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedB) (String.Internal.append (":") ((encodedBody)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedBi) (String.Internal.append (":") ((psJsonQuote (psEncodeCodecBinderInfo binder))))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedLam)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedN) (String.Internal.append (":") ((psEncodeCodecName name)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedT) (String.Internal.append (":") ((encodedType)))))))))))) ("}"))))
  | .forallE name type body binder =>
      match psEncodeCodecExpr body with
      | Except.error error => Except.error error
      | Except.ok encodedBody =>
          match psEncodeCodecExpr type with
          | Except.error error => Except.error error
          | Except.ok encodedType =>
              Except.ok
                ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedB) (String.Internal.append (":") ((encodedBody)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedBi) (String.Internal.append (":") ((psJsonQuote (psEncodeCodecBinderInfo binder))))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedForall)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedN) (String.Internal.append (":") ((psEncodeCodecName name)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedT) (String.Internal.append (":") ((encodedType)))))))))))) ("}"))))
  | .letE name type value body =>
      match psEncodeCodecExpr body with
      | Except.error error => Except.error error
      | Except.ok encodedBody =>
          match psEncodeCodecExpr type with
          | Except.error error => Except.error error
          | Except.ok encodedType =>
              match psEncodeCodecExpr value with
              | Except.error error => Except.error error
              | Except.ok encodedValue =>
                  Except.ok
                    ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedB) (String.Internal.append (":") ((encodedBody)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedLet)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedN) (String.Internal.append (":") ((psEncodeCodecName name)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedT) (String.Internal.append (":") ((encodedType)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedV) (String.Internal.append (":") ((encodedValue)))))))))))) ("}"))))
  | .lit literal =>
      match literal with
      | .natural value =>
          Except.ok
            ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedNat)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedV) (String.Internal.append (":") ((psJsonQuote (psCheckedAdmissionNatToString value))))))) ("}"))))
      | .string value =>
          Except.ok
            ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedStr)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedV) (String.Internal.append (":") ((psJsonQuote value)))))) ("}"))))
  | .proj typeName index value =>
      match psEncodeCodecExpr value with
      | Except.error error => Except.error error
      | Except.ok encodedValue =>
          Except.ok
            ((String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedE) (String.Internal.append (":") ((encodedValue)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedI) (String.Internal.append (":") ((psCheckedAdmissionNatToString index)))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") ((psCodecQuotedProj)))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedN) (String.Internal.append (":") ((psEncodeCodecName typeName)))))))))) ("}"))))

end PsCodecSpineReference
