/**
 * 재공,제품원가 - 제조원가(재공) - 3단 헤더 + 동일레벨 펼침
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
      fitStyle: 'fill',
      emptyMessage: '조회된 데이터가 없습니다.',
      hscrollBar: true,
      showEmptyMessage: true,
      headerDepth: 3,
    },
    footer: { visible: false },
    filtering: { enabled: false },
    footers: { visible: false, items: [] },
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
    { fieldName: 'etcInDefRwQty', dataType: ValueType.NUMBER },
    { fieldName: 'etcInDefRwAmt', dataType: ValueType.NUMBER },
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

  // ===== 고정 레이아웃 (RealGrid 네이티브 expandable 사용) =====
  layout: [
    { column: '구분' },
    { column: '모델' },
    { column: 'inch' },
    { column: '판매처' },
    { column: '월' },
    // 제조원가 (3단 헤더: 제조원가 > BOH/IN/OUT > 수량/금액)
    {
      name: 'grpManuCost',
      header: { text: '제조원가' },
      direction: 'horizontal',
      items: [
        { name: 'grpBOH', header: { text: '기초재공품재고(BOH)' }, direction: 'horizontal',
          items: [{ column: 'bohQty' }, { column: 'bohAmt' }] },
        { name: 'grpIN', header: { text: '입고(IN)' }, direction: 'horizontal',
          items: [{ column: 'inQty' }, { column: 'inAmt' }] },
        { name: 'grpOUT', header: { text: '출고(OUT)' }, direction: 'horizontal',
          items: [{ column: 'outQty' }, { column: 'outAmt' }] },
      ],
    },
    // LOSS 영역 — 헤더 [+]/[-] 클릭으로 확장/축소
    {
      name: 'grpLossArea',
      header: { text: 'LOSS' },
      expandable: true,
      expanded: false,
      direction: 'horizontal',
      items: [
        { name: 'grpLoss', header: { text: 'LOSS' }, groupShowMode: 'always',
          direction: 'horizontal', items: [{ column: 'lossQty' }, { column: 'lossAmt' }] },
        { name: 'grpLossDefect', header: { text: '공정발생 불량' }, groupShowMode: 'expand',
          direction: 'horizontal', items: [{ column: 'lossDefectQty' }, { column: 'lossDefectAmt' }] },
        { name: 'grpLossSale', header: { text: '불량판매' }, groupShowMode: 'expand',
          direction: 'horizontal', items: [{ column: 'lossSaleQty' }, { column: 'lossSaleAmt' }] },
      ],
    },
    // 타계정입고 영역 — 헤더 [+]/[-] 클릭으로 확장/축소
    {
      name: 'grpRmaInArea',
      header: { text: '타계정입고' },
      expandable: true,
      expanded: false,
      direction: 'horizontal',
      items: [
        { name: 'grpRmaIn', header: { text: '타계정입고' }, groupShowMode: 'always',
          direction: 'horizontal', items: [{ column: 'rmaInQty' }, { column: 'rmaInAmt' }] },
        { name: 'grpEtcInLot', header: { text: '기타입고(LOT변환)' }, groupShowMode: 'expand',
          direction: 'horizontal', items: [{ column: 'etcInLotQty' }, { column: 'etcInLotAmt' }] },
        { name: 'grpEtcInDefRw', header: { text: '기타입고(불량 R/W)' }, groupShowMode: 'expand',
          direction: 'horizontal', items: [{ column: 'etcInDefRwQty' }, { column: 'etcInDefRwAmt' }] },
        { name: 'grpEtcInRma', header: { text: '기타입고(RMA R/W)' }, groupShowMode: 'expand',
          direction: 'horizontal', items: [{ column: 'etcInRmaQty' }, { column: 'etcInRmaAmt' }] },
        { name: 'grpEtcInPrevDef', header: { text: '기타입고(전월 불량)' }, groupShowMode: 'expand',
          direction: 'horizontal', items: [{ column: 'etcInPrevDefQty' }, { column: 'etcInPrevDefAmt' }] },
        { name: 'grpEtcInCurDef', header: { text: '기타입고(당월 불량)' }, groupShowMode: 'expand',
          direction: 'horizontal', items: [{ column: 'etcInCurDefQty' }, { column: 'etcInCurDefAmt' }] },
      ],
    },
    // 타계정출고 영역 — 헤더 [+]/[-] 클릭으로 확장/축소
    {
      name: 'grpRmaOutArea',
      header: { text: '타계정출고' },
      expandable: true,
      expanded: false,
      direction: 'horizontal',
      items: [
        { name: 'grpRmaOut', header: { text: '타계정출고' }, groupShowMode: 'always',
          direction: 'horizontal', items: [{ column: 'outEtcQty' }, { column: 'outEtcAmt' }] },
        { name: 'grpEtcOutLot', header: { text: '기타출고(LOT변환)' }, groupShowMode: 'expand',
          direction: 'horizontal', items: [{ column: 'etcOutLotQty' }, { column: 'etcOutLotAmt' }] },
        { name: 'grpEtcOutEtc', header: { text: '기타출고(기타)' }, groupShowMode: 'expand',
          direction: 'horizontal', items: [{ column: 'etcOutEtcQty' }, { column: 'etcOutEtcAmt' }] },
      ],
    },
    { column: '불량률' },
    {
      name: 'grpEOH',
      header: { text: '기말재공품재고(EOH)' },
      direction: 'horizontal',
      items: [{ column: 'eohQty' }, { column: 'eohAmt' }],
    },
  ],

  columns: [
    { name: '구분', fieldName: '구분', width: 40, header: { text: '구분' },
      styleName: 'tc', mergeRule: { criteria: gubunMergeCriteria } },
    { name: '모델', fieldName: '모델', width: 50, header: { text: '모델' },
      styleName: 'tc', mergeRule: { criteria: commonMergeCriteria } },
    { name: 'inch', fieldName: 'inch', width: 30, header: { text: '인치' },
      styleName: 'tc', mergeRule: { criteria: commonMergeCriteria } },
    { name: '판매처', fieldName: '판매처', width: 30, header: { text: '판매처' },
      styleName: 'tc', mergeRule: { criteria: commonMergeCriteria } },
    { name: 'rowType', fieldName: 'rowType', visible: false },
    { name: '월', fieldName: '월', width: 25, header: { text: '월' }, autoFilter: true, styleName: 'tc' },
    // BOH
    { name: 'bohQty', fieldName: 'bohQty', width: 60, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'bohAmt', fieldName: 'bohAmt', width: 85, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
    // IN
    { name: 'inQty', fieldName: 'inQty', width: 60, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'inAmt', fieldName: 'inAmt', width: 85, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
    // OUT
    { name: 'outQty', fieldName: 'outQty', width: 60, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'outAmt', fieldName: 'outAmt', width: 85, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
    // LOSS
    { name: 'lossQty', fieldName: 'lossQty', width: 60, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'lossAmt', fieldName: 'lossAmt', width: 85, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
    // 공정발생 불량
    { name: 'lossDefectQty', fieldName: 'lossDefectQty', width: 60, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'lossDefectAmt', fieldName: 'lossDefectAmt', width: 85, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
    // 불량판매
    { name: 'lossSaleQty', fieldName: 'lossSaleQty', width: 60, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'lossSaleAmt', fieldName: 'lossSaleAmt', width: 85, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
    // 타계정입고
    { name: 'rmaInQty', fieldName: 'rmaInQty', width: 60, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'rmaInAmt', fieldName: 'rmaInAmt', width: 85, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
    // 기타입고(LOT변환)
    { name: 'etcInLotQty', fieldName: 'etcInLotQty', width: 60, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'etcInLotAmt', fieldName: 'etcInLotAmt', width: 85, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
    // 기타입고(불량 R/W)
    { name: 'etcInDefRwQty', fieldName: 'etcInDefRwQty', width: 60, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'etcInDefRwAmt', fieldName: 'etcInDefRwAmt', width: 85, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
    // 기타입고(RMA R/W)
    { name: 'etcInRmaQty', fieldName: 'etcInRmaQty', width: 60, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'etcInRmaAmt', fieldName: 'etcInRmaAmt', width: 85, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
    // 기타입고(전월 불량)
    { name: 'etcInPrevDefQty', fieldName: 'etcInPrevDefQty', width: 60, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'etcInPrevDefAmt', fieldName: 'etcInPrevDefAmt', width: 85, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
    // 기타입고(당월 불량)
    { name: 'etcInCurDefQty', fieldName: 'etcInCurDefQty', width: 60, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'etcInCurDefAmt', fieldName: 'etcInCurDefAmt', width: 85, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
    // 타계정출고
    { name: 'outEtcQty', fieldName: 'outEtcQty', width: 60, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'outEtcAmt', fieldName: 'outEtcAmt', width: 85, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
    // 기타출고(LOT변환)
    { name: 'etcOutLotQty', fieldName: 'etcOutLotQty', width: 60, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'etcOutLotAmt', fieldName: 'etcOutLotAmt', width: 85, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
    // 기타출고(기타)
    { name: 'etcOutEtcQty', fieldName: 'etcOutEtcQty', width: 60, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'etcOutEtcAmt', fieldName: 'etcOutEtcAmt', width: 85, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
    // 불량률, EOH
    { name: '불량률', fieldName: '불량률', width: 50, header: { text: '불량률(%)' }, styleName: 'tr', numberFormat: '#,##0.00' },
    { name: 'eohQty', fieldName: 'eohQty', width: 60, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
    { name: 'eohAmt', fieldName: 'eohAmt', width: 85, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  ],
};

module.exports = grid;
