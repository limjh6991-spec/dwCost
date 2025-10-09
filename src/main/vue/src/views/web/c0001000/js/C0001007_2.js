/*
* 기준정보 > 일반코드
*/
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
		paste: { enabled: true,enableAppend:false,checkReadOnly:true },
		rowIndicator: { visible: true },
		sorting: { enabled: true },
		//sortMode: {},
		stateBar: { visible: true },
		//summaryMode: {},
	},

	fields: [
		{ fieldName: 'majCode', dataType: ValueType.TEXT },
		{ fieldName: 'code', dataType: ValueType.TEXT },
		{ fieldName: 'codeOrg', dataType: ValueType.TEXT },
		{ fieldName: 'codeName', dataType: ValueType.TEXT },
		{ fieldName: 'trayCell', dataType: ValueType.TEXT },
		{ fieldName: 'createDate', dataType: ValueType.TEXT },
		{ fieldName: 'useYn', dataType: ValueType.BOOLEAN },
		{ fieldName: 'sortOrder', dataType: ValueType.TEXT },
		{ fieldName: 'etc1', dataType: ValueType.TEXT },
		{ fieldName: 'etc2', dataType: ValueType.TEXT },
	],

	columns: [
		{ 
			name: 'majCode', fieldName: 'majCode', width: '200', header: { text: '대분류' }, sortable: false, autoFilter:true,
			styleCallback: function(grid, dataCell){
				var ret = {}
		
				if(dataCell.item.rowState == 'created' || dataCell.item.itemState == 'appending' || dataCell.item.itemState == 'inserting'){
				ret.editable = true;
				} else {
				ret.editable = false;
				}
		
				return ret;
			} 	
		},
		{ 
			name: 'code', fieldName: 'code', width: '200', header: { text: '코드' }, sortable: true, editable: true, editor: {maxLength: 10}, autoFilter:true,
			styleCallback: function(grid, dataCell){
				var ret = {}
		
				if(dataCell.item.rowState == 'created' || dataCell.item.itemState == 'appending' || dataCell.item.itemState == 'inserting' || dataCell.item.itemState == 'normal'){
				ret.editable = true;
				} else {
				ret.editable = false;
				}
		
				return ret;
			} 	
		},
		{ name: 'codeName', fieldName: 'codeName', width: '500', header: { text: '코드명' }, editable: true, editor: {maxLength: 50}, autoFilter:true },
		{ name: 'trayCell', fieldName: 'trayCell', width: '200', header: { text: 'Tray Cell' }, editable: true, sortable: true, editor: {maxLength: 3}, autoFilter:true },
		{ name: 'createDate', fieldName: 'createDate', width: '200', header: { text: '생성일' }, editable: false, sortable: true, autoFilter:true },
		{
			name: 'useYn', fieldName: 'useYn', width: '140', header: { text: '사용여부' }, editable: false, sortable: false, autoFilter:true,
			renderer: {
				type: "check",
				editable: true,
				trueValues: "1",
				falseValues: "0",
			},
		},
		{ name: 'sortOrder', fieldName: 'sortOrder', width: '200', header: { text: 'Sort Order' }, editable: true, sortable: true, autoFilter:true },
		{ name: 'etc1', fieldName: 'etc1', width: '200', header: { text: 'Etc1' }, editable: true, sortable: true, autoFilter:true },
		{ name: 'etc2', fieldName: 'etc2', width: '200', header: { text: 'Etc2' }, editable: true, sortable: true , autoFilter:true},
	],
}

module.exports = grid;