# VINA 원가결산 프로세스 · 단계별 프로시저 · 산출 테이블 (260731 정정본)

> ★ **VN은 doi_mat_cost / doi_expen_matl 미사용.** 재료비집계(doi_mat_amt)·가공비(doi_acct_expen) 원천에서
>   제품별(도우코드) 배부 → doi_expn_matl → 기초 → 단가 → 재공평가로 직접 흐름.
> 파라미터 공통: `(@YYYYMM, @SITE='VN', @SEL_CODE='ACTUAL')`

## 전체 흐름
```
[재료비 원천]  STOCK_ADJ → MATL_RESC → MAT_AMT ──▶ doi_mat_amt / DOI_VN_MAT_INPUT(직과) / DOI_MATL_RESC(공통)
[가공비 원천]  (부서·계정 집계) ─────────────────▶ doi_acct_expen
                                                        │
[① 투입배부] UP_VN_EXPN_INPUT ──────────────────────────▶ doi_expn_matl (재료 직과/공통+면적, 가공 물량×면적)
[② 기초]     UP_VN_COST_BOH ────────────────────────────▶ DOI_COST_BOH (전월EOH 이월 / 초기 doi_boh_amt seed)
[③ 단가]     UP_VN_COST_UNIT (doi_expn_matl+DOI_COST_BOH+수불) ─▶ doi_cost_unit  = (기초+투입)/(OUT+EOHEQ)
[④ 재공평가] UP_VN_WIP_EVAL (단가+투입+기초+수불) ────────▶ DOI_COST  (완전생성: 수량+금액 BOH/IN/EOH/OUT/LOSS/out_단가 + 기타입고재유입 RMAIN/ETC_IN_DEF_RW + PL전/후_AMT)
```

## 단계별 상세

### 재료비 원천 (기존 로직, doi_mat_amt까지)
| 순 | 프로시저 | 산출 |
|---|---|---|
| 1 | `UP_VN_STOCK_ADJ` | 재고조정(6272 기타출고→투입 재분류) → **DOI_VN_STOCK_ADJ, DOI_VN_ETC_INOUT** |
| 2 | `UP_VN_MATL_RESC` | **doi_matl_resc** (재료비 원장, 공통배부 소스) |
| 3 | `UP_VN_MAT_AMT` | **doi_mat_amt** (재료비 집계) · 직과 소스 = DOI_VN_MAT_INPUT |

### 가공비 원천 (기존 로직, doi_acct_expen까지)
| 순 | 프로시저 | 산출 |
|---|---|---|
| 4 | (부서·계정 집계) | **doi_acct_expen** (부서/원가항목별 투입비용) |

### 【리팩토링 핵심】 투입 → 기초 → 단가 → 재공평가
| 순 | 프로시저 | 입력 | 산출 |
|---|---|---|---|
| ① | **UP_VN_EXPN_INPUT** | DOI_VN_MAT_INPUT(직과)+DOI_MATL_RESC(공통)+doi_acct_expen(가공) | **doi_expn_matl** 투입금액·투입수량(=SUM IN_MONTH) |
| ② | **UP_VN_COST_BOH** | 전월 DOI_COST.EOH(정상월) / doi_boh_amt.PRE_EOH_AMT(초기, 통) | **DOI_COST_BOH** 기초(전액보존) + BOH_QTY |
| ③ | **UP_VN_COST_UNIT** | doi_expn_matl + DOI_COST_BOH + 수불 + V_VN_WIP_CONV(EOHEQ) | **doi_cost_unit** 단가=(기초+투입)/(OUT+EOHEQ) |
| ④ | **UP_VN_WIP_EVAL** (3단계) | doi_cost_unit + doi_expn_matl + DOI_COST_BOH + 수불 | **[1]재공평가→TMP_VN_COST_EOH(EOH) [2]원가조립→TMP_VN_COST(OUT/LOSS/out_단가/기타입고재유입/PL) [3]→DOI_COST**. 단계별 검증로그(EOH대사/원가보존). 구 UP_VN_COST 대체 |

- 공정(PL전/PL후)은 컬럼이 아니라 **EOHEQ = PL전×0.5+PL후×0.9** 로 ③④에서만 반영.
- **② 기초 배분(초기월)**: 통 기초(PRE_EOH_AMT)를 **실제 투입금액 비율**로 원가항목에 배분(재료:가공=실제 투입비, 202606 재료72%). 생산수불 기초 없는 모델은 전액 가공비. 이후월은 전월 EOH 이월. ※ 기존 경비비율(제조경비AA/(AA+재료))은 AA에 원재료비(6211000) 포함되어 경비 과대 → 폐기.
- 생산없는(환산량=0) 재공모델: 재료→MDAX(원장), **가공→실제 가공계정(EDEP/EPOW… 전역 가공구조로 분해)**, ADJ_YN='Y'(기초이월) → ④에서 BOH=EOH(재공 유지).
- 전량손실 모델: OUT=0·EOH=0·LOSS=BOH+IN.

### 수불·매출원가
| 순 | 프로시저 | 산출 |
|---|---|---|
| 11 | `UP_VN_STOCK_BOH` | doi_st_boh_amt, doi_stock_boh, doi_stco, doi_stuc |
| 12 | `UP_VN_STOCK_COST` | **doi_stco** (제품수불원가) |
| 13 | `UP_VN_SALE_COST` | **doi_slco**, doi_sale, doi_smce_cost (매출원가) |

## 산출 테이블 요약
| 테이블 | 생성 프로시저 | 내용 |
|---|---|---|
| doi_matl_resc / doi_mat_amt | UP_VN_MATL_RESC / UP_VN_MAT_AMT | 재료비 원장/집계 |
| doi_acct_expen | (경비집계) | 부서·계정 투입비용 |
| doi_boh_amt | (기초 seed) | 재공기초(경비/재료비, 도우코드) |
| **doi_expn_matl** ⭐ | UP_VN_EXPN_INPUT | 투입 배부(재료+가공, 제품별) |
| **DOI_COST_BOH** ⭐ | UP_VN_COST_BOH / DOI_MAKE_COST_BOH | 기초금액(원가항목) |
| **doi_cost_unit** ⭐ | UP_VN_COST_UNIT | 재공단가 |
| **DOI_COST** | UP_VN_WIP_EVAL(구 UP_VN_COST 대체) | 재공평가·원가 완전생성(수량+금액 전체, 기타입고 재유입 포함) |
| doi_stco / doi_slco … | UP_VN_STOCK_*/SALE_COST | 수불·매출원가 |

⭐ = 리팩토링 신규 (VN 전용). **doi_mat_cost / doi_expen_matl 은 VN 흐름에서 제외.**

## 검증 (202606 VN, 완전 정합)
- 투입배부: 재료 5,124,416.21 / 가공 1,972,637.97
- 기초 전액보존: 1,293,331.16 (= doi_boh_amt), BOH_QTY 수불 정합
- **완전 원가보존**: 투입(BOH+IN) 8,390,385.34 = OUT 6,964,938.79 + EOH 1,415,649 + LOSS 9,797.55 (차 0, 미보존 0건)

## 미결(운영화)
1. 배치/메뉴에 ①~④ 편입 (현재 재료비 원천만 화면 C0003000 버튼화).
2. 수불/매출(D): DOI_COST 참조 자동 반영(UP_VN_WIP_EVAL이 DOI_COST 생성). STOCK_BOH/COST/SALE 활성 doi_expen_matl 참조 0 확인 → 별도 변경 불필요.
3. 운영 DB 반영.
