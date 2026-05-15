/*
 * 결산증빙 자료 > 제품별 재공평가(DOI_COST)
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
    fixed: { colBarWidth: 1, colCount: 1 },
  },

  fields: [
    // { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    // { fieldName: 'selCode', dataType: ValueType.TEXT },
    // { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'expenSel', dataType: ValueType.TEXT },
    { fieldName: 'expenSel명', dataType: ValueType.TEXT },
    { fieldName: 'acctName', dataType: ValueType.TEXT },
    { fieldName: 'bohQty', dataType: ValueType.NUMBER },
    { fieldName: 'inQty', dataType: ValueType.NUMBER },
    { fieldName: 'eohQty', dataType: ValueType.NUMBER },
    { fieldName: 'outQty', dataType: ValueType.NUMBER },
    { fieldName: 'lossQty', dataType: ValueType.NUMBER },
    { fieldName: 'rmainQty', dataType: ValueType.NUMBER },
    { fieldName: 'adjQty', dataType: ValueType.NUMBER },
    { fieldName: 'boh', dataType: ValueType.NUMBER },
    { fieldName: 'inputAmt', dataType: ValueType.NUMBER },
    { fieldName: 'eoh', dataType: ValueType.NUMBER },
    { fieldName: 'outAmt', dataType: ValueType.NUMBER },
    { fieldName: 'loss', dataType: ValueType.NUMBER },
    { fieldName: 'rmaIn', dataType: ValueType.NUMBER },
  ],

  columns: [
    { name: '구분', fieldName: '구분', width: '80', header: { text: '구분' }, autoFilter: true, styleName: 'tl' },
    { name: 'model', fieldName: 'model', width: '80', header: { text: 'MODEL' }, autoFilter: true, styleName: 'tl' },
    { name: 'expenSel', fieldName: 'expenSel', width: '80', header: { text: '원가항목코드' }, autoFilter: true, styleName: 'tl' },
    { name: 'expenSel명', fieldName: 'expenSel명', width: '80', header: { text: '원가항목명' }, autoFilter: true, styleName: 'tl' },
    { name: 'acctName', fieldName: 'acctName', width: '80', header: { text: '계정과목' }, autoFilter: true, styleName: 'tl' },
    { name: 'bohQty', fieldName: 'bohQty', width: '80', header: { text: '기초수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', },
    { name: 'inQty', fieldName: 'inQty', width: '80', header: { text: 'IN수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', },
    { name: 'eohQty', fieldName: 'eohQty', width: '80', header: { text: '기말수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', },
    { name: 'outQty', fieldName: 'outQty', width: '80', header: { text: 'OUT수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', },
    { name: 'lossQty', fieldName: 'lossQty', width: '80', header: { text: '불량수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', },
    { name: 'rmainQty', fieldName: 'rmainQty', width: '80', header: { text: 'RMA수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', },
    { name: 'adjQty', fieldName: 'adjQty', width: '80', header: { text: '환산수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { text: '합계' } },
    { name: 'boh', fieldName: 'boh', width: '80', header: { text: '기초금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'inputAmt', fieldName: 'inputAmt', width: '80', header: { text: 'IN금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'eoh', fieldName: 'eoh', width: '80', header: { text: '기말금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'outAmt', fieldName: 'outAmt', width: '80', header: { text: 'OUT금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'loss', fieldName: 'loss', width: '80', header: { text: '불량금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'rmaIn', fieldName: 'rmaIn', width: '80', header: { text: 'RMA금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
  ],
};

module.exports = grid;
