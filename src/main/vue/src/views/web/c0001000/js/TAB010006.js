/* 기준정보 > 언어별계정항목 (TAB010006) — 타시스템 언어별계정항목(ACCLANG) 적재 조회.
 *   원천 DOI_VN_IF_ACCLANG(계정행) + DOI_VN_IF_ACCLANG_LANG(DataBlock4 언어별 명칭, ColIDX 0~5 피벗).
 *   언어 컬럼: 한국어/영어/일본어/简体中文/繁體中文/Tiếng việt (필드명 '베트남어'는 CamelMap 안전용, 헤더만 Tiếng việt) */
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
    { fieldName: '한국어', dataType: ValueType.TEXT },
    { fieldName: '영어', dataType: ValueType.TEXT },
    { fieldName: '일본어', dataType: ValueType.TEXT },
    { fieldName: '简体中文', dataType: ValueType.TEXT },
    { fieldName: '繁體中文', dataType: ValueType.TEXT },
    { fieldName: '베트남어', dataType: ValueType.TEXT },
    { fieldName: '조회순서', dataType: ValueType.NUMBER },
  ],
  columns: [
    { name: '계정대분류코드', fieldName: '계정대분류코드', width: 200, header: { text: '계정대분류코드' }, styleName: 'tl' },
    { name: '계정항목', fieldName: '계정항목', width: 300, header: { text: '계정항목' }, styleName: 'tl' },
    { name: '한국어', fieldName: '한국어', width: 220, header: { text: '한국어' }, styleName: 'tl' },
    { name: '영어', fieldName: '영어', width: 220, header: { text: '영어' }, styleName: 'tl' },
    { name: '일본어', fieldName: '일본어', width: 220, header: { text: '일본어' }, styleName: 'tl' },
    { name: '简体中文', fieldName: '简体中文', width: 220, header: { text: '简体中文' }, styleName: 'tl' },
    { name: '繁體中文', fieldName: '繁體中文', width: 220, header: { text: '繁體中文' }, styleName: 'tl' },
    { name: '베트남어', fieldName: '베트남어', width: 220, header: { text: 'Tiếng việt' }, styleName: 'tl' },
    { name: '조회순서', fieldName: '조회순서', width: 90, header: { text: '조회순서' }, styleName: 'tr', numberFormat: '#,##0' },
  ],
  layout: ['계정대분류코드', '계정항목', '한국어', '영어', '일본어', '简体中文', '繁體中文', '베트남어', '조회순서'],
};
module.exports = grid;
