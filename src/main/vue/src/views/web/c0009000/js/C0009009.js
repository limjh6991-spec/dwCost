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
      showEmptyMessage: true 
    },
    edit: { editable: false },
    footer: { visible: true },
    paste: { enabled: false },
    rowIndicator: { visible: true },
    sorting: { enabled: true },
    stateBar: { visible: false },
    filtering: { enabled: true },
  },
  fields: [
  ],
  columns: [
  ]
};

module.exports = grid;