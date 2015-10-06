import os except sleep
import posix, parseutils
include system/ansi_c
## This library makes your code run as a daemon process on Unix-like systems.

var
  pid: Pid
  pidFileInner: string
  fi, fo, fe: File

proc onStop(sig: cint) {.noconv.} =
  close(fi)
  close(fo)
  close(fe)
  removeFile(pidFileInner)

  quit(QuitSuccess)

template daemonize*(pidfile, si, so, se: string, body: stmt): expr =
  ## deamonizer
  ##
  ## pidfile: path to file where pid will be stored
  ## si: standard input for daemonzied process
  ## so: standard output for daemonzied process
  ## se: standard ouput for daemonzied process

  if fileExists(pidfile):
    raise newException(IOError, "pidfile " & pidfile & " already exist, daemon already running?")


  pid = fork()
  if pid > 0:
    quit(QuitSuccess)

  discard chdir("/")
  discard setsid()
  discard umask(0)

  pid = fork()
  if pid > 0:
    quit(QuitSuccess)

  flushFile(stdout)
  flushFile(stderr)

  if not si.isNil and si != "":
    fi = open(si, fmRead)
    discard dup2(getFileHandle(fi), getFileHandle(stdin))

  if not so.isNil and so != "":
    fo = open(so, fmAppend)
    discard dup2(getFileHandle(fo), getFileHandle(stdout))

  if not se.isNil and se != "":
    fe = open(se, fmAppend)
    discard dup2(getFileHandle(fe), getFileHandle(stderr))

  pidFileInner = pidfile

  c_signal(SIGINT, onStop)
  c_signal(SIGTERM, onStop)

  pid = getpid()
  writeFile(pidfile, $pid)

  c_free(addr pid)

  body

when isMainModule:
  proc main() =
    var i = 0
    while true:
      i.inc()
      echo i
      discard sleep(1)
  daemonize("/tmp/daemonize.pid", "/dev/null", "/tmp/daemonize.out", "/tmp/daemonize.err"):
    main()
