CREATE           VIEW V_DOI_PROD_SUBUL AS

select

	YYYYMM,

	SEL_CODE,

	SITE,

	구분,

	구분_ord,

	도우코드,

	도우모델,

	작업구분,

	org작업구분,

	model,

	Inch,

	DW_Site,

	coalesce(BOH_ADJ,0) as BOH_MONTH,

	(IN_MONTH+BONUS_MONTH) as IN_MONTH,

	BONUS_MONTH,

	coalesce(EOH_ADJ,0) as EOH_MONTH,

	coalesce(OUT_ADJ,0) as OUT_MONTH,

	LOSS_MONTH,

	NG_MONTH,

	수율제외_MONTH,

	REWORK진행_MONTH,

	SHIPPING_PLAN_MONTH,

	SHIPPING_ACTUAL_MONTH,

	material_loss,

	recall_loss,

	Adj_YN

from

	doi_prod_subul

union all

select 

	YYYYMM,

	SEL_CODE,

	SITE,

	구분,

	구분_ord,

	도우코드,

	도우모델,

	작업구분,

	org작업구분,

	model,

	Inch,

	DW_Site,

	BOH_MONTH,

	IN_MONTH,

	BONUS_MONTH,

	AdjEOH_MONTH EOH_MONTH,

	AdjOUT_MONTH OUT_MONTH,

	LOSS_MONTH,

	NG_MONTH,

	수율제외_MONTH,

	REWORK진행_MONTH,

	SHIPPING_PLAN_MONTH,

	SHIPPING_ACTUAL_MONTH,

	material_loss,

	recall_loss,

	'Y' as Adj_YN

from

	doi_prod_subul_adj

UNION ALL

select

	YYYYMM,

	SEL_CODE,

	SITE,

	구분,

	구분_ord,

	도우코드,

	도우모델,

	작업구분,

	org작업구분,

	model,

	Inch,

	DW_Site,

	BOH_ADJ as BOH_MONTH,

	(IN_MONTH+BONUS_MONTH) as IN_MONTH,

	BONUS_MONTH,

	EOH_ADJ as EOH_MONTH,

	OUT_ADJ as OUT_MONTH,

	LOSS_MONTH,

	NG_MONTH,

	수율제외_MONTH,

	REWORK진행_MONTH,

	SHIPPING_PLAN_MONTH,

	SHIPPING_ACTUAL_MONTH,

	material_loss,

	recall_loss,

	Adj_YN

from

	doi_rnd_subul;