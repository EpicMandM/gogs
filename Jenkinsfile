pipeline {
    agent {
        kubernetes {
            yaml """
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: golang
                    image: golang:1.20-bookworm
                    command: ["sleep"]
                    args: ["30d"]
                    env:
                      - name: CGO_CFLAGS
                        value: "-g -O2 -Wno-return-local-addr"
                  - name: kaniko
                    image: gcr.io/kaniko-project/executor:debug
                    command: ["/busybox/cat"]
                    tty: true
                    volumeMounts:
                      - name: kaniko-secret
                        mountPath: /kaniko/.docker
                      - name: dockerfile-storage
                        mountPath: /workspace
                  restartPolicy: Never
                  volumes:
                  - name: kaniko-secret
                    secret:
                      secretName: dockercred
                      items:
                      - key: .dockerconfigjson
                        path: config.json
                  - name: dockerfile-storage
                    persistentVolumeClaim:
                      claimName: dockerfile-claim
            """
        }
    }
    stages {
        
        stage('Build') {
            steps {
                container('golang') {
                    sh 'go build -o gogs -buildvcs=false'
                }
            }
        }
        
        stage('Test') {
            steps {
                container('golang') {
                    sh 'go test -v -cover ./...'
                }
            }
        }
        
        stage('Dockerfile Build & Push Image') {
            steps {
                container('kaniko') {
                    script {
                        sh '''
                        /kaniko/executor --dockerfile $(pwd)/Dockerfile \
                                         --context $(pwd) \
                                         --destination=epicmandm/gogs:latest
                        '''
                    }
                }
            }
        }
        // Uncomment and modify this stage as needed for your deployment
        // stage('Deploy to K8S') {     
        //     steps {
        //         sh 'kubectl delete deployment gogs'
        //         sh 'kubectl apply -f gogs-deployment.yaml -n default'
        //     }
        // }
    }
}
