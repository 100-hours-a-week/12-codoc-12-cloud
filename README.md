# Codoc Cloud Infrastructure (Terraform)

본 레포지토리는 **Codoc 서비스 V1(MVP) 단계의 인프라를 Terraform(IaC)** 으로 관리하기 위한 저장소이다.  
초기 단계에서는 **Big Bang 배포 방식**을 채택하여, 단일 EC2 기반 환경을 빠르고 재현 가능하게 구축하는 것을 목표로 한다.

---

## 1. 도입 배경

Codoc 서비스는 초기 MVP 단계에서 다음과 같은 요구사항을 가진다.

- 빠른 인프라 구축 및 재현 가능성
- 최소 비용으로 운영 가능한 구조
- 애플리케이션 코드(백엔드/프론트엔드/AI)와 인프라 정의의 분리
- 향후 확장(VPC 분리, Private Subnet, VPN, 무중단 배포)을 고려한 설계

이를 위해 **Terraform을 활용한 Infrastructure as Code(IaC)** 방식을 도입하였다.

---

## 2. 기술 스택

- **IaC**: Terraform
- **Cloud Provider**: AWS
- **Region**: ap-northeast-2 (Seoul)
- **OS**: Ubuntu 22.04 LTS
- **Instance Type**: t3.small

---

## 3. V1 인프라 구성 (Big Bang 배포)

V1 단계에서는 **단일 EC2 기반 Big Bang 배포** 구조를 사용한다.  
Terraform을 통해 다음 리소스들을 코드로 정의하였다.

### 3.1 네트워크 (VPC)

- Custom VPC 생성
  - CIDR: `10.10.0.0/16`
- Public Subnet 1개
  - CIDR: `10.10.1.0/24`
- Internet Gateway
- Public Route Table
  - `0.0.0.0/0 → Internet Gateway`

### 3.2 보안 (Security Group)

- EC2 보안 그룹 설정
  - SSH (22) : 허용 (초기 학습 단계에서는 전체 허용)
  - HTTP (80) : 허용
  - HTTPS (443) : 허용
  - Outbound : 전체 허용

> 추후 단계에서는 SSH 접근을 VPN 또는 SSM 기반으로 제한할 계획이다.

### 3.3 컴퓨트 (EC2)

- EC2 인스턴스 1대
  - Ubuntu 22.04 LTS
  - t3.small
  - Root Volume: 15GB (gp3)
- 퍼블릭 IP 자동 할당
- Nginx 기반 Reverse Proxy 구성 예정
  - `/` → 프론트엔드 정적 파일
  - `/api` → 백엔드 (localhost:8080)

---

## 4. Terraform 프로젝트 구조

```text
.
├── aws/
│   ├── main.tf          # VPC, Subnet, SG, EC2 정의
│   ├── variables.tf     # 변수 정의
│   ├── versions.tf     # Terraform / Provider 버전 고정
│   ├── outputs.tf      # 생성 리소스 출력
│   └── .terraform.lock.hcl
├── .gitignore
└── README.md
```

	•	.tf 파일: 인프라 구조(설계도)  
	•	.tfvars 파일: 실제 값(로컬에서만 사용, Git 제외)  
	•	.terraform.lock.hcl: Provider 버전 고정 (재현성 확보)  

---

## 5. Terraform 실행 흐름

Terraform은 로컬 환경에 설정된 AWS 자격증명을 사용하여 실행한다.
```text
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```
	•	plan을 통해 실제 변경 사항을 사전에 검증한 후  
	•	apply를 통해 AWS 리소스를 생성한다.  

> GitHub에는 Terraform 코드만 관리하며,  
> 실제 인프라 생성은 로컬 또는 CI 환경에서 명시적으로 실행한다.

---

## 6. 설계 의도 및 선택 이유

- **IaC 도입**
  - 인프라를 코드로 관리하여 재현성 및 변경 이력 확보

- **Big Bang 배포**
  - MVP 단계에서 복잡도를 낮추고 빠른 검증을 우선

- **단일 EC2 구조**
  - 트래픽이 낮은 초기 서비스 특성에 적합
  - 비용 최소화

- **VPC 직접 구성**
  - 네트워크 구조에 대한 명확한 이해 및 확장 기반 확보

---

## 7. 향후 확장 계획

- Private Subnet 분리
- VPN 서버 또는 AWS Client VPN 도입
- RDS / Managed Service 분리
- ALB 기반 무중단 배포 구조
- dev / prod 환경 분리
- GitHub Actions 기반 Terraform Plan 자동화

---

## 8. 요약

본 Terraform 구성은 Codoc 서비스의 V1 인프라를 빠르고 안전하게 구축하기 위한 최소 단위의 IaC 구현이며,  
향후 서비스 확장과 운영 고도화를 고려한 기반 설계를 목표로 한다.
