#!/bin/bash

SERVER_ADDRESS="192.168.110.14"
SERVER_PORT="3000"

BASTION_HOST="192.168.110.229"
BASTION_PORT="22"
BASTION_USER="root"
BASTION_PASSWORD="xxxx"

TUNNEL_MANAGER_DATABASE_HOST="192.168.110.14"
TUNNEL_MANAGER_DATABASE_PORT="3306"
TUNNEL_MANAGER_DATABASE_USER="tunnel-manager"
TUNNEL_MANAGER_DATABASE_PASSWORD="tunnel-manager-pass"
TUNNEL_MANAGER_DATABASE_NAME="tunnel-manager"

ENV_JSON=$(cat <<EOF
{
    "bastion_host": "${BASTION_HOST}",
    "bastion_port": "${BASTION_PORT}",
    "bastion_user": "${BASTION_USER}",
    "bastion_password": "${BASTION_PASSWORD}",
    "tunnel_manager_database_host": "${TUNNEL_MANAGER_DATABASE_HOST}",
    "tunnel_manager_database_port": "${TUNNEL_MANAGER_DATABASE_PORT}",
    "tunnel_manager_database_user": "${TUNNEL_MANAGER_DATABASE_USER}",
    "tunnel_manager_database_password": "${TUNNEL_MANAGER_DATABASE_PASSWORD}",
    "tunnel_manager_database_name": "${TUNNEL_MANAGER_DATABASE_NAME}"
}
EOF
)

echo "[*] Logging in to semaphore..."
cnt=0
while true
do
   (( cnt = "$cnt" + 1 ))
    HTTP_STATUS=$(curl -s -w "%{http_code}" -c semaphore-cookie -XPOST \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -d '{"auth": "admin", "password": "semaphorepass"}' \
    -o /dev/null \
    http://$SERVER_ADDRESS:$SERVER_PORT/api/auth/login)
   if [[ $HTTP_STATUS =~ ^2[0-9][0-9]$ ]]; then
      break
   fi
   if [ "$cnt" = "30" ]; then
      echo "[!] Failed to login to Semaphore."
      exit 1;
   fi
   sleep 1
done
echo "[*] Successfully logged in to Semaphore!"

echo "[*] Creating token..."
RESPONSE=$(curl -s -w "\n%{http_code}" -b semaphore-cookie -XPOST \
-H 'Content-Type: application/json' \
-H 'Accept: application/json' \
"http://$SERVER_ADDRESS:$SERVER_PORT/api/user/tokens")

HTTP_STATUS=$(echo "$RESPONSE" | tail -n1)
if [[ ! $HTTP_STATUS =~ ^2[0-9][0-9]$ ]]; then
 echo "[!] ERROR: Failed to create token! Status code: $HTTP_STATUS"
 exit 1
fi

RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')
TOKEN_ID=$(echo "$RESPONSE_BODY" | grep -o '"id":"[^"]*"' | awk -F'"' '{print $4}')

if [ "$TOKEN_ID" = "" ]; then
 echo "[!] ERROR: Failed to get token ID from response!"
 exit 1
fi

echo "[*] Running Bastion Task..."
HTTP_STATUS=$(curl -s -w "%{http_code}" -b semaphore-cookie -X 'POST' \
 "http://$SERVER_ADDRESS:$SERVER_PORT/api/project/1/tasks" \
 -H 'accept: application/json' \
 -H 'Content-Type: application/json' \
 -H "Authorization: Bearer $TOKEN_ID" \
 --data-raw '{
  "template_id": 2,
  "params": {},
  "environment": "'"$(echo $ENV_JSON | sed 's/"/\\"/g')"'",
  "secret": "{}",
  "project_id": 1
  }' \
 -o /dev/null)

if [[ ! $HTTP_STATUS =~ ^2[0-9][0-9]$ ]]; then
 echo "[!] ERROR: Failed to run bastion task! Status code: $HTTP_STATUS"
 exit 1
fi

echo "[*] Deleting token..."
HTTP_STATUS=$(curl -s -w "%{http_code}" -b semaphore-cookie -X 'DELETE' \
 "http://$SERVER_ADDRESS:$SERVER_PORT/api/user/tokens/$TOKEN_ID" \
 -H 'accept: application/json' \
 -H 'Content-Type: application/json' \
 -H "Authorization: Bearer $TOKEN_ID" \
 -o /dev/null)

if [[ ! $HTTP_STATUS =~ ^2[0-9][0-9]$ ]]; then
 echo "[!] ERROR: Failed to delete token! Status code: $HTTP_STATUS"
 exit 1
fi
