/* 타시스템 > 매출정보 > 수출신고필증조회 (TAB070024) — 수출신고필증(EXP_PERMIT) 적재 조회. 원천 DOI_VN_IF_EXP_PERMIT */
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
    { fieldName: '사업부문', dataType: ValueType.TEXT },
    { fieldName: '수입통관일', dataType: ValueType.TEXT },
    { fieldName: '수입통관관리번호', dataType: ValueType.TEXT },
    { fieldName: '수출구분', dataType: ValueType.TEXT },
    { fieldName: '거래처', dataType: ValueType.TEXT },
    { fieldName: '통화', dataType: ValueType.TEXT },
    { fieldName: '가격조건', dataType: ValueType.TEXT },
  ],
  columns: [
    { name: '사업부문', fieldName: '사업부문', width: 120, header: { text: '사업부문' }, styleName: 'tc' },
    { name: '수입통관일', fieldName: '수입통관일', width: 110, header: { text: '수입통관일' }, styleName: 'tc' },
    { name: '수입통관관리번호', fieldName: '수입통관관리번호', width: 160, header: { text: '수입통관관리번호' }, styleName: 'tl' },
    { name: '수출구분', fieldName: '수출구분', width: 100, header: { text: '수출구분' }, styleName: 'tc' },
    { name: '거래처', fieldName: '거래처', width: 200, header: { text: '거래처' }, styleName: 'tl' },
    { name: '통화', fieldName: '통화', width: 80, header: { text: '통화' }, styleName: 'tc' },
    { name: '가격조건', fieldName: '가격조건', width: 120, header: { text: '가격조건' }, styleName: 'tc' },
  ],
  layout: ['사업부문', '수입통관일', '수입통관관리번호', '수출구분', '거래처', '통화', '가격조건'],
};
module.exports = grid;
