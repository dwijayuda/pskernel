import {
  mkdir,
  mkdtemp,
  readFile,
  rm,
  writeFile,
} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {parseCommonArgs,parseTranslateArgs} from '../src/args.js';
import {
  checkVerifiedSource,
  compileVerifiedSource,
} from '../src/verified-pipeline.js';
import {verifiedAssuranceReport} from '../src/verified-assurance.js';
import {clearVerifiedProjectModuleCache} from '../src/verified-project-pipeline.js';
import {parseVerifiedRuntimeArg,prepareVerifiedMainArguments} from '../src/verified-runtime.js';
import {decodeVerifiedJsonArgument} from '../src/verified-runtime-json.js';
import {runCommand} from '../src/commands/run.js';
import {buildCommand} from '../src/commands/build.js';
import {checkCommand} from '../src/commands/check.js';
import {emitLeanCommand} from '../src/commands/emit-lean.js';
import {translateCommand} from '../src/commands/translate.js';
import {verifyRuntimeDependencyLock} from '../src/runtime-lock.js';
import {decodeModuleArtifact} from '@proofscript/module';
import {nameFromDotted} from 'lean-ts-kernel';

function equal(actual:unknown,expected:unknown):void{
  if(actual!==expected)throw new Error('expected '+String(expected)+', got '+String(actual));
}
function throws(fn:()=>unknown,pattern:RegExp):void{
  try{fn();}catch(error){
    if(pattern.test(error instanceof Error?error.message:String(error)))return;
    throw error;
  }
  throw new Error('expected throw '+String(pattern));
}

{
  const args=parseCommonArgs(['src/main.ps','-p','demo','--verified','--json','--','41','true']);
  equal(args.entry,'src/main.ps');
  equal(args.project,'demo');
  equal(args.json,true);
  equal(args.verified,true);
  equal(args.buildTarget,'js');
  equal(args.passthrough.join(','),'41,true');
}
{
  const args=parseCommonArgs(['--project','psconfig.json']);
  equal(args.project,'psconfig.json');
  equal(args.json,false);
  equal(args.verified,false);
  equal(args.buildTarget,'js');
}
{
  const args=parseCommonArgs([
    'src/main.ps','--verified','--target','wasm',
  ]);
  equal(args.buildTarget,'wasm');
}
throws(
  ()=>parseCommonArgs(['--target','wat']),
  /PS_CLI_BUILD_TARGET/,
);
throws(()=>parseCommonArgs(['--wat']),/PS_CLI_UNKNOWN_OPTION/);
throws(()=>parseCommonArgs(['a.ps','b.ps']),/PS_CLI_USAGE/);
{
  const args=parseTranslateArgs(['src/main.lean','--to','ps','-p','demo']);
  equal(args.entry,'src/main.lean');
  equal(args.target,'ps');
  equal(args.project,'demo');
}
throws(
  ()=>parseTranslateArgs(['main.ps']),
  /PS_CLI_TRANSLATE_TARGET/,
);
throws(
  ()=>parseTranslateArgs(['--to','lean','-p','demo']),
  /PS_CLI_TRANSLATE_ENTRY/,
);
throws(
  ()=>parseTranslateArgs(['main.ps','--to','ts']),
  /PS_CLI_TRANSLATE_TARGET/,
);
throws(
  ()=>parseTranslateArgs(['main.ps','--to','lean','--verified']),
  /PS_CLI_TRANSLATE_VERIFIED/,
);
throws(
  ()=>parseTranslateArgs([
    'main.ps','--to','lean','--target','wasm',
  ]),
  /PS_CLI_TRANSLATE_BUILD_TARGET/,
);
console.log('ok - psc CLI argument/UX contract');


{
  const result=compileVerifiedSource(
    'function identity {α : Type}(x : α) : α := x;',
    'identity.ts',
  );
  equal(result.checkedCore.kind,'proofscript-checked-core');
  equal(
    result.typeScript.includes('identity<T0>(x: T0): T0'),
    true,
  );
  equal(result.emitted.javascript.includes('function identity(x)'),true);
  equal(result.emitted.javascript.includes('T0'),false);
}
console.log('ok - psc verified checked-core compiler pipeline');

{
  const checked=checkVerifiedSource(
    'extern function hostInc(x : Nat) : Nat '+
    'from "host-lib" import inc; '+
    'function use(x : Nat) : Nat := hostInc(x);',
  );
  const assurance=verifiedAssuranceReport(checked.checkedCore);
  equal(checked.checkedCore.externals.length,1);
  equal(assurance.runtimeAssumptionCount,1);
  equal(assurance.runtimeAssumptions[0]?.name,'hostInc');
  equal(assurance.runtimeAssumptions[0]?.source,'host-lib');
  equal(assurance.runtimeAssumptions[0]?.importedName,'inc');
  equal(assurance.runtimeAssumptions[0]?.proofEvidence,false);
  equal(assurance.runtimeExternalsAreProofEvidence,false);
}
console.log('ok - psc verified runtime external assurance');

{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-external-assurance-check-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        runtimeDependencies:{'host-lib':'1.0.0'},
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.ps'),
      'extern function hostInc(x : Nat) : Nat '+
      'from "host-lib" import inc; '+
      'function use(x : Nat) : Nat := hostInc(x);\n',
      'utf8',
    );
    const result=await checkCommand({
      project:directory,
      json:true,
      verified:true,
      passthrough:[],
    });
    if(!('assurance' in result)){
      throw new Error('verified check did not return assurance');
    }
    const assurance=result.assurance;
    equal(assurance.runtimeAssumptionCount,1);
    equal(assurance.kernelCheckedDefinitionCount,1);
    equal(assurance.kernelCheckedTheoremCount,0);
    equal(assurance.runtimeAssumptions[0]?.source,'host-lib');
    equal(assurance.runtimeExternalsAreProofEvidence,false);
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc verified project assurance reports source externals');

{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-external-policy-reject-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.ps'),
      'extern function hostInc(x : Nat) : Nat '+
      'from "host-lib" import inc;\n',
      'utf8',
    );
    let rejected=false;
    try{
      await checkCommand({
        project:directory,
        json:true,
        verified:true,
        passthrough:[],
      });
    }catch(error){
      rejected=/PS_RUNTIME_DEPENDENCY_UNDECLARED/.test(String(error));
    }
    equal(rejected,true);
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc verified check rejects undeclared runtime dependency');

