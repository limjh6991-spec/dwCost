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
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: 'selCode', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'boh', dataType: ValueType.NUMBER },
    { fieldName: 'inputAmt', dataType: ValueType.NUMBER },
    { fieldName: 'acctName', dataType: ValueType.TEXT },
    { fieldName: 'subName', dataType: ValueType.TEXT },
    { fieldName: 'itemName', dataType: ValueType.TEXT },
  ],

  columns: [
    { name: 'yyyymm', fieldName: 'yyyymm', width: '80', header: { text: 'YYYYMM' }, autoFilter: true, styleName: 'tl' },
    { name: 'selCode', fieldName: 'selCode', width: '80', header: { text: 'SEL_CODE' }, autoFilter: true, styleName: 'tl' },
    { name: 'site', fieldName: 'site', width: '80', header: { text: '사이트' }, autoFilter: true, styleName: 'tl' },
    { name: '구분', fieldName: '구분', width: '80', header: { text: '구분' }, autoFilter: true, styleName: 'tl' },
    { name: 'model', fieldName: 'model', width: '80', header: { text: 'MODEL' }, autoFilter: true, styleName: 'tl', footer: { text: '합계' } },
    { name: 'boh', fieldName: 'boh', width: '80', header: { text: '기초금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'inputAmt', fieldName: 'inputAmt', width: '80', header: { text: '투입금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'acctName', fieldName: 'acctName', width: '80', header: { text: '계정명' }, autoFilter: true, styleName: 'tl' },
    { name: 'subName', fieldName: 'subName', width: '80', header: { text: '비목코드' }, autoFilter: true, styleName: 'tl' },
    { name: 'itemName', fieldName: 'itemName', width: '80', header: { text: '세목코드' }, autoFilter: true, styleName: 'tl' },
  ],
};

module.exports = grid;
