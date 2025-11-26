/*
 * 타시스템 I/F&Upload > 매출 정보
 */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: true, exclusive: false, syncHeadCheck: true },
    copy: { enabled: true, singleMode: false },
    display: { columnMovable: false, editItemMerging: true, fitStyle: 'even', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
    edit: { editable: true, columnEditableFirst: true, commitByCell: true, commitWhenLeave: true },
    footer: { visible: false },
    hideDeletedRows: true,
    paste: { enabled: true, checkReadOnly: true },
    rowIndicator: { visible: true },
    sorting: { enabled: false },
    stateBar: { visible: false },
    filtering: { enabled: true },
    fixed: { colBarWidth: 1, colCount: 7 },
  },

  fields: [
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: 'selCode', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: '선택', dataType: ValueType.TEXT },
    { fieldName: '출고처리', dataType: ValueType.TEXT },
    { fieldName: '사업단위', dataType: ValueType.TEXT },
    { fieldName: '거래명세서번호', dataType: ValueType.TEXT },
    { fieldName: '거래명세서일', dataType: ValueType.TEXT },
    { fieldName: 'local구분', dataType: ValueType.TEXT },
    { fieldName: '출고구분', dataType: ValueType.TEXT },
    { fieldName: '부서', dataType: ValueType.TEXT },
    { fieldName: '담당자', dataType: ValueType.TEXT },
    { fieldName: '청구처', dataType: ValueType.TEXT },
    { fieldName: '거래처', dataType: ValueType.TEXT },
    { fieldName: '유통구조', dataType: ValueType.TEXT },
    { fieldName: '거래처번호', dataType: ValueType.TEXT },
    { fieldName: '중개인', dataType: ValueType.TEXT },
    { fieldName: '납품장소', dataType: ValueType.TEXT },
    { fieldName: '인도조건', dataType: ValueType.TEXT },
    { fieldName: '판매후보관', dataType: ValueType.TEXT },
    { fieldName: '위탁', dataType: ValueType.TEXT },
    { fieldName: '납품거래처', dataType: ValueType.TEXT },
    { fieldName: '납기일', dataType: ValueType.TEXT },
    { fieldName: '품명', dataType: ValueType.TEXT },
    { fieldName: '품번', dataType: ValueType.TEXT },
    { fieldName: '규격', dataType: ValueType.TEXT },
    { fieldName: '판매단위', dataType: ValueType.TEXT },
    { fieldName: '판매기준가', dataType: ValueType.NUMBER },
    { fieldName: '수량', dataType: ValueType.NUMBER },
    { fieldName: '부가세포함', dataType: ValueType.TEXT },
    { fieldName: '통화', dataType: ValueType.TEXT },
    { fieldName: '환율', dataType: ValueType.NUMBER },
    { fieldName: '판매단가', dataType: ValueType.NUMBER },
    { fieldName: '판매금액', dataType: ValueType.NUMBER },
    { fieldName: '부가세액', dataType: ValueType.NUMBER },
    { fieldName: '판매금액계', dataType: ValueType.NUMBER },
    { fieldName: '원화판매금액', dataType: ValueType.NUMBER },
    { fieldName: '원화부가세액', dataType: ValueType.NUMBER },
    { fieldName: '원화판매금액계', dataType: ValueType.NUMBER },
    { fieldName: '창고', dataType: ValueType.TEXT },
    { fieldName: '보관위치', dataType: ValueType.TEXT },
    { fieldName: 'lotNo', dataType: ValueType.TEXT },
    { fieldName: '세금계산서진행상태', dataType: ValueType.TEXT },
    { fieldName: '배송상태', dataType: ValueType.TEXT },
    { fieldName: '품목특이사항', dataType: ValueType.TEXT },
    { fieldName: '매출시점', dataType: ValueType.TEXT },
    { fieldName: '진행조회', dataType: ValueType.TEXT },
    { fieldName: '원천조회', dataType: ValueType.TEXT },
    { fieldName: '원천관리번호', dataType: ValueType.TEXT },
    { fieldName: '원천번호', dataType: ValueType.TEXT },
    { fieldName: 'poNo', dataType: ValueType.TEXT },
    { fieldName: '반품', dataType: ValueType.TEXT },
    { fieldName: '매출수량', dataType: ValueType.NUMBER },
    { fieldName: '매출금액계', dataType: ValueType.NUMBER },
    { fieldName: '미매출금액', dataType: ValueType.NUMBER },
    { fieldName: '세금계산서금액계', dataType: ValueType.NUMBER },
    { fieldName: '계산서미발행액', dataType: ValueType.NUMBER },
    { fieldName: '계산서미발행수량', dataType: ValueType.NUMBER },
    { fieldName: '기타출고구분', dataType: ValueType.TEXT },
    { fieldName: '품목자산분류', dataType: ValueType.TEXT },
    { fieldName: '단가소급여부', dataType: ValueType.TEXT },
    { fieldName: '수량(단가소급)', dataType: ValueType.NUMBER },
    { fieldName: '유상사급여부', dataType: ValueType.TEXT },
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
          ret.styleName = 'tl';
        }
        return ret;
      },
    },
    {
      name: 'selCode',
      fieldName: 'selCode',
      width: '80',
      header: { text: 'SEL_CODE' },
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
          ret.styleName = 'tl';
        }
        return ret;
      },
    },
    {
      name: 'site',
      fieldName: 'site',
      width: '80',
      header: { text: 'SITE' },
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
          ret.styleName = 'tl';
        }
        return ret;
      },
    },
    { name: '선택', fieldName: '선택', width: '80', header: { text: '선택' }, autoFilter: true, styleName: 'edit tl' },
    { name: '출고처리', fieldName: '출고처리', width: '120', header: { text: '출고처리' }, autoFilter: true, styleName: 'edit tl' },
    { name: '사업단위', fieldName: '사업단위', width: '120', header: { text: '사업단위' }, autoFilter: true, styleName: 'edit tl' },
    {
      name: '거래명세서번호',
      fieldName: '거래명세서번호',
      width: '210',
      header: { text: '거래명세서번호' },
      autoFilter: true,
      styleName: 'tl',
      editable: false,
      styleCallback: function (grid, dataCell) {
        var ret = {};
        if (dataCell.item.rowState == 'created' || dataCell.item.itemState == 'appending' || dataCell.item.itemState == 'inserting') {
          ret.editable = true;
          ret.styleName = 'edit tl';
        } else {
          ret.editable = false;
          ret.styleName = 'tl';
        }
        return ret;
      },
    },
    { name: '거래명세서일', fieldName: '거래명세서일', width: '180', header: { text: '거래명세서일' }, autoFilter: true, styleName: 'edit tl' },
    { name: 'local구분', fieldName: 'local구분', width: '110', header: { text: 'Local구분' }, autoFilter: true, styleName: 'edit tl' },
    { name: '출고구분', fieldName: '출고구분', width: '120', header: { text: '출고구분' }, autoFilter: true, styleName: 'edit tl' },
    { name: '부서', fieldName: '부서', width: '80', header: { text: '부서' }, autoFilter: true, styleName: 'edit tl' },
    { name: '담당자', fieldName: '담당자', width: '90', header: { text: '담당자' }, autoFilter: true, styleName: 'edit tl' },
    { name: '청구처', fieldName: '청구처', width: '90', header: { text: '청구처' }, autoFilter: true, styleName: 'edit tl' },
    { name: '거래처', fieldName: '거래처', width: '90', header: { text: '거래처' }, autoFilter: true, styleName: 'edit tl' },
    { name: '유통구조', fieldName: '유통구조', width: '120', header: { text: '유통구조' }, autoFilter: true, styleName: 'edit tl' },
    { name: '거래처번호', fieldName: '거래처번호', width: '150', header: { text: '거래처번호' }, autoFilter: true, styleName: 'edit tl' },
    { name: '중개인', fieldName: '중개인', width: '90', header: { text: '중개인' }, autoFilter: true, styleName: 'edit tl' },
    { name: '납품장소', fieldName: '납품장소', width: '120', header: { text: '납품장소' }, autoFilter: true, styleName: 'edit tl' },
    { name: '인도조건', fieldName: '인도조건', width: '120', header: { text: '인도조건' }, autoFilter: true, styleName: 'edit tl' },
    { name: '판매후보관', fieldName: '판매후보관', width: '150', header: { text: '판매후보관' }, autoFilter: true, styleName: 'edit tl' },
    { name: '위탁', fieldName: '위탁', width: '80', header: { text: '위탁' }, autoFilter: true, styleName: 'edit tl' },
    { name: '납품거래처', fieldName: '납품거래처', width: '150', header: { text: '납품거래처' }, autoFilter: true, styleName: 'edit tl' },
    { name: '납기일', fieldName: '납기일', width: '90', header: { text: '납기일' }, autoFilter: true, styleName: 'edit tl' },
    { name: '품명', fieldName: '품명', width: '80', header: { text: '품명' }, autoFilter: true, styleName: 'edit tl' },
    { name: '품번', fieldName: '품번', width: '80', header: { text: '품번' }, autoFilter: true, styleName: 'edit tl' },
    { name: '규격', fieldName: '규격', width: '80', header: { text: '규격' }, autoFilter: true, styleName: 'edit tl' },
    { name: '판매단위', fieldName: '판매단위', width: '120', header: { text: '판매단위' }, autoFilter: true, styleName: 'edit tl' },
    { name: '판매기준가', fieldName: '판매기준가', width: '150', header: { text: '판매기준가' }, autoFilter: true, styleName: 'edit tr', numberFormat: '#,##0.##' },
    { name: '수량', fieldName: '수량', width: '80', header: { text: '수량' }, autoFilter: true, styleName: 'edit tr', numberFormat: '#,##0.##' },
    { name: '부가세포함', fieldName: '부가세포함', width: '150', header: { text: '부가세포함' }, autoFilter: true, styleName: 'edit tl' },
    { name: '통화', fieldName: '통화', width: '80', header: { text: '통화' }, autoFilter: true, styleName: 'edit tl' },
    { name: '환율', fieldName: '환율', width: '80', header: { text: '환율' }, autoFilter: true, styleName: 'edit tr', numberFormat: '#,##0.##' },
    { name: '판매단가', fieldName: '판매단가', width: '120', header: { text: '판매단가' }, autoFilter: true, styleName: 'edit tr', numberFormat: '#,##0.##' },
    { name: '판매금액', fieldName: '판매금액', width: '120', header: { text: '판매금액' }, autoFilter: true, styleName: 'edit tr', numberFormat: '#,##0.##' },
    { name: '부가세액', fieldName: '부가세액', width: '120', header: { text: '부가세액' }, autoFilter: true, styleName: 'edit tr', numberFormat: '#,##0.##' },
    { name: '판매금액계', fieldName: '판매금액계', width: '150', header: { text: '판매금액계' }, autoFilter: true, styleName: 'edit tr', numberFormat: '#,##0.##' },
    { name: '원화판매금액', fieldName: '원화판매금액', width: '180', header: { text: '원화판매금액' }, autoFilter: true, styleName: 'edit tr', numberFormat: '#,##0.##' },
    { name: '원화부가세액', fieldName: '원화부가세액', width: '180', header: { text: '원화부가세액' }, autoFilter: true, styleName: 'edit tr', numberFormat: '#,##0.##' },
    { name: '원화판매금액계', fieldName: '원화판매금액계', width: '210', header: { text: '원화판매금액계' }, autoFilter: true, styleName: 'edit tr', numberFormat: '#,##0.##' },
    { name: '창고', fieldName: '창고', width: '80', header: { text: '창고' }, autoFilter: true, styleName: 'edit tl' },
    { name: '보관위치', fieldName: '보관위치', width: '120', header: { text: '보관위치' }, autoFilter: true, styleName: 'edit tl' },
    { name: 'lotNo', fieldName: 'lotNo', width: '80', header: { text: 'Lot_No' }, autoFilter: true, styleName: 'edit tl' },
    { name: '세금계산서진행상태', fieldName: '세금계산서진행상태', width: '280', header: { text: '세금계산서_진행상태' }, autoFilter: true, styleName: 'edit tl' },
    { name: '배송상태', fieldName: '배송상태', width: '120', header: { text: '배송상태' }, autoFilter: true, styleName: 'edit tl' },
    { name: '품목특이사항', fieldName: '품목특이사항', width: '180', header: { text: '품목특이사항' }, autoFilter: true, styleName: 'edit tl' },
    { name: '매출시점', fieldName: '매출시점', width: '120', header: { text: '매출시점' }, autoFilter: true, styleName: 'edit tl' },
    { name: '진행조회', fieldName: '진행조회', width: '120', header: { text: '진행조회' }, autoFilter: true, styleName: 'edit tl' },
    { name: '원천조회', fieldName: '원천조회', width: '120', header: { text: '원천조회' }, autoFilter: true, styleName: 'edit tl' },
    { name: '원천관리번호', fieldName: '원천관리번호', width: '180', header: { text: '원천관리번호' }, autoFilter: true, styleName: 'edit tl' },
    { name: '원천번호', fieldName: '원천번호', width: '120', header: { text: '원천번호' }, autoFilter: true, styleName: 'edit tl' },
    { name: 'poNo', fieldName: 'poNo', width: '80', header: { text: 'PO_No' }, autoFilter: true, styleName: 'edit tl' },
    { name: '반품', fieldName: '반품', width: '80', header: { text: '반품' }, autoFilter: true, styleName: 'edit tl' },
    { name: '매출수량', fieldName: '매출수량', width: '120', header: { text: '매출수량' }, autoFilter: true, styleName: 'edit tr', numberFormat: '#,##0' },
    { name: '매출금액계', fieldName: '매출금액계', width: '150', header: { text: '매출금액계' }, autoFilter: true, styleName: 'edit tr', numberFormat: '#,##0' },
    { name: '미매출금액', fieldName: '미매출금액', width: '150', header: { text: '미매출금액' }, autoFilter: true, styleName: 'edit tr', numberFormat: '#,##0' },
    { name: '세금계산서금액계', fieldName: '세금계산서금액계', width: '240', header: { text: '세금계산서금액계' }, autoFilter: true, styleName: 'edit tr', numberFormat: '#,##0' },
    { name: '계산서미발행액', fieldName: '계산서미발행액', width: '210', header: { text: '계산서미발행액' }, autoFilter: true, styleName: 'edit tr', numberFormat: '#,##0' },
    { name: '계산서미발행수량', fieldName: '계산서미발행수량', width: '240', header: { text: '계산서미발행수량' }, autoFilter: true, styleName: 'edit tr', numberFormat: '#,##0' },
    { name: '기타출고구분', fieldName: '기타출고구분', width: '180', header: { text: '기타출고구분' }, autoFilter: true, styleName: 'edit tl' },
    { name: '품목자산분류', fieldName: '품목자산분류', width: '180', header: { text: '품목자산분류' }, autoFilter: true, styleName: 'edit tl' },
    { name: '단가소급여부', fieldName: '단가소급여부', width: '180', header: { text: '단가소급여부' }, autoFilter: true, styleName: 'edit tl' },
    { name: '수량(단가소급)', fieldName: '수량(단가소급)', width: '220', header: { text: '수량(단가소급)' }, autoFilter: true, styleName: 'edit tr', numberFormat: '#,##0' },
    { name: '유상사급여부', fieldName: '유상사급여부', width: '180', header: { text: '유상사급여부' }, autoFilter: true, styleName: 'edit tl' },
  ],
};

module.exports = grid;
