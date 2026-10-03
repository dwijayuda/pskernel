export interface UserId {
  readonly value: bigint;
}
export interface ParseError {
  readonly message: string;
}
export type ParseResult =
  | { readonly tag: "ok"; readonly value: UserId }
  | { readonly tag: "error"; readonly error: ParseError };
export declare function parseUserId(text: string): ParseResult;
