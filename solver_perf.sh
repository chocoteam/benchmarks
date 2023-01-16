#!/bin/bash
# Script to run the regression tests.

set -e
### Global variables.
source ./env.sh

# Environment setup.
if [ ! -d ${DATASET} ]; then
  echo "${DATASET}: No such directory"
  exit 1
fi

NOW=$(date +'%s')


if [ $# -eq 0 ]; then
  echo "Usage: $0 [-c change | -e label | -b branch]"
  echo "-c change: run the given Github commit"
  echo "-e label: run the experiment. Labelled using 'label'"
  echo "-b branch: run over a given branch"
  echo "-m: run over master branch"
  exit 1
fi

TAG=$2
TS=""

KIND=
case $1 in
-c)
  KIND=change
  ID=${TAG:0:6}
  MOD=$(( $ID % 100 ))
  REF=refs/changes/${MOD}/${TAG}

  # We fetch the code
  cd ${TOP}
  git fetch ${GITHUB_URL} ${REF} && git checkout FETCH_HEAD
  TS=`git show -s --format=%ct`
  ;;
-e)
  KIND=experiment
  TS=${NOW}
  ;;
-m)
  cd ${TOP}
  KIND=master

  # Check if we already have it
  LAST_SHA=`git log -1 --pretty=format:"%h" -- .`
  TAG="master/${LAST_SHA}"
  git checkout master && git pull --rebase
  SHA=`git rev-parse --short HEAD`
  TAG="master/${SHA}"
  TS=`git show -s --format=%ct`
  ;;
-b)
  cd ${TOP}
  KIND=branch
  BRANCH=${TAG}
  # Check if we already have it
  LAST_SHA=`git log -1 --pretty=format:"%h" -- .`
  TAG="${BRANCH}/${LAST_SHA}"
  git checkout $2 && git pull --rebase
  SHA=`git rev-parse --short HEAD`
  TAG="${BRANCH}/${SHA}"
  TS=`git show -s --format=%ct`
  ;;
*)
  echo "Unsupported option: $1"
  exit 1
esac

# Kind of experiment (g)errit or (e)xperiment

# Run the benchmark.
cd ${SOLVER_PATH}
OUTPUT=${RESULTS}/${NOW}
mkdir ${OUTPUT}
echo "Dataset location: ${DATASET}"
echo "Output: ${OUTPUT}"
echo "Tag: ${TAG}"
echo "Kind: ${KIND}"

if grep -q ${TAG} ${RESULTS}/runs.csv; then
  echo "Results for ${TAG} are already in"
  exit 0
fi

#mvn -q clean package -DskipTests

#CURRENT_VERSION=`mvn ${MVN_ARGS} org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version | grep -v "\[INFO\]" | grep -v "\[WARNING\]"`
CURRENT_VERSION=4.10.11-SNAPSHOT
JAR=${SOLVER_PATH}/parsers/target/choco-parsers-${CURRENT_VERSION}-light.jar
MAIN_CLASS="org.chocosolver.parser.Parser"
ARGS=" -limit=[1m] -lvl JSON" 

for FILE in `find ${DATASET} -type f \( -name "*.xml" -o -name "*.fzn" \)`; do
  echo ${FILE}
  LOG="$(basename -s .txt ${FILE}).json"
  MARGS=$ARGS" -log ${OUTPUT}/${LOG}"
  java -XX:+UseSerialGC -server -Xss128M -Xmx8192m -cp .:${JAR} ${MAIN_CLASS} ${FILE} ${MARGS}
done  


# We register the benchmark.
echo "${NOW};${TAG};${KIND};${TS}" >> ${RESULTS}/runs.csv
echo ${NOW}
