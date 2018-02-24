#!/bin/bash

# include bash_completion framework
. /etc/bash_completion

# and our completion script
. ../../bash_completion

# stub out compopt to stop it complaining
compopt() {
  # echo "Stubbed out compopt $@" >&2
  :
}

# Complete at given word and line-point
# see https://www.gnu.org/software/bash/manual/bashref.html#Bash-Variables
complete_at_point() {
  COMP_CWORD=$1; shift
  COMP_POINT=$1; shift

  COMP_LINE="$@"
  COMP_WORDS=("$@")

  COMPREPLY=()
  _nonrec_make "$@"

  echo "${COMPREPLY[@]}"
}

complete_at_end_of_line() {
  COMP_LINE="$@"
  # end of line
  COMP_POINT=${#COMP_LINE}
  COMP_WORDS=("$@")
  # last word
  COMP_CWORD=$(expr ${#COMP_WORDS[@]} - 1)

  COMPREPLY=()
  _nonrec_make "$@"

  echo "${COMPREPLY[@]}"
}

test_contains() {
  check="$1"; shift

  for i; do
    if [ "$i" = "$check" ]; then
      return 0
    fi
  done
  echo "Failed to find $check in '$@'"
  return 1
}

set -e

completion=$(complete_at_end_of_line make B)
test_contains "BUILD_MODE=" $completion

completion=$(complete_at_end_of_line make C)
test_contains "COLOR_TTY=" $completion

completion=$(complete_at_end_of_line make V)
test_contains "VERBOSE=" $completion

completion=$(complete_at_end_of_line make VERBOSE=)
test_contains "true" $completion

completion=$(complete_at_end_of_line make BUILD_MODE=)
test_contains "debug" $completion
test_contains "release" $completion

script=$(pwd)/$(basename ${0})
objdir=obj/$(basename $(pwd))
(
  # Run commands from below this directory
  cd ../../..
  wd=$(pwd)
  completion=$(complete_at_end_of_line make  /)
  # includes this test
  test_contains "${script}.test" $completion
  # and other tests
  test_contains "${wd}/tests/testing/${objdir}/passes" $completion
)
