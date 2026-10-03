import {createHash} from 'node:crypto';
import {readdir,readFile,writeFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url));
const packageRoot=path.resolve(here,'..');
const root=path.join(packageRoot,'source','proofscript');
function gitObjectSha(type,body){const payload=Buffer.isBuffer(body)?body:Buffer.from(body);return createHash('sha1').update(Buffer.from(`${type} ${payload.length}\0`)).update(payload).digest();}
async function gitTreeSha(dir){const entries=(await readdir(dir,{withFileTypes:true})).sort((a,b)=>Buffer.from(a.name).compare(Buffer.from(b.name)));const parts=[];for(const entry of entries){const p=path.join(dir,entry.name);if(entry.isFile()){parts.push(Buffer.from(`100644 ${entry.name}\0`));parts.push(gitObjectSha('blob',await readFile(p)));}else if(entry.isDirectory()){parts.push(Buffer.from(`40000 ${entry.name}\0`));parts.push(Buffer.from(await gitTreeSha(p),'hex'));}else throw new Error('unsupported '+p);}return gitObjectSha('tree',Buffer.concat(parts)).toString('hex');}
const components={};
for(const n of ['foundation','core','environment','bridge','provider'])components[n]=await gitTreeSha(path.join(root,n));
const manifest={schemaVersion:1,packageName:'@proofscript/pskernel-lean',snapshotRoot:'source/proofscript',sourceRevision:'1b21b2483df7e8de7542873c24eaff2501539b1b',sourceTreeSha:await gitTreeSha(root),components};
await writeFile(path.join(packageRoot,'PROOFSCRIPT_SOURCE_MANIFEST.json'),JSON.stringify(manifest,null,2)+'\n');
console.log(JSON.stringify(manifest,null,2));