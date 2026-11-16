# Gitea 연결 점검

`git pull`·`push`가 안 될 때 **어디서 끊겼는지** 가르는 절차다. 증상마다 범인이 다르므로 순서대로 좁힌다.

원격: `http://222.112.172.253:9080/msjin-claude-lab/cp_workspace.git`

## 1. 증상 코드부터 구분한다

| 증상 | 뜻 | 범인 |
|---|---|---|
| `Could not connect` (타임아웃) | 패킷이 서비스까지 닿지 못함 | 공유기 포워딩·방화벽 |
| `Connection refused` | NAS까지 갔지만 그 포트에 아무도 없음 | nginx·컨테이너가 내려감 |
| `HTTP 5xx` | 연결은 됐고 서버가 응답함 | Gitea 처리 쪽 |
| `Failed to authenticate` | **서버까지 정상 도달** | 자격 증명 |

섞어서 하나의 원인으로 설명하려 하지 말 것. 증상이 중간에 바뀌면 원인이 바뀐 것이다.

## 2. 포트가 살아 있는지 (git 없이)

```bash
for p in 9080 5001 80; do
  timeout 8 bash -c "cat < /dev/null > /dev/tcp/222.112.172.253/$p" 2>/dev/null \
    && echo "$p: OK" || echo "$p: 실패"
done
```

`5001`·`80`은 되는데 `9080`만 실패하면 NAS는 켜져 있고 **9080 길목만** 끊긴 것이다. 이땐 NAS 안을 뒤질 필요가 없다 — 공유기 포워딩과 Synology 방화벽을 본다.

## 3. NAS 안쪽 (사람이 NAS에서)

```bash
docker port gitea                              # 3000/tcp -> 127.0.0.1:3000 이 정상
sudo netstat -tlnp | grep -E ':9080|:3000'     # ss 는 없다
docker logs --tail 50 gitea
```

Gitea는 **루프백 3000**에만 열려 있고, 외부 9080은 **DSM 역방향 프록시**(제어판 → 로그인 포털 → 고급)가 받아서 넘긴다. 그러니 `netstat`에 `0.0.0.0:9080 nginx`와 `127.0.0.1:3000 docker-proxy`가 **둘 다** 보여야 정상이다.

Gitea 로그에 요청이 하나도 안 찍히는데 cron(`CleanupOldRuns`)은 돌고 있다면, Gitea는 멀쩡하고 **요청이 도착하지 못하는 것**이다.

## 4. 읽기와 쓰기를 따로 본다

이 저장소는 **공개**라 읽기는 인증이 필요 없다. 그래서 아래 세 가지로는 자격 증명을 확인할 수 없다:

- `git fetch` / `git ls-remote` — 익명으로 된다
- `git push --dry-run` (올릴 것 없음) — 서버에 연결조차 안 한다
- `git push --dry-run` (새 ref) — ref 목록은 익명 GET으로 내려온다. 인증은 객체를 올리는 POST에서만 요구된다

**자격 증명 확인은 실제 push뿐이다.**

```bash
git log --oneline origin/main..HEAD    # 올릴 커밋이 있는지 먼저 확인
git push origin main
```

실패하면 GCM 창에 Gitea 계정 이름 + 액세스 토큰(설정 → 애플리케이션, `repository: 읽기/쓰기`)을 넣는다. 토큰은 채팅에 붙여 넣지 않는다.

저장된 자격 증명 보기:

```powershell
cmdkey /list | Select-String "222.112"
```

## 점검 기록

| 날짜 | 결과 |
|---|---|
| 2026-11-12 | clone·fetch·push 전부 정상 (커밋 `f0948af` push 성공) |
| 2026-11-13 | 9080 타임아웃 — NAS·Gitea·nginx 모두 정상인데 요청이 도달하지 못함. 공유기/방화벽 쪽에서 복구 후 정상 |
