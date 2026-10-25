import {performance} from 'node:perf_hooks';

// Diagnostic-only entry, inserted into an authenticated copy of the transport.
// No result from this module is a checked declaration or admission receipt.
export function runChurchStages(kernel, input) {
  const {arena,commands,session,nil,safety,list,array,request}=input;
  const get=name=>{if(!(name in kernel))throw Error('Missing production export '+name);return kernel[name];};
  const emit=(marker,value)=>console.log(marker+' '+JSON.stringify(value,(_k,v)=>typeof v==='bigint'?v.toString():v));
  const ok=result=>{
    if(result&&typeof result==='object'&&'value' in result)return result.value;
    throw Error('Required independent prefix/setup failed: '+JSON.stringify(result,(_k,v)=>typeof v==='bigint'?v.toString():v));
  };
  if(commands.length!==4||arena.size!==197n||session.resources.fuel!==4096n||
      session.resources.maxRecDepth!==0n||session.resources.maxNatSize!==134217728n||
      session.resources.maxDeclarations!==0n||session.resources.cancelled!==false)
    throw Error('Authentic input or published policy changed');
  const start=performance.now();
  const canonical=ok(get('psKernelExprV2PagedValidate')(arena));
  const prefix=ok(get('psKernelV1RunDag')(session,nil,safety,canonical,list(commands.slice(0,3))));
  if(array(prefix.replies).length!==3)throw Error('Prefix did not independently admit all three requests');
  const decoded=ok(get('psKernelExprV2DecodeChecked')(canonical));
  const installed=ok(get('psKernelDagGeneratedFromSession')(prefix.session,canonical,decoded));
  emit('PSC1_CHURCH_PREFIX',{requests:3,sourceNodes:arena.size,ownedNodes:installed.arena.size,
    declarations:get('psKernelEnvironmentSize')(prefix.session.environment)});
  const declaration=ok(get('psKernelDagDecodeDeclaration')(installed.built,request));
  const plan=ok(get('psKernelDagSimpleAdmissionPlan')(request,declaration));
  if(!plan.body||!('value' in plan.body))throw Error('Real theorem body required');
  const checker=get('psKernelMkCheckerSession')(get('psKernelKernelSessionEnvironment')(prefix.session),
    plan.base.levelParams,plan.safety,prefix.session.resources.maxRecDepth,prefix.session.resources.maxNatSize);
  const context=get('psKernelExprV2CheckContextEmpty')(checker.context);
  const initial=get('psKernelExprV2CheckStateWithWhnf')(get('psKernelExprV2CheckStateEmpty')(installed.arena),
    get('psKernelExprV2WhnfStateForDeclarations')(installed.arena,installed.declarations));
  const fuel=prefix.session.resources.fuel;
  function step(stage,action){
    console.error('PSC1_CHURCH_STAGE_BEGIN '+stage);
    const start=performance.now(),option=action();
    if(!option||!('value' in option))throw Error('PROBE_DIRECT_DECLINED '+stage);
    const result=option.value;
    if('error' in result){
      emit('PSC1_CHURCH_STAGE',{stage,status:'error',milliseconds:performance.now()-start,reason:result.error});
      throw {churchFailure:true,message:result.error};
    }
    if(!('value' in result))throw Error('Invalid production Except');
    emit('PSC1_CHURCH_STAGE',{stage,status:'ok',milliseconds:performance.now()-start});
    return result.value;
  }
  let verdict='accepted',reason='';
  try{
    const afterHeader=step('header',()=>get('psKernelExprV2AdmissionCheckHeaderWithFuel')(fuel,context,initial,plan.base,plan.typeRoot));
    const prepared=step('is-prop',()=>get('psKernelExprV2AdmissionPrepareBodyWithFuel')(fuel,context,afterHeader,plan));
    const body=plan.body.value;
    step('body-static',()=>get('Option').some(get('psKernelExprV2AdmissionStaticOnCanonical')(
      prepared.whnf.arena,body.snd,plan.base.levelParams)));
    const checked=step('body-check',()=>get('psKernelExprV2TryCheckStateWithFuel')(fuel,context,prepared,body.snd));
    const compared=step('final-defeq',()=>get('psKernelExprV2TryDefEqStateWithFuel')(
      fuel)(context)(checked.fst)(checked.snd)(plan.typeRoot));
    if(compared.snd!==true)throw {churchFailure:true,message:plan.mismatch};
  }catch(error){
    if(!error?.churchFailure)throw error;
    reason=error.message;
    const outcome=get('psKernelErrorOutcome')(get('psKernelErrorFromMessage')(reason));
    const variants=get('PsKernelOutcome');
    const key=Reflect.ownKeys(outcome).find(key=>typeof key==='symbol');
    verdict=[['rejectedInvalid','rejected'],['declinedUnsupported','unsupported'],
      ['resourceExhausted','resource_exhausted'],['internalError','internal_error']]
      .find(([name])=>outcome[key]===variants[name][key])?.[1];
    if(!verdict)throw Error('Invalid typed outcome');
  }
  const result={schema:'psc1-church-stages-v1',runtime:'generated',mode:'stages',verdict,reason,
    milliseconds:performance.now()-start,fuel:'4096',sourceNodes:'197'};
  emit('PSC1_CHURCH_RESULT',result);return result;
}
