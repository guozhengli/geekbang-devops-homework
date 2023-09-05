# 1: 请按照 Demo 做一遍实验，并提出一些改进建议，如果没办法完成所有 Demo，可以根据你体验到的 Demo 提出一些改进建议。

已操作的demo
1. 进入gitlab中camp-go-example项目dev分支，然后修改ui目录中的文件 添加一些内容来模拟开发，提交后 观察jenkins，argo会有相应的构建动作,最终会被发布到argo dev中
2. 将dev分支 PR到main，会在jenkins Merge Requests中进行执行pipline任务，然后提交到argo main中
3. 将camp-go-example/cmd/podinfo/main.go 代码复制一份达到重复率高的实验，然后提交。 观察jenkins会在pipline构建中失败。
4. 将camp-go-example/Dockerfile 文件中 FROM alpine:3.17 改为 FROM golang:1.16-alpine 或者安全性比较低的低版本来模拟pipline中安全检查的实验。然后提交。观察jenkins会在pipline中失败
5. 将harbor的镜像pull到本地，然后tag 重新命名下，在push到harbor。在此过程前需要 git login xxx.uk 登陆,此时登陆harbor查看会有个签名失败的镜像，次镜像就是刚才push上去的镜像
6. camp-go-example-helm/charts/env 中创建一个testing目录，并将dev下的文件copy到testing目录中来模拟创建新分支的测试需求。 然后在项目中创建testing分支。最终会看到argo中会多一个testing的
7. hey -n 10000 http://dev.podinfo.local/status/200 来模拟弹性伸缩，我这里失败了。执行后并没有弹性伸缩。查看无压力！ 

疑惑点
1. argo可以进行分组吗？ 比如按项目分组存放不同环境 或者按环境分组 存放不同项目
2. pr时为什么没有merge时就进行构建呢？ 合并前已经发版测试过了但再次merge前提交PR再次进行构建，不是很理解。我在测试时一次特意提交PR 然后紧跟着merge了，也会进行构建main但没有呗触发dev的构建
3. camp-go-example-helm是一个项目创建一个吗？这样如果项目很多时是否很麻烦？有没有支持通用方式 通用的调用同一个 不通用的在按这种方式？
4. 在dev进行sonar时，发现跳转到sonar后只有main一个分支，而且还是不可选的状态。这种是否可以更改呢？还是只能基于main进行检测？


# 2: 请你思考敏捷开发中的“迭代”、“用户故事”和“任务”有哪些区别？

> 我的想法：
>   迭代是周期性的，一个项目成立后，会进行拆分，然后按照周期性进行研发
>   而用户故事则是需求，以通俗易懂的方式叙述需求。可以将整个项目以用户故事方式进行拆分，然后迭代
>   任务则是用户故事的具体实现了。

# 3: DevOps 工作流中如何避免“配置漂移”的问题（基础设施和应用配置）

> 我的想法：
>   建立一个配置中心，将配置都由配置中心来进行管理。这样就可以避免配置不一致的问题。
