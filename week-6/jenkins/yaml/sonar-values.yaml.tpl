account:
  adminPassword: "${sonar_password}"
  currentAdminPassword: admin

ingress:
  enabled: true
  hosts:
    - name: "sonar.${prefix}.${domain}"
  ingressClassName: nginx