import type {
  VerifiedIrType,
} from '@proofscript/compiler-ir/verified';

export function substituteVerifiedType(
  type:VerifiedIrType,
  substitutions:ReadonlyMap<string,VerifiedIrType>,
):VerifiedIrType {
  switch(type.kind){
    case 'unknown':
    case 'primitive':
      return type;
    case 'typeParameter':
      return substitutions.get(type.name)??type;
    case 'named':
      return {
        ...type,
        args:type.args.map((arg)=>
          substituteVerifiedType(arg,substitutions)
        ),
      };
    case 'function':
      return {
        ...type,
        parameters:type.parameters.map((parameter)=>
          substituteVerifiedType(parameter,substitutions)
        ),
        result:substituteVerifiedType(type.result,substitutions),
      };
  }
}
