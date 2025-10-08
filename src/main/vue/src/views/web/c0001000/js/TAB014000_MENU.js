/*
* 기준정보 > 사용자-메뉴 권한 관리 - 메뉴
*/
const { ValueType, SelectionMode, SelectionStyle, GridFitStyle} = require('realgrid');

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
		stateBar: { visible: false },
		//summaryMode: {},
	},

	fields: [
		{ fieldName: 'sysResourceId', dataType: ValueType.TEXT },
		{ fieldName: 'upperSysResourceId', dataType: ValueType.TEXT },
		{ fieldName: 'fullPath', dataType: ValueType.TEXT },
		{ fieldName: 'sysResourceName', dataType: ValueType.TEXT },
		{ fieldName: 'seq', dataType: ValueType.NUMBER },
		{ fieldName: 'level', dataType: ValueType.NUMBER },
		{ fieldName: 'sysResourceTypeCodeId', dataType: ValueType.TEXT },
		{ fieldName: 'fullSeq', dataType: ValueType.TEXT },
		{ fieldName: 'menuTypeCodeId', dataType: ValueType.TEXT },
		{ fieldName: 'url', dataType: ValueType.TEXT },
		{ fieldName: 'hasAuth', dataType: ValueType.TEXT},
	],

	columns: [
		{ name: 'sysResourceName', fieldName: 'sysResourceName', width: '250', header: { text: '메뉴명' },editable:false },		
		{ name: 'sysResourceId', fieldName: 'sysResourceId', width: '200', header: { text: '메뉴ID' },editable:false },
		// { name: 'menuUrl', fieldName: 'menuUrl', width: '200', header: { text: 'URL' } ,editable:false},
		{ name: 'hasAuth', fieldName: 'hasAuth', width: '120', header: { text: 'HAS AUTH', checkLocation: "left"},editable:false,
			renderer: {
				type: "check",
				editable: true,				
				trueValues: "Y",
				falseValues: "N",				
			},
		},
	],
}

module.exports = grid;