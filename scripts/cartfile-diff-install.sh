set -x
set -e
if [ ! -e redis-2.4.18/src/redis-server ]; then
  git clone https://github.com/YPlan/CartfileDiff.git
  cd CartfileDiff
  make install;
fi