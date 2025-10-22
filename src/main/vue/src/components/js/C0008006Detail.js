/*
 * 결산증빙 자료 > 원가항목별 재료비(DOI_MAT_EXPEN) > 팝업
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
    { fieldName: '도우모델', dataType: ValueType.TEXT },
    { fieldName: '자재번호', dataType: ValueType.TEXT },
    { fieldName: 'matClass', dataType: ValueType.TEXT },
    { fieldName: '자재대분류', dataType: ValueType.TEXT },
    { fieldName: 'inAmt', dataType: ValueType.NUMBER },
    { fieldName: '환산량', dataType: ValueType.NUMBER },
    { fieldName: '소요량', dataType: ValueType.NUMBER },
    { fieldName: '배부적수', dataType: ValueType.NUMBER },
    { fieldName: '배부금액', dataType: ValueType.NUMBER },
    { fieldName: '사용량', dataType: ValueType.NUMBER },
  ],

  columns: [
    { name: 'yyyymm', fieldName: 'yyyymm', width: '80', header: { text: 'yyyymm' }, autoFilter: true, styleName: 'tl' },
    { name: 'selCode', fieldName: 'selCode', width: '80', header: { text: 'sel_code' }, autoFilter: true, styleName: 'tl' },
    { name: 'site', fieldName: 'site', width: '80', header: { text: 'site' }, autoFilter: true, styleName: 'tl' },
    { name: '도우모델', fieldName: '도우모델', width: '120', header: { text: '도우모델' }, autoFilter: true, styleName: 'tl' },
    { name: '자재번호', fieldName: '자재번호', width: '120', header: { text: '자재번호' }, autoFilter: true, styleName: 'tl' },
    { name: 'matClass', fieldName: 'matClass', width: '90', header: { text: 'mat_class' }, autoFilter: true, styleName: 'tl' },
    { name: '자재대분류', fieldName: '자재대분류', width: '150', header: { text: '자재대분류' }, autoFilter: true, styleName: 'tl' },
    { name: 'inAmt', fieldName: 'inAmt', width: '80', header: { text: 'in_amt' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0' },
    { name: '환산량', fieldName: '환산량', width: '90', header: { text: '환산량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0' },
    { name: '소요량', fieldName: '소요량', width: '90', header: { text: '소요량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0' },
    { name: '배부적수', fieldName: '배부적수', width: '120', header: { text: '배부적수' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { text: '합계' } },
    { name: '배부금액', fieldName: '배부금액', width: '120', header: { text: '배부금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: '사용량', fieldName: '사용량', width: '90', header: { text: '사용량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0' },
  ],
};

module.exports = grid;
