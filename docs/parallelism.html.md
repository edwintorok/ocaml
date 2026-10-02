[![Previous](previous_motif.svg)](advexamples.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](memorymodel.html)

* * *

# Chapter 9 Parallel programming

  * [9.1 Domains](parallelism.html#s%3Apar_domains)
  * [9.2 Domainslib: A library for nested-parallel programming](parallelism.html#s%3Apar_parfib)
  * [9.3 Parallel garbage collection](parallelism.html#s%3Apar_gc)
  * [9.4 Memory model: The easy bits](parallelism.html#s%3Apar_mm_easy)
  * [9.5 Blocking synchronisation](parallelism.html#s%3Apar_sync)
  * [9.6 Interaction with C bindings](parallelism.html#s%3Apar_c_bindings)
  * [9.7 Atomics](parallelism.html#s%3Apar_atomics)

In this chapter we look at the parallel programming facilities in OCaml. The
OCaml standard library exposes low-level primitives for parallel programming.
We recommend that users make use of higher-level parallel programming
libraries such as [domainslib](https://github.com/ocaml-multicore/domainslib).
This tutorial will first cover high-level parallel programming using
domainslib followed by low-level primitives exposed by the compiler.

OCaml distinguishes between concurrency and parallelism and provides distinct
mechanisms for expressing them. Concurrency is interleaved execution of tasks
(section [12.24.2](effects.html#s%3Aeffects-concurrency)) whereas parallelism
is simultaneous execution of tasks. In particular, parallel tasks overlap in
time but concurrent tasks may or may not overlap in time. Tasks may execute
concurrently by yielding control to each other. While concurrency is a program
structuring mechanism, parallelism is a mechanism to make your programs run
faster. If you are interested in the concurrent programming mechanisms in
OCaml, please refer to section [12.24](effects.html#s%3Aeffect-handlers) on
effect handlers and chapter [35](libthreads.html#c%3Athreads) on the threads
library.

## ﻿9.1 Domains

Domains are the units of parallelism in OCaml. The module
[Domain](libref/Domain.html) provides the primitives to create and manage
domains. New domains can be spawned using the spawn function.

Domain.spawn (fun _ -> print_endline "I ran in parallel")

I ran in parallel \- : unit Domain.t = <abstr>

The spawn function executes the given computation in parallel with the calling
domain.

Domains are heavy-weight entities. Each domain maps 1:1 to an operating system
thread. Each domain also has its own runtime state, which includes domain-
local structures for allocating memory. Hence, they are relatively expensive
to create and tear down.

_It is recommended that programs do not spawn more domains than the number of
available cores_.

In this tutorial we will be implementing, running and measuring the
performance of parallel programs. The results observed are dependent on the
number of cores available on the target machine. This tutorial was written on
a 2.3 GHz Quad-Core Intel Core i7 MacBook Pro with 4 cores and 8 hardware
threads. It is reasonable to expect roughly 4x performance on 4 domains for
parallel programs with little coordination between the domains, and when the
machine is not under load. Beyond 4 domains, the speedup is likely to be less
than linear. We will also use the command-line benchmarking tool
[hyperfine](https://github.com/sharkdp/hyperfine) to benchmark our programs.

### ﻿9.1.1 Joining domains

We will write a program to compute the nth Fibonacci number using recursion as
a running example. The sequential program for computing the nth Fibonacci
number is given below.

(* fib.ml *) let n = try int_of_string Sys.argv.(1) with _ -> 1 let rec fib n
= if n < 2 then n else fib (n - 1) + fib (n - 2) let main () = let r = fib n
in Printf.printf "fib(%d) = %d\n%!" n r let _ = main ()

The program can be compiled and benchmarked as follows:

    
    
    $ ocamlopt -o fib.exe fib.ml
    $ ./fib.exe 42
    fib(42) = 267914296
    $ hyperfine './fib.exe 42' # Benchmarking
    Benchmark 1: ./fib.exe 42
      Time (mean ± sd):     1.193 s ±  0.006 s    [User: 1.186 s, System: 0.003 s]
      Range (min … max):    1.181 s …  1.202 s    10 runs
    

We see that it takes around 1.2 seconds to compute the 42nd Fibonacci number.

Spawned domains can be joined using the join function to get their results.
The join function waits for target domain to terminate. The following program
computes the nth Fibonacci number twice in parallel.

(* fib_twice.ml *) let n = int_of_string Sys.argv.(1) let rec fib n = if n < 2
then n else fib (n - 1) + fib (n - 2) let main () = let d1 = Domain.spawn (fun
_ -> fib n) in let d2 = Domain.spawn (fun _ -> fib n) in let r1 = Domain.join
d1 in Printf.printf "fib(%d) = %d\n%!" n r1; let r2 = Domain.join d2 in
Printf.printf "fib(%d) = %d\n%!" n r2 let _ = main ()

The program spawns two domains which compute the nth Fibonacci number. The
spawn function returns a Domain.t value which can be joined to get the result
of the parallel computation. The join function blocks until the computation
runs to completion.

    
    
    $ ocamlopt -o fib_twice.exe fib_twice.ml
    $ ./fib_twice.exe 42
    fib(42) = 267914296
    fib(42) = 267914296
    $ hyperfine './fib_twice.exe 42'
    Benchmark 1: ./fib_twice.exe 42
      Time (mean ± sd):     1.249 s ±  0.025 s    [User: 2.451 s, System: 0.012 s]
      Range (min … max):    1.221 s …  1.290 s    10 runs
    

As one can see, computing the nth Fibonacci number twice takes almost the same
time as computing it once, thanks to parallelism.

## ﻿9.2 Domainslib: A library for nested-parallel programming

Let us attempt to parallelise the Fibonacci function. The two recursive calls
may be executed in parallel. However, naively parallelising the recursive
calls by spawning domains for each one will not work as it spawns too many
domains.

(* fib_par1.ml *) let n = try int_of_string Sys.argv.(1) with _ -> 1 let rec
fib n = if n < 2 then n else begin let d1 = Domain.spawn (fun _ -> fib (n -
1)) in let d2 = Domain.spawn (fun _ -> fib (n - 2)) in Domain.join d1 +
Domain.join d2 end let main () = let r = fib n in Printf.printf "fib(%d) =
%d\n%!" n r let _ = main ()

fib(1) = 1 val n : int = 1 val fib : int -> int = <fun> val main : unit ->
unit = <fun>

    
    
    $ ocamlopt -o fib_par1.exe fib_par1.ml
    $ ./fib_par1.exe 42
    Fatal error: exception Failure("failed to allocate domain")
    

OCaml has a limit of 128 domains that can be active at the same time. An
attempt to spawn more domains will raise an exception. How then can we
parallelise the Fibonacci function?

### ﻿9.2.1 Parallelising Fibonacci using domainslib

The OCaml standard library provides only low-level primitives for concurrent
and parallel programming, leaving high-level programming libraries to be
developed and distributed outside the core compiler distribution.
[Domainslib](https://github.com/ocaml-multicore/domainslib) is such a library
for nested-parallel programming, which is epitomised by the parallelism
available in the recursive Fibonacci computation. Let us use domainslib to
parallelise the recursive Fibonacci program. It is recommended that you
install domainslib using the [opam](https://opam.ocaml.org/) package manager.
This tutorial uses domainslib version 0.5.0.

Domainslib provides an async/await mechanism for spawning parallel tasks and
awaiting their results. On top of this mechanism, domainslib provides parallel
iterators. At its core, domainslib has an efficient implementation of [work-
stealing queues](https://en.wikipedia.org/wiki/Work_stealing) in order to
efficiently share tasks with other domains. A parallel implementation of the
Fibonacci program follows:

    
    
    (* fib_par2.ml *)
    let num_domains = int_of_string Sys.argv.(1)
    let n = int_of_string Sys.argv.(2)
    
    let rec fib n = if n < 2 then n else fib (n - 1) + fib (n - 2)
    
    module T = Domainslib.Task
    
    let rec fib_par pool n =
      if n > 20 then begin
        let a = T.async pool (fun _ -> fib_par pool (n-1)) in
        let b = T.async pool (fun _ -> fib_par pool (n-2)) in
        T.await pool a + T.await pool b
      end else fib n
    
    let main () =
      let pool = T.setup_pool ~num_domains:(num_domains - 1) () in
      let res = T.run pool (fun _ -> fib_par pool n) in
      T.teardown_pool pool;
      Printf.printf "fib(%d) = %d\n" n res
    
    let _ = main ()
    

The program takes the number of domains and the input to the Fibonacci
function as the first and the second command-line arguments respectively.

Let us start with the main function. First, we set up a pool of domains on
which the nested parallel tasks will run. The domain invoking the run function
will also participate in executing the tasks submitted to the pool. We invoke
the parallel Fibonacci function fib_par in the run function. Finally, we tear
down the pool and print the result.

For sufficiently large inputs (n > 20), the fib_par function spawns the left
and the right recursive calls asynchronously in the pool using the async
function. The async function returns a promise for the result. The result of
an asynchronous computation is obtained by awaiting the promise using the
await function. The await function call blocks until the promise is resolved.

For small inputs, the fib_par function simply calls the sequential Fibonacci
function fib. It is important to switch to sequential mode for small problem
sizes. If not, the cost of parallelisation will outweigh the work available.

For simplicity, we use ocamlfind to compile this program. In general, it is
recommended that users use [dune](https://github.com/ocaml/dune) to build
programs that use libraries installed through [opam](https://opam.ocaml.org/).

    
    
    $ ocamlfind ocamlopt -package domainslib -linkpkg -o fib_par2.exe fib_par2.ml
    $ ./fib_par2.exe 1 42
    fib(42) = 267914296
    $ hyperfine './fib.exe 42' './fib_par2.exe 2 42' \
                './fib_par2.exe 4 42' './fib_par2.exe 8 42'
    Benchmark 1: ./fib.exe 42
      Time (mean ± sd):     1.217 s ±  0.018 s    [User: 1.203 s, System: 0.004 s]
      Range (min … max):    1.202 s …  1.261 s    10 runs
    
    Benchmark 2: ./fib_par2.exe 2 42
      Time (mean ± sd):    628.2 ms ±   2.9 ms    [User: 1243.1 ms, System: 4.9 ms]
      Range (min … max):   625.7 ms … 634.5 ms    10 runs
    
    Benchmark 3: ./fib_par2.exe 4 42
      Time (mean ± sd):    337.6 ms ±  23.4 ms    [User: 1321.8 ms, System: 8.4 ms]
      Range (min … max):   318.5 ms … 377.6 ms    10 runs
    
    Benchmark 4: ./fib_par2.exe 8 42
      Time (mean ± sd):    250.0 ms ±   9.4 ms    [User: 1877.1 ms, System: 12.6 ms]
      Range (min … max):   242.5 ms … 277.3 ms    11 runs
    
    Summary
      './fib_par2.exe 8 42' ran
        1.35 ± 0.11 times faster than './fib_par2.exe 4 42'
        2.51 ± 0.10 times faster than './fib_par2.exe 2 42'
        4.87 ± 0.20 times faster than './fib.exe 42'
    

The results show that, with 8 domains, the parallel Fibonacci program runs
4.87 times faster than the sequential version.

### ﻿9.2.2 Parallel iteration constructs

Many numerical algorithms use for-loops. The parallel-for primitive provides a
straight-forward way to parallelise such code. Let us take the [spectral-
norm](https://benchmarksgame-
team.pages.debian.net/benchmarksgame/description/spectralnorm.html#spectralnorm)
benchmark from the computer language benchmarks game and parallelise it. The
sequential version of the program is given below.

(* spectralnorm.ml *) let n = try int_of_string Sys.argv.(1) with _ -> 32 let
eval_A i j = 1. /. float((i+j)*(i+j+1)/2+i+1) let eval_A_times_u u v = let n =
Array.length v - 1 in for i = 0 to n do let vi = ref 0\. in for j = 0 to n do
vi := !vi +. eval_A i j *. u.(j) done; v.(i) <\- !vi done let eval_At_times_u
u v = let n = Array.length v - 1 in for i = 0 to n do let vi = ref 0\. in for
j = 0 to n do vi := !vi +. eval_A j i *. u.(j) done; v.(i) <\- !vi done let
eval_AtA_times_u u v = let w = Array.make (Array.length u) 0.0 in
eval_A_times_u u w; eval_At_times_u w v let () = let u = Array.make n 1.0 and
v = Array.make n 0.0 in for _i = 0 to 9 do eval_AtA_times_u u v;
eval_AtA_times_u v u done; let vv = ref 0.0 and vBv = ref 0.0 in for i=0 to
n-1 do vv := !vv +. v.(i) *. v.(i); vBv := !vBv +. u.(i) *. v.(i) done;
Printf.printf "%0.9f\n" (sqrt(!vBv /. !vv))

Observe that the program has nested loops in eval_A_times_u and
eval_At_times_u. Each iteration of the outer loop body reads from u but writes
to disjoint memory locations in v. Hence, the iterations of the outer loop are
not dependent on each other and can be executed in parallel.

The parallel version of spectral norm is shown below.

    
    
    (* spectralnorm_par.ml *)
    let num_domains = try int_of_string Sys.argv.(1) with _ -> 1
    let n = try int_of_string Sys.argv.(2) with _ -> 32
    
    let eval_A i j = 1. /. float((i+j)*(i+j+1)/2+i+1)
    
    module T = Domainslib.Task
    
    let eval_A_times_u pool u v =
      let n = Array.length v - 1 in
      T.parallel_for pool ~start:0 ~finish:n ~body:(fun i ->
        let vi = ref 0. in
        for j = 0 to n do vi := !vi +. eval_A i j *. u.(j) done;
        v.(i) <- !vi
      )
    
    let eval_At_times_u pool u v =
      let n = Array.length v - 1 in
      T.parallel_for pool ~start:0 ~finish:n ~body:(fun i ->
        let vi = ref 0. in
        for j = 0 to n do vi := !vi +. eval_A j i *. u.(j) done;
        v.(i) <- !vi
      )
    
    let eval_AtA_times_u pool u v =
      let w = Array.make (Array.length u) 0.0 in
      eval_A_times_u pool u w; eval_At_times_u pool w v
    
    let () =
      let pool = T.setup_pool ~num_domains:(num_domains - 1) () in
      let u = Array.make n 1.0  and  v = Array.make n 0.0 in
      T.run pool (fun _ ->
      for _i = 0 to 9 do
        eval_AtA_times_u pool u v; eval_AtA_times_u pool v u
      done);
    
      let vv = ref 0.0  and  vBv = ref 0.0 in
      for i=0 to n-1 do
        vv := !vv +. v.(i) *. v.(i);
        vBv := !vBv +. u.(i) *. v.(i)
      done;
      T.teardown_pool pool;
      Printf.printf "%0.9f\n" (sqrt(!vBv /. !vv))
    

Observe that the parallel_for function is isomorphic to the for-loop in the
sequential version. No other change is required except for the boilerplate
code to set up and tear down the pools.

    
    
    $ ocamlopt -o spectralnorm.exe spectralnorm.ml
    $ ocamlfind ocamlopt -package domainslib -linkpkg -o spectralnorm_par.exe \
      spectralnorm_par.ml
    $ hyperfine './spectralnorm.exe 4096' './spectralnorm_par.exe 2 4096' \
                './spectralnorm_par.exe 4 4096' './spectralnorm_par.exe 8 4096'
    Benchmark 1: ./spectralnorm.exe 4096
      Time (mean ± sd):     1.989 s ±  0.013 s    [User: 1.972 s, System: 0.007 s]
      Range (min … max):    1.975 s …  2.018 s    10 runs
    
    Benchmark 2: ./spectralnorm_par.exe 2 4096
      Time (mean ± sd):     1.083 s ±  0.015 s    [User: 2.140 s, System: 0.009 s]
      Range (min … max):    1.064 s …  1.102 s    10 runs
    
    Benchmark 3: ./spectralnorm_par.exe 4 4096
      Time (mean ± sd):    698.7 ms ±  10.3 ms    [User: 2730.8 ms, System: 18.3 ms]
      Range (min … max):   680.9 ms … 721.7 ms    10 runs
    
    Benchmark 4: ./spectralnorm_par.exe 8 4096
      Time (mean ± sd):    921.8 ms ±  52.1 ms    [User: 6711.6 ms, System: 51.0 ms]
      Range (min … max):   838.6 ms … 989.2 ms    10 runs
    
    Summary
      './spectralnorm_par.exe 4 4096' ran
        1.32 ± 0.08 times faster than './spectralnorm_par.exe 8 4096'
        1.55 ± 0.03 times faster than './spectralnorm_par.exe 2 4096'
        2.85 ± 0.05 times faster than './spectralnorm.exe 4096'
    

On the author’s machine, the program scales reasonably well up to 4 domains
but performs worse with 8 domains. Recall that the machine only has 4 physical
cores. Debugging and fixing this performance issue is beyond the scope of this
tutorial.

## ﻿9.3 Parallel garbage collection

An important aspect of the scalability of parallel OCaml programs is the
scalability of the garbage collector (GC). The OCaml GC is designed to have
both low latency and good parallel scalability. OCaml has a generational
garbage collector with a small minor heap and a large major heap. New objects
(upto a certain size) are allocated in the minor heap. Each domain has its own
domain-local minor heap arena into which new objects are allocated without
synchronising with the other domains. When a domain exhausts its minor heap
arena, it calls for a stop-the-world collection of the minor heaps. In the
stop-the-world section, all the domains collect their minor heap arenas in
parallel evacuating the survivors to the major heap.

For the major heap, each domain maintains domain-local, size-segmented pools
of memory into which large objects and survivors from the minor collection are
allocated. Having domain-local pools avoids synchronisation for most major
heap allocations. The major heap is collected by a concurrent mark-and-sweep
algorithm that involves a few short stop-the-world pauses for each major
cycle.

Overall, users should expect the garbage collector to scale well with as the
number of domains increases, with latency remaining low. For more information
on the design and evaluation of the garbage collector, please have a look at
the ICFP 2020 paper on [Retrofitting Parallelism onto
OCaml](https://arxiv.org/abs/2004.11663).

## ﻿9.4 Memory model: The easy bits

Modern processors and compilers aggressively optimise programs. These
optimisations accelerate without otherwise affecting sequential programs, but
cause surprising behaviours to be visible in parallel programs. To benefit
from these optimisations, OCaml adopts a relaxed memory model that precisely
specifies which of these _relaxed behaviours_ programs may observe. While
these models are difficult to program against directly, the OCaml memory model
provides recipes that retain the simplicity of sequential reasoning.

Firstly, immutable values may be freely shared between multiple domains and
may be accessed in parallel. For mutable data structures such as reference
cells, arrays and mutable record fields, programmers should avoid _data
races_. Reference cells, arrays and mutable record fields are said to be _non-
atomic_ data structures. A data race is said to occur when two domains
concurrently access a non-atomic memory location without _synchronisation_ and
at least one of the accesses is a write. OCaml provides a number of ways to
introduce synchronisation including atomic variables (section 9.7) and mutexes
(section 9.5).

Importantly, for data race free (DRF) programs, OCaml provides sequentially
consistent (SC) semantics – the observed behaviour of such programs can be
explained by the interleaving of operations from different domains. This
property is known as the DRF-SC guarantee. Moreover, in OCaml, the DRF-SC
guarantee is modular – if a part of a program is data race free, then the
OCaml memory model ensures that those parts have sequential consistency
despite other parts of the program having data races. Even for programs with
data races, OCaml provides strong guarantees. While the user may observe non-
sequentially consistent behaviours, there are no crashes.

For more details on the relaxed behaviours in the presence of data races,
please have a look at the chapter on the hard bits of the memory model
(chapter [10](memorymodel.html#c%3Amemorymodel)).

## ﻿9.5 Blocking synchronisation

Domains may perform blocking synchronisation with the help of
[Mutex](libref/Mutex.html), [Condition](libref/Condition.html) and
[Semaphore](libref/Semaphore.html) modules. These modules are the same as
those used to synchronise threads created by the threads library (chapter
[35](libthreads.html#c%3Athreads)). For clarity, in the rest of this chapter,
we refer to the threads created by the threads library as _systhreads_. The
following program implements a concurrent stack using mutex and condition
variables.

module Blocking_stack : sig type 'a t val make : unit -> 'a t val push : 'a t -> 'a -> unit val pop : 'a t -> 'a end = struct type 'a t = { mutable contents: 'a list; mutex : Mutex.t; nonempty : Condition.t } let make () = { contents = []; mutex = Mutex.create (); nonempty = Condition.create () } let push r v = Mutex.lock r.mutex; r.contents <\- v::r.contents; Condition.signal r.nonempty; Mutex.unlock r.mutex let pop r = Mutex.lock r.mutex; let rec loop () = match r.contents with | [] -> Condition.wait r.nonempty r.mutex; loop () | x::xs -> r.contents <\- xs; x in let res = loop () in Mutex.unlock r.mutex; res end

The concurrent stack is implemented using a record with three fields: a
mutable field contents which stores the elements in the stack, a mutex to
control access to the contents field, and a condition variable nonempty, which
is used to signal blocked domains waiting for the stack to become non-empty.

The push operation locks the mutex, updates the contents field with a new list
whose head is the element being pushed and the tail is the old list. The
condition variable nonempty is signalled while the lock is held in order to
wake up any domains waiting on this condition. If there are waiting domains,
one of the domains is woken up. If there are none, then the signal operation
has no effect.

The pop operation locks the mutex and checks whether the stack is empty. If
so, the calling domain waits on the condition variable nonempty using the wait
primitive. The wait call atomically suspends the execution of the current
domain and unlocks the mutex. When this domain is woken up again (when the
wait call returns), it holds the lock on mutex. The domain tries to read the
contents of the stack again. If the pop operation sees that the stack is non-
empty, it updates the contents to the tail of the old list, and returns the
head.

The use of mutex to control access to the shared resource contents introduces
sufficient synchronisation between multiple domains using the stack. Hence,
there are no data races when multiple domains use the stack in parallel.

### ﻿9.5.1 Interaction with systhreads

How do systhreads interact with domains? The systhreads created on a
particular domain remain pinned to that domain. Only one systhread at a time
is allowed to run OCaml code on a particular domain. However, systhreads
belonging to a particular domain may run C library or system code in parallel.
Systhreads belonging to different domains may execute in parallel.

When using systhreads, the thread created for executing the computation given
to Domain.spawn is also treated as a systhread. For example, the following
program creates in total two domains (including the initial domain) with two
systhreads each (including the initial systhread for each of the domains).

    
    
    (* dom_thr.ml *)
    let m = Mutex.create ()
    let r = ref None (* protected by m *)
    
    let task () =
      let my_thr_id = Thread.(id (self ())) in
      let my_dom_id :> int = Domain.self () in
      Mutex.lock m;
      begin match !r with
      | None ->
          Printf.printf "Thread %d running on domain %d saw initial write\n%!"
            my_thr_id my_dom_id
      | Some their_thr_id ->
          Printf.printf "Thread %d running on domain %d saw the write by thread %d\n%!"
            my_thr_id my_dom_id their_thr_id;
      end;
      r := Some my_thr_id;
      Mutex.unlock m
    
    let task' () =
      let t = Thread.create task () in
      task ();
      Thread.join t
    
    let main () =
      let d = Domain.spawn task' in
      task' ();
      Domain.join d
    
    let _ = main ()
    
    
    
    $ ocamlopt -I +threads -I +unix unix.cmxa threads.cmxa -o dom_thr.exe dom_thr.ml
    $ ./dom_thr.exe
    Thread 1 running on domain 1 saw initial write
    Thread 0 running on domain 0 saw the write by thread 1
    Thread 2 running on domain 1 saw the write by thread 0
    Thread 3 running on domain 0 saw the write by thread 2
    

This program uses a shared reference cell protected by a mutex to communicate
between the different systhreads running on two different domains. The
systhread identifiers uniquely identify systhreads in the program. The initial
domain gets the domain id 0 and thread id 0. The newly spawned domain gets the
domain id 1.

Note that all the systhreads belonging to a particular domain are joined when
the domain is joined. In particular, if such a systhread is running an
infinite loop, then joining the domain will never return.

## ﻿9.6 Interaction with C bindings

During parallel execution with multiple domains, C code running on a domain
may run in parallel with any C code running in other domains even if neither
of them has released the “domain lock”. Prior to OCaml 5.0, C bindings may
have assumed that if the OCaml runtime lock is not released, then it would be
safe to manipulate global C state (e.g. initialise a function-local static
value). This is no longer true in the presence of parallel execution with
multiple domains.

## ﻿9.7 Atomics

Mutexes, condition variables and semaphores are used to implement blocking
synchronisation between domains. For non-blocking synchronisation, OCaml
provides [Atomic](libref/Atomic.html) variables. As the name suggests, non-
blocking synchronisation does not provide mechanisms for suspending and waking
up domains. On the other hand, primitives used in non-blocking synchronisation
are often compiled to atomic read-modify-write primitives that the hardware
provides. As an example, the following program increments a non-atomic counter
and an atomic counter in parallel.

(* incr.ml *) let twice_in_parallel f = let d1 = Domain.spawn f in let d2 =
Domain.spawn f in Domain.join d1; Domain.join d2 let plain_ref n = let r = ref
0 in let f () = for _i=1 to n do incr r done in twice_in_parallel f;
Printf.printf "Non-atomic ref count: %d\n" !r let atomic_ref n = let r =
Atomic.make 0 in let f () = for _i=1 to n do Atomic.incr r done in
twice_in_parallel f; Printf.printf "Atomic ref count: %d\n" (Atomic.get r) let
main () = let n = try int_of_string Sys.argv.(1) with _ -> 1 in plain_ref n;
atomic_ref n let _ = main ()

    
    
    $ ocamlopt -o incr.exe incr.ml
    $ ./incr.exe 1_000_000
    Non-atomic ref count: 1187193
    Atomic ref count: 2000000
    

Observe that the result from using the non-atomic counter is lower than what
one would naively expect. This is because the non-atomic incr function is
equivalent to:

let incr r = let curr = !r in r := curr + 1

Observe that the load and the store are two separate operations, and the
increment operation as a whole is not performed atomically. When two domains
execute this code in parallel, both of them may read the same value of the
counter curr and update it to curr + 1. Hence, instead of two increments, the
effect will be that of a single increment. On the other hand, the atomic
counter performs the load and the store atomically with the help of hardware
support for atomicity. The atomic counter returns the expected result.

Atomic variables can be used for low-level synchronisation between domains.
The following example uses an atomic variable to exchange a message between
two domains.

let r = Atomic.make None let sender () = Atomic.set r (Some "Hello") let rec receiver () = match Atomic.get r with | None -> Domain.cpu_relax (); receiver () | Some m -> print_endline m let main () = let s = Domain.spawn sender in let d = Domain.spawn receiver in Domain.join s; Domain.join d let _ = main ()

Hello val r : string option Atomic.t = <abstr> val sender : unit -> unit =
<fun> val receiver : unit -> unit = <fun> val main : unit -> unit = <fun>

Although the sender and the receiver compete to access r, this is not a data
race since r is an atomic reference.

### ﻿9.7.1 Lock-free stack

The Atomic module is used to implement non-blocking, lock-free data
structures. The following program implements a lock-free stack.

module Lockfree_stack : sig type 'a t val make : unit -> 'a t val push : 'a t -> 'a -> unit val pop : 'a t -> 'a option end = struct type 'a t = 'a list Atomic.t let make () = Atomic.make [] let rec push r v = let s = Atomic.get r in if Atomic.compare_and_set r s (v::s) then () else (Domain.cpu_relax (); push r v) let rec pop r = let s = Atomic.get r in match s with | [] -> None | x::xs -> if Atomic.compare_and_set r s xs then Some x else (Domain.cpu_relax (); pop r) end

The atomic stack is represented by an atomic reference that holds a list. The
push and pop operations use the compare_and_set primitive to attempt to
atomically update the atomic reference. The expression compare_and_set r seen
v sets the value of r to v if and only if its current value is physically
equal to seen. Importantly, the comparison and the update occur atomically.
The expression evaluates to true if the comparison succeeded (and the update
happened) and false otherwise.

If the compare_and_set fails, then some other domain is also attempting to
update the atomic reference at the same time. In this case, the push and pop
operations call Domain.cpu_relax to back off for a short duration allowing
competing domains to make progress before retrying the failed operation. This
lock-free stack implementation is called a [Treiber
stack](https://en.wikipedia.org/wiki/Treiber_stack).

### ﻿9.7.2 Atomic record fields

The type 'a Atomic.t is the atomic counterpart of the type of OCaml
references, 'a ref. Since OCaml 5.4, we also support atomic record fields,
which must be mutable, via the [@atomic] attribute.

For example:

type 'a refcounted = { value : 'a; mutable readers : int [@atomic]; }

The field readers is atomic, so that reading and writing to this field are
atomic operations similar to Atomic.get and Atomic.set. It is possible to
perform other atomic operations on this field by using a built-in extension
node, %atomic.loc: if rc is a value of type foo refcounted, then [%atomic.loc
rc.readers] is an expression of the built-in type foo Atomic.Loc.t, which
allows atomic operations defined in the [Atomic](libref/Atomic.html).Loc
module of the standard library, mirroring the operations exposed for atomic
references in the [Atomic](libref/Atomic.html) module:

# let add_reader rc = Atomic.Loc.fetch_and_add [%atomic.loc rc.readers] 1;;

val add_reader : 'a refcounted -> int = <fun>

# #show Atomic.Loc;;

module Loc : sig type 'a t = 'a atomic_loc external get : 'a t -> 'a =
"%atomic_load_loc" val set : 'a t -> 'a -> unit external exchange : 'a t -> 'a
-> 'a = "%atomic_exchange_loc" external compare_and_set : 'a t -> 'a -> 'a ->
bool = "%atomic_cas_loc" external fetch_and_add : int t -> int -> int =
"%atomic_fetch_add_loc" val incr : int t -> unit val decr : int t -> unit val
update : ('a -> 'a) -> 'a t -> unit end

##### ﻿Limitation

Currently there is no analogue of Atomic.make_contended for atomic record
fields. If false sharing is an issue for a specific record field, the best
supported approach is to use a field of type Atomic.t. We hope to implement
support for on-demand padding of record fields in the future.

##### ﻿Performance note

Internally [%atomic.loc rc.readers] is represented as a pair of the record
value and a field offset. Whenever this expression is directly applied to an
atomic primitive of the [Atomic](libref/Atomic.html).Loc module, the compiler
will optimize away the creation of the pair; it passes the value and the
offset as separate parameters to an underlying runtime primitive. On the other
hand, storing an atomic location in a data-structure or passing it to another,
non-inlined function may allocate a pair. When in doubt, you can inspect the
-dcmm intermediate representation of your code.

* * *

[![Previous](previous_motif.svg)](advexamples.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](memorymodel.html)

