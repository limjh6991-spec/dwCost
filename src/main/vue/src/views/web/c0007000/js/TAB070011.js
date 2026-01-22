/*
 * 유상사급 > 자재기타출고
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
    hideDeletedRows: true,
    paste: { enabled: true, checkReadOnly: true },
    rowIndicator: { visible: true },
    sorting: { enabled: false },
    stateBar: { visible: true },
  },
  fields: [
    { fieldName: 'seqNo', dataType: ValueType.NUMBER },
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: 'selCode', dataType: ValueType.TEXT },
    { fieldName: 'siteOrg', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: '창고', dataType: ValueType.TEXT },
    { fieldName: '품명', dataType: ValueType.TEXT },
    { fieldName: '품번', dataType: ValueType.TEXT },
    { fieldName: '규격', dataType: ValueType.TEXT },
    { fieldName: '단위', dataType: ValueType.TEXT },
    { fieldName: '수량', dataType: ValueType.NUMBER },
    { fieldName: '기타출고구분', dataType: ValueType.TEXT },
    { fieldName: '기준단위', dataType: ValueType.TEXT },
    { fieldName: '기준단위수량', dataType: ValueType.NUMBER },
    { fieldName: 'LotNo', dataType: ValueType.TEXT },
    { fieldName: '코스트센터', dataType: ValueType.TEXT },
    { fieldName: '현재고', dataType: ValueType.NUMBER },
    { fieldName: '특이사항', dataType: ValueType.TEXT }, 
  ],

  columns: [
    { name: 'seqNo', fieldName: 'seqNo', width: '0', header: { text: 'SEQ_NO' }, autoFilter: true, visible: false, editable: false, styleName: 'tl' },    
    {
      name: 'YYYYMM',
      fieldName: 'yyyymm',
      width: '80',
      header: { text: 'YYYYMM' },
      autoFilter: true,
      editable: false,
      styleName: 'tl',
      styleCallback: readOnly('tl'),
    },

    {
      name: 'SEL_CODE',
      fieldName: 'selCode',
      width: '80',
      header: { text: 'SEL_CODE' },
      autoFilter: true,
      editable: false,
      styleName: 'tl',
      styleCallback: readOnly('tl'),
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
      styleCallback: readOnly('tl'),
    },
    {
      name: '창고',
      fieldName: '창고',
      width: '70',
      header: { text: '창고' },
      autoFilter: true,
      editable: false,
      styleName: 'tl',
      styleCallback: addNewRow('tl')
    },
    { name: '품명', fieldName: '품명', width: '150', header: { text: '품명' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },    
    {
      name: '품번',
      fieldName: '품번',
      width: '70',
      header: { text: '품번' },
      autoFilter: true,
      editable: false,
      styleName: 'tl',
      styleCallback: addNewRow('tl')
    },    
    { name: '규격', fieldName: '규격', width: '150', header: { text: '규격' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: '단위', fieldName: '단위', width: '120', header: { text: '단위' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: '수량', fieldName: '수량', width: '100', header: { text: '수량' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '기타출고구분', fieldName: '기타출고구분', width: '120', header: { text: '기타출고구분' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: '기준단위', fieldName: '기준단위', width: '120', header: { text: '기준단위' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },     
    { name: '기준단위수량', fieldName: '기준단위수량', width: '100', header: { text: '기준단위수량' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: 'lotNo', fieldName: 'lotNo', width: '150', header: { text: 'LotNo' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: '코스트센터', fieldName: '코스트센터', width: '120', header: { text: '코스트센터' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') }, 
    { name: '현재고', fieldName: '현재고', width: '100', header: { text: '현재고' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '특이사항', fieldName: '특이사항', width: '120', header: { text: '특이사항' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },                   
  ],
};

module.exports = grid;
