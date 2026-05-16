/**
 * 기초데이터 변경 검증 - d27 내포장MST 비교 그리드
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
    fixed: { colBarWidth: 1, colCount: 3 },
  },
  fields: [
    { fieldName: 'status', dataType: ValueType.TEXT },
    { fieldName: 'sourceTable', dataType: ValueType.TEXT },
    { fieldName: 'packQrno', dataType: ValueType.TEXT },
    { fieldName: 'runId', dataType: ValueType.TEXT },
    { fieldName: '발행일자', dataType: ValueType.TEXT },
    { fieldName: '발행구분', dataType: ValueType.TEXT },
    { fieldName: '상태코드', dataType: ValueType.TEXT },
    { fieldName: 'pack상태', dataType: ValueType.TEXT },
    { fieldName: 'snapCell', dataType: ValueType.NUMBER },
    { fieldName: 'snapTray', dataType: ValueType.NUMBER },
    { fieldName: 'currCell', dataType: ValueType.NUMBER },
    { fieldName: 'currTray', dataType: ValueType.NUMBER },
    { fieldName: 'diffCell', dataType: ValueType.NUMBER },
    { fieldName: 'diffTray', dataType: ValueType.NUMBER },
    { fieldName: 'snap상태코드', dataType: ValueType.TEXT },
    { fieldName: 'curr상태코드', dataType: ValueType.TEXT },
  ],
  columns: [
    {
      name: 'status', fieldName: 'status', width: '60', header: { text: '상태' }, styleName: 'tc', editable: false,
      styleCallback: function(grid, dataCell) {
        var v = dataCell.value;
        if (v === '변경' || v === '삭제') return { styleName: 'tc', renderer: { type: 'text', styles: { background: '#f8d7da', foreground: '#842029', fontBold: true } } };
        if (v === '추가') return { styleName: 'tc', renderer: { type: 'text', styles: { background: '#cff4fc', foreground: '#055160', fontBold: true } } };
        if (v === '정상') return { styleName: 'tc', renderer: { type: 'text', styles: { background: '#d1e7dd', foreground: '#0f5132' } } };
        return {};
      },
    },
    { name: 'packQrno', fieldName: 'packQrno', width: '160', header: { text: 'PACK_QRNO' }, styleName: 'tl', editable: false },
    { name: 'runId', fieldName: 'runId', width: '120', header: { text: 'RUN_ID' }, styleName: 'tc', editable: false },
    { name: '발행일자', fieldName: '발행일자', width: '70', header: { text: '발행일' }, styleName: 'tc', editable: false },
    { name: '발행구분', fieldName: '발행구분', width: '60', header: { text: '발행구분' }, styleName: 'tc', editable: false },
    { name: 'snap상태코드', fieldName: 'snap상태코드', width: '60', header: { text: '상태(S)' }, styleName: 'tc', editable: false },
    { name: 'curr상태코드', fieldName: 'curr상태코드', width: '60', header: { text: '상태(C)' }, styleName: 'tc', editable: false },
    { name: 'snapCell', fieldName: 'snapCell', width: '70', header: { text: 'Cell(S)' }, styleName: 'number', editable: false, numberFormat: '#,##0' },
    { name: 'snapTray', fieldName: 'snapTray', width: '70', header: { text: 'Tray(S)' }, styleName: 'number', editable: false, numberFormat: '#,##0' },
    { name: 'currCell', fieldName: 'currCell', width: '70', header: { text: 'Cell(C)' }, styleName: 'number', editable: false, numberFormat: '#,##0' },
    { name: 'currTray', fieldName: 'currTray', width: '70', header: { text: 'Tray(C)' }, styleName: 'number', editable: false, numberFormat: '#,##0' },
    { name: 'diffCell', fieldName: 'diffCell', width: '60', header: { text: '△Cell' }, styleName: 'number', editable: false, numberFormat: '#,##0',
      styleCallback: function(g, d) { if (d.value && Math.abs(d.value) > 0.01) return { renderer: { type:'text', styles: { foreground:'#dc3545', fontBold:true }}}; return {}; }
    },
    { name: 'diffTray', fieldName: 'diffTray', width: '60', header: { text: '△Tray' }, styleName: 'number', editable: false, numberFormat: '#,##0',
      styleCallback: function(g, d) { if (d.value && Math.abs(d.value) > 0.01) return { renderer: { type:'text', styles: { foreground:'#dc3545', fontBold:true }}}; return {}; }
    },
  ],
};

module.exports = grid;
