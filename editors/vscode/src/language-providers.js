const vscode=require('vscode');
const {
  toLocation,
  toProtocolPosition,
  toRange,
}=require('./protocol.js');

const languageSelector=[
  {language:'proofscript'},
  {language:'proofscript-lean'},
  {pattern:'**/*.lean'},
];

function registerLanguageProviders(
  context,
  {getClient,isManagedDocument},
){
  context.subscriptions.push(
    vscode.languages.registerCompletionItemProvider(languageSelector,{
      provideCompletionItems:async(document,position)=>{
        if(!isManagedDocument(document))return [];
        const result=await getClient()?.request('textDocument/completion',{
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
    vscode.languages.registerDefinitionProvider(languageSelector,{
      provideDefinition:async(document,position)=>{
        if(!isManagedDocument(document))return undefined;
        const result=await getClient()?.request('textDocument/definition',{
          textDocument:{uri:document.uri.toString()},
          position:toProtocolPosition(position),
        });
        return result===null||result===undefined
          ?undefined
          :toLocation(vscode,result);
      },
    }),
    vscode.languages.registerReferenceProvider(languageSelector,{
      provideReferences:async(document,position,contextValue)=>{
        if(!isManagedDocument(document))return [];
        const result=await getClient()?.request('textDocument/references',{
          textDocument:{uri:document.uri.toString()},
          position:toProtocolPosition(position),
          context:{includeDeclaration:contextValue.includeDeclaration},
        })??[];
        return result.map((item)=>toLocation(vscode,item));
      },
    }),
    vscode.languages.registerHoverProvider(languageSelector,{
      provideHover:async(document,position)=>{
        if(!isManagedDocument(document))return undefined;
        const result=await getClient()?.request('textDocument/hover',{
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
    vscode.languages.registerDocumentSymbolProvider(languageSelector,{
      provideDocumentSymbols:async(document)=>{
        if(!isManagedDocument(document))return [];
        const values=await getClient()?.request(
          'textDocument/documentSymbol',
          {textDocument:{uri:document.uri.toString()}},
        )??[];
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
    vscode.languages.registerCodeActionsProvider(
      languageSelector,
      {
        provideCodeActions:(document)=>{
          if(!isManagedDocument(document))return [];
          const target=document.languageId==='proofscript'
            ?'lean'
            :'ps';
          const title=target==='lean'
            ?'ProofScript: Convert to Lean subset'
            :'ProofScript: Convert to ProofScript';
          const action=new vscode.CodeAction(
            title,
            vscode.CodeActionKind.RefactorRewrite,
          );
          action.command={
            command:target==='lean'
              ?'proofscript.convertToLean'
              :'proofscript.convertToProofScript',
            title,
            arguments:[document.uri],
          };
          return [action];
        },
      },
      {providedCodeActionKinds:[vscode.CodeActionKind.RefactorRewrite]},
    ),
  );
}

module.exports={registerLanguageProviders};
