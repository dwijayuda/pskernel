import { ConstantInfo, DefinitionInfo, ReducibilityHints } from '../core/declaration.js';
import { Environment, KernelError } from '../core/environment.js';
import { BinderInfo, Expr, app, bvar, constant, exprEq, exprKernelMetadataDiff, exprKernelMetadataEq, exprToString, forallE, lam, natLit, sort, strLit } from '../core/expr.js';
import { Level, levelParam, levelSucc, levelZero, mkIMax, mkMax } from '../core/level.js';
import { Name, anonymous, nameEq, nameKey, nameToString, numName, strName } from '../core/name.js';
import { Kernel } from '../kernel/kernel.js';
import { addInductive } from '../kernel/inductive/nested.js';
import { ConstructorDecl, InductiveDecl, addOrdinaryInductive } from '../kernel/inductive/ordinary.js';
import { isPrimitiveName } from '../kernel/primitive-names.js';
import { addPrimitiveDefinition, addPrimitiveInductive } from '../kernel/primitive.js';
import { addQuot } from '../kernel/quotient.js';
import { TypeChecker } from '../kernel/type-checker.js';
import { ExactJson, JObject, asArray, asBigInt, asBoolean, asIndex, asObject, asString, field, maybeField, parseExactJson } from './exact-json.js';

export interface Lean4ExportOptions {
  /** Strict by default: an oracle-facing replay must be produced by the pinned Lean release. */
  readonly expectedLeanVersion?: string;
  readonly supportedFormatVersions?: readonly string[];
}
export interface ReplayStats { readonly lines:number; readonly names:number; readonly levels:number; readonly expressions:number; readonly declarations:number }
export interface ReplayProgressOptions { readonly every?:number; readonly onProgress?:(stats:ReplayStats)=>void }

function asUInt(v:ExactJson,where:string,max=BigInt(Number.MAX_SAFE_INTEGER)):number{const n=asBigInt(v,where);if(n<0n||n>max)throw new KernelError(`${where} is outside supported unsigned range`);return Number(n);}
function arrIndex(a:readonly ExactJson[],where:string):number[]{return a.map((x,i)=>asIndex(x,`${where}[${i}]`));}
function boolField(o:JObject,k:string,where:string):boolean{return asBoolean(field(o,k,where),`${where}.${k}`);}
function namesEq(a:readonly Name[],b:readonly Name[]):boolean{return a.length===b.length&&a.every((x,i)=>nameEq(x,b[i]!));}
class DenseIndexTable<T>{
  private readonly values:T[];
  private readonly sparse=new Map<number,T>();
  private count:number;
  constructor(seed:readonly T[]=[]){this.values=[...seed];this.count=seed.length;}
  get size():number{return this.count;}
  get(i:number,what:string):T{
    if(i<this.values.length)return this.values[i]!;
    const x=this.sparse.get(i);if(x===undefined)throw new KernelError(`lean4export ${what} reference ${i} is undefined`);return x;
  }
  add(i:number,v:T,what:string):void{
    if(i<this.values.length||this.sparse.has(i))throw new KernelError(`lean4export ${what} index ${i} is already defined`);
    this.count++;
    if(i!==this.values.length){this.sparse.set(i,v);return;}
    this.values.push(v);
    while(this.sparse.has(this.values.length)){
      const j=this.values.length,next=this.sparse.get(j)!;this.sparse.delete(j);this.values.push(next);
    }
  }
}
function sameBool(a:boolean|undefined,b:boolean):boolean{return (a??false)===b;}

export class Lean4ExportReplay {
  readonly env:Environment;
  readonly kernel:Kernel;
  private readonly names=new DenseIndexTable<Name>([anonymous]);
  private readonly levels=new DenseIndexTable<Level>([levelZero]);
  private readonly exprs=new DenseIndexTable<Expr>();
  private sawMeta=false; private lineNo=0; private decls=0;
  private readonly pendingMutual=new Map<string,{all:readonly Name[]; defs:Map<string,DefinitionInfo>}>();
  private readonly expectedLeanVersion:string; private readonly formats:readonly string[];

