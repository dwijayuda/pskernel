import {SyntaxError,type SourcePosition,type SourceSpan,type Token,type Trivia} from './source.js';

const multiSymbols = [':=', '=>', '->', '==', '!=', '<=', '>=', '<-', '&&', '||', '::', '++', '**'] as const;
const isIdentifierStart = (ch: string): boolean => ch === '_' || /\p{ID_Start}/u.test(ch);
const isIdentifierContinue = (ch: string): boolean => ch === '_' || ch === "'" || ch === '?' || /\p{ID_Continue}/u.test(ch);
const codePointAt = (source: string, index: number): string => String.fromCodePoint(source.codePointAt(index)!);

interface CursorSnapshot { offset: number; line: number; column: number }

class Cursor {
  offset = 0;
  line = 1;
  column = 1;
  constructor(readonly source: string) {}
  get eof(): boolean { return this.offset >= this.source.length; }
  snapshot(): CursorSnapshot { return {offset:this.offset,line:this.line,column:this.column}; }
  position(): SourcePosition { return this.snapshot(); }
  startsWith(text: string): boolean { return this.source.startsWith(text, this.offset); }
  peekCodePoint(): string { return codePointAt(this.source, this.offset); }
  advanceCodePoint(): string {
    const ch = this.peekCodePoint();
    this.offset += ch.length;
    if (ch === '\n') { this.line += 1; this.column = 1; }
    else this.column += 1;
    return ch;
  }
  advanceAscii(count = 1): void {
    for (let i=0;i<count;i++) this.advanceCodePoint();
  }
}

const spanFrom = (start: CursorSnapshot, end: CursorSnapshot): SourceSpan => ({start,end});

function readTrivia(c: Cursor): Trivia[] {
  const out: Trivia[] = [];
  while (!c.eof) {
    const start = c.snapshot();
    if (/\s/u.test(c.peekCodePoint())) {
      while (!c.eof && /\s/u.test(c.peekCodePoint())) c.advanceCodePoint();
      out.push({kind:'whitespace',text:c.source.slice(start.offset,c.offset),span:spanFrom(start,c.snapshot())});
      continue;
    }
    if (c.startsWith('--')) {
      c.advanceAscii(2);
      while (!c.eof && !c.startsWith('\n') && !c.startsWith('\r')) c.advanceCodePoint();
      out.push({kind:'line-comment',text:c.source.slice(start.offset,c.offset),span:spanFrom(start,c.snapshot())});
      continue;
    }
    if (c.startsWith('/-')) {
      c.advanceAscii(2);
      let depth=1;
      while (!c.eof && depth>0) {
        if (c.startsWith('/-')) { c.advanceAscii(2); depth += 1; }
        else if (c.startsWith('-/')) { c.advanceAscii(2); depth -= 1; }
        else c.advanceCodePoint();
      }
      if (depth !== 0) throw new SyntaxError('unterminated block comment', spanFrom(start,c.snapshot()));
      out.push({kind:'block-comment',text:c.source.slice(start.offset,c.offset),span:spanFrom(start,c.snapshot())});
      continue;
    }
    break;
  }
  return out;
}

function readString(c: Cursor): {text:string;value:string;span:SourceSpan} {
  const start=c.snapshot();
  c.advanceAscii();
  let value='';
  while (!c.eof) {
    const ch=c.advanceCodePoint();
    if (ch==='"') return {text:c.source.slice(start.offset,c.offset),value,span:spanFrom(start,c.snapshot())};
    if (ch==='\n'||ch==='\r') throw new SyntaxError('newline in string literal', spanFrom(start,c.snapshot()));
    if (ch!=='\\') { value+=ch; continue; }
    if (c.eof) throw new SyntaxError('unterminated string escape', spanFrom(start,c.snapshot()));
    const esc=c.advanceCodePoint();
    if (esc==='"') value+='"';
    else if (esc==='\\') value+='\\';
    else if (esc==='n') value+='\n';
    else if (esc==='r') value+='\r';
    else if (esc==='t') value+='\t';
    else if (esc==='0') value+='\0';
    else if (esc==='x'||esc==='u') {
      const digits=esc==='x'?2:4;
      const hexStart=c.snapshot();
      let hex='';
      for(let i=0;i<digits;i++) {
        if(c.eof) throw new SyntaxError(`unterminated ${esc==='x'?'hex':'unicode'} escape`,spanFrom(start,c.snapshot()));
        const h=c.advanceCodePoint();
        if(!/[0-9a-fA-F]/.test(h)) throw new SyntaxError(`invalid ${esc==='x'?'hex':'unicode'} escape`,spanFrom(hexStart,c.snapshot()));
        hex+=h;
      }
      value+=String.fromCodePoint(parseInt(hex,16));
    } else throw new SyntaxError(`unsupported string escape \\${esc}`,spanFrom(start,c.snapshot()));
  }
  throw new SyntaxError('unterminated string literal',spanFrom(start,c.snapshot()));
}


