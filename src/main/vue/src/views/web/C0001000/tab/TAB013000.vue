/**
*	기준정보 > 사용자-메뉴 권한 관리 > 메뉴관리
*/
<template>
	<div>
		<div class="grid_box">
			<div class="left_box">
				<div class="btn_wrap ms-auto">
					<b-button class="second" @click="refreshMenu">초기화</b-button>
					<b-button class="sub" @click="addMenu">Child 추가</b-button>
					<b-button @click="delMenu">삭제</b-button>
					<b-button class="main" @click="saveMenu">저장</b-button>
				</div>            
			</div>
			<div class="form-floating ms-1 mt-1 mb-1" style="width:10%" >
				<select class="form-select label-80 " id="floatingSelect" aria-label="Floating label select example" v-model="selectdProdCtg" @change="onProdCtgChange">
					<option v-for="(pc,index) in prodCtgList" :value="pc.prodCategory" :key="index">{{pc.prodCategory}}</option>
				</select>
				<label for="floatingSelect" class="select">제품유형</label>
			</div>
			<div class="grid-border-none">
				<div id="menuGrid" ref="menuGrid" class="top-border" style="height:100%" ></div>
			</div>
		</div>
	</div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import {TreeView, LocalTreeDataProvider, RowState} from 'realgrid';

