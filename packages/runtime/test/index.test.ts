import {
  Environment,
  Kernel,
  addPrimitiveInductive,
  app,
  bvar,
  constant,
  forallE,
  lam,
  levelSucc,
  levelZero,
  mkAppN,
  nameEq,
  nameFromDotted,
  numName,
  strName,
  anonymous,
  natLit,
  sort,
  TypeChecker,
} from 'lean-ts-kernel';
import {
  LEAN434_WORLD_TOKEN,
  Lean434EvaluationError,
  Lean434Evaluator,
} from '../src/lean4-eval.js';
import {
  Lean434NameBridgeError,
  kernelNameToLean434Runtime,
  lean434RuntimeNameToKernel,
} from '../src/lean4-name.js';
import {
  Lean434RuntimeMetadataError,
  Lean434RuntimeMetadataIndex,
  parseLean434RuntimeMetadata,
} from '../src/lean4-metadata.js';
import {
  Lean434InitializerRunner,
} from '../src/lean4-init.js';
import {ctor,nat,natAdd,natMul,natSub,uint8} from '../src/index.js';
import {
  LEAN434_JS_EXTERN_MANIFEST,
  LEAN434_SOURCE_VERSION,
  LeanRef,
  LeanRefEmptyError,
  findLean434JsExtern,
  findLean434JsImplementedBy,
  findLean434JsIntrinsic,
  invokeLean434JsImplementedBy,
  lean_array_fget,
  lean_array_mk,
  lean_array_to_list,
  lean_array_fset,
  lean_array_get_size,
  lean_array_push,
  lean_array_set,
  lean_mk_empty_array_with_capacity,
  lean_nat_add,
  lean_nat_div,
  lean_nat_mod,
  lean_nat_mul,
  lean_nat_sub,
  lean_st_mk_ref,
  lean_st_ref_get,
  lean_st_ref_ptr_eq,
  lean_st_ref_set,
  lean_st_ref_swap,
  lean_st_ref_take,
  lean_string_is_valid_pos,
  lean_string_length,
  lean_string_utf8_at_end,
  lean_string_utf8_byte_size,
  lean_string_utf8_extract,
  lean_string_utf8_get,
  lean_string_utf8_next,
  lean_string_utf8_prev,
  lean_uint8_of_nat,
  lean_uint32_of_nat,
  lean_uint64_of_nat,
} from '../src/lean4.js';

function equal(a:unknown,b:unknown):void{
  if(a!==b)throw new Error(`expected ${String(b)}, got ${String(a)}`);
}
function ok(value:boolean,message:string):void{
  if(!value)throw new Error(message);
}
function deepEqual(a:unknown,b:unknown,message:string):void{
  if(JSON.stringify(a)!==JSON.stringify(b))throw new Error(message);
}
function throws(
  fn:()=>unknown,
  expected:new (...args:any[])=>Error,
  message:string,
):void{
  try{
    fn();
  }catch(error){
    if(error instanceof expected)return;
    throw error;
  }
  throw new Error(message);
}

// Existing ProofScript runtime foundation.
equal(natAdd(nat(2),nat(3)),5n);
equal(natMul(nat(4),nat(5)),20n);
equal(natSub(nat(2),nat(5)),0n);
equal(uint8(257),1);
equal(uint8(-1),255);
equal(ctor('Some',1).tag,'Some');

{
  const kernelName=numName(
    strName(
      strName(anonymous,'Lean'),
      'Meta',
    ),
    17n,
  );
  const runtimeName=kernelNameToLean434Runtime(kernelName);
  const roundTrip=lean434RuntimeNameToKernel(runtimeName);
  ok(nameEq(roundTrip,kernelName),'Lean Name bridge round-trip mismatch');
  throws(
    ()=>lean434RuntimeNameToKernel({
      kind:'constructor',
      name:'Not.Lean.Name',
      fields:[],
    }),
    Lean434NameBridgeError,
    'invalid runtime Name constructor must fail closed',
  );
}
console.log('ok - Lean runtime Name bridge preserves pskernel structure');

