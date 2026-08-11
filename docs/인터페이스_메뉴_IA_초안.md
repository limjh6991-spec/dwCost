# VN ERP/MES → CMS 인터페이스 메뉴 IA 초안 (v0.1)

> 목적: 신규 API 수신 화면(18종)이 들어갈 메뉴 구조를 먼저 확정해 화면 개발의 타깃을 제공하고 재작업을 방지.
> 범위: **VN / DWCMSTEST 우선** (HQ 추후). 대상 DB 테이블은 `DOI_VN_IF_*` 스테이징 + 기존 다운스트림.

---

## 1. 설계 원칙  *(v0.2 확정 반영)*
1. **최상위 그룹명은 기존 「타시스템」 유지**. 단 **마스터(①)는 기존 「원가기준정보」 그룹**에 배치하고, **수불·매출·원가/비용/재고(②③④)는 「타시스템」** 에 배치.
2. 각 수신 화면은 공통 UX: **[조회조건 입력] → [API 호출] 버튼 → 결과 그리드 + 적재]**. (기존 "엑셀 업로드" 자리를 "[API 호출]"로 대체)
3. **데이터 도메인별** 하위 그룹: 기초정보 · 수불 · 매출 · 원가/비용/재고.
4. **점진적 노출**: 신규 메뉴는 우선 `SYSADMIN` 권한에만 매핑 → 검증 후 VN 사용자 역할에 오픈. 기존 업로드 메뉴의 숨김/삭제는 마지막 1회 릴리스로 조율.

---

## 2. 목표 메뉴 트리  *(v0.2 확정)*

```
■ 원가기준정보 (기존 그룹)             ← 마스터(기초정보) 수신 화면 배치
│  ├─ 계정코드                [ERP]  DOI_VN_IF_ACCOUNT        (신규)
│  ├─ 언어별계정항목          [ERP]  DOI_VN_IF_ACCLANG        (신규)
│  ├─ 부서코드                [ERP]  DOI_VN_IF_DEPT           (신규)
│  ├─ 품목                    [ERP]  DOI_VN_IF_ITEM           (신규)
│  ├─ 자재코드                [ERP]  DOI_VN_IF_MATERIAL   → doi_vn_material   (기존 '자재조회' 대체)
│  ├─ 공정                    [ERP]  DOI_VN_IF_PROCESS        (신규)
│  └─ 제품별공정별소요자재    [ERP]  DOI_VN_IF_ITEM_PROC_MAT  (신규)

■ 타시스템 (기존 C0007000)             ← 수불·매출·원가/비용/재고 수신 (엑셀업로드→[API 호출])
│
├─ ② 수불
│   ├─ 생산수불                [MES]  DOI_VN_IF_WIP_SUBUL  → doi_vn_prod_resc  (기존 '생산정보 C0007003' 대체, PFL전/후)
│   ├─ 재고수불                [MES]  DOI_VN_IF_FG_SUBUL       (신규)
│   ├─ 기타입출고금액          [ERP]  DOI_VN_IF_ETC_INOUT  → doi_vn_etc_inout  (기존 업로드 대체)
│   ├─ 창고별수불집계          [ERP]  DOI_VN_IF_WH_STOCK_SUM   (신규)
│   └─ 사업단위별수불집계      [ERP]  DOI_VN_IF_BIZ_STOCK_SUM  (신규)
│
├─ ③ 매출
│   ├─ 수출매출품목            [ERP]  DOI_VN_IF_EXP_SALES  → doi_invoice_resc  (기존 '매출정보 C0007005' 대체)
│   ├─ 수출신고필증            [ERP]  DOI_VN_IF_EXP_PERMIT     (신규)
│   └─ 수출Claim              [ERP]  DOI_VN_IF_EXP_CLAIM       (기존 '불량반품 C0007009' 계열)
│
└─ ④ 원가/비용/재고
    ├─ 부서별계정별비용        [ERP]  DOI_VN_IF_DEPT_COST  → doi_dept_cost     (기존 '부서별_계정별_비용 C0007001' 대체)
    ├─ 품목별투입              [ERP]  DOI_VN_IF_ITEM_INPUT     (기존 '자재투입정보 C0007002' 대체)
    └─ 재고금액상세            [ERP]  DOI_VN_IF_STOCK_DETAIL → DOI_MATL_RESC   (신규)
```

> 미완: **창고수불**(정의서 미완성) — 확정 후 ② 수불에 추가.

---

## 3. 인터페이스 → 화면 → 다운스트림 매핑표

