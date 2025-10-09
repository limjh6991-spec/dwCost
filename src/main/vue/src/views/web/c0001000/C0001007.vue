/**
*	기준정보 > 일반코드 등록
*/
<template>
<div>
  <b-row >
      <b-col cols="4">
         <div class="grid_box">
          <div class="left_box">
            <div class="title">대분류</div>
            <div class="btn_wrap ms-auto">
              <b-button-group class="toggle_btn">
                <b-button :class="editMode ? '' : 'on'" @click="editModeClick(false)">조회</b-button>
								<b-button :class="editMode ? 'on' : ''" @click="editModeClick(true)">수정</b-button>
							</b-button-group>
              <div class="hr"></div>
              <b-button class="sub" @click="addBtnClick1">추가</b-button>
              <b-button class="main" @click="saveBtnClick1">저장</b-button>
            </div>
          </div>
          <div class="grid-border-none">
            <RealGrid
              ref="grid1"
              :uid="'grid1'"
              :step="'1'"
              :rows="grid1Rows"
              style="height: 100%"
            />
        </div>
      </div>
      </b-col>
      <b-col cols="8">
         <div class="grid_box">
            <div class="left_box">
              <div class="title">일반코드</div>
              <div class="btn_wrap ms-auto">
                  <b-button class="second" @click="excelBtnClick">엑셀</b-button>
                  <b-button class="sub" @click="addBtnClick2">추가</b-button>
                  <b-button class="main" @click="saveBtnClick2">저장</b-button>
                </div>            
            </div> 
          <div class="grid-border-none">
             <RealGrid
              ref="grid2"
              :uid="'grid2'"
              :step="'2'"
              :rows="grid2Rows"
              style="height: 100%"
            />
          </div>
        </div>
    </b-col>
  </b-row>
</div>
</template>

<script>
import { RowState } from "realgrid";
import grid1Field from "@web/c0001000/js/C0006007_1.js";
import grid2Field from "@web/c0001000/js/C0006007_2.js";

