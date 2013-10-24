function start_researcher(){
	
	VCT_CONTAINER=$1
	VCT_CONTAINER_URL=$2
	VCT_IP=$3

	# fetch/copy the latest VCT container
	if [[ ! -f $VCT_CONTAINER ]]; then
		wget --no-check-certificate $VCT_CONTAINER_URL # TODO add more versions and loop over them
	fi
	if [[ ! -f $VCT_CONTAINER ]]; then
		echo "Could not download $VCT_CONTAINER"
		exit 1
	fi

	echo "Unpacking..."
	rm -rf vct_rootfs
	mkdir -p vct_rootfs
	tar -C vct_rootfs --numeric-owner -xJf $VCT_CONTAINER

	echo "Patching..."
	rm -rf .pc # remove old quilt information, if any
	quilt push -a -v

	echo "Starting LXC..."
	lxc-start --name vct -f vct_rootfs/vct/config -d

	echo "Sleeping 10 seconds until booted..."
	sleep 10

	echo "Pinging..."
	ping6 -c 1 fdf6:1e51:5f7b:b50c::2 && echo "ok"
}
