/*
* 기준정보 > 사용자-메뉴 권한 관리 - 메뉴
*/
const { ValueType, SelectionMode, SelectionStyle, GridFitStyle } = require('realgrid');

const grid = {
	
	options: {
		checkBar: { visible: false },
		copy: { enabled: true, singleMode: true },
		//dataDrop: {},
		display: { 
			columnMovable: false, 
			editItemMerging: true,
			selectionMode: SelectionMode.SINGLE,
			selectionStyle:SelectionStyle.SINGLE_ROW,
			fitStyle: GridFitStyle.EVEN_FILL,
		},
		edit: { editable: true },
		//editor: {},
		//filtering: {},
		//filterMode: {},
		//filterPanel: {},
		//fixed: {},
		footer: {visible: false},
		//footers: {},
		//format: {},
		header: { height: 25 },
		//headerSummaries: {},
		//headerSummary: {},
		//hideDeletedRows: {},
		// paste: { enabled: false },
		rowIndicator: { visible : false},
		sorting: {enabled: false },
		//sortMode: {},
		stateBar: { visible: true },
		//summaryMode: {},
	},

	fields: [
		{ fieldName: 'prodCategory', dataType: ValueType.TEXT },
		{ fieldName: 'sysResourceId', dataType: ValueType.TEXT },
		{ fieldName: 'sysResourceName', dataType: ValueType.TEXT },
		{ fieldName: 'upperSysResourceId', dataType: ValueType.TEXT },
		{ fieldName: 'sysResourceTypeCodeId', dataType: ValueType.TEXT },
		{ fieldName: 'description', dataType: ValueType.TEXT },
		{ fieldName: 'seq', dataType: ValueType.TEXT },
		{ fieldName: 'url', dataType: ValueType.TEXT },
		{ fieldName: 'fullPath', dataType: ValueType.TEXT },
		{ fieldName: 'level', dataType: ValueType.NUMBER },
		{ fieldName: 'fullSeq', dataType: ValueType.TEXT },
		{ fieldName: 'orgSysResourceId', dataType: ValueType.TEXT },
	],

	columns: [
		{ name: 'sysResourceName', fieldName: 'sysResourceName', width: '250', header: { text: '메뉴명' }},		
		{ name: 'sysResourceId', fieldName: 'sysResourceId', width: '200', header: { text: 'SYS RESOURCE ID' }},
		{ name: 'sysResourceTypeCodeId', fieldName: 'sysResourceTypeCodeId', width: '200', header: { text: 'TYPE' }},
		{ name: 'description', fieldName: 'description', width: '200', header: { text: '설명' }},
		{ name: 'seq', fieldName: 'seq', width: '200', header: { text: 'SEQ' }},
		{ name: 'url', fieldName: 'url', width: '200', header: { text: 'URL' }},
	],
}

module.exports = grid;