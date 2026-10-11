//! C0's experimental, independently owned term engine.
//! This is not a Lean kernel checker and is not an acceptance oracle.
//! Lean's full reductions/quotients/recursors must be implemented before integration.
use std::collections::HashMap;

#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
pub struct ExprId(u32);
#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
pub struct LevelId(u32);
#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
pub struct NameId(u32);

#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
pub enum BinderInfo { Default, Implicit, StrictImplicit, Instance }

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum Level {
    Zero, Succ(LevelId), Max(LevelId, LevelId), IMax(LevelId, LevelId),
    Param(NameId), MVar(NameId),
}
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum Expr {
    BVar(u32), FVar(NameId), MVar(NameId), Sort(LevelId),
    Const(NameId, Box<[LevelId]>), App(ExprId, ExprId),
    Lam { name: NameId, domain: ExprId, body: ExprId, info: BinderInfo },
    Forall { name: NameId, domain: ExprId, body: ExprId, info: BinderInfo },
    Let { name: NameId, domain: ExprId, value: ExprId, body: ExprId, nondep: bool },
    Nat(Box<[u8]>), Str(Box<str>), MData(u64, ExprId),
    Proj { name: NameId, field: u32, target: ExprId },
}
/// A positive-only conversion hint, never a kernel rejection verdict.
/// Unknown requires the full Lean-compatible conversion checker.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ConversionHint { Equal, Unknown }

