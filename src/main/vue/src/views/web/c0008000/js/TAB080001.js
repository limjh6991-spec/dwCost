/*
 * 결산증빙 자료 > 부서별 경비 집계표(DOI_ACCT_AMT)
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
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: 'selCode', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: 'acctClass', dataType: ValueType.TEXT },
    { fieldName: 'dept', dataType: ValueType.TEXT },
    { fieldName: 'deptName', dataType: ValueType.TEXT },
    { fieldName: 'acct', dataType: ValueType.TEXT },
    { fieldName: 'acctName', dataType: ValueType.TEXT },
    // { fieldName: 'itemName', dataType: ValueType.TEXT },
    { fieldName: 'acctAmt', dataType: ValueType.NUMBER },
    { fieldName: 'dbtAmt', dataType: ValueType.NUMBER },
    { fieldName: 'crtAmt', dataType: ValueType.NUMBER },
    { fieldName: 'expenSel', dataType: ValueType.TEXT },
    { fieldName: 'expenSel명', dataType: ValueType.TEXT },
  ],

  columns: [
    // { name: 'yyyymm', fieldName: 'yyyymm', width: '80', header: { text: 'YYYYMM' }, autoFilter: true, styleName: 'tl' },
    // { name: 'selCode', fieldName: 'selCode', width: '80', header: { text: 'SEL_CODE' }, autoFilter: true, styleName: 'tl' },
    // { name: 'site', fieldName: 'site', width: '80', header: { text: '사이트' }, autoFilter: true, styleName: 'tl' },
    { name: 'acctClass', fieldName: 'acctClass', width: '80', header: { text: '비용구분' }, autoFilter: true, styleName: 'tl' },
    { name: 'dept', fieldName: 'dept', width: '80', header: { text: '코스트센터' }, autoFilter: true, styleName: 'tl' },
    { name: 'deptName', fieldName: 'deptName', width: '80', header: { text: '코스트센터명' }, autoFilter: true, styleName: 'tl' },
    { name: 'acct', fieldName: 'acct', width: '80', header: { text: '계정코드' }, autoFilter: true, styleName: 'tl' },
    { name: 'acctName', fieldName: 'acctName', width: '80', header: { text: '계정과목' }, autoFilter: true, styleName: 'tl' },
    { name: 'expenSel', fieldName: 'expenSel', width: '80', header: { text: '원가항목코드' }, autoFilter: true, styleName: 'tl' },
    { name: 'expenSel명', fieldName: 'expenSel명', width: '80', header: { text: '원가항목명' }, autoFilter: true, styleName: 'tl' },
    // { name: 'itemName', fieldName: 'itemName', width: '80', header: { text: '세목목코드' }, autoFilter: true, styleName: 'tl', footer: { text: '합계' } },
    { name: 'acctAmt', fieldName: 'acctAmt', width: '80', header: { text: '금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'dbtAmt', fieldName: 'dbtAmt', width: '80', header: { text: '차변금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'crtAmt', fieldName: 'crtAmt', width: '80', header: { text: '대변금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
  ],
};

module.exports = grid;
