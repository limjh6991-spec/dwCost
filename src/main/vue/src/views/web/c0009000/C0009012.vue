/** * 원가레포트 > 제품 재고수불 (VN) - V18 신규 포맷 (재고수불 검증) */
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="1" class="period">
          <div class="form-floating me-1">
            <date-picker label="기준월" mode="month" v-model="params.yyyymm" @change="onDateInput" />
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
          ref="stockLedgerV18Grid"
          :uid="'stockLedgerV18Grid'"
          :step="'1'"
          :grid="stockLedgerV18Grid"
          :layout="stockLedgerV18Grid.columnLayout"
          :rows="stockLedgerV18GridRows"
          style="height: 100%"
        />
      </div>
    </div>
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0009000/js/C0009012_V18.js';

export default {
  props: {},
  setup() {
    const srchInfo = useC0001001();
    const userAuthInfo = useUserAuthInfo();
    return { srchInfo, userAuthInfo };
  },
  data() {
    return {
      stockLedgerV18Grid: null,
      stockLedgerV18GridRows: [],
      params: { yyyymm: null, site: 'VINA', selcode: 'ACTUAL' },
      siteMap: { 본사: 'HQ', VINA: 'VN', HQ: 'HQ', VN: 'VN' },
    };
  },
  watch: {
    'srchInfo.yyyymm': {
      handler(newVal) {
        if (newVal) this.params.yyyymm = newVal;
      },
    },
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          this.initialize();
        }
      },
    },
  },
  computed: {
    gridView() {
      return this.$refs.stockLedgerV18Grid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.stockLedgerV18Grid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    },
  },
  created() {
    this.initialize();
    this.initializeGrid();
  },
  methods: {
    initialize() {
      this.params.yyyymm = this.srchInfo.yyyymm;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },
    initializeGrid() {
      this.stockLedgerV18Grid = _.cloneDeep(gridField);
    },
    onDateInput() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },
    async getDataList() {
      const rows = [];
      const param = {
        menuId: 'c0009000',
        queryId: 'C0009012_Sch1',
        queryParams: {
          yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
          site: this.params.site != null ? this.siteMap[this.params.site] : null,
          selcode: this.params.selcode,
        },
        target: rows,
      };
      await this.$axios.api.search(param);
      this.stockLedgerV18GridRows.splice(0, this.stockLedgerV18GridRows.length, ...rows);
    },
    searchClick() {
      this.getDataList();
    },
    async excelBtnClick() {
      const grid = this.gridView;
      const yyyymmdd = this.$utils.getTodayDate();
      const now = new Date();
      const hh = String(now.getHours()).padStart(2, '0');
      const mm = String(now.getMinutes()).padStart(2, '0');
      const fileName = `제품재고수불(VN)_${yyyymmdd}_${hh}${mm}.xlsx`;
      grid.exportGrid({ type: 'excel', target: 'local', fileName, progressMessage: '엑셀 Export중입니다.', done: () => alert('엑셀 내보내기가 완료되었습니다!') });
    },
  },
};
</script>
