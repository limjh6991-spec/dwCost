# 비나(VN) 신규포맷 — 단가 산정 & 제품별 금액 배부 로직 정리

작성 2026-08 (V11-3 기준). 대상: 재공평가 `doi_vn_cost`(UP_VN_WIP_EVAL_NEW), 제품 재고/매출원가 `doi_vn_stco`(UP_VN_STOCK_COST_NEW), R/S·R/W `DOI_VN_RSRW`(UP_VN_RSRW).

공통 그레인: **(YYYYMM, SEL_CODE, 도우코드, division[MP/R&D], EXPEN_SEL[원가항목=재료/가공])**. 물리수량은 도우코드 단위 → **원가항목마다 동일 수량 반복**(정상).

---

## 1. R/S·R/W 금액 확정 — `DOI_VN_RSRW` (UP_VN_RSRW)

제품→재공 재작업 루프(Re-Sorting/Re-work). **제품 기초단가**로 평가, **기초금액 한도**, **R/S 우선**.

| 요소 | 산식 |
|---|---|
| 제품 기초단가 | `DOI_STOCK_BOH.boh_amt 합 / boh수량 합` (도우코드·division) |
| R/S 금액(총) | `MIN(rs수량 × 기초단가, 기초금액)` — 기초 우선 소진 |
| R/W 금액(총) | `MIN(rw수량 × 기초단가, 기초금액 − R/S금액)` — R/S 소진 후 잔여 한도 |
| 원가항목 안분 | 총액 × `(원가항목별 기초금액 / 총 기초금액)` |

- 기초금액 < R/S·R/W 요구액이면 **초과분 금액 0**(수량은 유지, EOH 수량 음수 허용).
- 이 금액이 **재공 ETC-IN** = **제품 ETC-OUT** 양쪽에 동일 반영(루프 일치).

---

## 2. 재공평가 — `doi_vn_cost` (UP_VN_WIP_EVAL_NEW)

### 소스
| 항목 | 소스 |
|---|---|
| 수량·포지션(BOH/EOH LINE·B×WIP·FGS×전후, IN/OUT/ETC/LOSS) | `doi_vn_prod_resc` |
| BOH 금액(원가항목별) | `DOI_COST_BOH` |
| IN 금액(투입) | `doi_expn_matl` (→ USC_INPUT_AMT) |
| ETC-IN 금액(R/S·R/W만) | `DOI_VN_RSRW` (CODE/반제품/기타 입고 = **0 미정**) |

### 재공 단가 (uc)
```
pool  = BOH금액 + IN금액 + ETC-IN금액            (원가항목별)
분모  = OUT수량 + ETC-OUT수량 + 생산환산량
생산환산량 = Σ( EOH포지션수량 × 평가비율 )        평가비율: PL전 0.5 / PL후 0.9
uc    = pool / 분모
```
현업 공식 ④ 그대로: **재공단가 = (BOH+IN+ETC-IN) / (OUT + ETC-OUT + 생산환산량)**.

### 금액 배부
| 라인 | 배부 방식 |
|---|---|
| **BOH 포지션(8)** | `BOH금액 × (포지션수량 × 평가비율) / Σ(포지션수량 × 평가비율)` — **환산량 기준(전0.5/후0.9) = EOH와 동일**. 반올림 잔차는 **값이 가장 큰 포지션**이 흡수(Σ=BOH금액, 음수 방지). ※셋업 이후 BOH=전월 EOH금액이라 포지션 배분이 EOH와 일치(이월품이면 BOH포지션=EOH포지션 정확 일치) |
| **USC_INPUT** | = IN금액(투입) |
| **ETCIN_RESORT / REWORK** | = DOI_VN_RSRW rs_amt / rw_amt |
| **ETCIN_CODE / SEMI / ETC** | 0 (미정) |
| **EOH 포지션(8)** | `pool × 포지션수량 × 평가비율 / denom`(=uc×수량×비율, 나눗셈-마지막 → 이월품에서 BOH포지션과 정확 일치) |
| **ETC-OUT 포지션(8)** | `uc × 포지션수량` (반제품출고 유상/무상 포함) |
| **LOSS(전/후)** | 전량손실(분모=0)이면 pool 배분, 아니면 0(가치는 OUT에 흡수) |
| **OUTPUT_A(출고)** | **OUT수량>0**: 잔여 = pool − ΣETC-OUT − ΣEOH − ΣLOSS. **OUT수량=0(이월)**: 0 (잔여는 값이 가장 큰 EOH포지션이 흡수) → 원가보존 정확 |

