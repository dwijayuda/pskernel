def psRustRuntimePrelude : String :=
  "#![forbid(unsafe_code)]\n" ++
  "use num_bigint::{BigInt as PsInt, BigUint as PsNat};\n" ++
  "use num_traits::{ToPrimitive, Zero};\n" ++
  "use std::str::FromStr;\n" ++
  "fn __ps_nat_lit(text: &str) -> PsNat { PsNat::from_str(text).expect(\"valid generated Nat literal\") }\n" ++
  "fn __ps_int_lit(text: &str) -> PsInt { PsInt::from_str(text).expect(\"valid generated Int literal\") }\n" ++
  "fn __ps_nat_add(a: &PsNat, b: &PsNat) -> PsNat { a + b }\n" ++
  "fn __ps_nat_sub(a: &PsNat, b: &PsNat) -> PsNat { if a >= b { a - b } else { PsNat::zero() } }\n" ++
  "fn __ps_nat_mul(a: &PsNat, b: &PsNat) -> PsNat { a * b }\n" ++
  "fn __ps_nat_div(a: &PsNat, b: &PsNat) -> PsNat { if b.is_zero() { PsNat::zero() } else { a / b } }\n" ++
  "fn __ps_nat_mod(a: &PsNat, b: &PsNat) -> PsNat { if b.is_zero() { a.clone() } else { a % b } }\n" ++
  "fn __ps_int_of_nat(value: &PsNat) -> PsInt { PsInt::from(value.clone()) }\n" ++
  "fn __ps_int_neg_succ(value: &PsNat) -> PsInt { -(PsInt::from(value.clone()) + PsInt::from(1u8)) }\n" ++
  "fn __ps_int_neg(value: &PsInt) -> PsInt { -value }\n" ++
  "fn __ps_int_add(a: &PsInt, b: &PsInt) -> PsInt { a + b }\n" ++
  "fn __ps_int_sub(a: &PsInt, b: &PsInt) -> PsInt { a - b }\n" ++
  "fn __ps_int_mul(a: &PsInt, b: &PsInt) -> PsInt { a * b }\n" ++
  "fn __ps_char_of_nat(value: &PsNat) -> char { match value.to_u32().and_then(char::from_u32) { Some(c) => c, None => '\\0' } }\n" ++
  "fn __ps_char_to_nat(value: char) -> PsNat { PsNat::from(value as u32) }\n" ++
  "fn __ps_string_push(left: &String, right: char) -> String { let mut out = left.clone(); out.push(right); out }\n" ++
  "fn __ps_string_singleton(value: char) -> String { value.to_string() }\n" ++
  "fn __ps_string_length(value: &String) -> PsNat { PsNat::from(value.chars().count()) }\n" ++
  "fn __ps_string_append(left: &String, right: &String) -> String { let mut out = left.clone(); out.push_str(right); out }\n" ++
  "fn __ps_string_utf8_byte_size(value: &String) -> PsNat { PsNat::from(value.len()) }\n" ++
  "fn __ps_string_next(value: &String, position: &PsNat) -> PsNat { let mut index = PsNat::zero(); for c in value.chars() { let width = PsNat::from(c.len_utf8()); if &index == position { return position.clone() + width; } if &index > position { return position.clone() + PsNat::from(1u8); } index += width; } position.clone() + PsNat::from(1u8) }\n" ++
  "fn __ps_string_get(value: &String, position: &PsNat) -> char { let mut index = PsNat::zero(); for c in value.chars() { if &index == position { return c; } if &index > position { return 'A'; } index += PsNat::from(c.len_utf8()); } 'A' }\n" ++
  "fn __ps_string_at_end(value: &String, position: &PsNat) -> bool { position >= &PsNat::from(value.len()) }\n" ++
  "fn __ps_string_extract(value: &String, begin: &PsNat, end: &PsNat) -> String { if begin >= end { return String::new(); } let mut index = PsNat::zero(); let mut started = false; let mut out = String::new(); for c in value.chars() { let width = PsNat::from(c.len_utf8()); if !started { if &index == begin { started = true; } else { index += width; continue; } } if &index == end { return out; } out.push(c); index += width; } out }\n" ++
  "fn __ps_string_eq(left: &String, right: &String) -> bool { left == right }\n" ++
  "fn __ps_array_empty_with_capacity<T>(_capacity: &PsNat) -> Vec<T> { Vec::new() }\n" ++
  "fn __ps_array_size<T>(value: &Vec<T>) -> PsNat { PsNat::from(value.len()) }\n" ++
  "fn __ps_array_push<T: Clone>(array: &Vec<T>, value: &T) -> Vec<T> { let mut out = array.clone(); out.push(value.clone()); out }\n" ++
  "fn __ps_array_get<T: Clone>(array: &Vec<T>, index: &PsNat) -> T { let i = index.to_usize().expect(\"proved Array index fits usize\"); array[i].clone() }\n" ++
  "fn __ps_array_get_d<T: Clone>(array: &Vec<T>, index: &PsNat, fallback: &T) -> T { if index >= &PsNat::from(array.len()) { fallback.clone() } else { array[index.to_usize().expect(\"bounded Array index fits usize\")].clone() } }\n" ++
  "fn __ps_array_set<T: Clone>(array: &Vec<T>, index: &PsNat, value: &T) -> Vec<T> { let mut out = array.clone(); let i = index.to_usize().expect(\"proved Array index fits usize\"); out[i] = value.clone(); out }\n" ++
  "fn __ps_array_set_if_in_bounds<T: Clone>(array: &Vec<T>, index: &PsNat, value: &T) -> Vec<T> { if index >= &PsNat::from(array.len()) { array.clone() } else { let mut out = array.clone(); let i = index.to_usize().expect(\"bounded Array index fits usize\"); out[i] = value.clone(); out } }\n" ++
  "fn __ps_array_map<A: Clone, B, F: Fn(A) -> B>(f: F, array: &Vec<A>) -> Vec<B> { array.iter().cloned().map(f).collect() }\n" ++
  "fn __ps_array_foldl<A: Clone, B: Clone, F: Fn(B, A) -> B>(f: F, init: &B, array: &Vec<A>, start: &PsNat, stop: &PsNat) -> B { let size = PsNat::from(array.len()); let end = if stop <= &size { stop.clone() } else { size }; let mut index = start.clone(); let mut acc = init.clone(); while index < end { let i = index.to_usize().expect(\"bounded Array fold index fits usize\"); acc = f(acc, array[i].clone()); index += PsNat::from(1u8); } acc }\n"
