/** * TAB090002 - 월별, 기간별(누적) 조회 */
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="1" class="period">
          <div class="form-floating me-1">
            <date-picker label="시작월" mode="month" v-model="params.startYyyymm" />
            <label for="floatingSelect" class="select">시작월</label>
          </div>
        </b-col>
        <b-col cols="1" class="period">
          <div class="form-floating me-1">
            <date-picker label="종료월" mode="month" v-model="params.endYyyymm" />
            <label for="floatingSelect" class="select">종료월</label>
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
        <RealGrid ref="prodSubulGrid" :uid="'prodSubulGrid'" :step="'1'" :rows="prodSubulGridRows" style="height: 100%" />
      </div>
    </div>
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0009000/js/TAB090002.js';

export default {
  props: {},
  components: {},
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
      prodSubulGrid: null,
      prodSubulGridRows: [],
      params: {
        startYyyymm: null,
        endYyyymm: null,
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
    'params.startYyyymm': function(newVal) {
      if (newVal) {
        this.onDateChange();
      }
    },
    'params.endYyyymm': function(newVal) {
      if (newVal) {
        this.onDateChange();
      }
    },
    'srchInfo.yyyymm': {
      handler(newVal) {
        if (newVal && !this.params.startYyyymm) {
          this.params.startYyyymm = newVal;
          this.params.endYyyymm = newVal;
          console.log('[Tab090002] yyyymm 변경:', this.params.startYyyymm);
        }
      }
     },
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          if (this.$refs.prodSubulGrid != null) {
            this.initialize();
            this.searchClick();
          }
        }
      },
    },
  },
  computed: {
    gridView() {
      return this.$refs.prodSubulGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.prodSubulGrid.getGridDataProvider();
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
      const curMonth = this.srchInfo.yyyymm;
      this.params.startYyyymm = curMonth;
      this.params.endYyyymm = curMonth;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },
    initializeGrid() {
      this.prodSubulGrid = _.cloneDeep(gridField);
    },
    onDateChange() {
      // 기간 선택시 별도 처리 불필요
    },
    async getDataList() {
      this.gridView.commit();

      let params = {
        startYyyymm: this.params.startYyyymm != null ? this.params.startYyyymm.replaceAll('-', '') : null,
        endYyyymm: this.params.endYyyymm != null ? this.params.endYyyymm.replaceAll('-', '') : null,
        site: this.params.site != null ? this.siteMap[this.params.site] : null,
      };

      let param = {
        menuId: 'c0009000',
        queryId: 'C0009001_Tab090002',
        queryParams: params,
        target: this.prodSubulGridRows,
      };
      let resp = await this.$axios.api.search(param);
    },
    searchClick() {
      this.getDataList();
    },
    async excelBtnClick() {
      const grid = this.gridView;

      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();

      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `생산실적_기간별누적_${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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
