/* ============================================================
   비나(VN) 생산/재고 신규 포맷 raw 적재 테이블 (260801)
   출처: docs/비나_prod_stock_신규포맷.xlsx (시트 prod_resc / stock_resc, 동일 포맷)
   구조: 모델·구분 + BOH/EOH(LINE/B_LEVEL × WIP/FGS × PL전50%/후90%) + INPUT/기타입고/OUTPUT/기타출고/LOSS
   성격: 엑셀 1:1 landing(증빙). 원가 파이프라인용 정규화 테이블(doi_vn_prod)은 별도(UP 변환).
   ============================================================ */

CREATE TABLE doi_vn_prod_resc (
  yyyymm      varchar(6)   NOT NULL,
  sel_code    varchar(10)  NOT NULL DEFAULT 'ACTUAL',
  도우코드     nvarchar(30) NOT NULL,     -- 엑셀 Model
  division    varchar(10)  NOT NULL DEFAULT '',   -- MP / R&D
  -- ===== 기초 BOH (PL전50% / PL후90%) =====
  BOH_LINE_WIP_전 numeric(18,2), BOH_LINE_WIP_후 numeric(18,2),   -- 1 LINE_WIP (A_LEVEL)
  BOH_LINE_FGS_전 numeric(18,2), BOH_LINE_FGS_후 numeric(18,2),   -- 2 LINE_FGS (A_LEVEL)
  BOH_A_SUB_전    numeric(18,2), BOH_A_SUB_후    numeric(18,2),   -- 3=1+2 A_LEVEL SUBTOTAL
  BOH_B_WIP_전    numeric(18,2), BOH_B_WIP_후    numeric(18,2),   -- 4 B_LEVEL_WIP
  BOH_B_FGS_전    numeric(18,2), BOH_B_FGS_후    numeric(18,2),   -- 5 B_LEVEL_FGS
  BOH_B_SUB_전    numeric(18,2), BOH_B_SUB_후    numeric(18,2),   -- 6=4+5 B_LEVEL SUBTOTAL
  T_BOH_전        numeric(18,2), T_BOH_후        numeric(18,2),   -- 7=1+2+4+5 T_BOH
  -- ===== 입고 INPUT =====
  USC_INPUT       numeric(18,2),                                  -- (C)
  -- ===== 기타입고 Other Input (6=1+2+3+4+5) =====
  ETCIN_CODE      numeric(18,2),   -- 1 CODE 변경
  ETCIN_RESORT    numeric(18,2),   -- 2 Re-Sorting(재검사)
  ETCIN_REWORK    numeric(18,2),   -- 3 Re-work(SI검사)
  ETCIN_SEMI      numeric(18,2),   -- 4 반제품 입고
  ETCIN_ETC       numeric(18,2),   -- 5 기타
  ETCIN_TOTAL     numeric(18,2),   -- 6 기타입고 합
  -- ===== 출고 OUTPUT =====
  OUTPUT_A        numeric(18,2),                                  -- (C)
  -- ===== 기타출고 Other Output (PL전/후) =====
  ETCOUT_CODE_전      numeric(18,2), ETCOUT_CODE_후      numeric(18,2),  -- 1 CODE 변경
  ETCOUT_SEMI_PAID_전 numeric(18,2), ETCOUT_SEMI_PAID_후 numeric(18,2),  -- 2 반제품출고(유상)
  ETCOUT_SEMI_FREE_전 numeric(18,2), ETCOUT_SEMI_FREE_후 numeric(18,2),  -- 3 반제품출고(무상)
  ETCOUT_ETC_전       numeric(18,2), ETCOUT_ETC_후       numeric(18,2),  -- 4 기타
  ETCOUT_TOTAL_전     numeric(18,2), ETCOUT_TOTAL_후     numeric(18,2),  -- 5=1+2+3+4 기타출고 합
  -- ===== LOSS (SCRAP) =====
  LOSS_전 numeric(18,2), LOSS_후 numeric(18,2),
  -- ===== 재고 EOH (PL전/후) =====
  EOH_LINE_WIP_전 numeric(18,2), EOH_LINE_WIP_후 numeric(18,2),   -- 1 LINE_WIP (A)
  EOH_LINE_FGS_전 numeric(18,2), EOH_LINE_FGS_후 numeric(18,2),   -- 2 LINE_FGs (A)
  EOH_B_WIP_전    numeric(18,2), EOH_B_WIP_후    numeric(18,2),   -- 3 B_LEVEL WIP
  EOH_B_FGS_전    numeric(18,2), EOH_B_FGS_후    numeric(18,2),   -- 4 B_LEVEL FGs
  T_EOH_WIP_전    numeric(18,2), T_EOH_WIP_후    numeric(18,2),   -- 5=1+3 T_EOH WIP
  T_EOH_FGS_전    numeric(18,2), T_EOH_FGS_후    numeric(18,2),   -- 6=2+4 T_EOH FGs
  TOTAL_EOH_전    numeric(18,2), TOTAL_EOH_후    numeric(18,2),   -- 7=5+6 TOTAL_EOH(MES)
  EDIT_USER       varchar(50)  NULL,
  EDIT_DT         datetime     NULL DEFAULT getdate(),
  CONSTRAINT PK_doi_vn_prod_resc PRIMARY KEY (yyyymm, sel_code, 도우코드, division)
);

