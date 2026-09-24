import {
  LEAN434_SOURCE_GITHASH,
  LEAN434_SOURCE_VERSION,
} from './lean4.js';

export type Lean434MetadataExternEntry=
  |{readonly kind:'adhoc';readonly backend:string}
  |{readonly kind:'inline';readonly backend:string;readonly pattern:string}
  |{readonly kind:'standard';readonly backend:string;readonly symbol:string}
  |{readonly kind:'opaque'};

export interface Lean434MetadataExtern {
  readonly declaration:string;
  readonly entries:readonly Lean434MetadataExternEntry[];
}

export interface Lean434MetadataImplementedBy {
  readonly declaration:string;
  readonly implementation:string;
}

export interface Lean434MetadataInitializer {
  readonly module:string;
  readonly moduleIndex:number;
  readonly kind:'builtin'|'regular';
  readonly source:'olean'|'ir';
  readonly declaration:string;
  readonly initFunction:string|null;
  readonly ioUnit:boolean;
}

export interface Lean434RuntimeMetadataDocument {
  readonly format:'proofscript-lean434-runtime-metadata';
  readonly formatVersion:1;
  readonly lean:{
    readonly version:string;
    readonly githash:string;
  };
  readonly module:string;
  readonly externs:readonly Lean434MetadataExtern[];
  readonly implementedBy:readonly Lean434MetadataImplementedBy[];
  readonly initializers:readonly Lean434MetadataInitializer[];
}

export class Lean434RuntimeMetadataError extends Error{
  constructor(message:string){
    super(message);
    this.name='Lean434RuntimeMetadataError';
  }
}

function record(value:unknown,where:string):Record<string,unknown>{
  if(
    typeof value!=='object'
    ||value===null
    ||Array.isArray(value)
  ){
    throw new Lean434RuntimeMetadataError(where+' must be an object');
  }
  return value as Record<string,unknown>;
}

function stringField(
  object:Record<string,unknown>,
  name:string,
  where:string,
):string{
  const value=object[name];
  if(typeof value!=='string'){
    throw new Lean434RuntimeMetadataError(
      where+'.'+name+' must be a string',
    );
  }
  return value;
}

function integerField(
  object:Record<string,unknown>,
  name:string,
  where:string,
):number{
  const value=object[name];
  if(
    typeof value!=='number'
    ||!Number.isInteger(value)
    ||value<0
  ){
    throw new Lean434RuntimeMetadataError(
      where+'.'+name+' must be a non-negative integer',
    );
  }
  return value;
}

function booleanField(
  object:Record<string,unknown>,
  name:string,
  where:string,
):boolean{
  const value=object[name];
  if(typeof value!=='boolean'){
    throw new Lean434RuntimeMetadataError(
      where+'.'+name+' must be a boolean',
    );
  }
  return value;
}

function arrayField(
  object:Record<string,unknown>,
  name:string,
  where:string,
):readonly unknown[]{
  const value=object[name];
  if(!Array.isArray(value)){
    throw new Lean434RuntimeMetadataError(
      where+'.'+name+' must be an array',
    );
  }
  return value;
}

function parseExternEntry(
  value:unknown,
  where:string,
):Lean434MetadataExternEntry{
  const object=record(value,where);
  const kind=stringField(object,'kind',where);
  switch(kind){
    case 'adhoc':
      return {
        kind,
        backend:stringField(object,'backend',where),
      };
    case 'inline':
      return {
        kind,
        backend:stringField(object,'backend',where),
        pattern:stringField(object,'pattern',where),
      };
    case 'standard':
      return {
        kind,
        backend:stringField(object,'backend',where),
        symbol:stringField(object,'symbol',where),
      };
    case 'opaque':
      return {kind};
    default:
      throw new Lean434RuntimeMetadataError(
        where+".kind has unsupported value '"+kind+"'",
      );
  }
}

function parseExtern(
  value:unknown,
  where:string,
):Lean434MetadataExtern{
  const object=record(value,where);
  return {
    declaration:stringField(object,'declaration',where),
    entries:arrayField(object,'entries',where).map(
      (entry,index)=>parseExternEntry(
        entry,
        where+'.entries['+index+']',
      ),
    ),
  };
}

function parseImplementedBy(
  value:unknown,
  where:string,
):Lean434MetadataImplementedBy{
  const object=record(value,where);
  return {
    declaration:stringField(object,'declaration',where),
    implementation:stringField(object,'implementation',where),
  };
}

