/*
 * 결산증빙 자료 > 자재별 투입실적(DOI_MAT_AMT)
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
    { fieldName: 'matClass', dataType: ValueType.TEXT },
    { fieldName: 'expenSel', dataType: ValueType.TEXT },
    { fieldName: 'expenSel명', dataType: ValueType.TEXT },
    { fieldName: 'matCode', dataType: ValueType.TEXT },
    { fieldName: 'matDesc', dataType: ValueType.TEXT },
    { fieldName: 'inQty', dataType: ValueType.NUMBER },
    { fieldName: 'unitCost', dataType: ValueType.TEXT },
    { fieldName: 'inAmt', dataType: ValueType.NUMBER },
  ],

  columns: [
    { name: 'yyyymm', fieldName: 'yyyymm', width: '80', header: { text: 'YYYYMM' }, autoFilter: true, styleName: 'tl',  },
    { name: 'selCode', fieldName: 'selCode', width: '80', header: { text: 'SEL_CODE' }, autoFilter: true, styleName: 'tl',  },
    { name: 'site', fieldName: 'site', width: '80', header: { text: '사이트' }, autoFilter: true, styleName: 'tl',  },
    { name: 'matClass', fieldName: 'matClass', width: '80', header: { text: '대분류' }, autoFilter: true, styleName: 'tl',  },
    { name: 'expenSel', fieldName: 'expenSel', width: '80', header: { text: 'EXPEN_SEL' }, autoFilter: true, styleName: 'tl',  },
    { name: 'expenSel명', fieldName: 'expenSel명', width: '80', header: { text: 'EXPEN_SEL명' }, autoFilter: true, styleName: 'tl',  },
    { name: 'matCode', fieldName: 'matCode', width: '80', header: { text: '자재코드' }, autoFilter: true, styleName: 'tl',  },
    { name: 'matDesc', fieldName: 'matDesc', width: '80', header: { text: '자재명' }, autoFilter: true, styleName: 'tl', footer: { text: '합계' } },
    { name: 'inQty', fieldName: 'inQty', width: '80', header: { text: 'IN수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'unitCost', fieldName: 'unitCost', width: '80', header: { text: 'Unit Cost' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'inAmt', fieldName: 'inAmt', width: '80', header: { text: 'IN금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } }
  ],
};

module.exports = grid;
