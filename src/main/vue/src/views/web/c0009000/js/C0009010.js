/** 총 원가 */
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
      headerDepth: 3,
      headerHeight: 40,
    },
    edit: { editable: false },
    footer: { visible: false },
    paste: { enabled: false },
    rowIndicator: { visible: true },
    sorting: { enabled: true },
    stateBar: { visible: false },
    filtering: { enabled: true },
    fixed: { colBarWidth: 1, colCount: 1 },
  },
  fields: [
    { fieldName: 'gubun', dataType: ValueType.TEXT },
    { fieldName: '총합계', dataType: ValueType.NUMBER },
    { fieldName: '양산합계', dataType: ValueType.NUMBER },
    { fieldName: '개발합계', dataType: ValueType.NUMBER },
    { fieldName: '카세트합계', dataType: ValueType.NUMBER },
  ],
  columns: [
    { name: 'gubun', fieldName: 'gubun', width: 150, header: { text: '제품명' }, styleName: 'tl'},
    { name: '총합계', fieldName: '총합계', width: 120, header: { text: '총 합계' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: '양산합계', fieldName: '양산합계', width: 120, header: { text: '양산 합계' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: '개발합계', fieldName: '개발합계', width: 120, header: { text: '개발 합계' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: '카세트합계', fieldName: '카세트합계', width: 120, header: { text: '카세트 합계' }, styleName: 'tr', numberFormat: '#,##0' },
  ]
};

module.exports = grid;
