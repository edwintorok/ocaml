[![Previous](previous_motif.svg)](afl-fuzz.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](tail_mod_cons.html)

* * *

# Chapter 26 Runtime tracing with runtime events

  * [26.1 Overview](runtime-tracing.html#s%3Aruntime-tracing-overview)
  * [26.2 Architecture](runtime-tracing.html#s%3Aruntime-tracing-architecture)
  * [26.3 Usage](runtime-tracing.html#s%3Aruntime-tracing-usage)
  * [26.4 Custom events](runtime-tracing.html#s%3Aruntime-tracing-custom-events)

This chapter describes the runtime events tracing system which enables
continuous extraction of performance information from the OCaml runtime with
very low overhead. The system and interfaces are low-level and tightly coupled
to the runtime implementation, it is intended for end-users to rely on tooling
to consume and visualise data of interest.

Data emitted includes:

  * Event times of garbage collector and runtime phases 
  * Minor and major heap sizings and utilization 
  * Allocation and promotion rates between heaps 

Additional events can be declared and consumed, providing higher-level
monitoring capabilities to OCaml libraries. They are referred to as _custom
events_.

## ﻿26.1 Overview

There are three main classes of events emitted by the runtime events system:

Spans

     Events spanning over a duration in time. For example, the runtime events tracing system emits a span event that starts when a minor collection begins in the OCaml garbage collector and ends when the collection is completed. Spans can contain other spans, e.g other span events may be emitted that begin after a minor collection has begun and end before it does. 
Lifecycle events

     Events that occur at a moment in time. For example, when a domain terminates, a corresponding lifecycle event is emitted. 
Counters

     Events that include a measurement of some quantity of interest. For example, the number of words promoted from the minor to the major heap during the last minor garbage collection is emitted as a counter event. 

The runtime events tracing system is designed to be used in different
contexts:

Self monitoring

     OCaml programs and libraries can install their own callbacks to listen for runtime events and react to them programmatically, for example, to export events to disk or over the network. 
External monitoring

     An external process can consume the runtime events of an OCaml program whose runtime tracing system has been enabled by setting the corresponding environment variable. 

The runtime events tracing system logs events to a _ring buffer_.
Consequently, old events are being overwritten by new events. Consumers can
either continuously consume events or choose to only do so in response to some
circumstance, e.g if a particular query or operation takes longer than
expected to complete.

## ﻿26.2 Architecture

The runtime tracing system conceptually consists of two parts: 1) the event
sources which emit events and 2) the events transport that ingests and
transports these events.

### ﻿26.2.1 Event sources

Event sources are event-emitting points. There are a number of such sources in
the OCaml runtime system. These are further split into two sets: 1) event
sources that are always available and 2) event sources that are only available
in the instrumented runtime. Event sources in the instrumented runtime are
primarily of interest to developers of the OCaml runtime and garbage collector
and only consist of major heap allocation size counter events.

The full set of events emitted by event sources and their documentation can be
found in [Module Runtime_events](libref/Runtime_events.html).

### ﻿26.2.2 Events transport

The events transport part of the system ingests events emitted by the event
sources and makes them available to consumers.

#### ﻿Ring buffers

Events are transported using a data structure known as a _ring buffer_. This
data structure consists of two pointers into a linear backing array, the tail
pointer points to a location where new events can be written and the head
pointer points to the oldest event in the buffer that can be read. When
insufficient space is available in the backing array to write new events, the
head pointer is advanced and the oldest events are overwritten by new ones.

The ring buffer implementation used in runtime events can be written by at
most one producer at a time but can be read simultaneously by multiple
consumers without coordination from the producer. There is a unique ring
buffer for every running domain and, on domain termination, ring buffers may
be reused for newly spawned domains. Ring buffers are only allocated
(including for the main domain) when runtime events are enabled. The ring
buffers themselves are stored in a memory-mapped file with the processes
identifier as the name and the extension .events, this enables them to be read
from outside the main OCaml process. See
[Runtime_events](libref/Runtime_events.html) for more information.

#### ﻿Consumption APIs

