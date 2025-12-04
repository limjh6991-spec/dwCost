/*
 * 제품수불 체크 > ST002: 생산재고연결 검증 (FAB_COST.out = STOCK_COST.IN_AMT)
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
      emptyMessage: '✅ 모든 생산-재고 연결이 정상입니다!',
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
    { fieldName: 'expenSelName', dataType: 'text' },
    { fieldName: 'fabOutAmt', dataType: 'number' },
    { fieldName: 'stockInAmt', dataType: 'number' },
    { fieldName: 'diffAmt', dataType: 'number' },
    { fieldName: 'errorType', dataType: 'text' },
  ],
  columns: [
    {
      name: 'gubun',
      fieldName: 'gubun',
      type: 'data',
      width: 100,
      header: { text: '구분' }, autoFilter: true,
      styleName: 'center-column',
    },
    {
      name: 'model',
      fieldName: 'model',
      type: 'data',
      width: 150,
      header: { text: '모델' }, autoFilter: true,
      styleName: 'left-column',
    },
    {
      name: 'expenSel',
      fieldName: 'expenSel',
      type: 'data',
      width: 120,
      header: { text: '원가항목' }, autoFilter: true,
      styleName: 'center-column',
    },
    {
      name: 'expenSelName',
      fieldName: 'expenSelName',
      type: 'data',
      width: 150,
      header: { text: '원가항목명' }, autoFilter: true,
      styleName: 'tl',
    },
    {
      name: 'fabOutAmt',
      fieldName: 'fabOutAmt',
      type: 'data',
      width: 140,
      header: { text: '생산OUT' },
      numberFormat: '#,##0',
      styleName: 'tr',
    },
    {
      name: 'stockInAmt',
      fieldName: 'stockInAmt',
      type: 'data',
      width: 140,
      header: { text: '재고IN' },
      numberFormat: '#,##0',
      styleName: 'tr',
    },
    {
      name: 'diffAmt',
      fieldName: 'diffAmt',
      type: 'data',
      width: 140,
      header: { text: '차이금액' },
      numberFormat: '#,##0',
      styleName: 'tr',
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
    {
      name: 'errorType',
      fieldName: 'errorType',
      type: 'data',
      width: 180,
      header: { text: '오류유형' },
      styleName: 'center-column',
      styleCallback: function (grid, dataCell) {
        const value = dataCell.value;
        if (value === '생산데이터 없음' || value === '재고데이터 없음') {
          return { background: '#fff3cd', foreground: '#664d03' };
        } else if (value === '금액 불일치') {
          return { background: '#f8d7da', foreground: '#842029', fontBold: true };
        }
      },
    },
  ],
};

export default grid;
