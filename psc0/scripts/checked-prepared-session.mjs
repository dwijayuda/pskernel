// Compatibility composition for the existing checked host. Semantic ownership
// is shared with the npm CLI; provider defaults remain explicit at this boundary.
import { ownedCheckedIdentity } from './checked-kernel-identity.mjs';
import { createCheckedPreparedSession as createSession } from '../npm-cli/checked-session.mjs';
export { leanCheckedIdentity } from './checked-kernel-identity.mjs';
export { unwrapCompilerResult } from '../npm-cli/checked-session.mjs';
export function createCheckedPreparedSession(compiler, checker, identity = ownedCheckedIdentity) {
  return createSession(compiler, checker, identity);
}
