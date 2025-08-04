pipeline {
    agent any

    environment {
        KUBECONFIG = "/var/lib/jenkins/.kube/config"  // Path to kubeconfig for EKS
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds')
        AWS_DEFAULT_REGION = "ap-south-1"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/kalaiyarasi1511/Trend'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh '''
                    docker build -t ${DOCKERHUB_CREDENTIALS_USR}/trend-app:latest .
                    '''
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                script {
                    sh '''
                    echo ${DOCKERHUB_CREDENTIALS_PSW} | docker login -u ${DOCKERHUB_CREDENTIALS_USR} --password-stdin
                    docker push ${DOCKERHUB_CREDENTIALS_USR}/trend-app:latest
                    '''
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    sh '''
                    kubectl get nodes
                    kubectl apply -f k8s-deployment.yaml
                    kubectl apply -f k8s-service.yaml
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline completed."
        }
        failure {
            echo "Pipeline failed!"
        }
        success {
            echo "Pipeline executed successfully!"
        }
    }
}
