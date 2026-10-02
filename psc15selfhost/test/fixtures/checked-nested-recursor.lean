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

inductive CheckedList (alpha : Type) where
  | nil
  | cons (head : alpha) (tail : CheckedList alpha)

def checkedListLength (values : CheckedList Nat) : Nat :=
  match values with
  | CheckedList.nil => 0
  | CheckedList.cons _ tail => Nat.succ (checkedListLength tail)

def checkedListExample : Nat :=
  checkedListLength (CheckedList.cons 7 (CheckedList.cons 9 CheckedList.nil))
