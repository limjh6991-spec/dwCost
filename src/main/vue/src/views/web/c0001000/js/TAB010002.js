/*
 * 기준정보 > 부서코드 관리 (TAB010002)
 */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: true, exclusive: false, syncHeadCheck: true },
    copy: { enabled: true, singleMode: false },
    display: { columnMovable: false, editItemMerging: true, fitStyle: 'fill', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
    edit: { editable: true, columnEditableFirst: true, commitByCell: true, commitWhenLeave: true },
    footer: { visible: false },
    header: { height: 40, showTooltip: true, tooltipEllipsisOnly: true },
    hideDeletedRows: true,
    paste: { enabled: true, checkReadOnly: true },
    rowIndicator: { visible: true },
    sorting: { enabled: false },
    stateBar: { visible: true },
  },
  fields: [
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: 'selCode', dataType: ValueType.TEXT },
    { fieldName: 'siteOrg', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: 'dept', dataType: ValueType.TEXT },
    { fieldName: 'deptName', dataType: ValueType.TEXT },
    { fieldName: 'expenArea', dataType: ValueType.TEXT },
    { fieldName: 'costDist', dataType: ValueType.TEXT },
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
      name: 'selCode',
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
    { name: 'siteOrg', fieldName: 'siteOrg', width: '0', header: { text: '사이트' }, autoFilter: true, visible: false, editable: false, styleName: 'tl' },
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
          ret.styleName = 'edit tl';
        } else {
          ret.editable = false;
          ret.styleName = 'tl';
        }

        return ret;
      },
    },
    {
      name: 'dept',
      fieldName: 'dept',
      width: '150',
      header: { text: '코스트센터' },
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
    { name: 'deptName', fieldName: 'deptName', width: '120', header: { text: '코스트센터명' }, autoFilter: true, editable: true, styleName: 'edit tl' },
    { name: 'expenArea', fieldName: 'expenArea', width: '135', header: { text: '비용구분' }, autoFilter: true, editable: true, styleName: 'edit tl' },
  ],
};

module.exports = grid;
