#!/usr/bin/env python3
"""准备 App Review / TestFlight 外部测试用的演示账号与测试房间。

只用 Firebase 客户端 REST 接口(与 App 同一个公开 iOS API key),以演示账号
自己的身份写 Firestore,所以和 App 一样受 firestore.rules 约束,不需要 service account。

凭证存 keys/review_account.json(/keys/ 已 gitignore):
  {"email": "...", "password": "...", "nickname": "...", "roomName": "...", "roomDescription": "..."}
文件不存在时自动生成(随机密码),脚本从不打印密码——去这个文件里复制到 App Store Connect。

可重复执行(幂等):
  - 账号不存在 → 注册;已存在 → 登录
  - 资料不存在 → 创建(昵称即完成起名,登录后直接进主界面)
  - 已有自己当房主的房间 → 复用;否则按 App 的 CreateRoomUsecase 同款格式建房
审核员在 App 里删除账号后,再跑一次即可重建。

用法:python3 scripts/seed_review_account.py
"""

from __future__ import annotations

import base64
import hashlib
import json
import os
import secrets
import string
import sys
import urllib.error
import urllib.request
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CREDENTIALS = ROOT / "keys" / "review_account.json"
PROJECT_ID = "cofit-lmdyd"
BUNDLE_ID = "com.passerbo.cofitapp"

DEFAULTS = {
    # example.com 是保留域名,不会被任何人注册,也收不到信;审核员不需要收信。
    "email": "review.cofit@example.com",
    "nickname": "Reviewer",
    "roomName": "Review Room",
    "roomDescription": "App Review test room",
}


def ios_api_key() -> str:
    """firebase_options.dart 里的 iOS apiKey(随 App 分发的公开值)。"""
    text = (ROOT / "lib" / "firebase_options.dart").read_text()
    marker = "apiKey: '"
    start = text.index(marker) + len(marker)
    return text[start : text.index("'", start)]


def generate_password() -> str:
    # 去掉易混字符,审核员手输也不会错。
    alphabet = "".join(
        c for c in string.ascii_letters + string.digits if c not in "0OoIl1"
    )
    return "".join(secrets.choice(alphabet) for _ in range(16))


def load_credentials() -> dict:
    if CREDENTIALS.exists():
        creds = json.loads(CREDENTIALS.read_text())
        return {**DEFAULTS, **creds}
    creds = {**DEFAULTS, "password": generate_password()}
    CREDENTIALS.parent.mkdir(exist_ok=True)
    CREDENTIALS.write_text(json.dumps(creds, ensure_ascii=False, indent=2) + "\n")
    os.chmod(CREDENTIALS, 0o600)
    print(f"已生成凭证文件 {CREDENTIALS.relative_to(ROOT)}(密码只在该文件里)")
    return creds


class Api:
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.id_token: str | None = None

    def call(self, method: str, url: str, body: dict | None = None) -> dict:
        headers = {
            "Content-Type": "application/json",
            # iOS key 若开了「仅限 iOS 应用」限制,需要带 bundle id。
            "X-Ios-Bundle-Identifier": BUNDLE_ID,
        }
        if self.id_token and "identitytoolkit" not in url:
            headers["Authorization"] = f"Bearer {self.id_token}"
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(url, data=data, method=method, headers=headers)
        try:
            with urllib.request.urlopen(req) as resp:
                return json.loads(resp.read() or b"{}")
        except urllib.error.HTTPError as e:
            payload = e.read().decode()
            raise RuntimeError(f"{method} {url.split('?')[0]} → {e.code}: {payload}") from None

    # ---- Auth ----
    def auth(self, endpoint: str, email: str, password: str) -> dict:
        url = f"https://identitytoolkit.googleapis.com/v1/accounts:{endpoint}?key={self.api_key}"
        return self.call(
            "POST", url, {"email": email, "password": password, "returnSecureToken": True}
        )

    def sign_in_or_up(self, email: str, password: str) -> tuple[str, bool]:
        try:
            res = self.auth("signInWithPassword", email, password)
            created = False
        except RuntimeError as e:
            msg = str(e)
            if "INVALID_LOGIN_CREDENTIALS" in msg or "EMAIL_NOT_FOUND" in msg:
                try:
                    res = self.auth("signUp", email, password)
                except RuntimeError as e2:
                    if "EMAIL_EXISTS" in str(e2):
                        sys.exit(
                            "该邮箱已注册但密码与 keys/review_account.json 不符。"
                            "改回原密码,或在 Firebase console 删掉该用户后重跑。"
                        )
                    raise
                created = True
            else:
                raise
        self.id_token = res["idToken"]
        return res["localId"], created

    # ---- Firestore ----
    @property
    def docs_base(self) -> str:
        return f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

    def doc_name(self, path: str) -> str:
        return f"projects/{PROJECT_ID}/databases/(default)/documents/{path}"

    def get(self, path: str) -> dict | None:
        try:
            return self.call("GET", f"{self.docs_base}/{path}")
        except RuntimeError as e:
            if "→ 404" in str(e):
                return None
            raise

    def list_ids(self, path: str) -> list[str]:
        res = self.call("GET", f"{self.docs_base}/{path}?pageSize=50")
        return [d["name"].rsplit("/", 1)[1] for d in res.get("documents", [])]

    def commit(self, writes: list[dict]) -> None:
        self.call("POST", f"{self.docs_base}:commit", {"writes": writes})