  constructor(env=new Environment(),options:Lean4ExportOptions={}){
    this.env=env;this.kernel=new Kernel(env);this.expectedLeanVersion=options.expectedLeanVersion??'4.34.0';this.formats=options.supportedFormatVersions??['3.1.0'];
  }

  private stats():ReplayStats{return {lines:this.lineNo,names:this.names.size-1,levels:this.levels.size-1,expressions:this.exprs.size,declarations:this.decls};}

  /** Feed one physical NDJSON line. This keeps large-corpus replay streaming-friendly. */
  replayLine(raw:string):ReplayStats{
    if(raw.trim()==='')return this.stats();
    this.lineNo++;
    try{this.process(parseExactJson(raw));}
    catch(e){const msg=e instanceof Error?e.message:String(e);throw new KernelError(`lean4export line ${this.lineNo}: ${msg}`);}
    return this.stats();
  }

  /** Validate end-of-stream invariants after incremental replay. */
  finish():ReplayStats{
    if(!this.sawMeta)throw new KernelError('lean4export stream is missing initial metadata');
    if(this.pendingMutual.size!==0){const g=[...this.pendingMutual.values()][0]!;const missing=g.all.filter(n=>!g.defs.has(nameKey(n))).map(nameToString);throw new KernelError(`incomplete exported mutual definition group; missing ${missing.join(', ')}`);}
    return this.stats();
  }

  replay(text:string,progress:ReplayProgressOptions={}):ReplayStats{
    const every=Math.max(1,progress.every??Number.MAX_SAFE_INTEGER);
    let start=0;
    while(start<=text.length){
      const end=text.indexOf('\n',start);
      const raw=end<0?text.slice(start):text.slice(start,end);
      const before=this.lineNo;
      const stats=this.replayLine(raw);
      if(progress.onProgress&&this.lineNo!==before&&this.lineNo%every===0)progress.onProgress(stats);
      if(end<0)break;
      start=end+1;
    }
    return this.finish();
  }

  private process(v:ExactJson):void{
    const o=asObject(v,`line ${this.lineNo}`);
    if('meta' in o){this.meta(asObject(o.meta!,`line ${this.lineNo}.meta`));return;}
    if(!this.sawMeta)throw new KernelError('lean4export metadata must be the first record');
    if('in' in o){this.nameRecord(o);return;}if('il' in o){this.levelRecord(o);return;}if('ie' in o){this.exprRecord(o);return;}
    this.declarationRecord(o);this.decls++;
  }

  private meta(m:JObject):void{
    if(this.sawMeta||this.lineNo!==1)throw new KernelError('duplicate or non-initial lean4export metadata');
    const lean=asObject(field(m,'lean','meta'),'meta.lean'),format=asObject(field(m,'format','meta'),'meta.format');
    const lv=asString(field(lean,'version','meta.lean'),'meta.lean.version'),fv=asString(field(format,'version','meta.format'),'meta.format.version');
    if(lv!==this.expectedLeanVersion)throw new KernelError(`lean4export Lean version ${lv} does not match pinned ${this.expectedLeanVersion}`);
    if(!this.formats.includes(fv))throw new KernelError(`unsupported lean4export format ${fv}; expected ${this.formats.join(' or ')}`);
    this.sawMeta=true;
  }
  private n(i:number):Name{return this.names.get(i,'Name');} private l(i:number):Level{return this.levels.get(i,'Level');} private e(i:number):Expr{return this.exprs.get(i,'Expr');}
  private ns(v:ExactJson,where:string):Name[]{return arrIndex(asArray(v,where),where).map(i=>this.n(i));}
  private ls(v:ExactJson,where:string):Level[]{return arrIndex(asArray(v,where),where).map(i=>this.l(i));}

