# shellcheck disable=SC2148
# shellcheck disable=SC2034
# shellcheck disable=SC2086
# shellcheck disable=SC1091
# shellcheck disable=SC2016
SKIPUNZIP=0
. "$MODPATH"/util_functions.sh
magisk_path=/data/adb/modules/
module_id=$(grep_prop id $MODPATH/module.prop)
has_been_patch_privapp_permissions_product=0
get_build_characteristics=$(getprop ro.build.characteristics)

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

if [[ "$KSU" == "true" ]]; then
  ui_print "- KernelSU 用户空间当前的版本号: $KSU_VER_CODE"
  ui_print "- KernelSU 内核空间当前的版本号: $KSU_KERNEL_VER_CODE"
  if [ "$KSU_VER_CODE" -lt 11551 ]; then
    ui_print "*********************************************"
    ui_print "- 请更新 KernelSU 到 v0.8.0+ ！"
    abort "*********************************************"
  fi
elif [[ "$APATCH" == "true" ]]; then
  ui_print "- APatch 当前的版本号: $APATCH_VER_CODE"
  ui_print "- APatch 当前的版本名: $APATCH_VER"
  ui_print "- KernelPatch 用户空间当前的版本号: $KERNELPATCH_VERSION"
  ui_print "- KernelPatch 内核空间当前的版本号: $KERNEL_VERSION"
  if [ "$APATCH_VER_CODE" -lt 10568 ]; then
    ui_print "*********************************************"
    ui_print "- 请更新 APatch 到 10568+ ！"
    abort "*********************************************"
  fi
else
  ui_print "- Magisk 版本: $MAGISK_VER_CODE"
  if [ "$MAGISK_VER_CODE" -lt 26000 ]; then
    ui_print "*********************************************"
    ui_print "- 模块当前仅支持 Magisk 26.0+ 请更新 Magisk！"
    ui_print "- 您可以选择继续安装，但可能导致部分模块功能无法正常使用，是否继续？"
    ui_print "  音量+ ：已了解，继续安装"
    ui_print "  音量- ：否"
    ui_print "*********************************************"
    key_check
    if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
      ui_print "*********************************************"
      ui_print "- 你选择无视Magisk低版本警告，可能导致部分模块功能无法正常使用！！！"
      ui_print "*********************************************"
    else
      ui_print "*********************************************"
      ui_print "- 请更新 Magisk 到 26.0+ ！"
      abort "*********************************************"
    fi
    abort "*********************************************"
  fi
fi

# 重置缓存
rm -rf /data/system/package_cache
rm -rf /data/resource-cache

if [[ -d "$magisk_path$module_id" ]]; then
  ui_print "*********************************************"
  ui_print "模块不支持覆盖更新，请卸载模块并重启平板后再尝试安装！"
  ui_print "强行覆盖更新会导致模块数据异常，可能导致系统出现不可预料的异常问题！"
  ui_print "(APatch可能首次安装也会出现覆盖更新的提醒，这种情况下可以选择忽略)"
  ui_print "  音量+ ：哼，我偏要装(强制安装)"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "*********************************************"
    ui_print "- 你选择了强制安装！！！"
    ui_print "*********************************************"
  else
    ui_print "*********************************************"
    ui_print "- 请卸载模块并重启平板后再尝试安装QwQ！！！"
    abort "*********************************************"
  fi
fi

if [[ -d $magisk_path"xiaomi-pad-hyper-content-extension" ]]; then
  ui_print "*********************************************"
  ui_print "存在互斥模块[HyperOS For Pad 传送门补丁]，请卸载模块并重启平板后再尝试安装！"
  abort "*********************************************"
fi

add_post_fs_data() {
  local line="$1"
  printf "\n$line\n" >>"$MODPATH"/post-fs-data.sh
}

if [[ -d "$MODPATH/common/apks/MIUIContentExtension/$API/" ]]; then
  ui_print "*********************************************"
  ui_print "- 是否安装传送门？"
  ui_print "- [重要提醒]传送门可能会被异常加入到游戏工具箱，可以通过完美横屏应用计划Web UI一键移除"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    # 拷贝权限文件
    if [[ "$has_been_patch_privapp_permissions_product" == 0 ]]; then
      has_been_patch_privapp_permissions_product=1
      patch_privapp_permissions_product $MODPATH
      add_post_fs_data 'patch_privapp_permissions_product $MODDIR'
    fi
    ui_print "- 正在为你修补传送门的权限，请稍等~"
    patch_permissions "$MODPATH" "MIUIContentExtension"
    add_post_fs_data 'patch_permissions $MODDIR "MIUIContentExtension"'
    ui_print "- 正在为你固化传送门，请稍等~"
    if [[ ! -d $MODPATH"/system/product/priv-app/MIUIContentExtension/" ]]; then
      mkdir -p $MODPATH"/system/product/priv-app/MIUIContentExtension/"
    fi
    cp -f $MODPATH/common/apks/MIUIContentExtension/$API/MIUIContentExtension.apk $MODPATH/system/product/priv-app/MIUIContentExtension/MIUIContentExtension.apk
    unzip -jo "$ZIPFILE" "common/apks/MIUIContentExtension/$API/MIUIContentExtension.apk" -d /data/local/tmp/
    if [[ ! -f /data/local/tmp/MIUIContentExtension.apk ]]; then
      abort "- 坏诶，传送门安装失败，无法进行安装！"
    else
      pm install -r /data/local/tmp/MIUIContentExtension.apk
      rm -rf /data/local/tmp/MIUIContentExtension.apk
      rm -rf "$MODPATH"/common/apks/MIUIContentExtension/
      HAS_BEEN_INSTALLED_MIUIContentExtension_APK=$(pm list packages | grep com.miui.contentextension)
      if [[ $HAS_BEEN_INSTALLED_MIUIContentExtension_APK == *"package:com.miui.contentextension"* ]]; then
        ui_print "- 好诶，传送门安装完成！"
        ui_print "- 如果不生效请手动卸载模块并重启，再卸载传送门，再重新安装模块！"
        ui_print "- [重要提醒]传送门可能会被异常加入到游戏工具箱，可以通过完美横屏应用计划Web UI一键移除"
      else
        abort "- 坏诶，传送门安装失败，请尝试重新安装！"
      fi
    fi
  else
    ui_print "- 你选择不安装传送门！"
  fi
fi

if [[ -d "$MODPATH/common/apks/MIUITouchAssistant/$API/" ]]; then
  ui_print "*********************************************"
  ui_print "- 是否安装悬浮球？"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 正在为你固化悬浮球，请稍等~"
    if [[ ! -d $MODPATH"/system/product/app/MIUITouchAssistant/" ]]; then
      mkdir -p $MODPATH"/system/product/app/MIUITouchAssistant/"
    fi
    cp -f $MODPATH/common/apks/MIUITouchAssistant/$API/MIUITouchAssistant.apk $MODPATH/system/product/app/MIUITouchAssistant/MIUITouchAssistant.apk
    rm -rf "$MODPATH"/common/apks/MIUITouchAssistant/
    ui_print "- 好诶，悬浮球安装完成！"
    ui_print "- 如果不生效请手动重新安装一次悬浮球的安装包！"
  else
    ui_print "- 你选择不安装悬浮球！"
  fi
fi

ui_print "*********************************************"
ui_print "- 好诶w，模块已经安装完成了，重启平板后生效"
ui_print "- 功能具体支持情况以系统为准"
ui_print "*********************************************"