def s(value: str) -> dict:
    return {"stringValue": value}


def server_time(*field_paths: str) -> list[dict]:
    return [{"fieldPath": p, "setToServerValue": "REQUEST_TIME"} for p in field_paths]


def ensure_profile(api: Api, uid: str, nickname: str) -> str:
    existing = api.get(f"users/{uid}")
    if existing and existing.get("fields", {}).get("nickname", {}).get("stringValue"):
        return "已存在"
    api.commit(
        [
            {
                "update": {
                    "name": api.doc_name(f"users/{uid}"),
                    "fields": {
                        "uid": s(uid),
                        "nickname": s(nickname),
                        "avatarConfig": {"mapValue": {}},
                    },
                },
                "updateTransforms": server_time("createdAt", "updatedAt"),
            }
        ]
    )
    return "已创建"


def find_owned_room(api: Api, uid: str) -> str | None:
    for room_id in api.list_ids(f"users/{uid}/memberships"):
        room = api.get(f"rooms/{room_id}")
        if room and room.get("fields", {}).get("ownerId", {}).get("stringValue") == uid:
            return room_id
    return None


def create_room(api: Api, uid: str, name: str, description: str) -> str:
    """与 lib/features/room/usecase/create_room_usecase.dart 同款格式。"""
    room_id = str(uuid.uuid4())
    salt = base64.urlsafe_b64encode(secrets.token_bytes(16)).decode().rstrip("=")
    share_hash = hashlib.sha256(f"{room_id}:{uid}:{salt}".encode()).hexdigest()
    api.commit(
        [
            {
                "update": {
                    "name": api.doc_name(f"rooms/{room_id}"),
                    "fields": {
                        "roomId": s(room_id),
                        "name": s(name),
                        "description": s(description),
                        "visibility": s("unlisted"),
                        "ownerId": s(uid),
                        "shareLinkHash": s(share_hash),
                        "shareSalt": s(salt),
                        "members": {
                            "mapValue": {
                                "fields": {
                                    uid: {
                                        "mapValue": {
                                            "fields": {"userId": s(uid), "role": s("owner")}
                                        }
                                    }
                                }
                            }
                        },
                    },
                },
                "currentDocument": {"exists": False},
                "updateTransforms": server_time(
                    "createdAt", "updatedAt", f"members.`{uid}`.joinedAt"
                ),
            },
            {
                "update": {
                    "name": api.doc_name(f"users/{uid}/memberships/{room_id}"),
                    "fields": {"roomId": s(room_id), "userId": s(uid), "role": s("owner")},
                },
                "currentDocument": {"exists": False},
                "updateTransforms": server_time("createdAt", "updatedAt"),
            },
        ]
    )
    return room_id


def main() -> None:
    creds = load_credentials()
    api = Api(ios_api_key())

    uid, created = api.sign_in_or_up(creds["email"], creds["password"])
    print(f"账号 {creds['email']}:{'已注册' if created else '已存在'}(uid {uid})")

    print(f"资料(昵称 {creds['nickname']}):{ensure_profile(api, uid, creds['nickname'])}")

    room_id = find_owned_room(api, uid)
    if room_id:
        print(f"测试房间:已存在 {room_id}")
    else:
        room_id = create_room(api, uid, creds["roomName"], creds["roomDescription"])
        print(f"测试房间:已创建 {room_id}「{creds['roomName']}」")

    room = api.get(f"rooms/{room_id}")["fields"]
    link = f"cofit://room/{room_id}?h={room['shareLinkHash']['stringValue']}"
    print(f"邀请链接:{link}")


if __name__ == "__main__":
    main()
