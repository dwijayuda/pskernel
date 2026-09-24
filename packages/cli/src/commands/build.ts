import {mkdir,writeFile} from 'node:fs/promises';
import {basename,extname,join,resolve} from 'node:path';
import {baseReport,compileSource} from '../pipeline.js';
import {compileCheckedCoreToWasm} from '@proofscript/compiler';
import {compileVerifiedSourceProject} from '../verified-project-pipeline.js';
import {resolveSourceProject} from '../project-sources.js';
import {resolveInput} from '../input.js';
import type {BuildReport,BuildResult,CommonArgs} from '../types.js';
import {
  writeVerifiedModuleArtifacts,
} from '../project-artifact-output.js';
import {verifiedAssuranceReport} from '../verified-assurance.js';
import {
  assertRuntimeDependencyPolicy,
  verifyInstalledRuntimeDependencies,
} from '../runtime-dependencies.js';
import {verifyRuntimeDependencyLock} from '../runtime-lock.js';

export async function buildCommand(common:CommonArgs):Promise<BuildResult>{
  const target=common.buildTarget??'js';
  if(target==='wasm'&&!common.verified){
    throw new Error(
      'PS_CLI_WASM_REQUIRES_VERIFIED: --target wasm requires --verified',
    );
  }
  if(common.verified){
    const input=await resolveInput(common);
    const extension=extname(input.sourcePath);
    const stem=basename(input.sourcePath,extension);
    const project=await resolveSourceProject(input);
    const runtimeDependencyPolicy=assertRuntimeDependencyPolicy(
      project,
      input.loaded.config.runtimeDependencies,
    );
    await verifyInstalledRuntimeDependencies(
      input.loaded.directory,
      runtimeDependencyPolicy,
    );
    const runtimeDependencyLock=await verifyRuntimeDependencyLock(
      input.loaded.directory,
      runtimeDependencyPolicy,
    );
    const outDir=resolve(
      input.loaded.directory,
      input.loaded.config.compilerOptions.outDir,
    );
    await mkdir(outDir,{recursive:true});

    const tsPath=join(outDir,stem+'.ts');
    const result=compileVerifiedSourceProject(
      project,
      tsPath,
    );
    const jsPath=join(outDir,stem+'.js');
    const dtsPath=join(outDir,stem+'.d.ts');
    const leanPath=join(outDir,stem+'.lean');
    const mapPath=join(outDir,stem+'.js.map');
    const manifestPath=join(outDir,stem+'.proofscript.json');
    const wasmPath=join(outDir,stem+'.wasm');
    const watPath=join(outDir,stem+'.wat');
    const wasm=target==='wasm'
      ?compileCheckedCoreToWasm(result.checkedCore)
      :null;
    const moduleArtifactFiles=await writeVerifiedModuleArtifacts(
      outDir,
      result.moduleArtifacts,
    );

    const report:BuildReport={
      ok:true,
      command:'build',
      ...baseReport(
        input.sourcePath,
        result.checkedCore.declarations.length,
        result.featureIds,
        result.canonicalSourceHash,
      ),
      moduleCount:result.moduleOrder.length,
      moduleOrder:result.moduleOrder,
      moduleSources:result.moduleSources,
      projectIntegrity:result.projectIntegrity,
      sourceRoots:result.sourceRoots,
      moduleCacheHits:result.moduleCacheHits,
      moduleCacheMisses:result.moduleCacheMisses,
      semanticPipeline:'verified-core',
      proofStatus:'kernel-verified',
      assurance:verifiedAssuranceReport(
        result.checkedCore,
        input.loaded.config.runtimeDependencies,
      ),
      runtimeDependencyPolicy,
      runtimeDependencyLock,
      buildTarget:target,
      outputDirectory:outDir,
      artifacts:{
        typescript:tsPath,
        javascript:jsPath,
        declarations:dtsPath,
        sourceMap:result.emitted.sourceMap===undefined?null:mapPath,
        lean:leanPath,
        manifest:manifestPath,
        modules:moduleArtifactFiles,
        ...(wasm===null?{}:{
          webassembly:wasmPath,
          wat:watPath,
        }),
      },
      typescriptVersion:result.emitted.typescriptVersion,
      ...(wasm===null?{}:{
        binaryenVersion:wasm.wasm.binaryenVersion,
        wasmProfile:wasm.wasm.profile,
        wasmOptimized:wasm.wasm.optimized,
        wasmExports:wasm.wasm.exports,
      }),
    };

    const writes=[
      writeFile(tsPath,result.typeScript,'utf8'),
      writeFile(jsPath,result.emitted.javascript,'utf8'),
      writeFile(dtsPath,result.emitted.declaration,'utf8'),
      writeFile(leanPath,result.lean,'utf8'),
      writeFile(
        manifestPath,
        JSON.stringify(report,null,2)+'\n',
        'utf8',
      ),
    ];
    if(result.emitted.sourceMap!==undefined){
      writes.push(writeFile(mapPath,result.emitted.sourceMap,'utf8'));
    }
    if(wasm!==null){
      writes.push(writeFile(wasmPath,wasm.wasm.binary));
      writes.push(writeFile(watPath,wasm.wasm.text,'utf8'));
    }
    await Promise.all(writes);
    return {
      report,
      verifiedIr:result.ir,
      ...(wasm===null?{}:{wasm:wasm.wasm}),
      jsPath,
    };
  }

  const input=await resolveInput(common);
  const extension=extname(input.sourcePath);
  const stem=basename(input.sourcePath,extension);
  const result=compileSource(
    input.source,
    stem+'.ts',
    input.sourcePath,
  );
  const outDir=resolve(input.loaded.directory,input.loaded.config.compilerOptions.outDir);
  await mkdir(outDir,{recursive:true});

  const tsPath=join(outDir,stem+'.ts');
  const jsPath=join(outDir,stem+'.js');
  const dtsPath=join(outDir,stem+'.d.ts');
  const leanPath=join(outDir,stem+'.lean');
  const mapPath=join(outDir,stem+'.js.map');
  const manifestPath=join(outDir,stem+'.proofscript.json');

  const report:BuildReport={
    ok:true,
    command:'build',
    ...baseReport(
      input.sourcePath,
      result.checked.structures.length+
        result.checked.inductives.length+
        result.checked.declarations.length,
      result.surface.featureIds,
      result.canonicalSourceHash,
    ),
    outputDirectory:outDir,
    artifacts:{
      typescript:tsPath,
      javascript:jsPath,
      declarations:dtsPath,
      sourceMap:result.emitted.sourceMap===undefined?null:mapPath,
      lean:leanPath,
      manifest:manifestPath,
    },
    typescriptVersion:result.emitted.typescriptVersion,
    proofStatusDetail:'The current software subset is structurally lowered and type-checked; theorem/proof declarations are not yet elaborated to pskernel.',
  };

  const writes=[
    writeFile(tsPath,result.typeScript,'utf8'),
    writeFile(jsPath,result.emitted.javascript,'utf8'),
    writeFile(dtsPath,result.emitted.declaration,'utf8'),
    writeFile(leanPath,result.lean,'utf8'),
    writeFile(manifestPath,JSON.stringify(report,null,2)+'\n','utf8'),
  ];
  if(result.emitted.sourceMap!==undefined)writes.push(writeFile(mapPath,result.emitted.sourceMap,'utf8'));
  await Promise.all(writes);
  return {report,checked:result.checked,jsPath};
}
