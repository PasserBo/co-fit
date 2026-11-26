/** 需要 Firestore 模拟器的测试(rules、handler 集成):npm run test:emu。 */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['<rootDir>/test/**/*.emu.test.ts'],
  maxWorkers: 1,
};
