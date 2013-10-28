function start_vct (){
	VCT_CONTAINER=$1
	VCT_CONTAINER_URL=$2
	
	SLEEP=20
	
	# fetch/copy the latest VCT container
	if [[ ! -f dl/$VCT_CONTAINER ]]; then
		wget --no-check-certificate $VCT_CONTAINER_URL -O dl/$VCT_CONTAINER
	fi
	if [[ ! -f dl/$VCT_CONTAINER ]]; then
		echo "Could not download $VCT_CONTAINER"
		exit 1
	fi

	echo "Unpacking..."
	lxc-stop -n vct
	rm -rf vct/vct
	tar -C vct --numeric-owner -xJf dl/$VCT_CONTAINER

	cd vct
	echo "Patching..."
	rm -rf .pc # remove old quilt information, if any
	quilt push -a -v

	echo "Starting LXC..."
	lxc-start --name vct -f vct/config -s lxc.rootfs=$(pwd)/vct/rootfs -o vct.log -d

	echo "Sleeping $SLEEP seconds until booted..."
	sleep $SLEEP

	echo "Pinging..."
	ping6 -c 1 fdf6:1e51:5f7b:b50c::2 && echo "ok"
	
	cd ..
}

function archive_vct() {
    id = $(date +%Y%m%d_%H%M%S)
    if [ $# > 1 ]; then
        $id = $2;
    fi
    cd vct
    tar -c --xz -f ../archive/vct,$id.tar.xz vct
    cd ..
}

function tear_down_vct(){
    lxc-stop -n vct;
    lxc-destroy -n vct;
}
