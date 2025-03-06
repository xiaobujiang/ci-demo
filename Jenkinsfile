def APP =  env.JOB_NAME.split('/').last().toLowerCase()
def COMMITID = ""
def TIMESTAMP = ""
properties([
    parameters([
        string(
            name: 'APP',
            defaultValue: APP,
            description: '服务名称'
        ),
        reactiveChoice(
            choiceType: 'PT_SINGLE_SELECT', 
            description: '选择分支2', 
            filterLength: 0, 
            filterable: false, 
            name: 'BRANCH', 
            randomName: 'choice-parameter-${UUID.randomUUID().toString().substring(0, 4)}', 
            referencedParameters: 'APP', 
            script: groovyScript(
                fallbackScript: [
                    classpath: [], 
                    oldScript: '', 
                    sandbox: false, 
                    script: 'return [""]'
                ], 
                script: [
                    classpath: [], 
                    oldScript: '', 
                    sandbox: false, 
                    script:                     
'''def giturl = "https://github.com/yjiangi/ci-demo.git"                
def getTags = ("git ls-remote --heads ${giturl}").execute()
return getTags.text.readLines().collect { it.split()[1].replaceAll('refs/heads/', '') }.unique()
'''
                ]
            )
        )
    ])
])
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
      image: registry.cn-hangzhou.aliyuncs.com/s-ops/inbound-agent:latest
    - name: tools  
      image: registry.cn-hangzhou.aliyuncs.com/s-ops/tools:latest
      command:
        - cat
      tty: true         
    - name: docker
      image: registry.cn-hangzhou.aliyuncs.com/s-ops/docker:latest
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
      image: registry.cn-hangzhou.aliyuncs.com/s-ops/docker:19.03.1-dind
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
        REGISTRY_NAMEPSACE = "gitops-demo"
        IMAGE = "${DOCKER_REGISTRY}/${REGISTRY_NAMEPSACE}"
        GIT_URL = "git@github.com:yjiangi/${APP}.git"
    }
    options {
        //保持构建15天 最大保持构建的30个 发布包保留15天
        buildDiscarder logRotator(artifactDaysToKeepStr: '15', artifactNumToKeepStr: '', daysToKeepStr: '15', numToKeepStr: '30')
        //时间模块
        timestamps()
        //超时时间
        timeout(time:60, unit:'MINUTES')
    }

    stages {
       stage('pull code') {
            steps {                          
                echo '--------------------------拉取代码-----------------------'
                checkout([$class: 'GitSCM', branches: [[name: "${BRANCH}"]], 
                extensions: [], userRemoteConfigs: [[credentialsId: 'github-ci', 
                url: "${GIT_URL}"]]])
            }
        }           
        stage('commit'){
            steps{
              script{
                  COMMITID = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                  TIMESTAMP = sh(script: "date +%Y%m%d%H%M-%S", returnStdout: true).trim()
                  env.ImageTag = "${BUILD_ID}-${TIMESTAMP}-${COMMITID}"
                  env.AppName =  env.JOB_NAME.split('/').last().toLowerCase()
                  sh """
                  echo "仓库地址: ${GIT_URL}"
                  echo "服务分支: ${BRANCH}"
                  echo "分支id: ${COMMITID}"
                  echo "构建时间: ${TIMESTAMP}"
                  echo "镜像TAG: ${ImageTag}"
                  echo "服务名字: ${AppName}"
                  echo "服务名称: ${APP}"
                  """
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
                            
                            echo "开启多架构编译"
                            docker buildx create --name mybuilder --use --driver docker-container --driver-opt image=registry.cn-hangzhou.aliyuncs.com/s-ops/buildkit:buildx-stable-1

                            echo "登陆仓库"
                            docker login ${DOCKER_REGISTRY} -u ${DOCKER_USER} -p ${DOCKER_PASSWORD}

                            echo "构建/推送镜像"
                            docker buildx build --progress=plain --no-cache --platform=linux/amd64 -f Dockerfile -t ${IMAGE}/${AppName}:${ImageTag} . --push

                            """
                        }
                    }    
                }
            }
        }
      stage('change ImageTag') {
          steps {
                container('tools'){
                    script{
                      sh """
                       envsubst < ./values.tpl > helm/values.yaml
                       cat helm/values.yaml
                       helm template --debug  helm/  -f helm/values.yaml
                      """
                    }
                }
            }
        }
        stage('push yaml') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'github-ci', keyFileVariable: 'IDENTITY')]) {
                    script {
                      sh """
                        git config --global user.email "ci"
                        git config --global user.email "ci@ci.com"
                        git config core.sshCommand 'ssh -o StrictHostKeyChecking=no -i $IDENTITY'
                        git checkout main
                        git pull origin main
                        git add .
                        git commit -m "${AppName}-${ImageTag} " || true
                        git push origin main  
                        """
                    }    
                }
            }
        }       
    }
}