> 잔차 흡수: OUT수량>0이면 OUTPUT_A, =0(이월)이면 값이 가장 큰 EOH포지션. → 이월품 재공 OUTPUT=0(제품 INPUT phantom 없음), 포지션 음수 없음.

---

## 3. 제품 재고평가 / 매출원가 — `doi_vn_stco` (UP_VN_STOCK_COST_NEW)

### 소스
| 항목 | 소스 |
|---|---|
| 수량(BOH/INPUT 8분할/기타입고/OUTPUT SHIP 3종/기타출고/LOSS/EOH) | `doi_vn_stock_resc`(제품원장) |
| BOH 금액(제품 기초, 원가항목별) | `DOI_STOCK_BOH` |
| INPUT 금액(제품입고 = 재공출고) | 재공 `doi_vn_cost` **OUTPUT_A_AMT** (원가항목별) |
| 반제품 유상/무상 금액 | 재공 `doi_vn_cost` **반제품출고 AMT** |
| ETC-OUT R/S·R/W 금액 | `DOI_VN_RSRW` (제품 기초단가) |
| RMA | **무시** (금액 0, 단가 분모 제외) |

### 제품 단가 (uc) — ★R/S·R/W 차감 후 나머지로 산정 (2026-08 수정)
```
투입금액 = BOH_AMT + INPUT_AMT + 반제품(유상+무상)금액
투입수량 = BOH수량 + T_INPUT수량 + 반제품(유상+무상)수량           ← RMA 제외
uc = (투입금액 − R/S·R/W금액) / (투입수량 − R/S·R/W수량)
   R/S·R/W금액 = DOI_VN_RSRW(rs_amt+rw_amt, 원가항목별)
   R/S·R/W수량 = stock_resc(ETCOUT_RESORT+ETCOUT_REWORK, 도우코드)
```
**이유**: R/S·R/W는 제품 기초단가·기초금액 한도로 별도 평가(초과분 금액 0). 물량(수량)은 전량 빠져나가므로, **빠져나간 (수량+금액)을 제외한 나머지 pool로 uc를 구해야** OUTPUT·EOH가 remaining 수량에 정확히 배분됨.
- 미수정 시: RESORT ≫ 기초인 원가항목(특히 재료비 MDAX/MIAX, 제품기초 0)에서 RESORT 가치가 0 처리 → 그 값이 EOH(수량 0)에 갇힘(phantom). 예: 7178D/MDAX EOH 19,628(전부 phantom, 물리 EOH=0).
- 수정 후: 7178D EOH=0(물리와 일치), EOH phantom(수량0·금액≠0) 0건.

### 금액 배부
| 라인 | 배부 방식 |
|---|---|
| **BOH** | = DOI_STOCK_BOH 금액(원가항목별). **division은 stock_resc 기준으로 정렬**(DOI_STOCK_BOH를 stock_resc 도우코드·division에 조인 → 815AP 등 기초/수불 division 오분류시 누락 방지) |
| **INPUT 8분할**(NORMAL LAST·THIS / BACKSHIP·WHRET × SORT/PFRW/PLRW) | `INPUT금액 × 수량비`. 대표행 **NORMAL_THIS**에 잔차 |
| **ETCIN 반제품 유상/무상** | = 재공 반제품출고 금액 |
| **ETCIN RMA / 기타** | 0 |
| **OUTPUT(SHIP_A유상/무상/B)** | `uc × 수량` (무상 출하도 매출원가에 계상) |
| **ETC-OUT R/S·R/W** | = DOI_VN_RSRW (제품 기초단가, 한도 cap) |
| **ETC-OUT 무상매출 / 기타** | `uc × 수량` (무상매출: **재고·매출원가는 정상, 매출 수량·금액은 미반영**) |
| **LOSS** | `uc × 수량` |
| **EOH(WH0006)** | **`uc × EOH수량`(물리 고정)** → 재고 없으면(수량0) 금액 0 |
| **OUTPUT(매출원가)** | **잔여 = 투입 − R/S·R/W − 무상 − 기타 − LOSS − EOH** → 원가보존 정확 (SHIP 3종은 수량비 분할) |

