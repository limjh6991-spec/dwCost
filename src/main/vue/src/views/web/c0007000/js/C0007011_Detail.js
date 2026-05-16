/**
 * 수불 산출 검증 - 드릴다운 상세 그리드 (IN/OUT)
 */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: false },
    copy: { enabled: true, singleMode: false },
    display: {
      columnMovable: false, fitStyle: 'none', minWidth: 60,
      emptyMessage: '모델을 선택하세요.', hscrollBar: true, showEmptyMessage: true,
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
    { fieldName: 'lotNo', dataType: ValueType.TEXT },
    { fieldName: 'packQrno', dataType: ValueType.TEXT },
    { fieldName: 'runId', dataType: ValueType.TEXT },
    { fieldName: '공정코드', dataType: ValueType.TEXT },
    { fieldName: '순서', dataType: ValueType.TEXT },
    { fieldName: '작업구분', dataType: ValueType.TEXT },
    { fieldName: '작업시작', dataType: ValueType.TEXT },
    { fieldName: '발행일자', dataType: ValueType.TEXT },
    { fieldName: '대기작업시각', dataType: ValueType.TEXT },
    { fieldName: '상태코드', dataType: ValueType.TEXT },
    { fieldName: 'pack상태', dataType: ValueType.TEXT },
    { fieldName: 'cell수량', dataType: ValueType.NUMBER },
    { fieldName: 'tray수량', dataType: ValueType.NUMBER },
    { fieldName: '양품수량', dataType: ValueType.NUMBER },
  ],
  columns: [
    { name: 'lotNo', fieldName: 'lotNo', width: '150', header: { text: 'LOT_NO' }, styleName: 'tl', editable: false },
    { name: 'packQrno', fieldName: 'packQrno', width: '150', header: { text: 'PACK_QRNO' }, styleName: 'tl', editable: false },
    { name: 'runId', fieldName: 'runId', width: '120', header: { text: 'RUN_ID' }, styleName: 'tc', editable: false },
    { name: '공정코드', fieldName: '공정코드', width: '50', header: { text: '공정' }, styleName: 'tc', editable: false },
    { name: '순서', fieldName: '순서', width: '40', header: { text: '순서' }, styleName: 'tc', editable: false },
    { name: '작업구분', fieldName: '작업구분', width: '50', header: { text: '작업' }, styleName: 'tc', editable: false },
    { name: '작업시작', fieldName: '작업시작', width: '70', header: { text: '작업일' }, styleName: 'tc', editable: false },
    { name: '발행일자', fieldName: '발행일자', width: '70', header: { text: '발행일' }, styleName: 'tc', editable: false },
    { name: '대기작업시각', fieldName: '대기작업시각', width: '110', header: { text: '대기시각' }, styleName: 'tc', editable: false },
    { name: '상태코드', fieldName: '상태코드', width: '50', header: { text: '상태' }, styleName: 'tc', editable: false },
    { name: 'pack상태', fieldName: 'pack상태', width: '80', header: { text: 'PACK상태' }, styleName: 'tc', editable: false },
    { name: 'cell수량', fieldName: 'cell수량', width: '70', header: { text: 'Cell수량' }, styleName: 'number', editable: false, numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'number' } },
    { name: 'tray수량', fieldName: 'tray수량', width: '60', header: { text: 'Tray수량' }, styleName: 'number', editable: false, numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'number' } },
    { name: '양품수량', fieldName: '양품수량', width: '60', header: { text: '양품' }, styleName: 'number', editable: false, numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'number' } },
  ],
};

module.exports = grid;
