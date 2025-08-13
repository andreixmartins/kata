pipeline {
  agent {
    kubernetes {
      label 'kaniko-maven-ci-fix-chown'
      namespace 'infra'  
      yaml '''
apiVersion: v1
kind: Pod
spec:
  volumes:
    - name: home
      emptyDir: {}
    - name: kaniko-cache
      emptyDir: {}
    - name: maven-repo
      emptyDir: {}

  containers:
    # ----- GIT (non-root) -----
    - name: git
      image: alpine/git:2.45.2
      tty: true
      env:
        - name: HOME
          value: /home/jenkins
      command: ["/bin/sh","-lc","tail -f /dev/null"]
      volumeMounts:
        - name: home
          mountPath: /home/jenkins
      securityContext:
        runAsUser: 1000
        runAsGroup: 1000

    # ----- MAVEN (non-root) -----
    - name: maven
      image: maven:3.9-eclipse-temurin-21
      tty: true
      env:
        - name: HOME
          value: /home/jenkins
        - name: MAVEN_CONFIG
          value: /home/jenkins/.m2
      command: ["/bin/sh","-lc","tail -f /dev/null"]
      volumeMounts:
        - name: home
          mountPath: /home/jenkins
        - name: maven-repo
          mountPath: /home/jenkins/.m2
      securityContext:
        runAsUser: 1000
        runAsGroup: 1000

    # ----- KANIKO (root to allow chown during unpack) -----
    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      tty: true
      env:
        - name: HOME
          value: /home/jenkins
      command: ["/busybox/sh","-c","tail -f /dev/null"]
      volumeMounts:
        - name: home
          mountPath: /home/jenkins
        - name: kaniko-cache
          mountPath: /kaniko/cache
      securityContext:
        runAsUser: 0       # ← important: Kaniko needs root to chown files when unpacking base image
'''
    }
  }

  environment {
    IMAGE = 'axsoftware/boot-chart'     
    GIT_URL = 'https://github.com/andreixmartins/boot-chart.git' 
    GIT_BRANCH = 'main'                          
    GIT_CREDS = 'git-creds'                      
    REGISTRY_CREDS = 'dockerhub-creds' // Create this credential in Jenkins, password must be the docker-hub token
  }

  stages {
    stage('Checkout code from Github') {
      steps {
        deleteDir()
        container('git') {
          sh 'echo HOME=$HOME && id && ls -ld "$HOME"'
          sh 'git config --global --add safe.directory "$WORKSPACE"'
          git branch: env.GIT_BRANCH, url: env.GIT_URL, credentialsId: env.GIT_CREDS
          sh 'git rev-parse --short HEAD'
        }
      }
    }

    stage('Build app') {
      steps {
        container('maven') {
          sh 'mvn -B -DskipTests package'
        }
      }
    }

    stage('Publish to image registry') {
      steps {
        container('kaniko') {
          withCredentials([usernamePassword(credentialsId: env.REGISTRY_CREDS, usernameVariable: 'USER', passwordVariable: 'PASS')]) {
            sh '''
              set -euo pipefail
              : "${WORKSPACE:?WORKSPACE not set}"

              CFG_DIR="$WORKSPACE/.docker"
              DIGEST_PATH="$WORKSPACE/.kaniko-image.digest"
              mkdir -p "$CFG_DIR"

              # Docker Hub auth (base64 "user:token")
              AUTH="$(printf "%s:%s" "$USER" "$PASS" | base64 | tr -d '\\n')"
              printf '{ "auths": { "https://index.docker.io/v1/": { "auth": "%s" } } }\n' "$AUTH" > "$CFG_DIR/config.json"
              export DOCKER_CONFIG="$CFG_DIR"

              echo "Building & pushing docker.io/${IMAGE#docker.io/}:${BUILD_NUMBER}"
              /kaniko/executor \
                --context "$WORKSPACE" \
                --dockerfile "$WORKSPACE/Dockerfile" \
                --destination "docker.io/${IMAGE#docker.io/}:${BUILD_NUMBER}" \
                --destination "docker.io/${IMAGE#docker.io/}:latest" \
                --cache=true --cache-dir=/kaniko/cache \
                --verbosity=info \
                --digest-file "$DIGEST_PATH"

              [ -f "$DIGEST_PATH" ] && echo "Pushed digest: $(cat "$DIGEST_PATH")"
            '''
          }
        }
      }
    }
  }
}
