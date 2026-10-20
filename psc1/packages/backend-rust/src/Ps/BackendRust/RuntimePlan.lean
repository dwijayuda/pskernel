import Ps.CompilerIr.Model

/-- Canonical helper catalogue. Dependencies are attached to each implementation,
not inferred from generated source text. Legacy emitters keep their old prelude. -/
structure PsRustRuntimeHelper where
  name : String
  source : String
  nat : Bool
  int : Bool
  traits : Bool
  fromStr : Bool

def psRustRuntimeHelperCatalogue : List PsRustRuntimeHelper :=
  [
    { name := "__ps_nat_lit", source := "fn __ps_nat_lit(text: &str) -> PsNat { PsNat::from_str(text).expect(\"valid generated Nat literal\") }\n", nat := true, int := false, traits := false, fromStr := true },
    { name := "__ps_int_lit", source := "fn __ps_int_lit(text: &str) -> PsInt { PsInt::from_str(text).expect(\"valid generated Int literal\") }\n", nat := false, int := true, traits := false, fromStr := true },
    { name := "__ps_nat_add", source := "fn __ps_nat_add(a: &PsNat, b: &PsNat) -> PsNat { a + b }\n", nat := true, int := false, traits := false, fromStr := false },
    { name := "__ps_nat_sub", source := "fn __ps_nat_sub(a: &PsNat, b: &PsNat) -> PsNat { if a >= b { a - b } else { PsNat::zero() } }\n", nat := true, int := false, traits := true, fromStr := false },
    { name := "__ps_nat_mul", source := "fn __ps_nat_mul(a: &PsNat, b: &PsNat) -> PsNat { a * b }\n", nat := true, int := false, traits := false, fromStr := false },
    { name := "__ps_nat_div", source := "fn __ps_nat_div(a: &PsNat, b: &PsNat) -> PsNat { if b.is_zero() { PsNat::zero() } else { a / b } }\n", nat := true, int := false, traits := true, fromStr := false },
    { name := "__ps_nat_mod", source := "fn __ps_nat_mod(a: &PsNat, b: &PsNat) -> PsNat { if b.is_zero() { a.clone() } else { a % b } }\n", nat := true, int := false, traits := true, fromStr := false },
    { name := "__ps_uint8_of_nat", source := "fn __ps_uint8_of_nat(value: &PsNat) -> u8 { (value % PsNat::from(256u16)).to_u8().expect(\"mod 256 fits u8\") }\n", nat := true, int := false, traits := true, fromStr := false },
    { name := "__ps_int_of_nat", source := "fn __ps_int_of_nat(value: &PsNat) -> PsInt { PsInt::from(value.clone()) }\n", nat := true, int := true, traits := false, fromStr := false },
    { name := "__ps_int_neg_succ", source := "fn __ps_int_neg_succ(value: &PsNat) -> PsInt { -(PsInt::from(value.clone()) + PsInt::from(1u8)) }\n", nat := true, int := true, traits := false, fromStr := false },
    { name := "__ps_int_neg", source := "fn __ps_int_neg(value: &PsInt) -> PsInt { -value }\n", nat := false, int := true, traits := false, fromStr := false },
    { name := "__ps_int_add", source := "fn __ps_int_add(a: &PsInt, b: &PsInt) -> PsInt { a + b }\n", nat := false, int := true, traits := false, fromStr := false },
    { name := "__ps_int_sub", source := "fn __ps_int_sub(a: &PsInt, b: &PsInt) -> PsInt { a - b }\n", nat := false, int := true, traits := false, fromStr := false },
    { name := "__ps_int_mul", source := "fn __ps_int_mul(a: &PsInt, b: &PsInt) -> PsInt { a * b }\n", nat := false, int := true, traits := false, fromStr := false },
    { name := "__ps_char_of_nat", source := "fn __ps_char_of_nat(value: &PsNat) -> char { match value.to_u32().and_then(char::from_u32) { Some(c) => c, None => '\\0' } }\n", nat := true, int := false, traits := true, fromStr := false },
    { name := "__ps_char_to_nat", source := "fn __ps_char_to_nat(value: char) -> PsNat { PsNat::from(value as u32) }\n", nat := true, int := false, traits := false, fromStr := false },
    { name := "__ps_string_push", source := "fn __ps_string_push(left: &String, right: char) -> String { let mut out = left.clone(); out.push(right); out }\n", nat := false, int := false, traits := false, fromStr := false },
    { name := "__ps_string_singleton", source := "fn __ps_string_singleton(value: char) -> String { value.to_string() }\n", nat := false, int := false, traits := false, fromStr := false },
    { name := "__ps_string_length", source := "fn __ps_string_length(value: &String) -> PsNat { PsNat::from(value.chars().count()) }\n", nat := true, int := false, traits := false, fromStr := false },
    { name := "__ps_string_append", source := "fn __ps_string_append(left: &String, right: &String) -> String { let mut out = left.clone(); out.push_str(right); out }\n", nat := false, int := false, traits := false, fromStr := false },
    { name := "__ps_string_utf8_byte_size", source := "fn __ps_string_utf8_byte_size(value: &String) -> PsNat { PsNat::from(value.len()) }\n", nat := true, int := false, traits := false, fromStr := false },
    { name := "__ps_string_next", source := "fn __ps_string_next(value: &String, position: &PsNat) -> PsNat { let i = match position.to_usize() { Some(value) => value, None => return position.clone() + PsNat::from(1u8) }; match value.get(i..) { Some(rest) => match rest.chars().next() { Some(c) => position.clone() + PsNat::from(c.len_utf8()), None => position.clone() + PsNat::from(1u8) }, None => position.clone() + PsNat::from(1u8) } }\n", nat := true, int := false, traits := true, fromStr := false },
    { name := "__ps_string_get", source := "fn __ps_string_get(value: &String, position: &PsNat) -> char { let i = match position.to_usize() { Some(value) => value, None => return 'A' }; match value.get(i..) { Some(rest) => match rest.chars().next() { Some(c) => c, None => 'A' }, None => 'A' } }\n", nat := true, int := false, traits := true, fromStr := false },
    { name := "__ps_string_at_end", source := "fn __ps_string_at_end(value: &String, position: &PsNat) -> bool { position >= &PsNat::from(value.len()) }\n", nat := true, int := false, traits := false, fromStr := false },
    { name := "__ps_string_extract", source := "fn __ps_string_extract(value: &String, begin: &PsNat, end: &PsNat) -> String { if begin >= end { return String::new(); } let i = match begin.to_usize() { Some(value) => value, None => return String::new() }; let rest = match value.get(i..) { Some(value) => value, None => return String::new() }; let mut index = begin.clone(); let mut out = String::new(); for c in rest.chars() { if &index == end { return out; } out.push(c); index += PsNat::from(c.len_utf8()); } out }\n", nat := true, int := false, traits := true, fromStr := false },
    { name := "__ps_string_eq", source := "fn __ps_string_eq(left: &String, right: &String) -> bool { left == right }\n", nat := false, int := false, traits := false, fromStr := false },
    { name := "__ps_array_empty_with_capacity", source := "fn __ps_array_empty_with_capacity<T>(_capacity: &PsNat) -> Vec<T> { Vec::new() }\n", nat := true, int := false, traits := false, fromStr := false },
    { name := "__ps_array_size", source := "fn __ps_array_size<T>(value: &Vec<T>) -> PsNat { PsNat::from(value.len()) }\n", nat := true, int := false, traits := false, fromStr := false },
    { name := "__ps_array_push", source := "fn __ps_array_push<T: Clone>(array: &Vec<T>, value: &T) -> Vec<T> { let mut out = array.clone(); out.push(value.clone()); out }\n", nat := false, int := false, traits := false, fromStr := false },
    { name := "__ps_array_get", source := "fn __ps_array_get<T: Clone>(array: &Vec<T>, index: &PsNat) -> T { let i = index.to_usize().expect(\"proved Array index fits usize\"); array[i].clone() }\n", nat := true, int := false, traits := true, fromStr := false },
    { name := "__ps_array_get_d", source := "fn __ps_array_get_d<T: Clone>(array: &Vec<T>, index: &PsNat, fallback: &T) -> T { if index >= &PsNat::from(array.len()) { fallback.clone() } else { array[index.to_usize().expect(\"bounded Array index fits usize\")].clone() } }\n", nat := true, int := false, traits := true, fromStr := false },
    { name := "__ps_array_set", source := "fn __ps_array_set<T: Clone>(array: &Vec<T>, index: &PsNat, value: &T) -> Vec<T> { let mut out = array.clone(); let i = index.to_usize().expect(\"proved Array index fits usize\"); out[i] = value.clone(); out }\n", nat := true, int := false, traits := true, fromStr := false },
    { name := "__ps_array_set_if_in_bounds", source := "fn __ps_array_set_if_in_bounds<T: Clone>(array: &Vec<T>, index: &PsNat, value: &T) -> Vec<T> { if index >= &PsNat::from(array.len()) { array.clone() } else { let mut out = array.clone(); let i = index.to_usize().expect(\"bounded Array index fits usize\"); out[i] = value.clone(); out } }\n", nat := true, int := false, traits := true, fromStr := false },
    { name := "__ps_array_map", source := "fn __ps_array_map<A: Clone, B>(f: std::rc::Rc<dyn Fn(A) -> B>, array: &Vec<A>) -> Vec<B> { array.iter().cloned().map(|value| f(value)).collect() }\n", nat := false, int := false, traits := false, fromStr := false },
    { name := "__ps_array_foldl", source := "fn __ps_array_foldl<A: Clone, B: Clone>(f: std::rc::Rc<dyn Fn(B, A) -> B>, init: &B, array: &Vec<A>, start: &PsNat, stop: &PsNat) -> B { let size = PsNat::from(array.len()); let end = if stop <= &size { stop.clone() } else { size }; let mut index = start.clone(); let mut acc = init.clone(); while index < end { let i = index.to_usize().expect(\"bounded Array fold index fits usize\"); acc = f(acc, array[i].clone()); index += PsNat::from(1u8); } acc }\n", nat := true, int := false, traits := true, fromStr := false }
  ]

