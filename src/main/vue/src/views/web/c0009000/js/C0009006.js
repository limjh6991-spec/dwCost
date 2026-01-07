/** * 원부자재 배부표(제품별) */
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
    fixed: { colBarWidth: 1, colCount: 6 },
  },
  fields: [
    { fieldName: '자재분류', dataType: ValueType.TEXT },
    { fieldName: '자재대분류', dataType: ValueType.TEXT },
    { fieldName: '자재중분류', dataType: ValueType.TEXT },
    { fieldName: '자재명', dataType: ValueType.TEXT },
    { fieldName: '자재번호', dataType: ValueType.TEXT },
    { fieldName: 'size', dataType: ValueType.TEXT },
    { fieldName: 'z합계', dataType: ValueType.NUMBER },
  ],
  columns: [
    { name: '자재분류', fieldName: '자재분류', width: '80', header: { text: '자재분류' }, autoFilter: true, styleName: 'tl' },
    { name: '자재대분류', fieldName: '자재대분류', width: '80', header: { text: '대분류' }, autoFilter: true, styleName: 'tl' },
    { name: '자재중분류', fieldName: '자재중분류', width: '80', header: { text: '중분류' }, autoFilter: true, styleName: 'tl' },
    { name: '자재명', fieldName: '자재명', width: '80', header: { text: '품명' }, autoFilter: true, styleName: 'tl' },
    { name: '자재번호', fieldName: '자재번호', width: '80', header: { text: '품번' }, autoFilter: true, styleName: 'tl' },
    { name: 'size', fieldName: 'size', width: '80', header: { text: '규격' }, autoFilter: true, styleName: 'tl' },
    { name: 'z합계', fieldName: 'z합계', width: '80', header: { text: '제조경비 합계' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
  ],
};

module.exports = grid;
