#!/bin/sh

test_find() {
  check="$1"; shift

  for i; do
    if [ "$i" = "$check" ]; then
      return 0
    fi
  done
  return 1
}

test_contains() {
  if test_find "$@"; then
    return 0
  fi
  echo "Failed to find $check in '$@'"
  return 1
}

test_not_contains() {
  if ! test_find "$@"; then
    return 0
  fi
  echo "Unexpectedly found $check in '$@'"
  return 1
}

set -e
objdir=obj/$(basename $(pwd))

cd ../../..
top=$(pwd)

# completions trimmed of $(TOP)
completion=$(make completion_list_targets COMPLETION_FILTER=${top} | sed -n 's/^COMPLETION_TARGET_LIST=//p' | tr ' ' "\n" | sed "s:${top}/::")
# contains this test
test_contains "completion/${objdir}/test_completion_make.sh.test" $completion
# but not the run target
test_not_contains "completion/${objdir}/test_completion_make.sh.run" $completion

# filter into a different directory
completion=$(make completion_list_targets COMPLETION_FILTER=${top}/tests | sed -n 's/^COMPLETION_TARGET_LIST=//p' | tr ' ' "\n" | sed "s:${top}/::")
# doesn't contain this test
test_not_contains "completion/${objdir}/test_completion_make.sh.test" $completion

# filter into this directory
completion=$(make completion_list_targets COMPLETION_FILTER="${top}/completion/${objdir}/" | sed -n 's/^COMPLETION_TARGET_LIST=//p' | tr ' ' "\n" | sed "s:${top}/::")
# contains this test
test_contains "completion/${objdir}/test_completion_make.sh.test" $completion
# and now also the run target
test_contains "completion/${objdir}/test_completion_make.sh.run" $completion
