import Ps.CompilerIr.Model
import Ps.Foundation.List
import Ps.Foundation.Name
import Ps.Foundation.Text

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

def psRustRuntimeConcatMap {alpha beta : Type}
    (convert : alpha -> List beta) (values : List alpha) : List beta :=
  match values with
  | List.nil => List.nil
  | List.cons value rest =>
      psListAppend (convert value) (psRustRuntimeConcatMap convert rest)

private def intrinsicHelpers (operation : PsVerifiedIrIntrinsic) : List String :=
  match operation with
  | PsVerifiedIrIntrinsic.natAdd => ["__ps_nat_add"]
  | PsVerifiedIrIntrinsic.natSub => ["__ps_nat_sub"]
  | PsVerifiedIrIntrinsic.natMul => ["__ps_nat_mul"]
  | PsVerifiedIrIntrinsic.natDiv => ["__ps_nat_div"]
  | PsVerifiedIrIntrinsic.natMod => ["__ps_nat_mod"]
  | PsVerifiedIrIntrinsic.intOfNat => ["__ps_int_of_nat"]
  | PsVerifiedIrIntrinsic.intNegSucc => ["__ps_int_neg_succ"]
  | PsVerifiedIrIntrinsic.intNeg => ["__ps_int_neg"]
  | PsVerifiedIrIntrinsic.intAdd => ["__ps_int_add"]
  | PsVerifiedIrIntrinsic.intSub => ["__ps_int_sub"]
  | PsVerifiedIrIntrinsic.intMul => ["__ps_int_mul"]
  | PsVerifiedIrIntrinsic.charOfNat => ["__ps_char_of_nat"]
  | PsVerifiedIrIntrinsic.charToNat => ["__ps_char_to_nat"]
  | PsVerifiedIrIntrinsic.stringPush => ["__ps_string_push"]
  | PsVerifiedIrIntrinsic.stringSingleton => ["__ps_string_singleton"]
  | PsVerifiedIrIntrinsic.stringLength => ["__ps_string_length"]
  | PsVerifiedIrIntrinsic.stringAppend => ["__ps_string_append"]
  | PsVerifiedIrIntrinsic.stringUtf8ByteSize => ["__ps_string_utf8_byte_size"]
  | PsVerifiedIrIntrinsic.stringNext => ["__ps_string_next"]
  | PsVerifiedIrIntrinsic.stringGet => ["__ps_string_get"]
  | PsVerifiedIrIntrinsic.stringAtEnd => ["__ps_string_at_end"]
  | PsVerifiedIrIntrinsic.stringExtract => ["__ps_string_extract"]
  | PsVerifiedIrIntrinsic.stringEq => ["__ps_string_eq"]
  | PsVerifiedIrIntrinsic.arrayEmptyWithCapacity => ["__ps_array_empty_with_capacity"]
  | PsVerifiedIrIntrinsic.arraySize => ["__ps_array_size"]
  | PsVerifiedIrIntrinsic.arrayPush => ["__ps_array_push"]
  | PsVerifiedIrIntrinsic.arrayGet => ["__ps_array_get"]
  | PsVerifiedIrIntrinsic.arrayGetD => ["__ps_array_get_d"]
  | PsVerifiedIrIntrinsic.arraySet => ["__ps_array_set"]
  | PsVerifiedIrIntrinsic.arraySetIfInBounds => ["__ps_array_set_if_in_bounds"]
  | PsVerifiedIrIntrinsic.arrayMap => ["__ps_array_map"]
  | PsVerifiedIrIntrinsic.arrayFoldl => ["__ps_array_foldl"]
  | _ => []

private partial def typeRequirements (type : PsVerifiedIrType) : List String :=
  match type with
  | PsVerifiedIrType.primitive primitive =>
      match primitive with
      | PsVerifiedIrPrimitiveType.nat => ["@nat"]
      | PsVerifiedIrPrimitiveType.int => ["@int"]
      | _ => []
  | PsVerifiedIrType.named _ arguments =>
      psRustRuntimeConcatMap typeRequirements arguments
  | PsVerifiedIrType.function parameters result =>
      psListAppend (psRustRuntimeConcatMap typeRequirements parameters) (typeRequirements result)
  | _ => []

