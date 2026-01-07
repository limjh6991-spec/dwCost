/*
 * 결산증빙 자료 > 매출원가
 */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: false },
    copy: { enabled: true, singleMode: false },
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
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: '모델', dataType: ValueType.TEXT },
    { fieldName: 'local구분', dataType: ValueType.TEXT },
    { fieldName: '판매단위', dataType: ValueType.TEXT },
    { fieldName: '거래처', dataType: ValueType.TEXT },
    { fieldName: '월', dataType: ValueType.TEXT },
    { fieldName: 'outQty', dataType: ValueType.NUMBER },
    { fieldName: 'outAmt', dataType: ValueType.NUMBER },
  ],
  columns: [
    { name: '구분', fieldName: '구분', width: '80', header: { text: '구분' }, mergeRule: { criteria: "value['구분']+value['모델']+value['local구분']+value['판매단위']+value['거래처']" }, autoFilter: true, styleName: 'tl' },
    { name: '모델', fieldName: '모델', width: '80', header: { text: '모델' }, mergeRule: { criteria: "value['구분']+value['모델']+value['local구분']+value['판매단위']+value['거래처']" }, autoFilter: true, styleName: 'tl' },
    { name: 'local구분', fieldName: 'local구분', width: '110', header: { text: 'Local구분' }, mergeRule: { criteria: "value['구분']+value['모델']+value['local구분']+value['판매단위']+value['거래처']" }, autoFilter: true, styleName: 'tl' },
    { name: '판매단위', fieldName: '판매단위', width: '120', header: { text: '판매단위' }, mergeRule: { criteria: "value['구분']+value['모델']+value['local구분']+value['판매단위']+value['거래처']" }, autoFilter: true, styleName: 'tl' },
    { name: '거래처', fieldName: '거래처', width: '90', header: { text: '거래처' }, mergeRule: { criteria: "value['구분']+value['모델']+value['local구분']+value['판매단위']+value['거래처']" }, autoFilter: true, styleName: 'tl' },
    { name: '월', fieldName: '월', width: '80', header: { text: '월' }, autoFilter: true, styleName: 'tl', footer: { text: '합계' } },
    { name: 'outQty', fieldName: 'outQty', width: '80', header: { text: '수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'outAmt', fieldName: 'outAmt', width: '80', header: { text: '금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.######', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
  ],
  layout: [
    '구분',
    '모델',
    'local구분',
    '판매단위',
    '거래처',
    '월',
    {
      name: '판매제품',
      direction: 'horizontal',
      items: ['outQty', 'outAmt'],
      header: { text: '판매제품' },
    },
  ],
};

module.exports = grid;
