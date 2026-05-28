<!-- 기초데이터 변경 검증 - d21/d22/d27 레코드 비교 -->
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
        <b-button variant="warning" @click="snapshotClick" :disabled="isLoading">
          <span class="ico_save"></span>스냅샷 생성
        </b-button>
        <b-button @click="verifyClick" :disabled="isLoading">
          <span class="ico_search"></span>비교 검증
        </b-button>
      </div>
    </div>

    <!-- 요약 통계 카드 -->
    <div style="display: flex; gap: 12px; margin-bottom: 12px;">
      <!-- 스냅샷 정보 -->
      <div style="flex: 1; border: 2px solid #6c757d; border-radius: 8px; padding: 12px; background: #f8f9fa;">
        <h6 style="margin: 0 0 8px 0; font-size: 13px; font-weight: 600; color: #6c757d; border-bottom: 2px solid #6c757d; padding-bottom: 6px;">
          스냅샷 정보
        </h6>
        <div style="display: flex; gap: 6px;">
          <div style="flex: 1; padding: 8px; background: white; border-radius: 6px; text-align: center; border: 1px solid #dee2e6;">
            <div style="font-size: 11px; color: #6c757d;">스냅샷 일시</div>
            <div style="font-size: 14px; font-weight: bold; color: #212529;">{{ summary.snapshotDt || '-' }}</div>
          </div>
        </div>
      </div>

      <!-- 테이블별 건수 -->
      <div style="flex: 3; border: 2px solid #0d6efd; border-radius: 8px; padding: 12px; background: #f8f9fa;">
        <h6 style="margin: 0 0 8px 0; font-size: 13px; font-weight: 600; color: #0d6efd; border-bottom: 2px solid #0d6efd; padding-bottom: 6px;">
          레코드 비교 현황 (스냅샷 vs 현재)
        </h6>
        <div style="display: flex; gap: 6px;">
          <div style="flex: 1; padding: 8px; border-radius: 6px; text-align: center;"
               :style="{ background: getCountBg('d21'), border: '1px solid #dee2e6' }">
            <div style="font-size: 11px; color: #495057;">d21_제조지시VLR</div>
            <div style="font-size: 14px; font-weight: bold;">
              {{ summary.d21SnapCnt }} → {{ summary.d21CurrCnt }}
              <span v-if="summary.d21SnapCnt !== summary.d21CurrCnt" style="color: #dc3545; font-size: 11px;">
                ({{ summary.d21CurrCnt - summary.d21SnapCnt > 0 ? '+' : '' }}{{ summary.d21CurrCnt - summary.d21SnapCnt }})
              </span>
            </div>
          </div>
          <div style="flex: 1; padding: 8px; border-radius: 6px; text-align: center;"
               :style="{ background: getCountBg('d22'), border: '1px solid #dee2e6' }">
            <div style="font-size: 11px; color: #495057;">d22_RUN제조VLR</div>
            <div style="font-size: 14px; font-weight: bold;">
              {{ summary.d22SnapCnt }} → {{ summary.d22CurrCnt }}
              <span v-if="summary.d22SnapCnt !== summary.d22CurrCnt" style="color: #dc3545; font-size: 11px;">
                ({{ summary.d22CurrCnt - summary.d22SnapCnt > 0 ? '+' : '' }}{{ summary.d22CurrCnt - summary.d22SnapCnt }})
              </span>
            </div>
          </div>
          <div style="flex: 1; padding: 8px; border-radius: 6px; text-align: center;"
               :style="{ background: getCountBg('d27'), border: '1px solid #dee2e6' }">
            <div style="font-size: 11px; color: #495057;">d27_내포장MST</div>
            <div style="font-size: 14px; font-weight: bold;">
              {{ summary.d27SnapCnt }} → {{ summary.d27CurrCnt }}
              <span v-if="summary.d27SnapCnt !== summary.d27CurrCnt" style="color: #dc3545; font-size: 11px;">
                ({{ summary.d27CurrCnt - summary.d27SnapCnt > 0 ? '+' : '' }}{{ summary.d27CurrCnt - summary.d27SnapCnt }})
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 탭 영역: 테이블별 비교 -->
    <div class="grid_box">
      <b-tabs v-model="activeTab" class="custom-tabs">
        <!-- d21 제조지시VLR -->
        <b-tab title="d21_제조지시VLR">
          <div class="left_box">
            <span style="font-size: 12px; color: #6c757d;">변경/추가/삭제 건만 표시</span>
            <div class="btn_wrap ms-auto">
              <b-button class="second" size="sm" @click="toggleFilter('d21')">
                {{ showOnlyChanged.d21 ? '전체 보기' : '변경만 보기' }}
              </b-button>
              <b-button class="second" @click="excelBtnClick(0)">엑셀</b-button>
            </div>
          </div>
          <div class="grid-border-none" style="height: 500px;">
            <RealGrid ref="gridD21" :uid="'gridD21'" :step="'1'" :rows="gridD21Rows" style="height: 100%" />
          </div>
        </b-tab>

        <!-- d22 RUN제조VLR (같은 그리드 형식 재사용) -->
        <b-tab title="d22_RUN제조VLR">
          <div class="left_box">
            <span style="font-size: 12px; color: #6c757d;">변경/추가/삭제 건만 표시</span>
            <div class="btn_wrap ms-auto">
              <b-button class="second" size="sm" @click="toggleFilter('d22')">
                {{ showOnlyChanged.d22 ? '전체 보기' : '변경만 보기' }}
              </b-button>
              <b-button class="second" @click="excelBtnClick(1)">엑셀</b-button>
            </div>
          </div>
          <div class="grid-border-none" style="height: 500px;">
            <RealGrid ref="gridD22" :uid="'gridD22'" :step="'1'" :rows="gridD22Rows" style="height: 100%" />
          </div>
        </b-tab>

        <!-- d27 내포장MST -->
        <b-tab title="d27_내포장MST">
          <div class="left_box">
            <span style="font-size: 12px; color: #6c757d;">변경/추가/삭제 건만 표시</span>
            <div class="btn_wrap ms-auto">
              <b-button class="second" size="sm" @click="toggleFilter('d27')">
                {{ showOnlyChanged.d27 ? '전체 보기' : '변경만 보기' }}
              </b-button>
              <b-button class="second" @click="excelBtnClick(2)">엑셀</b-button>
            </div>
          </div>
          <div class="grid-border-none" style="height: 500px;">
            <RealGrid ref="gridD27" :uid="'gridD27'" :step="'2'" :rows="gridD27Rows" style="height: 100%" />
          </div>
        </b-tab>
      </b-tabs>
    </div>

    <!-- 변경 이력 팝업 -->
    <div v-if="showHistoryPopup" class="history-popup-overlay" @click.self="showHistoryPopup = false">
      <div class="history-popup">
        <div class="history-popup-header">
          <h6 style="margin: 0; font-weight: 600;">📋 변경 이력 — {{ historyTitle }}</h6>
          <button @click="showHistoryPopup = false" style="background: none; border: none; font-size: 18px; cursor: pointer; color: #666;">✕</button>
        </div>
        <div class="history-popup-body">
          <table v-if="historyRows.length > 0" style="width: 100%; font-size: 12px; border-collapse: collapse;">
            <thead>
              <tr style="background: #ffe0b2;">
                <th style="padding: 6px; border: 1px solid #ddd;">순번</th>
                <th style="padding: 6px; border: 1px solid #ddd;">변경일시</th>
                <th style="padding: 6px; border: 1px solid #ddd;">유형</th>
                <th style="padding: 6px; border: 1px solid #ddd;">변경자</th>
                <th style="padding: 6px; border: 1px solid #ddd;">사유</th>
                <th style="padding: 6px; border: 1px solid #ddd;">수량(변경전)</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(h, i) in historyRows" :key="i">
                <td style="padding: 4px 6px; border: 1px solid #ddd; text-align: center;">{{ i + 1 }}</td>
                <td style="padding: 4px 6px; border: 1px solid #ddd; text-align: center;">{{ h.changeDt }}</td>
                <td style="padding: 4px 6px; border: 1px solid #ddd; text-align: center;">{{ h.changeType }}</td>
                <td style="padding: 4px 6px; border: 1px solid #ddd; text-align: center;">{{ h.changeUser }}</td>
                <td style="padding: 4px 6px; border: 1px solid #ddd;">{{ h.changeReason }}</td>
                <td style="padding: 4px 6px; border: 1px solid #ddd; text-align: right; font-weight: bold; color: #dc3545;">
                  {{ h.cell수량 != null ? h.cell수량 : '-' }}
                </td>
              </tr>
            </tbody>
          </table>
          <div v-else style="text-align: center; padding: 20px; color: #999;">
            변경 이력이 없습니다.
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridFieldD21 from '@web/c0007000/js/C0007011.js';
import gridFieldD22 from '@web/c0007000/js/C0007011_D22.js';
import gridFieldD27 from '@web/c0007000/js/C0007011_Tab2.js';