The runtime event tracing system provides both OCaml and C APIs which are
cursor-based and polling-driven. The high-level process for consuming events
is as follows:

  1. A cursor is created via Runtime_events.create_cursor for either the current process or an external process (specified by a path and PID). 
  2. Runtime_events.Callbacks.create is called to register a callback function to receive the events. 
  3. The cursor is polled via Runtime_events.read_poll using the callbacks created in the previous step. For each matching event in the ring buffers, the provided callback functions are called. In addition to the emitted events, callbacks are given the emitter domain’s index and the emission timestamp. 

## ﻿26.3 Usage

### ﻿26.3.1 With OCaml APIs

We start with a simple example that prints the name, begin and end times of
events emitted by the runtime event tracing system:

    
    
    let runtime_begin _ ts phase =
        Printf.printf "Begin\t%s\t%Ld\n"
            (Runtime_events.runtime_phase_name phase)
            (Runtime_events.Timestamp.to_int64 ts)
    
    let runtime_end _ ts phase =
        Printf.printf "End\t%s\t%Ld\n"
            (Runtime_events.runtime_phase_name phase)
            (Runtime_events.Timestamp.to_int64 ts)
    
    let () =
        Runtime_events.start ();
        let cursor = Runtime_events.create_cursor None in
        let callbacks = Runtime_events.Callbacks.create ~runtime_begin ~runtime_end ()
        in
        while true do
            let list_ref = ref [] in (* for later fake GC work *)
            for _ = 1 to 100 do
                (* here we do some fake GC work *)
                list_ref := [];
                for _ = 1 to 10 do
                    list_ref := (Sys.opaque_identity(ref 42)) :: !list_ref
                done;
                Gc.full_major ();
            done;
            ignore(Runtime_events.read_poll cursor callbacks None);
            Unix.sleep 1
        done
    

The next step is to compile and link the program with the runtime_events
library. This can be done as follows:

    
    
           ocamlopt -I +runtime_events -I +unix unix.cmxa runtime_events.cmxa
                example.ml -o example
    

When using the _dune_ build system, this example can be built as follows:

    
    
    (executable
     (name example)
     (modules example)
     (libraries unix runtime_events))
    

Running the compiled binary of the example gives an output similar to:

    
    
    Begin   explicit_gc_full_major  24086187297852
    Begin   stw_leader      24086187298594
    Begin   minor   24086187299404
    Begin   minor_global_roots      24086187299807
    End     minor_global_roots      24086187331461
    Begin   minor_remembered_set    24086187331631
    Begin   minor_finalizers_oldify 24086187544312
    End     minor_finalizers_oldify 24086187544704
    Begin   minor_remembered_set_promote    24086187544879
    End     minor_remembered_set_promote    24086187606414
    End     minor_remembered_set    24086187606584
    Begin   minor_finalizers_admin  24086187606854
    End     minor_finalizers_admin  24086187607152
    Begin   minor_local_roots       24086187607329
    Begin   minor_local_roots_promote       24086187609699
    End     minor_local_roots_promote       24086187610539
    End     minor_local_roots       24086187610709
    End     minor   24086187611746
    Begin   minor_clear     24086187612238
    End     minor_clear     24086187612580
    End     stw_leader      24086187613209
    ...
    

This is an example of self-monitoring, where a program explicitly starts
listening to runtime events and monitors itself.

For external monitoring, a program does not need to be aware of the existence
of runtime events. Runtime events can be controlled via the environment
variable OCAML_RUNTIME_EVENTS_START which, when set, will cause the runtime
tracing system to be started at program initialization.

We could remove Runtime_events.start (); from the previous example and,
instead, call the program as below to produce the same result:

    
    
    OCAML_RUNTIME_EVENTS_START=1 ./example
    

#### ﻿Environment variables

Environment variables can be used to control different aspects of the runtime
event tracing system. The following environment variables are available:

  * OCAML_RUNTIME_EVENTS_START if set will cause the runtime events system to be started as part of the OCaml runtime initialization. 
  * OCAML_RUNTIME_EVENTS_DIR sets the directory where the .events files containing the runtime event tracing system’s ring buffers will be located. If not present the program’s working directory will be used. 
  * OCAML_RUNTIME_EVENTS_PRESERVE if set will make the OCaml runtime preserve the runtime events ring buffer files past the termination of the OCaml program. This can be useful for monitoring very short running programs. If not set, the .events files of the OCaml program will be deleted at program termination. 

