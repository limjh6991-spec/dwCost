/*
 * 결산증빙 자료 > 생산수불 > 팝업
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
    { fieldName: 'lotrunNo', dataType: ValueType.TEXT },
    { fieldName: 'bohMonth', dataType: ValueType.NUMBER },
    { fieldName: 'inMonth', dataType: ValueType.NUMBER },
    { fieldName: 'bonusMonth', dataType: ValueType.NUMBER },
    { fieldName: 'eohMonth', dataType: ValueType.NUMBER },
    { fieldName: 'outMonth', dataType: ValueType.NUMBER },
    { fieldName: 'lossMonth', dataType: ValueType.NUMBER },
    { fieldName: 'ngMonth', dataType: ValueType.NUMBER },
    { fieldName: '수율제외Month', dataType: ValueType.NUMBER },
    { fieldName: 'materialLoss', dataType: ValueType.NUMBER },
  ],

  columns: [
    { name: 'lotrunNo', fieldName: 'lotrunNo', width: '120', header: { text: 'LOTRUN_NO' }, autoFilter: true, styleName: 'tl', footer: { text: '합계' } },
    { name: 'bohMonth', fieldName: 'bohMonth', width: '80', header: { text: '기초재공' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'inMonth', fieldName: 'inMonth', width: '80', header: { text: '투입수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'bonusMonth', fieldName: 'bonusMonth', width: '80', header: { text: 'BONUS수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'eohMonth', fieldName: 'eohMonth', width: '80', header: { text: '기말재공' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'outMonth', fieldName: 'outMonth', width: '80', header: { text: 'OUT수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'lossMonth', fieldName: 'lossMonth', width: '80', header: { text: '불량수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'ngMonth', fieldName: 'ngMonth', width: '80', header: { text: 'NG수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: '수율제외Month', fieldName: '수율제외Month', width: '80', header: { text: '수율제외수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'materialLoss', fieldName: 'materialLoss', width: '80', header: { text: '원장불량수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
  ],
};

module.exports = grid;
