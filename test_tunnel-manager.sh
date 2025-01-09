#!/bin/bash

BASTION_HOST="192.168.110.229"
TUNNEL_MANAGER_PORT="8888"

TARGET_HOST="10.0.0.164"
TARGET_PORT="22"
TARGET_USER="root"
TARGET_PASSWORD="xxxx"
TUNNEL_PORT="30000"

echo "[*] Running test server ..."
killall test_http_server 2>&1 > /dev/null
./test_http_server &

echo "[*] Adding service ports..."

curl -X POST http://$BASTION_HOST:$TUNNEL_MANAGER_PORT/api/service-ports \
  -H 'Content-Type: application/json' \
  -d '{
    "service_ip": "192.168.110.14",
    "service_port": 2000,
    "local_port": 12000,
    "description": "Service Port 2000"
  }'

curl -X POST http://$BASTION_HOST:$TUNNEL_MANAGER_PORT/api/service-ports \
  -H 'Content-Type: application/json' \
  -d '{
    "service_ip": "192.168.110.14",
    "service_port": 2001,
    "local_port": 12001,
    "description": "Service Port 2001"
  }'

curl -X POST http://$BASTION_HOST:$TUNNEL_MANAGER_PORT/api/service-ports \
  -H 'Content-Type: application/json' \
  -d '{
    "service_ip": "192.168.110.14",
    "service_port": 2002,
    "local_port": 12002,
    "description": "Service Port 2002"
  }'

curl -X POST http://$BASTION_HOST:$TUNNEL_MANAGER_PORT/api/service-ports \
  -H 'Content-Type: application/json' \
  -d '{
    "service_ip": "192.168.110.14",
    "service_port": 8086,
    "local_port": 18086,
    "description": "Service Port 8086"
  }'

echo "[*] Adding target..."

curl -X POST http://$BASTION_HOST:$TUNNEL_MANAGER_PORT/api/vms \
  -H 'Content-Type: application/json' \
  -d '{
    "ip": "'$TARGET_HOST'",
    "port": '$TARGET_PORT',
    "user": "'$TARGET_USER'",
    "password": "'$TARGET_PASSWORD'",
    "description": "Test VM"
  }'
