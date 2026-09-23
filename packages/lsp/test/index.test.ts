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
  sourceKindFromLspDocument,
  createNodeProjectSourceHost,
} from '../src/index.js';

{
  const capabilities=lspCapabilities();
  equal(capabilities.textDocumentSync,1);
  equal(capabilities.hoverProvider,true);
  equal(capabilities.definitionProvider,true);
  equal(capabilities.referencesProvider,true);
  equal(
    capabilities.experimental.proofscriptProtocolVersion,
    PROOFSCRIPT_LSP_PROTOCOL_VERSION,
  );
  equal(capabilities.experimental.translateDocument,true);
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

{
  equal(
    sourceKindFromLspDocument('proofscript','file:///main.ps'),
    'proofscript',
  );
  equal(
    sourceKindFromLspDocument('proofscript-lean','file:///Main.lean'),
    'lean-subset',
  );
  equal(
    sourceKindFromLspDocument('lean4','file:///Main.lean'),
    'lean-subset',
  );
  const service=new ProofScriptLanguageService();
  service.openDocument(
    'file:///Main.lean',
    1,
    'theorem id (P : Prop) (h : P) : P := by assumption\n',
    'lean-subset',
  );
  equal(service.documentStatus('file:///Main.lean').sourceKind,'lean-subset');
  equal(service.documentStatus('file:///Main.lean').kernel,'verified');
}
console.log('ok - @proofscript/lsp dual-source document routing');

import {
  mkdtempSync,
  mkdirSync,
  rmSync,
  writeFileSync,
} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {pathToFileURL} from 'node:url';

{
  const root=mkdtempSync(join(tmpdir(),'proofscript-lsp-project-'));
  try{
    mkdirSync(join(root,'src'),{recursive:true});
    writeFileSync(
      join(root,'psconfig.json'),
      JSON.stringify({sourceRoots:['src']}),
    );
    const entryPath=join(root,'src','Main.ps');
    const corePath=join(root,'src','Core.lean');
    writeFileSync(entryPath,'import Core;');
    writeFileSync(
      corePath,
      'theorem id (P : Prop) (h : P) : P := by assumption\n',
    );
    const host=createNodeProjectSourceHost();
    const entry={
      uri:pathToFileURL(entryPath).href,
      sourceKind:'proofscript' as const,
      version:1,
      generation:1,
      text:'import Core;',
    };
    equal(host.entryModule(entry),'Main');
    const core=host.resolveImport(
      entry,
      {
        uri:entry.uri,
        sourceKind:entry.sourceKind,
        text:entry.text,
      },
      'Core',
    );
    equal(core.sourceKind,'lean-subset');
    equal(core.uri,pathToFileURL(corePath).href);
  }finally{
    rmSync(root,{recursive:true,force:true});
  }
}
console.log('ok - @proofscript/lsp shared project source-root resolver');

{
  const service=new ProofScriptLanguageService();
  service.openDocument(
    'file:///convert.ps',
    1,
    'theorem id(P : Prop, h : P) : P := by assumption;',
  );
  const translated=service.translateDocument('file:///convert.ps','lean');
  equal(translated.target,'lean');
  equal(translated.extension,'.lean');
}
console.log('ok - @proofscript/lsp translation service surface');
