

# 1 - Jenkins (Orchestrator)

- To install Jenkins run the commands below in the root kata folder. It will install Jenkins and create the "kata-bootstrap" job to build the whole kata structure.

```bash
cd jenkins
./run.sh
```


# 2 - Deploy infra

## To deploy infra
```bash
cd boot
./start.sh
```
## To destroy infra
```bash
cd boot
./cleanup.sh
```


# 3 - External acesss

- Jenkins - http://localhost:8080 
- username: admin
- password: admin

- Grafana - http://localhost:3000 
- username: admin
- password: admin