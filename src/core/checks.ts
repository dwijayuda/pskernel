import { Expr, hasFVar, hasLooseBVar, hasMVar } from './expr.js';
import { KernelError } from './environment.js';
export function ensureClosed(e:Expr,what='declaration'):void{if(hasMVar(e))throw new KernelError(`${what} contains metavariables`);if(hasFVar(e))throw new KernelError(`${what} contains free variables`);if(hasLooseBVar(e))throw new KernelError(`${what} contains loose bound variables`);}
