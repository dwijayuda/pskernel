export function outputResult(result:unknown,json:boolean):void{
  if(json){
    console.log(JSON.stringify(result,null,2));
    return;
  }
  if(typeof result!=='object'||result===null)return;

  const value=result as Record<string,unknown>;
  if(value.command==='check')console.log('✓ ProofScript check passed ('+String(value.declarations)+' declarations)');
  else if(value.command==='build')console.log('✓ Built '+String(value.source)+' → '+String(value.outputDirectory));
  else if(value.command==='init')console.log('✓ Initialized ProofScript '+String(value.kind)+' in '+String(value.directory));
  else if(value.command==='clean')console.log('✓ Removed '+String(value.removed));
}
