const vscode=require('vscode');
const fs=require('node:fs');
const path=require('node:path');
const {RpcClient}=require('./rpc-client.js');
const {InfoviewProvider}=require('./infoview.js');
const {
  isProofScript,
  openParams,
  publishDiagnostics,
  toLocation,
  toProtocolPosition,
  toRange,
}=require('./protocol.js');

const EXPECTED_PROTOCOL=1;
let client;
let diagnostics;
let output;
let statusBar;
let infoview;
let selectionTimer;

function resolveServerTarget(extensionPath){
  const config=vscode.workspace.getConfiguration('proofscript');
  const configured=config.get('lsp.path');
  const root=vscode.workspace.workspaceFolders?.[0]?.uri.fsPath??process.cwd();
  const bundled=path.join(extensionPath,'server','run-lsp.mjs');
  const target=configured
    ?(path.isAbsolute(configured)?configured:path.resolve(root,configured))
    :bundled;
  if(!fs.existsSync(target)){
    throw new Error('ProofScript LSP not found: '+target);
  }
  return {target,root};
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

function scheduleInfoview(editor,delay){
  clearTimeout(selectionTimer);
  selectionTimer=setTimeout(()=>void syncInfoview(editor),delay);
}

async function startServer(context){
  if(client!==undefined)await client.stop();
  const {target,root}=resolveServerTarget(context.extensionPath);
  client=new RpcClient({target,cwd:root,output});
  client.on(
    'textDocument/publishDiagnostics',
    (params)=>publishDiagnostics(vscode,diagnostics,params),
  );
  const init=await client.start(
    vscode.workspace.workspaceFolders?.[0]?.uri.toString()??null,
  );
  const protocol=init?.capabilities?.experimental?.proofscriptProtocolVersion;
  if(protocol!==EXPECTED_PROTOCOL){
    await client.stop();
    throw new Error(
      'ProofScript LSP protocol mismatch: editor expects '+
      EXPECTED_PROTOCOL+', server reports '+String(protocol),
    );
  }
  for(const document of vscode.workspace.textDocuments){
    if(isProofScript(document)){
      client.notify('textDocument/didOpen',openParams(document));
    }
  }
  await syncInfoview(vscode.window.activeTextEditor);
}

function registerDocumentLifecycle(context){
  context.subscriptions.push(
    vscode.workspace.onDidOpenTextDocument((document)=>{
      if(isProofScript(document)){
        client?.notify('textDocument/didOpen',openParams(document));
      }
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
      scheduleInfoview(vscode.window.activeTextEditor,80);
    }),
    vscode.workspace.onDidCloseTextDocument((document)=>{
      if(!isProofScript(document))return;
      client?.notify('textDocument/didClose',{
        textDocument:{uri:document.uri.toString()},
      });
      diagnostics.delete(document.uri);
    }),
    vscode.window.onDidChangeTextEditorSelection((event)=>{
      scheduleInfoview(event.textEditor,60);
    }),
  );
}

function registerLanguageProviders(context){
  context.subscriptions.push(
    vscode.languages.registerCompletionItemProvider('proofscript',{
      provideCompletionItems:async(document,position)=>{
        const result=await client?.request('textDocument/completion',{
          textDocument:{uri:document.uri.toString()},
          position:toProtocolPosition(position),
        });
        return (result?.items??[]).map((item)=>{
          const kind=item.kind===14
            ?vscode.CompletionItemKind.Keyword
            :item.kind===7
              ?vscode.CompletionItemKind.Class
              :vscode.CompletionItemKind.Function;
          const completion=new vscode.CompletionItem(item.label,kind);
          completion.detail=item.detail;
          return completion;
        });
      },
    },'.'),
    vscode.languages.registerDefinitionProvider('proofscript',{
      provideDefinition:async(document,position)=>{
        const result=await client?.request('textDocument/definition',{
          textDocument:{uri:document.uri.toString()},
          position:toProtocolPosition(position),
        });
        return result===null||result===undefined
          ?undefined
          :toLocation(vscode,result);
      },
    }),
    vscode.languages.registerReferenceProvider('proofscript',{
      provideReferences:async(document,position,contextValue)=>{
        const result=await client?.request('textDocument/references',{
          textDocument:{uri:document.uri.toString()},
          position:toProtocolPosition(position),
          context:{includeDeclaration:contextValue.includeDeclaration},
        })??[];
        return result.map((item)=>toLocation(vscode,item));
      },
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
          toRange(vscode,result.range),
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
          toRange(vscode,item.range),
          toRange(vscode,item.selectionRange),
        ));
      },
    }),
  );
}

function registerCommands(context){
  context.subscriptions.push(
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
  );
}

async function activate(context){
  output=vscode.window.createOutputChannel('ProofScript');
  diagnostics=vscode.languages.createDiagnosticCollection('proofscript');
  statusBar=vscode.window.createStatusBarItem(
    vscode.StatusBarAlignment.Left,
    100,
  );
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
  );
  registerCommands(context);
  registerDocumentLifecycle(context);
  registerLanguageProviders(context);

  try{
    await startServer(context);
  }catch(error){
    output.appendLine(String(error));
    vscode.window.showErrorMessage(
      'ProofScript LSP failed to start. See output.',
    );
  }
}

async function deactivate(){
  await client?.stop();
}

module.exports={activate,deactivate};
