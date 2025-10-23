/*
 * 타시스템 > 생산정보
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
    { fieldName: 'gubun', dataType: ValueType.TEXT },
    { fieldName: 'gubunOrd', dataType: ValueType.TEXT },
    { fieldName: 'dwCode', dataType: ValueType.TEXT },
    { fieldName: 'modelNType', dataType: ValueType.TEXT },
    { fieldName: 'dwModel', dataType: ValueType.TEXT },
    { fieldName: 'workGubun', dataType: ValueType.TEXT },
    { fieldName: 'orgWorkGubun', dataType: ValueType.TEXT },
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'outSite', dataType: ValueType.TEXT },
    { fieldName: 'bohMonth', dataType: ValueType.TEXT },
    { fieldName: 'inMonth', dataType: ValueType.TEXT },
    { fieldName: 'bonusMonth', dataType: ValueType.TEXT },
    { fieldName: 'eohMonth', dataType: ValueType.TEXT },
    { fieldName: 'outMonth', dataType: ValueType.TEXT },
    { fieldName: 'lossMonth', dataType: ValueType.TEXT },
    { fieldName: 'ngMonth', dataType: ValueType.TEXT },
    { fieldName: 'exceptMonth', dataType: ValueType.TEXT },
    { fieldName: 'reworkMonth', dataType: ValueType.TEXT },
    { fieldName: 'shippingPlanMonth', dataType: ValueType.TEXT },
    { fieldName: 'shippingActualMonth', dataType: ValueType.TEXT },
    { fieldName: 'materialLoss', dataType: ValueType.TEXT },
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
    { name: '구분', fieldName: 'gubun', width: '80', header: { text: '구분' }, autoFilter: true, editable: false, styleName: 'tl' },
    { name: '구분_ORD', fieldName: 'gubunOrd', width: '80', header: { text: '구분_ORD' }, autoFilter: true, editable: false, styleName: 'tl' },
    { name: '도우코드', fieldName: 'dwCode', width: '80', header: { text: '도우코드' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'MODEL_N_TYPE', fieldName: 'modelNType', width: '80', header: { text: 'MODEL_N_TYPE' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    {
      name: 'DW_MODEL',
      fieldName: 'dwModel',
      width: '80',
      header: { text: 'DW_MODEL' },
      autoFilter: true,
      editable: true,
      styleName: 'edit tl',
      styleCallback: function (grid, dataCell) {
        return { editable: true, styleName: 'edit tl' };
      },
    },
    { name: '작업구분', fieldName: 'workGubun', width: '80', header: { text: '작업구분' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'ORG작업구분', fieldName: 'orgWorkGubun', width: '80', header: { text: 'ORG작업구분' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'MODEL', fieldName: 'model', width: '120', header: { text: 'MODEL' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'OUT_SITE', fieldName: 'outSite', width: '80', header: { text: 'Site' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'BOH_MONTH', fieldName: 'bohMonth', width: '120', header: { text: 'BOH_MONTH' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'IN_MONTH', fieldName: 'inMonth', width: '120', header: { text: 'IN_MONTH' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'BONUS_MONTH', fieldName: 'bonusMonth', width: '120', header: { text: 'BONUS_MONTH' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'EOH_MONTH', fieldName: 'eohMonth', width: '120', header: { text: 'EOH_MONTH' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'OUT_MONTH', fieldName: 'outMonth', width: '120', header: { text: 'OUT_MONTH' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'LOSS_MONTH', fieldName: 'lossMonth', width: '120', header: { text: 'LOSS_MONTH' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'NG_MONTH', fieldName: 'ngMonth', width: '120', header: { text: 'NG_MONTH' }, autoFilter: true, editable: true, styleName: 'edit tl' },
  	{ name: 'EXCEPT_MONTH', fieldName: 'exceptMonth', width: '120', header: { text: 'EXCEPT_MONTH' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'REWORK_MONTH', fieldName: 'reworkMonth', width: '120', header: { text: 'REWORK_MONTH' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'SHIPPING_PLAN_MONTH', fieldName: 'shippingPlanMonth', width: '120', header: { text: 'SHIPPING_PLAN_MONTH' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'SHIPPING_ACTUAL_MONTH', fieldName: 'shippingActualMonth', width: '120', header: { text: 'SHIPPING_ACTUAL_MONTH' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'MATERIAL_LOSS', fieldName: 'materialLoss', width: '120', header: { text: 'MATERIAL_LOSS' }, autoFilter: true, editable: true, styleName: 'edit tl' },
  ],
};

module.exports = grid;