/*
 * 제조매출원가 > 매출원가 (모델별/거래선별 배부)
 */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: false },
    copy: { enabled: true, singleMode: true },
    display: { columnMovable: false, editItemMerging: true, fitStyle: 'even', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
    edit: { editable: false },
    footer: { visible: true },
    paste: { enabled: false },
    rowIndicator: { visible: true },
    sorting: { enabled: true },
    stateBar: { visible: false },
    filtering: { enabled: true },
    fixed: { colBarWidth: 0, colCount: 0 },
  },

  fields: [
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: '거래처', dataType: ValueType.TEXT },
    { fieldName: '품명', dataType: ValueType.TEXT },
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: 'expenSel', dataType: ValueType.TEXT },
    { fieldName: 'expenSel명', dataType: ValueType.TEXT },
    { fieldName: 'outQty', dataType: ValueType.NUMBER },
    { fieldName: 'outAmt', dataType: ValueType.NUMBER },
    { fieldName: 'saleQty', dataType: ValueType.NUMBER },
    { fieldName: 'saleAmt', dataType: ValueType.NUMBER },
    { fieldName: '매출원가율', dataType: ValueType.NUMBER },
    { fieldName: '매출원가', dataType: ValueType.NUMBER },
    { fieldName: '이익금액', dataType: ValueType.NUMBER },
  ],

  columns: [
    { name: 'yyyymm', fieldName: 'yyyymm', width: '80', header: { text: '기준월' }, autoFilter: true, styleName: 'tl' },
    { name: 'site', fieldName: 'site', width: '80', header: { text: '사업장' }, autoFilter: true, styleName: 'tl' },
    { name: '거래처', fieldName: '거래처', width: '150', header: { text: '거래처' }, autoFilter: true, styleName: 'tl' },
    { name: '품명', fieldName: '품명', width: '150', header: { text: '품명(모델)' }, autoFilter: true, styleName: 'tl' },
    { name: '구분', fieldName: '구분', width: '80', header: { text: '구분' }, autoFilter: true, styleName: 'tl' },
    { name: 'expenSel', fieldName: 'expenSel', width: '100', header: { text: '원가항목코드' }, autoFilter: true, styleName: 'tl' },
    { name: 'expenSel명', fieldName: 'expenSel명', width: '120', header: { text: '원가항목명' }, autoFilter: true, styleName: 'tl' },
    { name: 'outQty', fieldName: 'outQty', width: '100', header: { text: '출고수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'outAmt', fieldName: 'outAmt', width: '120', header: { text: '출고금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'saleQty', fieldName: 'saleQty', width: '100', header: { text: '매출수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'saleAmt', fieldName: 'saleAmt', width: '120', header: { text: '매출금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: '매출원가율', fieldName: '매출원가율', width: '100', header: { text: '매출원가율(%)' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.00' },
    { name: '매출원가', fieldName: '매출원가', width: '120', header: { text: '매출원가' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: '이익금액', fieldName: '이익금액', width: '120', header: { text: '이익금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
  ],
};

module.exports = grid;
