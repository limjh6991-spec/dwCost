
<!--
  전체 주석 처리됨: 기존 C0001003.vue 코드
  2025-10-30 기준, 사용 중지됨

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
  ...기존 script 전체...
  </script>
-->