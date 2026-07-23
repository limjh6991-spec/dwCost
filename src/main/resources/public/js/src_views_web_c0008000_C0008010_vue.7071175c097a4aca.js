(self["webpackChunkvue"] = self["webpackChunkvue"] || []).push([["src_views_web_c0008000_C0008010_vue"],{

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0008000/C0008010.vue?vue&type=script&lang=js":
/*!**************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0008000/C0008010.vue?vue&type=script&lang=js ***!
  \**************************************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _store_auth_userAuthInfo__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! @store/auth/userAuthInfo */ "./src/store/auth/userAuthInfo.js");
/* harmony import */ var _web_store_C0001001_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! @web/store/C0001001.js */ "./src/views/web/store/C0001001.js");
/* harmony import */ var _web_c0008000_js_C0008010_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! @web/c0008000/js/C0008010.js */ "./src/views/web/c0008000/js/C0008010.js");
/* harmony import */ var _web_c0008000_js_C0008010_js__WEBPACK_IMPORTED_MODULE_2___default = /*#__PURE__*/__webpack_require__.n(_web_c0008000_js_C0008010_js__WEBPACK_IMPORTED_MODULE_2__);



/* harmony default export */ __webpack_exports__["default"] = ({
  props: {},
  components: {},
  setup() {
    const srchInfo = (0,_web_store_C0001001_js__WEBPACK_IMPORTED_MODULE_1__.useC0001001)();
    const userAuthInfo = (0,_store_auth_userAuthInfo__WEBPACK_IMPORTED_MODULE_0__.useUserAuthInfo)();
    return {
      srchInfo,
      userAuthInfo
    };
  },
  data() {
    return {
      saleCogmGrid: null,
      saleCogmGridRows: [],
      params: {
        yyyymm: null,
        site: 'HQ',
        selcode: 'ACTUAL'
      },
      siteMap: {
        본사: 'HQ',
        //DB map
        VINA: 'VN',
        //DB map
        HQ: 'HQ',
        //DB map
        VN: 'VN' //DB map
      }
    };
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
      }
    },
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          if (this.$refs.saleCogmGrid != null) {
            this.initialize();
            this.searchClick();
          }
        }
      }
    }
  },
  computed: {
    gridView() {
      return this.$refs.saleCogmGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.saleCogmGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    }
  },
  created() {
    this.initialize();
    this.initializeGrid();
  },
  mounted() {},
  beforeUnmount() {},
  methods: {
    initialize() {
      this.params.yyyymm = this.srchInfo.yyyymm;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },
    initializeGrid() {
      this.saleCogmGrid = _.cloneDeep((_web_c0008000_js_C0008010_js__WEBPACK_IMPORTED_MODULE_2___default()));
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({
        yyyymm: this.params.yyyymm
      });
    },
    async getDataList() {
      this.gridView.commit();
      let params = {
        yyyy: this.params.yyyymm?.substring(0, 4),
        site: this.params.site != null ? this.siteMap[this.params.site] : null,
        selcode: this.params.selcode != null ? this.params.selcode : null
      };
      let param = {
        menuId: 'c0008000',
        queryId: 'C0008010_Sch1',
        queryParams: params,
        target: this.saleCogmGridRows
      };
      let resp = await this.$axios.api.search(param);
    },
    searchClick() {
      this.getDataList();
    },
    async excelBtnClick() {
      const grid = this.gridView;
      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `매출원가${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;
      const options = {
        type: 'excel',
        target: 'local',
        fileName: fileName,
        progressMessage: '엑셀 Export중입니다.',
        applyDynamicStyles: true,
        done: function () {
          alert('엑셀 내보내기가 완료되었습니다!');
        }
      };
      grid.exportGrid(options);
    }
  }
});

/***/ }),

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0008000/C0008010.vue?vue&type=template&id=725211e9":
/*!******************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0008000/C0008010.vue?vue&type=template&id=725211e9 ***!
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
  class: "form-floating year"
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
  return (0,vue__WEBPACK_IMPORTED_MODULE_0__.openBlock)(), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementBlock)("div", null, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_1, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_row, {
    class: "search_area"
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_col, {
      cols: "1"
    }, {
      default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_2, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_date_picker, {
        modelValue: $data.params.yyyymm,
        "onUpdate:modelValue": _cache[0] || (_cache[0] = $event => $data.params.yyyymm = $event),
        mode: "year",
        placeholder: "선택하세요"
      }, null, 8 /* PROPS */, ["modelValue"]), _cache[2] || (_cache[2] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", {
        for: "datepicker"
      }, "년도", -1 /* CACHED */))])]),
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
    }, null, -1 /* CACHED */), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("조회", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_5, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_6, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_7, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    class: "second",
    onClick: $options.excelBtnClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[5] || (_cache[5] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("엑셀", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_8, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_RealGrid, {
    ref: "saleCogmGrid",
    uid: 'saleCogmGrid',
    step: '1',
    rows: $data.saleCogmGridRows,
    style: {
      "height": "100%"
    }
  }, null, 8 /* PROPS */, ["rows"])])])]);
}

/***/ }),

/***/ "./src/views/web/c0008000/C0008010.vue":
/*!*********************************************!*\
  !*** ./src/views/web/c0008000/C0008010.vue ***!
  \*********************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _C0008010_vue_vue_type_template_id_725211e9__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./C0008010.vue?vue&type=template&id=725211e9 */ "./src/views/web/c0008000/C0008010.vue?vue&type=template&id=725211e9");
/* harmony import */ var _C0008010_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./C0008010.vue?vue&type=script&lang=js */ "./src/views/web/c0008000/C0008010.vue?vue&type=script&lang=js");
/* harmony import */ var _node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ../../../../node_modules/vue-loader/dist/exportHelper.js */ "./node_modules/vue-loader/dist/exportHelper.js");




;
const __exports__ = /*#__PURE__*/(0,_node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__["default"])(_C0008010_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"], [['render',_C0008010_vue_vue_type_template_id_725211e9__WEBPACK_IMPORTED_MODULE_0__.render],['__file',"src/views/web/c0008000/C0008010.vue"]])
/* hot reload */
if (false) // removed by dead control flow
{}


/* harmony default export */ __webpack_exports__["default"] = (__exports__);

/***/ }),

/***/ "./src/views/web/c0008000/C0008010.vue?vue&type=script&lang=js":
/*!*********************************************************************!*\
  !*** ./src/views/web/c0008000/C0008010.vue?vue&type=script&lang=js ***!
  \*********************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0008010_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0008010_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./C0008010.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0008000/C0008010.vue?vue&type=script&lang=js");
 

/***/ }),

/***/ "./src/views/web/c0008000/C0008010.vue?vue&type=template&id=725211e9":
/*!***************************************************************************!*\
  !*** ./src/views/web/c0008000/C0008010.vue?vue&type=template&id=725211e9 ***!
  \***************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0008010_vue_vue_type_template_id_725211e9__WEBPACK_IMPORTED_MODULE_0__.render; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0008010_vue_vue_type_template_id_725211e9__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./C0008010.vue?vue&type=template&id=725211e9 */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0008000/C0008010.vue?vue&type=template&id=725211e9");


/***/ }),

/***/ "./src/views/web/c0008000/js/C0008010.js":
/*!***********************************************!*\
  !*** ./src/views/web/c0008000/js/C0008010.js ***!
  \***********************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

/*
 * 결산증빙 자료 > 매출원가
 */
const {
  ValueType
} = __webpack_require__(/*! realgrid */ "./node_modules/realgrid/dist/main.js");
const grid = {
  options: {
    checkBar: {
      visible: false
    },
    copy: {
      enabled: true,
      singleMode: true
    },
    display: {
      columnMovable: false,
      editItemMerging: true,
      fitStyle: 'even',
      emptyMessage: '조회된 데이터가 없습니다.',
      hscrollBar: true,
      showEmptyMessage: true
    },
    edit: {
      editable: false
    },
    footer: {
      visible: true
    },
    paste: {
      enabled: false
    },
    rowIndicator: {
      visible: true
    },
    sorting: {
      enabled: true
    },
    stateBar: {
      visible: false
    },
    filtering: {
      enabled: true
    }
  },
  fields: [{
    fieldName: '구분',
    dataType: ValueType.TEXT
  }, {
    fieldName: '모델',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'local구분',
    dataType: ValueType.TEXT
  }, {
    fieldName: '판매단위',
    dataType: ValueType.TEXT
  }, {
    fieldName: '거래처',
    dataType: ValueType.TEXT
  }, {
    fieldName: '월',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'outQty',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'outAmt',
    dataType: ValueType.NUMBER
  }],
  columns: [{
    name: '구분',
    fieldName: '구분',
    width: '80',
    header: {
      text: '구분'
    },
    mergeRule: {
      criteria: "value['구분']+value['모델']+value['local구분']+value['판매단위']+value['거래처']"
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: '모델',
    fieldName: '모델',
    width: '80',
    header: {
      text: '모델'
    },
    mergeRule: {
      criteria: "value['구분']+value['모델']+value['local구분']+value['판매단위']+value['거래처']"
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: 'local구분',
    fieldName: 'local구분',
    width: '110',
    header: {
      text: 'Local구분'
    },
    mergeRule: {
      criteria: "value['구분']+value['모델']+value['local구분']+value['판매단위']+value['거래처']"
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: '판매단위',
    fieldName: '판매단위',
    width: '120',
    header: {
      text: '판매단위'
    },
    mergeRule: {
      criteria: "value['구분']+value['모델']+value['local구분']+value['판매단위']+value['거래처']"
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: '거래처',
    fieldName: '거래처',
    width: '90',
    header: {
      text: '거래처'
    },
    mergeRule: {
      criteria: "value['구분']+value['모델']+value['local구분']+value['판매단위']+value['거래처']"
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: '월',
    fieldName: '월',
    width: '80',
    header: {
      text: '월'
    },
    autoFilter: true,
    styleName: 'tl',
    footer: {
      TEXT: "합계"
    }
  }, {
    name: 'outQty',
    fieldName: 'outQty',
    width: '80',
    header: {
      text: '수량'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'outAmt',
    fieldName: 'outAmt',
    width: '80',
    header: {
      text: '원가'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0.######',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }],
  layout: ['월', '구분', '모델', 'local구분', '판매단위', '거래처', {
    name: '매출원가',
    direction: 'horizontal',
    items: ['outQty', 'outAmt'],
    header: {
      text: '매출원가'
    }
  }]
};
module.exports = grid;

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
//# sourceMappingURL=src_views_web_c0008000_C0008010_vue.7071175c097a4aca.js.map