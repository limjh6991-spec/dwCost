/**
 * 수불 산출 검증 - 도우모델별 비교 그리드
 * 뷰(V_DOI_PROD_SUBUL) 값 vs 기초테이블 역산값
 */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: false },
    copy: { enabled: true, singleMode: false },
    display: {
      columnMovable: false, fitStyle: 'none', minWidth: 60,
      emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true,
    },
    edit: { editable: false },
    footer: { visible: true },
    header: { height: 30 },
    hideDeletedRows: true,
    paste: { enabled: false },
    rowIndicator: { visible: true },
    sorting: { enabled: true },
    stateBar: { visible: false },
  },
  fields: [
    { fieldName: 'status', dataType: ValueType.TEXT },
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: '도우모델', dataType: ValueType.TEXT },
    // 뷰 값
    { fieldName: 'vBoh', dataType: ValueType.NUMBER },
    { fieldName: 'vIn', dataType: ValueType.NUMBER },
    { fieldName: 'vNg', dataType: ValueType.NUMBER },
    { fieldName: 'vOut', dataType: ValueType.NUMBER },
    { fieldName: 'vEoh', dataType: ValueType.NUMBER },
    { fieldName: 'vLoss', dataType: ValueType.NUMBER },
    // 역산 값
    { fieldName: 'rIn', dataType: ValueType.NUMBER },
    { fieldName: 'rNg', dataType: ValueType.NUMBER },
    { fieldName: 'rOut', dataType: ValueType.NUMBER },
    { fieldName: 'rEoh', dataType: ValueType.NUMBER },
    // 차이
    { fieldName: 'diffIn', dataType: ValueType.NUMBER },
    { fieldName: 'diffOut', dataType: ValueType.NUMBER },
    { fieldName: 'diffEoh', dataType: ValueType.NUMBER },
  ],
  columns: [
    { name: 'status', fieldName: 'status', width: '55', header: { text: '상태' }, styleName: 'tc', editable: false },
    { name: '구분', fieldName: '구분', width: '50', header: { text: '구분' }, styleName: 'tc', editable: false },
    { name: '도우모델', fieldName: '도우모델', width: '70', header: { text: '모델' }, styleName: 'tc', editable: false },
    // 수불 뷰 값
    { name: 'vBoh', fieldName: 'vBoh', width: '70', header: { text: 'BOH(뷰)' }, styleName: 'number', editable: false, numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'number' } },
    { name: 'vIn', fieldName: 'vIn', width: '70', header: { text: 'IN(뷰)' }, styleName: 'number', editable: false, numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'number' } },
    { name: 'vNg', fieldName: 'vNg', width: '60', header: { text: 'NG(뷰)' }, styleName: 'number', editable: false, numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'number' } },
    { name: 'vOut', fieldName: 'vOut', width: '70', header: { text: 'OUT(뷰)' }, styleName: 'number', editable: false, numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'number' } },
    { name: 'vLoss', fieldName: 'vLoss', width: '60', header: { text: 'LOSS(뷰)' }, styleName: 'number', editable: false, numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'number' } },
    { name: 'vEoh', fieldName: 'vEoh', width: '70', header: { text: 'EOH(뷰)' }, styleName: 'number', editable: false, numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'number' } },
    // 역산 값
    { name: 'rIn', fieldName: 'rIn', width: '70', header: { text: 'IN(역산)' }, styleName: 'number', editable: false, numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'number' } },
    { name: 'rNg', fieldName: 'rNg', width: '60', header: { text: 'NG(역산)' }, styleName: 'number', editable: false, numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'number' } },
    { name: 'rOut', fieldName: 'rOut', width: '70', header: { text: 'OUT(역산)' }, styleName: 'number', editable: false, numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'number' } },
    { name: 'rEoh', fieldName: 'rEoh', width: '70', header: { text: 'EOH(검산)' }, styleName: 'number', editable: false, numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'number' } },
    // 차이
    { name: 'diffIn', fieldName: 'diffIn', width: '55', header: { text: '△IN' }, styleName: 'number', editable: false, numberFormat: '#,##0' },
    { name: 'diffOut', fieldName: 'diffOut', width: '55', header: { text: '△OUT' }, styleName: 'number', editable: false, numberFormat: '#,##0' },
    { name: 'diffEoh', fieldName: 'diffEoh', width: '55', header: { text: '△EOH' }, styleName: 'number', editable: false, numberFormat: '#,##0' },
  ],
};

module.exports = grid;
