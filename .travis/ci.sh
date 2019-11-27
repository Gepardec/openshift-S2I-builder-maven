#!/bin/bash


GIT_BRANCH_NORMALIZED=${1//[\/.]/-}
GIT_BRANCH=${1}
MAVEN_TAG=${2}
FLAG_DRYRUN=false

namespace="travis-1"
return_code=0
sleep_time=20

# execute $COMMAND [$DRYRUN=false]
# if command and dryrun=true are provided the command will be execuded
# if command and dryrun=false (or no second argument is provided) 
# the function will only print the command the command to stdout
execute () {
  local exec_command=${1}
  local flag_dryrun=${2:-$FLAG_DRYRUN}

  if [[ "${flag_dryrun}" == false ]]; then
     echo "+ ${exec_command}"
     (eval "${exec_command}")
  else
    echo "${exec_command}"
  fi
}
readonly -f execute
[ "$?" -eq "0" ] || return $?

execute "oc new-build \
            --name=builder-${GIT_BRANCH_NORMALIZED}-${MAVEN_TAG} \
            --docker-image=maven:${MAVEN_TAG} \
            --labels='from=travis' \
            -n ${namespace} \
            --strategy docker \
            --to=builder-${GIT_BRANCH_NORMALIZED}:${MAVEN_TAG} \
            https://github.com/gepardec/openshift-builder-maven#${GIT_BRANCH}"
return_code=${?}

set -e

execute "sleep ${sleep_time}"
execute "oc cancel-build \
            bc/builder-${GIT_BRANCH_NORMALIZED}-${MAVEN_TAG} \
            bc/binary-artefact-${GIT_BRANCH_NORMALIZED}-${MAVEN_TAG} \
            bc/runtime-${GIT_BRANCH_NORMALIZED}-${MAVEN_TAG} \
            2> /dev/null \
            || true"
execute "oc import-image maven:${MAVEN_TAG}"
execute "oc start-build \
            --wait \
            --follow \
            --no-cache \
            --commit=$(git log --pretty=format:'%H' -n 1) \
            builder-${GIT_BRANCH_NORMALIZED}-${MAVEN_TAG}"

if [ "${return_code}" -eq "0" ]; then
  execute "oc new-build \
              --name=binary-artefact-${GIT_BRANCH_NORMALIZED}-${MAVEN_TAG} \
              --env=BUILDER_CONTEXT_DIR=helloworld \
              --env=BUILDER_MVN_OPTIONS='-P openshift' \
              --labels='from=travis' \
              --to=binary-artefact-${GIT_BRANCH_NORMALIZED}:${MAVEN_TAG} \
              builder-${GIT_BRANCH_NORMALIZED}:${MAVEN_TAG}~https://github.com/wildfly/quickstart#18.0.0.Final"   
  execute "sleep ${sleep_time}"
  execute "oc logs \
              --follow \
              bc/binary-artefact-${GIT_BRANCH_NORMALIZED}-${MAVEN_TAG}"

  execute "oc new-build \
              --name=runtime-${GIT_BRANCH_NORMALIZED}-${MAVEN_TAG} --docker-image=jboss/wildfly \
              --dockerfile=$'FROM jboss/wildfly\nCOPY ROOT.war /opt/jboss/wildfly/standalone/deployments/ROOT.war' \
              --labels='from=travis' \
              --source-image=binary-artefact-${GIT_BRANCH_NORMALIZED}:${MAVEN_TAG} \
              --source-image-path=/deployments/target/ROOT.war:. \
              --to=runtime-${GIT_BRANCH_NORMALIZED}:${MAVEN_TAG}"
  execute "sleep ${sleep_time}"
  execute "oc logs \
              --follow \
              bc/runtime-${GIT_BRANCH_NORMALIZED}-${MAVEN_TAG}"

  execute "oc new-app \
              runtime-${GIT_BRANCH_NORMALIZED}:${MAVEN_TAG} \
              --name=hello-world-${GIT_BRANCH_NORMALIZED}-${MAVEN_TAG}"
  execute "sleep ${sleep_time}"
  execute "oc rollout cancel \
              hello-world-${GIT_BRANCH_NORMALIZED}-${MAVEN_TAG} \
              || true"
  execute "oc rollout latest \
              hello-world-${GIT_BRANCH_NORMALIZED}-${MAVEN_TAG} \
              --again \
              || true"
  execute "oc expose \
              svc/hello-world-${GIT_BRANCH_NORMALIZED}-${MAVEN_TAG}"
fi

route=$(oc describe \
            route/hello-world-${GIT_BRANCH_NORMALIZED}-${MAVEN_TAG} \
        | grep 'Requested Host:' \
        | cut -d ':' -f2 \
        | xargs)

echo "wait for route to be unavailable"
while [[ "$(curl -s -o /dev/null -w %{http_code} http://${route})" != "503" ]]; do
    printf '.'
    sleep 1
done

echo ""
echo "wait for app to serve route"
until [[ "$(curl -s -o /dev/null -w %{http_code} http://${route})" == "200" ]]; do
    printf '.'
    sleep ${sleep_time}
done

curl -s http://${route}/HelloWorld | grep -q "Hello World"