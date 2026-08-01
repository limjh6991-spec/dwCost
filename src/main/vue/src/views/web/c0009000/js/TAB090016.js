/*
 * 매출원가(제품)_VN - 완제품창고(WH0006) 수불 + 각 항목 수량/금액, 도우코드 그레인
 * 위치: C0009007 재공,제품 원가 > 매출원가(제품) 다음
 * 레이아웃: 도우코드/모델/구분/BOH | INPUT | 기타입고 | OUTPUT | 기타출고 | LOSS | EOH(WH0006)
 *  - 제품수불부(C0009002_VN)의 수량전용 레이아웃에 항목별 금액 열을 추가한 형태.
 *  - INPUT/기타입고/OUTPUT/기타출고 그룹은 +/- 여닫기(expandable), 합계열은 항상표시(always).
 *  - 데이터 산식(수량/금액)은 추후 정의(현재 스텁). 프로시저: VN_ProductCostLedger_Subul
 */

const { ValueType } = require('realgrid');

// 수량/금액 2열 그룹 (base -> baseQty/baseAmt)
// pad: 최하단(4단) 정렬용 밴드 수. 스페이서 밴드에도 항목 라벨을 넣어 라벨이 위쪽 빈 밴드를
//      세로로 덮고, 수량/금액은 맨 아랫단 1행만 차지하도록 한다.
const qa = (base, text, showMode, pad = 0) => {
  let inner = [{ column: `${base}Qty` }, { column: `${base}Amt` }];
  for (let i = 0; i < pad; i++) {
    inner = [{ name: `grp_${base}_lv${i}`, header: { text: '' }, direction: 'horizontal', items: inner }];
  }
  const g = {
    name: `grp_${base}`,
    header: { text },
    direction: 'horizontal',
    items: inner,
  };
  if (showMode) g.groupShowMode = showMode;
  return g;
};

