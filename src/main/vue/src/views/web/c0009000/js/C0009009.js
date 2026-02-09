/*
 * 제품별 손익계산서
 */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: false },
    copy: { enabled: true, singleMode: true },
    display: {
      columnMovable: false,
      editItemMerging: true,
      fitStyle: 'even',
      emptyMessage: '조회된 데이터가 없습니다.',
      hscrollBar: true,
      showEmptyMessage: true,
      headerDepth: 2,
      headerHeight: 40,
    },
    edit: { editable: false },
    footer: { visible: false },
    paste: { enabled: false },
    rowIndicator: { visible: true },
    sorting: { enabled: true },
    stateBar: { visible: false },
    filtering: { enabled: true },
    fixed: { colBarWidth: 1, colCount: 3 },
  },

  fields: [
    { fieldName: 'gubun', dataType: ValueType.TEXT },
    { fieldName: 'zTotal', dataType: ValueType.NUMBER },
    { fieldName: 'zMassTotal', dataType: ValueType.NUMBER },
    { fieldName: 'zDevTotal', dataType: ValueType.NUMBER },
    { fieldName: 'zCasTotal', dataType: ValueType.NUMBER },
    { fieldName: 'zBuyTotal', dataType: ValueType.NUMBER },
  ],


  columns: [
    { name: 'gubun', fieldName: 'gubun', width: 180, header: { text: '제품명' }, styleName: 'tl' },
    { name: 'zTotal', fieldName: 'zTotal', width: 130, header: { text: '총합계' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'zMassTotal', fieldName: 'zMassTotal', width: 130, header: { text: '양산' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'zDevTotal', fieldName: 'zDevTotal', width: 130, header: { text: '개발' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'zCasTotal', fieldName: 'zCasTotal', width: 130, header: { text: '카세트' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'zBuyTotal', fieldName: 'zBuyTotal', width: 130, header: { text: '구매' }, styleName: 'tr', numberFormat: '#,##0' },
  ],
};

module.exports = grid;