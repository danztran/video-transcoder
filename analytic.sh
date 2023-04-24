main() {
  dirs=( `find dist -type d -maxdepth 1 ! -path dist` )
  for d in ${dirs[@]}; do
    echo \> `basename $d`
    find $d -type f -name "stat.short" -exec cat {} + | sed 's|^|  |g'
    echo
  done
}

main $@
