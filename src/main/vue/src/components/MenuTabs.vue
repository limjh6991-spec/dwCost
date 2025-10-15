<template>
  <div class="gnb" ref="gnb" :class="{ on: isHovered }">
    <div class="logo">
      <h1>DOWOOINSYS</h1>
    </div>
    <nav
      class=""                        
      :class="{ on: isHovered }"
      ref="menuContainer"
    >
      <ul class="depth1" @click="depth1MouseOver">
        <li v-for="(menu, index) in menuList" :key="index">
          <!-- Depth 1 -->
          <a v-if="menu.url"
            :href="menu.url"
            @click.prevent="
              menuClick(createMenuData(menu))
            "
          >
            <span>{{ menu.sysResourceName }}</span>
          </a>
          <a v-else role="button">
            <span>{{ menu.sysResourceName }}</span>
          </a>

          <!-- Depth 2 -->
          <ul class="depth2" v-if="menu.childSysResc">
            <li
              v-for="(subMenu, subIndex) in menu.childSysResc"
              :key="subIndex"
              @mouseover.stop="depth2MouseOver(subMenu)"
              @mouseout.stop="depth1MouseOver1"
            >
              <a
                v-if="subMenu.url"
                :href="subMenu.url"
                @click.prevent="
                  menuClick(createMenuData(menu, subMenu))
                "
              >
                <span>{{ subMenu.sysResourceName }}</span>
              </a>
              <a v-else role="button">
                <span>{{ subMenu.sysResourceName }}</span>
              </a>

              <!-- Depth 3 -->
              <ul class="depth3" v-if="subMenu.childSysResc" 
                :style="subMenu.childSysResc.length > 5 ? { overflowY: 'scroll', overflowX: 'hidden', marginRight: '10px',height:'160px' } : {}"
              ><!--li가 5개이상일때 style="overflow-y: scroll;  overflow-x: hidden; margin-right: 10px;"" -->
                <li 
                  v-for="(childMenu, childIndex) in subMenu.childSysResc"
                  :key="childIndex"
                  @mouseover.stop="depth2MouseOver(subMenu)"
                  @mouseout.stop="depth1MouseOver1"
                >
                  <a
                    v-if="childMenu.url"
                    :href="childMenu.url"
                    @click.prevent="
                      menuClick(createMenuData(menu, subMenu, childMenu))
                    "
                  >
                    <span>{{ childMenu.sysResourceName }}</span>
                  </a>
                  <a v-else role="button">
                    <span>{{ childMenu.sysResourceName }}</span>
                  </a>
                </li>
              </ul>
            </li>
          </ul>
        </li>
      </ul>

    </nav>
    <div class="user_info dw_mes">
      <div class="cur_time"><i class="bi bi-alarm"></i><span>{{curDateStr}}</span></div>
      <div class="form-floating">
          <select class="form-select label-60 " id="floatingSelect" aria-label="Floating label select example" v-model="selectdProdCtg" @change="onProdCtgChange">
              <option v-for="(pc,index) in prodCtgList" :value="pc.prodCategory" :key="index">{{pc.prodCategory==="HQ"? "청주" : "베트남"}}</option>
          </select>
          <label for="floatingSelect" class="select">사이트:</label>
      </div>

      <div class="logid">{{userAuthInfo.userInfo.useName}}</div>
      <div class="logout" @click="logoutClick">logout</div>
    </div>
 <div class="btn-wrap" :style="closeBtnStyle">
          <b-button class="btn-close-gnb" @click="resetMenu">닫기</b-button>
       </div>
      <!--닫기 버튼 추가 -->
    <div class="depth_bg" :style="depthBgStyle"> 
            <!-- <div class="btn-wrap" :style="{ top: `${depthBgHeight - 55}px` }">
          <b-button class="btn-close-gnb" @click="resetMenu">닫기</b-button>
       </div> -->
         <!--  마우스 오버 :메뉴 높이 계산 -->
    </div>
  </div>
  <div class="tab_wrap">
    <div class="tab-container">
      
      <div class="tabs-wrapper" ref="tabsContainer">
        <b-tabs v-model="activeTab" class="two_depth_tab">
          <b-tab v-for="(element, index) in tabs" :key="index"
            v-bind="props"
            class="custom-tab"
            @click.prevent="tabClick(element.url,element)"
          >
            <template #title>
              <div small v-b-tooltip.hover :title="element.menuFullPath" class="path"></div>
              <div class="menu">{{ element.menuNm }}</div>
              <b-button @click.stop="removeTab(index)" class="btn_close" v-if="!element.noRemove"></b-button>
            </template>
          </b-tab>
        </b-tabs>
      </div>
      <div class="btn-group" v-if="isTabsScrollable()">
        <b-button @click="scrollLeft" class="btn-left bi bi-chevron-left"></b-button>
        <b-button @click="scrollRight" class="btn-right bi bi-chevron-right"></b-button>
      </div>
    </div>
  </div>
