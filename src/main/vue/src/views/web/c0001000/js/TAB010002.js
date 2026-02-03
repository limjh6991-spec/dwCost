/*
 * 기준정보 > 부서코드 관리 (TAB010002)
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
    checkBar: { visible: true, exclusive: false, syncHeadCheck: true },
    copy: { enabled: true, singleMode: false },
    display: { columnMovable: false, editItemMerging: true, fitStyle: 'fill', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
    edit: { editable: true, columnEditableFirst: true, commitByCell: true, commitWhenLeave: true },
    footer: { visible: false },
    header: { height: 40, showTooltip: true, tooltipEllipsisOnly: true },
    hideDeletedRows: false,
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
      styleName: 'tc',
      styleCallback: readOnly('tc')
    },
    {
      name: 'selCode',
      fieldName: 'selCode',
      width: '80',
      header: { text: 'SEL_CODE' },
      autoFilter: true,
      editable: true,
      styleName: 'tc',
      styleCallback: readOnly('tc')
    },
    { name: 'siteOrg', fieldName: 'siteOrg', width: '0', header: { text: '사이트' }, autoFilter: true, visible: false, editable: false, styleName: 'tl' },
    {
      name: 'site',
      fieldName: 'site',
      width: '80',
      header: { text: '사이트' },
      autoFilter: true,
      editable: false,
      styleName: 'tc',
      styleCallback: readOnly('tc')
    },
    {
      name: 'dept',
      fieldName: 'dept',
      width: '100',
      header: { text: '코스트센터' },
      autoFilter: true,
      editable: false,
      styleName: 'tc',
      styleCallback: addNewRow('tc'),
    },
    { name: 'deptName', fieldName: 'deptName', width: '120', header: { text: '코스트센터명' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: 'expenArea', fieldName: 'expenArea', width: '135', header: { text: '비용구분' }, autoFilter: true, editable: true, styleName: 'tc', styleCallback: addNewRow('tc') },
  ],
};

module.exports = grid;
