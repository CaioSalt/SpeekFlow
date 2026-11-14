awk 'match($0, /GUw7IE/){print substr($0, RSTART-500, 800); exit}' /app/dist_injected/assets/index-BrlXRz2h.js
