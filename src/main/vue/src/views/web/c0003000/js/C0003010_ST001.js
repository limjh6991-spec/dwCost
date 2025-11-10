/*
 * 제품수불 체크 > ST001: 수량수식 검증 (EOH = BOH + INPUT - OUT)
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
      emptyMessage: '✅ 모든 수량수식이 정상입니다!',
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
    { fieldName: 'input', dataType: 'number' },
    { fieldName: 'out', dataType: 'number' },
    { fieldName: 'eoh', dataType: 'number' },
    { fieldName: 'calcEoh', dataType: 'number' },
    { fieldName: 'diff', dataType: 'number' },
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
      width: 100,
      header: { text: '재고구분' },
      styleName: 'center-column',
    },
    {
      name: 'boh',
      fieldName: 'boh',
      type: 'data',
      width: 120,
      header: { text: 'BOH' },
      numberFormat: '#,##0',
      styleName: 'right-column',
    },
    {
      name: 'input',
      fieldName: 'input',
      type: 'data',
      width: 120,
      header: { text: 'INPUT' },
      numberFormat: '#,##0',
      styleName: 'right-column',
    },
    {
      name: 'out',
      fieldName: 'out',
      type: 'data',
      width: 120,
      header: { text: 'OUT' },
      numberFormat: '#,##0',
      styleName: 'right-column',
    },
    {
      name: 'eoh',
      fieldName: 'eoh',
      type: 'data',
      width: 120,
      header: { text: 'EOH' },
      numberFormat: '#,##0',
      styleName: 'right-column',
    },
    {
      name: 'calcEoh',
      fieldName: 'calcEoh',
      type: 'data',
      width: 120,
      header: { text: '계산EOH' },
      numberFormat: '#,##0',
      styleName: 'right-column',
      styleCallback: function (grid, dataCell) {
        return { background: '#e7f3ff', foreground: '#0066cc' };
      },
    },
    {
      name: 'diff',
      fieldName: 'diff',
      type: 'data',
      width: 120,
      header: { text: '차이' },
      numberFormat: '#,##0.##',
      styleName: 'right-column',
      styleCallback: function (grid, dataCell) {
        const value = dataCell.value;
        if (Math.abs(value) > 0.01) {
          return {
            background: '#f8d7da',
            foreground: '#842029',
            fontBold: true,
          };
        }
      },
    },
  ],
};

export default grid;
