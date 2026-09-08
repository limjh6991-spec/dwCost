/** * 기준정보 > 공정 (TAB010007) — 타시스템 공정(PROCESS) 적재/조회. 원천 DOI_VN_IF_PROCESS */
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
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
        <RealGrid ref="procGrid" :uid="'procGrid'" :step="'1'" :rows="gridRows" style="height: 100%" :fixLayoutWidth="false" />
      </div>
    </div>
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import gridField from '@web/c0001000/js/TAB010007.js';
import ifaceApiMixin from '@/mixins/ifaceApiMixin.js';

export default {
  props: { tabId: { type: String, default: '' } },
  mixins: [ifaceApiMixin],
  setup() {
    const userAuthInfo = useUserAuthInfo();
    return { userAuthInfo };
  },
  data() {
    return {
      procGrid: null,
      gridRows: [],
      params: { site: 'VINA' },
      siteMap: { 본사: 'HQ', VINA: 'VN', HQ: 'HQ', VN: 'VN' },
    };
  },
  computed: {
    gridView() { return this.$refs.procGrid?.getGridView(); },
  },
  created() {
    this.procGrid = _.cloneDeep(gridField);
    this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
  },
  mounted() {
    this.$nextTick(() => { this.searchClick(); });
  },
  methods: {
    async getDataList() {
      if (!this.gridView) return;
      this.gridView.commit();
      const rows = [];
      await this.$axios.api.search({ menuId: 'c0001004', queryId: 'TAB010007_Sch1', queryParams: { site: this.siteMap[this.params.site] }, target: rows });
      this.gridRows.splice(0, this.gridRows.length, ...rows);
    },
    searchClick() { this.getDataList(); },
    // 공정(PROCESS, BSSPDBaseProcess) API 호출 → DOI_VN_IF_PROCESS 적재 → 그리드 새로고침
    apiCallClick() {
      this.callIface({
        key: 'PROCESS',
        params: { BizUnit: 0, site: this.siteMap[this.params.site] },
        successLabel: '공정',
        onSuccess: () => this.getDataList(),
      });
    },
    excelBtnClick() {
      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();
      const fileName = `공정${yyyymmdd}_${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}${String(now.getSeconds()).padStart(2, '0')}.xlsx`;
      this.gridView.exportGrid({ type: 'excel', target: 'local', fileName, progressMessage: '엑셀 Export중입니다.', done: () => alert('엑셀 내보내기가 완료되었습니다!') });
    },
  },
};
</script>
