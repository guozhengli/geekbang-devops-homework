# 训练营课程作业(必做)

使用 Terraform 开通一台腾讯云 CVM, 安装 K3s(集群 1), 并在集群 1 内安装 Jenkins、Argo CD
书写 Terraform lac 代码: 开通两台腾讯云 CVM, 分别安装 K3s(集群 2、集群 3), 并实现以下要求:
使用集群 1 作为 Terraform Kubernetes backend 后端存储
将 laC 源码存储在 GitHub 代码仓库中
在集群 1 的 Jenkins 中配置流水线, 实现在 lac 代码变更时自动触发变更 (Jenkinsfile)
在集群 1 的 Argo CD 实例中添加集群 2、3
使用一个 ApplicationSet +List Generators 在集群 2、集群 3 内的 default 命名空间下同时部署示例应用 Bookinfo(Helm Chart 源码见: iac/lastwork/bookinfo)
示例应用部署完成后，实现以下架构：

备注
这是一个理想的多云灾备部署场景, 集群 1、2、3 可能分别部署在不同云厂商。集群 1 的 Proxy 作为流量入口对外提供服务，对部署在集群 2 和集群 3 的无状态示例应用 Bookinfo 做负载均衡。

## 作业步骤

    - 使用Terraform拉起环境

        ```shell
        $ terraform init  # 进行初始化 如果外网包拉不下来时多尝试下 或者shell 设置代理进行FQ下载
        terraform apply --auto-approve # 进行apply
        ```

    - 等待crossplane provider部署完成后，查看crossplane provider状态

        ```shell
        $ kubectl get provider
        NAME                 INSTALLED   HEALTHY   PACKAGE                                              AGE
        provider-terraform   True        True      xpkg.upbound.io/upbound/provider-terraform:v0.11.0   3m
        ```

    部署 provoder config

        ```shell
        $ kubectl apply -f yaml/tf-provider-config.yaml
        ```

    - 等待环境完成后，Agro CD 中部署了 ApplicationSet

    - 登陆 Jenkins，配置 Iac 工程

        ![Alt text](image.png)
        ![Alt text](image-1.png)

    - 登陆 GitHub配置webhook
    - 提交iac代码触发构建，创建新集群

        ![Alt text](image-2.png)

    - 等待 Terraform 部署完成

        ```shell
        $ kubectl get workspace
        NAME    READY   SYNCED   AGE
        k3s-3   True    True     15m
        k3s-2   True    True     15m
        ❯ kubectl get workspace k3s-2 -o yaml | yq .status.atProvider.outputs.public_ip
        124.156.161.160
        ❯ kubectl get workspace k3s-3 -o yaml | yq .status.atProvider.outputs.public_ip
        43.128.24.229
        ```

    - 分别登陆到每台新建的机器上获取到config.yaml文件，并用argocli添加新集群到argocd中

        ```shell
        ❯ argocd cluster add default --cluster-endpoint=config2.yaml --kubeconfig=config2.yaml --name=k8s-2
        WARNING: This will create a service account `argocd-manager` on the cluster referenced by context `default` with full cluster level privileges. Do you want to continue [y/N]? y
        INFO[0002] ServiceAccount "argocd-manager" created in namespace "kube-system" 
        INFO[0002] ClusterRole "argocd-manager-role" created    
        INFO[0002] ClusterRoleBinding "argocd-manager-role-binding" created 
        INFO[0008] Created bearer token secret for ServiceAccount "argocd-manager" 
        Cluster 'https://124.156.161.160:6443' added
        ❯ argocd cluster add default --cluster-endpoint=config3.yaml --kubeconfig=config3.yaml --name=k8s-3
        WARNING: This will create a service account `argocd-manager` on the cluster referenced by context `default` with full cluster level privileges. Do you want to continue [y/N]? y
        INFO[0002] ServiceAccount "argocd-manager" created in namespace "kube-system" 
        INFO[0002] ClusterRole "argocd-manager-role" created    
        INFO[0002] ClusterRoleBinding "argocd-manager-role-binding" created 
        INFO[0008] Created bearer token secret for ServiceAccount "argocd-manager" 
        Cluster 'https://43.128.23.209:6443' added

        ```
        ![](assets/17021846111130.jpg)

    - 给每个集群添加 label use=prod，等待自动部署 bookinfo 完成

    - 部署 ingress + HAProxy 实现流量负载均衡 (加权轮询)，自动故障转移

        ```shell
        kubectl apply -f haproxy
        ```

    - 等待 HAProxy 部署完成后，测试

        ```shell
        for i in {1..10}; do curl http://43.129.235.21 -H "Host: bookinfo.example.local" -v; done
        ```

    - 查看两台集群的 productpage 日志

        ```shell
        export KUBECONFIG=./config2.yaml
        k logs productpage-v1-676fd29cf-mkzmf -f
        INFO:root:start at port 9080
        * Serving Flask app 'productpage' (lazy loading)
        * Environment: production
        WARNING: This is a development server. Do not use it in a production deployment.
        Use a production WSGI server instead.
        * Debug mode: on
        INFO:werkzeug:WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
        * Running on all addresses (::)
        * Running on http://[::1]:9080
        * Running on http://[::1]:9080
        INFO:werkzeug:Press CTRL+C to quit
        INFO:werkzeug: * Restarting with stat
        INFO:root:start at port 9080
        WARNING:werkzeug: * Debugger is active!
        INFO:werkzeug: * Debugger PIN: 716-601-183
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:03] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:05] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:07] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:09] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:11] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:13] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:15] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:17] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:19] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:21] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:23] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:25] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:27] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:29] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:31] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:33] "GET / HTTP/1.1" 200 -

        ...
        ```

        ```shell
        export KUBECONFIG=./config3.yaml
        $ kubectl logs productpage-v1-676fd29cf-4587z -f
        INFO:root:start at port 9080
        * Serving Flask app 'productpage' (lazy loading)
        * Environment: production
        WARNING: This is a development server. Do not use it in a production deployment.
        Use a production WSGI server instead.
        * Debug mode: on
        INFO:werkzeug:WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
        * Running on all addresses (::)
        * Running on http://[::1]:9080
        * Running on http://[::1]:9080
        INFO:werkzeug:Press CTRL+C to quit
        INFO:werkzeug: * Restarting with stat
        INFO:root:start at port 9080
        WARNING:werkzeug: * Debugger is active!
        INFO:werkzeug: * Debugger PIN: 106-274-489
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:04] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:06] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:08] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:10] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:12] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:14] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:16] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:18] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:20] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:22] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:24] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:26] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:28] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:30] "GET / HTTP/1.1" 200 -
        INFO:werkzeug:::ffff:10.98.0.24 - - [19/Dec/2023 18:57:32] "GET / HTTP/1.1" 200 -
    
        ```

    - 查看 HAProxy controller 日志

        ```shell
        $ kubectl logs haproxy-deployment-76556fc989-8mpkj -f
        [NOTICE]   (1) : New worker (9) forked
        [NOTICE]   (1) : Loading success.
        [NOTICE]   (9) : haproxy version is 2.9.0-fddb8c1
        [NOTICE]   (9) : path to executable is /usr/local/sbin/haproxy
        [WARNING]  (9) : [haproxy.main()] Failed to drop supplementary groups. Using 'gid'/'group' without 'uid'/'user' is generally useless.
        10.0.0.29:43296 [19/Dec/2023:18:58:06.601] http_front http_back/cluster2 0/0/1/4/5 200 1804 - - ---- 1/1/0/0/0 0/0 "GET / HTTP/1.1"
        10.0.0.29:38386 [19/Dec/2023:18:58:09.611] http_front http_back/cluster2 0/0/1/4/5 200 1804 - - ---- 2/2/0/0/0 0/0 "GET / HTTP/1.1"
        10.0.0.29:38402 [19/Dec/2023:18:58:10.614] http_front http_back/cluster2 0/0/1/4/5 200 1804 - - ---- 3/3/0/0/0 0/0 "GET / HTTP/1.1"
        10.0.0.29:38416 [19/Dec/2023:18:58:11.412] http_front http_back/cluster2 0/0/1/4/5 200 1804 - - ---- 4/4/0/0/0 0/0 "GET / HTTP/1.1"
        10.0.0.29:38386 [19/Dec/2023:18:58:12.117] http_front http_back/cluster3 0/0/1/3/4 200 1804 - - ---- 4/4/0/0/0 0/0 "GET / HTTP/1.1"
        10.0.0.29:38416 [19/Dec/2023:18:58:12.733] http_front http_back/cluster2 0/0/1/4/5 200 1804 - - ---- 4/4/0/0/0 0/0 "GET / HTTP/1.1"
        10.0.0.29:38416 [19/Dec/2023:18:58:13.365] http_front http_back/cluster2 0/0/0/4/4 200 1804 - - ---- 4/4/0/0/0 0/0 "GET / HTTP/1.1"
        10.0.0.29:38416 [19/Dec/2023:18:58:13.989] http_front http_back/cluster2 0/0/0/4/4 200 1804 - - ---- 4/4/0/0/0 0/0 "GET / HTTP/1.1"
        10.0.0.29:38402 [19/Dec/2023:18:58:14.637] http_front http_back/cluster2 0/0/0/4/4 200 1804 - - ---- 4/4/0/0/0 0/0 "GET / HTTP/1.1"
        10.0.0.29:38402 [19/Dec/2023:18:58:15.271] http_front http_back/cluster3 0/0/0/4/4 200 1804 - - ---- 4/4/0/0/0 0/0 "GET / HTTP/1.1"
        10.0.0.29:38402 [19/Dec/2023:18:58:15.885] http_front http_back/cluster2 0/0/0/5/5 200 1804 - - ---- 4/4/0/0/0 0/0 "GET / HTTP/1.1"
        10.0.0.29:43296 [19/Dec/2023:18:58:16.559] http_front http_back/cluster2 0/0/0/5/5 200 1804 - - ---- 4/4/0/0/0 0/0 "GET / HTTP/1.1"

        ```

    - 故障测试，在tencentcloud中销毁一台cluster，查看 HAProxy controller 日志

        ```shell
        $kubectl logs haproxy-deployment-76556fc989-8mpkj -f
        [NOTICE]   (1) : New worker (9) forked
        [NOTICE]   (1) : Loading success.
        [NOTICE]   (9) : haproxy version is 2.9.0-fddb8c1
        [NOTICE]   (9) : path to executable is /usr/local/sbin/haproxy
        [WARNING]  (9) : [haproxy.main()] Failed to drop supplementary groups. Using 'gid'/'group' without 'uid'/'user' is generally useless.
        10.0.0.28:43296 [10/Dec/2023:08:58:06.601] http_front http_back/cluster2 0/0/1/4/5 200 1804 - - ---- 1/1/0/0/0 0/0 "GET / HTTP/1.1"
        ...
        10.0.0.28:35370 [10/Dec/2023:09:10:51.453] http_front http_back/cluster2 0/0/0/4/4 200 1804 - - ---- 4/4/0/0/0 0/0 "GET / HTTP/1.1"
        Server http_back/cluster2 is DOWN, reason: Layer4 timeout, check duration: 2001ms. 1 active and 0 backup servers left. 0 sessions active, 0 requeued, 0 remaining in queue.
        [WARNING]  (9) : Server http_back/cluster2 is DOWN, reason: Layer4 timeout, check duration: 2001ms. 1 active and 0 backup servers left. 0 sessions active, 0 requeued, 0 remaining in queue.
        10.0.0.28:60392 [10/Dec/2023:09:15:16.097] http_front http_back/cluster3 0/0/1/3/4 200 1804 - - ---- 1/1/0/0/0 0/0 "GET / HTTP/1.1"
        10.0.0.28:60394 [10/Dec/2023:09:15:16.225] http_front http_back/cluster3 0/0/1/3/4 200 1804 - - ---- 2/2/0/0/0 0/0 "GET / HTTP/1.1"
        10.0.0.28:60410 [10/Dec/2023:09:15:16.360] http_front http_back/cluster3 0/0/1/3/4 200 1804 - - ---- 3/3/0/0/0 0/0 "GET / HTTP/1.1"
        10.0.0.28:60392 [10/Dec/2023:09:15:16.492] http_front http_back/cluster3 0/0/0/4/4 200 1804 - - ---- 3/3/0/0/0 0/0 "GET / HTTP/1.1"
        10.0.0.28:60414 [10/Dec/2023:09:15:16.634] http_front http_back/cluster3 0/0/1/3/4 200 1804 - - ---- 4/4/0/0/0 0/0 "GET / HTTP/1.1"
        10.0.0.28:60410 [10/Dec/2023:09:15:16.771] http_front http_back/cluster3 0/0/0/4/4 200 1804 - - ---- 4/4/0/0/0 0/0 "GET / HTTP/1.1"
        10.0.0.28:60394 [10/Dec/2023:09:15:16.911] http_front http_back/cluster3 0/0/0/3/3 200 1804 - - ---- 4/4/0/0/0 0/0 "GET / HTTP/1.1"
        10.0.0.28:60410 [10/Dec/2023:09:15:17.069] http_front http_back/cluster3 0/0/0/4/4 200 1804 - - ---- 4/4/0/0/0 0/0 "GET / HTTP/1.1"
        10.0.0.28:60414 [10/Dec/2023:09:15:17.205] http_front http_back/cluster3 0/0/0/4/4 200 1804 - - ---- 4/4/0/0/0 0/0 "GET / HTTP/1.1"
        10.0.0.28:60410 [10/Dec/2023:09:15:17.340] http_front http_back/cluster3 0/0/0/4/4 200 1804 - - ---- 4/4/0/0/0 0/0 "GET / HTTP/1.1"
        ```

