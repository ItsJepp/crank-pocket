if [ ! -d ./builds ]; then
  mkdir -p ./builds;
fi

echo "Building..."
pdc ./source ./builds/CrankPocket.pdx
echo "Done"
echo "Running..."
$PLAYDATE_SDK_PATH/bin/PlaydateSimulator ./builds/CrankPocket.pdx &