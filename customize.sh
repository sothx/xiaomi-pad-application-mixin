# shellcheck disable=SC2148
# shellcheck disable=SC2034
SKIPUNZIP=0
. "$MODPATH"/util_functions.sh
magisk_path=/data/adb/modules/
module_id=$(grep_prop id $MODPATH/module.prop)
has_been_patch_privapp_permissions_product=0

if [[ "$KSU" == "true" ]]; then
  ui_print "- KernelSU 用户空间当前的版本号: $KSU_VER_CODE"
  ui_print "- KernelSU 内核空间当前的版本号: $KSU_KERNEL_VER_CODE"
else
  ui_print "- Magisk 版本: $MAGISK_VER_CODE"
  if [ "$MAGISK_VER_CODE" -lt 26000 ]; then
    ui_print "*********************************************"
    ui_print "! 请安装 Magisk 26.0+"
    abort "*********************************************"
  fi
fi

if [[ -d "$magisk_path$module_id" ]]; then
  ui_print "*********************************************"
  ui_print "模块不允许覆盖安装，请卸载模块并重启平板后再尝试安装！"
  abort "*********************************************"
fi

if [[ -d $magisk_path"xiaomi-pad-hyper-content-extension" ]]; then
  ui_print "*********************************************"
  ui_print "存在互斥模块[HyperOS For Pad 传送门补丁]，请卸载模块并重启平板后再尝试安装！"
  abort "*********************************************"
fi

key_check() {
  while true; do
    key_check=$(/system/bin/getevent -qlc 1)
    key_event=$(echo "$key_check" | awk '{ print $3 }' | grep 'KEY_')
    key_status=$(echo "$key_check" | awk '{ print $4 }')
    if [[ "$key_event" == *"KEY_"* && "$key_status" == "DOWN" ]]; then
      keycheck="$key_event"
      break
    fi
  done
  while true; do
    key_check=$(/system/bin/getevent -qlc 1)
    key_event=$(echo "$key_check" | awk '{ print $3 }' | grep 'KEY_')
    key_status=$(echo "$key_check" | awk '{ print $4 }')
    if [[ "$key_event" == *"KEY_"* && "$key_status" == "UP" ]]; then
      break
    fi
  done
}

add_post_fs_data() {
  local line="$1"
  printf "\n$line\n" >>"$MODPATH"/post-fs-data.sh
}

ui_print "*********************************************"
ui_print "- 是否安装传送门？"
ui_print "  音量+ ：是"
ui_print "  音量- ：否"
ui_print "*********************************************"
key_check
if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
  # 检查权限文件是否拷贝
  if [[ "$has_been_patch_privapp_permissions_product" == 0 ]]; then
    has_been_patch_privapp_permissions_product=1
    patch_privapp_permissions_product $MODPATH
    add_post_fs_data 'patch_privapp_permissions_product $MODDIR'
  fi
  # 选择传送门的安装方式
  ui_print "*********************************************"
  ui_print "- 请选择传送门的安装方式？"
  ui_print "  音量+ ：仅修补传送门权限(不自动安装)"
  ui_print "  音量- ：修补权限并固化传送门为系统应用(自动安装)"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 正在为你修补传送门的权限，请稍等~"
    rm -rf "$MODPATH"/common/apks/MIUIContentExtension.apk
    patch_permissions "$MODPATH" "MIUIContentExtension"
    add_post_fs_data 'patch_permissions $MODDIR "MIUIContentExtension"'
    ui_print "- 好诶，传送门权限修补完成，请自行安装传送门并通过[scene]或者[爱玩机工具箱]固化传送门~"
  else
    ui_print "- 正在为你修补传送门的权限，请稍等~"
    patch_permissions "$MODPATH" "MIUIContentExtension"
    add_post_fs_data 'patch_permissions $MODDIR "MIUIContentExtension"'
    ui_print "- 正在为你固化传送门，请稍等~"
    if [[ ! -d $MODPATH"/system/product/priv-app/MIUIContentExtension/" ]]; then
      mkdir -p $MODPATH"/system/product/priv-app/MIUIContentExtension/"
    fi
    cp -f $MODPATH/common/apks/MIUIContentExtension.apk $MODPATH/system/product/priv-app/MIUIContentExtension/MIUIContentExtension.apk
    unzip -jo "$ZIPFILE" 'common/apks/MIUIContentExtension.apk' -d /data/local/tmp/ &>/dev/null
    if [[ ! -f /data/local/tmp/MIUIContentExtension.apk ]]; then
      abort "- 坏诶，传送门安装失败，无法进行安装！"
    else
      pm install -r /data/local/tmp/MIUIContentExtension.apk &>/dev/null
      rm -rf /data/local/tmp/MIUIContentExtension.apk
      rm -rf "$MODPATH"/common/apks/MIUIContentExtension.apk
      HAS_BEEN_INSTALLED_MIUIContentExtension_APK=$(pm list packages | grep com.miui.contentextension)
      if [[ $HAS_BEEN_INSTALLED_MIUIContentExtension_APK == *"package:com.miui.contentextension"* ]]; then
        ui_print "- 好诶，传送门安装完成！"
      else
        abort "- 坏诶，传送门安装失败，请尝试重新安装！"
      fi
    fi
  fi
