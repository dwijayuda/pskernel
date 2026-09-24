import type {CheckedCoreModule} from '@proofscript/checked-core';
import {npmPackageRootFromExternalSource} from '@proofscript/project/node';
import {
  exprToString,
  nameToString,
} from 'lean-ts-kernel';

export interface VerifiedRuntimeAssumption {
  readonly kind:'runtime-external';
  readonly name:string;
  readonly source:string;
  readonly packageRoot:string;
  readonly importedName:string;
  readonly logicalSignature:string;
  readonly expectedVersion?:string;
  readonly proofEvidence:false;
}

export interface VerifiedAssuranceReport {
  readonly proofAuthority:'pskernel';
  readonly internalProofs:'kernel-verified';
  readonly kernelCheckedDefinitionCount:number;
  readonly kernelCheckedTheoremCount:number;
  readonly runtimeAssumptionCount:number;
  readonly hasRuntimeAssumptions:boolean;
  readonly runtimeAssumptions:readonly VerifiedRuntimeAssumption[];
  readonly runtimeExternalsAreProofEvidence:false;
}

export function verifiedAssuranceReport(
  checkedCore:CheckedCoreModule,
  runtimeDependencies:Readonly<Record<string,string>>={},
):VerifiedAssuranceReport {
  const runtimeAssumptions=checkedCore.externals.map((external)=>{
    const packageRoot=npmPackageRootFromExternalSource(
      external.binding.source,
    );
    return {
      kind:'runtime-external' as const,
      name:nameToString(external.declaration.name),
      source:external.binding.source,
      packageRoot,
      importedName:external.binding.importedName,
      logicalSignature:exprToString(external.declaration.type),
      ...(runtimeDependencies[packageRoot]===undefined
        ?{}
        :{expectedVersion:runtimeDependencies[packageRoot]}),
      proofEvidence:false as const,
    };
  });
  return {
    proofAuthority:'pskernel',
    internalProofs:'kernel-verified',
    kernelCheckedDefinitionCount:checkedCore.definitions.length,
    kernelCheckedTheoremCount:checkedCore.theorems.length,
    runtimeAssumptionCount:runtimeAssumptions.length,
    hasRuntimeAssumptions:runtimeAssumptions.length>0,
    runtimeAssumptions,
    runtimeExternalsAreProofEvidence:false,
  };
}
