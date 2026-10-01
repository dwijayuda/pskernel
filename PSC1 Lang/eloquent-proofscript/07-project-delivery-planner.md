# 7. Project: A Delivery Planner

The first project combines the language features from the opening chapters into
one pure state machine.

The goal is not to reproduce the JavaScript robot project. It is to practice:

- structures;
- inductives;
- persistent state;
- lists;
- recursion;
- small helper functions;
- invariants that can later become theorems.

## The world

We model a small route network.

```proofscript
inductive Place where {
  | depot;
  | north;
  | south;
  | east;
  | west;
};
```

A delivery has a current location and a destination.

```proofscript
structure Parcel where {
  at: Place;
  target: Place;
}
```

A planner state contains the robot's location and remaining parcels.

```proofscript
structure DeliveryState where {
  robot: Place;
  parcels: PsList(Parcel);
}
```

## Pure transitions

Rather than mutating one shared world object, each step returns a new state.

Conceptually:

```text
step : DeliveryState -> Place -> DeliveryState
```

This style has an important property: if computation fails while constructing
the next state, the previous state remains available.

That becomes useful later when we discuss errors and rollback.

## A route

Start with a fixed route:

```proofscript
function fixedRoute(): PsList(Place) :=
  PsList.cons(
    Place.north,
    PsList.cons(
      Place.east,
      PsList.cons(Place.south, PsList.nil)
    )
  );
```

The exact route is not important. What matters is that the route is ordinary
data that can be transformed, inspected, and tested.

## Counting work

A simple recursive helper:

```proofscript
function remaining {α: Type}(xs: PsList(α)): Nat :=
  match xs with {
    | .nil => 0;
    | .cons head tail => 1 + remaining(tail);
  };
```

This gives us a measurable progress quantity.

## Invariants worth proving

After the program works, useful proof targets include:

- delivering a parcel never creates an extra parcel;
- moving without delivering preserves the parcel count;
- a finished state has no remaining parcels;
- a fixed route function is deterministic.

Do not prove all of these before the program exists.

The project demonstrates a productive order:

```text
model
-> executable functions
-> tests/examples
-> identify stable invariants
-> prove the valuable ones
```

## Extension: route search

A more advanced planner can use ordered `PsMap` and `PsSet` to record:

- adjacency;
- visited places;
- frontier state.

That is a good exercise for the current compiler-oriented collection libraries.

## Exercises

1. Implement `placeEq(a, b): Bool` by matching on both values using the
   equality mechanism available in your local PSC1 baseline.
2. Implement `parcelCount`.
3. Implement a function that removes parcels whose target equals the robot's
   current place.
4. Add a theorem about a helper whose result is definitionally obvious enough
   for `rfl`.
5. Refactor the project into at least two modules and make dependencies
   explicit.
