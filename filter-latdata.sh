#!/bin/bash

BENCH_NAME=$1
TEST_DIR=$2
IS_BG=$3
FILE="${TEST_DIR}/proc-page-profile-${BENCH_NAME}"

# gunzip -k "$FILE.gz"
cat $FILE | grep migrate_misplaced_page \
    | grep -v tmux | grep -v docker | grep -v rs:main | grep -v container | grep -v systemd > mmp.tmp
cat mmp.tmp | awk '{print $6 " " $7 " " $8 " " $9 " " $10 " " $11 " " $12}' >> lat.tmp

if [[ $IS_BG == "1" ]]; then
    cat $FILE | grep __kdemoted \
    | grep -v tmux | grep -v docker | grep -v systemd > kd.tmp
    cat kd.tmp | awk '{print $6 " " $7 " " $8 " " $9 " " $10}' >> lat.tmp
    rm kd.tmp
fi

mv lat.tmp ${TEST_DIR}
rm mmp.tmp
