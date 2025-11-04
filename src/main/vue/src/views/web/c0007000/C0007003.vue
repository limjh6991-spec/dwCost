/** * 타시스템 > 생산정보 */
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="2">
          <div class="form-floating">
            <div class="form-floating me-1">
              <date-picker label="기준월" mode="month" v-model="params.yyyymm" />
              <label for="floatingSelect" class="select">기준월</label>
            </div>
          </div>
        </b-col>
        <b-col cols="2">
          <div class="form-floating">
            <input autocomplete="off" type="text" class="form-control label-60" id="floating" placeholder="Site" v-model="displaySite" :disabled="true" />
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
        <RealGrid ref="dataGrid" :uid="'dataGrid'" :step="'1'" :rows="dataGridRows" style="height: 100%" />
      </div>
    </div>
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import gridField from '@web/c0007000/js/C0007003.js';

export default {
  props: {},
  components: {},
  setup() {
    const userAuthInfo = useUserAuthInfo();
    return { userAuthInfo };
  },
  data() {
    return {
      yyyymm: null,
      dataGrid: null,
      dataGridRows: [],
      params: {
        site: 'HQ',
        yyyymm: null,
      },
      siteMap: {
        '본사': 'HQ',
        'VINA': 'VN',
        'HQ': 'HQ',
        'VN': 'VN',
      },
    };
  },
  watch: {
    userAuthInfo: {
      handler(newVal) {
        if (newVal && newVal.curProdCtg) {
          this.params.site = newVal.curProdCtg === 'VN' ? 'VINA' : '본사';
          console.log('[C0007003] site 변경:', this.params.site);
          if (this.$refs.dataGrid != null) {
            this.getDataList();
          }
        }
      },
      deep: true,
      immediate: true
    }
  },
  computed: {
    gridView() {
      return this.$refs.dataGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.dataGrid.getGridDataProvider();
    },
    displaySite() {
      return this.params.site; // '본사' 또는 'VINA' 표시
    }
  },
  created() {
    const now = new Date();
    this.params.yyyymm = `${now.getFullYear()}-${("0" + (now.getMonth() + 1)).slice(-2)}`;
    this.initializeGrid();
  },
  mounted() {
    console.log('[mounted] C0007003 컴포넌트 마운트됨');
    this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    console.log('[mounted] site 설정:', this.params.site);
  },
  beforeUnmount() {},
  methods: {
    initializeGrid() {
      this.dataGrid = _.cloneDeep(gridField);
    },
    async getDataList() {
      this.gridView.commit();
      let yyyymm = this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null;
      let params = {
        yyyymm: yyyymm,
        site: this.siteMap[this.params.site], // '본사' → 'HQ', 'VINA' → 'VN' 변환
      };
      console.log('조회 파라미터:', params);
      let param = {
        menuId: 'c0007003',
        queryId: 'selectTab1GridData',
        queryParams: params,
        target: this.dataGridRows,
      };
      try {
        let resp = await this.$axios.api.search(param);
        console.log('조회 성공:', resp);
      } catch (error) {
        if (error.response) {
          console.error('조회 중 오류 발생:', error.response.data);
          this.$toast('error', `서버 오류: ${error.response.data?.message || error.response.status}`);
        } else {
          console.error('조회 중 오류 발생:', error.message);
          this.$toast('error', `서버 연결에 실패했습니다: ${error.message}`);
        }
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
      const fileName = `C0007003_데이터${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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

<style scoped>
.input-group {
  display: flex;
  align-items: center;
  gap: 8px;
}
.input-label {
  margin-right: 4px;
  font-weight: 500;
  color: #333;
}
.form-select {
  height: 32px;
  font-size: 15px;
  border-radius: 6px;
  border: 1px solid #bdbdbd;
  background: #fff;
  padding: 0 8px;
}
.yyyymm-tab-wrap {
  position: relative;
  display: flex;
  align-items: center;
  width: 140px;
}
.yyyymm-input-wrap {
  position: relative;
  width: 100%;
  display: flex;
  align-items: center;
}
.yyyymm-input {
  width: 100%;
  font-size: 16px;
  font-family: inherit;
  font-weight: 400;
  color: #222;
  border: 1px solid #bdbdbd;
  border-radius: 6px;
  background: #fff;
  text-align: center;
  cursor: pointer;
  padding-right: 32px;
  height: 38px;
  line-height: 38px;
  box-sizing: border-box;
}
.dropdown-arrow {
  position: absolute;
  right: 10px;
  top: 50%;
  transform: translateY(-50%);
  display: flex;
  align-items: center;
  height: 24px;
  cursor: pointer;
  z-index: 2;
}
.yyyymm-label {
  position: absolute;
  left: 14px;
  top: 8px;
  font-size: 14px;
  color: #888;
  pointer-events: none;
  background: transparent;
  z-index: 1;
}
.yyyymm-popup-inside {
  position: absolute;
  left: 0;
  top: 44px;
  background: #fff;
  border: 1px solid #bdbdbd;
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.10);
  padding: 16px 18px 10px 18px;
  z-index: 200;
  min-width: 220px;
  min-height: 100px;
  display: flex;
  flex-direction: column;
  align-items: center;
}
.popup-close-x {
  position: absolute;
  top: 8px;
  right: 10px;
  background: none;
  border: none;
  font-size: 14px;
  color: #888;
  cursor: pointer;
  z-index: 10;
}
.popup-header {
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 8px;
  margin-top: 8px;
}
.popup-year {
  font-weight: bold;
  font-size: 17px;
  color: #333;
  margin: 0 12px;
}
.popup-arrow {
  background: none;
  border: none;
  font-size: 17px;
  color: #333;
  cursor: pointer;
  padding: 0 8px;
}
.month-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
  margin-top: 8px;
}
.month-cell {
  aspect-ratio: 1/1;
  width: 44px;
  min-width: 44px;
  max-width: 60px;
  min-height: 44px;
  max-height: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  background: #f5f5f5;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 15px;
  color: #222;
  box-shadow: 0 2px 6px rgba(0,0,0,0.08);
  transition: background 0.2s, box-shadow 0.2s;
}
.month-cell.selected {
  background: #333;
  color: #fff;
  font-weight: bold;
  box-shadow: 0 4px 12px rgba(0,0,0,0.16);
}
.popup-footer {
  text-align: right;
  margin-top: 8px;
  width: 100%;
}
</style>
