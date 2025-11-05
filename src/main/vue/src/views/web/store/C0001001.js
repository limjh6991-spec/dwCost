import { defineStore } from 'pinia';
import moment from 'moment';

export const useC0001001 = defineStore('c0001001', {
  state: () => ({
    yyyymm:moment().format('YYYY-MM'),
  }),
  getters: {
    getSearchkInfo:(state) => {
      return {
        yyyymm:state.yyyymm,
      };
    },
  },
  actions: {
    setSearchInfo(obj){
      this.yyyymm = obj.yyyymm;
    },
  },   
});