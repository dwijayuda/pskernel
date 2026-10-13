-- Versioned runtime support, emitted as a separate Rust module.
-- Keep PSC arithmetic and Unicode contracts explicit at this boundary.
def psRustRuntimePrelude : String := r#"
#![forbid(unsafe_code)]
pub use num_bigint::{BigInt as PsInt, BigUint as PsNat};
use num_traits::{ToPrimitive, Zero};
use std::rc::Rc;
use std::str::FromStr;

pub type PsArray<T> = Rc<Vec<T>>;

pub(super) fn __ps_nat_lit(text: &str) -> PsNat {
    PsNat::from_str(text).expect("valid generated Nat literal")
}
pub(super) fn __ps_int_lit(text: &str) -> PsInt {
    PsInt::from_str(text).expect("valid generated Int literal")
}
pub(super) fn __ps_nat_add(a: &PsNat, b: &PsNat) -> PsNat { a + b }
pub(super) fn __ps_nat_sub(a: &PsNat, b: &PsNat) -> PsNat {
    if a >= b { a - b } else { PsNat::zero() }
}
pub(super) fn __ps_nat_mul(a: &PsNat, b: &PsNat) -> PsNat { a * b }
pub(super) fn __ps_nat_div(a: &PsNat, b: &PsNat) -> PsNat {
    if b.is_zero() { PsNat::zero() } else { a / b }
}
pub(super) fn __ps_nat_mod(a: &PsNat, b: &PsNat) -> PsNat {
    if b.is_zero() { a.clone() } else { a % b }
}
pub(super) fn __ps_int_to_nat(value: &PsInt) -> PsNat {
    value.to_biguint().unwrap_or_else(PsNat::zero)
}
pub(super) fn __ps_int_of_nat(value: &PsNat) -> PsInt { PsInt::from(value.clone()) }
pub(super) fn __ps_int_neg_succ(value: &PsNat) -> PsInt {
    -(PsInt::from(value.clone()) + PsInt::from(1u8))
}
pub(super) fn __ps_int_neg(value: &PsInt) -> PsInt { -value }
pub(super) fn __ps_int_add(a: &PsInt, b: &PsInt) -> PsInt { a + b }
pub(super) fn __ps_int_sub(a: &PsInt, b: &PsInt) -> PsInt { a - b }
pub(super) fn __ps_int_mul(a: &PsInt, b: &PsInt) -> PsInt { a * b }
pub(super) fn __ps_char_of_nat(value: &PsNat) -> char {
    value.to_u32().and_then(char::from_u32).unwrap_or('\0')
}
pub(super) fn __ps_char_to_nat(value: char) -> PsNat { PsNat::from(value as u32) }
pub(super) fn __ps_string_push(mut left: String, right: char) -> String {
    left.push(right);
    left
}
pub(super) fn __ps_string_singleton(value: char) -> String { value.to_string() }
pub(super) fn __ps_string_length(value: &String) -> PsNat {
    PsNat::from(value.chars().count())
}
pub(super) fn __ps_string_append(mut left: String, right: &String) -> String {
    left.push_str(right);
    left
}
pub(super) fn __ps_string_utf8_byte_size(value: &String) -> PsNat {
    PsNat::from(value.len())
}
pub(super) fn __ps_string_next(value: &String, position: &PsNat) -> PsNat {
    let next = position.to_usize()
        .and_then(|i| value.get(i..))
        .and_then(|rest| rest.chars().next());
    position + PsNat::from(next.map_or(1, char::len_utf8))
}
pub(super) fn __ps_string_get(value: &String, position: &PsNat) -> char {
    position.to_usize()
        .and_then(|i| value.get(i..))
        .and_then(|rest| rest.chars().next())
        .unwrap_or('A')
}
pub(super) fn __ps_string_at_end(value: &String, position: &PsNat) -> bool {
    position >= &PsNat::from(value.len())
}
pub(super) fn __ps_string_extract(value: &String, begin: &PsNat, end: &PsNat) -> String {
    if begin >= end { return String::new(); }
    let rest = match begin.to_usize().and_then(|i| value.get(i..)) {
        Some(rest) => rest,
        None => return String::new(),
    };
    let mut index = begin.clone();
    let mut out = String::new();
    for c in rest.chars() {
        if &index == end { break; }
        out.push(c);
        index += PsNat::from(c.len_utf8());
    }
    out
}
pub(super) fn __ps_string_eq(left: &String, right: &String) -> bool { left == right }
pub(super) fn __ps_array_empty_with_capacity<T>(capacity: &PsNat) -> PsArray<T> {
    Rc::new(Vec::with_capacity(capacity.to_usize().unwrap_or(0)))
}
// This builder owns its unpublished Vec; no persistent prefix is copied.
pub(super) fn __ps_array_build<T, S: Clone>(
    count: &PsNat, mut state: S,
    head: Rc<dyn Fn(S) -> T>, tail: Rc<dyn Fn(S) -> S>,
) -> PsArray<T> {
    let count = count.to_usize().expect("Array allocation size fits usize");
    let mut result = Vec::with_capacity(count);
    for _ in 0..count {
        result.push(head(state.clone()));
        state = tail(state);
    }
    Rc::new(result)
}
pub(super) fn __ps_array_size<T>(value: &PsArray<T>) -> PsNat { PsNat::from(value.len()) }
pub(super) fn __ps_array_push<T: Clone>(mut array: PsArray<T>, value: T) -> PsArray<T> {
    Rc::make_mut(&mut array).push(value);
    array
}
pub(super) fn __ps_array_get<T: Clone>(array: &PsArray<T>, index: &PsNat) -> T {
    let i = index.to_usize().expect("proved Array index fits usize");
    array[i].clone()
}
pub(super) fn __ps_array_get_d<T: Clone>(array: &PsArray<T>, index: &PsNat, fallback: &T) -> T {
    if index >= &PsNat::from(array.len()) {
        fallback.clone()
    } else {
        array[index.to_usize().expect("bounded Array index fits usize")].clone()
    }
}
pub(super) fn __ps_array_set<T: Clone>(
    mut array: PsArray<T>, index: &PsNat, value: T,
) -> PsArray<T> {
    let i = index.to_usize().expect("proved Array index fits usize");
    Rc::make_mut(&mut array)[i] = value;
    array
}
pub(super) fn __ps_array_set_if_in_bounds<T: Clone>(
    mut array: PsArray<T>, index: &PsNat, value: T,
) -> PsArray<T> {
    if index < &PsNat::from(array.len()) {
        let i = index.to_usize().expect("bounded Array index fits usize");
        Rc::make_mut(&mut array)[i] = value;
    }
    array
}
pub(super) fn __ps_array_map<A: Clone, B>(
    f: Rc<dyn Fn(A) -> B>, array: &PsArray<A>,
) -> PsArray<B> {
    Rc::new(array.iter().cloned().map(|value| f(value)).collect())
}
pub(super) fn __ps_array_foldl<A: Clone, B: Clone>(
    f: Rc<dyn Fn(B, A) -> B>, init: &B, array: &PsArray<A>,
    start: &PsNat, stop: &PsNat,
) -> B {
    let size = PsNat::from(array.len());
    let end = if stop <= &size { stop.clone() } else { size };
    let mut index = start.clone();
    let mut acc = init.clone();
    while index < end {
        let i = index.to_usize().expect("bounded Array fold index fits usize");
        acc = f(acc, array[i].clone());
        index += PsNat::from(1u8);
    }
    acc
}
"#
