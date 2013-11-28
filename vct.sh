function start_vct (){
	VCT_CONTAINER=$1
	VCT_CONTAINER_URL=$2
	
	SLEEP=20
	
	# fetch/copy the latest VCT container
	if [[ ! -f dl/$VCT_CONTAINER ]]; then
		echo "Downloading $VCT_CONTAINER..."
		wget -q --no-check-certificate $VCT_CONTAINER_URL -O dl/$VCT_CONTAINER
	fi
	if [[ ! -f dl/$VCT_CONTAINER ]]; then
		echo "Could not download $VCT_CONTAINER"
		exit 1
	fi

	echo "Unpacking..."
	tear_down_vct
	rm -rf vct/vct
	tar -C vct --numeric-owner -xJf dl/$VCT_CONTAINER

	cd vct
	echo "Patching..."
	rm -rf .pc # remove old quilt information, if any
	quilt push -a -v

	echo "Starting LXC..."
	lxc-start --name $VCT_LXC -f vct/config -s lxc.rootfs=$(pwd)/vct/rootfs -o vct.log -d

	echo "Sleeping $SLEEP seconds until booted..."
	sleep $SLEEP

	echo "Pinging..."
	ping6 -c 1 $VCT_IP && echo "ok"

	cd ..

	echo "SSHing..."
	ssh -i ./sshkey/id_rsa -o StrictHostKeyChecking=no root@$VCT_IP 'whoami'

#	echo "vct_system_init"
#	ssh -i ./sshkey/id_rsa -o StrictHostKeyChecking=no root@fdf6:1e51:5f7b:b50c::2 'sudo -u vct bash /home/vct/confine-dist/utils/vct/vct_system_init'

}

function archive_vct() {
    lxc-stop -n $VCT_LXC;
    id=$(date +%Y%m%d_%H%M%S);
    if [[ $# > 0 ]]; then
        id=$1;
    fi
    cd vct
    tar -c --xz -f ../archive/vct,$id.tar.xz vct
    cd ..
}

function tear_down_vct(){
    if lxc-info -n $VCT_LXC | grep -q RUNNING; then
		echo "Stopping vct..."
        lxc-stop -n $VCT_LXC;
    fi
}

VCT_LXC=${VCT_LXC:-vct_$(date -u +"%s")}
IPPREFIX=${IPPREFIX:-"fdf6:1e51:5f7b:b50c::"};
VCT_IP=${IPPREFIX}2

