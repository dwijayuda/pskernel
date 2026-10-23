-- Prod, its constructor and projections belong to the checked Essential Core
-- prelude. This module extends that identity; redeclaring it would conflict
-- when imported by ordinary PSC1 projects.

def product {α : Type} {β : Type}
    (first : α) (second : β) : Prod α β :=
  Prod.mk first second

def productFst {α : Type} {β : Type}
    (value : Prod α β) : α :=
  value.fst

def productSnd {α : Type} {β : Type}
    (value : Prod α β) : β :=
  value.snd

def productSwap {α : Type} {β : Type}
    (value : Prod α β) : Prod β α :=
  Prod.mk value.snd value.fst
