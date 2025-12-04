export const inputGridColumns = [
  {
    name: 'yyyymm',
    fieldName: 'yyyymm',
    header: { text: '년월' },
    width: 80,
    editable: false,
    styleName: 'text-center bg-light'
  },
  {
    name: 'selCode',
    fieldName: 'selCode',
    header: { text: '구분' },
    width: 80,
    editable: false,
    styleName: 'text-center bg-light'
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
    header: { text: '사업장' },
    width: 80,
    editable: false,
    styleName: 'text-center bg-light'
  },
  {
    name: '도우코드',
    fieldName: '도우코드',
    header: { text: '도우코드' },
    width: 150,
    editable: false,
    styleName: 'text-left cursor-pointer',
    renderer: {
      type: 'text',
      showTooltip: true
    }
  },
  {
    name: 'rmaIn',
    fieldName: 'rmaIn',
    header: { text: 'RMA_IN' },
    width: 120,
    editable: true,
    numberFormat: '#,##0',
    editor: { type: 'number' }
  },
  {
    name: 'rmaOut',
    fieldName: 'rmaOut',
    header: { text: 'RMA_OUT' },
    width: 120,
    editable: true,
    numberFormat: '#,##0',
    editor: { type: 'number' }
  }
];

export const inputGridFields = [
  { fieldName: 'yyyymm', dataType: 'text' },
  { fieldName: 'selCode', dataType: 'text' },
  { fieldName: 'siteOrg', dataType: 'text' },
  { fieldName: 'site', dataType: 'text' },
  { fieldName: '도우코드', dataType: 'text' },
  { fieldName: 'rmaIn', dataType: 'number' },
  { fieldName: 'rmaOut', dataType: 'number' },
];

export const inputGridOptions = {
	  checkBar: { visible: true, exclusive: false, syncHeadCheck: true },
		copy: { enabled: true, singleMode: true },
		//dataDrop: {},
		display: { columnMovable: false, editItemMerging: true, fitStyle: "evenFill" },
		edit: { editable: true,commitByCell:true },
		//editor: {},
		//filtering: {},
		//filterMode: {},
		//filterPanel: {},
		//fixed: {},
		//footer: {height:40},
		footers: {visible:false},
		//format: {},
		header: { height: 25 },
		//headerSummaries: {visible:false},
		//headerSummary: {height:40},
		//hideDeletedRows: {},
		paste: { enabled: false },
		rowIndicator: {visible:false},
		sorting: {enabled: false},
		//sortMode: {},
		stateBar: {visible:false},
		//summaryMode: {},
};
