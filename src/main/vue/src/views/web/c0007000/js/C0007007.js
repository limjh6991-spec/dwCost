/*
 * 타시스템 > 입고수불 자체 체크
 */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: false },
    copy: { enabled: true, singleMode: false },
    display: { 
      columnMovable: false, 
      editItemMerging: true, 
      fitStyle: 'none',
      minWidth: 100,
      emptyMessage: '조회된 데이터가 없습니다.', 
      hscrollBar: true, 
      showEmptyMessage: true,
      rowStyleCallback: function(grid, item, fixed) {
        const status = grid.getValue(item.index, '상태');
        if (status === '오류') {
          return { background: '#f8d7da' };
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
    // fixed: { colBarWidth: 1, colCount: 3 },
  },

  fields: [
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: 'selCode', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'modelType', dataType: ValueType.TEXT },
    { fieldName: 'stock', dataType: ValueType.TEXT },
    { fieldName: 'boh', dataType: ValueType.NUMBER },
    { fieldName: 'inputQty', dataType: ValueType.NUMBER },
    { fieldName: 'outQty', dataType: ValueType.NUMBER },
    { fieldName: 'eoh', dataType: ValueType.NUMBER },
    { fieldName: 'inputEtc', dataType: ValueType.NUMBER },
    { fieldName: 'inputMoving', dataType: ValueType.NUMBER },
    { fieldName: 'inputProd', dataType: ValueType.NUMBER },
    { fieldName: 'outSheet', dataType: ValueType.NUMBER },
    { fieldName: 'outReturn', dataType: ValueType.NUMBER },
    { fieldName: 'outInvoice', dataType: ValueType.NUMBER },
    { fieldName: 'outEtc', dataType: ValueType.NUMBER },
    { fieldName: 'outMoving', dataType: ValueType.NUMBER },
    { fieldName: 'inOut체크', dataType: ValueType.NUMBER },
    { fieldName: '상태', dataType: ValueType.TEXT },
    { fieldName: '비고', dataType: ValueType.TEXT },
  ],

  columns: [
    // {
    //   name: 'YYYYMM',
    //   fieldName: 'yyyymm',
    //   width: '80',
    //   header: { text: '기준월' },
    //   styleName: 'tc',
    //   editable: false,
    // },
    // {
    //   name: 'SEL_CODE',
    //   fieldName: 'selCode',
    //   width: '100',
    //   header: { text: 'SEL_CODE' },
    //   styleName: 'tc',
    //   editable: false,
    // },
    // {
    //   name: 'SITE',
    //   fieldName: 'site',
    //   width: '80',
    //   header: { text: 'SITE' },
    //   styleName: 'tc',
    //   editable: false,
    // },
    {
      name: '상태',
      fieldName: '상태',
      width: '80',
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
          ret.styleName = 'tc status-normal';
          ret.renderer = { 
            type: 'text',
            styles: {
              background: '#d1e7dd',
              foreground: '#0f5132',
              fontBold: true,
            }
          };
        } else if (status === '오류') {
          ret.styleName = 'tc status-error';
          ret.renderer = { 
            type: 'text',
            styles: {
              background: '#f8d7da',
              foreground: '#842029',
              fontBold: true,
            }
          };
        }
        
        return ret;
      },
    },
    {
      name: '비고',
      fieldName: '비고',
      width: '150',
      header: { text: '비고' },
      styleName: 'tl',
      editable: false,
      renderer: {
        type: 'text',
        showTooltip: true,
      },
      styleCallback: function (grid, dataCell) {
        var ret = {};
        var remark = dataCell.value;
        
        if (remark && remark.indexOf('오류') >= 0) {
          ret.renderer = { 
            type: 'text',
            styles: {
              foreground: '#842029',
              fontBold: true,
            }
          };
        }
        
        return ret;
      },
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
      width: '120',
      header: { text: 'MODEL_TYPE' },
      styleName: 'tc',
      editable: false,
    },
    {
      name: 'STOCK',
      fieldName: 'stock',
      width: '100',
      header: { text: 'STOCK' },
      styleName: 'tc',
      editable: false,
    },
    {
      name: 'BOH',
      fieldName: 'boh',
      width: '100',
      header: { text: 'BOH' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'INPUT',
      fieldName: 'inputQty',
      width: '100',
      header: { text: 'INPUT' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'OUT',
      fieldName: 'outQty',
      width: '100',
      header: { text: 'OUT' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'EOH',
      fieldName: 'eoh',
      width: '100',
      header: { text: 'EOH' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'INPUT_ETC',
      fieldName: 'inputEtc',
      width: '110',
      header: { text: 'INPUT_ETC' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'INPUT_MOVING',
      fieldName: 'inputMoving',
      width: '130',
      header: { text: 'INPUT_MOVING' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'INPUT_PROD',
      fieldName: 'inputProd',
      width: '120',
      header: { text: 'INPUT_PROD' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'OUT_SHEET',
      fieldName: 'outSheet',
      width: '110',
      header: { text: 'OUT_SHEET' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'OUT_RETURN',
      fieldName: 'outReturn',
      width: '120',
      header: { text: 'OUT_RETURN' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'OUT_INVOICE',
      fieldName: 'outInvoice',
      width: '130',
      header: { text: 'OUT_INVOICE' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'OUT_ETC',
      fieldName: 'outEtc',
      width: '100',
      header: { text: 'OUT_ETC' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'OUT_MOVING',
      fieldName: 'outMoving',
      width: '120',
      header: { text: 'OUT_MOVING' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'IN_OUT_체크',
      fieldName: 'inOut체크',
      width: '110',
      header: { text: 'IN-OUT 체크' },
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
  ],
};

module.exports = grid;