// Lean 4.34 Nat and machine-integer compatibility.
equal(LEAN434_SOURCE_VERSION,'4.34.0');
equal(lean_nat_add(2n,3n),5n);
equal(lean_nat_mul(4n,5n),20n);
equal(lean_nat_sub(2n,5n),0n);
equal(lean_nat_div(7n,2n),3n);
equal(lean_nat_div(7n,0n),0n);
equal(lean_nat_mod(7n,3n),1n);
equal(lean_nat_mod(7n,0n),7n);
equal(lean_uint8_of_nat(257n),1);
equal(lean_uint32_of_nat((1n<<32n)+3n),3);
equal(lean_uint64_of_nat((1n<<64n)+5n),5n);

// Lean Array has value semantics even though the native runtime may optimize
// unique arrays using destructive updates.
const empty=lean_mk_empty_array_with_capacity<number>(64n);
deepEqual(empty,[],'empty Lean array mismatch');
const listRuntime={
  kind:'constructor' as const,
  name:'List.cons' as const,
  fields:[
    10,
    {
      kind:'constructor' as const,
      name:'List.cons' as const,
      fields:[
        20,
        {
          kind:'constructor' as const,
          name:'List.nil' as const,
          fields:[],
        },
      ],
    },
  ],
};
deepEqual(
  lean_array_mk<number>(listRuntime),
  [10,20],
  'lean_array_mk List-to-array bridge mismatch',
);
deepEqual(
  lean_array_to_list([10,20]),
  listRuntime,
  'lean_array_to_list array-to-List bridge mismatch',
);
const one=lean_array_push(empty,10);
const two=lean_array_push(one,20);
equal(lean_array_get_size(two),2n);
equal(lean_array_fget(two,1n),20);
const changed=lean_array_fset(two,0n,99);
deepEqual(two,[10,20],'lean_array_fset mutated its input');
deepEqual(changed,[99,20],'lean_array_fset result mismatch');
const unchanged=lean_array_set(two,9n,77);
deepEqual(unchanged,[10,20],'lean_array_set out-of-bounds semantics mismatch');

// String.Pos.Raw uses UTF-8 byte offsets, never JavaScript UTF-16 indexes.
// "L∃∀N" occupies byte offsets 0,1,4,7 and has rawEndPos 8.
const utf8='L∃∀N';
equal(lean_string_length(utf8),4n);
equal(lean_string_utf8_byte_size(utf8),8n);
for(const p of [0n,1n,4n,7n,8n]){
  ok(lean_string_is_valid_pos(utf8,p),`expected valid UTF-8 position ${p}`);
}
ok(!lean_string_is_valid_pos(utf8,2n),'middle-of-codepoint position must be invalid');
equal(lean_string_utf8_get(utf8,0n),'L');
equal(lean_string_utf8_get(utf8,1n),'∃');
equal(lean_string_utf8_get(utf8,4n),'∀');
equal(lean_string_utf8_get(utf8,7n),'N');
equal(lean_string_utf8_get(utf8,2n),'A');
equal(lean_string_utf8_next(utf8,0n),1n);
equal(lean_string_utf8_next(utf8,1n),4n);
equal(lean_string_utf8_next(utf8,2n),3n);
equal(lean_string_utf8_next(utf8,8n),9n);
equal(lean_string_utf8_prev(utf8,4n),1n);
equal(lean_string_utf8_prev(utf8,2n),1n);
equal(lean_string_utf8_prev(utf8,0n),0n);
equal(lean_string_utf8_prev(utf8,10n),9n);
ok(!lean_string_utf8_at_end(utf8,7n),'byte 7 is not the end position');
ok(lean_string_utf8_at_end(utf8,8n),'byte 8 is the end position');
equal(lean_string_utf8_extract(utf8,1n,7n),'∃∀');
equal(lean_string_utf8_extract(utf8,7n,4n),'');

// First bootstrap ST.Ref implementation is intentionally single-threaded.
const ref=lean_st_mk_ref('first');
const alias=ref;
const other=lean_st_mk_ref('first');
ok(lean_st_ref_ptr_eq(ref,alias),'ST.Ref alias identity mismatch');
ok(!lean_st_ref_ptr_eq(ref,other),'distinct ST.Ref cells compared equal');
equal(lean_st_ref_get(ref),'first');
lean_st_ref_set(ref,'second');
equal(lean_st_ref_get(ref),'second');
equal(lean_st_ref_swap(ref,'third'),'second');
equal(lean_st_ref_get(ref),'third');
equal(lean_st_ref_take(ref),'third');
throws(
  ()=>lean_st_ref_get(ref),
  LeanRefEmptyError,
  'reading an empty bootstrap ST.Ref must fail closed',
);
lean_st_ref_set(ref,'restored');
equal(lean_st_ref_get(ref),'restored');

