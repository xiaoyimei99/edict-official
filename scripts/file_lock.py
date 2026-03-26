"""
文件锁工具 — 防止多进程并发读写 JSON 文件导致数据丢失。

用法:
    from file_lock import atomic_json_update, atomic_json_read

    # 原子读取
    data = atomic_json_read(path, default=[])

    # 原子更新（读 → 修改 → 写回，全程持锁）
    def modifier(tasks):
        tasks.append(new_task)
        return tasks 
    atomic_json_update(path, modifier, default=[])
"""
import json
import os
import pathlib
import tempfile
import time
from typing import Any, Callable


def _lock_path(path: pathlib.Path) -> pathlib.Path:
    return path.parent / (path.name + '.lock')


class FileLock:
    """跨平台文件锁实现"""
    def __init__(self, lock_file: pathlib.Path):
        self.lock_file = lock_file
    
    def __enter__(self):
        # 尝试创建锁文件
        while True:
            try:
                # 在Windows上，os.open配合O_CREAT|O_EXCL可以实现原子性创建
                fd = os.open(str(self.lock_file), os.O_CREAT | os.O_EXCL | os.O_WRONLY)
                os.close(fd)
                break
            except FileExistsError:
                # 锁文件已存在，等待
                time.sleep(0.1)
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        # 释放锁
        if self.lock_file.exists():
            try:
                self.lock_file.unlink()
            except:
                pass


def atomic_json_read(path: pathlib.Path, default: Any = None) -> Any:
    """持锁读取 JSON 文件。"""
    if not path.exists():
        return default
    
    lock_file = _lock_path(path)
    with FileLock(lock_file):
        try:
            return json.loads(path.read_text(encoding='utf-8'))
        except Exception:
            return default


def atomic_json_update(
    path: pathlib.Path,
    modifier: Callable[[Any], Any],
    default: Any = None,
) -> Any:
    """
    原子地读取 → 修改 → 写回 JSON 文件。
    modifier(data) 应返回修改后的数据。
    使用临时文件 + rename 保证写入原子性。
    """
    lock_file = _lock_path(path)
    with FileLock(lock_file):
        # Read
        try:
            data = json.loads(path.read_text(encoding='utf-8')) if path.exists() else default
        except Exception:
            data = default
        # Modify
        result = modifier(data)
        # Atomic write via temp file + rename
        tmp_fd, tmp_path = tempfile.mkstemp(
            dir=str(path.parent), suffix='.tmp', prefix=path.stem + '_'
        )
        try:
            with os.fdopen(tmp_fd, 'w', encoding='utf-8') as f:
                json.dump(result, f, ensure_ascii=False, indent=2)
            os.replace(tmp_path, str(path))
        except Exception:
            os.unlink(tmp_path)
            raise
        return result


def atomic_json_write(path: pathlib.Path, data: Any) -> None:
    """原子写入 JSON 文件（持排他锁 + tmpfile rename）。
    直接写入，不读取现有内容（避免 atomic_json_update 的多余读开销）。
    """
    lock_file = _lock_path(path)
    with FileLock(lock_file):
        tmp_fd, tmp_path = tempfile.mkstemp(
            dir=str(path.parent), suffix='.tmp', prefix=path.stem + '_'
        )
        try:
            with os.fdopen(tmp_fd, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            os.replace(tmp_path, str(path))
        except Exception:
            os.unlink(tmp_path)
            raise