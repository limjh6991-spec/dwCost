/*
 * 결산증빙 자료 > 자재별 투입실적(DOI_MAT_AMT) > 팝업
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
    { fieldName: 'matCode', dataType: ValueType.TEXT },
    { fieldName: 'mstDesc', dataType: ValueType.TEXT },
    { fieldName: 'size', dataType: ValueType.TEXT },
    { fieldName: 'inQty', dataType: ValueType.NUMBER },
    { fieldName: 'unitCost', dataType: ValueType.NUMBER },
    { fieldName: 'inAmt', dataType: ValueType.NUMBER },
    { fieldName: 'costGubun', dataType: ValueType.TEXT },
    { fieldName: 'matClass', dataType: ValueType.TEXT },
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'modelNType', dataType: ValueType.TEXT },
  ],

  columns: [
    { name: 'yyyymm', fieldName: 'yyyymm', width: '80', header: { text: 'YYYYMM' }, autoFilter: true, styleName: 'tl' },
    { name: 'selCode', fieldName: 'selCode', width: '80', header: { text: 'SEL_CODE' }, autoFilter: true, styleName: 'tl' },
    { name: 'site', fieldName: 'site', width: '80', header: { text: 'SITE' }, autoFilter: true, styleName: 'tl' },
    { name: 'matCode', fieldName: 'matCode', width: '80', header: { text: 'MAT_CODE' }, autoFilter: true, styleName: 'tl' },
    { name: 'matDesc', fieldName: 'matDesc', width: '80', header: { text: 'MAT_DESC' }, autoFilter: true, styleName: 'tl' },
    { name: 'size', fieldName: 'size', width: '80', header: { text: 'SIZE' }, autoFilter: true, styleName: 'tl', footer: { text: '합계' } },
    { name: 'inQty', fieldName: 'inQty', width: '80', header: { text: 'IN_QTY' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'unitCost', fieldName: 'unitCost', width: '90', header: { text: 'UNIT_COST' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'inAmt', fieldName: 'inAmt', width: '80', header: { text: 'IN_AMT' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'costGubun', fieldName: 'costGubun', width: '100', header: { text: 'COST_GUBUN' }, autoFilter: true, styleName: 'tl' },
    { name: 'matClass', fieldName: 'matClass', width: '90', header: { text: 'MAT_CLASS' }, autoFilter: true, styleName: 'tl' },
    { name: 'model', fieldName: 'model', width: '80', header: { text: 'MODEL' }, autoFilter: true, styleName: 'tl' },
    { name: 'modelNType', fieldName: 'modelNType', width: '120', header: { text: 'MODEL_N_TYPE' }, autoFilter: true, styleName: 'tl' },
  ],
};

module.exports = grid;
