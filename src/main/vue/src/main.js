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
// 번역 데이터는 DB API에서 동적 로드 (2차 사전: 단어 단위 매칭)
let koToVi = {};      // 1차: 전체 텍스트 매칭용
let koToViDict = {};   // 2차: 단어 사전 (긴 단어 우선)
let dictKeys = [];     // 사전 키 배열 (긴 단어 우선 정렬됨)

// 텍스트에서 한국어 단어를 사전으로 치환
function translateText(text) {
  if (!text || typeof text !== 'string') return text;
  const trimmed = text.trim();
  if (!trimmed) return text;
  
  // 1. 정확 매칭 우선 (1차 테이블)
  if (koToVi[trimmed]) return koToVi[trimmed];
  
  // 2. 단어 단위 치환 (2차 사전) - 긴 단어부터 매칭
  let result = trimmed;
  for (const ko of dictKeys) {
    if (result.includes(ko)) {
      result = result.split(ko).join(koToViDict[ko]);
    }
  }
  return result;
}

// DB에서 번역 데이터 로드 (localStorage 캐싱)
async function loadTranslations() {
  const currentLang = localStorage.getItem('locale') || 'ko';
  if (currentLang !== 'vi') return;

  // 캐시 확인
  const cached1 = localStorage.getItem('i18n_full');
  const cached2 = localStorage.getItem('i18n_dict');
  const cachedTime = localStorage.getItem('i18n_cache_time');
  const CACHE_TTL = 1000 * 60 * 60; // 1시간

  if (cached1 && cached2 && cachedTime && (Date.now() - parseInt(cachedTime)) < CACHE_TTL) {
    try {
      koToVi = JSON.parse(cached1);
      koToViDict = JSON.parse(cached2);
      dictKeys = Object.keys(koToViDict);
      console.log(`[i18n] 캐시 로드: 1차=${Object.keys(koToVi).length}건, 2차=${dictKeys.length}건`);
      return;
    } catch (e) {
      localStorage.removeItem('i18n_full');
      localStorage.removeItem('i18n_dict');
    }
  }

  // API에서 로드
  try {
    const baseURL = process.env.VUE_APP_API_URL || '';
    const [res1, res2] = await Promise.all([
      fetch(`${baseURL}/api/public/i18n?lang=vi`),
      fetch(`${baseURL}/api/public/i18n/dict?lang=vi`)
    ]);
    
    if (res1.ok) {
      const data = await res1.json();
      koToVi = data.translations || {};
    }
    if (res2.ok) {
      const data = await res2.json();
      koToViDict = data.dict || {};
      dictKeys = Object.keys(koToViDict); // 이미 긴 단어 우선 정렬됨
    }
    
    // 캐시 저장
    localStorage.setItem('i18n_full', JSON.stringify(koToVi));
    localStorage.setItem('i18n_dict', JSON.stringify(koToViDict));
    localStorage.setItem('i18n_cache_time', Date.now().toString());
    console.log(`[i18n] API 로드: 1차=${Object.keys(koToVi).length}건, 2차=${dictKeys.length}건`);
  } catch (e) {
    console.warn('[i18n] API 연결 실패:', e.message);
  }
}

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

// 워닝이 너무 많이 떠서 일단 콘솔 경고 비활성화
app.config.warnHandler = () => {};

//전역 에러 처리
app.config.errorHandler = (err, instance, info) => {
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
    return translateText(text);
  }
  return text;
};

// Global Translation Mixin - 2차 사전 기반 단어 단위 번역
app.mixin({
  mounted() {
    this.translateDOM();
  },
  updated() {
    this.translateDOM();
  },
  methods: {
    translateDOM() {
      const currentLang = localStorage.getItem('locale') || 'ko';
      if (document.documentElement.getAttribute('data-app-lang') !== currentLang) {
        document.documentElement.setAttribute('data-app-lang', currentLang);
      }
      if (currentLang !== 'vi') return;
      if (this.$el && this.$el.nodeType === 1) {
        const walk = (node) => {
          if (node.classList && (
            node.classList.contains('realgrid') || 
            node.classList.contains('rg-root') || 
            (node.id && node.id.startsWith('realgrid'))
          )) {
            return;
          }
          if (node.nodeType === 3) {
            const text = node.nodeValue.trim();
            if (text) {
              const translated = translateText(text);
              if (translated !== text) {
                node.nodeValue = translated;
              }
            }
          } else if (node.nodeType === 1) {
            if (node.tagName === 'OPTION') {
              const text = node.textContent.trim();
              if (text) {
                const translated = translateText(text);
                if (translated !== text) {
                  node.textContent = translated;
                }
              }
            }
            const placeholder = node.getAttribute('placeholder');
            if (placeholder) {
              const translated = translateText(placeholder.trim());
              if (translated !== placeholder.trim()) {
                node.setAttribute('placeholder', translated);
              }
            }
            node.childNodes.forEach(walk);
          }
        };
        walk(this.$el);
      }
    }
  }
});

// 초기 페인트부터 언어 스코프가 적용되도록 루트 속성 설정
document.documentElement.setAttribute('data-app-lang', localStorage.getItem('locale') || 'ko');

// 번역 로드 후 앱 마운트
loadTranslations().finally(() => {
  app.mount('#app');
});

