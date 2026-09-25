# 7. Project: A Persistent Route Planner

Project chapters are where separate language ideas become one program.

This project builds a small route planner over an immutable graph.

It exercises:

- structures;
- inductive lists;
- maps/sets;
- higher-order functions;
- recursion;
- option/result values;
- pure state transitions.

## The world

Suppose we have named places connected by roads.

Rather than mutate a global graph, model the network as a value.

A simplified edge:

```proofscript
structure Road where {
  from: String;
  to: String;
}
```

A route is a list of place names.

## Why persistence helps

A search algorithm explores alternatives.

Persistent values let each branch receive a logical state without worrying
that another branch mutates it behind the scenes.

This is an excellent fit for recursive search.

## A search result

Use an explicit result:

```proofscript
inductive RouteResult where {
  | found(path: PsList(String));
  | unreachable;
};
```

Now failure is part of the function's contract.

## Visited nodes

A `PsSet(String)` can record visited places using an explicit comparison
function.

The implementation may be simple rather than maximally efficient; the point of
the project is to separate the search algorithm from the data representation.

## Worklist search

Conceptually, maintain a list of candidate paths.

Repeatedly:

1. take one path;
2. inspect its current end;
3. if it reaches the destination, return it;
4. otherwise add unseen neighbors as new candidate paths;
5. continue recursively.

This is breadth-first search if candidates are appended in queue order.

## Decompose the program

Prefer small helpers:

```text
neighbors
extendPath
alreadyVisited
searchRoutes
findRoute
```

The final function should read at the level of route search, not list
constructor mechanics.

## A proof opportunity

Once the basic program works, identify one invariant worth proving.

Examples:

- an extension preserves the original path prefix;
- the start node remains the first element of every candidate route;
- a found route is never empty.

Do not attempt to prove the entire graph algorithm at once.

A small reusable invariant is better proof engineering.

## Testing strategy

Build tiny graphs:

- start equals destination;
- one direct edge;
- a two-hop path;
- a disconnected graph;
- a cycle.

Type safety does not eliminate the need for behavioral tests.

## Exercise extensions

1. Return route length together with the path.
2. Add a deterministic tie-breaking rule.
3. Use a map from node to predecessor instead of carrying complete candidate
   paths.
4. State one theorem about a helper function and prove it with the current
   bounded tactic set.
5. Compare the persistent design with a hypothetical mutable queue/set design.
