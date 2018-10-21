
set

export DOLLAR="$"
if [ "x$RHUB_HTTPS" == "xtrue" ]; then
    echo "Installing HTTPS nginx config"
    cat /etc/nginx/nginx.conf.https.in | envsubst > /etc/nginx/nginx.conf
else
    echo "Installing HTTP nginx config"
    cat /etc/nginx/nginx.conf.in | envsubst > /etc/nginx/nginx.conf
fi

wait-for frontend:3000 --  nginx -g "daemon off;"
