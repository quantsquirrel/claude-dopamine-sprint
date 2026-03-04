#!/usr/bin/env node
/**
 * Session Start Reminder Hook
 *
 * Injects a learning reminder and curriculum update notification
 * at session start based on the user's study streak state.
 */

import { readFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { homedir } from 'os';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const PLUGIN_ROOT = join(__dirname, '..');

function main() {
  // Read stdin with timeout protection
  let input = '';
  try {
    input = readFileSync(0, 'utf8');
  } catch (e) {
    // No stdin available, exit silently
    return;
  }

  // Parse hook input (not strictly needed, but validates we're in a hook context)
  try {
    JSON.parse(input);
  } catch (e) {
    return;
  }

  // Read state.json
  // Check for breadcrumb
  const breadcrumbPath = join(homedir(), '.claude', 'claude-dopamine-sprint', 'breadcrumb.txt');
  let breadcrumbMsg = '';
  if (existsSync(breadcrumbPath)) {
    try {
      const bc = readFileSync(breadcrumbPath, 'utf8').trim();
      if (bc) {
        breadcrumbMsg = `\n🍞 Breadcrumb: \`${bc}\``;
      }
    } catch (e) { /* ignore */ }
  }

  const statePath = join(homedir(), '.claude', 'claude-dopamine-sprint', 'state.json');
  let state;

  if (!existsSync(statePath)) {
    // No state file — first time user
    let msg = 'ADHD Sprint 플러그인이 설치되어 있습니다! `/sprint`로 첫 학습을 시작해보세요.';
    if (breadcrumbMsg) msg += breadcrumbMsg;
    const result = buildResult(msg);
    console.log(JSON.stringify(result));
    return;
  }

  try {
    state = JSON.parse(readFileSync(statePath, 'utf8'));
  } catch (e) {
    // Corrupted state, exit silently
    return;
  }

  const lastStudyDate = state.streak?.lastStudyDate;

  if (!lastStudyDate) {
    // State exists but no study record
    let msg = '아직 학습 기록이 없어요. `/sprint`로 첫 스프린트를!';
    if (breadcrumbMsg) msg += breadcrumbMsg;
    const result = buildResult(msg);
    console.log(JSON.stringify(result));
    return;
  }

  // Calculate days since last study
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const lastDate = new Date(lastStudyDate);
  lastDate.setHours(0, 0, 0, 0);
  const diffMs = today.getTime() - lastDate.getTime();
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

  const current = state.streak?.current || 0;
  const totalSessions = state.totalSessions || 0;

  // Already studied today — show mini progress instead of silence
  if (diffDays === 0) {
    let progressMsg = buildProgressSummary(state);
    if (progressMsg) {
      if (breadcrumbMsg) progressMsg += breadcrumbMsg;
      const result = buildResult(progressMsg);
      console.log(JSON.stringify(result));
    }
    return;
  }

  let msg;

  if (diffDays === 1) {
    msg = `🔥 스트릭 ${current}일! 오늘도 /sprint 한 번?`;
  } else if (diffDays >= 2 && diffDays <= 3) {
    msg = `⚠️ ${diffDays}일째 쉬고 있어요. 스트릭 끊기기 전에 /sprint!`;
  } else {
    // 4+ days
    msg = `📚 ${diffDays}일 만에 돌아오셨군요! /sprint로 다시 시작?`;
  }

  // Load curriculum for topic count and next topic
  const progress = state.progress || {};
  const completed = Object.values(progress).filter(p => p.status === 'completed').length;
  let topicCount = 10;
  try {
    const currPath = join(PLUGIN_ROOT, 'data', 'curriculum.json');
    if (existsSync(currPath)) {
      const curriculum = JSON.parse(readFileSync(currPath, 'utf8'));
      topicCount = curriculum.topics.length;
      const nextTopic = curriculum.topics.find(t => {
        const p = progress[t.id];
        return !p || p.status !== 'completed';
      });
      if (nextTopic) {
        msg += ` | 📊 ${completed}/${topicCount} 완료 | 다음: ${nextTopic.name}`;
      } else {
        msg += ` | 📊 ${completed}/${topicCount} 완료`;
      }
    } else {
      msg += ` | 📊 ${completed}/${topicCount} 토픽 완료`;
    }
  } catch (e) {
    msg += ` | 📊 ${completed}/${topicCount} 토픽 완료`;
  }

  // Check if curriculum update is needed
  const docIndexPath = join(PLUGIN_ROOT, 'data', 'doc-index.json');
  msg = appendUpdateHint(msg, docIndexPath);

  // Append breadcrumb if present
  if (breadcrumbMsg) {
    msg += breadcrumbMsg;
  }

  const result = buildResult(msg);
  console.log(JSON.stringify(result));
}

/**
 * If doc-index.json lastScanned is older than 7 days, append update hint.
 */
function appendUpdateHint(msg, docIndexPath) {
  try {
    if (!existsSync(docIndexPath)) return msg;

    const docIndex = JSON.parse(readFileSync(docIndexPath, 'utf8'));
    const lastScanned = docIndex.lastScanned;

    if (!lastScanned) return msg;

    const scannedDate = new Date(lastScanned);
    const now = new Date();
    const diffMs = now.getTime() - scannedDate.getTime();
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (diffDays >= 7) {
      return msg + ' | 💡 `/sprint update`로 새 기능도 확인해보세요!';
    }
  } catch (e) {
    // Ignore errors reading doc-index
  }

  return msg;
}

/**
 * Build a mini progress summary for users who already studied today.
 */
function buildProgressSummary(state) {
  const progress = state.progress || {};
  const completed = Object.values(progress).filter(p => p.status === 'completed').length;
  const current = state.streak?.current || 0;
  const totalMin = state.totalStudyMinutes || 0;

  if (completed === 0 && current === 0) return null;

  let topicCount = 10;
  try {
    const currPath = join(PLUGIN_ROOT, 'data', 'curriculum.json');
    if (existsSync(currPath)) {
      topicCount = JSON.parse(readFileSync(currPath, 'utf8')).topics.length;
    }
  } catch (e) { /* fallback to 10 */ }

  let parts = [];
  if (current > 0) parts.push(`🔥 ${current}일 스트릭`);
  if (completed > 0) parts.push(`📊 ${completed}/${topicCount} 완료`);
  if (totalMin > 0) parts.push(`⏱️ ${totalMin}분 학습`);

  if (completed >= topicCount) {
    parts.push('🎉 Core 완료! `/quiz`로 복습하거나 `/sprint update`로 새 토픽 확인');
  }

  return parts.join(' | ');
}

/**
 * Build the hook result JSON.
 */
function buildResult(message) {
  return {
    decision: 'approve',
    additionalContext: message,
  };
}

main();