function readCharacter(c: Cursor): {text:string;value:string;span:SourceSpan} {
  const start=c.snapshot();
  c.advanceAscii();
  if(c.eof)throw new SyntaxError('unterminated character literal',spanFrom(start,c.snapshot()));

  let value:string;
  const first=c.advanceCodePoint();
  if(first==="'"){
    throw new SyntaxError('empty character literal',spanFrom(start,c.snapshot()));
  }
  if(first!=='\\'){
    value=first;
  }else{
    if(c.eof)throw new SyntaxError('unterminated character escape',spanFrom(start,c.snapshot()));
    const esc=c.advanceCodePoint();
    if(esc==="'"||esc==='"'||esc==='\\')value=esc;
    else if(esc==='n')value='\n';
    else if(esc==='r')value='\r';
    else if(esc==='t')value='\t';
    else if(esc==='x'||esc==='u'){
      const digits=esc==='x'?2:4;
      const hexStart=c.snapshot();
      let hex='';
      for(let i=0;i<digits;i++){
        if(c.eof){
          throw new SyntaxError(
            `unterminated ${esc==='x'?'hex':'unicode'} character escape`,
            spanFrom(start,c.snapshot()),
          );
        }
        const h=c.advanceCodePoint();
        if(!/[0-9a-fA-F]/.test(h)){
          throw new SyntaxError(
            `invalid ${esc==='x'?'hex':'unicode'} character escape`,
            spanFrom(hexStart,c.snapshot()),
          );
        }
        hex+=h;
      }
      value=String.fromCodePoint(parseInt(hex,16));
    }else{
      throw new SyntaxError(
        `unsupported character escape \\${esc}`,
        spanFrom(start,c.snapshot()),
      );
    }
  }

  const codePoint=value.codePointAt(0);
  if(
    codePoint===undefined
    ||[...value].length!==1
    ||(codePoint>=0xd800&&codePoint<=0xdfff)
    ||codePoint>0x10ffff
  ){
    throw new SyntaxError(
      'character literal must contain one Unicode scalar value',
      spanFrom(start,c.snapshot()),
    );
  }
  if(c.eof||c.peekCodePoint()!=="'"){
    throw new SyntaxError(
      'character literal must contain exactly one character',
      spanFrom(start,c.snapshot()),
    );
  }
  c.advanceAscii();
  return {
    text:c.source.slice(start.offset,c.offset),
    value,
    span:spanFrom(start,c.snapshot()),
  };
}

function readNumber(c: Cursor): {text:string;span:SourceSpan} {
  const start=c.snapshot();
  if(c.startsWith('0x')||c.startsWith('0X')) {
    c.advanceAscii(2);
    const digitsStart=c.offset;
    while(!c.eof && /[0-9a-fA-F_]/.test(c.peekCodePoint())) c.advanceCodePoint();
    const digits=c.source.slice(digitsStart,c.offset);
    if(!/[0-9a-fA-F]/.test(digits)) throw new SyntaxError('hex literal requires digits',spanFrom(start,c.snapshot()));
  } else if(c.startsWith('0b')||c.startsWith('0B')) {
    c.advanceAscii(2);
    const digitsStart=c.offset;
    while(!c.eof && /[01_]/.test(c.peekCodePoint())) c.advanceCodePoint();
    const digits=c.source.slice(digitsStart,c.offset);
    if(!/[01]/.test(digits)) throw new SyntaxError('binary literal requires digits',spanFrom(start,c.snapshot()));
  } else {
    while(!c.eof && /[0-9_]/.test(c.peekCodePoint())) c.advanceCodePoint();
  }
  return {text:c.source.slice(start.offset,c.offset),span:spanFrom(start,c.snapshot())};
}

function readIdentifier(c: Cursor): {text:string;span:SourceSpan} {
  const start=c.snapshot();
  c.advanceCodePoint();
  while(!c.eof && isIdentifierContinue(c.peekCodePoint())) c.advanceCodePoint();
  while(!c.eof && c.startsWith('.') && c.offset+1<c.source.length) {
    const dot=c.snapshot(); c.advanceAscii();
    if(c.eof || !isIdentifierStart(c.peekCodePoint())) { c.offset=dot.offset;c.line=dot.line;c.column=dot.column;break; }
    c.advanceCodePoint();
    while(!c.eof && isIdentifierContinue(c.peekCodePoint())) c.advanceCodePoint();
  }
  return {text:c.source.slice(start.offset,c.offset),span:spanFrom(start,c.snapshot())};
}

export function lex(source: string): Token[] {
  const c=new Cursor(source),out:Token[]=[];
  let previousEnd=0;
  while(true) {
    const leadingTrivia=readTrivia(c);
    const start=c.snapshot();
    const adjacentToPrevious=out.length>0 && leadingTrivia.length===0 && start.offset===previousEnd;
    if(c.eof) {
      const span=spanFrom(start,start);
      out.push({kind:'eof',text:'<eof>',span,leadingTrivia,adjacentToPrevious});
      return out;
    }
    let token:Token;
    const ch=c.peekCodePoint();
    if(ch==='"') {
      const s=readString(c);
      token={kind:'string',text:s.text,value:s.value,span:s.span,leadingTrivia,adjacentToPrevious};
    } else if(ch==="'") {
      const value=readCharacter(c);
      token={kind:'char',text:value.text,value:value.value,span:value.span,leadingTrivia,adjacentToPrevious};
    } else if(/[0-9]/.test(ch)) {
      const n=readNumber(c);
      token={kind:'number',text:n.text,span:n.span,leadingTrivia,adjacentToPrevious};
    } else if(isIdentifierStart(ch)) {
      const id=readIdentifier(c);
      token={kind:'identifier',text:id.text,span:id.span,leadingTrivia,adjacentToPrevious};
    } else {
      const multi=multiSymbols.find(s=>c.startsWith(s));
      const symStart=c.snapshot();
      if(multi) c.advanceAscii(multi.length); else c.advanceCodePoint();
      token={kind:'symbol',text:c.source.slice(symStart.offset,c.offset),span:spanFrom(symStart,c.snapshot()),leadingTrivia,adjacentToPrevious};
    }
    previousEnd=token.span.end.offset;
    out.push(token);
  }
}

export function significantTokens(source:string):Token[] { return lex(source).filter(t=>t.kind!=='eof'); }