export default {
  name: 'TAB070014',
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
      activeTab: 0,
      isLoading: false,
      gridD21: null,
      gridD22: null,
      gridD27: null,
      historyRows: [],
      historyTitle: '',
      showHistoryPopup: false,
      gridD21Rows: [],
      gridD22Rows: [],
      gridD27Rows: [],
      allD21Rows: [],
      allD22Rows: [],
      allD27Rows: [],
      showOnlyChanged: { d21: false, d22: false, d27: false },
      params: {
        site: 'HQ',
        yyyymm: null,
      },
      siteMap: {
        '본사': 'HQ',
        'VINA': 'VN',
      },
      summary: {
        snapshotDt: null,
        d21SnapCnt: 0, d21CurrCnt: 0,
        d22SnapCnt: 0, d22CurrCnt: 0,
        d27SnapCnt: 0, d27CurrCnt: 0,
      },
    };
  },
  watch: {
    activeTab(newVal) {
      // 탭 전환 시 RealGrid 리사이즈 (숨겨진 상태에서 렌더링된 그리드 보정)
      this.$nextTick(() => {
        const refs = ['gridD21', 'gridD22', 'gridD27'];
        const ref = this.$refs[refs[newVal]];
        if (ref) {
          const gv = ref.getGridView();
          if (gv) {
            gv.resetSize();
            gv.fitLayoutWidth(null);
          }
        }
      });
    },
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
        if (newVal) {
          this.params.yyyymm = newVal;
        }
      },
    },
  },
  computed: {
    displaySite() {
      return this.params.site;
    },
  },
  created() {
    const now = new Date();
    this.params.yyyymm = `${now.getFullYear()}-${('0' + (now.getMonth() + 1)).slice(-2)}`;
    this.initializeGrid();
  },
  mounted() {
    this.params.yyyymm = this.srchInfo.yyyymm;
    this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
  },
  methods: {
    initializeGrid() {
      // d21, d22는 같은 그리드 형식 (투입/불량/양품 비교)
      this.gridD21 = _.cloneDeep(gridFieldD21);
      this.gridD22 = _.cloneDeep(gridFieldD22);
      this.gridD27 = _.cloneDeep(gridFieldD27);
    },

    getCountBg(table) {
      const s = this.summary;
      if (table === 'd21' && s.d21SnapCnt > 0 && s.d21SnapCnt !== s.d21CurrCnt) return '#fff3cd';
      if (table === 'd22' && s.d22SnapCnt > 0 && s.d22SnapCnt !== s.d22CurrCnt) return '#fff3cd';
      if (table === 'd27' && s.d27SnapCnt > 0 && s.d27SnapCnt !== s.d27CurrCnt) return '#fff3cd';
      return 'white';
    },

    /** 스냅샷 생성 버튼 */
    snapshotClick() {
      const yyyymm = this.params.yyyymm?.replaceAll('-', '') || null;
      if (!yyyymm) {
        this.$toast('info', '기준월을 선택하세요.');
        return;
      }
      this.$confirm(
        `${yyyymm.substring(0,4)}년 ${yyyymm.substring(4,6)}월 기초데이터 스냅샷을 생성하시겠습니까?\n(기존 스냅샷이 있으면 덮어씁니다)`,
        '스냅샷 생성 확인',
        async (result) => {
          if (!result) return;
          this.isLoading = true;
          try {
            const param = {
              menuId: 'c0007011',
              update: [{
                queryId: 'createSnapshot',
                data: [{
                  yyyymm: yyyymm,
                  site: this.siteMap[this.params.site] || 'HQ',
                }],
              }],
            };
            await this.$axios.api.saveData(param);
            this.$toast('success', '스냅샷이 생성되었습니다.');
            await this.verifyClick();
          } catch (e) {
            console.error(e);
            this.$toast('error', '스냅샷 생성 중 오류가 발생했습니다.');
          } finally {
            this.isLoading = false;
          }
        }
      );
    },

    /** 비교 검증 버튼 */
    async verifyClick() {
      this.isLoading = true;
      try {
        const yyyymm = this.params.yyyymm?.replaceAll('-', '') || null;
        const site = this.siteMap[this.params.site] || 'HQ';
        const qp = { yyyymm, site };

        // 1. 요약 조회
        const summaryResp = await this.$axios.api.search({
          menuId: 'c0007011', queryId: 'selectVerifySummary', queryParams: qp,
        });
        if (summaryResp && summaryResp.length > 0) {
          const d = summaryResp[0];
          this.summary.snapshotDt = d.snapshotDt || '-';
          this.summary.d21SnapCnt = d.d21SnapCnt || 0;
          this.summary.d21CurrCnt = d.d21CurrCnt || 0;
          this.summary.d22SnapCnt = d.d22SnapCnt || 0;
          this.summary.d22CurrCnt = d.d22CurrCnt || 0;
          this.summary.d27SnapCnt = d.d27SnapCnt || 0;
          this.summary.d27CurrCnt = d.d27CurrCnt || 0;
        }

        if (!this.summary.snapshotDt || this.summary.snapshotDt === '-') {
          this.$toast('info', '스냅샷이 없습니다. 먼저 스냅샷을 생성하세요.');
          return;
        }

        // 2. d21 비교
        const d21Resp = await this.$axios.api.search({
          menuId: 'c0007011', queryId: 'selectCompareD21', queryParams: qp,
        });
        this.allD21Rows = d21Resp || [];

        // 3. d22 비교
        const d22Resp = await this.$axios.api.search({
          menuId: 'c0007011', queryId: 'selectCompareD22', queryParams: qp,
        });
        this.allD22Rows = d22Resp || [];

        // 4. d27 비교
        const d27Resp = await this.$axios.api.search({
          menuId: 'c0007011', queryId: 'selectCompareD27', queryParams: qp,
        });
        this.allD27Rows = d27Resp || [];

        // 필터 적용
        this.applyFilter('d21');
        this.applyFilter('d22');
        this.applyFilter('d27');

        // 그리드 더블클릭 이벤트 연결 (이력 조회)
        this.historyRows = [];
        this.setupGridClick('gridD21', 'd21');
        this.setupGridClick('gridD22', 'd22');
        this.setupGridClick('gridD27', 'd27');

      } catch (e) {
        console.error(e);
        this.$toast('error', '검증 조회 중 오류가 발생했습니다.');
      } finally {
        this.isLoading = false;
      }
    },

    toggleFilter(table) {
      this.showOnlyChanged[table] = !this.showOnlyChanged[table];
      this.applyFilter(table);
    },

    applyFilter(table) {
      if (table === 'd21') {
        this.gridD21Rows = this.showOnlyChanged.d21
          ? this.allD21Rows.filter(r => r.status !== '정상')
          : this.allD21Rows;
      } else if (table === 'd22') {
        this.gridD22Rows = this.showOnlyChanged.d22
          ? this.allD22Rows.filter(r => r.status !== '정상')
          : this.allD22Rows;
      } else if (table === 'd27') {
        this.gridD27Rows = this.showOnlyChanged.d27
          ? this.allD27Rows.filter(r => r.status !== '정상')
          : this.allD27Rows;
      }
    },

    async excelBtnClick(tabIdx) {
      const refs = ['gridD21', 'gridD22', 'gridD27'];
      const names = ['d21_제조지시VLR', 'd22_RUN제조VLR', 'd27_내포장MST'];
      const grid = this.$refs[refs[tabIdx]]?.getGridView();
      if (!grid) return;
      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();
      const hms = `${String(now.getHours()).padStart(2,'0')}${String(now.getMinutes()).padStart(2,'0')}${String(now.getSeconds()).padStart(2,'0')}`;
      grid.exportGrid({
        type: 'excel', target: 'local',
        fileName: `기초데이터검증_${names[tabIdx]}_${yyyymmdd}_${hms}.xlsx`,
        indicator: 'hidden', header: 'default', footer: 'default',
        showProgress: true, progressMessage: '엑셀 Export중입니다.',
      });
    },

    /** 그리드 클릭 → 변경 이력 팝업 + 변경행 색상 */
    setupGridClick(refName, table) {
      this.$nextTick(() => {
        const gv = this.$refs[refName]?.getGridView();
        if (!gv) return;

        // 변경/추가/삭제 행 색상 표시
        gv.setRowStyleCallback((grid, item) => {
          const dp = grid.getDataSource();
          const status = dp.getValue(item.dataRow, 'status');
          if (status === '변경') return 'rg-row-changed';
          if (status === '추가') return 'rg-row-added';
          if (status === '삭제') return 'rg-row-deleted';
          return '';
        });

        // 단일 클릭 → 이력 팝업
        gv.onCellClicked = (grid, clickData) => {
          if (clickData.itemIndex < 0) return;
          const dp = this.$refs[refName].getGridDataProvider();
          const status = dp.getValue(clickData.itemIndex, 'status') || dp.getValue(clickData.itemIndex, 'STATUS');
          if (status && status !== '정상') {
            const row = {};
            dp.getFieldNames().forEach(f => { row[f] = dp.getValue(clickData.itemIndex, f); });
            this.loadHistory(table, row);
          }
        };
      });
    },

    async loadHistory(table, row) {
      const yyyymm = this.params.yyyymm?.replaceAll('-', '') || null;
      let queryId, queryParams;

      if (table === 'd21') {
        queryId = 'selectHistoryD21';
        const lotNo = row.LOTNO || row.lotNo;
        const gongjeong = row['공정코드'];
        queryParams = { yyyymm, lotNo, gongjeong };
        this.historyTitle = `d21 ${lotNo} / 공정 ${gongjeong}`;
      } else if (table === 'd22') {
        queryId = 'selectHistoryD22';
        const runNo = row.RUNNO || row.runNo;
        const gongjeong = row['공정코드'];
        queryParams = { yyyymm, runNo, gongjeong };
        this.historyTitle = `d22 ${runNo} / 공정 ${gongjeong}`;
      } else {
        queryId = 'selectHistoryD27';
        const packQrno = row.PACKQRNO || row.packQrno;
        queryParams = { yyyymm, packQrno };
        this.historyTitle = `d27 ${packQrno}`;
      }

      const resp = await this.$axios.api.search({
        menuId: 'c0007011', queryId, queryParams,
      });
      this.historyRows = resp || [];
      this.showHistoryPopup = true;
      if (this.historyRows.length === 0) {
        this.$toast('info', '변경 이력이 없습니다.');
      }
    },
  },
};
</script>


<style scoped>
.custom-tabs {
  border-bottom: 1px solid #dee2e6;
  margin-bottom: 0;
}

/* 팝업 오버레이 */
.history-popup-overlay {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(0,0,0,0.4);
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
}
.history-popup {
  background: white;
  border-radius: 12px;
  box-shadow: 0 8px 32px rgba(0,0,0,0.3);
  width: 700px;
  max-height: 500px;
  overflow: hidden;
}
.history-popup-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 20px;
  background: #fd7e14;
  color: white;
}
.history-popup-header h6 { color: white; }
.history-popup-header button { color: white !important; font-size: 20px; }
.history-popup-body {
  padding: 16px 20px;
  max-height: 400px;
  overflow-y: auto;
}
</style>

<style>
/* RealGrid 변경행 색상 (전역 스타일) */
.rg-row-changed {
  background: #fff3cd !important;
}
.rg-row-added {
  background: #d1e7dd !important;
}
.rg-row-deleted {
  background: #f8d7da !important;
}
</style>
