#/bin/bash

# CONFINE testing script using VCT and LXC
# lots of work to do

# URLs
VCT_CONTAINER=vct-container,2013080200.tar.xz
VCT_CONTAINER_URL=https://media.confine-project.eu/vct-container/$VCT_CONTAINER
RESEARCH_CONTAINER=researcher,20131025.tar.xz
RESEARCH_CONTAINER_URL=https://media.confine-project.eu/researcher-container/$RESEARCH_CONTAINER

set -e # fail on any exception

source vct.sh
start_vct $VCT_CONTAINER $VCT_CONTAINER_URL

source researcher.sh
start_researcher $RESEARCH_CONTAINER $RESEARCH_CONTAINER_URL

echo "bye"
exit 0
