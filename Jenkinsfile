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
        DOCKER_REGISTRY_CREDENTIALS_ID = "dockerhub-tdksoft-credentials" // ID de la credential Docker Hub dans Jenkins

        KUBERNETES_KUBECONFIG_ID = "kubeconfig-prod" // ID de la credential Secret File pour kubeconfig
        KUBERNETES_CONTEXT = "my-kubernetes-context" // Remplace par le nom de ton contexte Kubernetes (ex: minikube)
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

                    // Utilisation de `withCredentials` pour gérer le Kubeconfig de manière sécurisée
                    // Le KUBERNETES_KUBECONFIG_ID est déjà défini dans l'environnement du pipeline, on l'utilise ici
                    withCredentials([file(credentialsId: env.KUBERNETES_KUBECONFIG_ID, variable: 'KUBECONFIG_FILE')]) {
                        sh """
                            echo "Configuration du Kubeconfig..."
                            # Créer le répertoire .kube s'il n'existe pas
                            mkdir -p ~/.kube
                            # Copier le fichier Kubeconfig fourni par Jenkins dans le bon emplacement
                            cp "${KUBECONFIG_FILE}" ~/.kube/config
                            echo "Kubeconfig configuré."
                            # Sélectionner le bon contexte Kubernetes
                            kubectl config use-context "${env.KUBERNETES_CONTEXT}"
                        """
                        // Exécuter la commande Helm
                        // --install : installe si la release n'existe pas, met à jour sinon
                        // --wait : attend que toutes les ressources soient dans un état prêt avant de considérer le déploiement comme réussi
                        sh """
                            helm upgrade --install my-python-app "${env.HELM_CHART_PATH}" \\
                                --set image.repository="${env.DOCKER_IMAGE_NAME}" \\
                                --set image.tag="${env.IMAGE_TAG_FOR_DEPLOY}" \\
                                --wait
                        """
                    } // Fin de withCredentials pour Kubeconfig

                    echo "Déploiement Helm terminé."
                }
            }
        }

        stage('Run Helm Tests (Optional)') {
            steps {
                script {
                    echo "Running Helm tests..."
                    // Utilisation de withCredentials pour Kubeconfig ici aussi
                    withCredentials([file(credentialsId: env.KUBERNETES_KUBECONFIG_ID, variable: 'KUBECONFIG_FILE')]) {
                        sh "export KUBECONFIG=${KUBECONFIG_FILE}"
                        sh "kubectl config use-context ${env.KUBERNETES_CONTEXT}"
                        sh "helm test my-python-app" // 'my-python-app' est le nom de ta release Helm
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