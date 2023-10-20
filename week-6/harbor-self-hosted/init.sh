#!/bin/bash  

# helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# install cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.0 \
  --set installCRDs=true

# apply let's encrypt issuer
kubectl create namespace harbor
kubectl apply -f /tmp/cloudflare-token.yaml
kubectl apply -f /tmp/issuer.yaml

# install ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace --wait --version "4.7.2"

# install harbor HA
helm registry login docker.io --username lyzhang1999 --password dckr_pat_FQEWlxlMfz725jhCQh5-mv5msmU
mkdir -p /tmp/charts
mv /tmp/Chart.yaml /tmp/charts/Chart.yaml
mv /tmp/values.yaml /tmp/charts/values.yaml
cd /tmp/charts
helm dependencies update
helm install harbor . --namespace harbor --create-namespace