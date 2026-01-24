module.exports = {
  skipFiles: ['mocks/', 'test/'],
  mocha: {
    grep: "@skip-on-coverage",
    invert: true
  },
  providerOptions: {
    default_balance_ether: 10000
  }
};
