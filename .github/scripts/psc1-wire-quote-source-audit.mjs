// Preserve exact legacy bodies while adding a transport serializer parameter.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import{spawnSync}from'node:child_process';import{createHash}from'node:crypto';
const base='7b9dc2725be226f401a8adcd2e6f0af391308504';
const read=file=>{const r=spawnSync('git',['show',base+':psc1/'+file],{encoding:'utf8',timeout:10000,maxBuffer:1048576});assert.equal(r.status,0,r.stderr);return r.stdout;};
const bfile='packages/bridge/src/Ps/Bridge/CompilerHost.lean',sfile='packages/compiler/src/Ps/Compiler/Service.lean',oldBridge=read(bfile),oldService=read(sfile),bridge=fs.readFileSync(bfile,'utf8'),service=fs.readFileSync(sfile,'utf8');
const block=(text,start,end)=>{const a=text.indexOf(start),b=text.indexOf(end,a);assert.ok(a>=0&&b>a);return text.slice(a,b);};
const oldB=block(oldBridge,'def psCompilerHostAdmissionRequest\n','/-- Compiler continuation');
const newB=block(bridge,'def psCompilerHostAdmissionRequestWithQuote','/-- Legacy transport');
const body=text=>text.slice(text.indexOf(' :=')+3).trim();
assert.equal(body(newB).replace(/\bquoteString\b/g,'psJsonQuote'),body(oldB));
const oldS=block(oldService,'def compilePreparedWithOutputAbi (','\ndef compilePrepared (');
const newS=block(service,'def compilePreparedWithQuote (','\ndef compilePreparedWithOutputAbi (');
assert.equal(body(newS).replace(/\bquoteString\b/g,'psJsonQuote').replace('psCompilerHostAdmissionRequestWithQuote psJsonQuote','psCompilerHostAdmissionRequest'),body(oldS));
const diff=spawnSync('git',['diff','--name-only',base,'--','packages','host','lakefile.lean','lean-toolchain'],{encoding:'utf8'});assert.equal(diff.status,0);assert.deepEqual(diff.stdout.trim().split('\n').sort(),[bfile,sfile].sort());
const proof='import Ps.Compiler.Service\n\n'+oldB.replace('def psCompilerHostAdmissionRequest\n','def psWireReferenceAdmissionRequest\n')+
 '\ntheorem psWireLegacyAdmissionEquation : psCompilerHostAdmissionRequest = psWireReferenceAdmissionRequest := rfl\n\nnamespace Ps.Internal.CompilerService\n'+
 oldS.replace('def compilePreparedWithOutputAbi (','def psWireReferenceCompilePrepared (')+
 '\ntheorem psWireLegacyCompilerEquation : compilePreparedWithOutputAbi = psWireReferenceCompilePrepared := rfl\nend Ps.Internal.CompilerService\n'+
 '#print axioms psWireLegacyAdmissionEquation\n#print axioms Ps.Internal.CompilerService.psWireLegacyCompilerEquation\n';
fs.mkdirSync('dist/wire-quote',{recursive:true});fs.writeFileSync('dist/wire-quote/LegacyEquations.lean',proof);
const proposal=JSON.parse(fs.readFileSync('../.github/psc1/wire-quote-candidate.json')),require=(await import('node:module')).createRequire(path.resolve('host-tools/package.json')),prettier=require('prettier'),{parse}=require('@babel/parser');
const ast=s=>JSON.parse(JSON.stringify(parse(s,{sourceType:'module'}),(key,v)=>['start','end','loc','extra','comments','leadingComments','trailingComments','innerComments'].includes(key)?undefined:v));
const pins=[],sources={};
for(const [file,source]of Object.entries(proposal.files)){assert.ok(['psc1/host-tools/prepared-engine.mjs','psc1/host-tools/wire-quote.mjs'].includes(file));const formatted=await prettier.format(source,{parser:'babel',singleQuote:true,printWidth:100,quoteProps:'preserve'});assert.deepEqual(ast(formatted),ast(source));fs.writeFileSync(file.slice(5),formatted);sources[file]=formatted;pins.push({path:file,bytes:Buffer.byteLength(formatted),sha256:createHash('sha256').update(formatted).digest('hex')});console.log('PSC1_QUOTE_HOST_SOURCE '+JSON.stringify({file,source:formatted}));}
fs.writeFileSync('dist/wire-quote/host-sources.json',JSON.stringify(sources,null,2)+'\n');fs.writeFileSync('dist/wire-quote/host-pins.json',JSON.stringify({producerCommit:process.env.GITHUB_SHA,base,pins},null,2)+'\n');
console.log('PSC1_WIRE_LEGACY_BODY_AUDIT '+JSON.stringify({status:'passed',base,sourceFiles:[bfile,sfile],hostPins:pins}));
