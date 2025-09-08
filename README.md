# README.md


## 1. Что нужно сделать (Flowchart)


```mermaid
flowchart TD
A[Разработчик коммитит код] --> B[GitHub репозиторий]
B --> C[Настроить HelmRelease для kbot]
C --> D[GitHub Actions: build Docker image]
D --> E[Push образ в DockerHub]
E --> F[Обновить HelmRelease в GitHub]
F --> G[FluxCD подтягивает изменения]
G --> H[GKE: приложение kbot обновлено]
```


## 2. Как это работает (Sequence diagram)


```mermaid
sequenceDiagram
participant Dev as Developer
participant GH as GitHub
participant Actions as GitHub Actions
participant Docker as DockerHub
participant Flux as FluxCD
participant GKE as GKE Cluster


Dev->>GH: Push code / HelmRelease changes
GH->>Actions: Trigger workflow
Actions->>Docker: Build & push Docker image
Actions->>GH: Update HelmRelease with new image tag
GH->>Flux: Commit new HelmRelease
Flux->>GKE: Apply manifests
Docker->>GKE: Provide image for Deployment
GKE-->>Dev: kbot app updated