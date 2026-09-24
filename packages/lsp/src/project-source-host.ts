import {readFileSync} from 'node:fs';
import {
  basename,
  extname,
} from 'node:path';
import {
  fileURLToPath,
  pathToFileURL,
} from 'node:url';
import type {
  LanguageServiceProjectHost,
  ProjectResolvedSource,
  TextDocumentSnapshot,
} from '@proofscript/language-service';
import {
  nodeProjectResolutionForEntry,
  resolveLogicalModuleSource,
} from '@proofscript/project/node';
import {sourceKindFromLspDocument} from './source-kind.js';

function filePath(uri:string):string {
  try{
    return fileURLToPath(uri);
  }catch{
    throw new Error(
      "PS_LSP_PROJECT_URI: project imports require file:// URIs, got '"+uri+"'",
    );
  }
}

export function createNodeProjectSourceHost():
LanguageServiceProjectHost {
  return {
    entryModule(snapshot:TextDocumentSnapshot):string {
      const path=filePath(snapshot.uri);
      return basename(path,extname(path));
    },
    resolveImport(
      entry:TextDocumentSnapshot,
      _importer:ProjectResolvedSource,
      logicalModule:string,
    ):ProjectResolvedSource {
      const entryPath=filePath(entry.uri);
      const resolution=nodeProjectResolutionForEntry(entryPath);
      const sourcePath=resolveLogicalModuleSource(
        resolution.sourceRoots,
        logicalModule,
      );
      const uri=pathToFileURL(sourcePath).href;
      return {
        uri,
        sourceKind:sourceKindFromLspDocument(undefined,uri),
        text:readFileSync(sourcePath,'utf8'),
      };
    },
  };
}
