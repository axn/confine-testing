#!/bin/bash
#This script is used to create a research container

function tear_down_researcher_container(){
	echo "Verify running $RESEARCHER_CONTAINER_DIR..."
    if lxc-info -n $RESEARCHER_CONTAINER_DIR | grep -q RUNNING; then
		echo "Stopping LXC..."
        lxc-stop -n $RESEARCHER_CONTAINER_DIR;
    fi
}

function extract_researcher(){
    # fetch/copy the latest RESEARCHER container
	if [[ ! -f dl/$RESEARCHER_CONTAINER ]]; then
		echo "Downloading $RESEARCHER_CONTAINER"
		wget -q --no-check-certificate $RESEARCHER_CONTAINER_URL -O dl/$RESEARCHER_CONTAINER
	fi
	if [[ ! -f dl/$RESEARCHER_CONTAINER ]]; then
		echo "Could not download $RESEARCHER_CONTAINER"
		exit 1
	fi
	
    echo "Unpacking..."
	rm -rf $RESEARCHER_CONTAINER_DIR/researcher_lxc
	tar -C $RESEARCHER_CONTAINER_DIR --numeric-owner -xJf dl/$RESEARCHER_CONTAINER
	
	cd $RESEARCHER_CONTAINER_DIR
	echo "Patching..."
	rm -rf .pc # remove old quilt information, if any
	QUILT_PATCHES="../researcher/patches" quilt push -a -v
	cd -
	
}

function start_researcher() {
    echo "Starting LXC..."
    cd $RESEARCHER_CONTAINER_DIR
	lxc-start --name $RESEARCHER_CONTAINER_DIR -f researcher_lxc/config -s lxc.rootfs=$(pwd)/researcher_lxc/rootfs -o researcher.log -d
	cd -
}

function configure_inet() {
	ssh -i ./sshkey/id_rsa -o StrictHostKeyChecking=no root@${RESEARCHER_IP} "ip addr add ${IPV4PREFIX}3/24 dev eth0 && ip route add default via ${IPV4PREFIX}1 && ping -c 5 8.8.8.8";
}

function tar_xz_researcher() {
	echo "Packaging researcher lXC..."
    cd $RESEARCHER_CONTAINER_DIR
    #clean up
    quilt pop -a -v -f
    #tar
    id=$(date +%Y%m%d_%H%M%S);
	name=researcher,$id.tar.xz
	echo "Compressing with tar xz..."
    tar -c --xz -f ./$name researcher_lxc
    cd -
	mv $RESEARCHER_CONTAINER_DIR/$name ./dl/
	echo $name
}

function run_researcher() {
	RESEARCHER_CONTAINER=researcher,20131210.tar.xz
	RESEARCHER_CONTAINER_URL=https://media.confine-project.eu/researcher-container/$RESEARCHER_CONTAINER
	RESEARCHER_CONTAINER_DIR="researcher-container"
	
	. ./host.sh
	configure_network
	configure_masquerade
	
	mkdir -p $RESEARCHER_CONTAINER_DIR

	tear_down_researcher_container
	extract_researcher
	start_researcher
	sleep 10
	configure_inet
}

function stop_researcher() {
	echo "Cleaning apt-get cache..."
	ssh -i ./sshkey/id_rsa -o StrictHostKeyChecking=no root@${RESEARCHER_IP} "apt-get clean";
	tear_down_researcher_container
	tar_xz_researcher
}

LXC_NETWORK_LINK=${LXC_NETWORK_LINK:-"vmbridge"};
IPPREFIX=${IPPREFIX:-"fdf6:1e51:5f7b:b50c::"};
RESEARCHER_IP=${IPPREFIX}3
RESEARCHER_IP_PUBLIC=${RESEARCHER_IP_PUBLIC:-143.129.77.140}
OUT_IFACE=${OUT_IFACE:-"eth0"}
