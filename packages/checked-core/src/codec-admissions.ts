import type {BinderInfo} from 'lean-ts-kernel';
import type {
  CheckedCoreAdmission,
  CheckedCoreInstance,
  CheckedCoreStructure,
} from './index.js';
import {
  codecArray,
  codecBool,
  codecNat,
  codecObject,
  codecString,
  decodeCodecName,
  encodeCodecName,
} from './codec-base.js';
import {
  decodeCodecAxiom,
  decodeCodecDefinition,
  decodeCodecInductive,
  decodeCodecTheorem,
  encodeCodecAxiom,
  encodeCodecDefinition,
  encodeCodecInductive,
  encodeCodecTheorem,
} from './codec-declaration.js';

export interface CheckedCoreAdmissionsPayload {
  readonly format:'proofscript-checked-admissions';
  readonly version:1|2;
  readonly admissions:readonly unknown[];
}

function binder(value:unknown):BinderInfo {
  if(value==='default'||value==='implicit'||value==='strictImplicit'||value==='instImplicit')return value;
  throw new Error('checked-core codec: invalid structure binder');
}
function encodeStructure(value:CheckedCoreStructure):unknown {
  return {
    name:encodeCodecName(value.name),
    constructor:encodeCodecName(value.constructor),
    fields:value.fields.map((field)=>({
      name:field.name,index:field.index,binderInfo:field.binderInfo,
    })),
  };
}
function decodeStructure(value:unknown):CheckedCoreStructure {
  const o=codecObject(value,'structure');
  return {
    name:decodeCodecName(o.name),
    constructor:decodeCodecName(o.constructor),
    fields:codecArray(o.fields,'structure.fields').map((raw)=>{
      const field=codecObject(raw,'structure.field');
      return {
        name:codecString(field.name,'structure.field.name'),
        index:codecNat(field.index,'structure.field.index'),
        binderInfo:binder(field.binderInfo),
      };
    }),
  };
}
function encodeInstance(value:CheckedCoreInstance):unknown {
  return {
    name:encodeCodecName(value.name),
    className:encodeCodecName(value.className),
    anonymous:value.anonymous,
  };
}
function decodeInstance(value:unknown):CheckedCoreInstance {
  const o=codecObject(value,'instance');
  return {
    name:decodeCodecName(o.name),
    className:decodeCodecName(o.className),
    anonymous:codecBool(o.anonymous,'instance.anonymous'),
  };
}

function encodeAdmission(admission:CheckedCoreAdmission):unknown {
  switch(admission.kind){
    case 'external':
      return {
        kind:'external',
        declaration:encodeCodecAxiom(admission.declaration),
        binding:{
          source:admission.binding.source,
          importedName:admission.binding.importedName,
        },
      };
    case 'constant':
      return admission.declaration.kind==='definition'
        ?{kind:'constant',declaration:encodeCodecDefinition(admission.declaration)}
        :{kind:'constant',declaration:encodeCodecTheorem(admission.declaration)};
    case 'inductive':
      return {kind:'inductive',declaration:encodeCodecInductive(admission.declaration)};
    case 'structure':
    case 'class':
      return {
        kind:admission.kind,
        declaration:encodeCodecInductive(admission.declaration),
        structure:encodeStructure(admission.structure),
      };
    case 'instance':
      return {
        kind:'instance',
        declaration:encodeCodecDefinition(admission.declaration),
        instance:encodeInstance(admission.instance),
      };
  }
}
function decodeAdmission(value:unknown):CheckedCoreAdmission {
  const o=codecObject(value,'admission');
  switch(o.kind){
    case 'external':{
      const binding=codecObject(o.binding,'external.binding');
      return {
        kind:'external',
        declaration:decodeCodecAxiom(o.declaration),
        binding:{
          source:codecString(binding.source,'external.binding.source'),
          importedName:codecString(
            binding.importedName,
            'external.binding.importedName',
          ),
        },
      };
    }
    case 'constant':{
      const d=codecObject(o.declaration,'constant.declaration');
      return {
        kind:'constant',
        declaration:d.k==='definition'
          ?decodeCodecDefinition(d)
          :decodeCodecTheorem(d),
      };
    }
    case 'inductive':
      return {kind:'inductive',declaration:decodeCodecInductive(o.declaration)};
    case 'structure':
    case 'class':
      return {
        kind:o.kind,
        declaration:decodeCodecInductive(o.declaration),
        structure:decodeStructure(o.structure),
      };
    case 'instance':
      return {
        kind:'instance',
        declaration:decodeCodecDefinition(o.declaration),
        instance:decodeInstance(o.instance),
      };
    default:
      throw new Error('checked-core codec: invalid admission kind');
  }
}

export function encodeCheckedCoreAdmissions(
  admissions:readonly CheckedCoreAdmission[],
):CheckedCoreAdmissionsPayload {
  return {
    format:'proofscript-checked-admissions',
    version:2,
    admissions:admissions.map(encodeAdmission),
  };
}

export function decodeCheckedCoreAdmissions(
  value:unknown,
):readonly CheckedCoreAdmission[] {
  const o=codecObject(value,'payload');
  if(
    o.format!=='proofscript-checked-admissions'
    ||(o.version!==1&&o.version!==2)
  ){
    throw new Error('checked-core codec: unsupported payload format/version');
  }
  const admissions=codecArray(
    o.admissions,
    'payload.admissions',
  ).map(decodeAdmission);
  if(
    o.version===1
    &&admissions.some((admission)=>admission.kind==='external')
  ){
    throw new Error(
      'checked-core codec: external admissions require payload version 2',
    );
  }
  return admissions;
}
