/*
* 기준정보 > 원가 자재코드 관리
*/
const { ValueType } = require('realgrid');

const grid = {

	options: {
		checkBar: { visible: true, exclusive: false,syncHeadCheck:true },
		copy: { enabled: true, singleMode: false },
		//dataDrop: {},
		display: { columnMovable: false, editItemMerging: true, fitStyle: "fill" },
		edit: { editable: true, commitByCell: true },
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
		hideDeletedRows: true,
		paste: { enabled: true },
		rowIndicator: { visible: true },
		sorting: { enabled: false },
		//sortMode: {},
		stateBar: { visible: true },
		//summaryMode: {},
	},
	fields: [
		{ fieldName: 'yyyy', dataType: ValueType.TEXT },
		{ fieldName: 'selCode', dataType: ValueType.TEXT },
		{ fieldName: 'site', dataType: ValueType.TEXT },  
		{ fieldName: 'matCode', dataType: ValueType.TEXT },
		{ fieldName: 'matDesc', dataType: ValueType.TEXT },
		{ fieldName: 'expenSel', dataType: ValueType.TEXT },
		{ fieldName: 'size', dataType: ValueType.TEXT },
		{ fieldName: 'matClass', dataType: ValueType.TEXT },
		{ fieldName: 'gubun', dataType: ValueType.TEXT },
	],
	
	columns: [
		{ name: 'YYYY', fieldName: 'yyyy', width: '80', header: { text: '년도' }, autoFilter: true },
		{ name: 'SEL_CODE', fieldName: 'selCode', width: '80', header: { text: 'SEL_CODE' }, autoFilter: true },
		{ name: 'SITE', fieldName: 'site', width: '80', header: { text: '사이트' }, autoFilter: true },
		{ name: 'MAT_CODE', fieldName: 'matCode', width: '150', header: { text: '자재코드' }, autoFilter: true },
		{ name: 'MAT_DESC', fieldName: 'matDesc', width: '90', header: { text: '자재명' }, autoFilter: true },
		{ name: 'EXPEN_SEL', fieldName: 'expenSel', width: '70', header: { text: '원가항목' }, autoFilter: true,},
		{ name: 'SIZE', fieldName: 'size', width: '90', header: { text: '사용공정' }, autoFilter: true },
		{ name: 'MAT_CLASS', fieldName: 'matClass', width: '70', header: { text: '사용제품' }, autoFilter: true },
		{ name: '', fieldName: 'gubun', width: '120', header: { text: '비고' }, autoFilter: true }, 	]	
}

module.exports = grid;