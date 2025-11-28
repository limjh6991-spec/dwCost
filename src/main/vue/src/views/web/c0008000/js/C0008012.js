/*
 * 결산증빙 자료 > 매출
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
    { fieldName: '거래명세서번호', dataType: ValueType.TEXT },
    { fieldName: '거래명세서일', dataType: ValueType.TEXT },
    { fieldName: '부서', dataType: ValueType.TEXT },
    { fieldName: '담당자', dataType: ValueType.TEXT },
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: '거래처', dataType: ValueType.TEXT },
    { fieldName: '품명', dataType: ValueType.TEXT },
    { fieldName: '품번', dataType: ValueType.TEXT },
    { fieldName: '판매단위', dataType: ValueType.TEXT },
    { fieldName: '수량', dataType: ValueType.NUMBER },
    { fieldName: '통화', dataType: ValueType.TEXT },
    { fieldName: '환율', dataType: ValueType.NUMBER },
    { fieldName: '판매단가', dataType: ValueType.NUMBER },
    { fieldName: '국내공급가액', dataType: ValueType.NUMBER },
    { fieldName: '수출판매금액', dataType: ValueType.NUMBER },
    { fieldName: '부가세액', dataType: ValueType.NUMBER },
    { fieldName: '원화판매금액', dataType: ValueType.NUMBER },
    { fieldName: '원화부가세액', dataType: ValueType.NUMBER },
    { fieldName: '원화판매금액계', dataType: ValueType.NUMBER },
    { fieldName: '매출수량', dataType: ValueType.NUMBER },
    { fieldName: '매출금액계', dataType: ValueType.NUMBER },
    { fieldName: '세금계산서금액계', dataType: ValueType.NUMBER },
  ],

  columns: [
    { name: '거래명세서번호', fieldName: '거래명세서번호', width: '210', header: { text: '거래명세서번호' }, autoFilter: true, styleName: 'tl' },
    { name: '거래명세서일', fieldName: '거래명세서일', width: '180', header: { text: '거래명세서일' }, autoFilter: true, styleName: 'tl' },
    { name: '부서', fieldName: '부서', width: '80', header: { text: '부서' }, autoFilter: true, styleName: 'tl' },
    { name: '담당자', fieldName: '담당자', width: '90', header: { text: '담당자' }, autoFilter: true, styleName: 'tl' },
    { name: '구분', fieldName: '구분', width: '80', header: { text: '구분' }, autoFilter: true, styleName: 'tl' },
    { name: '거래처', fieldName: '거래처', width: '90', header: { text: '거래처' }, autoFilter: true, styleName: 'tl' },
    { name: '품명', fieldName: '품명', width: '80', header: { text: '품명' }, autoFilter: true, styleName: 'tl' },
    { name: '품번', fieldName: '품번', width: '80', header: { text: '품번' }, autoFilter: true, styleName: 'tl' },
    { name: '판매단위', fieldName: '판매단위', width: '120', header: { text: '판매단위' }, autoFilter: true, styleName: 'tl', footer: { text: '합계' } },
    { name: '수량', fieldName: '수량', width: '80', header: { text: '수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.##', footer: { expression: 'sum', numberFormat: '#,##0.##', styleName: 'sum-footer1' } },
    { name: '통화', fieldName: '통화', width: '80', header: { text: '통화' }, autoFilter: true, styleName: 'tl' },
    { name: '환율', fieldName: '환율', width: '80', header: { text: '환율' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.##', footer: { expression: 'sum', numberFormat: '#,##0.##', styleName: 'sum-footer1' } },
    { name: '판매단가', fieldName: '판매단가', width: '120', header: { text: '판매단가' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.##', footer: { expression: 'sum', numberFormat: '#,##0.##', styleName: 'sum-footer1' } ,
        renderer: {
    type: "html",
    callback: function(grid, cell) {
      const 통화 = grid.getValue(cell.index.itemIndex, "통화");
      const 판매단가 = cell.value;

      if (판매단가 == null || 판매단가 === "") return "";

      if (통화 === "USD") {
        return "$" + 판매단가.toLocaleString(undefined, { minimumFractionDigits: 2 });
      }
      if (통화 === "KRW") {
        return 판매단가.toLocaleString();  // 원화
      }
    }}},
    { name: '국내공급가액', fieldName: '국내공급가액', width: '120', header: { text: '국내공급가액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.##', footer: { expression: 'sum', numberFormat: '#,##0.##', styleName: 'sum-footer1' } },
    { name: '수출판매금액', fieldName: '수출판매금액', width: '120', header: { text: '수출판매금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.##', footer: { expression: 'sum', numberFormat: '#,##0.##', styleName: 'sum-footer1' } ,
    renderer: {
    type: "html",
    callback: function(grid, cell) {
      const 통화 = grid.getValue(cell.index.itemIndex, "통화");
      const 수출판매금액 = cell.value;

      if (수출판매금액 == null || 수출판매금액 === "") return "";

      if (통화 === "USD") {
        return "$" + 수출판매금액.toLocaleString(undefined, { minimumFractionDigits: 2 });
      }
      if (통화 === "KRW") {
        return 수출판매금액.toLocaleString();  // 원화
      }
    }}},
    { name: '부가세액', fieldName: '부가세액', width: '120', header: { text: '부가세액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.##', footer: { expression: 'sum', numberFormat: '#,##0.##', styleName: 'sum-footer1' } },
    { name: '원화판매금액', fieldName: '원화판매금액', width: '180', header: { text: '원화판매금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.##', footer: { expression: 'sum', numberFormat: '#,##0.##', styleName: 'sum-footer1' } },
    { name: '원화부가세액', fieldName: '원화부가세액', width: '180', header: { text: '원화부가세액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.##', footer: { expression: 'sum', numberFormat: '#,##0.##', styleName: 'sum-footer1' } },
    { name: '원화판매금액계', fieldName: '원화판매금액계', width: '210', header: { text: '원화판매금액계' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.##', footer: { expression: 'sum', numberFormat: '#,##0.##', styleName: 'sum-footer1' } },
    { name: '매출수량', fieldName: '매출수량', width: '120', header: { text: '매출수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.##', footer: { expression: 'sum', numberFormat: '#,##0.##', styleName: 'sum-footer1' } },
    { name: '매출금액계', fieldName: '매출금액계', width: '150', header: { text: '매출금액계' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.##', footer: { expression: 'sum', numberFormat: '#,##0.##', styleName: 'sum-footer1' } },
    { name: '세금계산서금액계', fieldName: '세금계산서금액계', width: '240', header: { text: '세금계산서금액계' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.##', footer: { expression: 'sum', numberFormat: '#,##0.##', styleName: 'sum-footer1' } },
  ],
};

module.exports = grid;
