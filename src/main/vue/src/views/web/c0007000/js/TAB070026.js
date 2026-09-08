/* 타시스템 > 자재투입정보 > 사업단위별수불집계조회 (TAB070026) — 사업단위별수불집계(BIZ_STOCK_SUM) 적재 조회. 원천 DOI_VN_IF_BIZ_STOCK_SUM */
const { ValueType } = require('realgrid');

const QTY = { styleName: 'tr', numberFormat: '#,##0.###' };

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
    { fieldName: '품목자산분류', dataType: ValueType.TEXT },
    { fieldName: '재고자산종류', dataType: ValueType.TEXT },
    { fieldName: '품목대분류', dataType: ValueType.TEXT },
    { fieldName: '품목중분류', dataType: ValueType.TEXT },
    { fieldName: '품목소분류', dataType: ValueType.TEXT },
    { fieldName: '품명', dataType: ValueType.TEXT },
    { fieldName: '품번', dataType: ValueType.TEXT },
    { fieldName: '규격', dataType: ValueType.TEXT },
    { fieldName: '단위', dataType: ValueType.TEXT },
    { fieldName: '품목상태', dataType: ValueType.TEXT },
    { fieldName: '이월수량', dataType: ValueType.NUMBER },
    { fieldName: '입고수량', dataType: ValueType.NUMBER },
    { fieldName: '출고수량', dataType: ValueType.NUMBER },
    { fieldName: '재고수량', dataType: ValueType.NUMBER },
  ],
  columns: [
    { name: '사업부문', fieldName: '사업부문', width: 130, header: { text: '사업부문' }, styleName: 'tl' },
    { name: '품목자산분류', fieldName: '품목자산분류', width: 110, header: { text: '품목자산분류' }, styleName: 'tc' },
    { name: '재고자산종류', fieldName: '재고자산종류', width: 110, header: { text: '재고자산종류' }, styleName: 'tc' },
    { name: '품목대분류', fieldName: '품목대분류', width: 100, header: { text: '품목대분류' }, styleName: 'tc' },
    { name: '품목중분류', fieldName: '품목중분류', width: 100, header: { text: '품목중분류' }, styleName: 'tc' },
    { name: '품목소분류', fieldName: '품목소분류', width: 100, header: { text: '품목소분류' }, styleName: 'tc' },
    { name: '품명', fieldName: '품명', width: 200, header: { text: '품명' }, styleName: 'tl' },
    { name: '품번', fieldName: '품번', width: 120, header: { text: '품번' }, styleName: 'tl' },
    { name: '규격', fieldName: '규격', width: 140, header: { text: '규격' }, styleName: 'tl' },
    { name: '단위', fieldName: '단위', width: 70, header: { text: '단위' }, styleName: 'tc' },
    { name: '품목상태', fieldName: '품목상태', width: 90, header: { text: '품목상태' }, styleName: 'tc' },
    { name: '이월수량', fieldName: '이월수량', width: 110, header: { text: '이월수량' }, ...QTY },
    { name: '입고수량', fieldName: '입고수량', width: 110, header: { text: '입고수량' }, ...QTY },
    { name: '출고수량', fieldName: '출고수량', width: 110, header: { text: '출고수량' }, ...QTY },
    { name: '재고수량', fieldName: '재고수량', width: 110, header: { text: '재고수량' }, ...QTY },
  ],
  layout: [
    '사업부문', '품목자산분류', '재고자산종류', '품목대분류', '품목중분류', '품목소분류',
    '품명', '품번', '규격', '단위', '품목상태', '이월수량', '입고수량', '출고수량', '재고수량',
  ],
};
module.exports = grid;
