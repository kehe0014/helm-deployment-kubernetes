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
        DOCKER_IMAGE_NAME = "tdksoft/my-python-api" // Ton compte Docker Hub et le nom de l'image
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
            steps {
                script {
                    def dockerImageTag = "${env.DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER}" // Utilise le numéro de build Jenkins comme tag
                    echo "Building Docker image: ${dockerImageTag}"

                    // Login à Docker Hub
                    withCredentials([usernamePassword(credentialsId: env.DOCKER_REGISTRY_CREDENTIALS_ID, passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh "docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}"
                    }

                    // Construire l'image en utilisant le Dockerfile
                    sh "docker build -t ${dockerImageTag} ."
                    sh "docker push ${dockerImageTag}"

                    // Stocke le tag de l'image construite pour les étapes ultérieures (déploiement)
                    env.IMAGE_TAG_FOR_DEPLOY = env.BUILD_NUMBER
                }
            }
        }

        stage('Deploy to Kubernetes with Helm') {
            steps {
                script {
                    echo "Deploying to Kubernetes using Helm..."

                    // Utilisation du kubeconfig depuis Jenkins Credentials
                    // Le fichier kubeconfig sera temporairement disponible dans l'environnement de build
                    withCredentials([file(credentialsId: env.KUBERNETES_KUBECONFIG_ID, variable: 'KUBECONFIG_FILE')]) {
                        // Exporte KUBECONFIG pour que kubectl et helm puissent le trouver
                        sh "export KUBECONFIG=${KUBECONFIG_FILE}"
                        // Choisir le contexte Kubernetes
                        sh "kubectl config use-context ${env.KUBERNETES_CONTEXT}"

                        // Exécuter la commande Helm
                        // --install : installe si la release n'existe pas, met à jour sinon
                        // --wait : attend que toutes les ressources soient dans un état prêt avant de considérer le déploiement comme réussi
                        sh "helm upgrade --install my-python-app ${env.HELM_CHART_PATH} " +
                           "--set image.repository=${env.DOCKER_IMAGE_NAME} " +
                           "--set image.tag=${env.IMAGE_TAG_FOR_DEPLOY} " +
                           "--wait"

                        echo "Helm deployment completed."
                    }
                }
            }
        }

        stage('Run Helm Tests (Optional)') {
            steps {
                script {
                    echo "Running Helm tests..."
                    withCredentials([file(credentialsId: env.KUBERNETES_KUBECONFIG_ID, variable: 'KUBECONFIG_FILE')]) {
                        sh "export KUBECONFIG=${KUBECONFIG_FILE}"
                        sh "kubectl config use-context ${env.KUBERNETES_CONTEXT}"
                        sh "helm test my-python-app" // 'my-python-app' est le nom de ta release Helm
                    }
                    echo "Helm tests finished."
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished."
        }
        failure {
            echo "Pipeline failed! Check logs for details."
        }
        success {
            echo "Pipeline succeeded!"
        }
        // Clean up Docker login
        // withCredentials([usernamePassword(credentialsId: env.DOCKER_REGISTRY_CREDENTIALS_ID, passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
        //     sh "docker logout"
        // }
    }
}