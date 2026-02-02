/*
 * 타시스템 > 생산정보 > 연구개발 수불 > 작업구분 팝업
 */
const { ValueType, GridFitStyle } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: false },
    copy: { enabled: true, singleMode: true },
    display: {
      columnMovable: false,
      editItemMerging: true,
      fitStyle: GridFitStyle.EVEN_FILL,
      emptyMessage: '조회된 데이터가 없습니다.',
      hscrollBar: true,
      showEmptyMessage: true,
    },
    edit: { editable: false },
    footer: { visible: false },
    paste: { enabled: false },
    rowIndicator: { visible: true },
    sorting: { enabled: true },
    stateBar: { visible: false },
  },

  grouping: {
    enabled: false,
    toast: false,
    levels: 0,
  },

  fields: [
    { fieldName: 'codeName', dataType: ValueType.TEXT },
  ],

  columns: [
    {
      name: 'codeName',
      fieldName: 'codeName',
      width: 200,
      header: { text: '작업구분' },
      styleName: 'tl',
      autoFilter: true,
    },
  ],
};

module.exports = grid;
