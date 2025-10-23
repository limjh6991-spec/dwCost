/** * 결산증빙 자료 > 제품별 투입 비용(DOI_PROD_EXPN) */
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
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="prodExpnGrid" :uid="'prodExpnGrid'" :step="'1'" :rows="prodExpnGridRows" style="height: 100%" />
      </div>
    </div>
    <CmDialog1 ref="cmDialog1C00008004" />
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import gridField from '@web/c0008000/js/C0008004.js';

export default {
  props: {},
  components: {},
  setup() {
    const userAuthInfo = useUserAuthInfo();
    return { userAuthInfo };
  },
  data() {
    return {
      prodExpnGrid: null,
      prodExpnGridRows: [],
      params: {
        yyyymm: null,
        site: 'HQ',
      },
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
          if (this.$refs.prodExpnGrid != null) {
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
      return this.$refs.prodExpnGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.prodExpnGrid.getGridDataProvider();
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
    },
    initializeGrid() {
      this.prodExpnGrid = _.cloneDeep(gridField);
    },
    async getDataList() {
      this.gridView.commit();

      let params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.params.site != null ? this.siteMap[this.params.site] : null,
      };

      let param = {
        menuId: 'c0008000',
        queryId: 'C0008004_Sch1',
        queryParams: params,
        target: this.prodExpnGridRows,
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
      const fileName = `원가항목별비용${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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
    async onCellClickedProdExpnGrid(grid, clickData) {
      if (clickData.cellType != 'data') return;

      if (clickData.column == 'model') {
        let queryParams = {
          yyyymm: grid.getValue(clickData.itemIndex, 'yyyymm'),
          site: grid.getValue(clickData.itemIndex, 'site') != null ? this.siteMap[grid.getValue(clickData.itemIndex, 'site')] : null,
          model: grid.getValue(clickData.itemIndex, 'model'),
        };

        const params = {
          dialogTitle: '상세 계정별 금액',
          popUpSize: 'xl', //sm,lg,xl
          height: 500,
          gridJs: 'C0008004Detail.js',
          search: {
            menuId: 'c0008000',
            queryId: 'C0008004_Sch2',
            queryParams: queryParams,
          },
          btnConfirm: false,
        };
        this.$refs.cmDialog1C00008004.openDialog(params);
      }
    },
  },
};
</script>
