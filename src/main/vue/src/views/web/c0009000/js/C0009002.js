/*
 * 제품 수불부
 */

const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: false },
    copy: { enabled: true, singleMode: true },
    display: { 
      columnMovable: false, 
      editItemMerging: true, 
      fitStyle: 'even', 
      emptyMessage: '조회된 데이터가 없습니다.', 
      hscrollBar: true, 
      showEmptyMessage: true,
      headerDepth: 2,
      mergePolicy: 'auto',  // 병합 정책 추가
    },
    edit: { editable: false },
    footer: { visible: true },
    paste: { enabled: false },
    rowIndicator: { visible: true },
    sorting: { enabled: true },
    stateBar: { visible: false },
    filtering: { enabled: true },
  },

  fields: [
    { fieldName: '순서', dataType: ValueType.NUMBER },   // 1 = 금액, 2 = 수량
    { fieldName: '구분', dataType: ValueType.TEXT }, 
    { fieldName: '코드', dataType: ValueType.TEXT }, 
    { fieldName: 'inch', dataType: ValueType.TEXT },
    { fieldName: 'dwSite', dataType: ValueType.TEXT },
    { fieldName: 'boh',      dataType: ValueType.NUMBER },
    { fieldName: 'input',    dataType: ValueType.NUMBER },
    { fieldName: 'inEtc',   dataType: ValueType.NUMBER },
    { fieldName: 'output',   dataType: ValueType.NUMBER },
    { fieldName: 'outEtc',  dataType: ValueType.NUMBER },
    { fieldName: 'eoh',      dataType: ValueType.NUMBER },
  ],

  columnLayout: [
    { column: '순서'  },
    { column: '구분' , mergeRule: "values['코드']  + value" },
    { column: '코드' , mergeRule: "values['구분'] + value"},
    { column: 'Inch', mergeRule: "values['코드'] + values['구분']"},
    { column: 'DW_SITE', mergeRule: "values['코드'] + values['구분']"},

    {
      name: 'grpBOH',
      header: { text: '기초재고금액' },
      direction: 'horizontal',
      items: [{ column: 'BOH' }],
    },
    {
      name: 'grpINPUT',
      header: { text: '입고금액' },
      direction: 'horizontal',
      items: [{ column: 'INPUT' }],
    },
    {
      name: 'grpIN_ETC',
      header: { text: '기타입고금액' },
      direction: 'horizontal',
      items: [{ column: 'IN_ETC' }],
    },
    {
      name: 'grpOUTPUT',
      header: { text: '출고금액' },
      direction: 'horizontal',
      items: [{ column: 'OUTPUT' }],
    },
    {
      name: 'grpOUT_ETC',
      header: { text: '기타출고금액' },
      direction: 'horizontal',
      items: [{ column: 'OUT_ETC' }],
    },
    {
      name: 'grpEOH',
      header: { text: '기말재고금액' },
      direction: 'horizontal',
      items: [{ column: 'EOH' }],
    },
  ],

  columns: [
    {
      name: '순서',
      fieldName: '순서',
      width: 50,
      header: { text: '순서' },
      visible: false,
    },
    {
      name: '구분',
      fieldName: '구분',
      width: 80,
      header: { text: '구분' },
      autoFilter: true,
      styleName: 'tc',
    },
    {
      name: '코드',
      fieldName: '코드',
      width: 80,
      header: { text: 'MODEL' },
      autoFilter: true,
      styleName: 'tc',
    },
    {
      name: 'Inch',
      fieldName: 'inch',
      width: 80,
      header: { text: 'Inch' },
      autoFilter: true,
      styleName: 'tr',
    },
    {
      name: 'DW_SITE',
      fieldName: 'dwSite',
      width: 80,
      header: { text: '거래처' },
      autoFilter: true,
      styleName: 'tc',
    },
    {
      name: 'BOH',
      fieldName: 'boh',
      width: 120,
      header: { text: '기초재고수량' },
      styleName: 'tr',
      numberFormat: '#,##0',
    },
    {
      name: 'INPUT',
      fieldName: 'input',
      width: 120,
      header: { text: '입고수량' },
      styleName: 'tr',
      numberFormat: '#,##0',
    },
    {
      name: 'IN_ETC',
      fieldName: 'inEtc',
      width: 120,
      header: { text: '기타입고수량' },
      styleName: 'tr',
      numberFormat: '#,##0',
    },
    {
      name: 'OUTPUT',
      fieldName: 'output',
      width: 120,
      header: { text: '출고수량' },
      styleName: 'tr',
      numberFormat: '#,##0',
    },
    {
      name: 'OUT_ETC',
      fieldName: 'outEtc',
      width: 120,
      header: { text: '기타출고수량' },
      styleName: 'tr',
      numberFormat: '#,##0',
    },
    {
      name: 'EOH',
      fieldName: 'eoh',
      width: 120,
      header: { text: '기말재고수량' },
      styleName: 'tr',
      numberFormat: '#,##0',
    },
  ],
};

module.exports = grid;
