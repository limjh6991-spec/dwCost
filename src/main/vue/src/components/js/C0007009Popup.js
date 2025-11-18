/*
 * 타시스템 > 불량반품 (DOI_MODEL_MAST) > 팝업
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
    footer: { visible: true },
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

  // 🔹 데이터 필드 정의 (백엔드 컬럼명과 매핑)
  fields: [
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'spec',  dataType: ValueType.TEXT },
    { fieldName: 'inch',  dataType: ValueType.TEXT },
  ],

  // 🔹 컬럼 정의 (화면에 보이는 컬럼)
  columns: [
    {
      name: 'model',
      fieldName: 'model',
      width: 100,
      header: { text: '모델명' },
      styleName: 'tc',
      autoFilter: true,
    },
    {
      name: 'spec',
      fieldName: 'spec',
      width: 200,
      header: { text: '규격' },
      styleName: 'tc',
      autoFilter: true,
    },
    {
      name: 'inch',
      fieldName: 'inch',
      width: 80,
      header: { text: '인치' },
      styleName: 'tc',
      autoFilter: true,
    },
  ],
};

module.exports = grid;
