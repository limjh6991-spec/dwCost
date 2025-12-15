<!-- 결산증빙 자료 > 제품별 손익계산서 -->
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
        <RealGrid ref="modelPlGrid" :uid="'modelPlGrid'" :step="'1'" :rows="modelPlGridRows" :grid="modelPlGrid" style="height: 100%" />
      </div>
    </div>
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';

export default {
  setup() {
    const srchInfo = useC0001001();
    const userAuthInfo = useUserAuthInfo();
    return { srchInfo, userAuthInfo };
  },

  data() {
    return {
      modelPlGrid: null,
      modelPlGridRows: [],

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

  computed: {
    gridView() {
      return this.$refs.modelPlGrid?.getGridView();
    },
    gridDataProvider() {
      return this.$refs.modelPlGrid?.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    },
  },

  watch: {
    'params.yyyymm'(newVal) {
      if (newVal) this.onDateChange();
    },
    'srchInfo.yyyymm': {
      handler(newVal) {
        if (newVal) this.params.yyyymm = newVal;
      },
    },
    prodCtg: {
      handler(newVal) {
        if (!newVal) return;
        this.params.site = newVal === 'VN' ? 'VINA' : '본사';
        if (this.$refs.modelPlGrid) {
          this.initialize();
          this.searchClick();
        }
      },
    },
  },

  created() {
    this.initialize();
    this.initializeGrid();
  },

  methods: {
    initialize() {
      this.params.yyyymm = this.srchInfo.yyyymm;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },

    initializeGrid() {
      this.modelPlGrid = _.cloneDeep(require(`@web/c0009000/js/C0009009.js`));
    },

    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },

    convertModelToFieldId(model) {
      if (!model) return model;

      const s = String(model).trim();

      const safe = s.replace(/[^\w\sㄱ-힣]/g, '').toLowerCase();

      let result = '';
      let makeUpper = false;

      for (const ch of safe) {
        if (ch === ' ' || ch === '_') {
          makeUpper = true;
          continue;
        }
        if (makeUpper) {
          result += ch.toUpperCase();
          makeUpper = false;
        } else {
          result += ch;
        }
      }
      return result;
    },

    ensureFieldAndColumn(baseGrid, { fieldName, colName, headerText, width = 110 }) {
      if (!baseGrid.fields.some(f => f.fieldName === fieldName)) {
        baseGrid.fields.push({ fieldName, dataType: 'number', valueType: 'number' });
      }
      if (!baseGrid.columns.some(c => c.name === colName)) {
        baseGrid.columns.push({
          name: colName,
          fieldName,
          width,
          header: { text: headerText },
          autoFilter: false,
          styleName: 'tr',
          numberFormat: '#,##0',
        });
      }
    },

    buildQtyRow(headerMeta, qtyRespRows) {
      const qtyMap = {};
      (qtyRespRows || []).forEach(r => {
        const modelRaw = r.model ?? r.MODEL ?? r['MODEL'];
        const key = this.convertModelToFieldId(modelRaw);
        qtyMap[key] = Number(r.qty || 0);
      });

      const row = { gubun: '매출수량' };

      headerMeta.forEach(m => {
        row[m.fieldId] = qtyMap[m.fieldId] ?? 0;
      });

      const yangsan = headerMeta.filter(x => String(x.gubun).trim() === '양산');
      const gaebal = headerMeta.filter(x => String(x.gubun).trim() === '개발');

      const sum = arr => arr.reduce((acc, m) => acc + Number(row[m.fieldId] || 0), 0);

      row.zMassTotal = sum(yangsan);
      row.zDevTotal = sum(gaebal);
      row.zTotal = row.zMassTotal + row.zDevTotal;

      return row;
    },

    remapAmountRows(rows, headerMeta) {
      return (rows || []).map(r => {
        const out = { ...r };

        headerMeta.forEach(m => {
          const rawKey = m.model;
          out[m.fieldId] = Number(r[rawKey] ?? 0);
        });

        out.zTotal = Number(r['Z합계'] ?? r['z합계'] ?? r['zTotal'] ?? 0);
        out.zDevTotal = Number(r['Z합계개발'] ?? r['z합계개발'] ?? r['zDevTotal'] ?? 0);
        out.zMassTotal = Number(r['Z합계양산'] ?? r['z합계양산'] ?? r['zMassTotal'] ?? 0);

        return out;
      });
    },

    normalizeAmountRows(rows, headerMeta) {
      const sumByGroup = (r, arr) =>
        arr.reduce((acc, m) => acc + Number(r[m.fieldId] || 0), 0);

      const yangsan = headerMeta.filter(x => x.gubun === '양산');
      const gaebal = headerMeta.filter(x => x.gubun === '개발');

      return (rows || []).map(r => {
        const out = { ...r };

        out.zTotal = Number(out.zTotal ?? 0);
        out.zMassTotal = Number(out.zMassTotal ?? 0);
        out.zDevTotal = Number(out.zDevTotal ?? 0);

        if ((!out.zMassTotal || isNaN(out.zMassTotal)) && yangsan.length) {
          out.zMassTotal = sumByGroup(out, yangsan);
        }
        if ((!out.zDevTotal || isNaN(out.zDevTotal)) && gaebal.length) {
          out.zDevTotal = sumByGroup(out, gaebal);
        }
        if ((!out.zTotal || isNaN(out.zTotal))) {
          out.zTotal = Number(out.zMassTotal || 0) + Number(out.zDevTotal || 0);
        }

        return out;
      });
    },

    async getDataList() {
      this.gridView.commit();

      const params = {
        yyyymm: this.params.yyyymm ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.params.site ? this.siteMap[this.params.site] : null,
      };

      const headerResp = await this.$axios.api.search({
        menuId: 'c0009000',
        queryId: 'C0009009_Col',
        queryParams: params,
        target: null,
      });

      const headerMetaRaw = (headerResp || []).map(item => {
        const modelRaw = item.model ?? item.MODEL ?? item['MODEL'];
        const gubunRaw = item.gubun ?? item['gubun'] ?? item.구분 ?? item['구분'];
        const model = String(modelRaw ?? '').trim();
        const gubun = String(gubunRaw ?? '').trim();
        const fieldId = this.convertModelToFieldId(model);
        return { model, gubun, fieldId };
      });

      const seen = new Set();
      const headerMeta = [];
      for (const m of headerMetaRaw) {
        if (!m.fieldId) continue;
        if (seen.has(m.fieldId)) continue;
        seen.add(m.fieldId);
        headerMeta.push(m);
      }

      const baseGrid = _.cloneDeep(require(`@web/c0009000/js/C0009009.js`));

      this.ensureFieldAndColumn(baseGrid, { fieldName: 'zTotal', colName: 'zTotal', headerText: '총합계' });
      this.ensureFieldAndColumn(baseGrid, { fieldName: 'zMassTotal', colName: 'zMassTotal', headerText: '양산합계' });
      this.ensureFieldAndColumn(baseGrid, { fieldName: 'zDevTotal', colName: 'zDevTotal', headerText: '개발합계' });

      headerMeta.forEach(m => {
        if (!baseGrid.fields.some(f => f.fieldName === m.fieldId)) {
          baseGrid.fields.push({ fieldName: m.fieldId, dataType: 'number', valueType: 'number' });
        }
        if (!baseGrid.columns.some(c => c.name === m.fieldId)) {
          baseGrid.columns.push({
            name: m.fieldId,
            fieldName: m.fieldId,
            width: 85,
            header: { text: m.model },
            autoFilter: false,
            styleName: 'tr',
            numberFormat: '#,##0',
          });
        }
      });

      this.gridDataProvider.setFields(baseGrid.fields);

      try { this.gridView.clearColumnLayout(); } catch (e) {}
      try { this.gridView.setColumnLayout([]); } catch (e) {}
      this.gridView.setColumns(baseGrid.columns);

      const yangsanModels = headerMeta.filter(x => x.gubun === '양산');
      const gaebalModels = headerMeta.filter(x => x.gubun === '개발');

      const layout = [
        { header: { text: '사업구분' }, items: [{ column: 'gubun', rowSpan: 2, header: { text: '제품명' } }] },
        { column: 'zTotal', rowSpan: 2, header: { text: '총합계' } },
        {
          header: { text: '합계' },
          items: [
            { column: 'zMassTotal', header: { text: '양산' } },
            { column: 'zDevTotal', header: { text: '개발' } },
          ],
        },
        { header: { text: '양산' }, items: yangsanModels.map(m => ({ column: m.fieldId })) },
        { header: { text: '개발' }, items: gaebalModels.map(m => ({ column: m.fieldId })) },
      ];

      this.gridView.setColumnLayout(layout);

      this.gridView.setCellStyleCallback(this.setCellStyleCallbackGrid.bind(this));
      this.gridView.setRowStyleCallback(this.setRowStyleCallbackGrid.bind(this));

      const amountResp = await this.$axios.api.search({
        menuId: 'c0009000',
        queryId: 'C0009009_Sch1',
        queryParams: params,
        target: null,
      });

      const qtyResp = await this.$axios.api.search({
        menuId: 'c0009000',
        queryId: 'C0009009_Qty',
        queryParams: params,
        target: null,
      });

      const qtyRow = this.buildQtyRow(headerMeta, qtyResp);

      const amountResp2 = this.remapAmountRows(amountResp, headerMeta);
      const amountRows = this.normalizeAmountRows(amountResp2, headerMeta);

      const finalRows = [qtyRow, ...amountRows];

      this.modelPlGridRows = finalRows;
      this.gridDataProvider.setRows(finalRows);

      console.log('amountResp', amountResp);
    },

    searchClick() {
      this.getDataList().catch(err => console.error(err));
    },

    async excelBtnClick() {
      const grid = this.gridView;
      if (!grid) return;

      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();
      const hh = String(now.getHours()).padStart(2, '0');
      const mm = String(now.getMinutes()).padStart(2, '0');
      const ss = String(now.getSeconds()).padStart(2, '0');

      const fileName = `제품별 손익계산서_${yyyymmdd}_${hh}${mm}${ss}.xlsx`;

      grid.exportGrid({
        type: 'excel',
        target: 'local',
        fileName,
        progressMessage: '엑셀 Export중입니다.',
        done: function () {
          alert('엑셀 내보내기가 완료되었습니다!');
        },
      });
    },
    setCellStyleCallbackGrid(grid, dataCell) {
      var ret = {};
      if (dataCell.dataColumn.name != 'gubun') {
        return ret;
      }
      var gubun = dataCell.value;
      if (this.$utils.containsValue(['  I. 매출액', '  II. 매출원가', '  III. 매출총이익', '  IV. 판매비와관리비', '  IV. 영업이익'], gubun)) {
        ret.style = { fontWeight: 'bold', whiteSpace: 'pre', backgroundColor: '#BFBFBF' };
      } else if (gubun === '매출수량') {
        ret.style = { fontWeight: 'bold', whiteSpace: 'pre', backgroundColor: '#fff3cd' };
      } else {
        ret.style = { fontWeight: 'normal', whiteSpace: 'pre' };
      }
      return ret;
    },
    setRowStyleCallbackGrid(grid, item, fixed) {
      var ret = {};
      var gubun = grid.getValue(item.index, 'gubun');
      if (this.$utils.containsValue(['  I. 매출액', '  II. 매출원가', '  III. 매출총이익', '  IV. 판매비와관리비', '  IV. 영업이익'], gubun)) {
        ret.style = { background: '#BFBFBF' };
      } else if (gubun === '매출수량') {
        ret.style = { background: '#fff3cd', fontWeight: 'bold' };
      }
      return ret;
    },
  },
};
</script>