  private nameRecord(o:JObject):void{
    const i=asIndex(field(o,'in','Name'),'Name.in');let n:Name;
    if('str' in o){const s=asObject(o.str!,'Name.str');n=strName(this.n(asIndex(field(s,'pre','Name.str'),'Name.str.pre')),asString(field(s,'str','Name.str'),'Name.str.str'));}
    else if('num' in o){const x=asObject(o.num!,'Name.num');n=numName(this.n(asIndex(field(x,'pre','Name.num'),'Name.num.pre')),asBigInt(field(x,'i','Name.num'),'Name.num.i'));}
    else throw new KernelError('invalid lean4export Name record');this.names.add(i,n,'Name');
  }
  private levelRecord(o:JObject):void{
    const i=asIndex(field(o,'il','Level'),'Level.il');let l:Level;
    if('succ' in o)l=levelSucc(this.l(asIndex(o.succ!,'Level.succ')));
    else if('max' in o){const a=arrIndex(asArray(o.max!,'Level.max'),'Level.max');if(a.length!==2)throw new KernelError('Level.max requires two operands');l=mkMax(this.l(a[0]!),this.l(a[1]!));}
    else if('imax' in o){const a=arrIndex(asArray(o.imax!,'Level.imax'),'Level.imax');if(a.length!==2)throw new KernelError('Level.imax requires two operands');l=mkIMax(this.l(a[0]!),this.l(a[1]!));}
    else if('param' in o)l=levelParam(this.n(asIndex(o.param!,'Level.param')));
    else throw new KernelError('invalid lean4export Level record');this.levels.add(i,l,'Level');
  }
  private exprRecord(o:JObject):void{
    const i=asIndex(field(o,'ie','Expr'),'Expr.ie');let e:Expr;
    if('bvar' in o)e=bvar(asUInt(o.bvar!,'Expr.bvar'));
    else if('sort' in o)e=sort(this.l(asIndex(o.sort!,'Expr.sort')));
    else if('const' in o){const c=asObject(o.const!,'Expr.const');e=constant(this.n(asIndex(field(c,'name','Expr.const'),'Expr.const.name')),this.ls(field(c,'us','Expr.const'),'Expr.const.us'));}
    else if('app' in o){const a=asObject(o.app!,'Expr.app');e=app(this.e(asIndex(field(a,'fn','Expr.app'),'Expr.app.fn')),this.e(asIndex(field(a,'arg','Expr.app'),'Expr.app.arg')));}
    else if('lam' in o||'forallE' in o){const key='lam' in o?'lam':'forallE',a=asObject(o[key]!,`Expr.${key}`),bi=asString(field(a,'binderInfo',`Expr.${key}`),`Expr.${key}.binderInfo`) as BinderInfo;if(!['default','implicit','strictImplicit','instImplicit'].includes(bi))throw new KernelError(`invalid binder info ${bi}`);const name=this.n(asIndex(field(a,'name',`Expr.${key}`),`Expr.${key}.name`)),type=this.e(asIndex(field(a,'type',`Expr.${key}`),`Expr.${key}.type`)),body=this.e(asIndex(field(a,'body',`Expr.${key}`),`Expr.${key}.body`));e=key==='lam'?lam(name,type,body,bi):forallE(name,type,body,bi);}
    else if('letE' in o){const a=asObject(o.letE!,'Expr.letE');e={kind:'let',name:this.n(asIndex(field(a,'name','Expr.letE'),'Expr.letE.name')),type:this.e(asIndex(field(a,'type','Expr.letE'),'Expr.letE.type')),value:this.e(asIndex(field(a,'value','Expr.letE'),'Expr.letE.value')),body:this.e(asIndex(field(a,'body','Expr.letE'),'Expr.letE.body'))};}
    else if('proj' in o){const a=asObject(o.proj!,'Expr.proj');e={kind:'proj',typeName:this.n(asIndex(field(a,'typeName','Expr.proj'),'Expr.proj.typeName')),index:asUInt(field(a,'idx','Expr.proj'),'Expr.proj.idx'),expr:this.e(asIndex(field(a,'struct','Expr.proj'),'Expr.proj.struct'))};}
    else if('natVal' in o)e=natLit(BigInt(asString(o.natVal!,'Expr.natVal')));
    else if('strVal' in o)e=strLit(asString(o.strVal!,'Expr.strVal'));
    else if('mdata' in o){const a=asObject(o.mdata!,'Expr.mdata'),data=asObject(field(a,'data','Expr.mdata'),'Expr.mdata.data');e={kind:'mdata',data,expr:this.e(asIndex(field(a,'expr','Expr.mdata'),'Expr.mdata.expr'))};}
    else throw new KernelError('invalid lean4export Expr record');this.exprs.add(i,e,'Expr');
  }

