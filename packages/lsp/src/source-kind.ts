import type {
  DocumentSourceKind,
} from '@proofscript/language-service';

export function sourceKindFromLspDocument(
  languageId:string|undefined,
  uri:string,
):DocumentSourceKind {
  if(languageId==='proofscript')return 'proofscript';
  if(languageId==='proofscript-lean')return 'lean-subset';
  const normalized=uri.toLowerCase();
  if(normalized.endsWith('.ps')||normalized.endsWith('.psx'))return 'proofscript';
  if(normalized.endsWith('.lean'))return 'lean-subset';
  throw new Error(
    "PS_LSP_SOURCE_KIND: unsupported document language '"+String(languageId)+
    "' for '"+uri+"'",
  );
}
