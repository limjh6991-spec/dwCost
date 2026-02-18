<template>
	<div class="login_wrap">
    <div class="row g-0 login_box " >
      <div class="col login_visu">
                <div class="header">
                  <h1 class="logo">
                    <span>원가관리시스템</span>
                  </h1>
              </div>
        </div>
      <div class="col login">
        <div class="header" >
            <div class="user_info">
              <div class="time"><span>{{ curDateStr }}</span></div>
            </div>			
        </div>
        <div class="user_info_box"> 
          <div class="title">Log In</div>
            <ul>
              <li class="user_id">
                  <div class="form-floating">
                    <input type="text" class="form-control" id="floatingId" placeholder="id" v-model="userId">
                    <label for="floatingId">사용자 ID</label>
                </div>              
              </li>
              <li class="password mt-4">
                  <div class="form-floating">
                    <input type="password" class="form-control" id="floatingPassword" placeholder="Password" v-model="password" @keydown.enter="login">
                    <label for="floatingPassword">비밀번호</label>
                </div>
              </li>
              <li class="cfmn">
                <b-button @click="login">확 인</b-button>              
              </li>  
              <li class="chage_pw">
                <a href="#" @click="changePassword">>비밀번호 변경</a>
              </li> 
              </ul>
          </div>	  
        </div>
    </div>
    <PasswordChangePopup ref="pcPopup"/>
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useRouter } from 'vue-router';
import PasswordChangePopup from "@web/popup/PasswordChangePopup";
export default {
	name: "DwLogin",
  
  setup() {
    const userAuthInfo = useUserAuthInfo();
    const router = useRouter(); // Vue Router 가져오기
    return { userAuthInfo ,router};
  },
  components: {
		PasswordChangePopup,
	},
  data() {
    return {
      //반장PC#1 : 230103-639 (메뉴 4개)
      //제조기술 : 230404-689 (메뉴 3개)
      //Back#1   : TEMP01 (메뉴 2개)  
      //200120-97 : BIZADMIN 권한
      userId:'',
      // userId:'SYSADMIN',
      password:'',
      curDateStr:'',
    };
  },
  mounted() {
    // this.getCurDt();
    this.startClock();
  },
	methods: {
    async login() {      
      try {
        let param = {userId:this.userId,password:this.password};
        const response = await this.$axios.post('/api/auth/login',param);        
        // console.log("response data:::",response.data);
        if(_.isEmpty(response.data)){
          this.$toast("info","잘 못된 사용자 정보입니다.");
        }else{
          this.userAuthInfo.setUserAuthInfo(response.data);
          this.router.push({ name: 'DwHome' });
          //일단 테스트
          document.documentElement.requestFullscreen();
        }
      } catch (error) {
        console.error(error);
        this.$toast('error',"데이터를 가져오는 중 오류 발생");
      }
    },
    async getCurDt(){
      const resp = await this.$axios.get('/api/auth/current-time');
      this.curDt = resp.data;       
    },
    changePassword(){
      let p = {};
      p['userId'] = this.userId;
      p['currentPassword'] = '';
      p['newPassword'] = '';
      p['confirmPassword'] = '';

      this.$refs.pcPopup.openDialog(p);
    } ,  
    startClock() {
      setInterval(() => {
        const now = new Date();
        now.setHours(now.getHours() + 9); // UTC+9 적용
        const formattedTime = now.toISOString().slice(0, 19).replace("T", " ");
        this.curDateStr = formattedTime;
      }, 1000);
    }, 
  },
}
</script>