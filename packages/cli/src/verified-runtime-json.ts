import type {
  VerifiedIrModule,
  VerifiedIrType,
} from '@proofscript/compiler-ir/verified';

export interface VerifiedRuntimeAbiContext {
  readonly module:VerifiedIrModule;
  readonly runtimeExports:Readonly<Record<string,unknown>>;
}

type TypeSubstitution=ReadonlyMap<string,VerifiedIrType>;

function fail(message:string):never {
  throw new Error('PS_RUN_VERIFIED_ABI: '+message);
}

function isRecord(value:unknown):value is Record<string,unknown> {
  return typeof value==='object'&&value!==null&&!Array.isArray(value);
}

function instantiateType(
  type:VerifiedIrType,
  substitution:TypeSubstitution,
):VerifiedIrType {
  if(type.kind==='typeParameter')return substitution.get(type.name)??type;
  if(type.kind==='named'){
    return {
      kind:'named',
      name:type.name,
      args:type.args.map((arg)=>instantiateType(arg,substitution)),
    };
  }
  if(type.kind==='function'){
    return {
      kind:'function',
      parameters:type.parameters.map((arg)=>instantiateType(arg,substitution)),
      result:instantiateType(type.result,substitution),
    };
  }
  return type;
}

function bindTypeParameters(
  names:readonly {readonly name:string}[],
  args:readonly VerifiedIrType[],
  parent:TypeSubstitution,
  label:string,
):TypeSubstitution {
  if(names.length!==args.length){
    fail(label+' expects '+names.length+' type arguments, got '+args.length);
  }
  const next=new Map(parent);
  names.forEach((parameter,index)=>{
    next.set(parameter.name,instantiateType(args[index]!,parent));
  });
  return next;
}

function decodePrimitive(
  value:unknown,
  name:Extract<VerifiedIrType,{kind:'primitive'}>['name'],
):unknown {
  if(name==='Nat'){
    if(typeof value!=='string'||!/^\d+$/u.test(value)){
      fail('nested Nat values must be decimal JSON strings');
    }
    return BigInt(value);
  }
  if(name==='Int'){
    if(typeof value!=='string'||!^-?\d+$/u.test(value)){
      fail('nested Int values must be decimal JSON strings');
    }
    return BigInt(value);
  }
  if(name==='UInt8'||name==='UInt16'||name==='UInt32'){
    const bits=name==='UInt8'?8n:name==='UInt16'?16n:32n;
    const limit=1n<<bits;
    if(
      typeof value!=='number'||
      !Number.isInteger(value)||
      value<0||
      BigInt(value)>=limit
    ){
      fail(
        'nested '+name+' values must be in-range JSON integers',
      );
    }
    return value;
  }
  if(name==='UInt64'){
    if(typeof value!=='string'||!/^\d+$/u.test(value)){
      fail('nested UInt64 values must be decimal JSON strings');
    }
    const parsed=BigInt(value);
    if(parsed>=(1n<<64n)){
      fail('nested UInt64 value is outside its 64-bit range');
    }
    return parsed;
  }
  if(name==='Bool'){
    if(typeof value!=='boolean')fail('nested Bool values must be JSON booleans');
    return value;
  }
  if(name==='String'){
    if(typeof value!=='string')fail('nested String values must be JSON strings');
    return value;
  }
  if(value!==null)fail('nested Unit values must be JSON null');
  return undefined;
}

function decodeValue(
  value:unknown,
  type:VerifiedIrType,
  context:VerifiedRuntimeAbiContext,
  substitution:TypeSubstitution=new Map(),
):unknown {
  const resolved=instantiateType(type,substitution);
  if(resolved.kind==='primitive')return decodePrimitive(value,resolved.name);
  if(resolved.kind==='typeParameter'){
    fail("unresolved runtime type parameter '"+resolved.name+"'");
  }
  if(resolved.kind==='function'){
    fail('function-typed runtime values cannot cross the CLI JSON ABI');
  }
  if(resolved.kind==='unknown'){
    fail('unknown runtime types cannot cross the CLI JSON ABI');
  }

  const structure=context.module.structures?.find(
    (item)=>item.name===resolved.name,
  );
  if(structure!==undefined){
    if(!isRecord(value)){
      fail("structure '"+resolved.name+"' must be a JSON object");
    }
    const fieldNames=new Set(structure.fields.map((field)=>field.name));
    for(const key of Object.keys(value)){
      if(!fieldNames.has(key)){
        fail("unknown field '"+key+"' for structure '"+resolved.name+"'");
      }
    }
    const local=bindTypeParameters(
      structure.typeParameters??[],
      resolved.args,
      substitution,
      "structure '"+resolved.name+"'",
    );
    const result:Record<string,unknown>={};
    for(const field of structure.fields){
      if(!Object.prototype.hasOwnProperty.call(value,field.name)){
        fail("missing field '"+field.name+"' for structure '"+resolved.name+"'");
      }
      result[field.name]=decodeValue(value[field.name],field.type,context,local);
    }
    return result;
  }

  const inductive=context.module.inductives?.find(
    (item)=>item.name===resolved.name,
  );
  if(inductive===undefined){
    fail("unknown named runtime type '"+resolved.name+"'");
  }
  if(!isRecord(value)){
    fail("inductive '"+resolved.name+"' must be a JSON object");
  }
  const ctorName=value.$ctor;
  if(typeof ctorName!=='string'){
    fail("inductive '"+resolved.name+"' requires string field '$ctor'");
  }
  const ctor=inductive.constructors.find((item)=>item.name===ctorName);
  if(ctor===undefined){
    fail("unknown constructor '"+ctorName+"' for inductive '"+resolved.name+"'");
  }
  const allowed=new Set(['$ctor',...ctor.fields.map((field)=>field.name)]);
  for(const key of Object.keys(value)){
    if(!allowed.has(key)){
      fail(
        "unknown field '"+key+"' for constructor '"+
        resolved.name+'.'+ctorName+"'",
      );
    }
  }
  const local=bindTypeParameters(
    inductive.typeParameters??[],
    resolved.args,
    substitution,
    "inductive '"+resolved.name+"'",
  );
  const fields=ctor.fields.map((field)=>{
    if(!Object.prototype.hasOwnProperty.call(value,field.name)){
      fail(
        "missing field '"+field.name+"' for constructor '"+
        resolved.name+'.'+ctorName+"'",
      );
    }
    return decodeValue(value[field.name],field.type,context,local);
  });
  const namespace=context.runtimeExports[resolved.name];
  if(!isRecord(namespace)){
    fail("runtime constructor namespace '"+resolved.name+"' is unavailable");
  }
  const factory=namespace[ctorName];
  if(typeof factory==='function'){
    return (factory as (...args:unknown[])=>unknown)(...fields);
  }
  if(fields.length===0&&factory!==undefined)return factory;
  fail("runtime constructor '"+resolved.name+'.'+ctorName+"' is unavailable");
}

