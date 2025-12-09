/**
 * Tab090009 - 제품별 판매관리비 집계표
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
    rowIndicator: { visible: true },
    sorting: { enabled: true },
    stateBar: { visible: false },
    filtering: { enabled: true },
    fixed: { colBarWidth: 1, colCount: 3 },
  },
  fields: [
    { fieldName: 'gubun', dataType: ValueType.TEXT },
    { fieldName: '제조경비계획', dataType: ValueType.NUMBER },
    { fieldName: 'z합계', dataType: ValueType.NUMBER },
  ],
  columns: [
    { name: 'gubun', fieldName: 'gubun', width: '80', header: { text: '구분' }, autoFilter: true, styleName: 'tl' },
    { name: '판매관리비계획', fieldName: '판매관리비계획', width: '80', header: { text: '판매관리비 계획' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'z합계', fieldName: 'z합계', width: '80', header: { text: '판매관리비 합계' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0' },
  ],
};

module.exports = grid;