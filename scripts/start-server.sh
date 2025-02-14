#!/bin/bash
CUR_V="$(find ${SERVER_DIR} -name installed_v_* | cut -d "_" -f3)"
#Check latest version available
LAT_V="$(curl -s https://api.github.com/repos/JGRennison/OpenTTD-patches/releases/latest | grep tag_name | cut -d '"' -f4)"
if [ -z $LAT_V ]; then				#ref https://ryanstutorials.net/bash-scripting-tutorial/bash-if-statements.php and https://stackoverflow.com/questions/18096670/what-does-z-mean-in-bash and https://tldp.org/LDP/abs/html/comparison-ops.html
	echo "Error:  Could not determine latest available version.  Is the server able to access the internet, or has the source file on github moved or been changed?  If latest was selected during container setup, the build will fail.  Enter a game version manually in the interim, i.e. jgrpp-0.38.0"
else
	echo "Latest available: $LAT_V"
fi

if [ -z $LAT_V ]; then
  if [ -z $CUR_V ]; then
    echo "---Something went wrong, couldn't get latest version---"
    sleep infinity
  else
    echo "---Can't get latest OpenTTD build version, falling back to installed version $CUR_V!---"
    LAT_V=$CUR_V
  fi
fi

GFX_PK_CUR_V="$(cat ${SERVER_DIR}/baseset/changelog.txt 2>/dev/null | head -1 | cut -d ' ' -f2)"
if [ "${GFX_PK_V}" = "latest" ]; then
  echo "---Getting latest OpenGFX version...---"
  GFX_PK_V="$(curl -s https://cdn.openttd.org/opengfx-releases/latest.yaml | grep "version:" | cut -d ' ' -f3)"
  if [ -z ${GFX_PK_V} ]; then
    if [ -z $GFX_PK_CUR_V ]; then
      echo "---Something went wrong, couldn't get latest build version---"
      sleep infinity
    else
      echo "---Can't get latest OpenGFX version, falling back to installed version $GFX_PK_CUR_V!---"
      GFX_PK_V=$GFX_PK_CUR_V
    fi
  else
    echo "---Latest OpenGFX version is: $GFX_PK_V---"
  fi
else
  echo "---Manually set OpenGFX version to ${GFX_PK_V}---"
fi

if [ ! -s ${SERVER_DIR}/installed_v_$LAT_V ]; then
  rm -rf ${SERVER_DIR}/installed_v_$LAT_V
fi

echo "---Version Check---"
if [ ! -f ${SERVER_DIR}/openttd ]; then
  echo
  echo "-------------------------------------"
  echo "---OpenTTD not found! Downloading,---"
  echo "-----and installing v$LAT_V-----"
  echo "-------------------------------------"
  cd ${SERVER_DIR}
  #https://github.com/JGRennison/OpenTTD-patches/releases/download/jgrpp-0.47.0/openttd-jgrpp-0.47.0-linux-generic-amd64.tar.xz
  if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${SERVER_DIR}/installed_v_${LAT_V} https://github.com/JGRennison/OpenTTD-patches/releases/download/${LAT_V}/openttd-${LAT_V}-linux-generic-amd64.tar.xz ; then
    echo "---Successfully downloaded OpenTTD v$LAT_V---"
  else
    echo "---Can't download OpenTTD v$LAT_V putting server into sleep mode---"
    sleep infinity
  fi
  tar --strip-components=1 -xf installed_v_$LAT_V -C ${SERVER_DIR}/
elif [ "$LAT_V" != "$CUR_V" ]; then
  echo
  echo "--------------------------------------------------------------------------"
  echo "---Version missmatch! Installed v$CUR_V, installing v$LAT_V!---"
  echo "--------------------------------------------------------------------------"
  echo
  cd ${SERVER_DIR}
  rm -rf ${SERVER_DIR}/installed_v_*
  if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${SERVER_DIR}/installed_v_${LAT_V} https://github.com/JGRennison/OpenTTD-patches/releases/download/${LAT_V}/openttd-${LAT_V}-linux-generic-amd64.tar.xz ; then
    echo "---Successfully downloaded OpenTTD v$LAT_V---"
  else
    echo "---Can't download OpenTTD v$LAT_V putting server into sleep mode---"
    sleep infinity
  fi
  tar --strip-components=1 -xf installed_v_$LAT_V -C ${SERVER_DIR}/
else
	echo "---OpenTTD v$LAT_V found---"
fi

if [ ! -f ${SERVER_DIR}/baseset/changelog.txt ]; then
  echo "---OpenGFX not found, downloading...---"
  cd ${SERVER_DIR}
  if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${SERVER_DIR}/opengfx-${GFX_PK_V}.zip https://cdn.openttd.org/opengfx-releases/${GFX_PK_V}/opengfx-${GFX_PK_V}-all.zip ; then
    echo "---Successfully downloaded OpenGFX---"
  else
    echo "---Can't download OpenGFX putting server into sleep mode---"
    sleep infinity
  fi
  unzip ${SERVER_DIR}/opengfx-${GFX_PK_V}.zip
  tar --strip-components=1 -xf ${SERVER_DIR}/opengfx-${GFX_PK_V}.tar -C ${SERVER_DIR}/baseset/
  rm ${SERVER_DIR}/opengfx-${GFX_PK_V}.zip ${SERVER_DIR}/opengfx-${GFX_PK_V}.tar
elif [ "$GFX_PK_CUR_V" != "$GFX_PK_V" ]; then
  echo "---Newer version for OpenGFX found, installing!---"
  cd ${SERVER_DIR}
  if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${SERVER_DIR}/opengfx-${GFX_PK_V}.zip https://cdn.openttd.org/opengfx-releases/${GFX_PK_V}/opengfx-${GFX_PK_V}-all.zip ; then
    echo "---Successfully downloaded OpenGFX---"
  else
    echo "---Can't download OpenGFX putting server into sleep mode---"
    sleep infinity
  fi
  unzip ${SERVER_DIR}/opengfx-${GFX_PK_V}.zip
  tar --strip-components=1 -xf ${SERVER_DIR}/opengfx-${GFX_PK_V}.tar -C ${SERVER_DIR}/baseset/
  rm ${SERVER_DIR}/opengfx-${GFX_PK_V}.zip ${SERVER_DIR}/opengfx-${GFX_PK_V}.tar
else
  echo "---OpenGFX found---"
fi

echo "---Prepare Server---"
if [ ! -f ~/.screenrc ]; then
    echo "defscrollback 30000
bindkey \"^C\" echo 'Blocked. Please use to command \"exit\" to shutdown the server or close this window to exit the terminal.'" > ~/.screenrc
fi
chmod -R ${DATA_PERM} ${DATA_DIR}
echo "---Checking for old logs---"
find ${SERVER_DIR} -name "masterLog.*" -exec rm -f {} \;
echo "---Server ready---"

echo "---Start Server---"
cd ${SERVER_DIR}
screen -S OpenTTD -L -Logfile ${SERVER_DIR}/masterLog.0 -d -m ${SERVER_DIR}/openttd -D ${GAME_PARAMS}
sleep 2
if [ "${ENABLE_WEBCONSOLE}" == "true" ]; then
    /opt/scripts/start-gotty.sh 2>/dev/null &
fi
screen -S watchdog -d -m /opt/scripts/start-watchdog.sh
tail -f ${SERVER_DIR}/masterLog.0