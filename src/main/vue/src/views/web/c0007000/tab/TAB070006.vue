<!-- 타시스템 > 입고수불 자체 체크 -->
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
            <input autocomplete="off" type="text" class="form-control label-60" id="floating" placeholder="Site" v-model="params.site" />
            <label for="floating">SITE</label>
          </div>
        </b-col>
        <b-col cols="2">
          <div class="form-floating">
            <input autocomplete="off" type="text" class="form-control label-60" id="floating" placeholder="MODEL" v-model="params.model" />
            <label for="floating">MODEL</label>
          </div>
        </b-col>
      </b-row>
      <div class="btn_area">
        <b-button @click="searchClick"><span class="ico_search"></span>조회</b-button>
      </div>
    </div>

    <!-- 통계 요약 카드 -->
    <div class="statistics-section" style="display: flex; gap: 16px; margin-bottom: 16px;">
      <!-- 탭1: 입고수불 밸런스 체크 통계 -->
      <div style="flex: 1; border: 2px solid #0d6efd; border-radius: 8px; padding: 16px; background: #f8f9fa;">
        <h6 style="margin: 0 0 12px 0; font-size: 14px; font-weight: 600; color: #0d6efd; border-bottom: 2px solid #0d6efd; padding-bottom: 8px;">
          입고수불 밸런스 체크
        </h6>
        <div style="display: flex; gap: 8px;">
          <div class="stat-card" style="flex: 1; padding: 12px; background: white; border-radius: 6px; text-align: center; border: 1px solid #dee2e6;">
            <div style="font-size: 11px; color: #6c757d; margin-bottom: 4px;">총 체크 건수</div>
            <div style="font-size: 24px; font-weight: bold; color: #212529;">{{ summary.totalCount }}</div>
          </div>
          <div class="stat-card" style="flex: 1; padding: 12px; background: #d1e7dd; border-radius: 6px; text-align: center; border: 1px solid #badbcc;">
            <div style="font-size: 11px; color: #0f5132; margin-bottom: 4px;">정상</div>
            <div style="font-size: 24px; font-weight: bold; color: #0f5132;">
              {{ summary.normalCount }}
              <span style="font-size: 12px; margin-left: 4px;">({{ summary.normalPercent }}%)</span>
            </div>
          </div>
          <div class="stat-card" style="flex: 1; padding: 12px; background: #f8d7da; border-radius: 6px; text-align: center; border: 1px solid #f5c2c7;">
            <div style="font-size: 11px; color: #842029; margin-bottom: 4px;">오류</div>
            <div style="font-size: 24px; font-weight: bold; color: #842029;">
              {{ summary.errorCount }}
              <span style="font-size: 12px; margin-left: 4px;">({{ summary.errorPercent }}%)</span>
            </div>
          </div>
          <div class="stat-card" style="flex: 1; padding: 12px; background: #fff3cd; border-radius: 6px; text-align: center; border: 1px solid #ffecb5;">
            <div style="font-size: 11px; color: #664d03; margin-bottom: 4px;">경고</div>
            <div style="font-size: 24px; font-weight: bold; color: #664d03;">
              {{ summary.warningCount }}
              <span style="font-size: 12px; margin-left: 4px;">({{ summary.warningPercent }}%)</span>
            </div>
          </div>
        </div>
      </div>

      <!-- 탭2: 기말/기초 체크 통계 -->
      <div style="flex: 1; border: 2px solid #6c757d; border-radius: 8px; padding: 16px; background: #f8f9fa;">
        <h6 style="margin: 0 0 12px 0; font-size: 14px; font-weight: 600; color: #6c757d; border-bottom: 2px solid #6c757d; padding-bottom: 8px;">
          기말/기초 체크
        </h6>
        <div style="display: flex; gap: 8px;">
          <div class="stat-card" style="flex: 1; padding: 12px; background: white; border-radius: 6px; text-align: center; border: 1px solid #dee2e6;">
            <div style="font-size: 11px; color: #6c757d; margin-bottom: 4px;">총 체크 건수</div>
            <div style="font-size: 24px; font-weight: bold; color: #212529;">{{ summary2.totalCount }}</div>
          </div>
          <div class="stat-card" style="flex: 1; padding: 12px; background: #d1e7dd; border-radius: 6px; text-align: center; border: 1px solid #badbcc;">
            <div style="font-size: 11px; color: #0f5132; margin-bottom: 4px;">정상</div>
            <div style="font-size: 24px; font-weight: bold; color: #0f5132;">
              {{ summary2.normalCount }}
              <span style="font-size: 12px; margin-left: 4px;">({{ summary2.normalPercent }}%)</span>
            </div>
          </div>
          <div class="stat-card" style="flex: 1; padding: 12px; background: #f8d7da; border-radius: 6px; text-align: center; border: 1px solid #f5c2c7;">
            <div style="font-size: 11px; color: #842029; margin-bottom: 4px;">불일치</div>
            <div style="font-size: 24px; font-weight: bold; color: #842029;">
              {{ summary2.mismatchCount }}
              <span style="font-size: 12px; margin-left: 4px;">({{ summary2.mismatchPercent }}%)</span>
            </div>
          </div>
          <div class="stat-card" style="flex: 1; padding: 12px; background: #fff3cd; border-radius: 6px; text-align: center; border: 1px solid #ffecb5;">
            <div style="font-size: 11px; color: #664d03; margin-bottom: 4px;">전월 데이터 없음</div>
            <div style="font-size: 24px; font-weight: bold; color: #664d03;">
              {{ summary2.noDataCount }}
              <span style="font-size: 12px; margin-left: 4px;">({{ summary2.noDataPercent }}%)</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 탭 메뉴 및 내용 -->
    <div class="grid_box">
      <b-tabs v-model="activeTab" class="custom-tabs">
        <b-tab title="입고수불 밸런스 체크">
          <div class="left_box">
            <div class="btn_wrap ms-auto">
              <b-button class="second" @click="excelBtnClick">엑셀 다운로드</b-button>
            </div>
          </div>
          <div class="grid-border-none" style="height: 500px;">
            <RealGrid ref="dataGrid" :uid="'dataGrid'" :step="'1'" :rows="dataGridRows" style="height: 100%" :fitLayoutWidthEnable="false"/>
          </div>
        </b-tab>
        <b-tab title="기말/기초 체크">
          <div class="left_box">
            <div class="btn_wrap ms-auto">
              <b-button class="second" @click="excelBtnClick">엑셀 다운로드</b-button>
            </div>
          </div>
          <div class="grid-border-none" style="height: 500px;">
            <RealGrid ref="dataGrid2" :uid="'dataGrid2'" :step="'2'" :rows="dataGrid2Rows" style="height: 100%" />
          </div>
        </b-tab>
      </b-tabs>
    </div>
  </div>
