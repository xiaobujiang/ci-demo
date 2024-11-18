// 使用split函数以斜杠为分隔符拆分字符串，并提取最后一个元素
def APP =  env.JOB_NAME.split('/').last().toLowerCase()

pipeline {
    agent {
        kubernetes {
            label "jnlp-slave-${UUID.randomUUID().toString().substring(0, 8)}"
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-slave
spec:
  volumes:
    - name: docker-socket
      emptyDir: {}
    - name: workspace-volume
      emptyDir: {}      
  serviceAccount: jenkins      
  containers:
    - name: jnlp
      image: docker.cloudimages.asia/jenkins/inbound-agent:latest 
    - name: tools  
      image: registry.cn-hangzhou.aliyuncs.com/s-ops/tools:latest
      command:
        - cat
      tty: true         
    - name: docker
      image: docker.cloudimages.asia/docker:latest
      env:
        - name: DOCKER_CLI_EXPERIMENTAL
          value: "enabled"  
      command:
      - sleep
      args:
      - 99d
      readinessProbe:
        exec:
          command: ["ls", "-S", "/var/run/docker.sock"]      
        initialDelaySeconds: 10  
      volumeMounts:
      - name: docker-socket
        mountPath: /var/run       
    - name: docker-daemon
      image: docker.cloudimages.asia/docker:19.03.1-dind
      securityContext:
        privileged: true
      volumeMounts:
      - name: docker-socket
        mountPath: /var/run
      - name: workspace-volume
        mountPath: /home/jenkins/agent
        readOnly: false               
"""
        }
    }
    environment {
        DOCKER_REGISTRY = "registry.cn-hangzhou.aliyuncs.com"
        REGISTRY_NAMEPSACE = "ci-demo"
        IMAGE = "${DOCKER_REGISTRY}/${REGISTRY_NAMEPSACE}"

    }

    options {
        //保持构建15天 最大保持构建的30个 发布包保留15天
        buildDiscarder logRotator(artifactDaysToKeepStr: '15', artifactNumToKeepStr: '', daysToKeepStr: '15', numToKeepStr: '30')
        //时间模块
        timestamps()
        //超时时间
        timeout(time:60, unit:'MINUTES')
        //跳过默认设置的代码check out
        skipDefaultCheckout true
    }


    stages {
        stage('build image tag') {
            steps {
                container('tools') {
                    script {
                        env.TIMESTAMP = sh(script: "date +%Y%m%d%H%M-%S", returnStdout: true).trim()
                         sh """
                            echo TAG: ${BUILD_ID}-${TIMESTAMP}
                          """
                    }         
                }
            }
        }

        stage('build image') {
            steps {
                container('docker') {
                    withCredentials([[$class: 'UsernamePasswordMultiBinding',
                        credentialsId: 'docker-auth',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASSWORD']]) {
                          script {
                            sh """
                            cd ci-demo
                            echo "开启多架构编译"
                            docker buildx create --name mybuilder --use --driver docker-container --driver-opt image=registry.cn-hangzhou.aliyuncs.com/s-ops/buildkit:buildx-stable-1

                            echo "登陆仓库"
                            docker login ${DOCKER_REGISTRY} -u ${DOCKER_USER} -p ${DOCKER_PASSWORD}

                            echo "构建/推送镜像"
                            docker buildx build --progress=plain --no-cache --platform=linux/amd64,linux/arm64 -t ${IMAGE}/${APP}:${BUILD_ID}-${TIMESTAMP} . --push

                            """
                        }
                    }    
                }
            }
        }   
    }
}
