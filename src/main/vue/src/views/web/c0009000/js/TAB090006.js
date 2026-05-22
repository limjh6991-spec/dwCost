/**
 * 재공,제품원가 - 제조원가(재공)
 */

const { ValueType } = require('realgrid');
const gubunMergeCriteria = "values['mergeKeyGubun']";
const commonMergeCriteria = "values['mergeKey']";

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
      headerDepth: 2,
     },
    footer: { visible: false },
    filtering: { enabled: false },
    footers: {
      visible: false,
      items: []
    },
  },
  fields: [
  { fieldName: '구분', dataType: ValueType.TEXT },
  { fieldName: '모델', dataType: ValueType.TEXT },
  { fieldName: 'inch', dataType: ValueType.TEXT },
  { fieldName: '판매처', dataType: ValueType.TEXT },
  { fieldName: 'rowType', dataType: ValueType.TEXT },
  { fieldName: '월', dataType: ValueType.TEXT },
  { fieldName: 'mergeKey', dataType: ValueType.TEXT },
  { fieldName: 'mergeKeyGubun', dataType: ValueType.TEXT },
  { fieldName: 'bohQty', dataType: ValueType.NUMBER },
  { fieldName: 'bohAmt', dataType: ValueType.NUMBER },
  { fieldName: 'inQty', dataType: ValueType.NUMBER },
  { fieldName: 'inAmt', dataType: ValueType.NUMBER },
  { fieldName: 'outQty', dataType: ValueType.NUMBER },
  { fieldName: 'outAmt', dataType: ValueType.NUMBER },
  { fieldName: 'lossQty', dataType: ValueType.NUMBER },
  { fieldName: 'lossAmt', dataType: ValueType.NUMBER },
  { fieldName: 'lossDefectQty', dataType: ValueType.NUMBER },
  { fieldName: 'lossDefectAmt', dataType: ValueType.NUMBER },
  { fieldName: 'lossSaleQty', dataType: ValueType.NUMBER },
  { fieldName: 'lossSaleAmt', dataType: ValueType.NUMBER },
  { fieldName: 'rmaInQty', dataType: ValueType.NUMBER },
  { fieldName: 'rmaInAmt', dataType: ValueType.NUMBER },
  { fieldName: 'etcInLotQty', dataType: ValueType.NUMBER },
  { fieldName: 'etcInLotAmt', dataType: ValueType.NUMBER },
  { fieldName: 'etcInRmaQty', dataType: ValueType.NUMBER },
  { fieldName: 'etcInRmaAmt', dataType: ValueType.NUMBER },
  { fieldName: 'etcInPrevDefQty', dataType: ValueType.NUMBER },
  { fieldName: 'etcInPrevDefAmt', dataType: ValueType.NUMBER },
  { fieldName: 'etcInCurDefQty', dataType: ValueType.NUMBER },
  { fieldName: 'etcInCurDefAmt', dataType: ValueType.NUMBER },
  { fieldName: 'outEtcQty', dataType: ValueType.NUMBER },
  { fieldName: 'outEtcAmt', dataType: ValueType.NUMBER },
  { fieldName: 'etcOutLotQty', dataType: ValueType.NUMBER },
  { fieldName: 'etcOutLotAmt', dataType: ValueType.NUMBER },
  { fieldName: 'etcOutEtcQty', dataType: ValueType.NUMBER },
  { fieldName: 'etcOutEtcAmt', dataType: ValueType.NUMBER },
  { fieldName: '불량률', dataType: ValueType.NUMBER },
  { fieldName: 'eohQty', dataType: ValueType.NUMBER },
  { fieldName: 'eohAmt', dataType: ValueType.NUMBER },
  ],
  // ===== 공통 레이아웃 블록 =====
  _commonPrefix: [
    { column: '구분' },
    { column: '모델' },
    { column: 'inch' },
    { column: '판매처' },
    { column: '월' },
    {
      name: 'grpBOH',
      header: { text: '기초재공품재고(BOH)' },
      direction: 'horizontal',
      items: [{ column: 'bohQty' }, { column: 'bohAmt' }],
    },
    {
      name: 'grpIN',
      header: { text: '입고(IN)' },
      direction: 'horizontal',
      items: [{ column: 'inQty' }, { column: 'inAmt' }],
    },
    {
      name: 'grpOUT',
      header: { text: '출고(OUT)' },
      direction: 'horizontal',
      items: [{ column: 'outQty' }, { column: 'outAmt' }],
    },
  ],
  _commonSuffix: [
    { column: '불량률' },
    {
      name: 'grpEOH',
      header: { text: '기말재공품재고(EOH)' },
      direction: 'horizontal',
      items: [{ column: 'eohQty' }, { column: 'eohAmt' }],
    },
  ],
  // LOSS 접힌 상태 (기본)
  _lossCollapsed: [
    {
      name: 'grpLoss',
      header: { text: 'LOSS  ⊕' },
      direction: 'horizontal',
      items: [{ column: 'lossQty' }, { column: 'lossAmt' }],
    },
  ],
  // LOSS 펼친 상태
  _lossExpanded: [
    {
      name: 'grpLoss',
      header: { text: 'LOSS  ⊖' },
      direction: 'horizontal',
      items: [{ column: 'lossQty' }, { column: 'lossAmt' }],
    },
    {
      name: 'grpLossDefect',
      header: { text: '공정발생 불량' },
      direction: 'horizontal',
      items: [{ column: 'lossDefectQty' }, { column: 'lossDefectAmt' }],
    },
    {
      name: 'grpLossSale',
      header: { text: '불량판매' },
      direction: 'horizontal',
      items: [{ column: 'lossSaleQty' }, { column: 'lossSaleAmt' }],
    },
  ],
  // 타계정입고 접힌 상태 (기본)
  _rmaInCollapsed: [
    {
      name: 'grpRmaIn',
      header: { text: '타계정입고  ⊕' },
      direction: 'horizontal',
      items: [{ column: 'rmaInQty' }, { column: 'rmaInAmt' }],
    },
  ],
  // 타계정입고 펼친 상태
  _rmaInExpanded: [
    {
      name: 'grpRmaIn',
      header: { text: '타계정입고  ⊖' },
      direction: 'horizontal',
      items: [{ column: 'rmaInQty' }, { column: 'rmaInAmt' }],
    },
    {
      name: 'grpEtcInLot',
      header: { text: '기타입고(LOT변환)' },
      direction: 'horizontal',
      items: [{ column: 'etcInLotQty' }, { column: 'etcInLotAmt' }],
    },
    {
      name: 'grpEtcInRma',
      header: { text: '기타입고(RMA R/W)' },
      direction: 'horizontal',
      items: [{ column: 'etcInRmaQty' }, { column: 'etcInRmaAmt' }],
    },
    {
      name: 'grpEtcInPrevDef',
      header: { text: '기타입고(전월 불량)' },
      direction: 'horizontal',
      items: [{ column: 'etcInPrevDefQty' }, { column: 'etcInPrevDefAmt' }],
    },
    {
      name: 'grpEtcInCurDef',
      header: { text: '기타입고(당월 불량)' },
      direction: 'horizontal',
      items: [{ column: 'etcInCurDefQty' }, { column: 'etcInCurDefAmt' }],
    },
  ],
  // 타계정출고 접힌 상태 (기본)
  _rmaOutCollapsed: [
    {
      name: 'grpRmaOut',
      header: { text: '타계정출고  ⊕' },
      direction: 'horizontal',
      items: [{ column: 'outEtcQty' }, { column: 'outEtcAmt' }],
    },
  ],
  // 타계정출고 펼친 상태
  _rmaOutExpanded: [
    {
      name: 'grpRmaOut',
      header: { text: '타계정출고  ⊖' },
      direction: 'horizontal',
      items: [{ column: 'outEtcQty' }, { column: 'outEtcAmt' }],
    },
    {
      name: 'grpEtcOutLot',
      header: { text: '기타출고(LOT변환)' },
      direction: 'horizontal',
      items: [{ column: 'etcOutLotQty' }, { column: 'etcOutLotAmt' }],
    },
    {
      name: 'grpEtcOutEtc',
      header: { text: '기타출고(기타)' },
      direction: 'horizontal',
      items: [{ column: 'etcOutEtcQty' }, { column: 'etcOutEtcAmt' }],
    },
  ],
  // 레이아웃 조합 함수
  buildLayout(lossExpanded, rmaInExpanded, rmaOutExpanded) {
    return [
      ...this._commonPrefix,
      ...(lossExpanded ? this._lossExpanded : this._lossCollapsed),
      ...(rmaInExpanded ? this._rmaInExpanded : this._rmaInCollapsed),
      ...(rmaOutExpanded ? this._rmaOutExpanded : this._rmaOutCollapsed),
      ...this._commonSuffix,
    ];
  },
  columns: [
  {
    name: '구분', fieldName: '구분', width: 80, header: { text: '구분' },
    styleName: 'tc', mergeRule: { criteria: gubunMergeCriteria }
  },
  {
    name: '모델', fieldName: '모델', width: 100, header: { text: '모델' },
    styleName: 'tc', mergeRule: { criteria: commonMergeCriteria }
  },
  {
    name: 'inch', fieldName: 'inch', width: 60, header: { text: '인치' },
    styleName: 'tc', mergeRule: { criteria: commonMergeCriteria }
  },
  {
    name: '판매처', fieldName: '판매처', width: 60, header: { text: '판매처' },
    styleName: 'tc', mergeRule: { criteria: commonMergeCriteria }
  },
  { name: 'rowType', fieldName: 'rowType', visible: false },
  { name: '월', fieldName: '월', width: 60, header: { text: '' }, autoFilter: true, styleName: 'tc' },
  // BOH
  { name: 'bohQty', fieldName: 'bohQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'bohAmt', fieldName: 'bohAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  // IN
  { name: 'inQty', fieldName: 'inQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'inAmt', fieldName: 'inAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  // OUT
  { name: 'outQty', fieldName: 'outQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'outAmt', fieldName: 'outAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  // LOSS
  { name: 'lossQty', fieldName: 'lossQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'lossAmt', fieldName: 'lossAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  // 공정발생 불량
  { name: 'lossDefectQty', fieldName: 'lossDefectQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'lossDefectAmt', fieldName: 'lossDefectAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  // 불량판매
  { name: 'lossSaleQty', fieldName: 'lossSaleQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'lossSaleAmt', fieldName: 'lossSaleAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  // 타계정입고
  { name: 'rmaInQty', fieldName: 'rmaInQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'rmaInAmt', fieldName: 'rmaInAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  // 기타입고(LOT변환)
  { name: 'etcInLotQty', fieldName: 'etcInLotQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'etcInLotAmt', fieldName: 'etcInLotAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  // 기타입고(RMA R/W)
  { name: 'etcInRmaQty', fieldName: 'etcInRmaQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'etcInRmaAmt', fieldName: 'etcInRmaAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  // 기타입고(전월 불량)
  { name: 'etcInPrevDefQty', fieldName: 'etcInPrevDefQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'etcInPrevDefAmt', fieldName: 'etcInPrevDefAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  // 기타입고(당월 불량)
  { name: 'etcInCurDefQty', fieldName: 'etcInCurDefQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'etcInCurDefAmt', fieldName: 'etcInCurDefAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  // 타계정출고
  { name: 'outEtcQty', fieldName: 'outEtcQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'outEtcAmt', fieldName: 'outEtcAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  // 기타출고(LOT변환)
  { name: 'etcOutLotQty', fieldName: 'etcOutLotQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'etcOutLotAmt', fieldName: 'etcOutLotAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  // 기타출고(기타)
  { name: 'etcOutEtcQty', fieldName: 'etcOutEtcQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'etcOutEtcAmt', fieldName: 'etcOutEtcAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  // 불량률, EOH
  { name: '불량률', fieldName: '불량률', width: 80, header: { text: '불량률(%)' }, styleName: 'tr', numberFormat: '#,##0.00' },
  { name: 'eohQty', fieldName: 'eohQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'eohAmt', fieldName: 'eohAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  ],
};

// 기본 레이아웃 (모두 접힌 상태)
grid.columnLayout = grid.buildLayout(false, false, false);

module.exports = grid;
