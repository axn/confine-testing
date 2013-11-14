#!/bin/bash

# CONFINE testing script using VCT and LXC
# lots of work to do

# URLs
VCT_CONTAINER=${VCT_CONTAINER:-vct-container,76e93a5efffa1ec48299af5b960e7dadc2d3e3c1,c4ccc10e10be2754f6ac1fb7be6ee87f8de267e9,76e93a5efffa1ec48299af5b960e7dadc2d3e3c1.tar.xz}
VCT_CONTAINER_URL=https://media.confine-project.eu/vct-container/$VCT_CONTAINER
RESEARCH_CONTAINER=${RESEARCH_CONTAINER:-researcher,20131107.tar.xz}
RESEARCH_CONTAINER_URL=https://media.confine-project.eu/researcher-container/$RESEARCH_CONTAINER

set -e # fail on any exception

. ./host.sh
. ./vct.sh
. ./researcher.sh

configure_network

start_vct $VCT_CONTAINER $VCT_CONTAINER_URL
start_researcher $RESEARCH_CONTAINER $RESEARCH_CONTAINER_URL

set +e # allow failure
run_tests
status=$?
set -e # fail on any exception
echo "Tests ended with $status"

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

exit $status