private def intrinsicHelpers : PsVerifiedIrIntrinsic → List String
  | .natAdd => ["__ps_nat_add"]
  | .natSub => ["__ps_nat_sub"]
  | .natMul => ["__ps_nat_mul"]
  | .natDiv => ["__ps_nat_div"]
  | .natMod => ["__ps_nat_mod"]
  | .intOfNat => ["__ps_int_of_nat"]
  | .intNegSucc => ["__ps_int_neg_succ"]
  | .intNeg => ["__ps_int_neg"]
  | .intAdd => ["__ps_int_add"]
  | .intSub => ["__ps_int_sub"]
  | .intMul => ["__ps_int_mul"]
  | .charOfNat => ["__ps_char_of_nat"]
  | .charToNat => ["__ps_char_to_nat"]
  | .stringPush => ["__ps_string_push"]
  | .stringSingleton => ["__ps_string_singleton"]
  | .stringLength => ["__ps_string_length"]
  | .stringAppend => ["__ps_string_append"]
  | .stringUtf8ByteSize => ["__ps_string_utf8_byte_size"]
  | .stringNext => ["__ps_string_next"]
  | .stringGet => ["__ps_string_get"]
  | .stringAtEnd => ["__ps_string_at_end"]
  | .stringExtract => ["__ps_string_extract"]
  | .stringEq => ["__ps_string_eq"]
  | .arrayEmptyWithCapacity => ["__ps_array_empty_with_capacity"]
  | .arraySize => ["__ps_array_size"]
  | .arrayPush => ["__ps_array_push"]
  | .arrayGet => ["__ps_array_get"]
  | .arrayGetD => ["__ps_array_get_d"]
  | .arraySet => ["__ps_array_set"]
  | .arraySetIfInBounds => ["__ps_array_set_if_in_bounds"]
  | .arrayMap => ["__ps_array_map"]
  | .arrayFoldl => ["__ps_array_foldl"]
  | _ => []

