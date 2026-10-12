#!/bin/bash
# Walk a note through the REST API: create, read, list, update, delete.
# Each route is its own Lambda function backed by the same DynamoDB table.
set -euo pipefail

STACK=aws-sdk-js-notes-app
CONTENT="note from CI $(date +%s)"

API_URL=$(lstk aws cloudformation describe-stacks --stack-name "$STACK" \
  --query "Stacks[0].Outputs[?starts_with(OutputKey, 'endpointEndpoint')].OutputValue | [0]" --output text)
NOTES="${API_URL%/}/notes"
echo "API: $NOTES"

# Print the body, or fail with the status and body on a non-2xx response
request() {
  local body status
  body=$(curl -s -m 30 -w '\n%{http_code}' "$@")
  status=${body##*$'\n'}
  body=${body%$'\n'*}
  if [ "${status:0:1}" != "2" ]; then
    echo "Test failed: $* returned HTTP $status: $body" >&2
    return 1
  fi
  echo "$body"
}

created=$(request -X POST "$NOTES" -H 'Content-Type: application/json' -d "{\"content\":\"$CONTENT\"}")
ID=$(echo "$created" | jq -r '.noteId.S')
if [ -z "$ID" ] || [ "$ID" = "null" ]; then
  echo "Test failed: create returned $created"
  exit 1
fi
echo "PASS: created note $ID"

note=$(request "$NOTES/$ID")
if ! echo "$note" | jq -e --arg c "$CONTENT" '.content == $c' > /dev/null; then
  echo "Test failed: get returned $note"
  exit 1
fi
echo "PASS: read note back"

if ! request "$NOTES" | jq -e --arg id "$ID" 'any(.[]; .noteId == $id)' > /dev/null; then
  echo "Test failed: note $ID missing from the list"
  exit 1
fi
echo "PASS: note appears in the list"

request -X PUT "$NOTES/$ID" -H 'Content-Type: application/json' -d '{"content":"updated by CI"}' > /dev/null
note=$(request "$NOTES/$ID")
if ! echo "$note" | jq -e '.content == "updated by CI"' > /dev/null; then
  echo "Test failed: update not applied, got $note"
  exit 1
fi
echo "PASS: updated note"

request -X DELETE "$NOTES/$ID" > /dev/null
# getNote answers 500 "Item not found." once the note is gone
status=$(curl -s -m 30 -o /dev/null -w '%{http_code}' "$NOTES/$ID")
if [ "$status" != "500" ]; then
  echo "Test failed: note still readable after delete (HTTP $status)"
  exit 1
fi
echo "PASS: deleted note"

echo "Test passed: notes API handled the full CRUD cycle"
