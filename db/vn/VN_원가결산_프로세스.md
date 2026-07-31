# VINA 원가결산 프로세스 · 단계별 프로시저 · 산출 테이블 (260731)

> 리팩토링(투입/기초/단가/재공평가 분리) 반영 최신본. **VN 전용**(본사는 UP_DOI_* 별도).
> 파라미터 공통: `(@YYYYMM, @SITE='VN', @SEL_CODE='ACTUAL')`

## 전체 흐름
```
[A 재료비]  STOCK_ADJ → MATL_RESC → MAT_AMT → MAT_COST ─┐
[B 경비]    EXPEN_MATL ────────────────────────────────┤─▶ [C 조립] UP_VN_COST → DOI_COST
                                                        │
[E 리팩토링 신규] (C 이후)  EXPN_INPUT → COST_BOH → COST_UNIT → WIP_EVAL ─▶ 신규 3테이블 + DOI_COST(EOH/PL) 반영
                                                        │
[D 수불/매출]  STOCK_BOH → STOCK_COST → SALE_COST ──────┘
```

## 단계별 상세

### A. 재료비 파이프라인  (화면 C0003000 ①~④ 버튼)
| 순 | 프로시저 | 역할 | 산출 테이블 |
|---|---|---|---|
| 1 | `UP_VN_STOCK_ADJ` | 재고조정(6272 기타출고→투입 재분류) | doi_prod_subul(조정) |
| 2 | `UP_VN_MATL_RESC` | 재료비 원장 | **doi_matl_resc** |
| 3 | `UP_VN_MAT_AMT` | 재료비 집계 | **doi_mat_amt** |
| 4 | `UP_VN_MAT_COST` | 재료비 배부(직과/공통, 도우코드, 면적, BOH, 단가) | **doi_mat_cost** |

### B. 경비집계
| 순 | 프로시저 | 역할 | 산출 테이블 |
|---|---|---|---|
| 5 | `UP_VN_EXPEN_MATL` | 부서·계정 투입 → 물량×면적 배부(도우코드), 기초 경비/재료비 분배 | **doi_acct_expen**, **doi_boh_amt**(기초설정), **doi_expen_matl** |

### C. 가공비·재료비 조립 → 원가
| 순 | 프로시저 | 역할 | 산출 테이블 |
|---|---|---|---|
| 6 | `UP_VN_COST` | doi_mat_cost + doi_expen_matl 조립 → BOH/IN/EOH/OUT + PL전/후_AMT | **DOI_COST** |

### E. 【신규 리팩토링】 투입·기초·단가·재공평가 분리  (C 이후 실행)
> 소스 = C까지의 결과(doi_mat_cost/doi_expen_matl) 추출. 총액 보존. **재공평가를 투입에서 분리.**

| 순 | 프로시저 | 역할 | 산출 테이블 |
|---|---|---|---|
| 7 | `UP_VN_EXPN_INPUT` | 투입(재료+가공, 도우코드×공정×항목, 수량/금액) | **doi_vn_expn_matl** |
| 8 | `UP_VN_COST_BOH` | 기초금액(재료 BOH_AMT + 가공 boh) | **DOI_COST_BOH** |
| 9 | `UP_VN_COST_UNIT` | 재공단가 = (기초+투입)/(OUT+EOHEQ) | **doi_cost_unit** |
| 10 | `UP_VN_WIP_EVAL` | 재공평가: EOH=단가×EOHEQ, PL전/후/입고전_AMT | **doi_cost_wip** + **DOI_COST**(EOH/PL 반영) |

보조: `V_VN_PROCESS_RATE`(공정 PL전/PL후 비율 뷰) · `V_VN_WIP_CONV`(EOHEQ) 사용.

### D. 수불·매출원가
| 순 | 프로시저 | 역할 | 산출 테이블 |
|---|---|---|---|
| 11 | `UP_VN_STOCK_BOH` | 제품수불 기초 | **doi_st_boh_amt**, **doi_stock_boh**, doi_stco, doi_stuc |
| 12 | `UP_VN_STOCK_COST` | 제품수불 원가 | **doi_stco** |
| 13 | `UP_VN_SALE_COST` | 매출원가(모델/거래선 배부) | **doi_slco**, **doi_sale**, **doi_smce_cost** |

### 보조(기초금액 관리)
| 프로시저 | 역할 | 산출 테이블 | 화면 |
|---|---|---|---|
| `DOI_MAKE_COST_BOH` | 전월 DOI_COST.EOH → 당월 기초 이월 | DOI_COST_BOH | C0007010 |

## 산출 테이블 요약 (프로시저 → 테이블)
| 테이블 | 생성 프로시저 | 내용 |
|---|---|---|
| doi_matl_resc | UP_VN_MATL_RESC | 재료비 원장 |
| doi_mat_amt | UP_VN_MAT_AMT | 재료비 집계 |
| doi_mat_cost | UP_VN_MAT_COST | 재료비 배부(직과/공통/BOH/단가) |
| doi_acct_expen | UP_VN_EXPEN_MATL | 부서·계정 투입비용 |
| doi_boh_amt | UP_VN_EXPEN_MATL | 재공기초(경비/재료비 분배) |
| doi_expen_matl | UP_VN_EXPEN_MATL | 경비/가공비 집계 |
| **DOI_COST** | UP_VN_COST (+WIP_EVAL) | 제조원가(BOH/IN/EOH/OUT/PL) |
| **doi_vn_expn_matl** ⭐ | UP_VN_EXPN_INPUT | 투입(재료+가공, 공정별) |
| **DOI_COST_BOH** ⭐ | UP_VN_COST_BOH / DOI_MAKE_COST_BOH | 기초금액 |
| **doi_cost_unit** ⭐ | UP_VN_COST_UNIT | 재공단가 |
| **doi_cost_wip** ⭐ | UP_VN_WIP_EVAL | 재공평가(EOH/PL) |
| doi_stco | UP_VN_STOCK_COST/BOH | 제품수불원가 |
| doi_slco / doi_sale / doi_smce_cost | UP_VN_SALE_COST | 매출원가 |

⭐ = 리팩토링 신규 (VN 전용)

## 실행 순서 (권장)
`A(1→2→3→4)` → `B(5)` → `C(6)` → `E(7→8→9→10)` → `D(11→12→13)`
- E는 C 이후(doi_mat_cost/doi_expen_matl/DOI_COST 존재 필요). WIP_EVAL이 DOI_COST의 EOH/PL을 최종 반영.
- 현재 A①~④만 화면(C0003000) 버튼화. B/C/D/E는 배치·메뉴 편입 잔여.
