import type {AxiomInfo} from 'lean-ts-kernel';

export interface CheckedCoreExternalBinding {
  readonly source:string;
  readonly importedName:string;
}

export interface CheckedCoreExternal {
  readonly declaration:AxiomInfo;
  readonly binding:CheckedCoreExternalBinding;
}

const importIdentifier=/^[A-Za-z_$][A-Za-z0-9_$]*$/u;

export function validateCheckedCoreExternal(
  external:CheckedCoreExternal,
):void {
  if(external.declaration.isUnsafe!==true){
    throw new Error(
      'checked-core external invariant: runtime external axiom must be unsafe',
    );
  }
  if(external.binding.source.length===0){
    throw new Error(
      'checked-core external invariant: module source must be non-empty',
    );
  }
  if(!importIdentifier.test(external.binding.importedName)){
    throw new Error(
      "checked-core external invariant: invalid imported name '"+
      external.binding.importedName+"'",
    );
  }
}
