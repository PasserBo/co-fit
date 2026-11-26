/**
 * firestore.rules 中 add-partner-start-push 新增的四段。
 * 运行:npm run test:emu(Firestore 模拟器)。
 */
import {
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
} from 'firebase/firestore';
import { readFileSync } from 'fs';
import { resolve } from 'path';

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-cofit',
    firestore: { rules: readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8') },
  });
});

afterAll(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/lin/memberships/r1'), { roomId: 'r1' });
  });
});

const lin = () => env.authenticatedContext('lin').firestore();
const zhou = () => env.authenticatedContext('zhou').firestore();

describe('devices', () => {
  const token = 'tok:abc';
  const valid = { token, platform: 'ios', updatedAt: serverTimestamp() };

  it('本人可以登记、删除', async () => {
    await assertSucceeds(setDoc(doc(lin(), `users/lin/devices/${token}`), valid));
    await assertSucceeds(deleteDoc(doc(lin(), `users/lin/devices/${token}`)));
  });
  it('不能读,包括本人', async () => {
    await assertFails(getDoc(doc(lin(), `users/lin/devices/${token}`)));
  });
  it('不能替别人登记', async () => {
    await assertFails(setDoc(doc(zhou(), `users/lin/devices/${token}`), valid));
  });
  it('可以带当地时差,超出范围或类型不对不行', async () => {
    await assertSucceeds(
      setDoc(doc(lin(), `users/lin/devices/${token}`), { ...valid, utcOffsetMinutes: 540 }),
    );
    await assertFails(
      setDoc(doc(lin(), `users/lin/devices/${token}`), { ...valid, utcOffsetMinutes: 2000 }),
    );
    await assertFails(
      setDoc(doc(lin(), `users/lin/devices/${token}`), { ...valid, utcOffsetMinutes: '540' }),
    );
  });
  it('token 必须等于文档 id,不能多字段', async () => {
    await assertFails(setDoc(doc(lin(), 'users/lin/devices/other'), valid));
    await assertFails(setDoc(doc(lin(), `users/lin/devices/${token}`), { ...valid, extra: 1 }));
  });
});

describe('settings', () => {
  it('本人可以写 notifications,可读可删', async () => {
    const ref = doc(lin(), 'users/lin/settings/notifications');
    await assertSucceeds(
      setDoc(ref, { partnerStartEnabled: false, mutedRoomIds: ['r1'], updatedAt: serverTimestamp() }),
    );
    await assertSucceeds(getDoc(ref));
    await assertSucceeds(deleteDoc(ref));
  });
  it('别人不可读写', async () => {
    await assertFails(getDoc(doc(zhou(), 'users/lin/settings/notifications')));
    await assertFails(
      setDoc(doc(zhou(), 'users/lin/settings/notifications'), { updatedAt: serverTimestamp() }),
    );
  });
  it('只允许 notifications 文档、合法类型', async () => {
    await assertFails(setDoc(doc(lin(), 'users/lin/settings/other'), { updatedAt: serverTimestamp() }));
    await assertFails(
      setDoc(doc(lin(), 'users/lin/settings/notifications'), {
        partnerStartEnabled: 'no',
        updatedAt: serverTimestamp(),
      }),
    );
  });
});

describe('workout_starts', () => {
  const signal = (roomId: string) => ({
    roomId,
    startedAt: Timestamp.now(),
    createdAt: serverTimestamp(),
  });

  it('本人在自己是成员的房间可以创建', async () => {
    await assertSucceeds(setDoc(doc(lin(), 'users/lin/workout_starts/s1'), signal('r1')));
  });
  it('不是成员的房间不行', async () => {
    await assertFails(setDoc(doc(lin(), 'users/lin/workout_starts/s1'), signal('r2')));
  });
  it('不能替别人创建,不能读', async () => {
    await assertFails(setDoc(doc(zhou(), 'users/lin/workout_starts/s1'), signal('r1')));
    await assertFails(getDoc(doc(lin(), 'users/lin/workout_starts/s1')));
  });
  it('本人可以删除(账号删除)', async () => {
    await assertSucceeds(deleteDoc(doc(lin(), 'users/lin/workout_starts/s1')));
  });
});

describe('notification_state', () => {
  it('客户端不可写,本人可读可删', async () => {
    const ref = doc(lin(), 'users/lin/notification_state/partner_start');
    await assertFails(setDoc(ref, { lastSentAt: Timestamp.now() }));
    await assertSucceeds(getDoc(ref));
    await assertSucceeds(deleteDoc(ref));
    await assertFails(getDoc(doc(zhou(), 'users/lin/notification_state/partner_start')));
  });
});
