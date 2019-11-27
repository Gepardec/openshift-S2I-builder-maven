#!/bin/bash
# https://docs.openshift.com/container-platform/4.2/authentication/understanding-and-creating-service-accounts.html#service-accounts-managing_understanding-service-accounts

oc new-project travis-1 --display-name="CI - Openshift Builder Maven" --description="CI/CD Environment used by Travis-CI to test gepardec/openshift-builder-maven"
oc create sa travis -n travis-1
oc policy add-role-to-user admin system:serviceaccount:travis-1:travis -n travis-1
oc sa get-token travis -n travis-1 > /.travis/token
travis encrypt-file .travis/token .travis/token.enc --pro --force