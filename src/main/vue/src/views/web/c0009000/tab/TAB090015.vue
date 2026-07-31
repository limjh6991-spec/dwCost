/**
 * TAB090015 - 월별 집계(수량_VN) : 재공품 공정 수불(수량), 도우코드 그레인 (VINA 전용)
 * 기초/기타입고/기타출고/재고 그룹은 +/- 여닫기
 */
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="1" class="period">
          <div class="form-floating me-1">
            <date-picker label="연도" mode="year" v-model="params.year" />
            <label for="floatingSelect" class="select">년도</label>
          </div>
        </b-col>
        <b-col cols="1" class="period">
          <div class="form-floating me-1">
            <b-form-select v-model="params.month" :options="monthOptions" class="form-control" style="padding-left: 60px; min-width: 150px;" />
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
          ref="prodSubulGrid"
          :uid="'prodSubulGrid'"
          :grid="prodSubulGrid"
          :layout="prodSubulGrid.layout"
          :step="'1'"
          :rows="prodSubulGridRows"
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
import gridField from '@web/c0009000/js/TAB090015.js';
import _ from 'lodash';

export default {
  name: 'TAB090015',
  props: {},
  components: {},
  setup() {
    const srchInfo = useC0001001();
    const userAuthInfo = useUserAuthInfo();
    return { srchInfo, userAuthInfo };
  },
  data() {
    return {
      prodSubulGrid: null,
      prodSubulGridRows: [],
      isInitializing: true,
      monthOptions: [
        { value: null, text: '전체' },
        { value: '01', text: '1월' }, { value: '02', text: '2월' }, { value: '03', text: '3월' },
        { value: '04', text: '4월' }, { value: '05', text: '5월' }, { value: '06', text: '6월' },
        { value: '07', text: '7월' }, { value: '08', text: '8월' }, { value: '09', text: '9월' },
        { value: '10', text: '10월' }, { value: '11', text: '11월' }, { value: '12', text: '12월' },
      ],
      params: { year: null, month: null, yyyymm: null, site: 'VINA' },
      siteMap: { 본사: 'HQ', VINA: 'VN', HQ: 'HQ', VN: 'VN' },
    };
  },
  watch: {
    'params.year'() { if (!this.isInitializing) this.getDataList(); },
    'params.month'() { if (!this.isInitializing) this.getDataList(); },
    prodCtg: {
      handler(newVal) {
        if (newVal && this.$refs.prodSubulGrid != null) {
          this.initialize();
          this.getDataList();
        }
      },
    },
  },
  computed: {
    prodCtg() { return this.userAuthInfo.curProdCtg; },
    gridView() { return this.$refs.prodSubulGrid ? this.$refs.prodSubulGrid.getGridView() : null; },
  },
  created() {
    this.isInitializing = true;
    this.initialize();
    this.initializeGrid();
    this.$nextTick(() => { this.isInitializing = false; });
  },
  mounted() {
    this.getDataList();
  },
  methods: {
    initialize() {
      const base = this.srchInfo.yyyymm;
      this.params.year = base ? String(base).substring(0, 4) : String(new Date().getFullYear());
      this.params.month = null; // 기준월 디폴트 = 전체
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },
    initializeGrid() {
      this.prodSubulGrid = _.cloneDeep(gridField);
    },
    searchClick() { this.getDataList(); },
    async getDataList() {
      const gv = this.gridView;
      if (gv) gv.commit();
      const yyyy = this.params.year ? String(this.params.year) : '';
      const yyyymm = this.params.month ? `${yyyy}${this.params.month}` : '';
      const site = this.params.site != null ? this.siteMap[this.params.site] : null;
      const resp = await this.$axios.api.search({
        menuId: 'c0009000',
        queryId: 'C0009001_Tab090015',
        queryParams: { yyyy, yyyymm, site },
        target: [],
      });
      this.prodSubulGridRows = Array.isArray(resp) ? resp : (resp && resp.data ? resp.data : []);
    },
    excelBtnClick() {
      const gv = this.gridView;
      if (!gv) return;
      const yyyymmdd = new Date().toISOString().slice(0, 10).replace(/-/g, '');
      gv.exportGrid({
        type: 'excel', target: 'local', fileName: `생산실적_월별집계_수량VN_${yyyymmdd}.xlsx`,
        showProgress: true, progressMessage: '엑셀 다운로드 중입니다.', indicator: 'hidden', header: 'visible', footer: 'visible',
      });
    },
  },
};
</script>

<style scoped>
</style>
