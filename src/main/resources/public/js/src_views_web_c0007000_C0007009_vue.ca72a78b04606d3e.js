(self["webpackChunkvue"] = self["webpackChunkvue"] || []).push([["src_views_web_c0007000_C0007009_vue"],{

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007009.vue?vue&type=script&lang=js":
/*!**************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007009.vue?vue&type=script&lang=js ***!
  \**************************************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var core_js_modules_es_array_push_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! core-js/modules/es.array.push.js */ "./node_modules/core-js/modules/es.array.push.js");
/* harmony import */ var core_js_modules_es_array_push_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_array_push_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var core_js_modules_es_iterator_constructor_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! core-js/modules/es.iterator.constructor.js */ "./node_modules/core-js/modules/es.iterator.constructor.js");
/* harmony import */ var core_js_modules_es_iterator_constructor_js__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_iterator_constructor_js__WEBPACK_IMPORTED_MODULE_1__);
/* harmony import */ var core_js_modules_es_iterator_for_each_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! core-js/modules/es.iterator.for-each.js */ "./node_modules/core-js/modules/es.iterator.for-each.js");
/* harmony import */ var core_js_modules_es_iterator_for_each_js__WEBPACK_IMPORTED_MODULE_2___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_iterator_for_each_js__WEBPACK_IMPORTED_MODULE_2__);
/* harmony import */ var _store_auth_userAuthInfo__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! @store/auth/userAuthInfo */ "./src/store/auth/userAuthInfo.js");
/* harmony import */ var _web_store_C0001001_js__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(/*! @web/store/C0001001.js */ "./src/views/web/store/C0001001.js");
/* harmony import */ var _web_c0007000_js_C0007009_js__WEBPACK_IMPORTED_MODULE_5__ = __webpack_require__(/*! @web/c0007000/js/C0007009.js */ "./src/views/web/c0007000/js/C0007009.js");
/* harmony import */ var _web_c0007000_js_C0007009_js__WEBPACK_IMPORTED_MODULE_5___default = /*#__PURE__*/__webpack_require__.n(_web_c0007000_js_C0007009_js__WEBPACK_IMPORTED_MODULE_5__);
/* harmony import */ var realgrid__WEBPACK_IMPORTED_MODULE_6__ = __webpack_require__(/*! realgrid */ "./node_modules/realgrid/dist/main.esm.js");







