import * as kernel from './kernel.js';

const unit = value => typeof value === 'function' ? value() : value;
const unwrap = result => {
  if (!result || !Object.hasOwn(result, 'value')) throw Error('Kernel rejected example: '+String(result?.error?.message));
  return result.value;
};
const nil = unit(kernel.List.nil);
const safe = unit(kernel.PsKernelDefinitionSafety.safe);
const session = unwrap(kernel.psKernelKernelSessionEmpty(
  unit(kernel.psKernelResourcePolicyDefault), unit(kernel.psKernelProviderDefault)));
const sort = kernel.PsKernelExpr.sort(unit(kernel.PsKernelLevel.zero));

unwrap(kernel.psKernelV1CheckExpression(session, nil, safe, sort));
const invalid = kernel.PsKernelExpr.app(sort, sort);
const rejection = kernel.psKernelV1CheckExpression(session, nil, safe, invalid);
if (!rejection || !Object.hasOwn(rejection, 'error')) throw Error('Ill-typed application was accepted');
console.log('PSKERNEL_PUBLIC_API_EXAMPLE: PASS validSort=true invalidApplicationRejected=true independentRuntime=true');
