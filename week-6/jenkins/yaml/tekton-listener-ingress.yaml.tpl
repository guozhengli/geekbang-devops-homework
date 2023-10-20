apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tekton-listener-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
    - host: tekton.${prefix}.${domain}
      http:
        paths:
          - path: /hooks
            pathType: Prefix
            backend:
              service:
                name: el-github-listener
                port:
                  number: 8080
