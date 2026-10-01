import {readFileSync} from 'node:fs';
import {Lean4ExportReplay} from '../dist/src/integration/lean4export.js';
const file=process.argv[2];
if(!file){console.error('usage: npm run replay -- <lean4export.ndjson>');process.exit(2);}
try{
  const replay=new Lean4ExportReplay();
  const stats=replay.replay(readFileSync(file,'utf8'));
  console.log(JSON.stringify({ok:true,file,stats,constants:replay.env.entries().length},null,2));
}catch(e){
  console.error(JSON.stringify({ok:false,file,error:e instanceof Error?(e.stack??e.message):String(e)},null,2));
  process.exit(1);
}