# devops 本地多环境多集群配置

# 截图展示
![tekton](image-3.png)

![tekton](image-4.png)

![argocd](image-5.png)

![argocd](image-7.png)

![argocd](image-8.png)

![argocd](image-9.png)

![argocd](image-6.png)


# 部署 Tekton

```bash
# 安装 Tekton Operator  等待安装完成才能部署 Trigger
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
# 安装 Tekton Dashboard
kubectl apply -f https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml
# 其他组件
# Tekton Trigger（触发器）
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
# Webhook Interceptors（事件处理器）
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml
```

# 部署ArgoCD
```bash
$ kubectl create namespace argocd 
$ kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# argoCD image updater
$ kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml
```
由于国内需要魔法，所以需要将对应的yaml文件中image地址替换下。

# 将国外镜像转入阿里云仓库

## 获取镜像
需要将xx.yaml下载下来，然后在yaml文件中查找到image镜像地址

## 国外镜像转存至阿里云仓库

```bash
# 1. 登陆香港服务器 172.31.140.44
# 2. 进入脚本目录
$ cd /opt/k8s/
# 3. 创建配置文件
$ touch tekton-releases.yaml
```

tekton-releases.yaml 文件
```yaml
images:
- up: "ubuntu" # 源镜像
  down: "registry.cn-beijing.aliyuncs.com/lgz_devops/ubuntu" # 需要转存到的地址
  tag: "23.04" # 源镜像版本
```

