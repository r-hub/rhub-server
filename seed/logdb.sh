
echo DB is at $LOGDB_URL

# The last part is the DB, so we remove that
BASEURL="${LOGDB_URL%/*}"

# Need to wait for the DB to be ready
while true
do
    echo "waiting for DB"
    if curl -s "$BASEURL"; then break; fi
    sleep 1
done

# Try creating a _users DB, to avoid error messages
curl -s -X PUT "$BASEURL/_users" || true

if curl -s -o /dev/null "$LOGDB_URL"; then
    echo Creating /logs DB
    curl -s -X PUT "$LOGDB_URL"
else
    echo /logs DB already exists
fi

echo Adding/updating design document
REV=$(curl -s "$LOGDB_URL"/_design/app  | jq -r ._rev)
if [[ "$REV" != "null" ]];  then
    curl --silent --request DELETE "$LOGDB_URL/_design/app?rev=$REV"
fi
curl --silent --header "Content-Type: application/json" \
     --request PUT --data @/seed/app.json \
     "$LOGDB_URL/_design/app"
