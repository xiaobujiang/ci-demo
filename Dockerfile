# 指定基础的go编译镜像
FROM registry.cn-hangzhou.aliyuncs.com/s-ops/golang:alpine3.17 as build

# 指定go的环境变量
ENV GOPROXY=https://goproxy.cn \
     GO111MODULE=on \
     CGO_ENABLED=0 \
     GOOS=linux

# 指定工作空间目录，会自动cd到这个目录
WORKDIR /opt

# 把项目的其他所有文件拷贝到容器中
COPY . .

# 编译成可执行二进制文件
RUN go build -o app .

FROM egistry.cn-hangzhou.aliyuncs.com/s-ops/alpine:latest as serviceDeploy

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories &&   apk update &&   apk upgrade &&   apk add ca-certificates && update-ca-certificates &&   apk add --update tzdata &&   rm -rf /var/cache/apk/*

ENV TZ=Asia/Shanghai

COPY --from=build /opt/app /
CMD ["/app"]
