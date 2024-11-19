appname: ${AppName}

service:
  port: 8080

replicaCount: 1

image:
  repository: ${IMAGE}/${AppName} 
  tag: ${ImageTag}
  pullPolicy: IfNotPresent

resources:
  limits:
    cpu: 50m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 128Mi
