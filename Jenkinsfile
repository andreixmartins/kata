pipeline {
  agent {
    kubernetes {
      label 'kaniko-maven-ci'
      namespace 'infra'   // change if needed
      yaml '''
apiVersion: v1
kind: Pod
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    fsGroupChangePolicy: "OnRootMismatch"
  volumes:
    - name: home
      emptyDir: {}
    - name: kaniko-cache
      emptyDir: {}
    - name: maven-repo
      emptyDir: {}
  containers:
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
'''
    }
  }

  environment {
    IMAGE = 'axsoftware/boot-chart'     // <— set your image
    GIT_URL = 'https://github.com/andreixmartins/boot-chart.git'  // <— set your repo
    GIT_BRANCH = 'main'                          // <— set your branch
    GIT_CREDS = 'git-creds'                      // <— Jenkins credential ID (Username/Password or Token)
  }

  stages {
    stage('Checkout') {
      steps {
        deleteDir()
        container('git') {
          // now $HOME is /home/jenkins and writable
          sh 'echo HOME=$HOME && id && ls -ld $HOME'
          sh 'git config --global --add safe.directory "$WORKSPACE"'
          git branch: env.GIT_BRANCH, url: env.GIT_URL, credentialsId: env.GIT_CREDS
          sh 'git rev-parse --short HEAD'
        }
      }
    }

    stage('Build (Maven)') {
      steps {
        container('maven') {
          sh 'mvn -B -DskipTests package'
        }
      }
    }

    stage('Build & Push Image (Kaniko)') {
      steps {
        container('kaniko') {
          withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
            sh '''
              mkdir -p /kaniko/.docker
              cat > /kaniko/.docker/config.json <<EOF
              {"auths":{"https://index.docker.io/v1/":{"username":"$USER","password":"$PASS"}}}
              EOF

              /kaniko/executor \
                --context "$WORKSPACE" \
                --dockerfile "$WORKSPACE/Dockerfile" \
                --destination "${IMAGE}:${BUILD_NUMBER}" \
                --destination "${IMAGE}:latest" \
                --cache=true --cache-dir=/kaniko/cache
            '''
          }
        }
      }
    }
  }
}
