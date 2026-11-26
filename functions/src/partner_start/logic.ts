/**
 * 伙伴开始运动推送的纯逻辑(change add-partner-start-push)。
 * 不碰 Firestore / Messaging,方便单测;读写都在 handler.ts。
 */

/** 推送配置。全部是内容:来自 Remote Config 参数 `partner_start_push_config`。 */
export interface PartnerStartConfig {
  /** 每个接收者两条推送之间至少间隔多少小时。 */
  cooldownHours: number;
  /** 开始运动的信号晚于开始时间多少分钟到达服务端就不再推送(离线补写)。 */
  staleMinutes: number;
  /** 占位符:{room}、{nickname}。 */
  title: string;
  body: string;
  /** 发起人没有昵称时代替 {nickname}。 */
  fallbackNickname: string;
}

export const CONFIG_PARAM_KEY = 'partner_start_push_config';

export const DEFAULT_CONFIG: PartnerStartConfig = {
  cooldownHours: 3,
  staleMinutes: 10,
  title: '{room}',
  body: '你的「{room}」运动伙伴 {nickname} 开始运动了!',
  fallbackNickname: 'TA',
};

/** 解析配置 JSON;缺失、类型不对、取值越界的字段用默认值。 */
export function parseConfig(raw: string | undefined | null): PartnerStartConfig {
  if (!raw || raw.trim() === '') return { ...DEFAULT_CONFIG };
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return { ...DEFAULT_CONFIG };
  }
  if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
    return { ...DEFAULT_CONFIG };
  }
  const obj = parsed as Record<string, unknown>;
  const nonNegative = (v: unknown, fallback: number) =>
    typeof v === 'number' && Number.isFinite(v) && v >= 0 ? v : fallback;
  const nonEmpty = (v: unknown, fallback: string) =>
    typeof v === 'string' && v.trim() !== '' ? v : fallback;
  return {
    cooldownHours: nonNegative(obj.cooldownHours, DEFAULT_CONFIG.cooldownHours),
    staleMinutes: nonNegative(obj.staleMinutes, DEFAULT_CONFIG.staleMinutes),
    title: nonEmpty(obj.title, DEFAULT_CONFIG.title),
    body: nonEmpty(obj.body, DEFAULT_CONFIG.body),
    fallbackNickname: nonEmpty(obj.fallbackNickname, DEFAULT_CONFIG.fallbackNickname),
  };
}

/**
 * 信号是否过期:服务端收到时间(createdAt)比客户端的开始时间晚超过 staleMinutes。
 * 客户端时钟偏快(startedAt 在 createdAt 之后)视为新鲜。
 */
export function isStale(startedAt: Date, createdAt: Date, staleMinutes: number): boolean {
  return createdAt.getTime() - startedAt.getTime() > staleMinutes * 60_000;
}

export interface RoomInfo {
  roomId: string;
  name: string;
  memberIds: string[];
}

/**
 * 发起人所在房间 → 每个接收者与发起人的共同房间。
 * 只算发起人仍在成员表里的房间;发起人自己不是接收者。
 */
export function sharedRoomsByRecipient(
  senderId: string,
  rooms: RoomInfo[],
): Map<string, RoomInfo[]> {
  const result = new Map<string, RoomInfo[]>();
  for (const room of rooms) {
    if (!room.memberIds.includes(senderId)) continue;
    for (const memberId of room.memberIds) {
      if (memberId === senderId || memberId.trim() === '') continue;
      const list = result.get(memberId) ?? [];
      if (!list.some((r) => r.roomId === room.roomId)) list.push(room);
      result.set(memberId, list);
    }
  }
  return result;
}

/**
 * 推送里写哪个房间:出牌的房间优先;它不是共同房间或被静音时,
 * 用其余未静音的共同房间里按名称排第一个的。全部静音返回 null(不推)。
 */
export function chooseRoom(
  shared: RoomInfo[],
  mutedRoomIds: ReadonlySet<string>,
  startRoomId: string,
): RoomInfo | null {
  const eligible = shared.filter((r) => !mutedRoomIds.has(r.roomId));
  if (eligible.length === 0) return null;
  const startRoom = eligible.find((r) => r.roomId === startRoomId);
  if (startRoom) return startRoom;
  return [...eligible].sort(
    (a, b) => a.name.localeCompare(b.name) || a.roomId.localeCompare(b.roomId),
  )[0];
}

/** 接收者是否还在冷却中。 */
export function isCoolingDown(
  lastSentAt: Date | null | undefined,
  now: Date,
  cooldownHours: number,
): boolean {
  if (!lastSentAt) return false;
  return now.getTime() - lastSentAt.getTime() < cooldownHours * 3_600_000;
}

export interface RecipientSettings {
  partnerStartEnabled: boolean;
  mutedRoomIds: Set<string>;
}

/** 设置文档 → 设置;文档不存在 / 字段缺失 = 开、无静音。 */
export function parseSettings(data: Record<string, unknown> | undefined): RecipientSettings {
  const enabled = data?.partnerStartEnabled;
  const muted = data?.mutedRoomIds;
  return {
    partnerStartEnabled: enabled === false ? false : true,
    mutedRoomIds: new Set(
      Array.isArray(muted) ? muted.filter((v): v is string => typeof v === 'string') : [],
    ),
  };
}

/** 替换 {room} / {nickname}。 */
export function renderTemplate(template: string, vars: { room: string; nickname: string }): string {
  return template.replace(/\{room\}/g, vars.room).replace(/\{nickname\}/g, vars.nickname);
}

export function buildNotificationText(
  config: PartnerStartConfig,
  roomName: string,
  nickname: string | undefined | null,
): { title: string; body: string } {
  const vars = {
    room: roomName,
    nickname: nickname && nickname.trim() !== '' ? nickname.trim() : config.fallbackNickname,
  };
  return {
    title: renderTemplate(config.title, vars),
    body: renderTemplate(config.body, vars),
  };
}

/** 发送失败时,这些错误码说明 token 已失效,应删除设备登记。 */
export const INVALID_TOKEN_ERROR_CODES: ReadonlySet<string> = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

/** 推送 data 里的类型标记,客户端据此识别。 */
export const PUSH_TYPE = 'partner_start';
