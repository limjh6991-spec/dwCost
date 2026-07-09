/** * TAB090009 - 제품별 판매관리비 집계표 */
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="1" class="period">
          <div class="form-floating me-1">
            <date-picker label="기준월" mode="month" v-model="params.yyyymm" @change="onDateInput" />
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
        <b-col cols="2" class="ms-3" v-if="showCurrencySelect">
          <div class="form-floating">
            <input autocomplete="off" type="text" class="form-control label-60" id="baseRate" :value="baseRateDisplay" placeholder="기준환율" :disabled="true" />
            <label for="baseRate">기준환율</label>
          </div>
        </b-col>
        <b-col cols="2" class="ms-2 d-flex align-items-center" v-if="showCurrencySelect">
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
        <RealGrid ref="sga2Grid" :uid="'sga2Grid'" :step="'1'" :rows="sga2GridRows" style="height: 100%" />
      </div>
    </div>
    <ExchangeRatePopup ref="exchangeRatePopup" @closePopup="onExchangeRateClosed" />
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { applyAmtFormatLive } from '@/utils/gridUtils';
import { useC0001001 } from '@web/store/C0001001.js';
import currencyConvert from '@web/c0007000/js/currencyConvert.js';
import ExchangeRatePopup from '@/components/ExchangeRatePopup.vue';

