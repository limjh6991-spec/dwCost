/*
 * 타시스템 > 매출정보 > 수출Claim (참고/조회용, DOI_VN_EXP_CLAIM)
 *  - 반품물량은 이미 FGS 수불(RMA 재입고)에 반영됨 → 결산 계산 미연동(조회 전용)
 *  - CamelMap(소문자화) 회피 위해 조회쿼리에서 한글 별칭 사용, fieldName 한글 통일
 */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: false },
    copy: { enabled: true, singleMode: false },
    display: { columnMovable: false, fitStyle: 'fill', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
    edit: { editable: false },
    footer: { visible: true },
    paste: { enabled: false },
    rowIndicator: { visible: true },
  },
  fields: [
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: '사업단위', dataType: ValueType.TEXT },
    { fieldName: '클레임번호', dataType: ValueType.TEXT },
    { fieldName: '클레임일자', dataType: ValueType.TEXT },
    { fieldName: '반품종류', dataType: ValueType.TEXT },
    { fieldName: '반품구분', dataType: ValueType.TEXT },
    { fieldName: '재수출진행', dataType: ValueType.TEXT },
    { fieldName: '반품진행', dataType: ValueType.TEXT },
    { fieldName: '부서', dataType: ValueType.TEXT },
    { fieldName: '담당자', dataType: ValueType.TEXT },
    { fieldName: '바이어', dataType: ValueType.TEXT },
    { fieldName: '에이전트', dataType: ValueType.TEXT },
    { fieldName: '통화', dataType: ValueType.TEXT },
    { fieldName: '환율', dataType: ValueType.NUMBER },
    { fieldName: '품명', dataType: ValueType.TEXT },
    { fieldName: '품번', dataType: ValueType.TEXT },
    { fieldName: '규격', dataType: ValueType.TEXT },
    { fieldName: '판매단위', dataType: ValueType.TEXT },
    { fieldName: '판매단가', dataType: ValueType.NUMBER },
    { fieldName: '수량', dataType: ValueType.NUMBER },
    { fieldName: '판매금액', dataType: ValueType.NUMBER },
    { fieldName: '원화판매금액', dataType: ValueType.NUMBER },
    { fieldName: '창고', dataType: ValueType.TEXT },
    { fieldName: '비고', dataType: ValueType.TEXT },
  ],
  columns: [
    { fieldName: 'yyyymm', name: 'yyyymm', header: { text: '기준월' }, width: 70, styleName: 'tl' },
    { fieldName: '사업단위', name: '사업단위', header: { text: '사업단위' }, width: 90, styleName: 'tl' },
    { fieldName: '클레임번호', name: '클레임번호', header: { text: 'Claim번호' }, width: 120, styleName: 'tl' },
    { fieldName: '클레임일자', name: '클레임일자', header: { text: 'Claim일자' }, width: 90, styleName: 'tc' },
    { fieldName: '반품종류', name: '반품종류', header: { text: '반품종류' }, width: 180, styleName: 'tl' },
    { fieldName: '재수출진행', name: '재수출진행', header: { text: '재수출진행' }, width: 80, styleName: 'tc' },
    { fieldName: '반품진행', name: '반품진행', header: { text: '반품진행' }, width: 80, styleName: 'tc' },
    { fieldName: '부서', name: '부서', header: { text: '부서' }, width: 90, styleName: 'tl' },
    { fieldName: '담당자', name: '담당자', header: { text: '담당자' }, width: 110, styleName: 'tl' },
    { fieldName: '바이어', name: '바이어', header: { text: 'Buyer' }, width: 80, styleName: 'tl' },
    { fieldName: '에이전트', name: '에이전트', header: { text: 'Agent' }, width: 80, styleName: 'tl' },
    { fieldName: '통화', name: '통화', header: { text: '통화' }, width: 55, styleName: 'tc' },
    { fieldName: '환율', name: '환율', header: { text: '환율' }, width: 70, numberFormat: '#,##0.00', styleName: 'tr' },
    { fieldName: '품명', name: '품명', header: { text: '품명' }, width: 160, styleName: 'tl' },
    { fieldName: '품번', name: '품번', header: { text: '품번(도우코드)' }, width: 100, styleName: 'tl' },
    { fieldName: '규격', name: '규격', header: { text: '규격' }, width: 100, styleName: 'tl' },
    { fieldName: '판매단위', name: '판매단위', header: { text: '판매단위' }, width: 70, styleName: 'tc' },
    { fieldName: '판매단가', name: '판매단가', header: { text: '판매단가' }, width: 90, numberFormat: '#,##0.00', styleName: 'tr' },
    { fieldName: '수량', name: '수량', header: { text: '수량' }, width: 90, numberFormat: '#,##0', styleName: 'tr' },
    { fieldName: '판매금액', name: '판매금액', header: { text: '판매금액' }, width: 110, numberFormat: '#,##0.00', styleName: 'tr' },
    { fieldName: '원화판매금액', name: '원화판매금액', header: { text: '원화판매금액' }, width: 120, numberFormat: '#,##0.00', styleName: 'tr' },
    { fieldName: '창고', name: '창고', header: { text: '창고' }, width: 100, styleName: 'tl' },
    { fieldName: '비고', name: '비고', header: { text: 'Remarks' }, width: 220, styleName: 'tl' },
  ],
};

// 수량/금액 합계 푸터
grid.columns.forEach((c) => {
  const f = c.fieldName || '';
  if (f.includes('금액')) {
    c.footer = { expression: 'sum', numberFormat: '#,##0.00' };
  } else if (f === '수량') {
    c.footer = { expression: 'sum', numberFormat: '#,##0' };
  }
});

module.exports = grid;
