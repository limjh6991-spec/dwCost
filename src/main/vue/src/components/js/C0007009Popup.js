/*
 * 타시스템 > 불량반품 (DOI_PROD_SUBUL) > 팝업
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

  fields: [
    { fieldName: '도우코드', dataType: ValueType.TEXT },
    { fieldName: '세부모델', dataType: ValueType.TEXT },
    { fieldName: 'inch',  dataType: ValueType.TEXT },
    { fieldName: 'outMonth', dataType: ValueType.NUMBER },
  ],

  columns: [
    {
      name: '도우코드',
      fieldName: '도우코드',
      width: 100,
      header: { text: '도우코드' },
      styleName: 'tc',
      autoFilter: true,
    },
        {
      name: '세부모델',
      fieldName: '세부모델',
      width: 100,
      header: { text: '세부모델' },
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
    {
      name: 'outMonth',
      fieldName: 'outMonth',
      width: 80,
      header: { text: 'OUT_MONTH' },
      styleName: 'tr',
      autoFilter: true,
      numberFormat: '#,##0',
    },
  ],
};

module.exports = grid;
