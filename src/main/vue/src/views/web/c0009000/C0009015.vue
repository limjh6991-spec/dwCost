/** * 재고자산 평가 */
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
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="journalGrid" :uid="'journalGrid'" :step="'1'" :rows="journalGridRows" :grid="journalGrid" style="height: 100%" />
      </div>
    </div>
    <ExchangeRatePopup ref="exchangeRatePopup" @closePopup="onExchangeRateClosed" />
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0009000/js/C0009015.js';
import { applyAmtFormat } from '@/utils/gridUtils';
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
      userAuthInfo 
    };
  },
  data() {
    return {
      journalGrid: null,
      journalGridRows: [],
      params: {
        yyyymm: null,
        site: 'HQ',
        selCode: '',
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
        this.onDateChange();
      }
    },
    'srchInfo.yyyymm': {
      handler(newVal) {
        if (newVal) {
          this.params.yyyymm = newVal;
        }
      }
     },
    prodCtg: {
      async handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';

          if (this.$refs.journalGrid != null) {
            this.initialize();
            this.searchClick();
          }
        }
      },
    },
  },
  computed: {
    hasSysAdmin() {
      const roleList = this.userAuthInfo?.roleList || [];
      return roleList.includes('SYSADMIN');
    },
    gridView() {
      return this.$refs.journalGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.journalGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    },
  },
  created() {
    this.initialize();
    this.initializeGrid();
  },
  mounted() {
    const gv = this.gridView;
    if (!gv) return;

    gv.setRowStyleCallback((grid, item) => {
      const row = item?.dataRow ?? item?.itemIndex ?? item?.index;
      if (row == null || row < 0) return null;

      const gubun = String(grid.getValue(row, '구분') ?? '');
      const assetType = String(grid.getValue(row, '재고자산구분') ?? '');
      const itemCode = String(grid.getValue(row, '품번') ?? '');
      const isSummaryRow = (gubun === '합계' || itemCode.includes('합계')) && ['재공품', '제품'].includes(assetType);

      if (isSummaryRow) {
        return { style: { background: '#e8f4f8', fontWeight: 'bold' } };
      }

      return null;
    });
  },
  beforeUnmount() {},
  methods: {    
    initialize() {
      this.params.yyyymm = this.srchInfo.yyyymm;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },
    initializeGrid() {
      this.journalGrid = _.cloneDeep(gridField);
      this.currencyFields = gridField.currencyFields || [];
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },
    getSafeNumber(value) {
      const parsed = Number(value);
      return Number.isFinite(parsed) ? parsed : 0;
    },
    appendSummaryRows(rows) {
      const summaryMap = new Map();
      const targetGroups = ['재공품', '제품'];

      for (const row of rows) {
        const group = row?.['재고자산구분'];
        if (!targetGroups.includes(group)) continue;

        if (!summaryMap.has(group)) {
          summaryMap.set(group, {
            yyyymm: this.params.yyyymm ? this.params.yyyymm.replaceAll('-', '') : '',
            재고자산구분: group,
            구분: '합계',
            품번: `${group} 합계`,
            재고수량: 0,
            취득원가: 0,
            판매단가Krw: null,
            판매단가Usd: null,
            환율: null,
            nrv: 0,
            차이: 0,
            비고: '',
          });
        }

        const summary = summaryMap.get(group);
        summary.재고수량 += this.getSafeNumber(row?.['재고수량']);
        summary.취득원가 += this.getSafeNumber(row?.['취득원가']);
        summary.nrv += this.getSafeNumber(row?.['nrv']);
        summary.차이 += this.getSafeNumber(row?.['차이']);
      }

      const summaryRows = targetGroups
        .filter((group) => summaryMap.has(group))
        .map((group) => summaryMap.get(group));

      return [...rows, ...summaryRows];
    },
    async getDataList() {
      this.gridView.commit();

      // VINA(USD): 금액 컬럼 소수점 2자리 표시 (본사는 정수 유지)
      applyAmtFormat(this.gridView, this.journalGrid.columns, this.userAuthInfo.curProdCtg, this.currency);

      let params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.params.site != null ? this.siteMap[this.params.site] : null,
        selCode: this.params.selCode === '' ? 'ACTUAL' : this.params.selCode,
      };

      const rows = [];
      let param = {
        menuId: 'c0009000',
        queryId: 'C0009015_Sch1',
        queryParams: params,
        target: rows,
      };
      await this.$axios.api.search(param);
      const displayRows = await this.buildCurrencyRows(rows);
      this.journalGridRows = this.appendSummaryRows(displayRows);
      this.gridDataProvider.setRows(this.journalGridRows);
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
      if (this.isCurrencyReadonly) this.searchClick();
    },
    async excelBtnClick() {
      const grid = this.gridView;

      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();

      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `재고자산평가_${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

      const options = {
        type: 'excel',
        target: 'local',
        fileName: fileName,
        progressMessage: '엑셀 Export중입니다.',
        done: function () {
          alert('엑셀 내보내기가 완료되었습니다!');
        },
      };

      grid.exportGrid(options);
    },
  },
};
</script>
