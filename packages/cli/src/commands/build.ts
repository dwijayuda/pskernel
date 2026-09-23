import {mkdir,writeFile} from 'node:fs/promises';
import {basename,extname,join,resolve} from 'node:path';
import {baseReport,compileSource} from '../pipeline.js';
import {resolveInput} from '../input.js';
import type {BuildResult,CommonArgs} from '../types.js';

export async function buildCommand(common:CommonArgs):Promise<BuildResult>{
  const input=await resolveInput(common);
  const stem=extname(input.sourcePath)==='.ps'?basename(input.sourcePath,'.ps'):basename(input.sourcePath);
  const result=compileSource(input.source,stem+'.ts');
  const outDir=resolve(input.loaded.directory,input.loaded.config.compilerOptions.outDir);
  await mkdir(outDir,{recursive:true});

  const tsPath=join(outDir,stem+'.ts');
  const jsPath=join(outDir,stem+'.js');
  const dtsPath=join(outDir,stem+'.d.ts');
  const leanPath=join(outDir,stem+'.lean');
  const mapPath=join(outDir,stem+'.js.map');
  const manifestPath=join(outDir,stem+'.proofscript.json');

  const report={
    ok:true,
    command:'build',
    ...baseReport(input.sourcePath,result.checked.structures.length+result.checked.inductives.length+result.checked.declarations.length,result.surface.featureIds),
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
