import {existsSync} from 'node:fs';
import {mkdir,writeFile} from 'node:fs/promises';
import {basename,join,resolve} from 'node:path';
import {DEFAULT_CONFIG} from '../config.js';

export async function initCommand(args:readonly string[]){
  let target='.';
  let lib=false;
  for(const arg of args){
    if(arg==='--lib')lib=true;
    else if(arg==='-y'||arg==='--yes')continue;
    else if(arg.startsWith('-'))throw new Error("PS_CLI_UNKNOWN_OPTION: unknown option '"+arg+"'");
    else if(target==='.')target=arg;
    else throw new Error("PS_CLI_USAGE: unexpected argument '"+arg+"'");
  }

  const dir=resolve(target);
  await mkdir(join(dir,'src'),{recursive:true});
  const configPath=join(dir,'psconfig.json');
  if(existsSync(configPath))throw new Error('PS_INIT_EXISTS: psconfig.json already exists in '+dir);

  const entry=lib?'src/index.ps':'src/main.ps';
  const source=lib
    ? 'const answer : Nat := 42;\nfunction add(x : Nat, y : Nat) : Nat := x + y;\n'
    : 'const answer : Nat := 42;\nfunction main(x : Nat) : Nat := let y : Nat := x + answer; y;\n';
  const packageJson={
    name:basename(dir),
    private:true,
    type:'module',
    scripts:lib
      ? {check:'psc check',build:'psc build'}
      : {check:'psc check',build:'psc build',start:'psc run -- 1'},
  };

  await Promise.all([
    writeFile(configPath,JSON.stringify({...DEFAULT_CONFIG,entry},null,2)+'\n','utf8'),
    writeFile(join(dir,entry),source,'utf8'),
    writeFile(join(dir,'package.json'),JSON.stringify(packageJson,null,2)+'\n','utf8'),
    writeFile(join(dir,'.gitignore'),'dist/\n.proofscript/\nnode_modules/\n','utf8'),
  ]);

  return {ok:true,command:'init',directory:dir,entry,kind:lib?'library':'application'};
}
