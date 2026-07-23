(self["webpackChunkvue"] = self["webpackChunkvue"] || []).push([["src_views_web_c0008000_C0008003_vue"],{

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0008000/C0008003.vue?vue&type=script&lang=js":
/*!**************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0008000/C0008003.vue?vue&type=script&lang=js ***!
  \**************************************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _store_auth_userAuthInfo__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! @store/auth/userAuthInfo */ "./src/store/auth/userAuthInfo.js");
/* harmony import */ var _web_store_C0001001_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! @web/store/C0001001.js */ "./src/views/web/store/C0001001.js");
/* harmony import */ var _web_c0008000_js_C0008003_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! @web/c0008000/js/C0008003.js */ "./src/views/web/c0008000/js/C0008003.js");
/* harmony import */ var _web_c0008000_js_C0008003_js__WEBPACK_IMPORTED_MODULE_2___default = /*#__PURE__*/__webpack_require__.n(_web_c0008000_js_C0008003_js__WEBPACK_IMPORTED_MODULE_2__);



/* harmony default export */ __webpack_exports__["default"] = ({
  components: {},
  props: {},
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
      amtCheckGrid: null,
      amtCheckGridRows: [],
      params: {
        yyyymm: null,
        site: 'HQ',
        gubun: '전체',
        seq: '전체'
      },
      gubunList: [{
        value: '전체',
        text: '전체'
      }, {
        value: '제조경비',
        text: '제조경비'
      }, {
        value: '판매관리비',
        text: '판매관리비'
      }],
      seqListMfg: [{
        value: '전체',
        text: '전체'
      }, {
        value: '1',
        text: '제조경비'
      }, {
        value: '2',
        text: '연구개발부서'
      }, {
        value: '3',
        text: '카세트팀'
      }],
      seqListSga: [{
        value: '전체',
        text: '전체'
      }, {
        value: '4',
        text: '판매관리비'
      }, {
        value: '5',
        text: '연구개발부서'
      }],
      siteMap: {
        본사: 'HQ',
        VINA: 'VN',
        HQ: 'HQ',
        VN: 'VN'
      }
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
    }
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
          if (this.$refs.amtCheckGrid != null) {
            this.initialize();
            this.searchClick();
          }
        }
      }
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
      //var current = new Date();
      this.params.yyyymm = this.srchInfo.yyyymm; //`${current.getFullYear()}-${(current.getMonth() + 1).toString().padStart(2, '0')}`;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
      this.params.gubun = '전체';
      this.params.seq = '전체';
    },
    initializeGrid() {
      this.amtCheckGrid = _.cloneDeep((_web_c0008000_js_C0008003_js__WEBPACK_IMPORTED_MODULE_2___default()));
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({
        yyyymm: this.params.yyyymm
      });
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
        seq: this.params.seq
      };
      const param = {
        menuId: 'c0008000',
        queryId: 'C0008003_Select',
        queryParams: params,
        target: this.amtCheckGridRows
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
        }
      };
      grid.exportGrid(options);
    }
  }
});