// Extern mapping is explicit and fail-closed.
equal(findLean434JsExtern('lean_nat_add')?.jsExport,'lean_nat_add');
equal(findLean434JsExtern('lean_st_ref_get')?.category,'mutable-state');
equal(findLean434JsExtern('not_a_real_lean_extern'),undefined);
ok(
  LEAN434_JS_EXTERN_MANIFEST.every((entry)=>entry.leanSymbol.length>0&&entry.jsExport.length>0),
  'extern manifest contains an empty symbol',
);

const unsafeCastBinding=findLean434JsIntrinsic('unsafeCast');
ok(unsafeCastBinding!==undefined,'missing unsafeCast intrinsic binding');
equal(unsafeCastBinding!.arity,3);
deepEqual(
  unsafeCastBinding!.runtimeArgs,
  [2],
  'unsafeCast intrinsic must erase source/target type arguments',
);
{
  const evaluator=new Lean434Evaluator(new Environment());
  let cast=evaluator.evaluate(constant(nameFromDotted('unsafeCast')));
  cast=evaluator.applyRuntimeValue(cast,evaluator.evaluate(sort(levelZero)));
  cast=evaluator.applyRuntimeValue(cast,evaluator.evaluate(sort(levelZero)));
  equal(
    evaluator.applyRuntimeValue(cast,37n),
    37n,
  );
}

const rawBinding=findLean434JsImplementedBy('TSyntaxArray.raw');
ok(rawBinding!==undefined,'missing TSyntaxArray.raw implemented_by binding');
const rawPayload=[{kind:'syntax'}];
equal(
  invokeLean434JsImplementedBy(rawBinding!,[rawPayload]),
  rawPayload,
);
const mkBinding=findLean434JsImplementedBy('TSyntaxArray.mk');
ok(mkBinding!==undefined,'missing TSyntaxArray.mk implemented_by binding');
equal(
  invokeLean434JsImplementedBy(mkBinding!,[rawPayload]),
  rawPayload,
);

