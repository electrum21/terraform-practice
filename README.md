# Terraform Practice

A collection of **AWS** infrastructure projects built with **Terraform** and automated via **GitLab CI/CD**. Each project lives in its own subdirectory with its own pipeline and README.

The repository is hosted on GitHub and automatically mirrored to GitLab, where the CI/CD pipelines run.

---

## 📂 Projects

### 1. [`simple-web-server/`](./simple-web-server)

A fully networked Apache web server provisioned from scratch on AWS — no default VPC.

Covers a complete networking stack (VPC → Internet Gateway → Route Table → Subnet → Security Group → NIC → Elastic IP → EC2), with Terraform state stored remotely in S3. A three-stage GitLab pipeline handles plan, apply, and manual destroy automatically.

→ [Read the full README](./simple-web-server/README.md)

---

### 2. [`multi-vpc-architecture/`](./multi-vpc-architecture)

> 🚧 Work in progress

A layered, multi-VPC architecture using reusable Terraform modules. Designed around a hub-and-spoke model with a Transit Gateway connecting isolated VPCs for an intranet and an intranet-facing application.

---

### 3. [`cloudfront-static-web-app/`](./cloudfront-static-web-app)

A secure, globally distributed static web app hosted on a private S3 bucket and served via CloudFront CDN.

Uses Origin Access Control (OAC) with SigV4 signing to ensure the S3 bucket is never exposed directly to the public internet — all traffic routes through CloudFront with forced HTTPS redirection. Terraform state is stored remotely in a separate, versioned, AES-256-encrypted S3 bucket. A dynamic asset uploader handles MIME-type mapping and file hashing for cache invalidation across all static file types.

→ [Read the full README](./cloudfront-static-web-app/README.md)

---

## 🔁 CI/CD Architecture

The root `.gitlab-ci.yml` acts as a **parent pipeline** that selectively triggers child pipelines in each project directory based on which files changed.

```
push to repo
    │
    ▼
Root pipeline (.gitlab-ci.yml)
    ├── simple-web-server/** changed?       → trigger simple-web-server/.gitlab-ci.yml
    ├── multi-vpc-architecture/** changed?  → trigger multi-vpc-architecture/.gitlab-ci.yml
    └── cloudfront-s3-static-web/** changed? → trigger cloudfront-s3-static-web/.gitlab-ci.yml
```

Each child pipeline runs independently with its own stages and state. The `strategy: depend` setting means the parent pipeline's status reflects the outcome of whichever child pipelines were triggered — a failing child marks the parent as failed.

This means changes scoped to one project never trigger unnecessary pipeline runs in the other.

---

## 🔗 GitHub → GitLab Mirroring

The repository is mirrored from GitHub to GitLab on every push and delete event via a GitHub Actions workflow (`.github/workflows/mirror.yml`). GitLab is where the Terraform CI/CD pipelines actually execute.

```
GitHub (source of truth)
    │  push / delete event
    ▼
GitHub Actions: mirror.yml
    │  git mirror
    ▼
GitLab (pipeline execution)
```

---

## 🛠️ Stack

| Tool | Role |
|---|---|
| Terraform | Infrastructure as Code |
| AWS | Cloud provider |
| GitLab CI/CD | Pipeline execution |
| GitHub Actions | Repository mirroring |
| S3 | Remote Terraform state storage |