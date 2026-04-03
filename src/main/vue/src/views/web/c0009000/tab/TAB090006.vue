/** * 재공,제품 원가 - 제조원가(재공) */

<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="1" class="period">
          <div class="form-floating me-1">
            <date-picker label="연도" mode="year" v-model="params.year" />
            <label for="floatingSelect" class="select">년도</label>
          </div>
        </b-col>
          <b-col cols="1" class="period">
            <div class="form-floating me-1">
              <b-form-select v-model="params.month" :options="monthOptions" class="form-control" style="padding-left: 60px; min-width: 150px;" />
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
        <div class="btn_wrap ms-auto">
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid
          ref="manuCostGrid"
          :uid="'manuCostGrid'"
          :grid="activeGrid"
          :step="'1'"
          :rows="manuCostGridRows"
          style="height: 100%"
        />
      </div>
    </div>
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';

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
      manuCostGrid: null,
      manuCostDtlGrid: null,
      manuCostGridRows: [],
      totalRowCount: 0,   

      yearSelected: false,
      syncingYearToMonth: false,
      isInitializing: true,

      yearRowsCache: [],
      yearCacheKey: null,
      
      monthOptions: [
        { value: null, text: '전체' },
        { value: '01', text: '1월' },
        { value: '02', text: '2월' },
        { value: '03', text: '3월' },
        { value: '04', text: '4월' },
        { value: '05', text: '5월' },
        { value: '06', text: '6월' },
        { value: '07', text: '7월' },
        { value: '08', text: '8월' },
        { value: '09', text: '9월' },
        { value: '10', text: '10월' },
        { value: '11', text: '11월' },
        { value: '12', text: '12월' },
      ],
      selCodeList: [],

      params: {
        year: null,
        month: null,
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
      'params.year'(newVal) {
        if (!newVal) {
          this.yearSelected = false;
          this.params.month = null;
          this.params.yyyymm = null;
          this.params.viewMode = 'YEAR';

          return;
        }

        if (!this.isInitializing) {
          this.yearSelected = true;
        }

        const yyyy = String(newVal);

        if (this.params.month) {
          const mm = String(this.params.month);
          this.params.yyyymm = `${yyyy}${mm}`;
          this.params.viewMode = 'MONTH';
        } else {
          this.params.yyyymm = null;
          this.params.viewMode = 'YEAR';
        }
        
        this.clearYearCache?.();
      },

      'params.month'(newVal) {
        if (!newVal) {
          this.params.yyyymm = null;
          this.params.viewMode = 'YEAR';
          return;
        }

        if (!this.isInitializing) {
          const yyyy = String(this.params.year);
          const mm = String(newVal);
          this.params.yyyymm = `${yyyy}${mm}`;
          this.params.viewMode = 'MONTH';
        }
      },
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          if (this.$refs.manuCostGrid != null) {
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
    showMonth() {
      return this.yearSelected;
    },
    activeGrid() {
      return this.params.viewMode === 'MONTH' ? this.manuCostDtlGrid : this.manuCostGrid;
    },
    gridKey() {
      return this.params.viewMode === 'MONTH' ? 'MONTH' : 'YEAR';
    },
    gridView() {
      return this.$refs.manuCostGrid.getGridView();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    },
  },
  created() {
    this.isInitializing = true;
    this.initialize();
    this.initializeGrid();
    this.$nextTick(() => {
      this.isInitializing = false;
    });
  },
  mounted() {
    const gv = this.gridView;

    // ✅ 1) Footer 명시적 활성화
    if (gv) {
      try {
        // RealGridJS 스타일로 footer 활성화 시도
        const footerVisible = { visible: true };
        if (typeof gv.setFooterVisible === 'function') {
          gv.setFooterVisible(true);
        }
      } catch (e) {
        console.log('Footer setting error:', e.message);
      }
    }

    // ✅ 2) 요약행 색상: itemIndex 기준으로 rowType 읽기
    gv.setRowStyleCallback((grid, item) => {
      const itemIndex =
        item?.itemIndex ?? item?.index ?? item?.dataRow; // 버전별 안전 처리

      if (itemIndex == null || itemIndex < 0) return null;

      const rowType = String(grid.getValue(itemIndex, 'rowType') ?? '');

      if (rowType === 'SUBTOTAL') {
        return { style: { background: '#f5f7ff', fontWeight: 'bold' } };
      }
      if (rowType === 'GRAND_TOTAL') {
        return { style: { background: '#e8f4f8', fontWeight: 'bold' } };
      }
      if (rowType === 'TOTAL') {
        return { style: { background: '#fff3cd', fontWeight: 'bold' } };
      }
      return null;
    });

    // ✅ 3) 병합 spanCallback도 itemIndex 기준으로 판별
    this.applySpanCallbacks();

    // ✅ 4) 정렬 후 refresh(보험)
    // (이벤트명이 환경/버전에 따라 다를 수 있어 여러개 걸어둠)
    gv.onSorted = () => gv.refresh();
    gv.onSortingChanged = () => gv.refresh();
    gv.onDataSorted = () => gv.refresh();
  },
  beforeUnmount() {},
  methods: {
    initialize() {
      const baseYyyymm = this.srchInfo.yyyymm;
      const defaultYear = baseYyyymm 
      ? String(baseYyyymm).substring(0, 4) : String(new Date().getFullYear());

      this.params.year = defaultYear;
      this.params.month = null;
      this.params.yyyymm = null;
      this.params.viewMode = 'YEAR';

      this.yearSelected = false;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
      this.loadSelCodeList();
    },
    initializeGrid() {
      this.manuCostGrid = _.cloneDeep(require(`@web/c0009000/js/TAB090006.js`));
      this.manuCostDtlGrid = _.cloneDeep(require(`@web/c0009000/js/TAB090006_2.js`));
    },
    async applyGridMode(mode) {
      const gv = this.gridView;
      if (!gv) return;

      const g = mode === 'MONTH' ? this.manuCostDtlGrid : this.manuCostGrid;

      if (g?.columns) gv.setColumns(g.columns);
      if (g?.columnLayout) gv.setColumnLayout(g.columnLayout);
      
      // 월상세 모드에서만 footer 활성화
      if (mode === 'MONTH') {
        // footer 옵션 활성화
        if (gv.footerOptions) {
          gv.footerOptions.visible = true;
        }
      }

      this.applySpanCallbacks();
      gv.refresh();
    },
    capSpan(span) {
      const max = 5;
      const s = Number(span) || 1;
      return Math.max(1, Math.min(s, max));
    },
    getRowInfoByItemIndex(grid, itemIndex) {
      return {
        rowType: String(grid.getValue(itemIndex, 'rowType') ?? ''),
        gubun: String(grid.getValue(itemIndex, '구분') ?? ''),
      };
    },
    applySpanCallbacks() {
      const gv = this.gridView;
      if (!gv) return;

      const makeSpan = (colName) => {
        const layout = gv.layoutByColumn(colName);
        if (!layout) return;

        layout.spanCallback = (grid, layout, itemIndex) => {
          if (itemIndex == null || itemIndex < 0) return 1;

          const { rowType, gubun } = this.getRowInfoByItemIndex(grid, itemIndex);

          let span = 1;

          if (rowType === 'SUBTOTAL') span = 5;
          else if (rowType === 'GRAND_TOTAL') span = 5;
          else if (rowType === 'TOTAL' && gubun === '판매처별') {
            if (colName === '구분' || colName === '모델') span = 2;
            else if (colName === 'inch' || colName === '판매처' || colName === '월') span = 3;
          } else if (rowType === 'TOTAL') span = 5;

          return this.capSpan(span);
        };
      };

      ['구분', '모델', 'inch', '판매처', '월'].forEach(makeSpan);

      gv.refresh();
    },
    async fetchYearRowsIfNeeded() {
      if (!this.hasSysAdmin) {
        this.params.selCode = 'ACTUAL';
      }
      const yyyy = this.params.year;
      const site = this.params.site != null ? this.siteMap[this.params.site] : null;
      const selCode = this.params.selCode === '' ? 'ACTUAL' : this.params.selCode;
      const key = `${yyyy}|${site || ''}|${selCode || ''}`;

      if (this.yearCacheKey === key && Array.isArray(this.yearRowsCache) && this.yearRowsCache.length) {
        return this.yearRowsCache;
      }

      const param = {
        menuId: 'c0009000',
        queryId: 'C0009007_Tab090006',
        queryParams: { yyyy, site, selCode },
        target: [],
      };

      const resp = await this.$axios.api.search(param);

      let rows = [];
      if (resp && resp.data) {
        rows = Array.isArray(resp.data) ? resp.data : (resp.data.rows || []);
      } else if (Array.isArray(resp)) {
        rows = resp;
      }

      rows = rows.map(r => {
        if (r == null) return r;

        if ('YYYYMM' in r || 'yyyymm' in r) return r;

        const mm = this.parseMonthNumber(r['월']);
        if (!mm) return r;

        const yyyymm = `${this.params.year}${String(mm).padStart(2, '0')}`;
        return { ...r, YYYYMM: yyyymm };
      });

      this.yearRowsCache = rows;
      this.yearCacheKey = key;
      return rows;
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

    parseMonthNumber(monthText) {
      const m = String(monthText || '').match(/(\d{1,2})\s*월/);
      if (!m) return null;
      const mm = Number(m[1]);
      return mm >= 1 && mm <= 12 ? mm : null;
    },    
    buildManuCostRows(rows) {
      if (!Array.isArray(rows) || rows.length === 0) return [];

      const result = [];
      const numberCols = [
        'bohQty','bohAmt',
        'inQty','inAmt',
        'inEtcQty','inEtcAmt',
        'rmaInQty','rmaInAmt',
        'outQty','outAmt',
        'rmaOutQty','rmaOutAmt',
        'lossQty','lossAmt',
        'eohQty','eohAmt',
      ];
      const groupMap = {};

      rows.forEach(r => {
        const gubun = r['구분'] || '기타';
        if (!groupMap[gubun]) groupMap[gubun] = [];
        groupMap[gubun].push(r);
      });

      const orderedGubuns = [];
      if (groupMap['개발']) orderedGubuns.push('개발');
      if (groupMap['양산']) orderedGubuns.push('양산');
      Object.keys(groupMap).forEach(g => {
        if (!orderedGubuns.includes(g)) orderedGubuns.push(g);
      });

      let mergeGroupSeq = 0;
      const grandTotalRow = this.createEmptySubtotalRowByGroup('총합계', rows[0] || {});

      orderedGubuns.forEach(g => {
        const list = groupMap[g];
        if (!list || list.length === 0) return;

        const subtotalRow = this.createEmptySubtotalRowByGroup(g, list[0]);
        
        let lastKey = null;

    list.forEach(r => {
      const prodKey = [
        r['구분'] || '',
        r['모델'] || r['model'] || '',
        r['inch'] || '',
        r['판매처'] || r['DW_SITE'] || r['dwSite'] || '',
      ].join('|');

      if (prodKey !== lastKey) {
        mergeGroupSeq++;
        lastKey = prodKey;
      }

      const mergeKey =
        prodKey.replace(/\|/g, '') === ''
          ? `ROW|${mergeGroupSeq}`
          : `DATA|${mergeGroupSeq}`; 

      const mergeKeyGubun = mergeKey;

          result.push({
            ...r,
            rowType: 'DATA',
            mergeKey,
            mergeKeyGubun,
          });
          this.accumulateRow(subtotalRow, r, numberCols);
          this.accumulateRow(grandTotalRow, r, numberCols);
        });

        result.push(this.makeSubtotalRowByGroup(subtotalRow, g));
      });

      // 총합계 BOH: 1월 BOH 합산, EOH: 마지막 데이터월 EOH 합산
      const janRows = rows.filter(r => this.parseMonthNumber(r['월']) === 1);
      let bohQtySum = 0, bohAmtSum = 0;
      janRows.forEach(r => {
        bohQtySum += Number(r.bohQty) || 0;
        bohAmtSum += Number(r.bohAmt) || 0;
      });

      let maxMonth = 0;
      rows.forEach(r => {
        const mm = this.parseMonthNumber(r['월']);
        if (mm && mm > maxMonth) maxMonth = mm;
      });
      const lastMonthRows = rows.filter(r => this.parseMonthNumber(r['월']) === maxMonth);
      let eohQtySum = 0, eohAmtSum = 0;
      lastMonthRows.forEach(r => {
        eohQtySum += Number(r.eohQty) || 0;
        eohAmtSum += Number(r.eohAmt) || 0;
      });

      grandTotalRow.bohQty = bohQtySum;
      grandTotalRow.bohAmt = bohAmtSum;
      grandTotalRow.eohQty = eohQtySum;
      grandTotalRow.eohAmt = eohAmtSum;

      result.push(this.makeGrandTotalRow(grandTotalRow));

      const first = rows[0] || {};
      const dwSiteField = 
        '판매처' in first ? '판매처' : 
        'DW_SITE' in first ? 'DW_SITE' : 
        'dwSite' in first ? 'dwSite' :
        null;

      if (!dwSiteField) {
        return result;
      }

      const siteTotalsMap = {};

      rows.forEach(r => {
        const key = r[dwSiteField] || '-';

        if (!siteTotalsMap[key]) {
          siteTotalsMap[key] = this.createEmptySubtotalRowByGroup(key, r);
        }
        this.accumulateRow(siteTotalsMap[key], r, numberCols);
      });

      const siteKeys = Object.keys(siteTotalsMap);
      const orderedSiteKeys = [];
      if (siteKeys.includes('-')) {
        orderedSiteKeys.push('-');
      }
      siteKeys.filter(k => k !== '-').sort().forEach(k => {
        orderedSiteKeys.push(k);
      });

      orderedSiteKeys.forEach((key, idx) => {
        const totalRow = siteTotalsMap[key];
        result.push({
          ...this.makeTotalRow(totalRow, dwSiteField, key),
          mergeKey: `TOTAL|${key}`,
          mergeKeyGubun: 'TOTAL',
        });
      });

      return result;
    },
    createEmptySubtotalRowByGroup(groupName, baseRow = {}) {
      return {
        rowType: 'SUBTOTAL',
        구분: `소계(${groupName})`,
        월: '',
        bohQty: 0, bohAmt: 0,
        inQty: 0, inAmt: 0,
        outQty: 0, outAmt: 0,
        lossQty: 0, lossAmt: 0,
        rmaInQty: 0, rmaInAmt: 0,
        rmaOutQty: 0, rmaOutAmt: 0,
        eohQty: 0, eohAmt: 0,
        inMatQty: 0, inMatAmt: 0,
        inEtcQty: 0, inEtcAmt: 0,
        inRmaQty: 0, inRmaAmt: 0,
        outGoodQty: 0, outGoodAmt: 0,
        outEtcQty: 0, outEtcAmt: 0,
      };
    },

    buildMonthDetailRowsWithTotal(rows, selectedYYYYMM) {
    const monthLabel = `${Number(selectedYYYYMM.substring(4, 6))}월`;

      const result = [];
      const numberColsCandidates = [
        ['BOH_QTY', 'bohQty'], ['BOH_AMT', 'bohAmt'],
        ['IN_QTY', 'inQty'],   ['IN_AMT', 'inAmt'],
        ['OUT_QTY','outQty'],  ['OUT_AMT','outAmt'],
        ['LOSS_QTY','lossQty'],['LOSS_AMT','lossAmt'],
        ['RMA_IN_QTY','rmaInQty'], ['RMA_IN_AMT','rmaInAmt'],
        ['EOH_QTY','eohQty'],  ['EOH_AMT','eohAmt'],
      ];

      rows.forEach((r, idx) => {
        // camelCase 필드명 명시적 추가 (footer 계산용)
        const dataRow = { ...r, 월: r['월'] ?? monthLabel, rowType: 'DATA', mergeKey: `MD|${idx}`, mergeKeyGubun: `MD|${idx}` };
        numberColsCandidates.forEach(([k1, k2]) => {
          if (k1 in r) dataRow[k2] = Number(r[k1]) || 0;
          else if (k2 in r) dataRow[k2] = Number(r[k2]) || 0;
        });
        result.push(dataRow);
      });

      const totalRow = { rowType: 'TOTAL', 구분: '월합계', 월: monthLabel };

      numberColsCandidates.forEach(([k1, k2]) => {
        totalRow[k1] = 0;
        totalRow[k2] = 0;
      });

      rows.forEach(r => {
        numberColsCandidates.forEach(([k1, k2]) => {
          if (k1 in r) totalRow[k1] += Number(r[k1]) || 0;
          if (k2 in r) totalRow[k2] += Number(r[k2]) || 0;
        });
      });

      const lossAmt = (totalRow.LOSS_AMT || totalRow.lossAmt || 0);
      const bohAmt  = (totalRow.BOH_AMT  || totalRow.bohAmt  || 0);
      const inAmt   = (totalRow.IN_AMT   || totalRow.inAmt   || 0);
      totalRow['불량률'] = (lossAmt * 1.0) / ((bohAmt + inAmt) || null) * 100;

      totalRow.mergeKey = `TOTAL|${selectedYYYYMM}`;
      totalRow.mergeKeyGubun = 'TOTAL';

      // 마지막 행에 합계 표시 (footer 스타일로)
      result.push(totalRow);
      return result;
    },
    accumulateRow(target, source, numberCols) {
      numberCols.forEach(col => {
        const v = Number(source[col]) || 0;
        target[col] += v;
      });
    },

    makeSubtotalRowByGroup(row, groupName) {
      return {
        ...row,
        rowType: 'SUBTOTAL',
        구분: `소계(${groupName})`,
        월: '',
        mergeKey: `SUBTOTAL|${groupName}`,
        mergeKeyGubun: `SUBTOTAL|${groupName}`,
      };
    },

    makeGrandTotalRow(row) {
      return {
        ...row,
        rowType: 'GRAND_TOTAL',
        구분: '총 합계 (1월 BOH / 최종 결산월 EOH)',
        월: '',
        mergeKey: 'GRAND_TOTAL',
        mergeKeyGubun: 'GRAND_TOTAL',
      };
    },

    makeTotalRow(row, dwSiteField, siteKey) {
      return {
        ...row,
        rowType: 'TOTAL',
        구분: '판매처별',
        모델: '',
        inch: siteKey,
        판매처: '',
        월: '',
      };
    },
    async searchClick() {
      const yearRows = await this.fetchYearRowsIfNeeded();

      if (this.params.viewMode === 'YEAR') {
        await this.applyGridMode('YEAR');
        const rows = this.buildManuCostRows(yearRows);

        this.totalRowCount = rows.filter(r => r.rowType === 'TOTAL').length;
        this.manuCostGridRows = rows;
        
        this.$nextTick(() => {
          this.applyRowFixing();
        });
        return;
      }

      await this.applyGridMode('MONTH');

      const selectedYYYYMM = String(this.params.yyyymm || '');
      const filtered = yearRows.filter(r => {
        const rowYYYYMM = String(r['YYYYMM'] || r['yyyymm'] || '');
        return rowYYYYMM === selectedYYYYMM;
      });

      const rows = this.buildMonthDetailRowsWithTotal(filtered, selectedYYYYMM);
      
      this.totalRowCount = rows.filter(r => r.rowType === 'TOTAL').length;
      this.manuCostGridRows = rows;
      
      this.$nextTick(() => {
        // Footer 계산을 위해 refresh 수행
        const gv = this.gridView;
        if (gv) {
          gv.refresh();
        }
      });
    },
    applyRowFixing() {
      const gv = this.gridView;

      if (!gv || this.totalRowCount === 0) return;
    },
    async excelBtnClick() {
      const grid = this.gridView;

      await this.$nextTick();

      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();

      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `매출원가(제품)_${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

      const options = {
        type: 'excel',
        target: 'local',
        fileName: fileName,
        progressMessage: '엑셀 Export중입니다.',
        exportDisplay: true,
        done: function () {
          alert('엑셀 내보내기가 완료되었습니다!');
        },
      };

      grid.exportGrid(options);
    },
  },
};
</script>