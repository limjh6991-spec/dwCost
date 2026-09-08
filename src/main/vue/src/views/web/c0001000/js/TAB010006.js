/* 기준정보 > 언어별계정항목 (TAB010006) — 타시스템 언어별계정항목(ACCLANG) 적재 조회. 원천 DOI_VN_IF_ACCLANG */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: false },
    display: { columnMovable: false, fitStyle: 'fill', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
    edit: { editable: false },
    footer: { visible: false },
    rowIndicator: { visible: true },
  },
  fields: [
    { fieldName: '계정대분류코드', dataType: ValueType.TEXT },
    { fieldName: '계정항목', dataType: ValueType.TEXT },
    { fieldName: '조회순서', dataType: ValueType.NUMBER },
  ],
  columns: [
    { name: '계정대분류코드', fieldName: '계정대분류코드', width: 200, header: { text: '계정대분류코드' }, styleName: 'tl' },
    { name: '계정항목', fieldName: '계정항목', width: 300, header: { text: '계정항목' }, styleName: 'tl' },
    { name: '조회순서', fieldName: '조회순서', width: 100, header: { text: '조회순서' }, styleName: 'tr', numberFormat: '#,##0' },
  ],
  layout: ['계정대분류코드', '계정항목', '조회순서'],
};
module.exports = grid;
