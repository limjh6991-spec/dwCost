/**
*	기준정보 > 사용자-메뉴 권한 관리 > 사용자메뉴 권한관리
*/
<template>
	<div>
		<b-row>
			<b-col cols="5">
				<div class="grid_box">
					<div class="left_box">
						<div class="title">Role</div>
						<div class="btn_wrap ms-auto">
							<b-button @click="delRoleClick">삭제</b-button>									
							<b-button class="sub" @click="addRoleClick">추가</b-button>
							<b-button class="main" @click="saveRoleClick">저장</b-button>
						</div>
					</div>
					<div class="grid-border-none">
						<RealGrid  ref="roleGrid" :uid="'roleGrid'" :step="'2'" :rows="roleList" style="height: 100%;" :fitLayoutWidthEnable="false"/>
					</div>
				</div>
			</b-col>
			<b-col cols="7">
				<div class="grid_box">
					<b-tabs b-model="tab" class="four_depth_tab">
						<b-tab title="사용자">
							<div class="left_box">
								<!-- <div class="title">시스템 리소스</div> -->
								<div class="btn_wrap ms-auto">
									<b-button @click="delRoleUserClick">삭제</b-button>									
									<b-button class="sub" @click="addRoleUserClick">추가</b-button>
								</div>
							</div>
							<div class="grid-border-none" style="height:500px;">
								<RealGrid  ref="roleUserGrid" :uid="'roleUserGrid'" :rows="roleUserList" style="height: 100%;" :fitLayoutWidthEnable="false"/>
							</div>
						</b-tab>
						<b-tab title="시스템 리소스">
							<div class="left_box">
								<!-- <div class="title">시스템 리소스</div> -->
								<div class="btn_wrap ms-auto">
									<b-button class="sub" @click="refreshRoleMenu">초기화</b-button>
									<b-button class="main" @click="saveRoleMenu">저장</b-button>
								</div>
							</div>
							<div class="form-floating ms-1 mt-1 mb-1" style="width:15%" >
								<select class="form-select label-80 " id="floatingSelect" aria-label="Floating label select example" v-model="selectdProdCtg" @change="onProdCtgChange">
									<option v-for="(pc,index) in prodCtgList" :value="pc.prodCategory" :key="index">{{pc.prodCategory}}</option>
								</select>
								<label for="floatingSelect" class="select">제품유형</label>
							</div>
							<div class="grid-border-none" style="height:500px;">
								<div  id="roleMenuGrid" ref="roleMenuGrid" class="top-border" style="height:100%;"></div>
							</div>
						</b-tab>
            			
					</b-tabs>
				</div>
			</b-col>
		</b-row>
		<SearchUserPopup ref="suPopup" @confirm="searchUserConfirm"/>
	</div>
</template>

<script>
import {TreeView, LocalTreeDataProvider} from 'realgrid';
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import SearchUserPopup from "@web/popup/SearchUserPopup";

