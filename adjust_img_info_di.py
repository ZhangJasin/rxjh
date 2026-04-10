#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
调整 img_info_di.png 的色系，参考 dropdown_normal.png 的色调
保持阴影样式不变
"""

from PIL import Image, ImageStat
import os

def analyze_image(image_path):
    """分析图片的平均颜色"""
    img = Image.open(image_path).convert('RGBA')
    rgb_img = img.convert('RGB')
    stat = ImageStat.Stat(rgb_img)
    return {
        'avg_rgb': stat.mean,
        'image': img,
        'size': img.size
    }

def adjust_color_tone(source_img, target_img):
    """
    将源图片的色调调整为目标图片的色调
    保持透明度和阴影不变
    """
    # 转换为 HSV 空间
    hsv_source = source_img.convert('HSV')
    hsv_target = target_img.convert('HSV')
    
    # 计算平均色相差异
    source_stat = ImageStat.Stat(hsv_source)
    target_stat = ImageStat.Stat(hsv_target)
    
    source_avg_h = source_stat.mean[0]
    target_avg_h = target_stat.mean[0]
    source_avg_s = source_stat.mean[1]
    target_avg_s = target_stat.mean[1]
    source_avg_v = source_stat.mean[2]
    target_avg_v = target_stat.mean[2]
    
    # 计算色相偏移
    hue_shift = target_avg_h - source_avg_h
    
    print(f"源图片平均 HSV: H={source_avg_h:.1f}, S={source_avg_s:.1f}, V={source_avg_v:.1f}")
    print(f"目标图片平均 HSV: H={target_avg_h:.1f}, S={target_avg_s:.1f}, V={target_avg_v:.1f}")
    print(f"色相偏移: {hue_shift:.1f}")
    
    # 计算饱和度和明度比例
    s_ratio = target_avg_s / source_avg_s if source_avg_s > 0 else 1.0
    v_ratio = target_avg_v / source_avg_v if source_avg_v > 0 else 1.0
    
    print(f"饱和度比例: {s_ratio:.2f}")
    print(f"明度比例: {v_ratio:.2f}")
    
    # 应用调整
    width, height = hsv_source.size
    pixels = hsv_source.load()
    
    for y in range(height):
        for x in range(width):
            h, s, v, a = source_img.getpixel((x, y))[:4]
            
            # 只调整非完全透明的像素（保持透明度）
            if a > 0:
                # 调整色相
                h = (h + int(hue_shift)) % 256
                
                # 调整饱和度
                s = min(255, int(s * s_ratio))
                
                # 调整明度
                v = min(255, int(v * v_ratio))
                
                pixels[x, y] = (h, s, v)
    
    # 转换回 RGBA
    result_rgb = hsv_source.convert('RGBA')
    
    # 恢复原始透明度
    result_pixels = result_rgb.load()
    source_pixels = source_img.load()
    
    for y in range(height):
        for x in range(width):
            r, g, b = result_pixels[x, y][:3]
            a = source_pixels[x, y][3] if len(source_pixels[x, y]) > 3 else 255
            result_pixels[x, y] = (r, g, b, a)
    
    return result_rgb

def main():
    # 文件路径
    source_path = r'd:\works\RXjianghu\rxjianghu1\9963d_rxjh_fgui_project\assets\public\image\img_info_di.png'
    target_path = r'd:\works\RXjianghu\rxjianghu1\9963d_rxjh_fgui_project\assets\public\image\dropdown_normal.png'
    output_path = source_path
    
    # 检查文件
    if not os.path.exists(source_path):
        print(f"错误: 找不到源文件 {source_path}")
        return
    
    if not os.path.exists(target_path):
        print(f"错误: 找不到目标文件 {target_path}")
        return
    
    print("="*60)
    print("分析图片颜色")
    print("="*60)
    
    # 分析图片
    source_info = analyze_image(source_path)
    target_info = analyze_image(target_path)
    
    print(f"\n源图片 (img_info_di.png):")
    print(f"  尺寸: {source_info['size']}")
    print(f"  平均 RGB: R={source_info['avg_rgb'][0]:.1f}, G={source_info['avg_rgb'][1]:.1f}, B={source_info['avg_rgb'][2]:.1f}")
    
    print(f"\n目标图片 (dropdown_normal.png):")
    print(f"  尺寸: {target_info['size']}")
    print(f"  平均 RGB: R={target_info['avg_rgb'][0]:.1f}, G={target_info['avg_rgb'][1]:.1f}, B={target_info['avg_rgb'][2]:.1f}")
    
    print("\n" + "="*60)
    print("调整色调")
    print("="*60 + "\n")
    
    # 备份原图
    backup_path = source_path.replace('.png', '_backup.png')
    if not os.path.exists(backup_path):
        import shutil
        shutil.copy2(source_path, backup_path)
        print(f"已备份原图到: {backup_path}")
    
    # 调整色调
    result_img = adjust_color_tone(source_info['image'], target_info['image'])
    
    # 保存
    result_img.save(output_path, 'PNG')
    print(f"\n已保存调整后的图片到: {output_path}")
    
    # 验证
    print("\n" + "="*60)
    print("验证结果")
    print("="*60)
    result_info = analyze_image(output_path)
    print(f"调整后平均 RGB: R={result_info['avg_rgb'][0]:.1f}, G={result_info['avg_rgb'][1]:.1f}, B={result_info['avg_rgb'][2]:.1f}")
    
    print("\n✅ 处理完成!")

if __name__ == '__main__':
    main()