/* harmony default export */ __webpack_exports__["default"] = ({
  name: 'C0007009',
  props: {
    yearList: {
      type: Array,
      default: () => []
    }
  },
  setup() {
    const srchInfo = (0,_web_store_C0001001_js__WEBPACK_IMPORTED_MODULE_4__.useC0001001)();
    const userAuthInfo = (0,_store_auth_userAuthInfo__WEBPACK_IMPORTED_MODULE_3__.useUserAuthInfo)();
    return {
      srchInfo,
      userAuthInfo
    };
  },
  data() {
    return {
      viewGrid: null,
      viewGridRows: [],
      deletedRows: [],
      hasSearched: false,
      params: {
        yyyymm: null,
        site: 'HQ'
      },
      siteMap: {
        본사: 'HQ',
        VINA: 'VN',
        HQ: 'HQ',
        VN: 'VN'
      },
      selectedModel: '',
      selectedModelInfo: null,
      selectedRowIndex: null,
      isClosedMonth: false
    };
  },
  computed: {
    viewGridView() {
      return this.$refs.viewGrid && this.$refs.viewGrid.getGridView();
    },
    viewGridDataProvider() {
      return this.$refs.viewGrid && this.$refs.viewGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    }
  },
  watch: {
    'params.yyyymm': async function (newVal) {
      if (newVal) {
        this.onDateChange();
        await this.checkClosingMonth();
      } else {
        this.isClosedMonth = false;
      }
    },
    'srchInfo.yyyymm': {
      handler(newVal) {
        if (newVal) this.params.yyyymm = newVal;
      }
    },
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          if (this.viewGridView && this.hasSearched) {
            this.searchClick();
          }
        }
      }
    }
  },
  created() {
    this.viewGrid = _.cloneDeep((_web_c0007000_js_C0007009_js__WEBPACK_IMPORTED_MODULE_5___default()));
  },
  mounted() {
    this.params.yyyymm = this.srchInfo.yyyymm;
    this.params.site = this.srchInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    this.$nextTick(async () => {
      await this.checkClosingMonth();
      const gv = this.viewGridView;
      if (!gv) return;
      gv.onEditBegin = (grid, index) => {
        if (index.fieldName === '구분') {
          return false;
        }
      };
    });
  },
  activated() {
    this.reInitScreen();
  },
  methods: {
    initializeGrid() {
      this.modelGrid = _.cloneDeep((_web_c0007000_js_C0007009_js__WEBPACK_IMPORTED_MODULE_5___default()));
    },
    async checkClosingMonth() {
      const yyyymm = this.params.yyyymm ? this.params.yyyymm.replaceAll('-', '') : null;
      if (!yyyymm) {
        this.isClosedMonth = false;
        return;
      }
      try {
        const res = await this.$axios.get('/api/common/closing-month/check', {
          params: {
            yyyymm
          }
        });
        this.isClosedMonth = res?.data?.isClosed === true || res?.data?.isClosed === 'Y';
      } catch (e) {
        console.error('마감월 조회 실패', e);
        this.isClosedMonth = false;
      }
    },
    reInitScreen() {
      this.params.yyyymm = this.srchInfo.yyyymm;
      this.params.site = this.srchInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
      this.viewGridRows = [];
      this.deletedRows = [];
      this.hasSearched = false;
      if (this.viewGridDataProvider) this.viewGridDataProvider.clearRows();
      this.selectedModel = '';
      this.selectedRowIndex = null;
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({
        yyyymm: this.params.yyyymm
      });
    },
    addViewRow() {
      if (!this.viewGridView || !this.viewGridDataProvider) return;
      this.viewGridView.commit();
      this.viewGridDataProvider.addRow({
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        selCode: 'ACTUAL',
        siteOrg: this.siteMap[this.params.site] || this.params.site,
        site: this.params.site,
        구분: '',
        도우코드: '',
        rmaIn: null,
        rmaOut: null,
        생성자: this.userAuthInfo.userInfo.userName,
        생성시각: null
      });
      let itemIndex = this.viewGridView.getItemCount() - 1;
      this.viewGridView.setCurrent({
        itemIndex: itemIndex
      });
    },
    async getDataList() {
      const yyyymm = this.params.yyyymm ? this.params.yyyymm.replaceAll('-', '') : null;
      const siteCode = this.siteMap[this.params.site] || this.params.site;
      const params = {
        yyyymm,
        site: siteCode
      };
      const param = {
        menuId: 'c0007009',
        queryId: 'selectRmaData',
        queryParams: params,
        target: this.viewGridRows
      };
      try {
        await this.$axios.api.search(param);
      } catch (e) {
        console.error('❌ 조회 실패:', e);
        this.$toast('error', '조회 중 오류가 발생했습니다.');
      }
    },
    async searchClick() {
      if (!this.params.yyyymm) {
        this.$toast('error', '년월을 선택해 주세요.');
        return;
      }
      if (this.viewGridView) {
        this.viewGridView.commit();
      } else {
        return;
      }
      this.hasSearched = true;
      await this.getDataList();
      const gv = this.viewGridView;
      if (gv) {}
    },
    onCellClickedViewGrid(grid, clickData) {
      if (clickData.cellType !== 'data') return;
      const fieldName = clickData.fieldName;
      const itemIndex = clickData.itemIndex;
      if (fieldName === '도우코드') {
        if (itemIndex == null || itemIndex < 0) return;
        const rowState = this.viewGridDataProvider.getRowState(itemIndex);
        if (rowState !== 'created') {
          return;
        }
        if (grid.isEditing()) {
          try {
            grid.commit(true);
          } catch (e) {
            console.warn('⚠️ [onCellClickedViewGrid] commit 중 에러 → cancel()', e);
            try {
              grid.cancel();
            } catch (e2) {
              console.warn('⚠️ [onCellClickedViewGrid] cancel 실패', e2);
            }
          }
        }
        this.selectedRowIndex = itemIndex;
        this.selectedModel = '';
        this.openModelPopup();
      }
    },
    async deleteRmaData() {
      if (!this.viewGridView || !this.viewGridDataProvider) return;
      this.viewGridView.commit();
      const checkedRows = this.viewGridView.getCheckedRows();
      if (checkedRows.length === 0) {
        this.$toast('info', '삭제할 행을 선택하세요');
        return;
      }
      const deletedCount = checkedRows.length;
      this.$confirm('확인', `${deletedCount}건을 삭제하시겠습니까?`, async confirmed => {
        if (!confirmed) return;
        let newRows = [];
        let existingRows = [];
        checkedRows.forEach(itemIndex => {
          if (this.viewGridDataProvider.getRowState(itemIndex) === realgrid__WEBPACK_IMPORTED_MODULE_6__.RowState.CREATED) {
            newRows.push(itemIndex);
          } else {
            existingRows.push(this.viewGridDataProvider.getJsonRow(itemIndex));
          }
        });
        if (newRows.length > 0) {
          this.viewGridDataProvider.removeRows(newRows);
        }
        if (existingRows.length > 0) {
          try {
            let param = {
              menuId: 'c0007009',
              delete: [{
                queryId: 'deleteRmaData',
                data: existingRows
              }]
            };
            await this.$axios.api.saveData(param);
            this.searchClick();
          } catch {
            this.$toast('error', '삭제 중 에러가 발생했습니다.');
            return;
          }
        }
        this.$toast('success', `${deletedCount}건이 삭제되었습니다.`);
      });
    },
    async updateRmaData() {
      if (!this.viewGridView || !this.viewGridDataProvider) return;
      this.viewGridView.commit();
      let saveData = this.$refs.viewGrid.getSaveData();
      if (saveData.count <= 0) {
        this.$toast('info', '변경된 내용이 없습니다.');
        return;
      }
      const allRows = [...(saveData.insert || []), ...(saveData.update || [])];
      const emptyDowuCode = allRows.find(row => !row.도우코드 || row.도우코드.trim() === '');
      if (emptyDowuCode) {
        this.$toast('error', '도우코드가 선택되지 않았습니다.');
        return;
      }
      this.$confirm('확인', '수정하신 내용을 저장 하시겠습니까?', async confirm => {
        if (confirm) {
          let param = {
            menuId: 'c0007009',
            delete: [{
              queryId: 'deleteRmaData',
              data: saveData.delete
            }],
            insert: [{
              queryId: 'insertRmaData',
              data: saveData.insert
            }],
            update: [{
              queryId: 'updateRmaData',
              data: saveData.update
            }]
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
    },
    onEditCommitViewGrid(grid, index, oldValue, newValue) {
      const fieldName = index.fieldName || grid.getColumn(index.column).fieldName;
      if (fieldName !== 'rmaIn') {
        return;
      }
      const rmaIn = Number(newValue || 0);
      const outMonth = Number(grid.getValue(index.itemIndex, 'outMonth') || 0);
      if (outMonth && rmaIn > outMonth) {
        grid.setValue(index.itemIndex, 'rmaIn', oldValue);
      }
    },
    openModelPopup() {
      const siteCode = this.siteMap[this.params.site] || this.params.site;
      const yyyymm = this.params.yyyymm ? this.params.yyyymm.replaceAll('-', '') : null;
      const queryParams = {
        yyyymm: yyyymm,
        site: siteCode
      };
      if (this.selectedModel && this.selectedModel.trim() !== '') {
        queryParams.model = this.selectedModel;
      }
      const params = {
        dialogTitle: '모델 정보',
        popUpSize: 'lg',
        step: 7,
        height: 500,
        gridJs: 'C0007009Popup.js',
        search: {
          menuId: 'c0007009',
          queryId: 'selectModelPopup',
          queryParams: queryParams
        },
        showButton: false,
        confirmOnEnter: true
      };
      this.$refs.cmDialog1C0007009.openDialog(params);
      this.$nextTick(() => {
        setTimeout(() => {
          const dialog = this.$refs.cmDialog1C0007009;
          const gridWrapper = dialog?.$refs?.cmDialog1Grid;
          const gridView = gridWrapper?.getGridView?.();
          const dp = gridWrapper?.getGridDataProvider?.();
          if (!gridView || !dp) {
            return;
          }
          gridView.onCellDblClicked = (grid, clickData) => {
            if (clickData.cellType !== 'data') return;
            if (grid.isEditing()) {
              try {
                grid.commit(true);
              } catch (e) {
                console.warn('⚠️ [Popup] commit 에러 → cancel()', e);
                try {
                  grid.cancel();
                } catch (e2) {
                  console.warn('⚠️ [Popup] cancel 도 실패', e2);
                }
              }
            }
            const row = dp.getJsonRow(clickData.dataRow);
            if (!row) return;
            const mainGrid = this.viewGridView;
            if (mainGrid && mainGrid.isEditing()) {
              try {
                mainGrid.commit(true);
              } catch (e) {
                console.warn('⚠️ [Popup] 메인 commit 에러 → cancel()', e);
                try {
                  mainGrid.cancel();
                } catch (e2) {
                  console.warn('⚠️ [Popup] 메인 cancel 도 실패', e2);
                }
              }
            }
            this.applyModelFromPopup(row);
            if (typeof dialog.closeDialog === 'function') dialog.closeDialog();else if (typeof dialog.hide === 'function') dialog.hide();else if (typeof dialog.close === 'function') dialog.close();else console.warn('닫기 메소드 없음');
          };
        }, 50);
      });
    },
    handleModelConfirm(params) {
      if (params.gridJs !== 'C0007009Popup.js') return;
      const gridView = params.gridView;
      const dp = params.dataProvider;
      if (!gridView || !dp) {
        this.$toast('error', '그리드 정보를 찾을 수 없습니다.');
        return;
      }
      if (gridView.isEditing()) {
        try {
          gridView.commit(true);
        } catch (e) {
          console.warn('⚠️ [handleModelConfirm] commit 에러 → cancel()', e);
          try {
            gridView.cancel();
          } catch (e2) {
            console.warn('⚠️ [handleModelConfirm] cancel 도 실패', e2);
          }
        }
      }
      const checked = gridView.getCheckedRows(true);
      if (!checked || checked.length === 0) {
        this.$toast('info', '선택된 모델이 없습니다.');
        return;
      }
      const row = dp.getJsonRow(checked[0]);
      const mainGrid = this.viewGridView;
      if (mainGrid && mainGrid.isEditing()) {
        try {
          mainGrid.commit(true);
        } catch (e) {
          console.warn('⚠️ [handleModelConfirm] 메인 commit 에러 → cancel()', e);
          try {
            mainGrid.cancel();
          } catch (e2) {
            console.warn('⚠️ [handleModelConfirm] 메인 cancel 도 실패', e2);
          }
        }
      }
      this.applyModelFromPopup(row);
    },
    applyModelFromPopup(row) {
      const modelValue = row['도우코드'];
      if (!modelValue) {
        this.$toast('error', '모델 정보를 찾을 수 없습니다.');
        return;
      }
      if (!this.viewGridDataProvider || this.selectedRowIndex == null) {
        this.$toast('error', '대상 행 정보를 찾을 수 없습니다.');
        return;
      }
      this.viewGridDataProvider.setValue(this.selectedRowIndex, '도우코드', modelValue);
      const lastChar = modelValue.slice(-1).toUpperCase();
      const category = lastChar === 'P' ? '양산' : '개발';
      this.viewGridDataProvider.setValue(this.selectedRowIndex, '구분', category);
      const outMonth = row['outMonth'] || row['OUT_MONTH'] || row['outQty'];
      if (outMonth) {
        this.viewGridDataProvider.setValue(this.selectedRowIndex, 'outMonth', outMonth);
      }
      if (this.viewGridRows[this.selectedRowIndex]) {
        this.viewGridRows[this.selectedRowIndex]['도우코드'] = modelValue;
        this.viewGridRows[this.selectedRowIndex]['구분'] = category;
        if (outMonth) {
          this.viewGridRows[this.selectedRowIndex]['outMonth'] = outMonth;
        }
      }
      this.selectedRowIndex = null;
      this.selectedGridType = null;
      this.selectedModel = '';
    }
  }
});

/***/ }),

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007009.vue?vue&type=template&id=8eddfc1a":
/*!******************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007009.vue?vue&type=template&id=8eddfc1a ***!
  \******************************************************************************************************************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* binding */ render; }
