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

### 2. [`cloudfront-static-web-app/`](./cloudfront-static-web-app)

A secure, globally distributed static web app hosted on a private S3 bucket and served via CloudFront CDN.

Uses Origin Access Control (OAC) with SigV4 signing to ensure the S3 bucket is never exposed directly to the public internet — all traffic routes through CloudFront with forced HTTPS redirection. Terraform state is stored remotely in a separate, versioned, AES-256-encrypted S3 bucket. A dynamic asset uploader handles MIME-type mapping and file hashing for cache invalidation across all static file types.

→ [Read the full README](./cloudfront-static-web-app/README.md)

---

### 3. [`vpc-peering/`](./vpc-peering)

A secure, multi-region network architecture provisioning an automated and private cross-region VPC Peering connection using Terraform.

Automates the deployment of two isolated Virtual Private Clouds across different AWS regions (us-east-1 and us-west-2), each hosting an Ubuntu EC2 instance. Using a bidirectional requester-accepter model, traffic between the instances routes entirely within the AWS backbone network using private IP addresses, bypassing the public internet for secure, low-latency communication. Included Internet Gateways are strictly confined to handling administrative SSH access, while custom route tables and security groups restrict inter-VPC traffic explicitly to the peered CIDR blocks.

→ [Read the full README](./vpc-peering/README.md)

---

### 4. [`beanstalk-blue-green-deployment/`](./beanstalk-blue-green-deployment)

A zero-downtime blue-green deployment pipeline provisioned on AWS Elastic Beanstalk using Terraform.

Stands up two structurally identical environments — Blue (production) and Green (staging) — each running a different version of a Node.js application on the same instance type, platform, and load balancer configuration. A single AWS CLI CNAME swap promotes Green to production instantly and without redeployment, with Blue retained as a live rollback target. Application bundles are stored in a private, access-blocked S3 bucket and retrieved by Beanstalk via IAM instance role. Terraform state is stored remotely in a versioned, AES-256-encrypted S3 bucket. A three-stage GitLab pipeline handles plan, apply, and manual destroy automatically.

→ [Read the full README](./beanstalk-blue-green-deployment/README.md)

---

### 5. [`auto-ec2-image-builder/`](./auto-ec2-image-builder)

An automated pipeline that builds patched Windows AMIs using EC2 Image Builder, chaining each successful build as the parent image for the next run.

Terraform provisions the static infrastructure — a dedicated VPC, IAM roles, Image Builder components, and the initial pipeline — while GitLab CI handles the per-run work: bumping the recipe version, triggering the build, streaming CloudWatch logs inline, and writing the new AMI ID back to SSM on success. Python, AWS CLI, CloudWatch Agent, and a set of offline Python wheels are baked into every AMI. A separate `Launch-Instance` stage spins up a Windows EC2 instance from the latest AMI with RDP access, creating the key pair, security group, and IAM instance profile on first run if they don't exist.

→ [Read the full README](./auto-ec2-image-builder/README.md)

---

## 🔁 CI/CD Architecture

The root `.gitlab-ci.yml` acts as a **parent pipeline** that selectively triggers child pipelines in each project directory based on which files changed.

```
push to repo
    │
    ▼
Root pipeline (.gitlab-ci.yml)
    ├── simple-web-server/** changed?       → trigger simple-web-server/.gitlab-ci.yml
    ├── cloudfront-static-web-app/** changed? → trigger cloudfront-static-web-app/.gitlab-ci.yml
    ├── vpc-peering/** changed? → trigger vpc-peering/.gitlab-ci.yml
    ├── beanstalk-blue-green-deployment/** changed? → trigger beanstalk-blue-green-deployment/.gitlab-ci.yml
    └── auto-ec2-image-builder/** changed? → trigger auto-ec2-image-builder/.gitlab-ci.yml
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