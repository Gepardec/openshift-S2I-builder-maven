#!/bin/bash

set -e

### 1) Create a new project
oc new-project s2i-builder-maven \
   --display-name="S2I Maven Builder" \
   --description="This project contains all resources to build the S2I Maven Builder and use 
                  the builder to compile and run the hello world application. The hello world
                  application used here is available on github (wildfly/quickstart)."

### 2) create the builder image 
oc new-build https://github.com/gepardec/openshift-builder-maven#1.0.0 --name=s2i-builder-maven
oc logs bc/s2i-builder-maven -f

### 3) use the builder to build your artefact
oc new-build s2i-builder-maven~https://github.com/wildfly/quickstart#18.0.0.Final \
    --name=binary-artefact  \
    --env=BUILDER_CONTEXT_DIR=helloworld \
    --env=BUILDER_MVN_OPTIONS="-P openshift"
oc logs bc/binary-artefact -f

### 4) Combine artefact with runtime
oc new-build --name=runtime --docker-image=jboss/wildfly \
    --source-image=binary-artefact \
    --source-image-path=/deployments/target/ROOT.war:. \
    --dockerfile=$'FROM jboss/wildfly\nCOPY ROOT.war /opt/jboss/wildfly/standalone/deployments/ROOT.war'
oc logs bc/runtime -f

### 5) Deploy the application
oc new-app runtime --name=hello-world

### 6) Expose the application
oc expose svc/hello-world

### 7) Access the application
oc describe route/hello-world | grep "Requested Host:"
