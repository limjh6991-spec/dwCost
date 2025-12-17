<!-- 제품별 손익계산서 -->
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

    makeProcModelKey(model) {
      const m = String(model ?? '').trim();
      if (!m) return '';

      const cleaned = m.replace(/[^\w\sㄱ-힣]/g, ' ').trim();
      if (!cleaned) return '';

      const parts = cleaned.split(/\s+/).filter(Boolean);
      if (!parts.length) return '';

      const first = parts[0].toLowerCase();
      const rest = parts.slice(1).map(p => {
        const low = p.toLowerCase();
        return low ? low[0].toUpperCase() + low.slice(1) : '';
      });

      return first + rest.join('');
    },

    makeFieldId(pivotKey) {
      const s = String(pivotKey ?? '').trim();
      if (!s) return '';
      return (
        'COL_' +
        s
          .replace(/\s+/g, '_')
          .replace(/[^\wㄱ-힣]/g, '_')
      );
    },

    ensureField(gridDef, fieldName, dataType = 'number') {
      if (!gridDef.fields) gridDef.fields = [];
      if (!gridDef.fields.some(f => f.fieldName === fieldName)) {
        gridDef.fields.push({ fieldName, dataType, valueType: dataType });
      }
    },
    ensureColumn(gridDef, col) {
      if (!gridDef.columns) gridDef.columns = [];
      if (!gridDef.columns.some(c => c.name === col.name)) {
        gridDef.columns.push(col);
      }
    },

    buildDisplayMapFromQty(qtyRows) {
      const map = {};
      (qtyRows || []).forEach(r => {
        const modelRaw = r.model ?? r.MODEL ?? r['MODEL'];
        const model = String(modelRaw ?? '').trim();
        if (!model) return;

        const procKey = this.makeProcModelKey(model);
        if (!procKey) return;

        if (!map[procKey] || String(map[procKey]).length < model.length) {
          map[procKey] = model;
        }
      });
      return map;
    },

    formatDisplayModel(model) {
      const s = String(model ?? '').trim().replace(/\s+/g, ' ');
      return s.toUpperCase();
    },

    buildHeaderMetaFromSch1(amountRows, displayMap) {
      const first = amountRows?.[0];
      if (!first) return [];

      const ignore = new Set([
        'rn', 'gubun',
        'z합계', 'zTotal',
        '개발z합계개발', 'z합계개발', 'zDevTotal',
        '양산z합계양산', 'z합계양산', 'zMassTotal',
      ]);

      return Object.keys(first)
        .filter(k => !ignore.has(k))
        .map(pivotKey => {
          const gubun = pivotKey.startsWith('개발') ? '개발' : '양산';
          const procModelKey = pivotKey.replace(/^개발|^양산/, '');
          const raw = displayMap?.[procModelKey] ?? procModelKey;
          const displayModel = this.formatDisplayModel(raw);

          return {
            pivotKey,
            gubun,
            procModelKey,
            model: displayModel,
            fieldId: this.makeFieldId(pivotKey),
          };
        });
    },

    buildQtyRow(headerMeta, qtyRespRows) {
      const qtyMap = {};
      (qtyRespRows || []).forEach(r => {
        const gubunRaw = r.구분 ?? r.gubun ?? r['gubun'] ?? r['구분'];
        const modelRaw = r.model ?? r.MODEL ?? r['MODEL'];

        const gubun = String(gubunRaw ?? '').trim();
        const model = String(modelRaw ?? '').trim();

        const procKey = this.makeProcModelKey(model);
        if (!gubun || !procKey) return;

        const pivotKey = `${gubun}${procKey}`;
        qtyMap[pivotKey] = Number(r.qty || 0);
      });

      const row = { gubun: '매출수량' };
      headerMeta.forEach(m => {
        row[m.fieldId] = qtyMap[m.pivotKey] ?? 0;
      });

      const sum = g =>
        headerMeta
          .filter(x => x.gubun === g)
          .reduce((acc, m) => acc + Number(row[m.fieldId] || 0), 0);

      row.zMassTotal = sum('양산');
      row.zDevTotal = sum('개발');
      row.zTotal = row.zMassTotal + row.zDevTotal;

      return row;
    },

    remapAmountRows(amountRows, headerMeta) {
      return (amountRows || []).map(r => {
        const o = { ...r };

        headerMeta.forEach(m => {
          o[m.fieldId] = Number(r[m.pivotKey] ?? 0);
        });

        o.zTotal = Number(r['z합계'] ?? r['Z합계'] ?? 0);
        o.zDevTotal = Number(r['개발z합계개발'] ?? r['Z합계개발'] ?? 0);
        o.zMassTotal = Number(r['양산z합계양산'] ?? r['Z합계양산'] ?? 0);

        return o;
      });
    },

    async getDataList() {
      this.gridView.commit();

      const params = {
        yyyymm: this.params.yyyymm?.replaceAll('-',''),
        site: this.siteMap[this.params.site]
      };

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

      const displayMap = this.buildDisplayMapFromQty(qtyResp);
      const headerMeta = this.buildHeaderMetaFromSch1(amountResp, displayMap);
      const baseGrid = _.cloneDeep(require(`@web/c0009000/js/C0009009.js`));
      [
        { k:'zTotal',     text:'총합계' },
        { k:'zMassTotal', text:'양산합계' },
        { k:'zDevTotal',  text:'개발합계' },
      ].forEach(({k,text}) => {
        this.ensureField(baseGrid, k, 'number');
        this.ensureColumn(baseGrid, {
          name: k,
          fieldName: k,
          header: { text },
          numberFormat: '#,##0',
          width: 110,
          styleName: 'tr',
        });
      });

      headerMeta.forEach(m => {
        this.ensureField(baseGrid, m.fieldId, 'number');
        this.ensureColumn(baseGrid, {
          name: m.fieldId,
          fieldName: m.fieldId,
          header: { text: m.model },
          numberFormat: '#,##0',
          width: 85,
          styleName: 'tr',
        });
      });

      this.gridDataProvider.setFields(baseGrid.fields);
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

      const qtyRow = this.buildQtyRow(headerMeta, qtyResp);
      const amountRows = this.remapAmountRows(amountResp, headerMeta);

      const finalRows = [qtyRow, ...amountRows];

      this.modelPlGridRows = finalRows;
      this.gridDataProvider.setRows(finalRows);
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
      if (this.$utils.containsValue(['  I. 매출액', '  II. 매출원가', '  III. 매출총이익', '  IV. 판매비와관리비', '  V. 영업이익'], gubun)) {
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
      if (this.$utils.containsValue(['  I. 매출액', '  II. 매출원가', '  III. 매출총이익', '  IV. 판매비와관리비', '  V. 영업이익'], gubun)) {
        ret.style = { background: '#BFBFBF' };
      } else if (gubun === '매출수량') {
        ret.style = { background: '#fff3cd', fontWeight: 'bold' };
      }
      return ret;
    },
  },
};
</script>
