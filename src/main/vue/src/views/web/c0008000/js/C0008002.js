/*
 * 결산증빙 자료 > 원가항목별 비용(DOI_EXPEN_AMT)
 */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: false },
    copy: { enabled: true, singleMode: true },
    display: { columnMovable: false, editItemMerging: true, fitStyle: 'fill', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
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
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: 'selCode', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: 'subName', dataType: ValueType.TEXT },
    { fieldName: 'itemName', dataType: ValueType.TEXT },
    { fieldName: 'acctAmt', dataType: ValueType.NUMBER },
    { fieldName: 'expenSel', dataType: ValueType.TEXT },
  ],

  columns: [
    { name: 'yyyymm', fieldName: 'yyyymm', width: '80', header: { text: 'YYYYMM' }, autoFilter: true, styleName: 'tl' },
    { name: 'selCode', fieldName: 'selCode', width: '80', header: { text: 'SEL_CODE' }, autoFilter: true, styleName: 'tl' },
    { name: 'site', fieldName: 'site', width: '80', header: { text: '사이트' }, autoFilter: true, styleName: 'tl' },
    { name: 'subName', fieldName: 'subName', width: '80', header: { text: '비목코드' }, autoFilter: true, styleName: 'tl' },
    { name: 'itemName', fieldName: 'itemName', width: '80', header: { text: '세목코드' }, autoFilter: true, styleName: 'tl', footer: { text: '합계' } },
    { name: 'acctAmt', fieldName: 'acctAmt', width: '80', header: { text: '금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'expenSel', fieldName: 'expenSel', width: '80', header: { text: 'EXPEN_SEL' }, autoFilter: true, styleName: 'tl' },
  ],
};

module.exports = grid;
