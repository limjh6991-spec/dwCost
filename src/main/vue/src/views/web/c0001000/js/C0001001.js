/*
* 프로세스 플래닝 >  제품 모델 관리 > 모델기본정보
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
		{ fieldName: 'acctClass', dataType: ValueType.TEXT },
		{ fieldName: 'acct', dataType: ValueType.TEXT },
		{ fieldName: 'acctName', dataType: ValueType.TEXT },
		{ fieldName: 'subName', dataType: ValueType.TEXT },
		{ fieldName: 'itemName', dataType: ValueType.TEXT },
		{ fieldName: 'expenSel', dataType: ValueType.TEXT },,
	],
	
	columns: [
		{ name: 'YYYY', fieldName: 'yyyy', width: '80', header: { text: '년도' }, autoFilter: true },
		{ name: 'SEL_CODE', fieldName: 'selCode', width: '80', header: { text: 'SEL_CODE' }, autoFilter: true },
		{ name: 'SITE', fieldName: 'site', width: '80', header: { text: '사이트' }, autoFilter: true },
		{ name: 'ACCT_CLASS', fieldName: 'acctClass', width: '150', header: { text: '원가항목' }, autoFilter: true,},
		{ name: 'ACCT', fieldName: 'acct', width: '90', header: { text: '계정코드' }, autoFilter: true },
		{ name: 'ACCT_NAME', fieldName: 'acctName', width: '70', header: { text: '계정명' }, autoFilter: true },
		{ name: 'SUB_NAME', fieldName: 'subName', width: '120', header: { text: '비목' }, autoFilter: true },
		{ name: 'ITEM_NAME', fieldName: 'itemName', width: '135', header: { text: '세목' }, autoFilter: true },
		{ name: 'EXPEN_SEL', fieldName: 'expenSel', width: '135', header: { text: 'EXPEN_SEL' }, autoFilter: true },	]	
}

module.exports = grid;