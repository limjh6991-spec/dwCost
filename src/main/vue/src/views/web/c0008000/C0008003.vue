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
        <b-col cols="2" class="ms-3">
          <div class="form-floating">
            <select class="form-select label-60" id="floatingSelect" v-model="params.gubun" @change="onGubunChange">
              <option v-for="gubun in gubunList" :key="gubun.value" :value="gubun.value">
                {{ gubun.text }}
              </option>
            </select>
            <label for="floatingSelect" class="select">비용구분</label>
          </div>
        </b-col>
        <b-col cols="2" class="ms-3" v-show="params.gubun !== '전체'">
          <div class="form-floating">
            <select class="form-select label-60" id="floatingSelect" v-model="params.seq">
              <option v-for="seq in currentSeqList" :key="seq.value" :value="seq.value">
                {{ seq.text }}
              </option>
            </select>
            <label for="floatingSelectSeq" class="select">제조비용</label>
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
            <b-button class="second" @click="excelBtnClick">엑셀</b-button>
        </div>
      </div>
        <div class="grid-border-none">
            <RealGrid ref="amtCheckGrid" :uid="'amtCheckGrid'" :step="'1'" :rows="amtCheckGridRows" style="height: 100%"/>
        </div>
      </div>
    </div> 
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0008000/js/C0008003.js';

export default {
    components: {},
    props: {},
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
        amtCheckGrid: null,
        amtCheckGridRows: [],
        params: {
            yyyymm: null,
            site: 'HQ',
            gubun: '전체',
            seq: '전체', 
        },
        gubunList: [
            { value: '전체', text: '전체' },
            { value: '제조경비', text: '제조경비' },
            { value: '판매관리비', text: '판매관리비' },
        ],
        seqListMfg: [
            { value: '전체', text: '전체' },
            { value: '1', text: '제조경비' },
            { value: '2', text: '연구개발부서' },
            { value: '3', text: '카세트팀' },
        ],
        seqListSga: [
            { value: '전체', text: '전체' },
            { value: '4', text: '판매관리비' },
            { value: '5', text: '연구개발부서' },
        ],
        siteMap: {
            본사: 'HQ',
            VINA: 'VN',
            HQ: 'HQ',
            VN: 'VN',
        },
      };
    },
    computed: {
        gridView() {
            return this.$refs.amtCheckGrid.getGridView();
        },
        gridDataProvider() {
            return this.$refs.amtCheckGrid.getGridDataProvider();
        },
        prodCtg() {
            return this.userAuthInfo.curProdCtg;
        },
               // ✅ 구분에 따라 동적으로 하위 탭 리스트 변경
        currentSeqList() {
            if (this.params.gubun === '제조경비') {
                return this.seqListMfg;
            } else if (this.params.gubun === '판매관리비') {
                return this.seqListSga;
            }
            return [];
        },
        // ✅ 하위 탭 라벨 동적 변경
        seqLabel() {
            if (this.params.gubun === '제조경비') {
                return '제조경비';
            } else if (this.params.gubun === '판매관리비') {
                return '판매관리비';
            }
            return '상세구분';
        },
    },
    watch: {
        'params.yyyymm': function (newVal) {
            if (newVal) {
                this.onDateChange();
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
            if (this.$refs.amtCheckGrid != null) {
                this.initialize();
                this.searchClick();
            }
          } 
        },
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
            //var current = new Date();
            this.params.yyyymm = this.srchInfo.yyyymm; //`${current.getFullYear()}-${(current.getMonth() + 1).toString().padStart(2, '0')}`;
            this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
            this.params.gubun = '전체';
            this.params.seq = '전체';
        },
        initializeGrid() {
            this.amtCheckGrid = _.cloneDeep(gridField);
        },
        onDateChange() {
            this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
        },
        onGubunChange() {
            this.params.seq = '전체'; // 구분 변경 시 하위 탭 리셋
        },
        async getDataList() {
            if (!this.params.yyyymm) {
                this.$toast('error', '기준월을 선택해주세요.');
                return;
            }
         
        const params = {
            yyyymm: this.params.yyyymm?.replaceAll('-', ''),
            site: this.siteMap[this.params.site] || this.params.site,
            gubun: this.params.gubun,
            seq: this.params.seq,
        };

        const param = {
            menuId: 'c0008000',
            queryId: 'C0008003_Select',
            queryParams: params,
            target: this.amtCheckGridRows,
        };

        try {
            const response = await this.$axios.api.search(param);

        } catch (e) {
            console.error('조회 실패:', e);
            console.error('❌ 에러 상세:', e.response?.data || e.message);
            this.$toast('error', '데이터 조회 중 오류가 발생했습니다.');
        }
        },
        searchClick() {
          this.getDataList();
        },
        async excelBtnClick() {
            const grid = this.gridView;

            if (!grid) {
                this.$toast('error', '그리드가 초기화되지 않았습니다.');
                return;
            }

            const now = new Date();
            const yyyymmdd = this.$utils.getTodayDate();

            const hours = String(now.getHours()).padStart(2, '0');
            const minutes = String(now.getMinutes()).padStart(2, '0');
            const seconds = String(now.getSeconds()).padStart(2, '0');
            const fileName = `배부금액 검증${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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
    },
};
</script>