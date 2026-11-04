#!/usr/bin/env node
// 把 firestore/card_templates.json(SSOT)写入 Firestore `card_templates`。
//
// 用法(CI 或本地,需 GOOGLE_APPLICATION_CREDENTIALS 指向 service account):
//   node tool/seed_card_templates.mjs --project cofit-lmdyd [--dry-run] [--prune]
//
// - 默认只 upsert(set 覆盖同 id 文档),不删除线上多出来的文档;
// - --prune 才删除不在 JSON 里的文档(破坏性,workflow_dispatch 手动开启);
// - --dry-run 只打印将要发生的变更。
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const args = process.argv.slice(2);
const flag = (name) => args.includes(name);
const option = (name) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : undefined;
};

const projectId = option('--project');
if (!projectId) {
  console.error('缺少 --project <firebaseProjectId>');
  process.exit(2);
}
const dryRun = flag('--dry-run');
const prune = flag('--prune');

const here = path.dirname(fileURLToPath(import.meta.url));
const jsonPath = path.resolve(here, '..', 'firestore', 'card_templates.json');
const { templates } = JSON.parse(await readFile(jsonPath, 'utf8'));

const REQUIRED = ['id', 'name', 'type', 'ablyActionId', 'defaultDurationSec'];
const ids = new Set();
for (const t of templates) {
  for (const key of REQUIRED) {
    if (t[key] === undefined || t[key] === '') {
      throw new Error(`模板 ${t.id ?? '?'} 缺少字段 ${key}`);
    }
  }
  if (ids.has(t.id)) throw new Error(`重复 id: ${t.id}`);
  ids.add(t.id);
  if (!Number.isInteger(t.defaultDurationSec) || t.defaultDurationSec <= 0) {
    throw new Error(`模板 ${t.id} 的 defaultDurationSec 必须是正整数`);
  }
}

initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore();
const col = db.collection('card_templates');

const existing = new Map();
for (const doc of (await col.get()).docs) existing.set(doc.id, doc.data());

let created = 0;
let updated = 0;
const batch = db.batch();
for (const t of templates) {
  const { id, ...data } = t;
  const before = existing.get(id);
  if (!before) created++;
  else if (JSON.stringify(before) !== JSON.stringify(data)) updated++;
  else continue;
  console.log(`${before ? 'update' : 'create'} card_templates/${id} (${t.name})`);
  if (!dryRun) batch.set(col.doc(id), data);
}

let deleted = 0;
for (const id of existing.keys()) {
  if (ids.has(id)) continue;
  if (!prune) {
    console.log(`keep   card_templates/${id}(不在 JSON 里;--prune 才删除)`);
    continue;
  }
  deleted++;
  console.log(`delete card_templates/${id}`);
  if (!dryRun) batch.delete(col.doc(id));
}

if (!dryRun) await batch.commit();
console.log(
  `${dryRun ? '[dry-run] ' : ''}done: ${created} created, ${updated} updated, ${deleted} deleted, ${templates.length} in JSON, ${existing.size} were online`,
);
