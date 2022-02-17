#!/bin/ash

# exit when any command fails
set -o errexit -o pipefail

# configuration
: "${APP_UID:=503}"
: "${APP_GID:=503}"
: "${APP_UMASK:=027}"
: "${APP_USER:=postfix}"
: "${APP_GROUP:=postfix}"
: "${APP_HOME:=/var/spool/postfix}"
: "${APP_DATA_DIR:=/var/lib/postfix}"
: "${APP_CONF_DIR:=/etc/postfix}"

# export configuration
export APP_CONF_DIR APP_HOME APP_USER APP_GROUP

# invoked as root, add user and prepare container
if [ "$(id -u)" -eq 0 ]; then
  echo ">> removing default user and group"
  if getent passwd "$APP_USER" >/dev/null; then deluser "$APP_USER"; fi
  if getent group "$APP_GROUP" >/dev/null; then delgroup "$APP_GROUP"; fi

  echo ">> adding unprivileged user (uid: $APP_UID / gid: $APP_GID)"
  addgroup -g "$APP_GID" "$APP_GROUP"
  adduser -HD -h "$APP_HOME" -s /sbin/nologin -G "$APP_GROUP" -u "$APP_UID" -k /dev/null "$APP_USER"

  echo ">> fixing permissions"
  install -dm 0750 -o "$APP_USER" -g "$APP_GROUP" "$APP_HOME" "$APP_CONF_DIR"
  chown -R "$APP_USER":"$APP_GROUP" \
          "$APP_HOME" \
          "$APP_DATA_DIR" \
          /etc/s6
  chown -R root:"$APP_GROUP" "$APP_CONF_DIR"

  echo ">> create link for syslog redirection"
  install -dm 0750 -o "$APP_USER" -g "$APP_GROUP" /run/syslogd
  ln -s /run/syslogd/syslogd.sock /dev/log
fi

# tighten umask for newly created files / dirs
echo ">> changing umask to $APP_UMASK"
umask "$APP_UMASK"

echo ">> starting application"
exec /bin/s6-svscan /etc/s6

# vim: set ft=bash ts=2 sts=2 expandtab:

