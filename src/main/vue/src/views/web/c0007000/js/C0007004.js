/*
 * 타시스템 > 제품정보
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
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'modelType', dataType: ValueType.TEXT },
    { fieldName: 'stock', dataType: ValueType.TEXT },
    { fieldName: 'boh', dataType: ValueType.TEXT },
    { fieldName: 'input', dataType: ValueType.TEXT },
    { fieldName: 'out', dataType: ValueType.TEXT },
    { fieldName: 'eoh', dataType: ValueType.TEXT },
    { fieldName: 'inputEtc', dataType: ValueType.TEXT },
    { fieldName: 'inputMoving', dataType: ValueType.TEXT },
    { fieldName: 'inputProd', dataType: ValueType.TEXT },
    { fieldName: 'outSheet', dataType: ValueType.TEXT },
    { fieldName: 'outReturn', dataType: ValueType.TEXT },
    { fieldName: 'outInvoice', dataType: ValueType.TEXT },
    { fieldName: 'outEtc', dataType: ValueType.TEXT },
    { fieldName: 'outMoving', dataType: ValueType.TEXT },
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
    { name: 'MODEL_TYPE', fieldName: 'modelType', width: '70', header: { text: 'MODEL_TYPE' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'STOCK', fieldName: 'stock', width: '120', header: { text: 'STOCK' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'BOH', fieldName: 'boh', width: '135', header: { text: 'BOH' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'INPUT', fieldName: 'input', width: '135', header: { text: 'INPUT' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'OUT', fieldName: 'out', width: '70', header: { text: 'OUT' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'EOH', fieldName: 'eoh', width: '120', header: { text: 'EOH' }, autoFilter: true, editable: true, styleName: 'edit tl' },
  { name: 'INPUT_ETC', fieldName: 'inputEtc', width: '135', header: { text: 'INPUT_ETC' }, autoFilter: true, editable: true, styleName: 'edit tl' },
  { name: 'INPUT_MOVING', fieldName: 'inputMoving', width: '135', header: { text: 'INPUT_MOVING' }, autoFilter: true, editable: true, styleName: 'edit tl' },
  { name: 'INPUT_PROD', fieldName: 'inputProd', width: '70', header: { text: 'INPUT_PROD' }, autoFilter: true, editable: true, styleName: 'edit tl' },
  { name: 'OUT_SHEET', fieldName: 'outSheet', width: '120', header: { text: 'OUT_SHEET' }, autoFilter: true, editable: true, styleName: 'edit tl' },
  { name: 'OUT_RETURN', fieldName: 'outReturn', width: '120', header: { text: 'OUT_RETURN' }, autoFilter: true, editable: true, styleName: 'edit tl' },
  { name: 'OUT_INVOICE', fieldName: 'outInvoice', width: '120', header: { text: 'OUT_INVOICE' }, autoFilter: true, editable: true, styleName: 'edit tl' },
  { name: 'OUT_ETC', fieldName: 'outEtc', width: '120', header: { text: 'OUT_ETC' }, autoFilter: true, editable: true, styleName: 'edit tl' },
  { name: 'OUT_MOVING', fieldName: 'outMoving', width: '120', header: { text: 'OUT_MOVING' }, autoFilter: true, editable: true, styleName: 'edit tl' }
  ],
};

module.exports = grid;