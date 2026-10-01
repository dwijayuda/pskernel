import * as ts from 'typescript';

export interface TypeScriptCompileResult {
  readonly javascript:string;
  readonly declaration:string;
  readonly sourceMap?:string;
  readonly diagnostics:readonly string[];
  readonly typescriptVersion:string;
}

export function compileTypeScript(source:string,fileName='module.ts'):TypeScriptCompileResult {
  const options:ts.CompilerOptions={
    target:ts.ScriptTarget.ES2022,
    module:ts.ModuleKind.ES2022,
    moduleResolution:ts.ModuleResolutionKind.Bundler,
    strict:true,
    declaration:true,
    sourceMap:true,
    noEmitOnError:true,
    skipLibCheck:true,
  };
  const defaultHost=ts.createCompilerHost(options);
  const outputs=new Map<string,string>();
  const host:ts.CompilerHost={
    ...defaultHost,
    fileExists:(name)=>name===fileName||defaultHost.fileExists(name),
    readFile:(name)=>name===fileName?source:defaultHost.readFile(name),
    getSourceFile:(name,languageVersion,onError,shouldCreateNewSourceFile)=>{
      if(name===fileName)return ts.createSourceFile(name,source,languageVersion,true,ts.ScriptKind.TS);
      return defaultHost.getSourceFile(name,languageVersion,onError,shouldCreateNewSourceFile);
    },
    writeFile:(name,text)=>{outputs.set(name,text);},
  };
  const program=ts.createProgram([fileName],options,host);
  const before=ts.getPreEmitDiagnostics(program);
  const emitted=program.emit();
  const diagnostics=[...before,...emitted.diagnostics].map((diagnostic)=>{
    const message=ts.flattenDiagnosticMessageText(diagnostic.messageText,'\n');
    if(diagnostic.file&&diagnostic.start!==undefined){
      const pos=diagnostic.file.getLineAndCharacterOfPosition(diagnostic.start);
      return diagnostic.file.fileName+':'+(pos.line+1)+':'+(pos.character+1)+' TS'+diagnostic.code+': '+message;
    }
    return 'TS'+diagnostic.code+': '+message;
  });
  if(diagnostics.length>0)throw new Error('PS_TS_COMPILE_FAILED:\n'+diagnostics.join('\n'));

  const javascript=[...outputs.entries()].find(([name])=>name.endsWith('.js'))?.[1];
  const declaration=[...outputs.entries()].find(([name])=>name.endsWith('.d.ts'))?.[1];
  const sourceMap=[...outputs.entries()].find(([name])=>name.endsWith('.js.map'))?.[1];
  if(javascript===undefined||declaration===undefined)throw new Error('PS_TS_COMPILE_MISSING_OUTPUT');

  return {
    javascript,
    declaration,
    ...(sourceMap===undefined?{}:{sourceMap}),
    diagnostics,
    typescriptVersion:ts.version,
  };
}
