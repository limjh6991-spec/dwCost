/**
 * TAB090015 - 월별 집계(수량_VN) : 제품 수불부 (VINA 전용)
 * 헤더: 기초(T_BOH) / 입고(USC_INPUT) / 기타입고 / 출고(OUTPUT_A) / 기타출고 / LOSS / 재고(EOH)
 * 기초·재고는 PFL전(50%)/PFL후(90%) 2열. 기타입고/기타출고/재고 그룹은 +/- 여닫기(expandable).
 *
 * 필드명은 CamelMap(DB컬럼 T_BOH_B → tBohB) 규칙에 맞춘 camelCase.
 * 데이터 프로시저 기대 컬럼(예): T_BOH_B/T_BOH_A, USC_INPUT, IN_CODE ... TOTAL_EOH_B/TOTAL_EOH_A
 */

const NUM = { numberFormat: '#,##0', styleName: 'right-column', footer: { expression: 'sum', numberFormat: '#,##0' } };
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
    { fieldName: 'tBohB', dataType: 'number' }, { fieldName: 'tBohA', dataType: 'number' },
    { fieldName: 'uscInput', dataType: 'number' },
    { fieldName: 'inCode', dataType: 'number' },
    { fieldName: 'inResort', dataType: 'number' },
    { fieldName: 'inRework', dataType: 'number' },
    { fieldName: 'inSemi', dataType: 'number' },
    { fieldName: 'inEtc', dataType: 'number' },
    { fieldName: 'inTotal', dataType: 'number' },
    { fieldName: 'outputA', dataType: 'number' },
    { fieldName: 'outCode', dataType: 'number' },
    { fieldName: 'outSemiPaid', dataType: 'number' },
    { fieldName: 'outSemiFree', dataType: 'number' },
    { fieldName: 'outEtc', dataType: 'number' },
    { fieldName: 'outTotal', dataType: 'number' },
    { fieldName: 'loss', dataType: 'number' },
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
    numCol('tBohB', 'PFL전 50%'), numCol('tBohA', 'PFL후 90%'),
    numCol('uscInput', 'USC_INPUT'),
    numCol('inCode', 'CODE 변경'),
    numCol('inResort', 'Re-Sorting(재검사)', { width: '120' }),
    numCol('inRework', 'Re-work(재보완)', { width: '120' }),
    numCol('inSemi', '반제품 입고', { width: '100' }),
    numCol('inEtc', '기타'),
    numCol('inTotal', '기타입고', { width: '100' }),
    numCol('outputA', 'OUTPUT_A'),
    numCol('outCode', 'CODE 변경'),
    numCol('outSemiPaid', '반제품출고(유상)', { width: '120' }),
    numCol('outSemiFree', '반제품출고(무상)', { width: '120' }),
    numCol('outEtc', '기타'),
    numCol('outTotal', '기타출고', { width: '100' }),
    numCol('loss', 'LOSS(SCRAP)', { width: '100' }),
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
    pflGroup('tBoh', '기초 / BOH (T_BOH)'),
    { name: 'grpInput', direction: 'horizontal', header: { text: '입고 / INPUT' }, items: ['uscInput'] },
    {
      name: 'grpOtherInput',
      direction: 'horizontal',
      header: { text: '기타입고 / Other Input' },
      expandable: true,
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
      items: [
        { column: 'outCode', groupShowMode: 'expand' },
        {
          name: 'grpOutSemi', direction: 'horizontal', header: { text: '반제품 출고' }, groupShowMode: 'expand',
          items: ['outSemiPaid', 'outSemiFree'],
        },
        { column: 'outEtc', groupShowMode: 'expand' },
        { column: 'outTotal', groupShowMode: 'always' },
      ],
    },
    { name: 'grpLoss', direction: 'horizontal', header: { text: 'LOSS / SCRAP' }, items: ['loss'] },
    {
      name: 'grpEoh',
      direction: 'horizontal',
      header: { text: '재고 / EOH' },
      expandable: true,
      items: [
        { ...pflGroup('lineWip', 'LINE_WIP (A)'), groupShowMode: 'expand' },
        { ...pflGroup('lineFgs', 'LINE_FGs (A)'), groupShowMode: 'expand' },
        { ...pflGroup('bWip', 'B_LEVEL WIP (A)'), groupShowMode: 'expand' },
        { ...pflGroup('bFgs', 'B_LEVEL FGs (A)'), groupShowMode: 'expand' },
        { ...pflGroup('tEohWip', 'T_EOH WIP (7-5+6)'), groupShowMode: 'expand' },
        { ...pflGroup('tEohFgs', 'T_EOH FGs (2+4)'), groupShowMode: 'expand' },
        { ...pflGroup('totalEoh', 'TOTAL_EOH'), groupShowMode: 'always' },
      ],
    },
  ],
  options: {
    edit: { editable: false },
    display: { fitStyle: 'evenFill' },
    footer: { visible: true },
    header: { height: 60 },
  },
};

export default tab090015GridField;