/* harmony export */ });
/* harmony import */ var vue__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! vue */ "./node_modules/vue/dist/vue.runtime.esm-bundler.js");

const _hoisted_1 = {
  class: "search_box"
};
const _hoisted_2 = {
  class: "form-floating"
};
const _hoisted_3 = {
  class: "form-floating"
};
const _hoisted_4 = {
  class: "btn_area"
};
const _hoisted_5 = {
  class: "grid_box search_onerow"
};
const _hoisted_6 = {
  class: "left_box"
};
const _hoisted_7 = {
  class: "btn_wrap ms-auto"
};
const _hoisted_8 = {
  class: "grid-border-none"
};
function render(_ctx, _cache, $props, $setup, $data, $options) {
  const _component_date_picker = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("date-picker");
  const _component_b_col = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("b-col");
  const _component_b_row = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("b-row");
  const _component_b_button = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("b-button");
  const _component_RealGrid = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("RealGrid");
  const _component_CmDialog1 = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("CmDialog1");
  return (0,vue__WEBPACK_IMPORTED_MODULE_0__.openBlock)(), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementBlock)("div", null, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_1, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_row, {
    class: "search_area"
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_col, {
      cols: "1"
    }, {
      default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_2, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_date_picker, {
        label: "기준월",
        mode: "month",
        modelValue: $data.params.yyyymm,
        "onUpdate:modelValue": _cache[0] || (_cache[0] = $event => $data.params.yyyymm = $event)
      }, null, 8 /* PROPS */, ["modelValue"]), _cache[2] || (_cache[2] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", null, "기준월", -1 /* CACHED */))])]),
      _: 1 /* STABLE */
    }), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_col, {
      cols: "2",
      class: "ms-3"
    }, {
      default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_3, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.withDirectives)((0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("input", {
        autocomplete: "off",
        type: "text",
        class: "form-control label-60",
        id: "floating",
        placeholder: "Site",
        "onUpdate:modelValue": _cache[1] || (_cache[1] = $event => $data.params.site = $event),
        disabled: true
      }, null, 512 /* NEED_PATCH */), [[vue__WEBPACK_IMPORTED_MODULE_0__.vModelText, $data.params.site]]), _cache[3] || (_cache[3] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", {
        for: "floating"
      }, "사업장", -1 /* CACHED */))])]),
      _: 1 /* STABLE */
    })]),
    _: 1 /* STABLE */
  }), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_4, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    onClick: $options.searchClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[4] || (_cache[4] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("span", {
      class: "ico_search"
    }, null, -1 /* CACHED */), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)(" 조회 ", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_5, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_6, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_7, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", null, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.withDirectives)((0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    onClick: $options.addViewRow,
    class: "sub"
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[5] || (_cache[5] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)(" 추가", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"]), [[vue__WEBPACK_IMPORTED_MODULE_0__.vShow, !$data.isClosedMonth]]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.withDirectives)((0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    class: "second",
    onClick: $options.deleteRmaData
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[6] || (_cache[6] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)(" 삭제", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"]), [[vue__WEBPACK_IMPORTED_MODULE_0__.vShow, !$data.isClosedMonth]]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.withDirectives)((0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    class: "main",
    onClick: $options.updateRmaData
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[7] || (_cache[7] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("저장", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"]), [[vue__WEBPACK_IMPORTED_MODULE_0__.vShow, !$data.isClosedMonth]])])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_8, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_RealGrid, {
    ref: "viewGrid",
    uid: 'viewGrid',
    rows: $data.viewGridRows,
    style: {
      "height": "100%"
    },
    fixLayoutWidth: false,
    onCellClicked: $options.onCellClickedViewGrid,
    onEditCommit: $options.onEditCommitViewGrid
  }, null, 8 /* PROPS */, ["rows", "onCellClicked", "onEditCommit"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_CmDialog1, {
    ref: "cmDialog1C0007009",
    onConfirm: $options.handleModelConfirm
  }, null, 8 /* PROPS */, ["onConfirm"])]);
}

/***/ }),

