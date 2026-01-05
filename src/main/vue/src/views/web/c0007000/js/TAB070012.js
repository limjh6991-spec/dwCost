/*
 * 기준정보 > 부서별, 계정별 비용
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
    display: { columnMovable: false, editItemMerging: true, fitStyle: 'none', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
    edit: { editable: true, columnEditableFirst: true, commitByCell: true, commitWhenLeave: true },
    footer: { visible: true },
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
    { fieldName: '자산처리계정', dataType: ValueType.TEXT },
    { fieldName: '품목자산분류', dataType: ValueType.TEXT },
    { fieldName: '재고자산종류', dataType: ValueType.TEXT },
    { fieldName: '매출원가계정', dataType: ValueType.TEXT },
    { fieldName: '대분류', dataType: ValueType.TEXT },
    { fieldName: '중분류', dataType: ValueType.TEXT },
    { fieldName: '소분류', dataType: ValueType.TEXT },
    { fieldName: '품목기타분류', dataType: ValueType.TEXT },
    { fieldName: '품명', dataType: ValueType.TEXT },
    { fieldName: '품번', dataType: ValueType.TEXT },
    { fieldName: '규격', dataType: ValueType.TEXT },
    { fieldName: '단위', dataType: ValueType.TEXT },
    { fieldName: '기초수량', dataType: ValueType.NUMBER },
    { fieldName: '기초금액', dataType: ValueType.NUMBER },
    { fieldName: '입고수량', dataType: ValueType.NUMBER },
    { fieldName: '입고금액', dataType: ValueType.NUMBER },
    { fieldName: '출고수량', dataType: ValueType.NUMBER },
    { fieldName: '출고금액', dataType: ValueType.NUMBER },
    { fieldName: '재고수량A', dataType: ValueType.NUMBER },
    { fieldName: '결산재고수량B', dataType: ValueType.NUMBER },
    { fieldName: '차이수량A_B', dataType: ValueType.NUMBER },
    { fieldName: '재고금액C', dataType: ValueType.NUMBER },
    { fieldName: '결산재고금액D', dataType: ValueType.NUMBER },
    { fieldName: '차이금액C_D', dataType: ValueType.NUMBER },
    { fieldName: '최종결산월재고단가', dataType: ValueType.NUMBER },
    { fieldName: '생산수량', dataType: ValueType.NUMBER },
    { fieldName: '생산금액', dataType: ValueType.NUMBER },
    { fieldName: '구매수량', dataType: ValueType.NUMBER },
    { fieldName: '구매금액', dataType: ValueType.NUMBER },
    { fieldName: '적송입고수량', dataType: ValueType.NUMBER },
    { fieldName: '적송입고금액', dataType: ValueType.NUMBER },
    { fieldName: '기타입고수량', dataType: ValueType.NUMBER },
    { fieldName: '기타입고금액', dataType: ValueType.NUMBER },
    { fieldName: '판매수량', dataType: ValueType.NUMBER },
    { fieldName: '판매원가', dataType: ValueType.NUMBER },
    { fieldName: '투입수량', dataType: ValueType.NUMBER },
    { fieldName: '투입금액', dataType: ValueType.NUMBER },
    { fieldName: '적송출고수량', dataType: ValueType.NUMBER },
    { fieldName: '적송출고금액', dataType: ValueType.NUMBER },
    { fieldName: '기타출고수량', dataType: ValueType.NUMBER },
    { fieldName: '기타출고금액', dataType: ValueType.NUMBER },     
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
    { name: '자산처리계정', fieldName: '자산처리계정', width: '150', header: { text: '자산처리계정' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: '품목자산분류', fieldName: '품목자산분류', width: '120', header: { text: '품목자산분류' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: '재고자산종류', fieldName: '재고자산종류', width: '150', header: { text: '재고자산종류' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: '매출원가계정', fieldName: '매출원가계정', width: '120', header: { text: '매출원가계정' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },  
    { name: '대분류', fieldName: '대분류', width: '150', header: { text: '대분류' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: '중분류', fieldName: '중분류', width: '120', header: { text: '중분류' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: '소분류', fieldName: '소분류', width: '150', header: { text: '소분류' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },
    { name: '품목기타분류', fieldName: '품목기타분류', width: '120', header: { text: '품목기타분류' }, autoFilter: true, editable: true, styleName: 'tl', styleCallback: addNewRow('tl') },
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
    { name: '기초수량', fieldName: '기초수량', width: '100', header: { text: '기초수량' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '기초금액', fieldName: '기초금액', width: '120', header: { text: '기초금액' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '입고수량', fieldName: '입고수량', width: '100', header: { text: '입고수량' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '입고금액', fieldName: '입고금액', width: '120', header: { text: '입고금액' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '출고수량', fieldName: '출고수량', width: '100', header: { text: '출고수량' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '출고금액', fieldName: '출고금액', width: '120', header: { text: '출고금액' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },    
    { name: '재고수량A', fieldName: '재고수량A', width: '100', header: { text: '재고수량A' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '결산재고수량B', fieldName: '결산재고수량B', width: '120', header: { text: '결산재고수량B' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '차이수량A_B', fieldName: '차이수량A_B', width: '100', header: { text: '차이수량A_B' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '재고금액C', fieldName: '재고금액C', width: '120', header: { text: '재고금액C' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '결산재고금액D', fieldName: '결산재고금액D', width: '120', header: { text: '결산재고금액D' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') }, 
    { name: '차이금액C_D', fieldName: '차이금액C_D', width: '120', header: { text: '차이금액C_D' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '최종결산월재고단가', fieldName: '최종결산월재고단가', width: '150', header: { text: '최종결산월재고단가' }, autoFilter: true, editable: true, styleName: 'tr', styleCallback: addNewRow('tr'), numberFormat: '#,##0' },
    { name: '생산수량', fieldName: '생산수량', width: '100', header: { text: '생산수량' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '생산금액', fieldName: '생산금액', width: '120', header: { text: '생산금액' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '구매수량', fieldName: '구매수량', width: '100', header: { text: '구매수량' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '구매금액', fieldName: '구매금액', width: '120', header: { text: '구매금액' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '적송입고수량', fieldName: '적송입고수량', width: '100', header: { text: '적송입고수량' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '적송입고금액', fieldName: '적송입고금액', width: '120', header: { text: '적송입고금액' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '기타입고수량', fieldName: '기타입고수량', width: '100', header: { text: '기타입고수량' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '기타입고금액', fieldName: '기타입고금액', width: '120', header: { text: '기타입고금액' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '판매수량', fieldName: '판매수량', width: '100', header: { text: '판매수량' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '판매원가', fieldName: '판매원가', width: '120', header: { text: '판매원가' }, autoFilter: true, editable: true, styleName: 'tr', styleCallback: addNewRow('tr'), numberFormat: '#,##0' },
    { name: '투입수량', fieldName: '투입수량', width: '100', header: { text: '투입수량' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '투입금액', fieldName: '투입금액', width: '120', header: { text: '투입금액' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '적송출고수량', fieldName: '적송출고수량', width: '100', header: { text: '적송출고수량' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '적송출고금액', fieldName: '적송출고금액', width: '120', header: { text: '적송출고금액' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '기타출고수량', fieldName: '기타출고수량', width: '100', header: { text: '기타출고수량' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },
    { name: '기타출고금액', fieldName: '기타출고금액', width: '120', header: { text: '기타출고금액' }, autoFilter: true, editable: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }, styleCallback: addNewRow('tr') },                                
  ],
};

module.exports = grid;
