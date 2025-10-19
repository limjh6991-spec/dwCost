/*
 * 프로세스 플래닝 >  제품 모델 관리 > 모델기본정보
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
    { fieldName: 'acctClassOrg', dataType: ValueType.TEXT },
    { fieldName: 'acctClass', dataType: ValueType.TEXT },
    { fieldName: 'acct', dataType: ValueType.TEXT },
    { fieldName: 'acctName', dataType: ValueType.TEXT },
    { fieldName: 'subName', dataType: ValueType.TEXT },
    { fieldName: 'itemName', dataType: ValueType.TEXT },
    { fieldName: 'expenSel', dataType: ValueType.TEXT },
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
    { name: 'ACCT_CLASS_ORG', fieldName: 'acctClassOrg', width: '0', header: { text: '원가항목' }, autoFilter: true, visible: false, editable: false, styleName: 'tl' },
    { name: 'ACCT_CLASS', fieldName: 'acctClass', width: '150', header: { text: '원가항목' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    {
      name: 'ACCT',
      fieldName: 'acct',
      width: '90',
      header: { text: '계정코드' },
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
    { name: 'ACCT_NAME', fieldName: 'acctName', width: '70', header: { text: '계정명' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'SUB_NAME', fieldName: 'subName', width: '120', header: { text: '비목' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'ITEM_NAME', fieldName: 'itemName', width: '135', header: { text: '세목' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'EXPEN_SEL', fieldName: 'expenSel', width: '135', header: { text: 'EXPEN_SEL' }, autoFilter: true, editable: true, styleName: 'edit tl' },
  ],
};

module.exports = grid;
