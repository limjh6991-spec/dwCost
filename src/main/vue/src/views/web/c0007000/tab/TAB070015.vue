<!-- 수불 산출 검증 - 도우모델별 뷰값 vs 역산값 비교 -->
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
            <input autocomplete="off" type="text" class="form-control label-60" placeholder="Site" v-model="displaySite" :disabled="true" />
            <label>사업장</label>
          </div>
        </b-col>
      </b-row>
      <div class="btn_area">
        <b-button @click="verifyClick" :disabled="isLoading">
          <span class="ico_search"></span>검증 실행
        </b-button>
      </div>
    </div>

    <!-- 검산 카드 -->
    <div v-if="totals.hasData" style="display: flex; gap: 12px; margin-bottom: 12px;">
      <div v-for="g in ['양산', '개발']" :key="g"
           style="flex: 1; border-radius: 8px; padding: 12px; background: #f8f9fa;"
           :style="{ border: '2px solid ' + (g === '양산' ? '#0d6efd' : '#198754') }">
        <h6 style="margin: 0 0 8px 0; font-size: 13px; font-weight: 600; padding-bottom: 6px;"
            :style="{ color: g === '양산' ? '#0d6efd' : '#198754', borderBottom: '2px solid ' + (g === '양산' ? '#0d6efd' : '#198754') }">
          {{ g }} 합계
        </h6>
        <div style="display: flex; gap: 4px; flex-wrap: wrap;">
          <div v-for="item in [
            { label: 'BOH', val: totals[g]?.vBoh },
            { label: '+ IN', val: totals[g]?.vIn },
            { label: '- NG', val: totals[g]?.vNg },
            { label: '- OUT', val: totals[g]?.vOut },
            { label: '- LOSS', val: totals[g]?.vLoss },
            { label: '= EOH', val: totals[g]?.vEoh },
          ]" :key="item.label"
             style="flex: 1; min-width: 70px; padding: 6px; background: white; border-radius: 6px; text-align: center; border: 1px solid #dee2e6;">
            <div style="font-size: 10px; color: #6c757d;">{{ item.label }}</div>
            <div style="font-size: 13px; font-weight: bold;">{{ formatNum(item.val) }}</div>
          </div>
          <div style="flex: 1; min-width: 80px; padding: 6px; border-radius: 6px; text-align: center;"
               :style="{ background: totals[g]?.diff === 0 ? '#d1e7dd' : '#f8d7da', border: '1px solid ' + (totals[g]?.diff === 0 ? '#198754' : '#dc3545') }">
            <div style="font-size: 10px;">검산차이</div>
            <div style="font-size: 13px; font-weight: bold;"
                 :style="{ color: totals[g]?.diff === 0 ? '#198754' : '#dc3545' }">
              {{ totals[g]?.diff === 0 ? '✅ 0' : totals[g]?.diff }}
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 도우모델별 비교 그리드 -->
    <div class="grid_box">
      <div class="left_box">
        <span style="font-size: 12px; color: #6c757d;">도우모델별 수불 뷰값 vs 기초테이블 역산값</span>
        <div class="btn_wrap ms-auto">
          <b-button class="second" size="sm" @click="toggleFilter">
            {{ showOnlyDiff ? '전체 보기' : '불일치만 보기' }}
          </b-button>
        </div>
      </div>
      <div class="grid-border-none" style="height: 350px;">
        <RealGrid ref="gridSubul" :uid="'gridSubul'" :step="'1'" :rows="filteredRows" style="height: 100%" />
      </div>
    </div>

    <!-- 드릴다운 상세 -->
    <div class="grid_box" style="margin-top: 12px;">
      <div class="left_box">
        <span style="font-size: 12px; font-weight: 600;">
          {{ detailTitle }}
        </span>
        <div class="btn_wrap ms-auto">
          <b-button class="second" size="sm" @click="loadDetailIN" :disabled="!selectedModel">IN 상세</b-button>
          <b-button class="second" size="sm" @click="loadDetailOUT" :disabled="!selectedModel">OUT 상세</b-button>
        </div>
      </div>
      <div class="grid-border-none" style="height: 250px;">
        <RealGrid ref="gridDetail" :uid="'gridDetail'" :step="'2'" :rows="detailRows" style="height: 100%" />
      </div>
    </div>
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridFieldSubul from '@web/c0007000/js/C0007011_Subul.js';
import gridFieldDetail from '@web/c0007000/js/C0007011_Detail.js';

