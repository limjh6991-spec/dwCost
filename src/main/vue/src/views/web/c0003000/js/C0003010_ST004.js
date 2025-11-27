/*
 * 제품수불 체크 > ST004: 원가항목 정합성 검증 (expen_sel NULL/불일치 체크)
 */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: false },
    copy: { enabled: true, singleMode: false },
    display: {
      columnMovable: false,
      editItemMerging: true,
      fitStyle: 'even',
      emptyMessage: '✅ 모든 원가항목이 정상입니다!',
      hscrollBar: true,
      showEmptyMessage: true,
    },
    edit: { editable: false },
    footer: { visible: false },
    header: { height: 30 },
    hideDeletedRows: true,
    paste: { enabled: false },
    stateBar: { visible: false },
    sorting: { enabled: true, style: 'inclusive' },
  },
  fields: [
    { fieldName: 'tableName', dataType: 'text' },
    { fieldName: 'model', dataType: 'text' },
    { fieldName: 'gubun', dataType: 'text' },
    { fieldName: 'expenSel', dataType: 'text' },
    { fieldName: 'errorType', dataType: 'text' },
    { fieldName: 'remark', dataType: 'text' },
  ],
  columns: [
    {
      name: 'tableName',
      fieldName: 'tableName',
      type: 'data',
      width: 180,
      header: { text: '테이블' },
      styleName: 'center-column',
      styleCallback: function (grid, dataCell) {
        const value = dataCell.value;
        if (value === 'DOI_COST') {
          return { background: '#e7f3ff', foreground: '#0066cc', fontBold: true };
        } else if (value === 'DOI_STOCK_BOH') {
          return { background: '#d1e7dd', foreground: '#0f5132', fontBold: true };
        } else if (value === 'DOI_STCO') {
          return { background: '#fff3cd', foreground: '#664d03', fontBold: true };
        }
      },
    },
    {
      name: 'model',
      fieldName: 'model',
      type: 'data',
      width: 150,
      header: { text: '모델' },
      styleName: 'left-column',
    },
    {
      name: 'gubun',
      fieldName: 'gubun',
      type: 'data',
      width: 100,
      header: { text: '구분' },
      styleName: 'center-column',
    },
    {
      name: 'expenSel',
      fieldName: 'expenSel',
      type: 'data',
      width: 120,
      header: { text: '원가항목' },
      styleName: 'center-column',
      styleCallback: function (grid, dataCell) {
        const value = dataCell.value;
        if (!value || value === 'NULL') {
          return {
            background: '#f8d7da',
            foreground: '#842029',
            fontBold: true,
          };
        }
      },
    },
    {
      name: 'errorType',
      fieldName: 'errorType',
      type: 'data',
      width: 150,
      header: { text: '오류유형' },
      styleName: 'center-column',
      styleCallback: function (grid, dataCell) {
        const value = dataCell.value;
        if (value === 'NULL값 존재') {
          return { background: '#f8d7da', foreground: '#842029', fontBold: true };
        } else if (value === '원가항목 누락') {
          return { background: '#fff3cd', foreground: '#664d03' };
        }
      },
    },
    {
      name: 'remark',
      fieldName: 'remark',
      type: 'data',
      width: 400,
      header: { text: '비고' },
      styleName: 'left-column',
    },
  ],
};

export default grid;
