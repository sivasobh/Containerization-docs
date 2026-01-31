# Copilot Prompt — Containerization Documentation

Purpose
-------
This prompt template instructs an LLM to generate comprehensive, production-ready documentation covering containerization topics: Docker, Kubernetes, and Helm charts.

Use case
--------
- Create README-style docs for teams onboarding to containerization.
- Generate step-by-step guides, examples, and best practices for converting an app to containers and deploying to Kubernetes with Helm.

How to use
----------
1. Fill the placeholders in the Example Input section below.
2. Feed the completed prompt to your LLM (Copilot, ChatGPT, etc.).
3. Request the output as Markdown.

Scope
-----
- Docker: image design, Dockerfile examples, multi-stage builds, common commands, security and size optimizations.
- Kubernetes: manifests (Deployment, Service, ConfigMap, Secret, Ingress), best practices for resources, probes, configs, and RBAC notes.
- Helm charts: chart structure, templates, values.yaml examples, packaging, and release instructions.

Output format requirements
-------------------------
- Output must be valid Markdown with headings, code blocks, tables where useful, and short command snippets.
- Include at least one minimal example for each of: Dockerfile, Kubernetes manifests, and Helm chart file structure.
- Add a TL;DR section at the top and a Troubleshooting / FAQ at the end.

Tone and audience
-----------------
- Audience: developers and DevOps engineers with basic familiarity with containers.
- Tone: practical, concise, actionable; prefer examples and commands over theory.

Checklist to include
--------------------
- TL;DR summary
- When to use Docker vs Kubernetes vs Helm
- Dockerfile example with explanation
- Build and push commands (Docker CLI and optional BuildKit or ACR/registry notes)
- Kubernetes manifests with explanations (Deployment, Service, ConfigMap, Secret, Ingress)
- Helm chart skeleton and `values.yaml` example
- CI/CD snippet example for building and deploying (GitHub Actions or similar)
- Security and hardening tips (image scanning, least privilege, Secrets handling)
- Cleanup and rollback procedures
- Further reading / links

Example Input (fill these placeholders)
-------------------------------------
- Project name: {project_name}
- Language/runtime: {language_runtime} (e.g., Node.js 18, Python 3.11, Go 1.20)
- Exposed port: {port}
- Environment variables: {env_vars} (list of names + purpose)
- Registry: {container_registry} (optional)
- Kubernetes target: {k8s_context} (single-cluster / multi-cluster notes)
- Helm release name: {helm_release}
- Extra goals: {extra_goals} (e.g., small image size, zero-downtime deploys)

Example Prompt (paste to LLM after filling placeholders)
---------------------------------------------------
"Generate a complete, practical documentation guide for containerizing the `{project_name}` application ({language_runtime}). The app listens on port `{port}` and uses these environment variables: `{env_vars}`. Include:

- A short TL;DR and 'When to use' guidance for Docker, Kubernetes, and Helm.
- A minimal, annotated `Dockerfile` showing a recommended multi-stage build and build commands.
- Commands to build, tag, and push the image to `{container_registry}` (show both Docker CLI and an example GitHub Actions job).
- Kubernetes manifest examples for `Deployment`, `Service`, `ConfigMap`, `Secret` (with best-practice notes), and an `Ingress` example.
- A minimal Helm chart skeleton (Chart.yaml, values.yaml, templates/_helpers.tpl, templates/deployment.yaml, templates/service.yaml) and how to install and upgrade with Helm.
- Recommended resource limits/requests, readiness and liveness probes, and rollout strategy example for zero-downtime deploys.
- Security recommendations (image scanning, non-root user, secrets management) and a short Troubleshooting / FAQ section.

Format the output in Markdown with code fences, clear headings, and a short Commands quick-reference box. Keep the guide practical and no longer than necessary; use examples that can be copy-pasted and adapted."

Optional variations
-------------------
- Request a short cheat-sheet instead of full docs.
- Request docs targeted to a specific cloud provider (GKE, EKS, AKS) with provider-specific notes.

Examples snippets to include in final doc
--------------------------------------
- Minimal multi-stage `Dockerfile` for `{language_runtime}`
- `kubectl` commands for common workflows (apply, rollout, port-forward, logs)
- Example `helm install` / `helm upgrade --install` command

Notes
-----
- Keep code examples small and focused; link to advanced topics instead of embedding long references.
