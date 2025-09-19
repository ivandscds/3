#!/data/data/com.termux/files/usr/bin/bash
# Script para descargar playlist de YouTube en 360p y convertir a M3U8
# Excluye videos 104-108 y borra el MP4 después de convertir

PLAYLIST_URL="https://youtube.com/playlist?list=PL24C8378F296DB656&si=TZeeSW2DO_FNYku9"

# Rutas fijas en la SD card
DIR_MP4="/storage/8874-1708/bfdi-temp"
DIR_M3U8="/storage/8874-1708/bfdi-m3u8"

# Crear carpetas si no existen
mkdir -p "$DIR_MP4"
mkdir -p "$DIR_M3U8"

# Función para instalar paquetes si es necesario
install_if_needed() {
    pkg_name=$1
    read -p "¿Tienes instalado $pkg_name? (s/n): " resp
    if [[ "$resp" =~ ^[Nn]$ ]]; then
        echo "⬇️ Instalando $pkg_name..."
        pkg install -y "$pkg_name"
    else
        echo "✅ $pkg_name ya instalado, continuando..."
    fi
}

# Revisar e instalar dependencias
install_if_needed "python"
install_if_needed "ffmpeg"

read -p "¿Tienes instalado yt-dlp? (s/n): " resp_yt
if [[ "$resp_yt" =~ ^[Nn]$ ]]; then
    echo "⬇️ Instalando yt-dlp..."
    pip install -U yt-dlp
else
    echo "✅ yt-dlp ya instalado, continuando..."
fi

# Descargar playlist en 360p, excluyendo videos 104-108
echo "⬇️ Iniciando descarga de la playlist en 360p (excluyendo videos 104-108)..."
yt-dlp -f "bestvideo[height<=360]+bestaudio/best[height<=360]" \
  --playlist-items "1-103,109-" \
  -o "$DIR_MP4/%(title)s.%(ext)s" \
  "$PLAYLIST_URL"

# Convertir a M3U8 y borrar cada MP4
for mp4 in "$DIR_MP4"/*.mp4; do
    [ -e "$mp4" ] || continue
    base=$(basename "$mp4" .mp4)

    echo "🎬 Creando $base.m3u8 desde $base.mp4..."
    ffmpeg -i "$mp4" -c copy -hls_time 10 -hls_list_size 0 -f hls "$DIR_M3U8/$base.m3u8"

    if [ $? -eq 0 ]; then
        echo "🗑 Borrando $base.mp4..."
        rm "$mp4"
        echo "✅ $base.m3u8 creado y $base.mp4 eliminado."
    else
        echo "⚠️ Error con $base.mp4, no se borrará."
    fi
done

echo "🎉 Proceso completado. Todos los M3U8 están en $DIR_M3U8"
