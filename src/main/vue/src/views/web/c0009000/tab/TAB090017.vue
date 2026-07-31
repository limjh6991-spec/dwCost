/**
 * TAB090017 - 제조원가(재공)_VN : 재공품 공정 수불 구조 + 항목별 수량/금액, 도우코드 그레인
 * 위치: C0009007 재공,제품 원가 > 제조원가(재공) 과 매출원가(제품) 사이 (VINA 전용)
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
        <b-col cols="2" class="ms-3" v-if="showCurrencySelect">
          <div class="form-floating">
            <select class="form-select label-60" id="currencySelect" :value="currency" @change="onCurrencyChange($event.target.value)">
              <option value="USD">USD</option>
              <option value="KRW">KRW</option>
              <option value="VND">VND</option>
            </select>
            <label for="currencySelect">통화</label>
          </div>
        </b-col>
        <b-col cols="2" class="ms-3" v-if="showCurrencySelect">
          <div class="form-floating">
            <input autocomplete="off" type="text" class="form-control label-60" id="baseRate" :value="baseRateDisplay" placeholder="기준환율" :disabled="true" />
            <label for="baseRate">기준환율</label>
          </div>
        </b-col>
        <b-col cols="2" class="ms-2 d-flex align-items-center" v-if="showCurrencySelect">
          <b-button class="second" size="sm" @click="openExchangeRate">환율관리</b-button>
          <span class="ms-2 text-primary" style="font-size: 12px">{{ appliedRateLabel }}</span>
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
    <ExchangeRatePopup ref="exchangeRatePopup" @closePopup="onExchangeRateClosed" />
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import currencyConvert from '@web/c0007000/js/currencyConvert.js';
import ExchangeRatePopup from '@/components/ExchangeRatePopup.vue';
import gridField from '@web/c0009000/js/TAB090017.js';
import _ from 'lodash';

export default {
  name: 'TAB090017',
  mixins: [currencyConvert],
  components: { ExchangeRatePopup },
  setup() {
    const srchInfo = useC0001001();
    const userAuthInfo = useUserAuthInfo();
    return { srchInfo, userAuthInfo };
  },
  data() {
    return {
      wipMfgGrid: null,
      wipMfgGridRows: [],
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
        if (newVal && this.$refs.wipMfgGrid != null) {
          this.initialize();
          this.getDataList();
        }
      },
    },
  },
  computed: {
    prodCtg() { return this.userAuthInfo.curProdCtg; },
    gridView() { return this.$refs.wipMfgGrid ? this.$refs.wipMfgGrid.getGridView() : null; },
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
      this.params.yyyymm = null;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },
    initializeGrid() {
      this.wipMfgGrid = _.cloneDeep(gridField);
    },
    searchClick() { this.getDataList(); },
    async getDataList() {
      const gv = this.gridView;
      if (gv) gv.commit();
      const yyyy = this.params.year ? String(this.params.year) : '';
      const yyyymm = this.params.month ? `${yyyy}${this.params.month}` : '';
      this.params.yyyymm = yyyymm || null;
      const site = this.params.site != null ? this.siteMap[this.params.site] : null;
      const resp = await this.$axios.api.search({
        menuId: 'c0009000',
        queryId: 'C0009007_Tab090017',
        queryParams: { yyyy, yyyymm, site },
        target: [],
      });
      const raw = Array.isArray(resp) ? resp : (resp && resp.data ? resp.data : []);
      this.currencyFields = raw.length ? Object.keys(raw[0]).filter((k) => /Amt$/i.test(k)) : [];
      this.wipMfgGridRows = await this.buildCurrencyRows(raw);
    },
    onCurrencyChange(currency) {
      this.setCurrency(currency);
      this.getDataList();
    },
    openExchangeRate() {
      this.$refs.exchangeRatePopup.openDialog({ yyyymm: this.params.yyyymm || (this.params.year ? `${this.params.year}01` : null) });
    },
    onExchangeRateClosed() {
      if (this.isCurrencyReadonly) this.getDataList();
    },
    excelBtnClick() {
      const gv = this.gridView;
      if (!gv) return;
      const yyyymmdd = new Date().toISOString().slice(0, 10).replace(/-/g, '');
      gv.exportGrid({
        type: 'excel', target: 'local', fileName: `제조원가_재공_VN_${yyyymmdd}.xlsx`,
        showProgress: true, progressMessage: '엑셀 다운로드 중입니다.', indicator: 'hidden', header: 'visible', footer: 'visible',
      });
    },
  },
};
</script>

<style scoped>
</style>
