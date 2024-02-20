def executeSSHCommand(String command) {
    sshPublisher(
        publishers: [
            sshPublisherDesc(
                configName: "vm", 
                verbose: true,
                transfers: [
                    sshTransfer(
                        execCommand: command
                    )
                ]
            )
        ]
    )
}

pipeline {
    agent any
    options {
        buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '10'))
        disableConcurrentBuilds()
    }
    stages {
        stage('Clean previous') {
            steps {
                executeSSHCommand("cd ~/gogs && docker-compose down -v && cd .. && rm -rf ~/gogs")
            }
        }
        stage('Tests, Build & Deploy') {
            steps {
                executeSSHCommand("git clone https://github.com/EpicMandM/gogs.git && cd ~/gogs && docker-compose up --detach && docker-compose logs --follow")
            }
        }
        }
    }
