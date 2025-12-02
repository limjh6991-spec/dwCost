/** * 결산증빙 자료 > 제품별 투입 재료비(DOI_PROD_MAT) */
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
        <RealGrid ref="prodMatGrid" :uid="'prodMatGrid'" :step="'1'" :rows="prodMatGridRows" style="height: 100%" />
      </div>
    </div>
    <CmDialog1 ref="cmDialog1C00008007" />
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0008000/js/C0008007.js';

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
      prodMatGrid: null,
      prodMatGridRows: [],
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
          console.log('[C0003007] yyyymm 변경:', this.params.yyyymm);
        }
      }
     },
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          if (this.$refs.prodMatGrid != null) {
            this.initialize();
            this.searchClick();
          }
        }
      },
    },
  },
  computed: {
    gridView() {
      return this.$refs.prodMatGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.prodMatGrid.getGridDataProvider();
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
      //var current = new Date();
      this.params.yyyymm = this.srchInfo.yyyymm; //`${current.getFullYear()}-${(current.getMonth() + 1).toString().padStart(2, '0')}`;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },
    initializeGrid() {
      this.prodMatGrid = _.cloneDeep(gridField);
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

      let param = {
        menuId: 'c0008000',
        queryId: 'C0008007_Sch1',
        queryParams: params,
        target: this.prodMatGridRows,
      };
      // let resp = await this.$axios.api.search(param);
      try {
        let resp = await this.$axios.api.search(param);
        
        // 성공 응답 처리
        if (resp.data && resp.data.success) {
          this.prodExpnGridRows = resp.data.data; // 데이터 바인딩
          this.$message.success('데이터를 성공적으로 조회했습니다.');
        } else {
          this.$message.error(resp.data.message || '데이터 조회에 실패했습니다.');
        }
      }catch (error) {
        // 에러 처리
        console.error('API 호출 실패:', error);
        // this.$message.error('서버 오류가 발생했습니다.');
      }
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
      const fileName = `재료별투입재료비${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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
    async onCellClickedProdMatGrid(grid, clickData) {
      if (clickData.cellType != 'data') return;

      if (clickData.column == '도우모델') {
        let queryParams = {
          // yyyymm: grid.getValue(clickData.itemIndex, 'yyyymm'),
          // site: grid.getValue(clickData.itemIndex, 'site') != null ? this.siteMap[grid.getValue(clickData.itemIndex, 'site')] : null,
          yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
          site: this.params.site != null ? this.siteMap[this.params.site] : null,
          gubun: grid.getValue(clickData.itemIndex, '구분'),
          model: grid.getValue(clickData.itemIndex, '도우모델'),
        };

        const params = {
          dialogTitle: '모델 재료비 금액',
          popUpSize: 'xl', //sm,lg,xl
          height: 500,
          gridJs: 'C0008007Detail.js', //C0008006Detail과 동일
          search: {
            menuId: 'c0008000',
            queryId: 'C0008007_Sch2',
            queryParams: queryParams,
          },
          btnConfirm: false,
        };
        this.$refs.cmDialog1C00008007.openDialog(params);
      }
    },
  },
};
</script>
