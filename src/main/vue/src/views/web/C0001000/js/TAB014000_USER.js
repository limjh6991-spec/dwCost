const { ValueType, SelectionStyle, SelectionMode, GridFitStyle} = require('realgrid');

const grid = {
	dataProvider: null,
	gridView: null,
	options: {
		checkBar: { visible: true },
		copy: { enabled: true, singleMode: false },
		//dataDrop: {},
		display: {
			columnMovable: false,
			editItemMerging: false,
			selectionStyle: SelectionStyle.ROWS,
			selectionMode: SelectionMode.SINGLE,
			fitStyle: GridFitStyle.EVEN_FILL,
		},
		edit: { editable: true },
		//editor: {},
		//filtering: {},
		//filterMode: {},
		//filterPanel: {},
		//fixed: {},
		footer: { visible: false },
		//footers: {},
		//format: {},
		header: { height: 25 },
		//headerSummaries: {},
		//headerSummary: {},
		//hideDeletedRows: {},
		paste: { enabled: false },
		rowIndicator: { visible: false },
		sorting: { enabled: false },
		//sortMode: {},
		stateBar: { visible: true },
		//summaryMode: {},
	},

	fields: [
		{ fieldName: 'userId', dataType: ValueType.TEXT },
		{ fieldName: 'userName', dataType: ValueType.TEXT },
		{ fieldName: 'deptCode', dataType: ValueType.TEXT },
		{ fieldName: 'deptName', dataType: ValueType.TEXT },
		{ fieldName: 'positionName', dataType: ValueType.TEXT },
		{ fieldName: 'positionCode', dataType: ValueType.TEXT },
		{ fieldName: 'utg', dataType: ValueType.TEXT },
		{ fieldName: 'itg', dataType: ValueType.TEXT },
		{ fieldName: 'delYn', dataType: ValueType.TEXT },
		{ fieldName: 'password', dataType: ValueType.TEXT },
	],

	columns: [
		{ name: 'deptName', fieldName: 'deptName', width: '200', header: { text: '부서명' },autoFilter:true },
		{ name: 'deptCode', fieldName: 'userId', width: '150', header: { text: '부서 CODE' },autoFilter:true },
		{ name: 'userName', fieldName: 'userName', width: '200', header: { text: '사용자명' },autoFilter:true },
		{ name: 'userId', fieldName: 'userId', width: '150', header: { text: '사용자 ID' },autoFilter:true },
		{ name: 'positionName', fieldName: 'positionName', width: '150', header: { text: '직책명' },autoFilter:true },
		{ name: 'positionCode', fieldName: 'positionCode', width: '150', header: { text: '직책 CODE' },autoFilter:true },
	],
}

module.exports = grid;