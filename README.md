# Cow wisdom web server

## Prerequisites

```
sudo apt install fortune-mod cowsay -y
```

## How to use?

1. Run `./wisecow.sh`
2. Point the browser to server port (default 4499)

## What to expect?
![wisecow](https://github.com/nyrahul/wisecow/assets/9133227/8d6bfde3-4a5a-480e-8d55-3fef60300d98)

# Problem Statement
Deploy the wisecow application as a k8s app

## Requirement
1. Create Dockerfile for the image and corresponding k8s manifest to deploy in k8s env. The wisecow service should be exposed as k8s service.
2. Github action for creating new image when changes are made to this repo
3. [Challenge goal]: Enable secure TLS communication for the wisecow app.

## Expected Artifacts
1. Github repo containing the app with corresponding dockerfile, k8s manifest, any other artifacts needed.
2. Github repo with corresponding github action.
3. Set repository visibility to public as required by the supplied assessment brief.

## Container image

Build and run the app locally with Docker:

```sh
docker build -t wisecow:local .
docker run --rm -p 4499:4499 wisecow:local
```

Open <http://localhost:4499>. The image installs the app's runtime dependencies and runs it as an unprivileged user.

## Kubernetes deployment

Requirements: a Kubernetes cluster, `kubectl`, an NGINX Ingress Controller, a DNS name pointing to the ingress controller, and a TLS certificate/key for that name.

1. Replace `wisecow.example.com` in `k8s/ingress.yaml` with your DNS name.
2. Create the TLS secret in the namespace where the app will run:

   ```sh
   kubectl create namespace wisecow
   kubectl create secret tls wisecow-tls -n wisecow --cert=fullchain.pem --key=privkey.pem
   ```

3. In `k8s/deployment.yaml`, replace `ghcr.io/REPLACE_WITH_OWNER/wisecow:latest` with your GHCR image name, then deploy:

   ```sh
   kubectl apply -n wisecow -f k8s/deployment.yaml
   kubectl apply -n wisecow -f k8s/ingress.yaml
   ```

The Service is internal to the cluster; the Ingress routes HTTPS traffic to it and terminates TLS using `wisecow-tls`. Ensure the cluster can pull the GHCR package. For a private package, configure a registry pull secret for the `wisecow` service account in the deployment namespace.

## GitHub Actions CI/CD

`.github/workflows/deploy.yml` builds and pushes a commit-tagged image and `latest` to GHCR on pushes to `main`, then updates the Kubernetes deployment. Add these settings under **Settings → Secrets and variables → Actions**:

- Secret `KUBE_CONFIG`: the kubeconfig content for a service account permitted to manage the deployment and ingress in the target namespace.
- Variable `KUBE_NAMESPACE`: namespace to deploy into (for example, `wisecow`). It is created by the workflow if needed.
- Variable `DEPLOY_TO_K8S`: set to `true` only when the configured runner can reach the cluster. Until then, pushes build and publish the image but skip deployment.

The GHCR package must be pullable by the cluster. Set `wisecow.example.com` in the ingress manifest before enabling deploys. Configure repository visibility separately in GitHub to match the assessment requirement; this workflow does not change repository settings.
