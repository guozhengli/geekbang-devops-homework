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
