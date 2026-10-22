export const corpus = [
  { id: 'lean-modules', grammar: 'lean', assurance: 'checked', entry: 'Entry',
    sources: [{ module: 'Lib', text: 'namespace Lib\ndef base : Nat := 40\nend Lib\n' },
      { module: 'Entry', text: 'import Lib\ndef Ps.Internal.Corpus.hidden : Nat := Lib.base\ndef answer : Nat := Ps.Internal.Corpus.hidden + 2\n' }],
    consumer: "if (m.answer !== 42n || Object.keys(m).join(',') !== 'answer') throw Error('module/private ownership');" },
  { id: 'ps-integer-unicode', grammar: 'ps', assurance: 'checked', entry: 'Entry',
    sources: [{ module: 'Entry', text: 'def huge : Int := -9007199254740993123456789\ndef text : String := "λ🙂"\n' }],
    consumer: "if (m.huge !== -9007199254740993123456789n || m.text !== 'λ🙂') throw Error('integer/unicode');" },
  { id: 'ps-list-literal', grammar: 'ps', assurance: 'checked', entry: 'Entry',
    sources: [{ module: 'Entry', text: 'def answer(flag : Bool) : Nat :=\n let values : List(Nat) := if (flag) { [7, 11] } else { [] }\n match values with { | List.nil => 0 | List.cons head rest => head }\n' }],
    consumer: "if (m.answer(false) !== 0n || m.answer(true) !== 7n) throw Error('PS list literal');" },
  { id: 'lean-handler-pattern', grammar: 'lean', assurance: 'checked', entry: 'Entry',
    sources: [{ module: 'Entry', text: 'def Ps.Internal.Corpus.guarded (fail : Bool) : Except Nat Nat := do\n  try\n    if fail then throw 7 else pure 3\n  catch error =>\n    pure (error + 1)\ndef observe (fail : Bool) : Nat :=\n  match Ps.Internal.Corpus.guarded fail with\n  | Except.ok value => value\n  | Except.error error => error\n' }],
    consumer: "if (m.observe(false) !== 3n || m.observe(true) !== 8n) throw Error('handler/pattern');" },
  { id: 'lean-ordinary-loop', grammar: 'lean', assurance: 'ordinary-checked', entry: 'Entry',
    sources: [{ module: 'Entry', text: 'partial def answer (limit : Nat) : Id Nat := do\n  let mut value : Nat := 0\n  while Nat.blt value limit do\n    value := Nat.succ value\n  return value\n' }],
    consumer: "if (m.answer(5n) !== 5n) throw Error('ordinary loop');" }
];
export const observedExpressions = {
  'lean-modules':'({answer:String(m.answer),exports:Object.keys(m)})',
  'ps-integer-unicode':'({huge:String(m.huge),text:m.text})',
  'ps-list-literal':'({empty:String(m.answer(false)),first:String(m.answer(true))})',
  'lean-handler-pattern':'({normal:String(m.observe(false)),caught:String(m.observe(true))})',
  'lean-ordinary-loop':'({zero:String(m.answer(0n)),five:String(m.answer(5n))})'
};
export const expectedObservations = {
  'lean-modules':{answer:'42',exports:['answer']},
  'ps-integer-unicode':{huge:'-9007199254740993123456789',text:'λ🙂'},
  'ps-list-literal':{empty:'0',first:'7'},
  'lean-handler-pattern':{normal:'3',caught:'8'},
  'lean-ordinary-loop':{zero:'0',five:'5'}
};

export const refusals = [
 {id:'malformed-list',grammar:'ps',assurance:'checked',source:'def value : List(Nat) := [1,,2]\n',phase:'parse'},
 {id:'wrong-body',grammar:'lean',assurance:'checked',source:'def bad : Nat := true\n',phase:'elaboration'},
 {id:'missing-import',grammar:'ps',assurance:'checked',source:'import Missing\ndef value : Nat := 1\n',phase:'capture'},
 {id:'checked-partial',grammar:'lean',assurance:'checked',source:'partial def spin (n : Nat) : Nat := spin n\n',phase:'preparation'},
 {id:'verified',grammar:'ps',assurance:'verified',source:'def value : Nat := 1\n',phase:'wire'}
];
export const rustObservations = {
 'lean-modules':'println!("{{\\\"answer\\\":\\\"{}\\\",\\\"exports\\\":[\\\"answer\\\"]}}", answer());',
 'ps-integer-unicode':'println!("{{\\\"huge\\\":\\\"{}\\\",\\\"text\\\":\\\"{}\\\"}}", huge(), text());',
 'ps-list-literal':'println!("{{\\\"empty\\\":\\\"{}\\\",\\\"first\\\":\\\"{}\\\"}}", answer(false), answer(true));',
 'lean-handler-pattern':'println!("{{\\\"normal\\\":\\\"{}\\\",\\\"caught\\\":\\\"{}\\\"}}", observe(false), observe(true));',
 'lean-ordinary-loop':'println!("{{\\\"zero\\\":\\\"{}\\\",\\\"five\\\":\\\"{}\\\"}}", answer(PsNat::from(0u8)), answer(PsNat::from(5u8)));'
};
