/**
 * 기초데이터 변경 검증 - d22 RUN제조VLR 비교 그리드
 * 비교 수량: 불량수량, 양품수량
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
    footer: { visible: false },
    header: { height: 30 },
    hideDeletedRows: true,
    paste: { enabled: false },
    rowIndicator: { visible: true },
    sorting: { enabled: true },
    stateBar: { visible: false },
  },
  fields: [
    { fieldName: 'status', dataType: ValueType.TEXT },
    { fieldName: 'sourceTable', dataType: ValueType.TEXT },
    { fieldName: '공장코드', dataType: ValueType.TEXT },
    { fieldName: 'runNo', dataType: ValueType.TEXT },
    { fieldName: '공정코드', dataType: ValueType.TEXT },
    { fieldName: '차수', dataType: ValueType.NUMBER },
    { fieldName: 'lotNo', dataType: ValueType.TEXT },
    { fieldName: '작업구분', dataType: ValueType.TEXT },
    { fieldName: '작업시작', dataType: ValueType.TEXT },
    { fieldName: 'snap불량', dataType: ValueType.NUMBER },
    { fieldName: 'snap양품', dataType: ValueType.NUMBER },
    { fieldName: 'curr불량', dataType: ValueType.NUMBER },
    { fieldName: 'curr양품', dataType: ValueType.NUMBER },
    { fieldName: 'diff불량', dataType: ValueType.NUMBER },
    { fieldName: 'diff양품', dataType: ValueType.NUMBER },
  ],
  columns: [
    { name: 'status', fieldName: 'status', width: '60', header: { text: '상태' }, styleName: 'tc', editable: false },
    { name: '공장코드', fieldName: '공장코드', width: '50', header: { text: '공장' }, styleName: 'tc', editable: false },
    { name: 'runNo', fieldName: 'runNo', width: '100', header: { text: 'RUN_NO' }, styleName: 'tc', editable: false },
    { name: '공정코드', fieldName: '공정코드', width: '50', header: { text: '공정' }, styleName: 'tc', editable: false },
    { name: '차수', fieldName: '차수', width: '40', header: { text: '차수' }, styleName: 'tc', editable: false },
    { name: 'lotNo', fieldName: 'lotNo', width: '120', header: { text: 'LOT_NO' }, styleName: 'tl', editable: false },
    { name: '작업구분', fieldName: '작업구분', width: '50', header: { text: '작업' }, styleName: 'tc', editable: false },
    { name: '작업시작', fieldName: '작업시작', width: '70', header: { text: '작업일' }, styleName: 'tc', editable: false },
    // 스냅샷
    { name: 'snap불량', fieldName: 'snap불량', width: '70', header: { text: '불량(S)' }, styleName: 'number', editable: false, numberFormat: '#,##0' },
    { name: 'snap양품', fieldName: 'snap양품', width: '70', header: { text: '양품(S)' }, styleName: 'number', editable: false, numberFormat: '#,##0' },
    // 현시점
    { name: 'curr불량', fieldName: 'curr불량', width: '70', header: { text: '불량(C)' }, styleName: 'number', editable: false, numberFormat: '#,##0' },
    { name: 'curr양품', fieldName: 'curr양품', width: '70', header: { text: '양품(C)' }, styleName: 'number', editable: false, numberFormat: '#,##0' },
    // 차이
    { name: 'diff불량', fieldName: 'diff불량', width: '60', header: { text: '△불량' }, styleName: 'number', editable: false, numberFormat: '#,##0' },
    { name: 'diff양품', fieldName: 'diff양품', width: '60', header: { text: '△양품' }, styleName: 'number', editable: false, numberFormat: '#,##0' },
  ],
};

module.exports = grid;
