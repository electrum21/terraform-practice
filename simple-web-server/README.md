# AWS Simple Web Server Deployment using Terraform

## 📌 Project Overview
This project demonstrates the use of **Infrastructure as Code (IaC)** to provision a virtual computing environment on AWS. By using **Terraform**, I’ve automated the deployment of an EC2 instance, ensuring a repeatable and version-controlled infrastructure setup.

---

## 🏗️ Architecture & Resources
The configuration provisions a single instance within the default VPC.

* **Cloud Provider:** AWS (Region: `us-east-1`)
* **Resource Type:** `aws_instance`
* **Machine Image:** Ubuntu Server 22.04 LTS (HVM)
* **Instance Type:** `t3.micro` (Free Tier Eligible)
* **Tags:** Managed by Terraform

---

## 🚀 Deployment Outcome
The infrastructure was successfully initialized and deployed in **17 seconds**. 

### 1. Verification Screenshot
Below is the confirmation from the AWS Management Console showing that the Virtual Private Cloud (VPC) is in an `Available` state:

![AWS Console Proof](screenshots/vpc_screenshot.png)

Below is the confirmation from the AWS Management Console showing that the subnet is in an `Available` state:

![AWS Console Proof](screenshots/subnet_screenshot.png)

Below is the confirmation from the AWS Management Console showing the instance in a `Running` state:

![AWS Console Proof](screenshots/instance_screenshot.png)

### 2. Terminal Apply Log
```text
aws_instance.web-server-instance: Creating...
aws_instance.web-server-instance: Still creating... [10s elapsed]
aws_instance.web-server-instance: Creation complete after 17s [id=i-0022f2e0b9e2572b6]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

## 🔧 Manual Deployment Steps

To replicate this environment, follow these steps:

### Clone the Repository

```bash
git clone https://github.com/electrum21/terraform-practice.git
cd simple-web-server
```

### Initialize & Plan

```bash
terraform init
terraform validate
terraform plan
```

### Apply Configuration

```bash
terraform apply
```

---

## 🛡️ Security & Best Practices

As a Computer Science student with an interest in Cybersecurity, I have implemented the following safeguards:

* **Sensitive Data Protection:**
  A `.gitignore` file is utilized to ensure `terraform.tfstate`, `.terraform/`, and `*.tfvars` are never pushed to version control. This prevents the leakage of infrastructure metadata and credentials.

* **Credential Management:**
  No AWS Access Keys are hardcoded. Authentication is handled via the AWS CLI and environment-level configuration.


---

## 💡 Key Learnings

* **IaC Fundamentals:**
  Moving away from manual console configuration to declarative code.

* **State Management:**
  Understanding the critical role of the state file in tracking resource mappings.


---

## 🧹 Cleanup

To avoid unnecessary AWS costs or clear your workspace entirely, the resources can be destroyed with:

```bash
terraform destroy
```

---
