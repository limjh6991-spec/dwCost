/** * 결산증빙 자료 > 재품수불_금액(DOI_STCO) */
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
        <b-col cols="2">
          <div class="form-floating">
            <select class="form-select label-60" id="floatingSelect" v-model="params.gubun">
              <option v-for="gubun in gubunList" :key="gubun.value" :value="gubun">
                {{ gubun.text }}
              </option>
            </select>
            <label for="floatingSelect" class="select">구분</label>
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
        <RealGrid ref="stockCostGrid" :uid="'stockCostGrid'" :step="'1'" :rows="stockCostGridRows" style="height: 100%" />
      </div>
    </div>
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import gridField from '@web/c0008000/js/C0008010.js';

export default {
  props: {},
  components: {},
  setup() {
    const userAuthInfo = useUserAuthInfo();
    return { userAuthInfo };
  },
  data() {
    return {
      stockCostGrid: null,
      stockCostGridRows: [],
      params: {
        yyyymm: null,
        site: 'HQ',
        gubun: { value: '전체', text: '전체' },
      },
      gubunList: [
        { value: '전체', text: '전체' },
        { value: '개발', text: '개발' },
        { value: '양산', text: '양산' },
      ],
      siteMap: {
        본사: 'HQ', //DB map
        VINA: 'VN', //DB map
        HQ: 'HQ', //DB map
        VN: 'VN', //DB map
      },
      isProcessing: false,
    };
  },
  watch: {
    userAuthInfo: {
      handler(newVal) {
        if (newVal.curProdCtg) {
          this.params.site = newVal.curProdCtg === 'VN' ? 'VINA' : '본사';
          if (this.$refs.stockCostGrid != null) {
            this.initialize();
            this.searchClick();
          }
        }
      },
      deep: true,
      immediate: true,
    },
  },
  computed: {
    gridView() {
      return this.$refs.stockCostGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.stockCostGrid.getGridDataProvider();
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
      var current = new Date();
      this.params.yyyymm = `${current.getFullYear()}-${(current.getMonth() + 1).toString().padStart(2, '0')}`;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
      this.params.gubun = { value: '전체', text: '전체' };
    },
    initializeGrid() {
      this.stockCostGrid = _.cloneDeep(gridField);
    },
    async getDataList() {
      this.gridView.commit();

      let params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.params.site != null ? this.siteMap[this.params.site] : null,
        gubun: this.params.gubun != null ? this.params.gubun.value : null,
      };

      let param = {
        menuId: 'c0008000',
        queryId: 'C0008010_Sch1',
        queryParams: params,
        target: this.stockCostGridRows,
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
      const fileName = `제품수불금액${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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
