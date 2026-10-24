import Ps.Compiler.Ordinary

namespace OrdinaryExpansionReference

def psOrdinaryExpandWorker (declarations : List PsDeclaration) :
    PsEnvironment -> Except String (Prod (List PsDeclaration) (List PsName)) :=
  match declarations with
  | List.nil =>
      fun (environment : PsEnvironment) => Except.ok (Prod.mk List.nil List.nil)
  | List.cons declaration rest =>
      let smaller : PsEnvironment -> Except String (Prod (List PsDeclaration) (List PsName)) :=
        psOrdinaryExpandWorker rest;
      fun (environment : PsEnvironment) =>
        match declaration with
        | PsDeclaration.axiomDecl _ _ _ => Except.error "PSC1_SOURCE_AXIOM_FORBIDDEN"
        | PsDeclaration.opaqueDecl _ _ _ _ => Except.error "PSC1_SOURCE_OPAQUE_NOT_SELECTED"
        | PsDeclaration.partialDecl name levels type body =>
            match psWhnf environment psMetaEmpty psLocalEmpty type with
            | PsExpr.forallE _ _ _ _ =>
                match psOrdinaryWitnessWithFuel 128 environment psLocalEmpty type with
                | Option.none =>
                    Except.error (String.Internal.append
                      "PSC1_PARTIAL_NO_CHECKED_INHABITANT: " (psNameToString name))
                | Option.some witness =>
                    let logical := PsDeclaration.opaqueDecl name levels type witness;
                    match psOrdinaryAdd environment logical with
                    | Except.error error => Except.error error
                    | Except.ok withLogical =>
                        let implementation := PsDeclaration.definitionDecl
                          (psOrdinaryBodyName name) levels type body;
                        match psOrdinaryAdd withLogical implementation with
                        | Except.error error => Except.error error
                        | Except.ok withBody =>
                            match smaller withBody with
                            | Except.error error => Except.error error
                            | Except.ok expanded =>
                                Except.ok (Prod.mk
                                  (List.cons logical (List.cons implementation expanded.fst))
                                  (List.cons name expanded.snd))
            | _ =>
                Except.error (String.Internal.append
                  "PSC1_PARTIAL_EXPECTED_FUNCTION: " (psNameToString name))
        | _ =>
            match psOrdinaryAdd environment declaration with
            | Except.error error => Except.error error
            | Except.ok next =>
                match smaller next with
                | Except.error error => Except.error error
                | Except.ok expanded =>
                    Except.ok (Prod.mk (List.cons declaration expanded.fst) expanded.snd)


end OrdinaryExpansionReference
