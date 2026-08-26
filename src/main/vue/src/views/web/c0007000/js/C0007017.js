/*
 * 타시스템 > 기타입출고금액 (본사, DOI_ETC_INOUT)
 *   ERP 「기타입출고금액조회(통합)」 엑셀 23컬럼 그대로.
 */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: true, exclusive: false, syncHeadCheck: true },
    copy: { enabled: true, singleMode: false },
    display: { columnMovable: false, fitStyle: 'fill', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
    edit: { editable: false },
    footer: { visible: true },
    paste: { enabled: false },
    rowIndicator: { visible: true },
  },
  fields: [
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: '회계단위', dataType: ValueType.TEXT },
    { fieldName: '일자', dataType: ValueType.TEXT },
    { fieldName: '입출고구분', dataType: ValueType.TEXT },
    { fieldName: '원천구분', dataType: ValueType.TEXT },
    { fieldName: '기타입출고구분', dataType: ValueType.TEXT },
    { fieldName: '품목자산분류', dataType: ValueType.TEXT },
    { fieldName: '대분류', dataType: ValueType.TEXT },
    { fieldName: '중분류', dataType: ValueType.TEXT },
    { fieldName: '소분류', dataType: ValueType.TEXT },
    { fieldName: '품명', dataType: ValueType.TEXT },
    { fieldName: '품번', dataType: ValueType.TEXT },
    { fieldName: '규격', dataType: ValueType.TEXT },
    { fieldName: '단위', dataType: ValueType.TEXT },
    { fieldName: '단수보정구분', dataType: ValueType.TEXT },
    { fieldName: '수량', dataType: ValueType.NUMBER },
    { fieldName: '금액', dataType: ValueType.NUMBER },
    { fieldName: '단가', dataType: ValueType.NUMBER },
    { fieldName: '계정과목', dataType: ValueType.TEXT },
    { fieldName: '창고', dataType: ValueType.TEXT },
    { fieldName: '사용부서', dataType: ValueType.TEXT },
    { fieldName: '거래처', dataType: ValueType.TEXT },
    { fieldName: '특이사항', dataType: ValueType.TEXT },
    { fieldName: '품목특이사항', dataType: ValueType.TEXT },
  ],
  columns: [
    { fieldName: 'yyyymm', name: 'yyyymm', header: { text: '기준월' }, width: 70, styleName: 'tc' },
    { fieldName: '회계단위', name: '회계단위', header: { text: '회계단위' }, width: 70, styleName: 'tc' },
    { fieldName: '일자', name: '일자', header: { text: '일자' }, width: 90, styleName: 'tc' },
    { fieldName: '입출고구분', name: '입출고구분', header: { text: '입출고구분' }, width: 70, styleName: 'tc' },
    { fieldName: '원천구분', name: '원천구분', header: { text: '원천구분' }, width: 90, styleName: 'tl' },
    { fieldName: '기타입출고구분', name: '기타입출고구분', header: { text: '기타입출고구분' }, width: 140, styleName: 'tl' },
    { fieldName: '품목자산분류', name: '품목자산분류', header: { text: '품목자산분류' }, width: 90, styleName: 'tl' },
    { fieldName: '대분류', name: '대분류', header: { text: '대분류' }, width: 90, styleName: 'tl' },
    { fieldName: '중분류', name: '중분류', header: { text: '중분류' }, width: 90, styleName: 'tl' },
    { fieldName: '소분류', name: '소분류', header: { text: '소분류' }, width: 110, styleName: 'tl' },
    { fieldName: '품명', name: '품명', header: { text: '품명' }, width: 170, styleName: 'tl' },
    { fieldName: '품번', name: '품번', header: { text: '품번' }, width: 110, styleName: 'tl' },
    { fieldName: '규격', name: '규격', header: { text: '규격' }, width: 110, styleName: 'tl' },
    { fieldName: '단위', name: '단위', header: { text: '단위' }, width: 60, styleName: 'tc' },
    { fieldName: '단수보정구분', name: '단수보정구분', header: { text: '단수보정구분' }, width: 90, styleName: 'tc' },
    { fieldName: '수량', name: '수량', header: { text: '수량' }, width: 90, numberFormat: '#,##0', styleName: 'tr' },
    { fieldName: '금액', name: '금액', header: { text: '금액' }, width: 120, numberFormat: '#,##0', styleName: 'tr' },
    { fieldName: '단가', name: '단가', header: { text: '단가' }, width: 100, numberFormat: '#,##0.00', styleName: 'tr' },
    { fieldName: '계정과목', name: '계정과목', header: { text: '계정과목' }, width: 150, styleName: 'tl' },
    { fieldName: '창고', name: '창고', header: { text: '창고' }, width: 120, styleName: 'tl' },
    { fieldName: '사용부서', name: '사용부서', header: { text: '사용부서' }, width: 100, styleName: 'tl' },
    { fieldName: '거래처', name: '거래처', header: { text: '거래처' }, width: 100, styleName: 'tl' },
    { fieldName: '특이사항', name: '특이사항', header: { text: '특이사항' }, width: 200, styleName: 'tl' },
    { fieldName: '품목특이사항', name: '품목특이사항', header: { text: '품목특이사항' }, width: 200, styleName: 'tl' },
  ],
};

// 수량/금액 합계 푸터 (본사 원화라 정수 표기)
grid.columns.forEach((c) => {
  const f = c.fieldName || '';
  if (f === '금액') {
    c.footer = { expression: 'sum', numberFormat: '#,##0' };
  } else if (f === '수량') {
    c.footer = { expression: 'sum', numberFormat: '#,##0' };
  }
});

module.exports = grid;