private partial def typeRequirements : PsVerifiedIrType → List String
  | .primitive .nat => ["@nat"]
  | .primitive .int => ["@int"]
  | .named _ arguments => arguments.flatMap typeRequirements
  | .function parameters result => parameters.flatMap typeRequirements ++ typeRequirements result
  | _ => []

private partial def exprRequirements : PsVerifiedIrExpr → List String
  | .literal (.natural _) => ["@nat", "__ps_nat_lit"]
  | .literal (.integer _) => ["@int", "__ps_int_lit"]
  | .literal _ | .var _ => []
  | .intrinsic op types args =>
      intrinsicHelpers op ++ types.flatMap typeRequirements ++ args.flatMap exprRequirements
  | .lambda parameters result body =>
      parameters.flatMap (fun p => typeRequirements p.type) ++
      typeRequirements result ++ exprRequirements body
  | .call fn types args =>
      exprRequirements fn ++ types.flatMap typeRequirements ++ args.flatMap exprRequirements
  | .letE _ type value body =>
      typeRequirements type ++ exprRequirements value ++ exprRequirements body
  | .ifE condition yes no =>
      exprRequirements condition ++ exprRequirements yes ++ exprRequirements no
  | .record _ types fields | .constructor _ _ types fields =>
      types.flatMap typeRequirements ++ fields.flatMap (fun field => exprRequirements field.2)
  | .projection _ types value _ => types.flatMap typeRequirements ++ exprRequirements value
  | .matchE _ types value alternatives =>
      types.flatMap typeRequirements ++ exprRequirements value ++ alternatives.flatMap (fun alternative =>
        alternative.2.1.flatMap (fun binding => typeRequirements binding.type) ++
        exprRequirements alternative.2.2)

