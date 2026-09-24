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
  nameFromDotted,
  natLit,
  sort,
  TypeChecker,
} from 'lean-ts-kernel';
import {Lean434Evaluator} from '../src/lean4-eval.js';
import {ctor,nat,natAdd,natMul,natSub,uint8} from '../src/index.js';
import {
  LEAN434_JS_EXTERN_MANIFEST,
  LEAN434_SOURCE_VERSION,
  LeanRefEmptyError,
  findLean434JsExtern,
  findLean434JsImplementedBy,
  invokeLean434JsImplementedBy,
  lean_array_fget,
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
console.log('ok - @proofscript/runtime evaluates pskernel-admitted Lean expressions');
