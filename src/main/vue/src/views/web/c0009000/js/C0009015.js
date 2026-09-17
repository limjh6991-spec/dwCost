/** * 재고자산 평가 */

const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: false },
    copy: { enabled: true, singleMode: true },
    display: { columnMovable: false, editItemMerging: true, fitStyle: 'fill', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
    edit: { editable: true, columnEditableFirst: true, commitByCell: true, commitWhenLeave: true },
    footer: { visible: true },
    header: { height: 40, showTooltip: true, tooltipEllipsisOnly: true },
    hideDeletedRows: true,
    paste: { enabled: true, checkReadOnly: true },
    rowIndicator: { visible: true },
    sorting: { enabled: false },
    stateBar: { visible: true },
  },
  fields: [
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: '재고자산구분', dataType: ValueType.TEXT },
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: '품번', dataType: ValueType.TEXT },
    { fieldName: '재고수량', dataType: ValueType.NUMBER },
    { fieldName: '취득원가', dataType: ValueType.NUMBER },
    { fieldName: '판매단가Krw', dataType: ValueType.NUMBER },
    { fieldName: '판매단가Usd', dataType: ValueType.NUMBER },
    { fieldName: '환율', dataType: ValueType.NUMBER },
    { fieldName: 'nrv', dataType: ValueType.NUMBER },
    { fieldName: '차이', dataType: ValueType.NUMBER },
    { fieldName: '비고', dataType: ValueType.TEXT }
  ],
  columns: [
    {
      name: 'yyyymm',
      fieldName: 'yyyymm',
      width: '80',
      header: { text: 'YYYYMM' },
      autoFilter: true,
      editable: false,
      styleName: 'tl',
      styleCallback: function (grid, dataCell) {
        var ret = {};
        if (dataCell.item.rowState == 'created' || dataCell.item.itemState == 'appending' || dataCell.item.itemState == 'inserting') {
          ret.editable = true;
          ret.styleName = 'edit tl';
        } else {
          ret.editable = false;
          ret.styleName = 'tc';
        }
        return ret;
      },
    },
    { name: '재고자산구분', fieldName: '재고자산구분', width: '100', header: { text: '재고자산구분' }, autoFilter: true, styleName: 'tc' },
    { name: '구분', fieldName: '구분', width: '100', header: { text: '구분' }, autoFilter: true, styleName: 'tc' },
    { name: '품번', fieldName: '품번', width: '100', header: { text: '품번' }, autoFilter: true, styleName: 'tc'   },
    { name: '재고수량', fieldName: '재고수량', width: '100', header: { text: '재고수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: '취득원가', fieldName: '취득원가', width: '100', header: { text: '취득원가' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: '판매단가Krw', fieldName: '판매단가Krw', width: '100', header: { text: '판매단가(KRW)' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0' },
    { name: '판매단가Usd', fieldName: '판매단가Usd', width: '100', header: { text: '판매단가(USD)' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0' },
    { name: '환율', fieldName: '환율', width: '100', header: { text: '환율' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.00' },
    { name: 'nrv', fieldName: 'nrv', width: '100', header: { text: 'NRV' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }},
    { name: '차이', fieldName: '차이', width: '100', header: { text: '차이' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: '비고', fieldName: '비고', width: '100', header: { text: '비고' }, autoFilter: true, styleName: 'tc'   },
  ],
};

grid.currencyFields = ['판매단가Usd'];

module.exports = grid;