/** * 판매관리비 집계표 > 부서별 집계표 */
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
    fixed: { colBarWidth: 1, colCount: 1 },
  },
  fields: [
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: '계획', dataType: ValueType.NUMBER },
    { fieldName: '합계', dataType: ValueType.NUMBER },
  ],
  columns: [
    { name: '구분', fieldName: '구분', width: '80', header: { text: '구분' }, autoFilter: true, styleName: 'tl' },
    { name: '계획', fieldName: '계획', width: '80', header: { text: '계획' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0' },
    { name: '합계', fieldName: '합계', width: '80', header: { text: '합계' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0' },
  ],
};

module.exports = grid;