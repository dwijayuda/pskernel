import fs from 'node:fs';
import {
  Lean4ExportReplay,
  addOffset,
  levelEqStructural,
  levelIMaxRaw,
  levelMVar,
  levelMaxRaw,
  levelParam,
  levelSucc,
  levelZero,
  nameFromDotted,
} from '../dist/src/index.js';
import {
  Lean434Evaluator,
} from '../packages/runtime/dist/src/lean4-eval.js';
import {
  kernelLevelToLean434Runtime,
  lean434RuntimeLevelToKernel,
} from '../packages/runtime/dist/src/lean4-level.js';

const fixture=process.argv[2]??'lean434-level-bootstrap.ndjson';
if(!fs.existsSync(fixture)){
  throw new Error('missing generated Lean.Level fixture: '+fixture);
}

function declarationOrder(text){
  const names=['_'];
  const declarations=[];
  for(const raw of text.split(/\r?\n/u)){
    if(raw.trim()==='')continue;
    const record=JSON.parse(raw);
    if(Number.isInteger(record.in)){
      let value;
      if(record.str){
        value=(names[record.str.pre]==='_'?'':names[record.str.pre]+'.')+
          record.str.str;
      }else if(record.num){
        value=(names[record.num.pre]==='_'?'':names[record.num.pre]+'.')+
          String(record.num.i);
      }
      if(value!==undefined)names[record.in]=value;
      continue;
    }
    const named=(kind,obj)=>{
      if(obj&&Number.isInteger(obj.name)){
        declarations.push(kind+':'+names[obj.name]);
      }
    };
    named('def',record.def);
    named('opaque',record.opaque);
    named('axiom',record.axiom);
    named('thm',record.thm);
    if(record.inductive){
      for(const type of record.inductive.types??[]){
        named('inductive',type);
      }
    }
  }
  return declarations;
}

const deltaText=fs.readFileSync(fixture,'utf8');
const order=declarationOrder(deltaText);
const levelOrder=order.filter(x=>x.includes('Lean.Level'));
console.log(JSON.stringify({
  phase:'level-export-order',
  declarations:order.length,
  levelDeclarations:levelOrder,
},null,2));
const logicalIndex=order.indexOf('inductive:Lean.Level');
const implIndex=order.indexOf('inductive:Lean.Level_impl');
if(
  logicalIndex>=0
  &&implIndex>=0
  &&logicalIndex>implIndex
){
  throw new Error(
    'Lean.Level_impl was exported before logical Lean.Level',
  );
}

const preludeFixture='oracle/fixtures/lean434-init-prelude.ndjson';
if(!fs.existsSync(preludeFixture)){
  throw new Error('missing pinned Lean 4.34 Init.Prelude fixture');
}

const prelude=new Lean4ExportReplay();
prelude.replay(fs.readFileSync(preludeFixture,'utf8'));
const replay=new Lean4ExportReplay(prelude.env);
replay.replay(deltaText);

const evaluator=new Lean434Evaluator(replay.env);
const input=levelIMaxRaw(
  levelMaxRaw(
    levelSucc(levelParam(nameFromDotted('u'))),
    levelMVar(nameFromDotted('m')),
  ),
  levelSucc(levelZero),
);

let addOffsetFn=evaluator.evaluate(
  {kind:'const',name:nameFromDotted('Lean.Level.addOffset'),levels:[]},
);
addOffsetFn=evaluator.applyRuntimeValue(
  addOffsetFn,
  kernelLevelToLean434Runtime(input),
);
const result=evaluator.applyRuntimeValue(addOffsetFn,2n);
const actual=lean434RuntimeLevelToKernel(result);
const expected=addOffset(input,2n);

if(!levelEqStructural(actual,expected)){
  throw new Error(
    'real Lean.Level.addOffset disagrees structurally with pskernel Level.addOffset',
  );
}

console.log(
  'ok - real Lean.Level.addOffset executes through canonical pskernel Level bridge',
);
