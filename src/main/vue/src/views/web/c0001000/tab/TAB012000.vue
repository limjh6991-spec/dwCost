/**
*	기준정보 > 사용자-메뉴 권한 관리 > 사용자 관리
*/
<template>
	<div>
		<div class="grid_box">
			<div class="left_box">
				<div class="btn_wrap ms-auto">
					<b-button class="second" @click="getUserList">새로고침</b-button>
					<b-button class="sub" @click="addUser">추가</b-button>
					<b-button @click="delUser">삭제</b-button>
					<b-button class="main" @click="saveUser">저장</b-button>
				</div>            
			</div>
			<div class="grid-border-none">
				<RealGrid ref="userGrid" :uid="'userGrid'" :step="'0'" :rows="userList" style="height: 100%;"/>		
			</div>
		</div>
	</div>
</template>

<script>
import {RowState} from 'realgrid';

export default {
	props: {},  
	components: {},
	watch: {},
	data () {
		return {
			userGrid:null,
			userList:[],			
		}
	},
	computed: {
		userGridView(){
			return this.$refs.userGrid.getGridView();
		},
		userDataProvider(){
			return this.$refs.userGrid.getGridDataProvider();
		}
	},	
	created() {
		this.initializeGrid();
	},	
	mounted() {
		this.getUserList();
	},
	beforeUnmount() {},
	methods: {
		initializeGrid() {
			this.userGrid = _.cloneDeep(require(`@web/c0001000/js/TAB012000.js`));
		},
		async getUserList(){
			this.userGridView.commit();
			let param = {menuId:'C0001009',queryId:'selectUserList', target: this.userList};
			await this.$axios.api.search(param);	
		},
		addUser(){
			this.userGridView.commit();
			this.userDataProvider.addRow({});
			let ic = this.userGridView.getItemCount();
			this.userGridView.setCurrent({ itemIndex: ic + 1, fieldName: 'useName' });
		},
		delUser(){
			this.userGridView.commit();
			let delItemList = this.userGridView.getSelectedItems();
			if(_.isEmpty(delItemList)){
				this.$toast("info","선택된 정보가 없습니다.");
			}
			
			//1. 추가 후 삭제된것 처리
			let delCreList = [];
			delItemList.forEach(itemIndex => {
				if(this.userDataProvider.getRowState(itemIndex) === RowState.CREATED){	//추가된 행이면 삭제										
					delCreList.push(itemIndex);
				}
			});
			this.userDataProvider.removeRows(delCreList);

			//2.기존것 삭제 처리
			delItemList = this.userGridView.getSelectedItems();
			delItemList.forEach(itemIndex => {
				this.userDataProvider.setRowState(itemIndex, RowState.DELETED);		
			});
		},
		async saveUser(){
			this.userGridView.commit();
			let saveData = this.$refs.userGrid.getSaveData();
			let params = {};
			params['menuId'] = 'C0001009';
			params['delete'] = [{queryId:'deleteCmUser', data:saveData.delete}];	
			params['insert'] = [{queryId:'insertCmUser', data:saveData.insert}];
			params['update'] = [{queryId:'updateCmUser', data:saveData.update}];
			const resp = await this.$axios.api.saveData(params);
			if(resp.status === 'success'){
				this.userDataProvider.clearRowStates();
				this.$toast('success','저장되었습니다.');
			}else{
				this.$toast('error',resp.message);
			}
		},
	},
}

</script>