{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-external-runtime-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await mkdir(join(directory,'node_modules','host-lib'),{recursive:true});
    await mkdir(join(directory,'node_modules','helper-lib'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        runtimeDependencies:{'host-lib':'1.0.0'},
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'node_modules','host-lib','package.json'),
      JSON.stringify({
        name:'host-lib',
        version:'1.0.0',
        type:'module',
        main:'./index.js',
        types:'./index.d.ts',
        exports:{
          '.':{
            types:'./index.d.ts',
            import:'./index.js',
            default:'./index.js',
          },
          './feature':{
            types:'./feature.d.ts',
            import:'./feature.js',
            default:'./feature.js',
          },
        },
        dependencies:{'helper-lib':'2.0.0'},
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'node_modules','host-lib','index.js'),
      'import { suffix } from "helper-lib"; '+
      'export function shout(value) { return value + suffix; }\n',
      'utf8',
    );
    await writeFile(
      join(directory,'node_modules','host-lib','index.d.ts'),
      'export declare function shout(value: string): string;\n',
      'utf8',
    );
    await writeFile(
      join(directory,'node_modules','host-lib','feature.js'),
      'import { suffix } from "helper-lib"; '+
      'export function shout(value) { return value + suffix; }\n',
      'utf8',
    );
    await writeFile(
      join(directory,'node_modules','host-lib','feature.d.ts'),
      'export declare function shout(value: string): string;\n',
      'utf8',
    );
    await writeFile(
      join(directory,'node_modules','helper-lib','package.json'),
      JSON.stringify({
        name:'helper-lib',
        version:'2.0.0',
        type:'module',
        main:'./index.js',
        types:'./index.d.ts',
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'node_modules','helper-lib','index.js'),
      'export const suffix = "!";\n',
      'utf8',
    );
    await writeFile(
      join(directory,'node_modules','helper-lib','index.d.ts'),
      'export declare const suffix: string;\n',
      'utf8',
    );
    await writeFile(
      join(directory,'package-lock.json'),
      JSON.stringify({
        name:'proofscript-runtime-fixture',
        version:'1.0.0',
        lockfileVersion:3,
        requires:true,
        packages:{
          '':{
            name:'proofscript-runtime-fixture',
            version:'1.0.0',
            dependencies:{'host-lib':'1.0.0'},
          },
          'node_modules/host-lib':{
            version:'1.0.0',
            resolved:'https://registry.npmjs.org/host-lib/-/host-lib-1.0.0.tgz',
            integrity:'sha512-aG9zdA==',
            dependencies:{'helper-lib':'2.0.0'},
          },
          'node_modules/helper-lib':{
            version:'2.0.0',
            resolved:'https://registry.npmjs.org/helper-lib/-/helper-lib-2.0.0.tgz',
            integrity:'sha512-aGVscGVy',
          },
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.ps'),
      'extern function hostShout(value : String) : String '+
      'from "host-lib/feature" import shout; '+
      'function main(value : String) : String := hostShout(value);\n',
      'utf8',
    );

    const result=await runCommand({
      project:directory,
      json:true,
      verified:true,
      passthrough:['hello'],
    });
    equal(result.mainResult,'hello!');
    if(!('assurance' in result)){
      throw new Error('verified run did not retain assurance');
    }
    equal(result.assurance.runtimeAssumptionCount,1);
    equal(
      result.assurance.runtimeAssumptions[0]?.expectedVersion,
      '1.0.0',
    );
    equal(
      result.assurance.runtimeExternalsAreProofEvidence,
      false,
    );
    if(!('runtimeDependencyPolicy' in result)){
      throw new Error('verified run did not retain runtime dependency policy');
    }
    equal(result.runtimeDependencyPolicy.used.length,1);
    equal(
      result.runtimeDependencyPolicy.integrity.startsWith('sha256:'),
      true,
    );
    equal(
      result.runtimeDependencyPolicy.schema,
      'proofscript-runtime-dependencies-v2',
    );
    equal(
      result.runtimeDependencyPolicy.used[0]?.source,
      'host-lib/feature',
    );
    equal(
      result.runtimeDependencyPolicy.used[0]?.packageRoot,
      'host-lib',
    );
    equal(result.runtimeDependencyPolicy.used[0]?.version,'1.0.0');
    if(!('runtimeDependencyLock' in result)){
      throw new Error('verified run did not retain runtime dependency lock');
    }
    const lock=result.runtimeDependencyLock;
    if(lock===null||typeof lock!=='object'){
      throw new Error('verified run returned empty runtime dependency lock');
    }
    equal(lock.schema,'proofscript-runtime-lock-v2');
    equal(lock.lockfileVersion,3);
    equal(lock.roots[0]?.packageRoot,'host-lib');
    equal(lock.integrity.startsWith('sha256:'),true);
    equal(lock.roots.length,1);
    equal(lock.packages.length,2);
    equal(lock.packages[0]?.location,'node_modules/helper-lib');
    equal(lock.packages[0]?.version,'2.0.0');
    equal(lock.packages[1]?.location,'node_modules/host-lib');
    equal(
      lock.packages[1]?.dependencies[0]?.target,
      'node_modules/helper-lib',
    );
    const artifacts=result.artifacts;
    const javascript=await readFile(artifacts.javascript,'utf8');
    equal(
      javascript.includes('from "host-lib/feature"'),
      true,
    );
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc verified source FFI resolves exact package and runs');

{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-runtime-lock-missing-transitive-'),
  );
  try{
    await mkdir(join(directory,'node_modules','host-lib'),{recursive:true});
    await writeFile(
      join(directory,'node_modules','host-lib','package.json'),
      JSON.stringify({
        name:'host-lib',
        version:'1.0.0',
      })+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'package-lock.json'),
      JSON.stringify({
        name:'lock-missing-transitive',
        version:'1.0.0',
        lockfileVersion:3,
        packages:{
          '':{},
          'node_modules/host-lib':{
            version:'1.0.0',
            resolved:'https://registry.npmjs.org/host-lib/-/host-lib-1.0.0.tgz',
            integrity:'sha512-aG9zdA==',
            dependencies:{'helper-lib':'2.0.0'},
          },
        },
      })+'\n',
      'utf8',
    );
    let rejected=false;
    try{
      await verifyRuntimeDependencyLock(
        directory,
        {
          schema:'proofscript-runtime-dependencies-v2',
          integrity:'sha256:test',
          used:[{
            source:'host-lib/feature',
            packageRoot:'host-lib',
            version:'1.0.0',
          }],
        },
      );
    }catch(error){
      rejected=/PS_RUNTIME_LOCK_DEPENDENCY_MISSING/.test(String(error));
    }
    equal(rejected,true);
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc runtime lock rejects missing required transitive entry');



{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-wasm-build-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.ps'),
      'function main(x : Bool) : Bool := !x;\n',
      'utf8',
    );
    const checked=await checkCommand({
      project:directory,
      json:true,
      verified:true,
      buildTarget:'wasm',
      passthrough:[],
    });
    equal(checked.buildTarget,'wasm');
    equal(checked.wasmProfile,'proofscript-wasm32-mvp-js-v1');

    const built=await buildCommand({
      project:directory,
      json:true,
      verified:true,
      buildTarget:'wasm',
      passthrough:[],
    });
    equal(built.report.buildTarget,'wasm');
    const artifacts=built.report.artifacts;
    if(artifacts.webassembly===undefined||artifacts.wat===undefined){
      throw new Error('verified Wasm build did not emit Wasm artifacts');
    }
    const wasm=new Uint8Array(
      await readFile(artifacts.webassembly),
    );
    equal(WebAssembly.validate(wasm),true);
    equal(
      (await readFile(artifacts.wat,'utf8')).includes('(module'),
      true,
    );

    let legacyRejected=false;
    try{
      await buildCommand({
        project:directory,
        json:true,
        verified:false,
        buildTarget:'wasm',
        passthrough:[],
      });
    }catch(error){
      legacyRejected=/PS_CLI_WASM_REQUIRES_VERIFIED/.test(
        String(error),
      );
    }
    equal(legacyRejected,true);

    const runTrue=await runCommand({
      project:directory,
      json:true,
      verified:true,
      buildTarget:'wasm',
      passthrough:['true'],
    });
    equal(runTrue.mainResult,false);
    const runFalse=await runCommand({
      project:directory,
      json:true,
      verified:true,
      buildTarget:'wasm',
      passthrough:['false'],
    });
    equal(runFalse.mainResult,true);

    await writeFile(
      join(directory,'src','main.ps'),
      'function main(x : UInt32) : UInt32 := x;\n',
      'utf8',
    );
    const runUInt32=await runCommand({
      project:directory,
      json:true,
      verified:true,
      buildTarget:'wasm',
      passthrough:['4294967295'],
    });
    equal(runUInt32.mainResult,4294967295);

    await writeFile(
      join(directory,'src','main.ps'),
      'function main(x : UInt64) : UInt64 := x;\n',
      'utf8',
    );
    const runUInt64=await runCommand({
      project:directory,
      json:true,
      verified:true,
      buildTarget:'wasm',
      passthrough:['18446744073709551615'],
    });
    equal(runUInt64.mainResult,'18446744073709551615');
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc verified Wasm W2 build/run target');

{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-wasm-uint-run-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );

    const cases=[
      {type:'UInt8',input:'255',expected:255},
      {type:'UInt16',input:'65535',expected:65535},
      {type:'UInt32',input:'4294967295',expected:4294967295},
      {
        type:'UInt64',
        input:'18446744073709551615',
        expected:'18446744073709551615',
      },
    ] as const;

    for(const item of cases){
      await writeFile(
        join(directory,'src','main.ps'),
        'function main(x : '+item.type+') : '+item.type+' := x;\n',
        'utf8',
      );
      const result=await runCommand({
        project:directory,
        json:true,
        verified:true,
        buildTarget:'wasm',
        passthrough:[item.input],
      });
      equal(result.mainResult,item.expected);
    }
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc verified Wasm W2 UInt CLI run ABI');

{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-wasm-nat-pass-through-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.ps'),
      'function main(x : Nat) : Nat := x;\n',
      'utf8',
    );

    const checked=await checkCommand({
      project:directory,
      json:true,
      verified:true,
      buildTarget:'wasm',
      passthrough:[],
    });
    equal(checked.wasmProfile,'proofscript-wasm32-ref-js-v1');

    const huge=((1n<<100n)+123456789n).toString();
    const result=await runCommand({
      project:directory,
      json:true,
      verified:true,
      buildTarget:'wasm',
      passthrough:[huge],
    });
    equal(result.mainResult,huge);
    equal(result.wasmProfile,'proofscript-wasm32-ref-js-v1');

    let rejected=false;
    try{
      await runCommand({
        project:directory,
        json:true,
        verified:true,
        buildTarget:'wasm',
        passthrough:['-1'],
      });
    }catch(error){
      rejected=/Nat argument cannot be negative/.test(String(error));
    }
    equal(rejected,true);
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc verified Wasm W3a Nat externref pass-through');

{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-wasm-nat-literal-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    const huge='1267650600228229401496703205376';
    await writeFile(
      join(directory,'src','main.ps'),
      'function main(_seed : Nat) : Nat := '+huge+';\n',
      'utf8',
    );

    const checked=await checkCommand({
      project:directory,
      json:true,
      verified:true,
      buildTarget:'wasm',
      passthrough:[],
    });
    equal(checked.wasmProfile,'proofscript-wasm32-ref-js-v1');
    equal(checked.wasmRuntimeImports?.[0]?.name,'literal');
    equal(checked.wasmBigIntLiterals?.[0]?.decimal,huge);

    const result=await runCommand({
      project:directory,
      json:true,
      verified:true,
      buildTarget:'wasm',
      passthrough:['0'],
    });
    equal(result.mainResult,huge);
    equal(result.wasmBigIntLiterals?.[0]?.decimal,huge);
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc verified Wasm W3a Nat literal runtime');




{
  const result=compileVerifiedSource(
    'function add(x : Nat, y : Nat) : Nat := x + y; '+
    'function twice(x : Nat) : Nat := add(x, x);',
    'nat.ts',
  );
  equal(result.checkedCore.definitions.length,2);
  equal(result.typeScript.includes('return (x + y);'),true);
  equal(result.typeScript.includes('return add(x, x);'),true);
  equal(result.emitted.javascript.includes('function twice(x)'),true);
}
console.log('ok - psc verified Nat source pipeline');


{
  equal(parseVerifiedRuntimeArg('42',{kind:'primitive',name:'Nat'}),42n);
  equal(parseVerifiedRuntimeArg('-42',{kind:'primitive',name:'Int'}),-42n);
  equal(parseVerifiedRuntimeArg('true',{kind:'primitive',name:'Bool'}),true);
  equal(parseVerifiedRuntimeArg('255',{kind:'primitive',name:'UInt8'}),255);
  equal(parseVerifiedRuntimeArg('65535',{kind:'primitive',name:'UInt16'}),65535);
  equal(
    parseVerifiedRuntimeArg('4294967295',{kind:'primitive',name:'UInt32'}),
    4294967295,
  );
  equal(
    parseVerifiedRuntimeArg(
      '18446744073709551615',
      {kind:'primitive',name:'UInt64'},
    ),
    18446744073709551615n,
  );
  equal(parseVerifiedRuntimeArg('hello',{kind:'primitive',name:'String'}),'hello');
  equal(parseVerifiedRuntimeArg('()',{kind:'primitive',name:'Unit'}),undefined);
  throws(
    ()=>parseVerifiedRuntimeArg('-1',{kind:'primitive',name:'Nat'}),
    /Nat argument cannot be negative/,
  );
  throws(
    ()=>parseVerifiedRuntimeArg('yes',{kind:'primitive',name:'Bool'}),
    /Bool argument/,
  );
  throws(
    ()=>parseVerifiedRuntimeArg('256',{kind:'primitive',name:'UInt8'}),
    /outside/,
  );
  throws(
    ()=>parseVerifiedRuntimeArg(
      '18446744073709551616',
      {kind:'primitive',name:'UInt64'},
    ),
    /outside/,
  );
  const args=prepareVerifiedMainArguments({
    name:'main',
    typeParameters:[],
    parameters:[
      {name:'x',type:{kind:'primitive',name:'Nat'}},
      {name:'flag',type:{kind:'primitive',name:'Bool'}},
    ],
    resultType:{kind:'primitive',name:'Nat'},
    body:{kind:'var',name:'x'},
  },['7','false']);
  equal(args[0],7n);
  equal(args[1],false);
}
console.log('ok - psc verified runtime ABI');

{
  const decoded=decodeVerifiedJsonArgument(
    '"-42"',
    {kind:'primitive',name:'Int'},
    {
      module:{
        kind:'proofscript-verified-ir',
        declarations:[],
      },
      runtimeExports:{},
    },
  );
  equal(decoded,-42n);
}
console.log('ok - psc verified nested JSON Int ABI');


{
  const directory=await mkdtemp(join(tmpdir(),'proofscript-verified-run-'));
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.ps'),
      'function main(x : Nat) : Nat := x + x;\n',
      'utf8',
    );
    const result=await runCommand({
      project:directory,
      json:true,
      verified:true,
      passthrough:['21'],
    });
    equal(result.mainResult,'42');
    equal(result.semanticPipeline,'verified-core');
    equal(result.proofStatus,'kernel-verified');
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc verified run filesystem pipeline');

{
  const directory=await mkdtemp(join(tmpdir(),'proofscript-lean-verified-run-'));
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.lean',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.lean'),
      'def main (x : Nat) : Nat := x + x\n',
      'utf8',
    );
    const result=await runCommand({
      project:directory,
      json:true,
      verified:true,
      passthrough:['21'],
    });
    equal(result.mainResult,'42');
    equal(result.semanticPipeline,'verified-core');
    equal(result.proofStatus,'kernel-verified');
    equal(result.sourceKind,'lean-subset');
    equal(
      typeof result.canonicalSourceHash==='string'
        &&String(result.canonicalSourceHash).startsWith('sha256:'),
      true,
    );
    const artifacts=result.artifacts;
    equal(artifacts.typescript.endsWith('main.ts'),true);
    equal(artifacts.javascript.endsWith('main.js'),true);
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc verified Lean-subset run filesystem pipeline');


{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-verified-structure-abi-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.ps'),
      'structure User where { age : Nat; } '+
      'function main(user : User) : User := '+
      '{ age := user.age + 1 : User };\n',
      'utf8',
    );
    const result=await runCommand({
      project:directory,
      json:true,
      verified:true,
      passthrough:['{"age":"41"}'],
    });
    const output=result.mainResult as Record<string,unknown>;
    equal(output.age,'42');
    equal(result.semanticPipeline,'verified-core');
    equal(result.proofStatus,'kernel-verified');
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc verified structure JSON ABI round-trip');


{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-verified-adt-abi-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.ps'),
      'inductive PsOption(α : Type) where { '+
      '| none; | some(value : α); } '+
      'function main(value : PsOption(Nat)) : PsOption(Nat) := '+
      'match value with { '+
      '| .none => PsOption.some(1); '+
      '| .some x => PsOption.some(x + 1); };\n',
      'utf8',
    );
    const result=await runCommand({
      project:directory,
      json:true,
      verified:true,
      passthrough:['{"$ctor":"some","value":"41"}'],
    });
    const output=result.mainResult as Record<string,unknown>;
    equal(output.$ctor,'some');
    equal(output.value,'42');
    equal(result.semanticPipeline,'verified-core');
    equal(result.proofStatus,'kernel-verified');
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc verified generic ADT JSON ABI round-trip');


{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-verified-recursive-run-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.ps'),
      'inductive PsList(α : Type) where { '+
      '| nil; | cons(head : α, tail : PsList(α)); } '+
      'function length {α : Type}(xs : PsList(α)) : Nat := '+
      'match xs with { | .nil => 0; '+
      '| .cons head tail => 1 + length(tail); }; '+
      'function main(x : Nat) : Nat := '+
      'length(PsList.cons(x, PsList.cons(x, PsList.nil)));\n',
      'utf8',
    );
    const result=await runCommand({
      project:directory,
      json:true,
      verified:true,
      passthrough:['9'],
    });
    equal(result.mainResult,'2');
    equal(result.semanticPipeline,'verified-core');
    equal(result.proofStatus,'kernel-verified');
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc verified structural recursion run filesystem pipeline');


{
  const result=compileVerifiedSource(
    'function min(x : Nat, y : Nat) : Nat := '+
    'if (x <= y) { x } else { y };',
    'if.ts',
  );
  const min=result.ir.declarations.find((item)=>item.name==='min');
  equal(min?.body.kind,'if');
  if(min?.body.kind==='if'){
    equal(min.body.condition.kind,'intrinsic');
    if(min.body.condition.kind==='intrinsic'){
      equal(min.body.condition.operation,'nat.le');
    }
  }
  equal(result.typeScript.includes('x <= y'),true);
  equal(result.emitted.javascript.includes('x <= y'),true);
}
console.log('ok - psc verified proposition-based if pipeline');


{
  const result=compileVerifiedSource(
    'structure User where { age : Nat; } '+
    'function make(age : Nat) : User := { age := age : User }; '+
    'function get(user : User) : Nat := user.age;',
    'structure.ts',
  );
  equal(result.checkedCore.structures.length,1);
  equal(result.ir.structures?.length,1);
  equal(result.typeScript.includes('export interface User {'),true);
  equal(
    result.typeScript.includes(
      'function make(age: bigint): User',
    ),
    true,
  );
  equal(
    result.typeScript.includes(
      'return { [__ps$brand$0]: true, age: age };',
    ),
    true,
  );
  equal(result.typeScript.includes('return user.age;'),true);
  equal(result.emitted.javascript.includes('Symbol("ProofScript.User")'),true);
  equal(result.emitted.javascript.includes('function get(user)'),true);
  equal(result.emitted.declaration.includes('export interface User'),true);
}
{
  throws(
    ()=>compileVerifiedSource(
      'structure SigmaBox where { T : Type; value : T; } '+
      'function makeSigma(x : Nat) : SigmaBox := '+
      '{ T := Nat, value := x : SigmaBox };',
      'dependent-structure.ts',
    ),
    /PS_ERASE_DEPENDENT_STRUCTURE_FIELD_UNSUPPORTED/,
  );
}
console.log('ok - psc verified nominal structure pipeline');


{
  const result=compileVerifiedSource(
    'inductive MaybeNat where { | none; | some(value : Nat); } '+
    'const noneValue : MaybeNat := MaybeNat.none; '+
    'const oneValue : MaybeNat := MaybeNat.some(1);',
    'adt.ts',
  );
  equal(result.checkedCore.inductives.length,1);
  equal(result.ir.inductives?.length,1);
  equal(result.ir.inductives?.[0]?.name,'MaybeNat');
  equal(result.typeScript.includes('export type MaybeNat ='),true);
  equal(
    result.typeScript.includes(
      'unique symbol = Symbol("ProofScript.MaybeNat.tag")',
    ),
    true,
  );
  equal(
    result.typeScript.includes(
      '"some": (__field0: bigint): MaybeNat',
    ),
    true,
  );
  equal(
    result.typeScript.includes(
      'export const oneValue: MaybeNat = MaybeNat["some"](1n);',
    ),
    true,
  );
  equal(
    result.emitted.javascript.includes('Symbol("ProofScript.MaybeNat.tag")'),
    true,
  );
  equal(
    result.emitted.declaration.includes('export type MaybeNat ='),
    true,
  );
  equal(
    result.emitted.declaration.includes('export declare const MaybeNat'),
    true,
  );
}
console.log('ok - psc verified ADT constructor pipeline');


{
  const result=compileVerifiedSource(
    'inductive MaybeNat where { | none; | some(value : Nat); } '+
    'function getOrZero(value : MaybeNat) : Nat := '+
    'match value with { | .none => 0; | .some x => x; };',
    'adt-match.ts',
  );
  const get=result.ir.declarations.find(
    (item)=>item.name==='getOrZero',
  );
  equal(get?.body.kind,'match');
  equal(result.typeScript.includes('case "none": return 0n;'),true);
  equal(
    result.typeScript.includes(
      'case "some": return ((x: bigint) => x)(__ps$match$0.value);',
    ),
    true,
  );
  equal(result.emitted.javascript.includes('case "some"'),true);
}
console.log('ok - psc verified ADT match pipeline');


{
  const result=compileVerifiedSource(
    'inductive PsOption(α : Type) where { | none; | some(value : α); } '+
  'const noneNat : PsOption(Nat) := PsOption.none; '+
  'const oneNat : PsOption(Nat) := PsOption.some(1);',
    'generic-adt.ts',
  );
  equal(result.typeScript.includes('export type PsOption<T0> ='),true);
  equal(result.typeScript.includes('PsOption["none"]<bigint>()'),true);
  equal(result.typeScript.includes('PsOption["some"]<bigint>(1n)'),true);
  equal(result.emitted.javascript.includes('<T0>'),false);
}
console.log('ok - psc verified generic ADT constructor pipeline');


{
  const result=compileVerifiedSource(
    'inductive PsOption(α : Type) where { | none; | some(value : α); } '+
  'function getOr {α : Type}'+
  '(value : PsOption(α), fallback : α) : α := '+
  'match value with { | .none => fallback; | .some x => x; };',
    'generic-adt-match.ts',
  );
  const getOr=result.ir.declarations.find(
    (item)=>item.name==='getOr',
  );
  equal(getOr?.body.kind,'match');
  equal(
    result.typeScript.includes(
      'function getOr<T0>(value: PsOption<T0>, fallback: T0): T0',
    ),
    true,
  );
  equal(result.typeScript.includes('(x: T0) => x'),true);
  equal(result.emitted.javascript.includes('case "some"'),true);
}
console.log('ok - psc verified generic ADT match pipeline');


{
  const result=compileVerifiedSource(
    'inductive PsList(α : Type) where { '+
    '| nil; | cons(head : α, tail : PsList(α)); } '+
    'function headOr {α : Type}'+
    '(value : PsList(α), fallback : α) : α := '+
    'match value with { | .nil => fallback; | .cons head tail => head; };',
    'recursive-adt.ts',
  );
  const list=result.checkedCore.environment.find(
    nameFromDotted('PsList'),
  );
  equal(list?.kind,'inductive');
  if(list?.kind==='inductive')equal(list.isRec,true);
  equal(
    result.typeScript.includes(
      'readonly tail: PsList<T0>;',
    ),
    true,
  );
  equal(
    result.typeScript.includes(
      'function headOr<T0>(value: PsList<T0>, fallback: T0): T0',
    ),
    true,
  );
  equal(result.typeScript.includes('case "cons"'),true);
  equal(result.emitted.javascript.includes('case "cons"'),true);
}
console.log('ok - psc verified recursive ADT match pipeline');


{
  const result=compileVerifiedSource(
    'inductive PsList(α : Type) where { '+
    '| nil; | cons(head : α, tail : PsList(α)); } '+
    'function length {α : Type}(xs : PsList(α)) : Nat := '+
    'match xs with { | .nil => 0; | .cons head tail => 1 + length(tail); };',
    'recursive-function.ts',
  );
  const length=result.ir.declarations.find(
    (item)=>item.name==='length',
  );
  equal(length?.body.kind,'match');
  equal(
    result.typeScript.includes(
      'function length<T0>(xs: PsList<T0>): bigint',
    ),
    true,
  );
  equal(
    result.typeScript.includes(
      '1n + length(tail)',
    ),
    true,
  );
  equal(
    result.emitted.javascript.includes('length(tail)'),
    true,
  );
}
console.log('ok - psc verified structural recursive function pipeline');


{
  const result=compileVerifiedSource(
    'inductive PsListInvariant(α : Type) where { '+
    '| nil; | cons(head : α, tail : PsListInvariant(α)); } '+
    'function countFrom {α : Type}'+
    '(base : Nat, xs : PsListInvariant(α)) : Nat := '+
    'match xs with { | .nil => base; '+
    '| .cons head tail => 1 + countFrom(base, tail); };',
    'invariant-recursion.ts',
  );
  equal(
    result.typeScript.includes(
      'function countFrom<T0>(base: bigint, xs: PsListInvariant<T0>): bigint',
    ),
    true,
  );
  equal(
    result.typeScript.includes('countFrom(base, tail)'),
    true,
  );
  equal(
    result.emitted.javascript.includes('countFrom(base, tail)'),
    true,
  );
}
console.log('ok - psc verified invariant structural recursion pipeline');


{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-verified-invariant-recursion-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.ps'),
      'inductive PsList(α : Type) where { '+
      '| nil; | cons(head : α, tail : PsList(α)); } '+
      'function countFrom {α : Type}(base : Nat, xs : PsList(α)) : Nat := '+
      'match xs with { | .nil => base; '+
      '| .cons head tail => 1 + countFrom(base, tail); }; '+
      'function main(x : Nat) : Nat := '+
      'countFrom(x, PsList.cons(x, PsList.cons(x, PsList.nil)));\n',
      'utf8',
    );
    const result=await runCommand({
      project:directory,
      json:true,
      verified:true,
      passthrough:['5'],
    });
    equal(result.mainResult,'7');
    equal(result.semanticPipeline,'verified-core');
    equal(result.proofStatus,'kernel-verified');
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc verified invariant structural recursion run');


{
  const result=compileVerifiedSource(
    'inductive PsMapList(α : Type) where { '+
    '| nil; | cons(head : α, tail : PsMapList(α)); } '+
    'function map {α : Type}{β : Type}'+
    '(f : α -> β, xs : PsMapList(α)) : PsMapList(β) := '+
    'match xs with { | .nil => PsMapList.nil; '+
    '| .cons head tail => PsMapList.cons(f(head), map(f, tail)); };',
    'generic-map.ts',
  );
  equal(
    result.typeScript.includes(
      'function map<T0, T1>(f: (_arg0: T0) => T1, xs: PsMapList<T0>): PsMapList<T1>',
    ),
    true,
  );
  equal(result.typeScript.includes('map(f, tail)'),true);
  equal(result.typeScript.includes('f(head)'),true);
  equal(result.emitted.javascript.includes('map(f, tail)'),true);
}
console.log('ok - psc verified generic map structural recursion pipeline');


{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-verified-generic-map-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.ps'),
      'inductive PsList(α : Type) where { '+
      '| nil; | cons(head : α, tail : PsList(α)); } '+
      'function inc(x : Nat) : Nat := x + 1; '+
      'function map {α : Type}{β : Type}'+
      '(f : α -> β, xs : PsList(α)) : PsList(β) := '+
      'match xs with { | .nil => PsList.nil; '+
      '| .cons head tail => PsList.cons(f(head), map(f, tail)); }; '+
      'function length {α : Type}(xs : PsList(α)) : Nat := '+
      'match xs with { | .nil => 0; '+
      '| .cons head tail => 1 + length(tail); }; '+
      'function main(x : Nat) : Nat := '+
      'length(map(inc, PsList.cons(x, PsList.cons(x, PsList.nil))));\n',
      'utf8',
    );
    const result=await runCommand({
      project:directory,
      json:true,
      verified:true,
      passthrough:['9'],
    });
    equal(result.mainResult,'2');
    equal(result.semanticPipeline,'verified-core');
    equal(result.proofStatus,'kernel-verified');
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc verified generic map run filesystem pipeline');


{
  const result=compileVerifiedSource(
    'structure Box(α : Type) where { value : α; } '+
    'function boxNat(x : Nat) : Box(Nat) := '+
    '{ value := x : Box(Nat) }; '+
    'function unboxNat(box : Box(Nat)) : Nat := box.value;',
    'generic-structure-source.ts',
  );
  equal(result.checkedCore.structures.length,1);
  equal(result.ir.structures?.[0]?.typeParameters?.length,1);
  equal(result.typeScript.includes('export interface Box<T0> {'),true);
  equal(result.typeScript.includes('Box<bigint>'),true);
  equal(result.typeScript.includes('return box.value;'),true);
  equal(result.emitted.javascript.includes('function unboxNat(box)'),true);
}
console.log('ok - psc verified generic structure source pipeline');


{
  const result=compileVerifiedSource(
    'function plusTwo(x : Nat) : Nat := second(x) where { '+
    'second(y : Nat) : Nat := first(y) + 1; '+
    'first(y : Nat) : Nat := y + 1; }',
    'verified-where.ts',
  );
  equal(result.typeScript.includes('const first'),true);
  equal(result.typeScript.includes('const second'),true);
  equal(result.emitted.javascript.includes('first'),true);
  equal(result.emitted.javascript.includes('second'),true);
}
console.log('ok - psc verified acyclic where source pipeline');


{
  const result=compileVerifiedSource(
    'class Boxed(α : Type) where { value : α; } '+
    'function reuse {α : Type}[inst : Boxed(α)](x : α) : α := x; '+
    'function caller {α : Type}[inst : Boxed(α)](x : α) : α := reuse(x);',
    'local-instance-class.ts',
  );
  equal(result.checkedCore.classes.length,1);
  equal(result.checkedCore.structures.length,1);
  equal(
    result.typeScript.includes('export interface Boxed<T0> {'),
    true,
  );
  equal(
    result.typeScript.includes(
      'function reuse<T0>(inst: Boxed<T0>, x: T0): T0',
    ),
    true,
  );
  equal(
    result.typeScript.includes(
      'function caller<T0>(inst: Boxed<T0>, x: T0): T0',
    ),
    true,
  );
  equal(result.typeScript.includes('return reuse(inst, x);'),true);
  equal(result.emitted.javascript.includes('reuse(inst, x)'),true);
}
console.log('ok - psc verified local class instance pipeline');


{
  const result=compileVerifiedSource(
    'class Boxed(α : Type) where { value : α; } '+
    'instance boxedNat : Boxed(Nat) := { value := 7 : Boxed(Nat) }; '+
    'function get {α : Type}[inst : Boxed(α)](x : α) : α := inst.value; '+
    'function read(x : Nat) : Nat := get(x);',
    'global-instance-class.ts',
  );
  equal(result.checkedCore.classes.length,1);
  equal(result.checkedCore.instances.length,1);
  equal(result.checkedCore.instances[0]?.anonymous,false);
  equal(
    result.typeScript.includes(
      'export const boxedNat: Boxed<bigint>',
    ),
    true,
  );
  equal(
    result.typeScript.includes(
      'function get<T0>(inst: Boxed<T0>, x: T0): T0',
    ),
    true,
  );
  equal(
    result.typeScript.includes(
      'function read(x: bigint): bigint',
    ),
    true,
  );
  equal(
    result.typeScript.includes('return get(boxedNat, x);'),
    true,
  );
  equal(result.emitted.javascript.includes('get(boxedNat, x)'),true);
}
console.log('ok - psc verified global class instance pipeline');


{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-emit-lean-target-registry-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.ps'),
      'function add(x : Nat, y : Nat) : Nat := x + y;\n',
      'utf8',
    );
    const lean=await emitLeanCommand({
      project:directory,
      json:false,
      verified:false,
      passthrough:[],
    });
    equal(
      lean,
      'def add (x : Nat) (y : Nat) : Nat := x + y\n',
    );
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc emit-lean uses source/target dispatch');

{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-translate-roundtrip-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.ps'),
      'function add(x : Nat, y : Nat) : Nat := x + y;\n',
      'utf8',
    );
    const lean=await translateCommand({
      project:directory,
      entry:'src/main.ps',
      target:'lean',
      json:false,
      verified:false,
      passthrough:[],
    });
    equal(
      lean,
      'def add (x : Nat) (y : Nat) : Nat := x + y\n',
    );
    await writeFile(
      join(directory,'src','main.lean'),
      lean,
      'utf8',
    );
    const proofScript=await translateCommand({
      project:directory,
      entry:'src/main.lean',
      target:'ps',
      json:false,
      verified:false,
      passthrough:[],
    });
    equal(
      proofScript,
      'def add(x : Nat, y : Nat) : Nat := x + y;\n',
    );
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc translate ps/lean canonical round-trip');

{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-canonical-source-hash-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    const psSource='function add(x : Nat, y : Nat) : Nat := x + y;\n';
    await writeFile(
      join(directory,'src','main.ps'),
      psSource,
      'utf8',
    );
    const psCheck=await checkCommand({
      project:directory,
      entry:'src/main.ps',
      json:true,
      verified:true,
      passthrough:[],
    });
    const lean=await translateCommand({
      project:directory,
      entry:'src/main.ps',
      target:'lean',
      json:false,
      verified:false,
      passthrough:[],
    });
    await writeFile(
      join(directory,'src','main.lean'),
      lean,
      'utf8',
    );
    const leanCheck=await checkCommand({
      project:directory,
      entry:'src/main.lean',
      json:true,
      verified:true,
      passthrough:[],
    });
    equal(
      psCheck.canonicalSourceHash,
      leanCheck.canonicalSourceHash,
    );
    equal(
      String(psCheck.canonicalSourceHash).startsWith('sha256:'),
      true,
    );
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc canonical source hash is source-kind neutral');

{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-mixed-ps-entry-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.ps'),
      'import Data\nfunction main(x : Nat) : Nat := double(x);\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','Data.lean'),
      'import Core\ndef double (x : Nat) : Nat := twice x\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','Core.ps'),
      'function twice(x : Nat) : Nat := x + x;\n',
      'utf8',
    );
    const result=await runCommand({
      project:directory,
      json:true,
      verified:true,
      passthrough:['21'],
    });
    equal(result.mainResult,'42');
    equal(
      result.moduleOrder?.join(','),
      'Core,Data,main',
    );
    equal(result.moduleCount,3);
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc mixed ProofScript -> Lean import run');

{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-mixed-lean-entry-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.lean',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.lean'),
      'import Data\ndef main (x : Nat) : Nat := inc x\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','Data.ps'),
      'function inc(x : Nat) : Nat := x + 1;\n',
      'utf8',
    );
    const result=await runCommand({
      project:directory,
      json:true,
      verified:true,
      passthrough:['41'],
    });
    equal(result.mainResult,'42');
    equal(
      result.moduleOrder?.join(','),
      'Data,main',
    );
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc mixed Lean -> ProofScript import run');

{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-mixed-imported-metadata-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','Core.ps'),
      'structure Box(α : Type) where { value : α; } '+
      'class Boxed(α : Type) where { value : α; } '+
      'instance boxedNat : Boxed(Nat) := { value := 7 : Boxed(Nat) };\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','Data.lean'),
      'import Core\n'+
      'def make (x : Nat) : Box Nat := { value := x : Box Nat }\n'+
      'def unwrap (box : Box Nat) : Nat := box.value\n'+
      'def get {α : Type} [inst : Boxed α] (x : α) : α := inst.value\n'+
      'def read (x : Nat) : Nat := get x\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.ps'),
      'import Data\n'+
      'function main(x : Nat) : Nat := read(unwrap(make(x)));\n',
      'utf8',
    );
    const result=await runCommand({
      project:directory,
      json:true,
      verified:true,
      passthrough:['21'],
    });
    equal(result.mainResult,'7');
    equal(
      result.moduleOrder?.join(','),
      'Core,Data,main',
    );
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc mixed imports preserve structure/class/instance metadata');

{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-project-cache-integrity-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','Data.lean'),
      'def inc (x : Nat) : Nat := x + 1\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.ps'),
      'import Data\nfunction main(x : Nat) : Nat := inc(x);\n',
      'utf8',
    );

    clearVerifiedProjectModuleCache();
    const first=await checkCommand({
      project:directory,
      json:true,
      verified:true,
      passthrough:[],
    });
    equal(first.moduleCacheHits,0);
    equal(first.moduleCacheMisses,2);
    equal(String(first.projectIntegrity).startsWith('sha256:'),true);
    const firstSources=first.moduleSources;
    equal(
      firstSources.every((item)=>item.moduleIntegrity.startsWith('sha256:')),
      true,
    );

    const second=await checkCommand({
      project:directory,
      json:true,
      verified:true,
      passthrough:[],
    });
    equal(second.projectIntegrity,first.projectIntegrity);
    equal(second.moduleCacheHits,2);
    equal(second.moduleCacheMisses,0);

    await writeFile(
      join(directory,'src','Data.lean'),
      'def inc (x : Nat) : Nat := x + 2\n',
      'utf8',
    );
    const third=await checkCommand({
      project:directory,
      json:true,
      verified:true,
      passthrough:[],
    });
    equal(third.moduleCacheHits,0);
    equal(third.moduleCacheMisses,2);
    equal(third.projectIntegrity===first.projectIntegrity,false);
  }finally{
    clearVerifiedProjectModuleCache();
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc checked-module cache uses dependency integrity keys');

{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-persistent-module-artifacts-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','Data.lean'),
      'def inc (x : Nat) : Nat := x + 1\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.ps'),
      'import Data\nfunction main(x : Nat) : Nat := inc(x);\n',
      'utf8',
    );

    clearVerifiedProjectModuleCache();
    const built=await buildCommand({
      project:directory,
      json:true,
      verified:true,
      passthrough:[],
    });
    const artifactRecords=built.report.artifacts.modules;
    if(artifactRecords===undefined){
      throw new Error('verified build did not emit module artifacts');
    }
    equal(artifactRecords.length,2);

    const decoded=new Map<string,ReturnType<typeof decodeModuleArtifact>>();
    for(const record of artifactRecords){
      const artifact=decodeModuleArtifact(
        await readFile(record.path,'utf8'),
      );
      equal(artifact.version,2);
      equal(artifact.integrity,record.integrity);
      decoded.set(record.module,artifact);
    }
    const data=decoded.get('Data');
    const main=decoded.get('main');
    if(data===undefined||main===undefined){
      throw new Error('missing emitted module artifact');
    }
    equal(main.dependencies.length,1);
    equal(main.dependencies[0]?.module,'Data');
    equal(main.dependencies[0]?.integrity,data.integrity);
    equal(
      main.metadata!==undefined
      &&typeof main.metadata==='object'
      &&!Array.isArray(main.metadata),
      true,
    );
    if(
      main.metadata===undefined
      ||typeof main.metadata!=='object'
      ||main.metadata===null
      ||Array.isArray(main.metadata)
    ){
      throw new Error('missing module artifact metadata');
    }
    const metadata=main.metadata as Record<string,unknown>;
    equal(
      String(metadata.canonicalSourceHash).startsWith('sha256:'),
      true,
    );
    equal(
      String(metadata.sourceCacheKey).startsWith('sha256:'),
      true,
    );
    equal('sourceKind' in metadata,false);
  }finally{
    clearVerifiedProjectModuleCache();
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc emits replay-gated checked-admission .psmodule v2 artifacts');


{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-configured-source-roots-'),
  );
  try{
    await mkdir(join(directory,'app'),{recursive:true});
    await mkdir(join(directory,'lib','Util'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'app/main.ps',
        sourceRoots:['lib'],
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'app','main.ps'),
      'import Util.Math\nfunction main(x : Nat) : Nat := inc(x);\n',
      'utf8',
    );
    await writeFile(
      join(directory,'lib','Util','Math.lean'),
      'def inc (x : Nat) : Nat := x + 1\n',
      'utf8',
    );
    const result=await runCommand({
      project:directory,
      json:true,
      verified:true,
      passthrough:['41'],
    });
    equal(result.mainResult,'42');
    const roots=result.sourceRoots;
    if(roots===undefined){
      throw new Error('verified run did not retain configured source roots');
    }
    equal(roots.length,1);
    equal(roots[0],join(directory,'lib'));
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc configured source roots resolve mixed-source imports');

{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-source-root-ambiguity-'),
  );
  try{
    await mkdir(join(directory,'app'),{recursive:true});
    await mkdir(join(directory,'lib-a'),{recursive:true});
    await mkdir(join(directory,'lib-b'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'app/main.ps',
        sourceRoots:['lib-a','lib-b'],
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'app','main.ps'),
      'import Shared\nfunction main(x : Nat) : Nat := id(x);\n',
      'utf8',
    );
    await writeFile(
      join(directory,'lib-a','Shared.ps'),
      'function id(x : Nat) : Nat := x;\n',
      'utf8',
    );
    await writeFile(
      join(directory,'lib-b','Shared.lean'),
      'def id (x : Nat) : Nat := x\n',
      'utf8',
    );
    let rejected=false;
    try{
      await checkCommand({
        project:directory,
        json:true,
        verified:true,
        passthrough:[],
      });
    }catch(error){
      rejected=/PS_PROJECT_SOURCE_AMBIGUITY/.test(String(error));
    }
    equal(rejected,true);
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc configured source roots reject duplicate logical modules');

{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-mixed-ambiguity-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.ps'),
      'import Data\nfunction main(x : Nat) : Nat := x;\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','Data.ps'),
      'function a(x : Nat) : Nat := x;\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','Data.lean'),
      'def b (x : Nat) : Nat := x\n',
      'utf8',
    );
    let rejected=false;
    try{
      await checkCommand({
        project:directory,
        json:true,
        verified:true,
        passthrough:[],
      });
    }catch(error){
      rejected=/PS_PROJECT_SOURCE_AMBIGUITY/.test(String(error));
    }
    equal(rejected,true);
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc mixed-source module ambiguity fails closed');

{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-imports-legacy-reject-'),
  );
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.ps'),
      'import Data\nfunction main(x : Nat) : Nat := x;\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','Data.ps'),
      'function id(x : Nat) : Nat := x;\n',
      'utf8',
    );
    let rejected=false;
    try{
      await checkCommand({
        project:directory,
        json:true,
        verified:false,
        passthrough:[],
      });
    }catch(error){
      rejected=/PS_PROJECT_IMPORTS_REQUIRE_VERIFIED/.test(String(error));
    }
    equal(rejected,true);
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc imports fail closed on legacy semantic lane');


