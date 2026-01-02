const c0008000Router = [
  {
    path: '/c0008001',
    name: '생산수불(DOI_PROD)',
    component: () => import('../views/web/c0008000/C0008001.vue'),
    meta: {
      upperSysResourceId: 'C0008000',
      sysResourceId: 'C0008001',
      requiresAuth: true,
    },
  },
  {
    path: '/c0008002',
    name: '투입비용',
    component: () => import('../views/web/c0008000/C0008002.vue'),
    meta: {
      upperSysResourceId: 'C0008000',
      sysResourceId: 'C0008002',
      requiresAuth: true,
    },
  },
  {
    path: '/c0008003',
    name: '배부금액 검증',
    component: () => import('../views/web/c0008000/C0008003.vue'),
    meta: {
      upperSysResourceId: 'C0008000',
      sysResourceId: 'C0008003',
      requiresAuth: true,
    },
  },
  {
    path: '/c0008004',
    name: '제품별 투입 비용(DOI_PROD_EXPN)',
    component: () => import('../views/web/c0008000/C0008004.vue'),
    meta: {
      upperSysResourceId: 'C0008000',
      sysResourceId: 'C0008004',
      requiresAuth: true,
    },
  },
  // {
  //   path: '/c0008005',
  //   name: '자재별 투입실적(DOI_MAT_AMT)',
  //   component: () => import('../views/web/c0008000/C0008005.vue'),
  //   meta: {
  //     upperSysResourceId: 'C0008000',
  //     sysResourceId: 'C0008005',
  //     requiresAuth: true,
  //   },
  // },
  // {
  //   path: '/c0008006',
  //   name: '원가항목별 재료비(DOI_MAT_EXPEN)',
  //   component: () => import('../views/web/c0008000/C0008006.vue'),
  //   meta: {
  //     upperSysResourceId: 'C0008000',
  //     sysResourceId: 'C0008006',
  //     requiresAuth: true,
  //   },
  // },
  // {
  //   path: '/c0008007',
  //   name: '제품별 투입 재료비(DOI_PROD_MAT)',
  //   component: () => import('../views/web/c0008000/C0008007.vue'),
  //   meta: {
  //     upperSysResourceId: 'C0008000',
  //     sysResourceId: 'C0008007',
  //     requiresAuth: true,
  //   },
  // },
  {
    path: '/c0008008',
    name: '제품별 재공평가(DOI_COST)',
    component: () => import('../views/web/c0008000/C0008008.vue'),
    meta: {
      upperSysResourceId: 'C0008000',
      sysResourceId: 'C0008008',
      requiresAuth: true,
    },
  },
  {
    path: '/c0008009',
    name: '재품수불_수량(DOI_STOCK)',
    component: () => import('../views/web/c0008000/C0008009.vue'),
    meta: {
      upperSysResourceId: 'C0008000',
      sysResourceId: 'C0008009',
      requiresAuth: true,
    },
  },
  {
    path: '/c0008011',
    name: '재품수불_금액(DOI_STCO)',
    component: () => import('../views/web/c0008000/C0008011.vue'),
    meta: {
      upperSysResourceId: 'C0008000',
      sysResourceId: 'C0008011',
      requiresAuth: true,
    },
  },
  {
    path: '/c0008010',
    name: '매출원가',
    component: () => import('../views/web/c0008000/C0008010.vue'),
    meta: {
      upperSysResourceId: 'C0008000',
      sysResourceId: 'C0008010',
      requiresAuth: true,
    },
  },
  {
    path: '/c0008012',
    name: '매출',
    component: () => import('../views/web/c0008000/C0008012.vue'),
    meta: {
      upperSysResourceId: 'C0008000',
      sysResourceId: 'C0008012',
      requiresAuth: true,
    },
  },
  {
    path: '/c0008013',
    name: '판매관리비',
    component: () => import('../views/web/c0008000/C0008013.vue'),
    meta: {
      upperSysResourceId: 'C0008000',
      sysResourceId: 'C0008013',
      requiresAuth: true,
    },
  },
  {
    path: '/c0008014',
    name: '경영실행',
    component: () => import('../views/web/c0008000/C0008014.vue'),
    meta: {
      upperSysResourceId: 'C0008000',
      sysResourceId: 'C0008014',
      requiresAuth: true,
    },
  },
];

export default c0008000Router;