</template>

<script>
import gridField from '@web/c0007000/js/C0007007.js';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField2 from '@web/c0007000/js/C0007007_Tab2.js';

export default {
  name: 'C0007006',
  components: {},
  setup() {
    const srchInfo = useC0001001();
    return {
      srchInfo,
    };
  },
  data() {
    return {
      activeTab: 0,
      dataGrid: null,
      dataGrid2: null,
      dataGridRows: [],
      dataGrid2Rows: [],
      params: {
        site: '',
        yyyymm: null,
        model: null,
      },
      summary: {
        totalCount: 0,
        normalCount: 0,
        errorCount: 0,
        warningCount: 0,
        normalPercent: '0.0',
        errorPercent: '0.0',
        warningPercent: '0.0',
      },
      summary2: {
        totalCount: 0,
        normalCount: 0,
        mismatchCount: 0,
        noDataCount: 0,
        normalPercent: '0.0',
        mismatchPercent: '0.0',
        noDataPercent: '0.0',
      },
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
        }
      },
    },
  },
  computed: {
    gridView() {
      return this.$refs.dataGrid?.getGridView();
    },
    gridDataProvider() {
      return this.$refs.dataGrid?.getGridDataProvider();
    },
    gridView2() {
      return this.$refs.dataGrid2?.getGridView();
    },
    gridDataProvider2() {
      return this.$refs.dataGrid2?.getGridDataProvider();
    },
  },
  created() {
    const now = new Date();
    this.params.yyyymm = `${now.getFullYear()}-${("0" + (now.getMonth() + 1)).slice(-2)}`;
    this.initializeGrid();
  },
  mounted() {
    this.params.yyyymm = this.srchInfo.yyyymm;
  },
  beforeUnmount() {},
  methods: {
    initializeGrid() {
      this.dataGrid = _.cloneDeep(gridField);
      this.dataGrid2 = _.cloneDeep(gridField2);
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },
    async getDataList() {
      this.gridView.commit();
      let yyyymm = this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null;
      let params = {
        yyyymm: yyyymm,
        site: this.params.site || null,
        model: this.params.model || null,
      };

      // 요약 정보 조회 - Tab1
      let summaryParam = {
        menuId: 'c0007006',
        queryId: 'selectIncomeSummary',
        queryParams: params,
      };

      let summaryResp = await this.$axios.api.search(summaryParam);
      if (summaryResp && summaryResp.length > 0) {
        const data = summaryResp[0];
        this.summary.totalCount = data.totalCount || 0;
        this.summary.normalCount = data.normalCount || 0;
        this.summary.errorCount = data.errorCount || 0;
        this.summary.warningCount = data.warningCount || 0;
        
        if (this.summary.totalCount > 0) {
          this.summary.normalPercent = ((this.summary.normalCount / this.summary.totalCount) * 100).toFixed(1);
          this.summary.errorPercent = ((this.summary.errorCount / this.summary.totalCount) * 100).toFixed(1);
          this.summary.warningPercent = ((this.summary.warningCount / this.summary.totalCount) * 100).toFixed(1);
        }
      }

      // 요약 정보 조회 - Tab2
      let summary2Param = {
        menuId: 'c0007006',
        queryId: 'selectIncomeSummary2',
        queryParams: params,
      };

      let summary2Resp = await this.$axios.api.search(summary2Param);
      if (summary2Resp && summary2Resp.length > 0) {
        const data = summary2Resp[0];
        this.summary2.totalCount = data.totalCount || 0;
        this.summary2.normalCount = data.normalCount || 0;
        this.summary2.mismatchCount = data.mismatchCount || 0;
        this.summary2.noDataCount = data.noDataCount || 0;
        
        if (this.summary2.totalCount > 0) {
          this.summary2.normalPercent = ((this.summary2.normalCount / this.summary2.totalCount) * 100).toFixed(1);
          this.summary2.mismatchPercent = ((this.summary2.mismatchCount / this.summary2.totalCount) * 100).toFixed(1);
          this.summary2.noDataPercent = ((this.summary2.noDataCount / this.summary2.totalCount) * 100).toFixed(1);
        }
      }

      // 탭1: 밸런스 체크 데이터 조회
      let param = {
        menuId: 'c0007006',
        queryId: 'selectIncomeBalanceCheck',
        queryParams: params,
        target: this.dataGridRows,
      };
      await this.$axios.api.search(param);

      // 탭2: 기말/기초 체크 데이터 조회
      let param2 = {
        menuId: 'c0007006',
        queryId: 'selectIncomeContinuityCheck',
        queryParams: params,
        target: this.dataGrid2Rows,
      };
      await this.$axios.api.search(param2);
    },

    searchClick() {
      this.getDataList();
    },

    async excelBtnClick() {
      const grid = this.activeTab === 0 ? this.gridView : this.gridView2;
      const tabName = this.activeTab === 0 ? '밸런스체크' : '기말기초체크';
      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `입고수불_${tabName}_${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

      const options = {
        type: 'excel',
        target: 'local',
        fileName: fileName,
        indicator: 'hidden',
        header: 'default',
        footer: 'default',
        showProgress: true,
        progressMessage: '엑셀 Export중입니다.',
        done: function () {
          console.log('엑셀 다운로드 완료');
        },
      };

      grid.exportGrid(options);
    },
  },
};
</script>

<style scoped>
.custom-tabs {
  border-bottom: 1px solid #dee2e6;
  margin-bottom: 0;
}
</style>
