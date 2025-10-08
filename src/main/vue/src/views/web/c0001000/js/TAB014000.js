/*
* 기준정보 > 사용자-메뉴 권한 관리-ROLE
*/
const { ValueType,SelectionStyle,SelectionMode, GridFitStyle} = require('realgrid');

const grid = {
	
	options: {
		checkBar: { visible: true,showAll:false },
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
		paste: { enabled: false },
		rowIndicator: { visible : false},
		sorting: {enabled: false },
		//sortMode: {},
		stateBar: { visible: true },
		//summaryMode: {},
	},

	fields: [
		{ fieldName: 'roleId', dataType: ValueType.TEXT },
		{ fieldName: 'roleName', dataType: ValueType.TEXT },
		{ fieldName: 'description', dataType: ValueType.TEXT },
	],

	columns: [
		{ name: 'roleId', fieldName: 'roleId', width: '100', header: { text: 'ROLE ID' },autoFilter:true },
		{ name: 'roleName', fieldName: 'roleName', width: '120', header: { text: 'ROLE NAME' },autoFilter:true,styleName:"tl edit" },
		{ name: 'description', fieldName: 'description', width: '250', header: { text: '설명' },autoFilter:true,styleName:"tl edit",renderer:{showTooltip:true}},
	],

}

module.exports = grid;