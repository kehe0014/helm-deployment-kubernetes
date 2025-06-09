// Jenkinsfile pour déployer une API Python avec Docker et Helm sur Kubernetes
// Ce pipeline Jenkins construit une image Docker, la pousse vers Docker Hub, et déploie l'application sur Kubernetes en utilisant Helm.
// Assurez-vous que Jenkins a les plugins nécessaires : Docker, Kubernetes, Helm, Git, et Pipeline.
// Assurez-vous également que les credentials Docker Hub et kubeconfig sont configurés dans Jenkins.
// Remplacez les valeurs des variables d'environnement par celles de votre projet.
// Ce pipeline est conçu pour être utilisé avec Jenkins Pipeline (Jenkinsfile) et nécessite que Jenkins soit configuré avec les plugins nécessaires.
// Assurez-vous que Jenkins a accès à Docker et Kubernetes, et que les credentials sont correctement configurés.
// Ce pipeline est un exemple de base et peut être adapté selon vos besoins spécifiques.
pipeline {
    agent any // Ou un agent spécifique comme 'agent { label 'docker-host' }' si tu as des runners Jenkins spécifiques

    environment {
        DOCKER_ID = "tdksoft"
        DOCKER_IMAGE_NAME = "${DOCKER_ID}/my-python-api" // Ton compte Docker Hub et le nom de l'image
        DOCKER_TAG = "v.${BUILD_ID}.0"
    

        KUBERNETES_KUBECONFIG_ID = "config" // ID de la credential Secret File pour kubeconfig
        KUBERNETES_CONTEXT = "default" 
        HELM_CHART_PATH = "helm" // Le chemin vers ton Helm Chart
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/kehe0014/helm-deployment-kubernetes.git'
            }
        }

        stage('Build Docker Image') {
            environment {
                DOCKER_PASS = credentials("DOCKER_HUB_PASS") // On récupère le mot de passe Docker Hub depuis les credentials Jenkins
            }
            steps {
                script {
                    def dockerImageTag = "${env.DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER}"
                    echo "Building Docker image: ${dockerImageTag}"
                    sh """
                        docker login -u $DOCKER_ID -p $DOCKER_PASS
                        docker build -t ${dockerImageTag} .
                        docker tag ${dockerImageTag} ${env.DOCKER_IMAGE_NAME}:latest
                    """
                    env.IMAGE_TAG_FOR_DEPLOY = env.BUILD_NUMBER
                }
            }
        }
        stage('Push Docker Image to Docker Hub') {
            environment {
                DOCKER_PASS = credentials("DOCKER_HUB_PASS") // On récupère le mot de passe Docker Hub depuis les credentials Jenkins
            }
            steps {
                script {
                    echo "Pushing Docker image to Docker Hub..."
                    sh """
                        docker push ${env.DOCKER_IMAGE_NAME}:${env.IMAGE_TAG_FOR_DEPLOY}
                        docker push ${env.DOCKER_IMAGE_NAME}:latest
                    """
                }
            }
        }
        
        stage('Deploy to Kubernetes with Helm') {
            steps {
                script {
                    echo "Déploiement vers Kubernetes avec Helm..."
                    
                    withCredentials([file(credentialsId: env.KUBERNETES_KUBECONFIG_ID, variable: 'KUBECONFIG_FILE')]) {
                        // Verify cluster access first
                        sh """
                            export KUBECONFIG=${KUBECONFIG_FILE}
                            kubectl config use-context ${env.KUBERNETES_CONTEXT}
                            kubectl cluster-info
                        """
                        
                        // Deploy with Helm
                        sh """
                            export KUBECONFIG=${KUBECONFIG_FILE}
                            helm upgrade --install my-python-app ${env.HELM_CHART_PATH} \\
                                --set image.repository=${env.DOCKER_IMAGE_NAME} \\
                                --set image.tag=${env.IMAGE_TAG_FOR_DEPLOY} \\
                                --wait \\
                                --timeout 300s \\
                                --debug
                        """
                        
                        // Verify deployment
                        sh """
                            kubectl rollout status deployment/my-python-app --timeout=120s
                            kubectl get pods -l app.kubernetes.io/name=my-python-app
                        """
                    }
                }
            }
        }

        stage('Run Helm Tests (Optional)') {
            steps {
                script {
                    echo "Running Helm tests..."
                    withCredentials([file(credentialsId: env.KUBERNETES_KUBECONFIG_ID, variable: 'KUBECONFIG_FILE')]) {
                        sh """
                            # Définir KUBECONFIG pour pointer vers le fichier temporaire
                            export KUBECONFIG=${KUBECONFIG_FILE}
                            kubectl config use-context ${env.KUBERNETES_CONTEXT}
                            helm test my-python-app
                        """
                    }
                    echo "Helm tests finished."
                }
            }
        }
    } // Fin des stages

    post { // La section 'post' doit être un enfant direct du bloc 'pipeline'
        always {
            echo "Pipeline finished."
        }
        failure {
            echo "Pipeline failed! Check logs for details."
        }
        success {
            echo "Pipeline succeeded!"
        }
        unstable {
            echo "Pipeline completed with warnings."
        }
        cleanup {
            echo "Cleaning up resources..."
            // Ici, tu peux ajouter des étapes de nettoyage si nécessaire, comme supprimer des images Docker temporaires ou des ressources Kubernetes.
        }
    } // Fin du post
} // Fin du pipeline