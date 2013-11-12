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
	echo "Updating VCT to $VCT_HASH..."
	rm -rf $VCT_CONTAINER_DIR/vct/rootfs/home/vct/confine-dist
    git clone http://git.confine-project.eu/confine.git $VCT_CONTAINER_DIR/vct/rootfs/home/vct/confine-dist
	cd $VCT_CONTAINER_DIR/vct/rootfs/home/vct/confine-dist
	git checkout $VCT_HASH
	VCT_HASH=$(git rev-parse $VCT_HASH)
	if ! [ ${#NODEFIRMWARE_HASH} -eq 40 ]; then
		NODEFIRMWARE_HASH=$(git rev-parse $NODEFIRMWARE_HASH)
	fi
	cd -
}

function start_vct() {
    echo "Starting LXC..."
    cd $VCT_CONTAINER_DIR
	lxc-start --name $VCT_CONTAINER_DIR -f vct/config -s lxc.rootfs=$(pwd)/vct/rootfs -o vct.log -d
	cd -
}

function stop_vct(){
    echo "Stopping LXC..."
    lxc-stop --name $VCT_CONTAINER_DIR
}

function clean_vct() {
	echo "Cleaning VCT installation..."
    ssh -i ./sshkey/id_rsa -o StrictHostKeyChecking=no vct@fdf6:1e51:5f7b:b50c::2 '/home/vct/confine-dist/utils/vct/vct_system_cleanup && sudo rm -rf /var/lib/vct' > $VCT_CONTAINER_DIR/vct_system_cleanup.log 2>&1
}

function network_vct() {
	echo "Providing LXC with network connectivity..."
    ssh -i ./sshkey/id_rsa -o StrictHostKeyChecking=no root@fdf6:1e51:5f7b:b50c::2 'ifconfig eth0 143.129.77.137 netmask 255.255.255.224; route add default gw 143.129.77.158; ping -c 1 8.8.8.8'
}

function install_vct(){
	echo "Installing VCT..."
    ssh -i ./sshkey/id_rsa -o StrictHostKeyChecking=no vct@fdf6:1e51:5f7b:b50c::2 '/home/vct/confine-dist/utils/vct/vct_system_install && sudo apt-get clean' > $VCT_CONTAINER_DIR/vct_system_install.log 2>&1
}

function init_vct(){
	echo "Initialising VCT..."
	ssh -i ./sshkey/id_rsa -o StrictHostKeyChecking=no vct@fdf6:1e51:5f7b:b50c::2 '/home/vct/confine-dist/utils/vct/vct_system_init' > $VCT_CONTAINER_DIR/vct_system_init.log 2>&1
}

function build_node_vct() {
	echo "Building node firmware..."
    ssh -i ./sshkey/id_rsa -o StrictHostKeyChecking=no vct@fdf6:1e51:5f7b:b50c::2 '/home/vct/confine-dist/utils/vct/vct_build_node_base_image'
}

function tar_xz_vct() {
	echo "Packaging VCT lXC..."
    cd $VCT_CONTAINER_DIR
    #clean up
    quilt pop -a -v -f
    #tar
    id=$(date +%Y%m%d_%H%M%S);
	name=vct-container,$VCT_HASH,$CONTROLLER_HASH,$NODEFIRMWARE_HASH.tar.xz
    tar -c --xz -f ./$name vct
    cd -
	echo $name
}

function update_controller() {
	echo "Updating controller to $CONTROLLER_HASH"
	rm -rf $VCT_CONTAINER_DIR/vct/rootfs/usr/local/lib/python2.7/dist-packages/controller
	git clone http://git.confine-project.eu/confine/controller.git  $VCT_CONTAINER_DIR/vct/rootfs/home/vct/confine-controller
	cd $VCT_CONTAINER_DIR/vct/rootfs/home/vct/confine-controller
	git checkout $CONTROLLER_HASH
	CONTROLLER_HASH=$(git rev-parse $CONTROLLER_HASH)
	cd -
	echo "/home/vct/confine-controller" > $VCT_CONTAINER_DIR/vct/rootfs/usr/local/lib/python2.7/dist-packages/controller.pth
}

function install_node_firmware() {
	echo "Updating node firmware to $NODEFIRMWARE_HASH"
	for branch in testing master; do
		URL=http://builds.confine-project.eu/confine/openwrt/x86/$branch-builds/$NODEFIRMWARE_HASH/images/CONFINE-openwrt-$branch-latest.img.gz
		if wget --spider $URL; then
			echo VCT_NODE_TEMPLATE_URL=\"$URL\" >> $VCT_CONTAINER_DIR/vct/rootfs/home/vct/confine-dist/utils/vct/vct.conf.overrides
			break;
		fi
	done
}

function build_vct() {
	VCT_CONTAINER=vct,20131104.tar.xz
	VCT_CONTAINER_URL=https://media.confine-project.eu/vct-container/$VCT_CONTAINER
	VCT_CONTAINER_DIR="vct-container"
	
	VCT_HASH=$1
	CONTROLLER_HASH=$2
	NODEFIRMWARE_HASH=$3
	
	mkdir -p $VCT_CONTAINER_DIR
	extract_vct
	start_vct
	sleep 10
	clean_vct
	update_vct
	network_vct
	install_node_firmware
	update_controller
	install_vct
	init_vct
	stop_vct
	tar_xz_vct
}

function build_vct_testing() {
	build_vct origin/testing origin/master origin/testing
}
