/*
 * 타시스템 > 제품정보
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
    footer: { visible: true },
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
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'modelType', dataType: ValueType.TEXT },
    { fieldName: 'stock', dataType: ValueType.TEXT },
    { fieldName: 'boh', dataType: ValueType.NUMBER },
    { fieldName: 'input', dataType: ValueType.NUMBER },
    { fieldName: 'out', dataType: ValueType.NUMBER },
    { fieldName: 'eoh', dataType: ValueType.NUMBER },
    { fieldName: 'inputEtc', dataType: ValueType.NUMBER },
    { fieldName: 'inputMoving', dataType: ValueType.NUMBER },
    { fieldName: 'inputProd', dataType: ValueType.NUMBER },
    { fieldName: 'outSheet', dataType: ValueType.NUMBER },
    { fieldName: 'outReturn', dataType: ValueType.NUMBER },
    { fieldName: 'outInvoice', dataType: ValueType.NUMBER },
    { fieldName: 'outEtc', dataType: ValueType.NUMBER },
    { fieldName: 'outMoving', dataType: ValueType.NUMBER },
  ],

  columns: [
    {
      name: 'YYYYMM',
      fieldName: 'yyyymm',
      width: '80',
      header: { text: 'YYYYMM' },
      autoFilter: true,
      editable: false,
      styleName: 'tc',
      styleCallback: readOnly('tc')      
    },
    {
      name: 'SEL_CODE',
      fieldName: 'selCode',
      width: '80',
      header: { text: 'SEL_CODE' },
      autoFilter: true,
      editable: false,
      styleName: 'tc',
      styleCallback: readOnly('tc')
    },
    { name: 'SITE_ORG', fieldName: 'siteOrg', width: '0', header: { text: '사이트' }, autoFilter: true, visible: false, editable: false, styleName: 'tl' },
    {
      name: 'SITE',
      fieldName: 'site',
      width: '80',
      header: { text: '사이트' },
      autoFilter: true,
      editable: false,
      styleName: 'tc',
      styleCallback: readOnly('tc')
    },
    {
      name: 'MODEL',
      fieldName: 'model',
      width: '90',
      header: { text: 'MODEL' },
      autoFilter: true,
      editable: false,
      styleName: 'tc',
      styleCallback: addNewRow('tc'),
    },
    {
      name: 'MODEL_TYPE',
      fieldName: 'modelType',
      width: '70',
      header: { text: 'MODEL_TYPE' },
      autoFilter: true,
      editable: false,
      styleName: 'tc',
      styleCallback: addNewRow('tc'),
    },
    {
      name: 'STOCK',
      fieldName: 'stock',
      width: '120',
      header: { text: 'STOCK' },
      autoFilter: true,
      editable: false,
      styleName: 'tl',
      styleCallback: addNewRow('tl'),
    },
    { name: 'BOH', fieldName: 'boh', width: '135', header: { text: 'BOH' }, autoFilter: true, editable: true, styleName: 'tr', styleCallback: addNewRow('tr'), numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'INPUT', fieldName: 'input', width: '135', header: { text: 'INPUT' }, autoFilter: true, editable: true, styleName: 'tr', styleCallback: addNewRow('tr'), numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'OUT', fieldName: 'out', width: '70', header: { text: 'OUT' }, autoFilter: true, editable: true, styleName: 'tr', styleCallback: addNewRow('tr'), numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'EOH', fieldName: 'eoh', width: '120', header: { text: 'EOH' }, autoFilter: true, editable: true, styleName: 'tr', styleCallback: addNewRow('tr'), numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'INPUT_ETC', fieldName: 'inputEtc', width: '135', header: { text: 'INPUT_ETC' }, autoFilter: true, editable: true, styleName: 'tr', styleCallback: addNewRow('tr'), numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'INPUT_MOVING', fieldName: 'inputMoving', width: '135', header: { text: 'INPUT_MOVING' }, autoFilter: true, editable: true, styleName: 'tr', styleCallback: addNewRow('tr'), numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'INPUT_PROD', fieldName: 'inputProd', width: '70', header: { text: 'INPUT_PROD' }, autoFilter: true, editable: true, styleName: 'tr', styleCallback: addNewRow('tr'), numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'OUT_SHEET', fieldName: 'outSheet', width: '120', header: { text: 'OUT_SHEET' }, autoFilter: true, editable: true, styleName: 'tr',  styleCallback: addNewRow('tr'), numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'OUT_RETURN', fieldName: 'outReturn', width: '120', header: { text: 'OUT_RETURN' }, autoFilter: true, editable: true, styleName: 'tr',  styleCallback: addNewRow('tr'), numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'OUT_INVOICE', fieldName: 'outInvoice', width: '120', header: { text: 'OUT_INVOICE' }, autoFilter: true, editable: true, styleName: 'tr',  styleCallback: addNewRow('tr'), numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'OUT_ETC', fieldName: 'outEtc', width: '120', header: { text: 'OUT_ETC' }, autoFilter: true, editable: true, styleName: 'tr', styleCallback: addNewRow('tr'), numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
    { name: 'OUT_MOVING', fieldName: 'outMoving', width: '120', header: { text: 'OUT_MOVING' }, autoFilter: true, editable: true, styleName: 'tr', styleCallback: addNewRow('tr'), numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
  ],
};

module.exports = grid;
