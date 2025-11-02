/** * 타시스템 I/F&Upload > 매출 정보 */
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
          <b-button class="second" @click="uploadClick">업로드</b-button>
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
          <b-button class="sub" @click="addBtnClick">추가</b-button>
          <b-button @click="delBtnClick">삭제</b-button>
          <b-button class="main" @click="saveBtnClick">저장</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="saleRescGrid" :uid="'saleRescGrid'" :step="'1'" :rows="saleRescGridRows" style="height: 100%" />
      </div>
    </div>
    <UploadPopup ref="uploadPopup1" @closePopup="closePopup" />
  </div>
</template>

<script>
import { RowState } from 'realgrid';
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import gridField from '@web/c0007000/js/C0007005.js';

export default {
  props: {},
  components: {},
  setup() {
    const userAuthInfo = useUserAuthInfo();
    return { userAuthInfo };
  },
  data() {
    return {
      saleRescGrid: null,
      saleRescGridRows: [],
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
      duplicateKey: ['거래명세서번호'],
      isValidteCellSaleRescGrid: false,
    };
  },
  watch: {
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          if (this.$refs.saleRescGrid != null) {
            this.initialize();
            this.searchClick();
          }
        }
      },
    },
  },
  computed: {
    gridView() {
      return this.$refs.saleRescGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.saleRescGrid.getGridDataProvider();
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
      var current = new Date();
      this.params.yyyymm = `${current.getFullYear()}-${(current.getMonth() + 1).toString().padStart(2, '0')}`;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },
    initializeGrid() {
      this.saleRescGrid = _.cloneDeep(gridField);
    },
    async getDataList() {
      this.gridView.commit();

      let params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.params.site != null ? this.siteMap[this.params.site] : null,
      };

      let param = {
        menuId: 'c0007005',
        queryId: 'C0007005_Sch1',
        queryParams: params,
        target: this.saleRescGridRows,
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
        uploadApi: '/api/c0007000/c0007005/upload',
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
          'field55',
          'field56',
          'field57',
          'field58',
          'field59',
          'field60',
          'field61',
          'field62',
          'field63',
          'field64',
        ],
        excelGrid,
        fileName: '매출정보_template',
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
      const fileName = `매출정보${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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
      this.gridDataProvider.addRow({ yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null, site: this.params.site != null ? this.siteMap[this.params.site] : null });
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
      let saveData = this.$refs.saleRescGrid.getSaveData();
      if (saveData.count <= 0) {
        this.$toast('info', '변경된 내용이 없습니다.');
        return;
      }
      this.duplicateIndices = this.$utils.findDuplicateIndices(this.duplicateKey, this.gridDataProvider.getJsonRows(0, -1));

      this.isValidteCellSaleRescGrid = true;
      let rslt = this.gridView.validateCells(null, false);
      this.isValidteCellSaleRescGrid = false;

      if (rslt === null) {
        this.$confirm('확인', '수정하신 내용을 저장 하시겠습니까?', async (confirm) => {
          if (confirm) {
            let param = {
              menuId: 'c0007005',
              delete: [{ queryId: 'C0007005_Del1', data: saveData.delete }],
              insert: [{ queryId: 'C0007005_Ins1', data: saveData.insert }],
              update: [{ queryId: 'C0007005_Update1', data: saveData.update }],
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
    onValidateColumnSaleRescGrid(grid, column, inserting, value, itemIndex, dataRow) {
      let error = {};
      if (!this.isValidteCellSaleRescGrid) return error;

      if (this.$utils.containsValue(['yyyymm', 'selCode', 'site', '거래명세서번호'], column.fieldName)) {
        if (_.isNil(value)) {
          error.level = 'error';
          error.message = '필수 입력입니다.';
        }
      }
      
      if (this.duplicateIndices.includes(itemIndex) && this.$utils.containsValue(['거래명세서번호'], column.fieldName)) {
        error.level = 'warning';
        error.message = '중복 입력입니다.';
      }

      if (this.$utils.containsValue(['선택', '출고처리', '부가세포함', '반품', '단가소급여부', '유상사급여부'], column.fieldName)) {
        if (!_.isNil(value) && value.length >= 2) {
          error.level = 'warning';
          error.message = '한자리로 입력해주세요.';
        }
      }

      return error;
    },

    setCellStyleCallbackSaleRescGrid(grid, cell) {
      let ret = {};
      if (cell.item.rowState == 'created' || cell.item.itemState == 'appending' || cell.item.itemState == 'inserting') {
        ret.editable = true;
        if (isNaN(cell.value)) {
          ret.styleName = 'edit tl';
        } else {
          ret.styleName = 'edit tr';
        }
      }
      return ret;
    },
  },
};
</script>
