/*
 * 제품 수불부 (VN) - 완제품창고(WH0006) 재고수불 신규 포맷
 * 헤더: 모형/구분/BOH | INPUT | 기타입고 | OUTPUT | 기타출고 | LOSS | EOH(WH0006)
 * INPUT/기타입고/OUTPUT/기타출고 그룹은 +/- 여닫기(expandable). 세부 산식은 추후 정의(스텁).
 */

const { ValueType } = require('realgrid');

const numCol = (name, fieldName, text, width = 90) => ({
  name,
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
    fixed: { colCount: 2 },
  },

  fields: [
    { fieldName: 'model', dataType: ValueType.TEXT },
    { fieldName: 'division', dataType: ValueType.TEXT },
    { fieldName: 'boh', dataType: ValueType.NUMBER },
    // INPUT > NORMAL FG INPUT
    { fieldName: 'fgLastMonth', dataType: ValueType.NUMBER },
    { fieldName: 'fgThisMonth', dataType: ValueType.NUMBER },
    // INPUT > RW FROM LINE → FG-WAREHOUSE
    { fieldName: 'backShipSorting', dataType: ValueType.NUMBER },
    { fieldName: 'backShipPfRw', dataType: ValueType.NUMBER },
    { fieldName: 'backShipPlRw', dataType: ValueType.NUMBER },
    { fieldName: 'whReturnSorting', dataType: ValueType.NUMBER },
    { fieldName: 'whReturnPfRw', dataType: ValueType.NUMBER },
    { fieldName: 'whReturnPlRw', dataType: ValueType.NUMBER },
    { fieldName: 'tInput', dataType: ValueType.NUMBER },
    // 기타입고
    { fieldName: 'ieRma', dataType: ValueType.NUMBER },
    { fieldName: 'ieReturnPaid', dataType: ValueType.NUMBER },
    { fieldName: 'ieReturnFree', dataType: ValueType.NUMBER },
    { fieldName: 'ieOther', dataType: ValueType.NUMBER },
    { fieldName: 'ieTotal', dataType: ValueType.NUMBER },
    // OUTPUT
    { fieldName: 'shipAPaid', dataType: ValueType.NUMBER },
    { fieldName: 'shipBPaid', dataType: ValueType.NUMBER },
    { fieldName: 'tOutput', dataType: ValueType.NUMBER },
    // 기타출고
    { fieldName: 'oeResorting', dataType: ValueType.NUMBER },
    { fieldName: 'oeRework', dataType: ValueType.NUMBER },
    { fieldName: 'oeRma', dataType: ValueType.NUMBER },
    { fieldName: 'oeFreeSale', dataType: ValueType.NUMBER },
    { fieldName: 'oeOther', dataType: ValueType.NUMBER },
    { fieldName: 'oeTotal', dataType: ValueType.NUMBER },
    { fieldName: 'loss', dataType: ValueType.NUMBER },
    { fieldName: 'eoh', dataType: ValueType.NUMBER },
  ],

  columns: [
    { name: 'model', fieldName: 'model', width: 90, header: { text: '모형\nModel' }, styleName: 'tc', autoFilter: true },
    { name: 'division', fieldName: 'division', width: 70, header: { text: '구분\nDivision' }, styleName: 'tc', autoFilter: true },
    numCol('boh', 'boh', 'BOH'),
    numCol('fgLastMonth', 'fgLastMonth', '1. LAST-MONTH', 100),
    numCol('fgThisMonth', 'fgThisMonth', '2. THIS-MONTH', 100),
    numCol('backShipSorting', 'backShipSorting', '3. BACK-SHIP(SORTING)', 110),
    numCol('backShipPfRw', 'backShipPfRw', '4. BACK-SHIP(PF-RW)', 110),
    numCol('backShipPlRw', 'backShipPlRw', '5. BACK-SHIP(PL-RW)', 110),
    numCol('whReturnSorting', 'whReturnSorting', '6. WH RETURN(SORTING)', 110),
    numCol('whReturnPfRw', 'whReturnPfRw', '7. WH RETURN(PF-RW)', 110),
    numCol('whReturnPlRw', 'whReturnPlRw', '8. WH RETURN(PL-RW)', 110),
    numCol('tInput', 'tInput', 'T_INPUT', 110),
    numCol('ieRma', 'ieRma', '1. RMA'),
    numCol('ieReturnPaid', 'ieReturnPaid', '2. 반제품(유상)', 100),
    numCol('ieReturnFree', 'ieReturnFree', '3. 반제품(무상)', 100),
    numCol('ieOther', 'ieOther', '4. 기타'),
    numCol('ieTotal', 'ieTotal', '기타입고', 120),
    numCol('shipAPaid', 'shipAPaid', 'PAID',150),
    numCol('shipBPaid', 'shipBPaid', 'PAID',150),
    numCol('tOutput', 'tOutput', 'T_OUTPUT', 110),
    numCol('oeResorting', 'oeResorting', '1. Re-Sorting(재검사)', 120),
    numCol('oeRework', 'oeRework', '2. Re-work(SI검사)', 120),
    numCol('oeRma', 'oeRma', '3. RMA'),
    numCol('oeFreeSale', 'oeFreeSale', '4. 무상반출', 100),
    numCol('oeOther', 'oeOther', '5. 기타'),
    numCol('oeTotal', 'oeTotal', '기타출고', 130),
    numCol('loss', 'loss', 'LOSS'),
    numCol('eoh', 'eoh', 'EOH\nWH0006', 110),
  ],

  columnLayout: [
    { column: 'model' },
    { column: 'division' },
    { column: 'boh' },
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
          items: [{ column: 'fgLastMonth' }, { column: 'fgThisMonth' }],
        },
        {
          name: 'grpRwLine',
          header: { text: 'RW FROM LINE → FG-WAREHOUSE / REWORK 생산라인 → 반제품 창고 CELL 입고' },
          direction: 'horizontal',
          groupShowMode: 'expand',
          items: [
            { column: 'backShipSorting' },
            { column: 'backShipPfRw' },
            { column: 'backShipPlRw' },
            { column: 'whReturnSorting' },
            { column: 'whReturnPfRw' },
            { column: 'whReturnPlRw' },
          ],
        },
        { column: 'tInput', groupShowMode: 'always' },
      ],
    },
    {
      name: 'grpInEtc',
      header: { text: '기타입고' },
      direction: 'horizontal',
      expandable: true,
      expanded: false,
      items: [
        { column: 'ieRma', groupShowMode: 'expand' },
        { column: 'ieReturnPaid', groupShowMode: 'expand' },
        { column: 'ieReturnFree', groupShowMode: 'expand' },
        { column: 'ieOther', groupShowMode: 'expand' },
        { column: 'ieTotal', groupShowMode: 'always' },
      ],
    },
    {
      name: 'grpOutput',
      header: { text: 'OUTPUT' },
      direction: 'horizontal',
      expandable: true,
      expanded: false,
      items: [
        { name: 'grpShipA', header: { text: 'SHIP(A급)' }, direction: 'horizontal', groupShowMode: 'expand', items: [{ column: 'shipAPaid' }] },
        { name: 'grpShipB', header: { text: 'SHIP(B급)' }, direction: 'horizontal', groupShowMode: 'expand', items: [{ column: 'shipBPaid' }] },
        { column: 'tOutput', groupShowMode: 'always' },
      ],
    },
    {
      name: 'grpOutEtc',
      header: { text: '기타출고' },
      direction: 'horizontal',
      expandable: true,
      expanded: false,
      items: [
        { column: 'oeResorting', groupShowMode: 'expand' },
        { column: 'oeRework', groupShowMode: 'expand' },
        { column: 'oeRma', groupShowMode: 'expand' },
        { column: 'oeFreeSale', groupShowMode: 'expand' },
        { column: 'oeOther', groupShowMode: 'expand' },
        { column: 'oeTotal', groupShowMode: 'always' },
      ],
    },
    { column: 'loss' },
    { column: 'eoh' },
  ],
};

module.exports = grid;