/// IDs must never escape their owner arena. A new arena invalidates every ID.
#[derive(Default)]
pub struct Arena {
    names: Vec<Box<str>>, name_index: HashMap<Box<str>, NameId>,
    levels: Vec<Level>, level_index: HashMap<Level, LevelId>,
    terms: Vec<Expr>, term_index: HashMap<Expr, ExprId>,
}
impl Arena {
    pub fn new() -> Self { Self::default() }
    pub fn name(&mut self, value: &str) -> NameId {
        if let Some(&id) = self.name_index.get(value) { return id; }
        let id = NameId(u32::try_from(self.names.len()).expect("name IDs exhausted"));
        let value: Box<str> = value.into();
        self.names.push(value.clone()); self.name_index.insert(value,id); id
    }
    pub fn level(&mut self, level: Level) -> LevelId {
        self.validate_level(&level);
        if let Some(&id) = self.level_index.get(&level) { return id; }
        let id = LevelId(u32::try_from(self.levels.len()).expect("level IDs exhausted"));
        self.levels.push(level.clone()); self.level_index.insert(level,id); id
    }
    pub fn intern(&mut self, term: Expr) -> ExprId {
        self.validate_term(&term);
        if let Some(&id) = self.term_index.get(&term) { return id; }
        let id = ExprId(u32::try_from(self.terms.len()).expect("term IDs exhausted"));
        self.terms.push(term.clone()); self.term_index.insert(term,id); id
    }
    pub fn get(&self, id: ExprId) -> &Expr { &self.terms[id.0 as usize] }
    pub fn count(&self) -> usize { self.terms.len() }
    /// Visit arguments in outermost-first order without building a list.
    pub fn spine(&self, mut root: ExprId, mut argument: impl FnMut(ExprId)) -> ExprId {
        while let Expr::App(fun,arg) = self.get(root) {
            argument(*arg); root = *fun;
        }
        root
    }
    fn validate_name(&self, id: NameId) { assert!((id.0 as usize) < self.names.len()); }
    fn validate_level_id(&self, id: LevelId) { assert!((id.0 as usize) < self.levels.len()); }
    fn validate_expr_id(&self, id: ExprId) { assert!((id.0 as usize) < self.terms.len()); }
    fn validate_level(&self, level: &Level) {
        match level {
            Level::Zero => {},
            Level::Succ(a) => self.validate_level_id(*a),
            Level::Max(a,b)|Level::IMax(a,b) => {self.validate_level_id(*a);self.validate_level_id(*b);},
            Level::Param(n)|Level::MVar(n) => self.validate_name(*n),
        }
    }
    fn validate_term(&self, t: &Expr) {
        match t {
            Expr::BVar(_)|Expr::Nat(_)|Expr::Str(_) => {},
            Expr::FVar(n)|Expr::MVar(n) => self.validate_name(*n),
            Expr::Sort(l) => self.validate_level_id(*l),
            Expr::Const(n,ls) => {self.validate_name(*n);for l in ls.iter(){self.validate_level_id(*l);}},
            Expr::App(f,a) => {self.validate_expr_id(*f);self.validate_expr_id(*a);},
            Expr::Lam{name,domain,body,..}|Expr::Forall{name,domain,body,..} => {
                self.validate_name(*name);self.validate_expr_id(*domain);self.validate_expr_id(*body);
            },
            Expr::Let{name,domain,value,body,..} => {
                self.validate_name(*name);self.validate_expr_id(*domain);
                self.validate_expr_id(*value);self.validate_expr_id(*body);
            },
            Expr::MData(_,e) => self.validate_expr_id(*e),
            Expr::Proj{name,target,..} => {self.validate_name(*name);self.validate_expr_id(*target);},
        }
    }
    /// De Bruijn substitution for a single bound variable.
    /// Returns Err on depth overflow rather than silently constructing an invalid term.
    pub fn instantiate1(&mut self, body: ExprId, replacement: ExprId)
        -> Result<ExprId, &'static str>
    {
        let mut memo = HashMap::new();
        let mut lift_memo = HashMap::new();
        self.subst_at(body, replacement, 0, &mut memo, &mut lift_memo)
    }
    fn lift(&mut self, id: ExprId, by: u32, depth: u32,
        memo: &mut HashMap<(ExprId,u32),ExprId>) -> Result<ExprId,&'static str>
    {
        if by == 0 { return Ok(id); }
        if let Some(&v) = memo.get(&(id,depth)) {return Ok(v);}
        let node = self.get(id).clone();
        let result = match node {
            Expr::BVar(i) if i >= depth => self.intern(Expr::BVar(i.checked_add(by).ok_or("de Bruijn overflow")?)),
            Expr::App(f,a) => {
                let f=self.lift(f,by,depth,memo)?;let a=self.lift(a,by,depth,memo)?;
                self.intern(Expr::App(f,a))
            }
            Expr::Lam{name,domain,body,info} => {
                let domain=self.lift(domain,by,depth,memo)?;
                let body=self.lift(body,by,depth.checked_add(1).ok_or("depth overflow")?,memo)?;
                self.intern(Expr::Lam{name,domain,body,info})
            }
            Expr::Forall{name,domain,body,info} => {
                let domain=self.lift(domain,by,depth,memo)?;
                let body=self.lift(body,by,depth.checked_add(1).ok_or("depth overflow")?,memo)?;
                self.intern(Expr::Forall{name,domain,body,info})
            }
            Expr::Let{name,domain,value,body,nondep} => {
                let domain=self.lift(domain,by,depth,memo)?;
                let value=self.lift(value,by,depth,memo)?;
                let body=self.lift(body,by,depth.checked_add(1).ok_or("depth overflow")?,memo)?;
                self.intern(Expr::Let{name,domain,value,body,nondep})
            }
            Expr::MData(x,e)=>{let e=self.lift(e,by,depth,memo)?;self.intern(Expr::MData(x,e))}
            Expr::Proj{name,field,target}=>{
                let target=self.lift(target,by,depth,memo)?;
                self.intern(Expr::Proj{name,field,target})
            }
            _ => id,
        };
        memo.insert((id,depth),result);
        Ok(result)
    }
    fn subst_at(&mut self,id:ExprId,replacement:ExprId,depth:u32,
        memo:&mut HashMap<(ExprId,u32),ExprId>,
        lift_memo:&mut HashMap<(u32,ExprId,u32),ExprId>) -> Result<ExprId,&'static str>
    {
        if let Some(&x)=memo.get(&(id,depth)){return Ok(x);}
        let node=self.get(id).clone();
        let result=match node {
            Expr::BVar(i) if i == depth => {
                if let Some(&cached) = lift_memo.get(&(depth,replacement,0)) { cached }
                else {
                    let value = self.lift(replacement,depth,0,&mut HashMap::new())?;
                    lift_memo.insert((depth,replacement,0),value);
                    value
                }
            },
            Expr::BVar(i) if i > depth => self.intern(Expr::BVar(i-1)),
            Expr::App(f,a) => {
                let f=self.subst_at(f,replacement,depth,memo,lift_memo)?;
                let a=self.subst_at(a,replacement,depth,memo,lift_memo)?;
                self.intern(Expr::App(f,a))
            }
            Expr::Lam{name,domain,body,info} => {
                let domain=self.subst_at(domain,replacement,depth,memo,lift_memo)?;
                let body=self.subst_at(body,replacement,depth.checked_add(1).ok_or("depth overflow")?,memo,lift_memo)?;
                self.intern(Expr::Lam{name,domain,body,info})
            }
            Expr::Forall{name,domain,body,info} => {
                let domain=self.subst_at(domain,replacement,depth,memo,lift_memo)?;
                let body=self.subst_at(body,replacement,depth.checked_add(1).ok_or("depth overflow")?,memo,lift_memo)?;
                self.intern(Expr::Forall{name,domain,body,info})
            }
            Expr::Let{name,domain,value,body,nondep} => {
                let domain=self.subst_at(domain,replacement,depth,memo,lift_memo)?;
                let value=self.subst_at(value,replacement,depth,memo,lift_memo)?;
                let body=self.subst_at(body,replacement,depth.checked_add(1).ok_or("depth overflow")?,memo,lift_memo)?;
                self.intern(Expr::Let{name,domain,value,body,nondep})
            }
            Expr::MData(x,e)=>{let e=self.subst_at(e,replacement,depth,memo,lift_memo)?;self.intern(Expr::MData(x,e))}
            Expr::Proj{name,field,target}=>{
                let target=self.subst_at(target,replacement,depth,memo,lift_memo)?;
                self.intern(Expr::Proj{name,field,target})
            }
            _=>id,
        };
        memo.insert((id,depth),result);
        Ok(result)
    }
    /// A conservative conversion precheck for an experimental engine.
    /// It never decides non-equality: unequal normal forms may still be
    /// definitionally equal through unsupported Lean reductions.
    /// On an exhausted budget, return Unknown (never Equal).
    pub fn conversion_hint(&mut self, left: ExprId, right: ExprId, fuel: usize) -> ConversionHint {
        if left == right { return ConversionHint::Equal; }
        let left_nf = match self.whnf_fragment(left, fuel) {
            Ok(value) => value,
            Err(_) => return ConversionHint::Unknown,
        };
        let right_nf = match self.whnf_fragment(right, fuel) {
            Ok(value) => value,
            Err(_) => return ConversionHint::Unknown,
        };
        if left_nf == right_nf { ConversionHint::Equal } else { ConversionHint::Unknown }
    }

