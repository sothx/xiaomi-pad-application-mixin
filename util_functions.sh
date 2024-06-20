# shellcheck disable=SC2148

patch_privapp_permissions_product() {
  SYSTEM_PRIVAPP_PERMISSION_PRODUCT_PATH="/system/product/etc/permissions/privapp-permissions-product.xml"
  MODULE_PRIVAPP_PERMISSION_PRODUCT_PATH=$1"/system/product/etc/permissions/privapp-permissions-product.xml"
  if [[ ! -d $1"/system/product/etc/permissions/" ]]; then
      mkdir -p $1"/system/product/etc/permissions/"
  fi
  # 移除旧版补丁文件
  rm -rf "$MODULE_PRIVAPP_PERMISSION_PRODUCT_PATH"
  # 复制私有App权限配置到模块内
  cp -f "$SYSTEM_PRIVAPP_PERMISSION_PRODUCT_PATH" "$MODULE_PRIVAPP_PERMISSION_PRODUCT_PATH"

}

patch_permissions() {
  SYSTEM_PRIVAPP_PERMISSION_PRODUCT_PATH="/system/product/etc/permissions/privapp-permissions-product.xml"
  MODULE_PRIVAPP_PERMISSION_PRODUCT_PATH=$1"/system/product/etc/permissions/privapp-permissions-product.xml"
  CODE_SNIPPET=$1"/common/code-snippet/"$2".xml"
  # 拷贝权限代码片段到模块文件内
  if [[ -f "$MODULE_PRIVAPP_PERMISSION_PRODUCT_PATH" ]]; then
    sed -i '/<\/permissions>/d' "$MODULE_PRIVAPP_PERMISSION_PRODUCT_PATH"
    cat "$CODE_SNIPPET" >>"$MODULE_PRIVAPP_PERMISSION_PRODUCT_PATH"
    printf "\n</permissions>\n" >>"$MODULE_PRIVAPP_PERMISSION_PRODUCT_PATH"
  fi
}

grep_prop() {
  local REGEX="s/^$1=//p"
  shift
  local FILES=$@
  [ -z "$FILES" ] && FILES='/system/build.prop'
  cat $FILES 2>/dev/null | dos2unix | sed -n "$REGEX" | head -n 1
}

update_system_prop() {
  local prop="$1"
  local value="$2"
  local file="$3"

  if grep -q "^$prop=" "$file"; then
    # 如果找到匹配行，使用 sed 进行替换
    sed -i "s/^$prop=.*/$prop=$value/" "$file"
  else
    # 如果没有找到匹配行，追加新行
    printf "$prop=$value\n" >> "$file"
  fi
}

remove_system_prop() {
  local prop="$1"
  local file="$2"
  sed -i "/^$prop=/d" "$file"
}


patch_secure_center_permissions() {
  MODULE_PRIVAPP_PERMISSION_PRODUCT_PATH=$1"/system/product/etc/permissions/privapp-permissions-product.xml"
  if [[ -f "$MODULE_PRIVAPP_PERMISSION_PRODUCT_PATH" ]]; then
    # 补全手机管家权限
    sed -i "$(awk '/<privapp-permissions package="com.miui.securitycenter">/{print NR+1; exit}' $MODULE_PRIVAPP_PERMISSION_PRODUCT_PATH)i \    \  <permission name=\"android.permission.SYSTEM_ALERT_WINDOW\" />" $MODULE_PRIVAPP_PERMISSION_PRODUCT_PATH
    sed -i "$(awk '/<privapp-permissions package="com.miui.securitycenter">/{print NR+1; exit}' $MODULE_PRIVAPP_PERMISSION_PRODUCT_PATH)i \    \  <permission name=\"android.permission.WRITE_SECURE_SETTINGS\" />" $MODULE_PRIVAPP_PERMISSION_PRODUCT_PATH
  fi
}