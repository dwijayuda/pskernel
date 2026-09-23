export class CancellationError extends Error {
  constructor(message='operation cancelled'){
    super(message);
    this.name='ProofScriptCancellationError';
  }
}
export interface CancellationSignal {
  readonly aborted:boolean;
  throwIfAborted():void;
}
class MutableCancellationSignal implements CancellationSignal {
  aborted=false;
  abort():void{this.aborted=true;}
  throwIfAborted():void{if(this.aborted)throw new CancellationError();}
}
export class CancellationController {
  readonly signal:CancellationSignal;
  private readonly mutable:MutableCancellationSignal;
  constructor(){this.mutable=new MutableCancellationSignal();this.signal=this.mutable;}
  abort():void{this.mutable.abort();}
}
export interface VerificationAdapter<State,Chunk,Result> {
  createState():State;
  push(state:State,chunk:Chunk):void|Promise<void>;
  finish(state:State):Result|Promise<Result>;
}
export interface VerificationProgress { readonly chunks:number; }
export interface VerifyStreamOptions {
  readonly signal?:CancellationSignal;
  readonly onProgress?:(progress:VerificationProgress)=>void;
}
export async function verifyStream<State,Chunk,Result>(
  chunks:Iterable<Chunk>|AsyncIterable<Chunk>,
  adapter:VerificationAdapter<State,Chunk,Result>,
  options:VerifyStreamOptions={},
):Promise<Result>{
  const state=adapter.createState();
  let count=0;
  for await(const chunk of chunks){
    options.signal?.throwIfAborted();
    await adapter.push(state,chunk);
    count+=1;
    options.onProgress?.({chunks:count});
  }
  options.signal?.throwIfAborted();
  return await adapter.finish(state);
}