-- stock_resc (V11-3): 제품원장 포맷, OUTPUT 3분할(SHIP_A유상/무상/B)
CREATE TABLE doi_vn_stock_resc (
  yyyymm varchar(6) NOT NULL, sel_code varchar(10) NOT NULL DEFAULT 'ACTUAL',
  도우코드 nvarchar(30) NOT NULL, division varchar(10) NOT NULL DEFAULT '',
  [BOH] numeric(18,2) NULL,
  [IN_NORMAL_LAST] numeric(18,2) NULL,
  [IN_NORMAL_THIS] numeric(18,2) NULL,
  [IN_RW_BACKSHIP_SORT] numeric(18,2) NULL,
  [IN_RW_BACKSHIP_PFRW] numeric(18,2) NULL,
  [IN_RW_BACKSHIP_PLRW] numeric(18,2) NULL,
  [IN_RW_WHRET_SORT] numeric(18,2) NULL,
  [IN_RW_WHRET_PFRW] numeric(18,2) NULL,
  [IN_RW_WHRET_PLRW] numeric(18,2) NULL,
  [T_INPUT] numeric(18,2) NULL,
  [ETCIN_RMA] numeric(18,2) NULL,
  [ETCIN_SEMI_PAID] numeric(18,2) NULL,
  [ETCIN_SEMI_FREE] numeric(18,2) NULL,
  [ETCIN_ETC] numeric(18,2) NULL,
  [ETCIN_TOTAL] numeric(18,2) NULL,
  [OUT_SHIP_A_PAID] numeric(18,2) NULL,
  [OUT_SHIP_A_FREE] numeric(18,2) NULL,
  [OUT_SHIP_B] numeric(18,2) NULL,
  [T_OUTPUT] numeric(18,2) NULL,
  [ETCOUT_RESORT] numeric(18,2) NULL,
  [ETCOUT_REWORK] numeric(18,2) NULL,
  [ETCOUT_FREESALE] numeric(18,2) NULL,
  [ETCOUT_ETC] numeric(18,2) NULL,
  [ETCOUT_TOTAL] numeric(18,2) NULL,
  [LOSS] numeric(18,2) NULL,
  [EOH_WH0006] numeric(18,2) NULL,
  [VERIFY] numeric(18,2) NULL,
  EDIT_USER varchar(50) NULL, EDIT_DT datetime NULL DEFAULT getdate(),
  CONSTRAINT PK_doi_vn_stock_resc PRIMARY KEY (yyyymm, sel_code, 도우코드, division)
);
