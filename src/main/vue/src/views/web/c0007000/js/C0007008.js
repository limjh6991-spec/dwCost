/*
 * 타시스템 > 생산/입고/판매 체크 - Tab1 (생산 <-> 입고)
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
      emptyMessage: '조회된 데이터가 없습니다.', 
      hscrollBar: true, 
      showEmptyMessage: true,
      rowChangeCallback: function(grid, oldRow, newRow) {
        const status = grid.getValue(newRow, 'status');
        if (status === '불일치') {
          return { background: '#fff5f5' };
        } else if (status === '생산 데이터 없음' || status === '입고 데이터 없음') {
          return { background: '#fffbf0' };
        }
        return null;
      }
    },
    edit: { editable: false },
    footer: { visible: false },
    header: { height: 30 },
    hideDeletedRows: true,
    paste: { enabled: false },
    stateBar: { visible: false },
    sorting: { enabled: true, style: 'inclusive' },
    fixed: { colBarWidth: 1, colCount: 2 },
  },
  fields: [
    { fieldName: 'yyyymm', dataType: 'text' },
    { fieldName: 'selCode', dataType: 'text' },
    { fieldName: 'site', dataType: 'text' },
    { fieldName: 'model', dataType: 'text' },
    { fieldName: 'modelType', dataType: 'text' },
    { fieldName: 'prodOut', dataType: 'number' },
    { fieldName: 'stockInput', dataType: 'number' },
    { fieldName: 'diffQty', dataType: 'number' },
    { fieldName: 'status', dataType: 'text' },
    { fieldName: 'remark', dataType: 'text' },
  ],
  columns: [
    {
      name: 'status',
      fieldName: 'status',
      type: 'data',
      width: 150,
      minWidth: 150,
      maxWidth: 150,
      resizable: false,
      fixedWidth: true,
      header: { text: '상태' },
      editable: false,
      styleName: 'center-column',
      styleCallback: function (grid, dataCell) {
        const value = dataCell.value;
        if (value === '일치') {
          return { background: '#d1e7dd', foreground: '#0f5132' };
        } else if (value === '불일치') {
          return { background: '#f8d7da', foreground: '#842029', fontBold: true };
        } else {
          return { background: '#fff3cd', foreground: '#664d03' };
        }
      },
    },
    {
      name: 'remark',
      fieldName: 'remark',
      type: 'data',
      width: 150,
      minWidth: 150,
      maxWidth: 150,
      resizable: false,
      fixedWidth: true,
      header: { text: '비고' },
      editable: false,
      styleName: 'left-column',
    },
    {
      name: 'yyyymm',
      fieldName: 'yyyymm',
      type: 'data',
      width: 90,
      header: { text: '기준월' },
      editable: false,
      styleName: 'left-column',
    },
    {
      name: 'selCode',
      fieldName: 'selCode',
      type: 'data',
      width: 100,
      header: { text: 'SEL_CODE' },
      editable: false,
      styleName: 'left-column',
    },
    {
      name: 'site',
      fieldName: 'site',
      type: 'data',
      width: 80,
      header: { text: 'SITE' },
      editable: false,
      styleName: 'left-column',
    },
    {
      name: 'model',
      fieldName: 'model',
      type: 'data',
      width: 150,
      header: { text: 'MODEL' },
      editable: false,
      styleName: 'left-column',
    },
    {
      name: 'modelType',
      fieldName: 'modelType',
      type: 'data',
      width: 150,
      header: { text: 'MODEL_TYPE' },
      editable: false,
      styleName: 'left-column',
    },
    {
      name: 'prodOut',
      fieldName: 'prodOut',
      type: 'data',
      width: 120,
      header: { text: '생산OUT' },
      editable: false,
      numberFormat: '#,##0',
      styleName: 'right-column',
    },
    {
      name: 'stockInput',
      fieldName: 'stockInput',
      type: 'data',
      width: 120,
      header: { text: '입고INPUT' },
      editable: false,
      numberFormat: '#,##0',
      styleName: 'right-column',
    },
    {
      name: 'diffQty',
      fieldName: 'diffQty',
      type: 'data',
      width: 120,
      header: { text: '차이수량' },
      editable: false,
      numberFormat: '#,##0',
      styleName: 'right-column',
      styleCallback: function (grid, dataCell) {
        const value = dataCell.value;
        if (value !== 0) {
          return { 
            background: '#fff3cd', 
            foreground: '#856404',
            fontBold: true
          };
        }
      },
    },
  ],
};

export default grid;
