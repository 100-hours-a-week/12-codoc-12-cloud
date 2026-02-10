# AWS IaC Notes

This folder contains Terraform for provisioning the EC2-based app environment.

## CloudWatch Logs Insights (Loadtest)

The app module can create:
1. Saved Logs Insights queries for loadtest analysis
2. A Logs Insights dashboard that visualizes those queries

### Why loadtest queries are separate

Loadtest traffic is intentionally separated from general operational monitoring so that:
1. Production incidents are not hidden by synthetic traffic
2. Dashboards remain actionable for on-call use
3. You can compare loadtest behavior without noise from real users

### What gets created

Saved queries (Spring):
1. `*-spring-loadtest-recent`
2. `*-spring-loadtest-errors`
3. `*-spring-loadtest-slow`
4. `*-spring-loadtest-p95-by-path`
5. `*-spring-loadtest-status`
6. `*-k6-core-recent`
7. `*-k6-sse`
8. `*-k6-by-instance`

Saved queries (Nginx):
1. `*-nginx-loadtest-recent`

Dashboard:
1. `*-log-insights` (includes K6 group widgets)

## 작업 요약 (2026-02-09)

### 목표
1. k6 부하테스트 트래픽을 서버 로그에서 식별 가능하게 하기
2. CloudWatch Logs Insights에 loadtest 전용 쿼리/대시보드 구성
3. 인스턴스별/경로별 관찰을 쉽게 만들기

### 적용된 변경 (Backend)
1. `LoadtestMdcFilter`가 `X-Loadtest` 헤더를 MDC로 넣고, 로그 스키마에서 `loadtest` 필드를 출력
2. 필터 순서를 명시적으로 고정 (LoadtestMdcFilter -> LoggingContextFilter)

관련 파일:
1. `../12-codoc-12-be/src/main/java/_ganzi/codoc/global/config/LoadtestMdcFilter.java`
2. `../12-codoc-12-be/src/main/java/_ganzi/codoc/global/log/LoggingContextFilter.java`
3. `../12-codoc-12-be/src/main/java/_ganzi/codoc/global/log/LogstashFixedSchemaProvider.java`
4. `../12-codoc-12-be/src/main/java/_ganzi/codoc/global/config/FilterConfig.java`

### 적용된 변경 (IaC / CloudWatch)
1. Logs Insights Saved Query 세트 생성
2. Logs Insights 대시보드에 K6 그룹 위젯 추가
3. 쿼리 문자열 문법 수정 (CloudWatch Logs Insights는 단일 따옴표를 안정적으로 처리)

관련 파일:
1. `aws/modules/app/main.tf`
2. `aws/modules/app/variables.tf`
3. `aws/envs/dev/main.tf`
4. `aws/envs/dev/variables.tf`
5. `aws/envs/dev/terraform.tfvars`
6. `aws/envs/prod/main.tf`
7. `aws/envs/prod/variables.tf`
8. `aws/envs/prod/terraform.tfvars`

## 진행 과정 요약

1. `X-Loadtest: true` 헤더 기반 식별을 설계
2. k6 스크립트에서 헤더가 포함되는지 확인
3. 로그에 `loadtest`가 null로 나오는 문제 확인
4. 원인: 필터 실행 순서 (LoggingContextFilter가 먼저 실행됨)
5. FilterConfig에 등록 순서를 명시하여 해결
6. CloudWatch Logs Insights 쿼리/대시보드 추가
7. 쿼리 문법 오류 해결 (백슬래시/큰따옴표 제거, `startswith` 사용)

## 확인 방법

1. 헤더 확인 테스트
```
curl -H "X-Loadtest: true" https://dev.codoc.cloud/api/health
```

2. Logs Insights 확인
```
fields @timestamp, path, loadtest, status
| filter path="/api/health"
| sort @timestamp desc
| limit 20
```

3. K6 전용 대시보드
`codoc-dev-log-insights`, `codoc-prod-log-insights`

## 주의 사항

1. CloudWatch Logs Insights는 쿼리 내부에 `\"` 형태의 백슬래시가 있으면 오류가 날 수 있음
2. `like "/path"` 문법 대신 `startswith(path, "/path")` 사용 권장
3. Terraform `-target` 적용은 임시 수단 (SG 변경 회피 목적)
### Required variables

Set these in `aws/envs/dev/terraform.tfvars` or `aws/envs/prod/terraform.tfvars`:
1. `spring_log_group_names`
2. `nginx_log_group_names`

If either list is empty, the corresponding saved queries and dashboard widgets are not created.

### Toggle

You can disable all Logs Insights resources:
1. `enable_log_insights = false`

### Expected log fields

The loadtest queries assume:
1. Spring logs include JSON fields `path`, `status`, `latency`, `loadtest`
2. Nginx logs include JSON fields `uri`, `status`, `request_time`, `upstream_time`, `loadtest`

Example:
1. `spring_log_group_names = ["codoc-be-access", "codoc-be-error"]`
2. `nginx_log_group_names  = ["codoc-nginx-access"]`

### Apply

From each environment:
1. `terraform plan`
2. `terraform apply`
