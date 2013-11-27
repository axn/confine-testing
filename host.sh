function configure_network(){
    if ! brctl show | grep $LXC_NETWORK_LINK > /dev/null 2>&1; then
        echo "Bridge $LXC_NETWORK_LINK does not exist, creating bridge..."
        if ip link show $LXC_NETWORK_LINK > /dev/null 2>&1; then
            echo "Interface $LXC_NETWORK_LINK exists but is not a bridge."
            return 1;
        fi
        brctl addbr $LXC_NETWORK_LINK;
    fi
    echo "Set $LXC_NETWORK_LINK up..."
    ip link set dev $LXC_NETWORK_LINK up;
    
    if ! ip -6 addr show dev $LXC_NETWORK_LINK | grep ${IPPREFIX}1/64 > /dev/null 2>&1; then
        echo "Configure $LXC_NETWORK_LINK..."
        ip -6 addr add ${IPPREFIX}1/64 dev $LXC_NETWORK_LINK
    fi
    return 0
}

function offset_ips(){
	IPOFFSET=${IPOFFSET:-0};
	VCT_IP=${IPPREFIX}$((2+${IPOFFSET}));
	RESEARCHER_IP=${IPPREFIX}$((3+${IPOFFSET}));
	echo "vct container on $VCT_IP, researcher container on $RESEARCHER_IP"
	echo "Updating patches to IP offset $IPOFFSET"
	git checkout */patches
	find */patches/ -type f -exec sed -i "s/fdf6:1e51:5f7b:b50c::2/${VCT_IP}/g" {} \;
	find */patches/ -type f -exec sed -i "s/fdf6:1e51:5f7b:b50c::3/${RESEARCHER_IP}/g" {} \;
	find */patches/ -type f -exec sed -i "s/vmbridge/${LXC_NETWORK_LINK}/g" {} \;
}

LXC_NETWORK_LINK=${LXC_NETWORK_LINK:-"vmbridge"};
IPPREFIX=${IPPREFIX:-"fdf6:1e51:5f7b:b50c::"};