  private hints(v:ExactJson):ReducibilityHints{
    if(typeof v==='string'){if(v==='opaque'||v==='abbrev')return {kind:v};throw new KernelError(`invalid reducibility hint ${v}`);}
    const o=asObject(v,'def.hints'),h=asBigInt(field(o,'regular','def.hints'),'def.hints.regular');if(h<0n||h>0xffffffffn)throw new KernelError('definition height is outside UInt32');return {kind:'regular',height:h};
  }
  private addExportedDefinition(info:DefinitionInfo,all:readonly Name[]):void{
    // DefinitionVal.all is informational for ordinary defnDecl, including safe definitions.
    // Lean 4.34 Kernel.Environment.replay ignores it and replays the declaration from actual
    // used constants. Only unsafe/partial mutualDefnDecl reconstruction needs a coherent group.
    if(info.safety==='safe'||all.length<=1){
      // A single unsafe definition has Lean's ordinary recursive-definition admission path.
      // A singleton partial that is actually self-recursive is handled by the mutual path below.
      const selfRef=info.safety==='partial'&&this.exprUsesName(info.value,info.name);
      if(!selfRef){if(isPrimitiveName(info.name))addPrimitiveDefinition(this.env,info);else this.kernel.addDefinition(info);return;}
    }
    if(!all.some(n=>nameEq(n,info.name)))throw new KernelError(`exported mutual definition '${nameToString(info.name)}' is missing from its all-list`);
    if(isPrimitiveName(info.name))throw new KernelError(`primitive '${nameToString(info.name)}' cannot be a mutual definition member`);
    const key=all.map(nameKey).join('|');let g=this.pendingMutual.get(key);
    if(!g){g={all:[...all],defs:new Map()};this.pendingMutual.set(key,g);}else if(!namesEq(g.all,all))throw new KernelError('inconsistent exported mutual definition all-list');
    const nk=nameKey(info.name);if(g.defs.has(nk))throw new KernelError(`duplicate exported mutual definition '${nameToString(info.name)}'`);g.defs.set(nk,info);
    if(g.defs.size===g.all.length){const defs=g.all.map(n=>g!.defs.get(nameKey(n))).filter((x):x is DefinitionInfo=>x!==undefined);if(defs.length!==g.all.length)throw new KernelError('exported mutual definition group is inconsistent');this.kernel.addMutualDefinitions(defs);this.pendingMutual.delete(key);}
  }
  private exprUsesName(e:Expr,n:Name):boolean{
    switch(e.kind){case'const':return nameEq(e.name,n);case'app':return this.exprUsesName(e.fn,n)||this.exprUsesName(e.arg,n);case'lam':case'forall':return this.exprUsesName(e.type,n)||this.exprUsesName(e.body,n);case'let':return this.exprUsesName(e.type,n)||this.exprUsesName(e.value,n)||this.exprUsesName(e.body,n);case'mdata':return this.exprUsesName(e.expr,n);case'proj':return this.exprUsesName(e.expr,n);default:return false;}
  }
  private declarationRecord(o:JObject):void{
    if('axiom' in o){const a=asObject(o.axiom!,'axiom');this.kernel.addAxiom({kind:'axiom',name:this.n(asIndex(field(a,'name','axiom'),'axiom.name')),levelParams:this.ns(field(a,'levelParams','axiom'),'axiom.levelParams'),type:this.e(asIndex(field(a,'type','axiom'),'axiom.type')),isUnsafe:boolField(a,'isUnsafe','axiom')});return;}
    if('def' in o){const a=asObject(o.def!,'def'),s=asString(field(a,'safety','def'),'def.safety');if(s!=='safe'&&s!=='unsafe'&&s!=='partial')throw new KernelError(`invalid definition safety ${s}`);const info:DefinitionInfo={kind:'definition',name:this.n(asIndex(field(a,'name','def'),'def.name')),levelParams:this.ns(field(a,'levelParams','def'),'def.levelParams'),type:this.e(asIndex(field(a,'type','def'),'def.type')),value:this.e(asIndex(field(a,'value','def'),'def.value')),hints:this.hints(field(a,'hints','def')),safety:s};const all=maybeField(a,'all')===undefined?[info.name]:this.ns(field(a,'all','def'),'def.all');this.addExportedDefinition(info,all);return;}
    if('thm' in o){const a=asObject(o.thm!,'thm');this.kernel.addTheorem({kind:'theorem',name:this.n(asIndex(field(a,'name','thm'),'thm.name')),levelParams:this.ns(field(a,'levelParams','thm'),'thm.levelParams'),type:this.e(asIndex(field(a,'type','thm'),'thm.type')),value:this.e(asIndex(field(a,'value','thm'),'thm.value'))});return;}
    if('opaque' in o){const a=asObject(o.opaque!,'opaque');this.kernel.addOpaque({kind:'opaque',name:this.n(asIndex(field(a,'name','opaque'),'opaque.name')),levelParams:this.ns(field(a,'levelParams','opaque'),'opaque.levelParams'),type:this.e(asIndex(field(a,'type','opaque'),'opaque.type')),value:this.e(asIndex(field(a,'value','opaque'),'opaque.value')),isUnsafe:boolField(a,'isUnsafe','opaque')});return;}
    if('quot' in o){this.quot(asObject(o.quot!,'quot'));return;}
    if('inductive' in o){this.inductive(asObject(o.inductive!,'inductive'));return;}
    throw new KernelError(`unknown lean4export declaration record at line ${this.lineNo}`);
  }

