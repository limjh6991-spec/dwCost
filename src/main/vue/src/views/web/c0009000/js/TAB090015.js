/**
 * TAB090015 - 월별 집계(수량_VN) : 제품 수불부 (VINA 전용)
 * 헤더: 기초(T_BOH) / 입고(USC_INPUT) / 기타입고 / 출고(OUTPUT_A) / 기타출고 / LOSS / 재고(EOH)
 * 기초·재고는 PFL전(50%)/PFL후(90%) 2열. 기타입고/기타출고/재고 그룹은 +/- 여닫기(expandable).
 *
 * 필드명은 CamelMap(DB컬럼 T_BOH_B → tBohB) 규칙에 맞춘 camelCase.
 * 데이터 프로시저 기대 컬럼(예): T_BOH_B/T_BOH_A, USC_INPUT, IN_CODE ... TOTAL_EOH_B/TOTAL_EOH_A
 */

const NUM = { numberFormat: '#,##0', styleName: 'tr', footer: { expression: 'sum', numberFormat: '#,##0' } };
const numCol = (name, text, extra = {}) => ({ name, fieldName: name, type: 'data', width: '90', header: { text }, ...NUM, ...extra });

// PFL전/후 2열 헤더 그룹 (base: tBoh → tBohB/tBohA)
const pflGroup = (base, headerText) => ({
  name: `grp_${base}`,
  direction: 'horizontal',
  header: { text: headerText },
  items: [
    { column: `${base}B`, header: { text: 'PFL전 50%' } },
    { column: `${base}A`, header: { text: 'PFL후 90%' } },
  ],
});