    /// Explicit-stack beta/zeta/metadata evaluator for the supported fragment.
    ///
    /// Each examined term node spends one unit from the caller's global budget.
    /// Outermost applications are pushed onto a spine and only rebuilt once
    /// when a non-lambda head is reached. This avoids recursive head-WHNF calls
    /// and temporary application reconstruction between beta steps.
    ///
    /// This is NOT Lean WHNF: delta, iota, projections, recursors, native
    /// reductions, proof irrelevance and quotient rules remain unsupported.
    pub fn whnf_fragment(&mut self, mut root: ExprId, fuel: usize) -> Result<ExprId, &'static str> {
        let mut pending = Vec::<ExprId>::new();
        let mut remaining = fuel;
        loop {
            if remaining == 0 { return Err("reduction fuel exhausted"); }
            remaining -= 1;
            match self.get(root).clone() {
                Expr::App(fun, arg) => { pending.push(arg); root = fun; }
                Expr::MData(_, inner) => root = inner,
                Expr::Let { body, value, .. } => root = self.instantiate1(body, value)?,
                Expr::Lam { body, .. } if !pending.is_empty() => {
                    // The nearest argument is at the end of the spine.
                    let arg = pending.pop().expect("checked nonempty");
                    root = self.instantiate1(body, arg)?;
                }
                _ => {
                    while let Some(arg) = pending.pop() {
                        root = self.intern(Expr::App(root, arg));
                    }
                    return Ok(root);
                }
            }
        }
    }

}

