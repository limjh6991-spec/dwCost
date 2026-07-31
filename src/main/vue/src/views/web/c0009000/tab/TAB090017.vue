/**
 * TAB090017 - 제조원가(재공)_VN : 재공품 공정 수불 구조 + 항목별 수량/금액, 도우코드 그레인
 * 위치: C0009007 재공,제품 원가 > 제조원가(재공) 과 매출원가(제품) 사이 (VINA 전용)
 * 기초(BOH)/기타입고/기타출고/재고(EOH) 그룹은 +/- 여닫기
 */
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="1" class="period">
          <div class="form-floating me-1">
            <date-picker label="기준월" mode="month" v-model="params.yyyymm" />
            <label for="floatingSelect" class="select">기준월</label>
          </div>
        </b-col>
        <b-col cols="2" class="ms-3">
          <div class="form-floating">
            <input autocomplete="off" type="text" class="form-control label-60" id="floating" placeholder="Site" v-model="params.site" :disabled="true" />
            <label for="floating">사업장</label>
          </div>
        </b-col>
      </b-row>
      <div class="btn_area">
        <b-button @click="searchClick"><span class="ico_search"></span>조회</b-button>
      </div>
    </div>
    <div class="grid_box search_onerow">
      <div class="left_box">
        <div class="btn_wrap ms-auto">
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid
          ref="wipMfgGrid"
          :uid="'wipMfgGrid'"
          :grid="wipMfgGrid"
          :layout="wipMfgGrid.layout"
          :step="'1'"
          :rows="wipMfgGridRows"
          style="height: 100%"
          :fitLayoutWidthEnable="false"
        />
      </div>
    </div>
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0009000/js/TAB090017.js';
import _ from 'lodash';

export default {
  name: 'TAB090017',
  props: {},
  components: {},
  setup() {
    const srchInfo = useC0001001();
    const userAuthInfo = useUserAuthInfo();
    return {
      srchInfo,
      userAuthInfo,
    };
  },
  data() {
    return {
      wipMfgGrid: null,
      wipMfgGridRows: [],
      params: {
        yyyymm: null,
        site: 'VINA',
      },
      siteMap: {
        본사: 'HQ',
        VINA: 'VN',
        HQ: 'HQ',
        VN: 'VN',
      },
    };
  },
  watch: {
    'params.yyyymm': function(newVal) {
      if (newVal) {
        this.getDataList();
      }
    },
    'srchInfo.yyyymm': {
      handler(newVal) {
        if (newVal && !this.params.yyyymm) {
          this.params.yyyymm = newVal;
        }
      },
    },
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          if (this.$refs.wipMfgGrid != null) {
            this.initialize();
            this.getDataList();
          }
        }
      },
      immediate: true,
    },
  },
  computed: {
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    },
    gridView() {
      return this.$refs.wipMfgGrid?.gridView;
    },
    gridDataProvider() {
      return this.$refs.wipMfgGrid?.dataProvider;
    },
  },
  created() {
    this.initialize();
    this.initializeGrid();
  },
  mounted() {
    this.getDataList();
  },
  methods: {
    initialize() {
      const curMonth = this.srchInfo.yyyymm;
      this.params.yyyymm = curMonth || new Date().toISOString().slice(0, 7).replace('-', '');
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },
    initializeGrid() {
      this.wipMfgGrid = _.cloneDeep(gridField);
    },
    searchClick() {
      this.getDataList();
    },
    async getDataList() {
      if (!this.gridView) return;
      this.gridView.commit();

      let params = {
        yyyymm: this.params.yyyymm ? this.params.yyyymm.replace('-', '') : '',
        site: this.params.site != null ? this.siteMap[this.params.site] : null,
      };

      let param = {
        menuId: 'c0009000',
        queryId: 'C0009007_Tab090017',
        queryParams: params,
        target: this.wipMfgGridRows,
      };

      await this.$axios.api.search(param);
    },
    excelBtnClick() {
      const yyyymmdd = new Date().toISOString().slice(0, 10).replace(/-/g, '');
      const fileName = `제조원가_재공_VN_${yyyymmdd}.xlsx`;
      this.gridView.exportGrid({
        type: 'excel',
        target: 'local',
        fileName: fileName,
        showProgress: true,
        progressMessage: '엑셀 다운로드 중입니다.',
        indicator: 'hidden',
        header: 'visible',
        footer: 'visible',
      });
    },
  },
};
</script>

<style scoped>
</style>
