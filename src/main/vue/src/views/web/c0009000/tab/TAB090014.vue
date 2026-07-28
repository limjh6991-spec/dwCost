/**
 * TAB090014 - 재공품 공정 수불 (생산실적 > 재공품 공정 수불)
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
          ref="wipSubulGrid"
          :uid="'wipSubulGrid'"
          :grid="wipSubulGrid"
          :layout="wipSubulGrid.layout"
          :step="'1'"
          :rows="wipSubulGridRows"
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
import gridField from '@web/c0009000/js/TAB090014.js';
import _ from 'lodash';

export default {
  name: 'TAB090014',
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
      wipSubulGrid: null,
      wipSubulGridRows: [],
      params: {
        yyyymm: null,
        site: 'HQ',
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
          if (this.$refs.wipSubulGrid != null) {
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
      return this.$refs.wipSubulGrid?.gridView;
    },
    gridDataProvider() {
      return this.$refs.wipSubulGrid?.dataProvider;
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
      this.wipSubulGrid = _.cloneDeep(gridField);
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
        queryId: 'C0009001_Tab090014',
        queryParams: params,
        target: this.wipSubulGridRows,
      };

      await this.$axios.api.search(param);
    },
    excelBtnClick() {
      const yyyymmdd = new Date().toISOString().slice(0, 10).replace(/-/g, '');
      const fileName = `생산실적_재공품공정수불_${yyyymmdd}.xlsx`;
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
