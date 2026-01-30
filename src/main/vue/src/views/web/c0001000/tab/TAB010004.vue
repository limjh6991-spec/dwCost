<!-- 기준정보 > 모델 관리 (TAB010004) -->
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
          <!-- <b-button class="second" @click="uploadClick">업로드</b-button> -->
          <b-button class="second" @click="genData">데이터 생성</b-button>          
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
          <b-button class="sub" @click="addBtnClick">추가</b-button>
          <b-button @click="delBtnClick">삭제</b-button>
          <b-button class="main" @click="saveBtnClick">저장</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="modelGrid" :uid="'modelGrid'" :step="'1'" :rows="modelGridRows" style="height: 100%" :fitLayoutWidthEnable="false" />
      </div>
    </div>
    <UploadPopup ref="uploadPopup1" @closePopup="closePopup" />
  </div>
</template>
<script>
import { RowState } from 'realgrid';
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0001000/js/TAB010004.js';
import axios from 'axios';
export default {
  components: {},
  props: {
    yearList: {
      type: Array,
      default: () => [],
    },
  },
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
      modelGrid: null,
      modelGridRows: [],
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
      isProcessing: false,
      duplicateKey: ['yyyymm', 'selCode', 'site', 'model'],
      isValidteCellModelGrid: false,
    };
  },
  computed: {
    gridView() {
      return this.$refs.modelGrid && this.$refs.modelGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.modelGrid && this.$refs.modelGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    },
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
            if (this.$refs.modelGrid != null) {
              this.searchClick();
            }
          }
        },
      },
    },
  created() {
    this.initializeGrid();
  },
  mounted() {
    this.params.yyyymm = this.srchInfo.yyyymm;
    this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    this.$nextTick(() => {
      this.searchClick();
      this.calcXYForAddRows();
    });
  },
  methods: {
    initializeGrid() {
      this.modelGrid = _.cloneDeep(gridField);
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },
    async getDataList() {
      if (!this.gridView) return;

      this.gridView.commit();
      
      let params = {
          yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
          site: this.siteMap[this.params.site],
        };

        let param = {
          menuId: 'c0001004',
          queryId: 'selectTab4GridData',
          queryParams: params,
          target: this.modelGridRows,
        };
        let resp = await this.$axios.api.search(param);
      },
    searchClick() {
      if (!this.params.yyyymm) {
        this.$toast && this.$toast('error', '년월 선택해 주세요.');
        return;
      }
      this.getDataList();
    },
    addBtnClick() {
      if (!this.gridView || !this.gridDataProvider) return;

      this.gridView.commit();

      this.gridDataProvider.addRow({
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.params.site,
        selCode: 'ACTUAL',
        addYn: 'Y',
        xy: null
      });

      let itemIndex = this.gridView.getItemCount() - 1;
      this.gridView.setCurrent({ itemIndex });
    },
    calcXYForAddRows() {
      if (!this.gridDataProvider) return;

      let syncing = false;

      this.gridDataProvider.onValueChanged = (provider, dataRow, fieldName) => {
        if (syncing) return;
        if (fieldName !== 'x' && fieldName !== 'y') return;

        // 신규 행 xy 계산
        const addYn = provider.getValue(dataRow, 'addYn');
        if (addYn !== 'Y') return;

        const x = this.normalizeNumber(provider.getValue(dataRow, 'x'));
        const y = this.normalizeNumber(provider.getValue(dataRow, 'y'));

        syncing = true;
        provider.setValue(dataRow, 'xy', (x != null && y != null) ? (x * y) : null);
        syncing = false;
      };
    },
    normalizeNumber(v) {
      if (v === '' || v === undefined || v === null) return null;
      const n = Number(String(v).replaceAll(',', ''));
      return Number.isFinite(n) ? n : null;
    },
    applyXY(rows) {
      if (!rows || rows.length === 0) return;

      rows.forEach(r => {
        r.x = this.normalizeNumber(r.x);
        r.y = this.normalizeNumber(r.y);

        r.xy = (r.x != null && r.y != null) ? (r.x * r.y) : null;
        
        if (!r.addYn) r.addYn = 'Y';
      });
    },
    delBtnClick() {
      if (!this.gridView || !this.gridDataProvider) return;

      this.gridView.commit();
      const checkedRows = this.gridView.getCheckedRows();
      if (checkedRows.length === 0) {
        this.$toast('info', '삭제할 행을 선택하세요');
      } else {
        let delItems = [];
        checkedRows.forEach((itemIndex) => {
          if (this.gridDataProvider.getRowState(itemIndex) === RowState.CREATED) {
            delItems.push(itemIndex);
          } else {
            this.gridDataProvider.setRowState(itemIndex, RowState.DELETED);
          }
        });
        this.gridDataProvider.removeRows(delItems);
      }
    },
    async saveBtnClick() {
      if (!this.gridView || !this.gridDataProvider) return;
      this.gridView.commit();

      let saveData = this.$refs.modelGrid.getSaveData();

      this.applyXY(saveData.insert);
      this.applyXY(saveData.update);

      if (saveData.count <= 0) {
        this.$toast('info', '변경된 내용이 없습니다.');
        return;
      }
      this.duplicateIndices = this.$utils.findDuplicateIndices(this.duplicateKey, this.gridDataProvider.getJsonRows(0, -1));

      this.isValidteCellModelGrid = true;
      let rslt = this.gridView.validateCells(null, false);
      this.isValidteCellModelGrid = false;

      if (rslt === null) {
        this.$confirm('확인', '수정하신 내용을 저장 하시겠습니까?', async (confirm) => {
          if (confirm) {
            let param = {
              menuId: 'c0001004',
              delete: [{ queryId: 'deleteTab4Data', data: saveData.delete }],
              insert: [{ queryId: 'insertTab4Data', data: saveData.insert }],
              update: [{ queryId: 'updateTab4Data', data: saveData.update }],
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
    onValidateColumnModelGrid(grid, column, inserting, value, itemIndex, dataRow) {
      let error = {};
      if (!this.isValidteCellModelGrid) return error;

      if (this.$utils.containsValue(['yyyymm', 'selCode', 'site', 'model'], column.fieldName)) {
        if (_.isNil(value)) {
          error.level = 'error';
          error.message = '필수 입력입니다.';
        }
      }

      if (this.duplicateIndices.includes(itemIndex) && this.$utils.containsValue(['yyyymm', 'selCode', 'site', 'model'], column.fieldName)) {
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
      const fileName = `면적기준정보${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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
    // uploadClick() {
    //   let excelGrid = _.cloneDeep(gridField);
    //   excelGrid.options.display.fitStyle = 'none'; // 엑셀다운로드시 none 아니면 width 0이 됨.
    //   this.$refs.uploadPopup1.openDialog({
    //     dialogTitle: '업로드 팝업',
    //     uploadApi: '/api/c0001000/c0001004/tab4Upload',
    //     headers: ['field1', 'field2', 'field3', 'field4', 'field5', 'field6', 'field7', 'field8', 'field9', 'field10', 'field11', 'field12', 'field13', 'field14', 'field15'],
    //     excelGrid,
    //     fileName: '면적기준정보_template',
    //   });
    // },
    closePopup() {
      this.searchClick();
    },
    async genData() {
      if (!this.params.yyyymm) {
        this.$toast && this.$toast('error', '년월 선택해 주세요.');
        return;
      }

      try {
        // 기존 데이터 확인
        let checkParams = {
          yyyymm: this.params.yyyymm.replaceAll('-', ''),
          site: this.siteMap[this.params.site],
        };

        let checkResp = await this.$axios.post('/api/c0001000/c0001004/checkExistingData', checkParams);
        
        if (checkResp.data && checkResp.data.exists) {
          this.$confirm('데이터 생성', '해당월 데이터가 존재합니다. 기존 데이터를 삭제하시겠습니까?', async (confirm) => {
            if (confirm) {
              this.$toast && this.$toast('info', '데이터를 생성 중입니다.');

              this.modelGridRows = [];

              await this.executeGenProcedure(checkParams);
            }
          });
        } else {
          await this.executeGenProcedure(checkParams);
        }
      } catch (error) {
        this.$toast && this.$toast('error', '데이터 생성 중 오류가 발생했습니다.');
        console.error(error);
      }
    },
    async executeGenProcedure(params) {
      try {
        let procParams = {
          yyyymm: params.yyyymm,
          site: params.site,
        };

        let resp = await this.$axios.post('/api/c0001000/c0001004/genModelMast', procParams);
        
        console.log('프로시저 응답:', resp.data);
        
        if (resp.data && resp.data.success) {
          // 데이터 생성 후 안정화 시간 대기
          await new Promise(resolve => setTimeout(resolve, 1500));
          // 데이터 조회
          this.searchClick();
          this.$toast && this.$toast('info', '데이터 생성이 완료되었습니다.');
        } else {
          const errorMsg = resp.data?.message || '데이터 생성에 실패했습니다.';
          this.$toast && this.$toast('error', errorMsg);
          console.error('프로시저 실행 실패:', resp.data);
        }
      } catch (error) {
        this.$toast && this.$toast('error', '프로시저 실행 중 오류가 발생했습니다: ' + error.message);
        console.error('프로시저 호출 에러:', error);
      }
    },
  },
};
</script>
