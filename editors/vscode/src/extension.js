const vscode=require('vscode');
const fs=require('node:fs');
const path=require('node:path');
const cp=require('node:child_process');

const EXPECTED_PROTOCOL=1;
let client;
let diagnostics;
let output;
let statusBar;
let infoview;
let selectionTimer;

class RpcClient {
  constructor(extensionPath){
    this.extensionPath=extensionPath;
    this.proc=null;
    this.buffer=Buffer.alloc(0);
    this.nextId=1;
    this.pending=new Map();
    this.listeners=new Map();
  }

  async start(){
    const config=vscode.workspace.getConfiguration('proofscript');
    const configured=config.get('lsp.path');
    const root=vscode.workspace.workspaceFolders?.[0]?.uri.fsPath??process.cwd();
    const bundled=path.join(this.extensionPath,'server','run-lsp.mjs');
    const target=configured
      ?(path.isAbsolute(configured)?configured:path.resolve(root,configured))
      :bundled;
    if(!fs.existsSync(target)){
      throw new Error('ProofScript LSP not found: '+target);
    }
    this.proc=cp.spawn(process.execPath,[target],{
      cwd:root,
      env:{...process.env,ELECTRON_RUN_AS_NODE:'1'},
      stdio:['pipe','pipe','pipe'],
      windowsHide:true,
    });
    this.proc.stdout.on('data',(chunk)=>{
      this.buffer=Buffer.concat([this.buffer,chunk]);
      this.drain();
    });
    this.proc.stderr.on('data',(chunk)=>output.append(chunk.toString()));
    this.proc.on('exit',(code)=>{
      output.appendLine('ProofScript LSP exited: '+String(code));
    });
    const init=await this.request('initialize',{
      processId:process.pid,
      rootUri:vscode.workspace.workspaceFolders?.[0]?.uri.toString()??null,
      capabilities:{},
    });
    const protocol=init?.capabilities?.experimental?.proofscriptProtocolVersion;
    if(protocol!==EXPECTED_PROTOCOL){
      throw new Error(
        'ProofScript LSP protocol mismatch: editor expects '+
        EXPECTED_PROTOCOL+', server reports '+String(protocol),
      );
    }
    this.notify('initialized',{});
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
      if(message.id!==undefined){
        const pending=this.pending.get(message.id);
        if(pending!==undefined){
          this.pending.delete(message.id);
          message.error
            ?pending.reject(new Error(message.error.message))
            :pending.resolve(message.result);
        }
      }else if(message.method!==undefined){
        for(const listener of this.listeners.get(message.method)??[]){
          listener(message.params);
        }
      }
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
    if(!this.proc?.stdin?.writable)throw new Error('ProofScript LSP is not running');
    const body=JSON.stringify(message);
    this.proc.stdin.write(
      'Content-Length: '+Buffer.byteLength(body)+'\r\n\r\n'+body,
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

class InfoviewProvider {
  constructor(){
    this.view=null;
    this.proof=null;
    this.status=null;
  }

  resolveWebviewView(view){
    this.view=view;
    this.render();
  }

  update(proof,status){
    this.proof=proof;
    this.status=status;
    this.render();
  }

  render(){
    if(this.view===null)return;
    const proof=this.proof;
    const status=this.status;
    const proofText=proof===null
      ?'Move the cursor into a theorem.'
      :escapeHtml(proof.message);
    const statusText=status===null
      ?'No document status.'
      :'Frontend: '+escapeHtml(status.frontend)+
        ' · Kernel: '+escapeHtml(status.kernel)+
        ' · Verified: '+String(status.verifiedDeclarations)+'/'+
        String(status.declarations);
    this.view.webview.html=
      '<!doctype html><html><body>'+
      '<h3>ProofScript</h3>'+
      '<p><strong>'+proofText+'</strong></p>'+
      '<p>'+statusText+'</p>'+
      '<hr><p><small>Proof authority: pskernel. '+
      'Cursor-sensitive tactic snapshots are not implemented yet.</small></p>'+
      '</body></html>';
  }
}

function escapeHtml(value){
  return String(value)
    .replaceAll('&','&amp;')
    .replaceAll('<','&lt;')
    .replaceAll('>','&gt;');
}

function isProofScript(document){
  return document?.languageId==='proofscript';
}

function toProtocolPosition(position){
  return {line:position.line,character:position.character};
}

function openParams(document){
  return {
    textDocument:{
      uri:document.uri.toString(),
      languageId:'proofscript',
      version:document.version,
      text:document.getText(),
    },
  };
}

function publishDiagnostics(params){
  const uri=vscode.Uri.parse(params.uri);
  const converted=(params.diagnostics??[]).map((item)=>{
    const range=new vscode.Range(
      item.range.start.line,item.range.start.character,
      item.range.end.line,item.range.end.character,
    );
    const severity=item.severity===1
      ?vscode.DiagnosticSeverity.Error
      :item.severity===2
        ?vscode.DiagnosticSeverity.Warning
        :vscode.DiagnosticSeverity.Information;
    const diagnostic=new vscode.Diagnostic(range,item.message,severity);
    diagnostic.code=item.code;
    diagnostic.source='ProofScript';
    return diagnostic;
  });
  diagnostics.set(uri,converted);
}

async function syncInfoview(editor){
  if(client===undefined||!isProofScript(editor?.document)){
    infoview?.update(null,null);
    return;
  }
  const uri=editor.document.uri.toString();
  try{
    const [proof,status]=await Promise.all([
      client.request('proofscript/proofState',{
        textDocument:{uri},
        position:toProtocolPosition(editor.selection.active),
      }),
      client.request('proofscript/documentStatus',{
        textDocument:{uri},
      }),
    ]);
    infoview?.update(proof,status);
    statusBar.text=status.kernel==='verified'
      ?'$(verified) ProofScript'
      :status.kernel==='rejected'
        ?'$(error) ProofScript'
        :'$(warning) ProofScript';
    statusBar.tooltip='Frontend: '+status.frontend+'; kernel: '+status.kernel;
    statusBar.show();
  }catch(error){
    output.appendLine(String(error));
  }
}

async function startServer(context){
  if(client!==undefined)await client.stop();
  client=new RpcClient(context.extensionPath);
  client.on('textDocument/publishDiagnostics',publishDiagnostics);
  await client.start();
  for(const document of vscode.workspace.textDocuments){
    if(isProofScript(document))client.notify('textDocument/didOpen',openParams(document));
  }
  await syncInfoview(vscode.window.activeTextEditor);
}

async function activate(context){
  output=vscode.window.createOutputChannel('ProofScript');
  diagnostics=vscode.languages.createDiagnosticCollection('proofscript');
  statusBar=vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left,100);
  statusBar.command='proofscript.showInfoview';
  infoview=new InfoviewProvider();

  context.subscriptions.push(
    output,
    diagnostics,
    statusBar,
    vscode.window.registerWebviewViewProvider(
      'proofscript.infoview',
      infoview,
    ),
    vscode.commands.registerCommand('proofscript.showInfoview',async()=>{
      await vscode.commands.executeCommand('proofscript.infoview.focus');
      await syncInfoview(vscode.window.activeTextEditor);
    }),
    vscode.commands.registerCommand('proofscript.restartServer',async()=>{
      await startServer(context);
    }),
    vscode.commands.registerCommand('proofscript.serverInfo',async()=>{
      const info=await client?.request('proofscript/serverInfo',{});
      output.appendLine(JSON.stringify(info,null,2));
      output.show(true);
    }),
    vscode.workspace.onDidOpenTextDocument((document)=>{
      if(isProofScript(document))client?.notify('textDocument/didOpen',openParams(document));
    }),
    vscode.workspace.onDidChangeTextDocument((event)=>{
      if(!isProofScript(event.document))return;
      client?.notify('textDocument/didChange',{
        textDocument:{
          uri:event.document.uri.toString(),
          version:event.document.version,
        },
        contentChanges:[{text:event.document.getText()}],
      });
      clearTimeout(selectionTimer);
      selectionTimer=setTimeout(
        ()=>void syncInfoview(vscode.window.activeTextEditor),
        80,
      );
    }),
    vscode.workspace.onDidCloseTextDocument((document)=>{
      if(isProofScript(document)){
        client?.notify('textDocument/didClose',{
          textDocument:{uri:document.uri.toString()},
        });
        diagnostics.delete(document.uri);
      }
    }),
    vscode.window.onDidChangeTextEditorSelection((event)=>{
      clearTimeout(selectionTimer);
      selectionTimer=setTimeout(()=>void syncInfoview(event.textEditor),60);
    }),
    vscode.languages.registerHoverProvider('proofscript',{
      provideHover:async(document,position)=>{
        const result=await client?.request('textDocument/hover',{
          textDocument:{uri:document.uri.toString()},
          position:toProtocolPosition(position),
        });
        if(result===null||result===undefined)return undefined;
        return new vscode.Hover(
          new vscode.MarkdownString(result.contents.value),
          new vscode.Range(
            result.range.start.line,result.range.start.character,
            result.range.end.line,result.range.end.character,
          ),
        );
      },
    }),
    vscode.languages.registerDocumentSymbolProvider('proofscript',{
      provideDocumentSymbols:async(document)=>{
        const values=await client?.request('textDocument/documentSymbol',{
          textDocument:{uri:document.uri.toString()},
        })??[];
        return values.map((item)=>new vscode.DocumentSymbol(
          item.name,
          item.detail??'',
          item.kind===12
            ?vscode.SymbolKind.Function
            :vscode.SymbolKind.Variable,
          new vscode.Range(
            item.range.start.line,item.range.start.character,
            item.range.end.line,item.range.end.character,
          ),
          new vscode.Range(
            item.selectionRange.start.line,item.selectionRange.start.character,
            item.selectionRange.end.line,item.selectionRange.end.character,
          ),
        ));
      },
    }),
  );

  try{
    await startServer(context);
  }catch(error){
    output.appendLine(String(error));
    vscode.window.showErrorMessage('ProofScript LSP failed to start. See output.');
  }
}

async function deactivate(){
  await client?.stop();
}

module.exports={activate,deactivate};
