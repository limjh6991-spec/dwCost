<!-- 타시스템 > 자재투입정보 -->
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
          <b-button v-show="!isClosedMonth && !isCurrencyReadonly" class="second" @click="uploadClick">업로드</b-button>
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
          <b-button v-show="!isClosedMonth && !isCurrencyReadonly" class="sub" @click="addBtnClick">추가</b-button>
          <b-button v-show="!isClosedMonth && !isCurrencyReadonly" @click="delBtnClick">삭제</b-button>
          <b-button v-show="!isClosedMonth && !isCurrencyReadonly" class="main" @click="saveBtnClick">저장</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="materialGrid" :uid="'materialGrid'" :step="'1'" :rows="materialGridRows" style="height: 100%" :fixLayoutWidth="false" />
      </div>
    </div>
    <UploadPopup ref="uploadPopup1" @closePopup="closePopup" />
    <ExchangeRatePopup ref="exchangeRatePopup" @closePopup="onExchangeRateClosed" />
  </div>
</template>

<script>
import { RowState } from 'realgrid';
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0007000/js/C0007002.js';
import { applyAmtFormat } from '@/utils/gridUtils';
import currencyConvert from '@web/c0007000/js/currencyConvert.js';
import ExchangeRatePopup from '@/components/ExchangeRatePopup.vue';

