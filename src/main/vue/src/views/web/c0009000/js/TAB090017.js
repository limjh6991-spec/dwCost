/*
 * 제조원가(재공)_VN - 재공품 공정 수불(생산실적 TAB090015 구조) + 항목별 금액, 도우코드 그레인
 * 위치: C0009007 재공,제품 원가 > 제조원가(재공) 과 매출원가(제품) 사이 (VINA 전용)
 * 레이아웃:
 *   기초/BOH (LINE_WIP·LINE_FGs·A LEVEL SUB·B_LEVEL_WIP·B_LEVEL_FGs·B LEVEL SUB·T_BOH, 각 PFL전50%/PFL후90% × 수량·금액)
 *   | 입고(USC_INPUT) | 기타입고(CODE변경·Re-Sorting·Re-work·반제품입고·기타·합계)
 *   | 출고(OUTPUT_A) | 기타출고(CODE변경·반제품출고 유상/무상·기타·합계)
 *   | LOSS(SCRAP)
 *   | 재고/EOH (LINE_WIP·LINE_FGs·B_LEVEL WIP·B_LEVEL FGs·T_EOH WIP·T_EOH FGs·TOTAL_EOH, 각 PFL전50%/PFL후90% × 수량·금액)
 *  - BOH/기타입고/기타출고/EOH 그룹은 +/- 여닫기, 합계열은 항상표시(always).
 *  - 데이터 산식(수량/금액)은 추후 정의(현재 스텁). 프로시저: VN_WipCostLedger_Subul
 */

const { ValueType } = require('realgrid');


// RealGrid는 같은 그룹 트리에 빈 spacer 노드가 있으면 빈 셀까지 병합해버린다.
// 따라서 실제 데이터가 있는 헤더만 그룹에 남기고, 빈 여백은 아예 그룹 구조에서 제거한다.
const pflGroup = (base, text, showMode) => {
  const g = {
    name: `grp_${base}`,
    header: { text },
    direction: 'horizontal',
    items: [
      { name: `${base}_b`, header: { text: 'PFL전 50%' }, direction: 'horizontal', items: [{ column: `${base}BQty` }, { column: `${base}BAmt` }] },
      { name: `${base}_a`, header: { text: 'PFL후 90%' }, direction: 'horizontal', items: [{ column: `${base}AQty` }, { column: `${base}AAmt` }] },
    ],
  };
  if (showMode) g.groupShowMode = showMode;
  return g;
};

const qaGroup = (base, text, showMode) => {
  const g = {
    name: `grp_${base}`,
    header: { text },
    direction: 'horizontal',
    items: [{ column: `${base}Qty` }, { column: `${base}Amt` }],
  };
  if (showMode) g.groupShowMode = showMode;
  return g;
};

// PFL 항목: [base, headerText]
const BOH = [
  ['bohLineWip', '1. LINE_WIP'],
  ['bohLineFgs', '2. LINE_FGS'],
  ['bohASub', '3=1+2. BOH A LEVEL SUB TOTAL'],
  ['bohBWip', '4. B_LEVEL_WIP'],
  ['bohBFgs', '5. B_LEVEL_FGS'],
  ['bohBSub', '6=4+5. BOH B LEVEL SUB TOTAL'],
];
const BOH_TOTAL = ['tBoh', '7=3+6. T_BOH'];

const EOH = [
  ['eohLineWip', '1. LINE_WIP (A)'],
  ['eohLineFgs', '2. LINE_FGS (A)'],
  ['eohBWip', '3. B_LEVEL WIP (A)'],
  ['eohBFgs', '4. B_LEVEL FGS'],
  ['eohTWip', '5(1+3). T_EOH WIP'],
  ['eohTFgs', '6(2+4). T_EOH FGS'],
];
const EOH_TOTAL = ['totalEoh', '7=5+6. TOTAL_EOH (MES)'];

// 수량/금액 항목
const IN_ETC = [
  ['inCode', '1. CODE 변경'],
  ['inResort', '2. Re-Sorting(재검사)'],
  ['inRework', '3. Re-work(SI검사)'],
  ['inSemi', '4. 반제품 입고'],
  ['inEtc', '5. 기타'],
];
const OUT_ETC = [
  ['outCode', '1. CODE 변경'],
  ['outSemiPaid', '2. 반제품 출고(유상)'],
  ['outSemiFree', '3. 반제품 출고(무상)'],
  ['outEtc', '4. 기타'],
];
const OUT_TOTAL = ['outTotal', '기타출고 (5=1+2+3+4)'];

