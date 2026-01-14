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
  { fieldName: 'rmaInQty', dataType: ValueType.NUMBER },
  { fieldName: 'rmaInAmt', dataType: ValueType.NUMBER }, 
  { fieldName: 'rmaOutQty', dataType: ValueType.NUMBER },
  { fieldName: 'rmaOutAmt', dataType: ValueType.NUMBER },  
  { fieldName: '불량률', dataType: ValueType.NUMBER },  
  { fieldName: 'eohQty', dataType: ValueType.NUMBER },
  { fieldName: 'eohAmt', dataType: ValueType.NUMBER },
  ],
  columnLayout: [
    { 
      column: '구분',
      spanCallback: (grid, layout, itemIndex) => {
        const rowType = (grid.getValue(itemIndex, 'rowType') || '').toString();
        const gubun = (grid.getValue(itemIndex, '구분') || '').toString();
        
        if (rowType === 'SUBTOTAL') return 5;
        if (rowType === 'GRAND_TOTAL') return 5;
        if (rowType === 'TOTAL' && gubun === '판매처별') return 2;
        if (rowType === 'TOTAL') return 5;
        return 1;
      }
    },
    { 
      column: '모델',
      spanCallback: (grid, layout, itemIndex) => {
        const rowType = (grid.getValue(itemIndex, 'rowType') || '').toString();
        const gubun = (grid.getValue(itemIndex, '구분') || '').toString();
        
        if (rowType === 'SUBTOTAL') return 5;
        if (rowType === 'GRAND_TOTAL') return 5;
        if (rowType === 'TOTAL' && gubun === '판매처별') return 2;
        if (rowType === 'TOTAL') return 5;
        return 1;
      }
    },
    { 
      column: 'inch',
      spanCallback: (grid, layout, itemIndex) => {
        const rowType = (grid.getValue(itemIndex, 'rowType') || '').toString();
        const gubun = (grid.getValue(itemIndex, '구분') || '').toString();
        
        if (rowType === 'SUBTOTAL') return 5;
        if (rowType === 'GRAND_TOTAL') return 5;
        if (rowType === 'TOTAL' && gubun === '판매처별') return 3;
        if (rowType === 'TOTAL') return 5;
        return 1;
      }
    },
    { 
      column: '판매처',
      spanCallback: (grid, layout, itemIndex) => {
        const rowType = (grid.getValue(itemIndex, 'rowType') || '').toString();
        const gubun = (grid.getValue(itemIndex, '구분') || '').toString();
        
        if (rowType === 'SUBTOTAL') return 5;
        if (rowType === 'GRAND_TOTAL') return 5;
        if (rowType === 'TOTAL' && gubun === '판매처별') return 3;
        if (rowType === 'TOTAL') return 5;
        return 1;
      }
    },
    { 
      column: '월',
      spanCallback: (grid, layout, itemIndex) => {
        const rowType = (grid.getValue(itemIndex, 'rowType') || '').toString();
        const gubun = (grid.getValue(itemIndex, '구분') || '').toString();
        
        if (rowType === 'SUBTOTAL') return 5;
        if (rowType === 'GRAND_TOTAL') return 5;
        if (rowType === 'TOTAL' && gubun === '판매처별') return 3;
        if (rowType === 'TOTAL') return 5;
        return 1;
      }
    },
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
      name: 'grpOUT',
      header: { text: '출고(OUT)' },
      direction: 'horizontal',
      items: [
        { column: 'outQty' },
        { column: 'outAmt' }
      ],
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
      name: 'grpRmaOut',
      header: { text: '타계정출고(RMA_OUT)' },
      direction: 'horizontal',
      items: [
        { column: 'rmaOutQty' },
        { column: 'rmaOutAmt' }
      ]
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
  { name: 'outQty', fieldName: 'outQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'outAmt', fieldName: 'outAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'lossQty', fieldName: 'lossQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'lossAmt', fieldName: 'lossAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'rmaInQty', fieldName: 'rmaInQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'rmaInAmt', fieldName: 'rmaInAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },  
  { name: 'rmaOutQty', fieldName: 'rmaOutQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'rmaOutAmt', fieldName: 'rmaOutAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: '불량률', fieldName: '불량률', width: 80, header: { text: '불량률(%)' }, styleName: 'tr', numberFormat: '#,##0.00' },  
  { name: 'eohQty', fieldName: 'eohQty', width: 80, header: { text: '수량' }, styleName: 'tr', numberFormat: '#,##0' },
  { name: 'eohAmt', fieldName: 'eohAmt', width: 100, header: { text: '금액' }, styleName: 'tr', numberFormat: '#,##0' },
  ],
};

module.exports = grid;
