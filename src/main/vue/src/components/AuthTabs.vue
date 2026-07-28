<template>
  <b-tabs v-model="internalActiveTab" class="three_depth_tab" @activate-tab="onTabActivated">
    <b-tab v-for="(tab) in tabList" :key="tab.sysResourceId">
      <template #title>{{ tab.sysResourceName }}</template>
      <slot :name="'tab-content-' + tab.sysResourceId">
        <p>확인용 {{ tab.sysResourceId }}</p>
      </slot>
    </b-tab>
  </b-tabs>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useRoute } from 'vue-router';

export default {
  name: "auth-tabs",
  emits: ["tabChange","update:activeTab"],
  setup() {
    const userAuthInfo = useUserAuthInfo();
    const route = useRoute(); // 현재 라우트 정보 가져오기  
    // console.log("route:::",route);
    const tab3Id = route.query.tab3Id;    
    const tabInfoList = userAuthInfo.getTabInfoListBySRI(route.meta.upperSysResourceId,route.meta.sysResourceId);    
    
    return { userAuthInfo, tabInfoList, tab3Id, route};
  },
  props: {
    activeTab: { type: Number, default: 0 },
    tabLevel: { type: Number, default: 3 },
    pTabId: { type: String, default:null },
  },  
  data() {
    return {      
      internalActiveTab: this.activeTab,      
    };
  },
  computed:{
    tab3List(){
      let list = this.tabInfoList || [];
      if (this.route?.meta?.sysResourceId === 'C0009001') {
        if (!list.some(item => item.sysResourceId === 'TAB090014')) {
          list = [
            ...list,
            { sysResourceId: 'TAB090014', sysResourceName: '재공품 공정 수불' }
          ];
        }
      }
      return list;  
    },
    tab4List(){
      let obj = this.tabInfoList.find((resc) => resc.sysResourceId === this.pTabId);      
      return obj['childSysResc'];
    },
    tabList(){
      return this.tabLevel === 3?this.tab3List:this.tab4List;
    }
    
  },
  watch: {    
    activeTab(newValue) {
      this.internalActiveTab = newValue;
    },
    internalActiveTab(newValue) {
      this.$emit("update:activeTab", newValue);
    },
    // 2024.12.1 keep alive 활성화에 따른 비활성화
    '$route.fullPath'(newPath, oldPath) { // 새로운 $route.fullPath 감시 추가 for Tab 이동을 위한
      if(newPath !== oldPath){
        let _tab3Id = this.$route.query.tab3Id;
        if(_tab3Id !== undefined){
          if(this.tab3Id !== _tab3Id){
            this.tab3Id = _tab3Id;
            this.reSetInternalActiveTab();
          }
        }
      }
    }
  },
  mounted(){ 
    if(this.tab3Id !== undefined && !_.isEmpty(this.tab3Id)){
      this.reSetInternalActiveTab();
    }else{
      this.internalActiveTab = 0;
    }
  },  
  methods: {
    reSetInternalActiveTab(){
      let i = this.tabList.findIndex(tab => tab.sysResourceId === this.tab3Id);      
      if(i > -1){
        this.internalActiveTab = i;
      }
    },
    onTabActivated(pTabIdx){
      this.userAuthInfo.setCurrentAuthTabInfo(this.tabList[pTabIdx]);
      this.$emit("tabChange",pTabIdx,this.tabIdx,this.tabList[pTabIdx]);
      this.tabIdx = pTabIdx
    },
  },

};
</script>
<style lang="scss">
.v-window-item {
 .v-container{
    padding:0!important;
  }
}
</style>