// const URI_PREFIX = '/api/c0006000/c0006009';
let mTreeProvider,mTreeView;
export default {
	setup() {
		const userAuthInfo = useUserAuthInfo();
		return { userAuthInfo};
	},
	props: {},  
	components: {},
	watch: {},
	data () {
		return {
			selectdProdCtg:null,
			selectedMenuClickData:null,
			menuGrid:null,
			menuTabList:[],
		}
	},
	computed: {
		prodCtgList(){
			return this.userAuthInfo.getProdCtgList;
		},
	},	
	created() {
	},	
	mounted() {
		this.selectdProdCtg = this.prodCtgList[0]['prodCategory'];
		this.initializeGrid();
		this.getMenuTabList();
	},
	beforeUnmount() {},
	methods: {
		initializeGrid() {
			this.menuGrid = _.cloneDeep(require(`@web/c0001000/js/TAB013000.js`));

			mTreeProvider = new LocalTreeDataProvider(false);
			mTreeView = new TreeView(this.$refs.menuGrid);
			mTreeView.setDataSource(mTreeProvider);
			mTreeProvider.setFields(this.menuGrid.fields);
			mTreeView.setColumns(this.menuGrid.columns);
			mTreeView.setOptions(this.menuGrid.options);
			mTreeView.onCellClicked = this.onCellClickedMenu;
			// mTreeView.columnByName('sysResourceId').styleCallback = this.cellStyleCallback;
			mTreeView.onValidateColumn = this.onValidateColumn;

		},
		async getMenuTabList(){
			let qp = {};
			qp['prodCategory'] = this.selectdProdCtg;
			let param = {menuId:'C0001009',queryId:'selectMenuTabList',queryParams:qp, target: this.menuTabList};
			let resp = await this.$axios.api.search(param);	
			// console.log("resp:::",resp);
			this.menuTabList = resp;
			mTreeProvider.setRows(this.menuTabList, "fullSeq");
			mTreeView.expandAll();
		},
		onProdCtgChange(v){
			this.getMenuTabList();
		},
		onCellClickedMenu(grid, clickData){
			// console.log("check:",clickData);
			this.selectedMenuClickData = clickData;
		},
		refreshMenu(){
			this.getMenuTabList();
		},
		addMenu(){
			mTreeView.commit();
			let child = {};
			let idx = -1;
			
			child['prodCategory'] = this.selectdProdCtg;
			child['sysResourceId'] = '';
			child['sysResourceName'] = '';
			child['sysResourceTypeCodeId'] = '';
			child['description'] = '';
			child['url'] = '';

			if(this.selectedMenuClickData === null){				
				child['upperSysResourceId'] = 'ROOT_MENU';
				child['seq'] = 999;
			}else{
				// console.log("selectedMenuClickData:::",this.selectedMenuClickData);
				let pi = this.selectedMenuClickData.itemIndex;
				idx = pi + 1;
				let upSysRescId = mTreeView.getValue(pi,"sysResourceId");
			
				child['upperSysResourceId'] = upSysRescId;
				child['seq'] = mTreeView.getChildren(pi).length + 1;
			}
			mTreeProvider.addChildRow(idx, child,-1, false);	
		},
		delMenu(){
			mTreeView.commit();
			if(this.selectedMenuClickData === null){
				this.$toast("warn",'선택된 정보가 없습니다.');
			}else{
				let dr = this.selectedMenuClickData.dataRow;
				let delCreList = [];
				let children = [];

				//1. 추가 후 삭제된것 처리
				if(mTreeProvider.getRowState(dr) === RowState.CREATED){
					delCreList.push(dr);
					children.push(...mTreeProvider.getChildren(dr)||[]);
					while(children.length > 0){
						let r = children.shift();
						delCreList.push(r);
						children.push(...mTreeProvider.getChildren(r)||[]);
					}
				}else{	//2.기존것 삭제 처리
					mTreeProvider.setRowState(dr, RowState.DELETED);		
					children.push(...mTreeProvider.getChildren(dr)||[]);
					while(children.length > 0){
						let r = children.shift();
						if(mTreeProvider.getRowState(r) === RowState.CREATED){
							delCreList.push(r);
						}else{
							mTreeProvider.setRowState(r, RowState.DELETED);	
						}
						children.push(...mTreeProvider.getChildren(r)||[]);
					}
				}
				mTreeProvider.removeRows(delCreList);
			}
		},
		// cellStyleCallback(grid, model){
		// 	let rtn = {};
		// 	rtn['editable'] = model.item.rowState === RowState.CREATED;
		// 	return rtn;
		// },
		onValidateColumn(grid, column, inserting, value, itemIndex, dataRow) {
			let error = {};
			if (column.fieldName === "sysResourceId") {
				if(value === null || _.isEmpty(value)){					
					error.level = "warning";
					error.message = "SYS RESOURCE ID 는 필수 입력입니다.";
					this.$toast("warn",itemIndex + "행 메뉴ID 는 필수 입력입니다.");
				}
			} else if (column.fieldName === "sysResourceTypeCodeId") {
				if(value === null || _.isEmpty(value)){					
					error.level = "warning";
					error.message = "TYPE 는 필수 입력입니다.";
					this.$toast("warn",itemIndex + "행 TYPE 는 필수 입력입니다.");
				}
			}
			return error;
		},
		async saveMenu(){
			mTreeView.commit();
			//todo 
			//sysResourceId, upperSysResourceId 중복 체크
			
			// let obj = mTreeProvider.getDistinctValues('sysResourceId');
			// if(obj.length !== mTreeProvider.getRowCount()){
			// 	this.$toast('warn','SYS RESOURCE ID 가 중복된 것이 있습니다.');
			// 	return;		
			// }

			mTreeView.validateCells(null, false);
			let saveData = this.$utils.getGridTreeSaveData(mTreeProvider);
			// console.log("check saveData:::",saveData);

			let params = {};
			params['menuId'] = 'C0001009';
			params['delete'] = [{queryId:'deleteCmSysResource', data:saveData.delete}];	
			params['insert'] = [{queryId:'insertCmSysResource', data:saveData.insert}];
			params['update'] = [{queryId:'updateCmSysResource', data:saveData.update}];

			const resp = await this.$axios.api.saveData(params);
			if(resp.status === 'success'){
				this.$toast('success','저장되었습니다.');
				this.getMenuTabList();				
			}else{
				this.$toast('error',resp.message);
			}
		},
	},
}

</script>
<style lang="css" scoped>
	::v-deep .grid-border-none {
    height: calc(100% - 90px);
}
</style>