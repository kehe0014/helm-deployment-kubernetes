pipeline {
    agent any

    environment {
        DOCKER_ID = "tdksoft"
        IMAGE_NAME = "${DOCKER_ID}/my-python-api"
        IMAGE_TAG = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
        HELM_CHART_PATH = './helm'
        // Le nom du release Helm sera différent selon l'environnement
        HELM_RELEASE_NAME = "my-python-app-${env.BRANCH_NAME}"
        // Namespace Kubernetes par défaut (peut être overridé par environnement)
        K8S_NAMESPACE = "default"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
                script {
                    // Déterminer la branche actuelle
                    env.BRANCH_NAME = env.GIT_BRANCH.replace('origin/', '')
                    echo "Building branch: ${env.BRANCH_NAME}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                }
            }
        }

        stage('Push Docker Image') {
            environment {
                DOCKER_PASS = credentials("DOCKER_HUB_PASS")
            }
            steps {
                script {
                    echo "Pushing Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
                    sh """
                        docker login -u ${DOCKER_ID} -p ${DOCKER_PASS}
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Determine Environment') {
            steps {
                script {
                    // Déterminer l'environnement cible en fonction de la branche
                    if (env.BRANCH_NAME == 'main') {
                        env.TARGET_ENV = 'prod'
                        env.K8S_NAMESPACE = 'production'
                    } else if (env.BRANCH_NAME == 'dev') {
                        // Pour la branche dev, nous déployons dans plusieurs environnements
                        env.TARGET_ENVS = ['dev', 'staging', 'qa']
                        env.K8S_NAMESPACE = 'development' // Par défaut pour dev
                    } else {
                        // Pour les autres branches (feature branches), déployer seulement en dev
                        env.TARGET_ENVS = ['dev']
                        env.K8S_NAMESPACE = 'development'
                    }
                }
            }
        }

        stage('Deploy to Environments') {
            environment {
                KUBECONFIG = credentials('config')
            }
            steps {
                script {
                    // Si TARGET_ENVS n'est pas défini (cas de la branche main), créer un tableau avec un seul élément
                    def targetEnvs = env.TARGET_ENVS ?: [env.TARGET_ENV]
                    
                    targetEnvs.each { envName ->
                        // Configurer les paramètres spécifiques à l'environnement
                        def namespace = envName == 'prod' ? 'production' : 
                                         envName == 'qa' ? 'quality-assurance' : 
                                         envName == 'staging' ? 'staging' : 'development'
                        
                        def releaseName = "my-python-app-${envName}"
                        def helmValuesFile = "${HELM_CHART_PATH}/values-${envName}.yaml"
                        
                        echo "Deploying to ${envName} environment (namespace: ${namespace})"
                        
                        // Vérifier si un fichier de valeurs spécifique existe
                        def valuesParam = fileExists(helmValuesFile) ? 
                            "-f ${helmValuesFile}" : ""
                        
                        sh """
                            # Set Kubernetes context if needed
                            kubectl config use-context ${envName}-cluster
                            
                            # Create namespace if it doesn't exist
                            kubectl get namespace ${namespace} || kubectl create namespace ${namespace}
                            
                            # Helm deployment with environment-specific settings
                            helm upgrade --install ${releaseName} ${HELM_CHART_PATH} \\
                              --namespace ${namespace} \\
                              --set image.repository=${IMAGE_NAME} \\
                              --set image.tag=${IMAGE_TAG} \\
                              --set serviceAccount.create=true \\
                              --set env=${envName} \\
                              ${valuesParam} \\
                              --wait \\
                              --timeout 5m
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished for branch ${env.BRANCH_NAME}"
        }
        success {
            echo "Pipeline successful!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}