#!/usr/bin/env python3

import argparse
import cv2
import json
import numpy as np
import sys

DEFAULT_IMAGE_PATH = '/tmp/quickshell/media/screenshot/image'

def iou(boxA, boxB):
    # Compute intersection over union for two boxes
    xA = max(boxA['x'], boxB['x'])
    yA = max(boxA['y'], boxB['y'])
    xB = min(boxA['x'] + boxA['width'], boxB['x'] + boxB['width'])
    yB = min(boxA['y'] + boxA['height'], boxB['y'] + boxB['height'])
    interW = max(0, xB - xA)
    interH = max(0, yB - yA)
    interArea = interW * interH
    boxAArea = boxA['width'] * boxA['height']
    boxBArea = boxB['width'] * boxB['height']
    
    if (boxAArea + boxBArea - interArea) == 0:
        return 0
    return interArea / float(boxAArea + boxBArea - interArea)

def non_max_suppression(regions, iou_threshold=0.6): # Bajé un poco el umbral para limpiar más
    if not regions:
        return []
        
    # Sort by area (largest first)
    regions = sorted(regions, key=lambda r: r['width'] * r['height'], reverse=True)
    keep = []
    
    while regions:
        current = regions.pop(0)
        keep.append(current)
        # Suppress regions that overlap significantly with the current region
        regions = [r for r in regions if iou(current, r) < iou_threshold]
        
    return keep

def find_regions(image_path, min_width, min_height, max_width=None, max_height=None, quality=False, k=150, min_size=20, sigma=0.8, resize_factor=None):
    # Optimización: Cargar sin canal alfa si no es necesario para segmentación
    image = cv2.imread(image_path, cv2.IMREAD_COLOR)
    if image is None:
        print(f'Error: Could not load image {image_path}', file=sys.stderr)
        sys.exit(1)
        
    orig_h, orig_w = image.shape[:2]
    
    # --- MEJORA: Escalado Inteligente ---
    # Si no se define factor, calculamos uno para que el lado más largo sea ~500px
    # Esto equilibra velocidad y precisión en cualquier monitor (1080p o 4K)
    if resize_factor is None:
        target_dim = 500
        resize_factor = target_dim / max(orig_h, orig_w)
        # No escalar si la imagen ya es pequeña
        if resize_factor > 1.0: resize_factor = 1.0
    
    # Aplicar redimensionado
    if resize_factor != 1.0:
        new_w = int(orig_w * resize_factor)
        new_h = int(orig_h * resize_factor)
        image_proc = cv2.resize(image, (new_w, new_h), interpolation=cv2.INTER_AREA)
    else:
        image_proc = image.copy()

    # Inicializar Selective Search
    ss = cv2.ximgproc.segmentation.createSelectiveSearchSegmentation()
    ss.setBaseImage(image_proc)
    
    if quality:
        ss.switchToSelectiveSearchQuality(k, min_size, sigma)
    else:
        ss.switchToSelectiveSearchFast(k, min_size, sigma)
        
    rects = ss.process()
    regions = []
    
    for (x, y, w, h) in rects:
        # Escalar coordenadas de vuelta al tamaño original
        if resize_factor != 1.0:
            x = int(x / resize_factor)
            y = int(y / resize_factor)
            w = int(w / resize_factor)
            h = int(h / resize_factor)
            
        # Filtrar región que es exactamente la imagen completa (fondo)
        if w >= orig_w - 5 and h >= orig_h - 5:
            continue
            
        # Filtros de tamaño
        if w > min_width and h > min_height:
            if (max_width is None or w < max_width) and (max_height is None or h < max_height):
                
                # --- MEJORA: Filtro de Relación de Aspecto (Aspect Ratio) ---
                # Evita detectar líneas muy finas o columnas muy delgadas que no son ventanas
                aspect_ratio = w / float(h)
                if 0.15 < aspect_ratio < 6.0: # Solo permitir formas rectangulares razonables
                    regions.append({'x': int(x), 'y': int(y), 'width': int(w), 'height': int(h)})

    # Eliminar duplicados
    regions = non_max_suppression(regions, iou_threshold=0.65)
    return regions, cv2.imread(image_path) # Retornar imagen original para debug

def draw_regions(image, regions, output_path):
    for region in regions:
        if 'x' in region:
            x, y, w, h = region['x'], region['y'], region['width'], region['height']
        elif 'at' in region and 'size' in region:
            x, y = region['at']
            w, h = region['size']
        else:
            continue
        cv2.rectangle(image, (x, y), (x + w, y + h), (0, 255, 0), 2) # Verde para mejor visibilidad
    cv2.imwrite(output_path, image)

def main():
    parser = argparse.ArgumentParser(description='Find regions of interest in an image using selective search.')
    parser.add_argument('-i', '--image', default=DEFAULT_IMAGE_PATH, help='Path to input image')
    parser.add_argument('-do', '--debug-output', help='Path to save debug image with rectangles')
    parser.add_argument('--min-width', type=int, default=150, help='Minimum width (Tweaked default)')
    parser.add_argument('--min-height', type=int, default=80, help='Minimum height (Tweaked default)')
    parser.add_argument('--max-width', type=int, help='Maximum width of detected region')
    parser.add_argument('--max-height', type=int, help='Maximum height of detected region')
    parser.add_argument('--single', action='store_true', help='Only output the most likely (largest) region')
    parser.add_argument('--quality', action='store_true', help='Use quality mode for selective search (slower, less sensitive)')
    parser.add_argument('--k', type=int, default=3000, help='Segmentation parameter k (default: 3000)')
    parser.add_argument('--min-size', type=int, default=50, help='Segmentation parameter min_size (default: 50)')
    parser.add_argument('--sigma', type=float, default=0.6, help='Segmentation parameter sigma (default: 0.6)')
    # Cambié el default a None para activar el cálculo automático inteligente
    parser.add_argument('--resize-factor', type=float, default=None, help='Resize factor. Leave empty for auto-calc.')
    parser.add_argument('--hyprctl', action='store_true', help='Mimics hyprctl window output')
    args = parser.parse_args()

    regions, image = find_regions(
        args.image,
        min_width=args.min_width,
        min_height=args.min_height,
        max_width=args.max_width,
        max_height=args.max_height,
        quality=args.quality,
        k=args.k,
        min_size=args.min_size,
        sigma=args.sigma,
        resize_factor=args.resize_factor
    )
    
    if args.single and regions:
        largest = max(regions, key=lambda r: r['width'] * r['height'])
        regions = [largest]
        
    if args.hyprctl:
        regions = [{"at": [r['x'], r['y']], "size": [r['width'], r['height']]} for r in regions]
        
    print(json.dumps(regions))
    
    if args.debug_output:
        draw_regions(image, regions, args.debug_output)

if __name__ == '__main__':
    main()
