#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
服务端文件读写工具
服务端文件编码为GBK格式，此工具用于正确读取和保存GBK编码的Lua文件
"""

import sys
import os

ENCODING = 'gbk'

def read_file(file_path):
    """读取GBK编码的文件"""
    if not os.path.exists(file_path):
        print(f"错误: 文件不存在 - {file_path}")
        return None
    
    with open(file_path, 'r', encoding=ENCODING, errors='replace') as f:
        content = f.read()
    
    print(f"成功读取文件: {file_path}")
    print(f"文件编码: {ENCODING}")
    print(f"文件行数: {len(content.splitlines())}")
    return content

def save_file(file_path, content):
    """保存为GBK编码的文件"""
    file_dir = os.path.dirname(file_path)
    if file_dir and not os.path.exists(file_dir):
        os.makedirs(file_dir, exist_ok=True)
    
    with open(file_path, 'w', encoding=ENCODING, errors='replace') as f:
        f.write(content)
    
    print(f"成功保存文件: {file_path}")
    print(f"文件编码: {ENCODING}")

def main():
    if len(sys.argv) < 3:
        print("用法:")
        print("  读取: python adjust_server_file.py read <文件路径>")
        print("  保存: python adjust_server_file.py save <文件路径>")
        print("        (从标准输入读取内容)")
        print("  替换并保存: python adjust_server_file.py replace <文件路径> <搜索字符串> <替换字符串>")
        sys.exit(1)
    
    action = sys.argv[1]
    file_path = sys.argv[2]
    
    if action == 'read':
        content = read_file(file_path)
        if content:
            print("\n" + "="*80)
            print(content)
            print("="*80)
    
    elif action == 'save':
        print("请输入文件内容 (以EOF结束):")
        content = sys.stdin.read()
        save_file(file_path, content)
    
    elif action == 'replace':
        if len(sys.argv) < 5:
            print("错误: replace模式需要提供搜索字符串和替换字符串")
            print("用法: python adjust_server_file.py replace <文件路径> <搜索字符串> <替换字符串>")
            sys.exit(1)
        
        search_str = sys.argv[3]
        replace_str = sys.argv[4]
        
        content = read_file(file_path)
        if content:
            new_content = content.replace(search_str, replace_str)
            if new_content == content:
                print("未找到要替换的字符串")
            else:
                save_file(file_path, new_content)
                print(f"替换完成: '{search_str}' -> '{replace_str}'")
    
    else:
        print(f"未知操作: {action}")
        print("支持的操作: read, save, replace")
        sys.exit(1)

if __name__ == '__main__':
    main()
