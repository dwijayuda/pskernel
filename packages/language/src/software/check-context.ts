import type {
  CheckedSoftwareStructure,
  SoftwareSignature,
  SoftwareType,
} from './types.js';

export interface SoftwareExpressionContext {
  readonly locals:ReadonlyMap<string,SoftwareType>;
  readonly signatures:ReadonlyMap<string,SoftwareSignature>;
  readonly structures:ReadonlyMap<string,CheckedSoftwareStructure>;
}

export function nominalTypeNames(context:SoftwareExpressionContext):ReadonlySet<string> {
  return new Set(context.structures.keys());
}

export function withSoftwareLocal(
  context:SoftwareExpressionContext,
  name:string,
  type:SoftwareType,
):SoftwareExpressionContext {
  const locals=new Map(context.locals);
  locals.set(name,type);
  return {...context,locals};
}
