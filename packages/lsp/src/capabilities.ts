export const PROOFSCRIPT_LSP_PROTOCOL_VERSION=2;

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
      translateDocument:true,
    },
  };
}
