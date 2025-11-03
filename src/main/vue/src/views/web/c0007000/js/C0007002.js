/*
 * 타시스템 > 자재투입정보
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
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: 'selCode', dataType: ValueType.TEXT },
    { fieldName: 'siteOrg', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: 'matCode', dataType: ValueType.TEXT },
    { fieldName: 'matDesc', dataType: ValueType.TEXT },
    { fieldName: 'size', dataType: ValueType.TEXT },
    { fieldName: 'inQty', dataType: ValueType.TEXT },
    { fieldName: 'unitCost', dataType: ValueType.TEXT },
    { fieldName: 'inAmt', dataType: ValueType.TEXT },
    { fieldName: 'costGubun', dataType: ValueType.TEXT },
	{ fieldName: 'matClass', dataType: ValueType.TEXT },
	{ fieldName: 'model', dataType: ValueType.TEXT },
	{ fieldName: 'modelNType', dataType: ValueType.TEXT },
  ],

  columns: [
    {
      name: 'YYYYMM',
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
      name: 'MAT_CODE',
      fieldName: 'matCode',
      width: '90',
      header: { text: '자재코드' },
      autoFilter: true,
      editable: true,
      styleName: 'edit tl',
      styleCallback: function (grid, dataCell) {
        return { editable: true, styleName: 'edit tl' };
      },
    },
    { name: 'MAT_DESC', fieldName: 'matDesc', width: '70', header: { text: '자재명' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: '[SIZE]', fieldName: 'size', width: '120', header: { text: 'SIZE' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'IN_QTY', fieldName: 'inQty', width: '135', header: { text: 'IN_QTY' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'UNIT_COST', fieldName: 'unitCost', width: '135', header: { text: 'UNIT_COST' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'IN_AMT', fieldName: 'inAmt', width: '70', header: { text: 'IN_AMT' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'COST_GUBUN', fieldName: 'costGubun', width: '120', header: { text: 'COST_GUBUN' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'MAT_CLASS', fieldName: 'matClass', width: '120', header: { text: 'MAT_CLASS' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'MODEL', fieldName: 'model', width: '120', header: { text: 'MODEL' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'MODEL_N_TYPE', fieldName: 'modelNType', width: '120', header: { text: 'MODEL_N_TYPE' }, autoFilter: true, editable: true, styleName: 'edit tl' },
  ],
};

module.exports = grid;