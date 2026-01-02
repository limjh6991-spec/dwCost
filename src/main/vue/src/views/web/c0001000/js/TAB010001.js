/*
 * 기준정보 > 계정과목 관리 (TAB010001)
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
    { fieldName: 'acctClassOrg', dataType: ValueType.TEXT },
    { fieldName: 'acctClass', dataType: ValueType.TEXT },
    { fieldName: '계정과목내부코드', dataType: ValueType.NUMBER },
    { fieldName: '전표기표여부', dataType: ValueType.NUMBER },
    { fieldName: 'acct', dataType: ValueType.TEXT },
    { fieldName: 'acctName', dataType: ValueType.TEXT },
    { fieldName: '차대', dataType: ValueType.TEXT },
    { fieldName: '계정대분류', dataType: ValueType.TEXT },
    { fieldName: '관리항목유형', dataType: ValueType.TEXT },
    { fieldName: '계정과목lev', dataType: ValueType.NUMBER },
    { fieldName: '상위계정과목', dataType: ValueType.TEXT },
    { fieldName: '경영계획과목', dataType: ValueType.TEXT },
    { fieldName: '상위계정과목내부코드', dataType: ValueType.NUMBER },
    { fieldName: '소분류', dataType: ValueType.TEXT },
    { fieldName: '중분류', dataType: ValueType.TEXT },
    { fieldName: '대분류', dataType: ValueType.TEXT },
    { fieldName: 'expenSel', dataType: ValueType.TEXT },
    { fieldName: 'expenSel명', dataType: ValueType.TEXT },
    { fieldName: '특이사항', dataType: ValueType.TEXT },
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
    { name: 'siteOrg', fieldName: 'siteOrg', width: '0', header: { text: 'SITE_ORG' }, autoFilter: true, visible: false, editable: false, styleName: 'tl' },
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
    { name: 'acctClassOrg', fieldName: 'acctClassOrg', width: '0', header: { text: 'ACCT_CLASS_ORG' }, autoFilter: true, visible: false, editable: false, styleName: 'tl' },
    { name: 'acctClass', fieldName: 'acctClass', width: '100', header: { text: '원가항목' }, autoFilter: true, styleName: 'edit tl' },
    { name: '계정과목내부코드', fieldName: '계정과목내부코드', width: '100', header: { text: '계정과목\n내부코드', styleName: 'multiline-header' }, autoFilter: true, styleName: 'edit tr', numberFormat: '###0' },
    { name: '전표기표여부', fieldName: '전표기표여부', width: '90', header: { text: '전표\n기표여부', styleName: 'multiline-header' }, autoFilter: true, styleName: 'edit tr', numberFormat: '###0' },
    {
      name: 'acct',
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
    { name: 'acctName', fieldName: 'acctName', width: '200', header: { text: '계정명' }, autoFilter: true, styleName: 'edit tl' },
    { name: '차대', fieldName: '차대', width: '60', header: { text: '차대' }, autoFilter: true, styleName: 'edit tl' },
    { name: '계정대분류', fieldName: '계정대분류', width: '70', header: { text: '계정\n대분류', styleName: 'multiline-header' }, autoFilter: true, styleName: 'edit tl' },
    { name: '관리항목유형', fieldName: '관리항목유형', width: '200', header: { text: '관리항목유형' }, autoFilter: true, styleName: 'edit tl' },
    { name: '계정과목lev', fieldName: '계정과목lev', width: '50', header: { text: '계정과목\nLev', styleName: 'multiline-header' }, autoFilter: true, styleName: 'edit tr', numberFormat: '###0' },
    { name: '상위계정과목', fieldName: '상위계정과목', width: '135', header: { text: '상위계정과목' }, autoFilter: true, styleName: 'edit tl' },
    { name: '경영계획과목', fieldName: '경영계획과목', width: '155', header: { text: '경영계획과목' }, autoFilter: true, styleName: 'edit tl' },
    { name: '상위계정과목내부코드', fieldName: '상위계정과목내부코드', width: '80', header: { text: '상위계정과목\n내부코드', styleName: 'multiline-header' }, autoFilter: true, styleName: 'edit tr', numberFormat: '###0' },
    { name: '소분류', fieldName: '소분류', width: '135', header: { text: '소분류' }, autoFilter: true, styleName: 'edit tl' },
    { name: '중분류', fieldName: '중분류', width: '135', header: { text: '중분류' }, autoFilter: true, styleName: 'edit tl' },
    { name: '대분류', fieldName: '대분류', width: '135', header: { text: '비목코드' }, autoFilter: true, styleName: 'edit tl' },
    { name: 'expenSel', fieldName: 'expenSel', width: '135', header: { text: '원가항목코드' }, autoFilter: true, styleName: 'edit tl' },
    { name: 'expenSel명', fieldName: 'expenSel명', width: '135', header: { text: '원가항목명' }, autoFilter: true, styleName: 'edit tl' },
    { name: '특이사항', fieldName: '특이사항', width: '135', header: { text: '특이사항' }, autoFilter: true, styleName: 'edit tl' },
  ],
};

module.exports = grid;
