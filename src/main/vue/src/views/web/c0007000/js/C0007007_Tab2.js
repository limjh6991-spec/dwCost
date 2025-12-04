/*
 * 타시스템 > 입고수불 자체 체크 > 기말/기초 체크
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
        const status = grid.getValue(newRow, '상태');
        if (status === '불일치') {
          return { background: '#fff5f5' };
        } else if (status === '전월 데이터 없음') {
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
    rowIndicator: { visible: true },
    sorting: { enabled: true },
    stateBar: { visible: false },
    fixed: { colBarWidth: 1, colCount: 3 },
  },

  fields: [
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: 'selCode', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'modelType', dataType: ValueType.TEXT },
    { fieldName: 'stock', dataType: ValueType.TEXT },
    { fieldName: 'boh', dataType: ValueType.NUMBER },
    { fieldName: 'prevEoh', dataType: ValueType.NUMBER },
    { fieldName: '차이수량', dataType: ValueType.NUMBER },
    { fieldName: '상태', dataType: ValueType.TEXT },
  ],

  columns: [
    {
      name: 'YYYYMM',
      fieldName: 'yyyymm',
      width: '80',
      header: { text: '기준월' },
      styleName: 'tc',
      editable: false,
    },
    {
      name: 'SEL_CODE',
      fieldName: 'selCode',
      width: '90',
      header: { text: 'SEL_CODE' },
      styleName: 'tc',
      editable: false,
    },
    {
      name: 'SITE',
      fieldName: 'site',
      width: '70',
      header: { text: 'SITE' },
      styleName: 'tc',
      editable: false,
    },
    {
      name: 'MODEL',
      fieldName: 'model',
      width: '150',
      header: { text: 'MODEL' },
      styleName: 'tl',
      editable: false,
    },
    {
      name: 'MODEL_TYPE',
      fieldName: 'modelType',
      width: '110',
      header: { text: 'MODEL_TYPE' },
      styleName: 'tc',
      editable: false,
    },
    {
      name: 'STOCK',
      fieldName: 'stock',
      width: '90',
      header: { text: 'STOCK' },
      styleName: 'tc',
      editable: false,
    },
    {
      name: 'BOH',
      fieldName: 'boh',
      width: '120',
      header: { text: 'BOH (당월기초수량)' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'PREV_EOH',
      fieldName: 'prevEoh',
      width: '120',
      header: { text: 'PREV_EOH (전월기말수량)' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: '차이수량',
      fieldName: '차이수량',
      width: '100',
      header: { text: '차이수량' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
      styleCallback: function (grid, dataCell) {
        var ret = {};
        var value = dataCell.value;
        
        if (value !== 0 && value !== null && Math.abs(value) > 0.01) {
          ret.renderer = { 
            type: 'text',
            styles: {
              background: '#fff3cd',
              foreground: '#dc3545',
              fontBold: true,
            }
          };
        }
        
        return ret;
      },
    },
    {
      name: '상태',
      fieldName: '상태',
      width: '130',
      header: { text: '상태' },
      styleName: 'tc',
      editable: false,
      renderer: {
        type: 'text',
        showTooltip: true,
      },
      styleCallback: function (grid, dataCell) {
        var ret = {};
        var status = dataCell.value;
        
        if (status === '정상') {
          ret.renderer = { 
            type: 'text',
            styles: {
              background: '#d1e7dd',
              foreground: '#0f5132',
              fontBold: true,
            }
          };
        } else if (status === '불일치') {
          ret.renderer = { 
            type: 'text',
            styles: {
              background: '#f8d7da',
              foreground: '#842029',
              fontBold: true,
            }
          };
        } else if (status === '전월 데이터 없음') {
          ret.renderer = { 
            type: 'text',
            styles: {
              background: '#fff3cd',
              foreground: '#664d03',
              fontBold: true,
            }
          };
        }
        
        return ret;
      },
    },
  ],
};

module.exports = grid;
