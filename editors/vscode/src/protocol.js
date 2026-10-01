function leanFileName(document){
  return String(
    document?.fileName
    ??document?.uri?.fsPath
    ??document?.uri?.path
    ??'',
  ).toLowerCase();
}

function sourceLanguageId(document,leanSubsetEnabled=false){
  if(document?.languageId==='proofscript')return 'proofscript';
  if(document?.languageId==='proofscript-lean')return 'proofscript-lean';
  if(leanSubsetEnabled&&leanFileName(document).endsWith('.lean')){
    return 'proofscript-lean';
  }
  return undefined;
}

function isProofScript(document,leanSubsetEnabled=false){
  return sourceLanguageId(document,leanSubsetEnabled)!==undefined;
}

function toProtocolPosition(position){
  return {line:position.line,character:position.character};
}

function openParams(document,leanSubsetEnabled=false){
  const languageId=sourceLanguageId(document,leanSubsetEnabled);
  if(languageId===undefined){
    throw new Error('document is outside ProofScript source ownership');
  }
  return {
    textDocument:{
      uri:document.uri.toString(),
      languageId,
      version:document.version,
      text:document.getText(),
    },
  };
}

function toRange(vscode,range){
  return new vscode.Range(
    range.start.line,
    range.start.character,
    range.end.line,
    range.end.character,
  );
}

function toLocation(vscode,value){
  return new vscode.Location(
    vscode.Uri.parse(value.uri),
    toRange(vscode,value.range),
  );
}

function publishDiagnostics(vscode,collection,params){
  const uri=vscode.Uri.parse(params.uri);
  const converted=(params.diagnostics??[]).map((item)=>{
    const severity=item.severity===1
      ?vscode.DiagnosticSeverity.Error
      :item.severity===2
        ?vscode.DiagnosticSeverity.Warning
        :vscode.DiagnosticSeverity.Information;
    const diagnostic=new vscode.Diagnostic(
      toRange(vscode,item.range),
      item.message,
      severity,
    );
    diagnostic.code=item.code;
    diagnostic.source='ProofScript';
    return diagnostic;
  });
  collection.set(uri,converted);
}

module.exports={
  isProofScript,
  openParams,
  publishDiagnostics,
  sourceLanguageId,
  toLocation,
  toProtocolPosition,
  toRange,
};
