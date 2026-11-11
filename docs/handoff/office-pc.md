# 사내망 PC 인계 — Gitea 원격으로 전환

작성: 2026-11-11, 개인 PC에서 작업한 Claude가 사내망 PC의 Claude에게 넘긴다.

**이 문서를 읽은 에이전트는 "할 일"을 순서대로 실행한다.** "멈춘다"고 적힌 조건에 걸리면 거기서 멈추고 사람에게 보고한다.

## 요약

- 사내망 PC는 `cp-workspace.bundle`을 만든 시점(`079f999`)에 머물러 있다. 원격이 없고 브랜치는 `master`다.
- 그 번들로 개인 PC에서 저장소를 복원했고, 그 뒤 **원격 저장소 두 곳**을 만들었다.
  - **Gitea (기준 저장소)**: `https://gitea.msjin.workers.dev/msjin-claude-lab/cp_workspace.git`. 개인 NAS에서 돌아간다. **사내망에서 접근되는지는 아직 확인하지 않았다** — 아래 0단계에서 확인한다.
  - **GitHub (읽기 전용 사본)**: `https://github.com/msjin-claude-lab/cp_workspace.git`. Gitea **푸시 미러**가 Gitea에 push가 들어올 때마다 자동으로 맞춘다. 사내망에서는 막혀 있으니 **사내망 PC에는 추가하지 않는다.**
- **모든 PC는 Gitea에만 push한다.** GitHub에는 직접 push하지 않는다(미러가 덮어써서 사라진다).
- 두 원격 모두 기본 브랜치는 `main`이다. `079f999` 위에 커밋이 더 올라가 있다(`git log --oneline 079f999..origin/main`으로 확인):

  | 커밋 | 내용 |
  |---|---|
  | `1c2c8ac` | 원격 구성. `CLAUDE.md`의 "로컬 전용, 원격 추가 금지" 규칙을 없애고, 네트워크 표를 사내망/개인 PC로 나누고, bundle 대신 Gitea clone을 기본 방법으로 삼음. `HANDOFF.md`의 "다른 PC에서 이어가기"도 같은 내용으로 고침 |
  | `4d8f823` | `CLAUDE.md`의 bundle 예시에서 브랜치 이름을 `main`으로 맞춤 |
  | 그 위 | Gitea → GitHub 푸시 미러 구조로 `CLAUDE.md` 갱신, 이 인계 문서 추가 |

- **bundle·메일 전달은 이제 예비 수단이다.** 앞으로는 `git pull` / `git push`로 주고받는다.

## 할 일

### 0. Gitea 접근 확인 (가장 먼저)

저장소를 건드리기 전에 사내망에서 Gitea에 닿는지 확인한다. 아래는 모두 읽기 전용이다.

```bash
nslookup gitea.msjin.workers.dev
curl -sS --max-time 20 https://gitea.msjin.workers.dev/api/v1/version
git ls-remote https://gitea.msjin.workers.dev/msjin-claude-lab/cp_workspace.git
```

| 확인 | 정상 결과 |
|---|---|
| `nslookup` | `Address:`에 IP가 나온다 (2026-11-11 기준 `104.21.x.x`, `172.67.x.x`) |
| `curl` | `{"version":"1.26.4"}` 같은 JSON |
| `git ls-remote` | 로그인 창 없이 `refs/heads/main` 한 줄 이상 |

- **셋 다 정상이면** 1단계로 간다.
- **하나라도 실패하면 여기서 멈춘다.** 저장소는 건드리지 않는다. 사람에게 어느 명령이 어떤 오류 문구로 실패했는지 그대로 보고한다. 원인을 단정하거나 우회(IP 직접 지정, 다른 DNS, 프록시 설정 등)하지 않는다. 실패 원인 판단과 대안 결정은 사람이 한다.

### 1. 현재 상태 확인

저장소 루트에서 실행한다.

```bash
git status --short --branch
git log --oneline -3
git remote -v
git log --oneline 079f999..HEAD      # 번들 이후에 생긴 로컬 커밋
```

- 커밋되지 않은 변경이 있으면 **멈추고** 사람에게 커밋할지 버릴지 묻는다. `.omc/`만 보이면 무시해도 된다(git 추적 대상이 아님).
- `git log 079f999..HEAD`에서 **나온 커밋은 기록해 둔다.** 3단계에서 Gitea 위에 다시 얹어야 한다.
- `079f999`가 이력에 없다는 오류가 나면 **멈춘다.** 다른 저장소이거나 이력이 갈라진 것이다.

### 2. 브랜치 이름을 `main`으로 바꾸고 Gitea를 `origin`으로 연결

```bash
git branch -m master main
git remote add origin https://gitea.msjin.workers.dev/msjin-claude-lab/cp_workspace.git
git config --global credential.https://gitea.msjin.workers.dev.provider generic
git fetch origin
git branch -u origin/main
```

