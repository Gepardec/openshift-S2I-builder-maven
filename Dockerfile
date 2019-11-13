FROM maven:3-jdk-11

ENV BUILDER_CONTEXT_DIR="" \
    BUILDER_MVN_MIRROR="" \
    BUILDER_MVN_MIRROR_ALLOW_FALLBACK=false \
    BUILDER_MVN_OPTIONS=""
    
ARG S2IDIR="/home/s2i"
LABEL io.k8s.description="S2I Maven Builder (based on docker.io/maven:${TAG})" \
      io.k8s.display-name="S2I Maven Builder" \
      io.openshift.tags="builder,java,maven" \
      io.openshift.s2i.scripts-url="image://${S2IDIR}/bin" \
      maintainer="Clemens Kaserer <clemens.kaserer@gepardec.com>"

COPY s2i ${S2IDIR}

ARG APPDIR="/deployments"
RUN mkdir -p ${APPDIR}/target && \
    chgrp -R 0 ${APPDIR} ${S2IDIR} /usr/share/maven/ref/ && \ 
    chmod -R g+rwX ${APPDIR} ${S2IDIR} /usr/share/maven/ref/

USER 1001

WORKDIR ${APPDIR}

CMD ["${S2IDIR}/bin/run"]
