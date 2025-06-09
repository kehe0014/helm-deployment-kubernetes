// Jenkinsfile

pipeline {
    agent any // Or a specific agent label if you have one, e.g., { label 'docker-builder' }

    environment {
        // Define your Docker image details
        DOCKER_ID = "tdksoft" 
        IMAGE_NAME = "${DOCKER_ID}/my-python-api"

        // Dynamically get the short Git commit SHA for the image tag
        // This is a common way to version images in CI/CD
        IMAGE_TAG = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()

        // Path to your application's Dockerfile and source code relative to the Jenkins workspace root
        APP_SOURCE_DIR = 'helm-deployment-kubernetes' 
        
        // Path to your Helm chart directory relative to the Jenkins workspace root
        HELM_CHART_PATH = 'helm-deployment-kubernetes/helm'

        // Helm release name
        HELM_RELEASE_NAME = 'my-python-app'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                // Ensure your SCM (e.g., Git) is checked out at the beginning
                // If this Jenkinsfile is in your Git repo, this is usually automatic.
                // Otherwise, add a 'checkout scm' step here.
                echo "Checking out Git repository..."
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Navigate to the directory containing your Dockerfile
                    dir("${APP_SOURCE_DIR}") {
                        echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
                        // Using 'docker build' directly for clarity and common practice in CI/CD
                        sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    echo "Pushing Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
                    // Login to Docker Hub using environment variables
                    sh """
                        docker login -u ${env.DOCKER_HUB_USER} -p ${env.DOCKER_PASS}
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
            
        }
        
        environment {
            // Assuming 'config' is the ID of your Jenkins credential containing the kubeconfig file
            KUBECONFIG = credentials('config')  // Jenkins will expose this as a temporary file path
        }

        stage('Deploy to Kubernetes with Helm') {
            steps {
                script {
                    echo "Deploying Helm chart: ${HELM_CHART_PATH} with image ${IMAGE_NAME}:${IMAGE_TAG}"
                    
                    sh """
                        # Verify cluster access (optional)
                        kubectl cluster-info
                        
                        # Helm deployment
                        helm upgrade --install ${HELM_RELEASE_NAME} ${HELM_CHART_PATH} \\
                        #  --namespace ${NAMESPACE} \\  # Always specify namespace
                          --set image.repository=${IMAGE_NAME} \\
                          --set image.tag=${IMAGE_TAG} \\
                          --set serviceAccount.create=true \\
                          --wait \\
                          --timeout 5m
                    """
                }
            }
        }
        // Optional: Post-deployment smoke tests or verification
        stage('Verify Deployment') {
            steps {
                script {
                    echo "Verifying deployment..."
                    // Example: wait for a pod to be ready and then run a simple curl to the service
                    sh "kubectl rollout status deployment/${HELM_RELEASE_NAME}-my-api-chart --timeout=120s"
                    // Add more checks if needed, e.g.:
                    // sh "kubectl exec deployment/${HELM_RELEASE_NAME}-my-api-chart -- curl -s http://localhost:5000/health"
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished."
        }
        success {
            echo "Pipeline successful!"
            // Add Slack notification or other success actions
        }
        failure {
            echo "Pipeline failed!"
            // Add Slack notification or other failure actions
        }
        // clean up workspace
        // cleanWs()
    }
}