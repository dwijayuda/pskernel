export interface ElabDiagnostic {
  readonly severity:'error'|'warning'|'info';
  readonly message:string;
  readonly start?:number;
  readonly end?:number;
}
export interface ElabContext<Core> { readonly expectedType?:Core; }
export interface ElabResult<Core> { readonly term?:Core; readonly diagnostics:readonly ElabDiagnostic[]; }
export interface TermElaborator<Surface,Core> {
  elaborate(surface:Surface,context:ElabContext<Core>):ElabResult<Core>;
}
export class ElaborationError extends Error {
  constructor(readonly diagnostics:readonly ElabDiagnostic[]){
    super(diagnostics.filter(d=>d.severity==='error').map(d=>d.message).join('; ')||'elaboration failed');
    this.name='ProofScriptElaborationError';
  }
}
export function elaborateChecked<Surface,Core>(
  elaborator:TermElaborator<Surface,Core>,surface:Surface,context:ElabContext<Core>={},
):Core{
  const result=elaborator.elaborate(surface,context);
  if(result.diagnostics.some(d=>d.severity==='error')||result.term===undefined)throw new ElaborationError(result.diagnostics);
  return result.term;
}
export interface DeclarationAdmission<Declaration,Environment> {
  admit(environment:Environment,declaration:Declaration):Environment;
}
export function admitElaborated<Declaration,Environment>(
  admission:DeclarationAdmission<Declaration,Environment>,environment:Environment,declaration:Declaration,
):Environment{return admission.admit(environment,declaration);}

export * from './application.js';

export * from './v061-context.js';
export * from './v061-type-elab.js';
export * from './v061-term-elab.js';
export * from './v061-declaration-elab.js';
export * from './v061-header-elab.js';

export * from './v061-structure-elab.js';