private def moduleRequirements (source : PsVerifiedIrModule) : List String :=
  source.structures.flatMap (fun value => value.fields.flatMap (fun field => typeRequirements field.type)) ++
  source.inductives.flatMap (fun value => value.constructors.flatMap (fun ctor =>
    ctor.fields.flatMap (fun field => typeRequirements field.type))) ++
  source.declarations.flatMap (fun value =>
    value.parameters.flatMap (fun p => typeRequirements p.type) ++
    typeRequirements value.resultType ++ exprRequirements value.body)

structure PsRustRuntimePlan where
  source : String
  requirements : List String

def psRustPlanRuntime (source : PsVerifiedIrModule) : PsRustRuntimePlan :=
  let requested := moduleRequirements source
  let helpers := psRustRuntimeHelperCatalogue.filter (fun item => requested.contains item.name)
  let needsNat := requested.contains "@nat" || helpers.any (fun item => item.nat)
  let needsInt := requested.contains "@int" || helpers.any (fun item => item.int)
  let needsTraits := helpers.any (fun item => item.traits)
  let needsFromStr := helpers.any (fun item => item.fromStr)
  let imports :=
    (if needsNat then "use num_bigint::BigUint as PsNat;\n" else "") ++
    (if needsInt then "use num_bigint::BigInt as PsInt;\n" else "") ++
    (if needsTraits then "use num_traits::{ToPrimitive, Zero};\n" else "") ++
    (if needsFromStr then "use std::str::FromStr;\n" else "")
  {
    source := imports ++ String.intercalate "" (helpers.map (fun item => item.source))
    requirements :=
      (if needsNat || needsInt then ["num-bigint@0.4.6"] else []) ++
      (if needsTraits then ["num-traits@0.2.19"] else []) ++
      helpers.map (fun item => item.name)
  }
