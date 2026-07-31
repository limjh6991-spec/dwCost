/** * 유상사급 (DOI_원장상계 전체 컬럼) */

const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: true, exclusive: false, syncHeadCheck: true },
    copy: { enabled: true, singleMode: false },
    display: { columnMovable: false, editItemMerging: true, fitStyle: 'fill', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
    edit: { editable: false, columnEditableFirst: true, commitByCell: true, commitWhenLeave: true },
    footer: { visible: true },
    header: { height: 40, showTooltip: true, tooltipEllipsisOnly: true },
    hideDeletedRows: true,
    paste: { enabled: true, checkReadOnly: true },
    rowIndicator: { visible: true },
    sorting: { enabled: false },
    stateBar: { visible: true },
  },
  fields: [
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: 'siteOrg', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: 'selCode', dataType: ValueType.TEXT },
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: '모델', dataType: ValueType.TEXT },
    { fieldName: '원장매칭', dataType: ValueType.TEXT },
    { fieldName: '소요량', dataType: ValueType.NUMBER },
    { fieldName: '배율', dataType: ValueType.NUMBER },
    { fieldName: '출하기여수량', dataType: ValueType.NUMBER },
    { fieldName: '원장사용량', dataType: ValueType.NUMBER },
    { fieldName: '원장단가', dataType: ValueType.NUMBER },
    { fieldName: '매출상계', dataType: ValueType.NUMBER },
  ],
  columns: [
    { name: 'yyyymm', fieldName: 'yyyymm', width: '80', header: { text: 'YYYYMM' }, autoFilter: true, editable: false, styleName: 'tc' },
    { name: 'siteOrg', fieldName: 'siteOrg', width: '0', header: { text: 'SITE_ORG' }, autoFilter: true, visible: false, editable: false, styleName: 'tl' },
    { name: 'site', fieldName: 'site', width: '80', header: { text: '사이트' }, autoFilter: true, editable: false, styleName: 'tc' },
    { name: 'selCode', fieldName: 'selCode', width: '80', header: { text: 'SEL_CODE' }, autoFilter: true, styleName: 'tc' },
    { name: '구분', fieldName: '구분', width: '80', header: { text: '구분' }, autoFilter: true, styleName: 'tc' },
    { name: '모델', fieldName: '모델', width: '120', header: { text: '모델' }, autoFilter: true, styleName: 'tc' },
    { name: '원장매칭', fieldName: '원장매칭', width: '120', header: { text: '원장매칭' }, autoFilter: true, styleName: 'tc' },
    { name: '소요량', fieldName: '소요량', width: '110', header: { text: '소요량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.000000' },
    { name: '배율', fieldName: '배율', width: '80', header: { text: '배율' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0' },
    { name: '출하기여수량', fieldName: '출하기여수량', width: '120', header: { text: '출하기여수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: '원장사용량', fieldName: '원장사용량', width: '120', header: { text: '원장사용량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: '원장단가', fieldName: '원장단가', width: '110', header: { text: '원장단가' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0' },
    { name: '매출상계', fieldName: '매출상계', width: '130', header: { text: '매출상계' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
  ],
};

grid.currencyFields = ['매출상계', '원장단가'];

module.exports = grid;
