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
        <RealGrid ref="totalCostGrid" :uid="'totalCostGrid'" :step="'1'" :rows="totalCostGridRows" :grid="totalCostGrid" style="height: 100%" />
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
      }
     },
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
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
      // fieldId 예: '양산ABC123', '개발XYZ9D', 'VNX100'
      let raw = String(fieldId || '').trim();

      // 1) prefix 제거 후 "진짜 모델명"만
      let model = raw.replace(/^양산/, '').replace(/^개발/, '').toUpperCase();

      // 2) 사업구분(3가지) - 카세트가 최우선!
      let bizGubun = '양산';
      if (model.startsWith('VN')) bizGubun = '카세트';
      else if (raw.startsWith('개발')) bizGubun = '개발';

      // 3) 제품구분(제품구조)
      let structure = 'UTG';
      if (model.startsWith('VN')) structure = '카세트';
      else if (model.startsWith('I')) structure = 'ITG';
      else if (model.startsWith('H')) structure = 'HTG';
      else if (model.startsWith('C')) structure = 'Coated';

      return {
        bizGubun,          // ✅ 양산/개발/카세트 (3가지)
        structure,         // ✅ UTG/ITG/HTG/Coated/카세트
        displayModel: model,
      };
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
          width: 110,
          styleName: 'tr',
        });
      });

      // ✅ 모델 컬럼들 추가
      modelKeys.forEach(fieldId => {
        const meta = this.getModelMetaFromField(fieldId); // bizGubun/structure/displayModel

        this.ensureField(baseGrid, fieldId, 'number');
        this.ensureColumn(baseGrid, {
          name: fieldId,
          fieldName: fieldId,
          width: 110,
          numberFormat: '#,##0',
          styleName: 'tr',
          // 여기 header.text는 layout에서 덮이지만, 안전장치로 둠
          header: { text: meta.displayModel },
        });
      });

      // ✅ 여기까지 만든 columns/fields를 실제 그리드에 반영!
      this.gridDataProvider.setFields(baseGrid.fields);
      this.gridView.setColumns(baseGrid.columns);

      // =====================================================
      // ✅ 3뎁스 레이아웃: 사업구분(양산/개발/카세트) > 제품구분(제품구조) > 모델명
      // =====================================================
      const headerMeta = modelKeys.map(fieldId => {
        const m = this.getModelMetaFromField(fieldId);
        return { fieldId, ...m };
      });

      const make2Depth = (biz) => {
        const list = headerMeta.filter(x => x.bizGubun === biz);
        const groups = this.groupBy(list, 'structure');

        return Object.entries(groups).map(([structure, models]) => ({
          header: { text: structure }, // ✅ 제품구분(제품구조)
          items: models.map(m => ({
            column: m.fieldId,
            header: { text: m.displayModel }, // ✅ 모델명(대문자 모델만)
          })),
        }));
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
      };

      await this.$axios.api.search({
        menuId: 'c0009000',
        queryId: 'C0009010_Sch1',
        queryParams: params,
        target: this.totalCostGridRows,
      });

      this.buildGridColumnsFromResult(this.totalCostGridRows);
      this.gridDataProvider.setRows(this.totalCostGridRows);
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