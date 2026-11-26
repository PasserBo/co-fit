import {
  DEFAULT_CONFIG,
  RoomInfo,
  buildNotificationText,
  chooseRoom,
  isCoolingDown,
  isStale,
  parseConfig,
  parseSettings,
  sharedRoomsByRecipient,
} from '../src/partner_start/logic';

const early: RoomInfo = { roomId: 'r-early', name: '早起组', memberIds: ['lin', 'zhou', 'chen'] };
const noon: RoomInfo = { roomId: 'r-noon', name: '午休组', memberIds: ['lin', 'zhou'] };
const other: RoomInfo = { roomId: 'r-other', name: '别的组', memberIds: ['zhou', 'wang'] };

describe('parseConfig', () => {
  it('空串 / 非法 JSON / 非对象 → 默认值', () => {
    expect(parseConfig('')).toEqual(DEFAULT_CONFIG);
    expect(parseConfig(undefined)).toEqual(DEFAULT_CONFIG);
    expect(parseConfig('{oops')).toEqual(DEFAULT_CONFIG);
    expect(parseConfig('[1]')).toEqual(DEFAULT_CONFIG);
  });

  it('合法字段覆盖默认值,非法字段回落', () => {
    const config = parseConfig(
      JSON.stringify({ cooldownHours: 6, staleMinutes: -1, title: '', body: '{nickname} 动起来了' }),
    );
    expect(config.cooldownHours).toBe(6);
    expect(config.staleMinutes).toBe(DEFAULT_CONFIG.staleMinutes);
    expect(config.title).toBe(DEFAULT_CONFIG.title);
    expect(config.body).toBe('{nickname} 动起来了');
  });
});

describe('isStale', () => {
  const started = new Date('2026-11-26T08:00:00Z');
  it('10 分钟内到达不过期', () => {
    expect(isStale(started, new Date('2026-11-26T08:09:59Z'), 10)).toBe(false);
  });
  it('晚于 10 分钟到达(离线补写)过期', () => {
    expect(isStale(started, new Date('2026-11-26T08:15:00Z'), 10)).toBe(true);
  });
  it('客户端时钟偏快视为新鲜', () => {
    expect(isStale(started, new Date('2026-11-26T07:50:00Z'), 10)).toBe(false);
  });
});

describe('sharedRoomsByRecipient', () => {
  it('跨房间去重,发起人自己不是接收者', () => {
    const map = sharedRoomsByRecipient('lin', [early, noon, other]);
    expect([...map.keys()].sort()).toEqual(['chen', 'zhou']);
    expect(map.get('zhou')!.map((r) => r.roomId)).toEqual(['r-early', 'r-noon']);
    expect(map.get('chen')!.map((r) => r.roomId)).toEqual(['r-early']);
  });

  it('发起人已不在成员表里的房间不算', () => {
    const map = sharedRoomsByRecipient('lin', [other]);
    expect(map.size).toBe(0);
  });
});

describe('chooseRoom', () => {
  it('同在两个房间:用出牌的房间', () => {
    expect(chooseRoom([early, noon], new Set(), 'r-noon')!.roomId).toBe('r-noon');
  });

  it('出牌的房间被静音:用另一个共同房间', () => {
    expect(chooseRoom([early, noon], new Set(['r-noon']), 'r-noon')!.roomId).toBe('r-early');
  });

  it('出牌的房间不是共同房间:按名称选第一个', () => {
    expect(chooseRoom([noon, early], new Set(), 'r-x')!.name).toBe(
      ['早起组', '午休组'].sort((a, b) => a.localeCompare(b))[0],
    );
  });

  it('唯一的共同房间被静音:不推', () => {
    expect(chooseRoom([early], new Set(['r-early']), 'r-early')).toBeNull();
  });
});

describe('isCoolingDown', () => {
  const now = new Date('2026-11-26T12:00:00Z');
  it('从没收过 → 不在冷却', () => {
    expect(isCoolingDown(null, now, 3)).toBe(false);
  });
  it('1 小时前收过,冷却 3 小时 → 冷却中', () => {
    expect(isCoolingDown(new Date('2026-11-26T11:00:00Z'), now, 3)).toBe(true);
  });
  it('4 小时前收过 → 冷却结束', () => {
    expect(isCoolingDown(new Date('2026-11-26T08:00:00Z'), now, 3)).toBe(false);
  });
});

describe('parseSettings', () => {
  it('文档不存在 = 开、无静音', () => {
    const s = parseSettings(undefined);
    expect(s.partnerStartEnabled).toBe(true);
    expect(s.mutedRoomIds.size).toBe(0);
  });
  it('关闭与静音', () => {
    const s = parseSettings({ partnerStartEnabled: false, mutedRoomIds: ['a', 1, 'b'] });
    expect(s.partnerStartEnabled).toBe(false);
    expect([...s.mutedRoomIds]).toEqual(['a', 'b']);
  });
});

describe('buildNotificationText', () => {
  it('按默认文案替换房间名与昵称', () => {
    expect(buildNotificationText(DEFAULT_CONFIG, '早起组', '小林')).toEqual({
      title: '早起组',
      body: '你的「早起组」运动伙伴 小林 开始运动了!',
    });
  });
  it('没有昵称时用兜底称呼', () => {
    expect(buildNotificationText(DEFAULT_CONFIG, '早起组', '  ').body).toContain('伙伴 TA 开始');
  });
});
