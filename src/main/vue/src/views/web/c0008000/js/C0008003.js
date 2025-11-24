/*
 * 결산증빙 자료 > 원가항목별 비용(DOI_EXPEN_AMT)
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
    // { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    // { fieldName: 'selCode', dataType: ValueType.TEXT },
    // { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: 'gubun', dataType: ValueType.TEXT },
    { fieldName: 'fromDeptCode', dataType: ValueType.TEXT },
    { fieldName: 'fromDeptName', dataType: ValueType.TEXT },
    { fieldName: 'fromAcctCode', dataType: ValueType.TEXT },
    { fieldName: 'fromAcctName', dataType: ValueType.TEXT },
    { fieldName: 'expenSel', dataType: ValueType.TEXT },
    { fieldName: 'expenSelName', dataType: ValueType.TEXT },
    { fieldName: 'acctAmt', dataType: ValueType.NUMBER },
    // { fieldName: 'seq', dataType: ValueType.NUMBER },
  ],

  columns: [
    // { name: 'yyyymm', fieldName: 'yyyymm', width: '80', header: { text: 'YYYYMM' }, autoFilter: true, styleName: 'tl' },
    // { name: 'selCode', fieldName: 'selCode', width: '80', header: { text: 'SEL_CODE' }, autoFilter: true, styleName: 'tl' },
    // { name: 'site', fieldName: 'site', width: '80', header: { text: '사이트' }, autoFilter: true, styleName: 'tl' },
    { name: 'GUBUN', fieldName: 'gubun', width: '80', header: { text: '구분' }, autoFilter: true, styleName: 'tl' },
    { name: 'FROM_DEPT_CODE', fieldName: 'fromDeptCode', width: '80', header: { text: '코스트센터' }, autoFilter: true, styleName: 'tl' },
    { name: 'FROM_DEPT_NAME', fieldName: 'fromDeptName', width: '80', header: { text: '코스트센터명' }, autoFilter: true, styleName: 'tl' },
    { name: 'FROM_ACCT_CODE', fieldName: 'fromAcctCode', width: '80', header: { text: '계정코드' }, autoFilter: true, styleName: 'tl' },
    { name: 'FROM_ACCT_NAME', fieldName: 'fromAcctName', width: '120', header: { text: '계정과목' }, autoFilter: true, styleName: 'tl' },
    { name: 'EXPEN_SEL', fieldName: 'expenSel', width: '80', header: { text: '원가항목' }, autoFilter: true, styleName: 'tl' },
    { name: 'EXPEN_SEL_NAME', fieldName: 'expenSelName', width: '80', header: { text: '원가항목명' }, autoFilter: true, styleName: 'tl' },
    { name: 'ACCT_AMT', fieldName: 'acctAmt', width: '80', header: { text: '배부금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    // { name: 'SEQ', fieldName: 'seq', width: '50', header: { text: '순번' }, autoFilter: true, styleName: 'tr' },
  ],
};

module.exports = grid;