export default {
  props: {},
  mixins: [currencyConvert],
  components: { ExchangeRatePopup },
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
      sga2Grid: null,
      sga2GridRows: [],
      selCodeList: [],
      params: {
        yyyy: null,
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
    'params.yyyymm': function (newVal) {
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
          if (this.$refs.sga2Grid != null) {
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
    gridView() {
      return this.$refs.sga2Grid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.sga2Grid.getGridDataProvider();
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
      this.loadSelCodeList();
    },
    initializeGrid() {
      this.sga2Grid = _.cloneDeep(require(`@web/c0009000/js/TAB090009.js`));
    },
    onDateChange() {
      // 년도 변경시 별도 처리 불필요
    },
    async getDataList() {
      this.gridView.commit();

      let params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.params.site != null ? this.siteMap[this.params.site] : null,
        selCode: this.params.selCode === '' ? 'ACTUAL' : this.params.selCode,
      };

      let searchParam = {
        menuId: 'c0009000',
        queryId: 'C0009008_Tab090009_Col',
        queryParams: params,
        target: null,
      };

      let result1 = await this.$axios.api.search(searchParam);
      
      result1.sort((a, b) => {
        const aModel = a.model || '';
        const bModel = b.model || '';
        
        const aIsYangsan = aModel.startsWith('양산');
        const bIsYangsan = bModel.startsWith('양산');
        const aIsGaebel = aModel.startsWith('개발');
        const bIsGaebel = bModel.startsWith('개발');
        
        if (aIsYangsan && !bIsYangsan) return -1;
        if (!aIsYangsan && bIsYangsan) return 1;
        if (aIsGaebel && !bIsGaebel) return -1;
        if (!aIsGaebel && bIsGaebel) return 1;
        
        return aModel.localeCompare(bModel);
      });
      
      const gridField1 = _.cloneDeep(require(`@web/c0009000/js/TAB090009.js`));
      
      // 고정 필드 (이미 존재하는 필드들)
      const fixedColumns = [
        { name: 'gubun', fieldName: 'gubun', width: 150, header: { text: '구분' }, styleName: 'tl' },
        { name: '판매관리비계획', fieldName: '판매관리비계획', width: 100, header: { text: '판매관리비 계획' }, styleName: 'tr', numberFormat: '#,##0' },
        { name: 'Z합계', fieldName: 'Z합계', width: 100, header: { text: '판매관리비 합계' }, styleName: 'tr', numberFormat: '#,##0' },
        { name: 'X합계', fieldName: 'X합계', width: 100, header: { text: '양산 합계' }, styleName: 'tr', numberFormat: '#,##0' },
        { name: 'Y합계', fieldName: 'Y합계', width: 100, header: { text: '개발 합계' }, styleName: 'tr', numberFormat: '#,##0' }
      ];
      
      // 양산/개발 분류
      const yangSanModels = result1.filter(m => m.model.startsWith('양산'));
      const gaeBelModels = result1.filter(m => m.model.startsWith('개발'));
      
      // 동적 모델 필드 추가
      result1.forEach((item) => {
        gridField1.fields.push({
          fieldName: item.model,
          valueType: 'number',
          dataType: 'number',
        });
      });

      // 동적 컬럼 추가
      result1.forEach((item) => {
        const displayModel = item.model.replace(/^(양산|개발)/, '');
        gridField1.columns.push({
          name: item.model,
          fieldName: item.model,
          width: 80,
          header: {
            text: displayModel,
          },
          autoFilter: false,
          numberFormat: '#,##0',
          styleName: 'tr',
        });
      });

      this.gridDataProvider.setFields(gridField1.fields);
      
      // 모든 컬럼 = 고정 + 동적
      const stripModelPrefix = (model) => model.replace(/^(양산|개발)/, '');
      const allColumns = [
        ...fixedColumns,
        ...result1.map((item) => ({
          name: item.model,
          fieldName: item.model,
          width: 80,
          header: { text: stripModelPrefix(item.model) },
          autoFilter: false,
          numberFormat: '#,##0',
          styleName: 'tr',
        }))
      ];
      
      this.gridView.setColumns(allColumns);
      applyAmtFormatLive(this.gridView, this.userAuthInfo.curProdCtg, this.currency);
      // 환산 대상 금액 컬럼(고정+동적) 수집
      this.currencyFields = allColumns.filter((c) => c.numberFormat).map((c) => c.fieldName);
      const layout = [
        { column: 'gubun', rowSpan: 2, header: { text: '구분' } },
        { column: '판매관리비계획', rowSpan: 2, header: { text: '판매관리비 계획' } },
        { column: 'Z합계', rowSpan: 2, header: { text: '판매관리비 합계' } },
        { column: 'X합계', rowSpan: 2, header: { text: '양산 합계' } },
        { column: 'Y합계', rowSpan: 2, header: { text: '개발 합계' } },
        {
          header: { text: '양산' },
          items: yangSanModels.map(m => ({
            column: m.model,
            header: { text: m.model.replace(/^양산/, '') }
          }))
        },
        {
          header: { text: '개발' },
          items: gaeBelModels.map(m => ({
            column: m.model,
            header: { text: m.model.replace(/^개발/, '') }
          }))
        }
      ];
      
      this.gridView.setColumnLayout(layout);

      const rows = [];
      await this.$axios.api.search({
        menuId: 'c0009000',
        queryId: 'C0009008_Tab090009',
        queryParams: params,
        target: rows,
      });
      // 선택 통화(KRW/VND)면 월평균 환율로 금액 환산 표시 (USD면 원본)
      const displayRows = await this.buildCurrencyRows(rows);
      this.sga2GridRows.splice(0, this.sga2GridRows.length, ...displayRows);
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
    async excelBtnClick() {
      const grid = this.gridView;

      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();

      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `제품별_판매관리비_집계표_${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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
    setCellStyleCallbackSga2Grid(grid, dataCell) {
      const ret = {};
      const isGubunCol = dataCell.dataColumn.name === 'gubun';

      // 안전하게 gubun 값 획득
      let gubun;
      if (isGubunCol) {
      gubun = dataCell.value ?? '';
      } else {
      const dataProvider = this.$refs.sga2Grid.getGridDataProvider();
      gubun = (dataProvider.getValue(dataCell.index.dataRow, 'gubun') ?? '');
      }

        const isRateRow = gubun === '    판관비 배부율 (제품별 매출비중)';
        const isSumRow  = gubun === '    (29) 합계';
        const isGrayRow = isRateRow || isSumRow;

      if (isGubunCol) {
        ret.style = {
          fontWeight: 'bold',
          whiteSpace: 'pre',
          ...(isGrayRow ? { background: '#BFBFBF' } : {}),
        };
      } else {
        ret.style = {
          whiteSpace: 'pre',
          ...(isGrayRow ? { background: '#BFBFBF' } : {}),
        };
      }

      // // 길이 체크 포함한 판관비 판별
      // const isSgapan = gubun.length >= 7 && gubun.substr(4, 3) === '판관비';
      // const isParentHead = /^\s*\(\d+\)/.test(gubun);

      // // 공통 스타일 결정
      // if (isSgapan||isParentHead) {
      // ret.style = { fontWeight: 'bold', background: '#BFBFBF', whiteSpace: 'pre' };
      // } else {
      // ret.style = { fontWeight: 'normal', whiteSpace: 'pre' };
      // }

      // 숫자 포맷은 gubun 컬럼 외에만 적용
      if (!isGubunCol && isRateRow) {
      ret.numberFormat = '#,##0.##';
      }

      return ret;
    },
    // setRowStyleCallbackSga2Grid(grid, item, fixed) {
    //   var ret = {};
    //   var gubun = grid.getValue(item.index, 'gubun'); 

    //   if(gubun.substr(4,3)==='판관비'){
    //     ret.style = { fontWeight: 'bold', background: '#BFBFBF' };
    //   }
    //   else if (/^\s*\(\d+\)/.test(gubun)) {
    //     ret.style = { background: '#BFBFBF' };
    //   }
    //   return ret;
    // },
  },
};
</script>
