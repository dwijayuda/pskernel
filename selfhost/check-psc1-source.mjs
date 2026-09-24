import fs from 'node:fs';
import path from 'node:path';

const root=path.resolve('src/ProofScript/Compiler');
const files=[];

function walk(dir){
  for(const entry of fs.readdirSync(dir,{withFileTypes:true})){
    const p=path.join(dir,entry.name);
    if(entry.isDirectory())walk(p);
    else if(entry.isFile()&&entry.name.endsWith('.lean'))files.push(p);
  }
}
walk(root);

const forbidden=[
  [/(^|\n)\s*import\s+Lean(?:\.|\s|$)/,'Lean implementation import'],
  [/(^|\n)\s*import\s+Std(?:\.|\s|$)/,'Std implementation import'],
  [/\bunsafe\b/,'unsafe'],
  [/\bimplemented_by\b/,'implemented_by'],
  [/\bextern\b/,'extern'],
  [/\bmacro_rules\b|\bmacro\b/,'macro'],
  [/(^|\s)syntax(?:\s|$)/,'custom syntax'],
  [/\belab_rules\b|\belab\b/,'custom elaborator'],
  [/\brun_tac\b/,'run_tac'],
  [/\bset_option\b/,'set_option'],
  [/\bopen\s+scoped\b/,'open scoped'],
  [/\bnamespace\b/,'namespace convenience'],
  [/\bsection\b/,'section convenience'],
  [/\babbrev\b/,'abbrev convenience'],
  [/\bopaque\b/,'opaque source convenience'],
  [/\bmutual\b/,'mutual declaration convenience'],
  [/\btermination_by\b|\bdecreasing_by\b/,'explicit termination machinery'],
  [/\bIO(?:\.|\s|\b)/,'IO in portable semantic module'],
  [/\bLean\./,'Lean implementation API'],
  [/\bStd\./,'Std implementation API'],
];

let failed=false;
for(const file of files){
  const text=fs.readFileSync(file,'utf8');
  for(const [re,label] of forbidden){
    if(re.test(text)){
      console.error(`PSC1_SOURCE_PROFILE: ${file}: forbidden ${label}`);
      failed=true;
    }
  }
}
if(failed)process.exit(1);
console.log(`PSC1_SOURCE_PROFILE: PASS (${files.length} portable modules)`);
