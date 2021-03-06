#!/bin/bash

cd $HOME

if [[ -z $EMAIL || -z $DOMAINS || -z $SECRET ]]; then
	echo "EMAIL, DOMAINS, and SECRET env vars required"
	env
	exit 1
fi

cat_log_and_deply_exit() {
    echo "Error"
    cat /var/log/letsencrypt/letsencrypt.log
    sleep 60
    exit 1
}

echo "Inputs:"
echo " EMAIL: $EMAIL"
echo " DOMAINS: $DOMAINS"
echo " SECRET: $SECRET"

NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
echo "Current Kubernetes namespce: $NAMESPACE"

echo "Starting HTTP server..."
python3 -m http.server 80 &
PID=$!
sleep 10

echo "Starting certbot..."
certbot certonly --webroot -w $HOME -d ${DOMAINS} --agree-tos --email ${EMAIL} --no-self-upgrade

kill $PID
echo "Certbot finished. Killing http server..."

echo "Finiding certs. Exiting if certs are not found ..."
CERTPATH=/etc/letsencrypt/live/$(echo $DOMAINS | cut -f1 -d',')
ls $CERTPATH || cat_log_and_deply_exit

echo "Creating update for secret..."
cat /secret-patch-template.json | \
	sed "s/NAMESPACE/${NAMESPACE}/" | \
	sed "s/NAME/${SECRET}/" | \
	sed "s/TLSCERT/$(cat ${CERTPATH}/fullchain.pem | base64 | tr -d '\n')/" | \
	sed "s/TLSKEY/$(cat ${CERTPATH}/privkey.pem |  base64 | tr -d '\n')/" \
	> /secret-patch.json

echo "Checking json file exists. Exiting if not found..."
ls /secret-patch.json || cat_log_and_deply_exit

# Update Secret
echo "Updating secret..."
curl \
  --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  -XPATCH \
  -H "Accept: application/json, */*" \
  -H "Content-Type: application/strategic-merge-patch+json" \
  -d @/secret-patch.json https://kubernetes/api/v1/namespaces/${NAMESPACE}/secrets/${SECRET} \
  -k -v
echo "Done"
