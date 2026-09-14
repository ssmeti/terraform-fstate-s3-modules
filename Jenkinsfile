pipeline {
    agent any

    options {
        // Prevent two runs from touching the same state at once
        disableConcurrentBuilds()
        timestamps()
    }

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        TF_IN_AUTOMATION    = 'true'   // tells Terraform it's running non-interactively
        TF_VAR_assume_role_arn = 'arn:aws:iam::434661699668:role/terraform-execution-role'
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Terraform action to run'
        )
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Format Check') {
            steps {
                    sh 'terraform fmt -check -recursive'
            }
        }

        stage('Terraform Init') {
            steps {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-terraform-creds'
                    ]]) {
                        sh 'terraform init -input=false'
                    }
            }
        }

        stage('Terraform Validate') {
            steps {
                    sh 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            steps {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-terraform-creds'
                    ]]) {
                        sh 'terraform plan -input=false -out=tfplan'
                    }
            }
        }

        stage('Manual Approval') {
            when {
                expression { params.ACTION == 'apply' || params.ACTION == 'destroy' }
            }
            steps {
                // Pauses the pipeline here until a human clicks approve in the Jenkins UI.
                // Review the plan output from the previous stage before approving.
                input message: "Apply these changes to AWS?", ok: "Approve"
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-terraform-creds'
                    ]]) {
                        sh 'terraform apply -input=false tfplan'
                    }
                }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-terraform-creds'
                    ]]) {
                        sh 'terraform destroy -input=false -auto-approve'
                    }
                }
        }
    }

    post {
        always {
                archiveArtifacts artifacts: 'tfplan', allowEmptyArchive: true
        }
        failure {
            echo 'Terraform pipeline failed — check the stage logs above.'
        }
    }
}
