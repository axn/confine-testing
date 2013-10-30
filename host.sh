LXC_NETWORK_LINK="vmbr"

function configure_network() {
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
    
    echo "Configure $LXC_NETWORK_LINK..."
    ip -6 addr add fdf6:1e51:5f7b:b50c::1/64 dev $LXC_NETWORK_LINK;
    return 0
}