#[cfg(test)]
mod tests {
    use super::*;
    #[test] fn structural_interning() {
        let mut a=Arena::new();let z=a.level(Level::Zero);
        let x=a.intern(Expr::Sort(z)); assert_eq!(x,a.intern(Expr::Sort(z)));
        assert_eq!(a.count(),1);
    }
    #[test] fn beta_identity() {
        let mut a=Arena::new();let n=a.name("x");let ty=a.intern(Expr::BVar(1));
        let body=a.intern(Expr::BVar(0));let value=a.intern(Expr::BVar(4));
        let lam=a.intern(Expr::Lam{name:n,domain:ty,body,info:BinderInfo::Default});
        let app=a.intern(Expr::App(lam,value));
        assert_eq!(a.whnf_fragment(app,32).unwrap(),value);
    }
    #[test] fn substitution_shifts_under_binders() {
        let mut a=Arena::new();let n=a.name("x");
        let ty=a.intern(Expr::BVar(0));
        let body=a.intern(Expr::Lam{name:n,domain:ty,body:ty,info:BinderInfo::Default});
        let replacement=a.intern(Expr::BVar(2));
        let out=a.instantiate1(body,replacement).unwrap();
        match a.get(out) { Expr::Lam{domain,body,..} => {
            assert_eq!(a.get(*domain),&Expr::BVar(2));
            assert_eq!(a.get(*body),&Expr::BVar(0));
        },_=>panic!("expected binder") }
    }
    #[test] fn application_spine() {
        let mut a=Arena::new();
        let f=a.intern(Expr::BVar(0));let x=a.intern(Expr::BVar(1));let y=a.intern(Expr::BVar(2));
        let fx=a.intern(Expr::App(f,x));let fxy=a.intern(Expr::App(fx,y));
        let mut args=Vec::new();assert_eq!(a.spine(fxy,|x|args.push(x)),f);
        assert_eq!(args,vec![y,x]);
    }
    #[test] fn nested_application_consumes_shared_fuel() {
        let mut a = Arena::new();
        let f = a.intern(Expr::BVar(0));
        let arg = a.intern(Expr::BVar(1));
        let a1 = a.intern(Expr::App(f, arg));
        let a2 = a.intern(Expr::App(a1, arg));
        assert_eq!(a.whnf_fragment(a2, 2), Err("reduction fuel exhausted"));
        assert_eq!(a.whnf_fragment(a2, 3), Ok(a2));
    }
    #[test] fn normal_forms_obey_budget() {
        let mut a = Arena::new();
        let x = a.intern(Expr::BVar(12));
        assert_eq!(a.whnf_fragment(x, 0), Err("reduction fuel exhausted"));
        assert_eq!(a.whnf_fragment(x, 1), Ok(x));
    }
    #[test] fn zeta_then_beta() {
        let mut a = Arena::new();
        let n = a.name("x");
        let ty = a.intern(Expr::BVar(0));
        let body = a.intern(Expr::BVar(0));
        let value = a.intern(Expr::Nat(vec![42].into_boxed_slice()));
        let lam = a.intern(Expr::Lam { name: n, domain: ty, body, info: BinderInfo::Default });
        let app = a.intern(Expr::App(lam, value));
        let term = a.intern(Expr::Let { name: n, domain: ty, value: app, body, nondep: false });
        assert_eq!(a.whnf_fragment(term, 20), Ok(value));
    }

    #[test] fn repeated_replacement_under_multiple_binders() {
        let mut a = Arena::new();
        let n = a.name("x");
        let bound = a.intern(Expr::BVar(0));
        let body = a.intern(Expr::App(bound, bound));
        let wrapped = a.intern(Expr::Lam {
            name: n, domain: bound, body, info: BinderInfo::Default
        });
        let replacement = a.intern(Expr::BVar(3));
        let out = a.instantiate1(wrapped, replacement).unwrap();
        match a.get(out) {
            Expr::Lam { domain, body, .. } => {
                assert_eq!(a.get(*domain), &Expr::BVar(3));
                assert_eq!(a.get(*body), &Expr::App(bound, bound));
            },
            _ => panic!("expected lambda"),
        }
    }

    #[test] fn two_argument_beta_preserves_argument_order() {
        let mut a = Arena::new();
        let n = a.name("x");
        let zero = a.level(Level::Zero);
        let t = a.intern(Expr::Sort(zero));
        let inner_body = a.intern(Expr::BVar(1));
        let inner = a.intern(Expr::Lam {
            name: n, domain: t, body: inner_body, info: BinderInfo::Default
        });
        let outer = a.intern(Expr::Lam {
            name: n, domain: t, body: inner, info: BinderInfo::Default
        });
        let x = a.intern(Expr::Nat(vec![10].into_boxed_slice()));
        let y = a.intern(Expr::Nat(vec![20].into_boxed_slice()));
        let first = a.intern(Expr::App(outer, x));
        let both = a.intern(Expr::App(first, y));
        assert_eq!(a.whnf_fragment(both, 12), Ok(x));
    }

    #[test] fn inert_head_does_not_allocate_another_application() {
        let mut a = Arena::new();
        let f = a.intern(Expr::BVar(0));
        let x = a.intern(Expr::BVar(1));
        let app = a.intern(Expr::App(f, x));
        let before = a.count();
        assert_eq!(a.whnf_fragment(app, 3), Ok(app));
        assert_eq!(a.count(), before);
    }

    #[test] fn under_binder_substitution_shifts_outer_variables() {
        let mut a = Arena::new();
        let n = a.name("x");
        let ty = a.intern(Expr::BVar(0));
        let target = a.intern(Expr::BVar(1));
        let body = a.intern(Expr::Lam {
            name: n, domain: ty, body: target, info: BinderInfo::Default
        });
        let replacement = a.intern(Expr::BVar(3));
        let reduced = a.instantiate1(body, replacement).unwrap();
        match a.get(reduced) {
            Expr::Lam { body, .. } => assert_eq!(a.get(*body), &Expr::BVar(4)),
            _ => panic!("expected lambda"),
        }
    }

    #[test] fn conversion_hint_never_claims_inequality() {
        let mut a = Arena::new();
        let n = a.name("x");
        let zero = a.level(Level::Zero);
        let ty = a.intern(Expr::Sort(zero));
        let body = a.intern(Expr::BVar(0));
        let value = a.intern(Expr::Nat(vec![7].into_boxed_slice()));
        let lam = a.intern(Expr::Lam { name:n, domain:ty, body, info:BinderInfo::Default });
        let app = a.intern(Expr::App(lam,value));
        assert_eq!(a.conversion_hint(app,value,10),ConversionHint::Equal);
        assert_eq!(a.conversion_hint(app,ty,10),ConversionHint::Unknown);
        assert_eq!(a.conversion_hint(app,value,1),ConversionHint::Unknown);
    }

}
