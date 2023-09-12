# 1: 请将以下 golang 代码构建为镜像，要求在能运行的情况下尽镜像体积尽可能小，上传你的 dockerfile 文件内容。

```go
package main

import "fmt"

func main() {
    fmt.Println("hello world")
}


```

> 第一题在目录1/中

```bsh
$ docker build -t t1:v1 -f Dockerfile .
$ docker build -t t1:v2 -f Dockerfile2 .

docker images 输出：
t1                                v2            7debe1811f36   5 seconds ago   126MB # 多层构建之后
t1                                v1            483f3996c1a2   5 minutes ago   943MB # 多层构建之前
```

# 2: 请为下面的代码构建多平台镜像，要求同时构建 amd64 和 arm64 的镜像，并推送到镜像仓库中。

```go

package main

import "fmt"

func main() {
	fmt.Println("hello world")
}

```

> 第二题

执行代码 

```bash

docker buildx create --use  --platform=linux/amd64,linux/arm64
docker buildx build -t test-harbor.xxxxxx.com/ops/lee100:v1 -f Dockerfile . --push

```

在执行过程中，直接执行第二题命令时报错，报错建议里需要执行create --use 本身不支持跨平台构建。
构建后顺利构建并推送到仓库
