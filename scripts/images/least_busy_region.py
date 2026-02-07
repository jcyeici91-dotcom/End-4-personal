#!/usr/bin/env python3
import os
os.environ["OPENCV_LOG_LEVEL"] = "SILENT"
import cv2
import numpy as np
import argparse
import json
import logging
from typing import Tuple, Optional, List, Union

# Configurar logging
logging.basicConfig(format='%(levelname)s: %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

class NumpyEncoder(json.JSONEncoder):
    """Garantiza que los tipos de datos de Numpy sean serializables a JSON."""
    def default(self, obj):
        if isinstance(obj, (np.int_, np.intc, np.intp, np.int8,
                            np.int16, np.int32, np.int64, np.uint8,
                            np.uint16, np.uint32, np.uint64)):
            return int(obj)
        elif isinstance(obj, (np.float_, np.float16, np.float32, np.float64)):
            return float(obj)
        elif isinstance(obj, (np.ndarray,)):
            return obj.tolist()
        return json.JSONEncoder.default(self, obj)

def center_crop(img: np.ndarray, target_w: int, target_h: int) -> np.ndarray:
    """Recorta el centro de la imagen al tamaño objetivo."""
    h, w = img.shape[:2]
    if w == target_w and h == target_h:
        return img
    
    # Calcular coordenadas para el recorte centrado
    x1 = max(0, (w - target_w) // 2)
    y1 = max(0, (h - target_h) // 2)
    x2 = min(w, x1 + target_w)
    y2 = min(h, y1 + target_h)
    
    return img[y1:y2, x1:x2]

def load_and_process_image(image_path: str, screen_width: Optional[int] = None, screen_height: Optional[int] = None, screen_mode: str = "fill", grayscale: bool = False) -> np.ndarray:
    """Carga, escala y recorta la imagen según la configuración de pantalla."""
    flags = cv2.IMREAD_GRAYSCALE if grayscale else cv2.IMREAD_COLOR
    img = cv2.imread(image_path, flags)
    
    if img is None:
        raise FileNotFoundError(f"Image not found or could not be read: {image_path}")

    orig_h, orig_w = img.shape[:2]

    # Si no se especifican dimensiones de pantalla, devolver original
    if screen_width is None or screen_height is None:
        logger.debug(f"Using original image size: {orig_w}x{orig_h}")
        return img

    # Calcular escala
    scale_w = screen_width / orig_w
    scale_h = screen_height / orig_h
    
    if screen_mode == "fill":
        scale = max(scale_w, scale_h)
    else:
        scale = min(scale_w, scale_h)

    new_w = int(orig_w * scale)
    new_h = int(orig_h * scale)

    logger.debug(f"Scaling image to {new_w}x{new_h} (scale: {scale:.3f}, mode: {screen_mode})")
    
    # Redimensionar (Lanczos4 es mejor calidad para downscaling)
    img = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_LANCZOS4)
    
    # Recortar al tamaño exacto de pantalla
    img = center_crop(img, screen_width, screen_height)
    
    return img

def calculate_integral_images(arr: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
    """Calcula imágenes integrales para suma y suma cuadrada."""
    integral = cv2.integral(arr, sdepth=cv2.CV_64F)[1:, 1:]
    integral_sq = cv2.integral(arr ** 2, sdepth=cv2.CV_64F)[1:, 1:]
    return integral, integral_sq

def region_sum(ii: np.ndarray, x1: int, y1: int, x2: int, y2: int) -> float:
    """Calcula la suma de una región usando la imagen integral en O(1)."""
    total = ii[y2, x2]
    if x1 > 0:
        total -= ii[y2, x1 - 1]
    if y1 > 0:
        total -= ii[y1 - 1, x2]
    if x1 > 0 and y1 > 0:
        total += ii[y1 - 1, x1 - 1]
    return total

def find_least_busy_region(image_path, region_width=300, region_height=200, **kwargs):
    # Extraer argumentos específicos y pasar el resto al loader
    stride = kwargs.get('stride', 2)
    horizontal_padding = kwargs.get('horizontal_padding', 50)
    vertical_padding = kwargs.get('vertical_padding', 50)
    busiest = kwargs.get('busiest', False)

    img = load_and_process_image(image_path, kwargs.get('screen_width'), kwargs.get('screen_height'), kwargs.get('screen_mode', 'fill'), grayscale=True)
    
    arr = img.astype(np.float64)
    h, w = arr.shape
    stride = max(1, int(stride))

    # Ajustar padding
    if horizontal_padding * 2 >= w: horizontal_padding = (w - 1) // 2
    if vertical_padding * 2 >= h: vertical_padding = (h - 1) // 2

    # Validar tamaño región
    max_region_w = w - 2 * horizontal_padding
    max_region_h = h - 2 * vertical_padding
    
    if max_region_w <= 0 or max_region_h <= 0:
        return (0,0), 0.0 # Fail safe

    region_width = min(region_width, max_region_w)
    region_height = min(region_height, max_region_h)

    integral, integral_sq = calculate_integral_images(arr)
    area = region_width * region_height

    best_var = None
    best_coords = (horizontal_padding, vertical_padding)

    # Definir límites de búsqueda
    x_start, y_start = horizontal_padding, vertical_padding
    x_end = w - region_width - horizontal_padding
    y_end = h - region_height - vertical_padding

    for y in range(y_start, y_end + 1, stride):
        for x in range(x_start, x_end + 1, stride):
            x2, y2 = x + region_width - 1, y + region_height - 1
            
            s = region_sum(integral, x, y, x2, y2)
            s2 = region_sum(integral_sq, x, y, x2, y2)
            
            mean = s / area
            var = (s2 / area) - (mean ** 2)

            if best_var is None:
                best_var = var
                best_coords = (x, y)
                continue

            if busiest:
                if var > best_var:
                    best_var = var
                    best_coords = (x, y)
            else:
                if var < best_var:
                    best_var = var
                    best_coords = (x, y)

    return best_coords, best_var

def find_largest_region(image_path, **kwargs):
    # Extraer argumentos
    stride = kwargs.get('stride', 2)
    threshold = kwargs.get('threshold', 100.0)
    aspect_ratio = kwargs.get('aspect_ratio', 1.0)
    horizontal_padding = kwargs.get('horizontal_padding', 50)
    vertical_padding = kwargs.get('vertical_padding', 50)

    img = load_and_process_image(image_path, kwargs.get('screen_width'), kwargs.get('screen_height'), kwargs.get('screen_mode', 'fill'), grayscale=True)
    
    arr = img.astype(np.float64)
    h, w = arr.shape
    stride = max(1, int(stride))

    # Ajustar padding
    if horizontal_padding * 2 >= w: horizontal_padding = (w - 1) // 2
    if vertical_padding * 2 >= h: vertical_padding = (h - 1) // 2

    integral, integral_sq = calculate_integral_images(arr)

    # Espacio efectivo
    effective_w = w - 2 * horizontal_padding
    effective_h = h - 2 * vertical_padding
    
    if effective_w <= 0 or effective_h <= 0:
        return None, (0, 0), None

    # Búsqueda binaria para el tamaño máximo
    min_size = 10
    if aspect_ratio >= 1.0:
        max_size = min(effective_h, int(effective_w / aspect_ratio))
    else:
        max_size = min(int(effective_h * aspect_ratio), effective_w)

    best_result = None

    while min_size <= max_size:
        mid = (min_size + max_size) // 2
        
        if aspect_ratio >= 1.0:
            region_h = mid
            region_w = int(round(mid * aspect_ratio))
        else:
            region_w = mid
            region_h = int(round(mid / aspect_ratio if aspect_ratio != 0 else mid))

        if region_w <= 0 or region_h <= 0: break
        
        # Validar límites
        if region_w > effective_w or region_h > effective_h:
            max_size = mid - 1
            continue

        found = False
        area = region_w * region_h
        
        x_start, y_start = horizontal_padding, vertical_padding
        x_end = w - region_w - horizontal_padding
        y_end = h - region_h - vertical_padding

        # Escanear imagen
        for y in range(y_start, y_end + 1, stride):
            for x in range(x_start, x_end + 1, stride):
                x2, y2 = x + region_w - 1, y + region_h - 1
                
                s = region_sum(integral, x, y, x2, y2)
                s2 = region_sum(integral_sq, x, y, x2, y2)
                
                mean = s / area
                var = (s2 / area) - (mean ** 2)

                if var <= threshold:
                    found = True
                    # Guardamos este resultado como candidato y probamos uno más grande
                    best_result = (x, y, region_w, region_h, var)
                    break
            if found: break
        
        if found:
            min_size = mid + 1
        else:
            max_size = mid - 1

    if best_result:
        x, y, region_w, region_h, var = best_result
        center_x = x + region_w // 2
        center_y = y + region_h // 2
        return (center_x, center_y), (region_w, region_h), var
    
    return None, (0, 0), None

def get_dominant_color(image_path, x, y, w, h, **kwargs):
    # Cargar imagen EN COLOR
    img = load_and_process_image(image_path, kwargs.get('screen_width'), kwargs.get('screen_height'), kwargs.get('screen_mode', 'fill'), grayscale=False)
    
    # Asegurar límites
    x, y = max(0, int(x)), max(0, int(y))
    w, h = int(w), int(h)
    
    # Recorte seguro
    region = img[y:min(y+h, img.shape[0]), x:min(x+w, img.shape[1])]
    
    if region.size == 0:
        return [0, 0, 0]

    # Aplanar y filtrar negros
    pixels = region.reshape((-1, 3))
    non_black = pixels[np.any(pixels > 15, axis=1)] # Umbral de negro ligeramente subido
    
    if non_black.shape[0] == 0:
        target_pixels = pixels # Si todo es negro, usar todo
    else:
        target_pixels = non_black

    target_pixels = np.float32(target_pixels)
    
    if target_pixels.shape[0] < 5:
        return [int(c) for c in np.mean(target_pixels, axis=0)[::-1]] # BGR a RGB

    # K-means optimizado
    criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 10, 1.0)
    K = 3
    flags = cv2.KMEANS_RANDOM_CENTERS
    _, labels, centers = cv2.kmeans(target_pixels, K, None, criteria, 10, flags)
    
    # Color más frecuente
    counts = np.bincount(labels.flatten())
    dominant = centers[np.argmax(counts)]
    
    # BGR a RGB
    return [int(c) for c in reversed(dominant)]

def main():
    parser = argparse.ArgumentParser(description="Find least busy region in an image.")
    parser.add_argument("image_path", help="Path to the input image")
    parser.add_argument("--width", type=int, default=300, help="Region width")
    parser.add_argument("--height", type=int, default=200, help="Region height")
    parser.add_argument("-v", "--visual-output", action="store_true", help="Output image with rectangle")
    parser.add_argument("--screen-width", type=int, default=1920, help="Screen width")
    parser.add_argument("--screen-height", type=int, default=1080, help="Screen height")
    parser.add_argument("--stride", type=int, default=10, help="Step size")
    parser.add_argument("--screen-mode", choices=["fill", "fit"], default="fill", help="Scaling mode")
    parser.add_argument("--verbose", action="store_true", help="Log debug info")
    parser.add_argument("-l", "--largest-region", action="store_true", help="Find largest region under variance threshold")
    parser.add_argument("-t", "--variance-threshold", type=float, default=1000.0, help="Variance threshold")
    parser.add_argument("--aspect-ratio", type=float, default=1.78, help="Aspect ratio for largest region")
    parser.add_argument("--horizontal-padding", "-hp", type=int, default=50, help="Horizontal padding")
    parser.add_argument("--vertical-padding", "-vp", type=int, default=50, help="Vertical padding")
    parser.add_argument("--busiest", action="store_true", help="Find busiest region instead")
    
    args = parser.parse_args()

    if args.verbose:
        logger.setLevel(logging.DEBUG)

    # Empaquetar argumentos comunes
    common_args = {
        'screen_width': args.screen_width,
        'screen_height': args.screen_height,
        'screen_mode': args.screen_mode,
        'stride': args.stride,
        'horizontal_padding': args.horizontal_padding,
        'vertical_padding': args.vertical_padding
    }

    if args.largest_region:
        center, size, var = find_largest_region(
            args.image_path,
            threshold=args.variance_threshold,
            aspect_ratio=args.aspect_ratio,
            **common_args
        )
        
        if center:
            cx, cy = center
            rw, rh = size
            
            # Obtener color dominante
            # IMPORTANTE: Calcular coordenadas de la esquina superior izquierda para el recorte
            x_top_left = cx - rw // 2
            y_top_left = cy - rh // 2
            
            dom_color = get_dominant_color(args.image_path, x_top_left, y_top_left, rw, rh, **common_args)
            dom_hex = '#{:02x}{:02x}{:02x}'.format(*dom_color)

            output = {
                "center_x": int(cx),
                "center_y": int(cy),
                "width": int(rw),
                "height": int(rh),
                "variance": float(var),
                "dominant_color": dom_hex
            }
            print(json.dumps(output, cls=NumpyEncoder))
            
            if args.visual_output:
                img_debug = load_and_process_image(args.image_path, args.screen_width, args.screen_height, args.screen_mode)
                cv2.rectangle(img_debug, (x_top_left, y_top_left), (x_top_left + rw, y_top_left + rh), (255, 0, 0), 3)
                cv2.imwrite('output.png', img_debug)
        else:
            print(json.dumps({"error": "No region found under the threshold."}))

    else:
        # Modo por defecto: Least Busy Region
        coords, variance = find_least_busy_region(
            args.image_path,
            region_width=args.width,
            region_height=args.height,
            busiest=args.busiest,
            **common_args
        )
        
        # Coords es top-left, convertir a centro
        x, y = coords
        center_x = x + args.width // 2
        center_y = y + args.height // 2
        
        dom_color = get_dominant_color(args.image_path, x, y, args.width, args.height, **common_args)
        dom_hex = '#{:02x}{:02x}{:02x}'.format(*dom_color)

        output = {
            "center_x": int(center_x),
            "center_y": int(center_y),
            "width": int(args.width),
            "height": int(args.height),
            "variance": float(variance) if variance is not None else 0.0,
            "dominant_color": dom_hex
        }
        print(json.dumps(output, cls=NumpyEncoder))

        if args.visual_output:
            img_debug = load_and_process_image(args.image_path, args.screen_width, args.screen_height, args.screen_mode)
            cv2.rectangle(img_debug, (x, y), (x + args.width, y + args.height), (0, 0, 255), 3)
            cv2.imwrite('output.png', img_debug)

if __name__ == "__main__":
    main()
