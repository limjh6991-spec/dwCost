import { defineStore } from 'pinia';
import axios from '@/plugins/axios';

export const useUserAuthInfo = defineStore('userAuthInfo', {
  state: () => ({
    token: null,
    userInfo: {},
    roleList: [],
    sysResource:{},
    sysResourceList: [],
    prodCtgList: [],
    selectedProdCtg:null,
    line:null,
    adminList:[
      'allAdmin'
    ], //여러 자세한 admin 목록 있을 수 있어서
    workStatusRoleYn:null,
    selectedMenuInfo:null,
    selectedAuthTabInfo:null,
  }),
  getters: {
    isAuthenticated: (state) => !!state.token, // 인증 여부
    curToken:(state) => state.token,
    loginUserId:(state) => state.userInfo.usaeId,
    loginUserName:(state) => state.userInfo.userName,
    loginUserDeptName:(state) => state.userInfo.deptName,
    getSysResourceMap:(state) => state.sysResource,
    getSysResourceList:(state) => state.sysResourceList,
    getProdCtgList:(state) => state.prodCtgList,
    curProdCtg:(state) => state.selectedProdCtg,
    isAdmin:(state) => state.adminList.indexOf('allAdmin') > -1,
    hasWorkStatusRoleYn:(state) => state.workStatusRoleYn,
    curMenuInfo:(state) => state.selectedMenuInfo,
    curAuthTabInfo:(state) => state.selectedAuthTabInfo,
    getRoleList:(state) => state.roleList,
  },
  actions: {
    // 인증 정보 설정
    setUserAuthInfo(authInfo) {      
      this.token = authInfo.token;
      this.userInfo = authInfo.userInfo;
      this.roleList = authInfo.roleList;
      this.sysResource = authInfo.sysResource;
      this.sysResourceList = authInfo.sysResourceList;
      this.prodCtgList = authInfo.prodCtgList,
      this.selectedProdCtg = this.prodCtgList[0]['prodCategory'];
      this.line = this.prodCtgList[0]['line'];
      this.workStatusRoleYn = authInfo.hasWorkStatusRoleYn;
      // this.adminList = authInfo.adminList;
      localStorage.setItem('userAuthInfo', JSON.stringify(this.$state));  //로컬 스토리지에 저장
    },
    clearToken() {
      this.token = null;
      localStorage.removeItem('token');
    },
    loadToken() {
      this.token = localStorage.getItem('token');
    },
    // 초기화
    clearUserAuthInfo() {
      console.log("사용자 권한 관련 정보 초기화...");
      localStorage.removeItem('localTabs'+this.token);
      this.token = '';
      this.userInfo = {};
      this.roleList = [];
      this.sysResource = {};
      this.sysResourceList = [];
      this.prodCtgList = [];
      this.selectedProdCtg = null;
      this.line = null;
      this.adminList = [];
      this.workStatusRoleYn = null;
      localStorage.removeItem('userAuthInfo'); // 로컬 스토리지 초기화
    },

    loadAuthInfo() {
      const lsState = localStorage.getItem('userAuthInfo');
      console.log(lsState);
      if(lsState) {
        this.$patch(JSON.parse(lsState)); // 상태 복원
      }
    },

    getTabInfoListBySRI(pUpperSysResourceId,pSysResourceId) {
      return this.fincChildSysResc(this.sysResource,pUpperSysResourceId,pSysResourceId);
    },

    getRoleProcessList() {
      let processList = [];
      try{
        let tempProcessList = this.sysResourceList.filter((item) => item.sysResourceTypeCodeId === '공정');
        processList = [...new Map(tempProcessList.map(item => [item.sysResourceId, item])).values()]; //중복제거
      }catch(error){
        console.warn("권한 있는 공정 처리중 오류입니다.");
      }
      return processList;
    },

    fincChildSysResc(sysResource,pUpperSysResourceId,pSysResourceId){
      // 현재 노드가 조건에 맞는지 확인   
      if(sysResource['upperSysResourceId'] === pUpperSysResourceId && sysResource['sysResourceId'] === pSysResourceId) {
        return sysResource.childSysResc; // 조건에 맞는 노드 반환
      }
      
      if (sysResource.childSysResc && Array.isArray(sysResource.childSysResc)) {
        for(let sr of sysResource.childSysResc) {
          const result = this.fincChildSysResc(sr, pUpperSysResourceId,pSysResourceId); 
          if (result) {
            return result; 
          }
        }
      }
    },

    async logout(){
      try {
        const response = await axios.post('/api/auth/logout');
        let rslt = response.data;
        this.$toast('success',"로그아웃 되었습니다.\n잠시 후 로그인 페이지로 이동합니다.");

        setTimeout(() => {
          Promise.resolve(this.clearUserAuthInfo()).then(() => {
            window.location = "/"; // 항상 완료 후 실행
          });
        }, 3000); // 3초
        
      } catch (error) {
        console.error(error);
        this.$toast('error',"로그아웃 중 오류 발생하였습니다.");
      }
    },
    async changeProdCtg(prodCtg){
      try {
        /*if(this.selectedProdCtg === prodCtg){
          console.log("동일한 prodCtg 선택됨. - ",prodCtg);
          return;
        }*/
		console.log("prodCtg ",prodCtg);
		this.selectedProdCtg = prodCtg;
        this.prodCtgList.forEach(el => {
          if(el['prodCategory'] === prodCtg){
            this.line = el['line'];
          }
        });

        let params = {};
        params['prodCategory'] = prodCtg;
        const response = await axios.post('/api/auth/change-prodctg',params);
        let rslt = response.data;      
        this.sysResource = rslt.sysResource;
        this.sysResourceList = rslt.sysResourceList;
		console.log("userAuthInfo ",JSON.stringify(this.$state));
        localStorage.setItem('userAuthInfo', JSON.stringify(this.$state));  //로컬 스토리지에 다시저장
      } catch (error) {
        console.error(error);
        this.$toast('error',"prod category 변경에 실패하였습니다.");
      }
    },
    setCurrentMenuInfo(menuObj){
      this.selectedMenuInfo = menuObj;
    },
    setCurrentAuthTabInfo(tabObj){
      this.selectedAuthTabInfo = tabObj;
    },
    
  },  
});