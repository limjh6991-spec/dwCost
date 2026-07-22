/** * 판매관리비 집계표 > 부서별 집계표(누적) */
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="1" class="period">
          <div class="form-floating me-1">
            <date-picker label="시작월" mode="month" v-model="params.fromYyyymm" />
            <label for="floatingSelect" class="select">시작월</label>
          </div>
        </b-col>
        <b-col cols="auto" class="d-flex align-items-center px-1">~</b-col>
        <b-col cols="1" class="period">
          <div class="form-floating me-1">
            <date-picker label="종료월" mode="month" v-model="params.toYyyymm" />
            <label for="floatingSelect" class="select">종료월</label>
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
        fromYyyymm: null,
        toYyyymm: null,
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
    'srchInfo.yyyymm': {
      handler(newVal) {
        if (newVal) {
          this.params.toYyyymm = newVal;
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
      const yyyymm = this.srchInfo.yyyymm;
      this.params.toYyyymm = yyyymm;
      if (yyyymm) {
        const yyyy = yyyymm.substring(0, 4);
        this.params.fromYyyymm = yyyy + '-01';
      }
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },
    initializeGrid() {
      this.sgaGrid = _.cloneDeep(require(`@web/c0009000/js/TAB090008.js`));
    },
    async getDataList() {
      this.gridView.commit();

      let params = {
        fromYyyymm: this.params.fromYyyymm != null ? this.params.fromYyyymm.replaceAll('-', '') : null,
        toYyyymm: this.params.toYyyymm != null ? this.params.toYyyymm.replaceAll('-', '') : null,
        site: this.params.site != null ? this.siteMap[this.params.site] : null,
      };

      let searchParam = {
        menuId: 'c0009000',
        queryId: 'C0009008_Tab090008_Cum_Col',
        queryParams: params,
        target: null,
      };

      let result1 = await this.$axios.api.search(searchParam);
      const gridField1 = _.cloneDeep(require(`@web/c0009000/js/TAB090008.js`));
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
      this.currencyFields = gridField1.columns.filter((c) => c.numberFormat).map((c) => c.fieldName);

      const rows = [];
      await this.$axios.api.search({
        menuId: 'c0009000',
        queryId: 'C0009008_Tab090008_Cum',
        queryParams: params,
        target: rows,
      });
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
      this.$refs.exchangeRatePopup.openDialog({ yyyymm: this.params.toYyyymm });
    },
    onExchangeRateClosed() {
      if (this.isCurrencyReadonly) this.searchClick();
    },
    async excelBtnClick() {
      const grid = this.gridView;
      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `판매관리비_부서별_집계표_누적_${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;
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
    setCellStyleCallbackSgaCumGrid(grid, dataCell) {
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
    setRowStyleCallbackSgaCumGrid(grid, item, fixed) {
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