</template>

<script>
import draggable from "vuedraggable";
import { useUserAuthInfo } from "@store/auth/userAuthInfo";

export default {
  components: {
    draggable,
  },
  setup() {
    const userAuthInfo = useUserAuthInfo();
    return { userAuthInfo };
  },
  data() {
    return {
      activeTab: 0,
      tabs: [],
      // menuList: [],
      isHovered: false,
      isDragging: false,
      depthBgHeight: 0,
       opacity: 0,
       top: "-100px",
      selectdProdCtg:null,
      curDateStr:'',
    };
  },
  computed:{
		menuList(){
      return this.userAuthInfo.getSysResourceMap.childSysResc;
    },
    prodCtgList(){
			return this.userAuthInfo.getProdCtgList;
		},
    depthBgStyle(){
      return {
        height: `${this.depthBgHeight}px`,
        opacity: this.opacity,
        
      };
    },
    closeBtnStyle(){
      return {
        top: `${this.depthBgHeight - 5 == -5 ? -100 : this.depthBgHeight - 5}px`,
        opacity: this.opacity,
        
      };
    },
	},
  created() {
    this.$eventBus.on("menuMoveClick", this.menuMoveClick);
  },
  mounted() {
    this.startClock();
    //document.addEventListener("click", this.handleOutsideClick);
    this.userAuthInfo.loadAuthInfo();
    this.selectdProdCtg = this.userAuthInfo.curProdCtg;
    this.$nextTick(()=>{
      this.menuList = _.cloneDeep(this.userAuthInfo.getSysResourceMap.childSysResc);
      const localTabs = this.$utils.getLocalStorageData(localStorage, 'localTabs'+this.userAuthInfo.token);
      //작업현황 권한 있는지(코드관리에서 관리함)
      //if(this.userAuthInfo.hasWorkStatusRoleYn === "Y"){ //25.10.05 yhkim
      //  this.menuClick({menuId: "R", menuNm: '작업 현황', menuFullPath: '작업 현황', url: '/WorkStatus', noRemove: true });
      //}
      if(!_.isEmpty(localTabs)){
        localTabs.forEach(tab => this.menuClick(tab));
      }
    });
  },
  beforeUnmount() {
		//document.removeEventListener("click", this.handleOutsideClick);
    this.$eventBus.off("menuMoveClick");
	},
  methods: {
    startClock() {
      setInterval(() => {
        const now = new Date();
        now.setHours(now.getHours() + 9); // UTC+9 적용
        const formattedTime = now.toISOString().slice(0, 19).replace("T", " ");
        this.curDateStr = formattedTime;
      }, 1000);
    },
    /*handleOutsideClick(event) {
      const gnb = this.$refs.gnb;
      // gnb 영역 외부를 클릭했을 때만 실행
      console.log();
      if (gnb && !gnb.contains(event.target)) {
        this.isHovered = false;
        this.depthBgHeight = 0;
          this.opacity = 0;
      }
    },*/ 
    menuMoveClick({ menu, callback }) {
      this.menuClick(menu, callback);
    },  
    menuClick(mn, callback = null) {
      this.userAuthInfo.setCurrentMenuInfo(mn); //현재 메뉴정보 저장

      if (this.tabs.length == 0 || !this.tabs.some((tab) => tab.menuId == mn.menuId)) {
        this.tabs.push(mn);
        this.activeTab = this.tabs.length-1;
        if(mn.url){          
          this.pushQueryRouter(mn.url, callback);
        }
      }else if(this.tabs.some((tab) => tab.menuId == mn.menuId)){
        let tabIndex = this.tabs.findIndex((tab) => tab.menuId == mn.menuId);
        if(this.activeTab != tabIndex){
          this.activeTab = tabIndex;
        }
        this.pushQueryRouter(mn.url, callback);
      }  
      if(mn.menuId == "R") return;
      this.$utils.updateLocalStorage(localStorage, 'localTabs' + this.userAuthInfo.token, [_.cloneDeep(mn)]);
    },
    tabClick(url,el) {      
      this.userAuthInfo.setCurrentMenuInfo(el); //현재 메뉴정보 저장
      this.$router.push({ path: url});
    },
    removeTab(index) {
      this.$utils.updateLocalStorage(localStorage, 'localTabs'+this.userAuthInfo.token, [_.cloneDeep(this.tabs[index])], true);
      this.tabs.splice(index, 1);
      if (this.activeTab === index) {
        this.activeTab = Math.max(0, index - 1);
      } else if (this.activeTab > index) {
        this.activeTab = this.activeTab - 1;
      } else if (this.tabs.length == 1) {
        this.activeTab = 0;
      }
      let tab = this.tabs[this.activeTab];
      if(this.$utils.isValidProperty(tab, 'menuNm')){
        this.$router.push({ path: tab.url });
      }else{
        this.$utils.removeLocalStorage(localStorage, 'localTabs'+this.userAuthInfo.token);
        this.$router.push({ path: '/' });
      }
    },
    async depth1MouseOver() {
      this.isHovered = !this.isHovered;

      await this.$nextTick();

      let maxDepth2Length = 0;

      this.menuList.forEach((menu) => {
        if (menu.childSysResc && Array.isArray(menu.childSysResc)) {
          const depth2Length = menu.childSysResc.length;
          maxDepth2Length = Math.max(maxDepth2Length, depth2Length);
        }
      });
      if(!this.isHovered){
        this.depthBgHeight = 0;
         this.opacity = 0;
      }else{
        const liHeight = 42;
        this.depthBgHeight = maxDepth2Length * liHeight + 50;   
         this.opacity = 1;      
      }
    },
    async depth1MouseOver1() {
      await this.$nextTick();

      let maxDepth2Length = 0;

      this.menuList.forEach((menu) => {
        if (menu.childSysResc && Array.isArray(menu.childSysResc)) {
          const depth2Length = menu.childSysResc.length;
          maxDepth2Length = Math.max(maxDepth2Length, depth2Length);
        }
      });
      if(!this.isHovered){
        this.depthBgHeight = 0;
         this.opacity = 0;
      }else{
        const liHeight = 42;
        this.depthBgHeight = maxDepth2Length * liHeight + 50;   
         this.opacity = 1;      
      }
    },
    async depth2MouseOver(mn) {
      await this.$nextTick();

      let maxDepth2Length = 0;
      this.menuList.forEach((menu) => {
        if (menu.childSysResc && Array.isArray(menu.childSysResc)) {
          let depth2Length = menu.childSysResc.length;
          const subMenu = menu.childSysResc.find(
            (submenu) => submenu.sysResourceId === mn.sysResourceId
          );
          if (subMenu && subMenu.childSysResc && Array.isArray(subMenu.childSysResc)) {
            depth2Length += subMenu.childSysResc.length;
          }
          maxDepth2Length = Math.max(maxDepth2Length, depth2Length);
        }
      });
      
      const liHeight = 42;
      this.depthBgHeight = maxDepth2Length * liHeight + 50;
       this.opacity = 1; 
    },
    /*navMouseLeave(event) {
      if(this.status)return;
      const relatedTarget = event.relatedTarget;
      const menuContainer = this.$refs.menuContainer;
      if (!menuContainer.contains(relatedTarget)) {
        this.isHovered = false;
        this.depthBgHeight = 0;
      }
    },*/    
    resetMenu() {
      this.isHovered = false;
      this.depthBgHeight = 0;
      this.opacity = 0; 
    },
    getMenuFullPath(depth1, depth2, depth3) {
      return `${depth1} > ${depth2} > ${depth3}`;
    },
    dragStart() {
      this.isDragging = true;
    },
    dragEnd(event) {
      this.activeTab = event.newIndex;
      this.isDragging = false;
    },
    logoutClick() {
      this.$confirmYesOrNo("선택", "로그아웃 하시겠습니까?", (confirmed) => {
        if (confirmed) {
          this.userAuthInfo.logout();
        } 
      });
    },
    createMenuData(menu, subMenu = null, childMenu = null) {
      return this.$utils.createMenuData(menu, subMenu, childMenu);
    },
    onProdCtgChange(evt){
			this.userAuthInfo.changeProdCtg(evt.target.value);
		},  
    // pushQueryRouter(url, callback = null){
    //   let queryObj = this.$utils.parseQueryParams(url); console.log('info',url); console.log('info',queryObj);
    //   this.$router.push({ path: url,query:queryObj }).then(() => {
    //     if(callback != null) callback();
    //   }).catch(err => {
    //     console.error('failed:', err);
    //   });;
    // },
    pushQueryRouter(url, callback = null) {
    try {
      let queryObj = this.$utils.parseQueryParams(url); 
      console.log('1. Original URL:', url); 
      console.log('2. Parsed Query:', queryObj);
      
      // URL에서 경로와 쿼리 분리
      const [cleanPath, queryString] = url.split('?');
      console.log('3. Clean Path:', cleanPath); 
      console.log('4. Query String:', queryString);
      
      // 라우터 인스턴스 확인
      console.log('5. Router Instance:', this.$router);
      console.log('6. Current Route:', this.$route);
      
      // 등록된 모든 라우트 확인
      const allRoutes = this.$router.getRoutes();
      console.log('7. Total Registered Routes:', allRoutes.length);
      
      // c0001009 관련 라우트 찾기
      const c0001009Routes = allRoutes.filter(route => 
        route.path.includes('c0001009') || 
        route.name?.includes('c0001009') ||
        route.meta?.sysResourceId === 'C0001009'
      );
      
      console.log('8. Found c0001009 routes:', c0001009Routes);
      
      // 정확한 경로 매칭 확인
      const routeExists = allRoutes.some(route => {
        const pathMatch = route.path === cleanPath;
        const nameMatch = route.name === cleanPath.replace('/', '');
        console.log(`   Checking: ${route.path} (${route.name}) -> pathMatch: ${pathMatch}, nameMatch: ${nameMatch}`);
        return pathMatch || nameMatch;
      });
      
      console.log('9. Route exists:', routeExists);
      
      if (!routeExists) {
        console.error(`10. ERROR: 경로 ${cleanPath}가 라우터에 등록되어 있지 않습니다.`);
        
        // 등록된 모든 경로 출력 (참고용)
        console.log('All available paths:');
        allRoutes.forEach(route => {
          console.log(`   - ${route.path} (${route.name})`);
        });
        
        if (callback) callback(new Error(`경로를 찾을 수 없음: ${cleanPath}`));
        return;
      }
      
      console.log('11. Attempting router push...');
      
      // 실제 네비게이션 시도
      this.$router.push({ 
        path: cleanPath,
        query: queryObj 
      }).then(() => {
        console.log('12. ✅ Navigation successful');
        if(callback != null) callback();
      }).catch(err => {
        console.error('13. ❌ Navigation failed:', err);
        console.error('Error details:', {
          message: err.message,
          stack: err.stack,
          name: err.name
        });
      });
      
    } catch (error) {
      console.error('14. 💥 Outer catch block error:', error);
    }
  },
    scrollLeft() {
      const container = this.$refs.tabsContainer;
      if (container && container.scrollLeft !== undefined) {
        container.scrollLeft -= 150; // 왼쪽으로 스크롤
      } else {
        console.error('tabsContainer is null or undefined');
      }
    },
    scrollRight() {
      const container = this.$refs.tabsContainer;
      if (container && container.scrollLeft !== undefined) {
        container.scrollLeft += 150; // 오른쪽으로 스크롤
      } else {
        console.error('tabsContainer is null or undefined');
      }
    },
    isTabsScrollable() {
      const tabsWrapper = this.$refs.tabsContainer; // tabsContainer에 대한 ref 참조
      if (!tabsWrapper) return false;

      // 스크롤 가능 여부 확인
      return tabsWrapper.scrollWidth > tabsWrapper.clientWidth;
    },

  },
};
</script>

