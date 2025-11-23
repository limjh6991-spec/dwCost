/*
 * 결산증빙 자료 > 판매관리비
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
    { fieldName: 'subName', dataType: ValueType.TEXT },
    { fieldName: 'itemName', dataType: ValueType.TEXT },
    { fieldName: 'expenSel', dataType: ValueType.TEXT },
    { fieldName: 'expenSel명', dataType: ValueType.TEXT },
    { fieldName: 'saleAmt', dataType: ValueType.NUMBER },
    { fieldName: 'totAmt', dataType: ValueType.NUMBER },
    { fieldName: 'totSmce', dataType: ValueType.NUMBER },
    { fieldName: 'totAcct', dataType: ValueType.NUMBER },
    { fieldName: 'distRate', dataType: ValueType.NUMBER },
    { fieldName: 'distAmt', dataType: ValueType.NUMBER },
  ],

  columns: [
    { name: '구분', fieldName: '구분', width: '80', header: { text: '구분' }, autoFilter: true, styleName: 'tl' },
    { name: 'model', fieldName: 'model', width: '80', header: { text: '모델명' }, autoFilter: true, styleName: 'tl' },
    { name: 'subName', fieldName: 'subName', width: '80', header: { text: '비목코드' }, autoFilter: true, styleName: 'tl' },
    { name: 'itemName', fieldName: 'itemName', width: '90', header: { text: '세목코드' }, autoFilter: true, styleName: 'tl' },
    { name: 'expenSel', fieldName: 'expenSel', width: '90', header: { text: '원가항목코드' }, autoFilter: true, styleName: 'tl' },
    { name: 'expenSel명', fieldName: 'expenSel명', width: '120', header: { text: '원가항목명' }, autoFilter: true, styleName: 'tl' },
    { name: 'saleAmt', fieldName: 'saleAmt', width: '80', header: { text: '모델매출액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'totAmt', fieldName: 'totAmt', width: '80', header: { text: '매출총액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'totSmce', fieldName: 'totSmce', width: '80', header: { text: '판관비총액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'totAcct', fieldName: 'totAcct', width: '80', header: { text: '원가항목판관비' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'distRate', fieldName: 'distRate', width: '90', header: { text: '배부율' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.#########', footer: { text: '합계' } },
    { name: 'distAmt', fieldName: 'distAmt', width: '80', header: { text: '배부금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.######', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
  ],
};

module.exports = grid;
