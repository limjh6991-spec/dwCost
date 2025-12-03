/*
 * 타시스템 I/F&Upload > 불량반품 - 조회용 그리드
 */
const { values } = require('lodash');
const { ValueType } = require('realgrid');

const fields = [
  { fieldName: 'rowSeq', dataType: ValueType.NUMBER },
  { fieldName: 'yyyymm', dataType: ValueType.TEXT },
  { fieldName: 'selCode', dataType: ValueType.TEXT },
  { fieldName: 'siteOrg', dataType: ValueType.TEXT },
  { fieldName: 'site', dataType: ValueType.TEXT },
  { fieldName: '구분', dataType: ValueType.TEXT },
  { fieldName: '모델명', dataType: ValueType.TEXT },
  { fieldName: 'rmaIn', dataType: ValueType.NUMBER },
  { fieldName: 'rmaOut', dataType: ValueType.NUMBER },
];

const viewGrid = {
  options: {
    checkBar: { visible: true, exclusive: false, syncHeadCheck: true },
    copy: { enabled: true, singleMode: false },
    display: {
      columnMovable: false,
      editItemMerging: true,
      fitStyle: 'fill',
      emptyMessage: '조회된 데이터가 없습니다.',
      hscrollBar: true,
      showEmptyMessage: true,
      rowHeight: 30,
      showEmptyRows: true,
    },
    edit: { editable: true, insertable: false, appendable: false },
    footer: { visible: true, height: 25 },
    header: { height: 25 },
    hideDeletedRows: true,
    paste: { enabled: false },
    rowIndicator: { visible: true },
    sorting: { enabled: false },
    stateBar: { visible: true },
  },

  fields,
  columns: [
    { 
      name: 'rowSeq', 
      fieldName: 'rowSeq', 
      width: 0, 
      visible: false
    },
    { 
      name: 'yyyymm', 
      fieldName: 'yyyymm', 
      width: 80, 
      header: { text: 'YYYYMM' }, 
      autoFilter: true, 
      styleName: 'tl',
      editable: false 
    },
    { 
      name: 'selCode', 
      fieldName: 'selCode', 
      width: 80, 
      header: { text: 'SEL_CODE' }, 
      autoFilter: true, 
      styleName: 'tl',
      editable: false 
    },
    { 
      name: 'siteOrg', 
      fieldName: 'siteOrg', 
      width: 0, 
      header: { text: 'SITE_ORG' }, 
      visible: false, 
      styleName: 'tl',
      editable: false 
    },
    { 
      name: 'site', 
      fieldName: 'site', 
      width: 80, 
      header: { text: '사이트' }, 
      autoFilter: true, 
      styleName: 'tl',
      editable: false 
    },
    { 
      name: '구분', 
      fieldName: '구분', 
      width: 80, 
      header: { text: '구분' }, 
      autoFilter: true, 
      styleName: 'tl',
      editable: true,
      lookupDisplay: true,
      editor: {
        type: 'dropdown',
        textReadOnly: true,
        dropDownWhenClick: true,
        domainOnly: true,
      },
    },
    { 
      name: '모델명', 
      fieldName: '모델명', 
      width: 150, 
      header: { text: '모델명' }, 
      autoFilter: true, 
      styleName: 'tl cursor-pointer',
      editable: false 
    },
    { 
      name: 'rmaIn', 
      fieldName: 'rmaIn', 
      width: 120, 
      header: { text: 'RMA_IN' }, 
      autoFilter: true, 
      styleName: 'tr',
      editable: true,
      editor: { type: 'number' },
      numberFormat: '#,##0'
    },
    { 
      name: 'rmaOut', 
      fieldName: 'rmaOut', 
      width: 120, 
      header: { text: 'RMA_OUT' }, 
      autoFilter: true, 
      styleName: 'tr',
      editable: true,
      editor: { type: 'number' },
      numberFormat: '#,##0'
    },
  ],
};

module.exports = { viewGrid };
