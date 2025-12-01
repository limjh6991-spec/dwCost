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
];

export default c0009000Router;
