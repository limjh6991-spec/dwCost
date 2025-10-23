/*
 * 기준정보 > 부서별, 계정별 비용
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
    { fieldName: 'acctClass', dataType: ValueType.TEXT },
    { fieldName: 'dept', dataType: ValueType.TEXT },
    { fieldName: 'acct', dataType: ValueType.TEXT },
    { fieldName: 'subName', dataType: ValueType.TEXT },
    { fieldName: 'itemName', dataType: ValueType.TEXT },
    { fieldName: 'acctAmt', dataType: ValueType.TEXT },
    { fieldName: 'expenSel', dataType: ValueType.TEXT },
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
      name: 'ACCT_CLASS',
      fieldName: 'acctClass',
      width: '90',
      header: { text: '경비구분' },
      autoFilter: true,
      editable: true,
      styleName: 'edit tl',
      styleCallback: function (grid, dataCell) {
        return { editable: true, styleName: 'edit tl' };
      },
    },
    { name: 'DEPT', fieldName: 'dept', width: '70', header: { text: '부서코드' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'ACCT', fieldName: 'acct', width: '120', header: { text: '계정코드' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'SUB_NAME', fieldName: 'subName', width: '135', header: { text: '비목코드' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'ITEM_NAME', fieldName: 'itemName', width: '135', header: { text: '세목코드' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'ACCT_AMT', fieldName: 'acctAmt', width: '70', header: { text: '금액' }, autoFilter: true, editable: true, styleName: 'edit tl' },
	{ name: 'EXPEN_SEL', fieldName: 'expenSel', width: '120', header: { text: 'EXPENSEL' }, autoFilter: true, editable: true, styleName: 'edit tl' },
  ],
};

module.exports = grid;