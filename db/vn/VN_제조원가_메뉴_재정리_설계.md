# VN 제조_매출원가 메뉴 재정리 설계 (260731)

> 목적: 개발서버 VN `제조_매출원가` 메뉴를 **실제 리팩토링 프로세스**에 맞춰 재정리하고, 각 탭을 **실제 실행 프로시저**에 연결.
> 변경 없이 설계만. 승인 후 3계층(DB메뉴 / Vue탭 / 매퍼) 구현.

## 1. 구조 3계층 (탭 1개 = 아래 3개 세트)
| 계층 | 위치 | 역할 |
|---|---|---|
| ① 메뉴 | `DOI_CM_SYS_RESOURCE` (prod_category='VN') | 탭 노드(SYS_RESOURCE_ID=TABxxx, UPPER=C0003001, TYPE=TAB, SEQ, URL) |
| ② 화면 | `src/main/vue/.../c0003000/C0003001.vue` | `#tab-content-TABxxx` 템플릿 + import + components 등록 |
| ③ 탭 | `.../c0003000/tab/TABxxx.vue` | `<VnProcRunner title="…" queryId="C0003001_VnN" procName="UP_VN_…" />` 한 줄 |
| ④ 매퍼 | `mapper/web/c0003000/C0003000.xml` | `<select id="C0003001_VnN">EXEC UP_VN_… #{yyyymm},#{site},#{selcode}</select>` |

→ 신규 탭 추가 = ①행 INSERT + ②템플릿/import + ③파일 1개 + ④Sch 1개.

## 2. 현재 상태 (지저분)
**C0003001 제조원가 집계** VN 탭:
- 구 HQ식 5탭 **TAB030001~005** (경비집계/가공비배부/재료비집계/재료비배부/재공평가) — VN 미사용/혼란
- 신규 VN 4탭 **TAB030009~012** (①재고조정/②재료비원장/③재료비집계/④재료비배부)
  - Vn1=UP_VN_STOCK_ADJ, Vn2=UP_VN_MATL_RESC, Vn3=UP_VN_MAT_AMT, **Vn4=UP_VN_MAT_COST(→doi_mat_cost, 폐기대상)**
- TAB030002 [DEL] 잔재
- 리팩토링 신규 파이프라인(투입/기초/단가/재공평가)은 **탭·연결 전무**

**C0003000 하위 [DEL] 잔재**: C0003003 비용자재집계, C0003004 재공평가, C0003005 가공비배부, C0003007 경비집계, C0003008 매출원가, C0003009 제품수불

## 3. 목표 구조 — C0003001 제조원가 집계 (실제 프로세스 8탭)
| SEQ | TAB id | 탭명 | queryId | 실행 프로시저 | 산출 테이블 | 조치 |
|---|---|---|---|---|---|---|
| 1 | TAB030009 | ① 재고조정 | C0003001_Vn1 | `UP_VN_STOCK_ADJ` | DOI_VN_STOCK_ADJ, DOI_VN_ETC_INOUT (6272 기타출고→투입 재분류) | 유지 |
| 2 | TAB030010 | ② 재료비원장 | C0003001_Vn2 | `UP_VN_MATL_RESC` | doi_matl_resc | 유지 |
| 3 | TAB030011 | ③ 재료비집계 | C0003001_Vn3 | `UP_VN_MAT_AMT` | doi_mat_amt | 유지 |
| 4 | TAB030013 | ④ 가공비집계 | C0003001_Vn5 | `UP_VN_ACCT_EXPEN`(신규 분리) | doi_acct_expen | **신규** |
| 5 | TAB030014 | ⑤ 투입배부 | C0003001_Vn6 | `UP_VN_EXPN_INPUT` | doi_expn_matl | **신규** |
| 6 | TAB030015 | ⑥ 재공기초 | C0003001_Vn7 | `UP_VN_COST_BOH` | DOI_COST_BOH | **신규** |
| 7 | TAB030016 | ⑦ 재공단가 | C0003001_Vn8 | `UP_VN_COST_UNIT` | doi_cost_unit | **신규** |
| 8 | TAB030017 | ⑧ 재공평가 | C0003001_Vn9 | `UP_VN_WIP_EVAL` | **DOI_COST**(완전생성, 구 UP_VN_COST 대체) | **신규** |

**제거(VN)**: TAB030001~005(구 HQ탭), TAB030012(④재료비배부=UP_VN_MAT_COST, doi_mat_cost 폐기).
※ ④가공비집계: `UP_VN_EXPEN_MATL`이 doi_acct_expen 생성(부산물 doi_expen_matl/doi_boh_amt는 신규 파이프라인 미사용). 추후 doi_acct_expen 전용 프로시저로 분리 가능.

## 4. 목표 구조 — C0003002 매출원가 집계
| SEQ | TAB id | 탭명 | 실행 프로시저 | 산출 |
|---|---|---|---|---|
| 1 | TAB030006 | 제품 수불 | `UP_VN_STOCK_BOH` → `UP_VN_STOCK_COST` | doi_stock_boh / doi_stco |
| 2 | TAB030007 | 매출원가 | `UP_VN_SALE_COST` | doi_slco / doi_sale / doi_smce_cost |
| 3 | TAB030008 | 매출상계 | (기존) | — |
→ VN 매출원가 탭↔프로시저 연결 현황 별도 확인 필요(현재 VnProcRunner 미적용 가능성).

**매출원가측 변경점**: **없음(확인 완료)**. STOCK_BOH/STOCK_COST/SALE_COST의 활성 코드는 전부 **DOI_COST만 참조**(주석 제외 doi_expen_matl 활성참조 0). 이제 UP_VN_WIP_EVAL이 DOI_COST를 직접 생성하므로 매출원가/수불은 **자동으로 신규 원가 사용**. (STOCK_BOH의 doi_expen_matl 1건은 주석 처리된 죽은 코드)

## 5. 실행 순서 (배치/화면 버튼 순)
`①재고조정 → ②재료비원장 → ③재료비집계 → ④가공비집계 → ⑤투입배부 → ⑥재공기초 → ⑦재공단가 → ⑧재공평가` → (매출) `제품수불 → 매출원가`

## 6. 구현 체크리스트 (승인 후)
- [ ] DOI_CM_SYS_RESOURCE: TAB030013~017 INSERT(VN, UPPER=C0003001, TYPE=TAB, SEQ 4~8, URL=/c0003001?tab3Id=TABxxx). TAB030001~005·012 DEL_YN='Y'. 기존 [DEL] 정리.
- [ ] C0003000.xml: C0003001_Vn5~Vn9 select 추가(EXEC 각 프로시저).
- [ ] C0003001.vue: TAB030013~017 템플릿/import/components. TAB030001~005·012 제거.
- [ ] tab/TAB030013~017.vue: VnProcRunner 1줄씩.
- [ ] (매출) C0003002 VN 프로시저 연결 확인.
- [ ] MapperEnum 등 신규 menuId 등록 확인([[mapperenum-registration]]).

## 7. 참고
- 신규 파이프라인 함수/검증: db/vn/VN_원가결산_프로세스.md
- 탭 실행 컴포넌트: VnProcRunner(title, queryId, procName) — 진행/결과 로그 표시.
