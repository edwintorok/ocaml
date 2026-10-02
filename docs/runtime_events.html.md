[![Previous](previous_motif.svg)](libstr.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](libthreads.html)

* * *

# Chapter 34 The runtime_events library

The runtime_events library provides an API for consuming runtime tracing and
metrics information from the runtime. See chapter [26](runtime-
tracing.html#c%3Aruntime-tracing) for more information.

Programs that use runtime_events must be linked as follows:

    
    
            ocamlc -I +runtime_events other options unix.cma runtime_events.cma other files
            ocamlopt -I +runtime_events other options unix.cmxa runtime_events.cmxa other files
    

Compilation units that use the runtime_events library must also be compiled
with the -I +runtime_events option (see chapter [13](comp.html#c%3Acamlc)).

  * [Module Runtime_events](libref/Runtime_events.html): tracing system 

* * *

[![Previous](previous_motif.svg)](libstr.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](libthreads.html)