{
  const metadata=parseLean434RuntimeMetadata({
    format:'proofscript-lean434-runtime-metadata',
    formatVersion:1,
    lean:{
      version:'4.34.0',
      githash:'293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
    },
    module:'Lean.Parser',
    externs:[
      {
        declaration:'Nat.add',
        entries:[
          {kind:'standard',backend:'all',symbol:'lean_nat_add'},
        ],
      },
    ],
    implementedBy:[
      {
        declaration:'TSyntaxArray.raw',
        implementation:'TSyntaxArray.rawImpl',
      },
    ],
    initializers:[
      {
        module:'Lean.Parser.Extension',
        moduleIndex:4,
        kind:'regular',
        source:'olean',
        declaration:'exampleInit',
        initFunction:'exampleInitFn',
        ioUnit:false,
      },
      {
        module:'Lean.Parser.Extension',
        moduleIndex:4,
        kind:'regular',
        source:'ir',
        declaration:'exampleInit',
        initFunction:'exampleInitFn',
        ioUnit:false,
      },
      {
        module:'Lean.Parser.Extension',
        moduleIndex:4,
        kind:'builtin',
        source:'olean',
        declaration:'unitInit',
        initFunction:null,
        ioUnit:true,
      },
    ],
  });
  equal(metadata.initializers.length,2);
  equal(metadata.initializers[0]?.source,'olean');
  equal(metadata.initializers[1]?.declaration,'unitInit');
  const index=new Lean434RuntimeMetadataIndex(metadata);
  equal(
    index.externFor('Nat.add')?.entries[0]?.kind,
    'standard',
  );
  equal(
    index.implementedByFor('TSyntaxArray.raw')?.implementation,
    'TSyntaxArray.rawImpl',
  );
  equal(
    index.initializersForModule('Lean.Parser.Extension').length,
    2,
  );
  throws(
    ()=>parseLean434RuntimeMetadata({
      ...metadata,
      lean:{...metadata.lean,githash:'wrong'},
    }),
    Lean434RuntimeMetadataError,
    'runtime metadata githash drift must fail closed',
  );

  const metadataEvaluator=new Lean434Evaluator(
    new Environment(),
    {metadata:index},
  );
  equal(
    metadataEvaluator.evaluate(
      mkAppN(
        constant(nameFromDotted('Nat.add')),
        [natLit(2n),natLit(3n)],
      ),
    ),
    5n,
  );
  equal(
    metadataEvaluator.evaluate(
      app(
        constant(nameFromDotted('TSyntaxArray.raw')),
        natLit(9n),
      ),
    ),
    9n,
  );

  const wrongExtern=parseLean434RuntimeMetadata({
    ...metadata,
    externs:[
      {
        declaration:'Nat.add',
        entries:[
          {kind:'standard',backend:'all',symbol:'lean_nat_mul'},
        ],
      },
    ],
  });
  throws(
    ()=>new Lean434Evaluator(
      new Environment(),
      {metadata:new Lean434RuntimeMetadataIndex(wrongExtern)},
    ).evaluate(
      mkAppN(
        constant(nameFromDotted('Nat.add')),
        [natLit(2n),natLit(3n)],
      ),
    ),
    Lean434EvaluationError,
    'extern sidecar mismatch must fail closed',
  );

  const wrongImplementedBy=parseLean434RuntimeMetadata({
    ...metadata,
    implementedBy:[
      {
        declaration:'TSyntaxArray.raw',
        implementation:'Wrong.rawImpl',
      },
    ],
  });
  throws(
    ()=>new Lean434Evaluator(
      new Environment(),
      {metadata:new Lean434RuntimeMetadataIndex(wrongImplementedBy)},
    ).evaluate(
      app(
        constant(nameFromDotted('TSyntaxArray.raw')),
        natLit(1n),
      ),
    ),
    Lean434EvaluationError,
    'implemented_by sidecar mismatch must fail closed',
  );
}
console.log('ok - Lean 4.34 runtime metadata loader validates and deduplicates');

console.log('ok - @proofscript/runtime foundation + Lean 4.34 JS compatibility slice');


{
  const environment=new Environment();
  const Nat=nameFromDotted('Nat');
  const NatZero=nameFromDotted('Nat.zero');
  const NatSucc=nameFromDotted('Nat.succ');
  const x=nameFromDotted('x');
  const natType=constant(Nat);

  addPrimitiveInductive(environment,{
    levelParams:[],
    numParams:0,
    types:[{
      name:Nat,
      type:sort(levelSucc(levelZero)),
      ctors:[
        {name:NatZero,type:natType},
        {name:NatSucc,type:forallE(x,natType,natType)},
      ],
    }],
  });

  const kernel=new Kernel(environment);
  const fortyTwo=nameFromDotted('RuntimeTest.fortyTwo');
  kernel.addDefinition({
    kind:'definition',
    name:fortyTwo,
    levelParams:[],
    type:natType,
    value:app(constant(NatSucc),natLit(41n)),
    hints:{kind:'regular',height:1n},
    safety:'safe',
  });

  const addOne=nameFromDotted('RuntimeTest.addOne');
  kernel.addDefinition({
    kind:'definition',
    name:addOne,
    levelParams:[],
    type:forallE(x,natType,natType),
    value:lam(
      x,
      natType,
      app(constant(NatSucc),bvar(0)),
    ),
    hints:{kind:'regular',height:1n},
    safety:'safe',
  });

  const evaluator=new Lean434Evaluator(environment);
  equal(evaluator.evaluate(constant(fortyTwo)),42n);
  equal(
    evaluator.evaluate(app(constant(addOne),natLit(41n))),
    42n,
  );

  const NatRec=nameFromDotted('Nat.rec');
  const ih=nameFromDotted('ih');
  const motive=lam(
    nameFromDotted('_n'),
    natType,
    natType,
  );
  const step=lam(
    x,
    natType,
    lam(
      ih,
      natType,
      app(constant(NatSucc),bvar(0)),
    ),
  );
  const recExpr=mkAppN(
    constant(NatRec,[levelSucc(levelZero)]),
    [motive,natLit(0n),step,natLit(5n)],
  );
  const recChecker=new TypeChecker(environment);
  ok(
    recChecker.isDefEq(recChecker.check(recExpr),natType),
    'Nat.rec result type is not definitionally Nat',
  );
  equal(evaluator.evaluate(recExpr),5n);
}
{
  const environment=new Environment();
  const kernel=new Kernel(environment);
  const P=nameFromDotted('RuntimeTest.P');
  const proof=nameFromDotted('RuntimeTest.proof');
  kernel.addAxiom({
    kind:'axiom',
    name:P,
    levelParams:[],
    type:sort(levelZero),
  });
  kernel.addAxiom({
    kind:'axiom',
    name:proof,
    levelParams:[],
    type:constant(P),
  });
  const value=new Lean434Evaluator(environment).evaluate(constant(proof));
  ok(
    typeof value==='object'
      &&value!==null
      &&!Array.isArray(value)
      &&'kind' in value
      &&value.kind==='proof',
    'proposition-valued axiom was not erased to proof evidence',
  );
}
console.log('ok - proposition-valued axioms erase without JS implementations');

