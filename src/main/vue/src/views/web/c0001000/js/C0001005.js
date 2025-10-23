/*
 * 기준정보 > 제품기본정보
 */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: true, exclusive: false, syncHeadCheck: true },
    copy: { enabled: true, singleMode: false },
    //dataDrop: {},
    display: { columnMovable: false, editItemMerging: true, fitStyle: 'fill', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
    edit: { editable: true, columnEditableFirst: true, commitByCell: true, commitWhenLeave: true },
    //editor: {},
    //filtering: {},
    //filterMode: {},
    //filterPanel: {},
    //fixed: {},
    footer: { visible: false },
    //footers: {},
    //format: {},
    header: { height: 25 },
    //headerSummaries: {},
    //headerSummary: {},
    hideDeletedRows: true,
    paste: { enabled: true, checkReadOnly: true },
    rowIndicator: { visible: true },
    sorting: { enabled: false },
    //sortMode: {},
    stateBar: { visible: true },
    //summaryMode: {},
    fixed: { colBarWidth: 1, colCount: 1 },
  },
  fields: [
    { fieldName: 'yyyy', dataType: ValueType.TEXT },
    { fieldName: 'selCode', dataType: ValueType.TEXT },
    { fieldName: 'siteOrg', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'spec', dataType: ValueType.TEXT },
    { fieldName: 'inch', dataType: ValueType.TEXT },
    { fieldName: 'glassThick', dataType: ValueType.TEXT },
    { fieldName: 'sheet', dataType: ValueType.TEXT },
    { fieldName: 'block', dataType: ValueType.TEXT },
    { fieldName: 'cell', dataType: ValueType.TEXT },
	{ fieldName: 'runSize', dataType: ValueType.TEXT },
  { fieldName: 'x', dataType: ValueType.TEXT },
  { fieldName: 'y', dataType: ValueType.TEXT },
	{ fieldName: 'xy', dataType: ValueType.TEXT },
  ],

  columns: [
    {
      name: 'YYYY',
      fieldName: 'yyyy',
      width: '80',
      header: { text: '년도' },
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
      name: 'SEL_CODE',
      fieldName: 'selCode',
      width: '80',
      header: { text: 'SEL_CODE' },
      autoFilter: true,
      editable: true,
      styleName: 'edit tl',
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
    { name: 'SITE_ORG', fieldName: 'siteOrg', width: '0', header: { text: '사이트' }, autoFilter: true, visible: false, editable: false, styleName: 'tl' },
    {
      name: 'SITE',
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
          ret.styleName = 'edit tl';
        } else {
          ret.editable = false;
          ret.styleName = 'tl';
        }

        return ret;
      },
    },
    {
      name: 'MODEL',
      fieldName: 'model',
      width: '90',
      header: { text: 'MODEL' },
      autoFilter: true,
      editable: true,
      styleName: 'edit tl',
      styleCallback: function (grid, dataCell) {
        return { editable: true, styleName: 'edit tl' };
      },
    },
    { name: 'SPEC', fieldName: 'spec', width: '70', header: { text: '규격' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'INCH', fieldName: 'inch', width: '120', header: { text: '인치' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'GLASS_THICK', fieldName: 'glassThick', width: '135', header: { text: '두께' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'SHEET', fieldName: 'sheet', width: '135', header: { text: 'SHEET' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'BLOCK', fieldName: 'block', width: '70', header: { text: 'BLOCK' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'CELL', fieldName: 'cell', width: '120', header: { text: 'CELL' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'RUN_SIZE', fieldName: 'runSize', width: '135', header: { text: 'RUN_SIZE' }, autoFilter: true, editable: true, styleName: 'edit tl' },
  { name: 'X', fieldName: 'x', width: '135', header: { text: '가로' }, autoFilter: true, editable: true, styleName: 'edit tl' },
  { name: 'Y', fieldName: 'y', width: '135', header: { text: '세로' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'XY', fieldName: 'xy', width: '135', header: { text: '면적' }, autoFilter: true, editable: true, styleName: 'edit tl' },
  ],
};

module.exports = grid;