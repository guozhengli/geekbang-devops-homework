harbor:
  enabled: true
  persistence:
    persistentVolumeClaim:
      registry:
        size: 20Gi
  externalURL: https://harbor.${prefix}.${domain}
  redis:
    type: external
    external:
      addr: "redis-master"
  database:
    type: external
    external:
      host: "db-pgpool"
      username: "postgres"
      password: "postgres"
  expose:
    tls:
      enabled: true
      certSource: secret
      secret:
        secretName: harbor-secret-tls
        notarySecretName: notary-secret-tls
    ingress:
      className: nginx
      annotations:
        kubernetes.io/tls-acme: "true"
        cert-manager.io/issuer: "harbor-issuer"
      hosts:
        core: harbor.${prefix}.${domain}
        notary: notary.${prefix}.${domain}
  portal:
    replicas: 2
  core:
    replicas: 2
  jobservice:
    replicas: 2
  registry:
    replicas: 2
  chartmuseum:
    replicas: 2

redis:
  enabled: true
  fullnameOverride: redis
  auth:
    enabled: false

postgresql-ha:
  enabled: true
  fullnameOverride: db
  global:
    postgresql:
      username: postgres
      password: postgres
      database: registry
      repmgrUsername: postgres
      repmgrPassword: postgres
