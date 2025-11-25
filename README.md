# argocd-feature-branches
GitOps setup for testing Argo CD with feature branches.

This is a small playground for running Argo CD behind the Kubernetes Gateway API using **kgateway** (and **Envoy** proxy) — all running locally on Minikube, and exposed to the internet through a [Cloudflare Quick Tunnel](https://github.com/cloudflare/cloudflared).

Everything is automated using a [Taskfile](https://taskfile.dev/docs/installation).

If you can type `task up`, you’re good. 😄

**Why did I use Taskfile?**

First of all, just to explore: it's a cool tool in the sense that you can say *“run these scripts in this order, with these variables, in a clean and readable way”*

— and it just does it. No fuss, no cryptic syntax.

Compared to a Makefile, Taskfile feels… well… human

The only downside I found so far is that you need to install the `Taskfile` binary.

# 🚀 What this playground does

When you run task up, it will:
- spin up a Minikube cluster
- install Gateway API CRDs
- install [KGateway](https://kgateway.dev/docs/latest/install/helm/) (Envoy-based L7 gateway)
- install Argo CD
- generate a full set of TLS certificates
- configure end-to-end TLS — **client** → `HTTPS` → Gateway → `HTTPS` → **Argo CD** 
- start a Cloudflare tunnel
- patch Argo CD to use your new public URL
- print out the URLs you can connect to

You end up with Argo CD accessible at:
- https://argocd.local:8085
 (local)
- https://<something>.trycloudflare.com (public)

Pretty cool for demos or experimenting with Gateway API + Envoy + TLS.

▶️ Getting started

Just run:
```
cd bootstrap/
task up
```

Grab a coffee — it’ll set up everything.

When it’s done, it prints your access info.

# 🧹 How to Destroy Everything
You can wipe out absolutely everything with:
```
cd bootstrap/
task down
```
This command takes care of the entire cleanup process for you:
- stops the Cloudflare tunnel
- stops any running kubectl port-forward
- deletes the Minikube cluster
- removes generated TLS certificates (`certs/`)
- removes the Cloudflare URL file (`.cloudflare-url`)
- Cleans up temporary logs / PID files