/***/ "./src/views/web/c0007000/C0007009.vue":
/*!*********************************************!*\
  !*** ./src/views/web/c0007000/C0007009.vue ***!
  \*********************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _C0007009_vue_vue_type_template_id_8eddfc1a__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./C0007009.vue?vue&type=template&id=8eddfc1a */ "./src/views/web/c0007000/C0007009.vue?vue&type=template&id=8eddfc1a");
/* harmony import */ var _C0007009_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./C0007009.vue?vue&type=script&lang=js */ "./src/views/web/c0007000/C0007009.vue?vue&type=script&lang=js");
/* harmony import */ var _node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ../../../../node_modules/vue-loader/dist/exportHelper.js */ "./node_modules/vue-loader/dist/exportHelper.js");




;
const __exports__ = /*#__PURE__*/(0,_node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__["default"])(_C0007009_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"], [['render',_C0007009_vue_vue_type_template_id_8eddfc1a__WEBPACK_IMPORTED_MODULE_0__.render],['__file',"src/views/web/c0007000/C0007009.vue"]])
/* hot reload */
if (false) // removed by dead control flow
{}


/* harmony default export */ __webpack_exports__["default"] = (__exports__);

/***/ }),

/***/ "./src/views/web/c0007000/C0007009.vue?vue&type=script&lang=js":
/*!*********************************************************************!*\
  !*** ./src/views/web/c0007000/C0007009.vue?vue&type=script&lang=js ***!
  \*********************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0007009_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0007009_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./C0007009.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007009.vue?vue&type=script&lang=js");
 

/***/ }),

