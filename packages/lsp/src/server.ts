import {Buffer} from 'node:buffer';
import {
  ProofScriptLanguageService,
  type Position,
  type ServiceDiagnostic,
} from '@proofscript/language-service';
import {createInitPreludeEnvironmentProvider} from './prelude-environment.js';
import {sourceKindFromLspDocument} from './source-kind.js';
import {createNodeProjectSourceHost} from './project-source-host.js';

interface RpcMessage {
  readonly jsonrpc?:string;
  readonly id?:number|string|null;
  readonly method?:string;
  readonly params?:any;
}

export const PROOFSCRIPT_LSP_PROTOCOL_VERSION=1;

export function lspCapabilities(){
  return {
    textDocumentSync:1,
    hoverProvider:true,
    completionProvider:{triggerCharacters:['.']},
    definitionProvider:true,
    referencesProvider:true,
    documentSymbolProvider:true,
    experimental:{
      proofscriptProtocolVersion:PROOFSCRIPT_LSP_PROTOCOL_VERSION,
      proofState:true,
      documentStatus:true,
    },
  };
}

export class ProofScriptLanguageServer {
  private readonly prelude=createInitPreludeEnvironmentProvider();
  private readonly service=new ProofScriptLanguageService({
    environmentFactory:()=>this.prelude.create(),
    projectHost:createNodeProjectSourceHost(),
  });
  private input=Buffer.alloc(0);
  private shutdownRequested=false;

  start():void {
    process.stdin.on('data',(chunk:Buffer)=>{
      this.input=Buffer.concat([this.input,chunk]);
      this.drain();
    });
    process.stdin.on('end',()=>{
      if(!this.shutdownRequested)process.exit(0);
    });
  }

  private drain():void {
    while(true){
      const headerEnd=this.input.indexOf('\r\n\r\n');
      if(headerEnd<0)return;
      const header=this.input.slice(0,headerEnd).toString('utf8');
      const match=/Content-Length:\s*(\d+)/i.exec(header);
      if(match===null){
        this.input=this.input.slice(headerEnd+4);
        continue;
      }
      const length=Number(match[1]);
      const bodyStart=headerEnd+4;
      if(this.input.length<bodyStart+length)return;
      const body=this.input.slice(bodyStart,bodyStart+length).toString('utf8');
      this.input=this.input.slice(bodyStart+length);
      try{
        void this.handle(JSON.parse(body) as RpcMessage);
      }catch(error){
        this.log('invalid LSP message: '+messageOf(error));
      }
    }
  }

  private async handle(message:RpcMessage):Promise<void> {
    if(message.method===undefined)return;
    try{
      switch(message.method){
        case 'initialize':
          this.reply(message.id,{
            capabilities:lspCapabilities(),
            serverInfo:{name:'ProofScript',version:'0.0.0-dev'},
          });
          return;
        case 'initialized':
          return;
        case 'shutdown':
          this.shutdownRequested=true;
          this.reply(message.id,null);
          return;
        case 'exit':
          process.exit(this.shutdownRequested?0:1);
          return;
        case 'textDocument/didOpen':{
          const document=message.params?.textDocument;
          this.service.openDocument(
            document.uri,
            document.version??0,
            document.text??'',
            sourceKindFromLspDocument(
              document.languageId,
              document.uri,
            ),
          );
          this.publishDiagnostics(document.uri);
          return;
        }
        case 'textDocument/didChange':{
          const uri=message.params?.textDocument?.uri as string;
          const version=message.params?.textDocument?.version??0;
          const changes=message.params?.contentChanges;
          const text=Array.isArray(changes)&&changes.length>0
            ?String(changes[changes.length-1]?.text??'')
            :(this.service.getDocument(uri)?.text??'');
          this.service.replaceDocument(uri,version,text);
          this.publishDiagnostics(uri);
          return;
        }
        case 'textDocument/didClose':{
          const uri=message.params?.textDocument?.uri as string;
          this.service.closeDocument(uri);
          this.notify('textDocument/publishDiagnostics',{
            uri,
            diagnostics:[],
          });
          return;
        }
        case 'textDocument/completion':
          this.reply(message.id,{
            isIncomplete:false,
            items:this.service.completions(
              message.params.textDocument.uri,
              message.params.position as Position,
            ),
          });
          return;
        case 'textDocument/definition':
          this.reply(
            message.id,
            this.service.definition(
              message.params.textDocument.uri,
              message.params.position as Position,
            ),
          );
          return;
        case 'textDocument/references':
          this.reply(
            message.id,
            this.service.references(
              message.params.textDocument.uri,
              message.params.position as Position,
              message.params.context?.includeDeclaration!==false,
            ),
          );
          return;
        case 'textDocument/hover':
          this.reply(
            message.id,
            this.service.hover(
              message.params.textDocument.uri,
              message.params.position as Position,
            ),
          );
          return;
        case 'textDocument/documentSymbol':
          this.reply(
            message.id,
            this.service.documentSymbols(message.params.textDocument.uri),
          );
          return;
        case 'proofscript/proofState':
          this.reply(
            message.id,
            this.service.proofState(
              message.params.textDocument.uri,
              message.params.position as Position,
            ),
          );
          return;
        case 'proofscript/documentStatus':
          this.reply(
            message.id,
            this.service.documentStatus(message.params.textDocument.uri),
          );
          return;
        case 'proofscript/serverInfo':
          this.reply(message.id,{
            protocolVersion:PROOFSCRIPT_LSP_PROTOCOL_VERSION,
            proofAuthority:'pskernel',
            proofStateGranularity:'declaration',
            cursorSensitiveTacticSteps:false,
            editorEnvironment:this.prelude.status(),
            projectAwareImports:true,
          });
          return;
        default:
          if(message.id!==undefined){
            this.error(message.id,-32601,'method not found: '+message.method);
          }
      }
    }catch(error){
      if(message.id!==undefined){
        this.error(message.id,-32603,messageOf(error));
      }else{
        this.log(messageOf(error));
      }
    }
  }

  private publishDiagnostics(uri:string):void {
    let diagnostics:readonly ServiceDiagnostic[];
    try{diagnostics=this.service.diagnostics(uri);}
    catch(error){
      diagnostics=[{
        range:{
          start:{line:0,character:0},
          end:{line:0,character:0},
        },
        severity:1,
        code:'PS_LSP_ANALYSIS_ERROR',
        source:'proofscript',
        phase:'tooling',
        message:messageOf(error),
      }];
    }
    this.notify('textDocument/publishDiagnostics',{uri,diagnostics});
  }

  private reply(id:RpcMessage['id'],result:unknown):void {
    if(id===undefined)return;
    this.send({jsonrpc:'2.0',id,result});
  }

  private error(
    id:RpcMessage['id'],
    code:number,
    message:string,
  ):void {
    if(id===undefined)return;
    this.send({jsonrpc:'2.0',id,error:{code,message}});
  }

  private notify(method:string,params:unknown):void {
    this.send({jsonrpc:'2.0',method,params});
  }

  private send(message:unknown):void {
    const body=JSON.stringify(message);
    process.stdout.write(
      'Content-Length: '+Buffer.byteLength(body,'utf8')+
      '\r\n\r\n'+body,
    );
  }

  private log(message:string):void {
    this.notify('window/logMessage',{type:3,message});
  }
}

function messageOf(error:unknown):string {
  return error instanceof Error?error.message:String(error);
}

export function startLspServer():void {
  new ProofScriptLanguageServer().start();
}
