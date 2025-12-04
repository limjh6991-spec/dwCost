/*
 * 타시스템 > 생산수불 자체 체크
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
          return {
            background: '#f8d7da',
            foreground: '#842029',
            fontBold: true
          };
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
    { fieldName: 'dwSite', dataType: ValueType.TEXT },
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: '구분Ord', dataType: ValueType.NUMBER },
    { fieldName: '도우코드', dataType: ValueType.TEXT },
    { fieldName: 'modelNType', dataType: ValueType.TEXT },
    { fieldName: '도우모델', dataType: ValueType.TEXT },
    { fieldName: '작업구분', dataType: ValueType.TEXT },
    { fieldName: 'org작업구분', dataType: ValueType.TEXT },
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'inch', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: 'bohMonth', dataType: ValueType.NUMBER },
    { fieldName: 'inMonth', dataType: ValueType.NUMBER },
    { fieldName: 'bonusMonth', dataType: ValueType.NUMBER },
    { fieldName: 'eohMonth', dataType: ValueType.NUMBER },
    { fieldName: 'outMonth', dataType: ValueType.NUMBER },
    { fieldName: 'lossMonth', dataType: ValueType.NUMBER },
    { fieldName: 'ngMonth', dataType: ValueType.NUMBER },
    { fieldName: '수율제외Month', dataType: ValueType.NUMBER },
    { fieldName: 'rework진행Month', dataType: ValueType.NUMBER },
    { fieldName: 'shippingPlanMonth', dataType: ValueType.NUMBER },
    { fieldName: 'shippingActualMonth', dataType: ValueType.NUMBER },
    { fieldName: 'materialLoss', dataType: ValueType.NUMBER },
    { fieldName: 'inOut체크', dataType: ValueType.NUMBER },
    { fieldName: 'loss체크', dataType: ValueType.NUMBER },
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
    //   width: '80',
    //   header: { text: 'SEL_CODE' },
    //   styleName: 'tc',
    //   editable: false,
    // },
    // {
    //   name: 'DW_SITE',
    //   fieldName: 'dwSite',
    //   width: '80',
    //   header: { text: 'DW_SITE' },
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
      width: '200',
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
      name: 'GUBUN',
      fieldName: '구분',
      width: '70',
      header: { text: '구분' },
      styleName: 'tc',
      editable: false,
    },
    {
      name: 'GUBUN_ORD',
      fieldName: '구분Ord',
      width: '80',
      header: { text: '구분_ORD' },
      styleName: 'tc',
      editable: false,
    },
    // {
    //   name: 'DW_CODE',
    //   fieldName: '도우코드',
    //   width: '100',
    //   header: { text: '도우코드' },
    //   styleName: 'tc',
    //   editable: false,
    // },
    {
      name: '도우코드',
      fieldName: '도우코드',
      width: '120',
      header: { text: '도우코드' },
      styleName: 'tc',
      editable: false,
    },
    {
      name: 'DW_MODEL',
      fieldName: '도우모델',
      width: '100',
      header: { text: '도우모델' },
      styleName: 'tc',
      editable: false,
    },
    {
      name: 'WORK_GUBUN',
      fieldName: '작업구분',
      width: '80',
      header: { text: '작업구분' },
      styleName: 'tc',
      editable: false,
    },
    {
      name: 'ORG_WORK_GUBUN',
      fieldName: 'org작업구분',
      width: '100',
      header: { text: 'ORG작업구분' },
      styleName: 'tc',
      editable: false,
    },
    {
      name: 'MODEL',
      fieldName: 'model',
      width: '120',
      header: { text: 'MODEL' },
      styleName: 'tl',
      editable: false,
    },
    {
      name: 'INCH',
      fieldName: 'inch',
      width: '70',
      header: { text: 'INCH' },
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
      name: 'BOH_MONTH',
      fieldName: 'bohMonth',
      width: '100',
      header: { text: 'BOH_MONTH' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'IN_MONTH',
      fieldName: 'inMonth',
      width: '100',
      header: { text: 'IN_MONTH' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'BONUS_MONTH',
      fieldName: 'bonusMonth',
      width: '110',
      header: { text: 'BONUS_MONTH' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'EOH_MONTH',
      fieldName: 'eohMonth',
      width: '100',
      header: { text: 'EOH_MONTH' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'OUT_MONTH',
      fieldName: 'outMonth',
      width: '100',
      header: { text: 'OUT_MONTH' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'LOSS_MONTH',
      fieldName: 'lossMonth',
      width: '110',
      header: { text: 'LOSS_MONTH' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'NG_MONTH',
      fieldName: 'ngMonth',
      width: '100',
      header: { text: 'NG_MONTH' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: '수율제외_MONTH',
      fieldName: '수율제외Month',
      width: '120',
      header: { text: '수율제외_MONTH' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'REWORK진행_MONTH',
      fieldName: 'rework진행Month',
      width: '140',
      header: { text: 'REWORK진행_MONTH' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'SHIPPING_PLAN_MONTH',
      fieldName: 'shippingPlanMonth',
      width: '160',
      header: { text: 'SHIPPING_PLAN_MONTH' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'SHIPPING_ACTUAL_MONTH',
      fieldName: 'shippingActualMonth',
      width: '180',
      header: { text: 'SHIPPING_ACTUAL_MONTH' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'MATERIAL_LOSS',
      fieldName: 'materialLoss',
      width: '130',
      header: { text: 'MATERIAL_LOSS' },
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
    {
      name: 'LOSS_체크',
      fieldName: 'loss체크',
      width: '110',
      header: { text: 'LOSS 체크' },
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
