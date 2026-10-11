import Ps.KernelCore.Admission.Quot.Bootstrap

/-
Quotient environment admission.

After validating Eq/Eq.refl and reserved names, this module installs the four
kernel-recognized quotient constants and marks quotient computation enabled in
the environment. Quot computation itself lives in the reduction layer.
-/

def psKernelAddQuot
    (environment : PsKernelEnvironment) :
    Except String PsKernelEnvironment :=
  if environment.quotInitialized then
    Except.ok environment
  else
    match psKernelCheckEqForQuot environment with
    | Except.error error =>
        Except.error error
    | Except.ok _ =>
        let reserved :=
          List.cons
            psKernelQuotName
            (List.cons
              psKernelQuotMkName
              (List.cons
                psKernelQuotLiftName
                (List.cons
                  psKernelQuotIndName
                  List.nil)));
        match
            psKernelCheckQuotReservedNames
              environment
              reserved with
        | Except.error error =>
            Except.error error
        | Except.ok _ =>
            let universeName :=
              PsKernelName.str
                PsKernelName.anonymous
                "u";
            let resultUniverseName :=
              PsKernelName.str
                PsKernelName.anonymous
                "v";
            let quotTypeBase :=
              PsKernelConstantBase.mk
                psKernelQuotName
                (List.cons
                  universeName
                  List.nil)
                (psKernelMakeQuotType
                  universeName);
            let quotTypeInfo :=
              PsKernelQuotInfo.mk
                quotTypeBase
                PsKernelQuotKind.typeQ;
            let env1 :=
              psKernelEnvironmentAddUnchecked
                environment
                (PsKernelConstantInfo.quotInfo
                  quotTypeInfo);
            let quotMkBase :=
              PsKernelConstantBase.mk
                psKernelQuotMkName
                (List.cons
                  universeName
                  List.nil)
                (psKernelMakeQuotMkType
                  universeName);
            let quotMkInfo :=
              PsKernelQuotInfo.mk
                quotMkBase
                PsKernelQuotKind.ctorQ;
            let env2 :=
              psKernelEnvironmentAddUnchecked
                env1
                (PsKernelConstantInfo.quotInfo
                  quotMkInfo);
            let quotLiftBase :=
              PsKernelConstantBase.mk
                psKernelQuotLiftName
                (List.cons
                  universeName
                  (List.cons
                    resultUniverseName
                    List.nil))
                (psKernelMakeQuotLiftType
                  universeName
                  resultUniverseName);
            let quotLiftInfo :=
              PsKernelQuotInfo.mk
                quotLiftBase
                PsKernelQuotKind.liftQ;
            let env3 :=
              psKernelEnvironmentAddUnchecked
                env2
                (PsKernelConstantInfo.quotInfo
                  quotLiftInfo);
            let quotIndBase :=
              PsKernelConstantBase.mk
                psKernelQuotIndName
                (List.cons
                  universeName
                  List.nil)
                (psKernelMakeQuotIndType
                  universeName);
            let quotIndInfo :=
              PsKernelQuotInfo.mk
                quotIndBase
                PsKernelQuotKind.indQ;
            let env4 :=
              psKernelEnvironmentAddUnchecked
                env3
                (PsKernelConstantInfo.quotInfo
                  quotIndInfo);
            Except.ok
              (psKernelEnvironmentMarkQuotInitialized
                env4)
