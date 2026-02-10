# Loadtest 관측 구성 (IaC)

## 목표
1. k6 부하테스트 트래픽을 운영 로그에서 분리해 관측한다.
2. CloudWatch Logs Insights에서 재사용 가능한 쿼리/대시보드를 제공한다.
3. 인스턴스별/경로별 병목 지점을 빠르게 파악한다.

## 적용 범위
1. Terraform (CloudWatch Logs Insights Saved Query + Dashboard)
2. dev/prod 동일 구성

## 적용 내용
1. Saved Query 세트 추가
   - `*-spring-loadtest-*`
   - `*-nginx-loadtest-recent`
   - `*-k6-*`
2. 대시보드 섹션 추가
   - `K6 Loadtest 그룹` 위젯 묶음
3. 쿼리 문법 안정화
   - 문자열 비교는 단일 따옴표 사용
   - 경로 매칭은 `startswith(path, ...)` 사용

## 변경된 파일
1. `aws/modules/app/main.tf`
2. `aws/modules/app/variables.tf`
3. `aws/envs/dev/main.tf`
4. `aws/envs/dev/variables.tf`
5. `aws/envs/dev/terraform.tfvars`
6. `aws/envs/prod/main.tf`
7. `aws/envs/prod/variables.tf`
8. `aws/envs/prod/terraform.tfvars`

## 쿼리 그룹
### Spring Loadtest
1. `*-spring-loadtest-recent`
2. `*-spring-loadtest-errors`
3. `*-spring-loadtest-slow`
4. `*-spring-loadtest-p95-by-path`
5. `*-spring-loadtest-status`

### Nginx Loadtest
1. `*-nginx-loadtest-recent`

### K6 그룹
1. `*-k6-core-recent`
2. `*-k6-sse`
3. `*-k6-by-instance`

## 트러블슈팅
### 1) 대시보드 전체 문법 오류
증상:
1. `token recognition error at: '\'` (MalformedQueryException)

원인:
1. Logs Insights는 쿼리 내 `\"` 같은 백슬래시 이스케이프가 있으면 실패

해결:
1. 모든 쿼리를 단일 따옴표로 변경
2. 문자열 비교는 `path = '/api/...'`

### 2) 경로 매칭 문법 오류
증상:
1. `like "/api/..."` 구문에서 오류 발생

원인:
1. Logs Insights는 `like "/string"` 형식을 허용하지 않음

해결:
1. `startswith(path, '/api/...')`로 변경

## 확인 방법
1. 대시보드 확인
   - dev: `codoc-dev-log-insights`
   - prod: `codoc-prod-log-insights`
2. 쿼리 직접 실행
```
fields @timestamp, path, loadtest, status
| filter loadtest = 'true'
| sort @timestamp desc
| limit 50
```
