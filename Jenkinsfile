pipeline {
    agent any
    options {
        buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '10'))
        disableConcurrentBuilds()
    }
    triggers {
        pollSCM('* * * * *')
    }
    stages {
        stage('GitSCM checkout') {
            steps { 
                  checkout([$class: 'GitSCM', branches: [[name: '*/main']], 
                    userRemoteConfigs: [[url: 'https://github.com/EpicMandM/gogs.git']]])
            }
        }
        stage('Clean previous') {
            steps {
                sshPublisher(
                        publishers: [
                            sshPublisherDesc(
                                configName: "vm", 
                                verbose: true,
                                transfers: [
                                    sshTransfer(
                                        execCommand: "cd ~/gogs_deploy && docker-compose down && rm -rf ~/gogs_deploy"
                                    )
                                ]
                            )
                        ]
                    )
            }
        }
        stage('Build & Deploy') {
            steps {
                    sshPublisher(
                        publishers: [
                            sshPublisherDesc(
                                configName: "vm", 
                                verbose: true,
                                transfers: [
                                    sshTransfer(
                                        execCommand: "git clone -b main --single-branch git@github.com:EpicMandM/gogs_compose.git ./gogs_deploy && cd ~/gogs_compose/deploy && docker-compose up"
                                    )
                                ]
                            )
                        ]
                    )
                }
            }
        }
    }
