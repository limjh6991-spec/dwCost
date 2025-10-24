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
		{ fieldName: 'yyyymm', dataType: ValueType.TEXT },
		{ fieldName: 'siteOrg', dataType: ValueType.TEXT },  
		{ fieldName: 'site', dataType: ValueType.TEXT },  
		{ fieldName: 'prodName', dataType: ValueType.TEXT },
		{ fieldName: 'prodCode', dataType: ValueType.TEXT },
		{ fieldName: 'prodInventoryClass', dataType: ValueType.TEXT },
		{ fieldName: 'prodLargeClass', dataType: ValueType.TEXT },
		{ fieldName: 'prodMidClass', dataType: ValueType.TEXT },
		{ fieldName: 'prodSmallClass', dataType: ValueType.TEXT },
		{ fieldName: 'processSeq', dataType: ValueType.TEXT },
		{ fieldName: 'process', dataType: ValueType.TEXT },
		{ fieldName: 'processMatName', dataType: ValueType.TEXT },
		{ fieldName: 'processMatCode', dataType: ValueType.TEXT },
		{ fieldName: 'matName', dataType: ValueType.TEXT },
		{ fieldName: 'matCode', dataType: ValueType.TEXT },
		{ fieldName: 'matInventoryClass', dataType: ValueType.TEXT },
		{ fieldName: 'matLargeClass', dataType: ValueType.TEXT },
		{ fieldName: 'matMidClass', dataType: ValueType.TEXT },
		{ fieldName: 'matSmallClass', dataType: ValueType.TEXT },
		{ fieldName: 'inputUnit', dataType: ValueType.TEXT },
		{ fieldName: 'reqQty', dataType: ValueType.TEXT },
		{ fieldName: 'inLossRate', dataType: ValueType.TEXT },
		{ fieldName: 'outLossRate', dataType: ValueType.TEXT },
		{ fieldName: 'assyLoc', dataType: ValueType.TEXT },
		{ fieldName: 'etc', dataType: ValueType.TEXT },
		{ fieldName: 'firstRegDate', dataType: ValueType.TEXT },
		{ fieldName: 'firstRegId', dataType: ValueType.TEXT },
		{ fieldName: 'lastModDate', dataType: ValueType.TEXT },
		{ fieldName: 'lastModId', dataType: ValueType.TEXT },
	],
	
	columns: [
   {
      name: 'YYYYMM',
      fieldName: 'yyyymm',
      width: '80',
      header: { text: 'YYYYMM' },
      autoFilter: true,
      editable: false,
      styleName: 'tl',
      styleCallback: function (grid, dataCell) {
        var ret = {};

        if (dataCell.item.rowState == 'created' || dataCell.item.itemState == 'appending' || dataCell.item.itemState == 'inserting') {
          ret.editable = true;
          ret.styleName = 'edit tl';
        } else {
          ret.editable = false;
          ret.styleName = 'tl';
        }

        return ret;
      },
    },
		{ name: 'SITE_ORG', fieldName: 'siteOrg', width: '80', header: { text: 'SITE_ORG' }, autoFilter: true, visible:false },
    {
      name: 'SITE',
      fieldName: 'site',
      width: '80',
      header: { text: '사이트' },
      autoFilter: true,
      editable: false,
      styleName: 'tl',
      styleCallback: function (grid, dataCell) {
        var ret = {};

        if (dataCell.item.rowState == 'created' || dataCell.item.itemState == 'appending' || dataCell.item.itemState == 'inserting') {
          ret.editable = true;
          ret.styleName = 'edit tl';
        } else {
          ret.editable = false;
          ret.styleName = 'tl';
        }

        return ret;
      },
    },
		{ name: '제품명', fieldName: 'prodName', width: '150', header: { text: '제품명' }, autoFilter: true },
		{ name: '제품번호', fieldName: 'prodCode', width: '150', header: { text: '제품번호' }, autoFilter: true },
		{ name: '품목자산분류', fieldName: 'prodInventoryClass', width: '150', header: { text: '품목자산분류' }, autoFilter: true },
		{ name: '품목대분류', fieldName: 'prodLargeClass', width: '80', header: { text: '품목대분류' }, autoFilter: true },
		{ name: '품목중분류', fieldName: 'prodMidClass', width: '80', header: { text: '품목중분류' }, autoFilter: true },
		{ name: '품목소분류', fieldName: 'prodSmallClass', width: '80', header: { text: '품목소분류' }, autoFilter: true },
		{ name: '공정차수', fieldName: 'processSeq', width: '80', header: { text: '공정차수' }, autoFilter: true },
		{ name: '공정', fieldName: 'process', width: '150', header: { text: '공정' }, autoFilter: true },
		{ name: '공정품명', fieldName: 'processMatName', width: '150', header: { text: '공정품명' }, autoFilter: true },
		{ name: '공정품번호', fieldName: 'processMatCode', width: '150', header: { text: '공정품번호' }, autoFilter: true },
		{ name: '자재명', fieldName: 'matName', width: '150', header: { text: '자재명' }, autoFilter: true },
		{ name: '자재번호', fieldName: 'matCode', width: '150', header: { text: '자재번호' }, autoFilter: true },
		{ name: '자재자산분류', fieldName: 'matInventoryClass', width: '150', header: { text: '자재자산분류' }, autoFilter: true },
		{ name: '자재대분류', fieldName: 'matLargeClass', width: '80', header: { text: '자재대분류' }, autoFilter: true },
		{ name: '자재중분류', fieldName: 'matMidClass', width: '80', header: { text: '자재중분류' }, autoFilter: true },
		{ name: '자재소분류', fieldName: 'matSmallClass', width: '80', header: { text: '자재소분류' }, autoFilter: true },
		{ name: '투입단위', fieldName: 'inputUnit', width: '80', header: { text: '투입단위' }, autoFilter: true },
		{ name: '소요량', fieldName: 'reqQty', width: '80', header: { text: '소요량' }, autoFilter: true },
		{ name: '내부Loss율', fieldName: 'inLossRate', width: '80', header: { text: '내부Loss율' }, autoFilter: true },
		{ name: '외부Loss율', fieldName: 'outLossRate', width: '80', header: { text: '외부Loss율' }, autoFilter: true },
		{ name: '조립위치', fieldName: 'assyLoc', width: '150', header: { text: '조립위치' }, autoFilter: true },
		{ name: '특이사항', fieldName: 'etc', width: '200', header: { text: '특이사항' }, autoFilter: true },
		{ name: '최초작성일', fieldName: 'firstRegDate', width: '150', header: { text: '최초작성일' }, autoFilter: true },
		{ name: '최초작성자', fieldName: 'firstRegId', width: '100', header: { text: '최초작성자' }, autoFilter: true },
		{ name: '최종수정일', fieldName: 'lastModDate', width: '150', header: { text: '최종수정일' }, autoFilter: true },
		{ name: '최종수정자', fieldName: 'lastModId', width: '100', header: { text: '최종수정자' }, autoFilter: true },
		]	
}

module.exports = grid;