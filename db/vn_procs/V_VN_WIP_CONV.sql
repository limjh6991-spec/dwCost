CREATE OR ALTER VIEW V_VN_WIP_CONV AS
SELECT
    yyyymm  AS wc_ym,
    site    AS wc_site,
    구분    AS wc_gubun,
    도우모델 AS wc_model,
    SUM(TRY_CONVERT(float,REPLACE(REPLACE(ISNULL(PL전,N'0'),N',',N''),N' ',N''))) * 0.5
  + SUM(TRY_CONVERT(float,REPLACE(REPLACE(ISNULL(PL후,N'0'),N',',N''),N' ',N''))) * 0.9  AS EOHEQ,
    SUM(TRY_CONVERT(float,REPLACE(REPLACE(ISNULL(PL전,N'0'),N',',N''),N' ',N''))) * 0.5
  + SUM(TRY_CONVERT(float,REPLACE(REPLACE(ISNULL(PL후,N'0'),N',',N''),N' ',N''))) * 0.9
  + SUM(ISNULL(OUTETC_MONTH,0))
  - SUM(ISNULL(타계정입고,0))  AS CONV
FROM DOI_PROD_SUBUL
GROUP BY yyyymm, site, 구분, 도우모델;