| 인터페이스 | 소스 | IF 스테이징 | 다운스트림(기존) | 기존화면 대체 |
|---|---|---|---|---|
| 계정코드 | ERP | DOI_VN_IF_ACCOUNT | (계정 마스터) | 업로드 대체 |
| 언어별계정항목 | ERP | DOI_VN_IF_ACCLANG | – | 신규 |
| 부서코드 | ERP | DOI_VN_IF_DEPT | (부서 마스터) | 업로드 대체 |
| 품목 | ERP | DOI_VN_IF_ITEM | (품목 마스터) | 신규 |
| 자재코드 | ERP | DOI_VN_IF_MATERIAL | **doi_vn_material** | 자재조회 대체 |
| 공정 | ERP | DOI_VN_IF_PROCESS | – | 신규 |
| 제품별공정별소요자재 | ERP | DOI_VN_IF_ITEM_PROC_MAT | (BOM) | 신규 |
| 생산수불 | **MES** | DOI_VN_IF_WIP_SUBUL | **doi_vn_prod_resc** (PFL전/후) | 생산정보(C0007003) |
| 재고수불 | **MES** | DOI_VN_IF_FG_SUBUL | – | 신규 |
| 기타입출고금액 | ERP | DOI_VN_IF_ETC_INOUT | **doi_vn_etc_inout** | 업로드 대체 |
| 창고별수불집계 | ERP | DOI_VN_IF_WH_STOCK_SUM | – | 신규 |
| 사업단위별수불집계 | ERP | DOI_VN_IF_BIZ_STOCK_SUM | – | 신규 |
| 수출매출품목 | ERP | DOI_VN_IF_EXP_SALES | **doi_invoice_resc** | 매출정보(C0007005) |
| 수출신고필증 | ERP | DOI_VN_IF_EXP_PERMIT | – | 신규 |
| 수출Claim | ERP | DOI_VN_IF_EXP_CLAIM | – | 불량반품(C0007009) |
| 부서별계정별비용 | ERP | DOI_VN_IF_DEPT_COST | **doi_dept_cost** | 부서별_계정별_비용(C0007001) |
| 품목별투입 | ERP | DOI_VN_IF_ITEM_INPUT | (doi_expn_matl 투입) | 자재투입정보(C0007002) |
| 재고금액상세 | ERP | DOI_VN_IF_STOCK_DETAIL | **DOI_MATL_RESC** | 신규 |

---

## 4. 기존 메뉴 대체/정리 매핑 (마지막 릴리스 조율 대상)
| 기존 화면 | 현재 | 신규 대체 |
|---|---|---|
| C0007001 부서별_계정별_비용 | 엑셀 업로드 | ④ 부서별계정별비용 [API 호출] |
| C0007002 자재투입정보 | 엑셀 업로드 | ④ 품목별투입 [API 호출] |
| C0007003 생산정보 | 엑셀 업로드 | ② 생산수불 [MES API] |
| C0007005 매출정보 | 엑셀 업로드 | ③ 수출매출품목 [API 호출] |
| C0007009 불량반품 | 엑셀 업로드 | ③ 수출Claim [API 호출] |
| (자재조회/계정코드/부서코드/기타입출고/재고금액상세 업로드) | 엑셀 업로드 | ①/②/④ 대응 [API 호출] |

> 대체가 검증되기 전까지 **기존 업로드 화면은 유지**(병행). 검증 완료 후 숨김/삭제.

---

## 5. 화면 공통 UX (수신 화면 표준)
- 상단: 조회조건(기간 YYYYMM 또는 DateFr/To, factory/workDate 등 인터페이스별) + **[API 호출]** 버튼 (+ SEL_CODE, SITE=VN 고정)
- 호출 → 백엔드 API 클라이언트 → 응답 JSON → `UP_VN_IF_LOAD_*` 적재(삭제 후 재적재) → 결과 그리드
- 하단/별도: **[원가 반영]**(다운스트림 변환: doi_dept_cost 등) — 검증 후 자동/수동 선택
- 상태 표시: 마지막 수신일시(LOAD_DTTM)·건수·request_id

---

## 6. 단계적 노출 방안
1. 인터페이스별 화면 완성 → 메뉴 엔트리 추가 → **SYSADMIN 권한에만** 매핑(현업 미노출)
2. 실호출(TEST 8801)·적재·다운스트림 검증
3. 검증 완료 → VN 사용자 역할에 순차 오픈
4. **최종 릴리스 1회**: 기존 업로드 메뉴 정리 + 신규 메뉴 정식 노출 (공지 포함)

---

## 7. 확정 현황
- ✅ 최상위 그룹명: **「타시스템」 유지**
- ✅ 마스터(①) 위치: **기존 「원가기준정보」 그룹**에 배치 (②③④는 타시스템)
- ⬜ 수출Claim ↔ 불량반품 대응 관계 최종 확인 (남음)
- ⬜ 화면ID 체계(신규 Cxxxxxx 부여 규칙) (남음)
