import Ps.Foundation.Name

-- Checked source registrations. The declaration identity is resolved against
-- the current environment; stored types or bodies cannot become stale when
-- proof abstraction finalizes the actual declarations.
inductive PsSimpEntryKind where
  | proof
  | unfoldDefinition
  deriving BEq

structure PsSimpEntry where
  name : PsName
  kind : PsSimpEntryKind
  priority : Nat := 1000

def psSimpEntriesMerge (left right : List PsSimpEntry) : List PsSimpEntry :=
  right.foldl (fun entries entry =>
    if entries.any (fun prior => psNameEq prior.name entry.name) then entries
    else entries ++ [entry]) left

def psSimpEntriesAdd (entries : List PsSimpEntry) (entry : PsSimpEntry) :
    List PsSimpEntry :=
  entry :: entries.filter (fun prior => !psNameEq prior.name entry.name)
