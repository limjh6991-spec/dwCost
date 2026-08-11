# -*- coding: utf-8 -*-
# 다운스트림 변환 프로시저 생성기 (API 원문 저장, 미매핑=NULL, 멱등 delete-insert)
import io, os

OUTDIR = r'C:\dev\dwCost\db\vn\interface'

def gen(proc, target, iftbl, keys, params, mapping, note, if_has_selcode=True):
    """mapping: list of (target_col, source_expr). source '@x'/'NULL'/'GETDATE()'/'s.Col'/CAST(...)"""
    tgt_cols = ', '.join('['+t+']' for (t, _) in mapping)
    n = len(mapping)
    sel = '\n        '.join(
        f"{src}{',' if i < n-1 else ' '}  -- {t}" for i, (t, src) in enumerate(mapping))
    del_where = ' AND '.join(f"[{k}] = {v}" for (k, v) in keys)
    sig = ',\n    '.join(params)
    where = "s.SITE = @site"
    if if_has_selcode:
        where += "\n      AND ISNULL(s.SEL_CODE, N'') = ISNULL(@selCode, N'')"
    s = f"""-- =============================================================================
-- 다운스트림 변환: {iftbl} (스테이징) -> {target} (운영)
--   {note}
--   멱등: 동일 키 삭제 후 재적재. API 원문 그대로 저장, 미매핑 컬럼은 NULL(보류).
-- =============================================================================
CREATE OR ALTER PROCEDURE {proc}
    {sig}
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM {target}
    WHERE {del_where};

    INSERT INTO {target}
        ({tgt_cols})
    SELECT
        {sel}
    FROM {iftbl} s
    WHERE {where};

    SELECT @@ROWCOUNT AS transformed;
END;
"""
    path = os.path.join(OUTDIR, proc + '.sql')
    io.open(path, 'w', encoding='utf-8').write(s)
    return path, len(mapping)

# 공통 파라미터
P_FULL = ['@yyyymm  VARCHAR(6)', '@selCode VARCHAR(10) = N\'ACTUAL\'', '@site    VARCHAR(4) = N\'VN\'']

# ---------------- 1) STOCK_DETAIL -> DOI_MATL_RESC (재고금액상세) ----------------
m_stock = [
 ('YYYYMM','@yyyymm'),('SEL_CODE','@selCode'),('SITE','@site'),
 ('자산처리계정','s.AssetAccName'),('품목자산분류','s.AssetName'),('재고자산종류','s.AssetGroupName'),
 ('매출원가계정','s.SalesAccName'),('대분류','s.UMItemClassLName'),('중분류','s.UMItmeClassMName'),
 ('소분류','s.UMItemClassSName'),('품목기타분류','s.UMItemEtcClassName'),('품명','s.ItemName'),
 ('품번','s.ItemNo'),('규격','s.Spec'),('단위','s.UnitName'),
 ('기초수량','CAST(s.PreQty AS real)'),('기초금액','CAST(s.PreAmt AS numeric(15,2))'),
 ('입고수량','CAST(s.InQty AS real)'),('입고금액','CAST(s.InAmt AS numeric(15,2))'),
 ('출고수량','CAST(s.OutQty AS real)'),('출고금액','CAST(s.OutAmt AS numeric(15,2))'),
 ('재고수량','CAST(s.StockQty AS real)'),('결산후재고수량','CAST(s.StockQty2 AS real)'),
 ('차이수량','CAST(s.DiffQty AS real)'),('재고금액','CAST(s.StockAmt AS numeric(15,2))'),
 ('결산후재고금액','CAST(s.StockAmt2 AS numeric(15,2))'),('차이금액','CAST(s.DiffAmt AS numeric(15,2))'),
 ('최종결산월재고단가','CAST(s.StkPrice AS real)'),
 ('생산수량','CAST(s.ProdQty AS real)'),('생산금액','CAST(s.ProdAmt AS numeric(15,2))'),
 ('구매수량','CAST(s.BuyQty AS real)'),('구매금액','CAST(s.BuyAmt AS numeric(15,2))'),
 ('적송입고수량','CAST(s.MvInQty AS real)'),('적송입고금액','CAST(s.MvInAmt AS numeric(15,2))'),
 ('기타입고수량','CAST(s.EtcInQty AS real)'),('기타입고금액','CAST(s.EtcInAmt AS numeric(15,2))'),
 ('판매수량','CAST(s.SalesQty AS real)'),('판매원가','CAST(s.SalesAmt AS numeric(15,2))'),
 ('투입수량','CAST(s.InputQty AS real)'),('투입금액','CAST(s.InputAmt AS numeric(15,2))'),
 ('적송출고수량','CAST(s.MvOutQty AS real)'),('적송출고금액','CAST(s.MvOutAmt AS numeric(15,2))'),
 ('기타출고수량','CAST(s.EtcOutQty AS real)'),('기타출고금액','CAST(s.EtcOutAmt AS numeric(15,2))'),
]
keys_stock = [('YYYYMM','@yyyymm'),('SEL_CODE','@selCode'),('SITE','@site')]

