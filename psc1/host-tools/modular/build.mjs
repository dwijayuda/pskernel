// Additive experimental packaging session. Production proofscript packages and
// compiler executors are never replaced by this pilot.
import fs from 'node:fs';
import crypto from 'node:crypto';
import path from 'node:path';
import os from 'node:os';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
import {compileSources,run,sha256,packageNames,packageVersion,umbrellaName} from './compiler.mjs';
import {verifyPrintedGraph} from './graph.mjs';
import {openPublicationStore} from '../transactional-publication.mjs';
const workspace=fileURLToPath(new URL('../../',import.meta.url));
const fail=code=>{throw Error('PSC1_MODULAR_'+code);};
const json=v=>JSON.stringify(v,null,2)+'\n';
function put(root,name,value){
  const target=path.join(root,name);fs.mkdirSync(path.dirname(target),{recursive:true});
  fs.writeFileSync(target,value,{flag:'wx'});
}
export function files(root,prefix='',rows=[]){
  for(const name of fs.readdirSync(path.join(root,prefix)).sort()){
    const relative=prefix?prefix+'/'+name:name,s=fs.lstatSync(path.join(root,relative));
    if(s.isSymbolicLink())fail('PACKAGING_SYMLINK');
    if(s.isDirectory())files(root,relative,rows);
    else{if(!s.isFile())fail('PACKAGING_KIND');const b=fs.readFileSync(path.join(root,relative));
      rows.push({path:relative,bytes:b.length,sha256:sha256(b)});}
  }return rows;
}
function metadata(name,dependencies={},unit){
  return {name,version:packageVersion,type:'module',license:'Apache-2.0',engines:{node:'>=22.23.3'},
    exports:{'.':{types:'./dist/js/index.d.mts',import:'./dist/js/index.mjs'},
      './ts':{types:'./dist/ts/index.d.mts',import:'./dist/ts/index.mjs'},
      './package.json':'./package.json'},files:['dist','src','sources','PROVENANCE.json','LICENSE','NOTICE'],
    dependencies,proofscript:{profile:'psc1-modular-pilot/1',unit,experimental:true,
      admissionAuthority:false,publicationAuthority:false,compilerFrontend:false}};
}
function sdk(){
  const root=path.resolve(workspace,'../node_modules'),tsc=path.join(root,'typescript/bin/tsc');
  assert.match(run(process.execPath,[tsc,'--version']),/Version 7[.]0[.]2/);
  const roots=['typescript','@typescript/typescript-linux-x64'].map(p=>path.join(root,p));
  const pins=roots.flatMap(root=>files(root).map(p=>({...p,absolute:path.join(root,p.path)})));
  const verify=()=>{for(const p of pins)if(sha256(fs.readFileSync(p.absolute))!==p.sha256)fail('TYPESCRIPT_RESOURCE_CHANGED');};
  return {tsc,verify,resourcesSha256:sha256(json(pins.map(p=>({path:p.absolute,bytes:p.bytes,sha256:p.sha256}))))};
}
function compileTs(sdk,config,file){
  fs.writeFileSync(file,json(config));sdk.verify();
  run(process.execPath,[sdk.tsc,'--project',file]);sdk.verify();
}
function pack(root,destination){
  const out=JSON.parse(run('npm',['pack',root,'--ignore-scripts','--json','--pack-destination',destination]));
  assert.equal(out.length,1);const name=out[0].filename;
  if(!/^[a-z][a-z0-9.-]+[.]tgz$/.test(name))fail('TARBALL_PATH');
  const bytes=fs.readFileSync(path.join(destination,name));
  return{tarball:name,bytes:bytes.length,sha256:sha256(bytes)};
}
export function buildPilot({sources,out,producer,checker,sourceVariants,requestId='modular-pilot',publicationFault=()=>{}}){
  const publication=openPublicationStore(path.resolve(out),'portable-file');
  const admitted=compileSources({sources,producer,checker,requestId});
  const candidate=admitted.candidate,typescript=sdk();
  const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-modular-pack-'));
  let stage;
  try{
    const packages=packageNames.map((name,index)=>{
      const root=path.join(temporary,'packages',name.split('/')[1]);
      const actualDependencies=new Set([...(index===0?[]:[packageNames[0]]),
        ...candidate.js[index].imports.map(i=>i.source),...candidate.ts[index].imports.map(i=>i.source.replace(/\/ts$/,''))]);
      const dependencies=Object.fromEntries([...actualDependencies].sort().map(name=>{
        if(!packageNames.includes(name))fail('PACKAGE_DEPENDENCY');return[name,packageVersion];
      }));
      const meta=metadata(name,dependencies,index);
      put(root,'package.json',json(meta));
      put(root,'LICENSE',fs.readFileSync(path.join(workspace,'LICENSE')));
      put(root,'NOTICE',fs.readFileSync(path.join(workspace,'NOTICE')));
      put(root,'dist/js/index.mjs',candidate.js[index].source);
      put(root,'src/ts/index.mts',candidate.ts[index].source);
      // Own sources are data, never imports, plugins, or an authority selector.
      const selected=index===0?[]:[sources[index-1]];
      for(const source of selected){
        put(root,'sources/'+(index===1?'Name':'Consumer')+'.'+source.kind,source.text);
        const alternate=sourceVariants?.[source.module];
        if(alternate&&alternate.kind!==source.kind)put(root,'sources/'+(index===1?'Name':'Consumer')+'.'+alternate.kind,alternate.text);
      }
      put(root,'PROVENANCE.json',json({schema:'psc1-modular-unit-provenance/1',unit:index,
        sourceClosureDigest:candidate.sourceClosureDigest,candidateSha256:admitted.candidateSha256,
        ownerNames:candidate.units[index].names,origins:candidate.origins,profile:candidate.profile,
        generatedTypeScriptMap:'dist/ts/index.mjs.map maps to src/ts/index.mts',
        originalSourceMapping:'declaration origins only; no fabricated Lean line sourcemap',
        fullCompilerSelfHosting:false}));
      return{root,name,meta};
    });
    const paths={};
    for(const [index,pkg]of packages.entries()){
      // Declaration inference covers unchanged JS runtime helpers. Public data
      // types and source function signatures come from the same checked IR.
      if(index===0){
        const infer=path.join(temporary,'js-runtime-types');
        compileTs(typescript,{compilerOptions:{allowJs:true,checkJs:false,declaration:true,emitDeclarationOnly:true,
          noEmitOnError:true,target:'ES2022',module:'NodeNext',moduleResolution:'NodeNext',types:[],rootDir:path.join(pkg.root,'dist/js'),outDir:infer},
          files:[path.join(pkg.root,'dist/js/index.mjs')]},path.join(temporary,'infer.json'));
        put(pkg.root,'dist/js/index.d.mts',fs.readFileSync(path.join(infer,'index.d.mts'),'utf8')+candidate.js[index].declarations);
      }else put(pkg.root,'dist/js/index.d.mts',candidate.js[index].declarations);
      compileTs(typescript,{compilerOptions:{strict:true,noEmitOnError:true,target:'ES2022',module:'NodeNext',
        moduleResolution:'NodeNext',declaration:true,declarationMap:true,sourceMap:true,inlineSources:true,
        types:[],lib:['ES2022','DOM'],rootDir:path.join(pkg.root,'src/ts'),outDir:path.join(pkg.root,'dist/ts'),paths},
        files:[path.join(pkg.root,'src/ts/index.mts')]},path.join(temporary,'unit-'+index+'.json'));
      paths[pkg.name]=[path.join(pkg.root,'dist/js/index.d.mts')];
      paths[pkg.name+'/ts']=[path.join(pkg.root,'dist/ts/index.d.mts')];
    }
    const graphEvidence={};
    for(const variant of ['js','ts'])
      graphEvidence[variant]=verifyPrintedGraph(candidate,variant,packages.map(p=>fs.readFileSync(path.join(p.root,'dist',variant,'index.mjs'),'utf8')));
    const tarballs=path.join(temporary,'tarballs');fs.mkdirSync(tarballs);
    const records=packages.map(pkg=>({name:pkg.name,version:packageVersion,files:files(pkg.root),...pack(pkg.root,tarballs)}));
    const umbrella=path.join(temporary,'umbrella');fs.mkdirSync(umbrella);
    const meta={name:umbrellaName,version:packageVersion,type:'module',license:'Apache-2.0',engines:{node:'>=22.23.3'},
      exports:{'.':{types:'./index.d.mts',import:'./index.mjs'},'./package.json':'./package.json'},
      dependencies:Object.fromEntries(packageNames.map(name=>[name,packageVersion])),
      proofscript:{profile:'psc1-modular-pilot/1',experimental:true,admissionAuthority:false,publicationAuthority:false}};
    put(umbrella,'package.json',json(meta));
    put(umbrella,'LICENSE',fs.readFileSync(path.join(workspace,'LICENSE')));
    put(umbrella,'NOTICE',fs.readFileSync(path.join(workspace,'NOTICE')));
    put(umbrella,'loader.mjs',fs.readFileSync(new URL('./loader.mjs',import.meta.url)));
    put(umbrella,'index.d.mts',[
      "export interface PilotIdentity { readonly sourceClosureDigest: string; readonly checkerCommit: string; readonly logicalAdmission: 'accepted'; }",
      "export declare function verifyPilot(): PilotIdentity;",
      "export declare function loadPilot(options?:{variant?:'js'}):Promise<{readonly variant:'js';readonly sourceClosureDigest:string;readonly runtime:typeof import('@proofscript/modular-pilot-runtime');readonly names:typeof import('@proofscript/modular-pilot-names');readonly consumer:typeof import('@proofscript/modular-pilot-consumer')}>;",
      "export declare function loadPilot(options:{variant:'ts'}):Promise<{readonly variant:'ts';readonly sourceClosureDigest:string;readonly runtime:typeof import('@proofscript/modular-pilot-runtime/ts');readonly names:typeof import('@proofscript/modular-pilot-names/ts');readonly consumer:typeof import('@proofscript/modular-pilot-consumer/ts')}>;"
    ].join('\n')+'\n');
    const cohort={schema:'psc1-modular-installed-cohort/1',version:packageVersion,
      sourceClosureDigest:candidate.sourceClosureDigest,grammar:candidate.grammar,
      compilerCommit:process.env.GITHUB_SHA,producerSha256:admitted.resources[0].sha256,
      checkerCommit:admitted.receipt.checkerCommit,admissionsSha256:admitted.receipt.admissionsDigest,
      logicalAdmission:'accepted',behaviorallyVerified:false,
      originalIrSha256:admitted.originalIrSha256,transformedIrSha256:admitted.transformedIrSha256,
      typeAbis:{js:'structural-$ps$tag/1',ts:'shared-unique-symbols/1'},packages:records,
      bootstrapFiles:files(umbrella),graphEvidence,
      sourceRecords:sources.map(s=>({module:s.module,kind:s.kind,sha256:sha256(s.text)})),
      claim:'experimental compiler component graph; canonical Core admission and bounded IR/consumer checks; no backend preservation proof or modular self-hosting claim'};
    const cohortBytes=Buffer.from(json(cohort)),cohortSha256=sha256(cohortBytes);
    put(umbrella,'cohort.json',cohortBytes);
    put(umbrella,'index.mjs',"import {createPilotLoader} from './loader.mjs';\nconst loader=createPilotLoader(new URL('.',import.meta.url),"+
      JSON.stringify(cohortSha256)+");\nexport const verifyPilot=loader.verify;\nexport const loadPilot=loader.load;\n");
    const rootTar=pack(umbrella,tarballs);
    stage=path.join(publication.root,'generations','.stage-'+cryptoId());fs.mkdirSync(stage,{mode:0o700});
    for(const row of [...records,rootTar])fs.copyFileSync(path.join(tarballs,row.tarball),path.join(stage,row.tarball));
    put(stage,'cohort.json',cohortBytes);put(stage,'admissions.json',candidate.admissions);
    put(stage,'original-ir.json',json(candidate.originalIr));put(stage,'transformed-ir.json',json(candidate.transformedIr));
    put(stage,'sources.json',json(sources));
    put(stage,'qualification-input.json',json({schema:'psc1-modular-pilot-input/1',testedCommit:process.env.GITHUB_SHA,
      cohortSha256,rootTar,packages:records.map(({files,...rest})=>rest),
      admission:admitted.receipt,execution:admitted.execution,typescriptResourcesSha256:typescript.resourcesSha256,
      candidateSha256:admitted.candidateSha256,profile:candidate.profile,scope:'additive pilot; existing qualified compiler untouched'}));
    const sealed=files(stage);
    if(sealed.reduce((n,p)=>n+p.bytes,0)>32*1024*1024)fail('AGGREGATE_BOUND');
    const manifest={schema:'psc1-generated-service-bundle/1',kind:'modular-pilot-npm-cohort',
      targetFile:'cohort.json',checkerCommit:admitted.receipt.checkerCommit,logicalAdmission:'accepted',
      irValidation:'original-and-transformed-strict',files:sealed,behaviorallyVerified:false,cohortSha256};
    const verify=()=>{
      typescript.verify();for(const pin of admitted.resources)if(sha256(fs.readFileSync(pin.file))!==pin.sha256)fail('TOOL_CHANGED');
    };
    const published=publication.publish({stage,manifest,verify,fault:publicationFault});stage=undefined;
    return Object.freeze({...published,cohortSha256,rootTar,packages:records,candidate,receipt:admitted.receipt,
      execution:admitted.execution,typescriptResourcesSha256:typescript.resourcesSha256});
  }finally{
    if(stage&&fs.existsSync(stage))fs.rmSync(stage,{recursive:true,force:true});
    fs.rmSync(temporary,{recursive:true,force:true});
  }
}
function cryptoId(){return crypto.randomUUID();}
