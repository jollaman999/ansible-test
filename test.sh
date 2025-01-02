#!/bin/bash

SERVER_ADDRESS="192.168.110.14"
SERVER_PORT="3000"

BASTION_HOST="192.168.110.229"
BASTION_PORT="22"
BASTION_USER="root"
BASTION_PASSWORD="xxxx"
TARGET_HOST="10.0.0.164"
TARGET_PORT="22"
TARGET_USER="root"
TARGET_PASSWORD="xxxx"
TUNNEL_PORT="30000"

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

echo "[*] Creating project..."
HTTP_STATUS=$(curl -s -w "%{http_code}" -b semaphore-cookie -X 'POST' \
 "http://$SERVER_ADDRESS:$SERVER_PORT/api/project/1/tasks" \
 -H 'accept: application/json' \
 -H 'Content-Type: application/json' \
 -H "Authorization: Bearer $TOKEN_ID" \
 -d '{
  "template_id": 1,
  "params": {},
  "environment": "{
    \"bastion_host\":\"$BASTION_HOST\",
    \"bastion_port\":\"$BASTION_PORT\",
    \"bastion_user\":\"$BASTION_USER\",
    \"bastion_password\":\"$BASTION_PASSWORD\",
    \"target_host\":\"$TARGET_HOST\",
    \"target_port\":\"$TARGET_PORT\",
    \"target_user\":\"$TARGET_USER\",
    \"target_password\":\"$TARGET_PASSWORD\",
    \"tunnel_port\":\"$TUNNEL_PORT\"
  }",
  "secret": "{}",
  "project_id": 1
  }' \
 -o /dev/null)

if [[ ! $HTTP_STATUS =~ ^2[0-9][0-9]$ ]]; then
 echo "[!] ERROR: Failed to create project! Status code: $HTTP_STATUS"
 exit 1
fi
