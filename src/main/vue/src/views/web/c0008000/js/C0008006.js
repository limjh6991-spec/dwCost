/*
 * 결산증빙 자료 > 원가항목별 재료비(DOI_MAT_EXPEN)
 */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: false },
    copy: { enabled: true, singleMode: true },
    display: { columnMovable: false, editItemMerging: true, fitStyle: 'even', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
    edit: { editable: false },
    footer: { visible: true },
    paste: { enabled: false },
    rowIndicator: { visible: true },
    sorting: { enabled: true },
    stateBar: { visible: false },
    filtering: { enabled: true },
    fixed: { colBarWidth: 1, colCount: 1 },
  },

  fields: [
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: 'selCode', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
  { fieldName: '도우모델', dataType: ValueType.TEXT },
  { fieldName: '자재번호', dataType: ValueType.TEXT },
  { fieldName: '자재명', dataType: ValueType.TEXT },
  { fieldName: 'expenSel', dataType: ValueType.TEXT },
  { fieldName: 'expenSel명', dataType: ValueType.TEXT },
  { fieldName: 'matClass', dataType: ValueType.TEXT },
  { fieldName: 'inAmt', dataType:ValueType.NUMBER },
  { fieldName: '환산량', dataType: ValueType.NUMBER },
  { fieldName: 'bom사용량', dataType: ValueType.TEXT },
  { fieldName: '면적', dataType: ValueType.NUMBER },
  { fieldName: '사용량', dataType: ValueType.NUMBER },
  { fieldName: '배부적수', dataType: ValueType.TEXT },
   { fieldName: '배부금액', dataType: ValueType.NUMBER },
  { fieldName: '배부방식', dataType: ValueType.TEXT } 
  ],

  columns: [
    { name: 'yyyymm', fieldName: 'yyyymm', width: '80', header: { text: 'YYYYMM' }, autoFilter: true, styleName: 'tl' },
    { name: 'selCode', fieldName: 'selCode', width: '80', header: { text: 'SEL_CODE' }, autoFilter: true, styleName: 'tl' },
    { name: 'site', fieldName: 'site', width: '80', header: { text: '사이트' }, autoFilter: true, styleName: 'tl' },
  { name: '도우모델', fieldName: '도우모델', width: '80', header: { text: '도우모델' }, autoFilter: true, styleName: 'tl',  },
  { name: '자재번호', fieldName: '자재번호', width: '80', header: { text: '자재번호' }, autoFilter: true, styleName: 'tl',  },
  { name: '자재명', fieldName: '자재명', width: '80', header: { text: '자재명' }, autoFilter: true, styleName: 'tl',  },
  { name: 'expen_sel', fieldName: 'expenSel', width: '80', header: { text: 'EXPEN_SEL' }, autoFilter: true, styleName: 'tl',  },
  { name: 'expen_sel명', fieldName: 'expenSel명', width: '80', header: { text: 'EXPEN_SEL명' }, autoFilter: true, styleName: 'tl',  },
  { name: 'mat_class', fieldName: 'matClass', width: '80', header: { text: '대분류' }, autoFilter: true, styleName: 'tl',  },
  { name: '환산량', fieldName: '환산량', width: '80', header: { text: '환산량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0',},
  { name: 'BOM사용량', fieldName: 'bom사용량', width: '80', header: { text: 'BOM사용량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', } ,
  { name: '면적', fieldName: '면적', width: '80', header: { text: '면적' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', },
  { name: '사용량', fieldName: '사용량', width: '80', header: { text: '사용량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', },
  { name: '배부적수', fieldName: '배부적수', width: '80', header: { text: '배부적수' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0',  },
  { name: 'inAmt', fieldName: 'inAmt', width: '80', header: { text: '투입금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { text: '합계' } },
  { name: '배부금액', fieldName: '배부금액', width: '80', header: { text: '배부금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
  { name: '배부방식', fieldName: '배부방식', width: '80', header: { text: '배부방식' }, autoFilter: true, styleName: 'tl', }    
    // { name: 'matClass', fieldName: 'matClass', width: '80', header: { text: 'MAT_CLASS' }, autoFilter: true, styleName: 'tl', footer: { text: '합계' } },
    // { name: '배부금액', fieldName: '배부금액', width: '80', header: { text: '배부금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' } },
  ],
};

module.exports = grid;
