# shellcheck disable=SC2148
# shellcheck disable=SC2034
SKIPUNZIP=0
. "$MODPATH"/util_functions.sh
magisk_path=/data/adb/modules/
module_id=$(grep_prop id $MODPATH/module.prop)
has_been_patch_privapp_permissions_product=0
get_build_characteristics=$(getprop ro.build.characteristics)
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
# rm -rf /data/resource-cache

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

ui_print "*********************************************"
ui_print "- 是否安装传送门？"
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
  ui_print "- 正在为你固化悬浮球，请稍等~"
  if [[ ! -d $MODPATH"/system/product/app/MIUITouchAssistant/" ]]; then
    mkdir -p $MODPATH"/system/product/app/MIUITouchAssistant/"
  fi
  cp -f $MODPATH/common/apks/MIUITouchAssistant.apk $MODPATH/system/product/app/MIUITouchAssistant/MIUITouchAssistant.apk
  ui_print "- 好诶，悬浮球安装完成！"
  # ui_print "- 正在为你安装悬浮球，请稍等~"
  # unzip -jo "$ZIPFILE" 'common/apks/MIUITouchAssistant.apk' -d /data/local/tmp/ &>/dev/null
  # pm install -r /data/local/tmp/MIUITouchAssistant.apk &>/dev/null
  # rm -rf /data/local/tmp/MIUITouchAssistant.apk
  # rm -rf "$MODPATH"/common/apks/MIUITouchAssistant.apk
  # HAS_BEEN_INSTALLED_MIUITouchAssistant_APK=$(pm list packages | grep com.miui.touchassistant)
  # if [[ $HAS_BEEN_INSTALLED_MIUITouchAssistant_APK == *"package:com.miui.touchassistant"* ]]; then
  #   ui_print "- 好诶，悬浮球安装完成！"
  # else
  #   abort "- 坏诶，悬浮球安装失败，请尝试重新安装！"
  # fi
else
  ui_print "- 你选择不安装悬浮球！"
fi

if [[ ! -f "/system/product/priv-app/kidspace/kidspace.apk" ]]; then
  ui_print "*********************************************"
  ui_print "- 是否安装小米教育中心？"
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
      if [[ ! -d $MODPATH"/system/product/priv-app/kidspace/" ]]; then
        mkdir -p $MODPATH"/system/product/priv-app/kidspace/"
      fi
      cp -f $MODPATH/common/apks/kidspace.apk $MODPATH/system/product/priv-app/kidspace/kidspace.apk
      ui_print "- 正在为你安装小米教育中心，请稍等~"
      unzip -jo "$ZIPFILE" 'common/apks/kidspace.apk' -d /data/local/tmp/ &>/dev/null
      if [[ ! -f /data/local/tmp/kidspace.apk ]]; then
        abort "- 坏诶，小米教育中心安装失败，无法进行安装！"
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
fi

# ui_print "*********************************************"
# ui_print "- 是否修补搜索的权限？"
# ui_print "  音量+ ：是"
# ui_print "  音量- ：否"
# ui_print "*********************************************"
# key_check
# if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
#   ui_print "- 正在为你修补搜索的权限，请稍等~"
#   patch_permissions "$MODPATH" "QuickSearchBoxPadMIUI15"
#   add_post_fs_data 'patch_permissions $MODDIR "QuickSearchBoxPadMIUI15"'
#   ui_print "- 好诶，搜索权限修补完成，重启系统后生效！"
# else
#   ui_print "- 你选择不修补搜索的权限！"
# fi

# 短信
# if [[ ! -f "/system/product/priv-app/MIUIMms_FOLD/MIUIMms_FOLD.apk" && "$get_build_characteristics" = "tablet" && "$API" -eq 34 ]]; then
#   ui_print "*********************************************"
#   ui_print "- 是否安装短信？"
#   ui_print "  音量+ ：是"
#   ui_print "  音量- ：否"
#   ui_print "*********************************************"
#   key_check
#   if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
#     # 拷贝权限文件
#     if [[ "$has_been_patch_privapp_permissions_product" == 0 ]]; then
#       has_been_patch_privapp_permissions_product=1
#       patch_privapp_permissions_product $MODPATH
#       add_post_fs_data 'patch_privapp_permissions_product $MODDIR'
#     fi
#     ui_print "*********************************************"
#     ui_print "- 请选择短信的安装方式？"
#     ui_print "  音量+ ：仅修补短信权限(不自动安装)"
#     ui_print "  音量- ：修补权限并固化短信为系统应用(自动安装)"
#     ui_print "*********************************************"
#     key_check
#     if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
#       ui_print "- 正在为你修补短信的权限，请稍等~"
#       patch_permissions "$MODPATH" "MIUIMms_FOLD"
#       add_post_fs_data 'patch_permissions $MODDIR "MIUIMms_FOLD"'
#       ui_print "- 好诶，短信的权限修补完成，请自行安装短信并通过[scene]或者[爱玩机工具箱]固化短信，重启系统后生效！"
#     else
#       ui_print "- 正在为你修补短信的权限，请稍等~"
#       patch_permissions "$MODPATH" "MIUIMms_FOLD"
#       add_post_fs_data 'patch_permissions $MODDIR "MIUIMms_FOLD"'
#       ui_print "- 正在为你固化短信，请稍等~"
#       if [[ ! -d $MODPATH"/system/product/priv-app/MIUIMms_FOLD/" ]]; then
#         mkdir -p $MODPATH"/system/product/priv-app/MIUIMms_FOLD/"
#       fi
#       cp -f $MODPATH/common/apks/MIUIMms_FOLD.apk $MODPATH/system/product/priv-app/MIUIMms_FOLD/MIUIMms_FOLD.apk
#       ui_print "- 正在为你安装短信，请稍等~"
#       unzip -jo "$ZIPFILE" 'common/apks/MIUIMms_FOLD.apk' -d /data/local/tmp/ &>/dev/null
#       if [[ ! -f /data/local/tmp/MIUIMms_FOLD.apk ]]; then
#         abort "- 坏诶，短信安装失败，无法进行安装！"
#       else
#         pm install -r /data/local/tmp/MIUIMms_FOLD.apk &>/dev/null
#         rm -rf /data/local/tmp/MIUIMms_FOLD.apk
#         rm -rf "$MODPATH"/common/apks/MIUIMms_FOLD.apk
#         HAS_BEEN_INSTALLED_MIUIMms_FOLD_APK=$(pm list packages | grep "^package:com.android.mms$")
#         if [[ $HAS_BEEN_INSTALLED_MIUIMms_FOLD_APK ]]; then
#           ui_print "- 好诶，短信安装完成！"
#         else
#           abort "- 坏诶，短信安装失败，请尝试重新安装！"
#         fi
#       fi
#     fi
#   else
#     ui_print "- 你选择不安装短信！"
#   fi
# fi

