#!/bin/bash

docker compose up -d

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
    http://127.0.0.1:3000/api/auth/login)
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
http://127.0.0.1:3000/api/user/tokens)

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
 'http://127.0.0.1:3000/api/projects' \
 -H 'accept: application/json' \
 -H 'Content-Type: application/json' \
 -H "Authorization: Bearer $TOKEN_ID" \
 -d '{"name":"ansible","alert":true}' \
 -o /dev/null)

if [[ ! $HTTP_STATUS =~ ^2[0-9][0-9]$ ]]; then
 echo "[!] ERROR: Failed to create project! Status code: $HTTP_STATUS"
 exit 1
fi

echo "[*] Creating inventory..."
HTTP_STATUS=$(curl -s -w "%{http_code}" -b semaphore-cookie -X 'POST' \
 'http://127.0.0.1:3000/api/project/1/inventory' \
 -H 'accept: application/json' \
 -H 'Content-Type: application/json' \
 -H "Authorization: Bearer $TOKEN_ID" \
 -d '{"name":"all","ssh_key_id":1,"type":"static","inventory":"[all]\n127.0.0.1 ansible_connection=local","project_id":1}' \
 -o /dev/null)

if [[ ! $HTTP_STATUS =~ ^2[0-9][0-9]$ ]]; then
 echo "[!] ERROR: Failed to create inventory! Status code: $HTTP_STATUS"
 exit 1
fi

echo "[*] Creating Agent repository..."
HTTP_STATUS=$(curl -s -w "%{http_code}" -b semaphore-cookie -X 'POST' \
 'http://127.0.0.1:3000/api/project/1/repositories' \
 -H 'accept: application/json' \
 -H 'Content-Type: application/json' \
 -H "Authorization: Bearer $TOKEN_ID" \
 -d '{"name":"install-agent","git_url":"/ansible/playbooks/install-agent","ssh_key_id":1,"project_id":1}' \
 -o /dev/null)

if [[ ! $HTTP_STATUS =~ ^2[0-9][0-9]$ ]]; then
 echo "[!] ERROR: Failed to register agent playbook! Status code: $HTTP_STATUS"
 exit 1
fi

echo "[*] Creating Bastion repository..."
HTTP_STATUS=$(curl -s -w "%{http_code}" -b semaphore-cookie -X 'POST' \
 'http://127.0.0.1:3000/api/project/1/repositories' \
 -H 'accept: application/json' \
 -H 'Content-Type: application/json' \
 -H "Authorization: Bearer $TOKEN_ID" \
 -d '{"name":"install-bastion","git_url":"/ansible/playbooks/install-bastion","ssh_key_id":1,"project_id":1}' \
 -o /dev/null)

if [[ ! $HTTP_STATUS =~ ^2[0-9][0-9]$ ]]; then
 echo "[!] ERROR: Failed to register bastion playbook! Status code: $HTTP_STATUS"
 exit 1
fi

echo "[*] Creating Agent template..."
HTTP_STATUS=$(curl -s -w "%{http_code}" -b semaphore-cookie -X 'POST' \
 'http://127.0.0.1:3000/api/project/1/templates' \
 -H 'accept: application/json' \
 -H 'Content-Type: application/json' \
 -H "Authorization: Bearer $TOKEN_ID" \
 -d '{"type":"","playbook":"playbook.yaml","inventory_id":1,"repository_id":1,"environment_id":1,"name":"install-agent","survey_vars":[{"values":[],"name":"bastion_host","title":"bastion_host","required":true,"type":""},{"values":[],"name":"bastion_port","title":"bastion_port","type":"","required":true},{"values":[],"name":"bastion_user","title":"bastion_user","type":"","required":true},{"values":[],"name":"bastion_password","title":"bastion_password","type":"","required":true},{"values":[],"name":"target_host","title":"target_host","type":"","required":true},{"values":[],"name":"target_port","title":"target_port","description":"","required":true,"type":""},{"values":[],"name":"target_user","title":"target_user","type":"","required":true},{"values":[],"name":"target_password","title":"target_password","type":"","required":true},{"values":[],"name":"tunnel_port","title":"tunnel_port","type":"","required":true},{"values":[],"name":"install_method","title":"install_method","type":""}],"app":"ansible","arguments":"[]","project_id":1}' \
 -o /dev/null)

if [[ ! $HTTP_STATUS =~ ^2[0-9][0-9]$ ]]; then
 echo "[!] ERROR: Failed to create agent template! Status code: $HTTP_STATUS"
 exit 1
fi

echo "[*] Creating Bastion template..."
HTTP_STATUS=$(curl -s -w "%{http_code}" -b semaphore-cookie -X 'POST' \
 'http://127.0.0.1:3000/api/project/1/templates' \
 -H 'accept: application/json' \
 -H 'Content-Type: application/json' \
 -H "Authorization: Bearer $TOKEN_ID" \
 -d '{"type":"","name":"install-bastion","playbook":"playbook.yaml","inventory_id":1,"repository_id":2,"environment_id":1,"survey_vars":[{"values":[],"name":"bastion_host","title":"bastion_host","required":true},{"values":[],"name":"bastion_port","title":"bastion_port","required":true},{"values":[],"name":"bastion_user","title":"bastion_user","required":true},{"values":[],"name":"bastion_password","title":"bastion_password","required":true},{"values":[],"name":"tunnel_manager_database_host","title":"tunnel_manager_database_host","required":true},{"values":[],"name":"tunnel_manager_database_port","title":"tunnel_manager_database_port","required":true},{"values":[],"name":"tunnel_manager_database_user","title":"tunnel_manager_database_user","required":true},{"values":[],"name":"tunnel_manager_database_password","title":"tunnel_manager_database_password","required":true},{"values":[],"name":"tunnel_manager_database_name","title":"tunnel_manager_database_name","required":true}],"app":"ansible","arguments":"[]","project_id":1}' \
 -o /dev/null)

if [[ ! $HTTP_STATUS =~ ^2[0-9][0-9]$ ]]; then
 echo "[!] ERROR: Failed to create bastion template! Status code: $HTTP_STATUS"
 exit 1
fi

echo "[*] Deleting token..."
HTTP_STATUS=$(curl -s -w "%{http_code}" -b semaphore-cookie -X 'DELETE' \
 "http://127.0.0.1:3000/api/user/tokens/$TOKEN_ID" \
 -H 'accept: application/json' \
 -H 'Content-Type: application/json' \
 -H "Authorization: Bearer $TOKEN_ID" \
 -o /dev/null)

if [[ ! $HTTP_STATUS =~ ^2[0-9][0-9]$ ]]; then
 echo "[!] ERROR: Failed to delete token! Status code: $HTTP_STATUS"
 exit 1
fi

echo "[*] Deleting cookie..."
rm -f semaphore-cookie
