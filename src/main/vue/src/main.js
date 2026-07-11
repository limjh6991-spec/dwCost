import { createApp, nextTick, ref } from 'vue'
import App from './App.vue'
import 'vue3-toastify/dist/index.css';
import axios from './plugins/axios.js';
import './assets/styles.css'
import router from './router'
import dwcomponents from './components/components.js';
import { createPinia } from 'pinia';
import utils from './utils/utils';
import _ from "lodash"; // Lodash 전체 import
import { v4 as uuidv4 } from 'uuid';
import showToast from './utils/toast';
import mitt from 'mitt';
import JSZip from 'jszip';
import moment from 'moment';
import BootstrapVue3 from 'bootstrap-vue-3';
import 'bootstrap/dist/css/bootstrap.css';
import 'bootstrap-vue-3/dist/bootstrap-vue-3.css';
import 'bootstrap-icons/font/bootstrap-icons.css';

import RealGrid from 'realgrid';
import popup from './plugins/popup';
import "@assets/style/realgrid.css";
import "@assets/style/font.css";
import zIndexManager from "@/utils/zIndexManager";
import koToVi from '@/assets/i18n/ko_to_vi.json';

//import * as ionicons5 from '@vicons/ionicons5';
//import { LogInOutline } from '@vicons/ionicons5';

window.JSZip = JSZip;

//STYLE
import '@assets/style/dwScss/dwScss.scss'
import '@assets/style/normalize.css'
import '@assets/style/realgrid.css'

const app = createApp(App);
const pinia = createPinia();
const eventBus = mitt();

// RealGrid2 라이선스 적용
RealGrid.setLicenseKey(process.env.VUE_APP_REAL_GRID_2LIC);

// Object.keys(ionicons5).forEach((key) => {
//   const icon = ionicons5[key];
//   if (icon) {
//     app.component(key, defineComponent (icon));	
// 	}
// });
//app.component('LogInIcon', defineComponent(LogInOutline));

// 워닝이 너무 많이 떠서 일단 콘솔 경고 비활성화
app.config.warnHandler = () => {};

//전역 에러 처리
app.config.errorHandler = (err, instance, info) => {
  // RealGrid 라이선스 만료 에러는 개발환경에서 무시 (워터마크만 표시됨)
  if (err && err.toString().includes('LicenseError')) {
    console.warn('[RealGrid] 라이선스 만료 - 개발환경에서는 워터마크가 표시됩니다.');
    return;
  }
  console.error(`전역 에러 처리: ${err}`);
  showToast("error","시스템 관리자에게 문의하십시오.\n"+err);
};

// Promise 에러 처리
window.onunhandledrejection = (event) => {
  console.error('전역 Promise 에러:', event.reason);
  showToast("error","시스템 관리자에게 문의하십시오.\nMessage: "+event.reason.message);
};

// 전역 오류 처리
window.onerror = (message, source, lineno, colno, error) => {
  // console.error('전역 Error:', message, source, lineno, colno, error);
  showToast("error","시스템 관리자에게 문의하십시오.\n"+message);
};

app.use(BootstrapVue3);
app.use(dwcomponents);
app.use(router);
app.use(pinia);
app.use(popup);


// Toast를 Pinia에 전역 등록
pinia.use(({ store }) => {
  store.$toast = showToast;
});

app.config.globalProperties.$axios = axios;
app.config.globalProperties.$toast = showToast;
app.config.globalProperties.$utils = utils;
app.config.globalProperties.$_ = _;
app.config.globalProperties.$nextTick = nextTick;
app.config.globalProperties.$ref = ref;
app.config.globalProperties.$uuid = uuidv4;
app.config.globalProperties.$eventBus = eventBus;
app.config.globalProperties.$moment = moment;
app.config.globalProperties.$zIndexManager = zIndexManager;
app.config.globalProperties.$trans = (text) => {
  if (!text) return '';
  const currentLang = localStorage.getItem('locale') || 'ko';
  if (currentLang === 'vi') {
    const key = text.toString().trim();
    return koToVi[key] || text;
  }
  return text;
};

app.mount('#app');
