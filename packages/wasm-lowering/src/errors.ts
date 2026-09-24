export class WasmLoweringError extends Error {
  readonly code:string;

  constructor(code:string,message:string){
    super(code+': '+message);
    this.name='WasmLoweringError';
    this.code=code;
  }
}

export function unsupported(code:string,message:string):never {
  throw new WasmLoweringError(code,message);
}
