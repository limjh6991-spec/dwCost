/** * 판매관리비 집계표 > 부서별 집계표 */
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
        <b-col cols="3" class="ms-2 d-flex align-items-center" v-if="showCurrencySelect">
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
        <RealGrid ref="sgaGrid" :uid="'sgaGrid'" :step="'1'" :rows="sgaGridRows" style="height: 100%" />
      </div>
    </div>
    <ExchangeRatePopup ref="exchangeRatePopup" @closePopup="onExchangeRateClosed" />
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { applyAmtFormatLive } from '@/utils/gridUtils';
import { useC0001001 } from '@web/store/C0001001.js';
import currencyConvert from '@web/c0007000/js/currencyConvert.js';
import ExchangeRatePopup from '@/components/ExchangeRatePopup.vue';

export default {
  props: {},
  mixins: [currencyConvert],
  components: { ExchangeRatePopup },
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
      sgaGrid: null,
      sgaGridRows: [],
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
    'params.yyyymm': function (newVal) {
      if (newVal) {
        this.onDateChange();
      }
    },
    'srchInfo.yyyymm': {
      handler(newVal) {
        if (newVal) {
          this.params.yyyymm = newVal;
        }
      },
    },
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          if (this.$refs.sgaGrid != null) {
            this.initialize();
            this.searchClick();
          }
        }
      },
    },
  },
  computed: {
    gridView() {
      return this.$refs.sgaGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.sgaGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    },
  },
  created() {
    this.initialize();
    this.initializeGrid();
  },
  mounted() {},
  beforeUnmount() {},
  methods: {
    initialize() {
      this.params.yyyymm = this.srchInfo.yyyymm;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },
    initializeGrid() {
      this.sgaGrid = _.cloneDeep(require(`@web/c0009000/js/TAB090008.js`));
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },
    async getDataList() {
      this.gridView.commit();

      let params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.params.site != null ? this.siteMap[this.params.site] : null,
      };

      let searchParam = {
        menuId: 'c0009000',
        queryId: 'C0009008_Tab090008_Col',
        queryParams: params,
        target: null,
      };

      let result1 = await this.$axios.api.search(searchParam);
      const gridField1 = _.cloneDeep(require(`@web/c0009000/js/TAB090008.js`));
      // 통화별 금액 표시: VINA·USD면 2자리, KRW/VND·본사면 정수
      const isVinaUsd = this.userAuthInfo.curProdCtg === 'VN' && (this.currency === 'USD' || this.currency == null);
      const amtFmt = isVinaUsd ? '#,##0.00' : '#,##0';
      result1.forEach((item) => {
        gridField1.fields.push({
          fieldName: item.deptName,
          valueType: 'number',
          dataType: 'number',
        });

        gridField1.columns.push({
          name: item.deptName,
          fieldName: item.deptName,
          width: 80,
          header: {
            text: item.deptName,
          },
          autoFilter: false,
          numberFormat: amtFmt,
          styleName: 'tr',
        });
      });

      this.gridDataProvider.setFields(gridField1.fields);
      this.gridView.setColumns(gridField1.columns);
      applyAmtFormatLive(this.gridView, this.userAuthInfo.curProdCtg, this.currency);
      // 환산 대상 금액 컬럼(고정 + 동적 부서 컬럼) 수집
      this.currencyFields = gridField1.columns.filter((c) => c.numberFormat).map((c) => c.fieldName);

      const rows = [];
      await this.$axios.api.search({
        menuId: 'c0009000',
        queryId: 'C0009008_Tab090008',
        queryParams: params,
        target: rows,
      });
      // 선택 통화(KRW/VND)면 월평균 환율로 금액 환산 표시 (USD면 원본)
      const displayRows = await this.buildCurrencyRows(rows);
      this.sgaGridRows.splice(0, this.sgaGridRows.length, ...displayRows);
    },
    searchClick() {
      this.getDataList();
    },
    onCurrencyChange(currency) {
      this.setCurrency(currency);
      this.searchClick();
    },
    openExchangeRate() {
      this.$refs.exchangeRatePopup.openDialog({ yyyymm: this.params.yyyymm });
    },
    onExchangeRateClosed() {
      // 환율 등록/수정 후, 비-USD 표시 중이면 갱신된 환율로 재환산
      if (this.isCurrencyReadonly) this.searchClick();
    },
    async excelBtnClick() {
      const grid = this.gridView;

      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();

      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `판매관리비_부서별_집계표_${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

      const options = {
        type: 'excel',
        target: 'local',
        fileName: fileName,
        progressMessage: '엑셀 Export중입니다.',
        applyDynamicStyles: true,
        done: function () {
          alert('엑셀 내보내기가 완료되었습니다!');
        },
      };

      grid.exportGrid(options);
    },
    setCellStyleCallbackSgaGrid(grid, dataCell) {
      var ret = {};
      if (dataCell.dataColumn.name != 'gubun') {
        return ret;
      }
      var gubun = dataCell.value;
      if (this.$utils.containsValue(['합계'], gubun)) {
        ret.style = { fontWeight: 'bold', whiteSpace: 'pre', backgroundColor: '#BFBFBF', textAlign: 'center' };
      } else if (/^\s*\(\d+\)/.test(gubun)) {
        ret.style = { fontWeight: 'bold', whiteSpace: 'pre' };
      } else {
        ret.style = { fontWeight: 'normal', whiteSpace: 'pre' };
      }
      return ret;
    },
    setRowStyleCallbackSgaGrid(grid, item, fixed) {
      var ret = {};
      var gubun = grid.getValue(item.index, 'gubun');
      if (this.$utils.containsValue(['합계'], gubun)) {
        ret.style = { background: '#BFBFBF' };
      }
      return ret;
    },
  },
};
</script>
