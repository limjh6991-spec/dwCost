/**
 * Tab090001 - 월별 집계 (수량)
 * RealGrid Definition
 */
const { ValueType } = require('realgrid');
const gubunMergeCriteria = "values['mergeKeyGubun']";
const commonMergeCriteria = "values['mergeKey']";

const tab090001GridField = {
  options: {
    edit: { editable: false },
    display: {
      columnMovable: false, 
      editItemMerging: true, 
      fitStyle: 'even', 
      emptyMessage: '조회된 데이터가 없습니다.', 
      hscrollBar: true, 
      showEmptyMessage: true,
     },
    footer: { visible: true },
    filtering: { enabled: true },
  },  
  fields: [
    { fieldName: '구분', dataType: ValueType.TEXT },
    { fieldName: '모델', dataType: ValueType.TEXT },
    { fieldName: 'inch', dataType: ValueType.TEXT },
    { fieldName: 'dwSite', dataType: ValueType.TEXT },
    { fieldName: 'rowType', dataType: ValueType.TEXT },
    { fieldName: "totalKind", dataType: ValueType.TEXT },    
    { fieldName: '월', dataType: ValueType.TEXT },
    { fieldName: 'mergeKey', dataType: ValueType.TEXT },
    { fieldName: 'mergeKeyGubun', dataType: ValueType.TEXT },    
    { fieldName: '계획', dataType: ValueType.NUMBER },
    { fieldName: '실적', dataType: ValueType.NUMBER },
    { fieldName: '달성률', dataType: ValueType.NUMBER },
    { fieldName: 'boh', dataType: ValueType.NUMBER },
    { fieldName: 'in', dataType: ValueType.NUMBER },
    { fieldName: 'out', dataType: ValueType.NUMBER },
    { fieldName: 'outEtc', dataType: ValueType.NUMBER },
    { fieldName: 'loss', dataType: ValueType.NUMBER },
    { fieldName: 'eoh', dataType: ValueType.NUMBER },
    { fieldName: '불량률', dataType: ValueType.NUMBER },
    { fieldName: '수율', dataType: ValueType.NUMBER },
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
      width: 80,
      header: { text: '인치' },
      styleName: 'tc',
      mergeRule: { 
        criteria: commonMergeCriteria,
      }      
    },
    {
      name: 'dwSite',
      fieldName: 'dwSite',
      width: 80,
      header: { text: '판매처' },
      styleName: 'tc',
      mergeRule: { 
        criteria: commonMergeCriteria,
      }         
    },
    { name: "rowType", fieldName: "rowType", visible: false },
    { name: "totalKind", fieldName: "totalKind", visible: false },    
    { name: '월', fieldName: '월', width: 60, header: { text: '월' }, autoFilter: true, styleName: 'tc' },    
    {
      name: '계획',
      fieldName: '계획',
      width: 100,
      header: { text: '계획' },
      styleName: 'tr',
      numberFormat: '#,##0',
    },
    {
      name: '실적',
      fieldName: '실적',
      width: 100,
      header: { text: '실적' },
      styleName: 'tr',
      numberFormat: '#,##0',
      // footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", }
    },
    {
      name: '달성률',
      fieldName: '달성률',
      width: 100,
      header: { text: '달성률' },
      styleName: 'tr',
      numberFormat: '#,##0.00%',
    },
    {
      name: 'boh',
      fieldName: 'boh',
      width: 100,
      header: { text: 'BOH' },
      styleName: 'tr',
      numberFormat: '#,##0',
      footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", }
    },
    {
      name: 'in',
      fieldName: 'in',
      width: 100,
      header: { text: 'IN' },
      styleName: 'tr',
      numberFormat: '#,##0',
      footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", }
    },
    {
      name: 'out',
      fieldName: 'out',
      width: 100,
      header: { text: 'OUT' },
      styleName: 'tr',
      numberFormat: '#,##0',
      footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", }
    },
    {
      name: 'loss',
      fieldName: 'loss',
      width: 100,
      header: { text: 'LOSS' },
      styleName: 'tr',
      numberFormat: '#,##0',
      footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", }
    },
    {
      name: 'eoh',
      fieldName: 'eoh',
      width: 100,
      header: { text: 'EOH' },
      styleName: 'tr',
      numberFormat: '#,##0',
      footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", }
    },
    {
      name: 'outEtc',
      fieldName: 'outEtc',
      width: 100,
      header: { text: 'OUT_ETC' },
      styleName: 'tr',
      numberFormat: '#,##0',
      footer: { expression: "sum", numberFormat: "#,##0", styleName: "sum-footer1", }
    },
    {
      name: '불량률',
      fieldName: '불량률',
      width: 100,
      header: { text: '불량률' },
      styleName: 'tr',
      numberFormat: '#,##0.00%',
    },
    {
      name: '수율',
      fieldName: '수율',
      width: 100,
      header: { text: '수율' },
      styleName: 'tr',
      numberFormat: '#,##0.00%',
    },
  ],
  options: {
    edit: { editable: false },
    display: { fitStyle: 'evenFill' },
    footer: { visible: true },
  },
};

export default tab090001GridField;
