pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds') // Jenkins credentials ID
        DOCKER_IMAGE = "kalaiyarasi15/trend-app:latest"
        KUBECONFIG_CREDENTIALS = credentials('eks-kubeconfig') // Jenkins kubeconfig secret
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/kalaiyarasi1511/Trend.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker build -t $DOCKER_IMAGE .'
                }
            }
        }

        stage('Push Docker Image to DockerHub') {
            steps {
                script {
                    sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                    sh 'docker push $DOCKER_IMAGE'
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    // Write kubeconfig to file
                    writeFile file: 'kubeconfig', text: KUBECONFIG_CREDENTIALS
                    withEnv(["KUBECONFIG=${WORKSPACE}/kubeconfig"]) {
                        sh 'kubectl apply -f deployment.yml'
                    }
                }
            }
        }
    }
}
