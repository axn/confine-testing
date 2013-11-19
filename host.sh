LXC_NETWORK_LINK="vmbr"

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
    
    if ! ip -6 addr show dev vmbr | grep fdf6:1e51:5f7b:b50c::1/64 > /dev/null 2>&1; then
        echo "Configure $LXC_NETWORK_LINK..."
        ip -6 addr add fdf6:1e51:5f7b:b50c::1/64 dev $LXC_NETWORK_LINK
    fi
    return 0
}

function offset_ips(){
	IPOFFSET=${IPOFFSET:-0};
	PREFIX="fdf6:1e51:5f7b:b50c::";
	VCT_IP=${PREFIX}$((2+${IPOFFSET}));
	RESEARCHER_IP=${PREFIX}$((3+${IPOFFSET}));
	echo "vct container on $VCT_IP, researcher container on $RESEARCHER_IP"
	if ! [ $IPOFFSET -eq 0 ]; then
		echo "Updating patches to IP offset $IPOFFSET"
		find */patches/ -type f -exec sed -i "s/${PREFIX}2/${VCT_IP}/g" {} \;
		find */patches/ -type f -exec sed -i "s/${PREFIX}3/${RESEARCHER_IP}/g" {} \;
	fi
}
