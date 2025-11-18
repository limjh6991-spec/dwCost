/** * 결산증빙 자료 > 경영 실행 */
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="2">
          <div class="form-floating">
            <select class="form-select label-60" id="floatingSelect" v-model="params.yyyy">
              <option v-for="yyyy in yearList" :key="yyyy.value" :value="yyyy">
                {{ yyyy.text }}
              </option>
            </select>
            <label for="floatingSelect" class="select">년도</label>
          </div>
        </b-col>
        <b-col cols="2">
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
      <div class="parent-flex-center-div">
        <span style="font-size: 22px; font-weight: bold">SITE 別 경영 실행 {{ siteStr }}</span>
      </div>
      <div class="parent-flex-right-div">
        <span style="font-size: 14px">(단위 : 백만원)</span>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="reportGrid" :uid="'reportGrid'" :step="'1'" :rows="reportGridRows" style="height: 100%" :fitLayoutWidthEnable="false" />
      </div>
    </div>
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0008000/js/C0008014.js';

export default {
  props: {},
  components: {},
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
      reportGrid: null,
      reportGridRows: [],
      params: {
        yyyymm: null,
        yyyy: null,
        site: 'HQ',
      },
      yearList: [],
      siteMap: {
        본사: 'HQ', //DB map
        VINA: 'VN', //DB map
        HQ: 'HQ', //DB map
        VN: 'VN', //DB map
      },
      siteStr: '',
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
          this.params.yyyy = { value: parseInt(newVal.substring(0, 4)), text: newVal.substring(0, 4) };
        }
      },
    },
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          if (this.$refs.reportGrid != null) {
            this.initialize();
            this.searchClick();
          }
        }
      },
    },
  },
  computed: {
    gridView() {
      return this.$refs.reportGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.reportGrid.getGridDataProvider();
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
      this.yearList = [];
      for (let i = current.getFullYear() - 9; i <= current.getFullYear(); i++) {
        this.yearList.push({ value: i, text: i.toString() });
      }
      if (this.srchInfo.yyyymm != null && this.srchInfo.yyyymm.length >= 4) {
        this.params.yyyy = { value: parseInt(this.srchInfo.yyyymm.substring(0, 4)), text: this.srchInfo.yyyymm.substring(0, 4) };
      } else {
        this.params.yyyy = { value: current.getFullYear(), text: current.getFullYear().toString() };
      }
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
      this.siteStr = this.params.site === 'VINA' ? '(VN)' : '(국내)';
    },
    initializeGrid() {
      this.reportGrid = _.cloneDeep(gridField);
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },
    async getDataList() {
      this.gridView.commit();

      let params = {
        yyyy: this.params.yyyy?.text,
        site: this.params.site != null ? this.siteMap[this.params.site] : null,
      };

      this.gridView.columnByName('tot').header.text = this.params.yyyy?.text?.substring(2, 4) + '年 실행';

      let param = {
        menuId: 'c0008000',
        queryId: 'C0008014_Sch1',
        queryParams: params,
        target: this.reportGridRows,
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
      const fileName = `경영실행${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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
    setCellStyleCallbackReportGrid(grid, dataCell) {
      var ret = {};
      if (dataCell.dataColumn.name != '구분') {
        return ret;
      }
      var gubun = dataCell.value;
      if (this.$utils.containsValue(['매출액', '매출원가', '재료비', '노무비', '제조경비', '매출총이익', '판매관리비', '영업이익'], gubun)) {
        ret.style = { fontWeight: 'bold', whiteSpace: 'pre' };
      } else {
        ret.style = { fontWeight: 'normal', whiteSpace: 'pre' };
      }
      return ret;
    },
  },
};
</script>
<style lang="css" scoped>
.parent-flex-center-div {
  display: flex;
  justify-content: center; /* 수평 가운데 정렬 */
  /* align-items: center;     수직 가운데 정렬 */
  height: 40px;
  background: #ffffff;
}
.parent-flex-right-div {
  display: flex;
  justify-content: right; /* 수평 가운데 정렬 */
  /* align-items: center;     수직 가운데 정렬 */
  height: 22px;
  background: #ffffff;
}
::v-deep .grid-border-none {
  height: calc(100% - 102px);
}
.space {
  white-space: pre-wrap;
}
</style>
