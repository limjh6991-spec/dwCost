import axios from 'axios';
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import handleError from '@/utils/axiosErrorHandler';

// Axios 기본 설정
const instance = axios.create({
  baseURL: process.env.VUE_APP_API_URL, // API 기본 URL
  timeout: 10000 * 6 * 30,  // 요청 시간 초과 (10000 = 10초)
  headers: {
    'Content-Type': 'application/json', // 기본 Content-Type
  }
});

// 로딩 상태 관리용 변수
let activeRequests = 0;

// 요청 인터셉터 (옵션, 요청 전에 처리할 작업)
instance.interceptors.request.use(
  config => {
    activeRequests++;
    window.dispatchEvent(new CustomEvent("loading-start"));
    //토큰을 헤더에 추가
    const userAuthStore = useUserAuthInfo();
    let token = userAuthStore.curToken;    
    //새로고침 관련 한번 로드 해줌
    if(token === null){
      console.log("load auth info....");
      userAuthStore.loadAuthInfo();
      token = userAuthStore.curToken;
    }

    if(token !== null) {      
      config.headers.Authorization = `Bearer ${token}`;
    }    
    
    //start - 2025.4.11 로그 관련 추가
    try{
      let curMenuInfo = userAuthStore.curMenuInfo;
      if(curMenuInfo !== null){
        // console.log("curMenuInfo:::",curMenuInfo);
        config.headers['X-Menu-Path'] = encodeURIComponent(curMenuInfo.menuFullPath);
        config.headers['X-Menu-Url'] = encodeURIComponent(curMenuInfo.url);
        config.headers['X-Prod'] = encodeURIComponent(userAuthStore.curProdCtg);
      }
      
      config.headers['X-Tab-Path'] = "";
      config.headers['X-Tab-Id'] = "";

      let curAuthTabInfo = userAuthStore.curAuthTabInfo;
      if(curAuthTabInfo !== null){
        // console.log("curAuthTabInfo:::",curAuthTabInfo);
        if(curAuthTabInfo.fullPath.indexOf(curMenuInfo.menuFullPath) > -1){
          config.headers['X-Tab-Path'] = encodeURIComponent(curAuthTabInfo.fullPath);
          config.headers['X-Tab-Id'] = encodeURIComponent(curAuthTabInfo.sysResourceId);
        }
      }

      config.headers['X-Menu-Id'] = "";
      config.headers['X-Query-Id'] = "";
      if(config.url === "api/generic/search"){
        config.headers['X-Menu-Id'] = config.data.menuId; 
        config.headers['X-Query-Id'] = config.data.queryId;
        
      }else if(config.url === "api/generic/saveData"){
        config.headers['X-Menu-Id'] = config.data.menuId;
        let queryIds = [];

        if(config.data.insert !== undefined){
          queryIds.push(config.data.insert[0]["queryId"]);
        }

        if(config.data.delete !== undefined){
          queryIds.push(config.data.delete[0]["queryId"]);
        }

        if(config.data.update !== undefined){
          queryIds.push(config.data.update[0]["queryId"]);
        }
        
        config.headers['X-Query-Id'] = queryIds.join(" ");
      }
      //end
    }catch(error){
      console.warn("시스템 로그 정보 구성 실패하였습니다.");
    }finally{
    }

    return config;
  },
  error => {
    return Promise.reject(error);
  }
);

// 응답 인터셉터 (옵션, 응답을 처리할 작업)
instance.interceptors.response.use(  
  (response) => { 
    activeRequests--;
    if (activeRequests === 0) {
      // 로딩 종료 이벤트
      window.dispatchEvent(new CustomEvent("loading-end"));
    }
    return response;
  }, 
  (error) => {
    activeRequests--;
    if(activeRequests === 0) {
      // 로딩 종료 이벤트
      window.dispatchEvent(new CustomEvent("loading-end"));
    }
    // 오류 처리    
    console.error('API 응답 오류:', error);
    handleError(error); // 핸들러 연결
    
    
    //vue 에러페이지 출력 방지 주석
    // return Promise.reject(error);
  }
);

/**
 * 공통 API 조회, 저장 호출 메서드
 */
const api = {
	async search(params) {
    try {
      const data = await instance.post('api/generic/search', params).then(response => response.data);
      if(params.all == undefined || params.all == false){
        if(typeof params.callback === "function"){
          params.callback(data);
        }else if(params.target != undefined && Array.isArray(params.target)) {
          // 대용량 결과에서 splice(...data) 스프레드가 인자 한계를 넘겨
          // "Maximum call stack size exceeded"가 나므로 청크로 나눠 채운다.
          params.target.splice(0, params.target.length);
          const CHUNK = 5000;
          for (let i = 0; i < data.length; i += CHUNK) {
            params.target.push(...data.slice(i, i + CHUNK));
          }
        }else if(params.target != undefined && typeof params.target === 'object') {
          Object.assign(params.target, data[0] || {});
        }
      }
      return data;
    } catch (error) {
      console.error('데이터를 가져오는 중 오류 발생:', error);
      //vue 에러페이지 출력 방지 주석
      // throw error;
      return []; // 오류 시 빈 배열 반환하여 undefined.data 오류 방지
    }
	},
	async saveData(params) {
		return instance.post('api/generic/saveData', params).then((response) => response.data);
	},

  async searchAll(paramsList) {
    const results = new Array(paramsList.length);
    try {
      await Promise.all(
        paramsList.map(async (param, index) => {
          Object.assign(param, { all: true });
          const data = await this.search(param);
          if (typeof param.callback === "function") {
            param.callback(data);
          } else if (param.target != undefined && Array.isArray(param.target)) {
            param.target.splice(0, param.target.length, ...data);
          } else if (param.target != undefined && typeof param.target === "object") {
            Object.assign(param.target, data[0] || {});
          }
          results[index] = data; // 해당 인덱스에 결과를 직접 저장
        })
      );
      //console.log('All data processed successfully:', results);
      return results;
    } catch (error) {
      console.error('Error during searchAll:', error);
      throw error;
    }
  },

  async saveBatch(paramsList) {
    const results = [];
		try {
			await paramsList.reduce(async (previousPromise, param, index) => {
				await previousPromise;
				const result = await this.api.saveData(param);
        results.push(result);
			}, Promise.resolve());
			//console.log('All operations completed successfully.');
      return results;
		} catch (error) {
			console.error('Error during batch operation:', error);
      return results;
		}
	}
};

instance.api = api;

export default instance;
