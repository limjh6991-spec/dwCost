/** * 타시스템 > 매출정보 > 수출신고필증*/
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
          <b-button v-show="showIfApiButton" class="second" @click="apiCallClick">API 호출</b-button>
          <b-button v-show="!isClosedMonth" class="second" @click="uploadClick">업로드</b-button>
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
          <b-button v-show="!isClosedMonth" class="sub" @click="addBtnClick">추가</b-button>
          <b-button v-show="!isClosedMonth" @click="delBtnClick">삭제</b-button>
          <b-button v-show="!isClosedMonth" class="main" @click="saveBtnClick">저장</b-button>          
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="invoiceRescGrid" :uid="'invoiceRescGrid'" :step="'1'" :rows="invoiceRescGridRows" style="height: 100%" />
      </div>
    </div>
    <UploadPopup ref="uploadPopup2" @closePopup="closePopup" />
    <ExchangeRatePopup ref="exchangeRatePopup" @closePopup="onExchangeRateClosed" />
  </div>
</template>

<script>
import { RowState } from 'realgrid';
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0007000/js/C0007005_2.js';
import currencyConvert from '@web/c0007000/js/currencyConvert.js';
import ExchangeRatePopup from '@/components/ExchangeRatePopup.vue';
import ifaceApiMixin from '@/mixins/ifaceApiMixin.js';

