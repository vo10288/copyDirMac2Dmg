#!/bin/bash

# Controllo dei parametri
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <directory_sorgente> <directory_destinazione>"
    exit 1
fi

# Variabili
SOURCE_DIR="$1"
DESTINATION_DIR="$2"
SOURCE_NAME=$(basename "$SOURCE_DIR")
TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
DMG_PATH="${DESTINATION_DIR}/${SOURCE_NAME}-${TIMESTAMP}.dmg"
HASH_FILE="${DESTINATION_DIR}/${SOURCE_NAME}-hash-${TIMESTAMP}.csv"
FILE_LIST="${DESTINATION_DIR}/${SOURCE_NAME}-elenco-file-${TIMESTAMP}.csv"
ALL_HASHES="${DESTINATION_DIR}/${SOURCE_NAME}-hash-all-files-${TIMESTAMP}.csv"
INFO_FILE="${DESTINATION_DIR}/${SOURCE_NAME}-mac-info-${TIMESTAMP}.txt"

# Identificazione del Mac con il seriale e altre info
SERIAL_NUMBER=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $NF}')
echo "Numero di serie del Mac: ${SERIAL_NUMBER}" > "${INFO_FILE}"
echo "Percorso logico copiato: ${SOURCE_DIR}" >> "${INFO_FILE}"
echo "Percorso destinazione copiato: ${DESTINATION_DIR}" >> "${INFO_FILE}"
echo "Copyright Aka Vision" >> "${INFO_FILE}"

# Creazione del DMG da una directory
echo "Creando il file DMG..."
hdiutil create -volname "Backup ${TIMESTAMP}" -srcfolder "${SOURCE_DIR}" -ov -format UDZO "${DMG_PATH}"

# Calcolo dell'hash SHA256 del DMG
echo "Calcolando l'hash SHA256 del DMG..."
shasum -a 256 "${DMG_PATH}" | awk -v sn="${SERIAL_NUMBER}" '{ print sn "," $1 }' > "${HASH_FILE}"
echo "Hash del file DMG: $(cat ${HASH_FILE})"

# Montaggio del DMG
MOUNT_POINT="/Volumes/Backup ${TIMESTAMP}"
hdiutil attach "${DMG_PATH}" -mountpoint "${MOUNT_POINT}"

# Lista dei file e calcolo degli hash
echo "Elencando e calcolando gli hash dei file nel DMG..."
echo "Percorsi dei file:" > "${FILE_LIST}"
echo "Percorso del file, Hash SHA256" > "${ALL_HASHES}"
find "${MOUNT_POINT}" -type f -print0 | while IFS= read -r -d '' file; do
    RELATIVE_PATH="${file#${MOUNT_POINT}/}"
    echo "${RELATIVE_PATH}" | tee -a "${FILE_LIST}"
    shasum -a 256 "${file}" | awk -v fname="${RELATIVE_PATH}" -v sn="${SERIAL_NUMBER}" '{ print fname "," $1 }' | tee -a "${ALL_HASHES}"
done

# Smontaggio del volume
hdiutil detach "${MOUNT_POINT}"

# Notifica audio che la copia è terminata
say "copia della directory terminata"
cat copyright.csv
# Apertura dei file hash e lista per verificare
open "${HASH_FILE}"
open "${FILE_LIST}"
open "${ALL_HASHES}"
open "${INFO_FILE}"

echo "Operazione completata. File generati:"
echo "File DMG: ${DMG_PATH}"
echo "File di hash del DMG: ${HASH_FILE}"
echo "Elenco file: ${FILE_LIST}"
echo "Hash di tutti i file: ${ALL_HASHES}"
echo "Informazioni del Mac: ${INFO_FILE}"
