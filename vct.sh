function start_vct (){
	VCT_CONTAINER=$1
	VCT_CONTAINER_URL=$2
	
	# fetch/copy the latest VCT container
	if [[ ! -f dl/$VCT_CONTAINER ]]; then
		wget --no-check-certificate $VCT_CONTAINER_URL -O dl/$VCT_CONTAINER
	fi
	if [[ ! -f dl/$VCT_CONTAINER ]]; then
		echo "Could not download $VCT_CONTAINER"
		exit 1
	fi

	echo "Unpacking..."
	rm -r vct/vct
	tar -C vct --numeric-owner -xJf $VCT_CONTAINER

	cd vct
	echo "Patching..."
	rm -rf .pc # remove old quilt information, if any
	quilt push -a -v

	echo "Starting LXC..."
	lxc-start --name vct -f vct/config -d

	echo "Sleeping 10 seconds until booted..."
	sleep 10

	echo "Pinging..."
	ping6 -c 1 fdf6:1e51:5f7b:b50c::2 && echo "ok"
}

