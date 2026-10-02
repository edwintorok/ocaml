[![Previous](previous_motif.svg)](ocamldoc.html)
[![Up](contents_motif.svg)](index.html) [![Next](next_motif.svg)](native-
debugger.html)

* * *

# Chapter 20 The debugger (ocamldebug)

  * [20.1 Compiling for debugging](debugger.html#s%3Adebugger-compilation)
  * [20.2 Invocation](debugger.html#s%3Adebugger-invocation)
  * [20.3 Commands](debugger.html#s%3Adebugger-commands)
  * [20.4 Executing a program](debugger.html#s%3Adebugger-execution)
  * [20.5 Breakpoints](debugger.html#s%3Abreakpoints)
  * [20.6 The call stack](debugger.html#s%3Adebugger-callstack)
  * [20.7 Examining variable values](debugger.html#s%3Adebugger-examining-values)
  * [20.8 Controlling the debugger](debugger.html#s%3Adebugger-control)
  * [20.9 Miscellaneous commands](debugger.html#s%3Adebugger-misc-cmds)
  * [20.10 Running the debugger under Emacs](debugger.html#s%3Ainf-debugger)

This chapter describes the OCaml source-level replay debugger ocamldebug.

The debugger is available on systems that provide BSD sockets, including
Windows. Under the native Windows ports, the replay functions are not enabled.

## ﻿20.1 Compiling for debugging

Before the debugger can be used, the program must be compiled and linked with
the -g option: all .cmo and .cma files that are part of the program should
have been created with ocamlc -g, and they must be linked together with ocamlc
-g.

Compiling with -g entails no penalty on the running time of programs: object
files and bytecode executable files are bigger and take longer to produce, but
the executable files run at exactly the same speed as if they had been
compiled without -g.

## ﻿20.2 Invocation

### ﻿20.2.1 Starting the debugger

The OCaml debugger is invoked by running the program ocamldebug with the name
of the bytecode executable file as first argument:

    
    
            ocamldebug [options] program [arguments]
    

The arguments following program are optional, and are passed as command-line
arguments to the program being debugged. (See also the set arguments command.)

The following command-line options are recognized:

-c  count
     Set the maximum number of simultaneously live checkpoints to count.
-cd  dir
     Run the debugger program from the working directory dir, instead of the current directory. (See also the cd command.)
-emacs
     Tell the debugger it is executed under Emacs. (See section 20.10 for information on how to run the debugger under Emacs.)
-I directory
     Add directory to the list of directories searched for source files and compiled files. (See also the directory command.)
-s socket
     Use socket for communicating with the debugged program. See the description of the command set socket (section 20.8.8) for the format of socket.
-version
     Print version string and exit.
-vnum
     Print short version number and exit.
-help or \--help
     Display a short usage summary and exit. 

### ﻿20.2.2 Initialization file

On start-up, the debugger will read commands from an initialization file
before giving control to the user. The default file is .ocamldebug in the
current directory if it exists, otherwise .ocamldebug in the user’s home
directory.

### ﻿20.2.3 Exiting the debugger

The command quit exits the debugger. You can also exit the debugger by typing
an end-of-file character (usually ctrl-D).

Typing an interrupt character (usually ctrl-C) will not exit the debugger, but
will terminate the action of any debugger command that is in progress and
return to the debugger command level.

## ﻿20.3 Commands

A debugger command is a single line of input. It starts with a command name,
which is followed by arguments depending on this name. Examples:

    
    
            run
            goto 1000
            set arguments arg1 arg2
    

A command name can be truncated as long as there is no ambiguity. For
instance, go 1000 is understood as goto 1000, since there are no other
commands whose name starts with go. For the most frequently used commands,
ambiguous abbreviations are allowed. For instance, r stands for run even
though there are others commands starting with r. You can test the validity of
an abbreviation using the help command.

If the previous command has been successful, a blank line (typing just RET)
will repeat it.

### ﻿20.3.1 Getting help

The OCaml debugger has a simple on-line help system, which gives a brief
description of each command and variable.

help

     Print the list of commands.
help command

     Give help about the command command.
help set variable, help show variable

     Give help about the variable variable. The list of all debugger variables can be obtained with help set.
help info topic

     Give help about topic. Use help info to get a list of known topics. 

### ﻿20.3.2 Accessing the debugger state

set variable value

     Set the debugger variable variable to the value value.
show variable

     Print the value of the debugger variable variable.
info subject

     Give information about the given subject. For instance, info breakpoints will print the list of all breakpoints. 

## ﻿20.4 Executing a program

### ﻿20.4.1 Events

Events are “interesting” locations in the source code, corresponding to the
beginning or end of evaluation of “interesting” sub-expressions. Events are
the unit of single-stepping (stepping goes to the next or previous event
encountered in the program execution). Also, breakpoints can only be set at
events. Thus, events play the role of line numbers in debuggers for
conventional languages.

During program execution, a counter is incremented at each event encountered.
The value of this counter is referred as the _current time_. Thanks to reverse
execution, it is possible to jump back and forth to any time of the execution.

Here is where the debugger events (written ⋈) are located in the source code:

  * Following a function application: 
        
        (f arg)⋈
        

  * On entrance to a function: 
        
        fun x y z -> ⋈ ...
        

  * On each case of a pattern-matching definition (function, match…with construct, try…with construct): 
        
        function pat1 -> ⋈ expr1
               | ...
               | patN -> ⋈ exprN
        

  * Between subexpressions of a sequence: 
        
        expr1; ⋈ expr2; ⋈ ...; ⋈ exprN
        

  * In the two branches of a conditional expression: 
        
        if cond then ⋈ expr1 else ⋈ expr2
        

  * At the beginning of each iteration of a loop: 
        
        while cond do ⋈ body done
        for i = a to b do ⋈ body done
        

Exceptions: A function application followed by a function return is replaced
by the compiler by a jump (tail-call optimization). In this case, no event is
put after the function application.

### ﻿20.4.2 Starting the debugged program

The debugger starts executing the debugged program only when needed. This
allows setting breakpoints or assigning debugger variables before execution
starts. There are several ways to start execution:

run

     Run the program until a breakpoint is hit, or the program terminates. 
goto 0

     Load the program and stop on the first event. 
goto time

     Load the program and execute it until the given time. Useful when you already know approximately at what time the problem appears. Also useful to set breakpoints on function values that have not been computed at time 0 (see section 20.5). 

The execution of a program is affected by certain information it receives when
the debugger starts it, such as the command-line arguments to the program and
its working directory. The debugger provides commands to specify this
information (set arguments and cd). These commands must be used before program
execution starts. If you try to change the arguments or the working directory
after starting your program, the debugger will kill the program (after asking
for confirmation).

### ﻿20.4.3 Running the program

The following commands execute the program forward or backward, starting at
the current time. The execution will stop either when specified by the command
or when a breakpoint is encountered.

run

     Execute the program forward from current time. Stops at next breakpoint or when the program terminates. 
reverse

     Execute the program backward from current time. Mostly useful to go to the last breakpoint encountered before the current time. 
step [count]

     Run the program and stop at the next event. With an argument, do it count times. If count is 0, run until the program terminates or a breakpoint is hit. 
backstep [count]

     Run the program backward and stop at the previous event. With an argument, do it count times. 
next [count]

     Run the program and stop at the next event, skipping over function calls. With an argument, do it count times. 
previous [count]

     Run the program backward and stop at the previous event, skipping over function calls. With an argument, do it count times. 
finish

     Run the program until the current function returns. 
start

     Run the program backward and stop at the first event before the current function invocation. 

### ﻿20.4.4 Time travel

You can jump directly to a given time, without stopping on breakpoints, using
the goto command.

As you move through the program, the debugger maintains an history of the
successive times you stop at. The last command can be used to revisit these
times: each last command moves one step back through the history. That is
useful mainly to undo commands such as step and next.

goto time

     Jump to the given time. 
last [count]

     Go back to the latest time recorded in the execution history. With an argument, do it count times. 
set history size

     Set the size of the execution history. 

### ﻿20.4.5 Killing the program

kill

     Kill the program being executed. This command is mainly useful if you wish to recompile the program without leaving the debugger. 

## ﻿20.5 Breakpoints

A breakpoint causes the program to stop whenever a certain point in the
program is reached. It can be set in several ways using the break command.
Breakpoints are assigned numbers when set, for further reference. The most
comfortable way to set breakpoints is through the Emacs interface (see section
20.10).

break

     Set a breakpoint at the current position in the program execution. The current position must be on an event (i.e., neither at the beginning, nor at the end of the program).
break function

     Set a breakpoint at the beginning of function. This works only when the functional value of the identifier function has been computed and assigned to the identifier. Hence this command cannot be used at the very beginning of the program execution, when all identifiers are still undefined; use goto time to advance execution until the functional value is available.
break @ [module] line

     Set a breakpoint in module module (or in the current module if module is not given), at the first event of line line.
break @ [module] line column

     Set a breakpoint in module module (or in the current module if module is not given), at the event closest to line line, column column.
break @ [module] # character

     Set a breakpoint in module module at the event closest to character number character.
break  frag:pc, break  pc

     Set a breakpoint at code address frag:pc. The integer frag is the identifier of a code fragment, a set of modules that have been loaded at once, either initially or with the Dynlink module. The integer pc is the instruction counter within this code fragment. If frag is omitted, it defaults to 0, which is the code fragment of the program loaded initially.
delete [breakpoint-numbers]

     Delete the specified breakpoints. Without argument, all breakpoints are deleted (after asking for confirmation).
info breakpoints

     Print the list of all breakpoints. 

## ﻿20.6 The call stack

Each time the program performs a function application, it saves the location
of the application (the return address) in a block of data called a stack
frame. The frame also contains the local variables of the caller function. All
the frames are allocated in a region of memory called the call stack. The
command backtrace (or bt) displays parts of the call stack.

At any time, one of the stack frames is “selected” by the debugger; several
debugger commands refer implicitly to the selected frame. In particular,
whenever you ask the debugger for the value of a local variable, the value is
found in the selected frame. The commands frame, up and down select whichever
frame you are interested in.

When the program stops, the debugger automatically selects the currently
executing frame and describes it briefly as the frame command does.

frame

     Describe the currently selected stack frame.
frame frame-number

     Select a stack frame by number and describe it. The frame currently executing when the program stopped has number 0; its caller has number 1; and so on up the call stack.
backtrace [count], bt [count]

     Print the call stack. This is useful to see which sequence of function calls led to the currently executing frame. With a positive argument, print only the innermost count frames. With a negative argument, print only the outermost -count frames.
up [count]

     Select and display the stack frame just “above” the selected frame, that is, the frame that called the selected frame. An argument says how many frames to go up.
down [count]

     Select and display the stack frame just “below” the selected frame, that is, the frame that was called by the selected frame. An argument says how many frames to go down. 

## ﻿20.7 Examining variable values

The debugger can print the current value of simple expressions. The
expressions can involve program variables: all the identifiers that are in
scope at the selected program point can be accessed.

Expressions that can be printed are a subset of OCaml expressions, as
described by the following grammar:

| simple-expr| ::=|  [lowercase-ident](lex.html#lowercase-ident)  
---|---|---  
 | ∣|  { [capitalized-ident](lex.html#capitalized-ident) . } [lowercase-ident](lex.html#lowercase-ident)  
 | ∣|  *  
 | ∣|  $ integer  
 | ∣|  simple-expr . [lowercase-ident](lex.html#lowercase-ident)  
 | ∣|  simple-expr .( integer )  
 | ∣|  simple-expr .[ integer ]  
 | ∣|  ! simple-expr  
 | ∣|  ( simple-expr )  
  
The first two cases refer to a value identifier, either unqualified or
qualified by the path to the structure that define it. * refers to the result
just computed (typically, the value of a function application), and is valid
only if the selected event is an “after” event (typically, a function
application). $ integer refer to a previously printed value. The remaining
four forms select part of an expression: respectively, a record field, an
array element, a string element, and the current contents of a reference.

print variables

     Print the values of the given variables. print can be abbreviated as p. 
display variables

     Same as print, but limit the depth of printing to 1. Useful to browse large data structures without printing them in full. display can be abbreviated as d. 

When printing a complex expression, a name of the form $integer is
automatically assigned to its value. Such names are also assigned to parts of
the value that cannot be printed because the maximal printing depth is
exceeded. Named values can be printed later on with the commands p $integer or
d $integer. Named values are valid only as long as the program is stopped.
They are forgotten as soon as the program resumes execution.

set print_depth d

     Limit the printing of values to a maximal depth of d. 
set print_length l

     Limit the printing of values to at most l nodes printed. 

## ﻿20.8 Controlling the debugger

### ﻿20.8.1 Setting the program name and arguments

set program file

     Set the program name to file. 
set arguments arguments

     Give arguments as command-line arguments for the program. 

A shell is used to pass the arguments to the debugged program. You can
therefore use wildcards, shell variables, and file redirections inside the
arguments. To debug programs that read from standard input, it is recommended
to redirect their input from a file (using set arguments < input-file),
otherwise input to the program and input to the debugger are not properly
separated, and inputs are not properly replayed when running the program
backwards.

### ﻿20.8.2 How programs are loaded

The loadingmode variable controls how the program is executed.

set loadingmode direct

     The program is run directly by the debugger. This is the default mode. 
set loadingmode runtime

     The debugger execute the OCaml runtime ocamlrun on the program. Rarely useful; moreover it prevents the debugging of programs compiled in “custom runtime” mode. 
set loadingmode manual

     The user starts manually the program, when asked by the debugger. Allows remote debugging (see section 20.8.8). 

### ﻿20.8.3 Search path for files

The debugger searches for source files and compiled interface files in a list
of directories, the search path. The search path initially contains the
current directory . and the standard library directory. The directory command
adds directories to the path.

Whenever the search path is modified, the debugger will clear any information
it may have cached about the files.

directory directorynames

     Add the given directories to the search path. These directories are added at the front, and will therefore be searched first.
directory directorynames for modulename

     Same as directory directorynames, but the given directories will be searched only when looking for the source file of a module that has been packed into modulename.
directory

     Reset the search path. This requires confirmation. 

### ﻿20.8.4 Working directory

Each time a program is started in the debugger, it inherits its working
directory from the current working directory of the debugger. This working
directory is initially whatever it inherited from its parent process
(typically the shell), but you can specify a new working directory in the
debugger with the cd command or the -cd command-line option.

cd directory

     Set the working directory for ocamldebug to directory.
pwd

     Print the working directory for ocamldebug. 

### ﻿20.8.5 Turning reverse execution on and off

In some cases, you may want to turn reverse execution off. This speeds up the
program execution, and is also sometimes useful for interactive programs.

Normally, the debugger takes checkpoints of the program state from time to
time. That is, it makes a copy of the current state of the program (using the
Unix system call fork). If the variable checkpoints is set to off, the
debugger will not take any checkpoints.

set checkpoints on/off

     Select whether the debugger makes checkpoints or not. 

### ﻿20.8.6 Behavior of the debugger with respect to fork

When the program issues a call to fork, the debugger can either follow the
child or the parent. By default, the debugger follows the parent process. The
variable follow_fork_mode controls this behavior:

set follow_fork_mode child/parent

     Select whether to follow the child or the parent in case of a call to fork. 

### ﻿20.8.7 Stopping execution when new code is loaded

The debugger is compatible with the Dynlink module. However, when an external
module is not yet loaded, it is impossible to set a breakpoint in its code. In
order to facilitate setting breakpoints in dynamically loaded code, the
debugger stops the program each time new modules are loaded. This behavior can
be disabled using the break_on_load variable:

set break_on_load on/off

     Select whether to stop after loading new code. 

### ﻿20.8.8 Communication between the debugger and the program

The debugger communicate with the program being debugged through a Unix
socket. You may need to change the socket name, for example if you need to run
the debugger on a machine and your program on another.

set socket socket

     Use socket for communication with the program. socket can be either a file name, or an Internet port specification host:port, where host is a host name or an Internet address in dot notation, and port is a port number on the host. 

On the debugged program side, the socket name is passed through the
CAML_DEBUG_SOCKET environment variable.

### ﻿20.8.9 Fine-tuning the debugger

Several variables enables to fine-tune the debugger. Reasonable defaults are
provided, and you should normally not have to change them.

set processcount count

     Set the maximum number of checkpoints to count. More checkpoints facilitate going far back in time, but use more memory and create more Unix processes. 

As checkpointing is quite expensive, it must not be done too often. On the
other hand, backward execution is faster when checkpoints are taken more
often. In particular, backward single-stepping is more responsive when many
checkpoints have been taken just before the current time. To fine-tune the
checkpointing strategy, the debugger does not take checkpoints at the same
frequency for long displacements (e.g. run) and small ones (e.g. step). The
two variables bigstep and smallstep contain the number of events between two
checkpoints in each case.

set bigstep count

     Set the number of events between two checkpoints for long displacements. 
set smallstep count

     Set the number of events between two checkpoints for small displacements. 

The following commands display information on checkpoints and events:

info checkpoints

     Print a list of checkpoints. 
info events [module]

     Print the list of events in the given module (the current module, by default). 

### ﻿20.8.10 User-defined printers

Just as in the toplevel system (section [14.2](toplevel.html#s%3Atoplevel-
directives)), the user can register functions for printing values of certain
types. For technical reasons, the debugger cannot call printing functions that
reside in the program being debugged. The code for the printing functions must
therefore be loaded explicitly in the debugger.

load_printer "file-name"

     Load in the debugger the indicated .cmo or .cma object file. The file is loaded in an environment consisting only of the OCaml standard library plus the definitions provided by object files previously loaded using load_printer. If this file depends on other object files not yet loaded, the debugger automatically loads them if it is able to find them in the search path. The loaded file does not have direct access to the modules of the program being debugged.
install_printer printer-name

     Register the function named printer-name (a value path) as a printer for objects whose types match the argument type of the function. That is, the debugger will call printer-name when it has such an object to print. The printing function printer-name must use the Format library module to produce its output, otherwise its output will not be correctly located in the values printed by the toplevel loop.

The value path printer-name must refer to one of the functions defined by the
object files loaded using load_printer. It cannot reference the functions of
the program being debugged.

remove_printer printer-name

     Remove the named function from the table of value printers. 

## ﻿20.9 Miscellaneous commands

list [module] [beginning] [end]

     List the source of module module, from line number beginning to line number end. By default, 20 lines of the current module are displayed, starting 10 lines before the current position. 
source filename

     Read debugger commands from the script filename. 

## ﻿20.10 Running the debugger under Emacs

The most user-friendly way to use the debugger is to run it under Emacs with
the OCaml mode available through MELPA and also at
[https://github.com/ocaml/caml-mode](https://github.com/ocaml/caml-mode).

The OCaml debugger is started under Emacs by the command M-x camldebug, with
argument the name of the executable file progname to debug. Communication with
the debugger takes place in an Emacs buffer named *camldebug-progname*. The
editing and history facilities of Shell mode are available for interacting
with the debugger.

In addition, Emacs displays the source files containing the current event (the
current position in the program execution) and highlights the location of the
event. This display is updated synchronously with the debugger action.

The following bindings for the most common debugger commands are available in
the *camldebug-progname* buffer:

C-c C-s

     (command step): execute the program one step forward. 
C-c C-k

     (command backstep): execute the program one step backward. 
C-c C-n

     (command next): execute the program one step forward, skipping over function calls. 
Middle mouse button

     (command display): display named value. $n under mouse cursor (support incremental browsing of large data structures). 
C-c C-p

     (command print): print value of identifier at point. 
C-c C-d

     (command display): display value of identifier at point. 
C-c C-r

     (command run): execute the program forward to next breakpoint. 
C-c C-v

     (command reverse): execute the program backward to latest breakpoint. 
C-c C-l

     (command last): go back one step in the command history. 
C-c C-t

     (command backtrace): display backtrace of function calls. 
C-c C-f

     (command finish): run forward till the current function returns. 
C-c <

     (command up): select the stack frame below the current frame. 
C-c >

     (command down): select the stack frame above the current frame. 

In all buffers in OCaml editing mode, the following debugger commands are also
available:

C-x C-a C-b

     (command break): set a breakpoint at event closest to point 
C-x C-a C-p

     (command print): print value of identifier at point 
C-x C-a C-d

     (command display): display value of identifier at point 

* * *

[![Previous](previous_motif.svg)](ocamldoc.html)
[![Up](contents_motif.svg)](index.html) [![Next](next_motif.svg)](native-
debugger.html)

