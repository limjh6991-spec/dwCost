/** * 기준정보 > 원가자재코드 */
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="2">
          <div class="form-floating">
            <div class="form-floating me-1">
              <date-picker label="기준월" mode="month" v-model="params.yyyymm" />
              <label for="floatingSelect" class="select">기준월</label>
            </div>
          </div>
        </b-col>
        <b-col cols="2">
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
          <b-button class="second" @click="uploadClick">업로드</b-button>
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
          <b-button class="sub" @click="addBtnClick">추가</b-button>
          <b-button @click="delBtnClick">삭제</b-button>
          <b-button class="main" @click="saveBtnClick">저장</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="materialGrid" :uid="'materialGrid'" :step="'1'" :rows="materialGridRows" style="height: 100%" />
      </div>
    </div>
    <UploadPopup ref="uploadPopup1" @closePopup="closePopup" />
  </div>
</template>

<script>
import { RowState } from 'realgrid';
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import UploadPopup from '@components/UploadPopup.vue';
import _ from 'lodash';
import gridField from '@web/c0001000/js/C0001003.js';

export default {
  props: {},
  components: {
    UploadPopup,
  },
  setup() {
    const userAuthInfo = useUserAuthInfo();
    return { userAuthInfo };
  },
  data() {
    return {
      materialGrid: null,
      materialGridRows: [],
      params: {
        yyyymm: null,
        site: 'HQ',
      },
      yearList: [],
      siteMap: {
        본사: 'HQ', //DB map
        VINA: 'VN', //DB map
        HQ: 'HQ', //DB map
        VN: 'VN', //DB map
      },
      isProcessing: false,
      duplicateKey: ['yyyymm', 'site', 'matCode'],
      isValidteCellMaterialGrid: false,
      duplicateIndices: [],
    };
  },
  watch: {
    selectedMonth(newVal) {
      this.updateYyyymm();
    },
    selectedYear(newVal) {
      this.updateYyyymm();
    },
    userAuthInfo: {
      handler(newVal) {
        if (newVal) {
          if (newVal.curProdCtg) {
            this.params.site = newVal.curProdCtg === 'VN' ? 'VINA' : '본사';
            if (this.$refs.materialGrid != null) {
              this.initialize();
              this.searchClick();
            }
          }
        }
      },
      deep: true,
      immediate: true
    },
  },
  computed: {
    gridView() {
      return this.$refs.materialGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.materialGrid.getGridDataProvider();
    },
  },
  created() {
    // 기준월을 오늘 날짜 기준으로 세팅 (항상 YYYY-MM 형태)
    const now = new Date();
    this.params.yyyymm = `${now.getFullYear()}-${("0" + (now.getMonth() + 1)).slice(-2)}`;
    this.initialize();
    this.initializeGrid();
  },
  mounted() {},
  beforeUnmount() {},
  methods: {
    updateYyyymm() {
      // 월/년 선택 시 기준월 업데이트 (YYYY-MM)
      if (this.selectedYear && this.selectedMonth) {
        this.params.yyyymm = `${this.selectedYear}-${this.selectedMonth.toString().padStart(2, '0')}`;
      }
    },
    initialize() {
      var current = new Date();
      this.yearList = [];
      for (let i = current.getFullYear() - 1; i < current.getFullYear() + 6; i++) {
        this.yearList.push({ value: i, text: i });
      }
      this.params.yyyymm = `${current.getFullYear()}-${(current.getMonth() + 1).toString().padStart(2, '0')}`;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },
    initializeGrid() {
      this.materialGrid = _.cloneDeep(gridField);
    },
    async getDataList() {
      this.gridView.commit();
      // 기준월(YYYY-MM)을 DB 쿼리용(YYYYMM)으로 변환
      let yyyymm = this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null;
      let params = {
        yyyymm: yyyymm,
        site: this.siteMap[this.params.site],
      };
      let param = {
        menuId: 'c0001003',
        queryId: 'selectTab1GridData',
        queryParams: params,
      };
      let resp = await this.$axios.api.search(param);
      console.log('조회 결과:', resp);
      // resp가 배열, resp.data, resp.rows 등 다양한 구조에 대응
      if (Array.isArray(resp)) {
        this.materialGridRows = resp;
      } else if (Array.isArray(resp.data)) {
        this.materialGridRows = resp.data;
      } else if (Array.isArray(resp.rows)) {
        this.materialGridRows = resp.rows;
      } else {
        this.materialGridRows = [];
      }
    },

    searchClick() {
      this.getDataList();
    },

    uploadPopupBtnClick() {
      this.uploadClick();
    },

    uploadClick() {
      let excelGrid = _.cloneDeep(gridField);
      excelGrid.options.display.fitStyle = 'none'; // 엑셀다운로드시 none 아니면 width 0이 됨.
      this.$refs.uploadPopup1.openDialog({
        dialogTitle: '업로드 팝업',
        uploadApi: '/api/c0001000/c0001003/upload',
        headers: ['field1', 'field2', 'field3', 'field4', 'field5', 'field6', 'field7', 'field8', 'field9'],
        excelGrid,
        fileName: '자재정보_template',
      });
    },

    closePopup() {
      this.searchClick();
    },

    async excelBtnClick() {
      const grid = this.gridView;

      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();

      const hours = String(now.getHours()).padStart(2, "0");
      const minutes = String(now.getMinutes()).padStart(2, "0");
      const seconds = String(now.getSeconds()).padStart(2, "0");
      const fileName = `자재정보${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

      const options = {
        type: "excel",
        target: "local",
        fileName: fileName,
        progressMessage: "엑셀 Export중입니다.",
        done: function () {
          alert("엑셀 내보내기가 완료되었습니다!");
        },
      };

      grid.exportGrid(options);
    },

    addBtnClick() {
      this.gridView.commit();
      this.gridDataProvider.addRow({ yyyymm: this.params.yyyymm, site: this.params.site });
      let itemIndex = this.gridView.getItemCount() - 1;
      this.gridView.setCurrent({ itemIndex: itemIndex });
    },

    delBtnClick() {
      this.gridView.commit();
      const checkedRows = this.gridView.getCheckedRows();
      if (checkedRows.length === 0) {
        this.$toast("info", "삭제할 행을 선택하세요");
      } else {
        // 삭제할 행의 정보를 수집
        let deleteInfo = [];
        checkedRows.forEach((itemIndex) => {
          const rowData = this.gridDataProvider.getJsonRow(itemIndex);
          deleteInfo.push(`${rowData.matCode} (${rowData.matDesc})`);
        });

        const deleteMessage = `선택한 ${checkedRows.length}개의 자재를 삭제하시겠습니까?\n\n삭제 대상:\n${deleteInfo.join('\n')}`;
        
        this.$confirm('삭제 확인', deleteMessage, (confirm) => {
          if (confirm) {
            let delItems = [];
            let deletedCount = 0;
            
            checkedRows.forEach((itemIndex) => {
              if (this.gridDataProvider.getRowState(itemIndex) === RowState.CREATED) {
                delItems.push(itemIndex);
                deletedCount++;
              } else {
                this.gridDataProvider.setRowState(itemIndex, RowState.DELETED);
                deletedCount++;
              }
            });
            
            this.gridDataProvider.removeRows(delItems);
            this.$toast('success', `${deletedCount}개의 자재가 삭제 표시되었습니다. 저장 버튼을 클릭하여 완료하세요.`);
          }
        });
      }
    },

    async saveBtnClick() {
      this.gridView.commit();
      await this.saveData();
    },

    async saveData() {
      let saveData = this.$refs.materialGrid.getSaveData();
      if (saveData.count <= 0) {
        this.$toast('info', '변경된 내용이 없습니다.');
        return;
      }
      this.duplicateIndices = this.$utils.findDuplicateIndices(this.duplicateKey, this.gridDataProvider.getJsonRows(0, -1));

      this.isValidteCellMaterialGrid = true;
      let rslt = this.gridView.validateCells(null, false);
      this.isValidteCellMaterialGrid = false;

      if (rslt === null) {
        this.$confirm('확인', '수정하신 내용을 저장 하시겠습니까?', async (confirm) => {
          if (confirm) {
            let param = {
              menuId:'c0001003',
              delete: [{queryId:'deleteTab1Data', data:saveData.delete}],
              insert: [{queryId:'insertTab1Data', data:saveData.insert}],
              update: [{queryId:'updateTab1Data', data:saveData.update}],
            };

            try {
              let resp = await this.$axios.api.saveData(param);
              
              // 저장된 작업 내용을 상세히 표시
              let saveMessage = '저장 완료:\n';
              if (saveData.insert.length > 0) saveMessage += `• 추가: ${saveData.insert.length}건\n`;
              if (saveData.update.length > 0) saveMessage += `• 수정: ${saveData.update.length}건\n`;
              if (saveData.delete.length > 0) saveMessage += `• 삭제: ${saveData.delete.length}건\n`;
              
              this.$toast('success', saveMessage.trim());
              this.searchClick();
            } catch {
              this.$toast('error', '저장 중 오류가 발생했습니다. 다시 시도해주세요.');
            }
          }
        });
      } 
    },
    onValidateColumnMaterialGrid(grid, column, inserting, value, itemIndex, dataRow) {
      let error = {};
      if (!this.isValidteCellMaterialGrid) return error;

      if (this.$utils.containsValue(['yyyymm', 'site', 'matCode'], column.fieldName)) {
        if (_.isNil(value)) {
          error.level = 'error';
          error.message = '필수 입력입니다.';
        }
      }

      if (this.duplicateIndices.includes(itemIndex) && this.$utils.containsValue(['yyyymm', 'site', 'matCode'], column.fieldName)) {
        error.level = 'warning';
        error.message = '중복 입력입니다.';
      }

      return error;
    },
		onProdCtgChange(v){
			this.userAuthInfo.changeProdCtg(v);
      this.$toast('info','ccccccccccc');
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? '비나' : '본사';
		}
  },
};
</script>