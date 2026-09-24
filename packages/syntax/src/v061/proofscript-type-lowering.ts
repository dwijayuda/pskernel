import type {V061TypeExpr} from './type-parser.js';
import {v061BinaryPrecedence} from './operators.js';

const APPLICATION_PRECEDENCE=8;
const UNARY_PRECEDENCE=7;
const EQUALITY_PRECEDENCE=0;
const ARROW_PRECEDENCE=-1;
const ROOT_PRECEDENCE=-2;

function wrap(
  rendered:string,
  precedence:number,
  parentPrecedence:number,
):string {
  return precedence<parentPrecedence?'('+rendered+')':rendered;
}

export function lowerV061TypeToProofScript(
  type:V061TypeExpr,
  parentPrecedence=ROOT_PRECEDENCE,
):string {
  switch(type.kind){
    case 'nat':
      return type.text;
    case 'bool':
      return type.value?'true':'false';
    case 'named':
      return type.name;
    case 'group':
      return '('+lowerV061TypeToProofScript(type.value)+')';
    case 'application':{
      const rendered=
        lowerV061TypeToProofScript(type.fn,APPLICATION_PRECEDENCE)+
        '('+
        type.args.map((arg)=>lowerV061TypeToProofScript(arg)).join(', ')+
        ')';
      return wrap(rendered,APPLICATION_PRECEDENCE,parentPrecedence);
    }
    case 'unary':{
      const rendered='!'+
        lowerV061TypeToProofScript(type.operand,UNARY_PRECEDENCE);
      return wrap(rendered,UNARY_PRECEDENCE,parentPrecedence);
    }
    case 'binary':{
      const precedence=v061BinaryPrecedence(type.operator);
      if(precedence===undefined){
        throw new Error(
          "PS_PRINT_TYPE_OPERATOR: unsupported operator '"+type.operator+"'",
        );
      }
      const rendered=
        lowerV061TypeToProofScript(type.left,precedence)+' '+
        type.operator+' '+
        lowerV061TypeToProofScript(type.right,precedence+1);
      return wrap(rendered,precedence,parentPrecedence);
    }
    case 'equality':{
      const rendered=
        lowerV061TypeToProofScript(
          type.left,
          EQUALITY_PRECEDENCE+1,
        )+' = '+
        lowerV061TypeToProofScript(
          type.right,
          EQUALITY_PRECEDENCE+1,
        );
      return wrap(rendered,EQUALITY_PRECEDENCE,parentPrecedence);
    }
    case 'dependentArrow':{
      const rendered=
        '('+type.name+' : '+
        lowerV061TypeToProofScript(type.domain)+') -> '+
        lowerV061TypeToProofScript(type.codomain,ARROW_PRECEDENCE);
      return wrap(rendered,ARROW_PRECEDENCE,parentPrecedence);
    }
    case 'arrow':{
      const rendered=
        lowerV061TypeToProofScript(type.domain,ARROW_PRECEDENCE+1)+
        ' -> '+
        lowerV061TypeToProofScript(type.codomain,ARROW_PRECEDENCE);
      return wrap(rendered,ARROW_PRECEDENCE,parentPrecedence);
    }
  }
}
