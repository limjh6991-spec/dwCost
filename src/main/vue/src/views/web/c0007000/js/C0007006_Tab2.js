/*
 * 타시스템 > 생산수불 자체 체크 > 기말/기초 체크
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
        // Row 전체 스타일 적용
        const status = grid.getValue(newRow, '상태');
        if (status === '불일치') {
          return { background: '#fff5f5' }; // 연한 빨간색 배경
        } else if (status === '전월 데이터 없음') {
          return { background: '#fffbf0' }; // 연한 노란색 배경
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
    { fieldName: '상태', dataType: ValueType.TEXT },
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: 'selCode', dataType: ValueType.TEXT },
    { fieldName: 'dwSite', dataType: ValueType.TEXT },
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: '구분Ord', dataType: ValueType.NUMBER },
    { fieldName: '도우코드', dataType: ValueType.TEXT },
    { fieldName: '도우모델', dataType: ValueType.TEXT },
    { fieldName: '작업구분', dataType: ValueType.TEXT },
    { fieldName: 'org작업구분', dataType: ValueType.TEXT },
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'inch', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: 'bohMonth', dataType: ValueType.NUMBER },
    { fieldName: 'prevEohMonth', dataType: ValueType.NUMBER },
    { fieldName: '차이수량', dataType: ValueType.NUMBER },
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
      width: '120',
      header: { text: '상태' },
      styleName: 'tc',
      editable: false,
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
    {
      name: '구분',
      fieldName: '구분',
      width: '70',
      header: { text: '구분' },
      styleName: 'tc',
      editable: false,
    },
    {
      name: '구분_ORD',
      fieldName: '구분Ord',
      width: '80',
      header: { text: '구분_ORD' },
      styleName: 'number',
      editable: false,
    },
    {
      name: '도우코드',
      fieldName: '도우코드',
      width: '90',
      header: { text: '도우코드' },
      styleName: 'tc',
      editable: false,
    },
    {
      name: '도우모델',
      fieldName: '도우모델',
      width: '100',
      header: { text: '도우모델' },
      styleName: 'tc',
      editable: false,
    },
    {
      name: '작업구분',
      fieldName: '작업구분',
      width: '90',
      header: { text: '작업구분' },
      styleName: 'tc',
      editable: false,
    },
    {
      name: 'ORG작업구분',
      fieldName: 'org작업구분',
      width: '110',
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
      width: '110',
      header: { text: 'BOH_MONTH\n(당월기초수량)' },
      styleName: 'number',
      editable: false,
      numberFormat: '#,##0',
    },
    {
      name: 'PREV_EOH_MONTH',
      fieldName: 'prevEohMonth',
      width: '110',
      header: { text: 'EOH_MONTH\n(전월기말수량)' },
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