export default {
  name: 'TAB070015',
  props: {
    tabId: { type: String, default: '' },
  },
  setup() {
    const srchInfo = useC0001001();
    const userAuthInfo = useUserAuthInfo();
    return { srchInfo, userAuthInfo };
  },
  data() {
    return {
      isLoading: false,
      gridSubul: null,
      gridDetail: null,
      allRows: [],
      filteredRows: [],
      detailRows: [],
      showOnlyDiff: false,
      selectedModel: null,
      detailTitle: '모델을 선택하면 상세 데이터가 표시됩니다.',
      params: {
        site: 'HQ',
        yyyymm: null,
      },
      siteMap: {
        '본사': 'HQ',
        'VINA': 'VN',
      },
      totals: { hasData: false },
    };
  },
  computed: {
    displaySite() {
      return this.params.site || '본사';
    },
  },
  watch: {
    userAuthInfo: {
      handler(newVal) {
        if (newVal && newVal.curProdCtg) {
          this.params.site = newVal.curProdCtg === 'VN' ? 'VINA' : '본사';
        }
      },
    },
    'params.yyyymm': function (newVal) {
      if (newVal) {
        this.srchInfo.setSearchInfo({ yyyymm: newVal });
      }
    },
    'srchInfo.yyyymm': {
      handler(newVal) {
        if (newVal && newVal !== this.params.yyyymm) {
          this.params.yyyymm = newVal;
        }
      },
      immediate: true,
    },
  },
  created() {
    this.initializeGrid();
  },
  methods: {
    initializeGrid() {
      this.gridSubul = _.cloneDeep(gridFieldSubul);
      this.gridDetail = _.cloneDeep(gridFieldDetail);
    },

    formatNum(v) {
      if (v == null) return '-';
      return Number(v).toLocaleString();
    },

    toggleFilter() {
      this.showOnlyDiff = !this.showOnlyDiff;
      this.applyFilter();
    },

    applyFilter() {
      if (this.showOnlyDiff) {
        this.filteredRows = this.allRows.filter(r => r.status !== '일치');
      } else {
        this.filteredRows = [...this.allRows];
      }
    },

    calcTotals() {
      this.totals = { hasData: this.allRows.length > 0 };
      for (const g of ['양산', '개발']) {
        const rows = this.allRows.filter(r => r['구분'] === g);
        if (rows.length === 0) continue;
        const sum = (key) => rows.reduce((s, r) => s + (Number(r[key]) || 0), 0);
        const vBoh = sum('vBoh'), vIn = sum('vIn'), vNg = sum('vNg');
        const vOut = sum('vOut'), vEoh = sum('vEoh'), vLoss = sum('vLoss');
        const calc = vBoh + vIn - vNg - vOut - vLoss;
        this.totals[g] = {
          vBoh, vIn, vNg, vOut, vEoh, vLoss,
          diff: Math.round(vEoh - calc),
        };
      }
    },

    /** 검증 실행 */
    async verifyClick() {
      this.isLoading = true;
      try {
        const yyyymm = this.params.yyyymm?.replaceAll('-', '') || null;
        if (!yyyymm) {
          this.$toast('info', '기준월을 선택하세요.');
          return;
        }
        const site = this.siteMap[this.params.site] || 'HQ';

        const resp = await this.$axios.api.search({
          menuId: 'c0007011', queryId: 'selectSubulByModel',
          queryParams: { yyyymm, site },
        });
        this.allRows = resp || [];
        this.applyFilter();
        this.calcTotals();

        // 상단 그리드 모델 클릭 이벤트
        this.$nextTick(() => {
          const gv = this.$refs.gridSubul?.getGridView();
          if (gv) {
            gv.onCellClicked = (grid, clickData) => {
              if (clickData.itemIndex >= 0) {
                const dp = this.$refs.gridSubul.getGridDataProvider();
                this.selectedModel = dp.getValue(clickData.itemIndex, '도우모델');
                this.detailTitle = `[${this.selectedModel}] 선택됨 - IN/OUT 버튼으로 상세 조회`;
              }
            };
          }
        });

        this.$toast('success', `${this.allRows.length}건 조회 완료`);
      } catch (e) {
        console.error(e);
        this.$toast('error', '검증 조회 중 오류가 발생했습니다.');
      } finally {
        this.isLoading = false;
      }
    },

    /** IN 상세 드릴다운 */
    async loadDetailIN() {
      if (!this.selectedModel) return;
      const yyyymm = this.params.yyyymm?.replaceAll('-', '') || null;
      const resp = await this.$axios.api.search({
        menuId: 'c0007011', queryId: 'selectDetailIN',
        queryParams: { yyyymm, model: this.selectedModel },
      });
      this.detailRows = resp || [];
      this.detailTitle = `[${this.selectedModel}] IN 상세 (d21 투입) — ${this.detailRows.length}건`;
    },

    /** OUT 상세 드릴다운 */
    async loadDetailOUT() {
      if (!this.selectedModel) return;
      const yyyymm = this.params.yyyymm?.replaceAll('-', '') || null;
      const resp = await this.$axios.api.search({
        menuId: 'c0007011', queryId: 'selectDetailOUT',
        queryParams: { yyyymm, model: this.selectedModel },
      });
      this.detailRows = resp || [];
      this.detailTitle = `[${this.selectedModel}] OUT 상세 (d27 출하) — ${this.detailRows.length}건`;
    },
  },
};
</script>
