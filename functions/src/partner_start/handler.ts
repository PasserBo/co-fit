/**
 * 伙伴开始运动推送:`users/{uid}/workout_starts/{sessionId}` 创建时触发。
 * 规格:docs/spec/changes/add-partner-start-push/specs/partner-start-push/spec.md
 * 设计:docs/spec/changes/add-partner-start-push/design.md §1
 */
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { getMessaging, TokenMessage } from 'firebase-admin/messaging';
import { getRemoteConfig } from 'firebase-admin/remote-config';
import { logger } from 'firebase-functions';

import {
  CONFIG_PARAM_KEY,
  DEFAULT_CONFIG,
  INVALID_TOKEN_ERROR_CODES,
  PUSH_TYPE,
  PartnerStartConfig,
  RoomInfo,
  buildNotificationText,
  chooseRoom,
  isCoolingDown,
  isQuietHours,
  isStale,
  parseConfig,
  parseSettings,
  sharedRoomsByRecipient,
} from './logic';

const CONFIG_CACHE_MS = 5 * 60_000;
let cachedConfig: { value: PartnerStartConfig; loadedAt: number } | null = null;

/** Remote Config 服务端模板;读失败用默认值(推送不能因配置挂掉)。 */
async function loadConfig(): Promise<PartnerStartConfig> {
  const now = Date.now();
  if (cachedConfig && now - cachedConfig.loadedAt < CONFIG_CACHE_MS) {
    return cachedConfig.value;
  }
  try {
    const template = await getRemoteConfig().getServerTemplate({
      defaultConfig: { [CONFIG_PARAM_KEY]: '' },
    });
    const value = parseConfig(template.evaluate().getString(CONFIG_PARAM_KEY));
    cachedConfig = { value, loadedAt: now };
    return value;
  } catch (e) {
    logger.warn('partner_start: remote config unavailable, using defaults', e);
    const value = { ...DEFAULT_CONFIG };
    cachedConfig = { value, loadedAt: now };
    return value;
  }
}

function toDate(value: unknown): Date | null {
  return value instanceof Timestamp ? value.toDate() : null;
}

/** 发起人所在的房间(以 memberships 为索引,以房间文档的成员表为准)。 */
async function loadSenderRooms(senderId: string): Promise<RoomInfo[]> {
  const db = getFirestore();
  const memberships = await db.collection('users').doc(senderId).collection('memberships').get();
  if (memberships.empty) return [];
  const roomRefs = memberships.docs.map((d) => db.collection('rooms').doc(d.id));
  const roomSnaps = await db.getAll(...roomRefs);
  const rooms: RoomInfo[] = [];
  for (const snap of roomSnaps) {
    const data = snap.data();
    if (!data) continue;
    const members = data.members;
    const memberIds =
      members && typeof members === 'object' ? Object.keys(members as Record<string, unknown>) : [];
    rooms.push({
      roomId: snap.id,
      name: typeof data.name === 'string' ? data.name : '',
      memberIds,
    });
  }
  return rooms;
}

/** 冷却检查并占位(事务):返回 true 表示可以发。 */
async function claimCooldown(recipientId: string, now: Date, cooldownHours: number): Promise<boolean> {
  const db = getFirestore();
  const ref = db
    .collection('users')
    .doc(recipientId)
    .collection('notification_state')
    .doc(PUSH_TYPE);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const last = toDate(snap.get('lastSentAt'));
    if (isCoolingDown(last, now, cooldownHours)) return false;
    tx.set(ref, { lastSentAt: Timestamp.fromDate(now) });
    return true;
  });
}

async function notifyRecipient(params: {
  recipientId: string;
  sharedRooms: RoomInfo[];
  startRoomId: string;
  senderNickname: string | null;
  config: PartnerStartConfig;
  now: Date;
}): Promise<'sent' | 'skipped'> {
  const { recipientId, sharedRooms, startRoomId, senderNickname, config, now } = params;
  const db = getFirestore();
  const userRef = db.collection('users').doc(recipientId);

  const settings = parseSettings((await userRef.collection('settings').doc('notifications').get()).data());
  if (!settings.partnerStartEnabled) return 'skipped';

  const room = chooseRoom(sharedRooms, settings.mutedRoomIds, startRoomId);
  if (!room) return 'skipped';

  const devices = await userRef.collection('devices').get();
  // 夜间的设备不发(spec: 夜间不推送);全部在夜间时不占冷却。
  const tokens = devices.docs
    .filter(
      (d) =>
        !isQuietHours(now, d.get('utcOffsetMinutes'), config.quietStartHour, config.quietEndHour),
    )
    .map((d) => d.get('token'))
    .filter((t): t is string => typeof t === 'string' && t !== '');
  if (tokens.length === 0) return 'skipped';

  if (!(await claimCooldown(recipientId, now, config.cooldownHours))) return 'skipped';

  const text = buildNotificationText(config, room.name, senderNickname);
  const messages: TokenMessage[] = tokens.map((token) => ({
    token,
    notification: text,
    data: { type: PUSH_TYPE, roomId: room.roomId },
    apns: { payload: { aps: { sound: 'default', threadId: room.roomId } } },
  }));
  const response = await getMessaging().sendEach(messages);

  const invalid: string[] = [];
  response.responses.forEach((r, i) => {
    if (!r.success && r.error && INVALID_TOKEN_ERROR_CODES.has(r.error.code)) {
      invalid.push(tokens[i]);
    } else if (!r.success) {
      logger.warn('partner_start: send failed', { recipientId, code: r.error?.code });
    }
  });
  await Promise.all(invalid.map((t) => userRef.collection('devices').doc(t).delete()));
  return response.successCount > 0 ? 'sent' : 'skipped';
}

export async function handlePartnerStart(params: {
  senderId: string;
  sessionId: string;
  data: Record<string, unknown>;
  now?: Date;
}): Promise<void> {
  const { senderId, sessionId, data } = params;
  const now = params.now ?? new Date();
  const roomId = typeof data.roomId === 'string' ? data.roomId : '';
  const startedAt = toDate(data.startedAt);
  const createdAt = toDate(data.createdAt) ?? now;
  const config = await loadConfig();

  if (!roomId || !startedAt) {
    logger.warn('partner_start: malformed signal', { senderId, sessionId });
    return;
  }
  if (isStale(startedAt, createdAt, config.staleMinutes)) {
    logger.info('partner_start: stale signal dropped', { senderId, sessionId });
    return;
  }

  const db = getFirestore();
  const [rooms, senderSnap] = await Promise.all([
    loadSenderRooms(senderId),
    db.collection('users').doc(senderId).get(),
  ]);
  const nickname = senderSnap.get('nickname');
  const recipients = sharedRoomsByRecipient(senderId, rooms);

  const results = await Promise.allSettled(
    [...recipients.entries()].map(([recipientId, sharedRooms]) =>
      notifyRecipient({
        recipientId,
        sharedRooms,
        startRoomId: roomId,
        senderNickname: typeof nickname === 'string' ? nickname : null,
        config,
        now,
      }),
    ),
  );
  const sent = results.filter((r) => r.status === 'fulfilled' && r.value === 'sent').length;
  const failed = results.filter((r) => r.status === 'rejected');
  failed.forEach((r) => logger.error('partner_start: recipient failed', (r as PromiseRejectedResult).reason));
  logger.info('partner_start: done', {
    senderId,
    sessionId,
    recipients: recipients.size,
    sent,
    failed: failed.length,
  });
}
