/*
 * 타시스템 I/F&Upload > 불량반품 - 조회용 그리드
 */
const { ValueType } = require('realgrid');

function isNewRow(dataCell) {
  return dataCell.item &&
    (dataCell.item.rowState === 'created' ||
     dataCell.item.itemState === 'appending' ||
     dataCell.item.itemState === 'inserting');
}

// 고정 컬럼
function readOnly(styleName = 'tl') {
  return function () {
    return { editable: false, styleName };
  };
}

// 추가 행 편집 스타일
function addNewRow(styleName = 'edit tl') {
  return function (grid, dataCell) {
    const canEdit = isNewRow(dataCell);
    return {
      editable: canEdit,
      styleName: canEdit ? `edit ${styleName}` : styleName,
    };
  };
}

const fields = [
  { fieldName: 'rowSeq', dataType: ValueType.NUMBER },
  { fieldName: 'yyyymm', dataType: ValueType.TEXT },
  { fieldName: 'selCode', dataType: ValueType.TEXT },
  { fieldName: 'siteOrg', dataType: ValueType.TEXT },
  { fieldName: 'site', dataType: ValueType.TEXT },
  { fieldName: '구분', dataType: ValueType.TEXT },
  { fieldName: '도우코드', dataType: ValueType.TEXT },
  { fieldName: 'rmaIn', dataType: ValueType.NUMBER },
  { fieldName: 'rmaOut', dataType: ValueType.NUMBER },
  { fieldName: 'outMonth', dataType: ValueType.NUMBER },
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
    footer: { visible: true, height: 30 },
    header: { height: 25 },
    hideDeletedRows: false,
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
      styleName: 'tc',
      styleCallback: readOnly('tc'),
    },
    { 
      name: 'selCode', 
      fieldName: 'selCode', 
      width: 80, 
      header: { text: 'SEL_CODE' }, 
      autoFilter: true, 
      styleName: 'tc',
      styleCallback: readOnly('tc'), 
    },
    { 
      name: 'siteOrg', 
      fieldName: 'siteOrg', 
      width: 0, 
      header: { text: 'SITE_ORG' }, 
      visible: false, 
      styleName: 'tc',
    },
    { 
      name: 'site', 
      fieldName: 'site', 
      width: 80, 
      header: { text: '사이트' }, 
      autoFilter: true, 
      styleName: 'tc',
      styleCallback: readOnly('tc'),
    },
    { 
      name: '구분', 
      fieldName: '구분', 
      width: 80, 
      header: { text: '구분' }, 
      autoFilter: true, 
      styleName: 'tc',
      styleCallback: readOnly('tc'),
    },
    { 
      name: '도우코드', 
      fieldName: '도우코드', 
      width: 150, 
      header: { text: '도우코드' }, 
      autoFilter: true, 
      styleName: 'tc',
      styleCallback: readOnly('tc'),
    },
    { 
      name: 'rmaIn', 
      fieldName: 'rmaIn', 
      width: 120, 
      header: { text: 'RMA_IN' }, 
      autoFilter: true, 
      editable: true,
      styleName: 'tr',
      styleCallback: addNewRow('tr'),      
      numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }
    },
    { 
      name: 'rmaOut', 
      fieldName: 'rmaOut', 
      width: 120, 
      header: { text: 'RMA_OUT' }, 
      autoFilter: true, 
      editable: true,
      styleName: 'tr',
      styleCallback: addNewRow('tr'),
      numberFormat: '#,##0',
      footer: { expression: 'sum', numberFormat: '#,##0', styleName: 'sum-footer1' }
    },
    {
    name: 'outMonth',
    fieldName: 'outMonth',
    width: 0,
    visible: false,
    header: { text: 'OUT_MONTH' },
    styleName: 'tr',
    }
  ],
};

module.exports = viewGrid;
