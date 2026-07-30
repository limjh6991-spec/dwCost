CREATE OR ALTER VIEW V_DOI_PROD_SUBUL_VN AS
-- VN 전용: 공유 V_DOI_PROD_SUBUL 3브랜치 구조/조정로직 동일 + VN 필요컬럼(공정불량·타계정·기타입출고·반제품·OUTETC·ADJ·PL전/후/입고전) 추가
-- 브랜치1: doi_prod_subul (원천 - 추가컬럼 실값)
select
	YYYYMM, SEL_CODE, SITE, 구분, 구분_ord, 도우코드, 도우모델, 작업구분, org작업구분, model, Inch, DW_Site,
	coalesce(BOH_ADJ,0) as BOH_MONTH,
	(IN_MONTH+BONUS_MONTH) as IN_MONTH,
	BONUS_MONTH,
	coalesce(EOH_ADJ,0) as EOH_MONTH,
	coalesce(OUT_ADJ,0) as OUT_MONTH,
	LOSS_MONTH, NG_MONTH, 수율제외_MONTH, REWORK진행_MONTH, SHIPPING_PLAN_MONTH, SHIPPING_ACTUAL_MONTH, material_loss, recall_loss, Adj_YN,
	공정발생불량, 불량판매, 타계정입고, 기타입고_LOT변환, 기타입고_RMA_RW, 기타입고_전월불량, 기타입고_당월불량, 기타입고_불량_RW,
	타계정출고, 기타출고_LOT변환, 기타출고_기타, 기타출고_반제품_무상, 기타출고_반제품_유상,
	OUTETC_MONTH, BOH_ADJ, OUT_ADJ, EOH_ADJ, PL전, PL후, 입고전
from doi_prod_subul
union all
-- 브랜치2: doi_prod_subul_adj (추가컬럼 없음 → 0/NULL)
select
	YYYYMM, SEL_CODE, SITE, 구분, 구분_ord, 도우코드, 도우모델, 작업구분, org작업구분, model, Inch, DW_Site,
	BOH_MONTH,
	IN_MONTH,
	BONUS_MONTH,
	AdjEOH_MONTH EOH_MONTH,
	AdjOUT_MONTH OUT_MONTH,
	LOSS_MONTH, NG_MONTH, 수율제외_MONTH, REWORK진행_MONTH, SHIPPING_PLAN_MONTH, SHIPPING_ACTUAL_MONTH, material_loss, recall_loss, 'Y' as Adj_YN,
	CAST(0 AS int) 공정발생불량, CAST(0 AS int) 불량판매, CAST(0 AS int) 타계정입고, CAST(0 AS int) 기타입고_LOT변환, CAST(0 AS int) 기타입고_RMA_RW, CAST(0 AS int) 기타입고_전월불량, CAST(0 AS int) 기타입고_당월불량, CAST(0 AS int) 기타입고_불량_RW,
	CAST(0 AS int) 타계정출고, CAST(0 AS int) 기타출고_LOT변환, CAST(0 AS int) 기타출고_기타, CAST(NULL AS nvarchar(50)) 기타출고_반제품_무상, CAST(NULL AS nvarchar(50)) 기타출고_반제품_유상,
	CAST(0 AS int) OUTETC_MONTH, CAST(0 AS bigint) BOH_ADJ, CAST(0 AS bigint) OUT_ADJ, CAST(0 AS bigint) EOH_ADJ, CAST(NULL AS nvarchar(50)) PL전, CAST(NULL AS nvarchar(50)) PL후, CAST(NULL AS nvarchar(50)) 입고전
from doi_prod_subul_adj
UNION ALL
-- 브랜치3: doi_rnd_subul (BOH/OUT/EOH_ADJ 실값, 나머지 추가컬럼 0/NULL)
select
	YYYYMM, SEL_CODE, SITE, 구분, 구분_ord, 도우코드, 도우모델, 작업구분, org작업구분, model, Inch, DW_Site,
	BOH_ADJ as BOH_MONTH,
	(IN_MONTH+BONUS_MONTH) as IN_MONTH,
	BONUS_MONTH,
	EOH_ADJ as EOH_MONTH,
	OUT_ADJ as OUT_MONTH,
	LOSS_MONTH, NG_MONTH, 수율제외_MONTH, REWORK진행_MONTH, SHIPPING_PLAN_MONTH, SHIPPING_ACTUAL_MONTH, material_loss, recall_loss, Adj_YN,
	CAST(0 AS int) 공정발생불량, CAST(0 AS int) 불량판매, CAST(0 AS int) 타계정입고, CAST(0 AS int) 기타입고_LOT변환, CAST(0 AS int) 기타입고_RMA_RW, CAST(0 AS int) 기타입고_전월불량, CAST(0 AS int) 기타입고_당월불량, CAST(0 AS int) 기타입고_불량_RW,
	CAST(0 AS int) 타계정출고, CAST(0 AS int) 기타출고_LOT변환, CAST(0 AS int) 기타출고_기타, CAST(NULL AS nvarchar(50)) 기타출고_반제품_무상, CAST(NULL AS nvarchar(50)) 기타출고_반제품_유상,
	CAST(0 AS int) OUTETC_MONTH, BOH_ADJ, OUT_ADJ, EOH_ADJ, CAST(NULL AS nvarchar(50)) PL전, CAST(NULL AS nvarchar(50)) PL후, CAST(NULL AS nvarchar(50)) 입고전
from doi_rnd_subul;
