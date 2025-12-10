/**
 * 재공,제품원가 - 매출원가(제품)
 */

const { ValueType } = require('realgrid');
const gubunMergeCriteria = "values['mergeKeyGubun']";
const commonMergeCriteria = "values['mergeKey']";

const tab090007GridField = {
  options: {
    edit: { editable: false },
    display: {
      columnMovable: false, 
      editItemMerging: true, 
      fitStyle: 'even', 
      emptyMessage: '조회된 데이터가 없습니다.', 
      hscrollBar: true, 
      showEmptyMessage: true,
      headerDepth: 3,
     },
    footer: { visible: false },
    // fixed: { colBarWidth: 1, colCount: 4 },
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
  { fieldName: 'eohQty', dataType: ValueType.NUMBER },
  { fieldName: 'eohAmt', dataType: ValueType.NUMBER },
  { fieldName: 'inMatQty', dataType: ValueType.NUMBER },
  { fieldName: 'inMatAmt', dataType: ValueType.NUMBER },
  { fieldName: 'inEtcQty', dataType: ValueType.NUMBER },
  { fieldName: 'inEtcAmt', dataType: ValueType.NUMBER },
  { fieldName: 'rmaInQty', dataType: ValueType.NUMBER },
  { fieldName: 'rmaInAmt', dataType: ValueType.NUMBER },
  { fieldName: 'outGoodQty', dataType: ValueType.NUMBER },
  { fieldName: 'outGoodAmt', dataType: ValueType.NUMBER },
  { fieldName: 'outEtcQty', dataType: ValueType.NUMBER },
  { fieldName: 'outEtcAmt', dataType: ValueType.NUMBER },
  ],
  columnLayout: [
    { column: '구분' },
    { column: '모델' },
    { column: 'inch' },
    { column: '판매처' },
    { column: '월' },
    {
      name: 'grpCOGS',
      header: { text: '매출원가' },
      direction: 'horizontal',
      items: [
        {
          name: 'grpBOH',
          header: { text: '기초(BOH)' },
          direction: 'horizontal',
          items: [
            { column: 'bohQty' },
            { column: 'bohAmt' }
          ],
        },
        {
          name: 'grpIN',
          header: { text: '입고(IN)' },
          direction: 'horizontal',
          items: [
            { column: 'inQty' },
            { column: 'inAmt' }
          ],
        }, 
        {
          name: 'grpOUT',
          header: { text: '출고(OUT)' },
          direction: 'horizontal',
          items: [
            { column: 'outQty' },
            { column: 'outAmt' }
          ],
        }, 
        {
          name: 'grpEOH',
          header: { text: '재고(EOH)' },
          direction: 'horizontal',
          items: [
            { column: 'eohQty' },
            { column: 'eohAmt' }
          ],
        }, 
      ],
    },
    {
      name: 'grpInDetail',
      header: { text: '입고상세' },
      direction: 'horizontal',
      items: [
        { 
          name: 'grpMat',
          header: { text: '자재' },
          direction: 'horizontal',
          items: [
            { column: 'inMatQty' },
            { column: 'inMatAmt' }
          ] 
        },
        { 
          name: 'grpInEtc',
          header: { text: '타계정' },
          direction: 'horizontal',
          items: [
            { column: 'inEtcQty' },
            { column: 'inEtcAmt' }
          ] 
        },
        { 
          name: 'grpRma',
          header: { text: 'RMA' },
          direction: 'horizontal',
          items: [
            { column: 'rmaInQty' },
            { column: 'rmaInAmt' }
          ]
        },
      ],
    },
    {
      name: 'grpOutDetail',
      header: { text: '출고상세' },
      direction: 'horizontal',
      items: [
        {
          name: 'grpOutGood',
          header: { text: '양품' },
          direction: 'horizontal',
          items: [
            { column: 'outGoodQty' },
            { column: 'outGoodAmt' }
          ],
        },
        {
          name: 'grpOutEtc',
          header: { text: '타계정' },
          direction: 'horizontal',
          items: [
            { column: 'outEtcQty' },
            { column: 'outEtcAmt' }
          ]
        },
      ]
    },
  ],
  columns: [
  { 
    name: '구분',
    fieldName: '구분',
    width: 80,
    header: { text: '구분' },
    styleName: 'tc',
    mergeRule: { 
      criteria: gubunMergeCriteria,
    } 
  },
  { 
    name: '모델',
    fieldName: '모델',
    width: 100,
    header: { text: '모델' },
    styleName: 'tc',
    mergeRule: { 
      criteria: commonMergeCriteria,
    } 
  },
  { 
    name: 'inch',
    fieldName: 'inch', 
    width: 60, 
    header: { text: '인치' }, 
    styleName: 'tc', 
    mergeRule: {
      criteria: commonMergeCriteria,
    } 
  },
  { 
    name: '판매처', 
    fieldName: '판매처', 
    width: 60, 
    header: { text: '판매처' }, 
    styleName: 'tc', 
    mergeRule: { 
      criteria: commonMergeCriteria,
    } 
  },
  { name: 'rowType', fieldName: 'rowType', visible: false },
  { name: '월', fieldName: '월', width: 60, header: { text: '' }, styleName: 'tc' },
  { name: 'bohQty', fieldName: 'bohQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'bohAmt', fieldName: 'bohAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'inQty', fieldName: 'inQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'inAmt', fieldName: 'inAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'outQty', fieldName: 'outQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'outAmt', fieldName: 'outAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'eohQty', fieldName: 'eohQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'eohAmt', fieldName: 'eohAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'inMatQty', fieldName: 'inMatQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'inMatAmt', fieldName: 'inMatAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'inEtcQty', fieldName: 'inEtcQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'inEtcAmt', fieldName: 'inEtcAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'rmaInQty', fieldName: 'rmaInQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'rmaInAmt', fieldName: 'rmaInAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'outGoodQty', fieldName: 'outGoodQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'outGoodAmt', fieldName: 'outGoodAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'outEtcQty', fieldName: 'outEtcQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'outEtcAmt', fieldName: 'outEtcAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  ],
};

export default tab090007GridField;
