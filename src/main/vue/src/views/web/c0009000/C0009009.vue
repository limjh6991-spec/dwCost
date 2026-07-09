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
        <b-col cols="2" class="ms-3" v-if="showCurrencySelect">
          <div class="form-floating">
            <select class="form-select label-60" id="currencySelect" :value="currency" @change="onCurrencyChange($event.target.value)">
              <option value="USD">USD</option>
              <option value="KRW">KRW</option>
              <option value="VND">VND</option>
            </select>
            <label for="currencySelect">통화</label>
          </div>
        </b-col>
        <b-col cols="3" class="ms-2 d-flex align-items-center" v-if="showCurrencySelect">
          <b-button class="second" size="sm" @click="openExchangeRate">환율관리</b-button>
          <span class="ms-2 text-primary" style="font-size: 12px">{{ appliedRateLabel }}</span>
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
        <div id="modelPlTree" ref="modelPlTree" class="top-border" style="height: 100%"></div>
      </div>
    </div>
    <ExchangeRatePopup ref="exchangeRatePopup" @closePopup="onExchangeRateClosed" />
  </div>
</template>

<script>
import { TreeView, LocalTreeDataProvider } from 'realgrid';
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import { applyAmtFormatLive } from '@/utils/gridUtils';
import currencyConvert from '@web/c0007000/js/currencyConvert.js';
import ExchangeRatePopup from '@/components/ExchangeRatePopup.vue';
import gridField from '@web/c0009000/js/C0009009.js';

let modelPlTreeProvider, modelPlTreeView;

