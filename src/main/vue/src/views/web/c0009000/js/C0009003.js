/*
 * 판매 실적 집계
 *  - 고정(선두) 컬럼 레이아웃은 site별로 분기한다.
 *    · HQ(본사): 도우코드, 구분, inch, SET업체, 고객코드, 제품구조 (6컬럼 고정)
 *    · VN      : 구분, 모델명, SET업체, 고객코드, 도우코드, 두께, inch, 제품구조 (8컬럼 고정, 기존 유지)
 *  - fields/columns 는 두 레이아웃의 합집합(superset)으로 정의하고, columnLayout 과 fixed.colCount 로만 분기.
 *    (레이아웃에서 빠진 컬럼은 화면에 표시되지 않음 → prodCtg 전환 시 setColumnLayout/setFixedOptions 로 동적 전환)
 */

const { ValueType } = require('realgrid');

// 공통 꼬리 레이아웃: 매출계획 이후(월별 수량/금액/판매단가) — HQ/VN 공용
const tailLayout = [
  { column: '매출계획' },
  { column: '계획대비실적' },
  { name: 'grp1월',  header: { text: '1월' },  direction: 'horizontal', items: [{ column: 'qty1' },  { column: 'amt1' },  { column: 'price1' }] },
  { name: 'grp2월',  header: { text: '2월' },  direction: 'horizontal', items: [{ column: 'qty2' },  { column: 'amt2' },  { column: 'price2' }] },
  { name: 'grp3월',  header: { text: '3월' },  direction: 'horizontal', items: [{ column: 'qty3' },  { column: 'amt3' },  { column: 'price3' }] },
  { name: 'grp4월',  header: { text: '4월' },  direction: 'horizontal', items: [{ column: 'qty4' },  { column: 'amt4' },  { column: 'price4' }] },
  { name: 'grp5월',  header: { text: '5월' },  direction: 'horizontal', items: [{ column: 'qty5' },  { column: 'amt5' },  { column: 'price5' }] },
  { name: 'grp6월',  header: { text: '6월' },  direction: 'horizontal', items: [{ column: 'qty6' },  { column: 'amt6' },  { column: 'price6' }] },
  { name: 'grp7월',  header: { text: '7월' },  direction: 'horizontal', items: [{ column: 'qty7' },  { column: 'amt7' },  { column: 'price7' }] },
  { name: 'grp8월',  header: { text: '8월' },  direction: 'horizontal', items: [{ column: 'qty8' },  { column: 'amt8' },  { column: 'price8' }] },
  { name: 'grp9월',  header: { text: '9월' },  direction: 'horizontal', items: [{ column: 'qty9' },  { column: 'amt9' },  { column: 'price9' }] },
  { name: 'grp10월', header: { text: '10월' }, direction: 'horizontal', items: [{ column: 'qty10' }, { column: 'amt10' }, { column: 'price10' }] },
  { name: 'grp11월', header: { text: '11월' }, direction: 'horizontal', items: [{ column: 'qty11' }, { column: 'amt11' }, { column: 'price11' }] },
  { name: 'grp12월', header: { text: '12월' }, direction: 'horizontal', items: [{ column: 'qty12' }, { column: 'amt12' }, { column: 'price12' }] },
];

// HQ(본사): 도우코드, 구분, inch, SET업체, 고객코드, 제품구조 (6컬럼)
const columnLayoutHQ = [
  { column: '도우코드' },
  { column: '구분' },
  { column: 'inch' },
  { column: 'set업체' },
  { column: '고객코드' },
  { column: '제품구조' },
  ...tailLayout,
];

// VN: 구분, 모델명, SET업체, 고객코드, 도우코드, 두께, inch, 제품구조 (8컬럼, 기존 유지)
const columnLayoutVN = [
  { column: '구분' },
  { column: '모델명' },
  { column: 'set업체' },
  { column: '고객코드' },
  { column: '도우코드' },
  { column: '두께' },
  { column: 'inch' },
  { column: '제품구조' },
  ...tailLayout,
];