export default {
  props: {},
  mixins: [currencyConvert, ifaceApiMixin],
  components: { ExchangeRatePopup },
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
      invoiceRescGrid: null,
      invoiceRescGridRows: [],
      params: {
        site: 'HQ',
        yyyymm: null,
      },
      siteMap: {
        본사: 'HQ',
        VINA: 'VN',
        HQ: 'HQ',
        VN: 'VN',
      },
      duplicateKey: ['yyyymm', 'selCode', 'site', 'invoice관리번호'],
      isValidateCellInvoiceRescGrid: false,
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
          if (this.$refs.invoiceRescGrid != null) {
            this.searchClick();
          }
        }
      },
    },
  },
  computed: {
    gridView() {
      return this.$refs.invoiceRescGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.invoiceRescGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    },
    // 인터페이스(API 호출)는 VN 전용
    isVN() {
      return this.siteMap[this.params.site] === 'VN';
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
  beforeUnmount() {},
  methods: {
    initializeGrid() {
      this.invoiceRescGrid = _.cloneDeep(gridField);
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
      this.gridView.commit();
      let params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.params.site != null ? this.siteMap[this.params.site] : null,
      };

      let param = {
        menuId: 'c0007005',
        queryId: 'C0007005_Sch2',
        queryParams: params,
        target: this.invoiceRescGridRows,
      };
      let resp = await this.$axios.api.search(param);
      await this.refreshRate();
    },
    async refreshRate() {
      // 매출정보는 행별 통화·환율 체계 → 그리드 환산 없이 기준환율만 표시
      this.appliedRate = null;
      this.appliedRateMonth = null;
      if (!this.isVinaSite || this.currency === 'USD') return;
      const rate = await this.fetchExchangeRate(this.params.yyyymm, this.currency);
      if (rate) {
        this.appliedRate = rate;
        this.appliedRateMonth = this._normalizeYyyymm(this.params.yyyymm);
      }
    },
    onCurrencyChange(currency) {
      this.setCurrency(currency);
      this.refreshRate();
    },
    openExchangeRate() {
      this.$refs.exchangeRatePopup.openDialog({ yyyymm: this.params.yyyymm });
    },
    onExchangeRateClosed() {
      this.refreshRate();
    },
    searchClick() {
      if (!this.params.yyyymm) {
        this.$toast && this.$toast('error', '년월 선택해주세요.');
        return;
      }
      this.getDataList();
    },
    // 수출신고필증(EXP_PERMIT) API 호출 → 적재 → 그리드 새로고침
    apiCallClick() {
      if (!this.params.yyyymm) {
        this.$toast && this.$toast('error', '년월 선택해주세요.');
        return;
      }
      const yyyymm = this.params.yyyymm.replaceAll('-', '');
      // ERP DataBlock 조회조건 (정의서_수출 v1.0 - 수출매출품목): 매출일 월초~월말(SalesDateFr/To, YYYYMMDD).
      // ★샘플대로 전체 DataBlock 필드 전송(누락 시 빈 결과) — BizUnit/SMExpKind 등 0/'' 기본값.
      const y = Number(yyyymm.slice(0, 4));
      const m = Number(yyyymm.slice(4, 6));
      const lastDay = new Date(y, m, 0).getDate();
      const dfr = `${yyyymm}01`;
      const dto = `${yyyymm}${String(lastDay).padStart(2, '0')}`;
      const site = this.siteMap[this.params.site];
      if (site === 'HQ') {
        // 정의서_HQ 수출Invoice 요청 JSON 샘플 그대로(32필드): BizUnit=1, WorkingTag ''/IDX_NO 0, 문자플래그 '0'
        this.callIface({
          key: 'EXP_INVOICE_HQ',
          selCode: 'ACTUAL',
          yyyymm: yyyymm,
          params: {
            WorkingTag: '', IDX_NO: 0, Status: '0', DataSeq: 1, Selected: 1, TABLE_NAME: '', UserName: '',
            InvoiceNo: '', BizUnit: 1, SMExpKind: 0, UMOutKind: 0, DeptSeq: 0, EmpSeq: 0, CustSeq: 0, SMProgressType: 0,
            InvoiceDateFr: dfr, InvoiceDateTo: dto,
            ItemName: '', ItemNo: '', Spec: '', LotNo: '', WHSeq: 0, AssetSeq: 0, SourceRefNo: '', SourceNo: '',
            UMPriceTerms: 0, InvoiceRefNo: '', PONo: '', SourceTableSeq: 0, SMDelvStatus: '', IsEtcOut: '0', SMSalesProgType: 0,
            site,
          },
          successLabel: '수출Invoice',
          onSuccess: () => this.getDataList(),
        });
        return;
      }
      // 비나 수출매출품목 (EXP_SALES)
      this.callIface({
        key: 'EXP_SALES',
        selCode: 'ACTUAL',
        yyyymm: yyyymm,
        params: {
          BizUnit: 0, SMExpKind: 0, SalesNo: '', DeptSeq: 0, EmpSeq: 0, CustSeq: 0, CustNo: '', ItemName: '', ItemNo: '',
          SalesDateFr: dfr,
          SalesDateTo: dto,
          AssetSeq: 0, BillNo: '', UMPriceTerms: 0, InvoiceRefNo: '', SourceNo: '', SourceRefNo: '', SourceTableSeq: 0, UMChannel: 0,
          site,
        },
        successLabel: '수출매출품목',
        onSuccess: () => this.getDataList(),
      });
    },
    async excelBtnClick() {
      const grid = this.gridView;
      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `수출신고필증${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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
    addBtnClick() {
      if (!this.gridView || !this.gridDataProvider) return;

      this.gridView.commit();
      this.gridDataProvider.addRow({ 
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null, 
        site: this.params.site != null ? this.siteMap[this.params.site] : null,
        selCode: this.params.selCode ?? 'ACTUAL',
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
              menuId: 'c0007005',
              delete: [{ queryId: 'C0007005_Delete2', data: existingRows }],
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

      let saveData = this.$refs.invoiceRescGrid.getSaveData();
      if (saveData.count <= 0) {
        this.$toast('info', '변경된 내용이 없습니다.');
        return;
      }
      this.duplicateIndices = this.$utils.findDuplicateIndices(this.duplicateKey, this.gridDataProvider.getJsonRows(0, -1));

      this.isValidateCellInvoiceRescGrid = true;
      let rslt = this.gridView.validateCells(null, false);
      this.isValidateCellInvoiceRescGrid = false;

      if (rslt === null) {
        this.$confirm('확인', '수정하신 내용을 저장 하시겠습니까?', async (confirm) => {
          if (confirm) {
            let param = {
              menuId: 'c0007005',
              delete: [{ queryId: 'C0007005_Delete2', data: saveData.delete }],
              insert: [{ queryId: 'C0007005_Insert2', data: saveData.insert }],
              update: [{ queryId: 'C0007005_Update2', data: saveData.update }],
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
    onValidateColumnInvoiceRescGrid(grid, column, inserting, value, itemIndex, dataRow) {
      let error = {};
      if (!this.isValidateCellInvoiceRescGrid) return error;

      if (this.$utils.containsValue(['yyyymm', 'selCode', 'site', 'invoice관리번호'], column.fieldName)) {
        if (_.isNil(value)) {
          error.level = 'error';
          error.message = '필수 입력입니다.';
        }
      }

      if (this.duplicateIndices.includes(itemIndex) && this.$utils.containsValue(['yyyymm', 'selCode', 'site', 'invoice관리번호'], column.fieldName)) {
        error.level = 'warning';
        error.message = '중복 입력입니다.';
      }

      if (this.$utils.containsValue(['선택', '출고처리', '반품'], column.fieldName)) {
        if (!_.isNil(value) && value.length >= 2) {
          error.level = 'warning';
          error.message = '한자리로 입력해주세요.';
        }
      }

      return error;
    },
    uploadClick() {
      let excelGrid = _.cloneDeep(gridField);
      excelGrid.options.display.fitStyle = 'none'; // 엑셀다운로드시 none 아니면 width 0이 됨.
      this.$refs.uploadPopup2.openDialog({
        dialogTitle: '업로드 팝업',
        uploadApi: '/api/c0007000/c0007005/upload2',
        headers: [
          'field1',
          'field2',
          'field3',
          'field4',
          'field5',
          'field6',
          'field7',
          'field8',
          'field9',
          'field10',
          'field11',
          'field12',
          'field13',
          'field14',
          'field15',
          'field16',
          'field17',
          'field18',
          'field19',
          'field20',
          'field21',
          'field22',
          'field23',
          'field24',
          'field25',
          'field26',
          'field27',
          'field28',
          'field29',
          'field30',
          'field31',
          'field32',
          'field33',
          'field34',
          'field35',
          'field36',
          'field37',
          'field38',
          'field39',
          'field40',
          'field41',
          'field42',
          'field43',
          'field44',
          'field45',
          'field46',
          'field47',
          'field48',
          'field49',
          'field50',
          'field51',
          'field52',
          'field53',
          'field54',
        ],
        excelGrid,
        fileName: '매출정보_template',
      });
    },
    closePopup() {
      this.searchClick();
    },    
  },
};
</script>
