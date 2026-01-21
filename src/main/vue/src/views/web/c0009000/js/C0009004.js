/** * 자재 수불부 */

const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: true, exclusive: false, syncHeadCheck: true },
    copy: { enabled: true, singleMode: false },
    display: { columnMovable: false, editItemMerging: true, fitStyle: 'fill', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
    edit: { editable: true, columnEditableFirst: true, commitByCell: true, commitWhenLeave: true },
    footer: { visible: true },
    header: { height: 40, showTooltip: true, tooltipEllipsisOnly: true },
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
    { fieldName: '재고수량', dataType: ValueType.NUMBER },
    { fieldName: '재고금액', dataType: ValueType.NUMBER },
    { fieldName: '재고단가', dataType: ValueType.NUMBER },
    { fieldName: '최종결산월재고단가', dataType: ValueType.NUMBER },
    { fieldName: '구매수량', dataType: ValueType.NUMBER },
    { fieldName: '구매금액', dataType: ValueType.NUMBER },
    { fieldName: '기타입고수량', dataType: ValueType.NUMBER },
    { fieldName: '기타입고금액', dataType: ValueType.NUMBER },
    { fieldName: '판매수량', dataType: ValueType.NUMBER },
    { fieldName: '판매원가', dataType: ValueType.NUMBER },
    { fieldName: '투입수량', dataType: ValueType.NUMBER },
    { fieldName: '투입금액', dataType: ValueType.NUMBER },
    { fieldName: '기타출고수량', dataType: ValueType.NUMBER },
    { fieldName: '기타출고금액', dataType: ValueType.NUMBER },
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
      styleCallback: function (grid, dataCell) {
        var ret = {};
        if (dataCell.item.rowState == 'created' || dataCell.item.itemState == 'appending' || dataCell.item.itemState == 'inserting') {
          ret.editable = true;
          ret.styleName = 'edit tl';
        } else {
          ret.editable = false;
          ret.styleName = 'tc';
        }
        return ret;
      },
    },
    { name: 'selCode', fieldName: 'selCode', width: '80', header: { text: 'SEL_CODE' }, autoFilter: true, styleName: 'tc' },
    { name: 'siteOrg', fieldName: 'siteOrg', width: '0', header: { text: 'SITE_ORG' }, autoFilter: true, visible: false, editable: false, styleName: 'tl' },
    {
      name: 'site',
      fieldName: 'site',
      width: '80',
      header: { text: '사이트' },
      autoFilter: true,
      editable: false,
      styleName: 'tl',
      styleCallback: function (grid, dataCell) {
        var ret = {};
        if (dataCell.item.rowState == 'created' || dataCell.item.itemState == 'appending' || dataCell.item.itemState == 'inserting') {
          ret.editable = true;
          ret.styleName = 'edit tc';
        } else {
          ret.editable = false;
          ret.styleName = 'tc';
        }
        return ret;
      },
    },
    { name: '품목자산분류', fieldName: '품목자산분류', width: '120', header: { text: '품목자산분류' }, autoFilter: true, visible: false, editable: false, styleName: 'tc' },
    { name: '재고자산종류', fieldName: '재고자산종류', width: '120', header: { text: '재고자산종류' }, autoFilter: true, styleName: 'tc' },
    { name: '매출원가계정', fieldName: '매출원가계정', width: '120', header: { text: '매출원가계정' }, autoFilter: true, styleName: 'tc' },
    { name: '대분류', fieldName: '대분류', width: '100', header: { text: '대분류' }, autoFilter: true, styleName: 'tc' },
    { name: '중분류', fieldName: '중분류', width: '100', header: { text: '중분류' }, autoFilter: true, styleName: 'tc' },
    { name: '소분류', fieldName: '소분류', width: '100', header: { text: '소분류' }, autoFilter: true, styleName: 'tc' },
    { name: '품목기타분류', fieldName: '품목기타분류', width: '120', header: { text: '품목기타분류'}, autoFilter: true, styleName: 'tc' },
    { name: '품명', fieldName: '품명', width: '120', header: { text: '품명' }, autoFilter: true, styleName: 'tc' },
    { name: '품번', fieldName: '품번', width: '120', header: { text: '품번' }, autoFilter: true, styleName: 'tc' },
    { name: '규격', fieldName: '규격', width: '120', header: { text: '규격' }, autoFilter: true, styleName: 'tc' },
    { name: '단위', fieldName: '단위', width: '50', header: { text: '단위' }, autoFilter: true, styleName: 'tc' },
    { name: '기초수량', fieldName: '기초수량', width: '100', header: { text: '기초수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1",} },
    { name: '기초금액', fieldName: '기초금액', width: '120', header: { text: '기초금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1",} },
    { name: '입고수량', fieldName: '입고수량', width: '100', header: { text: '입고수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1",} },
    { name: '입고금액', fieldName: '입고금액', width: '120', header: { text: '입고금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1",} },
    { name: '출고수량', fieldName: '출고수량', width: '100', header: { text: '출고수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1",} },
    { name: '출고금액', fieldName: '출고금액', width: '120', header: { text: '출고금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1",} },
    { name: '재고수량', fieldName: '재고수량', width: '100', header: { text: '재고수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1",} },
    { name: '재고금액', fieldName: '재고금액', width: '120', header: { text: '재고금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1",} },
    { name: '재고단가', fieldName: '재고단가', width: '100', header: { text: '재고단가' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.00' },
    { name: '최종결산월재고단가', fieldName: '최종결산월재고단가', width: '100', header: { text: '최종결산월\n재고단가' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.00' },
    { name: '구매수량', fieldName: '구매수량', width: '100', header: { text: '구매수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1",} },
    { name: '구매금액', fieldName: '구매금액', width: '120', header: { text: '구매금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1",} },
    { name: '기타입고수량', fieldName: '기타입고수량', width: '120', header: { text: '기타입고수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1",} },
    { name: '기타입고금액', fieldName: '기타입고금액', width: '120', header: { text: '기타입고금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1",} },
    { name: '판매수량', fieldName: '판매수량', width: '100', header: { text: '판매수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1",} },
    { name: '판매원가', fieldName: '판매원가', width: '100', header: { text: '판매원가' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0.00' },
    { name: '투입수량', fieldName: '투입수량', width: '100', header: { text: '투입수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1",} },
    { name: '투입금액', fieldName: '투입금액', width: '120', header: { text: '투입금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1",} },
    { name: '기타출고수량', fieldName: '기타출고수량', width: '120', header: { text: '기타출고수량' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1",} },
    { name: '기타출고금액', fieldName: '기타출고금액', width: '120', header: { text: '기타출고금액' }, autoFilter: true, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1",} },
  ],
};

module.exports = grid;