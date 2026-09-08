/* 기준정보 > 공정 (TAB010007) — 타시스템 공정(PROCESS) 적재 조회. 원천 DOI_VN_IF_PROCESS */
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
    { fieldName: '사업단위', dataType: ValueType.TEXT },
    { fieldName: '공정내부코드', dataType: ValueType.TEXT },
    { fieldName: '공정명', dataType: ValueType.TEXT },
    { fieldName: '공정검사여부', dataType: ValueType.TEXT },
    { fieldName: '비고', dataType: ValueType.TEXT },
  ],
  columns: [
    { name: '사업단위', fieldName: '사업단위', width: 120, header: { text: '사업단위' }, styleName: 'tc' },
    { name: '공정내부코드', fieldName: '공정내부코드', width: 120, header: { text: '공정내부코드' }, styleName: 'tc' },
    { name: '공정명', fieldName: '공정명', width: 200, header: { text: '공정명' }, styleName: 'tl' },
    { name: '공정검사여부', fieldName: '공정검사여부', width: 100, header: { text: '공정검사여부' }, styleName: 'tc' },
    { name: '비고', fieldName: '비고', width: 300, header: { text: '비고' }, styleName: 'tl' },
  ],
  layout: ['사업단위', '공정내부코드', '공정명', '공정검사여부', '비고'],
};
module.exports = grid;