{
  const environment=new Environment();
  const Nat=nameFromDotted('Nat');
  const NatZero=nameFromDotted('Nat.zero');
  const NatSucc=nameFromDotted('Nat.succ');
  const x=nameFromDotted('x');
  const natType=constant(Nat);
  addPrimitiveInductive(environment,{
    levelParams:[],
    numParams:0,
    types:[{
      name:Nat,
      type:sort(levelSucc(levelZero)),
      ctors:[
        {name:NatZero,type:natType},
        {name:NatSucc,type:forallE(x,natType,natType)},
      ],
    }],
  });
  const kernel=new Kernel(environment);
  const wrapper=nameFromDotted('RuntimeTest.logicalWrapper');
  const implementation=nameFromDotted('RuntimeTest.unsafeImplementation');
  const functionType=forallE(x,natType,natType);
  kernel.addOpaque({
    kind:'opaque',
    name:wrapper,
    levelParams:[],
    type:functionType,
    value:lam(x,natType,natLit(0n)),
    isUnsafe:false,
  });
  kernel.addDefinition({
    kind:'definition',
    name:implementation,
    levelParams:[],
    type:functionType,
    value:lam(x,natType,bvar(0)),
    hints:{kind:'regular',height:1n},
    safety:'unsafe',
  });

  const metadata=parseLean434RuntimeMetadata({
    format:'proofscript-lean434-runtime-metadata',
    formatVersion:1,
    lean:{
      version:'4.34.0',
      githash:'293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
    },
    module:'RuntimeTest',
    externs:[],
    implementedBy:[{
      declaration:'RuntimeTest.logicalWrapper',
      implementation:'RuntimeTest.unsafeImplementation',
    }],
    initializers:[],
  });
  const logicalOnly=new Lean434Evaluator(environment);
  equal(
    logicalOnly.evaluate(app(constant(wrapper),natLit(42n))),
    0n,
  );
  const executable=new Lean434Evaluator(
    environment,
    {metadata:new Lean434RuntimeMetadataIndex(metadata)},
  );
  equal(
    executable.evaluate(app(constant(wrapper),natLit(42n))),
    42n,
  );
}
console.log(
  'ok - generic implemented_by executes runtime target without changing logical body',
);

console.log('ok - @proofscript/runtime evaluates pskernel-admitted Lean expressions');

