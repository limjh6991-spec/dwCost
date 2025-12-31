/*
 * 기준정보 > 면적기준정보 (TAB010004)
 */
const { ValueType } = require('realgrid');

function isNewRow(dataCell) {
  return dataCell.item &&
    (dataCell.item.rowState === 'created' ||
     dataCell.item.itemState === 'appending' ||
     dataCell.item.itemState === 'inserting');
}

// 고정 컬럼
function readOnly(styleName = 'tl') {
  return function () {
    return { editable: false, styleName };
  };
}

// 추가 행 편집 스타일
function addNewRow(styleName = 'edit tl') {
  return function (grid, dataCell) {
    const canEdit = isNewRow(dataCell);
    return {
      editable: canEdit,
      styleName: canEdit ? `edit ${styleName}` : styleName,
    };
  };
}

const grid = {
  options: {
    checkBar: { 
      visible: true, exclusive: false, syncHeadCheck: true, checkableExpression: "values['addYn'] == 'Y'"
    },
    copy: { enabled: true, singleMode: false },
    display: { columnMovable: false, editItemMerging: true, fitStyle: 'fill', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
    edit: { editable: true, columnEditableFirst: true, commitByCell: true, commitWhenLeave: true },
    footer: { visible: false },
    header: { height: 25 },
    hideDeletedRows: true,
    paste: { enabled: true, checkReadOnly: true },
    rowIndicator: { visible: true },
    sorting: { enabled: false },
    stateBar: { visible: true },
    fixed: { colBarWidth: 1, colCount: 1 },
  },
  fields: [
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
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
    { fieldName: 'addYn', dataType: ValueType.TEXT },
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
      styleCallback: readOnly('tl')
    },
    {
      name: 'SEL_CODE',
      fieldName: 'selCode',
      width: '80',
      header: { text: 'SEL_CODE' },
      autoFilter: true,
      editable: false,
      styleName: 'tl',
      styleCallback: readOnly('tl')
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
      styleCallback: readOnly('tl')
    },
    {
      name: 'MODEL',
      fieldName: 'model',
      width: '90',
      header: { text: 'MODEL' },
      autoFilter: true,
      styleName: 'tl',
      styleCallback: addNewRow('tl'),
    },
    { name: 'SPEC', fieldName: 'spec', width: '70', header: { text: '규격' }, autoFilter: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: 'INCH', fieldName: 'inch', width: '120', header: { text: '인치' }, autoFilter: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: 'GLASS_THICK', fieldName: 'glassThick', width: '135', header: { text: '두께' }, autoFilter: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: 'SHEET', fieldName: 'sheet', width: '135', header: { text: 'SHEET' }, autoFilter: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: 'BLOCK', fieldName: 'block', width: '70', header: { text: 'BLOCK' }, autoFilter: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: 'CELL', fieldName: 'cell', width: '120', header: { text: 'CELL' }, autoFilter: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: 'RUN_SIZE', fieldName: 'runSize', width: '135', header: { text: 'RUN_SIZE' }, autoFilter: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: 'X', fieldName: 'x', width: '135', header: { text: '가로' }, autoFilter: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: 'Y', fieldName: 'y', width: '135', header: { text: '세로' }, autoFilter: true , styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: 'XY', fieldName: 'xy', width: '135', header: { text: '면적' }, autoFilter: true, styleName: 'tl', styleCallback: readOnly('tl') },
    { name: 'ADD_YN', fieldName: 'addYn', width: '80', header: { text: 'ADD_YN' }, visible: false, autoFilter: true, styleName: 'tl', styleCallback: readOnly('tl') },
  ],
};

module.exports = grid;