const tab090015GridField = {
  fields: [
    { fieldName: 'model', dataType: 'text' },
    { fieldName: 'division', dataType: 'text' },
    { fieldName: 'bohLineWipB', dataType: 'number' }, { fieldName: 'bohLineWipA', dataType: 'number' },
    { fieldName: 'bohLineFgsB', dataType: 'number' }, { fieldName: 'bohLineFgsA', dataType: 'number' },
    { fieldName: 'bohASubB', dataType: 'number' },    { fieldName: 'bohASubA', dataType: 'number' },
    { fieldName: 'bohBWipB', dataType: 'number' },    { fieldName: 'bohBWipA', dataType: 'number' },
    { fieldName: 'bohBFgsB', dataType: 'number' },    { fieldName: 'bohBFgsA', dataType: 'number' },
    { fieldName: 'bohBSubB', dataType: 'number' },    { fieldName: 'bohBSubA', dataType: 'number' },
    { fieldName: 'tBohB', dataType: 'number' }, { fieldName: 'tBohA', dataType: 'number' },
    { fieldName: 'uscInput', dataType: 'number' },
    { fieldName: 'inCode', dataType: 'number' },
    { fieldName: 'inResort', dataType: 'number' },
    { fieldName: 'inRework', dataType: 'number' },
    { fieldName: 'inSemi', dataType: 'number' },
    { fieldName: 'inEtc', dataType: 'number' },
    { fieldName: 'inTotal', dataType: 'number' },
    { fieldName: 'outputA', dataType: 'number' },
    { fieldName: 'outCodeB', dataType: 'number' },     { fieldName: 'outCodeA', dataType: 'number' },
    { fieldName: 'outSemiPaidB', dataType: 'number' }, { fieldName: 'outSemiPaidA', dataType: 'number' },
    { fieldName: 'outSemiFreeB', dataType: 'number' }, { fieldName: 'outSemiFreeA', dataType: 'number' },
    { fieldName: 'outEtcB', dataType: 'number' },      { fieldName: 'outEtcA', dataType: 'number' },
    { fieldName: 'outTotalB', dataType: 'number' },    { fieldName: 'outTotalA', dataType: 'number' },
    { fieldName: 'lossB', dataType: 'number' }, { fieldName: 'lossA', dataType: 'number' }, { fieldName: 'lossT', dataType: 'number' },
    { fieldName: 'lineWipB', dataType: 'number' }, { fieldName: 'lineWipA', dataType: 'number' },
    { fieldName: 'lineFgsB', dataType: 'number' }, { fieldName: 'lineFgsA', dataType: 'number' },
    { fieldName: 'bWipB', dataType: 'number' },    { fieldName: 'bWipA', dataType: 'number' },
    { fieldName: 'bFgsB', dataType: 'number' },    { fieldName: 'bFgsA', dataType: 'number' },
    { fieldName: 'tEohWipB', dataType: 'number' }, { fieldName: 'tEohWipA', dataType: 'number' },
    { fieldName: 'tEohFgsB', dataType: 'number' }, { fieldName: 'tEohFgsA', dataType: 'number' },
    { fieldName: 'totalEohB', dataType: 'number' }, { fieldName: 'totalEohA', dataType: 'number' },
  ],
  columns: [
    { name: 'model', fieldName: 'model', type: 'data', width: '110', header: { text: '모델' }, styleName: 'left-column', autoFilter: true },
    { name: 'division', fieldName: 'division', type: 'data', width: '80', header: { text: '구분' }, styleName: 'center-column', autoFilter: true },
    numCol('bohLineWipB', 'PFL전 50%'), numCol('bohLineWipA', 'PFL후 90%'),
    numCol('bohLineFgsB', 'PFL전 50%'), numCol('bohLineFgsA', 'PFL후 90%'),
    numCol('bohASubB', 'PFL전 50%'),    numCol('bohASubA', 'PFL후 90%'),
    numCol('bohBWipB', 'PFL전 50%'),    numCol('bohBWipA', 'PFL후 90%'),
    numCol('bohBFgsB', 'PFL전 50%'),    numCol('bohBFgsA', 'PFL후 90%'),
    numCol('bohBSubB', 'PFL전 50%'),    numCol('bohBSubA', 'PFL후 90%'),
    numCol('tBohB', 'PFL전 50%'), numCol('tBohA', 'PFL후 90%'),
    numCol('uscInput', 'USC_INPUT'),
    numCol('inCode', 'CODE 변경'),
    numCol('inResort', 'Re-Sorting(재검사)', { width: '120' }),
    numCol('inRework', 'Re-work(재보완)', { width: '120' }),
    numCol('inSemi', '반제품 입고', { width: '100' }),
    numCol('inEtc', '기타'),
    numCol('inTotal', '기타입고', { width: '100' }),
    numCol('outputA', 'OUTPUT_A'),
    numCol('outCodeB', 'PFL전 50%'), numCol('outCodeA', 'PFL후 90%'),
    numCol('outSemiPaidB', 'PFL전 50%'), numCol('outSemiPaidA', 'PFL후 90%'),
    numCol('outSemiFreeB', 'PFL전 50%'), numCol('outSemiFreeA', 'PFL후 90%'),
    numCol('outEtcB', 'PFL전 50%'), numCol('outEtcA', 'PFL후 90%'),
    numCol('outTotalB', 'PFL전 50%'), numCol('outTotalA', 'PFL후 90%'),
    numCol('lossB', 'PFL전 50%'), numCol('lossA', 'PFL후 90%'), numCol('lossT', '합계'),
    numCol('lineWipB', 'PFL전 50%'), numCol('lineWipA', 'PFL후 90%'),
    numCol('lineFgsB', 'PFL전 50%'), numCol('lineFgsA', 'PFL후 90%'),
    numCol('bWipB', 'PFL전 50%'), numCol('bWipA', 'PFL후 90%'),
    numCol('bFgsB', 'PFL전 50%'), numCol('bFgsA', 'PFL후 90%'),
    numCol('tEohWipB', 'PFL전 50%'), numCol('tEohWipA', 'PFL후 90%'),
    numCol('tEohFgsB', 'PFL전 50%'), numCol('tEohFgsA', 'PFL후 90%'),
    numCol('totalEohB', 'PFL전 50%'), numCol('totalEohA', 'PFL후 90%'),
  ],
  layout: [
    'model',
    'division',
    {
      name: 'grpBoh',
      direction: 'horizontal',
      header: { text: '기초 / BOH (7=1+2+4+5)' },
      expandable: true,
      expanded: false,
      items: [
        { ...pflGroup('bohLineWip', '1. LINE_WIP'), groupShowMode: 'expand' },
        { ...pflGroup('bohLineFgs', '2. LINE_FGS'), groupShowMode: 'expand' },
        { ...pflGroup('bohASub', '3=1+2. BOH A LEVEL SUB TOTAL'), groupShowMode: 'expand' },
        { ...pflGroup('bohBWip', '4. B_LEVEL_WIP'), groupShowMode: 'expand' },
        { ...pflGroup('bohBFgs', '5. B_LEVEL_FGS'), groupShowMode: 'expand' },
        { ...pflGroup('bohBSub', '6=4+5. BOH B LEVEL SUB TOTAL'), groupShowMode: 'expand' },
        { ...pflGroup('tBoh', '7=1+2+4+5. T_BOH'), groupShowMode: 'always' },
      ],
    },
    { name: 'grpInput', direction: 'horizontal', header: { text: '입고 / INPUT' }, items: ['uscInput'] },
    {
      name: 'grpOtherInput',
      direction: 'horizontal',
      header: { text: '기타입고 / Other Input' },
      expandable: true,
      expanded: false,
      items: [
        { column: 'inCode', groupShowMode: 'expand' },
        { column: 'inResort', groupShowMode: 'expand' },
        { column: 'inRework', groupShowMode: 'expand' },
        { column: 'inSemi', groupShowMode: 'expand' },
        { column: 'inEtc', groupShowMode: 'expand' },
        { column: 'inTotal', groupShowMode: 'always' },
      ],
    },
    { name: 'grpOutput', direction: 'horizontal', header: { text: '출고 / OUTPUT' }, items: ['outputA'] },
    {
      name: 'grpOtherOutput',
      direction: 'horizontal',
      header: { text: '기타출고 / Other Output' },
      expandable: true,
      expanded: false,
      items: [
        { ...pflGroup('outCode', 'CODE 변경'), groupShowMode: 'expand' },
        { ...pflGroup('outSemiPaid', '반제품 출고 (유상)'), groupShowMode: 'expand' },
        { ...pflGroup('outSemiFree', '반제품 출고 (무상)'), groupShowMode: 'expand' },
        { ...pflGroup('outEtc', '기타'), groupShowMode: 'expand' },
        { ...pflGroup('outTotal', '기타출고 (5=1+2+3+4)'), groupShowMode: 'always' },
      ],
    },
    {
      name: 'grp_loss',
      direction: 'horizontal',
      header: { text: 'LOSS / SCRAP' },
      items: [
        { column: 'lossB', header: { text: 'PFL전 50%' } },
        { column: 'lossA', header: { text: 'PFL후 90%' } },
        { column: 'lossT', header: { text: '합계' } },
      ],
    },
    {
      name: 'grpEoh',
      direction: 'horizontal',
      header: { text: '재고 / EOH' },
      expandable: true,
      expanded: false,
      items: [
        { ...pflGroup('lineWip', 'LINE_WIP (A)'), groupShowMode: 'expand' },
        { ...pflGroup('lineFgs', 'LINE_FGs (A)'), groupShowMode: 'expand' },
        { ...pflGroup('bWip', 'B_LEVEL WIP (A)'), groupShowMode: 'expand' },
        { ...pflGroup('bFgs', 'B_LEVEL FGs (A)'), groupShowMode: 'expand' },
        { ...pflGroup('tEohWip', 'T_EOH WIP (1+3)'), groupShowMode: 'expand' },
        { ...pflGroup('tEohFgs', 'T_EOH FGs (2+4)'), groupShowMode: 'expand' },
        { ...pflGroup('totalEoh', 'TOTAL_EOH (MES) (7=5+6)'), groupShowMode: 'always' },
      ],
    },
  ],
  options: {
    edit: { editable: false },
    display: { fitStyle: 'even' },
    footer: { visible: true },
    header: { height: 60 },
    fixed: { colCount: 2 },    
    emptyMessage: '조회된 데이터가 없습니다.',    
    hscrollBar: true,
  },
};

export default tab090015GridField;