/***/ "./src/views/web/c0007000/C0007009.vue?vue&type=template&id=8eddfc1a":
/*!***************************************************************************!*\
  !*** ./src/views/web/c0007000/C0007009.vue?vue&type=template&id=8eddfc1a ***!
  \***************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0007009_vue_vue_type_template_id_8eddfc1a__WEBPACK_IMPORTED_MODULE_0__.render; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0007009_vue_vue_type_template_id_8eddfc1a__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./C0007009.vue?vue&type=template&id=8eddfc1a */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007009.vue?vue&type=template&id=8eddfc1a");


/***/ }),

/***/ "./src/views/web/c0007000/js/C0007009.js":
/*!***********************************************!*\
  !*** ./src/views/web/c0007000/js/C0007009.js ***!
  \***********************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

/*
 * 타시스템 I/F&Upload > 불량반품 - 조회용 그리드
 */
const {
  ValueType
} = __webpack_require__(/*! realgrid */ "./node_modules/realgrid/dist/main.js");
function isNewRow(dataCell) {
  return dataCell.item && (dataCell.item.rowState === 'created' || dataCell.item.itemState === 'appending' || dataCell.item.itemState === 'inserting');
}

// 고정 컬럼
function readOnly(styleName = 'tl') {
  return function () {
    return {
      editable: false,
      styleName
    };
  };
}

