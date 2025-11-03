/*
 * 결산증빙 자료 > 제품별 투입 비용(DOI_PROD_EXPN) > 팝업
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
  },

  fields: [
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'expenSel', dataType: ValueType.TEXT },
    { fieldName: 'expenSel명', dataType: ValueType.TEXT },
    { fieldName: 'inQty', dataType: ValueType.NUMBER },
    { fieldName: 'adjQty', dataType: ValueType.NUMBER },
    { fieldName: 'boh', dataType: ValueType.NUMBER },
    { fieldName: 'inputAmt', dataType: ValueType.NUMBER },
    { fieldName: 'subName', dataType: ValueType.TEXT },
  ],

  columns: [
    { name: '구분', fieldName: '구분', width: '80', header: { text: '구분' }, autoFilter: true, styleName: 'tl' },
    { name: 'model', fieldName: 'model', width: '80', header: { text: 'MODEL' }, autoFilter: true, styleName: 'tl' },
    { name: 'expenSel', fieldName: 'expenSel', width: '90', header: { text: 'EXPEN_SEL' }, autoFilter: true, styleName: 'tl' },
    { name: 'expenSel명', fieldName: 'expenSel명', width: '120', header: { text: 'EXPEN_SEL명' }, autoFilter: true, styleName: 'tl' },
    { name: 'inQty', fieldName: 'inQty', width: '80', header: { text: 'in_qty' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'adjQty', fieldName: 'adjQty', width: '80', header: { text: 'adj_qty' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'boh', fieldName: 'boh', width: '80', header: { text: 'BOH' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { text: '합계' } },
    { name: 'inputAmt', fieldName: 'inputAmt', width: '90', header: { text: 'INPUT_AMT' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.##', footer: { expression: 'sum', numberFormat: '#,##0.##', styleName: 'sum-footer1' } },
    { name: 'subName', fieldName: 'subName', width: '80', header: { text: 'SUB_NAME' }, autoFilter: true, styleName: 'tl' },
  ],
};

module.exports = grid;
