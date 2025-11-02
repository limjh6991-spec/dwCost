/** * 결산증빙 자료 > 제품별 재공평가(DOI_COST) */
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
            <select class="form-select label-60" id="floatingSelect" v-model="params.acctName">
              <option v-for="acctName in acctNameList" :key="acctName.value" :value="acctName">
                {{ acctName.text }}
              </option>
            </select>
            <label for="floatingSelect" class="select">계정명</label>
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
        <RealGrid ref="costGrid" :uid="'costGrid'" :step="'1'" :rows="costGridRows" style="height: 100%" />
      </div>
    </div>
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import gridField from '@web/c0008000/js/C0008008.js';

export default {
  props: {},
  components: {},
  setup() {
    const userAuthInfo = useUserAuthInfo();
    return { userAuthInfo };
  },
  data() {
    return {
      costGrid: null,
      costGridRows: [],
      params: {
        yyyymm: null,
        site: 'HQ',
        acctName: { value: '전체', text: '전체' },
      },
      acctNameList: [
        { value: '전체', text: '전체' },
        { value: '경비', text: '경비' },
        { value: '감가비', text: '감가비' },
        { value: '인건비', text: '인건비' },
        { value: '재료비', text: '재료비' },
      ],
      siteMap: {
        본사: 'HQ', //DB map
        VINA: 'VN', //DB map
        HQ: 'HQ', //DB map
        VN: 'VN', //DB map
      },
    };
  },
  watch: {
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          if (this.$refs.costGrid != null) {
            this.initialize();
            this.searchClick();
          }
        }
      },
    },
  },
  computed: {
    gridView() {
      return this.$refs.costGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.costGrid.getGridDataProvider();
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
      var current = new Date();
      this.params.yyyymm = `${current.getFullYear()}-${(current.getMonth() + 1).toString().padStart(2, '0')}`;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
      this.params.acctName = { value: '전체', text: '전체' };
    },
    initializeGrid() {
      this.costGrid = _.cloneDeep(gridField);
    },
    async getDataList() {
      this.gridView.commit();

      let params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.params.site != null ? this.siteMap[this.params.site] : null,
        acctName: this.params.acctName != null ? this.params.acctName.value : null,
      };

      let param = {
        menuId: 'c0008000',
        queryId: 'C0008008_Sch1',
        queryParams: params,
        target: this.costGridRows,
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
      const fileName = `제품별재공평가${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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
