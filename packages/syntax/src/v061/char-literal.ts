export function quoteV061Char(value:string):string {
  const chars=[...value];
  if(chars.length!==1){
    throw new Error('character literal printer requires one Unicode scalar value');
  }
  const ch=chars[0]!;
  const codePoint=ch.codePointAt(0)!;
  if(codePoint>=0xd800&&codePoint<=0xdfff){
    throw new Error('character literal printer rejects surrogate values');
  }

  let body:string;
  switch(ch){
    case "'":body="\\'";break;
    case '\\':body='\\\\';break;
    case '\n':body='\\n';break;
    case '\r':body='\\r';break;
    case '\t':body='\\t';break;
    default:
      if(codePoint<0x20||codePoint===0x7f){
        body=codePoint<=0xff
          ?'\\x'+codePoint.toString(16).padStart(2,'0')
          :'\\u'+codePoint.toString(16).padStart(4,'0');
      }else{
        body=ch;
      }
  }
  return "'"+body+"'";
}
