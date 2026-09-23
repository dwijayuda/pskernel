import {readFileSync,readdirSync} from 'node:fs';
import {join} from 'node:path';
import {fileURLToPath} from 'node:url';

const root=fileURLToPath(new URL('..',import.meta.url));
const rootManifest=JSON.parse(
  readFileSync(join(root,'package.json'),'utf8'),
);
const lock=JSON.parse(
  readFileSync(join(root,'package-lock.json'),'utf8'),
);
const packages=lock.packages??{};

function fail(message){
  throw new Error('workspace-lock: '+message);
}

if(lock.lockfileVersion!==3){
  fail('expected lockfileVersion 3');
}

const lockRoot=packages[''];
if(lockRoot===undefined)fail('root package entry missing');
if(
  JSON.stringify(lockRoot.workspaces)!==
  JSON.stringify(rootManifest.workspaces)
){
  fail('root workspaces differ from package.json');
}

const workspaceDirs=readdirSync(join(root,'packages'),{
  withFileTypes:true,
})
  .filter((entry)=>entry.isDirectory())
  .map((entry)=>entry.name)
  .sort();

const workspaceNames=new Map();
for(const dir of workspaceDirs){
  const path='packages/'+dir;
  const manifest=JSON.parse(
    readFileSync(join(root,path,'package.json'),'utf8'),
  );
  if(workspaceNames.has(manifest.name)){
    fail('duplicate workspace package name '+manifest.name);
  }
  workspaceNames.set(manifest.name,path);

  const locked=packages[path];
  if(locked===undefined){
    fail('missing workspace lock entry '+path);
  }
  if(
    locked.name!==manifest.name||
    locked.version!==manifest.version
  ){
    fail('workspace identity drift '+path);
  }
  for(const field of ['dependencies','devDependencies']){
    const expected=manifest[field]??{};
    const actual=locked[field]??{};
    if(JSON.stringify(actual)!==JSON.stringify(expected)){
      fail(path+' '+field+' drift');
    }
  }

  const link=packages['node_modules/'+manifest.name];
  if(
    link?.link!==true||
    link.resolved!==path
  ){
    fail('missing workspace link for '+manifest.name);
  }
}

const rootLink=packages['node_modules/'+rootManifest.name];
if(
  [...workspaceNames.keys()].some((name)=>{
    const path=workspaceNames.get(name);
    const manifest=JSON.parse(
      readFileSync(join(root,path,'package.json'),'utf8'),
    );
    return Object.entries(manifest.dependencies??{}).some(
      ([dep,spec])=>dep===rootManifest.name&&spec.startsWith('file:'),
    );
  })&&(
    rootLink?.link!==true||
    rootLink.resolved!==''
  )
){
  fail('root package workspace link missing');
}

function exactVersion(spec){
  return /^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/u.test(spec)
    ?spec
    :null;
}

const manifests=[
  rootManifest,
  ...workspaceDirs.map((dir)=>JSON.parse(
    readFileSync(join(root,'packages',dir,'package.json'),'utf8'),
  )),
];
for(const manifest of manifests){
  for(const field of ['dependencies','devDependencies']){
    for(const [name,spec] of Object.entries(manifest[field]??{})){
      if(spec.startsWith('file:'))continue;
      if(workspaceNames.has(name))continue;
      const external=packages['node_modules/'+name];
      if(external===undefined){
        fail('missing external lock entry '+name);
      }
      const expected=exactVersion(spec);
      if(expected!==null&&external.version!==expected){
        fail(
          name+' locked at '+external.version+
          ', expected '+expected,
        );
      }
    }
  }
}

console.log(
  'workspace-lock: PASS ('+
  workspaceDirs.length+' workspaces)',
);
