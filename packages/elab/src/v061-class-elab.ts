import type {V061ClassDeclaration} from '@proofscript/syntax';
import {Environment} from 'lean-ts-kernel';
import type {CheckedCoreStructure} from '@proofscript/checked-core';
import {
  elaborateV061StructureDeclaration,
} from './v061-structure-elab.js';

export interface ElaboratedV061Class {
  readonly declaration:ReturnType<
    typeof elaborateV061StructureDeclaration
  >['declaration'];
  readonly structure:CheckedCoreStructure;
}

export function elaborateV061ClassDeclaration(
  source:V061ClassDeclaration,
  environment:Environment,
):ElaboratedV061Class {
  return elaborateV061StructureDeclaration(
    {
      kind:'structure',
      name:source.name,
      params:source.params,
      fields:source.fields,
      terminatedBySemicolon:source.terminatedBySemicolon,
      span:source.span,
    },
    environment,
  );
}
