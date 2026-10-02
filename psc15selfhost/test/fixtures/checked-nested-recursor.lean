inductive CheckedTree where
  | leaf (value : Nat)
  | branch (children : List (Prod Nat CheckedTree)) (optional : Option CheckedTree)
      (pair : Prod CheckedTree (List CheckedTree)) (direct : CheckedTree)

def checkedTreeRoot (tree : CheckedTree) : Nat :=
  match tree with
  | CheckedTree.leaf value => value
  | CheckedTree.branch _ _ _ direct => checkedTreeRoot direct

def checkedTreeExample : Nat :=
  checkedTreeRoot (CheckedTree.branch List.nil Option.none
    (Prod.mk (CheckedTree.leaf 11) List.nil) (CheckedTree.leaf 42))
