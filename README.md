# GitOps on Kubernetes

A sample K8s project following GitOps mindset.

## Table of Contents

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Prerequisites

The following tools are required to use this project:

- [Git](https://git-scm.com)
- [Go programming language](https://golang.org/dl)
- [Docker CE](https://www.docker.com/community-edition)
- [Kubernetes cluster](https://kubernetes.io/docs/setup)
- [Terraform](https://www.terraform.io)
- [Helm](https://helm.sh)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- [git-crypt](https://github.com/AGWA/git-crypt)
- [jq](https://stedolan.github.io/jq)
- [yq](https://github.com/mikefarah/yq)

Please refer to each tool's installation instructions to setup your environment.

## Environments

This project assumes you're using two different environments (two different K8s clusters) to deploy your services:

- **Production cluster**: public cluster for production workloads.
- **Staging cluster**: internal cluster for validating new features and fixes.

Some GitHub actions (such as [this one](.github/workflows/update-sealed-secrets.yaml) assume you're using GKE clusters and, therefore, it uses `gcloud` to dynamically obtain the cluster credentials. This also requires configuring the following [Action secrets](https://github.com/Azure/actions-workflow-samples/blob/master/assets/create-secrets-for-GitHub-workflows.md) in the repo:

- **GKE_PROJECT**: GCP project.
- **GKE_SA_KEY**: Service Account key. The Service Account should have "Kubernetes Engine Developer" role.

> Note: adapt these actions according to the environments you're using.

## Building container images

Most of the container images used on this project are maintained by the upstream charts' maintainers. However, there are also services, and their corresponding images, maintained on this repo. You can find the required files to build these images under the [src](./src) folder.

To build these container with multi-arch support, run the commands below:

```bash
docker buildx create --name image-builder
docker buildx use image-builder
docker buildx build src/SERVICE --platform linux/amd64,linux/arm64 -t IMAGE_NAME:VERSION --push
docker buildx rm image-builder
```

> Note: you need to replace the SERVICE, IMAGE_NAME and VERSION placeholders in the commands above with the actual service name, its associated image name and the image version you want to use, respectively.
