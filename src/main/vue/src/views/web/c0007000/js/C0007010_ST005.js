/*
 * 제품수불 체크 > ST005: 음수재고 검증 (BOH < 0 OR EOH < 0)
 */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: false },
    copy: { enabled: true, singleMode: false },
    display: {
      columnMovable: false,
      editItemMerging: true,
      fitStyle: 'even',
      emptyMessage: '✅ 음수재고가 없습니다!',
      hscrollBar: true,
      showEmptyMessage: true,
    },
    edit: { editable: false },
    footer: { visible: false },
    header: { height: 30 },
    hideDeletedRows: true,
    paste: { enabled: false },
    stateBar: { visible: false },
    sorting: { enabled: true, style: 'inclusive' },
  },
  fields: [
    { fieldName: 'model', dataType: 'text' },
    { fieldName: 'stock', dataType: 'text' },
    { fieldName: 'boh', dataType: 'number' },
    { fieldName: 'eoh', dataType: 'number' },
    { fieldName: 'errorType', dataType: 'text' },
    { fieldName: 'remark', dataType: 'text' },
  ],
  columns: [
    {
      name: 'model',
      fieldName: 'model',
      type: 'data',
      width: 150,
      header: { text: '모델' },
      styleName: 'left-column',
    },
    {
      name: 'stock',
      fieldName: 'stock',
      type: 'data',
      width: 120,
      header: { text: '재고구분' },
      styleName: 'center-column',
    },
    {
      name: 'boh',
      fieldName: 'boh',
      type: 'data',
      width: 150,
      header: { text: 'BOH (기초재고)' },
      numberFormat: '#,##0',
      styleName: 'right-column',
      styleCallback: function (grid, dataCell) {
        const value = dataCell.value;
        if (value < 0) {
          return {
            background: '#f8d7da',
            foreground: '#842029',
            fontBold: true,
          };
        }
      },
    },
    {
      name: 'eoh',
      fieldName: 'eoh',
      type: 'data',
      width: 150,
      header: { text: 'EOH (기말재고)' },
      numberFormat: '#,##0',
      styleName: 'right-column',
      styleCallback: function (grid, dataCell) {
        const value = dataCell.value;
        if (value < 0) {
          return {
            background: '#f8d7da',
            foreground: '#842029',
            fontBold: true,
          };
        }
      },
    },
    {
      name: 'errorType',
      fieldName: 'errorType',
      type: 'data',
      width: 150,
      header: { text: '오류유형' },
      styleName: 'center-column',
      styleCallback: function (grid, dataCell) {
        const value = dataCell.value;
        if (value === 'BOH 음수' || value === 'EOH 음수') {
          return { background: '#f8d7da', foreground: '#842029', fontBold: true };
        }
      },
    },
    {
      name: 'remark',
      fieldName: 'remark',
      type: 'data',
      width: 400,
      header: { text: '비고' },
      styleName: 'left-column',
    },
  ],
};

export default grid;
