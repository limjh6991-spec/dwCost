/* ============================================================
   VN 제조원가 집계(C0003001) 메뉴 재정리 — 실제 리팩토링 프로세스 8탭 (260731)
   DOI_CM_SYS_RESOURCE (prod_category='VN'). 운영 반영용.
   화면/매퍼: C0003001.vue(TAB030013~017) + C0003000.xml(C0003001_Vn5~Vn9) 병행 배포 필요.
   ============================================================ */

-- 1) ①②③ 원천 탭 재순번 + 이름 정리
UPDATE DOI_CM_SYS_RESOURCE SET SEQ=1, SYS_RESOURCE_NAME=N'① 재고조정', MODI_DT=getdate(), MODI_USER='SYSADMIN' WHERE prod_category='VN' AND SYS_RESOURCE_ID='TAB030009';
UPDATE DOI_CM_SYS_RESOURCE SET SEQ=2, SYS_RESOURCE_NAME=N'② 재료비원장', MODI_DT=getdate(), MODI_USER='SYSADMIN' WHERE prod_category='VN' AND SYS_RESOURCE_ID='TAB030010';
UPDATE DOI_CM_SYS_RESOURCE SET SEQ=3, SYS_RESOURCE_NAME=N'③ 재료비집계', MODI_DT=getdate(), MODI_USER='SYSADMIN' WHERE prod_category='VN' AND SYS_RESOURCE_ID='TAB030011';

-- 2) 구 탭 제거 (경비집계/가공비배부/재공평가/④재료비배부(doi_mat_cost 폐기))
UPDATE DOI_CM_SYS_RESOURCE SET DEL_YN='Y', MODI_DT=getdate(), MODI_USER='SYSADMIN'
 WHERE prod_category='VN' AND SYS_RESOURCE_ID IN ('TAB030001','TAB030005','TAB030012');

-- 3) 신규 ④~⑧ 탭 (리팩토링 파이프라인)
DELETE FROM DOI_CM_SYS_RESOURCE WHERE prod_category='VN' AND SYS_RESOURCE_ID IN ('TAB030013','TAB030014','TAB030015','TAB030016','TAB030017');
INSERT INTO DOI_CM_SYS_RESOURCE (prod_category,SYS_RESOURCE_ID,SYS_RESOURCE_NAME,UPPER_SYS_RESOURCE_ID,SYS_RESOURCE_TYPE_CODE_ID,DESCRIPTION,SEQ,URL,INIT_DT,INIT_USER,DEL_YN) VALUES
 ('VN','TAB030013',N'④ 가공비집계','C0003001','TAB',N'④ 가공비집계 (doi_acct_expen)',4,'/c0003001?tab3Id=TAB030013',getdate(),'SYSADMIN','N'),
 ('VN','TAB030014',N'⑤ 투입배부','C0003001','TAB',N'⑤ 투입배부 (doi_expn_matl)',5,'/c0003001?tab3Id=TAB030014',getdate(),'SYSADMIN','N'),
 ('VN','TAB030015',N'⑥ 재공기초','C0003001','TAB',N'⑥ 재공기초 (DOI_COST_BOH)',6,'/c0003001?tab3Id=TAB030015',getdate(),'SYSADMIN','N'),
 ('VN','TAB030016',N'⑦ 재공단가','C0003001','TAB',N'⑦ 재공단가 (doi_cost_unit)',7,'/c0003001?tab3Id=TAB030016',getdate(),'SYSADMIN','N'),
 ('VN','TAB030017',N'⑧ 재공평가','C0003001','TAB',N'⑧ 재공평가 (DOI_COST)',8,'/c0003001?tab3Id=TAB030017',getdate(),'SYSADMIN','N');

-- 결과 확인
-- SELECT SEQ,SYS_RESOURCE_ID,SYS_RESOURCE_NAME,URL FROM DOI_CM_SYS_RESOURCE WHERE prod_category='VN' AND UPPER_SYS_RESOURCE_ID='C0003001' AND DEL_YN='N' ORDER BY SEQ;
