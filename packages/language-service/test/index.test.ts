import {
  ProofScriptLanguageService,
  offsetAt,
  positionAt,
} from '../src/index.js';

function equal(actual:unknown,expected:unknown):void {
  if(actual!==expected){
    throw new Error('expected '+String(expected)+', got '+String(actual));
  }
}

{
  const text='ab\ncd';
  const position=positionAt(text,4);
  equal(position.line,1);
  equal(position.character,1);
  equal(offsetAt(text,position),4);
}

{
  const service=new ProofScriptLanguageService();
  service.openDocument(
    'file:///proof.ps',
    1,
    'theorem id(P : Prop, h : P) : P := by exact h;',
  );
  const analysis=service.analyze('file:///proof.ps');
  equal(analysis.frontend,'parsed');
  equal(analysis.kernel,'verified');
  equal(analysis.declarations[0]?.kernel,'verified');
  const state=service.proofState(
    'file:///proof.ps',
    {line:0,character:10},
  );
  equal(state.status,'closed');
  equal(state.message,'Goals accomplished!');
  equal(state.goals.length,0);
  equal(state.initialGoal?.target,'P');
  equal(state.initialGoal?.locals.length,2);
  equal(state.initialGoal?.locals[0]?.name,'P');
  equal(state.initialGoal?.locals[0]?.type,'Prop');
  equal(state.initialGoal?.locals[1]?.name,'h');
  equal(state.initialGoal?.locals[1]?.type,'P');
}

{
  const service=new ProofScriptLanguageService();
  service.openDocument(
    'file:///bad.ps',
    1,
    'theorem bad(P : Prop) : P := by assumption;',
  );
  const analysis=service.analyze('file:///bad.ps');
  equal(analysis.kernel,'rejected');
  equal(analysis.diagnostics[0]?.severity,1);
  equal(service.proofState(
    'file:///bad.ps',
    {line:0,character:10},
  ).status,'rejected');
}

{
  const service=new ProofScriptLanguageService();
  service.openDocument(
    'file:///unsupported.ps',
    1,
    'structure Box where { value : Type; }',
  );
  const analysis=service.analyze('file:///unsupported.ps');
  equal(analysis.kernel,'verified');
  equal(analysis.diagnostics.length,0);
}

console.log('ok - @proofscript/language-service proof-aware document analysis');

{
  const service=new ProofScriptLanguageService();
  service.openDocument(
    'file:///proof.lean',
    1,
    'theorem id (P : Prop) (h : P) : P := by assumption\n',
    'lean-subset',
  );
  const analysis=service.analyze('file:///proof.lean');
  equal(analysis.sourceKind,'lean-subset');
  equal(analysis.frontend,'parsed');
  equal(analysis.kernel,'verified');
  equal(analysis.declarations[0]?.canonicalLean.startsWith('theorem id '),true);
  equal(service.documentStatus('file:///proof.lean').sourceKind,'lean-subset');
}
console.log('ok - @proofscript/language-service Lean-subset source routing');


{
  const service=new ProofScriptLanguageService();
  service.openDocument(
    'file:///nav.ps',
    1,
    'theorem id(P : Prop, h : P) : P := h; theorem use(P : Prop, h : P) : P := id(P, h);',
  );
  const completions=service.completions(
    'file:///nav.ps',
    {line:0,character:0},
  );
  equal(completions.some((item)=>item.label==='id'),true);
  equal(completions.some((item)=>item.label==='Prop'),true);
  const definition=service.definition(
    'file:///nav.ps',
    {line:0,character:75},
  );
  equal(definition?.uri,'file:///nav.ps');
  const references=service.references(
    'file:///nav.ps',
    {line:0,character:75},
    true,
  );
  equal(references.length,2);
}
console.log('ok - @proofscript/language-service navigation and completion');

{
  const service=new ProofScriptLanguageService();
  service.openDocument(
    'file:///sequence.ps',
    1,
    'theorem id(P : Prop, h : P) : P := by assumption; '+
    'theorem use(P : Prop, h : P) : P := by exact id(P, h);',
  );
  const analysis=service.analyze('file:///sequence.ps');
  equal(analysis.kernel,'verified');
  equal(analysis.declarations[1]?.kernel,'verified');
}
console.log('ok - @proofscript/language-service sequential document environment');

{
  const sources=new Map([
    [
      'Core',
      {
        uri:'file:///Core.lean',
        sourceKind:'lean-subset' as const,
        text:'theorem id (P : Prop) (h : P) : P := by assumption\n',
      },
    ],
  ]);
  const service=new ProofScriptLanguageService({
    projectHost:{
      entryModule:(snapshot)=>
        snapshot.uri.endsWith('/Main.ps')?'Main':'Core',
      resolveImport:(_entry,_importer,module)=>{
        const source=sources.get(module);
        if(source===undefined)throw new Error('missing module '+module);
        return source;
      },
    },
  });
  service.openDocument(
    'file:///Main.ps',
    1,
    'import Core;\ntheorem use(P : Prop, h : P) : P := by exact id(P, h);',
  );
  const analysis=service.analyze('file:///Main.ps');
  if(analysis.kernel!=='verified'){
    throw new Error(
      'mixed-source project analysis failed: '+
      JSON.stringify(analysis.diagnostics),
    );
  }
  equal(analysis.declarations[0]?.kernel,'verified');
  equal(analysis.project?.entryModule,'Main');
  equal(analysis.project?.moduleOrder.join(','),'Core,Main');
}
console.log('ok - @proofscript/language-service mixed-source import environment');

