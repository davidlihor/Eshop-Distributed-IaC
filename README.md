# E-Shop Infrastructure as Code (IaC)

[![GitLab CI](https://img.shields.io/badge/CI-GitLab-orange?logo=gitlab)](https://gitlab.com)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![Security](https://img.shields.io/badge/Security-DevSecOps-green?logo=security)](https://www.devsecops.org/)

> **Enterprise-grade DevSecOps infrastructure** for E-Commerce microservices platform on AWS EKS with automated GitOps workflows, comprehensive security controls, and production-ready observability.

---

## 📋 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [Security Stack](#-security-stack)
- [Infrastructure Components](#-infrastructure-components)
- [Observability Stack](#-observability-stack)
- [GitOps Flow](#-gitops-flow)
- [Prerequisites](#-prerequisites)
- [Infrastructure Bootstrap](#-infrastructure-bootstrap)
- [Deployment](#-deployment)
- [Pipeline Stages](#-pipeline-stages)
- [Cost Optimization](#-cost-optimization)

---

## 🏗 Architecture Overview

This project implements a **two-tier Infrastructure as Code** architecture for deploying and managing a secure microservices platform:

```
┌─────────────────────────────────────────────────────────────┐
│                      GitLab CI/CD                           │
│  (OIDC Authentication + Security Scanning)                  │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
   ┌────▼────┐              ┌─────▼─────┐
   │  Infra  │              │  Config   │
   │  Layer  │─────────────▶│   Layer   │
   └────┬────┘              └─────┬─────┘
        │                         │
        │    ┌───────────────────┴──────────────────────┐
        │    │                                           │
   ┌────▼────▼──────────────────────────────────────────▼───┐
   │              AWS EKS Cluster (Kubernetes 1.34)         │
   │  ┌──────────┐  ┌─────────┐  ┌──────────┐  ┌─────────┐│
   │  │  ArgoCD  │  │ Istio   │  │   LGTM   │  │   ESO   ││
   │  │ (GitOps) │  │ Mesh    │  │  Stack   │  │ Secrets ││
   │  └──────────┘  └─────────┘  └──────────┘  └─────────┘│
   └────────────────────────────────────────────────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         │                  │                  │
    ┌────▼────┐      ┌──────▼──────┐    ┌─────▼─────┐
    │   RDS   │      │  ElastiCache│    │  AmazonMQ │
    │PostgreSQL│     │   (Valkey)  │    │ (RabbitMQ)│
    └─────────┘      └─────────────┘    └───────────┘
```

### Key Design Principles

- **Infrastructure as Code**: 100% declarative infrastructure using Terraform
- **GitOps**: ArgoCD for continuous deployment and drift detection
- **Security-First**: Multi-layered security controls, encryption at rest/transit, IAM least privilege
- **Zero-Trust Networking**: Service mesh with mTLS, network policies, private subnets
- **Observability**: Unified LGTM stack (Loki, Grafana, Tempo, Mimir) with S3 backend
- **Compliance**: Automated security scanning (Trivy, Checkov), secrets management (ESO)

---

## 🔒 Security Stack

### 1. **Identity & Access Management (IAM)**

| Component | Authentication Method | Principle |
|-----------|----------------------|-----------|
| **GitLab CI/CD** | OIDC Web Identity Federation | Keyless authentication, no long-lived credentials |
| **EKS Workloads** | EKS Pod Identity (IRSA successor) | Service-specific IAM roles with least privilege |
| **GitLab Runner** | EC2 Instance Profile | Scoped permissions for Terraform operations |

### 2. **Secret Management**

- **External Secrets Operator (ESO)**: Synchronizes secrets from AWS Secrets Manager to Kubernetes
- **AWS Secrets Manager**: Central secret storage with KMS encryption
- **KMS Encryption**: Dedicated customer-managed keys for:
  - EKS cluster secrets encryption
  - Database credentials (PostgreSQL master passwords)
  - Application secrets (RabbitMQ, service-specific credentials)
  - S3 objects (monitoring data)

### 3. **Network Security**

```
┌─────────────────────────────────────────────────────┐
│                    VPC (10.0.0.0/16)                │
│                                                     │
│  ┌──────────────────┐      ┌──────────────────┐   │
│  │  Public Subnets  │      │ Private Subnets  │   │
│  │   (NAT Gateway)  │─────▶│  (EKS Nodes)     │   │
│  └──────────────────┘      └────────┬─────────┘   │
│                                     │             │
│                            ┌────────▼────────┐    │
│                            │ Data Subnets    │    │
│                            │ (RDS, MQ, Cache)│    │
│                            └─────────────────┘    │
└─────────────────────────────────────────────────────┘
```

- **Private EKS Endpoints**: Node-to-control plane communication within VPC
- **VPC Endpoints**: Private connectivity to AWS services (ECR, STS, Secrets Manager)
- **Security Groups**: Least-privilege ingress/egress rules per service
- **Network Policies**: Kubernetes-native pod-to-pod traffic control

### 4. **Compute Security**

- **IMDSv2 Enforcement**: Mandatory token-based metadata access (prevents SSRF attacks)
- **EBS Encryption**: All node volumes encrypted with customer-managed KMS keys
- **Dedicated Node Groups**: 
  - `apps`: Application workloads (auto-scaling 1-3 nodes)
  - `mgmt`: Management tools with taints (ArgoCD, monitoring)
- **AL2023 AMI**: Latest Amazon Linux 2023 with security patches

### 5. **CI/CD Security**

Automated security scanning integrated into GitLab pipeline:

| Stage | Tool | Purpose | Fail on Critical |
|-------|------|---------|------------------|
| **Secret Detection** | GitLab Secret Detection | Scans for hardcoded credentials | ✅ Yes |
| **IaC Scanning** | Trivy | Terraform misconfiguration detection | ✅ Yes |
| **Compliance** | Checkov | CIS benchmarks, best practices | ✅ Yes |
| **SAST** | Multiple | Static analysis security testing | ✅ Yes |

---

## 🛠 Infrastructure Components

### Core Infrastructure (`infra/`)

| Resource | Technology | Purpose |
|----------|-----------|---------|
| **Container Orchestration** | AWS EKS 1.34 | Kubernetes control plane with IRSA enabled |
| **Service Mesh** | Istio 1.28.3 | mTLS, traffic management, observability |
| **Load Balancing** | AWS Load Balancer Controller | Gateway API + ALB integration |
| **GitOps** | ArgoCD 9.3.4 | Continuous deployment and sync |
| **Networking** | AWS VPC Module | Multi-AZ, 3-tier subnet architecture |
| **Database** | RDS PostgreSQL 17 | Multi-AZ, encrypted, automated backups |
| **Cache** | ElastiCache Valkey 8 | In-memory cache for microservices |
| **Message Queue** | Amazon MQ (RabbitMQ) | Event-driven communication |
| **CI Runner** | EC2 Auto Scaling Group | Private VPC GitLab Runner |
| **Storage** | S3 + EBS CSI | Object storage for monitoring, encrypted EBS volumes |

### Configuration Layer (`config/`)

Provisions application-level resources **after** infrastructure deployment:

- **Database Provisioning**: Creates PostgreSQL databases and users per microservice
- **Secret Generation**: Generates and stores service-specific credentials in Secrets Manager
- **RabbitMQ Setup**: Creates virtual hosts and users for event-driven architecture
- **Access Control**: Configures fine-grained IAM policies for workload identities

> **Note**: This layer runs on a **private GitLab Runner** deployed in the VPC to access internal resources.

---

## 📊 Observability Stack

**LGTM Stack** (production-grade monitoring):

```
┌──────────────────────────────────────────────────────┐
│                   Grafana (UI)                       │
└───┬──────────────┬──────────────┬──────────────┬────┘
    │              │              │              │
┌───▼────┐   ┌─────▼─────┐  ┌────▼────┐   ┌────▼────┐
│  Loki  │   │   Mimir   │  │  Tempo  │   │ Alloy   │
│  Logs  │   │  Metrics  │  │ Traces  │   │ Collector│
└───┬────┘   └─────┬─────┘  └────┬────┘   └─────────┘
    │              │              │
    └──────────────┴──────────────┘
                   │
            ┌──────▼──────┐
            │  S3 Buckets │
            │  (Backend)  │
            └─────────────┘
```

### Features

- **Centralized Logging**: All pod logs aggregated in Loki with S3 long-term storage
- **Metrics**: Prometheus-compatible metrics stored in Mimir (scalable, multi-tenant)
- **Distributed Tracing**: End-to-end request tracing across microservices
- **IAM Integration**: Pod Identity associations for secure S3 access (no static credentials)
- **Cost-Efficient**: S3 backend reduces storage costs vs. in-cluster persistence

---

## 🔄 GitOps Flow

```
┌──────────────┐
│ Git Push     │
│ (IaC Changes)│
└──────┬───────┘
       │
┌──────▼────────────────────────────────────────────┐
│          GitLab CI Pipeline                       │
│  ┌──────────┐  ┌──────────┐  ┌─────────────┐    │
│  │ Validate │─▶│ Security │─▶│ Plan/Apply  │    │
│  │ (fmt)    │  │ Scanning │  │ (Terraform) │    │
│  └──────────┘  └──────────┘  └─────────────┘    │
└───────────────────────┬───────────────────────────┘
                        │
                ┌───────▼────────┐
                │   AWS EKS      │
                │  (State Change)│
                └───────┬────────┘
                        │
                ┌───────▼────────┐
                │    ArgoCD      │
                │ (Sync K8s Apps)│
                └────────────────┘
```

### Pipeline Workflow

1. **Code Push**: Developer pushes Terraform changes to GitLab
2. **OIDC Authentication**: GitLab CI assumes AWS role via Web Identity Token
3. **Validation**: `terraform fmt` and `terraform validate` checks
4. **Security Scan**: Trivy + Checkov analyze IaC for vulnerabilities
5. **Plan**: Generate execution plan, review in GitLab UI
6. **Manual Approval**: Senior engineer approves apply (main branch only)
7. **Apply**: Terraform provisions/updates AWS resources
8. **ArgoCD Sync**: Detects cluster changes, deploys/updates applications

---

## ✅ Prerequisites

### Required Tools

- **Terraform** >= 1.13
- **AWS CLI** v2
- **kubectl** >= 1.30
- **GitLab Account** (SaaS or self-hosted with OIDC support)

### AWS Resources (Manual Setup)

1. **S3 Bucket** for Terraform state (see Bootstrap section)
2. **OIDC Identity Provider** for GitLab authentication
3. **IAM Role** for GitLab CI/CD with Terraform permissions
4. **Secrets Manager Secret** for GitLab Runner registration token

---

## 🚀 Infrastructure Bootstrap & Security

> **Important**: These steps must be completed **before** running the Terraform pipeline.

### Step 1: Create Terraform State Backend

```bash
# Replace <your-aws-account-id> with your actual AWS account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION="us-east-1"
export STATE_BUCKET="eshop-terraform-state-${AWS_ACCOUNT_ID}"

# Create S3 bucket for state storage
aws s3api create-bucket \
    --bucket "${STATE_BUCKET}" \
    --region "${AWS_REGION}"

# Enable versioning (protects against accidental deletions)
aws s3api put-bucket-versioning \
    --bucket "${STATE_BUCKET}" \
    --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
    --bucket "${STATE_BUCKET}" \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }'

# Block public access
aws s3api put-public-access-block \
    --bucket "${STATE_BUCKET}" \
    --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### Step 2: Create GitLab Runner Authentication Secret

```bash
# Obtain the runner token from GitLab:
# Settings > CI/CD > Runners > New project runner > Copy registration token

aws secretsmanager create-secret \
    --name "gitlab/runner/token" \
    --description "GitLab Runner authentication token (Private VPC)" \
    --secret-string "<your-runner-registration-token>" \
    --region "${AWS_REGION}"
```

### Step 3: Configure OIDC Identity Provider

#### 3.1 Create OIDC Provider

```bash
aws iam create-open-id-connect-provider \
    --url "https://gitlab.com" \
    --client-id-list "https://gitlab.com" \
    --thumbprint-list "b3dd7606d2b5a8b4a13771dbecc9ee1cecafa38a"
```

#### 3.2 Create IAM Role for GitLab CI/CD

Create a file `gitlab-trust-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<your-aws-account-id>:oidc-provider/gitlab.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "gitlab.com:aud": "https://gitlab.com"
        },
        "StringLike": {
          "gitlab.com:sub": "project_path:<your-gitlab-group>/<your-gitlab-project>:ref_type:branch:ref:*"
        }
      }
    }
  ]
}
```

Create the IAM role:

```bash
# Replace placeholders in the JSON file first
aws iam create-role \
    --role-name GitLab-CI-Role \
    --assume-role-policy-document file://gitlab-trust-policy.json \
    --description "Role for GitLab CI/CD OIDC authentication"

# Attach required policies (adjust based on your needs)
aws iam attach-role-policy \
    --role-name GitLab-CI-Role \
    --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

aws iam attach-role-policy \
    --role-name GitLab-CI-Role \
    --policy-arn arn:aws:iam::aws:policy/IAMFullAccess
```

> **Security Note**: In production, replace `PowerUserAccess` and `IAMFullAccess` with custom policies following least privilege.

### Step 4: Configure GitLab CI/CD Variables

Navigate to your GitLab project: **Settings > CI/CD > Variables**

Add the following variables:

| Variable Name | Value | Protected | Masked |
|--------------|-------|-----------|--------|
| `AWS_AUD` | `https://gitlab.com` | ✅ | ❌ |
| `AWS_ROLE_ARN` | `arn:aws:iam::<your-account-id>:role/GitLab-CI-Role` | ✅ | ❌ |
| `TF_STATE_BUCKET` | `eshop-terraform-state-<your-account-id>` | ✅ | ❌ |

**Replace** `<your-account-id>` with your actual AWS account ID.

---

## 🔧 Deployment

### 1. Clone Repository

```bash
git clone <your-repo-url>
cd Eshop-IaC
```

### 2. Review Variables

Edit `infra/variables.tf` and `config/variables.tf` to customize:

- AWS region
- Cluster name
- Environment (dev/staging/production)
- Node instance types
- Scaling configurations

### 3. Deploy Infrastructure Layer

```bash
# Push to main branch triggers the pipeline
git add .
git commit -m "feat: initialize infrastructure"
git push origin main
```

**Pipeline Flow**:
1. ✅ `terraform fmt` validation
2. 🔍 Security scanning (Trivy, Checkov)
3. 📋 `terraform plan` (automatic)
4. ⏸️ **Manual approval required**
5. 🚀 `terraform apply` (deploys EKS, networking, RDS, etc.)

### 4. Deploy Configuration Layer

After infrastructure apply completes:

```bash
# The config_plan stage runs automatically using the private runner
# Review the plan in GitLab pipeline UI
# Approve the manual step to apply
```

**Configuration Layer Actions**:
- Creates PostgreSQL databases per microservice
- Generates and stores service credentials in Secrets Manager
- Configures RabbitMQ virtual hosts and users

### 5. Access Cluster

```bash
# Update kubeconfig
aws eks update-kubeconfig \
    --region us-east-1 \
    --name eshop-eks

# Verify connectivity
kubectl get nodes
kubectl get pods -A
```

### 6. Access ArgoCD

```bash
# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" | base64 -d && echo

# Port-forward to access UI
kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:443

# Open browser: https://localhost:8080
# Username: admin
# Password: <from previous command>
```

---

## 📦 Pipeline Stages

### **Stage 1: Validate**
- `terraform_fmt_infra`: Format validation for infrastructure code
- `terraform_fmt_config`: Format validation for configuration code
- `terraform_validate_infra`: Syntax and logic validation
- `terraform_validate_config`: Configuration layer validation

### **Stage 2: Security**
- `secret_detection`: GitLab native secret scanning
- `trivy_scan_infra`: IaC vulnerability scanning (SARIF reports)
- `trivy_scan_config`: Configuration security analysis
- `checkov_scan_infra`: CIS benchmarks and best practices
- `checkov_scan_config`: Compliance checks

### **Stage 3: Infrastructure Plan**
- `terraform_plan_infra`: Generate execution plan for infrastructure layer
- Artifacts: `tfplan` binary (expires in 1 week)

### **Stage 4: Infrastructure Apply** (Manual)
- `terraform_apply_infra`: Provisions AWS resources
- **Requires**: Manual approval on main branch
- **Deploys**: VPC, EKS, RDS, ElastiCache, MQ, IAM roles, S3 buckets

### **Stage 5: Configuration Plan**
- `terraform_plan_config`: Generate plan for application configuration
- **Runner**: `private-vpc-runner` (accesses internal resources)
- **Dependencies**: Waits for `terraform_apply_infra`

### **Stage 6: Configuration Apply** (Manual)
- `terraform_apply_config`: Configures databases, secrets, users
- **Runner**: `private-vpc-runner`

### **Stage 7: Destroy** (Manual, Main Branch Only)
- `terraform_destroy_config`: Removes application configuration
- `terraform_destroy_infra`: Destroys infrastructure (ordered)

---

## 💰 Cost Optimization

### Development Environment (`is_production = false`)

| Resource | Configuration | Monthly Cost (Estimate) |
|----------|--------------|-------------------------|
| EKS Control Plane | 1x cluster | $72 |
| EC2 Nodes (apps) | 2x m7i-flex.large | ~$90 |
| EC2 Nodes (mgmt) | 0x (scaled to 0) | $0 |
| RDS PostgreSQL | db.t4g.micro (dev tier) | ~$15 |
| ElastiCache | cache.t4g.micro | ~$12 |
| AmazonMQ | mq.t3.micro | ~$15 |
| NAT Gateway | 1x NAT (multi-AZ optional) | ~$32 |
| **Total** | | **~$236/month** |

### Production Environment (`is_production = true`)

- Auto-scaling: 3-5 nodes (apps), 1-2 nodes (mgmt)
- Multi-AZ RDS with read replicas
- Larger instance types for performance
- **Estimated**: ~$500-800/month

### Cost-Saving Tips

1. **Stop Development Environments**: Scale EKS node groups to 0 during non-working hours
2. **Use Spot Instances**: Configure mixed instance types for non-critical workloads
3. **S3 Lifecycle Policies**: Move monitoring data to Glacier after 90 days
4. **Reserved Instances**: Commit to 1-year RDS/ElastiCache reservations (40% savings)

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Ensure code passes `terraform fmt` and security scans
4. Commit with conventional commits (`feat:`, `fix:`, `docs:`)
5. Push and create a Merge Request

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 📧 Contact

For questions or support, please open an issue in the repository.

---

**Built with ❤️ for DevSecOps excellence**