#!groovy
@Library(['github.com/cloudogu/ces-build-lib@v1.48.0', 'github.com/cloudogu/dogu-build-lib@v1.5.1']) _
import com.cloudogu.ces.cesbuildlib.*
import com.cloudogu.ces.dogubuildlib.*

node('docker') {
    stage('Checkout') {
        checkout scm
    }

    stage('Lint') {
        lintDockerfile()
//            "resources/backup-consumer.sh resources/create-sa.sh resources/remove-sa.sh resources/pre-upgrade.sh resources/startup.sh resources/upgrade-notification.sh"
         shellCheck("resources/create-sa.sh resources/remove-sa.sh resources/startup.sh")
    }

    stage('Shell tests') {
        def bats_base_image="bats/bats"
        def bats_custom_image="cloudogu/bats"
        def bats_tag="1.2.1"

        def batsImage = docker.build("${bats_custom_image}:${bats_tag}", "--build-arg=BATS_BASE_IMAGE=${bats_base_image} --build-arg=BATS_TAG=${bats_tag} ./unitTests")
        try {
            sh "mkdir -p target"
            sh "mkdir -p testdir"

            batsContainer = batsImage.inside("--entrypoint='' -v ${WORKSPACE}:/workspace -v ${WORKSPACE}/testdir:/usr/share/webapps") {
                sh "make unit-test-shell-ci"
            }
        } finally {
            junit allowEmptyResults: true, testResults: 'target/shell_test_reports/*.xml'
        }
    }
}

node('vagrant') {

    Git git = new Git(this, 'cesmarvin')
    git.committerName = 'cesmarvin'
    git.committerEmail = 'cesmarvin@cloudogu.com'
    String doguDirectory = '/dogu'
    GitFlow gitflow = new GitFlow(this, git)
    GitHub github = new GitHub(this, git)
    Changelog changelog = new Changelog(this)

    timestamps {
        properties([
            // Keep only the last x builds to preserve space
            buildDiscarder(logRotator(numToKeepStr: '10')),
            // Don't run concurrent builds for a branch, because they use the same workspace directory
            disableConcurrentBuilds()
        ])

        EcoSystem ecoSystem = new EcoSystem(this, 'gcloud-ces-operations-internal-packer', 'jenkins-gcloud-ces-operations-internal')

        try {
            stage('Provision') {
                ecoSystem.provision(doguDirectory)
            }

            stage('Setup') {
                ecoSystem.loginBackend('cesmarvin-setup')
                ecoSystem.setup()
            }

            stage('Wait for dependencies') {
                timeout(15) {
                    ecoSystem.waitForDogu('cas')
                    ecoSystem.waitForDogu('usermgt')
                }
            }

            stage('Build') {
                ecoSystem.build(doguDirectory)
            }

            stage('Verify') {
                ecoSystem.verify(doguDirectory)
            }

            if (gitflow.isReleaseBranch()) {
                String releaseVersion = git.getSimpleBranchName()

                stage('Finish Release') {
                    gitflow.finishRelease(releaseVersion)
                }

                stage('Push Dogu to registry') {
                    ecoSystem.push(doguDirectory)
                }

                stage ('Add Github-Release') {
                    github.createReleaseWithChangelog(releaseVersion, changelog)
                }
            }

        } finally {
            stage('Clean') {
                ecoSystem.destroy()
            }
        }
    }
}
