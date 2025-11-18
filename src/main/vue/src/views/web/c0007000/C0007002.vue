<!-- 타시스템 > 자재투입정보 -->
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
        <RealGrid ref="materialGrid" :uid="'materialGrid'" :step="'1'" :rows="materialGridRows" style="height: 100%" :fixLayoutWidth="false" />
      </div>
    </div>
  </div>
</template>

<script>
import { RowState } from 'realgrid';
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0007000/js/C0007002.js';

export default {
  components: {},
  props: {
    yearList: {
      type: Array,
      default: () => [],
    },
  },
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
      materialGrid: null,
      materialGridRows: [],
      params: {
        yyyymm: null,
        site: 'HQ',
      },
      siteMap: {
        '본사': 'HQ',
        'VINA': 'VN',
        'HQ': 'HQ',
        'VN': 'VN',
      },
      isProcessing: false,
      duplicateKey: ['yyyymm', 'selCode', 'site', 'matCode'],
      isValidteCellMaterialGrid: false,
    };
  },
  computed: {
    gridView() {
      return this.$refs.materialGrid && this.$refs.materialGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.materialGrid && this.$refs.materialGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg; // '본사' 또는 'VINA' 표시
    }
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
      if (this.$refs.materialGrid != null) {
        this.searchClick();
          }
        }
      },
    },
  },
  created() {
    this.initializeGrid();
  },
  mounted() {
    this.params.yyyymm = this.srchInfo.yyyymm;
    this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    this.$nextTick(() => {
      this.searchClick();
    });
  },
  methods: {
    initializeGrid() {
      this.materialGrid = _.cloneDeep(gridField);
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },
    async getDataList() {
      if (!this.gridView) return;

      this.gridView.commit();

      let params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.siteMap[this.params.site],
      };

      let param = {
        menuId: 'c0007002',
        queryId: 'selectTab1GridData',
        queryParams: params,
        target: this.materialGridRows,
      };
        let resp = await this.$axios.api.search(param);
    },
    searchClick() {
      if (!this.params.yyyymm) {
        this.$toast && this.$toast('error', '년월 선택해 주세요.');
        return;
      }
      this.getDataList();
    },

    async excelBtnClick() {
      const grid = this.gridView;
      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `자재투입정보${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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
    closePopup() {
      this.searchClick();
    },
  },
};
</script>