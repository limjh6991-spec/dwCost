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
        <b-col cols="2">
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
        <RealGrid ref="totalCostGrid" :uid="'totalCostGrid'" :step="'1'" :rows="totalCostGridRows" :grid="totalCostGrid" style="height: 100%" :fitLayoutWidthEnable="false" />
      </div>
    </div>
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0009000/js/C0009010.js';

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
      STRUCT_ORDER: ['UTG', 'ITG', 'HTG', 'Coated', '카세트'],
    };
  },
  watch: {
        'params.yyyymm': async function(newVal) {
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
      }
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
        gridView() {
      return this.$refs.totalCostGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.totalCostGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    },
  },
  created() {
    this.initialize();
    this.initializeGrid();
    this.loadSelCodeList();
  },
  mounted() {},
  beforeUnmount() {},

  methods: {
    initialize() {
      this.params.yyyymm = this.srchInfo.yyyymm;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },
    initializeGrid() {
      this.totalCostGrid = _.cloneDeep(gridField);
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },

    getModelMetaFromField(fieldId) {
      const raw = String(fieldId || '').trim();

      // ✅ prefix(양산/개발/카세트)가 여러 번 붙는 케이스까지 반복 제거
      let s = raw;
      const prefixes = [/^양산/, /^개발/, /^카세트/];
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

      // 이제 s가 "진짜 모델명 후보"
      let model = String(s).toUpperCase();

      // ✅ 사업구분: raw에 카세트가 있으면 무조건 카세트로
      // (품명에 '카세트'가 들어가거나 pivot_key가 꼬여도 안전)
      let bizGubun = '양산';
      if (raw.includes('카세트') || model.includes('카세트')) bizGubun = '카세트';
      else if (raw.includes('개발')) bizGubun = '개발';

      // ✅ displayModel에서도 카세트 텍스트 제거(헤더 깔끔하게)
      model = model.replace(/^카세트+/, '');

      // ✅ 제품구분
      let structure = 'UTG';
      if (bizGubun === '카세트') structure = '카세트';
      else if (model.startsWith('I')) structure = 'ITG';
      else if (model.startsWith('H')) structure = 'HTG';
      else if (model.startsWith('C')) structure = 'Coated';

      return { bizGubun, structure, displayModel: model };
    },
    
    ensureField(gridDef, fieldName, dataType = 'number') {
      if (!gridDef.fields) gridDef.fields = [];
      if (!gridDef.fields.some(f => f.fieldName === fieldName)) {
        gridDef.fields.push({
          fieldName,
          dataType,       // 'number' | 'text'
          valueType: dataType,
        });
      }
    },

    ensureColumn(gridDef, col) {
      if (!gridDef.columns) gridDef.columns = [];
      if (!gridDef.columns.some(c => c.name === col.name)) {
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

      const ignore = new Set([
        'rn', 'gubun',
        '총합계', '양산합계', '개발합계', '카세트합계',
        '상품매출', '기타매출'
      ]);

      // ✅ 모델 컬럼 키들
      const modelKeys = keys.filter(k => !ignore.has(k));

      const baseGrid = _.cloneDeep(this.totalCostGrid);

      // ✅ gubun 필드/컬럼 보장(혹시 js에 없을까봐)
      this.ensureField(baseGrid, 'gubun', 'text');
      this.ensureColumn(baseGrid, {
        name: 'gubun',
        fieldName: 'gubun',
        width: 220,
        header: { text: '제품명' },
        styleName: 'tl',
      });

      // ✅ 합계 컬럼들
      [
        { k: '총합계', text: '총합계' },
        { k: '양산합계', text: '양산합계' },
        { k: '개발합계', text: '개발합계' },
        { k: '카세트합계', text: '카세트합계' },
      ].forEach(({ k, text }) => {
        if (!keys.includes(k)) return;
        this.ensureField(baseGrid, k, 'number');
        this.ensureColumn(baseGrid, {
          name: k,
          fieldName: k,
          header: { text },
          numberFormat: '#,##0',
          width: 90,
          styleName: 'tr',
        });
      });

      // =====================================================
      // ✅ 3뎁스 레이아웃: 사업구분(양산/개발/카세트) > 제품구분(제품구조) > 모델명
      // =====================================================
      const headerMeta = modelKeys.map(fieldId => {
        const m = this.getModelMetaFromField(fieldId);
        return { fieldId, ...m,    
        sortNumeric: /^[0-9]/.test(m.displayModel) ? 0 : 1,
        // 구조 정렬
        sortStructure:
          m.structure === 'UTG' ? 1 :
          m.structure === 'ITG' ? 2 :
          m.structure === 'HTG' ? 3 :
          m.structure === 'Coated' ? 4 :
          m.structure === '카세트' ? 9 : 9, };
      });

      const BIZ_ORDER = { '양산': 1, '개발': 2, '카세트': 3 };

      headerMeta.sort((a, b) => {
        const bo = (BIZ_ORDER[a.bizGubun] ?? 9) - (BIZ_ORDER[b.bizGubun] ?? 9);
        if (bo !== 0) return bo;

        if (a.sortStructure !== b.sortStructure) return a.sortStructure - b.sortStructure;
        if (a.sortNumeric !== b.sortNumeric) return a.sortNumeric - b.sortNumeric;
        return a.displayModel.localeCompare(b.displayModel);
      });

      // ✅ 모델 컬럼들 추가
      headerMeta.forEach(m => {
        const fieldId = m.fieldId;

        this.ensureField(baseGrid, fieldId, 'number');
        this.ensureColumn(baseGrid, {
          name: fieldId,
          fieldName: fieldId,
          width: 130,
          numberFormat: '#,##0',
          styleName: 'tr',
          header: { text: m.displayModel },
        });
      });

      // ✅ 여기까지 만든 columns/fields를 실제 그리드에 반영!
      this.gridDataProvider.setFields(baseGrid.fields);
      this.gridView.setColumns(baseGrid.columns);

      const make2Depth = (biz) => {
        const list = headerMeta.filter(x => x.bizGubun === biz);

        return this.STRUCT_ORDER
          .filter(structure => list.some(x => x.structure === structure))
          .map(structure => {
            const models = list
              .filter(x => x.structure === structure)
              .sort((a, b) => {
                if (a.sortNumeric !== b.sortNumeric) return a.sortNumeric - b.sortNumeric;
                return a.displayModel.localeCompare(b.displayModel);
              });

            return {
              header: { text: structure },
              items: models.map(m => ({
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

        { header: { text: '양산' }, items: make2Depth('양산') },
        { header: { text: '개발' }, items: make2Depth('개발') },
        { header: { text: '카세트' }, items: make2Depth('카세트') },
      ];

      this.gridView.setColumnLayout(layout);

      this.gridView.setCellStyleCallback(this.setCellStyleCallbackGrid.bind(this));
      this.gridView.setRowStyleCallback(this.setRowStyleCallbackGrid.bind(this));
    },

    async getDataList() {
      this.gridView.commit();

      const params = {
        yyyymm: this.params.yyyymm?.replaceAll('-', ''),
        site: this.siteMap[this.params.site],
        selCode: this.params.selCode,
      };

      console.log("params", {
        yyyymm: this.params.yyyymm?.replaceAll('-', ''),
        site: this.siteMap[this.params.site],
        selCode: this.params.selCode,
      });

      await this.$axios.api.search({
        menuId: 'c0009000',
        queryId: 'C0009010_Sch1',
        queryParams: params,
        target: this.totalCostGridRows,
      });

      this.buildGridColumnsFromResult(this.totalCostGridRows);
      this.gridDataProvider.setRows(this.totalCostGridRows);
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
      const grid = this.gridView;

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
      var gubun = dataCell.value;
      if (this.$utils.containsValue(['  I. 매출액', '  II. 재료비', '  III. 노무비', '  IV. 제조경비', '  V. 재고조정', '  VI. 판관비', '  VII. 총원가', '  VIII. 영업이익', '  IX. 한계이익', '  X. 손익분기점'], gubun)) {
        ret.style = { fontWeight: 'bold', whiteSpace: 'pre', backgroundColor: '#BFBFBF' };
      } else {
        ret.style = { fontWeight: 'normal', whiteSpace: 'pre' };
      }
      return ret;
    },
    setRowStyleCallbackGrid(grid, item, fixed) {
      var ret = {};
      var gubun = grid.getValue(item.index, 'gubun');
      if (this.$utils.containsValue(['  I. 매출액', '  II. 재료비', '  III. 노무비', '  IV. 제조경비', '  V. 재고조정', '  VI. 판관비', '  VII. 총원가', '  VIII. 영업이익', '  IX. 한계이익', '  X. 손익분기점'], gubun)) {
        ret.style = { background: '#BFBFBF' };
      }
      return ret;
    },
  }
};
</script>