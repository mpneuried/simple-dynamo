VERSIONS[0]=5.4
VERSIONS[1]=4.4
VERSIONS[2]=lts
VERSIONS[3]=latest

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SCRIPTDIR="dockertests"
cd $DIR
cd ..

for version in "${VERSIONS[@]}"
do
   :
   FV=`echo $version | sed 's/\./_/'`
   DFile="Dockerfile.$FV"
   if [ -f "$SCRIPTDIR/$DFile" ]; then
	   echo "TEST Version: $version"
	   BUILDLOGS="$DIR/dockerbuild.$version.log"
	   rm -f $BUILDLOGS
	   echo "Start build ..."
	   docker build -t=mpneuried.simple-dynamo.dockertest.$version -f=$SCRIPTDIR/$DFile . > $BUILDLOGS
	   echo "Run test ..."
	   docker run --name=mpneuried.simple-dynamo.dockertest.$version mpneuried.simple-dynamo.dockertest.$version >&2
	   echo "Remove container ..."
	   docker rm mpneuried.simple-dynamo.dockertest.$version >&2
   else
	   echo "Dockerfile '$DFile' not found"
   fi
done
