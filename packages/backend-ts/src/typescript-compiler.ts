import { spawnSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import {
  closeSync, existsSync, mkdtempSync, openSync, readFileSync, realpathSync, rmSync, statSync, unlinkSync, writeFileSync,
} from 'node:fs';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { fileURLToPath, pathToFileURL } from 'node:url';
import * as path from 'node:path';

export interface TypeScriptCompileResult {
  readonly javascript:string;
  readonly declaration:string;
  readonly sourceMap?:string;
  readonly diagnostics:readonly string[];
  readonly typescriptVersion:string;
}

const typescriptVersion='7.0.2';
const compilerTimeoutMs=120_000;
const compilerMaxBuffer=32*1024*1024;
let installedCli:string|undefined;

function object(value:unknown):Record<string,unknown> {
  if(value===null||typeof value!=='object'||Array.isArray(value)) {
    throw new Error('PS_TS_COMPILER_METADATA: expected an object');
  }
  return value as Record<string,unknown>;
}

function inside(directory:string,file:string):boolean {
  const relative=path.relative(directory,file);
  return relative!==''&&relative!=='..'&&!relative.startsWith('..'+path.sep)&&!path.isAbsolute(relative);
}

function compilerCli():string {
  if(installedCli!==undefined)return installedCli;
  try {
    const packageFile=realpathSync(createRequire(import.meta.url).resolve('typescript/package.json'));
    const directory=path.dirname(packageFile);
    const metadata=object(JSON.parse(readFileSync(packageFile,'utf8')));
    if(metadata['name']!=='typescript'||metadata['version']!==typescriptVersion) {
      throw new Error('expected installed typescript@'+typescriptVersion);
    }
    const bin=object(metadata['bin'])['tsc'];
    if(typeof bin!=='string'||bin.length===0||path.isAbsolute(bin)) {
      throw new Error('expected a relative package bin.tsc launcher');
    }
    const cli=realpathSync(path.resolve(directory,bin));
    if(!inside(directory,cli)||!statSync(cli).isFile()) {
      throw new Error('bin.tsc must be a regular file inside the installed TypeScript package');
    }
    const reported=spawnSync(process.execPath,[cli,'--version'],{
      encoding:'utf8',timeout:compilerTimeoutMs,maxBuffer:compilerMaxBuffer,
    });
    if(reported.error!==undefined||reported.signal!==null||reported.status!==0||
       reported.stdout.trim()!=='Version '+typescriptVersion||reported.stderr.trim()!=='') {
      throw new Error('installed launcher did not report TypeScript '+typescriptVersion);
    }
    installedCli=cli;
    return cli;
  } catch(error) {
    throw new Error('PS_TS_COMPILER_UNAVAILABLE: install typescript@'+typescriptVersion,{cause:error});
  }
}

function normalizedPath(file:string):string {
  const resolved=existsSync(file)?realpathSync(file):path.resolve(file);
  return process.platform==='win32'?resolved.toLowerCase():resolved;
}

function diagnosticText(line:string,stageFile:string,fileName:string):string {
  const rebase=(text:string):string=>{
    for(const spelling of [stageFile,stageFile.split(path.sep).join('/'),path.relative(process.cwd(),stageFile)]) {
      text=text.split(spelling).join(fileName);
    }
    return text.split(path.basename(stageFile)).join(path.basename(fileName));
  };
  const located=/^(.*)\((\d+),(\d+)\):\s+(?:error|warning)\s+TS(\d+):\s?(.*)$/.exec(line);
  if(located!==null) {
    const reported=located[1]!;
    const logical=normalizedPath(reported)===normalizedPath(stageFile)?fileName:reported;
    return logical+':'+located[2]+':'+located[3]+' TS'+located[4]+': '+rebase(located[5]!);
  }
  return rebase(line.replace(/^(?:error|warning)\s+(TS\d+):\s?/,'$1: '));
}

function rebaseMap(sourceMap:string,mapFile:string,stageFile:string,fileName:string):string {
  const map=object(JSON.parse(sourceMap));
  const sources=map['sources'];
  if(map['version']!==3||map['sourceRoot']!==''||!Array.isArray(sources)||
     sources.length!==1||typeof sources[0]!=='string'||
     normalizedPath(fileURLToPath(new URL(sources[0],pathToFileURL(mapFile))))!==normalizedPath(stageFile)) {
    throw new Error('PS_TS_SOURCE_MAP_UNSUPPORTED: expected the single virtual root source');
  }
  map['file']=path.basename(fileName,'.ts')+'.js';
  map['sources']=[encodeURIComponent(path.basename(fileName))];
  const ending=sourceMap.endsWith('\r\n')?'\r\n':sourceMap.endsWith('\n')?'\n':'';
  return JSON.stringify(map)+ending;
}

// TS7 has no compiler-host API. A unique sibling input retains the logical
// source directory's relative/package resolution without overwriting that source.
// Basename-dependent self references are explicitly refused, never redirected.
export function compileTypeScript(source:string,fileName='module.ts'):TypeScriptCompileResult {
  if(!fileName.endsWith('.ts')||fileName.endsWith('.d.ts')||/[\u0000-\u001f]/.test(fileName)) {
    throw new Error('PS_TS_SOURCE_NAME_UNSUPPORTED: expected an ordinary .ts file name');
  }
  const logicalFile=path.resolve(fileName);
  const directory=path.dirname(logicalFile);
  if(!existsSync(directory)||!statSync(directory).isDirectory()) {
    throw new Error('PS_TS_SOURCE_DIRECTORY_UNAVAILABLE: '+directory);
  }
  const cli=compilerCli();
  const stageStem='.psc-ts-'+randomUUID();
  const stageFile=path.join(directory,stageStem+'.ts');
  const outputDirectory=mkdtempSync(path.join(tmpdir(),'proofscript-ts7-'));
  let staged=false;
  try {
    const stage=openSync(stageFile,'wx');
    staged=true;
    try { writeFileSync(stage,source,'utf8'); }
    finally { closeSync(stage); }
    const compiled=spawnSync(process.execPath,[cli,
      '--ignoreConfig',
      '--target','ES2022',
      '--module','ES2022',
      '--moduleResolution','bundler',
      '--strict',
      '--declaration',
      '--sourceMap',
      '--noEmitOnError',
      '--skipLibCheck',
      '--types','*',
      '--noUncheckedSideEffectImports','false',
      '--libReplacement','true',
      '--pretty','false',
      // TS7 defaults rootDir to cwd. An explicit filesystem root admits the
      // caller's absolute virtual root and relative dependencies in one pass.
      '--rootDir',path.parse(logicalFile).root,
      '--outDir',outputDirectory,
      '--listFiles',
      '--listEmittedFiles',
      stageFile,
    ],{encoding:'utf8',timeout:compilerTimeoutMs,maxBuffer:compilerMaxBuffer});
    if(compiled.error!==undefined||compiled.signal!==null) {
      throw new Error('PS_TS_COMPILER_EXECUTION_FAILED',{cause:compiled.error});
    }
    const inputs:string[]=[];
    const outputs:string[]=[];
    const diagnostics:string[]=[];
    for(const line of (compiled.stdout+'\n'+compiled.stderr).split(/\r?\n/)) {
      if(line.trim()==='')continue;
      const candidate=line.replace(/^TSFILE:\s+/,'');
      if(path.isAbsolute(candidate)&&existsSync(candidate)&&statSync(candidate).isFile()) {
        if(inside(outputDirectory,candidate))outputs.push(candidate);
        else inputs.push(candidate);
      } else {
        diagnostics.push(diagnosticText(line,stageFile,fileName));
      }
    }
    // A sibling stage cannot impersonate the original basename in a cycle or
    // a triple-slash reference. Detect actual compiler-resolved source paths.
    const logicalStem=logicalFile.slice(0,-3);
    const originalCandidates=['.ts','.tsx','.d.ts','.js','.jsx'].map(
      (extension)=>normalizedPath(logicalStem+extension),
    );
    if(inputs.some((input)=>originalCandidates.includes(normalizedPath(input)))) {
      throw new Error('PS_TS_VIRTUAL_SELF_REFERENCE_UNSUPPORTED: '+fileName);
    }
    if(compiled.status!==0||diagnostics.length>0) {
      if(diagnostics.length===0)diagnostics.push('TypeScript exited with status '+compiled.status);
      throw new Error('PS_TS_COMPILE_FAILED:\n'+diagnostics.join('\n'));
    }
    const readOutput=(extension:string):{file:string;text:string}=>{
      const matches=[...new Set(outputs)].filter((file)=>path.basename(file)===stageStem+extension);
      if(matches.length!==1)throw new Error('PS_TS_COMPILE_MISSING_OUTPUT: '+extension);
      const file=matches[0]!;
      return {file,text:readFileSync(file,'utf8')};
    };
    const js=readOutput('.js');
    const declaration=readOutput('.d.ts').text;
    const map=readOutput('.js.map');
    const marker='//# sourceMappingURL='+stageStem+'.js.map';
    const endings=['\r\n','\n',''];
    const ending=endings.find((value)=>js.text.endsWith(marker+value));
    if(ending===undefined)throw new Error('PS_TS_SOURCE_MAP_UNSUPPORTED: missing root map footer');
    const javascript=js.text.slice(0,-(marker.length+ending.length))+
      '//# sourceMappingURL='+encodeURIComponent(path.basename(fileName,'.ts')+'.js.map')+ending;
    const sourceMap=rebaseMap(map.text,map.file,stageFile,fileName);
    if(javascript.includes(stageStem)||declaration.includes(stageStem)||sourceMap.includes(stageStem)) {
      throw new Error('PS_TS_SOURCE_NAME_UNSUPPORTED: basename-dependent compiler output');
    }
    return {javascript,declaration,sourceMap,diagnostics,typescriptVersion};
  } finally {
    try { if(staged)unlinkSync(stageFile); }
    finally { rmSync(outputDirectory,{recursive:true,force:true}); }
  }
}
