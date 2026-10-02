[![Previous](previous_motif.svg)](parallelism.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](language.html)

* * *

# Chapter 10 Memory model: The hard bits

  * [10.1 Why weakly consistent memory?](memorymodel.html#s%3Awhy_relaxed_memory)
  * [10.2 Data race freedom implies sequential consistency](memorymodel.html#s%3Adrf_sc)
  * [10.3 Reasoning with DRF-SC](memorymodel.html#s%3Adrf_reasoning)
  * [10.4 Local data race freedom](memorymodel.html#s%3Alocal_drf)
  * [10.5 An operational view of the memory model](memorymodel.html#s%3Amm_semantics)
  * [10.6 Non-compliant operations](memorymodel.html#s%3Amm_tearing)

This chapter describes the details of OCaml relaxed memory model. The relaxed
memory model describes what values an OCaml program is allowed to witness when
reading a memory location. If you are interested in high-level parallel
programming in OCaml, please have a look at the parallel programming chapter
[9](parallelism.html#c%3Aparallelism).

This chapter is aimed at experts who would like to understand the details of
the OCaml memory model from a practitioner’s perspective. For a formal
definition of the OCaml memory model, its guarantees and the compilation to
hardware memory models, please have a look at the PLDI 2018 paper on [Bounding
Data Races in Space and Time](https://doi.org/10.1145/3192366.3192421). The
memory model presented in this chapter is an extension of the one presented in
the PLDI 2018 paper. This chapter also covers some pragmatic aspects of the
memory model that are not covered in the paper.

## ﻿10.1 Why weakly consistent memory?

The simplest memory model that we could give to our programs is sequential
consistency. Under sequential consistency, the values observed by the program
can be explained through some interleaving of the operations from different
domains in the program. For example, consider the following program with two
domains d1 and d2 executing in parallel:

let d1 a b = let r1 = !a * 2 in let r2 = !b in let r3 = !a * 2 in (r1, r2, r3)
let d2 b = b := 0 let main () = let a = ref 1 in let b = ref 1 in let h =
Domain.spawn (fun _ -> let r1, r2, r3 = d1 a b in Printf.printf "r1 = %d, r2 =
%d, r3 = %d\n" r1 r2 r3) in d2 b; Domain.join h

The reference cells a and b are initially 1. The user may observe r1 = 2, r2 =
0, r3 = 2 if the write to b in d2 occurred before the read of b in d1. Here,
the observed behaviour can be explained in terms of interleaving of the
operations from different domains.

Let us now assume that a and b are aliases of each other.

let d1 a b = let r1 = !a * 2 in let r2 = !b in let r3 = !a * 2 in (r1, r2, r3)
let d2 b = b := 0 let main () = let ab = ref 1 in let h = Domain.spawn (fun _
-> let r1, r2, r3 = d1 ab ab in assert (not (r1 = 2 && r2 = 0 && r3 = 2))) in
d2 ab; Domain.join h

In the above program, the variables ab, a and b refer to the same reference
cell. One would expect that the assertion in the main function will never
fail. The reasoning is that if r2 is 0, then the write in d2 occurred before
the read of b in d1. Given that a and b are aliases, the second read of a in
d1 should also return 0.

### ﻿10.1.1 Compiler optimisations

Surprisingly, this assertion may fail in OCaml due to compiler optimisations.
The OCaml compiler observes the common sub-expression !a * 2 in d1 and
optimises the program to:

let d1 a b = let r1 = !a * 2 in let r2 = !b in let r3 = r1 in (* CSE: !a * 2
==> r1 *) (r1, r2, r3) let d2 b = b := 0 let main () = let ab = ref 1 in let h
= Domain.spawn (fun _ -> let r1, r2, r3 = d1 ab ab in assert (not (r1 = 2 &&
r2 = 0 && r3 = 2))) in d2 ab; Domain.join h

This optimisation is known as the common sub-expression elimination (CSE).
Such optimisations are valid and necessary for good performance, and do not
change the sequential meaning of the program. However, CSE breaks sequential
reasoning.

In the optimized program above, even if the write to b in d2 occurs between
the first and the second reads in d1, the program will observe the value 2 for
r3, causing the assertion to fail. The observed behaviour cannot be explained
by interleaving of operations from different domains in the source program.
Thus, CSE optimization is said to be invalid under sequential consistency.

One way to explain the observed behaviour is as if the operations performed on
a domain were reordered. For example, if the second and the third reads from
d1 were reordered,

let d1 a b = let r1 = !a * 2 in let r3 = !a * 2 in let r2 = !b in (r1, r2, r3)

then we can explain the observed behaviour (2,0,2) returned by d1.

### ﻿10.1.2 Hardware optimisations

The other source of reordering is by the hardware. Modern hardware
architectures have complex cache hierarchies with multiple levels of cache.
While cache coherence ensures that reads and writes to a single memory
location respect sequential consistency, the guarantees on programs that
operate on different memory locations are much weaker. Consider the following
program:

let a = ref 0 and b = ref 0 let d1 () = a := 1; !b let d2 () = b := 1; !a let
main () = let h = Domain.spawn d2 in let r1 = d1 () in let r2 = Domain.join h
in assert (not (r1 = 0 && r2 = 0))

Under sequential consistency, we would never expect the assertion to fail.
However, even on x86, which offers much stronger guarantees than ARM, the
writes performed at a CPU core are not immediately published to all of the
other cores. Since a and b are different memory locations, the reads of a and
b may both witness the initial values, leading to the assertion failure.

This behaviour can be explained if a load is allowed to be reordered before a
preceding store to a different memory location. This reordering can happen due
to the presence of in-core store-buffers on modern processors. Each core
effectively has a FIFO buffer of pending writes to avoid the need to block
while a write completes. The writes to a and b may be in the store-buffers of
cores c1 and c2 running the domains d1 and d2, respectively. The reads of b
and a running on the cores c1 and c2, respectively, will not see the writes if
the writes have not propagated from the buffers to the main memory.

## ﻿10.2 Data race freedom implies sequential consistency

The aim of the OCaml relaxed memory model is to precisely describe which
orders are preserved by the OCaml program. The compiler and the hardware are
free to optimize the program as long as they respect the ordering guarantees
of the memory model. While programming directly under the relaxed memory model
is difficult, the memory model also describes the conditions under which a
program will only exhibit sequentially consistent behaviours. This guarantee
is known as _data race freedom implies sequential consistency_ (DRF-SC). In
this section, we shall describe this guarantee. In order to do this, we first
need a number of definitions.

### ﻿10.2.1 Memory locations

OCaml classifies memory locations into _atomic_ and _non-atomic_ locations.
Reference cells, array fields and mutable record fields are non-atomic memory
locations. Immutable objects are non-atomic locations with an initialising
write but no further updates. Atomic memory locations are those that are
created using the [Atomic](libref/Atomic.html) module.

### ﻿10.2.2 Happens-before relation

Let us imagine that the OCaml programs are executed by an abstract machine
that executes one action at a time, arbitrarily picking one of the available
domains at each step. We classify actions into two: _inter-domain_ and _intra-
domain_. An inter-domain action is one which can be observed and be influenced
by actions on other domains. There are several inter-domain actions:

  * Reads and writes of atomic and non-atomic locations. 
  * Spawn and join of domains. 
  * Operations on mutexes. 

On the other hand, intra-domain actions can neither be observed nor influence
the execution of other domains. Examples include evaluating an arithmetic
expression, calling a function, etc. The memory model specification ignores
such intra-domain actions. In the sequel, we use the term action to indicate
inter-domain actions.

A totally ordered list of actions executed by the abstract machine is called
an _execution trace_. There might be several possible execution traces for a
given program due to non-determinism.

For a given execution trace, we define an irreflexive, transitive _happens-
before relation_ that captures the causality between actions in the OCaml
program. The happens-before relation is defined as the smallest transitive
relation satisfying the following properties:

  * We define the order in which a domain executes its actions as the _program order_. If an action x precedes another action y in program order, then x precedes y in happens-before order. 
  * If x is a write to an atomic location and y is a subsequent read or write to that memory location in the execution trace, then x precedes y in happens-before order. For atomic locations, compare_and_set, fetch_and_add, exchange, incr and decr are considered to perform both a read and a write. 
  * If x is Domain.spawn f and y is the first action in the newly spawned domain executing f, then x precedes y in happens-before order. 
  * If x is the last action in a domain d and y is Domain.join d, then x precedes y in happens-before order. 
  * If x is an unlock operation on a mutex, and y is any subsequent operation on the mutex in the execution trace, then x precedes y in happens-before order. 

### ﻿10.2.3 Data race

In a given trace, two actions are said to be _conflicting_ if they access the
same non-atomic location, at least one is a write and neither is an
initialising write to that location.

We say that a program has a _data race_ if there exists some execution trace
of the program with two conflicting actions and there does not exist a
happens-before relationship between the conflicting accesses. A program
without data races is said to be _correctly synchronised_.

### ﻿10.2.4 DRF-SC

DRF-SC guarantee: A program without data races will only exhibit sequentially
consistent behaviours.

DRF-SC is a strong guarantee for the programmers. Programmers can use
_sequential reasoning_ i.e., reasoning by executing one inter-domain action
after the other, to identify whether their program has a data race. In
particular, they do not need to reason about reorderings described in section
10.1 in order to determine whether their program has a data race. Once the
determination that a particular program is data race free is made, they do not
need to worry about reorderings in their code.

## ﻿10.3 Reasoning with DRF-SC

In this section, we will look at examples of using DRF-SC for program
reasoning. In this section, we will use the functions with names dN to
represent domains executing in parallel with other domains. That is, we assume
that there is a main function that runs the dN functions in parallel as
follows:

    
    
    let main () =
      let h1 = Domain.spawn d1 in
      let h2 = Domain.spawn d2 in
      ...
      ignore @@ Domain.join h1;
      ignore @@ Domain.join h2
    

Here is a simple example with a data race:

(* Has data race *) let r = ref 0 let d1 () = r := 1 let d2 () = !r

r is a non-atomic reference. The two domains race to access the reference, and
d1 is a write. Since there is no happens-before relationship between the
conflicting accesses, there is a data race.

Both of the programs that we had seen in the section 10.1 have data races. It
is no surprise that they exhibit non sequentially consistent behaviours.

Accessing disjoint array indices and fields of a record in parallel is not a
data race. For example,

(* No data race *) let a = [| 0; 1 |] let d1 () = a.(0) <\- 42 let d2 () =
a.(1) <\- 42

(* No data race *) type t = { mutable a : int; mutable b : int } let r = {a =
0; b = 1} let d1 () = r.a <\- 42 let d2 () = r.b <\- 42

do not have data races.

Races on atomic locations do not lead to a data race.

(* No data race *) let r = Atomic.make 0 let d1 () = Atomic.set r 1 let d2 ()
= Atomic.get r

#### ﻿Message-passing

Atomic variables may be used for implementing non-blocking communication
between domains.

(* No data race *) let msg = ref 0 let flag = Atomic.make false let d1 () =
msg := 42; (* a *) Atomic.set flag true (* b *) let d2 () = if Atomic.get flag
(* c *) then !msg (* d *) else 0

Observe that the actions a and d write and read from the same non-atomic
location msg, respectively, and hence are conflicting. We need to establish
that a and d have a happens-before relationship in order to show that this
program does not have a data race.

The action a precedes b in program order, and hence, a happens-before b.
Similarly, c happens-before d. If d2 observes the atomic variable flag to be
true, then b precedes c in happens-before order. Since happens-before is
transitive, the conflicting actions a and d are in happens-before order. If d2
observes the flag to be false, then the read of msg is not done. Hence, there
is no conflicting access in this execution trace. Hence, the program does not
have a data race.

The following modified version of the message passing program does have a data
race.

(* Has data race *) let msg = ref 0 let flag = Atomic.make false let d1 () =
msg := 42; (* a *) Atomic.set flag true (* b *) let d2 () = ignore (Atomic.get
flag); (* c *) !msg (* d *)

The domain d2 now unconditionally reads the non-atomic reference msg. Consider
the execution trace:

    
    
    Atomic.get flag; (* c *)
    !msg; (* d *)
    msg := 42; (* a *)
    Atomic.set flag true (* b *)
    

In this trace, d and a are conflicting operations. But there is no happens-
before relationship between them. Hence, this program has a data race.

## ﻿10.4 Local data race freedom

The OCaml memory model offers strong guarantees even for programs with data
races. It offers what is known as _local data race freedom sequential
consistency (LDRF-SC)_ guarantee. A formal definition of this property is
beyond the scope of this manual chapter. Interested readers are encouraged to
read the PLDI 2018 paper on [Bounding Data Races in Space and
Time](https://doi.org/10.1145/3192366.3192421).

Informally, LDRF-SC says that the data race free parts of the program remain
sequentially consistent. That is, even if the program has data races, those
parts of the program that are disjoint from the parts with data races are
amenable to sequential reasoning.

Consider the following snippet:

let snippet () = let c = ref 0 in c := 42; let a = !c in (a, c)

Observe that c is a newly allocated reference. Can the read of c return a
value which is not 42? That is, can a ever be not 42? Surprisingly, in the C++
and Java memory models, the answer is yes. With the C++ memory model, if the
program has a data race, even in unrelated parts, then the semantics is
undefined. If this snippet were linked with a library that had a data race,
then, under the C++ memory model, the read may return any value. Since data
races on unrelated locations can affect program behaviour, we say that C++
memory model is not bounded in space.

Unlike C++, Java memory model is bounded in space. But Java memory model is
not bounded in time; data races in the future will affect the past behaviour.
For example, consider the translation of this example to Java. We assume a
prior definition of Class c {int x;} and a shared _non-volatile_ variable C g.
Now the snippet may be part of a larger program with parallel threads:

    
    
    (* Thread 1 *)
    C c = new C();
    c.x = 42;
    a = c.x;
    g = c;
    
    (* Thread 2 *)
    g.x = 7;
    

The read of c.x and the write of g in the first thread are done on separate
memory locations. Hence, the Java memory model allows them to be reordered. As
a result, the write in the second thread may occur before the read of c.x, and
hence, c.x returns 7.

The OCaml equivalent of the Java code above is:

let g = ref None let snippet () = let c = ref 0 in c := 42; let a = !c in (a, c) let d1 () = let (a,c) = snippet () in g := Some c; a let d2 () = match !g with | None -> () | Some c -> c := 7

Observe that there is a data race on both g and c. Consider only the first
three instructions in snippet:

    
    
    let c = ref 0 in
    c := 42;
    let a = !c in
    ...
    

The OCaml memory model is bounded both in space and time. The only memory
location here is c. Reasoning only about this snippet, there is neither the
data race in space (the race on g) nor in time (the future race on c). Hence,
the snippet will have sequentially consistent behaviour, and the value
returned by !c will be 42.

The OCaml memory model guarantees that even for programs with data races,
memory safety is preserved. While programs with data races may observe non-
sequentially consistent behaviours, they will not crash.

## ﻿10.5 An operational view of the memory model

In this section, we describe the semantics of the OCaml memory model. A formal
definition of the operational view of the memory model is presented in section
3 of the PLDI 2018 paper on [Bounding Data Races in Space and
Time](https://doi.org/10.1145/3192366.3192421). This section presents an
informal description of the memory model with the help of an example.

Given an OCaml program, which may possibly contain data races, the operational
semantics tells you the values that may be observed by the read of a memory
location. For simplicity, we restrict the intra-thread actions to just the
accesses to atomic and non-atomic locations, ignoring domain spawn and join
operations, and the operations on mutexes.

We describe the semantics of the OCaml memory model in a straightforward
small-step operational manner. That is, the semantics is described by an
abstract machine that executes one action at a time, arbitrarily picking one
of the available domains at each step. This is similar to the abstract machine
that we had used to describe the happens-before relationship in section
10.2.2.

### ﻿10.5.1 Non-atomic locations

In the semantics, we model non-atomic locations as finite maps from timestamps
t to values v. We take timestamps to be rational numbers. The timestamps are
totally ordered but dense; there is a timestamp between any two others.

For example,

    
    
    a: [t1 -> 1; t2 -> 2]
    b: [t3 -> 3; t4 -> 4; t5 -> 5]
    c: [t6 -> 5; t7 -> 6; t8 -> 7]
    

represents three non-atomic locations a, b and c and their histories. The
location a has two writes at timestamps t1 and t2 with values 1 and 2,
respectively. When we write a: [t1 -> 1; t2 -> 2], we assume that t1 < t2. We
assume that the locations are initialised with a history that has a single
entry at timestamp 0 that maps to the initial value.

### ﻿10.5.2 Domains

Each domain is equipped with a _frontier_ , which is a map from non-atomic
locations to timestamps. Intuitively, each domain’s frontier records, for each
non-atomic location, the latest write known to the thread. More recent writes
may have occurred, but are not guaranteed to be visible.

For example,

    
    
    d1: [a -> t1; b -> t3; c -> t7]
    d2: [a -> t1; b -> t4; c -> t7]
    

represents two domains d1 and d2 and their frontiers.

A created domain inherits the frontier of its creator domain at the point
Domain.spawn is called.

### ﻿10.5.3 Non-atomic accesses

Let us now define the semantics of non-atomic reads and writes. Suppose domain
d1 performs the read of b. For non-atomic reads, the domains may read an
arbitrary element of the history for that location, as long as it is not older
than the timestamp in the domains’s frontier. In this case, since d1 frontier
at b is at t3, the read may return the value 3, 4 or 5. A non-atomic read does
not change the frontier of the current domain.

Suppose domain d2 writes the value 10 to c (c := 10). We pick a new timestamp
t9 for this write such that it is later than d2’s frontier at c. Note a
subtlety here: this new timestamp might not be later than everything else in
the history, but merely later than any other write known to the writing
domain. Hence, t9 may be inserted in c’s history either (a) between t7 and t8
or (b) after t8. Let us pick the former option for our discussion. Since the
new write appears after all the writes known by the domain d2 to the location
c, d2’s frontier at c is also updated. The new state of the abstract machine
is:

    
    
    (* Non-atomic locations *)
    a: [t1 -> 1; t2 -> 2]
    b: [t3 -> 3; t4 -> 4; t5 -> 5]
    c: [t6 -> 5; t7 -> 6; t9 -> 10; t8 -> 7] (* new write at t9 *)
    
    (* Domains *)
    d1: [a -> t1; b -> t3; c -> t7]
    d2: [a -> t1; b -> t4; c -> t9] (* frontier updated at c *)
    

### ﻿10.5.4 Atomic accesses

Atomic locations carry not only values but also synchronization information.
We model atomic locations as a pair of the value held by that location and a
frontier. The frontier models the synchronization information, which is merged
with the frontiers of threads that operate on the location. In this way, non-
atomic writes made by one thread can become known to another by communicating
via an atomic location.

For example,

    
    
    (* Atomic locations *)
    A: 10, [a -> t1; b -> t5; c -> t7]
    B: 5,  [a -> t2; b -> t4; c -> t6]
    

shows two atomic variables A and B with values 10 and 5, respectively, and
frontiers of their own. We use upper-case variable names to indicate atomic
locations.

During atomic reads, the frontier of the location is merged into that of the
domain performing the read. For example, suppose d1 reads B. The read returns
5, and d1’s frontier updated by merging it with B’s frontier, choosing the
later timestamp for each location. The abstract machine state before the
atomic read is:

    
    
    (* Non-atomic locations *)
    a: [t1 -> 1; t2 -> 2]
    b: [t3 -> 3; t4 -> 4; t5 -> 5]
    c: [t6 -> 5; t7 -> 6; t9 -> 10; t8 -> 7]
    
    (* Domains *)
    d1: [a -> t1; b -> t3; c -> t7]
    d2: [a -> t1; b -> t4; c -> t9]
    
    (* Atomic locations *)
    A: 10, [a -> t1; b -> t5; c -> t7]
    B: 5,  [a -> t2; b -> t4; c -> t6]
    

As a result of the atomic read, the abstract machine state is updated to:

    
    
    (* Non-atomic locations *)
    a: [t1 -> 1; t2 -> 2]
    b: [t3 -> 3; t4 -> 4; t5 -> 5]
    c: [t6 -> 5; t7 -> 6; t9 -> 10; t8 -> 7]
    
    (* Domains *)
    d1: [a -> t2; b -> t4; c -> t7] (* frontier updated at a and b *)
    d2: [a -> t1; b -> t4; c -> t9]
    
    (* Atomic locations *)
    A: 10, [a -> t1; b -> t5; c -> t7]
    B: 5,  [a -> t2; b -> t4; c -> t6]
    

During atomic writes, the value held by the atomic location is updated. The
frontiers of both the writing domain and that of the location being written to
are updated to the merge of the two frontiers. For example, if d2 writes 20 to
A in the current machine state, the machine state is updated to:

    
    
    (* Non-atomic locations *)
    a: [t1 -> 1; t2 -> 2]
    b: [t3 -> 3; t4 -> 4; t5 -> 5]
    c: [t6 -> 5; t7 -> 6; t9 -> 10; t8 -> 7]
    
    (* Domains *)
    d1: [a -> t2; b -> t4; c -> t7]
    d2: [a -> t1; b -> t5; c -> t9] (* frontier updated at b *)
    
    (* Atomic locations *)
    A: 20, [a -> t1; b -> t5; c -> t9] (* value updated. frontier updated at c. *)
    B: 5,  [a -> t2; b -> t4; c -> t6]
    

### ﻿10.5.5 Reasoning with the semantics

Let us revisit an example from earlier (section 10.1).

let a = ref 0 and b = ref 0 let d1 () = a := 1; !b let d2 () = b := 1; !a let
main () = let h = Domain.spawn d2 in let r1 = d1 () in let r2 = Domain.join h
in assert (not (r1 = 0 && r2 = 0))

This program has a data race on a and b, and hence, the program may exhibit
non sequentially consistent behaviour. Let us use the semantics to show that
the program may exhibit r1 = 0 && r2 = 0.

The initial state of the abstract machine is:

    
    
    (* Non-atomic locations *)
    a: [t0 -> 0]
    b: [t1 -> 0]
    
    (* Domains *)
    d1: [a -> t0; b -> t1]
    d2: [a -> t0; b -> t1]
    

There are several possible schedules for executing this program. Let us
consider the following schedule:

    
    
    1: a := 1 @ d1
    2: b := 1 @ d2
    3: !b     @ d1
    4: !a     @ d2
    

After the first action a:=1 by d1, the machine state is:

    
    
    (* Non-atomic locations *)
    a: [t0 -> 0; t2 -> 1] (* new write at t2 *)
    b: [t1 -> 0]
    
    (* Domains *)
    d1: [a -> t2; b -> t1] (* frontier updated at a *)
    d2: [a -> t0; b -> t1]
    

After the second action b:=1 by d2, the machine state is:

    
    
    (* Non-atomic locations *)
    a: [t0 -> 0; t2 -> 1]
    b: [t1 -> 0; t3 -> 1] (* new write at t3 *)
    
    (* Domains *)
    d1: [a -> t2; b -> t1]
    d2: [a -> t0; b -> t3] (* frontier updated at b *)
    

Now, for the third action !b by d1, observe that d1’s frontier at b is at t1.
Hence, the read may return either 0 or 1. Let us assume that it returns 0. The
machine state is not updated by the non-atomic read.

Similarly, for the fourth action !a by d2, d2’s frontier at a is at t0. Hence,
this read may also return either 0 or 1. Let us assume that it returns 0.
Hence, the assertion in the original program, assert (not (r1 = 0 && r2 = 0)),
will fail for this particular execution.

## ﻿10.6 Non-compliant operations

There are certain operations which are not memory model compliant.

  * Array.blit function on float arrays may cause _tearing_. When an unsynchronized blit operation runs concurrently with some overlapping write to the fields of the same float array, the field may end up with bits from either of the writes. 
  * With flat-float arrays or records with only float fields on 32-bit architectures, getting or setting a field involves two separate memory accesses. In the presence of data races, the user may observe tearing. 
  * The Bytes module [Bytes](libref/Bytes.html) permits mixed-mode accesses where reads and writes may be of different sizes. Unsynchronized mixed-mode accesses lead to tearing. 

* * *

[![Previous](previous_motif.svg)](parallelism.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](language.html)

