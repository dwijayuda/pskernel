const cp=require('node:child_process');

class RpcClient {
  constructor({target,cwd,output}){
    this.target=target;
    this.cwd=cwd;
    this.output=output;
    this.proc=null;
    this.buffer=Buffer.alloc(0);
    this.nextId=1;
    this.pending=new Map();
    this.listeners=new Map();
  }

  async start(rootUri){
    this.proc=cp.spawn(process.execPath,[this.target],{
      cwd:this.cwd,
      env:{...process.env,ELECTRON_RUN_AS_NODE:'1'},
      stdio:['pipe','pipe','pipe'],
      windowsHide:true,
    });
    this.proc.stdout.on('data',(chunk)=>{
      this.buffer=Buffer.concat([this.buffer,chunk]);
      this.drain();
    });
    this.proc.stderr.on(
      'data',
      (chunk)=>this.output.append(chunk.toString()),
    );
    this.proc.on('exit',(code)=>{
      this.output.appendLine('ProofScript LSP exited: '+String(code));
    });

    const initialized=await this.request('initialize',{
      processId:process.pid,
      rootUri,
      capabilities:{},
    });
    this.notify('initialized',{});
    return initialized;
  }

  drain(){
    while(true){
      const headerEnd=this.buffer.indexOf('\r\n\r\n');
      if(headerEnd<0)return;
      const header=this.buffer.slice(0,headerEnd).toString();
      const match=/Content-Length:\s*(\d+)/i.exec(header);
      if(match===null){
        this.buffer=this.buffer.slice(headerEnd+4);
        continue;
      }
      const length=Number(match[1]);
      const start=headerEnd+4;
      if(this.buffer.length<start+length)return;
      const message=JSON.parse(
        this.buffer.slice(start,start+length).toString('utf8'),
      );
      this.buffer=this.buffer.slice(start+length);
      this.dispatch(message);
    }
  }

  dispatch(message){
    if(message.id!==undefined){
      const pending=this.pending.get(message.id);
      if(pending===undefined)return;
      this.pending.delete(message.id);
      if(message.error){
        pending.reject(new Error(message.error.message));
      }else{
        pending.resolve(message.result);
      }
      return;
    }
    if(message.method===undefined)return;
    for(const listener of this.listeners.get(message.method)??[]){
      listener(message.params);
    }
  }

  request(method,params){
    const id=this.nextId++;
    return new Promise((resolve,reject)=>{
      this.pending.set(id,{resolve,reject});
      this.send({jsonrpc:'2.0',id,method,params});
    });
  }

  notify(method,params){
    this.send({jsonrpc:'2.0',method,params});
  }

  send(message){
    if(!this.proc?.stdin?.writable){
      throw new Error('ProofScript LSP is not running');
    }
    const body=JSON.stringify(message);
    this.proc.stdin.write(
      'Content-Length: '+Buffer.byteLength(body)+
      '\r\n\r\n'+body,
    );
  }

  on(method,listener){
    const values=this.listeners.get(method)??[];
    values.push(listener);
    this.listeners.set(method,values);
  }

  async stop(){
    if(this.proc===null)return;
    try{
      await Promise.race([
        this.request('shutdown',{}),
        new Promise((resolve)=>setTimeout(resolve,400)),
      ]);
      this.notify('exit',{});
    }catch{}
    try{this.proc.kill();}catch{}
    this.proc=null;
  }
}

module.exports={RpcClient};