/***/ }),

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0008000/C0008003.vue?vue&type=template&id=70c77fcd":
/*!******************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0008000/C0008003.vue?vue&type=template&id=70c77fcd ***!
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
  class: "form-floating me-1"
};
const _hoisted_3 = {
  class: "form-floating"
};
const _hoisted_4 = {
  class: "form-floating"
};
const _hoisted_5 = ["value"];
const _hoisted_6 = {
  class: "form-floating"
};
const _hoisted_7 = ["value"];
const _hoisted_8 = {
  class: "btn_area"
};
const _hoisted_9 = {
  class: "grid_box search_onerow"
};
const _hoisted_10 = {
  class: "left_box"
};
const _hoisted_11 = {
  class: "btn_wrap ms-auto"
};
const _hoisted_12 = {
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
      cols: "1",
      class: "period"
    }, {
      default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_2, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_date_picker, {
        label: "기준월",
        mode: "month",
        modelValue: $data.params.yyyymm,
        "onUpdate:modelValue": _cache[0] || (_cache[0] = $event => $data.params.yyyymm = $event)
      }, null, 8 /* PROPS */, ["modelValue"]), _cache[5] || (_cache[5] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", {
        for: "floatingSelect",
        class: "select"
      }, "기준월", -1 /* CACHED */))])]),
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
      }, null, 512 /* NEED_PATCH */), [[vue__WEBPACK_IMPORTED_MODULE_0__.vModelText, $data.params.site]]), _cache[6] || (_cache[6] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", {
        for: "floating"
      }, "사업장", -1 /* CACHED */))])]),
      _: 1 /* STABLE */
    }), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_col, {
      cols: "2",
      class: "ms-3"
    }, {
      default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_4, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.withDirectives)((0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("select", {
        class: "form-select label-60",
        id: "floatingSelect",
        "onUpdate:modelValue": _cache[2] || (_cache[2] = $event => $data.params.gubun = $event),
        onChange: _cache[3] || (_cache[3] = (...args) => $options.onGubunChange && $options.onGubunChange(...args))
      }, [((0,vue__WEBPACK_IMPORTED_MODULE_0__.openBlock)(true), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementBlock)(vue__WEBPACK_IMPORTED_MODULE_0__.Fragment, null, (0,vue__WEBPACK_IMPORTED_MODULE_0__.renderList)($data.gubunList, gubun => {
        return (0,vue__WEBPACK_IMPORTED_MODULE_0__.openBlock)(), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementBlock)("option", {
          key: gubun.value,
          value: gubun.value
        }, (0,vue__WEBPACK_IMPORTED_MODULE_0__.toDisplayString)(gubun.text), 9 /* TEXT, PROPS */, _hoisted_5);
      }), 128 /* KEYED_FRAGMENT */))], 544 /* NEED_HYDRATION, NEED_PATCH */), [[vue__WEBPACK_IMPORTED_MODULE_0__.vModelSelect, $data.params.gubun]]), _cache[7] || (_cache[7] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", {
        for: "floatingSelect",
        class: "select"
      }, "비용구분", -1 /* CACHED */))])]),
      _: 1 /* STABLE */
    }), (0,vue__WEBPACK_IMPORTED_MODULE_0__.withDirectives)((0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_col, {
      cols: "2",
      class: "ms-3"
    }, {
      default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_6, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.withDirectives)((0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("select", {
        class: "form-select label-60",
        id: "floatingSelect",
        "onUpdate:modelValue": _cache[4] || (_cache[4] = $event => $data.params.seq = $event)
      }, [((0,vue__WEBPACK_IMPORTED_MODULE_0__.openBlock)(true), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementBlock)(vue__WEBPACK_IMPORTED_MODULE_0__.Fragment, null, (0,vue__WEBPACK_IMPORTED_MODULE_0__.renderList)($options.currentSeqList, seq => {
        return (0,vue__WEBPACK_IMPORTED_MODULE_0__.openBlock)(), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementBlock)("option", {
          key: seq.value,
          value: seq.value
        }, (0,vue__WEBPACK_IMPORTED_MODULE_0__.toDisplayString)(seq.text), 9 /* TEXT, PROPS */, _hoisted_7);
      }), 128 /* KEYED_FRAGMENT */))], 512 /* NEED_PATCH */), [[vue__WEBPACK_IMPORTED_MODULE_0__.vModelSelect, $data.params.seq]]), _cache[8] || (_cache[8] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", {
        for: "floatingSelectSeq",
        class: "select"
      }, "제조비용", -1 /* CACHED */))])]),
      _: 1 /* STABLE */
    }, 512 /* NEED_PATCH */), [[vue__WEBPACK_IMPORTED_MODULE_0__.vShow, $data.params.gubun !== '전체']])]),
    _: 1 /* STABLE */
  }), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_8, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    onClick: $options.searchClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[9] || (_cache[9] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("span", {
      class: "ico_search"
    }, null, -1 /* CACHED */), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("조회", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_9, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_10, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_11, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    class: "second",
    onClick: $options.excelBtnClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[10] || (_cache[10] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("엑셀", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_12, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_RealGrid, {
    ref: "amtCheckGrid",
    uid: 'amtCheckGrid',
    step: '1',
    rows: $data.amtCheckGridRows,
    style: {
      "height": "100%"
    }
  }, null, 8 /* PROPS */, ["rows"])])])]);
}

/***/ }),

/***/ "./src/views/web/c0008000/C0008003.vue":
/*!*********************************************!*\
  !*** ./src/views/web/c0008000/C0008003.vue ***!
  \*********************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _C0008003_vue_vue_type_template_id_70c77fcd__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./C0008003.vue?vue&type=template&id=70c77fcd */ "./src/views/web/c0008000/C0008003.vue?vue&type=template&id=70c77fcd");