# ---------------- 2) EXP_SALES -> doi_invoice_resc (수출매출품목) ----------------
m_sales = [
 ('yyyymm','@yyyymm'),('sel_code','@selCode'),('site','@site'),
 ('사업단위','s.BizUnitName'),('Invoice_No','s.InvoiceRefNo'),('Invoice_Date','s.InvoiceDate'),
 ('수출구분','s.SMExpKindName'),('출고구분','s.UMChannelName'),('가격조건','s.UMPriceTermsName'),
 ('부서','s.DeptName'),('담당자','s.EmpName'),('Buyer','s.CustName'),
 ('통화','s.CurrName'),('환율','CAST(s.ExRate AS numeric(18,2))'),
 ('품명','s.ItemName'),('품번','s.ItemNo'),('규격','s.Spec'),('단위','s.UnitName'),
 ('판매기준가','CAST(s.ItemPrice AS numeric(18,0))'),('판매단가','CAST(s.CustPrice AS numeric(18,2))'),
 ('수량','CAST(s.Qty AS bigint)'),('판매금액','CAST(s.CurAmt AS numeric(15,2))'),
 ('원화판매금액','CAST(s.DomAmt AS numeric(15,2))'),('창고','s.WHName'),
 ('Remarks','s.RemarkI'),('특이사항','s.RemarkM'),
]
keys_sales = [('yyyymm','@yyyymm'),('sel_code','@selCode'),('site','@site')]

# ---------------- 3) ETC_INOUT -> doi_vn_etc_inout (기타입출고금액) ----------------
# 주의: EtcOutQty/Amt/Price 는 IF에서 NVARCHAR -> TRY_CONVERT. 대상 site/sel_code 컬럼 없음(VN 전용) -> yyyymm 키
m_etc = [
 ('일자','s.InOutDate'),('입출고구분','s.InOutName'),('원천구분','s.UMEtcOutKindSource'),
 ('기타입출고구분','s.UMEtcOutKindDetail'),('품목자산분류','s.AssetName'),('대분류','s.UMItemClassLName'),
 ('중분류','s.UMItemClassMName'),('소분류','s.UMItemClassSName'),('품명','s.ItemName'),
 ('품번','s.ItemNo'),('규격','s.Spec'),('단위','s.UnitName'),('단수보정구분','s.SMAdjustKindName'),
 ('수량','TRY_CONVERT(numeric(28,8), s.EtcOutQty)'),('금액','TRY_CONVERT(numeric(28,8), s.EtcOutAmt)'),
 ('단가','TRY_CONVERT(numeric(28,8), s.EtcOutPrice)'),('계정과목','s.AccName'),('창고','s.WHName'),
 ('사용부서','s.DeptName'),('거래처','s.CustName'),('특이사항','s.Remark'),('품목특이사항','s.ItemRemark'),
 ('yyyymm','@yyyymm'),('edit_user',"N'IF'"),('edit_date','GETDATE()'),
]
keys_etc = [('yyyymm','@yyyymm')]

# ---------------- 4) MATERIAL -> doi_vn_material (자재코드) ----------------
# 마스터: IF에 SEL_CODE 없음 -> WHERE 는 site만. yyyymm 파라미터. 대상 site 컬럼 없음 -> yyyymm 키
direct_mat = (['MAT_GRP_%d'%i for i in [1,2,4,5,6,7,8,9,10]] +
              ['MAT_CMF_%d'%i for i in range(1,21)] +
              ['FIRST_FLOW','LAST_FLOW','MFG_DEVISION','SUBCONTRACT_FLAG','BASE_MAT_ID','VENDOR_ID',
               'VENDOR_MAT_ID','CUSTOMER_ID','CUSTOMER_MAT_ID','BOM_SET_ID','APPLY_START_TIME',
               'APPLY_END_TIME','APPROVAL_FLAG','APPROVAL_USER_ID','APPROVAL_TIME','RELEASE_FLAG',
               'RELEASE_USER_ID','RELEASE_TIME','DEACTIVE_FLAG','DEACTIVE_USER_ID','DEACTIVE_TIME',
               'MAT_SHORT_DESC','VENDOR'])
