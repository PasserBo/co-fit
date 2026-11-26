/**
 * handler 集成测试:真实 Firestore 模拟器 + 假 Messaging / Remote Config。
 * 运行:npm run test:emu。
 */
const sendEach = jest.fn();
jest.mock('firebase-admin/messaging', () => ({
  getMessaging: () => ({ sendEach }),
}));
jest.mock('firebase-admin/remote-config', () => ({
  getRemoteConfig: () => ({
    getServerTemplate: async () => {
      throw new Error('no remote config in tests');
    },
  }),
}));

import { initializeApp } from 'firebase-admin/app';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';

import { handlePartnerStart } from '../src/partner_start/handler';

initializeApp({ projectId: 'demo-cofit' });
const db = getFirestore();
const now = new Date('2026-11-26T12:00:00Z');

async function clear() {
  await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/demo-cofit/databases/(default)/documents`,
    { method: 'DELETE' },
  );
}

async function seedRoom(roomId: string, name: string, memberIds: string[]) {
  const members = Object.fromEntries(memberIds.map((id) => [id, { userId: id, role: 'member' }]));
  await db.doc(`rooms/${roomId}`).set({ roomId, name, members });
  await Promise.all(memberIds.map((id) => db.doc(`users/${id}/memberships/${roomId}`).set({ roomId })));
}

async function seedDevice(uid: string, token: string, utcOffsetMinutes?: number) {
  await db.doc(`users/${uid}/devices/${token}`).set({
    token,
    platform: 'ios',
    updatedAt: Timestamp.now(),
    ...(utcOffsetMinutes === undefined ? {} : { utcOffsetMinutes }),
  });
}

function start(roomId: string, startedAt = now) {
  return handlePartnerStart({
    senderId: 'lin',
    sessionId: 's1',
    data: {
      roomId,
      startedAt: Timestamp.fromDate(startedAt),
      createdAt: Timestamp.fromDate(now),
    },
    now,
  });
}

function sentTo(): Array<{ token: string; title: string; body: string; roomId: string }> {
  return sendEach.mock.calls.flatMap(([messages]) =>
    messages.map((m: any) => ({
      token: m.token,
      title: m.notification.title,
      body: m.notification.body,
      roomId: m.data.roomId,
    })),
  );
}

beforeEach(async () => {
  await clear();
  sendEach.mockReset();
  sendEach.mockImplementation(async (messages: unknown[]) => ({
    successCount: messages.length,
    failureCount: 0,
    responses: messages.map(() => ({ success: true })),
  }));
  await db.doc('users/lin').set({ nickname: '小林' });
  await seedRoom('r-early', '早起组', ['lin', 'zhou', 'chen']);
  await seedRoom('r-noon', '午休组', ['lin', 'zhou']);
  await seedDevice('zhou', 'tok-zhou');
  await seedDevice('chen', 'tok-chen');
  await seedDevice('lin', 'tok-lin');
});

it('同房间伙伴各收一条,发起人不收;同在两个房间只收一条,写出牌的房间', async () => {
  await start('r-noon');
  const sent = sentTo();
  expect(sent.map((s) => s.token).sort()).toEqual(['tok-chen', 'tok-zhou']);
  const zhou = sent.find((s) => s.token === 'tok-zhou')!;
  expect(zhou.roomId).toBe('r-noon');
  expect(zhou.body).toBe('你的「午休组」运动伙伴 小林 开始运动了!');
  // chen 和 lin 不在午休组 → 用共同房间早起组
  expect(sent.find((s) => s.token === 'tok-chen')!.roomId).toBe('r-early');
});

it('离线补写的信号不推', async () => {
  await start('r-early', new Date(now.getTime() - 15 * 60_000));
  expect(sendEach).not.toHaveBeenCalled();
});

it('冷却中不推,并且冷却按接收者记录', async () => {
  await db
    .doc('users/zhou/notification_state/partner_start')
    .set({ lastSentAt: Timestamp.fromDate(new Date(now.getTime() - 3_600_000)) });
  await start('r-early');
  expect(sentTo().map((s) => s.token)).toEqual(['tok-chen']);
  const chenState = await db.doc('users/chen/notification_state/partner_start').get();
  expect(chenState.get('lastSentAt').toDate()).toEqual(now);
});

it('总开关关闭、或所有共同房间静音时不推', async () => {
  await db.doc('users/zhou/settings/notifications').set({ partnerStartEnabled: false });
  await db.doc('users/chen/settings/notifications').set({ mutedRoomIds: ['r-early'] });
  await start('r-early');
  expect(sendEach).not.toHaveBeenCalled();
});

it('出牌的房间被静音时改写另一个共同房间', async () => {
  await db.doc('users/zhou/settings/notifications').set({ mutedRoomIds: ['r-noon'] });
  await start('r-noon');
  expect(sentTo().find((s) => s.token === 'tok-zhou')!.roomId).toBe('r-early');
});

it('没有设备的接收者不占冷却', async () => {
  await db.doc('users/chen/devices/tok-chen').delete();
  await start('r-early');
  const chenState = await db.doc('users/chen/notification_state/partner_start').get();
  expect(chenState.exists).toBe(false);
});

it('失效 token 被删除', async () => {
  sendEach.mockImplementation(async (messages: unknown[]) => ({
    successCount: 0,
    failureCount: messages.length,
    responses: messages.map(() => ({
      success: false,
      error: { code: 'messaging/registration-token-not-registered' },
    })),
  }));
  await start('r-early');
  expect((await db.doc('users/zhou/devices/tok-zhou').get()).exists).toBe(false);
  expect((await db.doc('users/chen/devices/tok-chen').get()).exists).toBe(false);
});

it('接收者当地夜间:不发,也不占冷却;同一人白天的设备照发', async () => {
  // now = 12:00Z:纽约 7:00(夜间),东京 21:00(白天)
  await seedDevice('zhou', 'tok-zhou', -300);
  await seedDevice('chen', 'tok-chen', -300);
  await seedDevice('chen', 'tok-chen-tokyo', 540);
  await start('r-early');
  const tokens = sentTo().map((s) => s.token);
  expect(tokens).toEqual(['tok-chen-tokyo']);
  const zhouState = await db.doc('users/zhou/notification_state/partner_start').get();
  expect(zhouState.exists).toBe(false);
});
