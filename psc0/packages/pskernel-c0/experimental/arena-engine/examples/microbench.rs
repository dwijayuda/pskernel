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
    println!("note: no source kernel comparison and no claims of speedup");
}
