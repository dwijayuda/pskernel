import type {V061TypeExpr} from './type-parser.js';

function leanTypeTermBinaryPrecedence(operator:string):number {
  switch(operator){
    case '*':
    case '/':
    case '%':
      return 70;
    case '+':
    case '-':
      return 65;
    case '<':
    case '<=':
    case '>':
    case '>=':
    case '==':
    case '!=':
      return 50;
    case '&&':
      return 35;
    case '||':
      return 30;
    default:
      throw new Error('unsupported type binary operator '+operator);
  }
  throw new Error('unsupported type-term binary operator: '+operator);
}

export function lowerV061TypeToLean(
  type:V061TypeExpr,
  parentPrecedence=0,
):string {
  switch(type.kind){
    case 'nat':
      return type.text;
    case 'bool':
      return type.value?'true':'false';
    case 'named':
      return type.name;
    case 'group':
      return '('+lowerV061TypeToLean(type.value)+')';
    case 'application':{
      const precedence=80;
      const rendered=lowerV061TypeToLean(type.fn,precedence)+' '+
        type.args.map((arg)=>lowerV061TypeToLean(arg,precedence+1)).join(' ');
      return precedence<parentPrecedence?'('+rendered+')':rendered;
    }
    case 'unary':{
      const precedence=75;
      const rendered='!'+lowerV061TypeToLean(type.operand,precedence);
      return precedence<parentPrecedence?'('+rendered+')':rendered;
    }
    case 'binary':{
      const precedence=leanTypeTermBinaryPrecedence(type.operator);
      const rendered=lowerV061TypeToLean(type.left,precedence)+' '+
        type.operator+' '+
        lowerV061TypeToLean(type.right,precedence+1);
      return precedence<parentPrecedence?'('+rendered+')':rendered;
    }
    case 'equality':{
      const precedence=50;
      const rendered=lowerV061TypeToLean(type.left,precedence+1)+' = '+
        lowerV061TypeToLean(type.right,precedence+1);
      return precedence<parentPrecedence?'('+rendered+')':rendered;
    }
    case 'dependentArrow':{
      const precedence=25;
      const rendered='('+type.name+' : '+
        lowerV061TypeToLean(type.domain)+') -> '+
        lowerV061TypeToLean(type.codomain,precedence);
      return precedence<parentPrecedence?'('+rendered+')':rendered;
    }
    case 'arrow':{
      const precedence=25;
      const rendered=lowerV061TypeToLean(type.domain,precedence+1)+' -> '+
        lowerV061TypeToLean(type.codomain,precedence);
      return precedence<parentPrecedence?'('+rendered+')':rendered;
    }
  }
}
