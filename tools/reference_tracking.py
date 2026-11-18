"""Analysis only: track the reference fence at its native 30 fps. Requires NumPy/ffmpeg."""
import json, subprocess, sys
from pathlib import Path
import numpy as np
from numpy.lib.stride_tricks import sliding_window_view
raw = subprocess.check_output(['ffmpeg','-v','error','-ss','9','-i',sys.argv[1],'-t','0.6','-pix_fmt','gray','-f','rawvideo','-'])
frames = np.frombuffer(raw,np.uint8).reshape(-1,1108,512).astype(np.float32)
x,y,w,h = 385,512,20,118
template = frames[0,y:y+h,x:x+w]; rows=[]
for i,f in enumerate(frames):
 if i:
  x0=max(0,x-24); y0=max(0,y-32)
  candidates=sliding_window_view(f[y0:min(1108,y+h+33),x0:min(512,x+w+25)],(h,w))
  error=((candidates-template)**2).mean(axis=(-1,-2));dy,dx=np.unravel_index(error.argmin(),error.shape)
  x,y=int(x0+dx),int(y0+dy);rmse=float(np.sqrt(error.min()))
 else: rmse=0.0
 rows.append(dict(time=9+i/30,x=x,y=y,rmse=rmse))
result=dict(fps=30,landmark_xywh=[385,512,w,h],samples=rows,interpretation='Fence displacement includes camera tracking, zoom and shake; cannot isolate hit shake, player world speed or attack timing. No claim of original-engine parameters.')
Path(sys.argv[2]).write_text(json.dumps(result,indent=2));print(json.dumps(result))
