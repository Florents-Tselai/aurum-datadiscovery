#!/usr/bin/env bash

echo "Validating Aurum environment..."
echo "Aurum home directory is", $AURUM_HOME
echo "Aurum DDProfiler home is", $AURUM_DDPROFILER_HOME
echo "Aurum data will be stored under", $AURUM_DATA_DIR
echo "Aurum models will be stored under", $AURUM_MODELS_DIR
echo "Aurum ElasticSearch host is", $AURUM_ES_HOST
echo "Aurum virtualenv path is", $AURUM_VENV



CSV_DATA_DIR=$AURUM_DATA_DIR/fivethirtyeight
FIVETHIRTYEIGHT_MODEL_DIR=$AURUM_MODELS_DIR/fivethirtyeight
mkdir -p $CSV_DATA_DIR $FIVETHIRTYEIGHT_MODEL_DIR

echo "Clearing up old data & models"
rm $FIVETHIRTYEIGHT_MODEL_DIR/*
rm $CSV_DATA_DIR/*

echo "Deleting profiling indices: profile, text"
curl -X DELETE $AURUM_ES_HOST/profile
curl -X DELETE $AURUM_ES_HOST/text


echo Collecting csv files from fivethirtyeight
csv_files=`find ./fivethirtyeight -type f -name "*.csv"`
echo Copying `find ./fivethirtyeight -type f -name "*.csv" | wc -l` files
for i in $csv_files; do
    cp $i $CSV_DATA_DIR
    done

echo $CSV_DATA_DIR now has `ls -l $CSV_DATA_DIR | wc -l` files. `du -sch $CSV_DATA_DIR`


echo Generating fivethirtyeight.yml source file

tee $AURUM_DDPROFILER_HOME/fivethirtyeight.yml <<EOF
api_version: 0
sources:

- name: "fivethirtyeight_csv_repository"
  type: csv
  config:
      path: "$CSV_DATA_DIR"
      separator: ','
EOF




echo Building DDprofiler
cd $AURUM_DDPROFILER_HOME
/usr/bin/gradle clean build -x test installDist

chmod +x $AURUM_DDPROFILER/run.sh
echo "Running ddprofiler for files under $CSV_DATA_DIR"
$AURUM_DDPROFILER_HOME/run.sh --sources fivethirtyeight.yml

cd $AURUM_HOME
$AURUM_PYTHON networkbuildercoordinator.py --opath $FIVETHIRTYEIGHT_MODEL_DIR

echo "##############################################################################"
echo "You can find the FiveThirtyEight model under" $FIVETHIRTYEIGHT_MODEL_DIR
echo "##############################################################################"