export default {
  mixins: [currencyConvert],
  components: { ExchangeRatePopup },
  props: {},
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
      materialGrid: null,
      materialGridRows: [],
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
      duplicateKey: ['yyyymm', 'selCode', 'site', '품번'],
      isValidateCellMaterialGrid: false,
      isClosedMonth: false,
    };
  },
  watch: {
    'params.yyyymm': async function (newVal) {
      if (newVal) {
        this.onDateChange();
        await this.checkClosingMonth();
      } else {
        this.isClosedMonth = false;
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
          if (this.$refs.materialGrid != null) {
            this.searchClick();
          }
        }
      },
    },
  },
  computed: {
    gridView() {
      return this.$refs.materialGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.materialGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    },
  },
  created() {
    this.initializeGrid();
  },
  mounted() {
    this.params.yyyymm = this.srchInfo.yyyymm;
    this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    this.$nextTick(async () => {
      await this.checkClosingMonth();
      this.searchClick();
    });
  },
  methods: {
    initializeGrid() {
      this.materialGrid = _.cloneDeep(gridField);
      this.currencyFields = gridField.currencyFields || [];
    },
    async checkClosingMonth() {
      const yyyymm = this.params.yyyymm
        ? this.params.yyyymm.replaceAll('-', '')
        : null;

      if (!yyyymm) {
        this.isClosedMonth = false;
        return;
      }

      try {
        const res = await this.$axios.get('/api/common/closing-month/check', {
          params: { yyyymm },
        });

        this.isClosedMonth =
          res?.data?.isClosed === true || res?.data?.isClosed === 'Y';

      } catch (e) {
        console.error('마감월 조회 실패', e);
        this.isClosedMonth = false;
      }
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },
    async getDataList() {
      if (!this.gridView) return;

      this.gridView.commit();

      // VINA(USD): 금액 컬럼 소수점 2자리 표시 (본사는 정수 유지)
      applyAmtFormat(this.gridView, this.materialGrid.columns, this.userAuthInfo.curProdCtg, this.currency);

      let params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.siteMap[this.params.site],
      };

      const rows = [];
      let param = {
        menuId: 'c0007002',
        queryId: 'C0007002_Sch1',
        queryParams: params,
        target: rows,
      };
      await this.$axios.api.search(param);
      const displayRows = await this.buildCurrencyRows(rows);
      this.materialGridRows.splice(0, this.materialGridRows.length, ...displayRows);
      // 비-USD 표시 중 편집 잠금(환산값이 USD 컬럼에 저장되는 사고 방지)
      this.gridView.setEditOptions({ editable: !this.isCurrencyReadonly });
    },
    searchClick() {
      if (!this.params.yyyymm) {
        this.$toast && this.$toast('error', '년월 선택해주세요.');
        return;
      }
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
    addBtnClick() {
      if (!this.gridView || !this.gridDataProvider) return;

      this.gridView.commit();
      this.gridDataProvider.addRow({ 
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null, 
        site: this.params.site,
        selCode: 'ACTUAL'
         });
      let itemIndex = this.gridView.getItemCount() - 1;
      this.gridView.setCurrent({ itemIndex: itemIndex });
    },
    delBtnClick() {
      if (!this.gridView || !this.gridDataProvider) return;

      this.gridView.commit();
      const checkedRows = this.gridView.getCheckedRows();
      if (checkedRows.length === 0) {
        this.$toast('info', '삭제할 행을 선택하세요');
        return;
      }

      const deletedCount = checkedRows.length;
      
      this.$confirm('확인', `${deletedCount}건을 삭제하시겠습니까?`, async (confirmed) => {
        if (!confirmed) return;

        let newRows = [];
        let existingRows = [];
        
        checkedRows.forEach((itemIndex) => {
          if (this.gridDataProvider.getRowState(itemIndex) === RowState.CREATED) {
            newRows.push(itemIndex);
          } else {
            existingRows.push(this.gridDataProvider.getJsonRow(itemIndex));
          }
        });

        if (newRows.length > 0) {
          this.gridDataProvider.removeRows(newRows);
        }

        if (existingRows.length > 0) {
          try {
            let param = {
              menuId: 'c0007002',
              delete: [{ queryId: 'C0007002_Delete1', data: existingRows }],
            };
            await this.$axios.api.saveData(param);
            this.searchClick();
          } catch {
            this.$toast('error', '삭제 중 에러가 발생했습니다.');
            return;
          }
        }
        
        this.$toast('success', `${deletedCount}건이 삭제되었습니다.`);
      });
    },
    async saveBtnClick() {
      if (!this.gridView || !this.gridDataProvider) return;
      this.gridView.commit();

      let saveData = this.$refs.materialGrid.getSaveData();
      if (saveData.count <= 0) {
        this.$toast('info', '변경된 내용이 없습니다.');
        return;
      }
      this.duplicateIndices = this.$utils.findDuplicateIndices(this.duplicateKey, this.gridDataProvider.getJsonRows(0, -1));

      this.isValidateCellMaterialGrid = true;
      let rslt = this.gridView.validateCells(null, false);
      this.isValidateCellMaterialGrid = false;

      if (rslt === null) {
        this.$confirm('확인', '수정하신 내용을 저장 하시겠습니까?', async (confirm) => {
          if (confirm) {
            let param = {
              menuId: 'c0007002',
              delete: [{ queryId: 'C0007002_Delete1', data: saveData.delete }],
              insert: [{ queryId: 'C0007002_Insert1', data: saveData.insert }],
              update: [{ queryId: 'C0007002_Update1', data: saveData.update }],
            };

            try {
              let resp = await this.$axios.api.saveData(param);
              this.$toast('info', '저장완료');
              this.searchClick();
            } catch {
              this.$toast('info', '에러발생. 다시 작업해주세요.');
            }
          }
        });
      }
    },
    onValidateColumnMaterialGrid(grid, column, inserting, value, itemIndex, dataRow) {
      let error = {};
      if (!this.isValidateCellMaterialGrid) return error;

      if (this.$utils.containsValue(['yyyymm', 'selCode', 'site', '품번'], column.fieldName)) {
        if (_.isNil(value)) {
          error.level = 'error';
          error.message = '필수 입력입니다.';
        }
      }

      if (this.duplicateIndices.includes(itemIndex) && this.$utils.containsValue(['yyyymm', 'selCode', 'site', '품번'], column.fieldName)) {
        error.level = 'warning';
        error.message = '중복 입력입니다.';
      }

      return error;
    },
    async excelBtnClick() {
      const grid = this.gridView;
      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `자재투입정보${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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
    uploadClick() {
      let excelGrid = _.cloneDeep(gridField);
      excelGrid.options.display.fitStyle = 'none'; // 엑셀다운로드시 none 아니면 width 0이 됨.
      this.$refs.uploadPopup1.openDialog({
        dialogTitle: '업로드 팝업',
        uploadApi: '/api/c0007000/c0007002/upload',
        headers: ['field1', 'field2', 'field3', 'field4', 'field5', 'field6', 'field7', 'field8', 'field9', 'field10', 'field11', 'field12', 'field13'],
        excelGrid,
        fileName: '자재투입정보_template',
      });
    },
    closePopup() {
      this.searchClick();
    },
  },
};
</script>
