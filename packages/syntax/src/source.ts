export interface SourcePosition {
  readonly offset: number;
  readonly line: number;
  readonly column: number;
}

export interface SourceSpan {
  readonly start: SourcePosition;
  readonly end: SourcePosition;
}

export type TriviaKind = 'whitespace' | 'line-comment' | 'block-comment';
export interface Trivia {
  readonly kind: TriviaKind;
  readonly text: string;
  readonly span: SourceSpan;
}

export type TokenKind = 'identifier' | 'number' | 'string' | 'char' | 'symbol' | 'eof';
export interface Token {
  readonly kind: TokenKind;
  readonly text: string;
  readonly value?: string;
  readonly span: SourceSpan;
  readonly leadingTrivia: readonly Trivia[];
  /** True exactly when this token begins at the previous token's end offset. */
  readonly adjacentToPrevious: boolean;
}

export class SyntaxError extends Error {
  readonly span: SourceSpan;
  constructor(message: string, span: SourceSpan) {
    super(message);
    this.name = 'ProofScriptSyntaxError';
    this.span = span;
  }
}
