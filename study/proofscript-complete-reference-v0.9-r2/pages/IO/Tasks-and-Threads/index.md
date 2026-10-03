<a id="concurrency"></a>

# ProofScript — 21.11. Tasks and Threads

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Native IO separates a logical description from execution in a runtime environment. Console operations, mutable references, files, processes, clocks, randomness and tasks have exact APIs and effects. A file handle is a resource with identity and lifetime, not an immutable DTO. Browser, Node and Wasm hosts require explicit adapters; the existence of a Lean API does not establish that every target can implement it.

**Compiler and coverage boundary.** Retain native Task behavior rather than renaming Promise. Resource cleanup, cancellation, process termination and foreign failures need exact declared models; no undocumented async/await keyword is introduced.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [IO/Tasks-and-Threads/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/IO/Tasks-and-Threads/index.html). Source Git blob: `e0ebb353dc1c5d17bfc61430ee04727bf26fd392`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="LEAN_NUM_THREADS"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 21.11. Tasks and Threads

<a id="--tech-term-Tasks"></a>
*Tasks* are the fundamental primitive for writing multi-threaded code. A `Task α` represents a computation that, at some point, will [*resolve*](index.md#--tech-term-resolving-next) to a value of type `α`; it may be computed on a separate thread. When a task has resolved, its value can be read; attempting to get the value of a task before it resolves causes the current thread to block until the task has resolved. Tasks are similar to promises in JavaScript, `JoinHandle` in Rust, and `Future` in Scala.

Tasks may either carry out pure computations or `IO` actions. The API of pure tasks resembles that of [thunks](../../Basic-Types/Lazy-Computations/index.md#--tech-term-thunk): `Task.spawn` creates a `Task α` from a function in `Unit → α`, and `Task.get` waits until the function's value has been computed and then returns it. The value is cached, so subsequent requests do not need to recompute it. The key difference lies in when the computation occurs: while the values of thunks are not computed until they are forced, tasks execute opportunistically in a separate thread.

Tasks in `IO` are created using `IO.asTask`. Similarly, `BaseIO.asTask` and `EIO.asTask` create tasks in other `IO` monads. These tasks may have side effects, and can communicate with other tasks.

When the last reference to a task is dropped it is 
<a id="--tech-term-cancelled"></a>
*cancelled*. Pure tasks created with `Task.spawn` are terminated upon cancellation. Tasks spawned with `IO.asTask`, `EIO.asTask`, or `BaseIO.asTask` continue executing and must explicitly check for cancellation using `IO.checkCanceled`. Tasks may be explicitly cancelled using `IO.cancel`.

The Lean runtime maintains a thread pool for running tasks. The size of the thread pool is determined by the environment variable `LEAN_NUM_THREADS` if it is set, or by the number of logical processors on the current machine otherwise. The size of the thread pool is not a hard limit; in certain situations it may be exceeded to avoid deadlocks. By default, these threads are used to run tasks; each task has a 
<a id="--tech-term-priority"></a>
*priority* (`Task.Priority`), and higher-priority tasks take precedence over lower-priority tasks. Tasks may also be assigned to dedicated threads by spawning them with a sufficiently high priority.

<a id="Task"></a>

**type**

```text
Task.{u} (α : Type u) : Type u
```

`Task α` is a primitive for asynchronous computation. It represents a computation that will resolve to a value of type `α`, possibly being computed on another thread. This is similar to `Future` in Scala, `Promise` in Javascript, and `JoinHandle` in Rust.

The tasks have an overridden representation in the runtime.

<a id="The-Lean-Language-Reference--IO--Tasks-and-Threads--Creating-Tasks"></a>
### 21.11.1. Creating Tasks

Pure tasks should typically be created with `Task.spawn`, as `Task.pure` is a task that's already been resolved with the provided value. Impure tasks are created by one of the `asTask` actions.

<a id="The-Lean-Language-Reference--IO--Tasks-and-Threads--Creating-Tasks--Pure-Tasks"></a>
#### 21.11.1.1. Pure Tasks

Pure tasks may be created outside the `IO` family of monads. They are terminated when the last reference to them is dropped.

<a id="Task___spawn"></a>

**def**

```text
Task.spawn.{u} {α : Type u} (fn : Unit → α)
  (prio : Task.Priority := Task.Priority.default) : Task α
```

`spawn fn : Task α` constructs and immediately launches a new task for evaluating the function `fn () : α` asynchronously.

`prio`, if provided, is the priority of the task.

<a id="Task___pure"></a>

**constructor of Task**

```text
Task.pure.{u} {α : Type u} (get : α) : Task α
```

`Task.pure (a : α)` constructs a task that is already resolved with value `a`.

<a id="The-Lean-Language-Reference--IO--Tasks-and-Threads--Creating-Tasks--Impure-Tasks"></a>
#### 21.11.1.2. Impure Tasks

When spawning a task with side effects using one of the `asTask` functions, it's important to actually execute the resulting `IO` action. A task is spawned each time the resulting action is executed, not when `asTask` is called. Impure tasks continue running even when there are no references to them, though this does result in cancellation being requested. Cancellation may also be explicitly requested using `IO.cancel`. The impure task must check for cancellation using `IO.checkCanceled`.

<a id="BaseIO___asTask"></a>

**opaque**

```text
BaseIO.asTask {α : Type} (act : BaseIO α)
  (prio : Task.Priority := Task.Priority.default) : BaseIO (Task α)
```

Runs `act` in a separate `Task`, with priority `prio`.

Running the resulting `BaseIO` action causes the task to be started eagerly. Pure accesses to the `Task` do not influence the impure `act`.

Unlike pure tasks created by `Task.spawn`, tasks created by this function will run even if the last reference to the task is dropped. The `act` should explicitly check for cancellation via `IO.checkCanceled` if it should be terminated or otherwise react to the last reference being dropped.

<a id="EIO___asTask"></a>

**def**

```text
EIO.asTask {ε α : Type} (act : EIO ε α)
  (prio : Task.Priority := Task.Priority.default) :
  BaseIO (Task (Except ε α))
```

Runs `act` in a separate `Task`, with priority `prio`. Because `EIO ε` actions may throw an exception of type `ε`, the result of the task is an `Except ε α`.

Running the resulting `IO` action causes the task to be started eagerly. Pure accesses to the `Task` do not influence the impure `act`.

Unlike pure tasks created by `Task.spawn`, tasks created by this function will run even if the last reference to the task is dropped. The `act` should explicitly check for cancellation via `IO.checkCanceled` if it should be terminated or otherwise react to the last reference being dropped.

<a id="IO___asTask"></a>

**def**

```text
IO.asTask {α : Type} (act : IO α)
  (prio : Task.Priority := Task.Priority.default) :
  BaseIO (Task (Except IO.Error α))
```

Runs `act` in a separate `Task`, with priority `prio`. Because `IO` actions may throw an exception of type `IO.Error`, the result of the task is an `Except IO.Error α`.

Running the resulting `BaseIO` action causes the task to be started eagerly. Pure accesses to the `Task` do not influence the impure `act`. Because `IO` actions may throw an exception of type `IO.Error`, the result of the task is an `Except IO.Error α`.

Unlike pure tasks created by `Task.spawn`, tasks created by this function will run even if the last reference to the task is dropped. The `act` should explicitly check for cancellation via `IO.checkCanceled` if it should be terminated or otherwise react to the last reference being dropped.

<a id="The-Lean-Language-Reference--IO--Tasks-and-Threads--Creating-Tasks--Priorities"></a>
#### 21.11.1.3. Priorities

Task priorities are used by the thread scheduler to assign tasks to threads. Within the priority range `default`–`max`, higher-priority tasks always take precedence over lower-priority tasks. Tasks spawned with priority `dedicated` are assigned their own dedicated threads and do not contend with other tasks for the threads in the thread pool.

<a id="Task___Priority"></a>

**def**

```text
Task.Priority : Type
```

Task priority.

Tasks with higher priority will always be scheduled before tasks with lower priority. Tasks with a priority greater than `Task.Priority.max` are scheduled on dedicated threads.

<a id="Task___Priority___default"></a>

**def**

```text
Task.Priority.default : Task.Priority
```

The default priority for spawned tasks, also the lowest priority: `0`.

<a id="Task___Priority___max"></a>

**def**

```text
Task.Priority.max : Task.Priority
```

The highest regular priority for spawned tasks: `8`.

Spawning a task with a priority higher than `Task.Priority.max` is not an error but will spawn a dedicated worker for the task. This is indicated using `Task.Priority.dedicated`. Regular priority tasks are placed in a thread pool and worked on according to their priority order.

<a id="Task___Priority___dedicated"></a>

**def**

```text
Task.Priority.dedicated : Task.Priority
```

Indicates that a task should be scheduled on a dedicated thread.

Any priority higher than `Task.Priority.max` will result in the task being scheduled immediately on a dedicated thread. This is particularly useful for long-running and/or I/O-bound tasks since Lean will, by default, allocate no more non-dedicated workers than the number of cores to reduce context switches.

<a id="The-Lean-Language-Reference--IO--Tasks-and-Threads--Task-Results"></a>
### 21.11.2. Task Results

<a id="Task___get"></a>

**def**

```text
Task.get.{u} {α : Type u} (self : Task α) : α
```

Blocks the current thread until the given task has finished execution, and then returns the result of the task. If the current thread is itself executing a (non-dedicated) task, the maximum threadpool size is temporarily increased by one while waiting so as to ensure the process cannot be deadlocked by threadpool starvation. Note that when the current thread is unblocked, more tasks than the configured threadpool size may temporarily be running at the same time until sufficiently many tasks have finished.

`Task.map` and `Task.bind` should be preferred over `Task.get` for setting up task dependencies where possible as they do not require temporarily growing the threadpool in this way. In particular, calling `Task.get` in a task continuation with `(sync := true)` will panic as the continuation is decidedly not "cheap" in this case and deadlocks may otherwise occur. The waited-upon task should instead be returned and unwrapped using `Task.bind/IO.bindTask`.

<a id="IO___wait"></a>

**opaque**

```text
IO.wait {α : Type} (t : Task α) : BaseIO α
```

Waits for the task to finish, then returns its result.

<a id="IO___waitAny"></a>

**opaque**

```text
IO.waitAny {α : Type} (tasks : List (Task α))
  (h : tasks.length > 0 := by exact Nat.zero_lt_succ _) : BaseIO α
```

Waits until any of the tasks in the list has finished, then returns its result.

<a id="The-Lean-Language-Reference--IO--Tasks-and-Threads--Sequencing-Tasks"></a>
### 21.11.3. Sequencing Tasks

These operators create new tasks from old ones. When possible, it's good to use `Task.map` or `Task.bind` instead of manually calling `Task.get` in a new task because they don't temporarily increase the size of the thread pool.

<a id="Task___map"></a>

**def**

```text
Task.map.{u_1, u_2} {α : Type u_1} {β : Type u_2} (f : α → β)
  (x : Task α) (prio : Task.Priority := Task.Priority.default)
  (sync : Bool := false) : Task β
```

`map f x` maps function `f` over the task `x`: that is, it constructs (and immediately launches) a new task which will wait for the value of `x` to be available and then calls `f` on the result.

`prio`, if provided, is the priority of the task. If `sync` is set to true, `f` is executed on the current thread if `x` has already finished and otherwise on the thread that `x` finished on. `prio` is ignored in this case. This should only be done when executing `f` is cheap and non-blocking.

<a id="Task___bind"></a>

**def**

```text
Task.bind.{u_1, u_2} {α : Type u_1} {β : Type u_2} (x : Task α)
  (f : α → Task β) (prio : Task.Priority := Task.Priority.default)
  (sync : Bool := false) : Task β
```

`bind x f` does a monad "bind" operation on the task `x` with function `f`: that is, it constructs (and immediately launches) a new task which will wait for the value of `x` to be available and then calls `f` on the result, resulting in a new task which is then run for a result.

`prio`, if provided, is the priority of the task. If `sync` is set to true, `f` is executed on the current thread if `x` has already finished and otherwise on the thread that `x` finished on. `prio` is ignored in this case. This should only be done when executing `f` is cheap and non-blocking.

<a id="Task___mapList"></a>

**def**

```text
Task.mapList.{u_1, u_2} {α : Type u_1} {β : Type u_2} (f : List α → β)
  (tasks : List (Task α))
  (prio : Task.Priority := Task.Priority.default)
  (sync : Bool := false) : Task β
```

Creates a task that, when all `tasks` have finished, computes the result of `f` applied to their results.

<a id="BaseIO___mapTask"></a>

**opaque**

```text
BaseIO.mapTask.{u_1} {α : Type u_1} {β : Type} (f : α → BaseIO β)
  (t : Task α) (prio : Task.Priority := Task.Priority.default)
  (sync : Bool := false) : BaseIO (Task β)
```

Creates a new task that waits for `t` to complete and then runs the `BaseIO` action `f` on its result. This new task has priority `prio`.

Running the resulting `BaseIO` action causes the task to be started eagerly. Unlike pure tasks created by `Task.spawn`, tasks created by this function will run even if the last reference to the task is dropped. The `act` should explicitly check for cancellation via `IO.checkCanceled` if it should be terminated or otherwise react to the last reference being dropped.

<a id="EIO___mapTask"></a>

**def**

```text
EIO.mapTask.{u_1} {α : Type u_1} {ε β : Type} (f : α → EIO ε β)
  (t : Task α) (prio : Task.Priority := Task.Priority.default)
  (sync : Bool := false) : BaseIO (Task (Except ε β))
```

Creates a new task that waits for `t` to complete and then runs the `IO` action `f` on its result. This new task has priority `prio`.

Running the resulting `BaseIO` action causes the task to be started eagerly. Unlike pure tasks created by `Task.spawn`, tasks created by this function will run even if the last reference to the task is dropped. The `act` should explicitly check for cancellation via `IO.checkCanceled` if it should be terminated or otherwise react to the last reference being dropped. Because `EIO ε` actions may throw an exception of type `ε`, the result of the task is an `Except ε α`.

<a id="IO___mapTask"></a>

**def**

```text
IO.mapTask.{u_1} {α : Type u_1} {β : Type} (f : α → IO β) (t : Task α)
  (prio : Task.Priority := Task.Priority.default)
  (sync : Bool := false) : BaseIO (Task (Except IO.Error β))
```

Creates a new task that waits for `t` to complete and then runs the `IO` action `f` on its result. This new task has priority `prio`.

Running the resulting `BaseIO` action causes the task to be started eagerly. Unlike pure tasks created by `Task.spawn`, tasks created by this function will run even if the last reference to the task is dropped. The `act` should explicitly check for cancellation via `IO.checkCanceled` if it should be terminated or otherwise react to the last reference being dropped. Because `IO` actions may throw an exception of type `IO.Error`, the result of the task is an `Except IO.Error α`.

<a id="BaseIO___mapTasks"></a>

**def**

```text
BaseIO.mapTasks.{u_1} {α : Type u_1} {β : Type} (f : List α → BaseIO β)
  (tasks : List (Task α))
  (prio : Task.Priority := Task.Priority.default)
  (sync : Bool := false) : BaseIO (Task β)
```

Creates a new task that waits for all the tasks in the list `tasks` to complete, and then runs the `IO` action `f` on their results. This new task has priority `prio`.

Running the resulting `BaseIO` action causes the task to be started eagerly. Unlike pure tasks created by `Task.spawn`, tasks created by this function will run even if the last reference to the task is dropped. The `act` should explicitly check for cancellation via `IO.checkCanceled` if it should be terminated or otherwise react to the last reference being dropped.

<a id="EIO___mapTasks"></a>

**def**

```text
EIO.mapTasks.{u_1} {α : Type u_1} {ε β : Type} (f : List α → EIO ε β)
  (tasks : List (Task α))
  (prio : Task.Priority := Task.Priority.default)
  (sync : Bool := false) : BaseIO (Task (Except ε β))
```

Creates a new task that waits for all the tasks in the list `tasks` to complete, and then runs the `EIO ε` action `f` on their results. This new task has priority `prio`.

Running the resulting `BaseIO` action causes the task to be started eagerly. Unlike pure tasks created by `Task.spawn`, tasks created by this function will run even if the last reference to the task is dropped. The `act` should explicitly check for cancellation via `IO.checkCanceled` if it should be terminated or otherwise react to the last reference being dropped.

<a id="IO___mapTasks"></a>

**def**

```text
IO.mapTasks.{u_1} {α : Type u_1} {β : Type} (f : List α → IO β)
  (tasks : List (Task α))
  (prio : Task.Priority := Task.Priority.default)
  (sync : Bool := false) : BaseIO (Task (Except IO.Error β))
```

`IO` specialization of `EIO.mapTasks`.

<a id="BaseIO___bindTask"></a>

**opaque**

```text
BaseIO.bindTask.{u_1} {α : Type u_1} {β : Type} (t : Task α)
  (f : α → BaseIO (Task β))
  (prio : Task.Priority := Task.Priority.default)
  (sync : Bool := false) : BaseIO (Task β)
```

Creates a new task that waits for `t` to complete, runs the `IO` action `f` on its result, and then continues as the resulting task. This new task has priority `prio`.

Running the resulting `BaseIO` action causes this new task to be started eagerly. Unlike pure tasks created by `Task.spawn`, tasks created by this function will run even if the last reference to the task is dropped. The `act` should explicitly check for cancellation via `IO.checkCanceled` if it should be terminated or otherwise react to the last reference being dropped.

<a id="EIO___bindTask"></a>

**def**

```text
EIO.bindTask.{u_1} {α : Type u_1} {ε β : Type} (t : Task α)
  (f : α → EIO ε (Task (Except ε β)))
  (prio : Task.Priority := Task.Priority.default)
  (sync : Bool := false) : BaseIO (Task (Except ε β))
```

Creates a new task that waits for `t` to complete, runs the `EIO ε` action `f` on its result, and then continues as the resulting task. This new task has priority `prio`.

Running the resulting `BaseIO` action causes this new task to be started eagerly. Unlike pure tasks created by `Task.spawn`, tasks created by this function will run even if the last reference to the task is dropped. The `act` should explicitly check for cancellation via `IO.checkCanceled` if it should be terminated or otherwise react to the last reference being dropped. Because `EIO ε` actions may throw an exception of type `ε`, the result of the task is an `Except ε α`.

<a id="IO___bindTask"></a>

**def**

```text
IO.bindTask.{u_1} {α : Type u_1} {β : Type} (t : Task α)
  (f : α → IO (Task (Except IO.Error β)))
  (prio : Task.Priority := Task.Priority.default)
  (sync : Bool := false) : BaseIO (Task (Except IO.Error β))
```

Creates a new task that waits for `t` to complete, runs the `IO` action `f` on its result, and then continues as the resulting task. This new task has priority `prio`.

Running the resulting `BaseIO` action causes this new task to be started eagerly. Unlike pure tasks created by `Task.spawn`, tasks created by this function will run even if the last reference to the task is dropped. The `act` should explicitly check for cancellation via `IO.checkCanceled` if it should be terminated or otherwise react to the last reference being dropped. Because `IO` actions may throw an exception of type `IO.Error`, the result of the task is an `Except IO.Error α`.

<a id="BaseIO___chainTask"></a>

**def**

```text
BaseIO.chainTask.{u_1} {α : Type u_1} (t : Task α) (f : α → BaseIO Unit)
  (prio : Task.Priority := Task.Priority.default)
  (sync : Bool := false) : BaseIO Unit
```

Creates a new task that waits for `t` to complete and then runs the `IO` action `f` on its result. This new task has priority `prio`.

This is a version of `BaseIO.mapTask` that ignores the result value.

Running the resulting `BaseIO` action causes the task to be started eagerly. Unlike pure tasks created by `Task.spawn`, tasks created by this function will run even if the last reference to the task is dropped. The `act` should explicitly check for cancellation via `IO.checkCanceled` if it should be terminated or otherwise react to the last reference being dropped.

<a id="EIO___chainTask"></a>

**def**

```text
EIO.chainTask.{u_1} {α : Type u_1} {ε : Type} (t : Task α)
  (f : α → EIO ε Unit) (prio : Task.Priority := Task.Priority.default)
  (sync : Bool := false) : EIO ε Unit
```

Creates a new task that waits for `t` to complete and then runs the `EIO ε` action `f` on its result. This new task has priority `prio`.

This is a version of `EIO.mapTask` that ignores the result value.

Running the resulting `EIO ε` action causes the task to be started eagerly. Unlike pure tasks created by `Task.spawn`, tasks created by this function will run even if the last reference to the task is dropped. The `act` should explicitly check for cancellation via `IO.checkCanceled` if it should be terminated or otherwise react to the last reference being dropped.

<a id="IO___chainTask"></a>

**def**

```text
IO.chainTask.{u_1} {α : Type u_1} (t : Task α) (f : α → IO Unit)
  (prio : Task.Priority := Task.Priority.default)
  (sync : Bool := false) : IO Unit
```

Creates a new task that waits for `t` to complete and then runs the `IO` action `f` on its result. This new task has priority `prio`.

This is a version of `IO.mapTask` that ignores the result value.

Running the resulting `IO` action causes the task to be started eagerly. Unlike pure tasks created by `Task.spawn`, tasks created by this function will run even if the last reference to the task is dropped. The act should explicitly check for cancellation via `IO.checkCanceled` if it should be terminated or otherwise react to the last reference being dropped.

<a id="The-Lean-Language-Reference--IO--Tasks-and-Threads--Cancellation-and-Status"></a>
### 21.11.4. Cancellation and Status

Impure tasks should use `IO.checkCanceled` to react to cancellation, which occurs either as a result of `IO.cancel` or when the last reference to the task is dropped. Pure tasks are terminated automatically upon cancellation.

<a id="IO___cancel"></a>

**opaque**

```text
IO.cancel.{u_1} {α : Type u_1} : Task α → BaseIO Unit
```

Requests cooperative cancellation of the task. The task must explicitly call `IO.checkCanceled` to react to the cancellation.

<a id="IO___checkCanceled"></a>

**opaque**

```text
IO.checkCanceled : BaseIO Bool
```

Checks whether the current task's cancellation flag has been set by calling `IO.cancel` or by dropping the last reference to the task.

<a id="IO___hasFinished"></a>

**def**

```text
IO.hasFinished.{u_1} {α : Type u_1} (task : Task α) : BaseIO Bool
```

Checks whether the task has finished execution, at which point calling `Task.get` will return immediately.

<a id="IO___getTaskState"></a>

**opaque**

```text
IO.getTaskState.{u_1} {α : Type u_1} : Task α → BaseIO IO.TaskState
```

Returns the current state of a task in the Lean runtime's task manager.

For tasks derived from `Promise`s, the states `waiting` and `running` should be considered equivalent.

<a id="IO___TaskState___waiting"></a>

**inductive type**

```text
IO.TaskState : Type
```

The current state of a `Task` in the Lean runtime's task manager.

**Constructors**

```text
IO.TaskState.waiting : IO.TaskState
```

The `Task` is waiting to be run.

It can be waiting for dependencies to complete or sitting in the task manager queue waiting for a thread to run on.

```text
IO.TaskState.running : IO.TaskState
```

The `Task` is actively running on a thread or, in the case of a `Promise`, waiting for a call to `IO.Promise.resolve`.

```text
IO.TaskState.finished : IO.TaskState
```

The `Task` has finished running and its result is available. Calling `Task.get` or `IO.wait` on the task will not block.

<a id="IO___getTID"></a>

**opaque**

```text
IO.getTID : BaseIO UInt64
```

Returns the thread ID of the calling thread.

<a id="The-Lean-Language-Reference--IO--Tasks-and-Threads--Promises"></a>
### 21.11.5. Promises

Promises represent a value that will be supplied in the future. Supplying the value is called 
<a id="--tech-term-resolving-next"></a>
*resolving* the promise. Once created, a promise can be stored in a data structure or passed around like any other value, and attempts to read from it will block until it is resolved.

<a id="IO___Promise"></a>

**structure**

```text
IO.Promise (α : Type) : Type
```

`Promise α` allows you to create a `Task α` whose value is provided later by calling `resolve`.

Typical usage is as follows:

1. `let promise ← Promise.new` creates a promise
2. `promise.result? : Task (Option α)` can now be passed around
3. `promise.result?.get` blocks until the promise is resolved
4. `promise.resolve a` resolves the promise
5. `promise.result?.get` now returns `some a`

If the promise is dropped without ever being resolved, `promise.result?.get` will return `none`. See `Promise.result!/resultD` for other ways to handle this case.

<a id="IO___Promise___new"></a>

**opaque**

```text
IO.Promise.new {α : Type} [Nonempty α] : BaseIO (IO.Promise α)
```

Creates a new `Promise`.

<a id="IO___Promise___isResolved"></a>

**def**

```text
IO.Promise.isResolved {α : Type} (promise : IO.Promise α) : BaseIO Bool
```

Checks whether the promise has already been resolved, i.e. whether access to `result*` will return immediately.

<a id="IO___Promise___result___"></a>

**opaque**

```text
IO.Promise.result? {α : Type} (promise : IO.Promise α) : Task (Option α)
```

Like `Promise.result`, but resolves to `none` if the promise is dropped without ever being resolved.

<a id="IO___Promise___result___-next"></a>

**def**

```text
IO.Promise.result! {α : Type} (promise : IO.Promise α) : Task α
```

The result task of a `Promise`.

The task blocks until `Promise.resolve` is called. If the promise is dropped without ever being resolved, evaluating the task will panic and, when not using fatal panics, block forever. As `Promise.result!` is a pure value and thus the point of evaluation may not be known precisely, this means that any promise on which `Promise.result!` *may* be evaluated *must* be resolved eventually. When in doubt, always prefer `Promise.result?` to handle dropped promises explicitly.

<a id="IO___Promise___resultD"></a>

**def**

```text
IO.Promise.resultD {α : Type} (promise : IO.Promise α) (dflt : α) :
  Task α
```

Like `Promise.result`, but resolves to `dflt` if the promise is dropped without ever being resolved.

<a id="IO___Promise___resolve"></a>

**opaque**

```text
IO.Promise.resolve {α : Type} (value : α) (promise : IO.Promise α) :
  BaseIO Unit
```

Resolves a `Promise`.

Only the first call to this function has an effect.

<a id="The-Lean-Language-Reference--IO--Tasks-and-Threads--Communication-Between-Tasks"></a>
### 21.11.6. Communication Between Tasks

In addition to the types and operations described in this section, `IO.Ref` can be used as a lock. Taking the reference (using `take`) causes other threads to block when reading until the reference is `set` again. This pattern is described in [the section on reference cells](../Mutable-References/index.md#ref-locks).

<a id="The-Lean-Language-Reference--IO--Tasks-and-Threads--Communication-Between-Tasks--Channels"></a>
#### 21.11.6.1. Channels

The types and functions in this section are available after importing `Std.Sync.Channel`.

<a id="Std___Channel"></a>

**structure**

```text
Std.Channel (α : Type) : Type
```

A multi-producer multi-consumer FIFO channel that offers both bounded and unbounded buffering and an asynchronous API. To switch into synchronous mode use `Channel.sync`.

If a channel needs to be closed to indicate some sort of completion event use `Std.CloseableChannel` instead. Note that `Std.CloseableChannel` introduces a need for error handling in some cases, thus `Std.Channel` is usually easier to use if applicable.

<a id="Std___Channel___new"></a>

**def**

```text
Std.Channel.new {α : Type} (capacity : Option Nat := none) :
  BaseIO (Std.Channel α)
```

Create a new channel. If:

- `capacity` is `none` it will be unbounded (the default)
- `capacity` is `some 0` it will always force a rendezvous between sender and receiver
- `capacity` is `some n` with `n > 0` it will use a buffer of size `n` and begin blocking once it is filled

<a id="Std___Channel___send"></a>

**def**

```text
Std.Channel.send {α : Type} (ch : Std.Channel α) (v : α) :
  BaseIO (Task Unit)
```

Send a value through the channel, returning a task that will resolve once the transmission could be completed.

<a id="Std___Channel___recv"></a>

**def**

```text
Std.Channel.recv {α : Type} [Inhabited α] (ch : Std.Channel α) :
  BaseIO (Task α)
```

Receive a value from the channel, returning a task that will resolve once the transmission could be completed. Note that the task may resolve to `none` if the channel was closed before it could be completed.

<a id="Std___Channel___forAsync"></a>

**opaque**

```text
Std.Channel.forAsync {α : Type} [Inhabited α] (f : α → BaseIO Unit)
  (ch : Std.Channel α) (prio : Task.Priority := Task.Priority.default) :
  BaseIO (Task Unit)
```

`ch.forAsync f` calls `f` for every message received on `ch`.

Note that if this function is called twice, each message will only arrive at exactly one invocation.

<a id="Std___Channel___sync"></a>

**def**

```text
Std.Channel.sync {α : Type} (ch : Std.Channel α) : Std.Channel.Sync α
```

This function is a no-op and just a convenient way to expose the synchronous API of the channel.

<a id="Std___Channel___Sync"></a>

**def**

```text
Std.Channel.Sync (α : Type) : Type
```

A multi-producer multi-consumer FIFO channel that offers both bounded and unbounded buffering and a synchronous API. This type acts as a convenient layer to use a channel in a blocking fashion and is not actually different from the original channel.

If a channel needs to be closed to indicate some sort of completion event use `Std.CloseableChannel.Sync` instead. Note that `Std.CloseableChannel.Sync` introduces a need for error handling in some cases, thus `Std.Channel.Sync` is usually easier to use if applicable.

<a id="Std___CloseableChannel"></a>

**def**

```text
Std.CloseableChannel (α : Type) : Type
```

A multi-producer multi-consumer FIFO channel that offers both bounded and unbounded buffering and an asynchronous API, to switch into synchronous mode use `CloseableChannel.sync`.

Additionally `Std.CloseableChannel` can be closed if necessary, unlike `Std.Channel`. This introduces a need for error handling in some cases, thus it is usually easier to use `Std.Channel` if applicable.

<a id="Std___CloseableChannel___new"></a>

**def**

```text
Std.CloseableChannel.new {α : Type} (capacity : Option Nat := none) :
  BaseIO (Std.CloseableChannel α)
```

Create a new channel. If:

- `capacity` is `none` it will be unbounded (the default)
- `capacity` is `some 0` it will always force a rendezvous between sender and receiver
- `capacity` is `some n` with `n > 0` it will use a buffer of size `n` and begin blocking once it is filled

Synchronous channels can also be read using `for` loops. In particular, there is an instance of type `ForIn m (Std.Channel.Sync α) α` for every monad `m` with a `MonadLiftT BaseIO m` instance and `α` with an `Inhabited α` instance.

<a id="The-Lean-Language-Reference--IO--Tasks-and-Threads--Communication-Between-Tasks--Mutexes"></a>
#### 21.11.6.2. Mutexes

The types and functions in this section are available after importing `Std.Sync.Mutex`.

<a id="Std___Mutex"></a>

**type**

```text
Std.Mutex (α : Type) : Type
```

Mutual exclusion primitive (lock) guarding shared state of type `α`.

The type `Mutex α` is similar to `IO.Ref α`, except that concurrent accesses are guarded by a mutex instead of atomic pointer operations and busy-waiting.

<a id="Std___Mutex___new"></a>

**def**

```text
Std.Mutex.new {α : Type} (a : α) : BaseIO (Std.Mutex α)
```

Creates a new mutex.

<a id="Std___Mutex___atomically"></a>

**def**

```text
Std.Mutex.atomically {m : Type → Type} {α β : Type} [Monad m]
  [MonadLiftT BaseIO m] [MonadFinally m] (mutex : Std.Mutex α)
  (k : Std.AtomicT α m β) : m β
```

`mutex.atomically k` runs `k` with access to the mutex's state while locking the mutex.

Calling `mutex.atomically` while already holding the underlying `BaseMutex` in the same thread is undefined behavior. If this is unavoidable in your code, consider using `RecursiveMutex`.

<a id="Std___Mutex___atomicallyOnce"></a>

**def**

```text
Std.Mutex.atomicallyOnce {m : Type → Type} {α β : Type} [Monad m]
  [MonadLiftT BaseIO m] [MonadFinally m] (mutex : Std.Mutex α)
  (condvar : Std.Condvar) (pred : Std.AtomicT α m Bool)
  (k : Std.AtomicT α m β) : m β
```

`mutex.atomicallyOnce condvar pred k` runs `k`, waiting on `condvar` until `pred` returns true. Both `k` and `pred` have access to the mutex's state.

Calling `mutex.atomicallyOnce` while already holding the underlying `BaseMutex` in the same thread is undefined behavior. If this is unavoidable in your code, consider using `RecursiveMutex`.

<a id="Std___AtomicT"></a>

**def**

```text
Std.AtomicT (σ : Type) (m : Type → Type) (α : Type) : Type
```

`AtomicT α m` is the monad that can be atomically executed inside mutual exclusion primitives like `Mutex α` with outside monad `m`. The action has access to the state `α` of the mutex (via `get` and `set`).

<a id="The-Lean-Language-Reference--IO--Tasks-and-Threads--Communication-Between-Tasks--Condition-Variables"></a>
#### 21.11.6.3. Condition Variables

The types and functions in this section are available after importing `Std.Sync.Mutex`.

<a id="Std___Condvar"></a>

**def**

```text
Std.Condvar : Type
```

Condition variable, a synchronization primitive to be used with a `BaseMutex` or `Mutex`.

The thread that wants to modify the shared variable must:

1. Lock the `BaseMutex` or `Mutex`
2. Work on the shared variable
3. Call `Condvar.notifyOne` or `Condvar.notifyAll` after it is done. Note that this may be done before or after the mutex is unlocked.

If working with a `Mutex` the thread that waits on the `Condvar` can use `Mutex.atomicallyOnce` to wait until a condition is true. If working with a `BaseMutex` it must:

1. Lock the `BaseMutex`.
2. Do one of the following:

- Use `Condvar.waitUntil` to (potentially repeatedly wait) on the condition variable until the condition is true.
- Implement the waiting manually by:

   

  1. Checking the condition
  2. Calling `Condvar.wait` which releases the `BaseMutex` and suspends execution until the condition variable is notified.
  3. Check the condition and resume waiting if not satisfied.

<a id="Std___Condvar___new"></a>

**opaque**

```text
Std.Condvar.new : BaseIO Std.Condvar
```

Creates a new condition variable.

<a id="Std___Condvar___wait"></a>

**opaque**

```text
Std.Condvar.wait (condvar : Std.Condvar) (mutex : Std.BaseMutex) :
  BaseIO Unit
```

Waits until another thread calls `notifyOne` or `notifyAll`.

<a id="Std___Condvar___notifyOne"></a>

**opaque**

```text
Std.Condvar.notifyOne (condvar : Std.Condvar) : BaseIO Unit
```

Wakes up a single other thread executing `wait`.

<a id="Std___Condvar___notifyAll"></a>

**opaque**

```text
Std.Condvar.notifyAll (condvar : Std.Condvar) : BaseIO Unit
```

Wakes up all other threads executing `wait`.

<a id="Std___Condvar___waitUntil"></a>

**def**

```text
Std.Condvar.waitUntil.{u_1} {m : Type → Type u_1} [Monad m]
  [MonadLiftT BaseIO m] (condvar : Std.Condvar) (mutex : Std.BaseMutex)
  (pred : m Bool) : m Unit
```

Waits on the condition variable until the predicate is true.
