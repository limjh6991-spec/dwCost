/*
 * 타시스템 > 자재투입정보(VN) > 품목별투입조회 (DOI_VN_MAT_INPUT)
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
    { fieldName: '제품명', dataType: ValueType.TEXT },
    { fieldName: '제품번호', dataType: ValueType.TEXT },
    { fieldName: '제품규격', dataType: ValueType.TEXT },
    { fieldName: '품명', dataType: ValueType.TEXT },
    { fieldName: '품번', dataType: ValueType.TEXT },
    { fieldName: '규격', dataType: ValueType.TEXT },
    { fieldName: '투입수량', dataType: ValueType.NUMBER },
    { fieldName: '단가', dataType: ValueType.NUMBER },
    { fieldName: '투입금액', dataType: ValueType.NUMBER },
    { fieldName: '투입비율', dataType: ValueType.NUMBER },
    { fieldName: '제품품목자산분류', dataType: ValueType.TEXT },
    { fieldName: '품목자산분류', dataType: ValueType.TEXT },
  ],
  columns: [
    { fieldName: 'yyyymm', name: 'yyyymm', header: { text: '기준월' }, width: 80, styleName: 'tl' },
    { fieldName: '제품명', name: '제품명', header: { text: '제품명' }, width: 150, styleName: 'tl' },
    { fieldName: '제품번호', name: '제품번호', header: { text: '제품번호' }, width: 120, styleName: 'tl' },
    { fieldName: '제품규격', name: '제품규격', header: { text: '제품규격' }, width: 120, styleName: 'tl' },
    { fieldName: '품명', name: '품명', header: { text: '품명' }, width: 150, styleName: 'tl' },
    { fieldName: '품번', name: '품번', header: { text: '품번' }, width: 120, styleName: 'tl' },
    { fieldName: '규격', name: '규격', header: { text: '규격' }, width: 120, styleName: 'tl' },
    { fieldName: '투입수량', name: '투입수량', header: { text: '투입수량' }, width: 100, numberFormat: '#,##0', styleName: 'tr' },
    { fieldName: '단가', name: '단가', header: { text: '단가' }, width: 100, numberFormat: '#,##0.00', styleName: 'tr' },
    { fieldName: '투입금액', name: '투입금액', header: { text: '투입금액' }, width: 120, numberFormat: '#,##0', styleName: 'tr' },
    { fieldName: '투입비율', name: '투입비율', header: { text: '투입비율' }, width: 80, numberFormat: '#,##0.00', styleName: 'tr' },
    { fieldName: '제품품목자산분류', name: '제품품목자산분류', header: { text: '제품품목자산분류' }, width: 120, styleName: 'tl' },
    { fieldName: '품목자산분류', name: '품목자산분류', header: { text: '품목자산분류' }, width: 120, styleName: 'tl' },
  ],
};

module.exports = grid;
