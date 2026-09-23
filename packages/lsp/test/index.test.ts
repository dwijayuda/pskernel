import {offsetAt,positionAt,toLspDiagnostics} from '../src/index.js';
function equal(a:unknown,b:unknown):void{if(a!==b)throw new Error(`expected ${String(b)}, got ${String(a)}`);}
const text='ab\ncd';
const pos=positionAt(text,4);
equal(pos.line,1);equal(pos.character,1);equal(offsetAt(text,pos),4);
const [d]=toLspDiagnostics(text,[{severity:'error',message:'bad',start:3,end:5}]);
equal(d?.severity,1);equal(d?.range.start.line,1);
console.log('ok - @proofscript/lsp foundation');

import {
  PROOFSCRIPT_LSP_PROTOCOL_VERSION,
  ProofScriptLanguageService,
  lspCapabilities,
} from '../src/index.js';

{
  const capabilities=lspCapabilities();
  equal(capabilities.textDocumentSync,1);
  equal(capabilities.hoverProvider,true);
  equal(
    capabilities.experimental.proofscriptProtocolVersion,
    PROOFSCRIPT_LSP_PROTOCOL_VERSION,
  );
}
{
  const service=new ProofScriptLanguageService();
  service.openDocument(
    'file:///proof.ps',
    1,
    'theorem id(P : Prop, h : P) : P := by assumption;',
  );
  equal(service.documentStatus('file:///proof.ps').kernel,'verified');
}
console.log('ok - @proofscript/lsp proof-aware protocol surface');
