/*
 * 제품 수불부 (VN) - 완제품창고(WH0006) 재고수불 신규 포맷
 * 주의: 세부 컬럼(BACK-SHIP/WH RETURN/SHIP(A·B)/Re-Sorting/Re-work/반품품 등)의
 *       산식은 추후 정의. 현재는 프론트 스캐폴딩(합계 컬럼 위주, 세부는 0).
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
    { name: 'model', fieldName: 'model', width: 90, header: { text: 'MODEL' }, styleName: 'tc', autoFilter: true },
    numCol('boh', 'boh', 'BOH'),
    numCol('fgLastMonth', 'fgLastMonth', 'LAST-MONTH', 100),
    numCol('fgThisMonth', 'fgThisMonth', 'THIS-MONTH', 100),
    numCol('backShipSorting', 'backShipSorting', 'BACK-SHIP(SORTING)', 110),
    numCol('backShipPfRw', 'backShipPfRw', 'BACK-SHIP(PF-RW)', 110),
    numCol('backShipPlRw', 'backShipPlRw', 'BACK-SHIP(PL-RW)', 110),
    numCol('whReturnSorting', 'whReturnSorting', 'WH RETURN(SORTING)', 110),
    numCol('whReturnPfRw', 'whReturnPfRw', 'WH RETURN(PF-RW)', 110),
    numCol('whReturnPlRw', 'whReturnPlRw', 'WH RETURN(PL-RW)', 110),
    numCol('tInput', 'tInput', 'T_INPUT', 100),
    numCol('ieRma', 'ieRma', 'RMA'),
    numCol('ieReturnPaid', 'ieReturnPaid', '반품품(유상)', 100),
    numCol('ieReturnFree', 'ieReturnFree', '반품품(무상)', 100),
    numCol('ieOther', 'ieOther', '기타'),
    numCol('ieTotal', 'ieTotal', '기타입고', 100),
    numCol('shipAPaid', 'shipAPaid', 'PAID'),
    numCol('shipBPaid', 'shipBPaid', 'PAID'),
    numCol('tOutput', 'tOutput', 'T_OUTPUT', 100),
    numCol('oeResorting', 'oeResorting', 'Re-Sorting(재검사)', 120),
    numCol('oeRework', 'oeRework', 'Re-work(SI검사)', 120),
    numCol('oeRma', 'oeRma', 'RMA'),
    numCol('oeFreeSale', 'oeFreeSale', '무상매출', 100),
    numCol('oeOther', 'oeOther', '기타'),
    numCol('oeTotal', 'oeTotal', '기타출고', 100),
    numCol('loss', 'loss', 'LOSS'),
    numCol('eoh', 'eoh', 'EOH WH0006', 110),
  ],

  columnLayout: [
    { column: 'model' },
    { column: 'boh' },
    {
      name: 'grpInput',
      header: { text: 'INPUT' },
      direction: 'horizontal',
      items: [
        {
          name: 'grpNormalFg',
          header: { text: 'NORMAL FG INPUT' },
          direction: 'horizontal',
          items: [{ column: 'fgLastMonth' }, { column: 'fgThisMonth' }],
        },
        {
          name: 'grpRwLine',
          header: { text: 'RW FROM LINE → FG-WAREHOUSE / REWORK 생산라인 → 완제품 창고 CELL 입고' },
          direction: 'horizontal',
          items: [
            { column: 'backShipSorting' },
            { column: 'backShipPfRw' },
            { column: 'backShipPlRw' },
            { column: 'whReturnSorting' },
            { column: 'whReturnPfRw' },
            { column: 'whReturnPlRw' },
          ],
        },
        { column: 'tInput' },
      ],
    },
    {
      name: 'grpInEtc',
      header: { text: '기타입고' },
      direction: 'horizontal',
      items: [{ column: 'ieRma' }, { column: 'ieReturnPaid' }, { column: 'ieReturnFree' }, { column: 'ieOther' }, { column: 'ieTotal' }],
    },
    {
      name: 'grpOutput',
      header: { text: 'OUTPUT' },
      direction: 'horizontal',
      items: [
        { name: 'grpShipA', header: { text: 'SHIP(A 그)' }, direction: 'horizontal', items: [{ column: 'shipAPaid' }] },
        { name: 'grpShipB', header: { text: 'SHIP(B 그)' }, direction: 'horizontal', items: [{ column: 'shipBPaid' }] },
        { column: 'tOutput' },
      ],
    },
    {
      name: 'grpOutEtc',
      header: { text: '기타출고' },
      direction: 'horizontal',
      items: [
        { column: 'oeResorting' },
        { column: 'oeRework' },
        { column: 'oeRma' },
        { column: 'oeFreeSale' },
        { column: 'oeOther' },
        { column: 'oeTotal' },
      ],
    },
    { column: 'loss' },
    { column: 'eoh' },
  ],
};

module.exports = grid;
