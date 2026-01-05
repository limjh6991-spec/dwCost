/*
 * 기준정보 > 자재코드 (TAB010003)
 */
const { ValueType } = require('realgrid');

const grid = {
  options: {
    checkBar: { visible: true, exclusive: false, syncHeadCheck: true },
    copy: { enabled: true, singleMode: false },
    display: { columnMovable: false, editItemMerging: true, fitStyle: 'fill', emptyMessage: '조회된 데이터가 없습니다.', hscrollBar: true, showEmptyMessage: true },
    edit: { editable: true, columnEditableFirst: true, commitByCell: true, commitWhenLeave: true },
    footer: { visible: false },
    header: { height: 40, showTooltip: true, tooltipEllipsisOnly: true },
    hideDeletedRows: true,
    paste: { enabled: true, checkReadOnly: true },
    rowIndicator: { visible: true },
    sorting: { enabled: false },
    stateBar: { visible: true },
  },
  fields: [
    { fieldName: 'yyyymm', dataType: ValueType.TEXT },
    { fieldName: 'siteOrg', dataType: ValueType.TEXT },
    { fieldName: 'site', dataType: ValueType.TEXT },
    { fieldName: '제품명', dataType: ValueType.TEXT },
    { fieldName: '제품번호', dataType: ValueType.TEXT },
    { fieldName: '품목자산분류', dataType: ValueType.TEXT },
    { fieldName: '품목대분류', dataType: ValueType.TEXT },
    { fieldName: '품목중분류', dataType: ValueType.TEXT },
    { fieldName: '품목소분류', dataType: ValueType.TEXT },
    { fieldName: '공정차수', dataType: ValueType.TEXT },
    { fieldName: '공정', dataType: ValueType.TEXT },
    { fieldName: '공정품명', dataType: ValueType.TEXT },
    { fieldName: '공정품번호', dataType: ValueType.TEXT },
    { fieldName: '자재명', dataType: ValueType.TEXT },
    { fieldName: '자재번호', dataType: ValueType.TEXT },
    { fieldName: '자재자산분류', dataType: ValueType.TEXT },
    { fieldName: '자재대분류', dataType: ValueType.TEXT },
    { fieldName: '자재중분류', dataType: ValueType.TEXT },
    { fieldName: '자재소분류', dataType: ValueType.TEXT },
    { fieldName: '투입단위', dataType: ValueType.TEXT },
    { fieldName: '소요량', dataType: ValueType.TEXT },
    { fieldName: '내부Loss율', dataType: ValueType.TEXT },
    { fieldName: '외부Loss율', dataType: ValueType.TEXT },
    { fieldName: '조립위치', dataType: ValueType.TEXT },
    { fieldName: '특이사항', dataType: ValueType.TEXT },
    { fieldName: '최초작성일', dataType: ValueType.TEXT },
    { fieldName: '최초작성자', dataType: ValueType.TEXT },
    { fieldName: '최종수정일', dataType: ValueType.TEXT },
    { fieldName: '최종수정자', dataType: ValueType.TEXT },
  ],
  columns: [
    {
      name: 'yyyymm',
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
    { name: 'siteOrg', fieldName: 'siteOrg', width: '80', header: { text: 'SITE_ORG' }, autoFilter: true, visible:false },
    {
      name: 'site',
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
		{ name: '제품명', fieldName: '제품명', width: '150', header: { text: '제품명' }, autoFilter: true },
		{ name: '제품번호', fieldName: '제품번호', width: '150', header: { text: '제품번호' }, autoFilter: true },
		{ name: '품목자산분류', fieldName: '품목자산분류', width: '150', header: { text: '품목자산분류' }, autoFilter: true },
		{ name: '품목대분류', fieldName: '품목대분류', width: '80', header: { text: '품목대분류' }, autoFilter: true },
		{ name: '품목중분류', fieldName: '품목중분류', width: '80', header: { text: '품목중분류' }, autoFilter: true },
		{ name: '품목소분류', fieldName: '품목소분류', width: '80', header: { text: '품목소분류' }, autoFilter: true },
		{ name: '공정차수', fieldName: '공정차수', width: '80', header: { text: '공정차수' }, autoFilter: true },
		{ name: '공정', fieldName: '공정', width: '150', header: { text: '공정' }, autoFilter: true },
		{ name: '공정품명', fieldName: '공정품명', width: '150', header: { text: '공정품명' }, autoFilter: true },
		{ name: '공정품번호', fieldName: '공정품번호', width: '150', header: { text: '공정품번호' }, autoFilter: true },
		{ name: '자재명', fieldName: '자재명', width: '150', header: { text: '자재명' }, autoFilter: true },
		{ name: '자재번호', fieldName: '자재번호', width: '150', header: { text: '자재번호' }, autoFilter: true },
		{ name: '자재자산분류', fieldName: '자재자산분류', width: '150', header: { text: '자재자산분류' }, autoFilter: true },
		{ name: '자재대분류', fieldName: '자재대분류', width: '80', header: { text: '자재대분류' }, autoFilter: true },
		{ name: '자재중분류', fieldName: '자재중분류', width: '80', header: { text: '자재중분류' }, autoFilter: true },
		{ name: '자재소분류', fieldName: '자재소분류', width: '80', header: { text: '자재소분류' }, autoFilter: true },
		{ name: '투입단위', fieldName: '투입단위', width: '80', header: { text: '투입단위' }, autoFilter: true },
		{ name: '소요량', fieldName: '소요량', width: '80', header: { text: '소요량' }, autoFilter: true },
		{ name: '내부loss율', fieldName: '내부loss율', width: '80', header: { text: '내부Loss율' }, autoFilter: true },
		{ name: '외부loss율', fieldName: '외부loss율', width: '80', header: { text: '외부Loss율' }, autoFilter: true },
		{ name: '조립위치', fieldName: '조립위치', width: '150', header: { text: '조립위치' }, autoFilter: true },
		{ name: '특이사항', fieldName: '특이사항', width: '200', header: { text: '특이사항' }, autoFilter: true },
		{ name: '최초작성일', fieldName: '최초작성일', width: '150', header: { text: '최초작성일' }, autoFilter: true },
		{ name: '최초작성자', fieldName: '최초작성자', width: '100', header: { text: '최초작성자' }, autoFilter: true },
		{ name: '최종수정일', fieldName: '최종수정일', width: '150', header: { text: '최종수정일' }, autoFilter: true },
		{ name: '최종수정자', fieldName: '최종수정자', width: '100', header: { text: '최종수정자' }, autoFilter: true }
  ]
};

module.exports = grid;
