# cp-workspace

모든 프로젝트의 **공통 뼈대**다. 여기에는 프로젝트 전부가 공유하는 환경 사실과 규칙만 둔다.
개별 프로젝트는 `projects/<name>/` 아래에 두고, 그 프로젝트에만 해당하는 규칙은 거기의 `CLAUDE.md`에 쓴다.

```
cp-workspace/
├── CLAUDE.md            ← 이 파일. 모든 프로젝트가 공유하는 규칙
├── .omc-workspace       ← OMC 상태 루트 앵커
├── .claude/CLAUDE.md    ← OMC 코디네이터 관리 영역. 손대지 말 것
└── projects/
    └── loan/            ← 개별 프로젝트
```

`.omc-workspace` 마커 때문에 `projects/` 아래 프로젝트가 **자체 git 저장소**가 되더라도 OMC 상태(`.omc/`)는 여기 하나로 모인다. 프로젝트마다 상태가 흩어지지 않는다.

## 네트워크 제약

**차단된 것은 `github.com` 하나뿐이다.** 패키지 레지스트리는 열려 있다 (2026-11-11 실측).

| 호스트 | 상태 |
|---|---|
| `github.com` | 차단 |
| `registry.npmjs.org` | 가용 |
| `repo.maven.apache.org` | 가용 |

따라서 npm·Maven 의존성은 자유롭게 추가해도 된다. GitHub에서 받아오는 것만 안 된다.

### 사용할 수 없는 스킬

`gh` CLI 미설치 + GitHub 차단이라 아래는 이 워크스페이스에서 동작하지 않는다. 시도하지 말 것:

`/pr` · `/babysit` · `/fix-ci` · `/get-pr-comments` · `/review`(GitHub PR용 — 작업 중인 diff 리뷰는 `/omc-review`를 쓴다)

## git

**로컬 전용이다.** 원격을 추가하거나 push 하지 않는다. 커밋·브랜치·rebase 등 로컬 작업은 모두 정상이다.

## 설치된 도구

| 도구 | 버전 |
|---|---|
| JDK | 21.0.11 (LTS) |
| Maven | 3.9.11 |
| Node | 24.18.0 / npm 11.16.0 |
| Python | 3.12.10 |

**`jq`는 없다.** JSON 파일은 Read/Edit 도구로 수정한다. `jq`에 의존하는 셸 스크립트는 실패하므로(OMC의 `setup-progress.sh`가 그렇다) 같은 변경을 Edit로 직접 재현한다.

`gradle`, `gh`도 없다.

## 새 프로젝트를 추가할 때

1. `projects/<name>/` 생성
2. 프로젝트 고유 규칙·빌드 명령은 `projects/<name>/CLAUDE.md`에
3. 모든 프로젝트에 해당하는 사실을 알게 되면 이 파일에 추가한다
