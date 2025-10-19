const c0008000Router = [
  {
    path: '/c0008001',
    name: '부서별 경비 집계표(DOI_ACCT_AMT)',
    component: () => import('../views/web/c0008000/C0008001.vue'),
    meta: {
      upperSysResourceId: 'C0008000',
      sysResourceId: 'C0008001',
      requiresAuth: true,
    },
  },
  {
    path: '/c0008003',
    name: '생산수불(DOI_PROD)',
    component: () => import('../views/web/c0008000/C0008003.vue'),
    meta: {
      upperSysResourceId: 'C0008000',
      sysResourceId: 'C0008003',
      requiresAuth: true,
    },
  },
];

export default c0008000Router;
