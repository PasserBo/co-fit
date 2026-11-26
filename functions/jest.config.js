/** 纯逻辑单测:不需要模拟器。模拟器测试见 jest.emu.config.js。 */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['<rootDir>/test/**/*.test.ts'],
  testPathIgnorePatterns: ['/node_modules/', '\\.emu\\.test\\.ts$'],
};