else
  ui_print "- 你选择不安装传送门！"
fi

ui_print "*********************************************"
ui_print "- 是否安装悬浮球？"
ui_print "  音量+ ：是"
ui_print "  音量- ：否"
ui_print "*********************************************"
key_check
if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
  if [[ ! -d $MODPATH"/system/app/com.miui.touchassistant/" ]]; then
    ui_print "- 正在为你固化悬浮球，请稍等~"
    mkdir -p $MODPATH"/system/app/com.miui.touchassistant/"
    if [[ ! -d $MODPATH"/system/app/com.miui.touchassistant/" ]]; then
      mkdir -p $MODPATH"/system/app/com.miui.touchassistant/"
    fi
    cp -f $MODPATH/common/apks/MIUITouchAssistant.apk $MODPATH/system/app/com.miui.touchassistant/base.apk
  fi
  ui_print "- 正在为你安装悬浮球，请稍等~"
  unzip -jo "$ZIPFILE" 'common/apks/MIUITouchAssistant.apk' -d /data/local/tmp/ &>/dev/null
  pm install -r /data/local/tmp/MIUITouchAssistant.apk &>/dev/null
  rm -rf /data/local/tmp/MIUITouchAssistant.apk
  rm -rf "$MODPATH"/common/apks/MIUITouchAssistant.apk
  HAS_BEEN_INSTALLED_MIUITouchAssistant_APK=$(pm list packages | grep com.miui.touchassistant)
  if [[ $HAS_BEEN_INSTALLED_MIUITouchAssistant_APK == *"package:com.miui.touchassistant"* ]]; then
    ui_print "- 好诶，悬浮球安装完成！"
  else
    abort "- 坏诶，悬浮球安装失败，请尝试重新安装！"
  fi
else
  ui_print "- 你选择不安装悬浮球！"
fi

ui_print "*********************************************"
ui_print "- 是否安装小米教育中心？"
ui_print "  音量+ ：是"
ui_print "  音量- ：否"
ui_print "*********************************************"
key_check
if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
  if [[ "$has_been_patch_privapp_permissions_product" == 0 ]]; then
    has_been_patch_privapp_permissions_product=1
    patch_privapp_permissions_product $MODPATH
    add_post_fs_data 'patch_privapp_permissions_product $MODDIR'
  fi
  ui_print "*********************************************"
  ui_print "- 请选择小米教育中心的安装方式？"
  ui_print "  音量+ ：仅修补小米教育中心权限(不自动安装)"
  ui_print "  音量- ：修补权限并固化小米教育中心为系统应用(自动安装)"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 正在为你修补小米教育中心的权限，请稍等~"
    patch_permissions "$MODPATH" "kidspace"
    add_post_fs_data 'patch_permissions $MODDIR "kidspace"'
    ui_print "- 好诶，小米教育中心权限修补完成，请自行安装小米教育中心并通过[scene]或者[爱玩机工具箱]固化小米教育中心，重启系统后生效！"
  else
    ui_print "- 正在为你修补小米教育中心的权限，请稍等~"
    patch_permissions "$MODPATH" "kidspace"
    add_post_fs_data 'patch_permissions $MODDIR "kidspace"'
    ui_print "- 正在为你固化小米教育中心，请稍等~"
    if [[ ! -d $MODPATH"/system/app/priv-app/com.xiaomi.kidspace/" ]]; then
      mkdir -p $MODPATH"/system/app/priv-app/com.xiaomi.kidspace/"
    fi
    cp -f $MODPATH/common/apks/kidspace.apk $MODPATH/system/app/priv-app/com.xiaomi.kidspace/base.apk
    ui_print "- 正在为你安装小米教育中心，请稍等~"
    unzip -jo "$ZIPFILE" 'common/apks/kidspace.apk' -d /data/local/tmp/ &>/dev/null
    if [[ ! -f /data/local/tmp/kidspace.apk ]]; then
      abort "- 坏诶，传送门安装失败，无法进行安装！"
    else
      pm install -r /data/local/tmp/kidspace.apk &>/dev/null
      rm -rf /data/local/tmp/kidspace.apk
      rm -rf "$MODPATH"/common/apks/kidspace.apk
      HAS_BEEN_INSTALLED_kidspace_APK=$(pm list packages | grep com.xiaomi.kidspace)
      if [[ $HAS_BEEN_INSTALLED_kidspace_APK == *"package:com.xiaomi.kidspace"* ]]; then
        ui_print "- 好诶，小米教育中心安装完成！"
      else
        abort "- 坏诶，小米教育中心安装失败，请尝试重新安装！"
      fi
    fi
  fi
else
  ui_print "- 你选择不安装小米教育中心！"
fi

ui_print "*********************************************"
ui_print "- 好诶w，模块已经安装完成了，重启平板后生效"
ui_print "- 功能具体支持情况以系统为准"
ui_print "*********************************************"
