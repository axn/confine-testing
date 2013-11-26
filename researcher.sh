function start_researcher(){
	
	RESEARCH_CONTAINER=$1
	RESEARCH_CONTAINER_URL=$2

	SLEEP=5
	
	# fetch/copy the latest research container
	if [[ ! -f dl/$RESEARCH_CONTAINER ]]; then
		echo "Downloading $RESEARCH_CONTAINER"
		wget --no-check-certificate $RESEARCH_CONTAINER_URL -O dl/$RESEARCH_CONTAINER
	fi
	if [[ ! -f dl/$RESEARCH_CONTAINER ]]; then
		echo "Could not download $RESEARCH_CONTAINER"
		exit 1
	fi

	echo "Unpacking..."
	tear_down_researcher
	rm -rf researcher/researcher_lxc
	tar -C researcher --numeric-owner -xJf dl/$RESEARCH_CONTAINER

	cd researcher
	echo "Patching..."
	rm -rf .pc # remove old quilt information, if any
	quilt push -a -v
	
	echo "chmod files..."
	chmod 600 ../sshkey/id_rsa #avoid private ssh key permission problems
	chmod 755 researcher_lxc/rootfs/etc/tinc/confine/tinc-{up,down}
	
	echo "Adding tests..."
	git clone http://git.confine-project.eu/confine/confine-utils.git researcher_lxc/rootfs/home/vct/confine-utils
	git clone http://git.confine-project.eu/confine/confine-tests.git researcher_lxc/rootfs/home/vct/confine-tests
    if [[ $? != 0 ]]; then
        echo "Could not fetch the tests."
    fi
	
	echo "Adding firmware..."
	wget -q https://media.confine-project.eu/misc/debianbt32.tgz -P researcher_lxc/rootfs/tmp/

	echo "Starting LXC..."
	lxc-start --name $RESEARCHER_LXC -f researcher_lxc/config -s lxc.rootfs=$(pwd)/researcher_lxc/rootfs -d

	echo "Sleeping $SLEEP seconds until booted..."
	sleep $SLEEP

	echo "Pinging..."
	ping6 -c 1 $RESEARCHER_IP && echo "ok"
	cd ..
}


function run_tests(){
	echo "SSHing..."
	ssh -i ./sshkey/id_rsa -o StrictHostKeyChecking=no vct@$RESEARCHER_IP 'whoami'
	if [[ $? != 0 ]]; then
        echo "unable to ssh to researcher."
    fi

    sleep 20
    echo "Starting tests..."
    ssh -i ./sshkey/id_rsa -o StrictHostKeyChecking=no vct@$RESEARCHER_IP \
        "env CONFINE_SERVER_API='http://vctserver/api' CONFINE_USER='vct' CONFINE_PASSWORD='vct'  PYTHONPATH=confine-utils:confine-tests python -m unittest discover -s ./confine-tests/"
    return $?
}

function archive_researcher() {
    lxc-stop -n $RESEARCHER_LXC;
    id=$(date +%Y%m%d_%H%M%S);
    if [[ $# > 0 ]]; then
        id=$1;
    fi
    cd researcher
    tar -c --xz -f ../archive/researcher,$id.tar.xz researcher_lxc
    cd ..
}

function tear_down_researcher(){
    if lxc-info -n $RESEARCHER_LXC | grep -q RUNNING; then
        lxc-stop -n $RESEARCHER_LXC;
    fi
}

RESEARCHER_LXC=${RESEARCHER_LXC:-researcher_$(date -u +"%s")}
RESEARCHER_IP=fdf6:1e51:5f7b:b50c::3
