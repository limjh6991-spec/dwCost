<!-- 총 원가 -->
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
            <select class="form-select label-80" id="selCodeSelect" v-model="params.selCode">
              <option v-for="o in selCodeList" :key="o.value" :value="o.value">
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
        <div id="totalCostGrid" ref="totalCostGrid" class="top-border" style="height: 100%"></div>
      </div>
    </div>
  </div>
</template>

<script>
import { TreeView, LocalTreeDataProvider } from 'realgrid';
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0009000/js/C0009010.js';

let tcmTreeProvider, tcmTreeView;
export default {
  props: {},
  components: {},
  setup() {
    const srchInfo = useC0001001();
    const userAuthInfo = useUserAuthInfo();
    return {
      srchInfo,
      userAuthInfo,
    };
  },
  data() {
    return {
      totalCostGrid: null,
      totalCostGridRows: [],
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
      STRUCT_ORDER: ['UTG', 'ITG', 'HTG', 'Coated', '카세트', '상품'],
    };
  },
  watch: {
    'params.yyyymm': async function (newVal) {
      if (newVal) {
        this.onDateChange();
        await this.loadSelCodeList();
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
      async handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          await this.loadSelCodeList();

          if (this.$refs.totalCostGrid != null) {
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
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    },
  },
  created() {
    this.initialize();
    this.loadSelCodeList();
  },
  mounted() {
    this.initializeGrid();
  },
  beforeUnmount() {},

  methods: {
    initialize() {
      this.params.yyyymm = this.srchInfo.yyyymm;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },
    initializeGrid() {
      this.totalCostGrid = _.cloneDeep(gridField);

      tcmTreeProvider = new LocalTreeDataProvider(false);
      tcmTreeView = new TreeView(this.$refs.totalCostGrid);
      tcmTreeView.setDataSource(tcmTreeProvider);
      tcmTreeView.setOptions(this.totalCostGrid.options);
      tcmTreeView.treeOptions.expanderIconStyle = 'square';
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },

    // camelCase를 띄어쓰기로 분리하여 대문자로 변환
    camelToDisplay(str) {
      if (!str) return '';
      // camelCase → 띄어쓰기 분리 (uvResinCoating → UV RESIN COATING)
      return str
        .replace(/([a-z])([A-Z])/g, '$1 $2') // 소문자 뒤 대문자 앞에 공백
        .replace(/([A-Z]+)([A-Z][a-z])/g, '$1 $2') // 연속 대문자 분리
        .toUpperCase();
    },

    getModelMetaFromField(fieldId) {
      const raw = String(fieldId || '').trim();

      let s = raw;
      const prefixes = [/^양산/, /^개발/, /^카세트/, /^구매/];
      let changed = true;
      while (changed) {
        changed = false;
        for (const p of prefixes) {
          const next = s.replace(p, '');
          if (next !== s) {
            s = next;
            changed = true;
          }
        }
      }

      // camelCase를 띄어쓰기로 분리하여 표시
      let model = this.camelToDisplay(s);

      let bizGubun = '양산';
      if (raw.includes('카세트') || model.includes('카세트')) bizGubun = '카세트';
      else if (raw.includes('개발')) bizGubun = '개발';
      else if (raw.includes('구매')) bizGubun = '구매';

      model = model.replace(/^카세트+/, '');

      let structure = 'UTG';
      if (bizGubun === '카세트') structure = '카세트';
      else if (bizGubun === '구매') structure = '상품';
      else if (model.startsWith('I')) structure = 'ITG';
      else if (model.startsWith('H')) structure = 'HTG';
      else if (model.startsWith('C')) structure = 'Coated';

      return { bizGubun, structure, displayModel: model };
    },

    ensureField(gridDef, fieldName, dataType = 'number') {
      if (!gridDef.fields) gridDef.fields = [];
      if (!gridDef.fields.some((f) => f.fieldName === fieldName)) {
        gridDef.fields.push({
          fieldName,
          dataType,
          valueType: dataType,
        });
      }
    },

    ensureColumn(gridDef, col) {
      if (!gridDef.columns) gridDef.columns = [];
      if (!gridDef.columns.some((c) => c.name === col.name)) {
        gridDef.columns.push(col);
      }
    },

    groupBy(arr, key) {
      return (arr || []).reduce((acc, cur) => {
        const k = cur?.[key] ?? '기타';
        (acc[k] = acc[k] || []).push(cur);
        return acc;
      }, {});
    },

    buildGridColumnsFromResult(rows) {
      if (!rows || !rows.length) return;

      const first = rows[0];
      const keys = Object.keys(first);

      const ignore = new Set(['treeId', 'rn', 'gubun', '총합계', '양산합계', '개발합계', '카세트합계', '구매합계', '상품매출', '기타매출']);

      const modelKeys = keys.filter((k) => !ignore.has(k));

      const baseGrid = _.cloneDeep(this.totalCostGrid);

      this.ensureField(baseGrid, 'gubun', 'text');
      this.ensureColumn(baseGrid, {
        name: 'gubun',
        fieldName: 'gubun',
        width: 220,
        header: { text: '제품명' },
        styleName: 'tl',
      });

      [
        { k: '총합계', text: '총합계' },
        { k: '양산합계', text: '양산합계' },
        { k: '개발합계', text: '개발합계' },
        { k: '카세트합계', text: '카세트합계' },
        { k: '구매합계', text: '구매합계' },
      ].forEach(({ k, text }) => {
        if (!keys.includes(k)) return;
        this.ensureField(baseGrid, k, 'number');
        this.ensureColumn(baseGrid, {
          name: k,
          fieldName: k,
          header: { text },
          numberFormat: '#,##0',
          width: 80,
          styleName: 'tr',
        });
      });

      const headerMeta = modelKeys.map((fieldId) => {
        const m = this.getModelMetaFromField(fieldId);
        return {
          fieldId,
          ...m,
          sortNumeric: /^[0-9]/.test(m.displayModel) ? 0 : 1,

          sortStructure: m.structure === 'UTG' ? 1 : m.structure === 'ITG' ? 2 : m.structure === 'HTG' ? 3 : m.structure === 'Coated' ? 4 : m.structure === '카세트' ? 8 : m.structure === '상품' ? 9 : 9,
        };
      });

      const BIZ_ORDER = { 양산: 1, 개발: 2, 카세트: 3, 구매: 4 };

      headerMeta.sort((a, b) => {
        const bo = (BIZ_ORDER[a.bizGubun] ?? 9) - (BIZ_ORDER[b.bizGubun] ?? 9);
        if (bo !== 0) return bo;

        if (a.sortStructure !== b.sortStructure) return a.sortStructure - b.sortStructure;
        if (a.sortNumeric !== b.sortNumeric) return a.sortNumeric - b.sortNumeric;
        return a.displayModel.localeCompare(b.displayModel);
      });

      headerMeta.forEach((m) => {
        const fieldId = m.fieldId;

        this.ensureField(baseGrid, fieldId, 'number');
        this.ensureColumn(baseGrid, {
          name: fieldId,
          fieldName: fieldId,
          width: 110,
          numberFormat: '#,##0',
          styleName: 'tr',
          header: { text: m.displayModel },
        });
      });

      tcmTreeProvider.setFields(baseGrid.fields);
      tcmTreeView.setColumns(baseGrid.columns);

      const make2Depth = (biz) => {
        const list = headerMeta.filter((x) => x.bizGubun === biz);

        return this.STRUCT_ORDER.filter((structure) => list.some((x) => x.structure === structure)).map((structure) => {
          const models = list
            .filter((x) => x.structure === structure)
            .sort((a, b) => {
              if (a.sortNumeric !== b.sortNumeric) return a.sortNumeric - b.sortNumeric;
              return a.displayModel.localeCompare(b.displayModel);
            });

          return {
            header: { text: structure },
            items: models.map((m) => ({
              column: m.fieldId,
              header: { text: m.displayModel },
            })),
          };
        });
      };
      const layout = [
        {
          header: { text: '사업구분' },
          items: [
            {
              header: { text: '제품구분' },
              items: [
                {
                  column: 'gubun',
                  width: 200,
                  header: { text: '제품명' },
                  rowSpan: 3,
                },
              ],
            },
          ],
        },

        { column: '총합계', rowSpan: 3, header: { text: '총합계' } },
        { column: '양산합계', rowSpan: 3, header: { text: '양산합계' } },
        { column: '개발합계', rowSpan: 3, header: { text: '개발합계' } },
        { column: '카세트합계', rowSpan: 3, header: { text: '카세트합계' } },
        { column: '구매합계', rowSpan: 3, header: { text: '구매합계' } },

        { header: { text: '양산' }, items: make2Depth('양산') },
        { header: { text: '개발' }, items: make2Depth('개발') },
        { header: { text: '카세트' }, items: make2Depth('카세트') },
        { header: { text: '구매' }, items: make2Depth('구매') },
      ];

      tcmTreeView.setColumnLayout(layout);
      
      tcmTreeView.setCellStyleCallback(this.setCellStyleCallbackGrid.bind(this));
      tcmTreeView.setRowStyleCallback(this.setRowStyleCallbackGrid.bind(this));
    },

    async getDataList() {
      tcmTreeView.commit();

      if (!this.hasSysAdmin) {
        this.params.selCode = 'ACTUAL';
      }

      const params = {
        yyyymm: this.params.yyyymm?.replaceAll('-', ''),
        site: this.siteMap[this.params.site],
        selCode: this.params.selCode === '' ? 'ACTUAL' : this.params.selCode,
      };

      let resp = await this.$axios.api.search({
        menuId: 'c0009000',
        queryId: 'C0009010_Sch1',
        queryParams: params,
        target: this.totalCostGridRows,
      });
      this.buildGridColumnsFromResult(this.totalCostGridRows);
      tcmTreeProvider.setRows(this.totalCostGridRows, 'treeId');
      tcmTreeView.expandAll();
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

      const actual = this.selCodeList.find((x) => x.value === 'ACTUAL');

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
      const grid = tcmTreeView;

      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `총원가_${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

      const options = {
        type: 'excel',
        target: 'local',
        fileName,
        progressMessage: '엑셀 Export중입니다.',
        done: function () {
          alert('엑셀 내보내기가 완료되었습니다!');
        },
      };

      grid.exportGrid(options);
    },
    setCellStyleCallbackGrid(grid, dataCell) {
      var ret = {};
      if (dataCell.dataColumn.name != 'gubun') {
        return ret;
      }
      var gubun = dataCell?.value?.trim();
      if (/^M{0,3}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})\./.test(gubun)) {
        ret.style = { fontWeight: 'bold', whiteSpace: 'pre', backgroundColor: '#BFBFBF' };
      } else {
        ret.style = { fontWeight: 'normal', whiteSpace: 'pre' };
      }
      return ret;
    },
    setRowStyleCallbackGrid(grid, item, fixed) {
      var ret = {};
      var gubun = grid?.getValue(item.index, 'gubun')?.trim();
      if (/^M{0,3}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})\./.test(gubun)) {
        ret.style = { background: '#BFBFBF' };
      }
      return ret;
    },
  },
};
</script>