// 추가 행 편집 스타일
function addNewRow(styleName = 'edit tl') {
  return function (grid, dataCell) {
    const canEdit = isNewRow(dataCell);
    return {
      editable: canEdit,
      styleName: canEdit ? `edit ${styleName}` : styleName
    };
  };
}
const fields = [{
  fieldName: 'rowSeq',
  dataType: ValueType.NUMBER
}, {
  fieldName: 'yyyymm',
  dataType: ValueType.TEXT
}, {
  fieldName: 'selCode',
  dataType: ValueType.TEXT
}, {
  fieldName: 'siteOrg',
  dataType: ValueType.TEXT
}, {
  fieldName: 'site',
  dataType: ValueType.TEXT
}, {
  fieldName: '구분',
  dataType: ValueType.TEXT
}, {
  fieldName: '도우코드',
  dataType: ValueType.TEXT
}, {
  fieldName: 'rmaIn',
  dataType: ValueType.NUMBER
}, {
  fieldName: 'rmaOut',
  dataType: ValueType.NUMBER
}, {
  fieldName: 'outMonth',
  dataType: ValueType.NUMBER
}];
const viewGrid = {
  options: {
    checkBar: {
      visible: true,
      exclusive: false,
      syncHeadCheck: true
    },
    copy: {
      enabled: true,
      singleMode: false
    },
    display: {
      columnMovable: false,
      editItemMerging: true,
      fitStyle: 'fill',
      emptyMessage: '조회된 데이터가 없습니다.',
      hscrollBar: true,
      showEmptyMessage: true,
      rowHeight: 30,
      showEmptyRows: true
    },
    edit: {
      editable: true,
      insertable: false,
      appendable: false
    },
    footer: {
      visible: true,
      height: 30
    },
    header: {
      height: 25
    },
    hideDeletedRows: false,
    paste: {
      enabled: false
    },
    rowIndicator: {
      visible: true
    },
    sorting: {
      enabled: false
    },
    stateBar: {
      visible: true
    }
  },
  fields,
  columns: [{
    name: 'rowSeq',
    fieldName: 'rowSeq',
    width: 0,
    visible: false
  }, {
    name: 'yyyymm',
    fieldName: 'yyyymm',
    width: 80,
    header: {
      text: 'YYYYMM'
    },
    autoFilter: true,
    styleName: 'tc',
    styleCallback: readOnly('tc')
  }, {
    name: 'selCode',
    fieldName: 'selCode',
    width: 80,
    header: {
      text: 'SEL_CODE'
    },
    autoFilter: true,
    styleName: 'tc',
    styleCallback: readOnly('tc')
  }, {
    name: 'siteOrg',
    fieldName: 'siteOrg',
    width: 0,
    header: {
      text: 'SITE_ORG'
    },
    visible: false,
    styleName: 'tc'
  }, {
    name: 'site',
    fieldName: 'site',
    width: 80,
    header: {
      text: '사이트'
    },
    autoFilter: true,
    styleName: 'tc',
    styleCallback: readOnly('tc')
  }, {
    name: '구분',
    fieldName: '구분',
    width: 80,
    header: {
      text: '구분'
    },
    autoFilter: true,
    styleName: 'tc',
    styleCallback: readOnly('tc')
  }, {
    name: '도우코드',
    fieldName: '도우코드',
    width: 150,
    header: {
      text: '도우코드'
    },
    autoFilter: true,
    styleName: 'tc',
    styleCallback: readOnly('tc')
  }, {
    name: 'rmaIn',
    fieldName: 'rmaIn',
    width: 120,
    header: {
      text: 'RMA_IN'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    styleCallback: addNewRow('tr'),
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'rmaOut',
    fieldName: 'rmaOut',
    width: 120,
    header: {
      text: 'RMA_OUT'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    styleCallback: addNewRow('tr'),
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'outMonth',
    fieldName: 'outMonth',
    width: 0,
    visible: false,
    header: {
      text: 'OUT_MONTH'
    },
    styleName: 'tr'
  }]
};
module.exports = viewGrid;

/***/ }),