  private quot(q:JObject):void{
    const name=this.n(asIndex(field(q,'name','quot'),'quot.name')),kind=asString(field(q,'kind','quot'),'quot.kind');if(!['type','ctor','lift','ind'].includes(kind))throw new KernelError(`invalid Quot kind ${kind}`);
    if(!this.env.quotInitialized)addQuot(this.env);const got=this.env.get(name);const expectedType=this.e(asIndex(field(q,'type','quot'),'quot.type'));const expectedLevels=this.ns(field(q,'levelParams','quot'),'quot.levelParams');if(got.kind!=='quot'||got.quotKind!==kind||!namesEq(got.levelParams,expectedLevels)||!exprEq(got.type,expectedType))throw new KernelError(`exported Quot metadata mismatch for '${nameToString(name)}'\nTS: ${got.kind==='quot'?exprToString(got.type):'<not quot>'}\nLean: ${exprToString(expectedType)}`);
  }

  private inductive(g:JObject):void{
    const tvs=asArray(field(g,'types','inductive'),'inductive.types').map((x,i)=>asObject(x,`inductive.types[${i}]`));
    const cvs=asArray(field(g,'ctors','inductive'),'inductive.ctors').map((x,i)=>asObject(x,`inductive.ctors[${i}]`));
    const rvs=asArray(field(g,'recs','inductive'),'inductive.recs').map((x,i)=>asObject(x,`inductive.recs[${i}]`));if(tvs.length===0)throw new KernelError('empty inductive group');
    const first=tvs[0]!,lparams=this.ns(field(first,'levelParams','inductive type'),'inductive.type.levelParams'),nparams=asUInt(field(first,'numParams','inductive type'),'inductive.type.numParams'),unsafe=boolField(first,'isUnsafe','inductive type');
    const ctorByName=new Map<string,JObject>();for(const c of cvs)ctorByName.set(nameKey(this.n(asIndex(field(c,'name','constructor'),'constructor.name'))),c);
    const types=tvs.map((t,ti)=>{const lp=this.ns(field(t,'levelParams',`inductive.types[${ti}]`),`inductive.types[${ti}].levelParams`);if(!namesEq(lp,lparams)||asUInt(field(t,'numParams',`inductive.types[${ti}]`),'numParams')!==nparams||boolField(t,'isUnsafe',`inductive.types[${ti}]`)!==unsafe)throw new KernelError('inconsistent shared inductive group metadata');const ctors:ConstructorDecl[]=this.ns(field(t,'ctors',`inductive.types[${ti}]`),`inductive.types[${ti}].ctors`).map(n=>{const c=ctorByName.get(nameKey(n));if(!c)throw new KernelError(`missing exported constructor '${nameToString(n)}'`);return {name:n,type:this.e(asIndex(field(c,'type','constructor'),'constructor.type'))};});return {name:this.n(asIndex(field(t,'name',`inductive.types[${ti}]`),'inductive.type.name')),type:this.e(asIndex(field(t,'type',`inductive.types[${ti}]`),'inductive.type.type')),ctors};});
    const maxNested=Math.max(...tvs.map(t=>asUInt(field(t,'numNested','inductive type'),'inductive.type.numNested')));const d:InductiveDecl={levelParams:lparams,numParams:nparams,types,isUnsafe:unsafe,numNested:maxNested};
    if(types.length===1&&(nameEq(types[0]!.name,{kind:'str',prefix:anonymous,value:'Nat'})||nameEq(types[0]!.name,{kind:'str',prefix:anonymous,value:'Bool'})))addPrimitiveInductive(this.env,d);else if(maxNested>0)addInductive(this.env,d);else addOrdinaryInductive(this.env,d);
    this.compareInductiveMetadata(tvs,cvs,rvs);
  }

