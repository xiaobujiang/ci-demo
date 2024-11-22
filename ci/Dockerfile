# 基于 Alpine 最新版本构建tools容器镜像
FROM docker.cloudimages.asia/alpine:latest

# 安装kubectl helm yq envsubst
RUN sed -i 's|dl-cdn.alpinelinux.org|mirrors.ustc.edu.cn|g' /etc/apk/repositories && \
    apk update && apk upgrade && \
    apk add --no-cache \
        ca-certificates \
        tzdata \
        helm \
        kubectl \
        yq \
        bash \
        vim \
        gettext && \
    update-ca-certificates && \
    rm -rf /var/cache/apk/*
ENV TZ=Asia/Shanghai
