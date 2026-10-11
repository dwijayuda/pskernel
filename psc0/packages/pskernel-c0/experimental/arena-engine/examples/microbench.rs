//! Reproducible microbenchmark (not an equivalence or kernel benchmark).
//! cargo run --release --example microbench
use pskernel_c0_arena_engine::{Arena, Expr};
use std::hint::black_box;
use std::time::Instant;

fn main() {
    const DEPTH: usize = 1024;
    const REPEATS: usize = 1000;
    let mut arena = Arena::new();
    let head = arena.intern(Expr::BVar(0));
    let argument = arena.intern(Expr::BVar(1));
    let mut app = head;
    for _ in 0..DEPTH { app = arena.intern(Expr::App(app, argument)); }
    let started = Instant::now();
    for _ in 0..REPEATS {
        let mut count = 0;
        let h = arena.spine(app, |_| count += 1);
        assert_eq!(h, head);
        assert_eq!(count, DEPTH);
        black_box(count);
    }
    let spine_time = started.elapsed();
    let started = Instant::now();
    for _ in 0..REPEATS {
        let result = arena.whnf_fragment(app, DEPTH + 1).unwrap();
        black_box(result);
        assert_eq!(result, app);
    }
    let whnf_time = started.elapsed();
    println!("depth={},repeats={},nodes={}",DEPTH,REPEATS,arena.count());
    println!("spine_total_ns={}",spine_time.as_nanos());
    println!("whnf_total_ns={}",whnf_time.as_nanos());
    // In-process comparison against the previous recursive C0 algorithm.
    // Both runs use the same arena and identical input. This is a fragment
    // microbenchmark, NOT a comparison with production PSKernel-Core.
    const SUBST_DEPTH: usize = 128;
    const SUBST_REPEATS: usize = 300;
    let mut substitution_input = head;
    for _ in 0..SUBST_DEPTH {
        substitution_input = arena.intern(Expr::App(substitution_input, head));
    }
    let replacement = arena.intern(Expr::BVar(17));
    let expected = arena.instantiate1_reference(substitution_input, replacement).unwrap();
    assert_eq!(arena.instantiate1(substitution_input, replacement).unwrap(), expected);
    let started = Instant::now();
    for _ in 0..SUBST_REPEATS {
        black_box(arena.instantiate1_reference(substitution_input, replacement).unwrap());
    }
    let reference_time = started.elapsed();
    let started = Instant::now();
    for _ in 0..SUBST_REPEATS {
        black_box(arena.instantiate1(substitution_input, replacement).unwrap());
    }
    let hybrid_time = started.elapsed();
    println!("substitution_depth={},substitution_repeats={}",SUBST_DEPTH,SUBST_REPEATS);
    println!("recursive_substitution_total_ns={}",reference_time.as_nanos());
    println!("hybrid_substitution_total_ns={}",hybrid_time.as_nanos());
    println!("note: comparison only covers the C0 substitution fragment; no full kernel speedup claim");

}
