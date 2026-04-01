/** * 타시스템 > 생산정보 > MES 수불 */
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
          <b-button v-show="!isClosedMonth" class="second" @click="genData">데이터 생성</b-button>       
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="mesSubGrid" :uid="'mesSubGrid'" :step="'1'" :rows="mesSubGridRows" style="height: 100%" />
      </div>
    </div>
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0007000/js/C0007003TAB3.js';

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
      mesSubGrid: null,
      mesSubGridRows: [],
      params: {
        site: 'HQ',
        yyyymm: null,
      },
      siteMap: {
        본사: 'HQ',
        VINA: 'VN',
        HQ: 'HQ',
        VN: 'VN',
      },
      isClosedMonth: false,
    };
  },
  watch: {
    'params.yyyymm': async function (newVal) {
      if (newVal) {
        this.onDateChange();
        await this.checkClosingMonth();
      } else {
        this.isClosedMonth = false;
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
          if (this.$refs.mesSubGrid != null) {
            this.searchClick();
          }
        }
      },
    },
  },
  computed: {
    gridView() {
      return this.$refs.mesSubGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.mesSubGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    },
  },
  created() {
    this.initializeGrid();
  },
  mounted() {
    this.params.yyyymm = this.srchInfo.yyyymm;
    this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    this.$nextTick(async () => {
      await this.checkClosingMonth();
      this.searchClick();
    });
  },
  beforeUnmount() {},
  methods: {
    initializeGrid() {
      this.mesSubGrid = _.cloneDeep(gridField);
    },
    async checkClosingMonth() {
      const yyyymm = this.params.yyyymm
        ? this.params.yyyymm.replaceAll('-', '')
        : null;

      if (!yyyymm) {
        this.isClosedMonth = false;
        return;
      }

      try {
        const res = await this.$axios.get('/api/common/closing-month/check', {
          params: { yyyymm },
        });

        this.isClosedMonth =
          res?.data?.isClosed === true || res?.data?.isClosed === 'Y';

      } catch (e) {
        console.error('마감월 조회 실패', e);
        this.isClosedMonth = false;
      }
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },
    async getDataList() {
      this.gridView.commit();
      let params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.siteMap[this.params.site],
      };

      let param = {
        menuId: 'c0007003',
        queryId: 'C0007003_Sch3',
        queryParams: params,
        target: this.mesSubGridRows,
      };
      let resp = await this.$axios.api.search(param);
    },
    searchClick() {
      if (!this.params.yyyymm) {
        this.$toast && this.$toast('error', '년월 선택해주세요.');
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
      const fileName = `MES수불${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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
