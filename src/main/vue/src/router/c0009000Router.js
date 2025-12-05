const c0009000Router = [
  {
    path: '/c0009001',
    name: '생산실적',
    component: () => import('../views/web/c0009000/C0009001.vue'),
    meta: {
      upperSysResourceId: 'C0009000',
      sysResourceId: 'C0009001',
      requiresAuth: true,
    },
  },
    {
    path: '/c0009002',
    name: '제품 수불부',
    component: () => import('../views/web/c0009000/C0009002.vue'),
    meta: {
      upperSysResourceId: 'C0009000',
      sysResourceId: 'C0009002',
      requiresAuth: true,
    },
  },
    {
    path: '/c0009003',
    name: '판매 실적 집계',
    component: () => import('../views/web/c0009000/C0009003.vue'),
    meta: {
      upperSysResourceId: 'C0009000',
      sysResourceId: 'C0009003',
      requiresAuth: true,
    },
  },
    {
    path: '/c0009004',
    name: '자재수불부',
    component: () => import('../views/web/c0009000/C0009004.vue'),
    meta: {
      upperSysResourceId: 'C0009000',
      sysResourceId: 'C0009004',
      requiresAuth: true,
    },
  },
    {
    path: '/c0009005',
    name: '제조경비 집계표',
    component: () => import('../views/web/c0009000/C0009005.vue'),
    meta: {
      upperSysResourceId: 'C0009000',
      sysResourceId: 'C0009005',
      requiresAuth: true,
    },
  },
    {
    path: '/c0009006',
    name: '원부자재 배부표',
    component: () => import('../views/web/c0009000/C0009006.vue'),
    meta: {
      upperSysResourceId: 'C0009000',
      sysResourceId: 'C0009006',
      requiresAuth: true,
    },
  },
  {
    path: '/c0009007',
    name: '재공,제품 원가',
    component: () => import('../views/web/c0009000/C0009007.vue'),
    meta: {
      upperSysResourceId: 'C0009000',
      sysResourceId: 'C0009007',
      requiresAuth: true,
    },
  },    
  {
    path: '/c0009008',
    name: '판매관리비 집계표',
    component: () => import('../views/web/c0009000/C0009008.vue'),
    meta: {
      upperSysResourceId: 'C0009000',
      sysResourceId: 'C0009008',
      requiresAuth: true,
    },
  },
    {
    path: '/c0009009',
    name: '제품별 손익계산서',
    component: () => import('../views/web/c0009000/C0009009.vue'),
    meta: {
      upperSysResourceId: 'C0009000',
      sysResourceId: 'C0009009',
      requiresAuth: true,
    },
  },
    {
    path: '/c0009010',
    name: '총원가',
    component: () => import('../views/web/c0009000/C0009010.vue'),
    meta: {
      upperSysResourceId: 'C0009000',
      sysResourceId: 'C0009010',
      requiresAuth: true,
    },
  },
];

export default c0009000Router;