export default {
  name: "DW_C0001007",
  props: {},
  components: {},
  watch: {},
  data() {
    return {
      grid1:null,
      grid2:null,
      grid1Rows:[],
      grid2Rows:[],
      selectedMajCode:null,
      editMode:false,
    };
  },
  computed: {
    gridView1() {
      return this.$refs.grid1.getGridView();
    },
    gridDataProvider1() {
      return this.$refs.grid1.getGridDataProvider();
    },
    gridView2() {
      return this.$refs.grid2.getGridView();
    },
    gridDataProvider2() {
      return this.$refs.grid2.getGridDataProvider();
    },
  },
  created() {
    this.initializeGrid();
  },
  mounted() {
    //this.getGrid1Data();
  },
  activated(){
    this.getGrid1Data();
  },
  beforeUnmount() {},
  methods: {
    initializeGrid() {
      this.grid1 = _.cloneDeep(grid1Field);
      this.grid2 = _.cloneDeep(grid2Field);
    },
    async getGrid1Data() {
      this.gridView1.commit();

      let param = {
        menuId: "C0001007",
        queryId: "getGrid1Data",
        target: this.grid1Rows,
      };
      let resp = await this.$axios.api.search(param);
      this.editMode=false;
      //console.log(resp);
    },

    async getGrid2Data(majCode) {
      this.gridView2.commit();

      let param = {
        menuId: "C0001007",
        queryId: "getGrid2Data",
        queryParams: {majCode},
        target: this.grid2Rows,
      };
      let resp = await this.$axios.api.search(param);
      //console.log(resp);
    },

    searchClick() {
      this.getGrid1Data();
    },

    editModeClick(val){
      this.editMode=val;
    },
    //그리드 이벤트 설정
    //셀 클릭시
    /*
    async onCellClickedGrid1(grid, clickData) {
      if(this.editMode) return;
      if (clickData.cellType != "data"&&clickData.cellType != "check") return; 
      console.log(clickData);
      //2번째 그리드 수정중인것이 있으면 확인
      let saveData = this.$refs.grid2.getSaveData();
      if(saveData.insert.length>0||saveData.update.length>0){
        this.$confirm(
          "확인",
          "작성중인 내용이 사라집니다. 계속하시겠습니까?",
          async (confirm) => {
            if (confirm) {
              const prod = grid.getDataSource();
              let row = prod.getJsonRow(clickData.dataRow);
              this.selectedMajCode = row['majCode'];

              await this.getGrid2Data(this.selectedMajCode);
            }
          }
        );
      }
      else{
        const prod = grid.getDataSource();
        let row = prod.getJsonRow(clickData.dataRow);
        this.selectedMajCode = row['majCode'];

        await this.getGrid2Data(this.selectedMajCode);
      }   
    },*/
    //포커스 변경시
    async onCurrentChangedGrid1 (grid,clickData) {
      //console.log(clickData);
      if(this.editMode) return;
      let saveData = this.$refs.grid2.getSaveData();
      if(saveData.insert.length>0||saveData.update.length>0){
        this.$confirm(
          "확인",
          "작성중인 내용이 사라집니다. 계속하시겠습니까?",
          async (confirm) => {
            if (confirm) {
              const prod = grid.getDataSource();
              let row = prod.getJsonRow(clickData.dataRow);
              this.selectedMajCode = row['majCode'];

              await this.getGrid2Data(this.selectedMajCode);
            }
          }
        );
      }
      else{
        const prod = grid.getDataSource();
        let row = prod.getJsonRow(clickData.dataRow);
        this.selectedMajCode = row['majCode'];

        await this.getGrid2Data(this.selectedMajCode);
      }   
    },
    async excelBtnClick() {
      const grid = this.gridView2;

      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();

      const hours = String(now.getHours()).padStart(2, "0");
      const minutes = String(now.getMinutes()).padStart(2, "0");
      const seconds = String(now.getSeconds()).padStart(2, "0");
      const fileName = `일반코드_${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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

    addBtnClick1() {
      this.editMode=true;
      this.gridView1.commit();

      const rowCount = this.gridDataProvider1.getRowCount();
      let lastMajCode = this.gridDataProvider1.getValue(rowCount-1,'majCode');
      this.gridDataProvider1.addRow({majCode:Number(lastMajCode)+1});

      let itemIndex = this.gridView1.getItemCount() - 1;
      this.gridView1.setCurrent({ itemIndex: itemIndex});
    },

    addBtnClick2() {
      if(this.selectedMajCode==null){
        this.$toast("info", "먼저 대분류를 선택해주세요.");
        return;
      }
      this.gridView2.commit();
      this.gridDataProvider2.addRow({majCode:this.selectedMajCode,useYn:'true',createDate:this.getCurrentDate()});
      let itemIndex = this.gridView2.getItemCount() - 1;
      this.gridView2.setCurrent({ itemIndex: itemIndex});
    },

    delBtnClick() {
      this.gridView2.commit();
      const checkedRows = this.gridView2.getCheckedRows();
      if (checkedRows.length === 0) {
        this.$toast("info", "삭제할 행을 선택하세요");
      } else {
        let delItems = [];
        checkedRows.forEach((itemIndex) => {
          if (
            this.gridDataProvider2.getRowState(itemIndex) === RowState.CREATED
          ) {
            delItems.push(itemIndex);
          } else {
            this.gridDataProvider2.setRowState(itemIndex, RowState.DELETED);
          }
        });
        this.gridDataProvider2.removeRows(delItems);
      }
    },

    async saveBtnClick1() {
      this.gridView1.commit();
      await this.saveData1();
    },

    async saveBtnClick2() {
      this.gridView2.commit();
      await this.saveData2();
    },

    async saveData1() {
      this.$confirm(
        "확인",
        "수정하신 내용을 저장 하시겠습니까?",
        async (confirm) => {
          if (confirm) {
            let saveData = this.$refs.grid1.getSaveData();
              let param = {
                menuId:'C0001007',
                insert: [{queryId:'insertData1', data:saveData.insert}],
                update: [{queryId:'updateData1', data:saveData.update}],
              };

            try {
              let resp = await this.$axios.api.saveData(param);
              this.$toast("info", "저장완료");
              this.getGrid1Data();
            } 
            catch {
              this.$toast("info", "에러발생. 다시 작업해주세요.");
            }
          }
        }
      );
    },

    async saveData2() {
      this.$confirm(
        "확인",
        "수정하신 내용을 저장 하시겠습니까?",
        async (confirm) => {
          if (confirm) {
            let saveData = this.$refs.grid2.getSaveData();
              let param = {
                menuId:'C0001007',
                insert: [{queryId:'insertData2', data:saveData.insert}],
                update: [{queryId:'updateData2', data:saveData.update}],
              };

            try {
              let resp = await this.$axios.api.saveData(param);
              this.$toast("info", "저장완료");
              this.getGrid2Data(this.selectedMajCode);
            } 
            catch {
              this.$toast("info", "에러발생. 다시 작업해주세요.");
            }
          }
        }
      );
    },

    getCurrentDate() {
      const now = new Date();
      const year = now.getFullYear();
      const month = String(now.getMonth() + 1).padStart(2, "0");
      const day = String(now.getDate()).padStart(2, "0");

      return `${year}-${month}-${day}`;
    },
  },
};
</script>
<style lang="scss" scoped>
	::v-deep .row ,.col-4, .col-8{
		height: 100%;
	}
</style>