export default {
  mixins: [currencyConvert],
  components: { ExchangeRatePopup },
  setup() {
    const srchInfo = useC0001001();
    const userAuthInfo = useUserAuthInfo();
    return { srchInfo, userAuthInfo };
  },

  data() {
    return {
      modelPlGrid: null,
      modelPlGridRows: [],
      selCodeList: [],

      params: {
        yyyymm: null,
        site: 'HQ',
        selCode : '',
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
    'params.yyyymm'(newVal) {
      if (newVal) this.onDateChange();
    },
    
    prodCtg: {
      handler(newVal) {
        if (!newVal) return;
        this.params.site = newVal === 'VN' ? 'VINA' : '본사';
        if (this.$refs.modelPlTree) {
          this.initialize();
          this.searchClick();
        }
      },
    },
  },

  computed: {
    hasSysAdmin() {
      const roleList = this.userAuthInfo?.roleList || [];
      return roleList.includes('SYSADMIN');
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    },
  },

  created() {
    this.initialize();
  },

  mounted() {
    this.initializeGrid();
  },

  methods: {
    initialize() {
      this.params.yyyymm = this.srchInfo.yyyymm;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
      this.loadSelCodeList();
    },

    initializeGrid() {
      this.modelPlGrid = _.cloneDeep(gridField);

      modelPlTreeProvider = new LocalTreeDataProvider(false);
      modelPlTreeView = new TreeView(this.$refs.modelPlTree);
      modelPlTreeView.setDataSource(modelPlTreeProvider);
      modelPlTreeView.setOptions(this.modelPlGrid.options);
      modelPlTreeView.treeOptions.expanderIconStyle = 'square';
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

        // 소문자 키로 저장하여 대소문자 무관하게 매칭
        const lowerKey = procKey.toLowerCase();
        if (!map[lowerKey] || String(map[lowerKey]).length < model.length) {
          map[lowerKey] = model;
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
        'z합계', 'zTotal', 'Z합계',
        '개발z합계개발', '개발Z합계개발', 'z합계개발', 'Z합계개발', 'zDevTotal',
        '양산z합계양산', '양산Z합계양산', 'z합계양산', 'Z합계양산', 'zMassTotal',
        '카세트z합계카세트', '카세트Z합계카세트', 'z합계카세트', 'Z합계카세트', 'zCassetteTotal',
        '구매z합계구매', '구매Z합계구매', 'z합계구매', 'Z합계구매', 'zPurchaseTotal',
      ]);

      return Object.keys(first)
        .filter(k => !ignore.has(k))
        .map(pivotKey => {
          let gubun = '양산';
          if (pivotKey.startsWith('개발')) gubun = '개발';
          else if (pivotKey.startsWith('카세트')) gubun = '카세트';
          else if (pivotKey.startsWith('구매')) gubun = '구매';
          const procModelKey = pivotKey.replace(/^개발|^양산|^카세트|^구매/, '');
          // 소문자로 변환하여 displayMap에서 조회 (대소문자 무관 매칭)
          const lowerKey = procModelKey.toLowerCase();
          const raw = displayMap?.[lowerKey] ?? procModelKey;
          const displayModel = this.formatDisplayModel(raw);

          return {
            pivotKey,
            gubun,
            procModelKey: lowerKey,
            model: displayModel,
            fieldId: this.makeFieldId(pivotKey),
          };
        });
    },

    buildQtyRow(headerMeta, qtyRespRows) {
      // procModelKey 기준으로 수량 매핑 (구분 값 불일치 문제 해결)
      const qtyMap = {};
      (qtyRespRows || []).forEach(r => {
        const modelRaw = r.model ?? r.MODEL ?? r['MODEL'];
        const model = String(modelRaw ?? '').trim();

        const procKey = this.makeProcModelKey(model);
        if (!procKey) return;

        // 소문자 키로 저장하여 headerMeta.procModelKey와 매칭
        const lowerKey = procKey.toLowerCase();
        qtyMap[lowerKey] = (qtyMap[lowerKey] || 0) + Number(r.qty || 0);
      });

      const row = { gubun: '매출수량' };
      headerMeta.forEach(m => {
        // procModelKey로 매칭 (이미 lowercase)
        row[m.fieldId] = qtyMap[m.procModelKey] ?? 0;
      });

      const sum = g =>
        headerMeta
          .filter(x => x.gubun === g)
          .reduce((acc, m) => acc + Number(row[m.fieldId] || 0), 0);

      row.zMassTotal = sum('양산');
      row.zDevTotal = sum('개발');
      row.zCassetteTotal = sum('카세트');
      row.zPurchaseTotal = sum('구매');
      row.zTotal = row.zMassTotal + row.zDevTotal + row.zCassetteTotal + row.zPurchaseTotal;

      return row;
    },

    remapAmountRows(amountRows, headerMeta) {
      return (amountRows || []).map(r => {
        const o = { ...r };

        headerMeta.forEach(m => {
          o[m.fieldId] = Number(r[m.pivotKey] ?? 0);
        });

        o.zTotal = Number(r['z합계'] ?? r['Z합계'] ?? 0);
        o.zDevTotal = Number(r['개발z합계개발'] ?? r['개발Z합계개발'] ?? r['Z합계개발'] ?? 0);
        o.zMassTotal = Number(r['양산z합계양산'] ?? r['양산Z합계양산'] ?? r['Z합계양산'] ?? 0);
        o.zCassetteTotal = Number(r['카세트z합계카세트'] ?? r['카세트Z합계카세트'] ?? r['Z합계카세트'] ?? 0);
        o.zPurchaseTotal = Number(r['구매z합계구매'] ?? r['구매Z합계구매'] ?? r['Z합계구매'] ?? 0);

        return o;
      });
    },

    buildTreeRows(rows) {
      let topIndex = 0;
      let currentTopId = '';
      let childIndex = 0;

      return (rows || []).map(r => {
        const row = { ...r };
        const gubun = String(row.gubun ?? '').trim();

        if (gubun === '매출수량') {
          row.treeId = '0';
          return row;
        }

        const isTop = /^([IVXLCDM]+)\./.test(gubun);
        const isChild = /^\(\d+\)/.test(gubun) || /^\d+\./.test(gubun);

        if (isTop) {
          topIndex += 1;
          currentTopId = String(topIndex);
          childIndex = 0;
          row.treeId = currentTopId;
        } else if (isChild && currentTopId) {
          childIndex += 1;
          row.treeId = `${currentTopId}.${childIndex}`;
        } else {
          if (currentTopId) {
            childIndex += 1;
            row.treeId = `${currentTopId}.${childIndex}`;
          } else {
            topIndex += 1;
            currentTopId = String(topIndex);
            childIndex = 0;
            row.treeId = currentTopId;
          }
        }

        return row;
      });
    },

    collapseGubun(targetLabel) {
      const grid = modelPlTreeView;
      const count = typeof grid?.getItemCount === 'function' ? grid.getItemCount() : 0;

      for (let i = 0; i < count; i += 1) {
        const gubun = grid.getValue(i, 'gubun')?.trim();
        if (gubun === targetLabel) {
          if (typeof grid.collapse === 'function') {
            grid.collapse(i, true);
          } else if (typeof grid.setExpanded === 'function') {
            grid.setExpanded(i, false, true);
          }
          break;
        }
      }
    },

    async getDataList() {
      modelPlTreeView.commit();

      if (!this.hasSysAdmin) {
        this.params.selCode = 'ACTUAL';
      }

      const params = {
        yyyymm: this.params.yyyymm?.replaceAll('-',''),
        site: this.siteMap[this.params.site],
        selCode: this.params.selCode === '' ? 'ACTUAL' : this.params.selCode
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
      const baseGrid = _.cloneDeep(gridField);

      this.ensureField(baseGrid, 'treeId', 'text');
      this.ensureColumn(baseGrid, {
        name: 'treeId',
        fieldName: 'treeId',
        width: 0,
        visible: false,
      });
      [
        { k:'zTotal',     text:'총합계' },
        { k:'zMassTotal', text:'양산합계' },
        { k:'zDevTotal',  text:'개발합계' },
        { k:'zCassetteTotal', text:'카세트' },
        { k:'zPurchaseTotal', text:'구매' },
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
          width: 110,
          styleName: 'tr',
        });
      });

      modelPlTreeProvider.setFields(baseGrid.fields);
      modelPlTreeView.setColumns(baseGrid.columns);

      const sortByModel = (a, b) => a.model.localeCompare(b.model, undefined, { sensitivity: 'base' });
      const yangsanModels = headerMeta.filter(x => x.gubun === '양산').sort(sortByModel);
      const gaebalModels = headerMeta.filter(x => x.gubun === '개발').sort(sortByModel);
      const cassetteModels = headerMeta.filter(x => x.gubun === '카세트').sort(sortByModel);
      const purchaseModels = headerMeta.filter(x => x.gubun === '구매').sort(sortByModel);

      const layout = [
        { header: { text: '사업구분' }, items: [{ column: 'gubun', width: 280, rowSpan: 2, header: { text: '제품명' } }] },
        { column: 'zTotal', rowSpan: 2, header: { text: '총합계' } },
        {
          header: { text: '합계' },
          items: [
            { column: 'zMassTotal', header: { text: '양산' } },
            { column: 'zDevTotal', header: { text: '개발' } },
            { column: 'zCassetteTotal', header: { text: '카세트' } },
            { column: 'zPurchaseTotal', header: { text: '구매' } },
          ],
        },
        { header: { text: '양산' }, items: yangsanModels.map(m => ({ column: m.fieldId })) },
        { header: { text: '개발' }, items: gaebalModels.map(m => ({ column: m.fieldId })) },
        { header: { text: '카세트' }, items: cassetteModels.map(m => ({ column: m.fieldId })) },
        { header: { text: '구매' }, items: purchaseModels.map(m => ({ column: m.fieldId })) },
      ];

      modelPlTreeView.setColumnLayout(layout);

      modelPlTreeView.setCellStyleCallback(this.setCellStyleCallbackGrid.bind(this));
      modelPlTreeView.setRowStyleCallback(this.setRowStyleCallbackGrid.bind(this));

      applyAmtFormatLive(modelPlTreeView, this.userAuthInfo.curProdCtg, this.currency);

      const qtyRow = this.buildQtyRow(headerMeta, qtyResp);
      let amountRows = this.remapAmountRows(amountResp, headerMeta);
      // VINA·비USD: 금액행만 월평균 환율로 환산(수량행 '매출수량'은 원본 유지)
      this.currencyFields = baseGrid.columns.filter((c) => c.numberFormat).map((c) => c.fieldName);
      amountRows = await this.buildCurrencyRows(amountRows);

      const finalRows = this.buildTreeRows([qtyRow, ...amountRows]);

      this.modelPlGridRows = finalRows;
      modelPlTreeProvider.setRows(finalRows, 'treeId');
      modelPlTreeView.expandAll();
      this.collapseGubun('IV. 판매비와관리비');
    },

    onCurrencyChange(currency) {
      this.setCurrency(currency);
      this.searchClick();
    },
    openExchangeRate() {
      this.$refs.exchangeRatePopup.openDialog({ yyyymm: this.params.yyyymm });
    },
    onExchangeRateClosed() {
      if (this.isCurrencyReadonly) this.searchClick();
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
      this.getDataList().catch(err => console.error(err));
    },

    async excelBtnClick() {
      const grid = modelPlTreeView;
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
        // 매출수량 행은 수량 → VINA·USD 2자리 적용 제외(정수 표시)
        const r = dataCell.index.dataRow;
        if (r >= 0 && String(grid.getValue(r, 'gubun') ?? '').trim() === '매출수량') {
          ret.numberFormat = '#,##0';
        }
        return ret;
      }
      var gubun = String(dataCell.value ?? '').trim();
      if (/^M{0,3}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})\./.test(gubun)) {
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
      var gubun = String(grid.getValue(item.index, 'gubun') ?? '').trim();
      if (/^M{0,3}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})\./.test(gubun)) {
        ret.style = { background: '#BFBFBF' };
      } else if (gubun === '매출수량') {
        ret.style = { background: '#fff3cd', fontWeight: 'bold' };
      }
      return ret;
    },
  },
};
</script>
