# Terraform 작업 기록 (dev/prod)

이 문서는 `aws/` 아래 Terraform 구성만을 기준으로 dev/prod 환경을 구성한 흐름과 현재 구조를 요약한다.

**목표**
1. S3 백엔드로 Terraform state 공유
2. dev 환경 먼저 구성 후 prod 자동화
3. AMI는 이름(`codoc-base-v1`)으로 자동 조회
4. EIC(EC2 Instance Connect) 리소스를 Terraform으로 관리

---

**현재 구조**
1. `aws/modules/app/`  
   VPC/서브넷/라우팅/SG/EC2/EIC Endpoint를 포함하는 공통 모듈
2. `aws/envs/dev/`  
   dev 환경, S3 backend, AMI 이름 기반 조회
3. `aws/envs/prod/`  
   prod 환경, dev state에서 VPC/서브넷/EIC SG 자동 참조
4. `aws/bootstrap/`  
   S3 backend 버킷 생성용(초기 1회)

---

**S3 Backend**
1. 버킷: `codoc-terraform-state`
2. dev state key: `codoc/dev/terraform.tfstate`
3. prod state key: `codoc/prod/terraform.tfstate`

---

**AMI 전략**
1. AMI 이름 기준 조회  
   `ami_name = "codoc-base-v1"`
2. AMI 상태 필터  
   `state = available`, `root-device-type = ebs`
3. `ami_id`는 빈 값으로 두고 자동 조회

---

**EIC 전략**
1. dev VPC에 EIC Endpoint 생성
2. dev에서 생성된 EIC SG를 prod가 재사용
3. prod는 EIC Endpoint 추가 생성하지 않음
4. 보안그룹은 같은 VPC 내에서만 참조

---

**dev 환경 변수 핵심 (`aws/envs/dev/terraform.tfvars`)**
1. `ami_name = "codoc-base-v1"`
2. `create_eic_endpoint = true`
3. `use_existing_vpc = false`

---

**prod 자동 참조**
1. `aws/envs/prod/main.tf`에서 `terraform_remote_state`로 dev state 읽기
2. `vpc_id`, `subnet_id`, `eic_sg_id`를 dev 출력에서 자동 사용
3. prod에서는 `create_eic_endpoint = false`

---

**실행 순서**
1. dev apply  
   `cd aws/envs/dev` → `terraform init` → `terraform apply`
2. prod apply  
   `cd aws/envs/prod` → `terraform init` → `terraform apply`

---

**Terraform 이슈 대응 (요약)**
1. AMI 스냅샷 pending  
   AMI가 `available`일 때만 생성하도록 필터 추가
2. VPC 삭제 지연  
   인스턴스/ENI/EIC 등 의존 리소스가 남아 있으면 삭제 지연
3. 다른 VPC SG 참조 에러  
   같은 VPC 내 SG만 참조 가능
4. EIC Endpoint quota 초과  
   dev에서 만든 EIC Endpoint를 prod가 재사용하도록 변경
