/** * 생산실적 > 년간 전체 실적 집계 */
const { ValueType } = require('realgrid');

var headerSummaryCallback = [
  {
    valueCallback: function (grid, column, childIndex, summary, value) {
      var sum = 0;
      let dataProvider = grid.getDataSource();
      for (var i = 0; i < dataProvider.getRowCount(); i++) {
        if (dataProvider.getValue(i, 'gubun') == '기초(BOH)') {
          sum += dataProvider.getValue(i, summary.column.fieldName);
        }
      }
      return sum;
    },
    numberFormat: '#,##0.##',
  },
  {
    valueCallback: function (grid, column, childIndex, summary, value) {
      var sum = 0;
      let dataProvider = grid.getDataSource();
      for (var i = 0; i < dataProvider.getRowCount(); i++) {
        if (dataProvider.getValue(i, 'gubun') == '투입(IN)') {
          sum += dataProvider.getValue(i, summary.column.fieldName);
        }
      }
      return sum;
    },
    numberFormat: '#,##0.##',
  },
  {
    valueCallback: function (grid, column, childIndex, summary, value) {
      var sum = 0;
      let dataProvider = grid.getDataSource();
      for (var i = 0; i < dataProvider.getRowCount(); i++) {
        if (dataProvider.getValue(i, 'gubun') == '출고(OUT)') {
          sum += dataProvider.getValue(i, summary.column.fieldName);
        }
      }
      return sum;
    },
    numberFormat: '#,##0.##',
  },
  {
    valueCallback: function (grid, column, childIndex, summary, value) {
      var sum = 0;
      let dataProvider = grid.getDataSource();
      for (var i = 0; i < dataProvider.getRowCount(); i++) {
        if (dataProvider.getValue(i, 'gubun') == '재고(EOH)') {
          sum += dataProvider.getValue(i, summary.column.fieldName);
        }
      }
      return sum;
    },
    numberFormat: '#,##0.##',
  },
  {
    valueCallback: function (grid, column, childIndex, summary, value) {
      var sum = 0;
      let dataProvider = grid.getDataSource();
      for (var i = 0; i < dataProvider.getRowCount(); i++) {
        if (dataProvider.getValue(i, 'gubun') == '기타(LOSS)') {
          sum += dataProvider.getValue(i, summary.column.fieldName);
        }
      }
      return sum;
    },
    numberFormat: '#,##0.##',
  },
  {
    valueCallback: function (grid, column, childIndex, summary, value) {
      var sum1 = 0;
      var sum2 = 0;
      var sum3 = 0;
      let dataProvider = grid.getDataSource();
      for (var i = 0; i < dataProvider.getRowCount(); i++) {
        if (dataProvider.getValue(i, 'gubun') == '기초(BOH)') {
          sum1 += dataProvider.getValue(i, summary.column.fieldName);
        }
        if (dataProvider.getValue(i, 'gubun') == '투입(IN)') {
          sum2 += dataProvider.getValue(i, summary.column.fieldName);
        }
        if (dataProvider.getValue(i, 'gubun') == '기타(LOSS)') {
          sum3 += dataProvider.getValue(i, summary.column.fieldName);
        }
      }
      return sum3 == 0 ? 0 : ((sum1 + sum2) / sum3).toFixed(2);
    },
    numberFormat: '#,##0.##',
  },
];

