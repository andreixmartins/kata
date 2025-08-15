


# Jenkins (Orchestrator)

- To install Jenkins run the commands below in the root kata folder. It will install Jenkins and create the "kata-bootstrap" job to build the whole kata structure.

```bash
cd jenkins
./run.sh
```

- If you want to trigger the Jenkins job uncomment the line - `curl -u "$USER:$TOKEN" -X POST "$JENKINS_URL/job/kata-k8s-bootstrap/build"` in run.sh


- This job will run Tofu scripts like these below.

```bash
tofu init
tofu plan
tofu apply -auto-approve
```

```bash
tofu destroy -auto-approve
```


