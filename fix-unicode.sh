declare file="${1:-data.0.json}"

sed -r -e 's|([^\\])(u[0-9a-f]{4})|\1\\\2|g' \
       -e 's|([^\\])(u[0-9A-F]{4})|\1\\\2|g' \
       -e 's|([^\\])(u[0-9a-f]{4})|\1\\\2|g' \
       -e 's|([^\\])(u[0-9A-F]{4})|\1\\\2|g' \
       -e 's|(wiki/dok)\\(u[0-9a-fA-F]{4})|\1\2|g' \
       -e 's|(Q)\\(uebec)|\1\2|ig' \
       -e 's|(/iss)\\(ue)|\1\2|ig' \
       -e 's|(/incl)\\(ude)|\1\2|ig' \
       -e 's|(clo)\\(udbees)|\1\2|ig' \
       -e 's|(st)\\(uffed)|\1\2|ig' \
       -e 's|(st)\\(ubbed)|\1\2|ig' \
       -e 's|(Sa)\\(udade)|\1\2|ig' \
       -e 's|(A)\\(ubade)|\1\2|ig' \
       -e 's|(Val)\\(ueBean)|\1\2|ig' \
       -e 's|(Val)\\(ueCache)|\1\2|ig' \
       -e 's|(H)\\(ubBacked)|\1\2|ig' \
       -e 's|(St)\\(ubDaem)|\1\2|ig' \
       -e 's|(Cl)\\(ubbed)|\1\2|ig' \
       -e 's|(Pers)\\(uaded)|\1\2|ig' \
       -e 's|(Iss)\\(ueBean)|\1\2|ig' \
       -e 's|(Iss)\\(ueCache)|\1\2|ig' \
       -e 's|(r)\\(ubbed)|\1\2|ig' \
       -e 's|(Bl)\\(uebeard)|\1\2|ig' \
       -e 's|(/)\\(ubcd535\.iso)|\1\2|ig' \
       -e 's|(-dell-)\\(u2414h)|\1\2|ig' \
       -e 's|(dok)\\(u[0-9a-f]{4})|\1\2|ig' "$file" \
    | jq -sr '.[]|select(.rownum != 1 and .type == "regular file" and (.file|startswith("/mnt/WdMyCloud/Seagate_Expansion_Drive/"))).file|ltrimstr("/mnt/WdMyCloud/")' > files_to_move.txt
dos2unix files_to_move.txt  

sed -r -e 's|([^\\])(u[0-9a-f]{4})|\1\\\2|g' \
       -e 's|([^\\])(u[0-9A-F]{4})|\1\\\2|g' \
       -e 's|([^\\])(u[0-9a-f]{4})|\1\\\2|g' \
       -e 's|([^\\])(u[0-9A-F]{4})|\1\\\2|g' \
       -e 's|(wiki/dok)\\(u[0-9a-fA-F]{4})|\1\2|g' \
       -e 's|(Q)\\(uebec)|\1\2|ig' \
       -e 's|(/iss)\\(ue)|\1\2|ig' \
       -e 's|(/incl)\\(ude)|\1\2|ig' \
       -e 's|(clo)\\(udbees)|\1\2|ig' \
       -e 's|(st)\\(uffed)|\1\2|ig' \
       -e 's|(st)\\(ubbed)|\1\2|ig' \
       -e 's|(Sa)\\(udade)|\1\2|ig' \
       -e 's|(A)\\(ubade)|\1\2|ig' \
       -e 's|(Val)\\(ueBean)|\1\2|ig' \
       -e 's|(Val)\\(ueCache)|\1\2|ig' \
       -e 's|(H)\\(ubBacked)|\1\2|ig' \
       -e 's|(St)\\(ubDaem)|\1\2|ig' \
       -e 's|(Cl)\\(ubbed)|\1\2|ig' \
       -e 's|(Pers)\\(uaded)|\1\2|ig' \
       -e 's|(Iss)\\(ueBean)|\1\2|ig' \
       -e 's|(Iss)\\(ueCache)|\1\2|ig' \
       -e 's|(r)\\(ubbed)|\1\2|ig' \
       -e 's|(Bl)\\(uebeard)|\1\2|ig' \
       -e 's|(/)\\(ubcd535\.iso)|\1\2|ig' \
       -e 's|(-dell-)\\(u2414h)|\1\2|ig' \
       -e 's|(dok)\\(u[0-9a-f]{4})|\1\2|ig' "$file" \
    | jq -sc '[.[]|select(.rownum == 1 and .type == "regular file")|{sha256, file}]|unique|sort[]' > nasfiles_index.json