const grid = {
  options: {
    checkBar: { visible: false },
    copy: { enabled: true, singleMode: true },
    display: { columnMovable: false, editItemMerging: true, fitStyle: 'even', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
    edit: { editable: false },
    footer: { visible: false },
    paste: { enabled: false },
    rowIndicator: { visible: true },
    sorting: { enabled: true },
    stateBar: { visible: false },
    filtering: { enabled: true },
    headerSummaries: {
      visible: false,
      items: [{ height: 25 }, { height: 25 }, { height: 25 }, { height: 25 }, { height: 25 }, { height: 25 } /*,{ height: 25 }*/],
    },
  },
  fields: [
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: 'dwSite', dataType: ValueType.TEXT },
    { fieldName: '도우모델', dataType: ValueType.TEXT },
    { fieldName: 'inch', dataType: ValueType.TEXT },
    { fieldName: 'gubun', dataType: ValueType.TEXT },
    { fieldName: '1월', dataType: ValueType.NUMBER },
    { fieldName: '2월', dataType: ValueType.NUMBER },
    { fieldName: '3월', dataType: ValueType.NUMBER },
    { fieldName: '4월', dataType: ValueType.NUMBER },
    { fieldName: '5월', dataType: ValueType.NUMBER },
    { fieldName: '6월', dataType: ValueType.NUMBER },
    { fieldName: '7월', dataType: ValueType.NUMBER },
    { fieldName: '8월', dataType: ValueType.NUMBER },
    { fieldName: '9월', dataType: ValueType.NUMBER },
    { fieldName: '10월', dataType: ValueType.NUMBER },
    { fieldName: '11월', dataType: ValueType.NUMBER },
    { fieldName: '12월', dataType: ValueType.NUMBER },
  ],
  columns: [
    { name: 'model', fieldName: 'model', width: '80', header: { text: '모델명' }, mergeRule: { criteria: "value['model']+value['구분']+value['dwSite']+value['도우모델']+value['inch']" }, autoFilter: true, styleName: 'tl', headerSummary: [{ text: '총 생산실적', styleName: 'tc' }] },
    { name: '구분', fieldName: '구분', width: '80', header: { text: '구분' }, mergeRule: { criteria: "value['model']+value['구분']+value['dwSite']+value['도우모델']+value['inch']" }, autoFilter: true, styleName: 'tl' },
    { name: 'dwSite', fieldName: 'dwSite', width: '80', header: { text: 'SITE' }, mergeRule: { criteria: "value['model']+value['구분']+value['dwSite']+value['도우모델']+value['inch']" }, autoFilter: true, styleName: 'tl' },
    { name: '도우모델', fieldName: '도우모델', width: '120', header: { text: '자사코드' }, mergeRule: { criteria: "value['model']+value['구분']+value['dwSite']+value['도우모델']+value['inch']" }, autoFilter: true, styleName: 'tl' },
    { name: 'inch', fieldName: 'inch', width: '80', header: { text: 'Inch' }, mergeRule: { criteria: "value['model']+value['구분']+value['dwSite']+value['도우모델']+value['inch']" }, autoFilter: true, styleName: 'tl' },
    {
      name: 'gubun',
      fieldName: 'gubun',
      width: '80',
      header: { text: '구분' },
      autoFilter: true,
      styleName: 'tl',
      headerSummary: [
        { text: '기초(BOH)', styleName: 'tl' },
        { text: '투입(IN)', styleName: 'tl' },
        { text: '출고(OUT)', styleName: 'tl' },
        { text: '재고(EOH)', styleName: 'tl' },
        { text: '기타(LOSS)', styleName: 'tl' },
        { text: 'LOSS율', styleName: 'tl' } /*, { text: '가동율' }*/,
      ],
    },
    { name: '1월', fieldName: '1월', width: '80', header: { text: '1월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0.##', headerSummary: headerSummaryCallback },
    { name: '2월', fieldName: '2월', width: '80', header: { text: '2월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0.##', headerSummary: headerSummaryCallback },
    { name: '3월', fieldName: '3월', width: '80', header: { text: '3월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0.##', headerSummary: headerSummaryCallback },
    { name: '4월', fieldName: '4월', width: '80', header: { text: '4월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0.##', headerSummary: headerSummaryCallback },
    { name: '5월', fieldName: '5월', width: '80', header: { text: '5월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0.##', headerSummary: headerSummaryCallback },
    { name: '6월', fieldName: '6월', width: '80', header: { text: '6월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0.##', headerSummary: headerSummaryCallback },
    { name: '7월', fieldName: '7월', width: '80', header: { text: '7월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0.##', headerSummary: headerSummaryCallback },
    { name: '8월', fieldName: '8월', width: '80', header: { text: '8월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0.##', headerSummary: headerSummaryCallback },
    { name: '9월', fieldName: '9월', width: '80', header: { text: '9월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0.##', headerSummary: headerSummaryCallback },
    { name: '10월', fieldName: '10월', width: '80', header: { text: '10월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0.##', headerSummary: headerSummaryCallback },
    { name: '11월', fieldName: '11월', width: '80', header: { text: '11월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0.##', headerSummary: headerSummaryCallback },
    { name: '12월', fieldName: '12월', width: '80', header: { text: '12월' }, autoFilter: false, styleName: 'tr', numberFormat: '#,##0.##', headerSummary: headerSummaryCallback },
  ],
  layout: [
    {
      column: 'model',
      summaryUserSpans: [{ rowspan: 6, colspan: 5 }],
    },
    '구분',
    'dwSite',
    '도우모델',
    'inch',
    'gubun',
    {
      name: 'monthGroup',
      direction: 'horizontal',
      items: ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'],
      header: {
        text: ' ',
      },
    },
  ],
};

module.exports = grid;
