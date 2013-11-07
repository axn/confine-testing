#!/bin/bash
#This script is used to create an updated vct container

function extract_vct(){
    # fetch/copy the latest VCT container
	if [[ ! -f dl/$VCT_CONTAINER ]]; then
		wget --no-check-certificate $VCT_CONTAINER_URL -O dl/$VCT_CONTAINER
	fi
	if [[ ! -f dl/$VCT_CONTAINER ]]; then
		echo "Could not download $VCT_CONTAINER"
		exit 1
	fi
	
    echo "Unpacking..."
	
	rm -rf $VCT_CONTAINER_DIR/vct
	tar -C $VCT_CONTAINER_DIR --numeric-owner -xJf dl/$VCT_CONTAINER
	
	cd $VCT_CONTAINER_DIR
	echo "Patching..."
	rm -rf .pc # remove old quilt information, if any
	QUILT_PATCHES="../vct/patches" quilt push -a -v
	cd -
	
}

function update_vct() {
    cd $VCT_CONTAINER_DIR/vct/rootfs/home/vct/confine-dist
	#git pull
	git checkout $GIT_BRANCH
    GIT_HASH=$(git show | head -n 1 | awk '{print $2}')
	echo VCT_SERVER_VERSION=\"$VCT_SERVER_VERSION\" >> utils/vct/vct.conf.overrides
    cd -
}

function start_vct() {
    echo "Starting LXC..."
    cd vct-container
	lxc-start --name $VCT_CONTAINER_DIR -f vct/config -s lxc.rootfs=$(pwd)/vct/rootfs -o vct.log -d
	cd -
}

function stop_vct(){
    echo "Stopping LXC..."
    lxc-stop --name $VCT_CONTAINER_DIR
}

function clean_vct() {
    ssh -i ./sshkey/id_rsa -o StrictHostKeyChecking=no vct@fdf6:1e51:5f7b:b50c::2 '/home/vct/confine-dist/utils/vct/vct_system_cleanup && sudo rm -rf /var/lib/vct'
}

function network_vct() {
    ssh -i ./sshkey/id_rsa -o StrictHostKeyChecking=no root@fdf6:1e51:5f7b:b50c::2 'ifconfig eth0 143.129.77.137 netmask 255.255.255.224; route add default gw 143.129.77.158; ping -c 1 8.8.8.8'
}

function install_vct(){
    ssh -i ./sshkey/id_rsa -o StrictHostKeyChecking=no vct@fdf6:1e51:5f7b:b50c::2 '/home/vct/confine-dist/utils/vct/vct_system_install && /home/vct/confine-dist/utils/vct/vct_system_init && sudo apt-get clean'
}

function build_node_vct() {
    ssh -i ./sshkey/id_rsa -o StrictHostKeyChecking=no vct@fdf6:1e51:5f7b:b50c::2 '/home/vct/confine-dist/utils/vct/vct_build_node_base_image'
}

function tar_xz_vct() {
    cd $VCT_CONTAINER_DIR
    #clean up
    quilt pop -a -v -f
    #tar
    id=$(date +%Y%m%d_%H%M%S);
    tar -c --xz -f ./vct-container,${GIT_HASH},$id.tar.xz vct
    cd -
}

function build_vct_testing() {
    VCT_CONTAINER=vct,20131104.tar.xz
        VCT_CONTAINER_URL=https://media.confine-project.eu/vct-container/$VCT_CONTAINER
    VCT_CONTAINER_DIR="vct-container"
    GIT_BRANCH=origin/testing
    VCT_SERVER_VERSION=dev

    extract_vct
    start_vct
    sleep 10
    clean_vct
    update_vct
    network_vct
    install_vct
    stop_vct
    tar_xz_vct
}