/***/ "./src/views/web/store/C0001001.js":
/*!*****************************************!*\
  !*** ./src/views/web/store/C0001001.js ***!
  \*****************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   useC0001001: function() { return /* binding */ useC0001001; }
/* harmony export */ });
/* harmony import */ var pinia__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! pinia */ "./node_modules/pinia/dist/pinia.mjs");
/* harmony import */ var moment__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! moment */ "./node_modules/moment/moment.js");
/* harmony import */ var moment__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(moment__WEBPACK_IMPORTED_MODULE_1__);


const useC0001001 = (0,pinia__WEBPACK_IMPORTED_MODULE_0__.defineStore)('c0001001', {
  state: () => ({
    yyyymm: moment__WEBPACK_IMPORTED_MODULE_1___default()().format('YYYY-MM'),
    currency: 'USD' // VINA 화면 표시통화 (USD 기본 / KRW / VND). 화면군 공유
  }),
  getters: {
    getSearchkInfo: state => {
      return {
        yyyymm: state.yyyymm
      };
    },
    curCurrency: state => state.currency
  },
  actions: {
    setSearchInfo(obj) {
      this.yyyymm = obj.yyyymm;
    },
    setCurrency(currency) {
      this.currency = currency || 'USD';
    }
  }
});

/***/ })

}]);
//# sourceMappingURL=src_views_web_c0007000_C0007009_vue.ca72a78b04606d3e.js.map