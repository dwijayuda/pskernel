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
  toLocation,
  toProtocolPosition,
  toRange,
};
