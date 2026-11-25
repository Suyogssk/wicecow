# Cow wisdom web server

## Prerequisites

```
sudo apt install fortune-mod fortunes-min cowsay netcat-openbsd -y
```

## How to use ?

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

Requirements: a Kubernetes cluster, `kubectl`, a Traefik Ingress Controller, a DNS name pointing to the ingress controller, and a TLS certificate/key for that name.

1. Replace `wisecow.test` in `k8s/ingress.yaml` with your DNS name.
2. Create the TLS secret in the namespace where the app will run:

   ```sh
   kubectl create namespace wisecow
   kubectl create secret tls wisecow-tls -n wisecow --cert=fullchain.pem --key=privkey.pem
   ```

3. Confirm the image in `k8s/deployment.yaml` points to your GHCR package, then deploy:

   ```sh
   kubectl apply -n wisecow -f k8s/deployment.yaml
   kubectl apply -n wisecow -f k8s/ingress.yaml
   ```

The Service is internal to the cluster; the Ingress routes HTTPS traffic to it and terminates TLS using `wisecow-tls`. Ensure the cluster can pull the GHCR package. For a private package, configure a registry pull secret for the `wisecow` service account in the deployment namespace.

### Local Minikube TLS demo

The checked-in ingress host `wisecow.test` is for local testing. On Minikube v1.39 or newer, enable the Traefik addon:

```sh
minikube addons enable traefik
```

Create a self-signed certificate and the TLS secret (the browser will show a certificate warning):

```sh
openssl req -x509 -newkey rsa:2048 -nodes -keyout wisecow.test.key -out wisecow.test.crt -days 30 -subj "/CN=wisecow.test" -addext "subjectAltName=DNS:wisecow.test"
kubectl create secret tls wisecow-tls -n wisecow --cert=wisecow.test.crt --key=wisecow.test.key
kubectl apply -n wisecow -f k8s/ingress.yaml
```

Forward Traefik's HTTPS port and test the ingress:

```sh
kubectl port-forward -n kube-system svc/traefik 10443:443
curl -k --resolve wisecow.test:10443:127.0.0.1 https://wisecow.test:10443/
```

## GitHub Actions CI/CD

`.github/workflows/deploy.yml` builds and pushes a commit-tagged image and `latest` to GHCR on pushes to `main`, then deploys the commit image to a temporary Kind cluster with Traefik and a self-signed TLS certificate. The workflow checks that HTTPS returns the Wisecow page. The temporary cluster is deleted when the job ends, so it demonstrates deployment without keeping a public service running. Standard GitHub-hosted runners are free for public repositories.

The GHCR package must be pullable by the workflow. For a persistent deployment, use a cluster you can reach and a trusted certificate for its hostname; the repository remains configured to build and validate the image and Kubernetes/TLS deployment in the temporary cluster. Configure repository visibility separately in GitHub to match the assessment requirement; this workflow does not change repository settings.
