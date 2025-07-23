set -e 
magick icon.png -define icon:auto-resize=16,32,48 favicon.ico
sizes=(120 152 167 180)
for size in "${sizes[@]}"; do
  magick icon.png -resize ${size}x${size} apple-touch-icon-${size}x${size}.png
done
