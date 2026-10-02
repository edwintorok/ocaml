[![Previous](previous_motif.svg)](bindingops.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](arrayliterals.html)

* * *

## ﻿12.24 Effect handlers

  * [12.24.1 Basics](effects.html#s%3Aeffects-basics)
  * [12.24.2 Concurrency](effects.html#s%3Aeffects-concurrency)
  * [12.24.3 User-level threads](effects.html#s%3Aeffects-user-threads)
  * [12.24.4 Control inversion](effects.html#s%3Aeffects-sequence)
  * [12.24.5 Semantics](effects.html#s%3Aeffects-semantics)
  * [12.24.6 Shallow handlers](effects.html#s%3Aeffects-shallow)

(Introduced in 5.0. The syntax support for deep handlers was introduced in
5.3.)

| [pattern](patterns.html#pattern)| ::=|  ...  
---|---|---  
 | ∣|  effect [pattern](patterns.html#pattern), [value-name](names.html#value-name)  
  
  
Effect handlers are a mechanism for modular programming with user-defined
effects. Effect handlers allow the programmers to describe computations that
perform effectful operations, whose meaning is described by handlers that
enclose the computations. Effect handlers are a generalization of exception
handlers and enable non-local control-flow mechanisms such as resumable
exceptions, lightweight threads, coroutines, generators and asynchronous I/O
to be composably expressed. In this tutorial, we shall see how some of these
mechanisms can be built using effect handlers.

### ﻿12.24.1 Basics

To understand the basics, let us define an effect (that is, an operation) that
takes an integer argument and returns an integer result. We name this effect
Xchg.

open Effect open Effect.Deep type _ Effect.t += Xchg: int -> int t let comp1
() = perform (Xchg 0) + perform (Xchg 1)

We declare the exchange effect Xchg by extending the pre-defined extensible
variant type Effect.t with a new constructor Xchg: int -> int t. The
declaration may be intuitively read as “the Xchg effect takes an integer
parameter, and when this effect is performed, it returns an integer”. The
computation comp1 performs the effect twice using the perform primitive and
returns their sum.

We can handle the Xchg effect by implementing a handler that always returns
the successor of the offered value:

try comp1 () with | effect (Xchg n), k -> continue k (n+1)

\- : int = 3

We run the computation comp1 () under an effect handler that handles the Xchg
effect with a continuation bound to k. Here effect is a keyword which
signifies that the Xchg n pattern matches effects and not exceptions. As
mentioned earlier, effect handlers are a generalization of exception handlers.
Similar to exception handlers, when the computation performs the Xchg effect,
the control jumps to the corresponding handler, and unhandled effects are
forwarded to the outer handler. However, unlike exception handlers, the
handler is also provided with the delimited continuation k, which represents
the suspended computation between the point of perform and this handler.

The handler uses the continue primitive to resume the suspended computation
with the successor of the offered value. In this example, the computation
comp1 performs Xchg 0 and Xchg 1 and receives the values 1 and 2 from the
handler respectively. Hence, the whole expression evaluates to 3.

In this example, we use the _deep_ version of the effect handlers here as
opposed to the _shallow_ version. A deep handler monitors a computation until
the computation terminates (either normally or via an exception), and handles
all of the effects performed (in sequence) by the computation. In contrast, a
shallow handler monitors a computation until either the computation terminates
or the computation performs one effect, and it handles this single effect
only. In situations where they are applicable, deep handlers are usually
preferred. An example that utilises shallow handlers is discussed later in
12.24.6.

### ﻿12.24.2 Concurrency

The expressive power of effect handlers comes from the delimited continuation.
While the previous example immediately resumed the computation, the
computation may be resumed later, running some other computation in the
interim. Let us extend the previous example and implement message-passing
concurrency between two concurrent computations using the Xchg effect. We call
these concurrent computations tasks.

A task either is in a suspended state or is completed. We represent the task
status as follows:

type 'a status = Complete of 'a | Suspended of {msg: int; cont: (int, 'a status) continuation}

A task either is complete, with a result of type 'a, or is suspended with the
message msg to send and the continuation cont. The type (int,'a status)
continuation says that the suspended delimited computation expects an int
value to resume and returns a value of type 'a status when resumed.

Next, we define a step function that executes one step of computation until it
completes or suspends:

let step (f : unit -> 'a) () : 'a status = match f () with | v -> Complete v | effect (Xchg msg), cont -> Suspended {msg; cont}

The argument to the step function, f, is a computation that can perform an
Xchg effect and returns a result of type 'a. The step function itself returns
a value of type 'a status. Similar to exception patterns in a match ... with
expression ([11.6](patterns.html#sss%3Aexception-match)), OCaml also supports
effect patterns. Here, we pattern match the result of running the computation
f. If the computation returns with a value v, we return Complete v. Instead,
if the computation performs the effect Xchg msg with the continuation cont,
then we return Suspended {msg;cont}. In this case, the continuation cont is
not immediately invoked by the handler; instead, it is stored in a data
structure for later use.

Since the step function handles the Xchg effect, step f is a computation that
does not perform the Xchg effect. It may however perform other effects.
Moreover, since we are using deep handlers, the continuation cont stored in
the status does not perform the Xchg effect.

We can now write a simple scheduler that runs a pair of tasks to completion:

let rec run_both a b = match a (), b () with | Complete va, Complete vb -> (va, vb) | Suspended {msg = m1; cont = k1}, Suspended {msg = m2; cont = k2} -> run_both (fun () -> continue k1 m2) (fun () -> continue k2 m1) | _ -> failwith "Improper synchronization"

Both of the tasks may run to completion, or both may offer to exchange a
message. In the latter case, each computation receives the value offered by
the other computation. The situation where one computation offers an exchange
while the other computation terminates is regarded as a programmer error, and
causes the handler to raise an exception

We can now define a second computation that also exchanges two messages:

let comp2 () = perform (Xchg 21) * perform (Xchg 21)

Finally, we can run the two computations together:

run_both (step comp1) (step comp2)

\- : int * int = (42, 0)

The computation comp1 offers the values 0 and 1 and in exchange receives the
values 21 and 21, which it adds, producing 42. The computation comp2 offers
the values 21 and 21 and in exchange receives the values 0 and 1, which it
multiplies, producing 0. The communication between the two computations is
programmed entirely inside run_both. Indeed, the definitions of comp1 and
comp2, alone, do not assign any meaning to the Xchg effect.

### ﻿12.24.3 User-level threads

Let us extend the previous example for an arbitrary number of tasks. Many
languages such as GHC Haskell and Go provide user-level threads as a primitive
feature implemented in the runtime system. With effect handlers, user-level
threads and their schedulers can be implemented in OCaml itself. Typically,
user-level threading systems provide a fork primitive to spawn off a new
concurrent task and a yield primitive to yield control to some other task.
Correspondingly, we shall declare two effects as follows:

type _ Effect.t += Fork : (unit -> unit) -> unit t | Yield : unit t

The Fork effect takes a thunk (a suspended computation, represented as a
function of type unit -> unit) and returns a unit to the performer. The Yield
effect is unparameterized and returns a unit when performed. Let us consider
that a task performing an Xchg effect may match with any other task also
offering to exchange a value.

We shall also define helper functions that simply perform these effects:

let fork f = perform (Fork f) let yield () = perform Yield let xchg v =
perform (Xchg v)

A top-level run function defines the scheduler:

(* A concurrent round-robin scheduler *) let run (main : unit -> unit) : unit = let exchanger : (int * (int, unit) continuation) option ref = ref None (* waiting exchanger *) in let run_q = Queue.create () in (* scheduler queue *) let enqueue k v = let task () = continue k v in Queue.push task run_q in let dequeue () = if Queue.is_empty run_q then () (* done *) else begin let task = Queue.pop run_q in task () end in let rec spawn (f : unit -> unit) : unit = match f () with | () -> dequeue () | exception e -> print_endline (Printexc.to_string e); dequeue () | effect Yield, k -> enqueue k (); dequeue () | effect (Fork f), k -> enqueue k (); spawn f | effect (Xchg n), k -> begin match !exchanger with | Some (n', k') -> exchanger := None; enqueue k' n; continue k n' | None -> exchanger := Some (n, k); dequeue () end in spawn main

We use a mutable queue run_q to hold the scheduler queue. The FIFO queue
enables round-robin scheduling of tasks in the scheduler. enqueue inserts
tasks into the queue, and dequeue extracts tasks from the queue and runs them.
The reference cell exchanger holds a (suspended) task offering to exchange a
value. At any time, there is either zero or one suspended task that is
offering an exchange.

The heavy lifting is done by the spawn function. The spawn function runs the
given computation f in an effect handler. If f returns with unit value, we
dequeue and run the next task from the scheduler queue. If the computation f
raises any exception, we print the exception to the standard output and run
the next task from the scheduler.

The computation f may also perform effects. If f performs the Yield effect,
the current task is suspended (inserted into the queue of ready tasks), and
the next task from the scheduler queue is run. If the effect is Fork f, then
the current task is suspended, and the new task f is executed immediately via
a tail call to spawn f. Note that this choice to run the new task first is
arbitrary. We could very well have chosen instead to insert the task for f
into the ready queue and resumed k immediately.

If the effect is Xchg, then we first check whether there is a task waiting to
exchange. If so, we enqueue the waiting task with the current value being
offered and immediately resume the current task with the value being offered.
If not, we make the current task the waiting exchanger, and run the next task
from the scheduler queue.

Now we can write a concurrent program that utilises the newly defined
operations:

open Printf let _ = run (fun _ -> fork (fun _ -> printf "[t1] Sending 0\n";
let v = xchg 0 in printf "[t1] received %d\n" v); fork (fun _ -> printf "[t2]
Sending 1\n"; let v = xchg 1 in printf "[t2] received %d\n" v))

[t1] Sending 0 [t2] Sending 1 [t2] received 0 [t1] received 1

Observe that the messages from the two tasks are interleaved. Notice also that
the snippet above makes no reference to the effect handlers and is in direct
style (no monadic operations). This example illustrates that, with effect
handlers, the user code in a concurrent program can remain in simple direct
style, and the use of effect handlers can be fully contained within the
concurrency library implementation.

#### ﻿Resuming with an exception

In addition to resuming a continuation with a value, effect handlers also
permit resuming by raising an effect at the point of perform. This is done
with the help of the discontinue primitive. The discontinue primitive helps
ensure that resources are always eventually deallocated, even in the presence
of effects.

For example, consider the dequeue operation in the previous example reproduced
below:

… let dequeue () = if Queue.is_empty run_q then () (* done *) else (Queue.pop
run_q) ()

If the scheduler queue is empty, dequeue considers that the scheduler is done
and returns to the caller. However, there may still be a task waiting to
exchange a value (stored in the reference cell exchanger), which remains
blocked forever! If the blocked task holds onto resources, these resources are
leaked. For example, consider the following task:

let leaky_task () = fork (fun _ -> let oc = open_out "secret.txt" in
Fun.protect ~finally:(fun _ -> close_out oc) (fun _ -> output_value oc (xchg
0)))

The task writes the received message to the file secret.txt. It uses
Fun.protect to ensure that the output channel oc is closed on both normal and
exceptional return cases. Unfortunately, this is not sufficient. If the
exchange effect xchg 0 cannot be matched with an exchange effect performed by
some other thread, then this task remains blocked forever. Thus, the output
channel oc is never closed.

To avoid this problem, one must adhere to a simple discipline: _every
continuation must be eventually either continued or discontinued_. Here, we
use discontinue to ensure that the blocked task does not remain blocked
forever. By discontinuing this task, we force it to terminate (with an
exception):

exception Improper_synchronization let dequeue () = if Queue.is_empty run_q then begin match !exchanger with | None -> () (* done *) | Some (n, k) -> exchanger := None; discontinue k Improper_synchronization end else (Queue.pop run_q) ()

When the scheduler queue is empty and there is a blocked exchanger thread, the
dequeue function discontinues the blocked thread with an
Improper_synchronization exception. This exception is raised at the blocked
xchg function call, which causes the finally block to be run and closes the
output channel oc. From the point of view of the user, it seems as though the
function call xchg 0 raises the exception Improper_synchronization.

### ﻿12.24.4 Control inversion

When it comes to performing traversals on a data structure, there are two
fundamental ways depending on whether the producer or the consumer has the
control over the traversal. For example, in List.iter f l, the producer
List.iter has the control and pushes the element to the consumer f who
processes them. On the other hand, the [Seq](libref/Seq.html) module provides
a mechanism similar to delayed lists where the consumer controls the
traversal. For example, Seq.forever Random.bool returns an infinite sequence
of random bits where every bit is produced (on demand) when queried by the
consumer.

Naturally, producers such as List.iter are easier to write in the former
style. The latter style is ergonomically better for the consumer since it is
preferable and more natural to be in control. To have the best of both worlds,
we would like to write a producer in the former style and automatically
convert it to the latter style. The conversion can be written _once and for
all_ as a library function, thanks to effect handlers. Let us name this
function invert. We will first look at how to use the invert function before
looking at its implementation details. The type of this function is given
below:

val invert : iter:(('a -> unit) -> unit) -> 'a Seq.t

The invert function takes an iter function (a producer that pushes elements to
the consumer) and returns a sequence (where the consumer has the control). For
example,

let lst_iter = Fun.flip List.iter [1;2;3]

val lst_iter : (int -> unit) -> unit = <fun>

is an iter function with type (int -> unit) -> unit. The expression lst_iter f
pushes the elements 1, 2 and 3 to the consumer f. For example,

lst_iter (fun i -> Printf.printf "%d\n" i)

1 2 3 \- : unit = ()

The expression invert lst_iter returns a sequence that allows the consumer to
traverse the list on demand. For example,

let s = invert ~iter:lst_iter let next = Seq.to_dispenser s;;

val s : int Seq.t = <fun> val next : unit -> int option = <fun>

next();;

\- : int option = Some 1

next();;

\- : int option = Some 2

next();;

\- : int option = Some 3

next();;

\- : int option = None

We can use the same invert function on any iter function. For example,

let s = invert ~iter:(Fun.flip String.iter "OCaml") let next =
Seq.to_dispenser s;;

val s : char Seq.t = <fun> val next : unit -> char option = <fun>

next();;

\- : char option = Some 'O'

next();;

\- : char option = Some 'C'

next();;

\- : char option = Some 'a'

next();;

\- : char option = Some 'm'

next();;

\- : char option = Some 'l'

next();;

\- : char option = None

#### ﻿Implementing control inversion

The implementation of the invert function is given below:

let invert (type a) ~(iter : (a -> unit) -> unit) : a Seq.t = let module M = struct type _ Effect.t += Yield : a -> unit t end in let yield v = perform (M.Yield v) in fun () -> match iter yield with | () -> Seq.Nil | effect M.Yield v, k -> Seq.Cons (v, continue k)

The invert function declares an effect Yield that takes the element to be
yielded as a parameter. The yield function performs the Yield effect. The
lambda abstraction fun () -> ... delays all action until the first element of
the sequence is demanded. Once this happens, the computation iter yield is
executed under an effect handler. Every time the iter function pushes an
element to the yield function, the computation is interrupted by the Yield
effect. The Yield effect is handled by returning the value Seq.Cons(v,continue
k) to the consumer. The consumer gets the element v as well as the suspended
computation, which in the consumer’s eyes is just the tail of sequence.

When the consumer demands the next element from the sequence (by applying it
to ()), the continuation k is resumed. This allows the computation iter yield
to make progress, until it either yields another element or terminates
normally. In the latter case, the value Seq.Nil is returned, indicating to the
consumer that the iteration is over.

It is important to note that the sequence returned by the invert function is
_ephemeral_ (as defined by the [Seq](libref/Seq.html) module) i.e., the
sequence must be used at most once. Additionally, the sequence must be fully
consumed (i.e., used at least once) so as to ensure that the captured
continuation is used linearly.

### ﻿12.24.5 Semantics

In this section, we shall see the semantics of effect handlers with the help
of examples.

#### ﻿Nesting handlers

Like exception handlers, effect handlers can be nested.

type _ Effect.t += E : int t | F : string t let foo () = perform F let bar () = try foo () with | effect E, k -> failwith "impossible" let baz () = try bar () with | effect F, k -> continue k "Hello, world!"

In this example, the computation foo performs F, the inner handler handles
only E and the outer handler handles F. The call to baz returns Hello, world!.

baz ()

\- : string = "Hello, world!"

#### ﻿Fibers

It is useful to know a little bit about the implementation of effect handlers
to appreciate the design choices and their performance characteristics. Effect
handlers are implemented with the help of runtime-managed, dynamically growing
segments of stack called fibers. The program stack in OCaml is a linked list
of such fibers.

A new fiber is allocated for evaluating the computation enclosed by an effect
handler. The fiber is freed when the computation returns to the caller either
normally by returning a value or by raising an exception.

At the point of perform in foo in the previous example, the program stack
looks like this:

+-----+ +-----+ +-----+ | | | | | | | baz |<\--| bar |<\--| foo | | | | | | | | | | | | | +-----+ +-----+ +-----+ <\- stack_pointer

The two links correspond to the two effect handlers in the program. When the
effect F is handled in baz, the program state looks as follows:

+-----+ +-----+ +-----+ | | | | | | +-+ | baz | | bar |<\--| foo |<\--|k| | | | | | | +-+ +-----+ <\- stack_pointer +-----+ +-----+

The delimited continuation k is an object on the heap that refers to the
segment of the stack that corresponds to the suspended computation. Capturing
a continuation does not involve copying stack frames. When the continuation is
resumed, the stack is restored to the previous state by linking together the
segment pointed to by k to the current stack. Since neither continuation
capture nor resumption requires copying stack frames, suspending the execution
using perform and resuming it using either continue or discontinue are fast.

#### ﻿Unhandled effects

Unlike languages such as Eff and Koka, effect handlers in OCaml do not provide
effect safety; the compiler does not statically ensure that all the effects
performed by the program are handled. If effects do not have a matching
handler, then an Effect.Unhandled exception is raised at the point of the
corresponding perform. For example, in the previous example, bar does not
handle the effect F. Hence, we will get an Effect.Unhandled F exception when
we run bar.

try bar () with Effect.Unhandled F -> "Saw Effect.Unhandled exception"

\- : string = "Saw Effect.Unhandled exception"

#### ﻿Linear continuations

As discussed earlier 12.24.3, the delimited continuations in OCaml must be
used linearly – _every captured continuation must be resumed either with a
continue or discontinue exactly once_. Attempting to use a continuation more
than once raises a Continuation_already_resumed exception. For example:

try perform (Xchg 0) with | effect Xchg n, k -> continue k 21 + continue k 21

Exception: Stdlib.Effect.Continuation_already_resumed.

The primary motivation for adding effect handlers to OCaml is to enable
concurrent programming. One-shot continuations are sufficient for almost all
concurrent programming needs. They are also much cheaper to implement compared
to multi-shot continuations since they do not require stack frames to be
copied. Moreover, OCaml programs may also manipulate linear resources such as
sockets and file descriptors. The linearity discipline is easily broken if the
continuations are allowed to resume more than once. It would be quite hard to
debug such linearity violations on resources due to the lack of static checks
for linearity and the non-local nature of control flow. Hence, OCaml does not
support multi-shot continuations.

While the “at most once resumption” property of continuations is ensured with
a dynamic check, there is no check to ensure that the continuations are
resumed “at least once”. It is left to the user to ensure that the captured
continuations are resumed at least once. Not resuming continuations will leak
the memory allocated for the fibers as well as any resources that the
suspended computation may hold.

One may install a finaliser on the captured continuation to ensure that the
resources are freed:

exception Unwind Gc.finalise (fun k -> try ignore (discontinue k Unwind) with
_ -> ()) k

In this case, if k becomes unreachable, then the finaliser ensures that the
continuation stack is unwound by discontinuing with an Unwind exception,
allowing the computation to free up resources. However, the runtime cost of
finalisers is much more than the cost of capturing a continuation. Hence, it
is recommended that the user take care of resuming the continuation exactly
once rather than relying on the finaliser.

#### ﻿Limitations

OCaml’s effects are _synchronous_ : It is not possible to perform an effect
asynchronously from a signal handler, a finaliser, a memprof callback, or a GC
alarm, and catch it from the main part of the code. Instead, this would result
in an Effect.Unhandled exception (12.24.5).

Similarly, effects are incompatible with the use of callbacks from C to OCaml
(section [23.7](intfc.html#s%3Ac-callback)). It is not possible for an effect
to cross a call to caml_callback, this would instead result in an
Effect.Unhandled exception. In particular, care must be taken when mixing
libraries that use callbacks from C to OCaml and libraries that use effects.

### ﻿12.24.6 Shallow handlers

The examples that we have seen so far have used deep handlers. A deep handler
handles all the effects performed (in sequence) by the computation. Whenever a
continuation is captured in a deep handler, the captured continuation also
includes the handler. This means that, when the continuation is resumed, the
effect handler is automatically re-installed, and will handle the effect(s)
that the computation may perform in the future.

OCaml also provides shallow handlers. Compared to deep handlers, a shallow
handler handles only the first effect performed by the computation. The
continuation captured in a shallow handler does not include the handler. This
means that, when the continuation is resumed, the handler is no longer
present. For this reason, when the continuation is resumed, the user is
expected to provide a new effect handler (possibly a different one) to handle
the next effect that the computation may perform.

Shallow handlers make it easier to express certain kinds of programs. Let us
implement a shallow handler that enforces a particular sequence of effects (a
protocol) on a computation. For this example, let us consider that the
computation may perform the following effects:

type _ Effect.t += Send : int -> unit Effect.t | Recv : int Effect.t

Let us assume that we want to enforce a protocol that only permits an
alternating sequence of Send and Recv effects that conform to the regular
expression (Send;Recv)*;Send?. Hence, the sequence of effects [] (the empty
sequence), [Send], [Send;Recv], [Send;Recv;Send], etc., are allowed, but not
[Recv], [Send;Send], [Send;Recv;Recv], etc. The key observation here is that
the set of effects handled evolves over time. We can enforce this protocol
quite naturally using shallow handlers as shown below:

open Effect.Shallow let run (comp: unit -> unit) : unit = let rec loop_send : type a. (a,unit) continuation -> a -> unit = fun k v -> continue_with k v { retc = Fun.id; exnc = raise; effc = fun (type b) (eff : b Effect.t) -> match eff with | Send n -> Some (fun (k: (b,_) continuation) -> loop_recv n k ()) | Recv -> failwith "protocol violation" | _ -> None } and loop_recv : type a. int -> (a,unit) continuation -> a -> unit = fun n k v -> continue_with k v { retc = Fun.id; exnc = raise; effc = fun (type b) (eff : b Effect.t) -> match eff with | Recv -> Some (fun (k: (b,_) continuation) -> loop_send k n) | Send v -> failwith "protocol violation" | _ -> None } in loop_send (fiber comp) ()

The run function executes the computation comp ensuring that it can only
perform an alternating sequence of Send and Recv effects. The shallow handler
uses a different set of primitives compared to the deep handler. The primitive
fiber (on the last line) takes an 'a -> 'b function and returns a ('a,'b)
Effect.Shallow.continuation.

Unlike deep handlers, OCaml does not provide syntax support for shallow
handlers. The expression continue_with k v h resumes the continuation k with
value v under the handler h. The handler here is a record with three fields
for the value case (retc), the exceptional case (exnc) and the effect case
(effc).

The mutually recursive functions loop_send and loop_recv resume the given
continuation k with value v under different handlers. The loop_send function
handles the Send effect and tail calls the loop_recv function. If the
computation performs the Recv effect, then loop_send aborts the computation by
raising an exception. Similarly, the loop_recv function handles the Recv
effect and tail calls the loop_send function. If the computation performs the
Send effect, then loop_recv aborts the computation. Given that the
continuation captured in the shallow handler do not include the handler, there
is only ever one handler installed in the dynamic scope of the computation
comp.

Note that unlike deep handlers with syntax support, explicit type annotations
are necessary for the shallow handler. We must use a locally abstract type
(type b) in the effect handler (effc) and explicitly type annotate the effect
argument eff and the continuation k in each of the effect cases. Another point
to note is that the catch-all effect case “| _ -> None” is necessary. This
case may be intuitively read as “forward the unhandled effects to the outer
handler”. The standard library module [Effect](libref/Effect.html) also
provides a non-syntactic version of deep handlers, where similar annotations
are necessary.

The computation is initially executed by the loop_send function (see last line
in the code above) which ensures that the first effect that the computation is
allowed to perform is the Send effect. Note that the computation is free to
perform effects other than Send and Recv, which may be handled by an outer
handler.

We can see that the run function will permit a computation that follows the
protocol:

run (fun () -> printf "Send 42\n"; perform (Send 42); printf "Recv: %d\n"
(perform Recv); printf "Send 43\n"; perform (Send 43); printf "Recv: %d\n"
(perform Recv))

Send 42 Recv: 42 Send 43 Recv: 43 \- : unit = ()

and aborts those that do not:

run (fun () -> Printf.printf "Send 0\n"; perform (Send 0); Printf.printf "Send
1\n"; perform (Send 1) (* protocol violation *))

Send 0 Send 1 Exception: Failure "protocol violation".

We may implement the same example using deep handlers using reference cells
(easy, but unsatisfying) or without them (harder). We leave this as an
exercise to the reader.

* * *

[![Previous](previous_motif.svg)](bindingops.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](arrayliterals.html)

