/*
 * 결산증빙 자료 > 제품수불_수량(DOI_STOCK)
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
    // fixed: { colBarWidth: 1, colCount: 1 },
  },

  fields: [
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: '도우코드', dataType: ValueType.TEXT },
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'stock', dataType: ValueType.TEXT },
    { fieldName: 'boh', dataType: ValueType.NUMBER },
    { fieldName: 'inQty', dataType: ValueType.NUMBER },
    { fieldName: 'outQty', dataType: ValueType.NUMBER },
    { fieldName: 'eoh', dataType: ValueType.NUMBER },
    { fieldName: 'rmaOut', dataType: ValueType.NUMBER },
  ],

  columns: [
    { name: '구분', fieldName: '구분', width: '80', header: { text: '구분' }, autoFilter: true, styleName: 'tl' },
    { name: '도우코드', fieldName: '도우코드', width: '80', header: { text: '도우코드' }, autoFilter: true, styleName: 'tl' },
    { name: 'model', fieldName: 'model', width: '80', header: { text: '모델명' }, autoFilter: true, styleName: 'tl' },
    { name: 'stock', fieldName: 'stock', width: '80', header: { text: 'STOCK' }, autoFilter: true, styleName: 'tl', footer: { text: '합계' } },
    { name: 'boh', fieldName: 'boh', width: '80', header: { text: '기초수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'inQty', fieldName: 'inQty', width: '80', header: { text: 'IN수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'outQty', fieldName: 'outQty', width: '80', header: { text: 'OUT수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'eoh', fieldName: 'eoh', width: '80', header: { text: '기말수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'rmaOut', fieldName: 'rmaOut', width: '80', header: { text: 'RMAOUT' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
  ],
};

module.exports = grid;
