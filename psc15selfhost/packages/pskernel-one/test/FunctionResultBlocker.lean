inductive OneTree where
  | leaf
  | branch (child : OneTree)

def oneTreeEqual (left : OneTree) : OneTree -> Bool :=
  match left with
  | OneTree.leaf =>
      fun (right : OneTree) =>
        match right with
        | OneTree.leaf => true
        | OneTree.branch _ => false
  | OneTree.branch child =>
      let smaller : OneTree -> Bool := oneTreeEqual child;
      fun (right : OneTree) =>
        match right with
        | OneTree.leaf => false
        | OneTree.branch other => smaller other

def oneTreeUse (left right : OneTree) : Bool :=
  oneTreeEqual left right
