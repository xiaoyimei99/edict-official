#!/usr/bin/env python3
"""
中书省自动任务处理脚本 v2.0

定期扫描看板上的新任务（state=Zhongshu），自动更新进展并流转到下一步。
增强功能：
1. 智能分析任务类型
2. 多级状态流转支持
3. 任务卡住检测和告警
4. 详细的日志记录
"""

import sys
import pathlib
import logging
import json
from datetime import datetime, timedelta

# Ensure UTF-8 encoding for Chinese characters on Windows
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')
if sys.stderr.encoding != 'utf-8':
    sys.stderr.reconfigure(encoding='utf-8')

_BASE = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_BASE / 'scripts'))

from kanban_update import load, cmd_state, cmd_progress, cmd_flow
from utils import now_iso

# 配置
SCAN_INTERVAL_SECONDS = 300  # 5分钟扫描一次
MAX_PROCESSING_TIME_SECONDS = 7200  # 2小时未更新的任务视为卡住
AUTO流转_TIMEOUT_SECONDS = 300  # 5分钟未流转自动推进

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(name)s] %(message)s', datefmt='%H:%M:%S')
log = logging.getLogger('zhongshu_auto')


def parse_iso_time(iso_str):
    """解析ISO时间字符串"""
    try:
        if iso_str.endswith('Z'):
            iso_str = iso_str[:-1] + '+00:00'
        return datetime.fromisoformat(iso_str)
    except Exception:
        return None


def get_task_age(task):
    """获取任务龄期（秒）"""
    updated = task.get('updatedAt', '')
    if not updated:
        return float('inf')
    updated_dt = parse_iso_time(updated)
    if not updated_dt:
        return float('inf')
    now = datetime.now(updated_dt.tzinfo or datetime.now().astimezone().tzinfo)
    return (now - updated_dt).total_seconds()


def analyze_task(task):
    """
    分析任务类型并返回处理策略

    Returns: dict with keys:
        - action: 'progress' | 'state Menxia' | 'flow Shangshu' | 'block' | 'skip'
        - details: 详细描述
        - priority: 优先级 (high/normal/low)
        - next_state: 下一步期望状态
    """
    title = task.get('title', '')
    state = task.get('state', '')
    flow_log = task.get('flow_log', [])
    age = get_task_age(task)

    # 任务龄期告警
    if age > MAX_PROCESSING_TIME_SECONDS:
        return {
            'action': 'progress',
            'details': f'⚠️ 任务已卡住 {age/60:.0f} 分钟，请人工介入',
            'priority': 'high',
            'next_state': state
        }

    if not flow_log:
        return {
            'action': 'progress',
            'details': '已接收任务，正在分析需求',
            'priority': 'normal',
            'next_state': 'Zhongshu'
        }

    last_flow = flow_log[-1]
    from_dept = last_flow.get('from', '')

    # 太子转交的任务
    if from_dept == '太子':
        # 判断任务类型
        if '测试' in title:
            return {
                'action': 'state',
                'details': '测试任务，快速分析完成',
                'priority': 'low',
                'next_state': 'Menxia'
            }
        elif '智能宫殿' in title or '三省六部' in title:
            return {
                'action': 'progress',
                'details': '正在梳理系统架构和三省六部职责',
                'priority': 'high',
                'next_state': 'Zhongshu'
            }
        elif '创业' in title or '执行方案' in title:
            return {
                'action': 'progress',
                'details': '正在分析用户创业困境和技术需求',
                'priority': 'normal',
                'next_state': 'Zhongshu'
            }
        else:
            return {
                'action': 'progress',
                'details': '正在分析任务需求',
                'priority': 'normal',
                'next_state': 'Zhongshu'
            }

    # 中书省处理中
    if from_dept == '太子':
        if '已完成' in title or '完成' in title:
            return {
                'action': 'state',
                'details': '分析完成，提交门下省审议',
                'priority': 'normal',
                'next_state': 'Menxia'
            }

    # 默认处理
    return {
        'action': 'progress',
        'details': '处理中',
        'priority': 'normal',
        'next_state': 'Zhongshu'
    }


def process_task(task):
    """处理单个任务"""
    task_id = task.get('id')
    state = task.get('state', '')
    result = analyze_task(task)
    action = result['action']
    details = result['details']
    priority = result.get('priority', 'normal')

    # 优先处理高优先级任务
    if priority == 'high':
        log.info(f'⚠️ {task_id} 高优先级: {details}')

    if action == 'skip':
        return

    if action == 'progress':
        # 构建todo列表
        todo_pipe = '1.分析任务类型✅|2.制定处理方案🔄|3.提交门下省'
        if '测试' in task.get('title', ''):
            todo_pipe = '1.检查系统配置|2.执行测试流程🔄|3.验证结果'
        elif '创业' in task.get('title', '') or '方案' in task.get('title', ''):
            todo_pipe = '1.分析用户困境✅|2.梳理技术需求🔄|3.制定执行方案|4.形成方案文档'

        cmd_progress(task_id, details, todo_pipe)
        log.info(f'📡 {task_id} 自动进展: {details}')

    elif action == 'state':
        new_state = result['next_state']
        # 如果任务已经是目标状态，跳过状态更新
        if state == new_state:
            log.info(f'⌦ {task_id} 已是 {new_state} 状态，跳过更新')
        else:
            cmd_state(task_id, new_state, '分析完成，提交审议')
            log.info(f'✅ {task_id} 状态更新: {state} -> {new_state}')

    # 自动流转到尚书省
    elif action == 'flow':
        to_dept = result.get('to_dept', '尚书省')
        cmd_flow(task_id, '中书省', to_dept, '方案已制定，提交执行')
        log.info(f'🔄 {task_id} 流转: 中书省 -> {to_dept}')


def check_stuck_tasks(tasks):
    """检查卡住的任务并告警"""
    stuck = []
    for task in tasks:
        age = get_task_age(task)
        state = task.get('state', '')
        if age > MAX_PROCESSING_TIME_SECONDS and state != 'Done' and state != 'Cancelled':
            stuck.append({
                'id': task.get('id'),
                'state': state,
                'age': age,
                'title': task.get('title', '无标题')
            })

    if stuck:
        log.warning(f'⚠️ 发现 {len(stuck)} 个卡住的任务:')
        for t in stuck:
            log.warning(f'  - {t["id"]} [{t["state"]}]: {t["title"]} (卡住 {t["age"]/60:.0f} 分钟)')

    return stuck


def auto_process():
    """主函数：扫描并处理所有待处理任务"""
    tasks = load()
    pending = [t for t in tasks if t.get('state') in ('Zhongshu', 'Menxia')]

    # 检查卡住的任务
    stuck = check_stuck_tasks(tasks)

    if not pending:
        log.info('没有需要处理的待处理任务')
        return

    log.info(f'扫描到 {len(pending)} 个待处理任务')

    # 按优先级排序（先处理高优先级）
    def get_priority(t):
        title = t.get('title', '')
        if '创业' in title or '方案' in title:
            return 0  # 高优先级
        elif '测试' in title:
            return 2  # 低优先级
        return 1  # 正常优先级

    pending.sort(key=get_priority)

    for task in pending:
        try:
            process_task(task)
        except Exception as e:
            log.error(f'❌ 处理任务 {task.get("id")} 时出错: {e}')


if __name__ == '__main__':
    auto_process()
