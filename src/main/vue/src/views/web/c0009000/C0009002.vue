/** * 제품 수불부 */
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
        <b-col cols="2" v-if="hasSysAdmin">
          <div class="form-floating">
            <select
              class="form-select label-80"
              id="selCodeSelect"
              v-model="params.selCode"
            >
              <option
                v-for="o in selCodeList"
                :key="o.value"
                :value="o.value"
              >
                {{ o.text }}
              </option>
            </select>
            <label for="selCodeSelect" class="select">SEL_CODE</label>
          </div>
        </b-col>   
      </b-row>
      <div class="btn_area">
        <b-button @click="searchClick"><span class="ico_search"></span>조회</b-button>
      </div>
    </div>
    <div class="grid_box search_onerow">
      <div class="left_box">
        <!-- VN 화면 전용 탭 (HQ는 단일 그리드 유지) -->
        <ul v-if="isVN" class="nav nav-tabs prod_subul_tab">
          <li class="nav-item">
            <a class="nav-link" :class="{ active: activeTab === 'default' }" @click="switchTab('default')">제품 수불부</a>
          </li>
          <li class="nav-item">
            <a class="nav-link" :class="{ active: activeTab === 'vn' }" @click="switchTab('vn')">제품 수불부 (VN)</a>
          </li>
        </ul>
        <div class="btn_wrap ms-auto">
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid v-show="activeTab === 'default'" ref="prodSubulGrid" :uid="'prodSubulGrid'" :step="'1'" :grid="prodSubulGrid" :layout="prodSubulGrid.columnLayout" :rows="prodSubulGridRows" style="height: 100%" />
        <RealGrid v-show="activeTab === 'vn'" ref="prodSubulVnGrid" :uid="'prodSubulVnGrid'" :step="'1'" :grid="prodSubulVnGrid" :layout="prodSubulVnGrid.columnLayout" :rows="prodSubulVnGridRows" style="height: 100%" />
      </div>
    </div>
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0009000/js/C0009002.js';
import vnGridField from '@web/c0009000/js/C0009002_VN.js';

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
      prodSubulVnGrid: null,
      prodSubulVnGridRows: [],
      activeTab: 'default',
      selCodeList: [],
      params: {
        yyyymm: null,
        site: 'HQ',
        selCode: '',
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
        'params.yyyymm': function(newVal) {
      if (newVal) {
        this.onDateChange();
      }
    },
    'srchInfo.yyyymm': {
      handler(newVal) {
        if (newVal) {
          this.params.yyyymm = newVal;
          console.log('[C0009002] yyyymm 변경:', this.params.yyyymm);
        }
      }
     },
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          this.activeTab = 'default';
          if (this.$refs.prodSubulGrid != null) {
            this.initialize();
            this.searchClick();
          }
        }
      },
    },
  },
  computed: {
    hasSysAdmin() {
      const roleList = this.userAuthInfo?.roleList || [];
      return roleList.includes('SYSADMIN');
    },
     gridView() {
      return this.$refs.prodSubulGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.prodSubulGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    },
    isVN() {
      return this.siteMap[this.params.site] === 'VN';
    },
  },
  created() {
    this.initialize();
    this.initializeGrid();
  },
  mounted() {
    const gv = this.gridView;

    if (this.prodSubulGrid.columnLayout) {
      gv.setColumnLayout(this.prodSubulGrid.columnLayout);
    }

    gv.setFooter({ visible: true });              // visible만
    gv.setFooters([{ height: 30 }, { height: 30 }]); // ✅ 2줄 선언 (핵심)

    gv.setCellStyleCallback(this.setCellStyleCallbackProd);
    gv.setRowStyleCallback(this.setRowStyleCallbackProd);

    // VN 신규 포맷 그리드: 다단계 헤더 레이아웃 적용
    const vnGv = this.$refs.prodSubulVnGrid?.getGridView();
    if (vnGv && this.prodSubulVnGrid?.columnLayout) {
      vnGv.setColumnLayout(this.prodSubulVnGrid.columnLayout);
      vnGv.setFooter({ visible: true });
    }
  },
  beforeUnmount() {},
  methods: {    initialize() {
      this.params.yyyymm = this.srchInfo.yyyymm;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
      this.loadSelCodeList();
    },
    initializeGrid() {
      this.prodSubulGrid = _.cloneDeep(gridField);
      this.prodSubulVnGrid = _.cloneDeep(vnGridField);
    },
    switchTab(tab) {
      if (this.activeTab === tab) return;
      this.activeTab = tab;
      this.searchClick();
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },
    async getDataList() {
      const isVnTab = this.isVN && this.activeTab === 'vn';
      const activeGv = isVnTab ? this.$refs.prodSubulVnGrid?.getGridView() : this.gridView;
      activeGv?.commit();

      if (!this.hasSysAdmin) {
        this.params.selCode = 'ACTUAL';
      }

      let params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.params.site != null ? this.siteMap[this.params.site] : null,
        selCode: this.params.selCode === '' ? 'ACTUAL' : this.params.selCode,
      };

      // 신규 VN 포맷 탭은 상세 프로시저(VN_StockLedger_Detail), 그 외는 기존 포맷
      if (isVnTab) {
        const rows = [];
        await this.$axios.api.search({
          menuId: 'c0009000',
          queryId: 'C0009002_Detail',
          queryParams: params,
          target: rows,
        });
        this.prodSubulVnGridRows = rows;
      } else {
        const rows = [];
        await this.$axios.api.search({
          menuId: 'c0009000',
          queryId: 'C0009002_Sch1',
          queryParams: params,
          target: rows,
        });
        this.prodSubulGridRows = rows;
      }
    },

    async loadSelCodeList() {
      const list = [];

      await this.$axios.api.search({
        menuId: 'c0009000',
        queryId: 'C0009010_SelectSelCode',
        queryParams: {},
        target: list,
      });

      this.selCodeList = list;

      const actual = this.selCodeList.find(x => x.value === 'ACTUAL');

      if (actual) {
        this.params.selCode = 'ACTUAL';
      } else {
        this.params.selCode = this.selCodeList[0]?.value ?? '';
      }
    },

    searchClick() {
      this.getDataList();
    },
    async excelBtnClick() {
      const isVnTab = this.isVN && this.activeTab === 'vn';
      const grid = isVnTab ? this.$refs.prodSubulVnGrid?.getGridView() : this.gridView;
      if (!grid) return;

      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();

      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const baseName = isVnTab ? '제품 수불부(VN)' : '제품 수불부';
      const fileName = `${baseName}_${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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
    
    setCellStyleCallbackProd(grid, dataCell) {
      const ret = {};
      
      const row = dataCell.index.dataRow;
      if (row < 0) {
        return ret;
      }
      const colName = dataCell.dataColumn.name;
      const amountColumns = ['BOH', 'INPUT', 'IN_ETC', 'OUTPUT', 'OUT_ETC', 'EOH'];
      if (!amountColumns.includes(colName)) return ret;

      const gubun = grid.getValue(row, '구분');
      const seq   = grid.getValue(row, '순서');

      if (typeof gubun === 'string' && gubun.includes('합계')) {
        return ret;
      }

      // 🟡 일반 금액 행 (순서 = 1)만 노랑 배경
      if (Number(seq) === 1) {
        ret.style = {
          background: '#fff9e6',
        };
        // VINA·USD: 금액 행(순서=1)만 소수점 2자리 (수량 행/본사는 정수)
        const ctg = useUserAuthInfo().curProdCtg;
        const cur = useC0001001().currency;
        if (ctg === 'VN' && (cur === 'USD' || cur == null)) {
          ret.numberFormat = '#,##0.00';
        }
      }

      return ret;
    },
    setRowStyleCallbackProd(grid, item, fixed) {
      const ret = {};
      const row = item.dataRow;
      if (row < 0) return ret;

      const gubun = grid.getValue(row, '구분');

      if (typeof gubun === 'string' && gubun.includes('합계')) {
        ret.style = {
          background: '#BFBFBF',
          fontWeight: 'bold',
        };
      }

      return ret;
    },
  },
};
</script>

<style scoped>
/* VN 전용 탭 바 — left_box 안에 컴팩트하게 배치 */
.prod_subul_tab {
  border-bottom: 0;
  margin-bottom: 0;
  flex-wrap: nowrap;
  align-items: center;
}
.prod_subul_tab .nav-link {
  padding: 4px 16px;
  font-size: 13px;
  color: #555;
  border: 1px solid transparent;
  border-radius: 4px 4px 0 0;
  cursor: pointer;
  line-height: 1.4;
}
.prod_subul_tab .nav-link.active {
  color: #232f4e;
  font-weight: 600;
  background: #fff;
  border-color: #bebebe #bebebe #fff;
}
</style>
