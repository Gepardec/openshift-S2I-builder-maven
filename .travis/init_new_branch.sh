#!/bin/bash

GIT_BRANCH=${1}

set -e

./ci.sh ${GIT_BRANCH} latest
./ci.sh ${GIT_BRANCH} 3-jdk-14
./ci.sh ${GIT_BRANCH} 3-jdk-13
./ci.sh ${GIT_BRANCH} 3-jdk-12
./ci.sh ${GIT_BRANCH} 3-jdk-11
./ci.sh ${GIT_BRANCH} 3-jdk-10
./ci.sh ${GIT_BRANCH} 3-jdk-9
./ci.sh ${GIT_BRANCH} 3-jdk-8
