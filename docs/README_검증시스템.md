# dwisCOST 데이터 검증 시스템 - 전체 개요

## 📁 생성된 파일 목록

### 1. SQL 스크립트
- **`src/sql/Validation_CurrentStatus_Analysis.sql`** (20KB)
  - 현재 데이터 정합성 진단 SQL
  - 생산수불/재고수불/원천 데이터 오류 분석
  - **지금 바로 실행 가능!**

- **`src/sql/Create_ValidationTables.sql`** (이전에 생성)
  - 검증 시스템 테이블 생성
  - DOI_VALIDATION_LOG/ERROR/RULE 테이블

### 2. 문서
- **`docs/빠른_시작_가이드.md`** (9.2KB)
  - 즉시 실행 가능한 단계별 가이드
  - SQL 실행 방법
  - 데이터 수정 예시
  - 운영 체크리스트

- **`docs/시스템_셋업_제안서.md`** (30KB)
  - 완전한 시스템 전환 계획서
  - 9주 로드맵
  - 아키텍처 설계
  - 구현 가이드

- **`docs/dwisCOST_메뉴구조_및_기능명세서.md`** (기존)
  - 시스템 전체 구조
  - 메뉴별 기능 설명

## 🚀 지금 바로 시작하기

### Step 1: 현황 진단 (30분)
```bash
PGPASSWORD='qkdlsjfl!35' psql -h binarysoft.hopto.org -p 5433 -U wavice_user -d dowoo_mes_test -f src/sql/Validation_CurrentStatus_Analysis.sql -o diagnosis_report.txt
```

### Step 2: 결과 분석 (1시간)
- diagnosis_report.txt를 Excel로 열기
- 오류 건수 확인
- 우선순위 결정

### Step 3: 데이터 수정 (1-2주)
- 음수 재고 해결
- 생산수불 수식 오류 수정
- 생산-재고 연결 오류 수정

## 📊 검증 규칙 요약

| 코드 | 규칙명 | 심각도 | 용도 |
|-----|--------|--------|------|
| PS001 | 생산수불 수식 | ERROR | 월마감 검증 |
| PS003 | 월간 연결성 | ERROR | 월마감 검증 |
| PS005 | 음수 재고 | ERROR | 월마감 검증 |
| ST001 | 재고 수식 | ERROR | 월마감 검증 |
| ST002 | 생산→재고 연결 | ERROR | 월마감 검증 ⭐ |
| ST003 | 월간 연결성 | ERROR | 월마감 검증 |

## 🎯 두 가지 용도

### 1. 시스템 셋업 (현재 상황)
- 목적: 과거 데이터 정합성 진단 및 수정
- 도구: `Validation_CurrentStatus_Analysis.sql`
- 기간: 최근 3~6개월
- 산출물: 오류 현황 리포트, 수정 계획

### 2. 운영 중 검증 (시스템 구축 후)
- 목적: 월마감 시 데이터 검증 (운영자 수동 실행)
- 도구: ValidationService (C0009001 화면)
- 기간: 전월 데이터 (익월 1~3일)
- 산출물: 검증 리포트, 오류 목록, Excel Export

## �� 구현 일정

```
Week 1-2  : 현황 진단 + 데이터 분석
Week 3-4  : 데이터 클렌징 (음수 재고, 누락 등)
Week 5    : 데이터베이스 설계 + 테이블 생성
Week 6    : 백엔드 개발 (ValidationService)
Week 7    : 프론트엔드 개발 (검증 화면)
Week 8-9  : 테스트 + 운영 전환
```

## 📞 참고 문서

- **빠른 시작**: `docs/빠른_시작_가이드.md`
- **상세 제안서**: `docs/시스템_셋업_제안서.md`
- **시스템 명세**: `docs/dwisCOST_메뉴구조_및_기능명세서.md`
- **로컬 설정**: `LOCAL_SETUP.md`

---

**작성일:** 2025-11-04  
**버전:** 1.0