/* harmony import */ var _C0008003_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./C0008003.vue?vue&type=script&lang=js */ "./src/views/web/c0008000/C0008003.vue?vue&type=script&lang=js");
/* harmony import */ var _node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ../../../../node_modules/vue-loader/dist/exportHelper.js */ "./node_modules/vue-loader/dist/exportHelper.js");




;
const __exports__ = /*#__PURE__*/(0,_node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__["default"])(_C0008003_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"], [['render',_C0008003_vue_vue_type_template_id_70c77fcd__WEBPACK_IMPORTED_MODULE_0__.render],['__file',"src/views/web/c0008000/C0008003.vue"]])
/* hot reload */
if (false) // removed by dead control flow
{}


/* harmony default export */ __webpack_exports__["default"] = (__exports__);

/***/ }),

/***/ "./src/views/web/c0008000/C0008003.vue?vue&type=script&lang=js":
/*!*********************************************************************!*\
  !*** ./src/views/web/c0008000/C0008003.vue?vue&type=script&lang=js ***!
  \*********************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0008003_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0008003_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./C0008003.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0008000/C0008003.vue?vue&type=script&lang=js");
 

/***/ }),

/***/ "./src/views/web/c0008000/C0008003.vue?vue&type=template&id=70c77fcd":
/*!***************************************************************************!*\
  !*** ./src/views/web/c0008000/C0008003.vue?vue&type=template&id=70c77fcd ***!
  \***************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0008003_vue_vue_type_template_id_70c77fcd__WEBPACK_IMPORTED_MODULE_0__.render; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0008003_vue_vue_type_template_id_70c77fcd__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./C0008003.vue?vue&type=template&id=70c77fcd */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0008000/C0008003.vue?vue&type=template&id=70c77fcd");


/***/ }),

/***/ "./src/views/web/c0008000/js/C0008003.js":
/*!***********************************************!*\
  !*** ./src/views/web/c0008000/js/C0008003.js ***!
  \***********************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

/*
 * 결산증빙 자료 > 원가항목별 비용(DOI_EXPEN_AMT)
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
    // fixed: { colBarWidth: 1, colCount: 1 },
  },
  fields: [
  // { fieldName: 'yyyymm', dataType: ValueType.TEXT },
  // { fieldName: 'selCode', dataType: ValueType.TEXT },
  // { fieldName: 'site', dataType: ValueType.TEXT },
  {
    fieldName: 'gubun',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'fromDeptCode',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'fromDeptName',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'fromAcctCode',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'fromAcctName',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'expenSel',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'expenSelName',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'acctAmt',
    dataType: ValueType.NUMBER
  }
  // { fieldName: 'seq', dataType: ValueType.NUMBER },
  ],
  columns: [
  // { name: 'yyyymm', fieldName: 'yyyymm', width: '80', header: { text: 'YYYYMM' }, autoFilter: true, styleName: 'tl' },
  // { name: 'selCode', fieldName: 'selCode', width: '80', header: { text: 'SEL_CODE' }, autoFilter: true, styleName: 'tl' },
  // { name: 'site', fieldName: 'site', width: '80', header: { text: '사이트' }, autoFilter: true, styleName: 'tl' },
  {
    name: 'GUBUN',
    fieldName: 'gubun',
    width: '80',
    header: {
      text: '구분'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: 'FROM_DEPT_CODE',
    fieldName: 'fromDeptCode',
    width: '80',
    header: {
      text: '코스트센터'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: 'FROM_DEPT_NAME',
    fieldName: 'fromDeptName',
    width: '80',
    header: {
      text: '코스트센터명'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: 'FROM_ACCT_CODE',
    fieldName: 'fromAcctCode',
    width: '80',
    header: {
      text: '계정코드'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: 'FROM_ACCT_NAME',
    fieldName: 'fromAcctName',
    width: '120',
    header: {
      text: '계정과목'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: 'EXPEN_SEL',
    fieldName: 'expenSel',
    width: '80',
    header: {
      text: '원가항목'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: 'EXPEN_SEL_NAME',
    fieldName: 'expenSelName',
    width: '80',
    header: {
      text: '원가항목명'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: 'ACCT_AMT',
    fieldName: 'acctAmt',
    width: '80',
    header: {
      text: '배부금액'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }
  // { name: 'SEQ', fieldName: 'seq', width: '50', header: { text: '순번' }, autoFilter: true, styleName: 'tr' },
  ]
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
//# sourceMappingURL=src_views_web_c0008000_C0008003_vue.ca72a78b04606d3e.js.map