{
  const evaluator=new Lean434Evaluator(new Environment());
  const typeToken=evaluator.evaluate(sort(levelZero));

  const mkRefAction=evaluator.evaluate(
    mkAppN(
      constant(nameFromDotted('ST.Prim.mkRef')),
      [sort(levelZero),sort(levelZero),natLit(5n)],
    ),
  );
  const firstRun=evaluator.runStateAction(mkRefAction);
  const secondRun=evaluator.runStateAction(mkRefAction);
  equal(firstRun.state,LEAN434_WORLD_TOKEN);
  equal(secondRun.state,LEAN434_WORLD_TOKEN);
  const firstRef=firstRun.value;
  const secondRef=secondRun.value;
  if(!(firstRef instanceof LeanRef)){
    throw new Error('ST.Prim.mkRef did not allocate LeanRef');
  }
  if(!(secondRef instanceof LeanRef)){
    throw new Error('second ST.Prim.mkRef did not allocate LeanRef');
  }
  ok(
    !lean_st_ref_ptr_eq(firstRef,secondRef),
    'running ST.Prim.mkRef twice must allocate distinct references',
  );
  equal(lean_st_ref_get(firstRef),5n);

  let getFn=evaluator.evaluate(
    constant(nameFromDotted('ST.Prim.Ref.get')),
  );
  getFn=evaluator.applyRuntimeValue(getFn,typeToken);
  getFn=evaluator.applyRuntimeValue(getFn,typeToken);
  const getAction=evaluator.applyRuntimeValue(getFn,firstRef);
  equal(evaluator.runStateAction(getAction).value,5n);

  let setFn=evaluator.evaluate(
    constant(nameFromDotted('ST.Prim.Ref.set')),
  );
  setFn=evaluator.applyRuntimeValue(setFn,typeToken);
  setFn=evaluator.applyRuntimeValue(setFn,typeToken);
  setFn=evaluator.applyRuntimeValue(setFn,firstRef);
  const setAction=evaluator.applyRuntimeValue(setFn,9n);
  const setResult=evaluator.runStateAction(setAction);
  equal(setResult.value,undefined);
  equal(setResult.state,LEAN434_WORLD_TOKEN);
  equal(lean_st_ref_get(firstRef),9n);
}
console.log('ok - Lean ST externs execute as deferred state actions');

{
  const evaluator=new Lean434Evaluator(new Environment());
  const initializing=evaluator.evaluate(
    constant(nameFromDotted('IO.initializing')),
  );
  equal(evaluator.runIOAction(initializing).value,false);
  equal(evaluator.runInitializerAction(initializing).value,true);
  equal(evaluator.runIOAction(initializing).value,false);
}
console.log('ok - IO.initializing is scoped to Lean initializer execution');

{
  const environment=new Environment();
  const kernel=new Kernel(environment);
  const target=nameFromDotted('RuntimeInit.value');
  const actionName=nameFromDotted('RuntimeInit.make');
  kernel.addAxiom({
    kind:'axiom',
    name:target,
    levelParams:[],
    type:sort(levelZero),
  });
  kernel.addAxiom({
    kind:'axiom',
    name:actionName,
    levelParams:[],
    type:sort(levelZero),
  });

  const evaluator=new Lean434Evaluator(environment);
  const action=evaluator.evaluate(
    mkAppN(
      constant(nameFromDotted('ST.Prim.mkRef')),
      [sort(levelZero),sort(levelZero),natLit(11n)],
    ),
  );
  evaluator.setRuntimeGlobal('RuntimeInit.make',action);

  const metadata=parseLean434RuntimeMetadata({
    format:'proofscript-lean434-runtime-metadata',
    formatVersion:1,
    lean:{
      version:'4.34.0',
      githash:'293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
    },
    module:'RuntimeInit',
    externs:[],
    implementedBy:[],
    initializers:[
      {
        module:'RuntimeInit',
        moduleIndex:0,
        kind:'builtin',
        source:'olean',
        declaration:'RuntimeInit.value',
        initFunction:'RuntimeInit.make',
        ioUnit:false,
      },
    ],
  });
  const runner=new Lean434InitializerRunner(
    evaluator,
    new Lean434RuntimeMetadataIndex(metadata),
  );
  const first=runner.runAll();
  equal(first.executed.length,1);
  equal(first.skipped.length,0);

  const initialized=evaluator.evaluate(constant(target));
  if(!(initialized instanceof LeanRef)){
    throw new Error('initializer did not store its computed LeanRef');
  }
  equal(lean_st_ref_get(initialized),11n);

  const second=runner.runAll();
  equal(second.executed.length,0);
  equal(second.skipped.length,1);
  equal(evaluator.evaluate(constant(target)),initialized);
}
console.log('ok - Lean initializer runner stores globals and runs once');
