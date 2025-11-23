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
    // fixed: { colBarWidth: 1, colCount: 1 },
  },
  fields: [
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: 'selCode', dataType: ValueType.TEXT },
    { fieldName: 'siteOrg', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: '코스트센터', dataType: ValueType.TEXT },
    { fieldName: '코스트센터분류', dataType: ValueType.TEXT },
    { fieldName: '코스트센터유형', dataType: ValueType.TEXT },
    { fieldName: '계정코드', dataType: ValueType.TEXT },
    { fieldName: '계정과목', dataType: ValueType.TEXT },
    { fieldName: '비용구분', dataType: ValueType.TEXT },
    { fieldName: '차변금액', dataType: ValueType.NUMBER },
    { fieldName: '대변금액', dataType: ValueType.NUMBER },
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
    { name: '코스트센터', fieldName: '코스트센터', width: '70', header: { text: '코스트센터' }, autoFilter: true, editable: false, styleName: 'tl' },
    { name: '코스트센터분류', fieldName: '코스트센터분류', width: '120', header: { text: '코스트센터분류' }, autoFilter: true, editable: false, styleName: 'tl' },
    { name: '코스트센터유형', fieldName: '코스트센터유형', width: '120', header: { text: '코스트센터유형' }, autoFilter: true, editable: false, styleName: 'tl' },
    { name: '계정코드', fieldName: '계정코드', width: '120', header: { text: '계정코드' }, autoFilter: true, editable: false, styleName: 'tl' },
    { name: '계정과목', fieldName: '계정과목', width: '150', header: { text: '계정과목' }, autoFilter: true, editable: false, styleName: 'tl' },
	{ name: '비용구분', fieldName: '비용구분', width: '120', header: { text: '비용구분' }, autoFilter: true, editable: false, styleName: 'tl' },
    { name: '차변금액', fieldName: '차변금액', width: '100', header: { text: '차변금액' }, autoFilter: true, editable: false, styleName: 'tr', numberFormat: '#,##0' },
    { name: '대변금액', fieldName: '대변금액', width: '100', header: { text: '대변금액' }, autoFilter: true, editable: false, styleName: 'tr', numberFormat: '#,##0' },
  ],
};

module.exports = grid;