<style scoped>
::-webkit-scrollbar {
  width: 8px;
  border-radius: 10px;
}
::-webkit-scrollbar-track {
  background-color: #384462;
  border-radius: 8px;
}
::-webkit-scrollbar-thumb { 
  background-color: skyblue;
  border-radius: 8px;
}
::-webkit-scrollbar-button {
  display: none;
}
.tabs-wrapper::-webkit-scrollbar {
  display: none; /* Chrome, Safari, Edge 스크롤바 숨김 */
}

</style>
<style lang="scss">
.tab_wrap{
    display: flex;
    padding: 0 10px;
    background: url('@assets/images/bg_2depth.png') repeat-x;

    .bi{
        border-color:#ffffff;
        background: #7487ad;
        height: 26px;
        border-radius: 0;
        &::before, [class^="bi-"]::before, [class*=" bi-"]::before {
          vertical-align: 1.1em;
        }
        &:hover{
        border-color:#ffffff;
        }
      }
    }
 
.tab-container {
  display: flex;
  align-items: center;
  position: relative;
  overflow: hidden; /* 탭 내용이 넘치더라도 숨김 */
  width:100%;
}

.tabs-wrapper {
  flex-grow: 1;
  overflow-x: auto; /* 스크롤 가능 */
  white-space: nowrap;
  height: 26px;
  width: calc(100% - 110px);
  
}

.two_depth_tab {
  display: inline-flex;
  transition: transform 0.3s ease-in-out;
}

</style>