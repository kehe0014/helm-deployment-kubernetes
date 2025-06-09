pipeline {
    agent any

    environment {
        DOCKER_ID = "tdksoft"
        IMAGE_NAME = "${DOCKER_ID}/my-python-api"
        IMAGE_TAG = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
        APP_SOURCE_DIR = 'helm-deployment-kubernetes'
        HELM_CHART_PATH = 'helm-deployment-kubernetes/helm'
        HELM_RELEASE_NAME = 'my-python-app'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                echo "Checking out Git repository..."
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Remove the 'dir' block
                    echo "Building Docker image: tdksoft/my-python-api:${env.BUILD_NUMBER}"
                    // For debugging, you can keep these initially to confirm
                    sh 'pwd'
                    sh 'ls -R'
                    // Now, docker build will execute from the workspace root
                    sh "docker build -t tdksoft/my-python-api:${env.BUILD_NUMBER} ."
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                script {
                    echo "Pushing Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
                    sh """
                        docker login -u ${env.DOCKER_HUB_USER} -p ${env.DOCKER_PASS}
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy to Kubernetes with Helm') {
            environment {
                KUBECONFIG = credentials('config')
            }
            steps {
                script {
                    echo "Deploying Helm chart: ${HELM_CHART_PATH} with image ${IMAGE_NAME}:${IMAGE_TAG}"
                    sh """
                        # Verify cluster access (optional)
                        kubectl cluster-info

                        # Helm deployment
                        helm upgrade --install ${HELM_RELEASE_NAME} ${HELM_CHART_PATH} \\
                          --namespace ${NAMESPACE} \\  # Uncomment when NAMESPACE is defined
                          --set image.repository=${IMAGE_NAME} \\
                          --set image.tag=${IMAGE_TAG} \\
                          --set serviceAccount.create=true \\
                          --wait \\
                          --timeout 5m
                    """
                }
            }
        }

        // Optional: Uncomment when ready to use
        /*
        stage('Verify Deployment') {
            steps {
                script {
                    echo "Verifying deployment..."
                    sh "kubectl rollout status deployment/${HELM_RELEASE_NAME}-my-api-chart --timeout=120s"
                }
            }
        }
        */
    }

    post {
        always {
            echo "Pipeline finished."
        }
        success {
            echo "Pipeline successful!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}