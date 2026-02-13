/** * 제조 경비 집계표 > 제품별 집계표 */
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
        <RealGrid ref="t2Grid" :uid="'t2Grid'" :step="'1'" :rows="t2GridRows" style="height: 100%" />
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
      userAuthInfo,
    };
  },
  data() {
    return {
      t2Grid: null,
      t2GridRows: [],
      params: {
        yyyymm: null,
        site: 'HQ',
        selcode: 'ACTUAL',
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
          if (this.$refs.t2Grid != null) {
            this.initialize();
            this.searchClick();
          }
        }
      },
    },
  },
  computed: {
    gridView() {
      return this.$refs.t2Grid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.t2Grid.getGridDataProvider();
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
      this.t2Grid = _.cloneDeep(require(`@web/c0009000/js/TAB090005.js`));
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },
    async getDataList() {
      this.gridView.commit();

      let params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.params.site != null ? this.siteMap[this.params.site] : null,
        selcode : this.params.selcode != null ? this.params.selcode : null,
      };

      let searchParam = {
        menuId: 'c0009000',
        queryId: 'C0009005_Tab090005_Col',
        queryParams: params,
        target: null,
      };

      let result1 = await this.$axios.api.search(searchParam);
      const gridField1 = _.cloneDeep(require(`@web/c0009000/js/TAB090005.js`));
      
      let preGroupName = '';

      result1.forEach((item) => {
        gridField1.fields.push({
          fieldName: item.colName.toLowerCase(),
          valueType: 'number',
          dataType: 'number',
        });

        gridField1.columns.push({
          name: item.colName.toLowerCase(),
          fieldName: item.colName.toLowerCase(),
          width: 80,
          header: {
            text: item.displayName,
          },
          autoFilter: false,
          numberFormat: '#,##0',
          styleName: 'tr',
        });

        if (preGroupName !== item.groupName) {
          gridField1.layout.push({
            name: item.groupName + 'Group',
            direction: 'horizontal',
            items: [],
            header: {
              text: item.groupName,
            },
          });
          preGroupName = item.groupName;
        }
        const lastLayout = gridField1.layout[gridField1.layout.length - 1];
        lastLayout.items.push(item.colName.toLowerCase());
      });

      this.gridDataProvider.setFields(gridField1.fields);
      this.gridView.setColumns(gridField1.columns);
      this.gridView.setColumnLayout(gridField1.layout);

      let param = {
        menuId: 'c0009000',
        queryId: 'C0009005_Tab090005',
        queryParams: params,
        target: this.t2GridRows,
      };
      let resp = await this.$axios.api.search(param);
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
      const fileName = `제조경비_제품별_집계표_${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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
    setCellStyleCallbackT2Grid(grid, dataCell) {
      var ret = {};
      if (dataCell.dataColumn.name != 'gubun') {
        return ret;
      }
      var gubun = dataCell.value.trim();
      if (/^M{0,3}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})\./.test(gubun)) {
        ret.style = { fontWeight: 'bold', whiteSpace: 'pre', backgroundColor: '#BFBFBF' };
      } else {
        ret.style = { fontWeight: 'normal', whiteSpace: 'pre' };
      }
      return ret;
    },
    setRowStyleCallbackT2Grid(grid, item, fixed) {
      var ret = {};
      var gubun = grid.getValue(item.index, 'gubun').trim();
      if (/^M{0,3}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})\./.test(gubun)) {
        ret.style = { background: '#BFBFBF' };
      }
      return ret;
    },
  },
};
</script>
