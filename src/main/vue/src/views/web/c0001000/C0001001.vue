/** * 기본정보 > 계정 코드 */
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
          <b-button class="second" @click="uploadClick">업로드</b-button>
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
          <b-button class="sub" @click="addBtnClick">추가</b-button>
          <b-button @click="delBtnClick">삭제</b-button>
          <b-button class="main" @click="saveBtnClick">저장</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="acctGrid" :uid="'acctGrid'" :step="'1'" :rows="acctGridRows" style="height: 100%" />
      </div>
    </div>
    <UploadPopup ref="uploadPopup1" @closePopup="closePopup" />
  </div>
</template>

<script>
import { RowState } from 'realgrid';
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import gridField from '@web/c0001000/js/C0001001.js';

export default {
  props: {},
  components: {},
  setup() {
    const userAuthInfo = useUserAuthInfo();
    return { userAuthInfo };
  },
  data() {
    return {
      acctGrid: null,
      acctGridRows: [],
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
      duplicateKey: ['yyyy', 'selCode', 'site', 'acctClass', 'acct'],
      isValidteCellAcctGrid: false,
    };
  },
  watch: {
    userAuthInfo: {
      handler(newVal) {
        if (newVal.curProdCtg) {
          this.params.site = newVal.curProdCtg === 'VN' ? 'VINA' : '본사';
          if (this.$refs.acctGrid != null) {
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
      return this.$refs.acctGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.acctGrid.getGridDataProvider();
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
      this.acctGrid = _.cloneDeep(gridField);
    },
    async getDataList() {
      this.gridView.commit();

      let params = {
        yyyy: this.params.yyyy.text,
        site: this.siteMap[this.params.site],
      };

      let param = {
        menuId: 'c0001001',
        queryId: 'selectTab1GridData',
        queryParams: params,
        target: this.acctGridRows,
      };
      let resp = await this.$axios.api.search(param);
    },

    searchClick() {
      this.getDataList();
    },
    uploadClick() {
      let excelGrid = _.cloneDeep(gridField);
      excelGrid.options.display.fitStyle = 'none'; // 엑셀다운로드시 none 아니면 width 0이 됨.
      this.$refs.uploadPopup1.openDialog({
        dialogTitle: '업로드 팝업',
        uploadApi: '/api/c0001000/c0001001/upload',
        headers: ['field1', 'field2', 'field3', 'field4', 'field5', 'field6', 'field7', 'field8', 'field9', 'field10'],
        excelGrid,
        fileName: '원가계정정보_template',
      });
    },
    closePopup() {
      this.searchClick();
    },
    async excelBtnClick() {
      const grid = this.gridView;

      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();

      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `원가계정정보${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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
      let saveData = this.$refs.acctGrid.getSaveData();
      if (saveData.count <= 0) {
        this.$toast('info', '변경된 내용이 없습니다.');
        return;
      }
      this.duplicateIndices = this.$utils.findDuplicateIndices(this.duplicateKey, this.gridDataProvider.getJsonRows(0, -1));

      this.isValidteCellAcctGrid = true;
      let rslt = this.gridView.validateCells(null, false);
      this.isValidteCellAcctGrid = false;

      if (rslt === null) {
        this.$confirm('확인', '수정하신 내용을 저장 하시겠습니까?', async (confirm) => {
          if (confirm) {
            let param = {
              menuId: 'c0001001',
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
    onValidateColumnAcctGrid(grid, column, inserting, value, itemIndex, dataRow) {
      let error = {};
      if (!this.isValidteCellAcctGrid) return error;

      if (this.$utils.containsValue(['yyyy', 'selCode', 'site', 'acctClass', 'acct', 'acctName', 'subName', 'itemName', 'expenSel'], column.fieldName)) {
        if (_.isNil(value)) {
          error.level = 'error';
          error.message = '필수 입력입니다.';
        }
      }

      if (this.duplicateIndices.includes(itemIndex) && this.$utils.containsValue(['yyyy', 'selCode', 'site', 'acctClass', 'acct'], column.fieldName)) {
        error.level = 'warning';
        error.message = '중복 입력입니다.';
      }

      return error;
    },
  },
};
</script>
