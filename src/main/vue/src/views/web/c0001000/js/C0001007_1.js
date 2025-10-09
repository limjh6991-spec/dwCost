/*
* 기준정보 > 일반코드
*/
const { ValueType, SelectionStyle, SelectionMode, GridFitStyle} = require('realgrid');

const grid = {
	dataProvider: null,
	gridView: null,
	options: {
		checkBar: { visible: true },
		copy: { enabled: true, singleMode: true },
		//dataDrop: {},
		display: {
			columnMovable: false,
			editItemMerging: false,
			selectionStyle: SelectionStyle.SINGLE_ROW,
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
		rowIndicator: { visible: true },
		sorting: { enabled: true },
		//sortMode: {},
		stateBar: { visible: true },
		//summaryMode: {},
	},

	fields: [
		{ fieldName: 'majCodeName', dataType: ValueType.TEXT },
		{ fieldName: 'majCode', dataType: ValueType.TEXT },
	],

	columns: [
		{ name: 'majCodeName', fieldName: 'majCodeName', width: '200', header: { text: '대분류' }, editable: true, editor: {maxLength: 20}, autoFilter:true },
		{ name: 'majCode', fieldName: 'majCode', width: '200', header: { text: '코드' }, editable: false, editor: {maxLength: 3}, numberFormat: "#,##0" , autoFilter:true},
	],
}

module.exports = grid;