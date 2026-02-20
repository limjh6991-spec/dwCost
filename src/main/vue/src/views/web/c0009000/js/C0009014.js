/** * 기표내역 */

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
    { fieldName: '차변명', dataType: ValueType.TEXT },
    { fieldName: '차변금액', dataType: ValueType.NUMBER },
    { fieldName: '대변명', dataType: ValueType.TEXT },    
    { fieldName: '대변금액', dataType: ValueType.NUMBER },

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
    { name: '차변명', fieldName: '차변명', width: '100', header: { text: '차변명' }, autoFilter: true, styleName: 'tc' },
    { name: '차변금액', fieldName: '차변금액', width: '100', header: { text: '차변금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: '대변명', fieldName: '대변명', width: '100', header: { text: '대변명' }, autoFilter: true, styleName: 'tc' },
    { name: '대변금액', fieldName: '대변금액', width: '100', header: { text: '대변금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
  ],
};

module.exports = grid;