pipeline {
    agent {
        kubernetes {
            yaml """
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: alpine
                    image: alpine:3.15
                    command:
                    - sleep
                    args:
                    - 30d
                  - name: kaniko
                    image: gcr.io/kaniko-project/executor:debug
                    command:
                    - /busybox/cat
                    tty: true
                    volumeMounts:
                      - name: kaniko-secret
                        mountPath: /kaniko/.docker
                  volumes:
                    - name: kaniko-secret
                      secret:
                        secretName: regc99dred
                        items:
                          - key: .dockerconfigjson
                            path: config.json
            """
        }
    }
    stages {

                stage('Install dependencies') {
            steps {
                container('alpine') {
                   
                }
            }
        }
        
        stage('Build') {
            steps {
                container('alpine') {
                    sh 'go build -o gogs -buildvcs=false'
                }
            }
        }
        
        stage('Test') {
            steps {
                container('alpine') {
                    sh 'go test -v -cover ./...'
                }
            }
        }
        
        stage('Dockerfile Build & Push Image') {
              steps {
                container('kaniko') {
                  script {
                    sh '''
                    /kaniko/executor --dockerfile `pwd`/Dockerfile_app \
                                     --context `pwd` \
                                     --destination=petrobubka/my_gogs_image:${BUILD_NUMBER}
                    '''
                  }
                }
              }
            }
        stage('Deploy to K8S') {     
              steps {
                    sh 'kubectl delete deployment gogs'
                    sh 'sed -i "s/<TAG>/${BUILD_NUMBER}/" gogs-deployment.yaml'
                    sh 'kubectl apply -f gogs-deployment.yaml -n default'
              }
            }
    }
}