const grid = {
  options: {
    checkBar: { visible: false },
    copy: { enabled: true, singleMode: true },
    display: {
      columnMovable: false,
      editItemMerging: true,
      fitStyle: 'even',
      emptyMessage: '조회된 데이터가 없습니다.',
      hscrollBar: true,
      showEmptyMessage: true,
      headerDepth: 2,
    },
    edit: { editable: false },
    footer: { visible: true },
    paste: { enabled: false },
    rowIndicator: { visible: true },
    sorting: { enabled: true },
    stateBar: { visible: false },
    filtering: { enabled: true },
    fixed: { colBarWidth: 1, colCount: 6 },   // 기본 HQ(6). VN은 .vue 에서 8로 분기
  },
  // fields: HQ/VN 합집합 (모델명/두께 포함)
  fields: [
    { fieldName: '도우코드',  dataType: ValueType.TEXT },
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: '모델명', dataType: ValueType.TEXT },
    { fieldName: '두께',   dataType: ValueType.TEXT },
    { fieldName: 'inch',   dataType: ValueType.TEXT },
    { fieldName: 'set업체',  dataType: ValueType.TEXT },
    { fieldName: '고객코드',  dataType: ValueType.TEXT },
    { fieldName: '제품구조',  dataType: ValueType.TEXT },
    { fieldName: '매출계획',  dataType: ValueType.NUMBER },
    { fieldName: '계획대비실적',  dataType: ValueType.NUMBER },
    { fieldName: 'qty1',  dataType: ValueType.NUMBER },
    { fieldName: 'amt1',  dataType: ValueType.NUMBER },
    { fieldName: 'price1',  dataType: ValueType.NUMBER },
    { fieldName: 'qty2',  dataType: ValueType.NUMBER },
    { fieldName: 'amt2',  dataType: ValueType.NUMBER },
    { fieldName: 'price2',  dataType: ValueType.NUMBER },
    { fieldName: 'qty3',  dataType: ValueType.NUMBER },
    { fieldName: 'amt3',  dataType: ValueType.NUMBER },
    { fieldName: 'price3',  dataType: ValueType.NUMBER },
    { fieldName: 'qty4',  dataType: ValueType.NUMBER },
    { fieldName: 'amt4',  dataType: ValueType.NUMBER },
    { fieldName: 'price4',  dataType: ValueType.NUMBER },
    { fieldName: 'qty5',  dataType: ValueType.NUMBER },
    { fieldName: 'amt5',  dataType: ValueType.NUMBER },
    { fieldName: 'price5',  dataType: ValueType.NUMBER },
    { fieldName: 'qty6',  dataType: ValueType.NUMBER },
    { fieldName: 'amt6',  dataType: ValueType.NUMBER },
    { fieldName: 'price6',  dataType: ValueType.NUMBER },
    { fieldName: 'qty7',  dataType: ValueType.NUMBER },
    { fieldName: 'amt7',  dataType: ValueType.NUMBER },
    { fieldName: 'price7',  dataType: ValueType.NUMBER },
    { fieldName: 'qty8',  dataType: ValueType.NUMBER },
    { fieldName: 'amt8',  dataType: ValueType.NUMBER },
    { fieldName: 'price8',  dataType: ValueType.NUMBER },
    { fieldName: 'qty9',  dataType: ValueType.NUMBER },
    { fieldName: 'amt9',  dataType: ValueType.NUMBER },
    { fieldName: 'price9',  dataType: ValueType.NUMBER },
    { fieldName: 'qty10',  dataType: ValueType.NUMBER },
    { fieldName: 'amt10',  dataType: ValueType.NUMBER },
    { fieldName: 'price10',  dataType: ValueType.NUMBER },
    { fieldName: 'qty11',  dataType: ValueType.NUMBER },
    { fieldName: 'amt11',  dataType: ValueType.NUMBER },
    { fieldName: 'price11',  dataType: ValueType.NUMBER },
    { fieldName: 'qty12',  dataType: ValueType.NUMBER },
    { fieldName: 'amt12',  dataType: ValueType.NUMBER },
    { fieldName: 'price12',  dataType: ValueType.NUMBER },
  ],
  // 기본 레이아웃 = HQ. .vue initializeGrid 에서 site에 맞게 columnLayoutHQ/VN 으로 치환
  columnLayout: columnLayoutHQ,
  columnLayoutHQ,
  columnLayoutVN,
  columns: [
    { name: '도우코드',      fieldName: '도우코드',      width: 140, header: { text: '도우코드' }, autoFilter: true, styleName: 'tc' },
    { name: '구분', fieldName: '구분', width:60, header: { text: '구분' }, autoFilter: true, styleName: 'tc' },
    { name: '모델명', fieldName: '모델명', width: 80, header: { text: '모델명' }, autoFilter: true, styleName: 'tc' },
    { name: '두께',    fieldName: '두께',    width: 100, header: { text: '두께' }, autoFilter: true, styleName: 'tr' },
    { name: 'inch',   fieldName: 'inch',   width: 80, header: { text: 'inch' }, autoFilter: true, styleName: 'tr' },
    { name: 'set업체', fieldName: 'set업체', width: 80, header: { text: 'SET업체' }, autoFilter: true, styleName: 'tc' },
    { name: '고객코드', fieldName: '고객코드', width: 140, header: { text: '고객코드' }, autoFilter: true, styleName: 'tc', minWidth: 140, maxWidth: 140, },
    { name: '제품구조',   fieldName: '제품구조',   width: 90, header: { text: '제품구조' }, autoFilter: true, styleName: 'tc' },
    { name: '매출계획',  fieldName: '매출계획',  width: 120, header: { text: '매출계획' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: '계획대비실적',  fieldName: '계획대비실적',  width: 120, header: { text: '계획대비실적' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'qty1',  fieldName: 'qty1',  width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'amt1',  fieldName: 'amt1',  width: 120, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'price1',  fieldName: 'price1',  width: 90, header: { text: '판매단가' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'qty2',  fieldName: 'qty2',  width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'amt2',  fieldName: 'amt2',  width: 120, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'price2',  fieldName: 'price2',  width: 90, header: { text: '판매단가' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'qty3',  fieldName: 'qty3',  width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'amt3',  fieldName: 'amt3',  width: 120, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'price3',  fieldName: 'price3',  width: 90, header: { text: '판매단가' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'qty4',  fieldName: 'qty4',  width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'amt4',  fieldName: 'amt4',  width: 120, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'price4',  fieldName: 'price4',  width: 90, header: { text: '판매단가' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'qty5',  fieldName: 'qty5',  width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'amt5',  fieldName: 'amt5',  width: 120, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'price5',  fieldName: 'price5',  width: 90, header: { text: '판매단가' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'qty6',  fieldName: 'qty6',  width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'amt6',  fieldName: 'amt6',  width: 120, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'price6',  fieldName: 'price6',  width: 90, header: { text: '판매단가' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'qty7',  fieldName: 'qty7',  width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'amt7',  fieldName: 'amt7',  width: 120, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'price7',  fieldName: 'price7',  width: 90, header: { text: '판매단가' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'qty8',  fieldName: 'qty8',  width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'amt8',  fieldName: 'amt8',  width: 120, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'price8',  fieldName: 'price8',  width: 90, header: { text: '판매단가' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'qty9',  fieldName: 'qty9',  width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'amt9',  fieldName: 'amt9',  width: 120, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'price9',  fieldName: 'price9',  width: 90, header: { text: '판매단가' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'qty10',  fieldName: 'qty10',  width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'amt10',  fieldName: 'amt10',  width: 120, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'price10',  fieldName: 'price10',  width: 90, header: { text: '판매단가' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'qty11',  fieldName: 'qty11',  width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'amt11',  fieldName: 'amt11',  width: 120, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'price11',  fieldName: 'price11',  width: 90, header: { text: '판매단가' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'qty12',  fieldName: 'qty12',  width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'amt12',  fieldName: 'amt12',  width: 120, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0', footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", } },
    { name: 'price12',  fieldName: 'price12',  width: 90, header: { text: '판매단가' }, styleName: 'tr', numberFormat: '#,##0' },
  ],
};

grid.currencyFields = ['amt1','amt2','amt3','amt4','amt5','amt6','amt7','amt8','amt9','amt10','amt11','amt12','매출계획'];

module.exports = grid;