  private compareInductiveMetadata(tvs:readonly JObject[],cvs:readonly JObject[],rvs:readonly JObject[]):void{
    for(const t of tvs){const n=this.n(asIndex(field(t,'name','inductive type'),'inductive.type.name')),g=this.env.get(n);if(g.kind!=='inductive')throw new KernelError(`generated '${nameToString(n)}' is not inductive`);const expAll=this.ns(field(t,'all','inductive type'),'inductive.type.all'),expCtors=this.ns(field(t,'ctors','inductive type'),'inductive.type.ctors');if(!exprEq(g.type,this.e(asIndex(field(t,'type','inductive type'),'inductive.type.type')))||g.numParams!==asUInt(field(t,'numParams','inductive type'),'numParams')||g.numIndices!==asUInt(field(t,'numIndices','inductive type'),'numIndices')||!namesEq(g.all,expAll)||!namesEq(g.ctors,expCtors)||g.numNested!==asUInt(field(t,'numNested','inductive type'),'numNested')||g.isRec!==boolField(t,'isRec','inductive type')||g.isReflexive!==boolField(t,'isReflexive','inductive type')||!sameBool(g.isUnsafe,boolField(t,'isUnsafe','inductive type')))throw new KernelError(`generated inductive metadata mismatch for '${nameToString(n)}'`);}
    for(const c of cvs){
      const n=this.n(asIndex(field(c,'name','constructor'),'constructor.name')),g=this.env.get(n);
      if(g.kind!=='constructor')throw new KernelError(`generated '${nameToString(n)}' is not a constructor`);
      const expectedType=this.e(asIndex(field(c,'type','constructor'),'constructor.type'));
      if(!exprEq(g.type,expectedType))throw new KernelError(`generated constructor type mismatch for '${nameToString(n)}'\nTS: ${exprToString(g.type)}\nLean: ${exprToString(expectedType)}\nDiff: ${exprKernelMetadataDiff(g.type,expectedType)??'<exact-expression mismatch>'}`);
      if(!nameEq(g.induct,this.n(asIndex(field(c,'induct','constructor'),'constructor.induct')))||g.cidx!==asUInt(field(c,'cidx','constructor'),'constructor.cidx')||g.numParams!==asUInt(field(c,'numParams','constructor'),'constructor.numParams')||g.numFields!==asUInt(field(c,'numFields','constructor'),'constructor.numFields')||!sameBool(g.isUnsafe,boolField(c,'isUnsafe','constructor')))throw new KernelError(`generated constructor metadata mismatch for '${nameToString(n)}'`);
    }
    for(const r of rvs){
      const n=this.n(asIndex(field(r,'name','recursor'),'recursor.name')),g=this.env.get(n);
      if(g.kind!=='recursor')throw new KernelError(`generated '${nameToString(n)}' is not a recursor`);
      const expectedType=this.e(asIndex(field(r,'type','recursor'),'recursor.type')); 
      if(!exprKernelMetadataEq(g.type,expectedType))throw new KernelError(`generated recursor type mismatch for '${nameToString(n)}'\nTS: ${exprToString(g.type)}\nLean: ${exprToString(expectedType)}\nDiff: ${exprKernelMetadataDiff(g.type,expectedType)??'<unknown>'}`);
      if(g.numParams!==asUInt(field(r,'numParams','recursor'),'recursor.numParams'))throw new KernelError(`generated recursor numParams mismatch for '${nameToString(n)}'`);
      if(g.numIndices!==asUInt(field(r,'numIndices','recursor'),'recursor.numIndices'))throw new KernelError(`generated recursor numIndices mismatch for '${nameToString(n)}'`);
      if(g.numMotives!==asUInt(field(r,'numMotives','recursor'),'recursor.numMotives'))throw new KernelError(`generated recursor numMotives mismatch for '${nameToString(n)}'`);
      if(g.numMinors!==asUInt(field(r,'numMinors','recursor'),'recursor.numMinors'))throw new KernelError(`generated recursor numMinors mismatch for '${nameToString(n)}'`);
      if(g.k!==boolField(r,'k','recursor'))throw new KernelError(`generated recursor K flag mismatch for '${nameToString(n)}'`);
      if(!sameBool(g.isUnsafe,boolField(r,'isUnsafe','recursor')))throw new KernelError(`generated recursor safety mismatch for '${nameToString(n)}'`);
      if(!namesEq(g.all,this.ns(field(r,'all','recursor'),'recursor.all')))throw new KernelError(`generated recursor all-list mismatch for '${nameToString(n)}'`);
      const rs=asArray(field(r,'rules','recursor'),'recursor.rules');if(rs.length!==g.rules.length)throw new KernelError(`recursor rule count mismatch for '${nameToString(n)}'`);for(let i=0;i<rs.length;i++){const x=asObject(rs[i]!,`recursor.rules[${i}]`),a=g.rules[i]!;if(!nameEq(a.ctor,this.n(asIndex(field(x,'ctor','recursor rule'),'recursor.rule.ctor')))||a.nFields!==asUInt(field(x,'nfields','recursor rule'),'recursor.rule.nfields')||!exprKernelMetadataEq(a.rhs,this.e(asIndex(field(x,'rhs','recursor rule'),'recursor.rule.rhs'))))throw new KernelError(`recursor rule mismatch for '${nameToString(n)}' #${i}`);}}
  }
}