阿里云仓库权限如何获取？
```bash
# 不需要获取，在终端中进行登陆即可
$ docker login registry.cn-beijing.aliyuncs.com 
# 输入用户名密码，提示成功后即可
```

执行脚本
```bash
$ /opt/k8s/nerdtool -yaml_file tekton-releases.yaml # 漫长等待。期间的操作是 下载镜像-> 推送镜像 -> 删除本地镜像  
```

安装完成后，在自己集群中查看对应的软件服务是否已正常运行，如果出现问题查看对应pod的logs进行排查

## 添加harbor认证到secret 
``bash
cat << EOF > /tmp/docker-credentials.json
{
    "auths": {
        "test-harbor.xxx.com": {
            "username": "admin",
            "password": "Harbor12345",
            "auth": "YWRtaW46SGFyYm9yMTIzNDU="
        }
    }
}
EOF 

```

在k8s中生成认证
```bash
$ kubectl create secret generic docker-credentials --from-file=config.json=/tmp/docker-credentials.json --dry-run=client -o yaml | kubectl apply -f - # /tmp/docker-credentials.json 内容信息是上边生成的文件
```
argoCD image updater 配置
1. argoCD 的安装方式在安装部分已经有提及，这里不再描述。
2. 配置步骤
	1. 安装image updater 插件
	2. 给「定义仓库」访问权限，即设置 secret 

登陆页面
用户: admin
密码查看方式
```bash
# 登陆时，如何获取admin对应的密码？
$ kubectl get secret -n argocd argocd-initial-admin-secret -o yaml 
apiVersion: v1
data:
  password: V2w2YWJRb3REWm1MODdIUw== # 这个是base64的 需要解密，然后就可以使用了
