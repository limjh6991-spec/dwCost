/*
 * 결산증빙 자료 > 경영 실행
 */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: false },
    copy: { enabled: true, singleMode: true },
    display: { columnMovable: false, editItemMerging: true, fitStyle: 'even', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
    edit: { editable: false },
    footer: { visible: false },
    paste: { enabled: false },
    rowIndicator: { visible: false },
    sorting: { enabled: true },
    stateBar: { visible: false },
    filtering: { enabled: true },
    fixed: { colBarWidth: 1, colCount: 1 },
  },

  fields: [
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: 'tot', dataType: ValueType.NUMBER },
    { fieldName: '1월', dataType: ValueType.NUMBER },
    { fieldName: '2월', dataType: ValueType.NUMBER },
    { fieldName: '3월', dataType: ValueType.NUMBER },
    { fieldName: '4월', dataType: ValueType.NUMBER },
    { fieldName: '5월', dataType: ValueType.NUMBER },
    { fieldName: '6월', dataType: ValueType.NUMBER },
    { fieldName: '7월', dataType: ValueType.NUMBER },
    { fieldName: '8월', dataType: ValueType.NUMBER },
    { fieldName: '9월', dataType: ValueType.NUMBER },
    { fieldName: '10월', dataType: ValueType.NUMBER },
    { fieldName: '11월', dataType: ValueType.NUMBER },
    { fieldName: '12월', dataType: ValueType.NUMBER },
  ],

  columns: [
    { name: '구분', fieldName: '구분', width: '80', header: { text: '구분' }, autoFilter: true, styleName: 'tl' },
    { name: 'tot', fieldName: 'tot', width: '80', header: { text: '년 실행' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0' },
    { name: '1월', fieldName: '1월', width: '80', header: { text: '1월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0' },
    { name: '2월', fieldName: '2월', width: '80', header: { text: '2월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0' },
    { name: '3월', fieldName: '3월', width: '80', header: { text: '3월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0' },
    { name: '4월', fieldName: '4월', width: '80', header: { text: '4월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0' },
    { name: '5월', fieldName: '5월', width: '80', header: { text: '5월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0' },
    { name: '6월', fieldName: '6월', width: '80', header: { text: '6월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0' },
    { name: '7월', fieldName: '7월', width: '80', header: { text: '7월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0' },
    { name: '8월', fieldName: '8월', width: '80', header: { text: '8월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0' },
    { name: '9월', fieldName: '9월', width: '80', header: { text: '9월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0' },
    { name: '10월', fieldName: '10월', width: '80', header: { text: '10월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0' },
    { name: '11월', fieldName: '11월', width: '80', header: { text: '11월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0' },
    { name: '12월', fieldName: '12월', width: '80', header: { text: '12월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0' },
  ],
};

module.exports = grid;
