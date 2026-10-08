import './verify-build.mjs';
// Ground tests of the new checking machines in the reference kernel, in addition
// to executing their PSC-generated JavaScript. Not a general correctness proof.
import fs from 'node:fs';import path from 'node:path';import {fileURLToPath} from 'node:url';
import {root,json,sha256} from './source.mjs';
import {createGroundOracle,C,app,ctor,list,expr,definitions} from './ground-oracle.mjs';
import {B,U,Pi,Lam,App,Let,def,identity,identityType} from '../test/checker-values.mjs';
const oracle=createGroundOracle('PsKernelCheckerGround');
const {theorem,fuel}=oracle;
const cases=json(path.join(root,'test/checker-cases.json'));
const positives=[],negatives=[];
const empty=definitions([]);
const resultError=(t,e)=>ctor(t,'rejected',C('PsKernelCheckError.'+e));
const checked=(v,t,env=empty,budget=1024)=>app(C('psKernelTypeRun'),fuel(budget),app(C('psKernelCheckStart'),env,expr(v),expr(t)));
for(const c of cases){
 const expected=c.expected==='done'?ctor('TypeResult','done',expr(c.type)):resultError('TypeResult',c.error);
 positives.push({label:c.name,decl:theorem('TypeResult',expected,checked(c.value,c.type,definitions([...c.prior].reverse())))});
}
function admit(ds,budget=1024){return app(C('psKernelAdmissionRun'),fuel(budget),app(C('psKernelAdmissionStart'),definitions(ds)));}
const id=def('id',identityType(1),identity(1));
const use=def('use',identityType(1),['const',['str',['anonymous'],'id'],[]]);
const bad=def('bad',U(1),U(1));
for(const [label,ds,error] of [
 ['empty-batch',[],null],['identity-admission',[id],null],['sequential-admission',[id,use],null],
 ['duplicate-admission',[id,id],'duplicateName'],['forward-reference',[use,id],'unknownConstant'],
 ['bad-second-definition',[id,bad],'typeMismatch'],['bad-type-in-type',[bad],'typeMismatch']
])positives.push({label,decl:theorem('AdmissionResult',error?resultError('AdmissionResult',error):ctor('AdmissionResult','admitted',definitions([...ds].reverse())),admit(ds))});
const beta=App(Lam('A',U(1),Lam('x',B(0),B(0))),U(0));
const nf=Lam('x',U(0),B(0));
const red=(v,budget=1024)=>app(C('psKernelReduceRun'),fuel(budget),app(C('psKernelNormalStart'),empty,expr(v)));
positives.push({label:'beta-normal-form',decl:theorem('ReduceResult',ctor('ReduceResult','done',expr(nf)),red(beta))});
positives.push({label:'zeta-normal-form',decl:theorem('ReduceResult',ctor('ReduceResult','done',expr(nf)),red(Let('x',Pi('x',U(0),U(0)),beta,B(0))))});
const conv=(a,b,budget=1024)=>app(C('psKernelConversionRun'),fuel(budget),app(C('psKernelConversionStart'),empty,expr(a),expr(b)));
positives.push({label:'beta-conversion',decl:theorem('ConversionResult',C('PsKernelConversionResult.equal'),conv(beta,nf))});
positives.push({label:'unequal-sorts',decl:theorem('ConversionResult',C('PsKernelConversionResult.different'),conv(U(0),U(1)))});
positives.push({label:'type-shared-budget-zero',decl:theorem('TypeResult',C('PsKernelTypeResult.outOfFuel'),checked(U(0),U(1),empty,0))});
positives.push({label:'admission-shared-budget-zero',decl:theorem('AdmissionResult',C('PsKernelAdmissionResult.outOfFuel'),admit([],0))});
positives.push({label:'conversion-shared-budget-zero',decl:theorem('ConversionResult',C('PsKernelConversionResult.outOfFuel'),conv(U(0),U(0),0))});
negatives.push({label:'false-claim-Type-in-Type-accepted',decl:theorem('TypeResult',ctor('TypeResult','done',expr(U(1))),checked(U(1),U(1)))});
negatives.push({label:'false-claim-illtyped-definition-admitted',decl:theorem('AdmissionResult',ctor('AdmissionResult','admitted',definitions([bad])),admit([bad]))});
negatives.push({label:'false-claim-nonconvertible-sorts-equal',decl:theorem('ConversionResult',C('PsKernelConversionResult.equal'),conv(U(0),U(1)))});
const positive=oracle.check(positives.map(x=>x.decl));
if(positive.result.accepted!==true)throw Error('CHECKER_GROUND_POSITIVE:'+JSON.stringify(positive.result)+' case='+positives[positive.result.declarationIndex-oracle.baseCount-oracle.helperCount()]?.label);
const negativeControls=negatives.map(({label,decl})=>{const r=oracle.check([decl]);if(r.result.accepted!==false||r.result.errorKind!=='kernel-rejection'||r.result.declarationIndex!==oracle.baseCount+oracle.helperCount())throw Error('CHECKER_GROUND_CONTROL:'+label+JSON.stringify(r));return{label,...r};});
const record={schemaVersion:1,scope:'Bounded source-computation theorems over the owned checker; reference provider is external and not a runtime authority of this package; not a general soundness proof',provider:oracle.identity,providerSha256:oracle.pin.leanProviderSha256,sourceManifestSha256:sha256(fs.readFileSync(path.join(root,'manifests/SOURCE.json'))),fixtureSha256:sha256(fs.readFileSync(path.join(root,'test/checker-cases.json'))),harnessSha256:sha256(fs.readFileSync(fileURLToPath(import.meta.url))),sharedHarnessSha256:sha256(fs.readFileSync(path.join(root,'scripts/ground-oracle.mjs'))),sourceAdmissionCount:oracle.baseCount,positiveCases:positives.length,positiveLabels:positives.map(x=>x.label),positive,negativeControls};
fs.writeFileSync(path.join(root,'manifests/CHECKER_ORACLE.json'),JSON.stringify(record,null,2)+'\n');console.log(JSON.stringify(record,null,2));
