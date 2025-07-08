ms_to_mmss() {
  local ms=$1
  local total_sec=$(( ms / 1000 ))
  local min=$(( total_sec / 60 ))
  local sec=$(( total_sec % 60 ))
  printf "%d:%02d" "$min" "$sec"
}

while true; do

    playback_data=$(spotify_player get key playback 2>/dev/null)
    player_status=$(echo "$playback_data" | jq '.is_playing')
    artist=$(echo "$playback_data" | jq '.item.artists[0].name')
    title=$(echo "$playback_data" | jq '.item.name')
    progress_ms=$(echo "$playback_data" | jq '.progress_ms')
    duration_ms=$(echo "$playback_data" | jq '.item.duration_ms')

    progress=$(ms_to_mmss "$progress_ms")
    duration=$(ms_to_mmss "$duration_ms")

    if [ "$player_status" = "true" ]; then
        echo "<span color='#1db954'></span> $artist - $title $progress / $duration"
    elif [ "$player_status" = "false" ]; then
        echo "<span color='#1db954'></span>  $artist - $title"
    else
        echo ""
    fi

    sleep 1

done

