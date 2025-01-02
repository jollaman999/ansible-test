#!/bin/bash

CONFIG_FILE="/etc/tunnel-manager/vms.conf"
PORT_MAPPING_FILE="/etc/tunnel-manager/service-port-mapping.conf"

if [ -z "$SERVICE_IP" ]; then
    echo "Error: SERVICE_IP environment variable is not set"
    exit 1
fi

maintain_tunnel() {
    local vm_ip="$1"
    local vm_port="$2"
    local vm_user="$3"
    local tunnel_args=""

    # Build tunnel arguments from port mapping file
    while IFS=' ' read -r service_port tunnel_port; do
        [[ $service_port =~ ^#.*$ ]] && continue
        [[ -z $service_port ]] && continue
        tunnel_args+=" -R 127.0.0.1:${tunnel_port}:${SERVICE_IP}:${service_port}"
    done < "$PORT_MAPPING_FILE"

    while true; do
        if ! pgrep -f "ssh.*-R.*${SERVICE_IP}.*${vm_user}@${vm_ip}" > /dev/null; then
            ssh -N -o ServerAliveInterval=60 -o StrictHostKeyChecking=no \
                $tunnel_args \
                -p "${vm_port}" \
                "${vm_user}@${vm_ip}" &
            
            echo "$(date): Created tunnel for ${vm_ip} to ${SERVICE_IP}"
        fi
        sleep 10
    done
}

cleanup() {
    pkill -f "ssh.*-R.*:${SERVICE_IP}:"
    exit 0
}

trap cleanup SIGINT SIGTERM

while IFS=' ' read -r vm_ip vm_port vm_user; do
    [[ $vm_ip =~ ^#.*$ ]] && continue
    [[ -z $vm_ip ]] && continue
    
    maintain_tunnel "$vm_ip" "$vm_port" "$vm_user" &
done < "$CONFIG_FILE"

wait
