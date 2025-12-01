/*
 * 결산증빙 자료 > 제품별  가공비/판관비
 */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: false },
    copy: { enabled: true, singleMode: false },
    display: { columnMovable: false, editItemMerging: true, fitStyle: 'even', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
    edit: { editable: false },
    footer: { visible: true },
    paste: { enabled: false },
    rowIndicator: { visible: true },
    sorting: { enabled: true },
    stateBar: { visible: false },
    filtering: { enabled: true },
    fixed: { colBarWidth: 1, colCount: 1 },
  },

  fields: [
    // { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    // { fieldName: 'selCode', dataType: ValueType.TEXT },
    // { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: '면적', dataType: ValueType.TEXT },
    { fieldName: 'distRate', dataType: ValueType.TEXT },
    { fieldName: 'distValue', dataType: ValueType.TEXT },
    { fieldName: 'subName', dataType: ValueType.TEXT },
    { fieldName: 'itemName', dataType: ValueType.TEXT },
    { fieldName: 'expenSel', dataType: ValueType.TEXT },
    { fieldName: 'expenSel명', dataType: ValueType.TEXT },
    { fieldName: 'adjQty', dataType: ValueType.NUMBER },
    { fieldName: 'inQty', dataType: ValueType.NUMBER },
    { fieldName: 'outQty', dataType: ValueType.NUMBER },
    { fieldName: 'lossQty', dataType: ValueType.NUMBER },
    { fieldName: 'unitCost', dataType: ValueType.NUMBER },
    { fieldName: 'inputAmt', dataType: ValueType.NUMBER },
  ],

  columns: [
    // { name: 'yyyymm', fieldName: 'yyyymm', width: '80', header: { text: 'YYYYMM' }, autoFilter: true, styleName: 'tl' },
    // { name: 'selCode', fieldName: 'selCode', width: '80', header: { text: 'SEL_CODE' }, autoFilter: true, styleName: 'tl' },
    // { name: 'site', fieldName: 'site', width: '80', header: { text: '사이트' }, autoFilter: true, styleName: 'tl' },
    { name: '구분', fieldName: '구분', width: '80', header: { text: '구분' }, autoFilter: true, styleName: 'tl' },
    { name: 'model', fieldName: 'model', width: '80', header: { text: '모델명' }, autoFilter: true, styleName: 'tl' },
    { name: 'expenSel', fieldName: 'expenSel', width: '80', header: { text: '원가항목코드' }, autoFilter: true, styleName: 'tl' },
    { name: 'expenSel명', fieldName: 'expenSel명', width: '80', header: { text: '원가항목명' }, autoFilter: true, styleName: 'tl' },
    { name: 'subName', fieldName: 'subName', width: '80', header: { text: '배부구분' }, autoFilter: true, styleName: 'tl' },
     { name: '면적', fieldName: '면적', width: '80', header: { text: '면적' }, autoFilter: true, styleName: 'tl', footer: { text: '합계' } },
    { name: 'distRate', fieldName: 'distRate', width: '80', header: { text: '배부율' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.00', },
    { name: 'distValue', fieldName: 'distValue', width: '80', header: { text: '배부적수' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'inputAmt', fieldName: 'inputAmt', width: '80', header: { text: '투입금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    //{ name: 'itemName', fieldName: 'itemName', width: '80', header: { text: '소분류' }, autoFilter: true, styleName: 'tl' },
    { name: 'adjQty', fieldName: 'adjQty', width: '80', header: { text: '환산수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'inQty', fieldName: 'inQty', width: '80', header: { text: '투입수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'outQty', fieldName: 'outQty', width: '80', header: { text: 'Out수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'lossQty', fieldName: 'lossQty', width: '80', header: { text: '불량수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    // { name: 'unitCost', fieldName: 'unitCost', width: '80', header: { text: '단가' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
   // { name: 'boh', fieldName: 'boh', width: '80', header: { text: '기초금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
  ],
};

module.exports = grid;
