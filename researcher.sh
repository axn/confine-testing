function start_researcher(){
	
	RESEARCH_CONTAINER=$1
	RESEARCH_CONTAINER_URL=$2

	# fetch/copy the latest research container
	# if [[ ! -f dl/$RESEARCH_CONTAINER ]]; then
	# 	wget --no-check-certificate $RESEARCH_CONTAINER_URL -O dl/$RESEARCH_CONTAINER
	# fi
	if [[ ! -f dl/$RESEARCH_CONTAINER ]]; then
		echo "Could not download $RESEARCH_CONTAINER"
		exit 1
	fi

	echo "Unpacking..."
	rm -rf researcher/researcher_lxc
	tar -C researcher --numeric-owner -xJf dl/$RESEARCH_CONTAINER

	cd researcher
	echo "Patching..."
	rm -rf .pc # remove old quilt information, if any
	quilt push -a -v

	echo "Starting LXC..."
	lxc-start --name researcher -f researcher_lxc/config -d

	echo "Sleeping 10 seconds until booted..."
	sleep 10

	echo "Pinging..."
	ping6 -c 1 fdf6:1e51:5f7b:b50c::3 && echo "ok"
}
