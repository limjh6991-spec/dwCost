/*
 * 타시스템 > 재공/재고기초금액 이월 >  재고기초금액 이월
 */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: true, exclusive: false, syncHeadCheck: true },
    copy: { enabled: true, singleMode: false },
    display: { columnMovable: false, editItemMerging: true, fitStyle: 'fill', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
    edit: { editable: true, columnEditableFirst: true, commitByCell: true, commitWhenLeave: true },
    footer: { visible: false },
    hideDeletedRows: false,
    paste: { enabled: true, checkReadOnly: true },
    rowIndicator: { visible: true },
    sorting: { enabled: true },
    stateBar: { visible: true },
  },
  fields: [
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: 'selCode', dataType: ValueType.TEXT },
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'expenSel', dataType: ValueType.TEXT },
    { fieldName: 'expenSel명', dataType: ValueType.TEXT },
    { fieldName: 'acctName', dataType: ValueType.TEXT },
    { fieldName: 'bohQty', dataType: ValueType.NUMBER },
    { fieldName: 'bohAmt', dataType: ValueType.NUMBER },
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
          ret.styleName = 'tl';
        }

        return ret;
      },
    },
    {
      name: 'site',
      fieldName: 'site',
      width: '80',
      header: { text: 'SITE' },
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
          ret.styleName = 'tl';
        }

        return ret;
      },
    },
    {
      name: 'selCode',
      fieldName: 'selCode',
      width: '80',
      header: { text: 'SEL_CODE' },
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
          ret.styleName = 'tl';
        }

        return ret;
      },
    },
    {
      name: '구분',
      fieldName: '구분',
      width: '80',
      header: { text: '구분' },
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
          ret.styleName = 'tl';
        }

        return ret;
      },
    },
    {
      name: 'model',
      fieldName: 'model',
      width: '80',
      header: { text: 'MODEL' },
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
          ret.styleName = 'tl';
        }

        return ret;
      },
    },
    {
      name: 'expenSel',
      fieldName: 'expenSel',
      width: '90',
      header: { text: 'expen_sel' },
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
          ret.styleName = 'tl';
        }

        return ret;
      },
    },
    { name: 'expenSel명', fieldName: 'expenSel명', width: '120', header: { text: 'expen_sel명' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    {
      name: 'acctName',
      fieldName: 'acctName',
      width: '90',
      header: { text: 'ACCT_NAME' },
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
          ret.styleName = 'tl';
        }

        return ret;
      },
    },
    { name: 'bohQty', fieldName: 'bohQty', width: '80', header: { text: 'BOH_QTY' }, autoFilter: true, editable: true, styleName: 'edit tr', numberFormat: '#,##0' },
    { name: 'bohAmt', fieldName: 'bohAmt', width: '80', header: { text: 'BOH_AMT' }, autoFilter: true, editable: true, styleName: 'edit tr', numberFormat: '#,##0.##' },
  ],
};

module.exports = grid;