function encodePrimitive(
  value:unknown,
  name:Extract<VerifiedIrType,{kind:'primitive'}>['name'],
):unknown {
  if(name==='Nat'||name==='Int'){
    if(typeof value!=='bigint'){
      fail(name+' result did not use the verified bigint runtime representation');
    }
    return value.toString();
  }
  if(name==='UInt8'||name==='UInt16'||name==='UInt32'){
    const bits=name==='UInt8'?8n:name==='UInt16'?16n:32n;
    const limit=1n<<bits;
    if(
      typeof value!=='number'||
      !Number.isInteger(value)||
      value<0||
      BigInt(value)>=limit
    ){
      fail(name+' result is outside its verified unsigned range');
    }
    return value;
  }
  if(name==='UInt64'){
    if(
      typeof value!=='bigint'||
      value<0n||
      value>=(1n<<64n)
    ){
      fail('UInt64 result is outside its verified unsigned range');
    }
    return value.toString();
  }
  if(name==='Bool'){
    if(typeof value!=='boolean')fail('Bool result is not a boolean');
    return value;
  }
  if(name==='String'){
    if(typeof value!=='string')fail('String result is not a string');
    return value;
  }
  if(value!==undefined)fail('Unit result is not undefined');
  return null;
}

function constructorName(
  value:Record<string,unknown>,
  inductive:string,
):string {
  for(const symbol of Object.getOwnPropertySymbols(value)){
    if(symbol.description==='ProofScript.'+inductive+'.tag'){
      const tag=(value as Record<PropertyKey,unknown>)[symbol];
      if(typeof tag==='string')return tag;
    }
  }
  fail("runtime value for inductive '"+inductive+"' has no verified constructor tag");
}

function encodeValue(
  value:unknown,
  type:VerifiedIrType,
  module:VerifiedIrModule,
  substitution:TypeSubstitution=new Map(),
):unknown {
  const resolved=instantiateType(type,substitution);
  if(resolved.kind==='primitive')return encodePrimitive(value,resolved.name);
  if(resolved.kind==='typeParameter'){
    fail("unresolved result type parameter '"+resolved.name+"'");
  }
  if(resolved.kind==='function'){
    fail('function-typed results cannot cross the CLI JSON ABI');
  }
  if(resolved.kind==='unknown')fail('unknown result types cannot cross the CLI JSON ABI');
  if(!isRecord(value))fail("named result '"+resolved.name+"' is not an object");

  const structure=module.structures?.find((item)=>item.name===resolved.name);
  if(structure!==undefined){
    const local=bindTypeParameters(
      structure.typeParameters??[],
      resolved.args,
      substitution,
      "structure '"+resolved.name+"'",
    );
    const result:Record<string,unknown>={};
    for(const field of structure.fields){
      result[field.name]=encodeValue(value[field.name],field.type,module,local);
    }
    return result;
  }

  const inductive=module.inductives?.find((item)=>item.name===resolved.name);
  if(inductive===undefined)fail("unknown named result type '"+resolved.name+"'");
  const ctorName=constructorName(value,resolved.name);
  const ctor=inductive.constructors.find((item)=>item.name===ctorName);
  if(ctor===undefined){
    fail(
      "runtime constructor tag '"+ctorName+
      "' is not declared by inductive '"+resolved.name+"'",
    );
  }
  const local=bindTypeParameters(
    inductive.typeParameters??[],
    resolved.args,
    substitution,
    "inductive '"+resolved.name+"'",
  );
  const result:Record<string,unknown>={$ctor:ctorName};
  for(const field of ctor.fields){
    result[field.name]=encodeValue(value[field.name],field.type,module,local);
  }
  return result;
}

export function decodeVerifiedJsonArgument(
  text:string,
  type:VerifiedIrType,
  context:VerifiedRuntimeAbiContext,
):unknown {
  let parsed:unknown;
  try{parsed=JSON.parse(text);}
  catch(error){
    fail(
      'structured argument must be valid JSON: '+
      (error instanceof Error?error.message:String(error)),
    );
  }
  return decodeValue(parsed,type,context);
}

export function encodeVerifiedRuntimeValue(
  value:unknown,
  type:VerifiedIrType,
  module:VerifiedIrModule,
):unknown {
  return encodeValue(value,type,module);
}