> 잔차 흡수 라인 = **OUTPUT(매출원가)**. EOH는 물리수량 고정이라 phantom 없음. R/S·R/W 초과 차액은 매출원가에서 흡수.

---

## 3-B. 재료/가공 배부 — 생산환산량 (UP_VN_EXPN_INPUT) [2026-08 신기준]

재료 공통·가공비를 도우코드에 배부하는 **배부 적수** 기준.
```
생산환산량 = OUTPUT_A + (TOTAL_EOH_전 × 0.5) + (TOTAL_EOH_후 × 0.9)   [doi_vn_prod_resc]
배부적수   = 생산환산량 × 면적(DOI_MODEL_MAST.xy)
배부비율   = 모델 적수 / Σ 적수
```
- 소스: 구 `V_DOI_PROD_SUBUL`·`(IN+OUT+LOSS)/2` → 신 `doi_vn_prod_resc`·`OUT+eoheq`.
- 도우모델 = `LEFT(도우코드,LEN-1)`, 구분 = division(MP→양산/R&D→개발).
- **직과 재료(MDAX)** 는 실투입 도우코드에 직접 귀속(배부 아님) — 전량손실 모델도 보존.
- **공통재료(MIAX)·가공(UTG)** 만 생산환산량×면적 비율 배부. 면적검증은 OUTPUT>0 모델만.
- 재료/가공 **총액 불변**, 모델별 재분배(완성출고·기말재공 큰 모델로 이동). → doi_expn_matl → doi_vn_cost(투입 IN) 소비.
- ※배부 생산환산량(OUT+eoheq)과 재공단가 분모(OUT+**ETC-OUT**+eoheq)는 ETC-OUT 유무만 다름.

## 4. 재공 ↔ 제품 연결 (금액·수량 동일)

| 연결 | 재공 doi_vn_cost | 제품 doi_vn_stco |
|---|---|---|
| 제품입고 = 재공완성출고 | OUTPUT_A_AMT | T_INPUT_AMT |
| 반제품 (유상/무상) | 반제품출고 AMT | ETCIN 반제품 AMT |
| R/S·R/W (DOI_VN_RSRW) | ETC-IN AMT | ETC-OUT AMT |

202606 검증: 재공OUT=제품INPUT 9,784,665 / 반제품 29,013 / R·S·R·W 3,054,335 (모두 일치).

---

## 5. 원가보존

- 재공: `투입(BOH+IN+ETC-IN) = 산출(OUT+ETC-OUT+EOH+LOSS)` — OUTPUT_A 잔여로 **행별 차 0**.
- 제품: `투입(BOH+INPUT+반제품) = 산출(OUTPUT+ETC-OUT+LOSS+EOH)` — EOH 잔여로 **행별 차 0**.
- 물리수량 보존(VERIFY, RMA 제외) 전 행 0.

---

## 6. 수정 이력 & 남은 항목

**[해결] 제품 EOH phantom** (2026-08): uc를 R/S·R/W 차감 후 나머지로 산정 + EOH=uc×수량 물리고정 → EOH phantom(수량0·금액≠0) 0건. 7178D EOH 25,329(전부 phantom)→0.

**[해결] 재공평가 OUTPUT ±0.01 (수량 0 이월품)** (2026-08): OUT수량=0(이월)이면 OUTPUT_A_AMT=0, 잔차는 EOH_LINE_WIP_전이 흡수 → 이월품 재공 OUTPUT=0, 제품 INPUT phantom 제거(716JD IN_NORMAL_THIS_AMT 0), 루프 재공OUT=제품INPUT 정확 일치.

**[해결] BOH 포지션 배분 불일치** (2026-08): BOH도 EOH와 동일 환산량(전0.5/후0.9) 기준 배분 → 이월품 BOH포지션=EOH포지션.

**검증(202606) 최종**: 재공·제품 원가보존 차 0(행별 0), 제품 EOH 음수 0·phantom 0, 재공 OUTPUT phantom 0, 루프 완전 일치.
