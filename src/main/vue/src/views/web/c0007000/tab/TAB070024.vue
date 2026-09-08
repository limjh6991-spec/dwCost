/** * 타시스템 > 매출정보 > 수출신고필증조회 (TAB070024) — 수출신고필증(EXP_PERMIT) 적재/조회. 원천 DOI_VN_IF_EXP_PERMIT */
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
          <b-button v-show="showIfApiButton" class="second" @click="apiCallClick">API 호출</b-button>
          <b-button v-show="siteMap[params.site] === 'VN'" class="second" @click="openExchangeRate">환율관리</b-button>
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="permitGrid" :uid="'permitGrid'" :step="'1'" :rows="gridRows" style="height: 100%" :fixLayoutWidth="false" />
      </div>
    </div>
    <ExchangeRatePopup ref="exchangeRatePopup" @closePopup="onExchangeRateClosed" />
  </div>
</template>

<script>
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0007000/js/TAB070024.js';
import ifaceApiMixin from '@/mixins/ifaceApiMixin.js';
import ExchangeRatePopup from '@/components/ExchangeRatePopup.vue';

export default {
  props: { tabId: { type: String, default: '' } },
  components: { ExchangeRatePopup },
  mixins: [ifaceApiMixin],
  setup() {
    const srchInfo = useC0001001();
    return { srchInfo };
  },
  data() {
    return {
      permitGrid: null,
      gridRows: [],
      params: { yyyymm: null, site: 'VINA' },
      siteMap: { 본사: 'HQ', VINA: 'VN', HQ: 'HQ', VN: 'VN' },
    };
  },
  watch: {
    'params.yyyymm': function (newVal) { if (newVal) this.onDateChange(); },
    'srchInfo.yyyymm': { handler(newVal) { if (newVal) this.params.yyyymm = newVal; } },
  },
  computed: {
    gridView() { return this.$refs.permitGrid?.getGridView(); },
  },
  created() { this.permitGrid = _.cloneDeep(gridField); },
  mounted() {
    this.params.yyyymm = this.srchInfo.yyyymm;
    this.$nextTick(() => { this.searchClick(); });
  },
  methods: {
    onDateChange() { this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm }); },
    async getDataList() {
      if (!this.gridView) return;
      this.gridView.commit();
      const params = { yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null };
      const rows = [];
      await this.$axios.api.search({ menuId: 'c0007005', queryId: 'TAB070024_Sch1', queryParams: params, target: rows });
      this.gridRows.splice(0, this.gridRows.length, ...rows);
    },
    searchClick() {
      if (!this.params.yyyymm) { this.$toast && this.$toast('error', '년월 선택해주세요.'); return; }
      this.getDataList();
    },
    // 수출신고필증(EXP_PERMIT) API 호출 → DOI_VN_IF_EXP_PERMIT 적재 → 그리드 새로고침
    apiCallClick() {
      if (!this.params.yyyymm) { this.$toast && this.$toast('error', '년월 선택해주세요.'); return; }
      const yyyymm = this.params.yyyymm.replaceAll('-', '');
      const y = Number(yyyymm.slice(0, 4));
      const m = Number(yyyymm.slice(4, 6));
      const lastDay = String(new Date(y, m, 0).getDate()).padStart(2, '0');
      this.callIface({
        key: 'EXP_PERMIT',
        selCode: 'ACTUAL',
        yyyymm: yyyymm,
        params: { BizUnit: 0, PermitDateFr: `${yyyymm}01`, PermitDateTo: `${yyyymm}${lastDay}`, site: this.siteMap[this.params.site] },
        successLabel: '수출신고필증조회',
        onSuccess: () => this.getDataList(),
      });
    },
    // 환율관리(월평균 관리환율) 팝업 — ExchangeRatePopup(C0007012, DOI_EXCHANGE_RATE) 재사용
    openExchangeRate() {
      this.$refs.exchangeRatePopup.openDialog({ yyyymm: this.params.yyyymm });
    },
    onExchangeRateClosed() {
      this.searchClick();
    },
    excelBtnClick() {
      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();
      const fileName = `수출신고필증${yyyymmdd}_${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}${String(now.getSeconds()).padStart(2, '0')}.xlsx`;
      this.gridView.exportGrid({ type: 'excel', target: 'local', fileName, progressMessage: '엑셀 Export중입니다.', done: () => alert('엑셀 내보내기가 완료되었습니다!') });
    },
  },
};
</script>
