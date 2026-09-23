export type Doc =
  | {readonly kind:'text';readonly value:string}
  | {readonly kind:'line'}
  | {readonly kind:'concat';readonly parts:readonly Doc[]}
  | {readonly kind:'indent';readonly by:number;readonly doc:Doc}
  | {readonly kind:'group';readonly doc:Doc};
export const text=(value:string):Doc=>({kind:'text',value});
export const line:Doc={kind:'line'};
export const concat=(...parts:readonly Doc[]):Doc=>({kind:'concat',parts});
export const indent=(by:number,doc:Doc):Doc=>{
  if(!Number.isSafeInteger(by)||by<0)throw new RangeError('indent must be a non-negative integer');
  return {kind:'indent',by,doc};
};
export const group=(doc:Doc):Doc=>({kind:'group',doc});
export function join(separator:Doc,parts:readonly Doc[]):Doc{
  const out:Doc[]=[];
  parts.forEach((part,index)=>{if(index>0)out.push(separator);out.push(part);});
  return concat(...out);
}
function flat(doc:Doc):string{
  switch(doc.kind){
    case 'text':return doc.value;
    case 'line':return ' ';
    case 'concat':return doc.parts.map(flat).join('');
    case 'indent':return flat(doc.doc);
    case 'group':return flat(doc.doc);
  }
}
export function render(doc:Doc,width=80):string{
  if(!Number.isSafeInteger(width)||width<1)throw new RangeError('width must be a positive integer');
  let column=0;
  const go=(node:Doc,level:number):string=>{
    switch(node.kind){
      case 'text':column+=node.value.length;return node.value;
      case 'line':column=level;return '\n'+' '.repeat(level);
      case 'concat':return node.parts.map(part=>go(part,level)).join('');
      case 'indent':return go(node.doc,level+node.by);
      case 'group':{
        const candidate=flat(node.doc);
        if(column+candidate.length<=width){column+=candidate.length;return candidate;}
        return go(node.doc,level);
      }
    }
  };
  return go(doc,0);
}
export interface DiagnosticLike {
  readonly severity:'error'|'warning'|'info';
  readonly message:string;
  readonly line?:number;
  readonly column?:number;
}
export function renderDiagnostic(diagnostic:DiagnosticLike):string{
  const where=diagnostic.line===undefined?'':`:${diagnostic.line}${diagnostic.column===undefined?'':`:${diagnostic.column}`}`;
  return `${diagnostic.severity.toUpperCase()}${where}: ${diagnostic.message}`;
}