private partial def exprRequirements (expression : PsVerifiedIrExpr) : List String :=
  match expression with
  | PsVerifiedIrExpr.literal literal =>
      match literal with
      | PsVerifiedIrLiteral.natural _ => ["@nat", "__ps_nat_lit"]
      | PsVerifiedIrLiteral.integer _ => ["@int", "__ps_int_lit"]
      | _ => []
  | PsVerifiedIrExpr.var _ => []
  | PsVerifiedIrExpr.intrinsic operation types arguments =>
      psListAppend (intrinsicHelpers operation)
        (psListAppend (psRustRuntimeConcatMap typeRequirements types)
          (psRustRuntimeConcatMap exprRequirements arguments))
  | PsVerifiedIrExpr.lambda parameters result body =>
      psListAppend
        (psRustRuntimeConcatMap (fun (parameter : PsVerifiedIrParameter) =>
          typeRequirements parameter.type) parameters)
        (psListAppend (typeRequirements result) (exprRequirements body))
  | PsVerifiedIrExpr.call fn types arguments =>
      psListAppend (exprRequirements fn)
        (psListAppend (psRustRuntimeConcatMap typeRequirements types)
          (psRustRuntimeConcatMap exprRequirements arguments))
  | PsVerifiedIrExpr.letE _ type value body =>
      psListAppend (typeRequirements type)
        (psListAppend (exprRequirements value) (exprRequirements body))
  | PsVerifiedIrExpr.ifE condition yes no =>
      psListAppend (exprRequirements condition)
        (psListAppend (exprRequirements yes) (exprRequirements no))
  | PsVerifiedIrExpr.record _ types fields =>
      psListAppend (psRustRuntimeConcatMap typeRequirements types)
        (psRustRuntimeConcatMap (fun (field : Prod String PsVerifiedIrExpr) =>
          exprRequirements field.snd) fields)
  | PsVerifiedIrExpr.constructor _ _ types fields =>
      psListAppend (psRustRuntimeConcatMap typeRequirements types)
        (psRustRuntimeConcatMap (fun (field : Prod String PsVerifiedIrExpr) =>
          exprRequirements field.snd) fields)
  | PsVerifiedIrExpr.projection _ types value _ =>
      psListAppend (psRustRuntimeConcatMap typeRequirements types) (exprRequirements value)
  | PsVerifiedIrExpr.matchE _ types value alternatives =>
      psListAppend (psRustRuntimeConcatMap typeRequirements types)
        (psListAppend (exprRequirements value)
          (psRustRuntimeConcatMap
            (fun (alternative : Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) =>
              psListAppend
                (psRustRuntimeConcatMap (fun (binding : PsVerifiedIrMatchBinding) =>
                  typeRequirements binding.type) alternative.snd.fst)
                (exprRequirements alternative.snd.snd))
            alternatives))

private def moduleRequirements (source : PsVerifiedIrModule) : List String :=
  psListAppend
    (psRustRuntimeConcatMap (fun (value : PsVerifiedIrStructure) =>
      psRustRuntimeConcatMap (fun (field : PsVerifiedIrStructureField) =>
        typeRequirements field.type) value.fields) source.structures)
    (psListAppend
      (psRustRuntimeConcatMap (fun (value : PsVerifiedIrInductive) =>
        psRustRuntimeConcatMap (fun (constructor : PsVerifiedIrConstructor) =>
          psRustRuntimeConcatMap (fun (field : PsVerifiedIrConstructorField) =>
            typeRequirements field.type) constructor.fields) value.constructors) source.inductives)
      (psRustRuntimeConcatMap (fun (value : PsVerifiedIrDeclaration) =>
        psListAppend
          (psRustRuntimeConcatMap (fun (parameter : PsVerifiedIrParameter) =>
            typeRequirements parameter.type) value.parameters)
          (psListAppend (typeRequirements value.resultType) (exprRequirements value.body)))
        source.declarations))

structure PsRustRuntimePlan where
  source : String
  requirements : List String

def psRustRuntimeFilterHelpers (requested : List String)
    (helpers : List PsRustRuntimeHelper) : List PsRustRuntimeHelper :=
  match helpers with
  | List.nil => List.nil
  | List.cons item rest =>
      if psListAny (fun (name : String) => psStringEq name item.name) requested then
        List.cons item (psRustRuntimeFilterHelpers requested rest)
      else psRustRuntimeFilterHelpers requested rest

def psRustPlanRuntime (source : PsVerifiedIrModule) : PsRustRuntimePlan :=
  let requested : List String := moduleRequirements source;
  let helpers : List PsRustRuntimeHelper :=
    psRustRuntimeFilterHelpers requested psRustRuntimeHelperCatalogue;
  let needsNat : Bool :=
    psListAny (fun (name : String) => psStringEq name "@nat") requested ||
      psListAny (fun (item : PsRustRuntimeHelper) => item.nat) helpers;
  let needsInt : Bool :=
    psListAny (fun (name : String) => psStringEq name "@int") requested ||
      psListAny (fun (item : PsRustRuntimeHelper) => item.int) helpers;
  let needsTraits : Bool := psListAny (fun (item : PsRustRuntimeHelper) => item.traits) helpers;
  let needsFromStr : Bool := psListAny (fun (item : PsRustRuntimeHelper) => item.fromStr) helpers;
  let imports : String := psTextJoin "" [
    if needsNat then "use num_bigint::BigUint as PsNat;\n" else "",
    if needsInt then "use num_bigint::BigInt as PsInt;\n" else "",
    if needsTraits then "use num_traits::{ToPrimitive, Zero};\n" else "",
    if needsFromStr then "use std::str::FromStr;\n" else ""
  ];
  PsRustRuntimePlan.mk
    (String.Internal.append imports
      (psTextJoin "" (psListMap (fun (item : PsRustRuntimeHelper) => item.source) helpers)))
    (psListAppend (if needsNat || needsInt then ["num-bigint@0.4.6"] else [])
      (psListAppend (if needsTraits then ["num-traits@0.2.19"] else [])
        (psListMap (fun (item : PsRustRuntimeHelper) => item.name) helpers)))
