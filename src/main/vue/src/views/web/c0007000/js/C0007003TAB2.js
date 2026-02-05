/*
 * 타시스템 > 생산정보 > 연구개발 수불
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
    hideDeletedRows: false,
    paste: { enabled: true, checkReadOnly: true },
    rowIndicator: { visible: true },
    sorting: { enabled: false },
    stateBar: { visible: true },
    fixed: { colBarWidth: 1, colCount: 7 },
  },
  fields: [
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: 'selCode', dataType: ValueType.TEXT },
    { fieldName: 'siteOrg', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: '구분Ord', dataType: ValueType.TEXT },
    { fieldName: '도우코드', dataType: ValueType.TEXT },
    { fieldName: '도우모델', dataType: ValueType.TEXT },
    { fieldName: '작업구분', dataType: ValueType.TEXT },
    { fieldName: 'org작업구분', dataType: ValueType.TEXT },
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'inch', dataType: ValueType.TEXT },
    { fieldName: 'dwSite', dataType: ValueType.TEXT },
    { fieldName: 'bohMonth', dataType: ValueType.NUMBER },
    { fieldName: 'inMonth', dataType: ValueType.NUMBER },
    { fieldName: 'bonusMonth', dataType: ValueType.NUMBER },
    { fieldName: 'eohMonth', dataType: ValueType.NUMBER },
    { fieldName: 'outMonth', dataType: ValueType.NUMBER },
    { fieldName: 'lossMonth', dataType: ValueType.NUMBER },
    { fieldName: 'ngMonth', dataType: ValueType.NUMBER },
    { fieldName: '수율제외Month', dataType: ValueType.NUMBER },
    { fieldName: 'rework진행Month', dataType: ValueType.NUMBER },
    { fieldName: 'shippingPlanMonth', dataType: ValueType.NUMBER },
    { fieldName: 'shippingActualMonth', dataType: ValueType.NUMBER },
    { fieldName: 'materialLoss', dataType: ValueType.NUMBER },
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
      styleCallback: readOnly('tl')
    },
    {
      name: 'selCode',
      fieldName: 'selCode',
      width: '80',
      header: { text: 'SEL_CODE' },
      autoFilter: true,
      editable: false,
      styleName: 'tl',
      styleCallback: readOnly('tl')
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
      styleCallback: readOnly('tl')
    },
    { name: '구분', fieldName: '구분', width: '80', header: { text: '구분' }, autoFilter: true, editable: false, styleName: 'tl', styleCallback: readOnly('tl') },
    { name: '구분Ord', fieldName: '구분Ord', width: '100', header: { text: '구분_ORD' }, autoFilter: true, editable: false, styleName: 'tl', styleCallback: readOnly('tl') },
    {
      name: '도우코드',
      fieldName: '도우코드',
      width: '120',
      header: { text: '도우코드' },
      autoFilter: true,
      editable: false,
      styleName: 'tl',
      visible: false,
      styleCallback: readOnly('tl')
    },
    // {
    //   name: 'modelNType',
    //   fieldName: 'modelNType',
    //   width: '120',
    //   header: { text: 'MODEL_N_TYPE' },
    //   autoFilter: true,
    //   editable: false,
    //   styleName: 'tl',
    //   styleCallback: function (grid, dataCell) {
    //     var ret = {};
    //     if (dataCell.item.rowState == 'created' || dataCell.item.itemState == 'appending' || dataCell.item.itemState == 'inserting') {
    //       ret.editable = true;
    //       ret.styleName = 'edit tl';
    //     } else {
    //       ret.editable = false;
    //       ret.styleName = 'tl';
    //     }
    //     return ret;
    //   },
    // },
    { name: '도우모델', fieldName: '도우모델', width: '120', header: { text: 'MODEL' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: '작업구분', fieldName: '작업구분', width: '120', header: { text: '작업구분' }, autoFilter: true, editable: false, styleName: 'tl', styleCallback: readOnly('tl') },
    { name: 'org작업구분', fieldName: 'org작업구분', width: '150', header: { text: 'ORG작업구분' }, autoFilter: true, editable: false, styleName: 'tl', styleCallback: readOnly('tl'), visible: false },
    { name: 'model', fieldName: 'model', width: '80', header: { text: '제품군' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: 'inch', fieldName: 'inch', width: '80', header: { text: 'Inch' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: 'dwSite', fieldName: 'dwSite', width: '80', header: { text: '판매처' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: 'bohMonth', fieldName: 'bohMonth', width: '90', header: { text: 'BOH_MONTH' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0.##', styleCallback: addNewRow('tr') },
    { name: 'inMonth', fieldName: 'inMonth', width: '80', header: { text: 'IN_MONTH' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', styleCallback: addNewRow('tr') },
    { name: 'bonusMonth', fieldName: 'bonusMonth', width: '110', header: { text: 'BONUS_MONTH' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', styleCallback: addNewRow('tr') },
    { name: 'eohMonth', fieldName: 'eohMonth', width: '90', header: { text: 'EOH_MONTH' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0.##', styleCallback: addNewRow('tr') },
    { name: 'outMonth', fieldName: 'outMonth', width: '90', header: { text: 'OUT_MONTH' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', styleCallback: addNewRow('tr') },
    { name: 'lossMonth', fieldName: 'lossMonth', width: '100', header: { text: 'LOSS_MONTH' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', styleCallback: addNewRow('tr') },
    { name: 'ngMonth', fieldName: 'ngMonth', width: '80', header: { text: 'NG_MONTH' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', styleCallback: addNewRow('tr') },
    { name: '수율제외Month', fieldName: '수율제외Month', width: '180', header: { text: '수율제외_MONTH' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', styleCallback: addNewRow('tr') },
    { name: 'rework진행Month', fieldName: 'rework진행Month', width: '180', header: { text: 'REWORK진행_MONTH' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', styleCallback: addNewRow('tr') },
    { name: 'shippingPlanMonth', fieldName: 'shippingPlanMonth', width: '190', header: { text: 'SHIPPING_PLAN_MONTH' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', styleCallback: addNewRow('tr') },
    { name: 'shippingActualMonth', fieldName: 'shippingActualMonth', width: '210', header: { text: 'SHIPPING_ACTUAL_MONTH' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', styleCallback: addNewRow('tr') },
    { name: 'materialLoss', fieldName: 'materialLoss', width: '130', header: { text: 'MATERIAL_LOSS' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', styleCallback: addNewRow('tr') },
  ],
};

module.exports = grid;