`origin`이 이미 있다면 추가하지 말고 `git remote set-url origin <위 주소>`로 바꾼다. GitHub 주소가 남아 있다면 지운다.

`credential...provider generic`을 설정하는 이유: Git Credential Manager가 이 호스트의 종류를 알아내지 못해 매번 2초 이상 기다리며 경고를 낸다.

`git fetch`가 DNS 오류(`Could not resolve host`)로 실패하면 **재시도하지 말고 멈춘다.** 사람에게 보고만 하고 우회 방법(IP 직접 지정, 다른 DNS 사용 등)은 쓰지 않는다. 사내망 정책을 피하는 일이 되기 때문이다. 이 주소는 2026-11-11에 처음 만들어졌는데, 그 직전에 조회한 DNS 서버는 "없음" 응답을 최대 30분 동안 기억한다.

### 3. Gitea 내용 받기

**1단계에서 로컬 커밋이 없었다면:**

```bash
git merge --ff-only origin/main
```

**로컬 커밋이 있었다면:**

```bash
git rebase origin/main
```

충돌이 나면 양쪽 의도를 모두 살려서 해결한다. 판단이 서지 않으면 **멈추고** 보고한다. 충돌이 날 만한 곳은 `CLAUDE.md`의 "git" 절과 "다른 PC로 옮기기" 절, `HANDOFF.md`의 "다른 PC에서 이어가기" 절이다.

**검증:**

```bash
git log --oneline -3                 # 맨 위가 origin/main과 같은 커밋 (로컬 커밋이 있었다면 그 위에)
git status -sb | head -1             # ## main...origin/main
```

### 4. 로컬 커밋이 있었다면 push

```bash
git push
```

처음 push하면 Git Credential Manager 로그인 창이 뜬다. **사람이 직접** Gitea 계정 이름과 액세스 토큰을 입력해야 한다. 토큰은 Gitea **설정 → 애플리케이션**에서 `repository: 읽기/쓰기` 권한으로 만든다. 사람에게 그렇게 안내하고, 토큰을 채팅에 붙여 넣으라고 하지 않는다.

로컬 커밋이 없었다면 이 단계는 건너뛴다. clone·fetch·pull은 로그인 없이 된다(2026-11-11 현재 공개 저장소).

### 5. 보고

사람에게 아래 내용을 알린다.

- 최종 `git log --oneline -3`, `git remote -v`
- 로컬 커밋을 push했는지 여부
- 아래 "알아둘 것"의 첫 두 항목

## 알아둘 것

- **Gitea → GitHub 동기화는 자동이다.** 사내망 PC에서 Gitea에 push하면 Gitea 푸시 미러가 GitHub로 복사한다. 사내망 PC에서 할 일은 없다. 미러가 멈추면(대개 Gitea에 넣은 GitHub 토큰 만료) GitHub만 뒤처지며, 개인 PC에서 확인·조치한다.
- **Gitea 저장소는 현재 공개 상태다.** 주소만 알면 누구나 clone할 수 있다. 회사 관련 내용을 올리기 전에 사람에게 비공개 전환 여부를 확인한다. 비공개로 바꾸면 clone·fetch에도 토큰이 필요하다.
- **`https://git.msjin.workers.dev`는 쓰지 않는다.** GitHub을 우회하는 프록시라서 사내망 정책을 피해 가는 것이 된다. 원격으로 추가하거나 접속 확인을 하지 않는다.
- Gitea가 자기 주소를 아직 `http://mjins.synology.me:9080`으로 알고 있다. 그래서 웹 화면에 보이는 clone 주소가 이 주소로 나오는데, **사내망에서는 쓸 수 없으니 복사해 쓰지 말고** 이 문서의 `gitea.msjin.workers.dev` 주소를 쓴다. (NAS의 `app.ini`에서 `ROOT_URL`을 바꾸면 고쳐진다. 사람이 할 일이다.)
- 개인 PC 쪽 기록 (사내망 PC에는 해당 없음): JDK 21.0.13(Microsoft)과 Maven 3.9.16을 새로 설치했고, `mvn -q test` 결과는 14개 중 13개 통과, 1개 실패(`FeeCalculatorTest.chargesOnlyDaysBeyondGrace`)로 기대값 그대로다. 연습 과제는 아직 풀지 않았다.

## 사내망 PC Claude에게 붙여 넣을 시작 문장

Gitea에서 이 문서를 바로 볼 수 있다. 다만 2단계 전에는 로컬에 이 파일이 없으니, 아래처럼 주소를 같이 넘긴다.

```
저장소 루트에서 작업한다. 아래 인계 문서를 읽고 "할 일"을 순서대로 진행해라.
https://gitea.msjin.workers.dev/msjin-claude-lab/cp_workspace/raw/branch/main/docs/handoff/office-pc.md
```
