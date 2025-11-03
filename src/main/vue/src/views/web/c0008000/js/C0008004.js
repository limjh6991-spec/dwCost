/*
 * 결산증빙 자료 > 제품별 투입 비용(DOI_PROD_EXPN)
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
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'inQty', dataType: ValueType.NUMBER },
    { fieldName: 'chgQty', dataType: ValueType.NUMBER },
    { fieldName: 'totAmt', dataType: ValueType.NUMBER },
    { fieldName: 'dMatcost', dataType: ValueType.NUMBER },
    { fieldName: 'iMatcost', dataType: ValueType.NUMBER },
    { fieldName: 'fabCost', dataType: ValueType.NUMBER },
    { fieldName: 'sumUnitcost', dataType: ValueType.NUMBER },
    { fieldName: 'dmUnitcost', dataType: ValueType.NUMBER },
    { fieldName: 'diUnitcost', dataType: ValueType.NUMBER },
    { fieldName: 'fUnitcost', dataType: ValueType.NUMBER },
  ],

  columns: [
    { name: 'model', fieldName: 'model', width: '80', header: { text: 'model' }, autoFilter: true, styleName: 'tl', footer: { text: '합계' } },
    { name: 'inQty', fieldName: 'inQty', width: '80', header: { text: '투입수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'chgQty', fieldName: 'chgQty', width: '80', header: { text: '생산환산량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'totAmt', fieldName: 'totAmt', width: '80', header: { text: '합계' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'dMatcost', fieldName: 'dMatcost', width: '90', header: { text: '재료비(직접)' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'iMatcost', fieldName: 'iMatcost', width: '90', header: { text: '재료비(간접)' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'fabCost', fieldName: 'fabCost', width: '80', header: { text: '가공비' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'sumUnitcost', fieldName: 'sumUnitcost', width: '120', header: { text: '투입단가' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.##', footer: { expression: 'sum', numberFormat: '#,##0.##', styleName: 'sum-footer1' } },
    { name: 'dmUnitcost', fieldName: 'dmUnitcost', width: '110', header: { text: '직접재료비단가' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.##', footer: { expression: 'sum', numberFormat: '#,##0.##', styleName: 'sum-footer1' } },
    { name: 'diUnitcost', fieldName: 'diUnitcost', width: '110', header: { text: '간접재료비단가' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.##', footer: { expression: 'sum', numberFormat: '#,##0.##', styleName: 'sum-footer1' } },
    { name: 'fUnitcost', fieldName: 'fUnitcost', width: '100', header: { text: '직가공비단가' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.##', footer: { expression: 'sum', numberFormat: '#,##0.##', styleName: 'sum-footer1' } },
  ],

  layout: [
    'model',
    'inQty',
    'chgQty',
    {
      name: '투입비용',
      items: ['totAmt', 'dMatcost', 'iMatcost', 'fabCost'],
      header: { text: '투입비용' },
    },
    {
      name: '단가',
      items: ['sumUnitcost', 'dmUnitcost', 'diUnitcost', 'fUnitcost'],
      header: { text: '단가' },
    },
  ],
};

module.exports = grid;
