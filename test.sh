#/bin/bash

# CONFINE testing script using VCT and LXC
# lots of work to do

# URLs
VCT_CONTAINER=vct-container,2013080200.tar.xz
VCT_CONTAINER_URL=https://media.confine-project.eu/vct-container/$VCT_CONTAINER
RESEARCH_CONTAINER=researcher,20131028.tar.xz
RESEARCH_CONTAINER_URL=https://media.confine-project.eu/researcher-container/$RESEARCH_CONTAINER

set -e # fail on any exception

source vct.sh
source researcher.sh

start_vct $VCT_CONTAINER $VCT_CONTAINER_URL
start_researcher $RESEARCH_CONTAINER $RESEARCH_CONTAINER_URL

set +e # allow failure
run_tests
status=$?
set -e # fail on any exception
echo "Tests ended with $status"

if [[ $status != 0 ]]; then
    id=$(date +%Y%m%d_%H%M%S);
    archive_vct $id
    archive_researcher $id
fi

tear_down_researcher
tear_down_vct

exit $status
