import Ps.Kernel.Expr

/- Internal metadata. AlgebraicFamily entries are created only after checking
all constructor fields and covariance; the wire format cannot supply them. -/
inductive PsKernelOption (a : Type) where
  | none
  | some (value : a)

inductive PsKernelAlgInputConstructor where
  | constructor (name : PsKernelName) (type : PsKernelExpr)

inductive PsKernelAlgDeclaration where
  | declaration (name : PsKernelName) (parameters : PsKernelNatural)
      (type : PsKernelExpr) (constructors : PsKernelList PsKernelAlgInputConstructor)

inductive PsKernelAlgConstructor where
  | constructor (name : PsKernelName) (type : PsKernelExpr)
      (fields : PsKernelList PsKernelExpr)

inductive PsKernelAlgRule where
  | rule (constructor : PsKernelName) (constructorParameters minorIndex : PsKernelNatural)
      (recursiveFields : PsKernelList (PsKernelOption PsKernelName))

inductive PsKernelAlgBinder where
  | binder (id : PsKernelNatural) (type : PsKernelExpr) (visibility : PsKernelBinder)

inductive PsKernelAlgTargetReference where
  | reference (index : PsKernelNatural) (recursor : PsKernelName)

inductive PsKernelAlgTarget where
  | target (type : PsKernelExpr) (reference : PsKernelAlgTargetReference)
      (arguments : PsKernelList PsKernelExpr) (constructors : PsKernelList PsKernelAlgConstructor)

inductive PsKernelAlgMinor where
  | minor (target : PsKernelAlgTargetReference) (constructor : PsKernelName)
      (arguments fields : PsKernelList PsKernelExpr)
      (recursiveFields : PsKernelList (PsKernelOption PsKernelAlgTargetReference))

inductive PsKernelAlgHeader where
  | header (name : PsKernelName) (type : PsKernelExpr) (parameters : PsKernelNatural)
      (arguments : PsKernelList PsKernelExpr) (binders : PsKernelList PsKernelAlgBinder)
      (uniform : PsKernelExpr)
