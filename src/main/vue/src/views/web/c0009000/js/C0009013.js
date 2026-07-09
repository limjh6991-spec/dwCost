/** * 유상사급 */

const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: true, exclusive: false, syncHeadCheck: true },
    copy: { enabled: true, singleMode: false },
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
    { fieldName: 'siteOrg', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: 'selCode', dataType: ValueType.TEXT },    
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: '창고', dataType: ValueType.TEXT },
    { fieldName: '품번', dataType: ValueType.TEXT },
    { fieldName: '상계금액', dataType: ValueType.NUMBER },
    { fieldName: '수량', dataType: ValueType.NUMBER },
    { fieldName: '최종결산월재고단가', dataType: ValueType.NUMBER },
    { fieldName: 'inMonth', dataType: ValueType.NUMBER },
    { fieldName: 'distRate', dataType: ValueType.NUMBER },
    { fieldName: 'finalAmt', dataType: ValueType.NUMBER },
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
    { name: 'siteOrg', fieldName: 'siteOrg', width: '0', header: { text: 'SITE_ORG' }, autoFilter: true, visible: false, editable: false, styleName: 'tl' },
    {
      name: 'site',
      fieldName: 'site',
      width: '80',
      header: { text: '사이트' },
      autoFilter: true,
      editable: false,
      styleName: 'tl',
      styleCallback: function (grid, dataCell) {
        var ret = {};
        if (dataCell.item.rowState == 'created' || dataCell.item.itemState == 'appending' || dataCell.item.itemState == 'inserting') {
          ret.editable = true;
          ret.styleName = 'edit tc';
        } else {
          ret.editable = false;
          ret.styleName = 'tc';
        }
        return ret;
      },
    },
    { name: 'selCode', fieldName: 'selCode', width: '80', header: { text: 'SEL_CODE' }, autoFilter: true, styleName: 'tc' },
    { name: '구분', fieldName: '구분', width: '120', header: { text: '구분' }, autoFilter: true, visible: false, editable: false, styleName: 'tc' },
    { name: 'model', fieldName: 'model', width: '120', header: { text: 'MODEL' }, autoFilter: true, styleName: 'tc' },
    { name: '창고', fieldName: '창고', width: '120', header: { text: '창고' }, autoFilter: true, styleName: 'tc' },
    { name: '품번', fieldName: '품번', width: '100', header: { text: '품번' }, autoFilter: true, styleName: 'tc' },
    { name: '상계금액', fieldName: '상계금액', width: '100', header: { text: '상계금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0' },
    { name: '수량', fieldName: '수량', width: '100', header: { text: '수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0' },
    { name: '최종결산월재고단가', fieldName: '최종결산월재고단가', width: '120', header: { text: '최종결산월재고단가'}, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.0000' },
    { name: 'inMonth', fieldName: 'inMonth', width: '120', header: { text: '투입수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'distRate', fieldName: 'distRate', width: '120', header: { text: '배부비율' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.0000' },
    { name: 'finalAmt', fieldName: 'finalAmt', width: '120', header: { text: '배부금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0',footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
  ],
};

grid.currencyFields = ['상계금액','finalAmt','최종결산월재고단가'];

module.exports = grid;