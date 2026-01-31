# Docker — Containerization Guide

TL;DR
-----
- Use Docker to build, test, and distribute application images. Prefer multi-stage builds to minimize final image size and run containers as non-root.

When to use
-----------
- Local development, CI build artifacts, single-node containers, and image distribution to registries.


Multi-stage builds (overview)
-----------------------------
Multi-stage builds let you use multiple FROM stages in a single `Dockerfile`. Build-time dependencies and toolchains stay in earlier stages, and only the minimal runtime artifacts are copied into the final image. This dramatically reduces final image size and attack surface.

When to prefer multi-stage builds
- Building compiled languages (Go, Rust) where you want a static binary in a minimal base image.
- Building language runtimes (Node, Python) where build tools and dev dependencies should not be shipped.
- Any scenario where smaller images and faster pulls are important (CI, edge, serverless).

Example — Node.js multi-stage (build + runtime)
------------------------------------------------
```dockerfile
# build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# runtime stage
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
RUN addgroup -S app && adduser -S app -G app
USER app
EXPOSE 8080
CMD ["node", "dist/index.js"]
```

Example — Python (build wheels, produce small runtime image)
------------------------------------------------------------
```dockerfile
# build stage
FROM python:3.11-slim AS builder
WORKDIR /src
COPY pyproject.toml poetry.lock ./
RUN pip install --no-cache-dir build
COPY . .
RUN python -m build --wheel

# runtime stage
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /src/dist/*.whl /tmp/app.whl
RUN pip install --no-cache-dir /tmp/app.whl
USER 1000
EXPOSE 8000
CMD ["gunicorn", "myapp:app", "-b", "0.0.0.0:8000"]
```

Example — Go (static binary into scratch)
-----------------------------------------
```dockerfile
FROM golang:1.20-alpine AS builder
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -o myapp ./cmd/myapp

FROM scratch
COPY --from=builder /src/myapp /myapp
EXPOSE 8080
ENTRYPOINT ["/myapp"]
```

Use cases for Docker and multi-stage builds
-----------------------------------------
- Local development: fast feedback loops with bind mounts and lightweight images.
- CI builds: produce reproducible artifacts and push minimal runtime images to registries.
- Production deployments: small runtime images reduce network and storage usage.
- Edge/IoT/serverless: small images shorten cold-start times and fit constrained environments.
- Language-specific optimization: compile once in builder, run minimal runtime image.

Practical tips
--------------
- Use `.dockerignore` to exclude files from the build context.
- Prefer pinned base images (e.g., `node:18.16-alpine`) for reproducibility.
- Clean caches in the build stage where necessary (apt, pip, npm) to keep intermediate layers small.
- Test the final image by running only what will run in production to avoid surprises.


Build, tag and push (Docker CLI)
--------------------------------
```bash
docker build -t myapp:1.0 .
docker tag myapp:1.0 myregistry.example.com/myorg/myapp:1.0
docker push myregistry.example.com/myorg/myapp:1.0
```

GitHub Actions snippet (build and push)
---------------------------------------
```yaml
name: CI
on: [push]
jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - name: Login to registry
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          push: true
          tags: ghcr.io/${{ github.repository_owner }}/myapp:latest
```

Best practices
--------------
- Use multi-stage builds to avoid shipping build-time tools.
- Run as non-root user when possible.
- Minimize layers and prefer pinned base image versions.
- Scan images with an image scanner (Trivy, Snyk) in CI.
- Avoid embedding secrets in images; use runtime Secrets/Secrets Manager.

Security
--------
- Use official, minimal base images (alpine, slim variants).
- Regularly update base images and rebuild images in CI.
- Use image signing and scanning and enforce policies in registry.

Size optimization tips
----------------------
- Clean package caches in the build stage.
- Combine RUN lines where practical to reduce layers.
- Use `.dockerignore` to exclude dev files.

Quick commands reference
------------------------
- `docker build -t <name> .`
- `docker run -p 8080:8080 <name>`
- `docker push <registry>/<name>:<tag>`

Further reading
---------------
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Image scanning: https://github.com/aquasecurity/trivy
