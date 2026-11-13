#!/usr/bin/env node
/**
 * Stop hook — 정시 구간마다 한 번, 원격과 로컬을 비교해 pull/push 여부를 묻게 한다.
 *
 * - 그 구간에 이미 점검했으면(세션 시작 점검 포함) 아무것도 하지 않는다.
 * - pull 대상(원격에만 있는 커밋)이나 push 대상(로컬에만 있는 커밋·커밋 안 한 변경)이
 *   있으면 Stop을 막고(decision: block) Claude에게 질문을 맡긴다.
 * - 물을 것은 없지만 원격 확인(fetch)이 실패했으면 경고만 띄운다.
 * - 둘 다 아니면 조용히 끝난다.
 */

import { readFileSync } from "node:fs";
import { alreadyCheckedThisHour, askInstruction, compare, markChecked, summaryLine } from "./sync-core.mjs";

try {
  let input = {};
  try {
    input = JSON.parse(readFileSync(0, "utf8") || "{}");
  } catch {}
  // 이 hook이 막아서 이어진 대답의 끝이면 다시 막지 않는다(무한 반복 방지).
  if (input.stop_hook_active) process.exit(0);
  if (alreadyCheckedThisHour()) process.exit(0);
  markChecked(); // 결과와 상관없이 이 구간은 점검한 것으로 기록(원격이 느려도 매번 기다리지 않게)

  const r = compare();
  if (!r.ok) process.exit(0);

  if (r.askPull || r.askPush) {
    process.stdout.write(JSON.stringify({ decision: "block", reason: askInstruction(r, "대답 종료 시") }));
  } else if (r.fetchError) {
    process.stdout.write(JSON.stringify({ systemMessage: summaryLine(r) }));
  }
} catch {
  // git 저장소가 아니거나 git 실패 — 대화를 막지 않는다
}
process.exit(0);
