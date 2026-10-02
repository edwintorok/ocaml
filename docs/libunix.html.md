[![Previous](previous_motif.svg)](parsing.html)
[![Up](contents_motif.svg)](index.html) [![Next](next_motif.svg)](libstr.html)

* * *

# Chapter 32 The unix library: Unix system calls

The unix library makes many Unix system calls and system-related library
functions available to OCaml programs. This chapter describes briefly the
functions provided. Refer to sections 2 and 3 of the Unix manual for more
details on the behavior of these functions.

  * [Module Unix](libref/Unix.html): Unix system calls 
  * [Module UnixLabels](libref/UnixLabels.html): Labeled Unix system calls 

Not all functions are provided by all Unix variants. If some functions are not
available, they will raise Invalid_arg when called.

Programs that use the unix library must be linked as follows:

    
    
            ocamlc other options -I +unix unix.cma other files
            ocamlopt other options  -I +unix unix.cmxa other files
    

For interactive use of the unix library, do:

    
    
            ocamlmktop -o mytop -I +unix unix.cma
            ./mytop
    

or (if dynamic linking of C libraries is supported on your platform), start
ocaml and type

# #directory "+unix";;

# #load "unix.cma";;

> Windows: The Cygwin port of OCaml fully implements all functions from the
> Unix module. The native Win32 ports implement a subset of them. Below is a
> list of the functions that are not implemented, or only partially
> implemented, by the Win32 ports. Functions not mentioned are fully
> implemented and behave as described previously in this chapter.

Functions| Comment  
---|---  
fork| not implemented, use create_process or threads  
wait| not implemented, use waitpid  
waitpid| can only wait for a given PID, not any child process  
getppid| not implemented (meaningless under Windows)  
nice| not implemented  
truncate, ftruncate| implemented (since 4.10.0)  
link| implemented (since 3.02)  
fchmod| not implemented  
chown, fchown| not implemented (make no sense on a DOS file system)  
umask| not implemented  
access| execute permission X_OK cannot be tested, it just tests for read
permission instead  
chroot| not implemented  
mkfifo| not implemented  
symlink, readlink| implemented (since 4.03.0)  
kill| partially implemented (since 4.00.0): only the sigkill signal is
implemented  
sigprocmask, sigpending, sigsuspend| not implemented (no inter-process signals
on Windows  
pause| not implemented (no inter-process signals in Windows)  
alarm| not implemented  
times| partially implemented, will not report timings for child processes  
getitimer, setitimer| not implemented  
getuid, geteuid, getgid, getegid| always return 1  
setuid, setgid, setgroups, initgroups| not implemented  
getgroups| always returns [|1|] (since 2.00)  
getpwnam, getpwuid| always raise Not_found  
getgrnam, getgrgid| always raise Not_found  
type socket_domain| PF_INET is fully supported; PF_INET6 is fully supported
(since 4.01.0); PF_UNIX is supported since 4.14.0, but only works on Windows
10 1803 and later.  
establish_server| not implemented; use threads  
terminal functions (tc*)| not implemented  
setsid| not implemented  
  
* * *

[![Previous](previous_motif.svg)](parsing.html)
[![Up](contents_motif.svg)](index.html) [![Next](next_motif.svg)](libstr.html)

