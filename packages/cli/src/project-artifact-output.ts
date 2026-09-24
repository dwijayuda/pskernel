import {mkdir,writeFile} from 'node:fs/promises';
import {dirname,join} from 'node:path';
import {
  encodeModuleArtifact,
  type ModuleArtifactV2,
} from '@proofscript/module';

export interface VerifiedModuleArtifactRecord {
  readonly module:string;
  readonly artifact:ModuleArtifactV2;
}

export interface WrittenModuleArtifact {
  readonly module:string;
  readonly path:string;
  readonly integrity:string;
}

function moduleArtifactPath(
  root:string,
  module:string,
):string {
  return join(root,...module.split('.'))+'.psmodule';
}

export async function writeVerifiedModuleArtifacts(
  outDir:string,
  records:readonly VerifiedModuleArtifactRecord[],
):Promise<readonly WrittenModuleArtifact[]> {
  const root=join(outDir,'.proofscript','modules');
  const written:WrittenModuleArtifact[]=[];
  for(const record of records){
    const path=moduleArtifactPath(root,record.module);
    await mkdir(dirname(path),{recursive:true});
    await writeFile(
      path,
      encodeModuleArtifact(record.artifact),
      'utf8',
    );
    written.push({
      module:record.module,
      path,
      integrity:record.artifact.integrity,
    });
  }
  return written;
}
