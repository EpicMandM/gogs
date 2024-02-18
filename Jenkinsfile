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
                                        execCommand: "cd ~/gogs_compose/test && docker-compose down -v && cd .. && cd ~/gogs_compose/deploy && docker-compose down -v && cd ../../ && rm -rf ~/gogs_compose"
                                    )
                                ]
                            )
                        ]
                    )
            }
        }
        stage('Tests')
        {
            steps {
                sshPublisher(
                        publishers: [
                            sshPublisherDesc(
                                configName: "vm", 
                                verbose: true,
                                transfers: [
                                    sshTransfer(
                                        execCommand: "git clone git@github.com:EpicMandM/gogs_compose.git && cd ~/gogs_compose/test && docker-compose up"
                                    )
                                ]
                            )
                        ]
                    )
            }
        }
        stage('Clean tests') {
            steps {
                sshPublisher(
                        publishers: [
                            sshPublisherDesc(
                                configName: "vm", 
                                verbose: true,
                                transfers: [
                                    sshTransfer(
                                        execCommand: "cd ~/gogs_compose/test && docker-compose down -v && cd .. && cd ~/gogs_compose/deploy && docker-compose down -v && cd ../../ && rm -rf ~/gogs_compose"
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
                                        execCommand: "git clone git@github.com:EpicMandM/gogs_compose.git && cd ~/gogs_compose/deploy && docker-compose up -d"
                                    )
                                ]
                            )
                        ]
                    )
                }
            }
        }
    }
