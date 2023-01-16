# hperm
Helm-based k8s RBAC manager

## What is it
It is permissions (RBAC) manager for kubernetes, based on helm chart.

## How it works?
It creates Service Account, Role, Role Binding and Secret for users listed in chart values.
It is a helm chart, so it will be remove any RBAC configuration for absent users.

Helper script generates kubeconfig file for any user present in values, and stores it as secret, from where you can download it easily and provide it to any system or user yoiu need.

## How to
I am running it on bitbucket pipelines, so create pipeline like present in example.
Then add CI variables:
CLUSTER_NAME_HPERM - name of your cluster to template config
CA_DATA_HPERM - full CA line for your API (you can find it in your kubeconfig in "certificate-authority-data" line)
API_ENDPOINT_HPERM - k8s API endpoint ( you can find it in your kubeconfig in "server" line)
NS_HPERM - namespace for storing all data (including generated kubeconfig files)
DOCKER_USERNAME/DOCKER_PASSWORD - creds for you local registry (where k8s-toolkit image is stored)
b64_kubeconfig_from_CI_Envs - your CI k8s kubeconfig (echo -n /path/to/kubeconfig | base64 -w0) 

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

Start CI.

## Motivation
It is not always convinient to build ldap/vault/keycloack for small organisations, but you may still want to keep user-management DRY and IaaC style.

## Where I am using it (compatable and tested versions):
k8s on Digital Ocean 1.25.4-do.0
k8s on Digital Ocean 1.24.4-do.0
Bitbucket-pipelines as CI
helm3

## Special thanks:
https://github.com/sighupio/permission-manager
It is basically the same solution, but based on web UI, and not compatible wuth IaaC approach yet. Also it is not compatible with k8s > 1.24

https://palasts.com
We are managing users for tech team this way in Palasts
