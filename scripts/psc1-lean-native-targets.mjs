import {createReadStream,writeFileSync} from 'node:fs';
import {createInterface} from 'node:readline';

const args=process.argv.slice(2);
function take(name,required=true){
  const i=args.indexOf(name);
  if(i<0){
    if(required)throw new Error(`missing ${name}`);
    return null;
  }
  if(i+1>=args.length)throw new Error(`missing value for ${name}`);
  const value=args[i+1];
  args.splice(i,2);
  return value;
}
const input=take('--input');
const out=take('--out',false);
if(args.length)throw new Error(`unexpected arguments: ${args.join(' ')}`);

let names=new Map([[0,'_']]);
let exprs=new Map();
const targetKinds=new Map();

function resetTables(){
  names=new Map([[0,'_']]);
  exprs=new Map();
}
function nameAt(i){
  const n=names.get(i);
  if(n===undefined)throw new Error(`undefined Name reference ${i}`);
  return n;
}
function exprAt(i){
  const e=exprs.get(i);
  if(e===undefined)throw new Error(`undefined Expr reference ${i}`);
  return e;
}
function appendName(parent,part){
  return parent==='_'?String(part):`${parent}.${part}`;
}
function recordTarget(kind,name,lineNo){
  const old=targetKinds.get(name);
  if(old!==undefined&&old!==kind)
    throw new Error(`native target kind conflict for ${name} at line ${lineNo}: ${old} vs ${kind}`);
  targetKinds.set(name,kind);
}

const rl=createInterface({input:createReadStream(input),crlfDelay:Infinity});
let lineNo=0;
for await(const line of rl){
  lineNo++;
  if(!line.trim())continue;
  let x;
  try{x=JSON.parse(line);}
  catch(e){throw new Error(`invalid JSON at line ${lineNo}`,{cause:e});}

  // DependencyExport segmented containers reset Name/Level/Expr intern tables.
  if(x.segment!==undefined){resetTables();continue;}
  if(Number.isSafeInteger(x.in)){
    if(x.str&&Number.isSafeInteger(x.str.pre)&&typeof x.str.str==='string'){
      names.set(x.in,appendName(nameAt(x.str.pre),x.str.str));
      continue;
    }
    if(x.num&&Number.isSafeInteger(x.num.pre)&&Number.isSafeInteger(x.num.i)){
      names.set(x.in,appendName(nameAt(x.num.pre),x.num.i));
      continue;
    }
  }
  if(Number.isSafeInteger(x.ie)){
    let node={kind:'other'};
    if(x.const&&Number.isSafeInteger(x.const.name)&&Array.isArray(x.const.us)){
      node={kind:'const',name:nameAt(x.const.name),levels:x.const.us.length};
    }else if(x.app&&Number.isSafeInteger(x.app.fn)&&Number.isSafeInteger(x.app.arg)){
      const fn=exprAt(x.app.fn),arg=exprAt(x.app.arg);
      node={kind:'app',fn:x.app.fn,arg:x.app.arg};
      if(fn.kind==='const'&&fn.levels===0&&arg.kind==='const'){
        if(fn.name==='Lean.reduceNat')recordTarget('nat',arg.name,lineNo);
        else if(fn.name==='Lean.reduceBool')recordTarget('bool',arg.name,lineNo);
      }
    }
    if(exprs.has(x.ie))throw new Error(`duplicate Expr id ${x.ie} at line ${lineNo}`);
    exprs.set(x.ie,node);
  }
}
const lines=[...targetKinds.entries()]
  .sort(([a],[b])=>a.localeCompare(b))
  .map(([name,kind])=>`${kind}:${name}`);
const text=lines.length?lines.join('\n')+'\n':'';
if(out)writeFileSync(out,text);
else process.stdout.write(text);
console.error(JSON.stringify({ok:true,input,targets:lines.length},null,2));
