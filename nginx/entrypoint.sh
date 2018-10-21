
export DOLLAR="$"
cat /etc/nginx/nginx.conf.in | envsubst | tee /etc/nginx/nginx.conf

wait-for frontend:3000 --  nginx -g "daemon off;"
