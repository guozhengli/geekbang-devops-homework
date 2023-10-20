
harbor
```bash
cvm_password = "password123"
harbor_login_info = "Username: admin, Password: Harbor12345"
harbor_url = "https://harbor.lee101.devopscamp.us"
kube_config = "./config.yaml"
public_ip = "43.132.225.113"
```

jenkins
```bash
cvm_password = "password123"
harbor_url = "http://harbor.lee101.devopscamp.us, admin, Harbor12345"
jenkins_url = "http://jenkins.lee101.devopscamp.us, admin, password123"
kube_config = "./config.yaml"
public_ip = "101.32.216.173"
tekton_url = "http://tekton.lee101.devopscamp.us, (not ready yet)"
```

# 基础环境搭建

## 环境说明

1. 代码拉取地址： git@github.com:guozhengli/geekbang-devops-homework.git
2. 环境中用到的测试项目地址： https://github.com/guozhengli/vote-app.git

## harbor 搭建步骤

```bash
$ git clone  git@github.com:guozhengli/geekbang-devops-homework.git
$ cd geekbang-devops-homework/week-6/harbor-self-hosted
# 初始化harbor环境 需要安装 terraform 
$ terraform init # 初始化时需要科学上网，
$ terraform apply -auto-approve # 进行部署
# 部署完成后，输出信息如「harbor」
```

浏览器打开 https://harbor.lee101.devopscamp.us 进行登陆，登陆后创建项目「vote」

## jenkins 搭建步骤

```bash
$ cd geekbang-devops-homework/week-6/jenkins 
# 初始化jenkins 环境 需要安装 terraform 
$ terraform init # 初始化时需要科学上网，
$ terraform apply -auto-approve # 进行部署
# 部署完成后，输出信息如「jenkins」
```

将config.yaml 配置到本地。

![](https://fiya.oss-cn-beijing.aliyuncs.com/oss-cn-beijingdevops-001.png)

环境搭建完成

# 配置

## 环境配置

由于需要提交代码自动触发构建的需求，需要将  https://github.com/guozhengli/vote-app.git 用户token配置到 `jenkins/variables.tf`中
```bash
variable "prefix" {
  default = "lee101" 
}

variable "github_personal_token" {
  default = "xxxxxxxx" # 这里是你github或者gitlab的token
}
```

# 配置

### jenkins-构建流水线
1. 登陆jenkins http://jenkins.lee101.devopscamp.us/
2. 点击 「New Item」
3. 输入名字并选择「多分支流水线」
4. 点击「ok」保存

### jenkins-github设置
1. 点击左侧的「Manage Jenkins」
2. 选择「system」
3. 找到github Server
	1. 起名，随意
	2. 设置api url https://api.github.com
	3. 选择凭据
4. 保存

### github-webhook配置
1. 浏览器访问项目https://github.com/guozhengli/vote-app
2. 点击「Settings」
3. 点击左侧栏的「Webhooks」
4. 点击「add webhook」按钮
5. 输入验证
6. Payload URL： http://jenkins.lee101.devopscamp.us/github-webhook/
	1. 地址是从jenkins/Manage Jenkins/system/github下有个覆盖hook url
	2. 勾选「覆盖hook url」就会看到这个地址
7. Content type：选择application/json
8. 保存
9. 查看deliveries是否有ping通过的，通过的则代表配置完成

# 执行步骤

## 项目配置

## Jenkinsfile-auto配置

```pipline
pipeline {
    agent any
    stages{
        stage('Create multibranchPipelineJob'){
            steps{
                script{
                    def files = findFiles(glob: ' **/Jenkinsfile')
                    for (int i = 1; i < files.size(); i++) {
                        echo files[i].name
                        def filePath = files[i].path
                        def pathWithoutFile = filePath.replace('/Jenkinsfile', '')
                        def jobName = "auto-generated-" + ( pathWithoutFile =~ /([^\/]+)\/?$/)[0][0]
                        echo filePath
                        echo jobName
                        if(Jenkins.instance.getItemMap()[jobName] == null){
                            echo "Job ${jobName} does not exist, creating..."
                            createJob(filePath, jobName)
                        }else{
                            echo "Job ${jobName} already exists."
                        }
                    }
                }
            }
        }

    }
}

def createJob(filePath, jobName){
        jobDsl  targets: '*.groovy',
        removedJobAction: 'IGNORE',
        removedViewAction: 'IGNORE',
        lookupStrategy: 'JENKINS_ROOT',
        additionalParameters: [jenkinsfile: filePath, Name: jobName]
}
```

## pipelineCreator.groovy配置

```pipline
// get all DSL config http://jenkins.wangwei.devopscamp.us/plugin/job-dsl/api-viewer/index.html
multibranchPipelineJob("${Name}") {
    branchSources {
        branchSource {
            source {
                github {
                    id('github')
                    repoOwner("devops-advanced-camp")
                    configuredByUrl(false)
                    repository("vote")
                    repositoryUrl("https://github.com/devops-advanced-camp/vote.git")
                    credentialsId('github-pull-secret')

                    traits {
                        gitHubBranchDiscovery {
                            strategyId(1)
                        }
                        gitHubPullRequestDiscovery {
                            strategyId(2)
                        }
                    }
                }
            }
        }
        factory {
            workflowBranchProjectFactory {
                scriptPath("${jenkinsfile}")
            }
        }
    }
}
```

将项目 提交后，等待jenkins触发。

首次触发会报错，错误时
需要apply下 点下那个按钮就行了 需要执行3次 点3次

路径： dashboard/manage jenkins/in-process Script Approval 这里面
点击进去后 点击按钮 Approve 就可以了

# 疑问🤔

如果大仓方式，我们是按照某个业务线来配置的时候， 会出现新业务现时就得这么配置一次。就🉐`dashboard/manage jenkins/in-process Script Approval ` apply一次，如何来解决这个问题呢？
