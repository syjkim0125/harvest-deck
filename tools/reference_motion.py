"""Analysis only. Usage: python3 tools/reference_motion.py VIDEO.mp4 OUTPUT.json
Requires ffmpeg, Pillow, NumPy; NOT a runtime dependency. Does not copy reference art into game.
"""
import json, subprocess, sys, tempfile
from pathlib import Path
import numpy as np
from PIL import Image
from numpy.lib.stride_tricks import sliding_window_view
with tempfile.TemporaryDirectory() as scratch:
    images=[]
    for i,t in enumerate((9.0,9.2)):
        p=Path(scratch)/f'{i}.png'
        subprocess.run(['ffmpeg','-v','error','-ss',str(t),'-i',sys.argv[1],'-frames:v','1',str(p)],check=True)
        images.append(np.asarray(Image.open(p).convert('L'),dtype=np.float32))
    a,b=images
    x,y,w,h=385,512,20,118
    template=a[y:y+h,x:x+w]
    x0,y0=365,552
    patches=sliding_window_view(b[y0:750,x0:425],(h,w))
    ssd=((patches-template)**2).mean(axis=(-1,-2))
    oy,ox=np.unravel_index(ssd.argmin(),ssd.shape)
    x1,y1=int(x0+ox),int(y0+oy)
    result={'frames_seconds':[9.0,9.2],'reference_landmark_rect_xywh':[x,y,w,h],
            'matched_landmark_xy':[x1,y1],'background_displacement_px':[x1-x,y1-y],
            'patch_rmse':float(np.sqrt(ssd.min())),
            'interpretation':'Tracking+shake+motion combined. Not isolated camera shake or exact player speed.'}
    Path(sys.argv[2]).write_text(json.dumps(result,indent=2))
    print(json.dumps(result))
