/**
 * 조회조건 유지 믹스인 (searchStatePersist)
 * ----------------------------------------------------------------------------
 * 배경: 전역 keep-alive(App.vue)에도 불구하고 일부 라우트 화면이 상단 메뉴 탭 전환 후
 *       복귀 시 재mount되어 조회조건·결과가 초기화되는 현상이 있다(런타임 keep-alive 무력화).
 *       이 믹스인은 keep-alive 성패와 무관하게, 화면별 마지막 조회조건을 SPA 세션 동안
 *       유지되는 module-level 캐시에 저장했다가 재mount 시 복원+자동 재조회하도록 한다.
 *
 * 사용법:
 *   import searchStatePersist from '@/mixins/searchStatePersist.js';
 *   mixins: [searchStatePersist],
 *   data() { return { stateKey: 'C0009007_TAB090006' }; }   // 화면 고유 키(필수)
 *   // 조회 성공 지점: this.saveSearchState({ year, month, ... });
 *   // mounted(): const s = this.getSearchState(); if (s) { params 복원; this.searchClick(); }
 *
 * 주의: 캐시는 전체 새로고침(F5)/로그아웃 시 사라진다(의도 — keep-alive 대체 수명과 동일).
 */
const _cache = {};

export default {
  methods: {
    /** 현재 화면(stateKey)의 조회조건 스냅샷을 저장한다. stateKey 없으면 무시. */
    saveSearchState(snapshot) {
      if (this.stateKey) _cache[this.stateKey] = { ...snapshot };
    },
    /** 저장된 조회조건 스냅샷을 반환한다(없으면 null). */
    getSearchState() {
      return this.stateKey ? _cache[this.stateKey] || null : null;
    },
    /** 저장된 조회조건을 폐기한다(초기 상태로 시작하고 싶을 때). */
    clearSearchState() {
      if (this.stateKey) delete _cache[this.stateKey];
    },
  },
};
