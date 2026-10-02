[![Previous](previous_motif.svg)](gadts.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](attributes.html)

* * *

## ﻿12.11 Syntax for Bigarray access

(Introduced in Objective Caml 3.00)

| [expr](expr.html#expr)| ::=|  ...  
---|---|---  
 | ∣|  [expr](expr.html#expr) .{ [expr](expr.html#expr) { , [expr](expr.html#expr) } }  
 | ∣|  [expr](expr.html#expr) .{ [expr](expr.html#expr) { , [expr](expr.html#expr) } } <- [expr](expr.html#expr)  
  
This extension provides syntactic sugar for getting and setting elements in
the arrays provided by the [Bigarray](libref/Bigarray.html) module.

The short expressions are translated into calls to functions of the Bigarray
module as described in the following table.

expression| translation  
---|---  
[expr](expr.html#expr)0.{[expr](expr.html#expr)1}| Bigarray.Array1.get
[expr](expr.html#expr)0 [expr](expr.html#expr)1  
[expr](expr.html#expr)0.{[expr](expr.html#expr)1} <-[expr](expr.html#expr)|
Bigarray.Array1.set [expr](expr.html#expr)0 [expr](expr.html#expr)1
[expr](expr.html#expr)  
[expr](expr.html#expr)0.{[expr](expr.html#expr)1, [expr](expr.html#expr)2}|
Bigarray.Array2.get [expr](expr.html#expr)0 [expr](expr.html#expr)1
[expr](expr.html#expr)2  
[expr](expr.html#expr)0.{[expr](expr.html#expr)1, [expr](expr.html#expr)2}
<-[expr](expr.html#expr)| Bigarray.Array2.set [expr](expr.html#expr)0
[expr](expr.html#expr)1 [expr](expr.html#expr)2 [expr](expr.html#expr)  
[expr](expr.html#expr)0.{[expr](expr.html#expr)1, [expr](expr.html#expr)2,
[expr](expr.html#expr)3}| Bigarray.Array3.get [expr](expr.html#expr)0
[expr](expr.html#expr)1 [expr](expr.html#expr)2 [expr](expr.html#expr)3  
[expr](expr.html#expr)0.{[expr](expr.html#expr)1, [expr](expr.html#expr)2,
[expr](expr.html#expr)3} <-[expr](expr.html#expr)| Bigarray.Array3.set
[expr](expr.html#expr)0 [expr](expr.html#expr)1 [expr](expr.html#expr)2
[expr](expr.html#expr)3 [expr](expr.html#expr)  
[expr](expr.html#expr)0.{[expr](expr.html#expr)1, …, [expr](expr.html#expr)n}|
Bigarray.Genarray.get  [expr](expr.html#expr)0 [| [expr](expr.html#expr)1, … ,
[expr](expr.html#expr)n |]  
[expr](expr.html#expr)0.{[expr](expr.html#expr)1, …, [expr](expr.html#expr)n}
<-[expr](expr.html#expr)| Bigarray.Genarray.set  [expr](expr.html#expr)0 [|
[expr](expr.html#expr)1, … , [expr](expr.html#expr)n |] [expr](expr.html#expr)  
  
The last two entries are valid for any n > 3\.

* * *

[![Previous](previous_motif.svg)](gadts.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](attributes.html)

