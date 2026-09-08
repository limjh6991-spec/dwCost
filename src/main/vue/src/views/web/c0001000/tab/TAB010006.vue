/** * 기준정보 > 언어별계정항목 (TAB010006) — 타시스템 언어별계정항목(ACCLANG) 적재/조회. 원천 DOI_VN_IF_ACCLANG */
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
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="acclangGrid" :uid="'acclangGrid'" :step="'1'" :rows="gridRows" style="height: 100%" :fixLayoutWidth="false" />
      </div>
    </div>
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0001000/js/TAB010006.js';
import ifaceApiMixin from '@/mixins/ifaceApiMixin.js';

export default {
  props: { tabId: { type: String, default: '' } },
  mixins: [ifaceApiMixin],
  setup() {
    const srchInfo = useC0001001();
    const userAuthInfo = useUserAuthInfo();
    return { srchInfo, userAuthInfo };
  },
  data() {
    return {
      acclangGrid: null,
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
    gridView() { return this.$refs.acclangGrid?.getGridView(); },
  },
  created() {
    this.acclangGrid = _.cloneDeep(gridField);
    this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
  },
  mounted() {
    this.params.yyyymm = this.srchInfo.yyyymm;
    this.$nextTick(() => { this.searchClick(); });
  },
  methods: {
    onDateChange() { this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm }); },
    async getDataList() {
      if (!this.gridView) return;
      this.gridView.commit();
      const rows = [];
      await this.$axios.api.search({ menuId: 'c0001004', queryId: 'TAB010006_Sch1', queryParams: { site: this.siteMap[this.params.site] }, target: rows });
      this.gridRows.splice(0, this.gridRows.length, ...rows);
    },
    searchClick() { this.getDataList(); },
    // 언어별계정항목(ACCLANG, BSSACFSItemForName) API 호출 → DOI_VN_IF_ACCLANG 적재 → 그리드 새로고침
    apiCallClick() {
      const yyyymm = this.params.yyyymm ? this.params.yyyymm.replaceAll('-', '') : null;
      this.callIface({
        key: 'ACCLANG',
        yyyymm: yyyymm,
        selCode: 'ACTUAL',
        params: { site: this.siteMap[this.params.site] },
        successLabel: '언어별계정항목',
        onSuccess: () => this.getDataList(),
      });
    },
    excelBtnClick() {
      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();
      const fileName = `언어별계정항목${yyyymmdd}_${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}${String(now.getSeconds()).padStart(2, '0')}.xlsx`;
      this.gridView.exportGrid({ type: 'excel', target: 'local', fileName, progressMessage: '엑셀 Export중입니다.', done: () => alert('엑셀 내보내기가 완료되었습니다!') });
    },
  },
};
</script>
