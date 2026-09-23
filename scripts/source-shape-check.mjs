import {readdirSync,readFileSync,statSync} from 'node:fs';
import {join,relative} from 'node:path';
import {fileURLToPath} from 'node:url';

const root=fileURLToPath(new URL('..',import.meta.url));
const scopes=['syntax','meta','environment','checked-core','elab','language','language-service','erasure','compiler-ir','backend-ts','compiler','lsp','cli'];
const maxLines=300;
const maxLineLength=320;
const violations=[];

function walk(dir){
  for(const entry of readdirSync(dir)){
    const full=join(dir,entry);
    const stat=statSync(full);
    if(stat.isDirectory()){
      if(entry==='dist'||entry==='node_modules')continue;
      walk(full);
      continue;
    }
    if(!full.endsWith('.ts'))continue;
    const lines=readFileSync(full,'utf8').split(/\r?\n/u);
    if(lines.length>maxLines){
      violations.push(relative(root,full)+': '+lines.length+' lines > '+maxLines);
    }
    const longest=Math.max(0,...lines.map((line)=>line.length));
    if(longest>maxLineLength){
      violations.push(relative(root,full)+': max line '+longest+' > '+maxLineLength);
    }
  }
}

for(const scope of scopes)walk(join(root,'packages',scope,'src'));

if(violations.length>0){
  throw new Error('source-shape gate failed:\n'+violations.map((v)=>'  - '+v).join('\n'));
}
console.log('source-shape: PASS ('+scopes.join(', ')+')');
