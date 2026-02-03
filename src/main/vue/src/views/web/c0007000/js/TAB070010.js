/*
 * 타시스템 > 재공/재고기초금액 이월 >  재고기초금액 이월
 */
const { add } = require('lodash');
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
    hideDeletedRows: false,
    paste: { enabled: true, checkReadOnly: true },
    rowIndicator: { visible: true },
    sorting: { enabled: true },
    stateBar: { visible: true },
  },
  fields: [
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: 'selCode', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'expenSel', dataType: ValueType.TEXT },
    { fieldName: 'expenSel명', dataType: ValueType.TEXT },
    { fieldName: 'acctName', dataType: ValueType.TEXT },
    { fieldName: 'bohQty', dataType: ValueType.NUMBER },
    { fieldName: 'bohAmt', dataType: ValueType.NUMBER },
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
      editable: false,
      styleName: 'tc',
      styleCallback: readOnly('tc')
    },
    {
      name: 'site',
      fieldName: 'site',
      width: '80',
      header: { text: 'SITE' },
      autoFilter: true,
      editable: false,
      styleName: 'tc',
      styleCallback: readOnly('tc')
    },
    {
      name: '구분',
      fieldName: '구분',
      width: '80',
      header: { text: '구분' },
      autoFilter: true,
      editable: false,
      styleName: 'tc',
      styleCallback: addNewRow('tc')
    },
    {
      name: 'model',
      fieldName: 'model',
      width: '80',
      header: { text: 'MODEL' },
      autoFilter: true,
      editable: false,
      styleName: 'tl',
      styleCallback: addNewRow('tl')
    },
    {
      name: 'expenSel',
      fieldName: 'expenSel',
      width: '90',
      header: { text: 'expen_sel' },
      autoFilter: true,
      editable: false,
      styleName: 'tl',
      styleCallback: addNewRow('tl')
    },
    { name: 'expenSel명', fieldName: 'expenSel명', width: '120', header: { text: 'expen_sel명' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    {
      name: 'acctName',
      fieldName: 'acctName',
      width: '90',
      header: { text: 'ACCT_NAME' },
      autoFilter: true,
      editable: false,
      styleName: 'tl',
      styleCallback: addNewRow('tl')
    },
    { name: 'bohQty', fieldName: 'bohQty', width: '80', header: { text: 'BOH_QTY' }, autoFilter: true, editable: true, styleName: 'tr', styleCallback: addNewRow('tr'), numberFormat: '#,##0' },
    { name: 'bohAmt', fieldName: 'bohAmt', width: '80', header: { text: 'BOH_AMT' }, autoFilter: true, editable: true, styleName: 'tr', styleCallback: addNewRow('tr'), numberFormat: '#,##0.##' },
  ],
};

module.exports = grid;
