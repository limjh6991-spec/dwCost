import { defineStore } from 'pinia';
import moment from 'moment';

export const useC0001001 = defineStore('c0001001', {
  state: () => ({
    yyyymm:moment().format('YYYY-MM'),
    currency:'USD', // VINA 화면 표시통화 (USD 기본 / KRW / VND). 화면군 공유
  }),
  getters: {
    getSearchkInfo:(state) => {
      return {
        yyyymm:state.yyyymm,
      };
    },
    curCurrency:(state) => state.currency,
  },
  actions: {
    setSearchInfo(obj){
      this.yyyymm = obj.yyyymm;
    },
    setCurrency(currency){
      this.currency = currency || 'USD';
    },
  },
});