m_mat = [
 ('자재명','s.ItemName'),('자재번호','s.ItemNo'),('규격','s.Spec'),('품목자산분류','s.AssetName'),
 ('기준단위','s.UnitName'),('자재상태','s.SMStatusName'),('내외자구분','s.SMInOutKindName'),
 ('중요도','s.SMABCName'),('관리부서','s.DeptName'),('관리자','s.EmpName'),
 ('자재대분류','s.ItemClassLName'),('자재중분류','s.ItemClassMName'),('자재소분류','s.ItemClassSName'),
 ('영문명','s.ItemEngName'),('출고구분','s.SMOutKindName'),('대표자재','s.IsSTDItem'),
 ('BOM등록','s.IsBOMReg'),('제품별공정소요자재','s.IsProcMat'),('Lot 관리','s.IsLotMng'),
 ('Serial 관리','s.IsSerialMng'),('단가등록여부','s.IsPrice'),('유통기한구분','s.SMLimitTermKindName'),
 ('유통기간','s.SMLimitTermKind'),('등록자','CAST(s.RegUserSeq AS nvarchar(50))'),('등록일','s.RegDate'),
 ('품목설명','s.Remark'),('기본구매처','s.PurCustName'),('수탁거래처','s.TrustCustName'),
 ('부가세구분','s.SMVatKindName'),('판매단가에 부가세포함여부','s.PriceInVat'),('첨부파일','s.IsFileCheck'),
 ('이미지','s.IsImageCheck'),('최종수정자','CAST(s.LastUserSeq AS nvarchar(50))'),('최종수정일','s.LastDate'),
]
for c in direct_mat:
    if c == 'FIRST_FLOW_SEQ_NUM' or c == 'LAST_FLOW_SEQ_NUM':
        m_mat.append((c, f'CAST(s.{c} AS nvarchar(20))'))
    else:
        m_mat.append((c, 's.'+c))
# FIRST/LAST_FLOW_SEQ_NUM (IF int -> 대상 nvarchar) 별도
m_mat.insert(m_mat.index(('FIRST_FLOW','s.FIRST_FLOW'))+1, ('FIRST_FLOW_SEQ_NUM','CAST(s.FIRST_FLOW_SEQ_NUM AS nvarchar(20))'))
m_mat.insert(m_mat.index(('LAST_FLOW','s.LAST_FLOW'))+1, ('LAST_FLOW_SEQ_NUM','CAST(s.LAST_FLOW_SEQ_NUM AS nvarchar(20))'))
m_mat += [('IQC YN','s.IQC_YN'), ('yyyymm','@yyyymm'), ('edit_user',"N'IF'"), ('edit_date','GETDATE()')]
keys_mat = [('yyyymm','@yyyymm')]

results = []
results.append(gen('UP_VN_IF_XFORM_STOCK_DETAIL','DOI_MATL_RESC','DOI_VN_IF_STOCK_DETAIL',
    keys_stock, P_FULL, m_stock, '재고금액상세'))
results.append(gen('UP_VN_IF_XFORM_EXP_SALES','doi_invoice_resc','DOI_VN_IF_EXP_SALES',
    keys_sales, P_FULL, m_sales, '수출매출품목'))
results.append(gen('UP_VN_IF_XFORM_ETC_INOUT','doi_vn_etc_inout','DOI_VN_IF_ETC_INOUT',
    keys_etc, P_FULL, m_etc, '기타입출고금액 (수량/금액/단가는 NVARCHAR->TRY_CONVERT)'))
results.append(gen('UP_VN_IF_XFORM_MATERIAL','doi_vn_material','DOI_VN_IF_MATERIAL',
    keys_mat, P_FULL, m_mat, '자재코드 (마스터, IF SEL_CODE 무 -> site 기준)', if_has_selcode=False))

for path, n in results:
    print(f"{os.path.basename(path)}: {n} cols")
