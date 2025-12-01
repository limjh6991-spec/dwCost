/*
 * 생산실적 > 생산실적 월별/기간별(누적) 조회
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
      showEmptyMessage: true 
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
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: '코드', dataType: ValueType.TEXT },
    { fieldName: 'inch', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: '계획', dataType: ValueType.NUMBER },
    { fieldName: '실적', dataType: ValueType.NUMBER },
    { fieldName: '달성률', dataType: ValueType.NUMBER },
    { fieldName: 'boh', dataType: ValueType.NUMBER },
    { fieldName: 'inMonth', dataType: ValueType.NUMBER },
    { fieldName: 'outMonth', dataType: ValueType.NUMBER },
    { fieldName: 'lossMonth', dataType: ValueType.NUMBER },
    { fieldName: 'eoh', dataType: ValueType.NUMBER },
    { fieldName: '불량률', dataType: ValueType.NUMBER },
    { fieldName: '수율', dataType: ValueType.NUMBER },
  ],

  columns: [
    { 
      name: '구분', 
      fieldName: '구분', 
      width: '80', 
      header: { text: '구분' }, 
      autoFilter: true, 
      styleName: 'tl' 
    },
    { 
      name: '코드', 
      fieldName: '코드', 
      width: '80', 
      header: { text: '코드' }, 
      autoFilter: true, 
      styleName: 'tc' 
    },
    { 
      name: 'inch', 
      fieldName: 'inch', 
      width: '80', 
      header: { text: 'Inch' }, 
      autoFilter: true, 
      styleName: 'tc' 
    },
    { 
      name: 'site', 
      fieldName: 'site', 
      width: '100', 
      header: { text: 'SITE' }, 
      autoFilter: true, 
      styleName: 'tc' 
    },
    { 
      name: '계획', 
      fieldName: '계획', 
      width: '90', 
      header: { text: '계획' }, 
      autoFilter: true, 
      styleName: 'tr', 
      numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }
    },
    { 
      name: '실적', 
      fieldName: '실적', 
      width: '90', 
      header: { text: '실적' }, 
      autoFilter: true, 
      styleName: 'tr', 
      numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }
    },
    { 
      name: '달성률', 
      fieldName: '달성률', 
      width: '80', 
      header: { text: '달성률' }, 
      autoFilter: true, 
      styleName: 'tr', 
      numberFormat: '#,##0.00%'
    },
    { 
      name: 'boh', 
      fieldName: 'boh', 
      width: '90', 
      header: { text: '기초(BOH)' }, 
      autoFilter: true, 
      styleName: 'tr', 
      numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }
    },
    { 
      name: 'inMonth', 
      fieldName: 'inMonth', 
      width: '90', 
      header: { text: '입고(IN)' }, 
      autoFilter: true, 
      styleName: 'tr', 
      numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }
    },
    { 
      name: 'outMonth', 
      fieldName: 'outMonth', 
      width: '90', 
      header: { text: '출고(OUT)' }, 
      autoFilter: true, 
      styleName: 'tr', 
      numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }
    },
    { 
      name: 'lossMonth', 
      fieldName: 'lossMonth', 
      width: '90', 
      header: { text: '불량(LOSS)' }, 
      autoFilter: true, 
      styleName: 'tr', 
      numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }
    },
    { 
      name: 'eoh', 
      fieldName: 'eoh', 
      width: '90', 
      header: { text: '재고(EOH)' }, 
      autoFilter: true, 
      styleName: 'tr', 
      numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }
    },
    { 
      name: '불량률', 
      fieldName: '불량률', 
      width: '80', 
      header: { text: '불량률' }, 
      autoFilter: true, 
      styleName: 'tr', 
      numberFormat: '#,##0.00%'
    },
    { 
      name: '수율', 
      fieldName: '수율', 
      width: '80', 
      header: { text: '수율' }, 
      autoFilter: true, 
      styleName: 'tr', 
      numberFormat: '#,##0.00%',
      footer: { text: '합계' }
    },
  ],
};

module.exports = grid;
