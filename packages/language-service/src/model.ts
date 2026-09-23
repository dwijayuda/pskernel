import type {SourceKind} from '@proofscript/syntax';
export interface Position {
  readonly line:number;
  readonly character:number;
}
export interface Range {
  readonly start:Position;
  readonly end:Position;
}
export type DiagnosticSeverity=1|2|3;
export type AnalysisPhase='parser'|'elaboration'|'kernel'|'tooling';
export interface ServiceDiagnostic {
  readonly range:Range;
  readonly severity:DiagnosticSeverity;
  readonly code:string;
  readonly source:'proofscript';
  readonly phase:AnalysisPhase;
  readonly message:string;
}
export type DocumentSourceKind=SourceKind;

export interface TextDocumentSnapshot {
  readonly uri:string;
  readonly sourceKind:DocumentSourceKind;
  readonly version:number;
  readonly generation:number;
  readonly text:string;
}
export type DeclarationKernelStatus='verified'|'unsupported'|'rejected'|'not-run';
export interface ProofGoalLocal {
  readonly name:string;
  readonly type:string;
  readonly binderInfo:'default'|'implicit'|'strictImplicit'|'instImplicit';
}
export interface ProofGoal {
  readonly locals:readonly ProofGoalLocal[];
  readonly target:string;
}
export interface DeclarationStatus {
  readonly name:string;
  readonly kind:string;
  readonly range:Range;
  readonly selectionRange:Range;
  readonly kernel:DeclarationKernelStatus;
  readonly message?:string;
  readonly canonicalLean:string;
  readonly initialGoal?:ProofGoal;
}
export interface DocumentAnalysis {
  readonly uri:string;
  readonly sourceKind:DocumentSourceKind;
  readonly version:number;
  readonly generation:number;
  readonly text:string;
  readonly frontend:'parsed'|'rejected';
  readonly kernel:'verified'|'partial'|'unsupported'|'rejected'|'not-run';
  readonly diagnostics:readonly ServiceDiagnostic[];
  readonly declarations:readonly DeclarationStatus[];
  readonly canonicalLean?:string;
}
export interface ProofState {
  readonly status:'closed'|'rejected'|'unavailable'|'none';
  readonly declaration?:string;
  readonly message:string;
  readonly goals:readonly ProofGoal[];
  readonly initialGoal?:ProofGoal;
}
