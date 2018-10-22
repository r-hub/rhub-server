
set -e

export DOLLAR="$"
if [ "x$RHUB_HTTPS" == "xtrue" ]; then
    echo "Installing HTTPS nginx config"
    cat /etc/nginx/nginx.conf.https.in | envsubst > /etc/nginx/nginx.conf
    cat /etc/nginx/jenkins.conf.https.in | \
	envsubst > /etc/nginx/conf.d/jenkins.conf
else
    echo "Installing HTTP nginx config"
    cat /etc/nginx/nginx.conf.in | envsubst > /etc/nginx/nginx.conf
    cat /etc/nginx/jenkins.conf.in | \
	envsubst > /etc/nginx/conf.d/jenkins.conf
fi

wait-for frontend:3000 -- sleep 0
wait-for jenkins:8080  -- nginx -g "daemon off;"
