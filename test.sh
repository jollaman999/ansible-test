curl -X 'POST' \
  'http:/192.168.110.14:3000/api/project/1/tasks' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer ===========토큰값입력============' \
  -d '{
  "template_id": 1,
  "params": {},
  "environment": "{\"bastion_password\":\"xxxx\",\"target_password\":\"xxxx\"}",
  "secret": "{}",
  "project_id": 1
}'
