/** * 타시스템 > 자재투입정보(VN) > 품목별투입조회 (DOI_VN_MAT_INPUT) */
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
          <b-button v-show="showIfApiButton" class="second" @click="apiCallClick">API 호출</b-button>
          <b-button v-show="!isClosedMonth" class="second" @click="uploadClick">업로드</b-button>
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
          <b-button v-show="!isClosedMonth" @click="delBtnClick">삭제</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="dataGrid" :uid="'dataGrid'" :step="'1'" :rows="gridRows" style="height: 100%" :fixLayoutWidth="false" />
      </div>
    </div>
    <UploadPopup ref="uploadPopup1" @closePopup="closePopup" />
    <ExchangeRatePopup ref="exchangeRatePopup" @closePopup="onExchangeRateClosed" />
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import currencyConvert from '@web/c0007000/js/currencyConvert.js';
import ExchangeRatePopup from '@/components/ExchangeRatePopup.vue';
import gridField from '@web/c0007000/js/C0007012.js';

import ifaceApiMixin from '@/mixins/ifaceApiMixin.js';

export default {
  mixins: [currencyConvert, ifaceApiMixin],
  components: { ExchangeRatePopup },
  props: { tabId: { type: String, default: '' } },
  setup() {
    const srchInfo = useC0001001();
    const userAuthInfo = useUserAuthInfo();
    return { srchInfo, userAuthInfo };
  },
  data() {
    return { dataGrid: null, gridRows: [], params: { yyyymm: null, site: 'VINA' }, siteMap: { 본사: 'HQ', VINA: 'VN', HQ: 'HQ', VN: 'VN' }, isClosedMonth: false };
  },
  watch: {
    'params.yyyymm': async function (newVal) {
      if (newVal) { this.onDateChange(); await this.checkClosingMonth(); } else { this.isClosedMonth = false; }
    },
    'srchInfo.yyyymm': { handler(newVal) { if (newVal) this.params.yyyymm = newVal; } },
  },
  computed: {
    gridView() { return this.$refs.dataGrid?.getGridView(); },
    gridDataProvider() { return this.$refs.dataGrid?.getGridDataProvider(); },
  },
  created() {
    this.dataGrid = _.cloneDeep(gridField);
    this.currencyFields = (gridField.columns || []).map((c) => c.fieldName).filter((f) => f && (f.includes('금액') || f === '판매원가'));
  },
  mounted() {
    this.params.yyyymm = this.srchInfo.yyyymm;
    this.$nextTick(async () => { await this.checkClosingMonth(); this.searchClick(); });
  },
  methods: {
    async checkClosingMonth() {
      const yyyymm = this.params.yyyymm ? this.params.yyyymm.replaceAll('-', '') : null;
      if (!yyyymm) { this.isClosedMonth = false; return; }
      try {
        const res = await this.$axios.get('/api/common/closing-month/check', { params: { yyyymm } });
        this.isClosedMonth = res?.data?.isClosed === true || res?.data?.isClosed === 'Y';
      } catch (e) { this.isClosedMonth = false; }
    },
    onDateChange() { this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm }); },
    async getDataList() {
      if (!this.gridView) return;
      this.gridView.commit();
      let params = { yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null };
      const rows = [];
      await this.$axios.api.search({ menuId: 'c0007012', queryId: 'C0007012_VN_Sch1', queryParams: params, target: rows });
      const converted = await this.buildCurrencyRows(rows);
      this.gridRows.splice(0, this.gridRows.length, ...converted);
    },
    apiCallClick() {
      if (!this.params.yyyymm) { this.$toast && this.$toast('error', '년월 선택해주세요.'); return; }
      const yyyymm = this.params.yyyymm.replaceAll('-', '');
      // ERP DataBlock (ESM 원가): SMCostMng=5512001 고정 필수 + CostYMFr/To(YYYYMM). ⚠️품목별투입 전용 스펙 미확보 → 동일 ESM 패턴 적용(검증필요)
      this.callIface({
        key: 'ITEM_INPUT', selCode: 'ACTUAL', yyyymm: yyyymm,
        params: { SMCostMng: 5512001, CostYMFr: yyyymm, CostYMTo: yyyymm, site: this.siteMap[this.params.site] },
        successLabel: '품목별투입', onSuccess: () => this.getDataList(),
      });
    },
    searchClick() {
      if (!this.params.yyyymm) { this.$toast && this.$toast('error', '년월 선택해주세요.'); return; }
      this.getDataList();
    },
    delBtnClick() {
      if (!this.gridView || !this.gridDataProvider) return;
      this.gridView.commit();
      const checkedRows = this.gridView.getCheckedRows();
      if (checkedRows.length === 0) { this.$toast('info', '삭제할 행을 선택하세요'); return; }
      this.$confirm('확인', `${checkedRows.length}건을 삭제하시겠습니까?`, async (confirmed) => {
        if (!confirmed) return;
        let existingRows = [];
        checkedRows.forEach((idx) => { existingRows.push(this.gridDataProvider.getJsonRow(idx)); });
        if (existingRows.length > 0) {
          try {
            await this.$axios.api.saveData({ menuId: 'c0007012', delete: [{ queryId: 'C0007012_VN_Delete1', data: existingRows }] });
            this.searchClick();
          } catch { this.$toast('error', '삭제 중 에러가 발생했습니다.'); return; }
        }
        this.$toast('success', `${checkedRows.length}건이 삭제되었습니다.`);
      });
    },
    async excelBtnClick() {
      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();
      const fileName = `품목별투입조회${yyyymmdd}_${String(now.getHours()).padStart(2,'0')}${String(now.getMinutes()).padStart(2,'0')}${String(now.getSeconds()).padStart(2,'0')}.xlsx`;
      this.gridView.exportGrid({ type: 'excel', target: 'local', fileName, progressMessage: '엑셀 Export중입니다.', done: () => alert('엑셀 내보내기가 완료되었습니다!') });
    },
    uploadClick() {
      let excelGrid = _.cloneDeep(gridField);
      excelGrid.options.display.fitStyle = 'none';
      this.$refs.uploadPopup1.openDialog({
        dialogTitle: '품목별투입 업로드',
        uploadApi: '/api/c0007000/c0007012/upload',
        headers: ['field1','field2','field3','field4','field5','field6','field7','field8','field9','field10','field11','field12','field13'],
        excelGrid,
        fileName: '품목별투입조회_template',
      });
    },
    closePopup() { this.searchClick(); },
    onCurrencyChange(currency) { this.setCurrency(currency); this.getDataList(); },
    openExchangeRate() { this.$refs.exchangeRatePopup.openDialog({ yyyymm: this.params.yyyymm ? this.params.yyyymm.replaceAll('-', '') : null }); },
    onExchangeRateClosed() { if (this.isCurrencyReadonly) this.getDataList(); },
  },
};
</script>