# if [[ ! -f "/system/product/priv-app/MIUIContactsT/MIUIContactsT.apk" && "$get_build_characteristics" = "tablet" && "$API" -eq 34 ]]; then
#   ui_print "*********************************************"
#   ui_print "- 是否安装通讯录与拨号？"
#   ui_print "  音量+ ：是"
#   ui_print "  音量- ：否"
#   ui_print "*********************************************"
#   key_check
#   if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
#     # 拷贝权限文件
#     if [[ "$has_been_patch_privapp_permissions_product" == 0 ]]; then
#       has_been_patch_privapp_permissions_product=1
#       patch_privapp_permissions_product $MODPATH
#       add_post_fs_data 'patch_privapp_permissions_product $MODDIR'
#     fi
#     ui_print "*********************************************"
#     ui_print "- 请选择通讯录与拨号的安装方式？"
#     ui_print "  音量+ ：仅修补通讯录与拨号权限(不自动安装)"
#     ui_print "  音量- ：修补权限并固化通讯录与拨号为系统应用(自动安装)"
#     ui_print "*********************************************"
#     key_check
#     if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
#       ui_print "- 正在为你修补通讯录与拨号的权限，请稍等~"
#       patch_permissions "$MODPATH" "MIUIContactsT"
#       add_post_fs_data 'patch_permissions $MODDIR "MIUIContactsT"'
#       ui_print "- 好诶，通讯录与拨号的权限修补完成，请自行安装通讯录与拨号并通过[scene]或者[爱玩机工具箱]固化通讯录与拨号，重启系统后生效！"
#     else
#       ui_print "- 正在为你修补通讯录与拨号的权限，请稍等~"
#       patch_permissions "$MODPATH" "MIUIContactsT"
#       add_post_fs_data 'patch_permissions $MODDIR "MIUIContactsT"'
#       ui_print "- 正在为你固化通讯录与拨号，请稍等~"
#       if [[ ! -d $MODPATH"/system/product/priv-app/MIUIContactsT/" ]]; then
#         mkdir -p $MODPATH"/system/product/priv-app/MIUIContactsT/"
#       fi
#       cp -f $MODPATH/common/apks/MIUIMms_FOLD.apk $MODPATH/system/product/priv-app/MIUIContactsT/MIUIContactsT.apk
#       ui_print "- 正在为你安装通讯录与拨号，请稍等~"
#       unzip -jo "$ZIPFILE" 'common/apks/MIUIContactsT.apk' -d /data/local/tmp/ &>/dev/null
#       if [[ ! -f /data/local/tmp/MIUIContactsT.apk ]]; then
#         abort "- 坏诶，通讯录与拨号安装失败，无法进行安装！"
#       else
#         pm install -r /data/local/tmp/MIUIContactsT.apk &>/dev/null
#         rm -rf /data/local/tmp/MIUIContactsT.apk
#         rm -rf "$MODPATH"/common/apks/MIUIContactsT.apk
#         HAS_BEEN_INSTALLED_MIUIContactsT_APK=$(pm list packages | grep "^package:com.android.contacts$")
#         if [[ $HAS_BEEN_INSTALLED_MIUIContactsT_APK ]]; then
#           ui_print "- 好诶，通讯录与拨号安装完成！"
#         else
#           abort "- 坏诶，通讯录与拨号安装失败，请尝试重新安装！"
#         fi
#       fi
#     fi
#   else
#     ui_print "- 你选择不安装短信！"
#   fi
# fi


ui_print "*********************************************"
ui_print "- 好诶w，模块已经安装完成了，重启平板后生效"
ui_print "- 功能具体支持情况以系统为准"
ui_print "*********************************************"