const URI_PREFIX = '/api/c0006000/c0006009';
let rmTreeProvider,rmTreeView;
export default {
	setup() {
		const userAuthInfo = useUserAuthInfo();
		return { userAuthInfo};
	},
	props: {},  
	components: {
		SearchUserPopup
	},
	watch: {},
	data () {
		return {
			roleGrid:null,
			roleMenuGrid:null,
			roleUserGrid:null,
			roleList:[],
			roleMenuList:[],
			roleUserList:[],
			selectedRoleId:null,
			selectedRoleName:null,
			selectdProdCtg:null,			
		}
	},
	computed: {
		roleGV(){
			return this.$refs.roleGrid.getGridView();
		},
		roleDP(){
			return this.$refs.roleGrid.getGridDataProvider();
		},
		roleUserGV(){
			return this.$refs.roleUserGrid.getGridView();
		},
		roleUserDP(){
			return this.$refs.roleUserGrid.getGridDataProvider();
		},
		prodCtgList(){
			return this.userAuthInfo.getProdCtgList;
		},
	},	
	created() {
		this.initializeGrid();
	},	
	mounted() {
		this.initTreeGrid();
		this.getRoleList();
		this.selectdProdCtg = this.prodCtgList[0]['prodCategory'];
		
		this.roleGV.onValidateColumn = this.onValidateColumn;
		this.roleGV.columnByName('roleId').styleCallback = this.cellStyleCallback;
	},
	beforeUnmount() {},
	methods: {
		initializeGrid() {
			this.roleGrid = _.cloneDeep(require(`@web/c0001000/js/TAB014000.js`));
			this.roleMenuGrid = _.cloneDeep(require(`@web/c0001000/js/TAB014000_MENU.js`));
			this.roleUserGrid = _.cloneDeep(require(`@web/c0001000/js/TAB014000_USER.js`));			
		},
		initTreeGrid(){
			rmTreeProvider = new LocalTreeDataProvider(false);
			rmTreeView = new TreeView(this.$refs.roleMenuGrid);

			rmTreeView.setDataSource(rmTreeProvider);
			rmTreeProvider.setFields(this.roleMenuGrid.fields);
			rmTreeView.setColumns(this.roleMenuGrid.columns);
			rmTreeView.setOptions(this.roleMenuGrid.options);
			rmTreeView.onColumnCheckedChanged = this.onColumnCheckedChangedRoleMenuGrid;
		},
		async getRoleList() {
			let param = { menuId: 'C0001009', queryId: 'selectRoleList', target: this.roleList };
			await this.$axios.api.search(param);
		},
		onColumnCheckedChangedRoleMenuGrid(grid, col, chk){
			rmTreeView.commit(); 
			let cnt = rmTreeView.getItemCount();
			let v = chk === true?"Y":"N";
			for(let i = 0; i < cnt; i++){
				rmTreeProvider.setValue(i,"hasAuth",v);
			}
		},
		onCellClickedRoleGrid:function (grid, clickData) {
			rmTreeView.commit(); 
			let roleId = grid.getValue(clickData.itemIndex,'roleId');
			if(_.isEmpty(roleId)){
				return;
			}
			this.selectedRoleId = roleId;
			this.selectedRoleName = grid.getValue(clickData.itemIndex,'roleName');
			this.getRoleMenuList(roleId);
			this.getRoleUserList(roleId);
		},
		onProdCtgChange(v){
			if(!_.isEmpty(this.selectedRoleId)){
				this.getRoleMenuList(this.selectedRoleId);
			}
		},
		async getRoleMenuList(roleId) {
			let params = {};
			params['roleId'] = roleId;
			params['prodCategory'] = this.selectdProdCtg;
			try{
				const response = await this.$axios.post(URI_PREFIX +'/role/menutab/list',params);        
				this.roleMenuList = response.data;
				rmTreeProvider.setObjectRows(this.roleMenuList,'childSysResc');
				rmTreeView.expandAll();

				//헤더 체크박스 초기화
				let checkColumn = rmTreeView.columnByName("hasAuth");
				checkColumn.checked = false;	
 
			} catch (error){
				console.log(error);
				this.$toast('error','데이터를 가져오는 중 오류 발생');
			}
		},
		async getRoleUserList(roleId){
			let qp = {};
			qp['roleId'] = roleId;
			let param = {menuId:'C0001009',queryId:'selectRoleUserList',queryParams:qp, target: this.roleUserList};
			await this.$axios.api.search(param);		
		},
		async refreshRoleMenu(){
			rmTreeView.commit(); 
			let sd = this.roleGV.getSelectionData();
			if(_.isEmpty(sd)){
				this.$toast("warning","선택된 권한이 없습니다.");
				return;
			}

			let roleId = sd[0]['roleId'];
			this.getRoleMenuList(roleId);
		},
		async saveRoleMenu(){
			rmTreeView.commit(); 
			if(_.isEmpty(this.selectedRoleId)){
				this.$toast("warning","선택된 권한이 없습니다.");
				return;
			}
			let cnt = rmTreeView.getItemCount();
			let v;
			let roleMenuList = [];
			for(let i = 0; i < cnt; i++){
				v = rmTreeView.getValue(i,"hasAuth");
				if("Y" === v){
					let obj = {};
					obj['roleId'] = this.selectedRoleId;
					obj['prodCategory'] = this.selectdProdCtg;
					obj['upperSysResourceId'] = rmTreeView.getValue(i,"upperSysResourceId");
					obj['sysResourceId'] = rmTreeView.getValue(i,"sysResourceId");
					obj['sysResourceTypeCodeId'] = rmTreeView.getValue(i,"sysResourceTypeCodeId");
					
					roleMenuList.push(obj);
				}
			}

			try{
				let params = {};
				params['roleMenuList'] = roleMenuList;
				params['roleId'] = this.selectedRoleId;
				params['prodCategory'] = this.selectdProdCtg;
				const response = await this.$axios.post(URI_PREFIX +'/role/menutab/save',params);        
				if(response.data === "OK"){
					this.$toast('success','저장되었습니다.');
				}
			} catch (error){
				console.log(error);
				this.$toast('error','데이터를 저장 중 오류 발생');
			}
		},		
		addRoleClick(){
			this.roleDP.addRow({});

			let ic = this.roleGV.getItemCount();
			this.roleGV.setCurrent({ itemIndex: ic - 1, column: 'roleId' });
			setTimeout(() => {
				this.roleGV.showEditor();
			}, 100);
		},
		addRoleUserClick(){
			if(_.isEmpty(this.selectedRoleId)){
				this.$toast("info","선택된 Role이 없습니다.");
				return;
			}
			let params = {};
			this.$refs.suPopup.openDialog(params);
		},
		async searchUserConfirm(userIds){
			console.log("userIds:::",userIds);

			this.saveRoleUser(userIds);
		},
		async saveRoleUser(userIds){
			let params = {};
			params['roleId'] = this.selectedRoleId;
			params['roleName'] = this.selectedRoleName;
			params['userIds'] = userIds;
			
			let resp = await this.$axios.post(URI_PREFIX +'/role/user/save',params);        

			if(resp.data === "OK"){
				this.$toast('success','저장되었습니다.');
				this.getRoleUserList(this.selectedRoleId);
			}
		},
		async delRoleUserClick(){
			if(_.isEmpty(this.selectedRoleId)){
				this.$toast("info","선택된 Role이 없습니다.");
				return;
			}

			let sl = this.roleUserGV.getCheckedRows();
			if(_.isEmpty(sl)){
				this.$toast("info","선택된 사용자가 없습니다.");
				return;
			}

			this.$confirmYesOrNo("선택", "삭제 하시겠습니까?", (confirmed) => {
				if (confirmed) {
					let userIds = [];
					sl.forEach(row => {
						userIds.push(this.roleUserDP.getValue(row, "userId"));
					});
					this.delRoleUser(userIds);
				} 
			});
		},
		delRoleClick(){
			let sl = this.roleGV.getCheckedRows();
			if(_.isEmpty(sl)){
				this.$toast("info","선택된 Role이 없습니다.");
				return;
			}

			this.$confirmYesOrNo("선택", "삭제 하시겠습니까?", (confirmed) => {
				if (confirmed) {
					let roleIds = [];
					sl.forEach(row => {
						roleIds.push(this.roleDP.getValue(row, "roleId"));
					});
					this.delRole(roleIds);
				} 
			});
		},
		async delRole(roleIds){
			let params = {};
			params['roleIds'] = roleIds;
			let resp = await this.$axios.post(URI_PREFIX +'/role/delete',params);        

			if(resp.data === "OK"){
				this.$toast('success','삭제제되었습니다.');
				this.getRoleList();
			}
		},
		async delRoleUser(userIds){
			let params = {};
			params['roleId'] = this.selectedRoleId;
			params['userIds'] = userIds;
			
			let resp = await this.$axios.post(URI_PREFIX +'/role/user/delete',params);        

			if(resp.data === "OK"){
				this.$toast('success','삭제제되었습니다.');
				this.getRoleUserList(this.selectedRoleId);
			}
		},
		async saveRoleClick(){
			this.roleGV.commit();
			let saveData = this.$refs.roleGrid.getSaveData();
			let insertList = saveData['insert'];
			let updateList = saveData['update'];

			if(_.isEmpty(insertList) && _.isEmpty(updateList)){
				this.$toast('info','저장 할 정보가 없습니다.');
				return;
			}

			let rslt = this.roleGV.validateCells(null, false);
			if(rslt !== null){
				return;
			}

			let params = {};
			params['insertList'] = insertList;
			params['updateList'] = updateList;

			let resp = await this.$axios.post(URI_PREFIX +'/role/save',params);        

			if(resp.data === "OK"){
				this.$toast('success','저장되었습니다.');
				this.getRoleList();
			}else{
				this.$toast('info',resp.data);
			}
		},
		onValidateColumn(grid, column, inserting, value, itemIndex, dataRow) {
			let error = {};
			if (column.fieldName === 'roleId') {
				if(value === null || _.isEmpty(value)){					
					error.level = "warning";
					error.message = "ROLE Id 는 필수 입력입니다.";
					this.$toast("warn",itemIndex + "행 ROLE ID 는 필수 입력입니다.");
				}
			} 
			return error;
		}, 

		cellStyleCallback(grid, model){
			let v = grid.getValue(model.index.dataRow,'roleId');      
			let rtn = {};
			console.log("v:::",v);
			rtn['editable'] = v === null || v === undefined;
			if(v === null || v === undefined){
				rtn['styleName'] = 'edit';
			}
			return rtn;
		},
	},
}

</script>
<style lang="scss" scoped>
	::v-deep .row ,.col-4, .col-8{
		height: 100%;
	}
</style>