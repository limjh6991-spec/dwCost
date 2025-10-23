/** * 타시스템 > 부서별, 계정별 비용 */
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
          <!-- 조회 기능만 활성화, 다른 기능들은 주석처리 -->
          <!-- <b-button class="second" @click="uploadClick">업로드</b-button> -->
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
          <!-- <b-button class="sub" @click="addBtnClick">추가</b-button>
          <b-button @click="delBtnClick">삭제</b-button>
          <b-button class="main" @click="saveBtnClick">저장</b-button> -->
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="modelGrid" :uid="'modelGrid'" :step="'1'" :rows="modelGridRows" style="height: 100%" />
      </div>
    </div>
    <!-- 업로드 팝업 주석처리 - 조회 기능만 활성화 -->
    <!-- <UploadPopup ref="uploadPopup1" @closePopup="closePopup" /> -->
  </div>
</template>

<script>
import { RowState } from 'realgrid';
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import gridField from '@web/c0007000/js/C0007001.js';

export default {
  props: {},
  components: {},
  setup() {
    const userAuthInfo = useUserAuthInfo();
    return { userAuthInfo };
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
      duplicateKey: ['yyyymm', 'selCode', 'site', 'dept', 'acct'],
      isValidteCellmodelGrid: false,
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
          if (this.$refs.modelGrid != null) {
            this.initialize();
            this.searchClick();
          }
        }
         }
      },
      deep: true,
      immediate: true,
    },
  },
  computed: {
     userAuthInfo() {
       return useUserAuthInfo();
     },
    gridView() {
      return this.$refs.modelGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.modelGrid.getGridDataProvider();
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
    initialize() {
      var current = new Date();
      this.params.yyyymm = `${current.getFullYear()}-${(current.getMonth() + 1).toString().padStart(2, '0')}`;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },
    initializeGrid() {
      this.modelGrid = _.cloneDeep(gridField);
    },
    async getDataList() {
      this.gridView.commit();
      // 기준월(YYYY-MM)을 DB 쿼리용(YYYYMM)으로 변환
      let yyyymm = this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null;
      let params = {
        yyyymm: yyyymm,
        site: this.siteMap[this.params.site],
      };
      console.log('조회 파라미터:', params); // 실제 전달 값 확인
      let param = {
        menuId: 'c0007001',
        queryId: 'selectTab1GridData',
        queryParams: params,
        target: this.modelGridRows,
      };
      try {
        let resp = await this.$axios.api.search(param);
        console.log('조회 성공:', resp);
      } catch (error) {
        // 상세 오류 메시지 출력
        if (error.response) {
          console.error('조회 중 오류 발생:', error.response.data);
          this.$toast('error', `서버 오류: ${error.response.data?.message || error.response.status}`);
        } else {
          console.error('조회 중 오류 발생:', error.message);
          this.$toast('error', `서버 연결에 실패했습니다: ${error.message}`);
        }
      }
    },

    searchClick() {
      this.getDataList();
    },
    /* 업로드 기능 주석처리 - 조회 기능만 활성화
    uploadClick() {
      let excelGrid = _.cloneDeep(gridField);
      excelGrid.options.display.fitStyle = 'none'; // 엑셀다운로드시 none 아니면 width 0이 됨.
      this.$refs.uploadPopup1.openDialog({
        dialogTitle: '업로드 팝업',
        uploadApi: '/api/c0007000/C0007001/upload',
        headers: ['field1', 'field2', 'field3', 'field4', 'field5', 'field6', 'field7', 'field8', 'field9', 'field10', 'field11', 'field12', 'field13', 'field14', 'field15'],
        excelGrid,
        fileName: '부서별_계정별_비용_template',
      });
    },
    */
    /* 업로드 팝업 관련 메서드 주석처리
    closePopup() {
      this.searchClick();
    },
    */
    async excelBtnClick() {
      const grid = this.gridView;

      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();

      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `부서별_계정별_비용${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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

    /* CRUD 기능들 주석처리 - 조회 기능만 활성화
    addBtnClick() {
      this.gridView.commit();
      this.gridDataProvider.addRow({ yyyy: this.params.yyyy.text, site: this.params.site });
      let itemIndex = this.gridView.getItemCount() - 1;
      this.gridView.setCurrent({ itemIndex: itemIndex });
    },

    delBtnClick() {
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
      this.gridView.commit();
      await this.saveData();
    },

    async saveData() {
      let saveData = this.$refs.modelGrid.getSaveData();
      if (saveData.count <= 0) {
        this.$toast('info', '변경된 내용이 없습니다.');
        return;
      }
      this.duplicateIndices = this.$utils.findDuplicateIndices(this.duplicateKey, this.gridDataProvider.getJsonRows(0, -1));

      this.isValidteCellmodelGrid = true;
      let rslt = this.gridView.validateCells(null, false);
      this.isValidteCellmodelGrid = false;

      if (rslt === null) {
        this.$confirm('확인', '수정하신 내용을 저장 하시겠습니까?', async (confirm) => {
          if (confirm) {
            let param = {
              menuId: 'C0007001',
              delete: [{ queryId: 'deleteTab1Data', data: saveData.delete }],
              insert: [{ queryId: 'insertTab1Data', data: saveData.insert }],
              update: [{ queryId: 'updateTab1Data', data: saveData.update }],
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
    */
    /* 편집 검증 기능 주석처리 - 조회 기능만 활성화
    onValidateColumnmodelGrid(grid, column, inserting, value, itemIndex, dataRow) {
      let error = {};
      if (!this.isValidteCellmodelGrid) return error;

      if (this.$utils.containsValue(['yyyymm', 'selCode', 'site', 'dept', 'acct'], column.fieldName)) {
        if (_.isNil(value)) {
          error.level = 'error';
          error.message = '필수 입력입니다.';
        }
      }

      if (this.duplicateIndices.includes(itemIndex) && this.$utils.containsValue(['yyyymm', 'selCode', 'site', 'dept', 'acct'], column.fieldName)) {
        error.level = 'warning';
        error.message = '중복 입력입니다.';
      }

      return error;
    },
    */
  },
};
</script>

<style scoped>
.input-group {
  display: flex;
  align-items: center;
  gap: 8px;
}
.input-label {
  margin-right: 4px;
  font-weight: 500;
  color: #333;
}
.form-select {
  height: 32px;
  font-size: 15px;
  border-radius: 6px;
  border: 1px solid #bdbdbd;
  background: #fff;
  padding: 0 8px;
}
.yyyymm-tab-wrap {
  position: relative;
  display: flex;
  align-items: center;
  width: 140px;
}
.yyyymm-input-wrap {
  position: relative;
  width: 100%;
  display: flex;
  align-items: center;
}
.yyyymm-input {
  width: 100%;
  font-size: 16px;
  font-family: inherit;
  font-weight: 400;
  color: #222;
  border: 1px solid #bdbdbd;
  border-radius: 6px;
  background: #fff;
  text-align: center;
  cursor: pointer;
  padding-right: 32px;
  height: 38px;
  line-height: 38px;
  box-sizing: border-box;
}
.dropdown-arrow {
  position: absolute;
  right: 10px;
  top: 50%;
  transform: translateY(-50%);
  display: flex;
  align-items: center;
  height: 24px;
  cursor: pointer;
  z-index: 2;
}
.yyyymm-label {
  position: absolute;
  left: 14px;
  top: 8px;
  font-size: 14px;
  color: #888;
  pointer-events: none;
  background: transparent;
  z-index: 1;
}
.yyyymm-popup-inside {
  position: absolute;
  left: 0;
  top: 44px;
  background: #fff;
  border: 1px solid #bdbdbd;
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.10);
  padding: 16px 18px 10px 18px;
  z-index: 200;
  min-width: 220px;
  min-height: 100px;
  display: flex;
  flex-direction: column;
  align-items: center;
}
.popup-close-x {
  position: absolute;
  top: 8px;
  right: 10px;
  background: none;
  border: none;
  font-size: 14px;
  color: #888;
  cursor: pointer;
  z-index: 10;
}
.popup-header {
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 8px;
  margin-top: 8px;
}
.popup-year {
  font-weight: bold;
  font-size: 17px;
  color: #333;
  margin: 0 12px;
}
.popup-arrow {
  background: none;
  border: none;
  font-size: 17px;
  color: #333;
  cursor: pointer;
  padding: 0 8px;
}
.month-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
  margin-top: 8px;
}
.month-cell {
  aspect-ratio: 1/1;
  width: 44px;
  min-width: 44px;
  max-width: 60px;
  min-height: 44px;
  max-height: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  background: #f5f5f5;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 15px;
  color: #222;
  box-shadow: 0 2px 6px rgba(0,0,0,0.08);
  transition: background 0.2s, box-shadow 0.2s;
}
.month-cell.selected {
  background: #333;
  color: #fff;
  font-weight: bold;
  box-shadow: 0 4px 12px rgba(0,0,0,0.16);
}
.popup-footer {
  text-align: right;
  margin-top: 8px;
  width: 100%;
}
</style>
