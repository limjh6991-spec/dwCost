/** * 재공,제품 원가 - 매출원가(제품) */

<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="2">
          <div class="form-floating">
            <date-picker v-model="params.yyyymm" mode="year" />
            <label for="floatingSelect" class="select">년도</label>
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
        <RealGrid ref="prodCogsGrid" :uid="'prodCogsGrid'" :grid="prodCogsGrid" :layout="prodCogsGrid.columnLayout" :step="'1'" :rows="prodCogsGridRows" style="height: 100%" />
      </div>
    </div>
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0009000/js/TAB090007.js';

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
      prodCogsGrid: null,
      prodCogsGridRows: [],
      params: {
        yyyymm: null,
        site: 'HQ',
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
        }
      },
    },
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          if (this.$refs.prodCogsGrid != null) {
            this.initialize();
            this.searchClick();
          }
        }
      },
    },
  },
  computed: {
    gridView() {
      return this.$refs.prodCogsGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.prodCogsGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    },
  },
  created() {
    this.initialize();
    this.initializeGrid();
  },
  mounted() {
    const gv = this.gridView;

    if (this.prodCogsGrid.columnLayout) {
      gv.setColumnLayout(this.prodCogsGrid.columnLayout);
    }

    gv.setRowStyleCallback((grid, item, fixed) => {
      const row = item.dataRow;
      if (row == null || row < 0) return null;

      const rowType = (grid.getValue(row, 'rowType') || '').toString();
      console.log('rowStyleCallback:', row, rowType);

      if (rowType === 'SUBTOTAL') {
        return {
          style: {
            background: '#f5f7ff',
            fontWeight: 'bold',
          },
        };
      }

      if (rowType === 'TOTAL') {
        return {
          style: {
            background: '#fff3cd',
            fontWeight: 'bold',
          },
        };
      }

      return null;
    });

    const layoutGubun = gv.layoutByColumn('구분');
    if (layoutGubun) {
      layoutGubun.spanCallback = (grid, layout, itemIndex) => {
        const rowType = (grid.getValue(itemIndex, 'rowType') || '').toString();

        if (rowType === 'SUBTOTAL') {
          return 5;
        }
        if (rowType === 'TOTAL') {
          return 2;
        }
        return 1;
      };
    }

    const layoutInch = gv.layoutByColumn('inch');
    if (layoutInch) {
      layoutInch.spanCallback = (grid, layout, itemIndex) => {
        const rowType = (grid.getValue(itemIndex, 'rowType') || '').toString();

        if (rowType === 'TOTAL') {
          return 3;
        }
        return 1;
      };
    }
  },
  beforeUnmount() {},
  methods: {
    initialize() {
      this.params.yyyymm = this.srchInfo.yyyymm;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },
    initializeGrid() {
      this.prodCogsGrid = _.cloneDeep(gridField);
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },
    async getDataList() {
      this.gridView.commit();

      let params = {
        yyyy: this.params.yyyymm.substring(0, 4),
        site: this.params.site != null ? this.siteMap[this.params.site] : null,
      };

      let param = {
        menuId: 'c0009000',
        queryId: 'C0009007_Tab090007',
        queryParams: params,
        target: this.prodCogsGridRows,
      };
      let resp = await this.$axios.api.search(param);

      let rows = [];
      if (resp && resp.data) {
        rows = Array.isArray(resp.data) ? resp.data : resp.data.rows || [];
      } else if (Array.isArray(resp)) {
        rows = resp;
      }

      this.prodCogsGridRows = this.buildProdCogsRows(rows);
    },
    buildProdCogsRows(rows) {
      if (!Array.isArray(rows) || rows.length === 0) return [];

      const result = [];
      const numberCols = [
        'bohQty','bohAmt',
        'inQty','inAmt',
        'outQty','outAmt',
        'eohQty','eohAmt',
        'inMatQty','inMatAmt',
        'inEtcQty','inEtcAmt',
        'rmaInQty','rmaInAmt',
        'outGoodQty','outGoodAmt',
        'outEtcQty','outEtcAmt',
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
        });

        result.push(this.makeSubtotalRowByGroup(subtotalRow, g));
      });

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
        const key = r[dwSiteField];
        if (!key) return;

        if (!siteTotalsMap[key]) {
          siteTotalsMap[key] = this.createEmptySubtotalRowByGroup(key, r);
        }
        this.accumulateRow(siteTotalsMap[key], r, numberCols);
      });

      Object.keys(siteTotalsMap).forEach((key, idx) => {
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
        eohQty: 0, eohAmt: 0,
        inMatQty: 0, inMatAmt: 0,
        inEtcQty: 0, inEtcAmt: 0,
        inRmaQty: 0, inRmaAmt: 0,
        outGoodQty: 0, outGoodAmt: 0,
        outEtcQty: 0, outEtcAmt: 0,
      };
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
        mergeKeyGubun: `SUBTOTAL|${groupName}`,
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
      const fileName = `매출원가(제품)_${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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