/*
 * 제품수불 체크 > ST003: 금액수식 검증 (OUT_AMT = BOH_AMT + IN_AMT - EOH_AMT)
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
      emptyMessage: '✅ 모든 금액수식이 정상입니다!',
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
    { fieldName: 'gubun', dataType: 'text' },
    { fieldName: 'expenSel', dataType: 'text' },
    { fieldName: 'bohAmt', dataType: 'number' },
    { fieldName: 'inAmt', dataType: 'number' },
    { fieldName: 'eohAmt', dataType: 'number' },
    { fieldName: 'outAmt', dataType: 'number' },
    { fieldName: 'calcOutAmt', dataType: 'number' },
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
      name: 'gubun',
      fieldName: 'gubun',
      type: 'data',
      width: 100,
      header: { text: '구분' },
      styleName: 'center-column',
    },
    {
      name: 'expenSel',
      fieldName: 'expenSel',
      type: 'data',
      width: 120,
      header: { text: '원가항목' },
      styleName: 'center-column',
    },
    {
      name: 'bohAmt',
      fieldName: 'bohAmt',
      type: 'data',
      width: 130,
      header: { text: 'BOH_AMT' },
      numberFormat: '#,##0',
      styleName: 'right-column',
    },
    {
      name: 'inAmt',
      fieldName: 'inAmt',
      type: 'data',
      width: 130,
      header: { text: 'IN_AMT' },
      numberFormat: '#,##0',
      styleName: 'right-column',
    },
    {
      name: 'eohAmt',
      fieldName: 'eohAmt',
      type: 'data',
      width: 130,
      header: { text: 'EOH_AMT' },
      numberFormat: '#,##0',
      styleName: 'right-column',
    },
    {
      name: 'outAmt',
      fieldName: 'outAmt',
      type: 'data',
      width: 130,
      header: { text: 'OUT_AMT' },
      numberFormat: '#,##0',
      styleName: 'right-column',
    },
    {
      name: 'calcOutAmt',
      fieldName: 'calcOutAmt',
      type: 'data',
      width: 130,
      header: { text: '계산OUT_AMT' },
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
      width: 130,
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
