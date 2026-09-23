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
