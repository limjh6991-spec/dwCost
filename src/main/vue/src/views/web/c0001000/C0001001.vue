/**
*	기본정보 >  계정 코드
*/
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="2"> </b-col>
      </b-row>
      <div class="btn_area">
        <b-button @click="searchClick"
          ><span class="ico_search"></span>조회</b-button
        >
      </div>
    </div>
    <div class="grid_box search_onerow">
      <div class="left_box">
        <div class="btn_wrap ms-auto">
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
          <b-button class="sub" @click="addBtnClick">추가</b-button>
          <b-button @click="delBtnClick">삭제</b-button>
          <b-button class="main" @click="saveBtnClick">저장</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid
          ref="grid"
          :uid="'grid'"
          :step="'1'"
          :rows="gridRows"
          style="height: 100%"
        />
      </div>
    </div>
  </div>
</template>

<script>
import { RowState } from "realgrid";
import gridField from "@web/c0001000/js/C0001001.js";

export default {
  props: {},
  components: {},
  watch: {},
  data() {
    return {
      grid: null,
      gridRows: [],
    };
  },
  computed: {
    gridView() {
      return this.$refs.grid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.grid.getGridDataProvider();
    },
  },
  created() {
    this.initializeGrid();
  },
  mounted() {
    this.gridView.setFixedOptions({colCount: 1});
  },
  beforeUnmount() {},
  methods: {
    initializeGrid() {
      this.grid = _.cloneDeep(gridField);
    },

    cellStyleCallEdit(grid, model) {
      let rtn = {};
      rtn["editable"] = model.item.rowState === RowState.CREATED;
      return rtn;
    },

    async getDataList() {
      this.gridView.commit();

      let params = {
        gubun: '',//this.selectedGubun,
      };

      let param = {
        menuId: "c0001001",
        queryId: "selectTab1GridData",
        queryParams: params,
        target: this.gridRows,
      };
      let resp = await this.$axios.api.search(param);
      console.log(resp);
    },

    searchClick() {
      this.getDataList();
    },

    async excelBtnClick() {
      const grid = this.gridView;

      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();

      const hours = String(now.getHours()).padStart(2, "0");
      const minutes = String(now.getMinutes()).padStart(2, "0");
      const seconds = String(now.getSeconds()).padStart(2, "0");
      const fileName = `원가계정정보${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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
      this.gridDataProvider.addRow({});
      let itemIndex = this.gridView.getItemCount() - 1;
      this.gridView.setCurrent({ itemIndex: itemIndex });
    },

    delBtnClick() {
      this.gridView.commit();
      const checkedRows = this.gridView.getCheckedRows();
      if (checkedRows.length === 0) {
        this.$toast("info", "삭제할 행을 선택하세요");
      } else {
        let delItems = [];
        checkedRows.forEach((itemIndex) => {
          if (
            this.gridDataProvider.getRowState(itemIndex) === RowState.CREATED
          ) {
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
      this.$confirm(
        "확인",
        "수정하신 내용을 저장 하시겠습니까?",
        async (confirm) => {
          if (confirm) {
            let saveData = this.$refs.grid.getSaveData();
            console.log(saveData);
              let param = {
                menuId:'c0001001',
                delete: [{queryId:'deleteTab1Data', data:saveData.delete}],
                insert: [{queryId:'insertTab1Data', data:saveData.insert}],
                update: [{queryId:'updateTab1Data', data:saveData.update}],
              };

            try {
              let resp = await this.$axios.api.saveData(param);
              this.$toast("info", "저장완료");
              this.searchClick();
            } 
            catch {
              this.$toast("info", "에러발생. 다시 작업해주세요.");
            }
          }
        }
      );
    },
  },
};
</script>