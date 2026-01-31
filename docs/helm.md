# Helm — Chart and Release Guide

TL;DR
-----
- Use Helm to templatize Kubernetes manifests, manage releases, and store configurable defaults in `values.yaml`.

When to use
-----------
- When you need parameterized deployments, repeatable installs, and easy upgrades/rollbacks for Kubernetes apps.

Chart skeleton
--------------
```
mychart/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── _helpers.tpl
```

Minimal `Chart.yaml`
```yaml
apiVersion: v2
name: mychart
version: 0.1.0
appVersion: "1.0.0"
```

Minimal `values.yaml`
```yaml
replicaCount: 2
image:
  repository: myregistry.example.com/myorg/myapp
  tag: latest
  pullPolicy: IfNotPresent
service:
  type: ClusterIP
  port: 80
resources: {}
```

Example `templates/deployment.yaml` (snippet)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "mychart.fullname" . }}
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: 8080
```

Install and upgrade
-------------------
- Install: `helm install myrelease ./mychart -n mynamespace --create-namespace`
- Upgrade (or install): `helm upgrade --install myrelease ./mychart -n mynamespace`
- Rollback: `helm rollback myrelease 1`

Tips
----
- Keep templates simple and prefer small helpers in `_helpers.tpl`.
- Validate templates with `helm template ./mychart` before installing.
- Use `helm lint` in CI.
- Store chart values per environment (values-dev.yaml, values-prod.yaml) and pass with `-f`.

CI example (build and push chart package)
```bash
helm package ./mychart
helm repo index --url https://example.com/charts .
# Push package to chart repo (or upload to GitHub Pages / ChartMuseum)
```

Security and governance
-----------------------
- Lint charts and scan rendered manifests for risky settings.
- Avoid embedding credentials in `values.yaml`; use external secret mechanisms.

Further reading
---------------
- Helm docs: https://helm.sh/docs/

Umbrella chart (GitHub organization + sprint-version scenario)
-----------------------------------------------------------
An "umbrella" chart (aka parent chart) groups multiple subcharts and manages a release for an entire application composed of several components (microservices). This is useful for GitHub organizations that publish component charts separately and release coordinated sprint versions.

When to use an umbrella chart
- You have several independently developed charts (per-service) and need a single coordinated release.
- You want to pin component chart versions per sprint and deploy a consistent set across environments.

Example repository layout (GitHub organization)
```
charts-repo/               # repo that hosts packaged charts (GitHub Pages or OCI registry)
myorg-service-a/           # service A chart (chart.yaml, templates/...)
myorg-service-b/           # service B chart
umbrella-chart/            # parent chart that depends on the two service charts
```

Umbrella `Chart.yaml` (Helm v3 dependencies)
```yaml
apiVersion: v2
name: umbrella-chart
version: 0.1.0
appVersion: "2026.01-sprint-05"    # human-facing sprint tag
dependencies:
  - name: myorg-service-a
    version: "1.2.0"                # pinned component version for this sprint
    repository: "https://myorg.github.io/charts"
  - name: myorg-service-b
    version: "2.0.1"
    repository: "https://myorg.github.io/charts"
```

`values.yaml` (umbrella overrides and sprint metadata)
```yaml
# Global sprint metadata available to subcharts
global:
  sprintVersion: "2026.01-sprint-05"

myorg-service-a:
  replicaCount: 2

myorg-service-b:
  replicaCount: 1

# You can also pin child-chart image tags via global or per-chart keys
image:
  tag: "2026.01-sprint-05"
```

Workflow notes (GitHub org + CI)
- Component teams publish charts to the org chart repo (GitHub Pages) or push OCI chart packages to GitHub Packages/Container Registry.
- For each sprint, create an umbrella chart release that pins dependency versions in `Chart.yaml` and sets `global.sprintVersion` in `values.yaml`.
- CI process:
  1. Components build and publish chart packages (e.g., `helm package` and push to `gh-pages` or `helm push` to an OCI registry).
  2. Umbrella chart CI updates `Chart.yaml` dependency `version` fields to the published component versions for the sprint (automated via script or dependabot-style PR).
  3. Run `helm dependency update` in the umbrella chart to fetch dependency charts.
  4. Package and publish umbrella chart (or deploy directly using `helm upgrade --install`).

Example commands
```bash
# fetch dependencies (run in umbrella-chart/)
helm dependency update

# install/upgrade the sprint release
helm upgrade --install umbrella-release ./umbrella-chart -n mynamespace \
  --create-namespace --values ./umbrella-chart/values.yaml

# override sprintVersion at deploy time
helm upgrade --install umbrella-release ./umbrella-chart -n mynamespace \
  --set global.sprintVersion=2026.01-sprint-05
```

Packaging and publishing tips for GitHub
- GitHub Pages: push packaged charts to `gh-pages` branch and serve at `https://myorg.github.io/charts`.
- OCI (recommended for modern workflows): enable OCI support and push charts as OCI artifacts to `ghcr.io/myorg/charts`.

Example CI snippet (update dependencies and package)
```bash
cd umbrella-chart
python3 scripts/update-deps.py --sprint 2026.01-sprint-05   # updates Chart.yaml dependency versions
helm dependency update
helm package .
# upload package to gh-pages or OCI registry
```

Rollback and fast iteration
- When a sprint release has an issue, use `helm rollback <release> <revision>` to revert to the previous release.
- For fast iterative deploys during a sprint, you can keep umbrella `Chart.yaml` using looser version ranges during dev, and pin exact versions when promoting to staging/production.

Security and governance
- Use signed chart repositories or OCI registries and enable provenance checks in CI.
- Require PR approvals in the umbrella repo for dependency bumps to enforce review of which component versions are included in a sprint release.

