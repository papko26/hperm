# hperm

Helm-based k8s RBAC manager

## What is it

It is the permissions (RBAC) manager for Kubernetes, based on the helm chart.

## How it works?

It creates Service Account, Role, Role Binding, and Secret for users listed in chart values.
It is a helm chart, so it will remove any RBAC configuration for absent users.

Helper script generates kubeconfig file for any user present in values, and stores it as secret, from where you can download it easily and provide it to any system or user you need.

## How to

I am running it on bitbucket pipelines, so create a pipeline like presented in the example.
```
pipelines:
  branches:
     master:
      - parallel:
          - step:
                name: K8S infra PROD - permissions
                trigger: manual
                image:
                  # https://jira.atlassian.com/browse/BCLOUD-13014
                  name: your.regist.ry/k8s-toolset
                  username: $DOCKER_USERNAME
                  password: $DOCKER_PASSWORD
                  email: deploy@your_compa.ny
                script:
                  - cd hperm
                  - echo $b64_kubeconfig_from_CI_Envs | base64 -d > /tmp/kubeconfig
                  - helm upgrade -n hperm --install --wait --values values.yaml --kubeconfig /tmp/kubeconfig hperm .
                  - cd ../hperm-generator
                  - bash hperm-generator.sh /tmp/kubeconfig
```
Then add CI variables:
* `CLUSTER_NAME_HPERM` - the name of your cluster to template config
* `CA_DATA_HPERM` - full CA line for your API (you can find it in your kubeconfig in "certificate-authority-data" line)
* `API_ENDPOINT_HPERM` - k8s API endpoint ( you can find it in your kubeconfig in "server" line)
* `NS_HPERM` - namespace for storing all data (including generated kubeconfig files)
* `DOCKER_USERNAME/DOCKER_PASSWORD` - creds for you local registry (where k8s-toolkit image is stored)
* `b64_kubeconfig_from_CI_Envs` - your CI k8s kubeconfig (echo -n /path/to/kubeconfig | base64 -w0)

Build k8s-toolkit.Dockerfile and place it to your registry.
Deploy k8s cluster (you should have at least one to begin, right?)

Configure users.

```
accounts:
    #group root. Users in that group will have access to the whole cluster.
    root:
      #username
      bitbucket.ci:
        #just duplicate it here
        name: "bitbucket.ci"
    #group root. Users here can access only selected namespace
    developers:
      #username
      dev.test1:
        #just duplicate it here
        name: "debug.dev"
        #list of namespaces user will have full access
        namespaces:
        - default
        - monitoring

```

Start the pipeline.

## Motivation

It is not always convenient to build ldap/vault/keycloack for small organizations, but you may still want to keep user-management DRY and IaaC style.
I just want to share this approach with you, despite it is not mature, to save you some time.

## Where I am using it (compatible and tested versions):

* k8s on Digital Ocean 1.25.4-do.0
* k8s on Digital Ocean 1.24.4-do.0
* Bitbucket-pipelines as CI
* helm3

## TODO:
- CLUSTER_NAME_HPERM, CA_DATA_HPERM should be populated automatically
- API_ENDPOINT_HPERM - should try to use the default value
- [hperm-generator.sh](http://hperm-generator.sh/) should be rewritten on python/go
- the whole hperm-generator tool should run inside the cluster (as an operator?)

## Special thanks:

[https://github.com/sighupio/permission-manager](https://github.com/sighupio/permission-manager)
It is basically the same solution, but based on web UI, and not compatible with IaaC approach yet. Also it is not compatible with k8s > 1.24

[https://palasts.com](https://palasts.com/)
We are managing users for the tech team this way in Palasts
