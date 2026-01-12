/*
 * 제조매출원가 실행로그 팝업
 */
const { Football, FootstepsSharp } = require('@vicons/ionicons5');
const { ValueType } = require('realgrid');

const grid = {
  options: {
    display: { columnMovable: false, editItemMerging: true, fitStyle: 'fill'},
    checkBar: { visible: false },
    edit: { editable: false },
    indicator : { visible: false },
    rowIndicator: { visible: true },
    sorting: { enabled: true },
    stateBar: { visible: false },
    footer: { visible: false },
  },

  fields: [
    { fieldName: 'seqNo', dataType: ValueType.TEXT},
    { fieldName: 'execRslt', dataType: ValueType.TEXT },
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: 'selCode', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: 'execDate', dataType: ValueType.TEXT },
    { fieldName: 'execUser', dataType: ValueType.TEXT },
  ],

  columns: [
    { name: 'seqNo', fieldName: 'seqNo', width: '0', header: { text: 'No.' }, styleName: 'tr', visible: false },
    { name: 'execRslt', fieldName: 'execRslt', width: '80', header: { text: '실행결과' }, autoFilter: true, styleName: 'tl' },
    { name: 'yyyymm', fieldName: 'yyyymm', width: '80', header: { text: 'YYYYMM' }, autoFilter: true, styleName: 'tl' },
    { name: 'selCode', fieldName: 'selCode', width: '150', header: { text: 'SEL_CODE' }, autoFilter: true, styleName: 'tl' },
    { name: 'site', fieldName: 'site', width: '80', header: { text: '사업장' }, autoFilter: true, styleName: 'tl' },
    { name: 'execDate', fieldName: 'execDate', width: '150', header: { text: '실행일' }, autoFilter: true, styleName: 'tl' },
    { name: 'execUser', fieldName: 'execUser', width: '80', header: { text: '실행자' }, autoFilter: true, styleName: 'tl' },
  ],
};

module.exports = grid;
