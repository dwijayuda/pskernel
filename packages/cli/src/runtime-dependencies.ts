import {createHash} from 'node:crypto';
import {readFile} from 'node:fs/promises';
import {join} from 'node:path';
import type {ResolvedSourceProject} from './project-sources.js';

export interface RuntimeDependencyPolicyEntry {
  readonly source:string;
  readonly version:string;
}

export interface RuntimeDependencyPolicyReport {
  readonly schema:'proofscript-runtime-dependencies-v1';
  readonly integrity:string;
  readonly used:readonly RuntimeDependencyPolicyEntry[];
}

function usedRuntimeSources(
  project:ResolvedSourceProject,
):readonly string[] {
  return [
    ...new Set(
      project.plan.order.flatMap((module)=>
        (project.sources.get(module)?.surface.declarations??[])
          .filter((declaration)=>declaration.kind==='external')
          .map((declaration)=>
            declaration.kind==='external'
              ?declaration.binding.source
              :''
          )
      ),
    ),
  ].filter((source)=>source.length>0).sort();
}

export function assertRuntimeDependencyPolicy(
  project:ResolvedSourceProject,
  configured:Readonly<Record<string,string>>,
):RuntimeDependencyPolicyReport {
  const used=usedRuntimeSources(project).map((source)=>{
    const version=configured[source];
    if(version===undefined){
      throw new Error(
        "PS_RUNTIME_DEPENDENCY_UNDECLARED: external module '"+source+
        "' is not listed in psconfig.json runtimeDependencies",
      );
    }
    return {source,version};
  });
  const schema='proofscript-runtime-dependencies-v1' as const;
  const integrity='sha256:'+createHash('sha256')
    .update(JSON.stringify({schema,used}),'utf8')
    .digest('hex');
  return {schema,integrity,used};
}

async function installedPackageIdentity(
  projectDirectory:string,
  source:string,
):Promise<{readonly name:string;readonly version:string}> {
  const path=join(
    projectDirectory,
    'node_modules',
    ...source.split('/'),
    'package.json',
  );
  let text:string;
  try{
    text=await readFile(path,'utf8');
  }catch{
    throw new Error(
      "PS_RUNTIME_DEPENDENCY_MISSING: package '"+source+
      "' is not installed at '"+path+"'",
    );
  }
  let parsed:unknown;
  try{
    parsed=JSON.parse(text);
  }catch{
    throw new Error(
      "PS_RUNTIME_DEPENDENCY_PACKAGE_JSON: package '"+source+
      "' has invalid package.json",
    );
  }
  if(
    typeof parsed!=='object'
    ||parsed===null
    ||Array.isArray(parsed)
  ){
    throw new Error(
      "PS_RUNTIME_DEPENDENCY_PACKAGE_JSON: package '"+source+
      "' has invalid package metadata",
    );
  }
  const record=parsed as Record<string,unknown>;
  if(typeof record.name!=='string'||typeof record.version!=='string'){
    throw new Error(
      "PS_RUNTIME_DEPENDENCY_PACKAGE_JSON: package '"+source+
      "' must expose string name/version",
    );
  }
  return {name:record.name,version:record.version};
}

export async function verifyInstalledRuntimeDependencies(
  projectDirectory:string,
  policy:RuntimeDependencyPolicyReport,
):Promise<void> {
  for(const dependency of policy.used){
    const installed=await installedPackageIdentity(
      projectDirectory,
      dependency.source,
    );
    if(installed.name!==dependency.source){
      throw new Error(
        "PS_RUNTIME_DEPENDENCY_IDENTITY: expected package '"+
        dependency.source+"', installed metadata names '"+installed.name+"'",
      );
    }
    if(installed.version!==dependency.version){
      throw new Error(
        "PS_RUNTIME_DEPENDENCY_VERSION: package '"+dependency.source+
        "' requires exact version "+dependency.version+
        ', installed '+installed.version,
      );
    }
  }
}
