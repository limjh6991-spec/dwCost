/*
 * 제품 재고수불 (VN) - V18 신규 포맷 (재고수불 검증)
 * 다단계 헤더: BOH / INPUT / 기타입고 / OUTPUT / 기타출고 / LOSS / EOH / TOTAL_EOH(ERP) / 검증
 * 주의: 세부 산식은 추후 정의. 현재는 더미 프로시저(VN_StockLedger_V18) 데이터로 스캐폴딩.
 */

const { ValueType } = require('realgrid');

const numCol = (fieldName, text, width = 90) => ({
  name: fieldName,
  fieldName,
  width,
  header: { text },
  styleName: 'tr',
  numberFormat: '#,##0',
  footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' },
});

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
      headerDepth: 3,
      mergePolicy: 'auto',
    },
    edit: { editable: false },
    footer: { visible: true },
    paste: { enabled: false },
    rowIndicator: { visible: true },
    sorting: { enabled: true },
    stateBar: { visible: false },
    filtering: { enabled: true },
    fixed: { colCount: 1 },
  },

  fields: [
    { fieldName: 'model', dataType: ValueType.TEXT },
    // 기초 / BOH
    { fieldName: 'bohLine', dataType: ValueType.NUMBER },
    { fieldName: 'bohWcf', dataType: ValueType.NUMBER },
    { fieldName: 'bohBLevel', dataType: ValueType.NUMBER },
    { fieldName: 'tBoh', dataType: ValueType.NUMBER },
    // 입고 / INPUT
    { fieldName: 'uscInput', dataType: ValueType.NUMBER },
    // 기타입고 / Other Input
    { fieldName: 'ieCodeChange', dataType: ValueType.NUMBER },
    { fieldName: 'ieResorting', dataType: ValueType.NUMBER },
    { fieldName: 'ieRework', dataType: ValueType.NUMBER },
    { fieldName: 'ieSemiInput', dataType: ValueType.NUMBER },
    { fieldName: 'ieOther', dataType: ValueType.NUMBER },
    { fieldName: 'ieTotal', dataType: ValueType.NUMBER },
    // 출고 / OUTPUT
    { fieldName: 'outputA', dataType: ValueType.NUMBER },
    // 기타출고 / Other Output
    { fieldName: 'oeCodeChange', dataType: ValueType.NUMBER },
    { fieldName: 'oeSemiPaid', dataType: ValueType.NUMBER },
    { fieldName: 'oeSemiFree', dataType: ValueType.NUMBER },
    { fieldName: 'oeOther', dataType: ValueType.NUMBER },
    { fieldName: 'oeTotal', dataType: ValueType.NUMBER },
    // LOSS
    { fieldName: 'loss', dataType: ValueType.NUMBER },
    // 재고 / EOH
    { fieldName: 'eohLineWip', dataType: ValueType.NUMBER },
    { fieldName: 'eohLineFgs', dataType: ValueType.NUMBER },
    { fieldName: 'eohBLevelWip', dataType: ValueType.NUMBER },
    { fieldName: 'eohBLevelFgs', dataType: ValueType.NUMBER },
    { fieldName: 'tEohWip', dataType: ValueType.NUMBER },
    { fieldName: 'tEohFgs', dataType: ValueType.NUMBER },
    { fieldName: 'totalEohMes', dataType: ValueType.NUMBER },
    // TOTAL_EOH (ERP)
    { fieldName: 'plBefore', dataType: ValueType.NUMBER },
    { fieldName: 'plAfter', dataType: ValueType.NUMBER },
    // 검증
    { fieldName: 'verifyMatch', dataType: ValueType.TEXT },
    { fieldName: 'verifyDiff', dataType: ValueType.NUMBER },
  ],

  columns: [
    { name: 'model', fieldName: 'model', width: 90, header: { text: 'MODEL' }, styleName: 'tc', autoFilter: true },
    numCol('bohLine', 'BOH LINE (C)', 100),
    numCol('bohWcf', 'BOH WCF (C)', 100),
    numCol('bohBLevel', 'BOH B_LEVEL (A)', 110),
    numCol('tBoh', 'T_BOH', 90),
    numCol('uscInput', 'USC_INPUT (C)', 100),
    numCol('ieCodeChange', 'CODE 변경', 90),
    numCol('ieResorting', 'Re-Sorting (재검사)', 120),
    numCol('ieRework', 'Re-work (SI검사)', 120),
    numCol('ieSemiInput', '반제품 입고', 100),
    numCol('ieOther', '기타', 80),
    numCol('ieTotal', '기타입고', 90),
    numCol('outputA', 'OUTPUT_A (C)', 100),
    numCol('oeCodeChange', 'CODE 변경', 90),
    numCol('oeSemiPaid', '반제품 출고 (유상)', 120),
    numCol('oeSemiFree', '반제품 출고 (무상)', 120),
    numCol('oeOther', '기타', 80),
    numCol('oeTotal', '기타출고', 90),
    numCol('loss', 'LOSS (SCRAP)', 100),
    numCol('eohLineWip', 'LINE_WIP (A)', 100),
    numCol('eohLineFgs', 'LINE_FGs (A)', 100),
    numCol('eohBLevelWip', 'B_LEVEL WIP (A)', 110),
    numCol('eohBLevelFgs', 'B_LEVEL FGs', 110),
    numCol('tEohWip', 'T_EOH WIP (5=1+3)', 120),
    numCol('tEohFgs', 'T_EOH FGs (6=2+4)', 120),
    numCol('totalEohMes', 'TOTAL_EOH (MES) 7=5+6', 140),
    numCol('plBefore', 'PL전 50%', 90),
    numCol('plAfter', 'PL후 90%', 90),
    { name: 'verifyMatch', fieldName: 'verifyMatch', width: 70, header: { text: '일치' }, styleName: 'tc' },
    numCol('verifyDiff', '차이', 80),
  ],

  columnLayout: [
    { column: 'model' },
    {
      name: 'grpBoh',
      header: { text: '기초 / BOH (4=1+2+3)' },
      direction: 'horizontal',
      items: [{ column: 'bohLine' }, { column: 'bohWcf' }, { column: 'bohBLevel' }, { column: 'tBoh' }],
    },
    {
      name: 'grpInput',
      header: { text: '입고 / INPUT' },
      direction: 'horizontal',
      items: [{ column: 'uscInput' }],
    },
    {
      name: 'grpInEtc',
      header: { text: '기타입고 / Other Input (6=1+2+3+4+5)' },
      direction: 'horizontal',
      items: [
        { column: 'ieCodeChange' },
        { column: 'ieResorting' },
        { column: 'ieRework' },
        { column: 'ieSemiInput' },
        { column: 'ieOther' },
        { column: 'ieTotal' },
      ],
    },
    {
      name: 'grpOutput',
      header: { text: '출고 / OUTPUT' },
      direction: 'horizontal',
      items: [{ column: 'outputA' }],
    },
    {
      name: 'grpOutEtc',
      header: { text: '기타출고 / Other Output (5=1+2+3+4)' },
      direction: 'horizontal',
      items: [{ column: 'oeCodeChange' }, { column: 'oeSemiPaid' }, { column: 'oeSemiFree' }, { column: 'oeOther' }, { column: 'oeTotal' }],
    },
    { column: 'loss' },
    {
      name: 'grpEoh',
      header: { text: '재고 / EOH' },
      direction: 'horizontal',
      items: [
        { column: 'eohLineWip' },
        { column: 'eohLineFgs' },
        { column: 'eohBLevelWip' },
        { column: 'eohBLevelFgs' },
        { column: 'tEohWip' },
        { column: 'tEohFgs' },
        { column: 'totalEohMes' },
      ],
    },
    {
      name: 'grpTotalErp',
      header: { text: 'TOTAL_EOH (ERP)' },
      direction: 'horizontal',
      items: [{ column: 'plBefore' }, { column: 'plAfter' }],
    },
    {
      name: 'grpVerify',
      header: { text: '검증' },
      direction: 'horizontal',
      items: [{ column: 'verifyMatch' }, { column: 'verifyDiff' }],
    },
  ],
};

module.exports = grid;
