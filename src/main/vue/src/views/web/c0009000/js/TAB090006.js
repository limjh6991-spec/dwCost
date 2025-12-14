/**
 * 재공,제품원가 - 제조원가(재공)
 */

const { ValueType } = require('realgrid');
const gubunMergeCriteria = "values['mergeKeyGubun']";
const commonMergeCriteria = "values['mergeKey']";

const tab090006GridField = {
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
    filtering: { enabled: true },
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
  { fieldName: 'rmaInQty', dataType: ValueType.NUMBER },
  { fieldName: 'rmaInAmt', dataType: ValueType.NUMBER },  
  { fieldName: 'outQty', dataType: ValueType.NUMBER },
  { fieldName: 'outAmt', dataType: ValueType.NUMBER },
  { fieldName: 'rmaOutQty', dataType: ValueType.NUMBER },
  { fieldName: 'rmaOutAmt', dataType: ValueType.NUMBER },  
  { fieldName: 'lossQty', dataType: ValueType.NUMBER },
  { fieldName: 'lossAmt', dataType: ValueType.NUMBER },
  { fieldName: '불량률', dataType: ValueType.NUMBER },  
  { fieldName: 'eohQty', dataType: ValueType.NUMBER },
  { fieldName: 'eohAmt', dataType: ValueType.NUMBER },
  ],
  columnLayout: [
    { column: '구분' },
    { column: '모델' },
    { column: 'inch' },
    { column: '판매처' },
    { column: '월'},
    {
      name: 'grpBOH',
      header: { text: '기초재공품재고(BOH)' },
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
      name: 'grpRmaIn',
      header: { text: '타계정입고(RMA_IN)' },
      direction: 'horizontal',
      items: [
        { column: 'rmaInQty' },
        { column: 'rmaInAmt' }
      ] 
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
      name: 'grpRmaOut',
      header: { text: '타계정출고(RMA_OUT)' },
      direction: 'horizontal',
      items: [
        { column: 'rmaOutQty' },
        { column: 'rmaOutAmt' }
      ]
    },
    {
      name: 'grpLoss',
      header: { text: 'LOSS' },
      direction: 'horizontal',
      items: [
        { column: 'lossQty' },
        { column: 'lossAmt' }
      ],
    },
    { column: '불량률' },    
    {
      name: 'grpEOH',
      header: { text: '기말재공품재고(EOH)' },
      direction: 'horizontal',
      items: [
        { column: 'eohQty' },
        { column: 'eohAmt' }
      ],
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
  { name: '월', fieldName: '월', width: 60, header: { text: '' }, autoFilter: true, styleName: 'tc' },
  { name: 'bohQty', fieldName: 'bohQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'bohAmt', fieldName: 'bohAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'inQty', fieldName: 'inQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'inAmt', fieldName: 'inAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'rmaInQty', fieldName: 'rmaInQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'rmaInAmt', fieldName: 'rmaInAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },  
  { name: 'outQty', fieldName: 'outQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'outAmt', fieldName: 'outAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'rmaOutQty', fieldName: 'rmaOutQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'rmaOutAmt', fieldName: 'rmaOutAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'lossQty', fieldName: 'lossQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'lossAmt', fieldName: 'lossAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: '불량률', fieldName: '불량률', width: 80, header: { text: '불량률(%)' }, styleName: 'tr', numberFormat: '#,##0.00' },  
  { name: 'eohQty', fieldName: 'eohQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'eohAmt', fieldName: 'eohAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  ],
};

export default tab090006GridField;
