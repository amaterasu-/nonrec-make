# embedded-nonrec-make

## Justification

I picked up nonrec-make as the basis for a make-based project for work
on a Linux hosted project targeting a mixed embedded Linux, plus
bare-metal microcontroller project.

The basic pieces of nonrec-make form a nice core:

 * Declarative language
 * Support for building multiple `BUILD_MODE`s using out-of-tree obj
   directories
 * Some abstraction of platform
 * In-built support for -j parallel builds

But with a bit of extra work we can have a nice platform with:

 * Built-in host-based unit testing in code and script tests
 * Better dependency tracking
 * Simple "convention-based" rules to avoid having to keep Rules.mk
   files up to date
 * Support for cross-testing
 * Helpers for maintaining cross-platform code

So after having learnt a lot for the work project I'm back to re-write
everything from scratch, under a free software license, getting a
chance to learn from some mistakes, and a chance to do things better
the second time.

## Incompatibility with nonrec-make

### `$^` dependencies

Existing `target_CMD` command example uses `$^` to for its link
command-line.  Since we now track Makefiles as dependencies of normal
targets `$^` includes makefiles that will confuse the linker.  Use
`$(filter)` to only pass .o files.

Specifically (if you use `=` rules) you can use `$(DEP_OBJS)` to only
pass .o files.

```
cli$(EXE)_DEPS = cli.o cli_dep.o
cli$(EXE)_CMD = $(LINK.c) $(DEP_OBJS) $(LDLIBS) -o $@
```

# Testing

There are first-class test targets `test` and `test_tree` that behave
like the existing `tree` and `all` rules.

Compiled tests are defined by the `TESTS` variable and depend on the
binary file of the same name that is built in.  For example two tests
are defined below, built from source.

```Makefile
TARGETS := passes fails

passes_DEPS := passes.o
fails_DEPS := fails.o

TESTS := passes fails
fails_FAILS := true
```

Some tests mat be broken for small periods of time, so you may mark
them as `_FAILS` as above.  In this case success and failure are
inverted - it is an error for a `_FAILS` test to pass (you were
supposed to fix it, right, and mark it as working again).

## Environment

TESTS assumes the tests themselves are executables, you run them by
executing them where they were built.  Thus they are run from
`$(OBJPATH)` as their working directory.  They expect to run by
invoking directly from the command-line.

You may pass arguments to a test using the `_ARGS` declaration as
below.  Additionally you may add dependencies that are built before
running the tests.  Additionally these dependencies are actual
make-dependencies of the test results.  ie you should add your input
test-data as `_TEST_DEPS` so that the tests need to be re-run if the
input files change.  Additionally if those test-inputs need generation
or outputs of another test that should work too if `make ` knows how
to build them.

```
# For now adding unneeded dep on fails to test TEST_DEPS
passes_TEST_DEPS := fails
passes_ARGS := arg1 arg2 arg3
```

## Script tests

Script tests allow more complicated testing of built targets.  For
example you can test multitple different arguments or multiple
different calls of your built executables.

Script tests require an interpreter - eg a shell or script
interpreter.  `SCRIPT_TESTS` are invoked based on their extension -
for example `test.sh` will be invoked `$(RUN.sh) path/to/test.sh`

You can add new script test support by defining other `$(RUN)`
variables - eg `RUN.py := python`.

For consistency they are also run out of `$(OBJDIR)`, even though the
script resides in `$(d)`.

```
SCRIPT_TESTS := test.sh

test.sh_ARGS := script_arg1 script_arg2
```


# Approach

## Makefile dependencies

Make works best when it has exactly the correct correct dependencies.
And when developing you want reliability of those dependencies.  Since
the `Rules.mk` files define the build commands if those files change
potentially they should require the rebuilding of targets definied in
those files.

One approach is the "kbuild" approach that generates build scripts for
each output file.  This approach works because if a the script for
generating the output file changes, then the output file needs to be
rebuilt.  This has the downside of requiring those files to be
regenerated on each run, slowing down startup.

Instead of following the build-script approach we instead add a simple
dependency on the makefiles that define.  Since make is a global
system and nonrec-make has two passes this could mean every makefile
could be a dependency of any file.  Instead we take the pragmatic
assumption and add dependencies on:

 * The Rules.mk file for the current $(d)
 * All Rules.mk files toward the root of the repository
 * The basic nonrec-make files themselves (everything loaded before the first Rules.mk)

## Separation of output files

All outputs *must* be kept to target specific obj/target
subdirectories otherwise interference between BUILD_MODEs would occur.

Thus `clean_extra` is deprecated

## Cross compilation

Managing multiple target platforms can become complicated - to help
keep code and makefiles cleaner we define a set of platform variables
that may describe a given platform

```
PLATFORM_VARS := OS CPU PLATFORM BOARD
```

Example:

```
OS := Linux
CPU := x86_64
PLATFORM := pc
```

Each of these variables will be defined for the C pre-processor - eg
`-DOS_LINUX` `-DCPU_X86_64` `-DPLATFORM_PC`

### Bare-metal support

Multi-target projects often want to mix common code shared by multiple platforms, especially to allow cross-compilation and testing on host.  For similar targets

## Testing

Testing should be a first-class target of any usable build system.
You are writing tests for all of your code - right?  And especially
for embedded code, using good software design (ie appropriate
abstraction) significant algorithm coverage can be acheived on your
big fast host CPU.

### Testing stages

In reverse order:

1. The test target itself - building this causes the test to run.  If the test succeeds the target is built and make ends.  If the test fails the target must not be rebuilt.
2. The test must be re-run if the test program itself is rebuilt - thus the test target depends on it.  Conversely running the test should cause the program to be rebuilt if necessary
3. The test must be re-run if any input files change (they could change the results) thus the test target depends on any input files.  Conversely if any test files need generation they will be built as required.

Test environment

An open question is whether a test should be run in the directory of
the source file `$(d)`, or the context of the built binary
`$(OBJPATH)`.

`$(d)` is more natural if test input is in the source directory.
`$(OBJPATH)` has the benefit that tests don't need to be told their
`$(OBJPATH)` if they need to reference generated output.

The natural location differs for binary vs script (no generated files)
tests.


### Cross testing

1. How are programs run on target?  ssh? serial console? debugger? flash?
2. Test dependencies - test files need to be made available on the remote target.  network?  shares?  scp/rsync?
3. How is test-success determined?  Does the target support processes? exit codes?


# Extras

Find yourself typing `make BUILD_MODE=xyz` all the time?

```
cp completion/bash_completion /etc/bash_completion.d/nonrec-make
```

Then next time you load your shell:

```
make B<tab>
make BUILD_MODE=
make BUILD_MODE=<tab>
xyz debug release
```

# TODO

## Daytona compatiblity

LINKORDER? DEPENDS? Tests vs binaries?

Filter directories and/or targets by OS/CPU/PLATFORM/BOARD/PROJECT.
Currently only whole-platform opt-in support for OPT_IN_PLATFORMS is
working.


## Host builds for embedded cross targets

Sometimes you need to build a host-tool to run to build a cross output.
