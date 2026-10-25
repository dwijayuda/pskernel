/** Explicit host-owned Linux String IO capability adapter.
 * Load only separately checked programs. This API does not admit code.
 */
export type IoOperation = 'readLine' | 'writeLine' | 'readUtf8' | 'writeUtf8';
export interface TypedIoConfiguration {
  readonly abi: 'psc1-node-linux-string-io/1';
  readonly capabilities: readonly IoOperation[];
  readonly required: readonly IoOperation[];
  readonly root: string;
  readonly maxFileBytes: number;
  readonly maxLineBytes: number;
  readonly inputFd: number;
  readonly outputFd: number;
}
export interface TypedIo {
  execute(request: string): string;
  close(): void;
}
export function createTypedIo(configuration: TypedIoConfiguration): Readonly<TypedIo>;
export function withTypedIo<Program, Result>(
  configuration: TypedIoConfiguration,
  loadProgram: () => Program | Promise<Program>,
  useProgram: (program: Program, io: Readonly<TypedIo>) => Result | Promise<Result>,
): Promise<Result>;
