import Ps.Syntax.PrintLean
import Ps.Foundation.List
import Ps.Foundation.Name

-- Keep an anonymous explicit Pi as an ordinary arrow. The predecessor writer
-- prints (_ : A) -> B even inside a parameter type, while its binder reader
-- accepts A -> B there. Named and non-explicit binders keep their telescope.
def psPscv0ArrowDomain
    (type : PsSyntaxTerm) (printed : String) : String :=
  match type with
  | .forallE _ _ _ => psPrintLeanConcat3 "(" printed ")"
  | .lambda _ _ _ => psPrintLeanConcat3 "(" printed ")"
  | .letE _ _ _ _ _ | .haveE _ _ _ _ _ => psPrintLeanConcat3 "(" printed ")"
  | .ifE _ _ _ _ _ => psPrintLeanConcat3 "(" printed ")"
  | .matchMany _ _ _ _ => psPrintLeanConcat3 "(" printed ")"
  | _ => printed

def psPscv0PrintLeanTypeWithFuel (fuel : Nat) :
    PsSyntaxTerm -> Except PsSourcePrintError String :=
  match fuel with
  | 0 => fun (_term : PsSyntaxTerm) => Except.error PsSourcePrintError.fuelExhausted
  | remaining + 1 =>
      let smaller : PsSyntaxTerm -> Except PsSourcePrintError String :=
        psPscv0PrintLeanTypeWithFuel remaining;
      fun (term : PsSyntaxTerm) =>
        match term with
        | .forallE binders body _ =>
            let printBinder : Prod PsSyntaxBinderHead PsSyntaxTerm -> Except PsSourcePrintError String :=
              fun (binder : Prod PsSyntaxBinderHead PsSyntaxTerm) => do
                let head := binder.fst
                let typeText ← smaller binder.snd
                let anonymous := match head.kind with
                  | .explicit => head.name.segments == ["_"] && head.moreNames.isEmpty
                  | _ => false
                if anonymous then return psPscv0ArrowDomain binder.snd typeText
                psPrintTypedBinder head typeText;
            match psListMapExcept printBinder binders with
            | Except.error error => Except.error error
            | Except.ok domains =>
                match smaller body with
                | Except.error error => Except.error error
                | Except.ok codomain => Except.ok (psPrintArrowChain domains codomain)
        | .app fn args _ =>
            if psSyntaxTermSimpleForApplication fn then
              match smaller fn with
              | Except.error error => Except.error error
              | Except.ok head =>
                  let printArgument : PsSyntaxTerm -> Except PsSourcePrintError String :=
                    fun (argument : PsSyntaxTerm) =>
                      match smaller argument with
                      | Except.error error => Except.error error
                      | Except.ok printed =>
                          if psSyntaxTermSimpleForApplication argument then Except.ok printed
                          else Except.ok (psPrintLeanConcat3 "(" printed ")");
                  match psListMapExcept printArgument args with
                  | Except.error error => Except.error error
                  | Except.ok arguments => Except.ok (psPrintLeanConcat2 head (psPrintLeanSpaceJoinedSuffix arguments))
            else Except.error PsSourcePrintError.unsupportedApplication
        | _ => psPrintLeanTerm term

def psPscv0PrintLeanType (term : PsSyntaxTerm) : Except PsSourcePrintError String :=
  psPscv0PrintLeanTypeWithFuel 4096 term

def psPscv0PrintLeanBinder (binder : Prod PsSyntaxBinderHead PsSyntaxTerm) :
    Except PsSourcePrintError String := do
  let typeText ← psPscv0PrintLeanType binder.snd
  psPrintTypedBinder binder.fst typeText