function parseInitializer(
  value:unknown,
  where:string,
):Lean434MetadataInitializer{
  const object=record(value,where);
  const kind=stringField(object,'kind',where);
  if(kind!=='builtin'&&kind!=='regular'){
    throw new Lean434RuntimeMetadataError(
      where+".kind must be 'builtin' or 'regular'",
    );
  }
  const source=stringField(object,'source',where);
  if(source!=='olean'&&source!=='ir'){
    throw new Lean434RuntimeMetadataError(
      where+".source must be 'olean' or 'ir'",
    );
  }
  const initFunctionValue=object.initFunction;
  if(
    initFunctionValue!==null
    &&typeof initFunctionValue!=='string'
  ){
    throw new Lean434RuntimeMetadataError(
      where+'.initFunction must be string or null',
    );
  }
  const ioUnit=booleanField(object,'ioUnit',where);
  if(ioUnit!==(initFunctionValue===null)){
    throw new Lean434RuntimeMetadataError(
      where+' has inconsistent ioUnit/initFunction metadata',
    );
  }
  return {
    module:stringField(object,'module',where),
    moduleIndex:integerField(object,'moduleIndex',where),
    kind,
    source,
    declaration:stringField(object,'declaration',where),
    initFunction:initFunctionValue,
    ioUnit,
  };
}

function assertUnique(
  values:readonly string[],
  label:string,
):void{
  const seen=new Set<string>();
  for(const value of values){
    if(seen.has(value)){
      throw new Lean434RuntimeMetadataError(
        'duplicate '+label+": '"+value+"'",
      );
    }
    seen.add(value);
  }
}

export function parseLean434RuntimeMetadata(
  input:unknown,
):Lean434RuntimeMetadataDocument{
  const value=typeof input==='string'?JSON.parse(input) as unknown:input;
  const object=record(value,'metadata');
  if(object.format!=='proofscript-lean434-runtime-metadata'){
    throw new Lean434RuntimeMetadataError('unsupported metadata format');
  }
  if(object.formatVersion!==1){
    throw new Lean434RuntimeMetadataError(
      'unsupported metadata format version',
    );
  }
  const lean=record(object.lean,'metadata.lean');
  const leanVersion=stringField(lean,'version','metadata.lean');
  const leanGitHash=stringField(lean,'githash','metadata.lean');
  if(leanVersion!==LEAN434_SOURCE_VERSION){
    throw new Lean434RuntimeMetadataError(
      'Lean version mismatch: expected '+
      LEAN434_SOURCE_VERSION+', got '+leanVersion,
    );
  }
  if(leanGitHash!==LEAN434_SOURCE_GITHASH){
    throw new Lean434RuntimeMetadataError(
      'Lean githash mismatch: expected '+
      LEAN434_SOURCE_GITHASH+', got '+leanGitHash,
    );
  }

  const externs=arrayField(object,'externs','metadata').map(
    (entry,index)=>parseExtern(entry,'metadata.externs['+index+']'),
  );
  const implementedBy=arrayField(
    object,
    'implementedBy',
    'metadata',
  ).map(
    (entry,index)=>parseImplementedBy(
      entry,
      'metadata.implementedBy['+index+']',
    ),
  );
  const rawInitializers=arrayField(
    object,
    'initializers',
    'metadata',
  ).map(
    (entry,index)=>parseInitializer(
      entry,
      'metadata.initializers['+index+']',
    ),
  );

  assertUnique(
    externs.map((entry)=>entry.declaration),
    'extern declaration',
  );
  assertUnique(
    implementedBy.map((entry)=>entry.declaration),
    'implemented_by declaration',
  );

  // Lean combines regular initializer entries from .olean and .ir, removing
  // duplicates while preserving first occurrence order. Mirror that here.
  const seenInitializers=new Set<string>();
  const initializers:Lean434MetadataInitializer[]=[];
  for(const entry of rawInitializers){
    const key=[
      entry.moduleIndex,
      entry.kind,
      entry.declaration,
      entry.initFunction??'',
    ].join('\u0000');
    if(seenInitializers.has(key))continue;
    seenInitializers.add(key);
    initializers.push(entry);
  }

  return {
    format:'proofscript-lean434-runtime-metadata',
    formatVersion:1,
    lean:{
      version:leanVersion,
      githash:leanGitHash,
    },
    module:stringField(object,'module','metadata'),
    externs,
    implementedBy,
    initializers,
  };
}

export class Lean434RuntimeMetadataIndex{
  readonly externsByDeclaration:ReadonlyMap<string,Lean434MetadataExtern>;
  readonly implementedByByDeclaration:
    ReadonlyMap<string,Lean434MetadataImplementedBy>;

  constructor(readonly document:Lean434RuntimeMetadataDocument){
    this.externsByDeclaration=new Map(
      document.externs.map(
        (entry)=>[entry.declaration,entry] as const,
      ),
    );
    this.implementedByByDeclaration=new Map(
      document.implementedBy.map(
        (entry)=>[entry.declaration,entry] as const,
      ),
    );
  }

  externFor(
    declaration:string,
  ):Lean434MetadataExtern|undefined{
    return this.externsByDeclaration.get(declaration);
  }

  implementedByFor(
    declaration:string,
  ):Lean434MetadataImplementedBy|undefined{
    return this.implementedByByDeclaration.get(declaration);
  }

  initializersForModule(
    module:string,
  ):readonly Lean434MetadataInitializer[]{
    return this.document.initializers.filter(
      (entry)=>entry.module===module,
    );
  }
}