// ===== 필드/컬럼 생성 =====
const pflFields = (base) => ([
  { fieldName: `${base}BQty`, dataType: ValueType.NUMBER },
  { fieldName: `${base}BAmt`, dataType: ValueType.NUMBER },
  { fieldName: `${base}AQty`, dataType: ValueType.NUMBER },
  { fieldName: `${base}AAmt`, dataType: ValueType.NUMBER },
]);
const qaFields = (base) => ([
  { fieldName: `${base}Qty`, dataType: ValueType.NUMBER },
  { fieldName: `${base}Amt`, dataType: ValueType.NUMBER },
]);

const numCol = (name) => ({ name, fieldName: name, width: 70, header: { text: /Amt$/.test(name) ? '금액' : '수량' }, styleName: 'tr', numberFormat: '#,##0' });
const pflCols = (base) => ([numCol(`${base}BQty`), numCol(`${base}BAmt`), numCol(`${base}AQty`), numCol(`${base}AAmt`)]);
const qaCols = (base) => ([numCol(`${base}Qty`), numCol(`${base}Amt`)]);

const ALL_PFL = [...BOH, BOH_TOTAL, ...OUT_ETC, OUT_TOTAL, ...EOH, EOH_TOTAL];
const ALL_QA = [['uscInput'], ...IN_ETC, ['inTotal'], ['outputA'], ['loss']];

const grid = {
  options: {
    edit: { editable: false },
    display: {
      columnMovable: false,
      editItemMerging: false,
      fitStyle: 'even',
      emptyMessage: '조회된 데이터가 없습니다.',
      hscrollBar: true,
      showEmptyMessage: true,
      headerDepth: 4,
      mergePolicy: 'never',
    },
    footer: { visible: false },
    filtering: { enabled: false },
    header: { height: 80 },
    fixed: { colCount: 2 },
  },

  fields: [
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'division', dataType: ValueType.TEXT },
    ...ALL_PFL.flatMap(([b]) => pflFields(b)),
    ...ALL_QA.flatMap(([b]) => qaFields(b)),
  ],

  columns: [
    { name: 'model', fieldName: 'model', width: 90, header: { text: '모델\nModel' }, styleName: 'tc', autoFilter: true },
    { name: 'division', fieldName: 'division', width: 60, header: { text: '구분\nDivision' }, styleName: 'tc', autoFilter: true },
    ...ALL_PFL.flatMap(([b]) => pflCols(b)),
    ...ALL_QA.flatMap(([b]) => qaCols(b)),
  ],

  layout: [
    { column: 'model' },
    { column: 'division' },
    // 기초 / BOH (expandable)
    {
      name: 'grpBoh',
      header: { text: '기초 / BOH (7=3+6)' },
      direction: 'horizontal',
      expandable: true,
      expanded: false,
      items: [
        ...BOH.map(([b, t]) => pflGroup(b, t, 'expand')),
        pflGroup(BOH_TOTAL[0], BOH_TOTAL[1], 'always'),
      ],
    },
    // 입고 / INPUT
    { name: 'grpInput', header: { text: '입고 / INPUT' }, direction: 'horizontal', items: [qaGroup('uscInput', '1. USC_INPUT (C)')] },
    // 기타입고 (expandable)
    {
      name: 'grpInEtc',
      header: { text: '기타입고 / Other Input' },
      direction: 'horizontal',
      expandable: true,
      expanded: false,
      items: [
        ...IN_ETC.map(([b, t]) => qaGroup(b, t, 'expand')),
        qaGroup('inTotal', '기타입고 (6=1+2+3+4+5)', 'always'),
      ],
    },
    // 출고 / OUTPUT
    { name: 'grpOutput', header: { text: '출고 / OUTPUT' }, direction: 'horizontal', items: [qaGroup('outputA', '1. OUTPUT_A (C)')] },
    // 기타출고 (expandable)
    {
      name: 'grpOutEtc',
      header: { text: '기타출고 / Other Output' },
      direction: 'horizontal',
      expandable: true,
      expanded: false,
      items: [
        ...OUT_ETC.map(([b, t]) => pflGroup(b, t, 'expand')),
        pflGroup(OUT_TOTAL[0], OUT_TOTAL[1], 'always'),
      ],
    },
    // LOSS
    { name: 'grpLoss', header: { text: 'LOSS / SCRAP' }, direction: 'horizontal', items: [qaGroup('loss', 'LOSS(SCRAP)')] },
    // 재고 / EOH (expandable)
    {
      name: 'grpEoh',
      header: { text: '재고 / EOH (7=5+6)' },
      direction: 'horizontal',
      expandable: true,
      expanded: false,
      items: [
        ...EOH.map(([b, t]) => pflGroup(b, t, 'expand')),
        pflGroup(EOH_TOTAL[0], EOH_TOTAL[1], 'always'),
      ],
    },
  ],
};

module.exports = grid;
