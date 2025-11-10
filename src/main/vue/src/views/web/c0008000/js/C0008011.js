/*
 * 결산증빙 자료 > 제품수불_금액(DOI_STCO)
 */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: false },
    copy: { enabled: true, singleMode: true },
    display: { columnMovable: false, editItemMerging: true, fitStyle: 'even', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
    edit: { editable: false },
    footer: { visible: true },
    // header: { height: 60 }, // 그룹 헤더를 위한 높이 설정
    paste: { enabled: false },
    rowIndicator: { visible: true },
    sorting: { enabled: true },
    stateBar: { visible: false },
    filtering: { enabled: true },
    fixed: { colBarWidth: 0, colCount: 0 },
  },

  fields: [
    // { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    // { fieldName: 'selCode', dataType: ValueType.TEXT },
    // { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'bohQty', dataType: ValueType.NUMBER },
    { fieldName: 'bohAmt', dataType: ValueType.NUMBER },
    { fieldName: 'inQty', dataType: ValueType.NUMBER },
    { fieldName: 'inAmt', dataType: ValueType.NUMBER },
    { fieldName: 'eohQty', dataType: ValueType.NUMBER },
    { fieldName: 'eohAmt', dataType: ValueType.NUMBER },
    { fieldName: 'outQty', dataType: ValueType.NUMBER },
    { fieldName: 'outAmt', dataType: ValueType.NUMBER },
  ],

  columns: [
    // { name: 'yyyymm', fieldName: 'yyyymm', width: '80', header: { text: 'YYYYMM' }, autoFilter: true, styleName: 'tl' },
    // { name: 'selCode', fieldName: 'selCode', width: '80', header: { text: 'SEL_CODE' }, autoFilter: true, styleName: 'tl' },
    // { name: 'site', fieldName: 'site', width: '80', header: { text: '사이트' }, autoFilter: true, styleName: 'tl' },
    { name: '구분', fieldName: '구분', width: '80', header: { text: '구분' }, autoFilter: true, styleName: 'tl' },
    { name: 'model', fieldName: 'model', width: '80', header: { text: '모델명' }, autoFilter: true, styleName: 'tl', footer: { text: '합계' } },
    { name: 'bohQty', fieldName: 'bohQty', width: '80', header: { text: 'BOH 수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'bohAmt', fieldName: 'bohAmt', width: '80', header: { text: 'BOH 금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'inQty', fieldName: 'inQty', width: '80', header: { text: 'IN 수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'inAmt', fieldName: 'inAmt', width: '80', header: { text: 'IN 금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'eohQty', fieldName: 'eohQty', width: '80', header: { text: 'EOH 수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'eohAmt', fieldName: 'eohAmt', width: '80', header: { text: 'EOH 금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'outQty', fieldName: 'outQty', width: '80', header: { text: 'OUT 수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'outAmt', fieldName: 'outAmt', width: '80', header: { text: 'OUT 금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } }
  ],
};

module.exports = grid;
