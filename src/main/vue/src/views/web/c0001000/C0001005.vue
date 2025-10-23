/** * 기본정보 > 제품기준정보 */
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="2">
          <div class="form-floating">
            <select class="form-select label-60" id="floatingSelect" v-model="params.yyyy">
              <option v-for="yyyy in yearList" :key="yyyy.value" :value="yyyy">
                {{ yyyy.text }}
              </option>
            </select>
            <label for="floatingSelect" class="select">년도</label>
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
import gridField from '@web/c0001000/js/C0001005.js';

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
        yyyy: null,
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
      duplicateKey: ['yyyy', 'selCode', 'site', 'model'],
      isValidteCellmodelGrid: false,
    };
  },
  watch: {
    userAuthInfo: {
      handler(newVal) {
        if (newVal.curProdCtg) {
          this.params.site = newVal.curProdCtg === 'VN' ? 'VINA' : '본사';
          if (this.$refs.modelGrid != null) {
            this.initialize();
            this.searchClick();
          }
        }
      },
      deep: true,
      immediate: true,
    },
  },
  computed: {
    gridView() {
      return this.$refs.modelGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.modelGrid.getGridDataProvider();
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
      var current = new Date();
      this.yearList = [];
      for (let i = current.getFullYear() - 1; i < current.getFullYear() + 6; i++) {
        this.yearList.push({ value: i, text: i });
      }
      this.params.yyyy = { value: current.getFullYear(), text: current.getFullYear() };
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },
    initializeGrid() {
      this.modelGrid = _.cloneDeep(gridField);
    },
    async getDataList() {
      this.gridView.commit();

      let params = {
        yyyy: this.params.yyyy.text,
        site: this.siteMap[this.params.site],
      };

      let param = {
        menuId: 'C0001005',
        queryId: 'selectTab1GridData',
        queryParams: params,
        target: this.modelGridRows,
      };
      
      try {
        let resp = await this.$axios.api.search(param);
        console.log('조회 성공:', resp);
      } catch (error) {
        console.error('조회 중 오류 발생:', error);
        this.$toast('error', '서버 연결에 실패했습니다. Spring Boot 서버가 실행 중인지 확인하세요.');
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
        uploadApi: '/api/c0001000/C0001005/upload',
        headers: ['field1', 'field2', 'field3', 'field4', 'field5', 'field6', 'field7', 'field8', 'field9', 'field10', 'field11', 'field12', 'field13', 'field14', 'field15'],
        excelGrid,
        fileName: '제품기준정보_template',
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
      const fileName = `제품기준정보${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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
              menuId: 'C0001005',
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

      if (this.$utils.containsValue(['yyyy', 'selCode', 'site', 'model'], column.fieldName)) {
        if (_.isNil(value)) {
          error.level = 'error';
          error.message = '필수 입력입니다.';
        }
      }

      if (this.duplicateIndices.includes(itemIndex) && this.$utils.containsValue(['yyyy', 'selCode', 'site', 'model'], column.fieldName)) {
        error.level = 'warning';
        error.message = '중복 입력입니다.';
      }

      return error;
    },
    */
  },
};
</script>
