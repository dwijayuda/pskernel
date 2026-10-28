// Installed pilot integrity loader. The qualified bootstrap/pin is the trust
// anchor. Package metadata and source modules cannot grant checker authority.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {createRequire} from 'node:module';
import {fileURLToPath,pathToFileURL} from 'node:url';
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const fail=code=>{throw Error('PSC1_MODULAR_'+code);};
function file(root,relative){
  if(typeof relative!=='string'||relative.length>256||!relative.split('/').every(p=>/^[A-Za-z0-9_.-]+$/.test(p)&&!['.','..'].includes(p)))
    fail('RESOURCE_PATH');
  const absolute=path.resolve(root,...relative.split('/'));
  if(!absolute.startsWith(root+path.sep))fail('RESOURCE_PATH');
  for(let p=absolute;p!==root;p=path.dirname(p))if(fs.lstatSync(p).isSymbolicLink())fail('RESOURCE_SYMLINK');
  const stat=fs.lstatSync(absolute);if(!stat.isFile()||stat.size>32*1024*1024)fail('RESOURCE_KIND');
  return fs.readFileSync(absolute);
}
function inventory(root,prefix='',rows=[]){
  for(const name of fs.readdirSync(path.join(root,prefix)).sort()){
    const relative=prefix?prefix+'/'+name:name,p=path.join(root,relative),s=fs.lstatSync(p);
    if(s.isSymbolicLink())fail('RESOURCE_SYMLINK');
    if(s.isDirectory()){
      if(relative.split('/').length>8)fail('RESOURCE_DEPTH');
      rows.push(relative+'/');inventory(root,relative,rows);
    }
    else{if(!s.isFile())fail('RESOURCE_KIND');rows.push(relative);}
    if(rows.length>1024)fail('RESOURCE_COUNT');
  }return rows.sort();
}
function expectedEntries(files){
  const entries=new Set(files);
  for(const file of files){const parts=file.split('/');for(let n=1;n<parts.length;n++)entries.add(parts.slice(0,n).join('/')+'/');}
  return [...entries].sort();
}
export function createPilotLoader(rootUrl,expectedDigest){
  const root=path.resolve(rootUrl instanceof URL?fileURLToPath(rootUrl):rootUrl);
  if(!/^[a-f0-9]{64}$/.test(expectedDigest)||fs.realpathSync(root)!==root||!fs.lstatSync(root).isDirectory())fail('ROOT');
  const require=createRequire(path.join(root,'package.json'));
  function verify(){
    const bytes=file(root,'cohort.json');
    if(hash(bytes)!==expectedDigest)fail('COHORT_IDENTITY');
    const d=JSON.parse(bytes);
    const legacy=d.schema==='psc1-modular-installed-cohort/1',partitioned=d.schema==='psc1-modular-installed-cohort/3';
    const names=legacy?['@proofscript/modular-pilot-runtime','@proofscript/modular-pilot-names','@proofscript/modular-pilot-consumer']:d.packageNames;
    if((!legacy&&!partitioned&&d.schema!=='psc1-modular-installed-cohort/2')||!Array.isArray(names)||
      names.length<(partitioned?1:3)||names.length>(legacy?3:9)||new Set(names).size!==names.length||
      names[0]!=='@proofscript/modular-pilot-runtime'||
      names.some(name=>!/^@proofscript\/modular-pilot-[a-z0-9-]{1,114}$/.test(name))||
      d.packages.length!==names.length||d.protocol!==(legacy?'psc1-modular-pilot/1':partitioned?'psc1-modular-pilot/3':'psc1-modular-pilot/2')||
      d.version!==(legacy?'0.1.0-psc1-modular-pilot.0':partitioned?'0.1.0-psc1-modular-pilot.2':'0.1.0-psc1-modular-pilot.1')||d.logicalAdmission!=='accepted'||
      d.checkerCommit!=='eb6cafb7290e8bd5f2937522d8d804f58f02bafc')fail('COHORT_POLICY');
    if(partitioned){
      const p=d.partition,sources=d.sourceModules;
      if(!p||!Array.isArray(sources)||sources.length<2||sources.length>8||
        new Set(sources).size!==sources.length||
        !Array.isArray(p.groups)||p.groups.length!==names.length||
        !Array.isArray(p.sourceToUnit)||p.sourceToUnit.length!==sources.length+1||p.sourceToUnit[0]!==0)
        fail('PARTITION_LAYOUT');
      const coverage=p.groups.flat();
      if(coverage.length!==sources.length+1||new Set(coverage).size!==coverage.length||
        coverage.some(n=>!Number.isSafeInteger(n)||n<0||n>sources.length)||
        p.groups.some((g,i)=>!Array.isArray(g)||g.length===0||g.some(n=>p.sourceToUnit[n]!==i))||
        p.sourceToUnit.some(n=>!Number.isSafeInteger(n)||n<0||n>=names.length))fail('PARTITION_COVERAGE');
    }
    if(inventory(root).join(',')!==['LICENSE','NOTICE','cohort.json','index.d.mts','index.mjs','loader.mjs','package.json'].sort().join(','))
      fail('ROOT_INVENTORY');
    for(const pin of d.bootstrapFiles){const b=file(root,pin.path);if(b.length!==pin.bytes||hash(b)!==pin.sha256)fail('BOOTSTRAP_IDENTITY');}
    const scope=path.dirname(root);let total=bytes.length;
    const selected=[];
    for(const [index,pkg]of d.packages.entries()){
      const name=names[index];
      if(pkg.name!==name||pkg.version!==d.version)fail('PACKAGE_COHORT');
      const target=path.join(scope,name.split('/')[1]);
      if(fs.realpathSync(target)!==target||!fs.lstatSync(target).isDirectory())fail('PACKAGE_ROOT');
      if(require.resolve(name+'/package.json')!==path.join(target,'package.json'))fail('PACKAGE_RESOLUTION');
      if(inventory(target).join(',')!==expectedEntries(pkg.files.map(p=>p.path)).join(','))fail('PACKAGE_INVENTORY');
      for(const pin of pkg.files){
        const b=file(target,pin.path);total+=b.length;if(total>32*1024*1024)fail('AGGREGATE_BOUND');
        if(b.length!==pin.bytes||hash(b)!==pin.sha256)fail('PACKAGE_RESOURCE_IDENTITY');
      }
      const meta=JSON.parse(file(target,'package.json'));
      if(meta.name!==name||meta.version!==d.version||meta.license!=='Apache-2.0')fail('PACKAGE_METADATA');
      for(const targetName of ['dist/js/index.mjs','dist/js/index.d.mts','dist/ts/index.mjs','dist/ts/index.d.mts'])
        if(!pkg.files.some(pin=>pin.path===targetName))fail('PACKAGE_ENTRY');
      selected.push(target);
    }
    return{descriptor:d,roots:selected,names};
  }
  return Object.freeze({
    verify:()=>verify().descriptor,
    async load({variant='js'}={}){
      if(!['js','ts'].includes(variant))fail('VARIANT');
      const checked=verify(),modules=[];
      for(const dir of checked.roots)modules.push(await import(pathToFileURL(path.join(dir,'dist',variant,'index.mjs')).href));
      verify();
      const expected=checked.descriptor.protocol+':'+variant+':'+checked.descriptor.sourceClosureDigest;
      if(modules[0].__ps$cohort!==expected)fail('RUNTIME_COHORT');
      const d=checked.descriptor,partitioned=d.schema==='psc1-modular-installed-cohort/3';
      const consumer=partitioned?modules[d.partition.sourceToUnit[d.sourceModules.length]]:modules.at(-1);
      const nameIndex=partitioned?d.sourceModules.indexOf('Ps.Foundation.Name'):-1;
      const names=partitioned?(nameIndex<0?undefined:modules[d.partition.sourceToUnit[nameIndex+1]]):
        modules[checked.names.indexOf('@proofscript/modular-pilot-names')];
      return Object.freeze({runtime:modules[0],names,consumer,
        modules:Object.freeze(Object.fromEntries(checked.names.map((name,index)=>[name,modules[index]]))),
        sourceClosureDigest:checked.descriptor.sourceClosureDigest,variant});
    }
  });
}
