import type {
  VerifiedIrLiteral,
  VerifiedIrType,
} from '@proofscript/compiler-ir/verified';

export function emitVerifiedType(type:VerifiedIrType):string {
  switch(type.kind){
    case 'unknown':return 'unknown';
    case 'typeParameter':return type.name;
    case 'primitive':
      switch(type.name){
        case 'Nat':
        case 'Int':
          return 'bigint';
        case 'UInt8':
        case 'UInt16':
        case 'UInt32':
          return 'number';
        case 'UInt64':
          return 'bigint';
        case 'Bool':
          return 'boolean';
        case 'String':
          return 'string';
        case 'Unit':
          return 'undefined';
      }
    case 'named':
      return type.args.length===0
        ?type.name
        :type.name+'<'+type.args.map(emitVerifiedType).join(', ')+'>';
    case 'function':
      return '('+
        type.parameters.map((parameter,index)=>
          '_arg'+index+': '+emitVerifiedType(parameter)
        ).join(', ')+') => '+emitVerifiedType(type.result);
  }
}

export function emitVerifiedLiteral(value:VerifiedIrLiteral):string {
  if(typeof value==='bigint')return String(value)+'n';
  if(value===undefined)return 'undefined';
  return JSON.stringify(value);
}
