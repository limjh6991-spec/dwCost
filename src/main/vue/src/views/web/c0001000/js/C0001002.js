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
		{ fieldName: 'dept', dataType: ValueType.TEXT },
		{ fieldName: 'deptName', dataType: ValueType.TEXT },
		{ fieldName: 'expenArea', dataType: ValueType.TEXT },
	],
	
	columns: [
		{ name: 'YYYY', fieldName: 'yyyy', width: '80', header: { text: '년도' }, autoFilter: true },
		{ name: 'SEL_CODE', fieldName: 'selCode', width: '80', header: { text: 'SEL_CODE' }, autoFilter: true },
		{ name: 'SITE', fieldName: 'site', width: '80', header: { text: '사이트' }, autoFilter: true },
		{ name: 'DEPT', fieldName: 'dept', width: '150', header: { text: '부서코드' }, autoFilter: true,},
		{ name: 'DEPT_NAME', fieldName: 'deptName', width: '70', header: { text: 'ㅂ부서명명' }, autoFilter: true },
		{ name: 'EXPEN_AREA', fieldName: 'expenArea', width: '120', header: { text: '변경하면됨' }, autoFilter: true },	]	
}

module.exports = grid;