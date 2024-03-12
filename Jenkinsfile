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
                    volumeMounts:
                      - name: workspace-volume
                        mountPath: /workspace
                  - name: kaniko
                    image: gcr.io/kaniko-project/executor:debug
                    command: ["/busybox/cat"]
                    tty: true
                    volumeMounts:
                      - name: workspace-volume
                        mountPath: /workspace
                      - name: kaniko-secret
                        mountPath: /kaniko/.docker
                  restartPolicy: Never
                  volumes:
                  - name: workspace-volume
                    emptyDir: {}
                  - name: kaniko-secret
                    secret:
                      secretName: dockercred
                      items:
                      - key: .dockerconfigjson
                        path: config.json
            """
        }
    }
    stages {
        stage('Prepare kubectl') {
            steps {
                sh 'curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"'
                sh 'chmod +x kubectl'
                sh 'mkdir -p ~/.local/bin'
                sh 'mv ./kubectl ~/.local/bin/kubectl'
                environment {
                    PATH = "$PATH:~/.local/bin"
                }
            }
        }
        stage('Clone Repository') {
            steps {
                container('golang') {
                    sh 'git clone https://github.com/EpicMandM/gogs.git /workspace/gogs'
                }
            }
        }

        stage('Build') {
            steps {
                container('golang') {
                    sh 'cd /workspace/gogs && go build -o gogs -buildvcs=false'
                }
            }
        }

        stage('Test') {
            steps {
                container('golang') {
                    sh 'cd /workspace/gogs && go test -v -cover ./...'
                }
            }
        }

        stage('Dockerfile Build & Push Image') {
            steps {
                container('kaniko') {
                    script {
                        sh '''
                        cd /workspace/gogs
                        /kaniko/executor --dockerfile `pwd`/Dockerfile \
                                         --context `pwd` \
                                         --destination=epicmandm/gogs:latest
                        '''
                    }
                }
            }
        }
        stage('Deploy to K8S') {     
            steps {
                sh 'kubectl apply -f ./kuber/gogs-deployment-service.yaml -n default'
            }
        }
    }
}