The size of the runtime events ring buffers can be configured via
OCAMLRUNPARAM, see section [15.2](runtime.html#s%3Aocamlrun-options) for more
information.

#### ﻿Building with the instrumented runtime

Some events are only emitted by the instrumented runtime. To receive them, the
OCaml program needs to be compiled and linked against the instrumented
runtime. For our example program from earlier, this is achieved as follows:

    
    
    ocamlopt -runtime-variant i -I +runtime_events -I +unix unix.cmxa runtime_events.cmxa example.ml -o example
    

And for dune:

    
    
    (executable
     (name example)
     (modules example)
     (flags "-runtime-variant=i")
     (libraries unix runtime_events))
    

Note that as of OCaml 5.6, the instrumented runtime is not built and installed
by default, but can be obtained by configuring OCaml with \--enable-
instrumented-runtime. The instrumented runtime is likely to be removed
completely in OCaml 5.7.

### ﻿26.3.2 With tooling

Programmatic access to events is intended primarily for writers of
observability libraries and tooling for end-users. The flexible API enables
use of the performance data from runtime events for logging and monitoring
purposes.

In this section we cover several utilities in the runtime_events_tools package
which provide simple ways of extracting and summarising data from runtime
events. The trace utility in particular produces similar data to the previous
’eventlog’ instrumentation system available in OCaml 4.12 to 4.14.

First, install runtime_events_tools in an OCaml 5.0+ opam switch:

    
    
    opam install runtime_events_tools
    

This should install the olly tool in your path. You can now generate runtime
traces for programs compiled with OCaml 5.0+ using the trace subcommand:

    
    
    olly trace trace.json 'your_program.exe .. args ..'
    

Runtime tracing data will be generated in the json Trace Event Format to
trace.json. This can then be loaded into the Chrome tracing viewer or into
[Perfetto](https://ui.perfetto.dev/) to visualize the collected trace.

#### ﻿Measuring GC latency

The olly utility also includes a latency subcommand which consumes runtime
events data and on program completion emits a parseable histogram summary of
pause durations. It can be run as follows:

    
    
    olly latency 'your_program.exe .. args ..'
    

This should produce an output similar to the following:

    
    
    GC latency profile:
    #[Mean (ms):	2.46,	 Stddev (ms):	3.87]
    #[Min (ms):	0.01,	 max (ms):	9.17]
    
    Percentile 	 Latency (ms)
    25.0000 	 0.01
    50.0000 	 0.23
    60.0000 	 0.23
    70.0000 	 0.45
    75.0000 	 0.45
    80.0000 	 0.45
    85.0000 	 0.45
    90.0000 	 9.17
    95.0000 	 9.17
    96.0000 	 9.17
    97.0000 	 9.17
    98.0000 	 9.17
    99.0000 	 9.17
    99.9000 	 9.17
    99.9900 	 9.17
    99.9990 	 9.17
    99.9999 	 9.17
    100.0000 	 9.17
    

## ﻿26.4 Custom events

### ﻿26.4.1 Overview

The runtime events system supports defining custom events, also known as _user
events_. Identified by a globally unique name, they are emitted with payloads
of built-in (unit, int, span) and user-defined types. To understand the
manipulation of custom events, it is useful to know how they are transported
and stored: their representation consists of a name string (in fact, an index
into an array of all custom names) and an arbitrary byte sequence. Custom
event types can be _registered_ by providing encoding and decoding functions
to and from a byte sequence, via the function Runtime_events.Type.register.

Defining a new custom event (whether its payload is of a built-in type or a
custom type) is done via another registration function,
Runtime_events.User.register. This function records the association between
the custom event’s name, its type, and a _tag_. The tag is then used when
emitting or consuming custom events; it acts as a shorthand for the event
name.

Once an event is registered, values for that event are emitted using
Runtime_events.User.write.

To summarize, for a user to emit and consume custom events using a custom type
they need to:

  1. register the custom type 
  2. extend the Runtime_events.User.tag variant with a new constructor 
  3. register the new custom event, binding together the custom event name, the new tag, and the new custom type 
  4. emit instances of the event using Runtime_events.User.write
  5. indicate a callback which should receive all events of the custom type using Runtime_events.Callbacks.add_user_event to register it inside a Runtime_events.Callbacks.t object to be used when polling (see section 26.3.1 above). 
  6. _(Optional, if there are distinct events registered with the same custom type:)_ In that callback, pattern-match on the event tag in order to discriminate between different event tags of the same custom type. 

Note that if the emitter and the consumer are different programs, both must
perform steps 1 to 3 to register custom events and custom event types (if
any). Note that the tag values need not be the same in both programs; the only
values that should match are the names.

Unregistered events for user-defined types are currently ignored. As a
fallback, unregistered, custom events of a built-in type are available, but
are all tagged UNK (unknown).

There are thus three cases for the consumer when an event is received:

  * event is registered: payload and tag are available. 
  * event is not registered and has a built-in event type (unit, int, span): only the payload is available. 
  * event is not registered and has a custom event type: event is dropped. 

Note that event consumers bind callbacks to event _types_ , so they can work
as generic listeners interpreting payloads coming from events that were not
registered. Because this only works for events of built-in types, it can be
useful to emit events in pairs: an event of a custom type with an event of a
built-in type, enabling the design of a specialized consumer while staying
compatible with generic tracing tools.

### ﻿26.4.2 Tracing custom events: an example

The following program uses the Runtime_events.User and Runtime_events.Type
modules to declare two custom events providing span and int values. The tag
extensible variant is extended with CustomSpan and CustomInt.

    
    
    type Runtime_events.User.tag += CustomSpan | CustomInt
    
    let count_span =
        Runtime_events.User.register "count.span" CustomSpan
            Runtime_events.Type.span
    
    let count_value =
        Runtime_events.User.register "count.value" CustomInt
            Runtime_events.Type.int
    
    let count () =
        Runtime_events.User.write count_span Begin;
        for i = 1 to 5 do
            Runtime_events.User.write count_value i
        done;
        Runtime_events.User.write count_span End
    
    let () =
        Runtime_events.start ();
        for _ = 1 to 3 do
            count ()
        done
    

On the consumer side, one can use the provided event tag and type to match on
the relevant events. For the sake of completeness, we assume that the consumer
is a different program, and repeat the definition of the new tag constructors,
as well as the registering of the custom events.

    
    
    type Runtime_events.User.tag += CustomSpan | CustomInt
    
    let count_span =
        Runtime_events.User.register "count.span" CustomSpan
            Runtime_events.Type.span
    
    let count_value =
        Runtime_events.User.register "count.value" CustomInt
            Runtime_events.Type.int
    
    let span_event_handler domain_index ts event value =
        (* we're only interested in our CustomSpan event *)
        match Runtime_events.User.tag event, value with
        | CustomSpan, Runtime_events.Type.Begin -> Printf.printf "> count begin\n"
        | CustomSpan, End -> Printf.printf "< count end\n"
        | _ -> ()
    
    let int_event_handler domain_index ts event value =
        (* we're only interested in our CustomInt event *)
        match Runtime_events.User.tag event with
        | CustomInt -> Printf.printf "| count %d\n" value
        | _ -> ()
    
    let () =
        let open Runtime_events in
        let cursor = create_cursor None in
        let callbacks =
            Callbacks.create ()
            |> Callbacks.add_user_event Type.span span_event_handler
            |> Callbacks.add_user_event Type.int int_event_handler
        in
        for _ = 0 to 100 do
            ignore(read_poll cursor callbacks None)
        done
    

Giving the following output:

    
    
    > count begin
    | count 1
    | count 2
    | count 3
    | count 4
    | count 5
    < count end
    > count begin
    | count 1
    | count 2
    [...]
    

* * *

[![Previous](previous_motif.svg)](afl-fuzz.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](tail_mod_cons.html)

