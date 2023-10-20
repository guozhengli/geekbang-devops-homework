apiVersion: v1
kind: Secret
metadata:
  name: basic-user-pass
  annotations:
    tekton.dev/git-0: https://github.com
    tekton.dev/git-1: https://gitlab.com
type: kubernetes.io/basic-auth
stringData:
  username: "${github_username}"
  password: "${github_personal_token}"
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: build-bot
secrets:
  - name: basic-user-pass
