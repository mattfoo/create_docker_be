#!/bin/sh

CSS_FILE="pandoc.css"
DUMB_INIT="dumb-init_1.0.2_amd64.deb"

# shell script for creating a proper docker build environment
# based on best practices

if [ -z $1 ]; then
    echo "usage: $0 <project>"
    exit 1
fi

if [ -d $1 ]; then
    echo "[ERROR] Directory '$1' already exists!"
    exit 2
fi

echo "[INFO] Creating project: $1"
mkdir -p $1 && cd $1

echo "[INFO] Creating directory structure..."
for dir in build/etc build/scripts env packages tools; do
    mkdir -p assets/${dir}
done

echo "[INFO] Copying additional packages..."
cp ../assets/packages/*.deb assets/packages/

echo "[INFO] Copying css file for documentation purpose..."
mkdir -p doc && cp ../assets/doc/${CSS_FILE} doc/

echo "[INFO] Creating Makefile..."
cat > Makefile << _EOF_
NAME     = $1
REGISTRY = local
VERSION  = 1.00

.PHONY: build clean

all: build

clean-all: clean

build:
	@docker build --rm=true -t \$(REGISTRY)/\$(NAME):\$(VERSION) .
	@docker tag \$(REGISTRY)/\$(NAME):\$(VERSION) \$(REGISTRY)/\$(NAME):latest
	@docker images \$(REGISTRY)/\$(NAME)

clean:
	@docker rmi \$(REGISTRY)/\$(NAME):\$(VERSION)
	@docker rmi \$(REGISTRY)/\$(NAME):latest

html: README.md
	@pandoc -s -S --toc -c pandoc.css -f markdown README.md -t html5 -o ./doc/README.html

default: build
_EOF_

echo "[INFO] Creating Dockerfile..."
cat > Dockerfile << _EOF_
FROM debian:latest

MAINTAINER Matt Foo <foo.matt@googlemail.com>

# RUN apt-get update \\
#     && DEBIAN_FRONTEND=noninteractive apt-get -y install <put_in_your_packages> \\
#     && rm -rf /var/lib/apt/lists/*

ADD ./assets/packages/${DUMB_INIT} /tmp

RUN dpkg -i /tmp/${DUMB_INIT} && \\
    rm /tmp/${DUMB_INIT}

# Run
CMD [ "dumb-init", "--verbose" , "--help" ]
_EOF_

echo "[INFO] Creating README.md..."
echo "# ${1}" | tr [a-z] [A-Z] > README.md
echo "The purpose of this docker container is: ..." >> README.md

echo "[OK] Project successfully created!"