// Qty/Amt 컬럼 정의 한 쌍 생성
const qaCols = (base, wQty = 60, wAmt = 85) => ([
  { name: `${base}Qty`, fieldName: `${base}Qty`, width: wQty, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: `${base}Amt`, fieldName: `${base}Amt`, width: wAmt, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
]);

// 항목 정의: [base, headerText]
const BASES = [
  ['boh', 'BOH'],
  ['fgLastMonth', '1. LAST-MONTH'],
  ['fgThisMonth', '2. THIS-MONTH'],
  ['backShipSorting', '3. BACK-SHIP(SORTING)'],
  ['backShipPfRw', '4. BACK-SHIP(PF-RW)'],
  ['backShipPlRw', '5. BACK-SHIP(PL-RW)'],
  ['whReturnSorting', '6. WH RETURN(SORTING)'],
  ['whReturnPfRw', '7. WH RETURN(PF-RW)'],
  ['whReturnPlRw', '8. WH RETURN(PL-RW)'],
  ['tInput', 'T_INPUT'],
  ['ieRma', '1. RMA'],
  ['ieReturnPaid', '2. 반제품(유상)'],
  ['ieReturnFree', '3. 반제품(무상)'],
  ['ieOther', '4. 기타'],
  ['ieTotal', '기타입고'],
  ['shipAPaid', 'SHIP(A급) PAID'],
  ['shipBPaid', 'SHIP(B급) PAID'],
  ['tOutput', 'T_OUTPUT'],
  ['oeResorting', '1. Re-Sorting(재검사)'],
  ['oeRework', '2. Re-work(SI검사)'],
  ['oeRma', '3. RMA'],
  ['oeFreeSale', '4. 무상매출'],
  ['oeOther', '5. 기타'],
  ['oeTotal', '기타출고'],
  ['loss', 'LOSS'],
  ['eoh', 'EOH\nWH0006'],
];

const grid = {
  options: {
    edit: { editable: false },
    display: {
      columnMovable: false,
      editItemMerging: true,
      fitStyle: 'even',
      emptyMessage: '조회된 데이터가 없습니다.',
      hscrollBar: true,
      showEmptyMessage: true,
      headerDepth: 4,
      mergePolicy: 'auto',
    },
    footer: { visible: false },
    filtering: { enabled: false },
    fixed: { colCount: 2 },
  },

  fields: [
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'division', dataType: ValueType.TEXT },
    ...BASES.flatMap(([b]) => ([
      { fieldName: `${b}Qty`, dataType: ValueType.NUMBER },
      { fieldName: `${b}Amt`, dataType: ValueType.NUMBER },
    ])),
  ],

  columns: [
    { name: 'model', fieldName: 'model', width: 90, header: { text: '모델\nModel' }, styleName: 'tc', autoFilter: true },
    { name: 'division', fieldName: 'division', width: 60, header: { text: '구분\nDivision' }, styleName: 'tc', autoFilter: true },
    ...BASES.flatMap(([b]) => qaCols(b)),
  ],

  layout: [
    { column: 'model' },
    { column: 'division' },
    qa('boh', 'BOH', null, 2),
    // INPUT (expandable): NORMAL FG INPUT + RW FROM LINE + T_INPUT(합계)
    {
      name: 'grpInput',
      header: { text: 'INPUT' },
      direction: 'horizontal',
      expandable: true,
      expanded: false,
      items: [
        {
          name: 'grpNormalFg',
          header: { text: 'NORMAL FG INPUT' },
          direction: 'horizontal',
          groupShowMode: 'expand',
          items: [qa('fgLastMonth', '1. LAST-MONTH'), qa('fgThisMonth', '2. THIS-MONTH')],
        },
        {
          name: 'grpRwLine',
          header: { text: 'RW FROM LINE → FG WAREHOUSE / REWORK 생산라인 → 완제품 창고 CELL 입고' },
          direction: 'horizontal',
          groupShowMode: 'expand',
          items: [
            qa('backShipSorting', '3. BACK-SHIP(SORTING)'),
            qa('backShipPfRw', '4. BACK-SHIP(PF-RW)'),
            qa('backShipPlRw', '5. BACK-SHIP(PL-RW)'),
            qa('whReturnSorting', '6. WH RETURN(SORTING)'),
            qa('whReturnPfRw', '7. WH RETURN(PF-RW)'),
            qa('whReturnPlRw', '8. WH RETURN(PL-RW)'),
          ],
        },
        qa('tInput', 'T_INPUT (9=1-8)', 'always', 1),
      ],
    },
    // 기타입고 (expandable)
    {
      name: 'grpInEtc',
      header: { text: '기타입고' },
      direction: 'horizontal',
      expandable: true,
      expanded: false,
      items: [
        qa('ieRma', '1. RMA', 'expand', 1),
        qa('ieReturnPaid', '2. 반제품(유상)', 'expand', 1),
        qa('ieReturnFree', '3. 반제품(무상)', 'expand', 1),
        qa('ieOther', '4. 기타', 'expand', 1),
        qa('ieTotal', '기타입고 (5=1+2+3+4)', 'always', 1),
      ],
    },
    // OUTPUT (expandable): SHIP(A급)/SHIP(B급) + T_OUTPUT(합계)
    {
      name: 'grpOutput',
      header: { text: 'OUTPUT' },
      direction: 'horizontal',
      expandable: true,
      expanded: false,
      items: [
        qa('shipAPaid', 'SHIP(A급) PAID', 'expand', 1),
        qa('shipBPaid', 'SHIP(B급) PAID', 'expand', 1),
        qa('tOutput', 'T_OUTPUT (3=1+2)', 'always', 1),
      ],
    },
    // 기타출고 (expandable)
    {
      name: 'grpOutEtc',
      header: { text: '기타출고' },
      direction: 'horizontal',
      expandable: true,
      expanded: false,
      items: [
        qa('oeResorting', '1. Re-Sorting(재검사)', 'expand', 1),
        qa('oeRework', '2. Re-work(SI검사)', 'expand', 1),
        qa('oeRma', '3. RMA', 'expand', 1),
        qa('oeFreeSale', '4. 무상매출', 'expand', 1),
        qa('oeOther', '5. 기타', 'expand', 1),
        qa('oeTotal', '기타출고 (6=1+2+3+4+5)', 'always', 1),
      ],
    },
    qa('loss', 'LOSS', null, 2),
    qa('eoh', 'EOH (WH0006)', null, 2),
  ],
};

module.exports = grid;
