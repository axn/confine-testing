#!/bin/bash

# CONFINE testing script using VCT and LXC
# lots of work to do

# URLs
VCT_CONTAINER=${VCT_CONTAINER:-vct-container,vct016464d,controller7022f77,nodefw016464d.tar.xz}
VCT_CONTAINER_URL=https://media.confine-project.eu/vct-container/test/$VCT_CONTAINER
RESEARCH_CONTAINER=${RESEARCH_CONTAINER:-researcher,20140122_111534.tar.xz}
RESEARCH_CONTAINER_URL=https://media.confine-project.eu/researcher-container/$RESEARCH_CONTAINER
CONFINE_TESTS_URL=${CONFINE_TESTS_URL:-http://git.confine-project.eu/confine/confine-tests.git}
SETUP_ONLY=${SETUP_ONLY:-n}
NO_TEARDOWN=${NO_TEARDOWN:-n}

set -e # fail on any exception

. ./setup.conf
. ./host.sh
. ./vct.sh
. ./researcher.sh

echo "Using vct: $VCT_CONTAINER"
echo "Using researcher: $RESEARCH_CONTAINER"

configure_network

start_vct $VCT_CONTAINER $VCT_CONTAINER_URL
start_researcher $RESEARCH_CONTAINER $RESEARCH_CONTAINER_URL $CONFINE_TESTS_URL

configure_masquerade
configure_vct_inet
configure_researcher_inet

if [ "${SETUP_ONLY}" == "y" ]; then
	exit 0;
fi

set +e # allow failure
run_tests
status=$?
set -e # fail on any exception
echo "Tests ended with $status"

if [ "${NO_TEARDOWN}" == "y" ]; then
	exit $status;
fi

# if [[ $status != 0 ]]; then
# 	echo "Tests failed, archiving both containers for inspection"
#     id=$(date +%Y%m%d_%H%M%S);
#     archive_vct $id
#     archive_researcher $id
# fi

echo "Tearing down containers"
tear_down_researcher
tear_down_vct

echo "Done"

#exit $status
exit 0; #Allow jenkins to mark unstable
