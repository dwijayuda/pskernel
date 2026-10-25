const root={k:'a'},name=v=>({k:'s',p:root,v}),nat={k:'const',n:name('Nat'),ls:[]};
const decl=(n,v,t=nat)=>({kind:'constant',declaration:{k:'definition',h:{k:'regular',h:'1'},lp:[],n:name(n),s:'safe',t,v}});
const wire=admissions=>JSON.stringify({protocol:'pskernel-lean/1',format:'proofscript-checked-admissions',version:2,admissions});
const one=decl('Kernel.Valid',{k:'nat',v:'1'}),bad=decl('Kernel.Bad',{k:'sort',l:{k:'z'}});
const unsafe=JSON.parse(JSON.stringify(one));unsafe.declaration.s='unsafe';
const meta=JSON.parse(JSON.stringify(one));meta.declaration.v={k:'mvar',i:0};
const badHeight=JSON.parse(JSON.stringify(one));badHeight.declaration.h.h='4294967296';
const fixtures=[
 {id:'nat-accept',input:wire([one]),accepted:true},
 {id:'large-nat-accept',input:wire([decl('Kernel.Huge',{k:'nat',v:String((1n<<256n)+1n)})]),accepted:true},
 {id:'kernel-type-rejection',input:wire([bad]),accepted:false,errorKind:'kernel-rejection'},
 {id:'duplicate-declaration-rejection',input:wire([one,one]),accepted:false,errorKind:'kernel-rejection'},
 {id:'unknown-constant-rejection',input:wire([decl('Kernel.Missing',{k:'const',n:name('NotDeclaredAnywhere'),ls:[]})]),accepted:false,errorKind:'kernel-rejection'},
 {id:'unsafe-refusal',input:wire([unsafe]),accepted:false},
 {id:'metavariable-refusal',input:wire([meta]),accepted:false},
 {id:'height-overflow-refusal',input:wire([badHeight]),accepted:false},
 {id:'malformed-json',input:'{',accepted:false,errorKind:'malformed-request'},
 {id:'wrong-format',input:'{"format":"wrong","version":2,"admissions":[]}',accepted:false},
 {id:'wrong-version',input:'{"format":"proofscript-checked-admissions","version":1,"admissions":[]}',accepted:false,errorKind:'protocol-version'},
 {id:'string-version',input:'{"format":"proofscript-checked-admissions","version":"2","admissions":[]}',accepted:false},
 {id:'unknown-admission',input:wire([{kind:'unknown',declaration:{}}]),accepted:false},
 {id:'truncated-structured-name',input:wire([decl('Kernel.Broken',{k:'const',n:{k:'s'},ls:[]})]),accepted:false}
];

export {fixtures};