kind: Secret
metadata:
  creationTimestamp: "2023-11-07T06:24:25Z"
  name: argocd-initial-admin-secret
  namespace: argocd
  resourceVersion: "33889"
  uid: 4c05e17f-1853-48ad-a2ba-c0675d5e5805
type: Opaque
```

添加Repositories有两种方式(应用定义仓库=app)
- 在argoCD UI中 点击settings-->Repositories手动输入相关数据
- 通过yaml进行配置
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: master-helm-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  url: https://golib.xxx.com/devops/master-helm.git
  password: "glpat-2qywcgouostR--dT8i9c" # 这个是gitlab master-helm仓库的token
  username: ligz
```

如何创建token？
先登陆地址：[master-helm](https://golib.xxx.com/devops/master-helm)
![](https://fiya.oss-cn-beijing.aliyuncs.com/oss-cn-beijingdevops-mcenter-helm-token-001.png)
查找到 「设置」->「访问令牌」并单击进入
![](https://fiya.oss-cn-beijing.aliyuncs.com/oss-cn-beijingdevops-mcenter-heml-token-002.png)
输入「令牌名称」-> 选择角色 -> 点击「创建项目访问令牌」会得到一串token

添加app
文件: `application.yaml`
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: vote-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://golib.xxx.com/devops/master-helm.git # 应用定义仓库
    targetRevision: HEAD
    path: demo-2
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: vote-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true # 自动创建命名空间
```

执行
```bash
$ kubectl apply -f application.yaml 
```
## 配置pv pvc用于测试
yaml文件

pv文件： hostpv.yaml
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: task-pv-volume
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/srv"
```

pvc文件: hostpvc.yaml
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: task-pv-claim
  labels:
    type: local
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
```


执行命令
```bash
$ kubectl apply -f hostpv.yaml
$ kubectl apply -f hostpvc.yaml
```

查看状态

```bash
$ kubectl get pv      
NAME           CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                  STORAGECLASS   REASON   AGE
task-pv-volume   10Gi       RWO            Retain           Bound    default/pipeline-pvc   manua                   36m

$ kubectl get pvc 
NAME           STATUS   VOLUME         CAPACITY   ACCESS MODES   STORAGECLASS   AGE
task-pv-volume   Bound    pipeline-pvc   10Gi       RWO            manua          37m
```

EventListener用途： 用于监听gitlab 代码提交时触发CI

操作步骤
- 在集群中起EventListener容器
- 将其映射到nodeport中(真实生产中请使用ingress方式)
- 将servce中的地址与端口写入至gitlab中

## 在集群中起EventListener容器

`github-trigger-template-local.yaml`

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerTemplate
metadata:
  name: github-template
spec:
  params:
    - name: git_url
    - name: commit_id
    - name: microservice
  resourcetemplates:
    - apiVersion: tekton.dev/v1
      kind: PipelineRun
      metadata:
        generateName: github-run-
      spec:
        taskRunSpecs:
          - pipelineTaskName: git-clone-t2
            serviceAccountName: build-master-code
        pipelineRef:
          name: github-pipeline-ex2
        workspaces:
          - name: output
            persistentVolumeClaim:
              claimName: task-pv-claim
            subPath: $(context.pipelineRun.uid)
          - name: docker-credentials
            secret:
              secretName: docker-credentials-admin
        params:
          - name: git_url
            value: $(tt.params.git_url) # 注意：$tt 开头，从 EventListener binding params 获取
          - name: microservice
            value: $(tt.params.microservice)
          - name: git_repository
            value: "mcenter"
          - name: commit_id
            value: $(tt.params.commit_id)
          - name: registry_url
            value: "test-harbor.xxx.com"

```

`github-event-listener-local.yaml`

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: EventListener
metadata:
  name: github-listener
spec:
  serviceAccountName: tekton-triggers
  triggers:
    - name: github-push-events-trigger-result
      interceptors:
        - ref:
            name: "gitlab"
          params:
            - name: "eventTypes"
              value: ["Push Hook"]
      bindings:
        - name: git_url
          value: $(body.project.git_http_url)
        - name: commit_id
          value: main-$(body.after)
        - name: microservice
          value: "mcenter"
      template:
        ref: github-template
```

配置pipeline
`pipeline-local.yaml`
```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: github-pipeline-ex2
spec:
  workspaces:
    - name: output
    - name: docker-credentials
  params:
    - name: git_url
    - name: git_repository
      default: "mcenter"
    - name: microservice
      default: "result"
    - name: registry_url
      default: ""
    - name: commit_id
      default: "latest"
  tasks:
    # task 1: git-clone
    - name: git-clone-t2
      taskRef:
        name: git-clone-t2
      workspaces:
        - name: output
          workspace: output
      params:
        - name: url
          # 指向 pipeline 定义的 git_url 参数
          value: $(params.git_url)
    # task 2: build image with kaniko
    - name: kaniko
      taskRef:
        name: kaniko
      runAfter:
        - git-clone-t2
      workspaces:
        - name: source
          workspace: output
        - name: dockerconfig
          workspace: docker-credentials
      params:
        - name: IMAGE
          value: $(params.registry_url)/$(params.git_repository)/$(params.microservice):$(params.commit_id)
        - name: EXTRA_ARGS
          value:
            - "--insecure"
```

执行

```bash
$ kubectl apply -f github-trigger-template-local.yaml # 生成调用模版
$ kubectl apply -f github-event-listener-local.yaml # 生成“监听器”
$ kubectl apply -f pipeline-local.yaml # 生成模版调用的pipeline流程
```

## 将其映射到nodeport

`nodeport-evelt-server.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: github-listener-nodeport
  labels:
    app.kubernetes.io/managed-by: EventListener
    app.kubernetes.io/part-of: Triggers
spec:
  type: NodePort      #这里代表是NodePort类型的
  ports:
    - port: 8080        #这里的端口和clusterIP对应，即ip:8080,供内部访问。
      name: web
      targetPort: 8080  #端口一定要和container暴露出来的端口对应
      protocol: TCP
    - port: 9000    
      targetPort: 9000
      protocol: TCP
      name: grpc
      # nodePort: 32143   # 所有的节点都会开放此端口，此端口供外部调用。
  selector:
    app.kubernetes.io/managed-by: EventListener          #这里选择器一定要选择容器的标签，之前写name:kube-node是错的。
    app.kubernetes.io/part-of: Triggers
```

执行
```bash
$ kubectl apply -f nodeport-evelt-server.yaml # 目的是为了让外部可以访问 用别的方式也是可以的
```

## 将servce中的地址与端口写入至gitlab中

查找到pod对应的地址和端口: `http://22.50.10.232:31099/`

[登陆gitlab](https://golib.xxx.com/)
查找需要发布的项目: [项目地址](https://golib.xxx.com/ops/mcenter)

设置webhook: 设置->webhook 点击webhook 如图：
![](https://fiya.oss-cn-beijing.aliyuncs.com/oss-cn-beijingdevops-mcenter-demo-webhook-001.png)

![](https://fiya.oss-cn-beijing.aliyuncs.com/oss-cn-beijingdevops-mcenter-demo-webhook-002.png)

启动ssl验证 --> 点击「保存」即可

1、git clone 使用pipline时一直提示没权限
解决： 尝试用taskrun是否能正常clone 如果可以，则说明大概率是 pv pvc的问题。 我遇到的问题就是pv引起的。

2、pipline build and push 提示没权限
```bash
# 错误
error checking push permissions -- make sure you entered the correct tag name, and that you are authenticated correctly, and try again: checking push permission for "[test-harbor.xxx.com/master:latest](http://test-harbor.xxx.com/master:latest)": POST [https://test-harbor.xxx.com/v2/master/blobs/uploads/:](https://test-harbor.xxx.com/v2/master/blobs/uploads/:) BAD_REQUEST: bad request: invalid repository name: master
```

解决： 之前一直关注前面的错误，其实主要看最后的报错输出是什么就行了。 因为对harbor的push推送格式忘记的差不多了，一直以为是没有权限推送，其实报错说明很明确了。就是告诉你你这个仓库无效。其实是仓库地址写错了而已。
仓库地址
```bash
test-harbor.xxx.com/mcenter/mcenter:latest # /mcenter/ 代表仓库内的目录 然后还的接一个仓库地址名。之前我这里少了个mcenter 然后一直纠结最前面的报错。忽略了最后的报错。
```

这个解决完成后 又出现一个 harobr push 无权限。 这时候需要检查下`name: docker-credentials`
了 
```bash
$ kubectl get secrets docker-credentials # yaml文件如下
```

认证配置

```bash
cat << EOF > /tmp/docker-credentials.json
{
    "auths": {
        "harbor.${prefix}.${domain}": {
            "username": "admin",
            "password": "Harbor12345",
            "auth": "YWRtaW46SGFyYm9yMTIzNDU="
        }
    }
}
EOF
kubectl create secret generic docker-credentials --from-file=config.json=/tmp/docker-credentials.json --dry-run=client -o yaml | kubectl apply -f -
```

auth格式
```bash
$ admin:Harbor12345 # 做base64 加密就等同于YWRtaW46SGFyYm9yMTIzNDU=
```
这样配置上后就可以了。

