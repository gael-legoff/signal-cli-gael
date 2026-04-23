#!/bin/bash

set -ex

# Enable automatic service restart
sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf

# Clean up leftovers
rm -f gradle graalvm-jdk native-image.properties signal-cli

# Set up versions
SIGNAL_CLI_VERSION="v0.14.3"
GRADLE_VERSION="9.4.1"
GRAALVM_VERSION="25"

# Update the container & install the required tools
apt-get update 2>/dev/null
apt-get -y dist-upgrade
apt-get -y install wget unzip build-essential zlib1g-dev

# Download Gradle & GraalVM
wget --quiet -O gradle.zip https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip
unzip -q gradle.zip
rm -f gradle.zip
mv gradle-${GRADLE_VERSION} gradle

wget --quiet -O graalvm-jdk.tar.gz https://download.oracle.com/graalvm/${GRAALVM_VERSION}/latest/graalvm-jdk-${GRAALVM_VERSION}_linux-x64_bin.tar.gz
tar xzf graalvm-jdk.tar.gz
rm -f graalvm-jdk.tar.gz
mv -f graalvm-jdk* graalvm-jdk

export PATH=`realpath gradle/bin`:`realpath graalvm-jdk`/bin:$PATH

# Configure Native image
echo "NativeImageArgs=-march=x86-64-v2" > native-image.properties
export NATIVE_IMAGE_CONFIG_FILE=`realpath native-image.properties`

# Clone & build signal-cli
git clone -b ${SIGNAL_CLI_VERSION} --depth 1 https://github.com/AsamK/signal-cli.git

cd signal-cli

gradle build
gradle installDist
gradle distTar
gradle fatJar
gradle run --args="--help"
gradle nativeCompile

exit 0
