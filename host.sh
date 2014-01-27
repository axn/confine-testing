function configure_network(){
	if brctl show | grep -q $LXC_NETWORK_LINK; then
		ip link set dev $LXC_NETWORK_LINK down
		brctl delbr $LXC_NETWORK_LINK
	fi
	if ! brctl show | grep -q $LXC_NETWORK_LINK; then
        echo "Bridge $LXC_NETWORK_LINK does not exist, creating bridge..."
        if ip link show $LXC_NETWORK_LINK > /dev/null 2>&1; then
            echo "Interface $LXC_NETWORK_LINK exists but is not a bridge."
            return 1;
        fi
        brctl addbr $LXC_NETWORK_LINK;
    fi
    echo "Set $LXC_NETWORK_LINK up..."
    ip link set dev $LXC_NETWORK_LINK up;
	for i in $EXTRA_IFACES; do
		echo "Adding $i to $LXC_NETWORK_LINK"
		brctl addif $LXC_NETWORK_LINK $i
	done
	
    if ! ip -6 addr show dev $LXC_NETWORK_LINK | grep -q ${IPPREFIX}1/64; then
        echo "Configure IPV6 $LXC_NETWORK_LINK..."
        ip -6 addr add ${IPPREFIX}1/64 dev $LXC_NETWORK_LINK
    fi
	
    return 0
}

function configure_masquerade() {
	if ! ip addr show dev $LXC_NETWORK_LINK | grep -q ${IPV4PREFIX}.1/24; then
		echo "Configure IPV4 $LXC_NETWORK_LINK..."
		ip addr add ${IPV4PREFIX}1/24 dev $LXC_NETWORK_LINK
	fi
	
	echo 1 > /proc/sys/net/ipv4/ip_forward
	if iptables -t nat -D POSTROUTING -o ${OUT_IFACE} -s ${IPV4PREFIX}0/24 -j MASQUERADE; then
		echo "Removed previous MASQ rule..."
	fi
	echo "Clearing conntrack table..."
	conntrack -F
	echo "Adding MASQ rule for ${OUT_IFACE}"
	iptables -t nat -A POSTROUTING -o ${OUT_IFACE} -s ${IPV4PREFIX}0/24 -j MASQUERADE
}

LXC_NETWORK_LINK=${LXC_NETWORK_LINK:-"vmbridge"};
IPPREFIX=${IPPREFIX:-"fdf6:1e51:5f7b:b50c::"};
IPV4PREFIX=${IPV4PREFIX:-"172.16.0."};
OUT_IFACE=${OUT_IFACE:-"eth0"}
EXTRA_IFACES=${EXTRA_IFACES:-""}
