export type SurfaceFeatureClass = 'L' | 'D' | 'E' | 'X';
export type ProofScriptFeatureId =
  | 'L-CORE-LEAN'
  | 'L-LEAN434-ERASED-DO'
  | 'L-LEAN434-MONOTONICITY-BY'
  | 'L-LEAN434-RECALL'
  | 'L-LEAN434-LIA-GROBNER-PARAMS'
  | 'D-CALL'
  | 'D-EXPLICIT-PARAMS'
  | 'D-DECL-SEMI'
  | 'D-CONST-ALIAS'
  | 'D-FUNCTION-ALIAS'
  | 'E-IF-BRACE'
  | 'E-STRUCT-BODY'
  | 'E-CLASS-BODY'
  | 'E-INDUCTIVE-BODY'
  | 'E-MATCH-BODY'
  | 'E-WHERE-BODY';

export const LEAN434_INHERITED_FEATURE_IDS = [
  'L-LEAN434-ERASED-DO',
  'L-LEAN434-MONOTONICITY-BY',
  'L-LEAN434-RECALL',
  'L-LEAN434-LIA-GROBNER-PARAMS',
] as const satisfies readonly ProofScriptFeatureId[];
