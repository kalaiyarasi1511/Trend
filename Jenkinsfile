pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "your-dockerhub-username/trend-app"
        DOCKER_TAG = "latest"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    credentialsId: 'dockerhub-creds',  // GitHub creds if private repo
                    url: 'https://github.com/kalaiyarasi1511/Trend'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                    docker build -t $DOCKER_IMAGE:$DOCKER_TAG .
                    """
                }
            }
        }

        stage('Push Docker Image to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    docker push $DOCKER_IMAGE:$DOCKER_TAG
                    """
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                withCredentials([file(credentialsId: 'eks-kubeconfig', variable: 'KUBECONFIG')]) {
                    sh """
                    kubectl get nodes
                    kubectl apply -f k8s-deployment.yml
                    kubectl apply -f k8s-service.yml
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline executed successfully!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