{
  const service=new ProofScriptLanguageService({
    projectHost:{
      entryModule:()=> 'Main',
      resolveImport:()=>{throw new Error('no source');},
    },
  });
  service.openDocument(
    'file:///Main.ps',
    1,
    'import Missing; theorem id(P : Prop, h : P) : P := by assumption;',
  );
  const analysis=service.analyze('file:///Main.ps');
  equal(analysis.kernel,'not-run');
  equal(analysis.diagnostics[0]?.code,'PS_PROJECT_ANALYSIS_ERROR');
}
console.log('ok - @proofscript/language-service project failure is fail-closed');

{
  const mainText=
    'import Core;\ntheorem use(P : Prop, h : P) : P := by exact id(P, h);';
  const coreText=
    'theorem id (P : Prop) (h : P) : P := by assumption\n';
  const service=new ProofScriptLanguageService({
    projectHost:{
      entryModule:(snapshot)=>
        snapshot.uri.endsWith('/Main.ps')?'Main':'Core',
      resolveImport:(_entry,_importer,module)=>{
        if(module!=='Core')throw new Error('missing module '+module);
        return {
          uri:'file:///Core.lean',
          sourceKind:'lean-subset' as const,
          text:coreText,
        };
      },
    },
  });
  service.openDocument('file:///Main.ps',1,mainText);
  const useOffset=mainText.indexOf('id(');
  const definition=service.definition(
    'file:///Main.ps',
    positionAt(mainText,useOffset+1),
  );
  equal(definition?.uri,'file:///Core.lean');
  const references=service.references(
    'file:///Main.ps',
    positionAt(mainText,useOffset+1),
    true,
  );
  equal(references.length,2);
  equal(references.some((item)=>item.uri==='file:///Core.lean'),true);
  equal(references.some((item)=>item.uri==='file:///Main.ps'),true);
  const completions=service.completions(
    'file:///Main.ps',
    {line:0,character:0},
  );
  const imported=completions.find((item)=>item.label==='id');
  equal(imported?.source,'project');
}
console.log('ok - @proofscript/language-service cross-source navigation');

{
  const service=new ProofScriptLanguageService();
  service.openDocument(
    'file:///Translate.ps',
    1,
    'theorem id(P : Prop, h : P) : P := by assumption;',
  );
  const lean=service.translateDocument('file:///Translate.ps','lean');
  equal(lean.extension,'.lean');
  equal(lean.text.includes('theorem id (P : Prop) (h : P)'),true);

  service.openDocument(
    'file:///Translate.lean',
    1,
    lean.text,
    'lean-subset',
  );
  const proofscript=service.translateDocument(
    'file:///Translate.lean',
    'ps',
  );
  equal(proofscript.extension,'.ps');
  equal(proofscript.text.includes('theorem id(P : Prop, h : P)'),true);
}
console.log('ok - @proofscript/language-service document translation');

{
  const coreUri='file:///Core.lean';
  const mainUri='file:///Main.ps';
  const diskCore=
    'theorem id (P : Prop) (h : P) : P := by assumption\n';
  const service=new ProofScriptLanguageService({
    projectHost:{
      entryModule:(snapshot)=>
        snapshot.uri===mainUri?'Main':'Core',
      resolveImport:(_entry,_importer,module)=>{
        if(module!=='Core')throw new Error('missing module '+module);
        return {
          uri:coreUri,
          sourceKind:'lean-subset' as const,
          text:diskCore,
        };
      },
    },
  });
  service.openDocument(
    mainUri,
    1,
    'import Core;\ntheorem use(P : Prop, h : P) : P := by exact id(P, h);',
  );
  equal(service.analyze(mainUri).kernel,'verified');

  service.openDocument(
    coreUri,
    1,
    'theorem id (P : Prop) : P := by assumption\n',
    'lean-subset',
  );
  const broken=service.analyze(mainUri);
  equal(broken.kernel,'not-run');
  equal(broken.diagnostics[0]?.code,'PS_PROJECT_ANALYSIS_ERROR');

  service.replaceDocument(
    coreUri,
    2,
    diskCore,
  );
  equal(service.analyze(mainUri).kernel,'verified');

  service.closeDocument(coreUri);
  equal(service.analyze(mainUri).kernel,'verified');
}
console.log('ok - @proofscript/language-service importer buffer invalidation');
