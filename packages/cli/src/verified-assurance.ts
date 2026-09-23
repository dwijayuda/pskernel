import type {CheckedCoreModule} from '@proofscript/checked-core';
import {
  exprToString,
  nameToString,
} from 'lean-ts-kernel';

export interface VerifiedRuntimeAssumption {
  readonly kind:'runtime-external';
  readonly name:string;
  readonly source:string;
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
  const runtimeAssumptions=checkedCore.externals.map((external)=>({
    kind:'runtime-external' as const,
    name:nameToString(external.declaration.name),
    source:external.binding.source,
    importedName:external.binding.importedName,
    logicalSignature:exprToString(external.declaration.type),
    ...(runtimeDependencies[external.binding.source]===undefined
      ?{}
      :{expectedVersion:runtimeDependencies[external.binding.source]}),
    proofEvidence:false as const,
  }));
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
