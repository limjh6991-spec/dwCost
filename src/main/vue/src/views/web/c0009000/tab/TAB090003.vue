/** * 생산실적 > 년간 전체 실적 집계 */
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="1" class="period">
          <div class="form-floating me-1">
            <date-picker label="기준년도" mode="year" v-model="params.yyyy" />
            <label for="floatingSelect" class="select">기준년도</label>
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
        <RealGrid ref="prodSubulGrid" :uid="'prodSubulGrid'" :step="'1'" :rows="prodSubulGridRows" style="height: 100%" />
      </div>
    </div>
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0009000/js/TAB090003.js';

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
      prodSubulGrid: null,
      prodSubulGridRows: [],
      params: {
        yyyy: null,
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
    'params.yyyy': function (newVal) {
      if (newVal) {
        this.onDateChange();
      }
    },
    'srchInfo.yyyymm': {
      handler(newVal) {
        if (newVal && !this.params.yyyy) {
          // YYYYMM에서 YYYY만 추출
          this.params.yyyy = newVal.substring(0, 4);
        }
      },
    },
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          if (this.$refs.prodSubulGrid != null) {
            this.initialize();
            this.searchClick();
          }
        }
      },
    },
  },
  computed: {
    gridView() {
      return this.$refs.prodSubulGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.prodSubulGrid.getGridDataProvider();
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
      const curMonth = this.srchInfo.yyyymm;
      this.params.yyyy = curMonth ? curMonth.substring(0, 4) : new Date().getFullYear().toString();
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },
    initializeGrid() {
      this.prodSubulGrid = _.cloneDeep(gridField);
    },
    onDateChange() {
      // 년도 변경시 별도 처리 불필요
    },
    async getDataList() {
      this.gridView.commit();

      let params = {
        yyyy: this.params.yyyy,
        site: this.params.site != null ? this.siteMap[this.params.site] : null,
      };

      const gridField1 = _.cloneDeep(require(`@web/c0009000/js/TAB090003.js`));
      const yy = this.params.yyyy.substring(2, 4) + '년';

      var headerSummaryCallback = [
        {
          valueCallback: function (grid, column, childIndex, summary, value) {
            var sum = 0;
            let dataProvider = grid.getDataSource();
            for (var i = 0; i < dataProvider.getRowCount(); i++) {
              if (dataProvider.getValue(i, 'gubun') == '기초(BOH)') {
                sum += dataProvider.getValue(i, summary.column.fieldName);
              }
            }
            return sum;
          },
          numberFormat: '#,##0.##',
        },
        {
          valueCallback: function (grid, column, childIndex, summary, value) {
            var sum = 0;
            let dataProvider = grid.getDataSource();
            for (var i = 0; i < dataProvider.getRowCount(); i++) {
              if (dataProvider.getValue(i, 'gubun') == '투입(IN)') {
                sum += dataProvider.getValue(i, summary.column.fieldName);
              }
            }
            return sum;
          },
          numberFormat: '#,##0.##',
        },
        {
          valueCallback: function (grid, column, childIndex, summary, value) {
            var sum = 0;
            let dataProvider = grid.getDataSource();
            for (var i = 0; i < dataProvider.getRowCount(); i++) {
              if (dataProvider.getValue(i, 'gubun') == '출고(OUT)') {
                sum += dataProvider.getValue(i, summary.column.fieldName);
              }
            }
            return sum;
          },
          numberFormat: '#,##0.##',
        },
        {
          valueCallback: function (grid, column, childIndex, summary, value) {
            var sum = 0;
            let dataProvider = grid.getDataSource();
            for (var i = 0; i < dataProvider.getRowCount(); i++) {
              if (dataProvider.getValue(i, 'gubun') == '재고(EOH)') {
                sum += dataProvider.getValue(i, summary.column.fieldName);
              }
            }
            return sum;
          },
          numberFormat: '#,##0.##',
        },
        {
          valueCallback: function (grid, column, childIndex, summary, value) {
            var sum = 0;
            let dataProvider = grid.getDataSource();
            for (var i = 0; i < dataProvider.getRowCount(); i++) {
              if (dataProvider.getValue(i, 'gubun') == '기타(LOSS)') {
                sum += dataProvider.getValue(i, summary.column.fieldName);
              }
            }
            return sum;
          },
          numberFormat: '#,##0.##',
        },
        {
          valueCallback: function (grid, column, childIndex, summary, value) {
            var sum1 = 0;
            var sum2 = 0;
            var sum3 = 0;
            let dataProvider = grid.getDataSource();
            for (var i = 0; i < dataProvider.getRowCount(); i++) {
              if (dataProvider.getValue(i, 'gubun') == '기초(BOH)') {
                sum1 += dataProvider.getValue(i, summary.column.fieldName);
              }
              if (dataProvider.getValue(i, 'gubun') == '투입(IN)') {
                sum2 += dataProvider.getValue(i, summary.column.fieldName);
              }
              if (dataProvider.getValue(i, 'gubun') == '기타(LOSS)') {
                sum3 += dataProvider.getValue(i, summary.column.fieldName);
              }
            }
            return sum3 == 0 ? 0 : ((sum1 + sum2) / sum3).toFixed(2);
          },
          numberFormat: '#,##0.##',
        },
      ];

      gridField1.fields.push({
        fieldName: yy,
        valueType: 'number',
        dataType: 'number',
      });

      gridField1.columns.push({
        name: yy,
        fieldName: yy,
        width: 80,
        header: {
          text: yy + '누계',
        },
        autoFilter: false,
        numberFormat: '#,##0.##',
        styleName: 'tr',
        headerSummary: headerSummaryCallback,
      });

      gridField1.layout.push(yy);

      this.gridDataProvider.setFields(gridField1.fields);
      this.gridView.setColumns(gridField1.columns);
      this.gridView.setColumnLayout(gridField1.layout);

      let param = {
        menuId: 'c0009000',
        queryId: 'C0009001_Tab090003',
        queryParams: params,
        target: this.prodSubulGridRows,
      };
      let resp = await this.$axios.api.search(param);

      if (this.gridDataProvider.getRowCount() > 0) {
        this.gridView.setHeaderSummaries({ visible: true });
      } else {
        this.gridView.setHeaderSummaries({ visible: false });
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
      const fileName = `생산실적_년간전체실적집계_${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

      const options = {
        type: 'excel',
        target: 'local',
        fileName: fileName,
        progressMessage: '엑셀 Export중입니다.',
        applyDynamicStyles: true,
        done: function () {
          alert('엑셀 내보내기가 완료되었습니다!');
        },
      };

      grid.exportGrid(options);
    },
  },
};
</script>
